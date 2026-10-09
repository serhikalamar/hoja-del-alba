import GameCore
import SpriteKit

/// Lo que la historia decide de un área en este momento (lo calcula `ExploreSession` con GameCore).
struct AreaStoryState {
    /// Casillas que no se pisan ahora (puertas cerradas, escalinata, salidas y bajadas bloqueadas) y su aviso.
    var lockedTiles: [TilePoint: String] = [:]
    /// NPC que se ven y dónde.
    var npcs: [(npc: NPC, at: TilePoint)] = []
    /// "!"/"?" por id de NPC.
    var markers: [String: QuestMarker] = [:]
    var castleOpen = false
}

/// Escena de exploración: el pueblo, el interior de un edificio o un área de campo, con cámara que sigue al héroe,
/// colisiones con el mapa, puertas, salidas `>`, bajadas `e`, aldeanos y enemigos que esperan hasta verte.
/// En el campo los monstruos que no son jefe reaparecen (`FieldRespawn`).
final class ExploreScene: CombatScene {
    weak var session: ExploreSession?

    private(set) var map: AreaMap = Valdehierro.town
    private var progress = TownProgress()
    private var story = AreaStoryState()
    /// Monstruos de campo muertos (vuelven a los 90 s o al volver a entrar).
    private(set) var fieldRespawn = FieldRespawn()
    private var respawnCheck: TimeInterval = 0
    /// Jefes que ya se han presentado en esta visita.
    private var introducedBosses: Set<String> = []
    /// NPC con el que se está hablando (no se repite hasta alejarse).
    private var nearNPC: String?
    private let cam = SKCameraNode()
    private var ground: SKSpriteNode?
    private let props = SKNode()
    private var npcNodes: [(npc: NPC, node: SKSpriteNode, bubble: SKNode, marker: SKNode?)] = []
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

    /// Casilla cerrada por la historia (puerta, escalinata, salida o bajada).
    private func isLocked(_ p: TilePoint) -> Bool { story.lockedTiles[p] != nil }

    private func walkable(_ p: CGPoint) -> Bool {
        let t = tile(at: p)
        guard t.x >= 0, t.y >= 0, t.x < map.width, t.y < map.height else { return false }
        return map.isWalkable(t) && !isLocked(t)
    }

    /// Caja de los pies libre de obstáculos.
    private func free(feet p: CGPoint, halfWidth: CGFloat) -> Bool {
        [CGPoint(x: p.x - halfWidth, y: p.y - 4), CGPoint(x: p.x + halfWidth, y: p.y - 4),
         CGPoint(x: p.x - halfWidth, y: p.y + 4), CGPoint(x: p.x + halfWidth, y: p.y + 4)].allSatisfy(walkable)
    }

    // MARK: - Carga de un área

    /// Carga un área. Sin `story`, se la pide a la sesión (lo que decide la historia de esa área ahora mismo).
    func load(_ map: AreaMap, heroAt start: TilePoint, progress: TownProgress, story: AreaStoryState? = nil) {
        self.map = map
        self.progress = progress
        self.story = story ?? session?.storyState(for: map, progress: progress) ?? AreaStoryState()
        lootContinent = World.continent(map.continentID)
        fieldRespawn.reset()
        introducedBosses.removeAll()
        nearNPC = nil
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
        buildAmbience()
        buildNPCs()
        spawnEnemies()

        let start = center(of: start)
        hero.position = CGPoint(x: start.x, y: start.y + heroFootOffset)
        hero.zPosition = depth(for: start.y)
        onPortal = true
        cam.position = clampedCamera(hero.position)
    }

    /// Actualiza el progreso guardado y la historia (por ejemplo, al abrirse el castillo o aceptar una misión).
    func refresh(progress: TownProgress, story: AreaStoryState) {
        let castleChanged = story.castleOpen != self.story.castleOpen
        self.progress = progress
        self.story = story
        if castleChanged { props.removeAllChildren(); buildProps(); buildAmbience() }
        buildNPCs()
    }

    /// Monstruos de campo muertos ahora mismo.
    var fieldDeadIDs: Set<String> { fieldRespawn.deadIDs }

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
            let open = b.style != .castle || story.castleOpen
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
                    let variant = TownArt.treeVariant(map, x, y)   // en el campo, según el área (muertos, pinos nevados…)
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

    // MARK: - Ambiente: luces, humo y agua

    /// Pixeles de arte del mapa (origen arriba-izquierda) a coordenadas de la escena.
    private func scenePoint(artX x: Int, artY y: Int) -> CGPoint {
        CGPoint(x: CGFloat(x) * PX, y: CGFloat(map.height * TownArt.tile - y) * PX)
    }

