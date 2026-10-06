import CoreGraphics
import Foundation
import GameCore
import ImageIO
import SpriteKit
import UniformTypeIdentifiers

// Uso: swift run -c release Harness <comando> [opciones]
//   balance           Arena con varios equipos: oleada en la que cae un bot que no compra.
//   town              Simula el flujo del pueblo (entrar, rescatar, castillo, morir) y lo comprueba.
//   sprites           Hojas de sprites: héroes (todas las poses), enemigos, armas, aldeanos.
//   maps              Mapas completos del pueblo y de cada interior.
//   shots             Capturas de la escena: pueblo, interiores y arena.
//   fichas            Regenera las fichas de assets/ a partir de los datos del juego.
// Las imágenes se guardan en tools/Harness/output/.

let outputDir = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("output")
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

func save(_ image: CGImage, _ name: String) {
    let url = outputDir.appendingPathComponent("\(name).png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("  → \(url.path)")
}

func sheet(_ images: [CGImage], columns: Int, cell: Int, scale: Int, _ name: String) {
    let rows = (images.count + columns - 1) / columns
    let w = columns * cell * scale, h = rows * cell * scale
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    ctx.interpolationQuality = .none
    for (i, img) in images.enumerated() {
        let x = (i % columns) * cell * scale + (cell * scale - img.width * scale) / 2
        let y = h - (i / columns + 1) * cell * scale + 2
        ctx.draw(img, in: CGRect(x: x, y: y, width: img.width * scale, height: img.height * scale))
    }
    save(ctx.makeImage()!, name)
}

func tempStore() -> GameStore {
    GameStore(saveStore: SaveStore(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")))
}

/// Perfil con un arma forjada del tier indicado (espada + minerales comunes) y armadura.
func geared(tier: Int, quality: Int, armorTier: Int) -> PlayerProfile {
    var profile = PlayerProfile.newGame()
    let metal = PartMaterial.metals[tier - 1].id, wood = PartMaterial.woods[tier - 1].id
    let recipe = WeaponRecipe(headID: "head.sword.\(metal)", guardID: "guard.straight.\(metal)", gripID: "grip.short.\(wood)",
                              minerals: [.copper: min(8, 2 + tier * 2), .iron: min(4, tier)])
    let weapon = recipe.makeItem(quality: Roulette.segments[quality])
    let armorBP = Catalog.armors.filter { $0.tier <= armorTier }.max { $0.tier < $1.tier }!
    let armor = Catalog.makeShopItem(armorBP, rarity: quality >= 4 ? .epic : (quality >= 3 ? .rare : .common), level: tier * 2)
    profile.inventory += [weapon, armor]
    profile.equip(weapon.id)
    profile.equip(armor.id)
    return profile
}

/// Bot: se acerca al enemigo más cercano y deja que el héroe ataque solo.
func steer(_ scene: CombatScene) -> CGVector {
    let hero = scene.hero.position
    let foes = scene.enemies.filter { !$0.isDying && $0.isAggro }
    guard let target = foes.min(by: { $0.position.distance(to: hero) < $1.position.distance(to: hero) }),
          target.position.distance(to: hero) > 45 else { return .zero }
    return (target.position - hero).normalized
}

/// Juega la arena hasta caer. Devuelve la oleada alcanzada.
func arenaRun(_ profile: PlayerProfile, maxWave: Int = 60) -> Int {
    let store = tempStore()
    store.profile = profile
    store.startArena()
    let s = store.battle!
    var t: TimeInterval = 1
    s.startNextWave()
    for _ in 0..<(60 * 60 * 40) {
        t += 1.0 / 60
        s.joystick = steer(s.scene)
        s.scene.update(t)
        switch s.phase {
        case .intermission, .waveBreak:
            if s.wave >= maxWave { return s.wave }
            s.startNextWave()
        case .defeat: return s.wave
        default: if s.hp <= 0 { s.heroDied() }
        }
    }
    return s.wave
}

func check(_ condition: Bool, _ message: String) {
    print(condition ? "  ✔ \(message)" : "  ✘ \(message)")
    if !condition { failures += 1 }
}
var failures = 0

// MARK: - Comandos

let command = CommandLine.arguments.dropFirst().first ?? "help"

switch command {
case "balance":
    print("Arena (3 partidas por equipo, oleada en la que cae):")
    print("  Inicial:", (0..<3).map { _ in arenaRun(PlayerProfile.newGame()) })
    for (label, tier, quality, armor) in [("T2 Normal", 2, 2, 1), ("T3 Fina", 3, 3, 2), ("T4 Fina", 4, 3, 3),
                                          ("T5 Excelente", 5, 4, 4), ("T6 Excelente", 6, 4, 4), ("T6 Obra maestra", 6, 5, 4)] {
        print("  \(label):", (0..<3).map { _ in arenaRun(geared(tier: tier, quality: quality, armorTier: armor)) })
    }

case "town":
    MainActor.assumeIsolated {
        print("Flujo del pueblo:")
        let store = tempStore()
        store.profile = geared(tier: 3, quality: 3, armorTier: 2)
        store.profile.hasChosenRace = true
        store.startTown()
        let s = store.explore!
        var t: TimeInterval = 1
        func run(_ seconds: Double, joy: CGVector? = nil) {
            for _ in 0..<Int(seconds * 60) { t += 1.0 / 60; s.joystick = joy ?? steer(s.scene); s.scene.update(t) }
        }
        check(s.overlay == .dialog, "empieza con el diálogo de introducción")
        while s.overlay == .dialog { s.advanceDialog() }
        run(2.5, joy: CGVector(dx: 0, dy: 1))
        run(6)
        check(!store.profile.town.killedSpawns.isEmpty, "se pelea al avanzar hacia el mercado (\(store.profile.town.killedSpawns.count) muertos)")

        let bakery = Valdehierro.area("bakery")!
        var town = store.profile.town
        for spawn in bakery.spawns { town.killedSpawns.insert(spawn.id) }
        store.profile.town = town
        s.scene.load(bakery, heroAt: TilePoint(11, 2), progress: store.profile.town)
        run(0.3, joy: .zero)
        check(s.overlay == .dialog && s.dialog?.speaker.hasPrefix("Marta") == true, "al acercarse a Marta empieza su diálogo")
        while s.overlay == .dialog { s.advanceDialog() }
        check(store.profile.town.rescued.contains("marta"), "Marta queda rescatada")

        s.scene.load(Valdehierro.town, heroAt: TilePoint(21, 10), progress: store.profile.town)
        run(1, joy: CGVector(dx: 0, dy: 1))
        check(s.toast?.contains("castillo") == true, "la puerta del castillo avisa de que está cerrada")

        s.heroDied()
        check(s.overlay == .dead, "al morir aparece la pantalla de derrota")
        s.respawn()
        check(s.overlay == .none && s.scene.heroFeetTile() == Valdehierro.town.entry, "se reaparece en la puerta sur")
        print(failures == 0 ? "Todo correcto." : "\(failures) comprobaciones fallidas.")
    }

case "sprites":
    print("Hojas de sprites:")
    var heroes: [CGImage] = []
    for race in Race.allCases {
        for pose in HeroArt.Pose.allCases { heroes.append(HeroArt.grid(race: race, armorIcon: "armor_chain", pose: pose).makeCGImage()) }
    }
    sheet(heroes, columns: HeroArt.Pose.allCases.count, cell: 38, scale: 4, "heroes")
    sheet(Bestiary.all.map { EnemyArt.grid(for: $0.id, frame: 0).makeCGImage() }, columns: 10, cell: 36, scale: 4, "enemies")
    var attacks: [CGImage] = []
    for id in ["goblin", "bandit", "skeletonArcher", "orc", "wolf", "goblinKing"] {
        for frame in 0..<EnemyArt.frameCount { attacks.append(EnemyArt.grid(for: id, frame: frame).makeCGImage()) }
    }
    sheet(attacks, columns: 8, cell: 36, scale: 4, "enemy_attacks")
    let looks = ["baker", "weaver", "miller", "monk", "innkeeper", "alchemist", "princess"]
    sheet(looks.map { EnemyArt.grid(for: "npc.\($0)", frame: 0).makeCGImage() }, columns: 7, cell: 30, scale: 5, "npcs")
    sheet(PartCatalog.all.filter { $0.tier == 4 || $0.isSpecial }.map { WeaponArt.single($0).makeCGImage() },
          columns: 12, cell: 28, scale: 4, "parts")
    sheet(Mineral.allCases.map { Sprites.mineral($0).makeCGImage() } + [Sprites.coin, Sprites.heart, Sprites.potion].map { $0.makeCGImage() },
          columns: 13, cell: 12, scale: 6, "icons")

case "maps":
    print("Mapas:")
    for area in [Valdehierro.town] + Valdehierro.interiors {
        let T = TownArt.tile
        var grid = TownArt.ground(area)
        var items: [(Int, PixelGrid, Int, Int)] = []
        for y in 0..<area.height {
            for x in 0..<area.width {
                if area.tile(x, y) == .tree {
                    let tree = TownArt.tree(variant: (x * 7 + y) % 3)
                    items.append(((y + 1) * T, tree, x * T + T / 2 - tree.width / 2, (y + 1) * T - tree.height + 2))
                } else if area.tile(x, y) == .lamp {
                    items.append(((y + 1) * T, TownArt.lamp, x * T + T / 2 - TownArt.lamp.width / 2, (y + 1) * T - TownArt.lamp.height))
                }
            }
        }
        for b in area.buildings {
            let art = TownArt.building(b, open: false)
            items.append(((b.y + b.height) * T, art, b.x * T - 1, (b.y + b.height) * T - art.height + 1))
        }
        for item in items.sorted(by: { $0.0 < $1.0 }) { grid.draw(item.1, x: item.2, y: item.3) }
        save(grid.makeCGImage(), "map_\(area.id)")
    }

case "shots":
    MainActor.assumeIsolated {
        print("Capturas:")
        let size = CGSize(width: 852, height: 393)
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        func snap(_ scene: SKScene, _ name: String) {
            if let texture = view.texture(from: scene) { save(texture.cgImage(), name) }
        }
        let store = tempStore()
        store.profile = geared(tier: 3, quality: 3, armorTier: 2)
        store.startTown()
        let s = store.explore!
        view.presentScene(s.scene)
        s.scene.size = size
        while s.overlay == .dialog { s.advanceDialog() }
        var t: TimeInterval = 1
        func run(_ seconds: Double, joy: CGVector = .zero) {
            for _ in 0..<Int(seconds * 60) { t += 1.0 / 60; s.joystick = joy; s.scene.update(t) }
        }
        for (name, area, start) in [("shot_town_gate", Valdehierro.town, Valdehierro.town.entry),
                                    ("shot_town_plaza", Valdehierro.town, TilePoint(22, 22)),
                                    ("shot_inn", Valdehierro.area("inn")!, Valdehierro.area("inn")!.entry),
                                    ("shot_throne", Valdehierro.area("castle")!, Valdehierro.area("castle")!.entry)] {
            s.scene.load(area, heroAt: start, progress: store.profile.town)
            run(0.5)
            snap(s.scene, name)
        }
        store.startArena()
        let arena = store.battle!
        view.presentScene(arena.scene)
        arena.scene.size = size
        for _ in 0..<5 { arena.startNextWave(); arena.roundCleared() }
        arena.startNextWave()
        for _ in 0..<(60 * 5) { t += 1.0 / 60; arena.scene.update(t) }
        snap(arena.scene, "shot_arena_wave6")
    }

case "fichas":
    let root = outputDir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    func write(_ text: String, _ path: String) {
        let url = root.appendingPathComponent(path)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? text.write(to: url, atomically: true, encoding: .utf8)
        print("  → \(path)")
    }
    let header = "<!-- Generado con `make fichas` a partir del código. No editar a mano: cambia los datos y regenera. -->\n\n"
    func stat(_ v: Double) -> String { v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v) }
    func statsText(_ s: Stats) -> String { s.entries.map { "\($0.kind.formatBonus($0.value)) \($0.kind.shortName)" }.joined(separator: ", ") }

    var razas = header + "# Razas\n\n| Raza | Resumen | Vida | ATQ | DEF | Vel. ataque | Alcance | Velocidad | Crítico | Extras |\n|---|---|---|---|---|---|---|---|---|---|\n"
    for race in Race.allCases {
        let b = race.baseStats
        let extras = [StatKind.lifesteal, .goldBonus, .regen].filter { b[$0] > 0 }.map { "\($0.shortName) \($0.formatValue(b[$0]))" }.joined(separator: ", ")
        razas += "| \(race.name) | \(race.summary) | \(stat(b.maxHP)) | \(stat(b.attack)) | \(stat(b.defense)) | \(b.attackSpeed) | \(stat(b.range)) | \(stat(b.moveSpeed)) | \(Int(b.critChance * 100))% | \(extras.isEmpty ? "—" : extras) |\n"
    }
    write(razas, "assets/characters/razas.md")

    var enemigos = header + "# Bestiario (\(Bestiary.all.count) enemigos)\n\nValores base en su nivel de aparición; suben con el nivel de la zona u oleada (`EnemyDefinition.stats(level:)`).\n\n"
    enemigos += "| Id | Nombre | Nivel | Cuerpo | Comportamiento | Vida | Daño | Velocidad | Alcance | Jefe → pieza |\n|---|---|---|---|---|---|---|---|---|---|\n"
    let behaviorName: [EnemyBehavior: String] = [.melee: "cuerpo a cuerpo", .ranged: "a distancia", .charger: "embestida"]
    for e in Bestiary.all {
        let part = e.specialPartID.flatMap(PartCatalog.part)?.name ?? "—"
        enemigos += "| `\(e.id)` | \(e.name) | \(e.level) | \(e.template) | \(behaviorName[e.behavior]!) | \(stat(e.hp)) | \(stat(e.damage)) | \(stat(e.speed)) | \(stat(e.attackRange)) | \(e.isBoss ? part : "—") |\n"
    }
    write(enemigos, "assets/characters/enemigos.md")

    var aldeanos = header + "# Aldeanos y personajes\n\n| Id | Nombre | Dónde | Aspecto | Papel | Recompensa |\n|---|---|---|---|---|---|\n"
    for area in Valdehierro.interiors {
        for npc in area.npcs {
            var reward = ["\(npc.reward.gold) oro"] + npc.reward.minerals.map { "\($0.value) \($0.key.name)" }.sorted()
            if let part = npc.reward.partID.flatMap(PartCatalog.part) { reward.append(part.name) }
            aldeanos += "| `\(npc.id)` | \(npc.name) | \(area.name) | `\(npc.look)` | \(npc.role == .princess ? "princesa" : "aldeano") | \(reward.joined(separator: ", ")) |\n"
        }
    }
    write(aldeanos, "assets/characters/aldeanos.md")

    var catalogo = header + "# Catálogo de piezas y habilidades\n\n"
    for slot in PartSlot.allCases {
        let parts = PartCatalog.all.filter { $0.slot == slot }
        catalogo += "- **\(slot.name)**: \(parts.filter { !$0.isSpecial }.count) normales + \(parts.filter(\.isSpecial).count) únicas\n"
    }
    catalogo += "\n## Piezas únicas\n\n| Pieza | Hueco | Elementos | Estadísticas | Habilidad |\n|---|---|---|---|---|\n"
    for part in PartCatalog.specialParts {
        catalogo += "| \(part.name) | \(part.slot.name) | \(part.elements.map(\.name).joined(separator: ", ")) | \(statsText(part.stats)) | \(AbilityBook.ability(part.abilityID)?.name ?? "—") |\n"
    }
    catalogo += "\n## Habilidades (\(AbilityBook.all.count))\n\n| Id | Nombre | Elementos | Efecto |\n|---|---|---|---|\n"
    for ability in AbilityBook.all {
        catalogo += "| `\(ability.id)` | \(ability.name) | \(ability.elements.map(\.name).joined(separator: " + ")) | \(ability.description) |\n"
    }
    write(catalogo, "assets/design/catalogo.md")

default:
    print("""
    Comandos: balance | town | sprites | maps | shots | fichas
    Ejemplo: make balance   (o: cd tools/Harness && swift run -c release Harness balance)
    """)
}

exit(failures == 0 ? 0 : 1)
