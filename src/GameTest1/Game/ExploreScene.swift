import GameCore
import SpriteKit

/// Escena de exploración: el pueblo o el interior de un edificio, con cámara que sigue al héroe,
/// colisiones con el mapa, puertas, aldeanos y enemigos que esperan hasta verte.
final class ExploreScene: CombatScene {
    weak var session: ExploreSession?

    private(set) var map: AreaMap = Valdehierro.town
    private var progress = TownProgress()
    private let cam = SKCameraNode()
    private var ground: SKSpriteNode?
    private let props = SKNode()
    private var npcNodes: [(npc: NPC, node: SKSpriteNode, bubble: SKNode)] = []
    private var onPortal = true
    private var lockedCooldown: TimeInterval = 0

    static let tileSize = CGFloat(TownArt.tile) * PX

    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = .zero
        backgroundColor = SKColor(rgb: 0x14142B)
        addChild(cam)
        camera = cam
        addChild(props)
        addChild(hero)
        let fade = SKSpriteNode(color: .black, size: CGSize(width: 4000, height: 4000))
        fade.name = "fade"
        fade.zPosition = 1000
        fade.alpha = 0
        cam.addChild(fade)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    // MARK: - Coordenadas

    private var T: CGFloat { Self.tileSize }

    override var worldHeight: CGFloat { CGFloat(map.height) * T }
    override var shakeNode: SKNode? { cam }

    /// Centro de una casilla en coordenadas de la escena (Y hacia arriba).
    func center(of p: TilePoint) -> CGPoint {
        CGPoint(x: (CGFloat(p.x) + 0.5) * T, y: (CGFloat(map.height - 1 - p.y) + 0.5) * T)
    }

    func tile(at point: CGPoint) -> TilePoint {
        TilePoint(Int(floor(point.x / T)), map.height - 1 - Int(floor(point.y / T)))
    }

    private var heroFootOffset: CGFloat { hero.size.height / 2 - 8 }

    private func feet(of node: SKSpriteNode, offset: CGFloat) -> CGPoint {
        CGPoint(x: node.position.x, y: node.position.y - offset)
    }

    private func isLockedDoor(_ p: TilePoint) -> Bool {
        guard !map.isInterior, let b = map.building(at: p), b.doorTiles.contains(p) else { return false }
        return b.interiorID == nil || (b.style == .castle && !progress.castleOpen)
    }

    private func walkable(_ p: CGPoint) -> Bool {
        let t = tile(at: p)
        guard t.x >= 0, t.y >= 0, t.x < map.width, t.y < map.height else { return false }
        return map.isWalkable(t) && !isLockedDoor(t)
    }

    /// Caja de los pies libre de obstáculos.
    private func free(feet p: CGPoint, halfWidth: CGFloat) -> Bool {
        [CGPoint(x: p.x - halfWidth, y: p.y - 4), CGPoint(x: p.x + halfWidth, y: p.y - 4),
         CGPoint(x: p.x - halfWidth, y: p.y + 4), CGPoint(x: p.x + halfWidth, y: p.y + 4)].allSatisfy(walkable)
    }

    // MARK: - Carga de un área

    func load(_ map: AreaMap, heroAt start: TilePoint, progress: TownProgress) {
        self.map = map
        self.progress = progress
        clearCombat()
        props.removeAllChildren()
        ground?.removeFromParent()

        let groundImage = ArtCache.image("area.\(map.id)", grid: { TownArt.ground(map) })
        let groundNode = SKSpriteNode(texture: ArtCache.texture(fromImage: groundImage))
        groundNode.anchorPoint = .zero
        groundNode.size = CGSize(width: CGFloat(groundImage.width) * PX, height: CGFloat(groundImage.height) * PX)
        groundNode.zPosition = -100
        addChild(groundNode)
        ground = groundNode

        buildProps()
        buildNPCs()
        spawnEnemies()

        let start = center(of: start)
        hero.position = CGPoint(x: start.x, y: start.y + heroFootOffset)
        hero.zPosition = depth(for: start.y)
        onPortal = true
        cam.position = clampedCamera(hero.position)
    }

    /// Actualiza el progreso guardado (por ejemplo, al abrirse el castillo).
    func refresh(progress: TownProgress) {
        let castleChanged = progress.castleOpen != self.progress.castleOpen
        self.progress = progress
        if castleChanged { props.removeAllChildren(); buildProps() }
        buildNPCs()
    }

    private func addProp(_ grid: @autoclosure () -> PixelGrid, key: String, bottomLeft: CGPoint, depthY: CGFloat) {
        let image = ArtCache.image(key, grid: { grid() })
        let node = SKSpriteNode(texture: ArtCache.texture(fromImage: image))
        node.anchorPoint = .zero
        node.size = CGSize(width: CGFloat(image.width) * PX, height: CGFloat(image.height) * PX)
        node.position = bottomLeft
        node.zPosition = depth(for: depthY)
        props.addChild(node)
    }

