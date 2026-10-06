import GameCore
import SpriteKit

/// Modo arena: oleadas por niveles en un escenario fijo.
final class BattleScene: CombatScene {
    weak var session: BattleSession?

    private var groundNode: SKSpriteNode?

    private let decorLayer = SKNode()

    private var spawnQueue: [String] = []

    private var spawnTimer: TimeInterval = 0

    private var spawnInterval: TimeInterval = 1

    private var clearTimer: TimeInterval?

    /// Escenario (fondo y decoración).
    private var level: LevelDefinition = Worlds.village.levels[0]
    /// Nivel de dificultad de los enemigos de la oleada.
    private var enemyLevel = 1

    private var builtSize = CGSize.zero

    private var arena: CGRect {
        let top = CGFloat(VillageArt.bandHeight) * PX + 6
        return CGRect(x: 28, y: 24, width: max(10, size.width - 56), height: max(10, size.height - 24 - top))
    }

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor(rgb: 0x4A4440)
        anchorPoint = .zero
        addChild(decorLayer)
        addChild(hero)
        hero.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    func prepare(level: LevelDefinition, stats: Stats, hp: Double, armorIcon: String, weapon: Item?, race: Race) {
        let levelChanged = level.id != self.level.id
        self.level = level
        prepareHero(stats: stats, hp: hp, armorIcon: armorIcon, weapon: weapon, race: race)
        if levelChanged && builtSize != .zero { buildScenery() }
    }

    func startRound(_ wave: Wave, enemyLevel: Int) {
        self.enemyLevel = enemyLevel
        spawnQueue = wave.spawnOrder(using: &rng)
        spawnInterval = wave.spawnInterval
        spawnTimer = 0.6
        clearTimer = nil
        attackTimer = 0
        setRunning(true)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 50, size.height > 50,
              abs(size.width - builtSize.width) > 1 || abs(size.height - builtSize.height) > 1 else { return }
        builtSize = size
        buildScenery()
        hero.position = clamp(hero.position == .zero ? CGPoint(x: size.width / 2, y: size.height / 2) : hero.position)
    }

