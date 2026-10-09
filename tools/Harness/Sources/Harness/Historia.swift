import CoreGraphics
import Foundation
import GameCore
import SpriteKit

// MARK: - `make historia`: el modo historia de Valdemar jugado por un bot (balance-designer, B1)
//
// Un bot con equipo fijo de tier 1 (arma Normal sin minerales + casco, peto, guantes y botas de la forja) juega la
// historia con el combate de verdad de la escena (`ExploreScene` y `BattleScene`) en el orden de
// `valdemar/historia.md` §5: pueblo → Huertos → Robleda → casa del alcalde → Abadía + Cripta → Pedregal → patio y
// trono → epílogo del herrero → (tier 2) Paso del Norte → Calabozos (opcional).
// - Se teletransporta junto a cada monstruo (no recorre el mapa andando) y pelea hasta que no queda nadie en guardia:
//   lo que reaparece y le ve, también lo mata (como un jugador).
// - Acepta y entrega misiones hablando con los NPC en el pueblo; si a una misión de matar le faltan monstruos, vuelve a
//   entrar en el área (reaparecen) y mata solo los que cuentan.
// - No esquiva ni compra: el oro y los minerales se acumulan para ver qué podría forjar un jugador.
// - Si muere, reaparece (punto seguro / Puerta sur) y vuelve al mismo monstruo; tras 3 muertes con él, lo deja.
// Fichero aparte de `main.swift` (lo llama `case "historia"`).

/// Un momento de la historia medido.
struct StoryCheckpoint {
    var name: String
    var level: Double
    var deaths: Int
    var gold: Int
    var minerals: [Mineral: Int]
    var minutes: Double
    var xp: Int
}

struct StoryRunResult {
    var checkpoints: [StoryCheckpoint] = []
    /// Nivel al llegar a cada zona o área ("Huertos · Trigales quemados (5)" → 5,3).
    var arrivals: [(String, Int, Double)] = []
    var bossFights: [(String, Double)] = []
    var deathsAt: [String] = []
    var walls: [String] = []
    var stuck: [String] = []
    var kills = 0
    var questXP = 0
    /// Lo que forja y compra (perfil por defecto).
    var forged: [String] = []
    /// Partes de la historia a las que no llega.
    var blocked: [String] = []
    /// Veces que ha tenido que subir de nivel en el campo ante un muro.
    var grinds: [String] = []
}

@MainActor
final class StoryBot {
    let store: GameStore
    var s: ExploreSession
    var t: TimeInterval = 1
    var result = StoryRunResult()
    var deaths = 0
    var seconds = 0.0
    let verbose: Bool
    private var bossWatch: [ObjectIdentifier: (name: String, start: Double)] = [:]
    private var arrivedZones = Set<String>()
    /// Muros ante los que ya ha pasado por la ruleta.
    private var upgradedFor = Set<String>()
    private var grindedFor = Set<String>()
    /// Probabilidad de esquivar un golpe cuerpo a cuerpo avisado (0 = el bot de la arena, que no esquiva).
    let dodgeSkill: Double
    private var dodgeDecisions: [ObjectIdentifier: Bool] = [:]
    private var windupTextures: [String: SKTexture] = [:]
    private var strikeTextures: [String: SKTexture] = [:]
    private var lastPositions: [ObjectIdentifier: CGPoint] = [:]
    private var stillFrames: [ObjectIdentifier: Int] = [:]

    /// Equipo fijo de tier 1 sin minerales (no compra nada); si no, empieza con lo de una partida nueva y forja.
    let fixedGear: Bool

    init(verbose: Bool, dodgeSkill: Double, fixedGear: Bool) {
        self.verbose = verbose
        self.dodgeSkill = dodgeSkill
        self.fixedGear = fixedGear
        store = tempStore()
        var profile = PlayerProfile.newGame()
        profile.hasChosenRace = true
        if fixedGear { Self.equip(&profile, tier: 1) }
        store.profile = profile
        store.startTown()
        s = store.explore!
        skipDialogs()
    }

    /// Equipo del continente: espada (cobre/roble…) Normal sin minerales y las 4 armaduras de la forja del tier.
    static func equip(_ profile: inout PlayerProfile, tier: Int) {
        let metal = PartMaterial.metals[tier - 1].id, wood = PartMaterial.woods[tier - 1].id
        let weapon = WeaponRecipe(headID: "head.sword.\(metal)", guardID: "guard.straight.\(metal)", gripID: "grip.short.\(wood)")
            .makeItem(quality: Roulette.segments[2])
        profile.inventory.append(weapon)
        profile.equip(weapon.id)
        for id in ["helm.knight", "chest.chain", "gloves.gauntlets", "boots.greaves"] {
            let item = ArmorCatalog.makeShopItem(ArmorCatalog.style(id)!, tier: tier, dye: ArmorCatalog.dyes[0])
            profile.inventory.append(item)
            profile.equip(item.id)
        }
    }

    /// Lo que cuesta ese equipo en la forja (piezas del arma + las 4 armaduras forjadas).
    static func gearCost(tier: Int) -> (weapon: Int, armor: Int) {
        let metal = PartMaterial.metals[tier - 1].id, wood = PartMaterial.woods[tier - 1].id
        let weapon = ["head.sword.\(metal)", "guard.straight.\(metal)", "grip.short.\(wood)"]
            .compactMap(PartCatalog.part).reduce(0) { $0 + $1.price }
        let armor = ["helm.knight", "chest.chain", "gloves.gauntlets", "boots.greaves"].reduce(0) { sum, id in
            let style = ArmorCatalog.style(id)!
            let material = style.materialKind.materials[tier - 1]
            return sum + ArmorRecipe(styleID: id, materialID: material.id, dye: 0).goldCost
        }
        return (weapon, armor)
    }

