import Foundation

// MARK: - Datos efectivos (código + ajustes)
//
// Instantánea con todas las tablas del juego ya ajustadas. `GameTuning.apply` crea una nueva a partir de los valores
// del código y la cambia de golpe; los sitios de lectura (`Bestiary.all`, `PartCatalog.part`, `Mineral.value`,
// `Arena.reward`…) leen de `TunedData.current` sin buscar ajustes: todo está precalculado.
//
// Las instantáneas antiguas no se liberan nunca (se aplican pocas, al abrir el juego): así, si otro hilo estaba
// leyendo la anterior mientras se cambia, sigue siendo válida.

/// Números globales efectivos. Los valores por defecto son los del código (antes, constantes sueltas): cada uno indica
/// dónde se usa. Rangos y descripción: `TuningSchema.economy`.
public struct EconomyValues: Equatable, Sendable {
    /// `Mineral.dropRateMultiplier`: los minerales son escasos.
    public var mineralDropRate = 0.15
    /// `Continent.familyWeights`: pesos de la familia del continente (`progresion.md` §5).
    public var continentLootWeights: [Double] = [35, 27, 20, 12, 6]
    /// `PlayerProfile.arenaRun`: oro inicial de la arena.
    public var arenaStartingGold = 50.0
    /// `Arena.reward(wave:)` = 16 + 7 × oleada.
    public var arenaRewardBase = 16.0
    public var arenaRewardPerWave = 7.0
    /// `Arena.shopLevel(wave:)` = oleada ÷ 2 (1…10).
    public var arenaWavesPerShopLevel = 2.0
    /// `Arena.wallWave`.
    public var wallWave = 20.0
    /// `Leveling.arenaBossMultiplier`, `storyBossMultiplier`, `respawningMultiplier`.
    public var arenaBossXPMultiplier = 12.0
    public var storyBossXPMultiplier = 6.0
    public var respawningXPMultiplier = 0.3
    /// `Leveling.xpToNext` = 50 × nivel^1,6 + 30.
    public var xpCurveBase = 50.0
    public var xpCurveExponent = 1.6
    public var xpCurveFlat = 30.0
    /// `Leveling.levelBonus`: vida 8 % y ataque 8,5 % de la raza por nivel, +0,6 de defensa.
    public var levelHPGrowth = 0.08
    public var levelAttackGrowth = 0.085
    public var levelDefensePerLevel = 0.6
    /// `EnemyDefinition.stats(level:)`.
    public var enemyHPPerLevel = 0.13
    public var enemyHPDifficulty = 0.11
    public var enemyDamagePerLevel = 0.10
    public var enemyDamageDifficulty = 0.09
    public var enemySpeedPerLevel = 0.02
    /// `StoryEconomy.killGold` = 1 + nivel ÷ 3 (+ 10 × nivel los jefes) y `zoneGold` = 3 × nivel.
    public var storyKillGoldBase = 1.0
    public var storyKillGoldLevelsPerCoin = 3.0
    public var storyBossGoldPerLevel = 10.0
    public var storyZoneGoldPerLevel = 3.0
    /// `StoryDungeon.repeatPartChance`.
    public var storyDungeonRepeatPartChance = 0.25
    /// `WeaponRecipe.goldCost` = 10 × tier + 5.
    public var forgeGoldBase = 5.0
    public var forgeGoldPerTier = 10.0
    /// `ShopGenerator.rerollCost` = 10 + 10 × renovaciones.
    public var rerollBaseCost = 10.0
    public var rerollCostStep = 10.0
    /// Poción de la forja: precio 15 + 5 × nivel, cura el 50 %.
    public var potionBasePrice = 15.0
    public var potionPricePerLevel = 5.0
    public var potionHeal = 0.5

    public static let base = EconomyValues()
}

/// Tablas del juego con los ajustes aplicados.
final class TunedData: @unchecked Sendable {
    var tuning = GameTuning()
    var warnings: [String] = []

    var enemies: [EnemyDefinition] = Bestiary.baseAll
    var enemyByID: [String: EnemyDefinition] = [:]
    var storyBossTuning: [String: (hp: Double, damage: Double)] = EnemyDefinition.baseStoryBossTuning

