import GameCore
import SpriteKit

/// Modo arena: oleadas infinitas en una mazmorra más grande que la pantalla. La cámara sigue al héroe,
/// los monstruos salen por puertas y rejillas y rodean los obstáculos para llegar hasta él.
/// Cada 5 oleadas se baja un piso (`Arena.floor`).
final class BattleScene: CombatScene {
    weak var session: BattleSession?

    private(set) var dungeon: DungeonFloor = Arena.floor(wave: 1)
    private var builtFloorID: String?
    private let cam = SKCameraNode()
    private var ground: SKSpriteNode?
    private let props = SKNode()
    private let vignette = SKSpriteNode()

    private var spawnQueue: [String] = []
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1
    private var clearTimer: TimeInterval?
    /// Nivel de dificultad de los enemigos de la oleada.
    private var enemyLevel = 1

    /// Distancia (en casillas) de cada casilla al héroe, para que los enemigos rodeen los obstáculos.
    private var flow: [Int] = []
    private var flowOrigin: TilePoint?

    static let tileSize = CGFloat(DungeonArt.tile) * PX

    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = .zero
        backgroundColor = SKColor(rgb: DungeonArt.voidColor(dungeon.theme))
        addChild(cam)
        camera = cam
        addChild(props)
        addChild(hero)
        vignette.zPosition = 450
        cam.addChild(vignette)
        buildFloor()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    // MARK: - Coordenadas

    private var T: CGFloat { Self.tileSize }

    override var worldHeight: CGFloat { CGFloat(dungeon.height) * T }
    override var shakeNode: SKNode? { cam }

    /// Centro de una casilla en coordenadas de la escena (Y hacia arriba).
    func center(of p: TilePoint) -> CGPoint {
        CGPoint(x: (CGFloat(p.x) + 0.5) * T, y: (CGFloat(dungeon.height - 1 - p.y) + 0.5) * T)
    }

    func tile(at point: CGPoint) -> TilePoint {
        TilePoint(Int((point.x / T).rounded(.down)), dungeon.height - 1 - Int((point.y / T).rounded(.down)))
    }

    private var heroFootOffset: CGFloat { hero.size.height / 2 - 8 }

    private func feetOffset(_ enemy: EnemyNode) -> CGFloat { enemy.size.height / 2 - 6 }

    private func walkable(_ p: CGPoint) -> Bool { dungeon.isWalkable(tile(at: p)) }

    /// Caja de los pies libre de obstáculos.
    private func free(feet p: CGPoint, halfWidth: CGFloat) -> Bool {
        [CGPoint(x: p.x - halfWidth, y: p.y - 4), CGPoint(x: p.x + halfWidth, y: p.y - 4),
         CGPoint(x: p.x - halfWidth, y: p.y + 4), CGPoint(x: p.x + halfWidth, y: p.y + 4)].allSatisfy(walkable)
    }

    // MARK: - Preparación