    var profile: PlayerProfile { store.profile }
    var levelValue: Double {
        Double(profile.characterLevel) + Double(profile.levelXP) / Double(max(1, Leveling.xpToNext(profile.characterLevel)))
    }
    var totalXP: Int { (1..<profile.characterLevel).reduce(0) { $0 + Leveling.xpToNext($1) } + profile.levelXP }

    func note(_ text: String) { if verbose { print("      " + text) } }

    func checkpoint(_ name: String) {
        result.checkpoints.append(StoryCheckpoint(name: name, level: levelValue, deaths: deaths, gold: profile.gold,
                                                  minerals: profile.minerals, minutes: seconds / 60, xp: totalXP))
        note(String(format: "▸ %@: nivel %.1f · %d muertes · %d oro", name, levelValue, deaths, profile.gold))
    }

    // MARK: Bucle

    func skipDialogs() {
        var n = 0
        while n < 200 {
            n += 1
            switch s.overlay {
            case .dialog: s.advanceDialog()
            case .victory: s.closeVictory()
            case .smithy: s.closeSmithy()
            default: return
            }
        }
    }

    private func step(_ joy: CGVector) {
        t += 1.0 / 60
        seconds += 1.0 / 60
        s.joystick = joy
        s.scene.update(t)
    }

    /// Jefes: segundos desde que te ven hasta que mueren.
    private func watchBosses(_ enemies: [EnemyNode]) {
        for e in enemies where e.definition.isBoss && e.isAggro && bossWatch[ObjectIdentifier(e)] == nil {
            bossWatch[ObjectIdentifier(e)] = (e.definition.name, seconds)
        }
        let alive = Set(enemies.filter { !$0.isDying }.map(ObjectIdentifier.init))
        for (id, w) in bossWatch where !alive.contains(id) {
            result.bossFights.append((w.name, seconds - w.start))
            bossWatch[id] = nil
        }
    }

    /// Casilla de los pies de un enemigo.
    private func feet(_ e: EnemyNode) -> TilePoint {
        s.scene.tile(at: CGPoint(x: e.position.x, y: e.position.y - e.size.height / 2 + 6))
    }

    /// Se puede pisar sin entrar por una puerta, salida o bajada (ni casillas cerradas por la historia).
    private func passable(_ p: TilePoint, _ map: AreaMap, _ locked: [TilePoint: String]) -> Bool {
        guard p.x >= 0, p.y >= 0, p.x < map.width, p.y < map.height, map.isWalkable(p), locked[p] == nil else { return false }
        if map.exit(at: p) != nil || map.dungeonEntrance(at: p) != nil { return false }
        if let b = map.building(at: p), b.doorTiles.contains(p) { return false }
        if map.tile(p.x, p.y) == .exit { return false }
        return true
    }

    private var locked: [TilePoint: String] = [:]
    /// La última pelea acabó por tiempo (un enemigo al que no se llega).
    private var wasStuck = false

    /// Esquiva como un jugador (cada amenaza, con probabilidad `dodgeSkill`):
    /// - golpe cuerpo a cuerpo avisado (`EnemyArt.windupFrame`): se aparta durante el aviso;
    /// - embestida (el embestidor se para a menos de 180 px y luego carga): se aparta de lado;
    /// - disparo que viene hacia él: paso lateral.
    func dodge(_ scene: CombatScene) -> CGVector? {
        guard dodgeSkill > 0 else { return nil }
        let hero = scene.hero.position
        var dx: CGFloat = 0, dy: CGFloat = 0
        func decide(_ key: ObjectIdentifier, boss: Bool = false) -> Bool {
            // Los jefes avisan más (0,45 s) y se les mira más: se esquivan más a menudo.
            let skill = boss ? min(1, dodgeSkill + 0.15) : dodgeSkill
            if dodgeDecisions[key] == nil { dodgeDecisions[key] = Double.random(in: 0..<1) < skill }
            return dodgeDecisions[key]!
        }
        var seen = Set<ObjectIdentifier>()
        for e in scene.enemies where !e.isDying {
            let id = e.definition.id
            let key = ObjectIdentifier(e)
            if windupTextures[id] == nil {
                let textures = Art.enemyTextures(id)
                windupTextures[id] = textures[EnemyArt.windupFrame]
                strikeTextures[id] = textures[EnemyArt.strikeFrame]
            }
            let last = lastPositions[key]
            lastPositions[key] = e.position
            let distance = e.position.distance(to: hero)
            switch e.definition.behavior {
            case .melee:
                guard e.texture === windupTextures[id] else { continue }
                let reach = (HeroNode.bodyRadius + e.radius + CGFloat(e.stats.attackRange)) * 1.3
                guard distance < reach + 24 else { continue }
                seen.insert(key)
                guard decide(key, boss: e.definition.isBoss) else { continue }
                let away = (hero - e.position).normalized
                dx += away.dx
                dy += away.dy
            case .charger:
                let still = last.map { $0.distance(to: e.position) < 0.05 } ?? false
                stillFrames[key] = still ? (stillFrames[key] ?? 0) + 1 : 0
                // Quieto más de 0,6 s no es una carga: está atascado contra algo (y el héroe debe ir a pegarle).
                if stillFrames[key]! > 36 { continue }
                let dashing = e.texture === strikeTextures[id] && !still
                guard (still && distance < 190 && e.isAggro) || (dashing && distance < 220) else { continue }
                seen.insert(key)
                guard decide(key, boss: e.definition.isBoss) else { continue }
                // De lado respecto a la línea de la carga (siempre hacia el mismo lado durante esa carga).
                let line = (hero - e.position).normalized
                let side: CGFloat = (key.hashValue & 1) == 0 ? 1 : -1
                dx += -line.dy * side
                dy += line.dx * side
            case .ranged:
                continue
            }
        }
        for p in scene.projectiles {
            let key = ObjectIdentifier(p)
            let toHero = hero - p.position
            let v = p.velocity.normalized
            let ahead = toHero.dx * v.dx + toHero.dy * v.dy
            guard ahead > 0, ahead < 170 else { continue }
            let miss = abs(toHero.dx * v.dy - toHero.dy * v.dx)
            guard miss < HeroNode.bodyRadius + 10 else { continue }
            seen.insert(key)
            guard decide(key) else { continue }
            let cross = toHero.dx * v.dy - toHero.dy * v.dx
            let side: CGFloat = cross >= 0 ? 1 : -1
            dx += v.dy * side
            dy += -v.dx * side
        }
        dodgeDecisions = dodgeDecisions.filter { seen.contains($0.key) }
        guard dx != 0 || dy != 0 else { return nil }
        return CGVector(dx: dx, dy: dy).normalized
    }