    var normalParts: [WeaponPart] = PartCatalog.baseNormalParts
    var specialParts: [WeaponPart] = PartCatalog.baseSpecialParts
    var storyBossParts: [WeaponPart] = PartCatalog.baseStoryBossParts
    var allParts: [WeaponPart] = []
    var partByID: [String: WeaponPart] = [:]

    var armorStyles: [ArmorStyle] = ArmorCatalog.baseStyles
    var armorByID: [String: ArmorStyle] = [:]

    /// Por `Mineral.ordinal`.
    var mineralValues: [Int] = Mineral.allCases.map(\.baseValue)
    var mineralDropPercents: [Double] = Mineral.allCases.map(\.baseDropPercent)
    var mineralBuffs: [Stats] = Mineral.allCases.map(\.baseBuffPerUnit)
    var mineralLoot: [(Mineral, Double)] = []

    var town: AreaMap = Valdehierro.baseTown
    var interiors: [AreaMap] = Valdehierro.baseInteriors
    var fieldAreas: [AreaMap] = Valdemar.baseAreas
    var dungeons: [StoryDungeon] = Valdemar.baseDungeons
    var quests: [Quest] = ValdemarQuests.baseQuests

    var roulette: [CraftQuality] = Roulette.baseSegments
    var economy = EconomyValues.base

    init() { reindex() }

    /// Recalcula los índices después de cambiar las tablas.
    func reindex() {
        enemyByID = Dictionary(uniqueKeysWithValues: enemies.map { ($0.id, $0) })
        allParts = normalParts + specialParts + storyBossParts
        partByID = Dictionary(uniqueKeysWithValues: allParts.map { ($0.id, $0) })
        armorByID = Dictionary(uniqueKeysWithValues: armorStyles.map { ($0.id, $0) })
        mineralLoot = Array(zip(Mineral.allCases, mineralDropPercents))
    }

    /// Los valores del código, sin ajustes.
    static let base = TunedData()

    /// Lo que lee el juego.
    private(set) static var current = base
    private static var retired: [TunedData] = []
    private static let lock = NSLock()

    static func install(_ data: TunedData) {
        lock.lock()
        defer { lock.unlock() }
        retired.append(current)
        current = data
    }
}

// MARK: - Aplicar

extension GameTuning {
    /// Ajustes aplicados ahora mismo (vacío si no se ha aplicado ninguno).
    public static var current: GameTuning { TunedData.current.tuning }

    /// Avisos del último `apply`.
    public static var lastWarnings: [String] { TunedData.current.warnings }

    /// Aplica los ajustes sobre los valores del código y devuelve los avisos (ids desconocidos, valores recortados…).
    /// No acumula: `apply(GameTuning())` vuelve a los valores de serie.
    @discardableResult
    public static func apply(_ tuning: GameTuning) -> [String] {
        if tuning == TunedData.current.tuning, tuning.decodingWarnings == TunedData.current.tuning.decodingWarnings {
            return TunedData.current.warnings
        }
        let data = resolve(tuning)
        TunedData.install(data)
        return data.warnings
    }

    /// Calcula las tablas ajustadas sin instalarlas (lo usan `apply` y los tests).
    static func resolve(_ tuning: GameTuning) -> TunedData {
        var r = Resolver(data: TunedData())
        r.warnings = tuning.decodingWarnings
        if tuning.schemaVersion > currentSchemaVersion {
            r.warnings.append("schemaVersion \(tuning.schemaVersion) es más nueva que la del juego (\(currentSchemaVersion)): "
                              + "se aplica lo que se entiende")
        }
        r.enemies(tuning.enemies ?? [:])
        r.parts(tuning.parts ?? [:])
        r.armor(tuning.armor ?? [:])
        r.minerals(tuning.minerals ?? [:])
        r.world(areas: tuning.areas ?? [:], zones: tuning.zones ?? [:], spawns: tuning.spawns ?? [:],
                dungeons: tuning.dungeons ?? [:])
        r.quests(tuning.quests ?? [:])
        r.rescues(tuning.rescues ?? [:])
        r.roulette(tuning.roulette ?? [:])
        r.economy(tuning.economy ?? EconomyTuning())
        r.data.reindex()
        r.data.tuning = tuning
        r.data.warnings = r.warnings
        return r.data
    }
}

