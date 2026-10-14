import CoreGraphics
import Foundation
import GameCore
import ImageIO
import SpriteKit
import UniformTypeIdentifiers

// Uso: swift run -c release Harness <comando> [opciones]
//   balance [n] [-v] [perfil]  Arena roguelike: oleada en la que cae un bot según cómo mejora en la forja
//                     (n partidas por perfil, 5 por defecto; -v muestra lo que forja;
//                     perfiles: nada, medias, solo-arma, bien, sin-nivel).
//   niveles           Ritmo de subida de nivel en la historia (Valdehierro y Valdemar), estimado sin combate.
//   historia [n] [-v] Modo historia de Valdemar jugado por un bot con combate real (Historia.swift).
//   town              Simula el flujo del pueblo (entrar, rescatar, castillo, morir) y lo comprueba.
//   valdemar          Flujo del continente 1: salidas y bloqueos, reaparición de campo, misiones, castillo,
//                     casa del alcalde, morir en el campo y la Cripta (ValdemarCheck.swift).
//   sprites           Hojas de sprites: héroes (todas las poses), enemigos, armas, aldeanos.
//   hero              Héroe en detalle: razas × poses con armadura, los 18 diseños de armadura,
//                     opciones de personalización y animación de carrera (frames grandes).
//   mapa-continente   Mapa del continente de la pausa entero a PNG (fondo, áreas, niebla, iconos) y tiempos de dibujo.
//   mapa-mundo        Mapa del mundo (Ardenia): los 6 continentes, los futuros en gris, rutas; tiempo del fondo.
//   maps              Mapas completos de todas las áreas (pueblo, interiores, campo) + planos `plan_*`.
//   dungeon           Pisos completos de la mazmorra de la arena.
//   shop              Tienda del enano: poses del herrero y escena de la forja.
//   shots             Capturas de la escena: pueblo, interiores y arena.
//   fichas            Regenera las fichas de assets/ a partir de los datos del juego.
//   exportar-datos [carpeta]  Valores base en JSON para el panel web (por defecto admin/public/data/; `make datos`).
// Opción para cualquier comando: --ajustes <fichero.json> aplica un documento `GameTuning` antes (p. ej. para medir
// un ajuste del panel con `balance` o `historia`). Las rutas relativas valen desde la raíz del repositorio.
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
/// En la mazmorra rodea los obstáculos (camino más corto por casillas hasta el enemigo).
func steer(_ scene: CombatScene) -> CGVector {
    let hero = scene.hero.position
    let foes = scene.enemies.filter { !$0.isDying && $0.isAggro }
    guard let target = foes.min(by: { $0.position.distance(to: hero) < $1.position.distance(to: hero) }),
          target.position.distance(to: hero) > 45 else { return .zero }
    let direct = (target.position - hero).normalized
    guard let battle = scene as? BattleScene else { return direct }
    let floor = battle.dungeon
    let from = battle.tile(at: CGPoint(x: hero.x, y: hero.y - scene.hero.size.height / 2 + 8))
    let goal = battle.tile(at: CGPoint(x: target.position.x, y: target.position.y - target.size.height / 2 + 6))
    guard from != goal, floor.isWalkable(goal) else { return direct }
    // Anchura desde el enemigo hasta el héroe; el héroe va a la vecina más cercana al enemigo.
    var distance: [TilePoint: Int] = [goal: 0]
    var queue = [goal], head = 0
    while head < queue.count, distance[from] == nil {
        let p = queue[head]; head += 1
        for n in [TilePoint(p.x + 1, p.y), TilePoint(p.x - 1, p.y), TilePoint(p.x, p.y + 1), TilePoint(p.x, p.y - 1)]
        where distance[n] == nil && floor.isWalkable(n) {
            distance[n] = distance[p]! + 1
            queue.append(n)
        }
    }
    guard let here = distance[from], here > 1 else { return direct }
    let next = [TilePoint(from.x + 1, from.y), TilePoint(from.x - 1, from.y), TilePoint(from.x, from.y + 1), TilePoint(from.x, from.y - 1)]
        .filter { (distance[$0] ?? .max) < here }.first
    guard let next else { return direct }
    let c = battle.center(of: next)
    return (CGPoint(x: c.x, y: c.y + scene.hero.size.height / 2 - 8) - hero).normalized
}

// MARK: - Bot de la arena (roguelike: empieza de cero y mejora en la forja)

/// Cómo se porta el bot en la forja del enano (cada 2 oleadas).
struct ForgePolicy {
    let name: String
    /// Forja armas y armaduras (si no, solo compra pociones).
    var upgrades = true
    /// Fracción del oro que gasta en mejoras en cada parada (el resto lo guarda).
    var goldShare = 1.0
    /// Mejora solo en una de cada `every` paradas.
    var every = 1
    /// Forja armadura en la armería y compra la de la tienda.
    var armor = true
    /// Mete los minerales en el ritual.
    var minerals = true
    /// Vende lo que ya no usa.
    var sells = true
    /// Veces que renueva las ofertas de la tienda si no hay nada útil.
    var rerolls = 2
    /// Diagnóstico: el héroe se queda en el nivel 1 (para ver cuánto pesa el nivel).
    var freezeLevel = false

    let id: String