    private func buildAmbience() {
        // Halos de luz que parpadean (el fuego, rápido; los faroles, casi fijos).
        for light in TownArt.lightSources(map) {
            let glow = makeGlow(radius: CGFloat(light.radius) * PX * 1.3, color: light.color, alpha: 1)
            glow.position = scenePoint(artX: light.x, artY: light.y)
            glow.zPosition = 130
            let speed = light.flame ? 0.12 : 0.6
            // Interiores y noche más luz; de día en la calle, apenas un brillo.
            let base: CGFloat = (map.isInterior ? 0.3 : 0.16) * (light.flame ? 1 : 0.8)
            glow.alpha = base
            let low = base * (light.flame ? 0.75 : 0.92)
            glow.run(.sequence([
                .wait(forDuration: Double.random(in: 0..<0.5)),
                .repeatForever(.sequence([
                    .group([.scale(to: 1.05, duration: speed), .fadeAlpha(to: low, duration: speed)]),
                    .group([.scale(to: 0.97, duration: speed * 1.3), .fadeAlpha(to: base, duration: speed * 1.3)]),
                ])),
            ]))
            props.addChild(glow)
        }
        // Humo de las chimeneas.
        let smoke = (0..<8).map { f in ArtCache.texture("town.smoke.\(f)", grid: { TownArt.smoke(frame: f) }) }
        for mouth in TownArt.chimneyMouths(map) {
            let node = SKSpriteNode(texture: smoke[0])
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            node.size = CGSize(width: smoke[0].size().width * PX, height: smoke[0].size().height * PX)
            node.position = scenePoint(artX: mouth.x, artY: mouth.y)
            node.zPosition = 120
            node.run(.sequence([.wait(forDuration: Double.random(in: 0..<0.8)), .repeatForever(.animate(with: smoke, timePerFrame: 0.14))]))
            props.addChild(node)
        }
        // Agua de las fuentes.
        let water = (0..<4).map { f in ArtCache.texture("town.fountain.\(f)", grid: { TownArt.fountainSparkle(frame: f) }) }
        for c in TownArt.fountainCenters(map) {
            let node = SKSpriteNode(texture: water[0])
            node.size = CGSize(width: water[0].size().width * PX, height: water[0].size().height * PX)
            let p = scenePoint(artX: c.0, artY: c.1)
            node.position = p
            node.zPosition = depth(for: p.y - 20) + 0.5
            node.run(.repeatForever(.animate(with: water, timePerFrame: 0.12)))
            props.addChild(node)
        }
        // Llamas de las hogueras y braseros del campo (violetas en el campamento del Eclipse).
        let flames = [false, true].map { violet in
            (0..<6).map { f in ArtCache.texture("field.flame.\(violet).\(f)", grid: { TownArt.campfireFlame(frame: f, violet: violet) }) }
        }
        for spot in TownArt.campfireSpots(map) {
            let frames = flames[spot.violet ? 1 : 0]
            let node = SKSpriteNode(texture: frames[0])
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            node.size = CGSize(width: frames[0].size().width * PX, height: frames[0].size().height * PX)
            let p = scenePoint(artX: spot.x, artY: spot.y)
            node.position = p
            node.zPosition = depth(for: p.y) + 0.5
            node.run(.sequence([.wait(forDuration: Double.random(in: 0..<0.5)), .repeatForever(.animate(with: frames, timePerFrame: 0.1))]))
            props.addChild(node)
        }
        buildParticles()
    }

    /// Ambiente del campo: niebla baja en la abadía, ceniza y brasas en los trigales quemados, hojas en Robleda,
    /// nieve en el Paso (`TownArt.ambientEffects`). Cada partícula cruza su rectángulo, se desvanece y vuelve a empezar.
    private func buildParticles() {
        for effect in TownArt.ambientEffects(map) {
            let textures = (0..<3).map { v in
                ArtCache.texture("ambient.\(effect.kind.rawValue).\(v)", grid: { TownArt.ambientTexture(effect.kind, variant: v) })
            }
            for i in 0..<effect.count {
                let texture = textures[i % textures.count]
                let node = SKSpriteNode(texture: texture)
                node.size = CGSize(width: texture.size().width * PX, height: texture.size().height * PX)
                node.zPosition = effect.groundLevel ? -50 : 125
                node.alpha = 0
                let place = SKAction.run { [weak self, weak node] in
                    guard let self, let node else { return }
                    let x = effect.x + Int.random(in: 0..<max(1, effect.width))
                    let y = effect.y + Int.random(in: 0..<max(1, effect.height))
                    node.position = self.scenePoint(artX: x, artY: y)
                }
                let d = effect.duration * Double.random(in: 0.8...1.2)
                let move = SKAction.moveBy(x: CGFloat(effect.dx) * PX, y: -CGFloat(effect.dy) * PX, duration: d)
                let fade = SKAction.sequence([.fadeAlpha(to: effect.alpha, duration: d * 0.3), .wait(forDuration: d * 0.4), .fadeOut(withDuration: d * 0.3)])
                node.run(.sequence([.wait(forDuration: Double.random(in: 0..<effect.duration)),
                                    .repeatForever(.sequence([place, .group([move, fade])]))]))
                props.addChild(node)
            }
        }
    }