    /// Hacia el enemigo más cercano por el camino más corto en casillas (como el bot de la arena).
    private func steerExplore(to foes: [EnemyNode]) -> CGVector {
        let scene = s.scene, map = scene.map
        if let away = dodge(scene) { return away }
        let heroPos = scene.hero.position
        // Como un jugador: primero la escolta (magos y abanderados que disparan desde atrás), luego el jefe.
        let adds = foes.filter { !$0.definition.isBoss }
        let foes = adds.isEmpty ? foes : adds
        guard let target = foes.min(by: { $0.position.distance(to: heroPos) < $1.position.distance(to: heroPos) }),
              target.position.distance(to: heroPos) > 45 else { return .zero }
        let direct = (target.position - heroPos).normalized
        let from = scene.heroFeetTile()
        let goal = feet(target)
        guard from != goal else { return direct }
        var distance: [TilePoint: Int] = [goal: 0]
        var queue = [goal], head = 0
        while head < queue.count, distance[from] == nil {
            let p = queue[head]; head += 1
            for n in [TilePoint(p.x + 1, p.y), TilePoint(p.x - 1, p.y), TilePoint(p.x, p.y + 1), TilePoint(p.x, p.y - 1)]
            where distance[n] == nil && (passable(n, map, locked) || n == from) {
                distance[n] = distance[p]! + 1
                queue.append(n)
            }
        }
        guard let here = distance[from], here > 1 else { return direct }
        let next = [TilePoint(from.x + 1, from.y), TilePoint(from.x - 1, from.y), TilePoint(from.x, from.y + 1), TilePoint(from.x, from.y - 1)]
            .filter { (distance[$0] ?? .max) < here }.first
        guard let next else { return direct }
        let c = scene.center(of: next)
        return (CGPoint(x: c.x, y: c.y + scene.hero.size.height / 2 - 8) - heroPos).normalized
    }

    /// Como `steer` del bot de la arena (camino por casillas del piso), pero primero la escolta y luego el jefe.
    private func steerDungeon(_ battle: BattleScene) -> CGVector {
        let hero = battle.hero.position
        let active = battle.enemies.filter { !$0.isDying && $0.isAggro }
        let adds = active.filter { !$0.definition.isBoss }
        let foes = adds.isEmpty ? active : adds
        guard let target = foes.min(by: { $0.position.distance(to: hero) < $1.position.distance(to: hero) }),
              target.position.distance(to: hero) > 45 else { return .zero }
        let direct = (target.position - hero).normalized
        let floor = battle.dungeon
        let from = battle.tile(at: CGPoint(x: hero.x, y: hero.y - battle.hero.size.height / 2 + 8))
        let goal = battle.tile(at: CGPoint(x: target.position.x, y: target.position.y - target.size.height / 2 + 6))
        guard from != goal, floor.isWalkable(goal) else { return direct }
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
        guard let here = distance[from], here > 1,
              let next = [TilePoint(from.x + 1, from.y), TilePoint(from.x - 1, from.y), TilePoint(from.x, from.y + 1),
                          TilePoint(from.x, from.y - 1)].first(where: { (distance[$0] ?? .max) < here }) else { return direct }
        let c = battle.center(of: next)
        return (CGPoint(x: c.x, y: c.y + battle.hero.size.height / 2 - 8) - hero).normalized
    }

    /// Pone al héroe a 2-3 casillas de `p` (por el suelo, sin cruzar muros).
    private func place(near p: TilePoint) {
        let map = s.scene.map
        var distance: [TilePoint: Int] = [p: 0]
        var queue = [p], head = 0
        var spot = p
        while head < queue.count {
            let q = queue[head]; head += 1
            if distance[q]! >= 2 { spot = q; break }
            for n in [TilePoint(q.x + 1, q.y), TilePoint(q.x - 1, q.y), TilePoint(q.x, q.y + 1), TilePoint(q.x, q.y - 1)]
            where distance[n] == nil && passable(n, map, locked) {
                distance[n] = distance[q]! + 1
                queue.append(n)
            }
        }
        let c = s.scene.center(of: spot)
        s.scene.hero.position = CGPoint(x: c.x, y: c.y + s.scene.hero.size.height / 2 - 8)
    }

    /// Entra en un área (recarga: en el campo vuelven todos los monstruos).
    func enter(_ areaID: String, at tile: TilePoint? = nil) {
        guard let area = World.area(areaID) else { return }
        s.goTo(areaID, at: tile ?? World.startPoint(in: area))
        skipDialogs()
        locked = profile.lockedTiles(in: area)
        rest()
    }