    static let none = ForgePolicy(name: "No mejora (solo pociones)", upgrades: false, id: "nada")
    /// Mejora una parada sí y otra no, sin minerales, sin vender y sin renovar ofertas: va siempre por detrás.
    static let half = ForgePolicy(name: "Mejora a medias (1 de cada 2 paradas, sin minerales)", every: 2, minerals: false, sells: false,
                                  rerolls: 0, id: "medias")
    /// Solo el arma, sin minerales ni armería (el jugador que ignora la mitad de la forja).
    static let weaponOnly = ForgePolicy(name: "Solo el arma (sin armería ni minerales)", armor: false, minerals: false, sells: false,
                                        rerolls: 0, id: "solo-arma")
    static let good = ForgePolicy(name: "Mejora bien (arma, armadura, minerales)", id: "bien")
    static let goodNoLevels = ForgePolicy(name: "Mejora bien, pero sin subir de nivel", freezeLevel: true, id: "sin-nivel")
    static let all = [none, half, weaponOnly, good, goodNoLevels]
}

/// Lo que el bot valora del héroe: daño por segundo × vida efectiva.
func botScore(_ s: Stats) -> Double {
    let dps = s.attack * s.attackSpeed * (1 + s.critChance * (s.critMultiplier - 1)) * (1 + s.lifesteal)
    let ehp = (s.maxHP + 8 * s.regen) / (1 - Combat.damageReduction(defense: s.defense))
    return dps * ehp
}

/// Puntuación esperada del héroe si forja con esta receta (media sobre las casillas de la ruleta).
func expectedScore(_ profile: PlayerProfile, weapon recipe: WeaponRecipe) -> Double {
    zip(Roulette.segments, Roulette.probabilities(luck: recipe.luck)).reduce(0) { acc, entry in
        var p = profile
        let item = recipe.makeItem(quality: entry.0)
        p.inventory.append(item)
        p.equip(item.id)
        return acc + entry.1 * botScore(p.totalStats)
    }
}

func expectedScore(_ profile: PlayerProfile, armor recipe: ArmorRecipe) -> Double {
    zip(Roulette.segments, Roulette.probabilities(luck: recipe.luck)).reduce(0) { acc, entry in
        var p = profile
        let item = recipe.makeItem(quality: entry.0)
        p.inventory.append(item)
        p.equip(item.id)
        return acc + entry.1 * botScore(p.totalStats)
    }
}

/// Una parada en la forja: pociones si hace falta y, según el perfil, la mejor mejora posible
/// (ritual con piezas compradas o guardadas, armería, armadura de la tienda) hasta quedarse sin oro útil.
/// Elige lo que más mejora (daño por segundo × vida efectiva) en relación con lo que cuesta.
func visitForge(_ session: BattleSession, _ store: GameStore, policy: ForgePolicy, stop: Int, log: inout [String]) {
    guard let shop = session.shop else { return }
    var rng = SystemRandomNumberGenerator()
    // Poción: si le falta más del 40 % de la vida (al salir de la forja ya se cura un 30 %).
    if session.hp < session.maxHP * 0.6,
       let potion = shop.offers.first(where: { if case .potion = $0.kind { return !$0.sold } else { return false } }),
       store.profile.gold >= potion.price {
        shop.buy(potion)
    }
    guard policy.upgrades, stop % policy.every == 0 else { return }
    var budget = Int(Double(store.profile.gold) * policy.goldShare)
    /// Ya ha comprado piezas sueltas para un arma futura en esta parada (no cambia de plan a medias).
    var saving = false

    enum Action {
        /// Compra lo que falte y forja ya.
        case craft(WeaponRecipe, [ShopOffer])
        /// El arma aún no se puede pagar (o falta un hueco en la tienda): compra ahora las piezas que pueda.
        case save([ShopOffer])
        case armor(ArmorRecipe)
        case buyArmor(ShopOffer)
    }
    for _ in 0..<12 {
        let profile = store.profile
        let current = botScore(profile.totalStats)
        let available = min(budget, profile.gold)
        var best: (action: Action, value: Double)?
        func consider(_ action: Action, cost: Int, score: Double) {
            let gain = score / current - 1
            guard gain > 0.04 else { return }
            // Mejora por moneda, pero sin despreciar las compras grandes (un arma nueva vale más que tres guantes).
            let value = gain / Double(max(1, cost)).squareRoot()
            if best == nil || value > best!.value { best = (action, value) }
        }

        // Ritual: piezas propias + piezas a la venta (+ guarda/empuñadura "futuras" si hoy no hay).
        let offered = shop.offers.filter { !$0.sold && $0.part != nil }
        typealias Option = (id: String, offer: ShopOffer?, future: Int)
        func options(_ slot: PartSlot) -> [Option] {
            profile.ownedParts(slot).map { ($0.id, nil, 0) } + offered.filter { $0.part!.slot == slot }.map { ($0.part!.id, $0, 0) }
        }
        func future(_ slot: PartSlot, tier: Int) -> Option? {
            let t = max(1, min(tier, PartCatalog.maxShopTier(forLevel: shop.level)))
            let id = slot == .hilt ? "guard.straight.\(PartMaterial.metals[t - 1].id)" : "grip.short.\(PartMaterial.woods[t - 1].id)"
            guard let part = PartCatalog.part(id), profile.partCount(id) == 0, !offered.contains(where: { $0.part?.id == id }) else { return nil }
            return (id, nil, part.price)
        }
        var minerals: [Mineral: Int] = [:]
        if policy.minerals {
            var room = WeaponRecipe.maxMinerals
            for mineral in Mineral.allCases.reversed() where room > 0 {
                let n = min(room, profile.count(of: mineral))
                if n > 0 { minerals[mineral] = n; room -= n }
            }
        }
        for head in options(.head) {
            let tier = PartCatalog.part(head.id)?.tier ?? 1
            for guardPart in options(.hilt) + [future(.hilt, tier: tier)].compactMap({ $0 }) {
                for grip in options(.grip) + [future(.grip, tier: tier)].compactMap({ $0 }) {
                    let recipe = WeaponRecipe(headID: head.id, guardID: guardPart.id, gripID: grip.id, minerals: minerals)
                    let buys = [head.offer, guardPart.offer, grip.offer].compactMap { $0 }
                    let missing = guardPart.future + grip.future
                    let cost = buys.reduce(0) { $0 + $1.price } + recipe.goldCost + missing
                    let score = expectedScore(profile, weapon: recipe)
                    if missing == 0 && cost <= available {
                        consider(.craft(recipe, buys), cost: cost, score: score)
                    } else if !saving, !buys.isEmpty, head.offer.map({ $0.price <= available }) ?? true {
                        // Ahorra: la hoja primero; luego guarda y empuñadura si llega.
                        var left = available
                        let now = buys.filter { offer in
                            // No compra otra pieza para un hueco que ya tiene guardado (no cambia de plan a medias).
                            guard offer.price <= left, let part = offer.part,
                                  !profile.ownedParts(part.slot).contains(where: { $0.tier >= part.tier }) else { return false }
                            left -= offer.price
                            return true
                        }
                        if !now.isEmpty { consider(.save(now), cost: cost, score: score) }
                    }
                }
            }
        }
        if policy.armor {
            for style in ArmorCatalog.styles {
                guard let material = style.materialKind.materials.last(where: { $0.tier <= profile.maxArmorTier }) else { continue }
                let recipe = ArmorRecipe(styleID: style.id, materialID: material.id, dye: ArmorCatalog.dyes[0])
                if recipe.goldCost <= available {
                    consider(.armor(recipe), cost: recipe.goldCost, score: expectedScore(profile, armor: recipe))
                }
            }
            for offer in shop.offers where !offer.sold && offer.price <= available {
                guard let item = offer.item else { continue }
                var p = profile
                p.inventory.append(item)
                p.equip(item.id)
                consider(.buyArmor(offer), cost: offer.price, score: botScore(p.totalStats))
            }
        }
        guard let choice = best else {
            // Nada útil: renueva las ofertas si le sobra oro.
            if shop.rerolls < policy.rerolls, store.profile.gold >= 3 * shop.rerollCost + 40 {
                budget -= shop.rerollCost
                shop.reroll()
                continue
            }
            if CommandLine.arguments.contains("-d") {
                print("        [forja \(session.wave)] nada que hacer con \(available) de oro; ofertas:",
                      shop.offers.filter { !$0.sold }.map { "\($0.part?.name ?? $0.item?.name ?? "poción") \($0.price)" })
            }
            break
        }
        let goldBefore = store.profile.gold
        switch choice.action {
        case .craft(let recipe, let buys):
            buys.forEach(shop.buy)
            if let result = try? store.profile.craft(recipe, using: &rng) {
                log.append("\(session.wave):\(result.item.name) \(result.quality.name)")
                equipBest(store, .weapon)
            }
        case .save(let buys):
            saving = true
            for offer in buys {
                shop.buy(offer)
                log.append("\(session.wave):+\(offer.part!.name)")
            }
        case .armor(let recipe):
            guard let result = try? store.profile.craft(recipe, using: &rng) else { break }
            log.append("\(session.wave):\(result.item.name) \(result.quality.name)")
            equipBest(store, result.item.slot)
        case .buyArmor(let offer):
            shop.buy(offer)
            if let item = offer.item { equipBest(store, item.slot) }
        }
        budget -= goldBefore - store.profile.gold
        if store.profile.gold == goldBefore { break }
        if policy.sells {
            for item in store.profile.inventory where !store.profile.isEquipped(item) {
                store.profile.sell(item.id)
            }
        }
    }
}