/// Valida y aplica cada apartado sobre una copia de los valores del código.
private struct Resolver {
    let data: TunedData
    var warnings: [String] = []

    init(data: TunedData) { self.data = data }

    /// Valor recortado de un campo (nil si no viene o no vale).
    mutating func value(_ v: Double?, _ key: String, _ fields: [TuningField], _ context: String) -> Double? {
        guard let v, let field = fields.first(where: { $0.key == key }) else { return nil }
        return field.clamp(v, context, &warnings)
    }

    /// Cambia en `stats` las estadísticas que vienen (clave de `StatKind`), recortadas a su rango.
    mutating func stats(_ map: [String: Double]?, into stats: inout Stats, _ context: String) {
        for (key, v) in (map ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let kind = StatKind(rawValue: key), let field = TuningSchema.stats[kind] else {
                warnings.append("\(context).stats.\(key): estadística desconocida; se ignora")
                continue
            }
            if let clamped = field.clamp(v, "\(context).stats", &warnings) { stats[kind] = clamped }
        }
    }

    mutating func unknown(_ section: String, _ id: String, _ what: String) {
        warnings.append("\(section).\(id): \(what) desconocido; se ignora")
    }

    // MARK: Monstruos

    mutating func enemies(_ map: [String: EnemyTuning]) {
        let fields = TuningSchema.enemy
        for (id, t) in map.sorted(by: { $0.key < $1.key }) {
            guard let i = data.enemies.firstIndex(where: { $0.id == id }) else {
                unknown("enemies", id, "monstruo")
                continue
            }
            let ctx = "enemies.\(id)"
            var e = data.enemies[i]
            if let v = value(t.hp, "hp", fields, ctx) { e.hp = v }
            if let v = value(t.damage, "damage", fields, ctx) { e.damage = v }
            if let v = value(t.speed, "speed", fields, ctx) { e.speed = v }
            if let v = value(t.attackCooldown, "attackCooldown", fields, ctx) { e.attackCooldown = v }
            if let v = value(t.attackRange, "attackRange", fields, ctx) {
                let limits = TuningSchema.rangeLimits(e.behavior)
                let clamped = min(limits.upperBound, max(limits.lowerBound, v))
                if clamped != v {
                    warnings.append("\(ctx).attackRange: \(TuningField.format(v)) no vale para un monstruo "
                                    + "\(e.behavior == .ranged ? "a distancia" : "cuerpo a cuerpo") "
                                    + "[\(TuningField.format(limits.lowerBound)), \(TuningField.format(limits.upperBound))]; "
                                    + "se usa \(TuningField.format(clamped))")
                }
                e.attackRange = clamped
            }
            if let v = value(t.level, "level", fields, ctx) { e.level = Int(v) }
            if let v = value(t.dropChance, "dropChance", fields, ctx) { e.dropChance = v }
            if let v = value(t.dropRolls, "dropRolls", fields, ctx) { e.dropRolls = Int(v) }
            if let v = value(t.xpMultiplier, "xpMultiplier", fields, ctx) { e.xpMultiplier = v }
            if let v = value(t.goldMultiplier, "goldMultiplier", fields, ctx) { e.goldMultiplier = v }
            if t.storyHPMultiplier != nil || t.storyDamageMultiplier != nil {
                if e.isBoss {
                    var story = data.storyBossTuning[id] ?? (1, 1)
                    if let v = value(t.storyHPMultiplier, "storyHPMultiplier", fields, ctx) { story.hp = v }
                    if let v = value(t.storyDamageMultiplier, "storyDamageMultiplier", fields, ctx) { story.damage = v }
                    data.storyBossTuning[id] = story
                } else {
                    warnings.append("\(ctx): storyHPMultiplier/storyDamageMultiplier solo valen para jefes; se ignoran")
                }
            }
            data.enemies[i] = e
        }
    }

    // MARK: Piezas y armaduras