    /// Espera quieto hasta tener la vida casi llena (fuera de combate se recupera un 4 %/s).
    func rest() {
        for _ in 0..<(60 * 30) where s.hp < s.maxHP * 0.97 {
            if s.scene.enemies.contains(where: { $0.isAggro && !$0.isDying }) {
                if !fightAggro(limit: 120) {
                    died(at: "\(s.areaID) (descansando)")
                    return
                }
                if wasStuck { return }
            }
            step(.zero)
            skipDialogs()
        }
    }

    /// Muerte: se apunta y se reaparece (punto seguro del área o Puerta sur).
    func died(at place: String) {
        deaths += 1
        result.deathsAt.append(String(format: "%@ con nivel %.1f", place, levelValue))
        note("✝ muere: \(place)")
        if s.overlay != .dead { s.heroDied() }
        s.respawn()
        skipDialogs()
    }

    /// Pelea con todo lo que esté en guardia (y con `target`, si sigue vivo). false = el héroe ha muerto.
    @discardableResult
    func fightAggro(target spawnID: String? = nil, limit: Double = 150) -> Bool {
        let start = seconds
        let debug = CommandLine.arguments.contains("-d")
        let hp0 = s.hp
        var maxFoes = 0
        defer {
            if debug {
                let st = profile.totalStats
                print(String(format: "        pelea %@ nv %d: %d en guardia, vida %.0f→%.0f/%.0f, %.1f s · ATQ %.1f DEF %.1f VEL %.2f alcance %.0f",
                             spawnID ?? "-", profile.characterLevel, maxFoes, hp0, s.hp, s.maxHP, seconds - start, st.attack, st.defense, st.attackSpeed, st.range))
            }
        }
        while seconds - start < limit {
            skipDialogs()
            if s.overlay == .dead { return false }
            if s.hp <= 0 { s.heroDied(); return false }
            let enemies = s.scene.enemies
            watchBosses(enemies)
            var foes = enemies.filter { $0.isAggro && !$0.isDying }
            if foes.isEmpty, let spawnID, let target = enemies.first(where: { $0.spawnID == spawnID && !$0.isDying }) {
                foes = [target]
            }
            if foes.isEmpty { break }
            maxFoes = max(maxFoes, foes.count)
            if CommandLine.arguments.contains("-dd"), Int((seconds - start) * 60) % 60 == 0 {
                let h = s.scene.hero.position
                print(String(format: "          t=%.0f vida %.0f · ", seconds - start, s.hp)
                      + foes.map { String(format: "%@ %.0f/%.0f a %.0f", $0.definition.id, $0.hp, $0.maxHP, $0.position.distance(to: h)) }.joined(separator: ", "))
            }
            step(steerExplore(to: foes))
        }
        wasStuck = seconds - start >= limit
        if wasStuck {
            result.stuck.append("\(s.areaID): \(s.scene.enemies.filter(\.isAggro).map(\.definition.id))")
        }
        watchBosses(s.scene.enemies)
        s.scene.pickups.forEach(s.scene.collect)
        s.scene.partPickups.forEach(s.scene.collectPart)
        // Diagnóstico (`--piezas-arena`): cambia las piezas de jefe de Valdemar por las de la arena (tier 3-6).
        if CommandLine.arguments.contains("--piezas-arena") {
            var p = store.profile
            for (id, n) in p.parts where n > 0 && id.hasSuffix(PartCatalog.valdemarSuffix) {
                p.parts[id] = 0
                p.parts[String(id.dropLast(PartCatalog.valdemarSuffix.count)), default: 0] += n
            }
            store.profile = p
        }
        return true
    }

    /// Nota la zona (o el área) al llegar por primera vez.
    private func arrive(_ area: AreaMap, at tile: TilePoint) {
        let zone = area.isInterior ? nil : area.zone(at: tile)
        let key = zone?.id ?? area.id
        guard arrivedZones.insert(key).inserted else { return }
        let name = area.isInterior ? area.name : "\(area.name) · \(zone?.name ?? "-")"
        result.arrivals.append((name, area.level(at: tile), levelValue))
    }

    /// Mata los monstruos del área que cumplan `which` (vivos ahora), en orden de nivel y por cercanía.
    func clear(_ areaID: String, which: (Spawn) -> Bool = { _ in true }, reenter: Bool = true) {
        guard let area = World.area(areaID) else { return }
        if reenter || s.areaID != areaID { enter(areaID) }
        var pending = area.spawns.filter { which($0) && !profile.town.killedSpawns.contains($0.id) }
        var attempts: [String: Int] = [:]
        var here = s.scene.heroFeetTile()
        while !pending.isEmpty {
            // El de menos nivel; entre los de igual nivel, el más cercano.
            let low = pending.map { area.level(at: $0.position) }.min()!
            let next = pending.filter { area.level(at: $0.position) == low }
                .min { a, b in hypot(Double(a.position.x - here.x), Double(a.position.y - here.y))
                    < hypot(Double(b.position.x - here.x), Double(b.position.y - here.y)) }!
            guard s.scene.enemies.contains(where: { $0.spawnID == next.id && !$0.isDying }) else {
                pending.removeAll { $0.id == next.id }
                continue
            }
            arrive(area, at: next.position)
            place(near: next.position)
            if fightAggro(target: next.id) {
                result.kills = profile.town.killedSpawns.count
                pending.removeAll { $0.id == next.id }
                here = next.position
                rest()
                if s.areaID != areaID { enter(areaID) }
            } else {
                attempts[next.id, default: 0] += 1
                let who = Bestiary.enemy(next.enemyID)?.name ?? next.enemyID
                died(at: "\(who) (\(area.name), nv \(area.level(at: next.position)))")
                if attempts[next.id]! >= 3 {
                    // Como un jugador ante un muro: gasta oro y minerales en la ruleta y lo intenta 2 veces más.
                    if upgradedFor.insert(next.id).inserted, upgrade() {
                        attempts[next.id] = 1
                    } else if grindedFor.insert(next.id).inserted {
                        // Y si sigue sin poder: sube un nivel matando lo que reaparece en el área (como un jugador).
                        grind(areaID)
                        attempts[next.id] = 0
                    } else {
                        result.walls.append("\(who) en \(area.name)")
                        pending.removeAll { $0.id == next.id }
                    }
                }
                enter(areaID)
            }
        }
    }