/// Equipa lo mejor que tenga para un hueco.
func equipBest(_ store: GameStore, _ slot: EquipmentSlot) {
    let candidates = store.profile.inventory.filter { $0.slot == slot }
    let best = candidates.max { a, b in
        var pa = store.profile, pb = store.profile
        pa.equip(a.id); pb.equip(b.id)
        return botScore(pa.totalStats) < botScore(pb.totalStats)
    }
    if let best { store.profile.equip(best.id) }
}

struct ArenaResult {
    var wave: Int
    var level: Int
    var weapon: String
    var armorPieces: Int
    var log: [String]
    /// Minerales recogidos en toda la partida y oro ganado.
    var minerals: Int
    var gold: Int
}

/// Juega la arena (partida roguelike desde cero) hasta caer, parando en la forja según `policy`.
func arenaRun(policy: ForgePolicy, race: Race = .human, maxWave: Int = 60) -> ArenaResult {
    let store = tempStore()
    store.profile = PlayerProfile.newGame(race: race)
    store.startArena()
    let s = store.battle!
    var t: TimeInterval = 1
    s.startNextWave()
    var lastKills = 0, stalled = 0, stops = 0
    var log: [String] = []
    func result() -> ArenaResult {
        let p = store.profile
        let weapon = p.equippedWeapon.map { "\($0.name)\($0.qualityName.map { " \($0)" } ?? "")" } ?? "-"
        return ArenaResult(wave: s.wave, level: p.characterLevel, weapon: weapon,
                           armorPieces: EquipmentSlot.gear.filter { p.equipped($0) != nil }.count, log: log,
                           minerals: s.totalMineralsEarned, gold: s.goldEarned)
    }
    /// Con -t: estado del héroe al empezar cada oleada.
    func trace() {
        guard CommandLine.arguments.contains("-t") else { return }
        let st = store.profile.totalStats
        print(String(format: "      oleada %2d (enemigos nv %2d): héroe nv %2d · vida %4.0f/%4.0f · ATQ %5.1f · DEF %5.1f · VEL %.2f · oro %d",
                     s.wave, Arena.enemyLevel(wave: s.wave), store.profile.characterLevel, s.hp, st.maxHP, st.attack, st.defense,
                     st.attackSpeed, store.profile.gold))
    }
    trace()
    for _ in 0..<(60 * 60 * 120) {
        t += 1.0 / 60
        if policy.freezeLevel { store.profile.level = 1; store.profile.xp = 0 }
        s.joystick = steer(s.scene)
        s.scene.update(t)
        // Atasco: nadie muere en 90 s de juego (alguien se ha quedado encerrado).
        if s.kills != lastKills { lastKills = s.kills; stalled = 0 } else { stalled += 1 }
        if stalled == 60 * 90 {
            let scene = s.scene
            print("    ⚠︎ atasco en la oleada \(s.wave): héroe \(scene.tile(at: CGPoint(x: scene.hero.position.x, y: scene.hero.position.y - scene.hero.size.height / 2 + 8)))",
                  scene.enemies.map { "\($0.definition.id)@\(scene.tile(at: CGPoint(x: $0.position.x, y: $0.position.y - $0.size.height / 2 + 6)))" })
        }
        switch s.phase {
        case .intermission:
            if s.wave >= maxWave { return result() }
            stops += 1
            visitForge(s, store, policy: policy, stop: stops, log: &log)
            s.startNextWave()
            trace()
        case .waveBreak:
            if s.wave >= maxWave { return result() }
            s.startNextWave()
            trace()
        case .defeat: return result()
        default: if s.hp <= 0 { s.heroDied() }
        }
    }
    return result()
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] { var seen = Set<Element>(); return filter { seen.insert($0).inserted } }
}