    mutating func parts(_ map: [String: PartTuning]) {
        for (id, t) in map.sorted(by: { $0.key < $1.key }) {
            let ctx = "parts.\(id)"
            func tune(_ part: inout WeaponPart, _ r: inout Resolver) {
                r.stats(t.stats, into: &part.stats, ctx)
                if let v = r.value(t.price, "price", TuningSchema.part, ctx) { part.price = Int(v) }
                if let v = r.value(t.tier, "tier", TuningSchema.part, ctx) { part.tier = Int(v) }
            }
            let d = data
            if let i = d.normalParts.firstIndex(where: { $0.id == id }) {
                tune(&d.normalParts[i], &self)
            } else if let i = d.specialParts.firstIndex(where: { $0.id == id }) {
                tune(&d.specialParts[i], &self)
            } else if let i = d.storyBossParts.firstIndex(where: { $0.id == id }) {
                tune(&d.storyBossParts[i], &self)
            } else {
                unknown("parts", id, "pieza")
            }
        }
    }

    mutating func armor(_ map: [String: ArmorTuning]) {
        for (id, t) in map.sorted(by: { $0.key < $1.key }) {
            guard let i = data.armorStyles.firstIndex(where: { $0.id == id }) else {
                unknown("armor", id, "diseño de armadura")
                continue
            }
            let ctx = "armor.\(id)", d = data
            stats(t.stats, into: &d.armorStyles[i].base, ctx)
            if let v = value(t.price, "price", TuningSchema.armor, ctx) { data.armorStyles[i].priceOverride = v }
        }
    }

    // MARK: Minerales

    mutating func minerals(_ map: [String: MineralTuning]) {
        for (id, t) in map.sorted(by: { $0.key < $1.key }) {
            guard let mineral = Mineral(rawValue: id) else {
                unknown("minerals", id, "mineral")
                continue
            }
            let ctx = "minerals.\(id)", i = mineral.ordinal
            if let v = value(t.value, "value", TuningSchema.mineral, ctx) { data.mineralValues[i] = Int(v) }
            if let v = value(t.dropWeight, "dropWeight", TuningSchema.mineral, ctx) { data.mineralDropPercents[i] = v }
            let d = data
            stats(t.stats, into: &d.mineralBuffs[i], ctx)
        }
        if data.mineralDropPercents.reduce(0, +) <= 0 {
            warnings.append("minerals: los pesos de botín suman 0; se usan los de serie")
            data.mineralDropPercents = Mineral.allCases.map(\.baseDropPercent)
        }
    }

    // MARK: Mundo: áreas, zonas, spawns y mazmorras