    // MARK: Historia

    /// Habla con todos los NPC del pueblo que tengan "!" o "?" (acepta y entrega).
    func talkInTown() {
        enter(Valdehierro.townID, at: Valdehierro.town.entry)
        for _ in 0..<6 {
            let npcs = profile.visibleNPCs(in: Valdehierro.town).filter { profile.marker(for: $0.id) != nil }
            guard !npcs.isEmpty else { break }
            for npc in npcs {
                let before = profile.finishedQuests.map(\.reward.xp).reduce(0, +)
                s.npcReached(npc)
                skipDialogs()
                result.questXP += profile.finishedQuests.map(\.reward.xp).reduce(0, +) - before
            }
        }
    }

    /// Una misión de matar a medias: vuelve a entrar en el área (reaparecen) y mata solo lo que cuenta.
    func farm(_ questID: String) {
        guard let quest = World.quest(questID) else { return }
        for _ in 0..<6 {
            guard profile.isActive(quest), let i = quest.objectives.indices.first(where: {
                if case .kill = quest.objectives[$0] { return profile.progress(of: quest)[$0] < quest.objectives[$0].target }
                return false
            }), case let .kill(ids, _, areaID) = quest.objectives[i] else { return }
            let area = areaID ?? World.areas.first { a in a.isField && a.spawns.contains { ids.contains($0.enemyID) } }?.id
            guard let area else { return }
            note("· \(quest.title): \(profile.progress(of: quest)[i])/\(quest.objectives[i].target), vuelve a \(area)")
            clear(area, which: { ids.contains($0.enemyID) })
        }
    }

    /// Mazmorra de historia con el combate de la arena. Reintenta hasta 3 veces si muere.
    func dungeon(_ id: String) {
        guard let dungeon = World.storyDungeon(id),
              let area = World.area(dungeon.entranceAreaID),
              let entrance = area.dungeonEntrances.first(where: { $0.dungeonID == id }) else { return }
        result.arrivals.append((dungeon.name, dungeon.level, levelValue))
        var tries = 3
        var round = 0
        while round < tries {
            round += 1
            if round == 4 { _ = upgrade() }
            if round == 3, upgradedFor.insert(id).inserted { tries = 5 }
            enter(area.id, at: TilePoint(entrance.tiles[0].x, entrance.tiles[0].y + 2))
            s.dungeonEntranceTouched(entrance)
            guard let b = store.battle, b.story != nil else { note("no se pudo entrar en \(id)"); return }
            var won = false
            for _ in 0..<(60 * 60 * 15) {
                switch b.phase {
                case .fighting:
                    t += 1.0 / 60
                    seconds += 1.0 / 60
                    b.joystick = dodge(b.scene) ?? steerDungeon(b.scene)
                    b.scene.update(t)
                    watchBosses(b.scene.enemies)
                    if b.hp <= 0 { b.heroDied() }
                case .waveBreak: b.startNextWave()
                case .storyDialog: b.advanceStoryDialog()
                default: break
                }
                if b.phase == .storyVictory { won = true; break }
                if b.phase == .defeat { break }
            }
            watchBosses([])
            b.leaveStory()
            s = store.explore!
            skipDialogs()
            if won { return }
            deaths += 1
            result.deathsAt.append(String(format: "%@ (oleada %d) con nivel %.1f", dungeon.name, b.wave, levelValue))
            note("✝ muere en \(dungeon.name), oleada \(b.wave)")
        }
        result.walls.append(dungeon.name)
    }

    // MARK: Forja (el bot compra como un jugador sencillo)

    /// Valor de un puñado de minerales para el arma (el cobre, ataque, es lo que más pesa).
    static func mineralScore(_ m: [Mineral: Int]) -> Double {
        m.reduce(0.0) { acc, e in
            acc + Double(e.value) * (e.key == .copper ? 1 : (e.key == .iron || e.key == .silver ? 0.6 : (e.key == .emerald ? 0.5 : 0.1)))
        }
    }

    /// Los 12 mejores minerales que tiene (cobre, hierro, plata, esmeralda, oro).
    static func bestMinerals(_ have: [Mineral: Int]) -> [Mineral: Int] {
        var left = WeaponRecipe.maxMinerals
        var pick: [Mineral: Int] = [:]
        for m in [Mineral.copper, .iron, .silver, .emerald, .gold] where left > 0 {
            let n = min(left, have[m] ?? 0)
            if n > 0 { pick[m] = n; left -= n }
        }
        return pick
    }