    private func buildScenery() {
        groundNode?.removeFromParent()
        decorLayer.removeAllChildren()

        let artW = Int((size.width / PX).rounded(.up))
        let artH = Int((size.height / PX).rounded(.up))
        let image = VillageArt.background(width: artW, height: artH, level: level)
        let ground = SKSpriteNode(texture: ArtCache.texture(fromImage: image))
        ground.size = CGSize(width: CGFloat(artW) * PX, height: CGFloat(artH) * PX)
        ground.anchorPoint = CGPoint(x: 0, y: 1)
        ground.position = CGPoint(x: 0, y: size.height)
        ground.zPosition = -10
        addChild(ground)
        groundNode = ground

        // Decoración en los bordes de la zona de juego.
        var decorRNG = SeededGenerator(seed: UInt64(level.id * 31))
        let props: [PixelSprite] = switch level.ground {
        case "farm": [Sprites.hay, Sprites.crate, Sprites.barrel]
        case "graveyard": [Sprites.gravestone, Sprites.gravestone, Sprites.lampPost]
        case "castle": [Sprites.barrel, Sprites.lampPost]
        default: [Sprites.barrel, Sprites.crate, Sprites.lampPost]
        }
        let a = arena
        for i in 0..<7 {
            let sprite = props[Int.random(in: 0..<props.count, using: &decorRNG)]
            let node = SKSpriteNode(texture: ArtCache.texture(fromImage: sprite.makeCGImage()))
            node.size = CGSize(width: CGFloat(sprite.width) * PX, height: CGFloat(sprite.height) * PX)
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            let onLeft = i % 2 == 0
            let x = onLeft ? CGFloat.random(in: 6...a.minX + 20, using: &decorRNG)
                           : CGFloat.random(in: a.maxX - 20...size.width - 6, using: &decorRNG)
            let y = CGFloat.random(in: a.minY...a.maxY - 20, using: &decorRNG)
            node.position = CGPoint(x: x, y: y)
            node.zPosition = depth(for: y)
            decorLayer.addChild(node)
            if level.time != .day, sprite.rows == Sprites.lampPost.rows {
                let glow = SKShapeNode(circleOfRadius: 46)
                glow.fillColor = SKColor(rgb: 0xFFD870, alpha: 0.13)
                glow.strokeColor = .clear
                glow.position = CGPoint(x: 0, y: node.size.height - 4)
                glow.blendMode = .add
                node.addChild(glow)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = frameDelta(currentTime)
        guard running, dt > 0 else { return }
        updateSpawning(dt)
        updateCombat(dt)
        guard running else { return }
        checkRoundEnd(dt)
    }

    // MARK: - Reglas de la arena

    override var shakeNode: SKNode? { groundNode }

    override func moveHero(from old: CGPoint, to new: CGPoint) -> CGPoint { clamp(new) }

    /// Los que ya entraron no pueden salir (si no, los tiradores huirían fuera de alcance).
    override func constrain(_ enemy: EnemyNode, previous: CGPoint) {
        let bounds = arena.insetBy(dx: -6, dy: -6)
        if enemy.hasEntered {
            enemy.position = CGPoint(x: min(bounds.maxX, max(bounds.minX, enemy.position.x)),
                                     y: min(bounds.maxY, max(bounds.minY, enemy.position.y)))
        } else if bounds.contains(enemy.position) {
            enemy.hasEntered = true
        }
    }

    private func updateSpawning(_ dt: TimeInterval) {
        guard !spawnQueue.isEmpty else { return }
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }
        spawnTimer = spawnInterval
        spawn(spawnQueue.removeFirst())
    }

    private func spawn(_ id: String) {
        guard let definition = Bestiary.enemy(id) else { return }
        let enemy = EnemyNode(definition: definition, level: enemyLevel)
        let a = arena
        let margin: CGFloat = 30
        switch Int.random(in: 0..<4, using: &rng) {
        case 0: enemy.position = CGPoint(x: -margin, y: CGFloat.random(in: a.minY...a.maxY, using: &rng))
        case 1: enemy.position = CGPoint(x: size.width + margin, y: CGFloat.random(in: a.minY...a.maxY, using: &rng))
        case 2: enemy.position = CGPoint(x: CGFloat.random(in: a.minX...a.maxX, using: &rng), y: -margin)
        default: enemy.position = CGPoint(x: CGFloat.random(in: a.minX...a.maxX, using: &rng), y: a.maxY + 20)
        }
        if definition.isBoss {
            enemy.position = CGPoint(x: size.width / 2, y: a.maxY + 10)
            floatingText("¡\(definition.name.uppercased())!", at: CGPoint(x: size.width / 2, y: size.height / 2 + 40),
                         color: SKColor(rgb: 0xFFCD45), size: 22, duration: 2)
            shake(intensity: 6)
        }
        enemy.zPosition = depth(for: enemy.position.y)
        addChild(enemy)
        enemies.append(enemy)
    }

    private func checkRoundEnd(_ dt: TimeInterval) {
        guard spawnQueue.isEmpty, enemies.isEmpty else { return }
        if clearTimer == nil {
            clearTimer = 2.5
            pickups.forEach { $0.magnetized = true }
            partPickups.forEach { $0.magnetized = true }
            projectiles.forEach { $0.removeFromParent() }
            projectiles.removeAll()
        }
        clearTimer! -= dt
        if (pickups.isEmpty && partPickups.isEmpty) || clearTimer! <= 0 {
            pickups.forEach(collect)
            partPickups.forEach(collectPart)
            setRunning(false)
            session?.roundCleared()
        }
    }


    private func clamp(_ p: CGPoint) -> CGPoint {
        let a = arena
        return CGPoint(x: min(a.maxX, max(a.minX, p.x)), y: min(a.maxY, max(a.minY, p.y)))
    }
}