    mutating func world(areas: [String: AreaTuning], zones: [String: ZoneTuning], spawns: [String: String],
                        dungeons: [String: DungeonTuning]) {
        // Todas las áreas en una lista (pueblo, interiores y campo) y se reparten al final.
        var all = [data.town] + data.interiors + data.fieldAreas
        let base = all

        for (id, t) in areas.sorted(by: { $0.key < $1.key }) {
            guard let i = all.firstIndex(where: { $0.id == id }) else {
                unknown("areas", id, "área")
                continue
            }
            if let v = value(t.level, "level", TuningSchema.area, "areas.\(id)") { all[i].level = Int(v) }
        }

        for (id, t) in zones.sorted(by: { $0.key < $1.key }) {
            var found = false
            for a in all.indices {
                for z in all[a].zones.indices where all[a].zones[z].id == id {
                    found = true
                    if let v = value(t.level, "level", TuningSchema.zone, "zones.\(id)") { all[a].zones[z].level = Int(v) }
                }
            }
            if !found { unknown("zones", id, "zona") }
        }

        for (id, enemyID) in spawns.sorted(by: { $0.key < $1.key }) {
            guard let a = all.firstIndex(where: { $0.spawns.contains { $0.id == id } }),
                  let s = all[a].spawns.firstIndex(where: { $0.id == id }) else {
                unknown("spawns", id, "punto de aparición")
                continue
            }
            guard let enemy = data.enemyByIDBeforeIndex(enemyID) else {
                warnings.append("spawns.\(id): monstruo «\(enemyID)» desconocido; se ignora")
                continue
            }
            let current = data.enemyByIDBeforeIndex(all[a].spawns[s].enemyID)
            if current?.isBoss == true || enemy.isBoss {
                warnings.append("spawns.\(id): los jefes no se cambian ni se ponen en otro sitio (misiones y piezas); se ignora")
                continue
            }
            all[a].spawns[s].enemyID = enemyID
        }

        for (id, t) in dungeons.sorted(by: { $0.key < $1.key }) {
            guard let i = data.dungeons.firstIndex(where: { $0.id == id }) else {
                unknown("dungeons", id, "mazmorra")
                continue
            }
            let ctx = "dungeons.\(id)"
            if let v = value(t.level, "level", TuningSchema.dungeon, ctx) { data.dungeons[i].level = Int(v) }
            if let waves = t.waves {
                if !TuningSchema.dungeonWaves.contains(waves.count) {
                    warnings.append("\(ctx).waves: hacen falta entre \(TuningSchema.dungeonWaves.lowerBound) y "
                                    + "\(TuningSchema.dungeonWaves.upperBound) oleadas; se ignoran")
                } else {
                    let cleaned = waves.enumerated().map { n, wave in monsterCounts(wave, "\(ctx).waves[\(n)]") }
                    if cleaned.contains(where: \.isEmpty) {
                        warnings.append("\(ctx).waves: alguna oleada se queda sin monstruos; se ignoran")
                    } else {
                        data.dungeons[i].waves = cleaned
                    }
                }
            }
            if let escort = t.bossEscort {
                data.dungeons[i].bossEscort = monsterCounts(escort, "\(ctx).bossEscort")
            }
        }

        // Que ninguna misión de "mata N de X" se quede sin monstruos donde se pide.
        for quest in data.quests {
            for case .kill(let ids, _, let areaID) in quest.objectives {
                let wanted = Set(ids)
                if let areaID {
                    guard let a = all.firstIndex(where: { $0.id == areaID }),
                          !all[a].spawns.contains(where: { wanted.contains($0.enemyID) }) else { continue }
                    warnings.append("spawns: «\(quest.id)» necesita \(ids.joined(separator: "/")) en \(areaID); "
                                    + "se deshacen los cambios de spawns de esa área")
                    all[a].spawns = base[a].spawns
                } else {
                    let anywhere = all.contains { $0.spawns.contains { wanted.contains($0.enemyID) } }
                        || data.dungeons.contains { !$0.enemyIDs.isDisjoint(with: wanted) }
                    guard !anywhere else { continue }
                    warnings.append("spawns: «\(quest.id)» necesita \(ids.joined(separator: "/")) en algún sitio; "
                                    + "se deshacen todos los cambios de spawns")
                    for a in all.indices { all[a].spawns = base[a].spawns }
                }
            }
        }

        data.town = all[0]
        data.interiors = Array(all[1...data.interiors.count])
        data.fieldAreas = Array(all[(1 + data.interiors.count)...])
    }

    /// Cuántos de cada monstruo (sin jefes ni ids desconocidos), recortado a su rango.
    private mutating func monsterCounts(_ map: [String: Int], _ context: String) -> [String: Int] {
        var out: [String: Int] = [:]
        for (enemyID, count) in map.sorted(by: { $0.key < $1.key }) {
            guard let enemy = data.enemyByIDBeforeIndex(enemyID) else {
                warnings.append("\(context).\(enemyID): monstruo desconocido; se ignora")
                continue
            }
            guard !enemy.isBoss else {
                warnings.append("\(context).\(enemyID): los jefes no van en oleadas ni escoltas; se ignora")
                continue
            }
            let field = TuningSchema.dungeonCount
            if let n = field.clamp(Double(count), "\(context).\(enemyID)", &warnings), n > 0 { out[enemyID] = Int(n) }
        }
        return out
    }

    // MARK: Recompensas