    /// La mejor arma que puede forjar ahora (calidad Normal): hoja, guarda y empuñadura del tier de la forja o piezas de
    /// jefe que tenga, con sus 12 mejores minerales. Devuelve la receta, su coste en oro y la puntuación del héroe.
    func bestRecipe(_ p: PlayerProfile) -> (recipe: WeaponRecipe, cost: Int, score: Double) {
        let tier = p.storyForgeTier
        let metal = PartMaterial.metals[tier - 1].id, wood = PartMaterial.woods[tier - 1].id
        func options(_ slot: PartSlot, _ normal: String) -> [String] {
            [normal] + p.parts.filter { id, n in n > 0 && PartCatalog.part(id).map { $0.isSpecial && $0.slot == slot } == true }.map(\.key).sorted()
        }
        let pick = Self.bestMinerals(p.minerals)
        var best: (recipe: WeaponRecipe, cost: Int, score: Double)?
        for head in options(.head, "head.sword.\(metal)") {
            for guardID in options(.hilt, "guard.straight.\(metal)") {
                for grip in options(.grip, "grip.short.\(wood)") {
                    let recipe = WeaponRecipe(headID: head, guardID: guardID, gripID: grip, minerals: pick)
                    let cost = recipe.partIDs.filter { (p.parts[$0] ?? 0) == 0 }.compactMap(PartCatalog.part)
                        .reduce(0) { $0 + $1.price } + recipe.goldCost
                    var q = p
                    let item = recipe.makeItem(quality: Roulette.segments[2])
                    q.inventory.append(item)
                    q.equip(item.id)
                    let score = botScore(q.totalStats)
                    if best == nil || score > best!.score { best = (recipe, cost, score) }
                }
            }
        }
        return best!
    }

    /// Forja la receta (paga, gasta piezas y minerales) con la calidad dada y la equipa si mejora.
    private func forge(_ p: inout PlayerProfile, _ recipe: WeaponRecipe, cost: Int, quality: CraftQuality, note tag: String) {
        p.gold -= cost
        for id in recipe.partIDs where (p.parts[id] ?? 0) > 0 { p.parts[id]! -= 1 }
        for (m, n) in recipe.minerals { p.minerals[m, default: 0] -= n }
        let weapon = recipe.makeItem(quality: quality)
        let before = botScore(p.totalStats)
        p.inventory.append(weapon)
        let old = p.equippedWeapon?.id
        p.equip(weapon.id)
        if botScore(p.totalStats) < before, let old { p.equip(old) }
        let special = recipe.parts.filter(\.isSpecial).map(\.name)
        result.forged.append(String(format: "nv %.1f%@: %@ %@ +%d%@ (%d oro)", levelValue, tag, weapon.name, quality.name,
                                    recipe.totalMinerals, special.isEmpty ? "" : " [" + special.joined(separator: ", ") + "]", cost))
    }

    /// En la forja: rehace el arma si la mejor receta mejora al héroe (calidad Normal, sin suerte) y compra las
    /// armaduras de la tienda que le falten o sean de un tier menor. Con `fixedGear`, nada.
    func visitForge() {
        guard !fixedGear else { return }
        var p = store.profile
        let tier = p.storyForgeTier
        let best = bestRecipe(p)
        if best.score > botScore(p.totalStats) * 1.04, p.gold >= best.cost {
            forge(&p, best.recipe, cost: best.cost, quality: Roulette.segments[2], note: "")
        }
        for id in ["chest.chain", "helm.knight", "boots.greaves", "gloves.gauntlets"] {
            let style = ArmorCatalog.style(id)!
            if let worn = p.equipped(style.slot), worn.styleID != nil, worn.tier >= tier { continue }
            let item = ArmorCatalog.makeShopItem(style, tier: tier, dye: ArmorCatalog.dyes[0])
            guard p.gold >= item.value else { break }
            p.gold -= item.value
            p.inventory.append(item)
            p.equip(item.id)
            result.forged.append(String(format: "nv %.1f: %@ (%d oro)", levelValue, item.name, item.value))
        }
        store.profile = p
    }

    /// Ante un muro: vuelve a la forja y tira la ruleta (con suerte de verdad) con la mejor receta mientras le llegue el
    /// oro y tenga 6 minerales o más (hasta 4 veces); se queda con lo mejor. Devuelve si ha mejorado.
    @discardableResult
    func upgrade() -> Bool {
        guard !fixedGear else { return false }
        var p = store.profile
        let before = botScore(p.totalStats)
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<4 {
            let best = bestRecipe(p)
            guard best.recipe.totalMinerals >= 6, p.gold >= best.cost else { break }
            let quality = Roulette.segments[Roulette.spin(luck: best.recipe.luck, using: &rng)]
            forge(&p, best.recipe, cost: best.cost, quality: quality, note: " (muro)")
        }
        store.profile = p
        return botScore(p.totalStats) > before
    }

    /// Sube un nivel matando los monstruos de campo del área (vuelven al entrar), hasta 6 pasadas.
    func grind(_ areaID: String) {
        // En el pueblo o el castillo no reaparece nada: se sube en el Pedregal (el campo de más nivel antes del trono).
        let fieldID = World.area(areaID)?.isField == true ? areaID : "valdemar.pedregal"
        guard let area = World.area(fieldID) else { return }
        let areaID = fieldID
        let goal = profile.characterLevel + 1
        let start = seconds
        for _ in 0..<6 where profile.characterLevel < goal {
            clear(areaID, which: { !area.isPermanent($0) })
        }
        result.grinds.append(String(format: "%@: +1 nivel en %.0f min", area.name, (seconds - start) / 60))
        note("· sube de nivel en \(area.name) para volver a intentarlo")
    }

    /// Vuelve al pueblo: habla con todos (acepta y entrega) y pasa por la forja.
    func backToTown() {
        talkInTown()
        visitForge()
    }