func check(_ condition: Bool, _ message: String) {
    print(condition ? "  ✔ \(message)" : "  ✘ \(message)")
    if !condition { failures += 1 }
}
var failures = 0

// MARK: - Comandos

let command = CommandLine.arguments.dropFirst().first ?? "help"
let repoRoot = outputDir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
applyTuningArgument(root: repoRoot)

switch command {
case "balance":
    // Partidas de arena desde cero (roguelike): lo que cambia es cómo mejora el equipo en la forja.
    let args = CommandLine.arguments.dropFirst(2)
    let runs = args.compactMap { Int($0) }.first ?? 5
    let only = ForgePolicy.all.filter { args.contains($0.id) }
    print("Arena roguelike (\(runs) partidas por perfil, oleada en la que cae · nivel al caer):")
    for policy in only.isEmpty ? ForgePolicy.all : only {
        let results = (0..<runs).map { _ in arenaRun(policy: policy) }
        let sorted = results.sorted { $0.wave < $1.wave }
        let bosses = sorted.filter { Arena.isBossWave($0.wave) }.count
        print("  \(policy.name): mediana \(sorted[runs / 2].wave) · oleadas \(sorted.map(\.wave)) · niveles \(sorted.map(\.level))"
              + " · \(bosses)/\(runs) caen ante un jefe")
        let median = sorted[runs / 2]
        print("    partida mediana: cae en la \(median.wave) con nivel \(median.level), \(median.weapon), \(median.armorPieces)/4 armaduras"
              + " · \(median.minerals) minerales y \(median.gold) de oro en la partida")
        if args.contains("-v") {
            for r in sorted {
                print("    · oleada \(r.wave), nivel \(r.level): \(r.weapon) · \(r.armorPieces)/4 · \(r.log.joined(separator: " · "))")
            }
        }
    }

case "niveles":
    // Estimación rápida del ritmo de la historia (sin combate; la medida buena es `make historia`): cada monstruo
    // matado una vez, en orden de nivel de zona, las mazmorras una vez y las misiones al terminar su parte. Usa
    // `Leveling.storyXPForKill` (jefes ×storyBossMultiplier, los que reaparecen ×respawningMultiplier).
    struct Hero { var level = 1, xp = 0 }
    typealias Fight = (level: Int, boss: Bool, respawns: Bool)
    func gain(_ hero: inout Hero, _ xp: Int) {
        hero.xp += xp
        while hero.level < Leveling.maxLevel, hero.xp >= Leveling.xpToNext(hero.level) { hero.xp -= Leveling.xpToNext(hero.level); hero.level += 1 }
    }
    func fraction(_ hero: Hero) -> String { String(format: "%.1f", Double(hero.level) + Double(hero.xp) / Double(max(1, Leveling.xpToNext(hero.level)))) }
    /// Spawns de un área (opcionalmente solo algunas zonas), en orden de nivel.
    func spawns(_ area: AreaMap, zones: (Zone?) -> Bool = { _ in true }) -> [Fight] {
        area.spawns.filter { zones(area.zone(at: $0.position)) }
            .compactMap { s in Bestiary.enemy(s.enemyID).map { (area.level(at: s.position), $0.isBoss, area.isField && !area.isPermanent(s)) } }
            .sorted { $0.level < $1.level }
    }
    func dungeonFights(_ d: StoryDungeon) -> [Fight] {
        let mobs = d.waves.flatMap { $0.values }.reduce(0, +) + d.bossEscort.values.reduce(0, +)
        return Array(repeating: (d.level, false, true), count: mobs) + (d.bossID == nil ? [] : [(d.level, true, false)])
    }
    let town = Valdehierro.town
    let paso = "valdemar.paso"
    let late = [ValdemarQuests.reyGoblin, ValdemarQuests.pasoNorte, ValdemarQuests.calabozos, ValdemarQuests.liberar]
    let steps: [(String, [Fight], [String])] = {
        var out: [(String, [Fight], [String])] = []
        // Las casas de los 6 aldeanos (las demás, como la del alcalde, son de misiones posteriores).
        let isVillagerHouse = { (a: AreaMap) in a.npcs.contains { Valdehierro.villagerIDs.contains($0.id) } }
        let houses = Valdehierro.interiors.filter(isVillagerHouse).sorted { $0.level < $1.level }
        let townFights = (spawns(town) { $0?.id != "courtyard" } + houses.flatMap { spawns($0) }).sorted { $0.level < $1.level }
        out.append(("Pueblo liberado (calles + 6 casas)", townFights, [ValdemarQuests.liberar]))
        let field = World.areas.filter { a in !Valdehierro.areas.contains { $0.id == a.id } && a.id != paso }
            + Valdehierro.interiors.filter { !isVillagerHouse($0) && $0.id != "castle" }
        let crypt = World.storyDungeon("valdemar.cripta").map(dungeonFights) ?? []
        let quests = World.quests.map(\.id).filter { !late.contains($0) }
        out.append(("Campo + Cripta + misiones (antes del patio)", (field.flatMap { spawns($0) } + crypt).sorted { $0.level < $1.level }, quests))
        let castle = spawns(town) { $0?.id == "courtyard" } + (Valdehierro.area("castle").map { spawns($0) } ?? [])
        out.append(("Patio + Rey Goblin", castle, [ValdemarQuests.reyGoblin]))
        out.append(("Epílogo + Paso del Norte", World.area(paso).map { spawns($0) } ?? [], [ValdemarQuests.pasoNorte]))
        out.append(("+ Calabozos (opcional)", World.storyDungeon("valdemar.calabozos").map(dungeonFights) ?? [], [ValdemarQuests.calabozos]))
        return out
    }()
    print("Nivel del héroe en la historia (estimación: monstruos una vez + misiones; jefes ×\(Int(Leveling.storyBossMultiplier)),"
          + " los que reaparecen ×\(Leveling.respawningMultiplier)):")
    var hero = Hero()
    for (name, fights, quests) in steps {
        var fromFights = 0, fromBosses = 0
        for f in fights {
            let xp = Leveling.storyXPForKill(enemyLevel: f.level, heroLevel: hero.level, isBoss: f.boss, respawns: f.respawns)
            if f.boss { fromBosses += xp } else { fromFights += xp }
            gain(&hero, xp)
        }
        let fromQuests = quests.reduce(0) { $0 + (World.quest($1)?.reward.xp ?? 0) }
        gain(&hero, fromQuests)
        print("    \(name): \(fraction(hero)) [XP monstruos \(fromFights), jefes \(fromBosses), misiones \(fromQuests)]")
    }
    print("  Zonas: " + town.zones.map { "\($0.name) \($0.level)" }.joined(separator: ", ")
          + " · casas: " + Valdehierro.interiors.map { "\($0.name) \($0.level)" }.joined(separator: ", "))

case "historia":
    // Modo historia de Valdemar con el combate real (balance-designer, B1): Historia.swift.
    MainActor.assumeIsolated { storySimulation() }

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
        // Ya no se habla al acercarse: se toca al NPC (y si está lejos, el héroe camina hasta él).
        s.scene.load(bakery, heroAt: TilePoint(11, 2), progress: store.profile.town)
        run(0.5, joy: .zero)
        check(s.overlay == .none, "al acercarse a Marta no salta nada")
        check(s.scene.isReachIndicatorShown("marta"), "pero sale el «…» de al alcance sobre ella")
        s.scene.load(bakery, heroAt: bakery.entry, progress: store.profile.town)
        run(0.3, joy: .zero)
        check(!s.scene.isReachIndicatorShown("marta"), "desde la puerta no está al alcance")
        check(s.interact(with: "marta") == .walk, "tocarla de lejos: el héroe camina hasta ella")
        run(0.4, joy: .zero)
        let walked = s.scene.heroFeetTile() != bakery.entry
        run(0.2, joy: CGVector(dx: 1, dy: 0))
        check(walked && s.scene.walkingTo == nil && s.overlay == .none, "mover el joystick cancela el paseo")
        if let p = s.scene.screenPoint(ofNPC: "marta") {
            check(s.isNPC(atScreen: CGPoint(x: p.x + 30, y: p.y + 40)) && !s.isNPC(atScreen: CGPoint(x: p.x + 140, y: p.y)),
                  "el toque en pantalla da con Marta (con margen para el dedo) y no fuera")
        }
        check(s.tap(atScreen: s.scene.screenPoint(ofNPC: "marta") ?? .zero) && s.scene.walkingTo == "marta", "se vuelve a tocar")
        var steps = 0
        while s.overlay != .dialog && steps < 60 * 15 { steps += 1; t += 1.0 / 60; s.joystick = .zero; s.scene.update(t) }
        check(s.overlay == .dialog && s.dialog?.speaker.hasPrefix("Marta") == true,
              String(format: "al llegar (%.1f s) habla Marta", Double(steps) / 60))
        while s.overlay == .dialog { s.advanceDialog() }
        check(store.profile.town.rescued.contains("marta"), "Marta queda rescatada")

        // Sin los monstruos de la plaza (su jefe se presenta con un diálogo al verte).
        town = store.profile.town
        town.killedSpawns.formUnion(Valdehierro.town.spawns.filter { $0.id.hasPrefix("plaza.") }.map(\.id))
        store.profile.town = town
        s.scene.load(Valdehierro.town, heroAt: TilePoint(21, 10), progress: store.profile.town)
        run(1, joy: CGVector(dx: 0, dy: 1))
        check(s.lastToast?.contains("castillo") == true, "la puerta del castillo avisa de que está cerrada")

        s.heroDied()
        check(s.overlay == .dead, "al morir aparece la pantalla de derrota")
        s.respawn()
        check(s.overlay == .none && s.scene.heroFeetTile() == Valdehierro.town.entry, "se reaparece en la puerta sur")
        print(failures == 0 ? "Todo correcto." : "\(failures) comprobaciones fallidas.")
    }