    private func buildProps() {
        for b in map.buildings {
            let open = b.style != .castle || progress.castleOpen
            let bottom = CGFloat(map.height - b.y - b.height) * T
            addProp(TownArt.building(b, open: open), key: "building.\(b.id).\(open)",
                    bottomLeft: CGPoint(x: CGFloat(b.x) * T - PX, y: bottom - PX), depthY: bottom + 2)
        }
        for y in 0..<map.height {
            for x in 0..<map.width {
                let tile = map.tile(x, y)
                guard tile == .tree || tile == .lamp else { continue }
                let c = center(of: TilePoint(x, y))
                let bottom = c.y - T / 2
                if tile == .tree {
                    let variant = (x * 7 + y) % 3
                    let grid = TownArt.tree(variant: variant)
                    addProp(TownArt.tree(variant: variant), key: "tree.\(variant)",
                            bottomLeft: CGPoint(x: c.x - CGFloat(grid.width) * PX / 2, y: bottom), depthY: bottom + 4)
                } else {
                    addProp(TownArt.lamp, key: "lamp",
                            bottomLeft: CGPoint(x: c.x - CGFloat(TownArt.lamp.width) * PX / 2, y: bottom + 6), depthY: bottom + 6)
                }
            }
        }
    }

    // MARK: - Aldeanos

    /// Aldeanos ya rescatados que vuelven a la plaza.
    private static let plazaSpots: [String: TilePoint] = [
        "marta": TilePoint(17, 15), "elena": TilePoint(26, 15), "tomas": TilePoint(17, 18),
        "anselmo": TilePoint(26, 18), "bruno": TilePoint(19, 21), "iris": TilePoint(24, 21),
        "princess": TilePoint(22, 10),
    ]

    private func buildNPCs() {
        npcNodes.forEach { $0.node.removeFromParent() }
        npcNodes.removeAll()
        var list: [(NPC, TilePoint)] = []
        if map.isInterior {
            for npc in map.npcs where !isRescued(npc) { list.append((npc, npc.position)) }
        } else {
            for npc in Valdehierro.interiors.flatMap(\.npcs) where isRescued(npc) {
                if let spot = Self.plazaSpots[npc.id] { list.append((npc, spot)) }
            }
        }
        for (npc, spot) in list {
            let textures = Art.npcTextures(npc.look)
            let size = textures[0].size()
            let node = SKSpriteNode(texture: textures[0], size: CGSize(width: size.width * PX * 1.3, height: size.height * PX * 1.3))
            let c = center(of: spot)
            node.position = CGPoint(x: c.x, y: c.y + node.size.height / 2 - 8)
            node.zPosition = depth(for: c.y)
            node.addChild(makeShadow(width: 26, yOffset: -node.size.height / 2 + 4))
            node.run(.repeatForever(.animate(with: textures, timePerFrame: 0.5)))
            if npc.role == .princess { node.xScale = -1 }
            let bubble = speechBubble(isRescued(npc) ? "¡Gracias!" : npc.plea)
            bubble.position = CGPoint(x: 0, y: node.size.height / 2 + 18)
            bubble.zPosition = 300
            bubble.alpha = 0
            node.addChild(bubble)
            if npc.role == .princess { bubble.xScale = -1 }
            addChild(node)
            npcNodes.append((npc, node, bubble))
        }
    }

    private func isRescued(_ npc: NPC) -> Bool {
        npc.role == .princess ? progress.princessRescued : progress.rescued.contains(npc.id)
    }

    private func speechBubble(_ text: String) -> SKNode {
        let node = SKNode()
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 11
        label.fontColor = SKColor(rgb: 0x1A1C2C)
        label.verticalAlignmentMode = .center
        let width = label.frame.width + 14
        let box = SKShapeNode(rect: CGRect(x: -width / 2, y: -11, width: width, height: 22), cornerRadius: 3)
        box.fillColor = SKColor(rgb: 0xF4ECD8)
        box.strokeColor = SKColor(rgb: 0x1A1C2C)
        box.lineWidth = 2
        node.addChild(box)
        label.zPosition = 0.1
        node.addChild(label)
        return node
    }

    // MARK: - Enemigos

    private func spawnEnemies() {
        for spawn in map.spawns where !progress.killedSpawns.contains(spawn.id) {
            guard let definition = Bestiary.enemy(spawn.enemyID) else { continue }
            let enemy = EnemyNode(definition: definition, level: map.level(at: spawn.position))
            enemy.spawnID = spawn.id
            enemy.isAggro = false
            enemy.hasEntered = true
            let c = center(of: spawn.position)
            enemy.position = CGPoint(x: c.x, y: c.y + enemy.size.height / 2 - 6)
            enemy.zPosition = depth(for: c.y)
            addChild(enemy)
            enemies.append(enemy)
        }
    }

    override func isActive(_ enemy: EnemyNode) -> Bool { enemy.isAggro }