    private func boss(_ enemyID: String, in areaID: String) {
        clear(areaID, which: { $0.enemyID == enemyID })
    }

    func run() -> StoryRunResult {
        visitForge()
        checkpoint("Inicio")
        // 1. Pueblo: calles y casas por nivel (sin el patio); a la forja tras cada zona.
        let town = Valdehierro.town
        let houses = Valdehierro.interiors.filter { a in a.npcs.contains { Valdehierro.villagerIDs.contains($0.id) } }
        var stops: [(level: Int, id: String)] = town.zones.filter { $0.id != "courtyard" }.map { ($0.level, $0.id) }
        stops += houses.map { ($0.level, $0.id) }
        for stop in stops.sorted(by: { ($0.level, $0.id) < ($1.level, $1.id) }) {
            if let house = houses.first(where: { $0.id == stop.id }) {
                clear(house.id)
                for npc in house.npcs where npc.role == .villager {
                    s.npcReached(npc)
                    skipDialogs()
                }
            } else {
                clear(town.id, which: { town.zone(at: $0.position)?.id == stop.id }, reenter: s.areaID != town.id)
            }
            visitForge()
        }
        // Lo que se le resistió (la Bruja…), una vez más con el equipo nuevo.
        for house in houses where !profile.town.rescued.contains(where: { id in house.npcs.contains { $0.id == id } }) {
            clear(house.id)
            for npc in house.npcs where npc.role == .villager { s.npcReached(npc); skipDialogs() }
        }
        checkpoint("Pueblo liberado")
        if !profile.isQuestDone(ValdemarQuests.liberar) { result.blocked.append("pueblo sin liberar") }
        backToTown()

        // 2. Fuera, por nivel de área.
        clear("valdemar.huertos")
        farm(ValdemarQuests.molino)
        backToTown()
        checkpoint("Tras los Huertos")
        clear("valdemar.robleda")
        farm(ValdemarQuests.cazaMayor)
        farm(ValdemarQuests.hilos)
        backToTown()
        checkpoint("Tras Robleda")
        if profile.isQuestDone(ValdemarQuests.hilos) {
            clear("mayor")
            if let letter = Valdehierro.area("mayor")?.npcs.first(where: { $0.role == .clue }) {
                s.npcReached(letter)
                skipDialogs()
            }
            backToTown()
        } else {
            result.blocked.append("casa del alcalde cerrada")
        }
        checkpoint("Tras la casa del alcalde")
        clear("valdemar.abadia")
        farm(ValdemarQuests.abadia)
        dungeon("valdemar.cripta")
        backToTown()
        checkpoint("Tras la Abadía y la Cripta")
        clear("valdemar.pedregal")
        farm(ValdemarQuests.pedregal)
        farm(ValdemarQuests.pociones)
        backToTown()
        // Segundo intento con los jefes que le pararon (con más nivel y equipo).
        if !profile.hasDefeatedInStory("ogre") { boss("ogre", in: "valdemar.huertos") }
        if !profile.hasDefeatedInStory("alphaWolf") { boss("alphaWolf", in: "valdemar.robleda") }
        if !(profile.wonDungeons ?? []).contains("valdemar.cripta") { dungeon("valdemar.cripta") }
        if !profile.hasDefeatedInStory("warlord") { boss("warlord", in: "valdemar.pedregal") }
        backToTown()
        checkpoint("Antes del patio")

        // 3. Castillo (solo si el Capitán lo abre).
        if profile.isCastleOpen() {
            clear(town.id, which: { town.zone(at: $0.position)?.id == "courtyard" })
            clear("castle")
            if let castle = Valdehierro.area("castle"), profile.town.isCleared(castle),
               let princess = castle.npcs.first(where: { $0.role == .princess }) {
                s.npcReached(princess)
                skipDialogs()
            }
        } else {
            result.blocked.append("castillo cerrado")
        }
        checkpoint("Tras el Rey Goblin")
        // 4. Epílogo en la forja → tier 2 y Paso del Norte.
        if profile.isQuestDone(ValdemarQuests.reyGoblin) {
            enter(town.id, at: town.entry)
            if let smithy = town.buildings.first(where: { $0.interiorID == "smithy" }) {
                s.doorTouched(smithy)
                skipDialogs()
            }
            if fixedGear {
                var p = store.profile
                Self.equip(&p, tier: 2)
                store.profile = p
            }
            backToTown()
            clear("valdemar.paso")
        } else {
            result.blocked.append("sin Rey Goblin")
        }
        checkpoint("Fin (Paso del Norte, forja T2)")
        // 5. Opcional: Calabozos.
        if profile.isCastleOpen() {
            backToTown()
            dungeon("valdemar.calabozos")
            backToTown()
        }
        checkpoint("+ Calabozos (opcional)")
        result.kills = profile.town.killedSpawns.count
        result.questXP = profile.finishedQuests.map(\.reward.xp).reduce(0, +)
        return result
    }
}