    func prepare(floor: DungeonFloor, stats: Stats, hp: Double, look: HeroLook, weapon: Item?, level: Int = 1) {
        prepareHero(stats: stats, hp: hp, look: look, weapon: weapon, level: level)
        guard floor.id != builtFloorID else { return }
        self.dungeon = floor
        buildFloor()
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

    /// Dibuja el piso, coloca la decoración y las luces, y deja al héroe en la salida.
    private func buildFloor() {
        builtFloorID = dungeon.id
        clearCombat()
        props.removeAllChildren()
        ground?.removeFromParent()
        backgroundColor = SKColor(rgb: DungeonArt.voidColor(dungeon.theme))

        let image = ArtCache.image("dungeon.\(dungeon.id)", grid: { DungeonArt.ground(dungeon) })
        let node = SKSpriteNode(texture: ArtCache.texture(fromImage: image))
        node.anchorPoint = .zero
        node.size = CGSize(width: CGFloat(image.width) * PX, height: CGFloat(image.height) * PX)
        node.zPosition = -100
        addChild(node)
        ground = node

        // Capa animada del líquido (ondas, burbujas de lava, motas del abismo).
        let floor = dungeon
        if floor.rows.contains(where: { $0.contains(DungeonTile.liquid.rawValue) }) {
            let frames = (0..<DungeonArt.liquidFrames).map { f in
                ArtCache.texture("dungeon.liquid.\(floor.id).\(f)", grid: { DungeonArt.liquidOverlay(floor, frame: f) })
            }
            let liquid = SKSpriteNode(texture: frames[0])
            liquid.anchorPoint = .zero
            liquid.size = node.size
            liquid.zPosition = -99
            liquid.run(.repeatForever(.animate(with: frames, timePerFrame: 0.25)))
            props.addChild(liquid)
        }

        buildProps()
        flowOrigin = nil

        let start = center(of: dungeon.start)
        hero.position = CGPoint(x: start.x, y: start.y + heroFootOffset)
        hero.zPosition = depth(for: start.y)
        cam.position = clampedCamera(hero.position)
    }

    private func buildProps() {
        let theme = dungeon.theme
        let flames = (0..<DungeonArt.flameFrames).map { frame in
            ArtCache.texture("dungeon.flame.\(theme.rawValue).\(frame)", grid: { DungeonArt.flame(theme: theme, frame: frame) })
        }
        for y in 0..<dungeon.height {
            for x in 0..<dungeon.width {
                let t = dungeon.tile(x, y)
                let c = center(of: TilePoint(x, y))
                let bottom = c.y - T / 2
                let variant = (x * 7 + y * 3) % 4
                // El altar ocupa dos casillas: solo se dibuja desde la de la izquierda.
                let skip = t == .altar && dungeon.tile(x - 1, y) == .altar
                if !skip, let grid = DungeonArt.prop(t, theme: theme, variant: variant) {
                    let image = ArtCache.image("dungeon.prop.\(theme.rawValue).\(t.rawValue).\(variant)", grid: { grid })
                    let node = SKSpriteNode(texture: ArtCache.texture(fromImage: image))
                    node.anchorPoint = CGPoint(x: 0.5, y: 0)
                    node.size = CGSize(width: CGFloat(image.width) * PX, height: CGFloat(image.height) * PX)
                    node.position = CGPoint(x: t == .altar ? c.x + T / 2 : c.x, y: bottom)
                    node.zPosition = depth(for: bottom + 4)
                    props.addChild(node)
                    if t == .brazier { addFlame(flames, at: CGPoint(x: c.x, y: bottom + node.size.height - 6), z: node.zPosition + 0.01) }
                }
                if t == .torch {
                    addFlame(flames, at: CGPoint(x: c.x, y: c.y + 4), z: depth(for: bottom) + 0.01)
                }
            }
        }
    }

    /// Llama animada con un halo que parpadea.
    private func addFlame(_ frames: [SKTexture], at point: CGPoint, z: CGFloat) {
        guard let first = frames.first else { return }
        let flame = SKSpriteNode(texture: first)
        flame.size = CGSize(width: first.size().width * PX, height: first.size().height * PX)
        flame.anchorPoint = CGPoint(x: 0.5, y: 0)
        flame.position = point
        flame.zPosition = z
        let offset = Double.random(in: 0..<0.4, using: &rng)
        flame.run(.sequence([.wait(forDuration: offset), .repeatForever(.animate(with: frames, timePerFrame: 0.11))]))
        props.addChild(flame)

        let glow = makeGlow(radius: 110, color: DungeonArt.lightColor(dungeon.theme), alpha: 0.32)
        glow.position = CGPoint(x: point.x, y: point.y + 8)
        glow.zPosition = 130
        glow.run(.repeatForever(.sequence([
            .group([.scale(to: 1.06, duration: 0.18), .fadeAlpha(to: 0.26, duration: 0.18)]),
            .group([.scale(to: 0.96, duration: 0.23), .fadeAlpha(to: 0.32, duration: 0.23)]),
        ])))
        props.addChild(glow)
    }

    // MARK: - Cámara

    private func clampedCamera(_ target: CGPoint) -> CGPoint {
        let worldW = CGFloat(dungeon.width) * T, worldH = worldHeight
        let halfW = size.width / 2, halfH = size.height / 2
        let x = worldW <= size.width ? worldW / 2 : min(worldW - halfW, max(halfW, target.x))
        let y = worldH <= size.height ? worldH / 2 : min(worldH - halfH, max(halfH, target.y))
        return CGPoint(x: x, y: y)
    }

    private func updateCamera(_ dt: TimeInterval) {
        guard cam.action(forKey: "shake") == nil else { return }
        let target = clampedCamera(hero.position)
        let k = CGFloat(min(1, dt * 8))
        cam.position = CGPoint(x: cam.position.x + (target.x - cam.position.x) * k,
                               y: cam.position.y + (target.y - cam.position.y) * k)
    }

    private var visibleRect: CGRect {
        CGRect(x: cam.position.x - size.width / 2, y: cam.position.y - size.height / 2, width: size.width, height: size.height)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 50, size.height > 50 else { return }
        vignette.texture = Self.vignetteTexture(size: size)
        vignette.size = size
        cam.position = clampedCamera(hero.position)
    }

    /// Oscurece los bordes de la pantalla: da sensación de mazmorra iluminada solo cerca del héroe.
    private static func vignetteTexture(size: CGSize) -> SKTexture {
        let w = 128, h = max(32, Int(128 * size.height / size.width))
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [CGColor(red: 0, green: 0, blue: 0.03, alpha: 0), CGColor(red: 0, green: 0, blue: 0.03, alpha: 0.55)] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: colors, locations: [0.45, 1])!
        let c = CGPoint(x: CGFloat(w) / 2, y: CGFloat(h) / 2)
        ctx.scaleBy(x: 1, y: CGFloat(h) / CGFloat(w))
        ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: c.x, y: c.x), startRadius: 0,
                               endCenter: CGPoint(x: c.x, y: c.x), endRadius: CGFloat(w) * 0.62, options: .drawsAfterEndLocation)
        return SKTexture(cgImage: ctx.makeImage()!)
    }

    // MARK: - Bucle

    override func update(_ currentTime: TimeInterval) {
        let dt = frameDelta(currentTime)
        guard running, dt > 0 else { return }
        updateFlow()
        updateSpawning(dt)
        updateCombat(dt)
        guard running else { return }
        updateCamera(dt)
        checkRoundEnd(dt)
    }

    // MARK: - Movimiento por el mapa

    override func moveHero(from old: CGPoint, to new: CGPoint) -> CGPoint {
        let offset = heroFootOffset
        func ok(_ p: CGPoint) -> Bool { free(feet: CGPoint(x: p.x, y: p.y - offset), halfWidth: 11) }
        if ok(new) { return new }
        let slideX = CGPoint(x: new.x, y: old.y), slideY = CGPoint(x: old.x, y: new.y)
        if ok(slideX) { return slideX }
        if ok(slideY) { return slideY }
        // Esquinas: si solo roza el borde de un pilar o de una pared, se le empuja hacia el hueco.
        let dx = new.x - old.x, dy = new.y - old.y
        let speed = max(abs(dx), abs(dy))
        for nudge in stride(from: CGFloat(2), through: 12, by: 2) {
            if abs(dy) >= abs(dx) {
                for side in [CGFloat(1), -1] where ok(CGPoint(x: old.x + side * nudge, y: new.y)) {
                    return CGPoint(x: old.x + side * min(nudge, speed), y: old.y)
                }
            } else {
                for side in [CGFloat(1), -1] where ok(CGPoint(x: new.x, y: old.y + side * nudge)) {
                    return CGPoint(x: old.x, y: old.y + side * min(nudge, speed))
                }
            }
        }
        return old
    }

    override func blocksShot(at point: CGPoint) -> Bool {
        let t = tile(at: point)
        guard t.x >= 0, t.y >= 0, t.x < dungeon.width, t.y < dungeon.height else { return true }
        return dungeon.tile(t).isWall
    }

    override func constrain(_ enemy: EnemyNode, previous: CGPoint) {
        let offset = feetOffset(enemy)
        let half = min(14, enemy.radius * 0.6)
        let feet = CGPoint(x: enemy.position.x, y: enemy.position.y - offset)
        guard !free(feet: feet, halfWidth: half) else { return }
        let tryX = CGPoint(x: enemy.position.x, y: previous.y - offset)
        let tryY = CGPoint(x: previous.x, y: enemy.position.y - offset)
        if free(feet: tryX, halfWidth: half) {
            enemy.position.y = previous.y
        } else if free(feet: tryY, halfWidth: half) {
            enemy.position.x = previous.x
        } else {
            enemy.position = previous
        }
    }

    /// Recalcula las distancias al héroe cuando cambia de casilla (búsqueda en anchura, 8 direcciones).
    private func updateFlow() {
        let origin = tile(at: CGPoint(x: hero.position.x, y: hero.position.y - heroFootOffset))
        guard origin != flowOrigin, dungeon.isWalkable(origin) else { return }
        flowOrigin = origin
        let w = dungeon.width, h = dungeon.height
        flow = Array(repeating: Int.max, count: w * h)
        flow[origin.y * w + origin.x] = 0
        var queue = [origin]
        var head = 0
        while head < queue.count {
            let p = queue[head]
            head += 1
            let d = flow[p.y * w + p.x]
            for (dx, dy) in Self.directions {
                let n = TilePoint(p.x + dx, p.y + dy)
                guard n.x >= 0, n.y >= 0, n.x < w, n.y < h, flow[n.y * w + n.x] == Int.max, dungeon.isWalkable(n) else { continue }
                // Sin cortar esquinas en diagonal.
                if dx != 0 && dy != 0 && (!dungeon.isWalkable(TilePoint(p.x + dx, p.y)) || !dungeon.isWalkable(TilePoint(p.x, p.y + dy))) { continue }
                flow[n.y * w + n.x] = d + 1
                queue.append(n)
            }
        }
    }

    private static let directions = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]

    /// ¿Se ve al héroe en línea recta, sin paredes ni obstáculos en medio?
    private func clearPath(from a: CGPoint, to b: CGPoint, halfWidth: CGFloat) -> Bool {
        let distance = a.distance(to: b)
        let steps = Int(distance / (T * 0.4)) + 1
        let side = CGVector(dx: -(b.y - a.y), dy: b.x - a.x).normalized * halfWidth
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let p = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
            if !walkable(p + side) || !walkable(p + side * -1) { return false }
        }
        return true
    }

    override func chaseTarget(for enemy: EnemyNode) -> CGPoint {
        let offset = feetOffset(enemy)
        let feet = CGPoint(x: enemy.position.x, y: enemy.position.y - offset)
        let heroFeet = CGPoint(x: hero.position.x, y: hero.position.y - heroFootOffset)
        let half = min(14, enemy.radius * 0.6)
        if clearPath(from: feet, to: heroFeet, halfWidth: half) || flow.isEmpty { return hero.position }
        // Sigue el camino: la casilla vecina más cercana al héroe.
        let here = tile(at: feet)
        let w = dungeon.width
        var best: TilePoint?
        var bestDistance = here.x >= 0 && here.y >= 0 && here.x < w && here.y < dungeon.height ? flow[here.y * w + here.x] : Int.max
        for (dx, dy) in Self.directions {
            let n = TilePoint(here.x + dx, here.y + dy)
            guard n.x >= 0, n.y >= 0, n.x < w, n.y < dungeon.height else { continue }
            if dx != 0 && dy != 0 && (!dungeon.isWalkable(TilePoint(here.x + dx, here.y)) || !dungeon.isWalkable(TilePoint(here.x, here.y + dy))) { continue }
            let d = flow[n.y * w + n.x]
            if d < bestDistance { bestDistance = d; best = n }
        }
        guard let best else { return hero.position }
        let step = center(of: best)
        let dir = CGVector(dx: step.x - feet.x, dy: step.y - feet.y).normalized
        // Punto muy lejano en esa dirección: así no ataca ni dispara a través de paredes, solo camina.
        let reach: CGFloat = 4000
        return CGPoint(x: enemy.position.x + dir.dx * reach, y: enemy.position.y + dir.dy * reach)
    }

    // MARK: - Oleadas

    override func dropsSpecialPart(_ enemy: EnemyNode) -> Bool {
        session?.bossDropsPart() ?? true
    }

    private func updateSpawning(_ dt: TimeInterval) {
        guard !spawnQueue.isEmpty else { return }
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }
        spawnTimer = spawnInterval
        spawn(spawnQueue.removeFirst())
    }

    /// Entrada de monstruos para el siguiente: mejor una que no se vea pero que no esté lejísimos.
    private func pickSpawnPoint() -> TilePoint {
        let points = dungeon.spawnPoints
        guard !points.isEmpty else { return dungeon.start }
        let view = visibleRect.insetBy(dx: -T, dy: -T)
        let ranked = points
            .map { (point: $0, distance: center(of: $0).distance(to: hero.position)) }
            .sorted { $0.distance < $1.distance }
        let hidden = ranked.filter { !view.contains(center(of: $0.point)) }
        let pool = hidden.isEmpty ? Array(ranked.suffix(3)) : Array(hidden.prefix(4))
        return pool[Int.random(in: 0..<pool.count, using: &rng)].point
    }

    private func spawn(_ id: String) {
        guard let definition = Bestiary.enemy(id) else { return }
        // Mazmorra de historia (botín de un continente): jefes con su ajuste de historia; la arena, los números base.
        let enemy = EnemyNode(definition: lootContinent != nil ? definition.forStory : definition, level: enemyLevel)
        enemy.hasEntered = true
        let point = definition.isBoss ? dungeon.bossSpawn : pickSpawnPoint()
        let c = center(of: point)
        let jitter = definition.isBoss ? 0 : CGFloat.random(in: -8...8, using: &rng)
        enemy.position = CGPoint(x: c.x + jitter, y: c.y + feetOffset(enemy))
        enemy.zPosition = depth(for: c.y)
        enemy.alpha = 0
        enemy.run(.fadeIn(withDuration: 0.35))
        dust(at: CGPoint(x: c.x, y: c.y - 4))
        if definition.isBoss {
            floatingText("¡\(definition.name.uppercased())!", at: CGPoint(x: cam.position.x, y: cam.position.y + 40),
                         color: SKColor(rgb: 0xFFCD45), size: 22, duration: 2)
            shake(intensity: 6)
        }
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
}