    private func updateAggro() {
        let heroZone = map.zone(at: heroFeetTile())?.id
        for enemy in enemies where !enemy.isAggro && !enemy.isDying {
            let sight: CGFloat = enemy.definition.behavior == .ranged ? 300 : 240
            let distance = enemy.position.distance(to: hero.position)
            // En el pueblo no ven a través de muros: solo si estás en su zona o muy cerca.
            let enemyZone = map.zone(at: tile(at: CGPoint(x: enemy.position.x, y: enemy.position.y - enemy.size.height / 2 + 6)))?.id
            let sameZone = map.isInterior || enemyZone == heroZone || distance < 110
            guard (distance < sight && sameZone) || enemy.hp < enemy.maxHP else { continue }
            alert(enemy)
            // Avisa a la manada cercana.
            for other in enemies where !other.isAggro && other.position.distance(to: enemy.position) < 170 {
                alert(other)
            }
        }
    }

    private func alert(_ enemy: EnemyNode) {
        guard !enemy.isAggro else { return }
        enemy.isAggro = true
        floatingText("!", at: enemy.position + CGVector(dx: 0, dy: enemy.size.height / 2 + 6), color: SKColor(rgb: 0xFF5050), size: 18)
        if enemy.definition.isBoss { shake(intensity: 5) }
    }

    override func enemyDied(_ enemy: EnemyNode) {
        guard let id = enemy.spawnID else { return }
        progress.killedSpawns.insert(id)
        session?.spawnKilled(id, enemy: enemy.definition, at: tile(at: enemy.position))
    }

    override func constrain(_ enemy: EnemyNode, previous: CGPoint) {
        let offset = enemy.size.height / 2 - 6
        let half = min(14, enemy.radius * 0.6)
        guard !free(feet: feet(of: enemy, offset: offset), halfWidth: half) else { return }
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

    // MARK: - Héroe

    override func moveHero(from old: CGPoint, to new: CGPoint) -> CGPoint {
        let offset = heroFootOffset
        func ok(_ p: CGPoint) -> Bool { free(feet: CGPoint(x: p.x, y: p.y - offset), halfWidth: 11) }
        if ok(new) { return new }
        // Puerta cerrada (castillo, casas sin interior): avisa.
        let foot = CGPoint(x: new.x, y: new.y - offset)
        let corners = [CGPoint(x: foot.x - 11, y: foot.y + 6), CGPoint(x: foot.x + 11, y: foot.y + 6), CGPoint(x: foot.x, y: foot.y + 6)]
        if lockedCooldown <= 0, let door = corners.map(tile(at:)).first(where: isLockedDoor) {
            lockedCooldown = 2.5
            session?.lockedDoorTouched(map.building(at: door))
        }
        let slideX = CGPoint(x: new.x, y: old.y), slideY = CGPoint(x: old.x, y: new.y)
        if ok(slideX) { return slideX }
        if ok(slideY) { return slideY }
        return old
    }

    // MARK: - Bucle

    override func update(_ currentTime: TimeInterval) {
        let dt = frameDelta(currentTime)
        guard running, dt > 0 else { return }
        lockedCooldown -= dt
        updateAggro()
        updateCombat(dt)
        guard running else { return }
        // Fuera de combate se recupera vida poco a poco.
        if !enemies.contains(where: \.isAggro), hp < stats.maxHP {
            hp = min(stats.maxHP, hp + stats.maxHP * 0.04 * dt)
            reportHP()
        }
        updateCamera(dt)
        updateNPCs()
        checkPortals()
    }

    private func clampedCamera(_ target: CGPoint) -> CGPoint {
        let worldW = CGFloat(map.width) * T, worldH = worldHeight
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

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        cam.position = clampedCamera(hero.position)
    }

    private func updateNPCs() {
        let cleared = progress.isCleared(map) || map.spawns.allSatisfy { progress.killedSpawns.contains($0.id) }
        for entry in npcNodes {
            let distance = entry.node.position.distance(to: hero.position)
            let near = distance < 220
            entry.bubble.alpha = near ? 1 : 0
            if distance < 80, cleared || isRescued(entry.npc) {
                session?.npcReached(entry.npc)
            }
        }
    }

    private func checkPortals() {
        let t = tile(at: CGPoint(x: hero.position.x, y: hero.position.y - heroFootOffset))
        var touching = false
        if map.isInterior {
            if map.tile(t.x, t.y) == .exit {
                touching = true
                if !onPortal { session?.exitTouched() }
            }
        } else if let b = map.building(at: t), b.doorTiles.contains(t) {
            touching = true
            if !onPortal { session?.doorTouched(b) }
        }
        onPortal = touching
    }

    /// Fundido a negro para cambiar de área.
    func fade(_ midway: @escaping () -> Void) {
        guard let fade = cam.childNode(withName: "fade") else { midway(); return }
        fade.removeAllActions()
        fade.run(.sequence([
            .fadeIn(withDuration: 0.18),
            .run(midway),
            .fadeOut(withDuration: 0.25),
        ]))
    }

    /// Volver a la vida con la vida llena (la posición la decide `load`).
    func revive() {
        hero.removeAllActions()
        hero.alpha = 1
        hero.zRotation = 0
        hero.colorBlendFactor = 0
        hp = stats.maxHP
        reportHP()
    }

    func heroFeetTile() -> TilePoint {
        tile(at: CGPoint(x: hero.position.x, y: hero.position.y - heroFootOffset))
    }
}