@MainActor
func storySimulation() {
    let args = CommandLine.arguments.dropFirst(2)
    let runs = args.compactMap { Int($0) }.first ?? 3
    let verbose = args.contains("-v")
    let dodgeSkill = args.contains("--sin-esquivar") ? 0 : 0.7
    let fixedGear = args.contains("--fijo")
    print("Modo historia de Valdemar: bot con equipo T1 (T2 tras el Rey Goblin), combate real, \(runs) partidas, "
          + (dodgeSkill > 0 ? "esquiva el \(Int(dodgeSkill * 100)) % de los golpes avisados (\(Int(min(1, dodgeSkill + 0.15) * 100)) % los de jefe)" : "sin esquivar"))
    let t1 = StoryBot.gearCost(tier: 1), t2 = StoryBot.gearCost(tier: 2)
    print(fixedGear ? "  Equipo fijo: espada Normal T1 sin minerales + 4 armaduras T1 (T2 tras el Rey Goblin); no compra."
                    : "  Equipo: el de una partida nueva; en cada visita a la forja forja la mejor arma (piezas del tier de la forja"
                      + " o de jefe, 12 mejores minerales, calidad Normal) y compra las armaduras que le falten.")
    print("  Precios: piezas de espada T1 \(t1.weapon) + ritual 15 · armaduras T1 (forja) \(t1.armor) · T2: \(t2.weapon) + 25 · \(t2.armor)")
    if verbose {
        print("  Piezas de jefe de Valdemar: " + PartCatalog.storyBossParts.map { String(format: "%@ ATQ %.1f", $0.name, $0.stats.attack) }
            .joined(separator: " · ") + String(format: " · Hoja del Alba ATQ %.0f (T%d)", PartCatalog.part("legend.dawn")?.stats.attack ?? 0,
                                               PartCatalog.part("legend.dawn")?.tier ?? 0))
    }
    var all: [StoryRunResult] = []
    for i in 0..<runs {
        if verbose { print("    partida \(i + 1):") }
        all.append(StoryBot(verbose: verbose, dodgeSkill: dodgeSkill, fixedGear: fixedGear).run())
    }
    func median(_ xs: [Double]) -> Double { let s = xs.sorted(); return s[s.count / 2] }
    func medianInt(_ xs: [Int]) -> Int { let s = xs.sorted(); return s[s.count / 2] }
    print("\n  Momento                              Nivel (mediana · partidas)        Muertes  Oro    Minerales (Cu/Fe/Ag/Au/Esm)  Min.")
    for (i, cp) in all[0].checkpoints.enumerated() {
        let cps = all.map { $0.checkpoints[i] }
        let levels = cps.map(\.level)
        let minerals = [Mineral.copper, .iron, .silver, .gold, .emerald].map { m in medianInt(cps.map { $0.minerals[m] ?? 0 }) }
        let others = medianInt(cps.map { $0.minerals.filter { ![.copper, .iron, .silver, .gold, .emerald].contains($0.key) }.values.reduce(0, +) })
        print("  " + cp.name.padding(toLength: 37, withPad: " ", startingAt: 0)
              + String(format: "%4.1f ", median(levels))
              + ("(" + levels.map { String(format: "%.1f", $0) }.joined(separator: " ") + ")").padding(toLength: 29, withPad: " ", startingAt: 0)
              + String(format: "%5d  %5d  ", medianInt(cps.map(\.deaths)), medianInt(cps.map(\.gold)))
              + minerals.map(String.init).joined(separator: "/").padding(toLength: 18, withPad: " ", startingAt: 0)
              + (others > 0 ? "+\(others) otros " : "          ")
              + String(format: "%5.0f", median(cps.map(\.minutes))))
    }
    print("\n  Nivel al llegar (mediana):")
    var order: [String] = []
    var byPlace: [String: (Int, [Double])] = [:]
    for r in all { for (name, zl, lv) in r.arrivals { if byPlace[name] == nil { order.append(name); byPlace[name] = (zl, []) }; byPlace[name]!.1.append(lv) } }
    for name in order {
        let (zl, lvs) = byPlace[name]!
        let m = median(lvs)
        let mark = m + 0.5 < Double(zl) ? "  ← por debajo" : (m >= Double(zl) + 2 ? "  ← sobrado" : "")
        print("    " + name.padding(toLength: 52, withPad: " ", startingAt: 0) + String(format: "zona %2d · héroe %4.1f", zl, m) + mark)
    }
    var bosses: [String: [Double]] = [:]
    var bossOrder: [String] = []
    for r in all { for (name, secs) in r.bossFights { if bosses[name] == nil { bossOrder.append(name) }; bosses[name, default: []].append(secs) } }
    print("\n  Jefes (segundos desde que te ven hasta que caen; mediana): "
          + bossOrder.map { String(format: "%@ %.0f", $0, median(bosses[$0]!)) }.joined(separator: " · "))
    let deaths = all.flatMap(\.deathsAt)
    print("  Muertes (\(deaths.count) en \(runs) partidas): " + (deaths.isEmpty ? "ninguna" : Dictionary(grouping: deaths.map { $0.components(separatedBy: " con nivel").first! }, by: { $0 })
        .map { "\($0.key) ×\($0.value.count)" }.sorted().joined(separator: " · ")))
    let walls = all.flatMap(\.walls)
    if !walls.isEmpty { print("  ⚠︎ Muros (3 muertes seguidas, lo deja): " + walls.joined(separator: " · ")) }
    let stuck = all.flatMap(\.stuck)
    if !stuck.isEmpty { print("  ⚠︎ Atascos (150 s sin acabar): " + stuck.prefix(8).joined(separator: " · ")) }
    let grinds = all.flatMap(\.grinds)
    if !grinds.isEmpty { print("  Sube de nivel ante un muro (\(grinds.count) veces en \(runs) partidas): " + grinds.joined(separator: " · ")) }
    let blocked = all.flatMap(\.blocked)
    if !blocked.isEmpty { print("  ⚠︎ No llega: " + blocked.joined(separator: " · ")) }
    if verbose { for (i, r) in all.enumerated() { print("  Forja, partida \(i + 1): " + r.forged.joined(separator: " · ")) } }
    print(String(format: "  XP de misiones (mediana): %d de %d en total", medianInt(all.map(\.questXP)), medianInt(all.map { $0.checkpoints.last!.xp })))
}
