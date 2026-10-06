import GameCore
import SpriteKit

/// Escena de combate. Toda la simulación ocurre aquí; el estado que muestra la interfaz
/// se comunica a `BattleSession` mediante callbacks.
final class BattleScene: SKScene {
    weak var session: BattleSession?

    private let knight = KnightNode()
    private var groundNode: SKSpriteNode?
    private let decorLayer = SKNode()
    private var goblins: [GoblinNode] = []
    private var pickups: [MineralPickupNode] = []

    private var spawnQueue: [MonsterKind] = []
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1
    private var attackTimer: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    private var clearTimer: TimeInterval?
    private var running = false

    private var level = 1
    private(set) var stats = Stats.knightBase
    private(set) var hp: Double = 100
    private var reportedHP = -1
    private var rng = SystemRandomNumberGenerator()
    private var builtSize = CGSize.zero

    /// Zona jugable (deja una franja arriba para los árboles).
    private var arena: CGRect {
        CGRect(x: 28, y: 24, width: max(10, size.width - 56), height: max(10, size.height - 24 - 70))
    }

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor(red: 0.35, green: 0.63, blue: 0.29, alpha: 1)
        anchorPoint = .zero
        addChild(decorLayer)
        addChild(knight)
        knight.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    // MARK: - API para BattleSession

    func prepare(level: Int, stats: Stats, hp: Double, armorIcon: String, weaponIcon: String) {
        self.level = level
        self.stats = stats
        self.hp = min(hp, stats.maxHP)
        reportedHP = -1
        knight.setEquipment(armorIcon: armorIcon, weaponIcon: weaponIcon)
        reportHP()
    }

    func startRound(_ wave: Wave) {
        spawnQueue = wave.spawnOrder(using: &rng)
        spawnInterval = wave.spawnInterval
        spawnTimer = 0.6
        clearTimer = nil
        attackTimer = 0
        setRunning(true)
    }

    func setRunning(_ value: Bool) {
        running = value
        isPaused = !value
        if !value { knight.setWalking(false) }
    }

    func heal(_ amount: Double) {
        hp = min(stats.maxHP, hp + amount)
        reportHP()
        floatingText("+\(Int(amount))", at: knight.position + CGVector(dx: 0, dy: 30), color: .green, size: 14)
    }