    // MARK: - Aldeanos

    private func buildNPCs() {
        npcNodes.forEach { $0.node.removeFromParent() }
        npcNodes.removeAll()
        for (npc, spot) in story.npcs {
            // Misma escala y tamaño de pixel que el héroe (chibi dibujado con HeroArt).
            let chibi = NPCLooks.look(npc.look)
            let textures = chibi.map(NPCLooks.idleTextures) ?? Art.npcTextures(npc.look)
            let size = textures[0].size()
            let node = SKSpriteNode(texture: textures[0], size: CGSize(width: size.width * PX, height: size.height * PX))
            let c = center(of: spot)
            let footOffset: CGFloat = chibi == nil ? 6 : 8
            node.position = CGPoint(x: c.x, y: c.y + node.size.height / 2 - footOffset)
            node.zPosition = depth(for: c.y)
            node.addChild(makeShadow(width: chibi == nil ? 26 : 40, yOffset: -node.size.height / 2 + footOffset - 2))
            node.run(.repeatForever(.animate(with: textures, timePerFrame: 0.45)))
            if npc.role == .princess { node.xScale = -1 }
            let bubble = speechBubble(bubbleText(npc))
            bubble.position = CGPoint(x: 0, y: node.size.height / 2 + 18)
            bubble.zPosition = 300
            bubble.alpha = 0
            node.addChild(bubble)
            if npc.role == .princess { bubble.xScale = -1 }
            var markerNode: SKNode?
            if let marker = story.markers[npc.id] {
                let m = questMarker(marker)
                m.position = CGPoint(x: 0, y: node.size.height / 2 + 6)
                m.zPosition = 301
                if npc.role == .princess { m.xScale = -1 }
                node.addChild(m)
                markerNode = m
            }
            addChild(node)
            npcNodes.append((npc, node, bubble, markerNode))
        }
    }

    private func isRescued(_ npc: NPC) -> Bool {
        npc.role == .princess ? progress.princessRescued : progress.rescued.contains(npc.id)
    }

    private func bubbleText(_ npc: NPC) -> String {
        switch npc.role {
        case .villager, .princess: isRescued(npc) ? "¡Gracias!" : npc.plea
        case .questGiver, .clue: npc.plea
        }
    }