case "valdemar":
    // Flujo del continente 1 (viajes, misiones, castillo, mazmorras): ValdemarCheck.swift.
    MainActor.assumeIsolated { checkValdemar() }

case "valdemar-shots":
    MainActor.assumeIsolated { valdemarShots() }

case "sprites":
    print("Hojas de sprites:")
    var heroes: [CGImage] = []
    for race in Race.allCases {
        for pose in HeroArt.Pose.allCases { heroes.append(HeroArt.grid(HeroLook.starter(race: race, appearance: Appearance()), pose: pose).makeCGImage()) }
    }
    sheet(heroes, columns: HeroArt.Pose.allCases.count, cell: HeroArt.canvasWidth + 6, scale: 4, "heroes")
    sheet(Bestiary.all.map { EnemyArt.grid(for: $0.id, frame: 0).makeCGImage() }, columns: 10, cell: 36, scale: 4, "enemies")
    var attacks: [CGImage] = []
    for id in ["goblin", "bandit", "skeletonArcher", "orc", "wolf", "goblinKing"] {
        for frame in 0..<EnemyArt.frameCount { attacks.append(EnemyArt.grid(for: id, frame: frame).makeCGImage()) }
    }
    sheet(attacks, columns: EnemyArt.frameCount, cell: 36, scale: 4, "enemy_attacks")
    let looks = ["baker", "weaver", "miller", "monk", "innkeeper", "alchemist", "princess", "guardCaptain", "letter", "signpost"]
    sheet(looks.map { EnemyArt.grid(for: "npc.\($0)", frame: 0).makeCGImage() }, columns: 7, cell: 30, scale: 5, "npcs")
    // Aldeanos con versión chibi (NPCLooks, mismo sistema que el héroe).
    let chibis = looks.compactMap { NPCLooks.look($0) }.map { HeroArt.grid($0, pose: .idle0).makeCGImage() }
    sheet(chibis, columns: chibis.count, cell: HeroArt.canvasWidth + 6, scale: 4, "npcs_chibi")
    sheet(PartCatalog.all.filter { $0.tier == 4 || $0.isSpecial }.map { WeaponArt.single($0).makeCGImage() },
          columns: 12, cell: 28, scale: 4, "parts")
    sheet(Mineral.allCases.map { Sprites.mineral($0).makeCGImage() } + [Sprites.coin, Sprites.heart, Sprites.potion].map { $0.makeCGImage() },
          columns: 13, cell: 12, scale: 6, "icons")
    // Arte de Valdemar en grande (acólito, capitán, objetos, marcas de misión): ValdemarArtSheet.swift.
    MainActor.assumeIsolated { valdemarArtSheets() }