    private mutating func mineralCounts(_ map: [String: Int]?, _ context: String) -> [Mineral: Int]? {
        guard let map else { return nil }
        var out: [Mineral: Int] = [:]
        for (id, count) in map.sorted(by: { $0.key < $1.key }) {
            guard let mineral = Mineral(rawValue: id) else {
                warnings.append("\(context).minerals.\(id): mineral desconocido; se ignora")
                continue
            }
            if let n = TuningSchema.rewardMineral.clamp(Double(count), "\(context).minerals.\(id)", &warnings), n > 0 {
                out[mineral] = Int(n)
            }
        }
        return out
    }

    mutating func quests(_ map: [String: RewardTuning]) {
        for (id, t) in map.sorted(by: { $0.key < $1.key }) {
            guard let i = data.quests.firstIndex(where: { $0.id == id }) else {
                unknown("quests", id, "misión")
                continue
            }
            let ctx = "quests.\(id)"
            if let v = value(t.xp, "xp", TuningSchema.reward, ctx) { data.quests[i].reward.xp = Int(v) }
            if let v = value(t.gold, "gold", TuningSchema.reward, ctx) { data.quests[i].reward.gold = Int(v) }
            if let m = mineralCounts(t.minerals, ctx) { data.quests[i].reward.minerals = m }
        }
    }

    mutating func rescues(_ map: [String: RewardTuning]) {
        for (id, t) in map.sorted(by: { $0.key < $1.key }) {
            let ctx = "rescues.\(id)"
            if t.xp != nil { warnings.append("\(ctx).xp: los rescates no dan experiencia; se ignora") }
            let gold = value(t.gold, "gold", TuningSchema.reward, ctx).map { Int($0) }
            let minerals = mineralCounts(t.minerals, ctx)
            var found = false
            func tune(_ areas: inout [AreaMap]) {
                for a in areas.indices {
                    for n in areas[a].npcs.indices where areas[a].npcs[n].id == id
                        && (areas[a].npcs[n].role == .villager || areas[a].npcs[n].role == .princess) {
                        found = true
                        if let gold { areas[a].npcs[n].reward.gold = gold }
                        if let minerals { areas[a].npcs[n].reward.minerals = minerals }
                    }
                }
            }
            // Se rescatan dentro de su casa (o del salón del trono): la copia de la calle no da nada.
            tune(&data.interiors)
            if !found { unknown("rescues", id, "aldeano rescatable") }
        }
    }

    // MARK: Ruleta y economía

    mutating func roulette(_ map: [String: RouletteTuning]) {
        for (id, t) in map.sorted(by: { $0.key < $1.key }) {
            guard let i = data.roulette.firstIndex(where: { $0.id == id }) else {
                unknown("roulette", id, "casilla")
                continue
            }
            let ctx = "roulette.\(id)"
            if let v = value(t.weight, "weight", TuningSchema.roulette, ctx) { data.roulette[i].weight = v }
            if let v = value(t.multiplier, "multiplier", TuningSchema.roulette, ctx) { data.roulette[i].multiplier = v }
        }
        if data.roulette.map(\.weight).reduce(0, +) <= 0 {
            warnings.append("roulette: los pesos suman 0; se usan los de serie")
            data.roulette = Roulette.baseSegments
        }
    }

    mutating func economy(_ t: EconomyTuning) {
        for entry in TuningSchema.economy {
            guard let v = t[keyPath: entry.tuning] else { continue }
            if let clamped = entry.field.clamp(v, "economy", &warnings) { data.economy[keyPath: entry.value] = clamped }
        }
        if let weights = t.continentLootWeights {
            let count = EconomyValues.base.continentLootWeights.count
            if weights.count != count {
                warnings.append("economy.continentLootWeights: hacen falta \(count) pesos; se ignoran")
            } else {
                let clamped = weights.map { TuningSchema.lootWeight.clamp($0, "economy", &warnings) ?? 0 }
                if clamped.reduce(0, +) > 0 {
                    data.economy.continentLootWeights = clamped
                } else {
                    warnings.append("economy.continentLootWeights: suman 0; se ignoran")
                }
            }
        }
    }
}

private extension TunedData {
    /// Búsqueda por id en `enemies` mientras se resuelve (el índice se rehace al final).
    func enemyByIDBeforeIndex(_ id: String) -> EnemyDefinition? {
        enemies.first { $0.id == id }
    }
}