    /// "!" o "?" dorado con contorno sobre la cabeza (`Sprites.questMarker`), flotando suavemente.
    private func questMarker(_ marker: QuestMarker) -> SKNode {
        let key = marker == .offer ? "questMarker.offer" : "questMarker.turnIn"
        let texture = Art.gridTexture(key, Sprites.questMarker(marker))
        let node = SKSpriteNode(texture: texture, size: CGSize(width: texture.size().width * PX, height: texture.size().height * PX))
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        let up = SKAction.moveBy(x: 0, y: 4, duration: 0.6), down = SKAction.moveBy(x: 0, y: -4, duration: 0.6)
        up.timingMode = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        node.run(.repeatForever(.sequence([up, down])))
        return node
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
            spawnEnemy(spawn)
        }
    }

    @discardableResult
    private func spawnEnemy(_ spawn: Spawn) -> EnemyNode? {
        guard let definition = Bestiary.enemy(spawn.enemyID) else { return nil }
        // Historia: los jefes con su ajuste propio (`EnemyDefinition.forStory`, balance B1).
        let enemy = EnemyNode(definition: definition.forStory, level: map.level(at: spawn.position))
        enemy.spawnID = spawn.id
        enemy.isAggro = false
        enemy.hasEntered = true
        let c = center(of: spawn.position)
        enemy.position = CGPoint(x: c.x, y: c.y + enemy.size.height / 2 - 6)
        enemy.zPosition = depth(for: c.y)
        addChild(enemy)
        enemies.append(enemy)
        return enemy
    }

    /// Monstruos de campo que vuelven (90 s después de morir, lejos del héroe).
    private func updateRespawns(_ dt: TimeInterval) {
        guard map.isField else { return }
        respawnCheck -= dt
        guard respawnCheck <= 0 else { return }
        respawnCheck = 1
        for spawn in fieldRespawn.due(in: map, now: elapsed, hero: heroFeetTile()) {
            guard let enemy = spawnEnemy(spawn) else { continue }
            enemy.alpha = 0
            enemy.run(.fadeIn(withDuration: 0.6))
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
        if enemy.definition.isBoss {
            shake(intensity: 5)
            if let id = enemy.spawnID, introducedBosses.insert(id).inserted { session?.bossSpotted(enemy.definition) }
        }
    }

    override func enemyDied(_ enemy: EnemyNode) {
        guard let id = enemy.spawnID, let spawn = map.spawns.first(where: { $0.id == id }) else { return }
        if map.isPermanent(spawn) {
            progress.killedSpawns.insert(id)
        } else {
            fieldRespawn.died(id, at: elapsed)
        }
        session?.spawnKilled(id, enemy: enemy.definition, at: spawn.position)
    }

    override func blocksShot(at point: CGPoint) -> Bool {
        let t = tile(at: point)
        guard t.x >= 0, t.y >= 0, t.x < map.width, t.y < map.height else { return true }
        if let building = map.building(at: t) { return !building.doorTiles.contains(t) }
        switch map.tile(t.x, t.y) {
        case .wall, .interiorWall, .cliff, .rock, .pillar: return true
        default: return false
        }
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
        // Casilla cerrada por la historia (castillo, casas sin interior, salidas y bajadas bloqueadas): avisa.
        let foot = CGPoint(x: new.x, y: new.y - offset)
        let corners = [foot, CGPoint(x: foot.x - 11, y: foot.y - 4), CGPoint(x: foot.x + 11, y: foot.y - 4),
                       CGPoint(x: foot.x - 11, y: foot.y + 6), CGPoint(x: foot.x + 11, y: foot.y + 6), CGPoint(x: foot.x, y: foot.y + 6)]
        if lockedCooldown <= 0, let locked = corners.map(tile(at:)).first(where: isLocked), let message = story.lockedTiles[locked] {
            lockedCooldown = 2.5
            session?.lockedTileTouched(message)
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
        updateRespawns(dt)
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

    /// En los interiores solo se habla con la sala despejada (salvo con quien ya está rescatado); fuera, siempre.
    private func canTalk(to npc: NPC, cleared: Bool) -> Bool {
        guard map.isInterior else { return true }
        if npc.role == .clue { return cleared }
        return cleared || isRescued(npc)
    }

    private func updateNPCs() {
        let cleared = progress.isCleared(map)
        var closest: (npc: NPC, distance: CGFloat)?
        for entry in npcNodes {
            let distance = entry.node.position.distance(to: hero.position)
            let near = distance < 220
            entry.bubble.alpha = near && entry.marker == nil ? 1 : 0
            if distance < 80, canTalk(to: entry.npc, cleared: cleared), distance < (closest?.distance ?? .infinity) {
                closest = (entry.npc, distance)
            }
        }
        // Se habla al llegar; para volver a hablar hay que alejarse y volver.
        if let npc = closest?.npc {
            if nearNPC != npc.id {
                nearNPC = npc.id
                session?.npcReached(npc)
            }
        } else if let id = nearNPC, let entry = npcNodes.first(where: { $0.npc.id == id }),
                  entry.node.position.distance(to: hero.position) > 110 {
            nearNPC = nil
        } else if nearNPC != nil, !npcNodes.contains(where: { $0.npc.id == nearNPC }) {
            nearNPC = nil
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
        } else if let exit = map.exit(at: t) {
            touching = true
            if !onPortal { session?.areaExitTouched(exit) }
        } else if let entrance = map.dungeonEntrance(at: t) {
            touching = true
            if !onPortal { session?.dungeonEntranceTouched(entrance) }
        }
        onPortal = touching
    }

    /// Fundido a negro para cambiar de área.
    /// Fundido a negro: `midway` con la pantalla en negro y `then` al terminar (lo que pausa la escena,
    /// como un diálogo, va en `then`: con la escena en pausa el fundido se quedaría en negro).
    func fade(_ midway: @escaping () -> Void, then: (() -> Void)? = nil) {
        // Sin vista (banco de pruebas) las acciones no corren: se cambia de área al momento.
        guard view != nil, let fade = cam.childNode(withName: "fade") else { midway(); then?(); return }
        fade.removeAllActions()
        fade.run(.sequence([
            .fadeIn(withDuration: 0.18),
            .run(midway),
            .fadeOut(withDuration: 0.25),
            .run { then?() },
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