case "hero":
    print("Héroe en detalle:")
    let cell = max(HeroArt.canvasWidth, HeroArt.canvasHeight) + 6
    func gear(_ style: String, _ material: [UInt32], _ dye: UInt32) -> GearLook { GearLook(styleID: style, material: material, dye: dye) }
    let iron = PartMaterial.metals[1].palette, silver = PartMaterial.metals[2].palette
    let fullSet: [EquipmentSlot: GearLook] = [
        .helmet: gear("helm.knight", silver, 0xB13E53), .chest: gear("chest.plate", silver, 0x3B5DC9),
        .gloves: gear("gloves.gauntlets", silver, 0x3B5DC9), .boots: gear("boots.greaves", silver, 0x3B5DC9),
    ]
    // 1. Razas × poses: sin armadura, inicial y con armadura completa.
    for race in Race.allCases {
        var images: [CGImage] = []
        for gearSet in [[:], HeroLook.starter(race: race, appearance: Appearance()).gear, fullSet] {
            let look = HeroLook(race: race, appearance: Appearance(), gear: gearSet)
            images += HeroArt.Pose.allCases.map { HeroArt.grid(look, pose: $0).makeCGImage() }
        }
        sheet(images, columns: HeroArt.Pose.allCases.count, cell: cell, scale: 4, "hero_\(race.rawValue)")
    }
    // 2. Los 18 diseños de armadura sobre cada raza (con su material y un tinte).
    var styles: [CGImage] = []
    for race in Race.allCases {
        for style in ArmorCatalog.styles {
            let palette = style.materialKind.materials[2].palette
            let look = HeroLook(race: race, appearance: Appearance(), gear: [style.slot: gear(style.id, palette, 0xB13E53)])
            styles.append(HeroArt.grid(look, pose: .idle0).makeCGImage())
        }
    }
    sheet(styles, columns: ArmorCatalog.styles.count, cell: cell, scale: 3, "hero_gear_styles")
    // 3. Iconos de cada diseño de armadura.
    let icons = ArmorCatalog.styles.map { HeroArt.gearIcon(gear($0.id, $0.materialKind.materials[2].palette, 0xB13E53), slot: $0.slot).makeCGImage() }
    sheet(icons, columns: 9, cell: 20, scale: 6, "hero_gear_icons")
    // 4. Personalización: cada raza con cada peinado y varios colores.
    var custom: [CGImage] = []
    for race in Race.allCases {
        let options = HeroArt.options(for: race)
        for style in 0..<options.hairStyles.count {
            for color in 0..<min(3, options.hairColors.count) {
                let appearance = Appearance(skinTone: color % options.skinTones.count, hairStyle: style, hairColor: color * 2 % options.hairColors.count, eyeColor: color % options.eyeColors.count)
                custom.append(HeroArt.grid(HeroLook.starter(race: race, appearance: appearance), pose: .idle0).makeCGImage())
            }
        }
    }
    sheet(custom, columns: 9, cell: cell, scale: 3, "hero_appearance")
    // 5. Carrera en grande (humano con armadura completa), para revisar la animación.
    let runner = HeroLook(race: .human, appearance: Appearance(), gear: fullSet)
    sheet(HeroArt.runPoses.map { HeroArt.grid(runner, pose: $0).makeCGImage() }, columns: HeroArt.runPoses.count, cell: cell, scale: 8, "hero_run")
    // 6. Arma en la mano en cada pose (misma colocación que HeroNode), para cada raza.
    let sword = geared(tier: 3, quality: 2, armorTier: 1).equippedWeapon!
    let swordImage = Art.itemImage(sword)
    let ww = CGFloat(swordImage.width), wh = CGFloat(swordImage.height)
    let anchor = CGPoint(x: 0.5 * ww, y: (1 - (WeaponArt.gripPoint.y + 1) / wh) * wh)
    let poseAngles: [(HeroArt.Pose, CGFloat)] = [(.idle0, -0.3), (.run0, -0.3), (.run1, -0.3), (.run2, -0.3), (.run3, -0.3),
                                                 (.run4, -0.3), (.run5, -0.3), (.windup, 0.1), (.strike, -2.2), (.recover, -0.3)]
    let armed = Race.allCases.flatMap { race in
        poseAngles.map { pose, angle -> CGImage in
            let look = HeroLook(race: race, appearance: Appearance(), gear: fullSet)
            let body = HeroArt.grid(look, pose: pose).makeCGImage()
            let pad = 22, w = body.width + 2 * pad, h = body.height + 2 * pad
            let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.interpolationQuality = .none
            let behind = false
            if !behind { ctx.draw(body, in: CGRect(x: pad, y: pad, width: body.width, height: body.height)) }
            ctx.saveGState()
            let hand = HeroArt.hand(look, pose: pose)
            ctx.translateBy(x: CGFloat(pad) + hand.x, y: CGFloat(pad + body.height) - hand.y)
            ctx.rotate(by: angle)
            ctx.draw(swordImage, in: CGRect(x: -anchor.x, y: -anchor.y, width: ww, height: wh))
            ctx.restoreGState()
            if behind { ctx.draw(body, in: CGRect(x: pad, y: pad, width: body.width, height: body.height)) }
            return ctx.makeImage()!
        }
    }
    sheet(armed, columns: poseAngles.count, cell: cell + 44, scale: 3, "hero_weapon")
    _ = iron