    // MARK: - Ciclo de vida

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 50, size.height > 50,
              abs(size.width - builtSize.width) > 1 || abs(size.height - builtSize.height) > 1 else { return }
        builtSize = size
        buildScenery()
        knight.position = clamp(knight.position == .zero ? CGPoint(x: size.width / 2, y: size.height / 2) : knight.position)
    }

    private func buildScenery() {
        groundNode?.removeFromParent()
        decorLayer.removeAllChildren()

        let artW = Int((size.width / PX).rounded(.up))
        let artH = Int((size.height / PX).rounded(.up))
        let ground = SKSpriteNode(texture: ArtCache.texture(fromImage: Art.grassBackground(width: artW, height: artH, seed: UInt64(level * 7919))))
        ground.size = CGSize(width: CGFloat(artW) * PX, height: CGFloat(artH) * PX)
        ground.anchorPoint = .zero
        ground.zPosition = -10
        addChild(ground)
        groundNode = ground

        var decorRNG = SeededGenerator(seed: UInt64(level))
        // Hilera de árboles arriba.
        let treeSize = CGSize(width: 16 * PX, height: 16 * PX)
        var x: CGFloat = -10
        while x < size.width + 20 {
            let tree = SKSpriteNode(texture: Art.tree, size: treeSize)
            tree.anchorPoint = CGPoint(x: 0.5, y: 0)
            let y = size.height - treeSize.height + CGFloat.random(in: -6...14, using: &decorRNG)
            tree.position = CGPoint(x: x, y: y)
            tree.zPosition = depth(for: y) - 5
            decorLayer.addChild(tree)
            x += CGFloat.random(in: 26...40, using: &decorRNG)
        }
        // Algunas rocas decorativas.
        for _ in 0..<5 {
            let rock = SKSpriteNode(texture: Art.rock, size: CGSize(width: 8 * PX, height: 5 * PX))
            rock.position = CGPoint(
                x: CGFloat.random(in: arena.minX...arena.maxX, using: &decorRNG),
                y: CGFloat.random(in: arena.minY...arena.maxY, using: &decorRNG)
            )
            rock.zPosition = -5
            decorLayer.addChild(rock)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(1.0 / 20, currentTime - lastTime)
        lastTime = currentTime
        guard running, dt > 0 else { return }

        updateKnight(dt)
        updateSpawning(dt)
        updateGoblins(dt)
        guard running else { return }   // el caballero puede haber muerto
        updateKnightAttack(dt)
        updatePickups(dt)
        checkRoundEnd(dt)
    }

    // MARK: - Caballero

    private func updateKnight(_ dt: TimeInterval) {
        let input = session?.joystick ?? .zero
        let magnitude = min(1, input.length)
        if magnitude > 0.05 {
            let dir = input.normalized
            knight.position = clamp(knight.position + dir * (CGFloat(stats.moveSpeed * dt) * magnitude))
            knight.face(dx: dir.dx)
            knight.setWalking(true)
        } else {
            knight.setWalking(false)
        }
        knight.zPosition = depth(for: knight.position.y)

        if stats.regen > 0, hp < stats.maxHP {
            hp = min(stats.maxHP, hp + stats.regen * dt)
            reportHP()
        }
    }

    private func updateKnightAttack(_ dt: TimeInterval) {
        attackTimer -= dt
        guard attackTimer <= 0 else { return }
        let reach = CGFloat(stats.range) + KnightNode.bodyRadius * 0.5
        let candidates = goblins.filter { !$0.isDying && $0.position.distance(to: knight.position) - $0.radius <= reach }
        guard let target = candidates.min(by: {
            $0.position.distance(to: knight.position) < $1.position.distance(to: knight.position)
        }) else { return }

        attackTimer = 1 / stats.attackSpeed
        let aim = (target.position - knight.position).normalized
        knight.face(dx: aim.dx)
        knight.swing()
        slashEffect(direction: aim, reach: reach)

        // El objetivo recibe el golpe completo; los demás dentro del arco (~145°), el 75%.
        for goblin in candidates {
            let dir = (goblin.position - knight.position).normalized
            let isPrimary = goblin === target
            let inArc = dir.dx * aim.dx + dir.dy * aim.dy > 0.3
            guard isPrimary || inArc else { continue }
            var hit = Combat.rollHit(stats: stats, using: &rng)
            if !isPrimary { hit.amount *= 0.75 }
            damage(goblin, hit: hit)
        }
    }

    private func damage(_ goblin: GoblinNode, hit: Combat.Hit) {
        let died = goblin.takeDamage(hit.amount, from: knight.position)
        floatingText(
            hit.isCrit ? "\(Int(hit.amount))!" : "\(Int(hit.amount))",
            at: goblin.position + CGVector(dx: CGFloat.random(in: -6...6), dy: goblin.size.height / 2),
            color: hit.isCrit ? SKColor(red: 1, green: 0.8, blue: 0.3, alpha: 1) : .white,
            size: hit.isCrit ? 17 : 13
        )
        if stats.lifesteal > 0 {
            hp = min(stats.maxHP, hp + hit.amount * stats.lifesteal)
            reportHP()
        }
        if died { kill(goblin) }
    }

    private func knightHit(by raw: Double) {
        let amount = Combat.incomingDamage(raw: raw, defense: stats.defense)
        hp -= amount
        knight.hurtFlash()
        floatingText("-\(Int(amount.rounded()))", at: knight.position + CGVector(dx: 0, dy: 26), color: SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 1), size: 13)
        reportHP()
        session?.knightWasHit()
        if hp <= 0 {
            hp = 0
            running = false
            knight.setWalking(false)
            knight.playDeath()
            run(.sequence([.wait(forDuration: 1.2), .run { [weak self] in self?.session?.knightDied() }]))
        }
    }

    private func reportHP() {
        let rounded = Int(hp.rounded(.up))
        guard rounded != reportedHP else { return }
        reportedHP = rounded
        session?.knightHPChanged(hp: hp, maxHP: stats.maxHP)
    }

    // MARK: - Goblins

    private func updateSpawning(_ dt: TimeInterval) {
        guard !spawnQueue.isEmpty else { return }
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }
        spawnTimer = spawnInterval
        spawn(spawnQueue.removeFirst())
    }

    private func spawn(_ kind: MonsterKind) {
        let goblin = GoblinNode(kind: kind, level: level)
        let a = arena
        let margin: CGFloat = 30
        switch Int.random(in: 0..<4, using: &rng) {
        case 0: goblin.position = CGPoint(x: -margin, y: CGFloat.random(in: a.minY...a.maxY, using: &rng))
        case 1: goblin.position = CGPoint(x: size.width + margin, y: CGFloat.random(in: a.minY...a.maxY, using: &rng))
        case 2: goblin.position = CGPoint(x: CGFloat.random(in: a.minX...a.maxX, using: &rng), y: -margin)
        default: goblin.position = CGPoint(x: CGFloat.random(in: a.minX...a.maxX, using: &rng), y: a.maxY + 20)
        }
        goblin.zPosition = depth(for: goblin.position.y)
        addChild(goblin)
        goblins.append(goblin)

        if kind.isBoss {
            floatingText("¡EL REY GOBLIN!", at: CGPoint(x: size.width / 2, y: size.height / 2 + 40), color: SKColor(red: 1, green: 0.8, blue: 0.3, alpha: 1), size: 24, duration: 1.8)
        }
    }

    private func updateGoblins(_ dt: TimeInterval) {
        for goblin in goblins where !goblin.isDying {
            let contact = KnightNode.bodyRadius + goblin.radius + CGFloat(goblin.stats.attackRange)
            if let damage = goblin.step(dt: dt, target: knight.position, contactDistance: contact) {
                knightHit(by: damage)
                if !running { return }
            }
        }
        separateGoblins()
        for goblin in goblins { goblin.zPosition = depth(for: goblin.position.y) }
    }

    /// Evita que los goblins se amontonen en el mismo punto.
    private func separateGoblins() {
        let count = goblins.count
        guard count > 1 else { return }
        for i in 0..<(count - 1) {
            for j in (i + 1)..<count {
                let a = goblins[i], b = goblins[j]
                let delta = b.position - a.position
                let dist = delta.length
                let minDist = (a.radius + b.radius) * 0.85
                guard dist < minDist else { continue }
                let dir = dist > 0.01 ? delta.normalized : CGVector(dx: 1, dy: 0)
                let overlap = (minDist - dist) / 2
                a.push(dir * -overlap)
                b.push(dir * overlap)
            }
        }
    }

    private func kill(_ goblin: GoblinNode) {
        goblin.isDying = true
        goblins.removeAll { $0 === goblin }
        session?.goblinKilled(goblin.kind)

        goblin.removeAllActions()
        goblin.run(.sequence([
            .group([.fadeOut(withDuration: 0.25), .scaleY(to: 0.3, duration: 0.25)]),
            .removeFromParent(),
        ]))
        burst(at: goblin.position, color: SKColor(red: 0.22, green: 0.72, blue: 0.39, alpha: 1), count: burstCount(for: goblin.kind))

        for mineral in goblin.stats.rollDrops(using: &rng) {
            let pickup = MineralPickupNode(mineral: mineral)
            let offset = CGVector(dx: CGFloat.random(in: -18...18, using: &rng), dy: CGFloat.random(in: -12...12, using: &rng))
            pickup.position = goblin.position + offset
            pickup.zPosition = -2
            addChild(pickup)
            pickups.append(pickup)
        }
    }

    private func burstCount(for kind: MonsterKind) -> Int {
        kind.isBoss ? 30 : (kind == .goblinBrute ? 14 : 8)
    }

    // MARK: - Minerales

    private func updatePickups(_ dt: TimeInterval) {
        for pickup in pickups.reversed() {
            let toKnight = knight.position - pickup.position
            let distance = toKnight.length
            if distance < 22 {
                collect(pickup)
            } else if pickup.magnetized || distance < 80 {
                pickup.magnetized = true
                pickup.position = pickup.position + toKnight.normalized * CGFloat(340 * dt)
            }
        }
    }

    private func collect(_ pickup: MineralPickupNode) {
        pickups.removeAll { $0 === pickup }
        pickup.removeFromParent()
        session?.mineralCollected(pickup.mineral)
        let c = Sprites.mineralColors(pickup.mineral).mid
        let color = SKColor(red: CGFloat((c >> 16) & 0xFF) / 255, green: CGFloat((c >> 8) & 0xFF) / 255, blue: CGFloat(c & 0xFF) / 255, alpha: 1)
        floatingText("+1 \(pickup.mineral.name)", at: knight.position + CGVector(dx: 0, dy: 34), color: color, size: 12)
    }

    // MARK: - Fin de ronda

    private func checkRoundEnd(_ dt: TimeInterval) {
        guard spawnQueue.isEmpty, goblins.isEmpty else { return }
        if clearTimer == nil {
            clearTimer = 2.5
            pickups.forEach { $0.magnetized = true }
        }
        clearTimer! -= dt
        if pickups.isEmpty || clearTimer! <= 0 {
            pickups.forEach(collect)
            setRunning(false)
            session?.roundCleared()
        }
    }

    // MARK: - Efectos

    private func slashEffect(direction: CGVector, reach: CGFloat) {
        let path = CGMutablePath()
        let radius = max(20, reach * 0.75)
        path.addArc(center: .zero, radius: radius, startAngle: 1.25, endAngle: -1.25, clockwise: true)
        let arc = SKShapeNode(path: path)
        arc.strokeColor = SKColor(white: 1, alpha: 0.85)
        arc.lineWidth = 4
        arc.lineCap = .square
        arc.position = knight.position
        arc.zRotation = atan2(direction.dy, direction.dx)
        arc.zPosition = 150
        addChild(arc)
        arc.run(.sequence([
            .group([.fadeOut(withDuration: 0.18), .scale(to: 1.15, duration: 0.18)]),
            .removeFromParent(),
        ]))
    }

    private func burst(at point: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let bit = SKSpriteNode(color: Bool.random() ? color : .white, size: CGSize(width: PX, height: PX))
            bit.position = point
            bit.zPosition = 140
            addChild(bit)
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let distance = CGFloat.random(in: 12...34)
            bit.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.3),
                    .fadeOut(withDuration: 0.3),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func floatingText(_ text: String, at point: CGPoint, color: SKColor, size: CGFloat, duration: TimeInterval = 0.7) {
        let node = SKNode()
        node.position = point
        node.zPosition = 200
        let shadow = SKLabelNode(fontNamed: "Menlo-Bold")
        shadow.text = text
        shadow.fontSize = size
        shadow.fontColor = .black
        shadow.position = CGPoint(x: 1.5, y: -1.5)
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.zPosition = 0.1
        node.addChild(shadow)
        node.addChild(label)
        addChild(node)
        node.run(.sequence([
            .group([.moveBy(x: 0, y: 26, duration: duration), .sequence([.wait(forDuration: duration * 0.6), .fadeOut(withDuration: duration * 0.4)])]),
            .removeFromParent(),
        ]))
    }

    // MARK: - Utilidades

    private func clamp(_ p: CGPoint) -> CGPoint {
        let a = arena
        return CGPoint(x: min(a.maxX, max(a.minX, p.x)), y: min(a.maxY, max(a.minY, p.y)))
    }

    /// Lo que está más abajo en pantalla se dibuja delante.
    private func depth(for y: CGFloat) -> CGFloat {
        10 + (1 - y / max(1, size.height)) * 50
    }
}