case "mapa-continente":
    print("Mapa del continente (pausa):")
    MainActor.assumeIsolated { continentMapShots() }

case "mapa-mundo":
    print("Mapa del mundo (pausa):")
    MainActor.assumeIsolated { worldMapShots() }

case "maps":
    print("Mapas:")
    for area in World.areas {  // pueblo, interiores y áreas de campo (map-designer)
        let T = TownArt.tile
        var grid = TownArt.ground(area)
        var items: [(Int, PixelGrid, Int, Int)] = []
        for y in 0..<area.height {
            for x in 0..<area.width {
                if area.tile(x, y) == .tree {
                    let tree = TownArt.tree(variant: TownArt.treeVariant(area, x, y))
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
    // map-designer: plano esquemático de cada exterior (colores planos por casilla + datos), para revisar el diseño
    // mientras las casillas nuevas no tienen arte. Rojo = monstruo (magenta = jefe), amarillo = NPC, naranja = salida,
    // violeta = bajada a mazmorra, cian = punto seguro, blanco = entrada, marrón = edificio (puerta clara).
    for area in World.areas where !area.isInterior {
        let c = 8, w = area.width * c, h = area.height * c
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        func fill(_ x: Int, _ y: Int, _ rgb: UInt32, inset: Int = 0) {
            ctx.setFillColor(red: CGFloat(rgb >> 16 & 255) / 255, green: CGFloat(rgb >> 8 & 255) / 255, blue: CGFloat(rgb & 255) / 255, alpha: 1)
            ctx.fill(CGRect(x: x * c + inset, y: h - (y + 1) * c + inset, width: c - 2 * inset, height: c - 2 * inset))
        }
        let colors: [Character: UInt32] = [
            ".": 0x5FA845, ",": 0x7BBF55, "#": 0xA89F94, "=": 0xCFC4A8, "T": 0x1F5A2A, "~": 0x3B7DD8, "F": 0x3B7DD8,
            "f": 0x8A5A2B, "w": 0x777777, "S": 0xBBB39E, "l": 0x333333, "m": 0xC0504D, "c": 0x9C6B3A, "b": 0x2E7D32,
            "d": 0xB58B57, "%": 0xC9B44C, "p": 0x9E7A4A, "R": 0x6E6E6E, "^": 0x4A4038, "+": 0xD8D8D8, "n": 0xE0D3B0,
            "x": 0xFF7A1A, "e": 0x7B3FBF, ">": 0xFF9F1C, "I": 0xEEEEEE,
        ]
        for y in 0..<area.height {
            for x in 0..<area.width { fill(x, y, colors[area.tile(x, y).rawValue] ?? 0xFF00FF) }
        }
        for b in area.buildings {
            for y in b.y..<(b.y + b.height) { for x in b.x..<(b.x + b.width) { fill(x, y, 0x5A3A22) } }
            for d in b.doorTiles { fill(d.x, d.y, 0xF0D9A0) }
        }
        for s in area.spawns { fill(s.position.x, s.position.y, Bestiary.enemy(s.enemyID)?.isBoss == true ? 0xFF00FF : 0xE02020, inset: 1) }
        for n in area.npcs { fill(n.position.x, n.position.y, 0xFFE000, inset: 1) }
        if let safe = area.safePoint { fill(safe.x, safe.y, 0x00E5FF, inset: 1) }
        fill(area.entry.x, area.entry.y, 0xFFFFFF, inset: 2)
        save(ctx.makeImage()!, "plan_\(area.id)")
    }

case "shop":
    print("Tienda del enano:")
    // Poses del enano.
    sheet(DwarfSmithArt.Pose.allCases.map { DwarfSmithArt.grid($0).makeCGImage() },
          columns: DwarfSmithArt.Pose.allCases.count, cell: DwarfSmithArt.width + 6, scale: 4, "shop_dwarf")
    // La escena como en la tienda (3 puntos por pixel): iPhone horizontal y ventana de Mac.
    for (name, w, h) in [("shop_iphone", 284, 131), ("shop_mac", 393, 187)] {
        let focus = ForgeShopLayout.dwarfCenterX(artWidth: w)
        var g = ForgeBackdropArt.backdrop(width: w, height: h, focusX: focus)
        g.draw(ForgeBackdropArt.embers(width: w, height: h, focusX: focus, frame: 0), x: 0, y: 0)
        let counterTop = h - ForgeBackdropArt.counterHeight
        let dwarf = DwarfSmithArt.grid(.idle0)
        g.draw(dwarf, x: focus - dwarf.width / 2, y: counterTop + DwarfSmithArt.counterLine - dwarf.height)
        g.draw(ForgeBackdropArt.counter(width: ForgeShopLayout.counterWidth(artWidth: w)), x: 0, y: counterTop)
        let image = g.makeCGImage()
        sheet([image], columns: 1, cell: max(w, h) + 2, scale: 3, name)
    }

case "dungeon":
    print("Pisos de la mazmorra:")
    for floor in Dungeon.floors {
        let T = DungeonArt.tile
        var grid = DungeonArt.ground(floor)
        var items: [(Int, PixelGrid, Int, Int)] = []
        for y in 0..<floor.height {
            for x in 0..<floor.width {
                let t = floor.tile(x, y)
                let bottom = (y + 1) * T
                if !(t == .altar && floor.tile(x - 1, y) == .altar),
                   let prop = DungeonArt.prop(t, theme: floor.theme, variant: (x * 7 + y * 3) % 4) {
                    let cx = x * T + (t == .altar ? T : T / 2)
                    items.append((bottom, prop, cx - prop.width / 2, bottom - prop.height))
                    if t == .brazier {
                        let f = DungeonArt.flame(theme: floor.theme, frame: 0)
                        items.append((bottom + 1, f, x * T + T / 2 - f.width / 2, bottom - prop.height + 3 - f.height))
                    }
                }
                if t == .torch {
                    let f = DungeonArt.flame(theme: floor.theme, frame: 0)
                    items.append((bottom, f, x * T + T / 2 - f.width / 2, y * T + T / 2 - 2 - f.height))
                }
            }
        }
        for item in items.sorted(by: { $0.0 < $1.0 }) { grid.draw(item.1, x: item.2, y: item.3) }
        save(grid.makeCGImage(), "dungeon_\(floor.id)")
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
        // Delante de una casa (el héroe debe verse delante de la fachada) y aldeanos rescatados en la plaza.
        let town = Valdehierro.town
        if let house = town.buildings.first(where: { $0.style == .bakery }) ?? town.buildings.first {
            s.scene.load(town, heroAt: TilePoint(house.doorX + house.doorWidth, house.y + house.height), progress: store.profile.town)
            run(0.3, joy: CGVector(dx: 0, dy: 1))
            snap(s.scene, "shot_house_front")
        }
        var rescued = store.profile.town
        rescued.rescued = Valdehierro.villagerIDs
        rescued.killedSpawns = Set(([town] + Valdehierro.interiors).flatMap { $0.spawns.map(\.id) })
        s.scene.load(town, heroAt: TilePoint(21, 17), progress: rescued)
        run(0.5)
        snap(s.scene, "shot_plaza_villagers")
        if let inn = Valdehierro.area("inn") {
            s.scene.load(inn, heroAt: inn.entry, progress: TownProgress())
            run(0.3)
            snap(s.scene, "shot_inn_npc")
        }

        store.startArena()
        let arena = store.battle!
        view.presentScene(arena.scene)
        arena.scene.size = size
        arena.startNextWave()
        for _ in 0..<(60 * 6) { t += 1.0 / 60; arena.scene.update(t) }
        snap(arena.scene, "shot_arena_wave1")
        arena.roundCleared()
        for _ in 0..<4 { arena.startNextWave(); arena.roundCleared() }
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

case "exportar-datos":
    // Valores base del juego para el panel de administración (assets/admin/contrato.md).
    let folder = CommandLine.arguments.dropFirst(2).first { !$0.hasPrefix("-") && !$0.hasSuffix(".json") }
    let dir = folder.map { $0.hasPrefix("/") ? URL(fileURLWithPath: $0) : repoRoot.appendingPathComponent($0) }
        ?? repoRoot.appendingPathComponent("admin/public/data")
    print("Exportando los valores base a \(dir.path):")
    do {
        try exportBaseData(to: dir)
    } catch {
        print("Error al exportar: \(error)")
        failures += 1
    }

default:
    print("""
    Comandos: balance | town | valdemar | sprites | hero | maps | mapa-continente | mapa-mundo | dungeon | shop | shots | fichas | exportar-datos
    Ejemplo: make balance   (o: cd tools/Harness && swift run -c release Harness balance)
    """)
}

exit(failures == 0 ? 0 : 1)
