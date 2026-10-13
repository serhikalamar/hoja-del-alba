import Foundation

// MARK: - Esquema de los ajustes: rangos, tipos y descripciones
//
// Una sola fuente para tres cosas: validar al aplicar (`GameTuning.resolve`), avisar de campos desconocidos y
// exportar `esquema.json` para el panel web (`make datos`). Si añades un campo ajustable, añádelo aquí.

/// Un campo numérico ajustable.
public struct TuningField: Sendable {
    /// Nombre en el JSON.
    public let key: String
    public let min: Double
    public let max: Double
    /// Se redondea al entero más cercano.
    public let integer: Bool
    /// Qué es, en español (lo muestra el panel).
    public let description: String
    /// A qué valor del código corresponde.
    public let code: String

    public init(_ key: String, _ min: Double, _ max: Double, integer: Bool = false, _ description: String, code: String) {
        self.key = key
        self.min = min
        self.max = max
        self.integer = integer
        self.description = description
        self.code = code
    }

    /// Valor recortado al rango (y redondeado si es entero). Apunta un aviso si cambia o no es un número válido.
    func clamp(_ value: Double, _ context: String, _ warnings: inout [String]) -> Double? {
        guard value.isFinite else {
            warnings.append("\(context).\(key): no es un número válido; se ignora")
            return nil
        }
        var v = Swift.min(max, Swift.max(min, value))
        if v != value {
            warnings.append("\(context).\(key): \(TuningField.format(value)) fuera de rango [\(TuningField.format(min)), "
                            + "\(TuningField.format(max))]; se usa \(TuningField.format(integer ? v.rounded() : v))")
        } else if integer, v != v.rounded() {
            warnings.append("\(context).\(key): \(TuningField.format(value)) no es entero; se usa \(TuningField.format(v.rounded()))")
        }
        if integer { v = v.rounded() }
        return v
    }

    static func format(_ v: Double) -> String {
        v == v.rounded() && abs(v) < 1e15 ? String(Int(v)) : String(v)
    }
}

/// Un campo de `economy`: su valor efectivo vive en `EconomyValues`.
public struct EconomyField: @unchecked Sendable {
    public let field: TuningField
    let tuning: WritableKeyPath<EconomyTuning, Double?>
    let value: WritableKeyPath<EconomyValues, Double>

    /// Valor del código.
    public var base: Double { EconomyValues.base[keyPath: value] }
}

public enum TuningSchema {
    // MARK: Monstruos

    public static let enemy: [TuningField] = [
        TuningField("hp", 1, 1_000_000, "Vida en su nivel de aparición", code: "EnemyDefinition.hp"),
        TuningField("damage", 0, 100_000, "Daño por golpe o proyectil en su nivel de aparición", code: "EnemyDefinition.damage"),
        TuningField("speed", 10, 250, "Velocidad de movimiento (puntos/s; el héroe va a 125)", code: "EnemyDefinition.speed"),
        TuningField("attackCooldown", 0.8, 10, "Segundos entre ataques (mínimo 0,8: el más rápido del juego)",
                    code: "EnemyDefinition.attackCooldown"),
        TuningField("attackRange", 4, 300, "Alcance del ataque: cuerpo a cuerpo y embestida 4-40; a distancia 60-300",
                    code: "EnemyDefinition.attackRange"),
        TuningField("level", 1, 60, integer: true, "Nivel de aparición: en qué oleadas de la arena sale y desde dónde escala",
                    code: "EnemyDefinition.level"),
        TuningField("dropChance", 0, 1, "Probabilidad de soltar mineral en cada tirada (1 = siempre, como los jefes)",
                    code: "EnemyDefinition.dropChance"),
        TuningField("dropRolls", 0, 10, integer: true, "Tiradas de mineral al morir", code: "EnemyDefinition.dropRolls"),
        TuningField("xpMultiplier", 0, 10, "Multiplicador de la experiencia que da", code: "EnemyDefinition.xpMultiplier"),
        TuningField("goldMultiplier", 0, 10, "Multiplicador del oro que da en la historia (en la arena se cobra por oleada)",
                    code: "EnemyDefinition.goldMultiplier"),
        TuningField("storyHPMultiplier", 0.1, 10, "Solo jefes: multiplicador de vida en la historia",
                    code: "EnemyDefinition.storyBossTuning[id].hp"),
        TuningField("storyDamageMultiplier", 0.1, 10, "Solo jefes: multiplicador de daño en la historia",
                    code: "EnemyDefinition.storyBossTuning[id].damage"),
    ]

    /// Alcance permitido según el comportamiento.
    static func rangeLimits(_ behavior: EnemyBehavior) -> ClosedRange<Double> {
        behavior == .ranged ? 60...300 : 4...40
    }

    // MARK: Estadísticas (piezas, armaduras y minerales)

    /// Rango de cada estadística en piezas, armaduras y minerales.
    public static let stats: [StatKind: TuningField] = [
        .maxHP: TuningField("maxHP", -200, 2000, "Vida máxima", code: "Stats.maxHP"),
        .attack: TuningField("attack", -50, 500, "Ataque", code: "Stats.attack"),
        .defense: TuningField("defense", -50, 200, "Defensa", code: "Stats.defense"),
        .attackSpeed: TuningField("attackSpeed", -1, 2, "Ataques por segundo (suma)", code: "Stats.attackSpeed"),
        .range: TuningField("range", -30, 80, "Alcance (puntos)", code: "Stats.range"),
        .moveSpeed: TuningField("moveSpeed", -60, 60, "Velocidad de movimiento (puntos/s)", code: "Stats.moveSpeed"),
        .critChance: TuningField("critChance", -0.5, 0.5, "Probabilidad de crítico (0,05 = 5 %)", code: "Stats.critChance"),
        .critMultiplier: TuningField("critMultiplier", -1, 3, "Daño crítico extra (0,2 = +20 %)", code: "Stats.critMultiplier"),
        .lifesteal: TuningField("lifesteal", 0, 0.2, "Robo de vida (0,02 = 2 %)", code: "Stats.lifesteal"),
        .goldBonus: TuningField("goldBonus", -0.5, 2, "Oro extra (0,1 = +10 %)", code: "Stats.goldBonus"),
        .regen: TuningField("regen", 0, 20, "Vida por segundo", code: "Stats.regen"),
    ]

    // MARK: Piezas, armaduras, minerales

    public static let part: [TuningField] = [
        TuningField("price", 0, 1_000_000, integer: true, "Precio en la forja (las únicas no se venden: 0)", code: "WeaponPart.price"),
        TuningField("tier", 1, 6, integer: true, "Tier: desde cuándo la vende la forja y precio del ritual", code: "WeaponPart.tier"),
    ]

    public static let armor: [TuningField] = [
        TuningField("price", 0, 10_000, "Oro base de la forja a tier 1 (coste = precio × poder^1,3 + 5)",
                    code: "ArmorStyle.forgePrice"),
    ]

    public static let mineral: [TuningField] = [
        TuningField("value", 0, 100_000, integer: true, "Valor en oro por unidad", code: "Mineral.value"),
        TuningField("dropWeight", 0, 100, "Peso en el botín de la arena (los 10 suman 100 de serie)", code: "Mineral.dropPercent"),
    ]

    // MARK: Mundo

    public static let area: [TuningField] = [
        TuningField("level", 1, 60, integer: true, "Nivel de los monstruos fuera de zonas (interiores y campo)", code: "AreaMap.level"),
    ]

    public static let zone: [TuningField] = [
        TuningField("level", 1, 60, integer: true, "Nivel de los monstruos de la zona (y oro al liberarla)", code: "Zone.level"),
    ]

    public static let dungeon: [TuningField] = [
        TuningField("level", 1, 60, integer: true, "Nivel fijo de los monstruos de la mazmorra", code: "StoryDungeon.level"),
    ]

    /// Cuántos monstruos de un tipo por oleada (o en la escolta) de una mazmorra de historia.
    public static let dungeonCount = TuningField("count", 0, 40, integer: true, "Monstruos de ese tipo", code: "StoryDungeon.waves")
    /// Oleadas por mazmorra.
    public static let dungeonWaves = 1...10

    public static let reward: [TuningField] = [
        TuningField("xp", 0, 1_000_000, integer: true, "Experiencia (solo misiones)", code: "QuestReward.xp"),
        TuningField("gold", 0, 1_000_000, integer: true, "Oro", code: "QuestReward.gold / Reward.gold"),
    ]

    /// Unidades de un mineral en una recompensa.
    public static let rewardMineral = TuningField("minerals", 0, 99, integer: true, "Unidades de ese mineral",
                                                  code: "QuestReward.minerals")

    public static let roulette: [TuningField] = [
        TuningField("weight", 0, 100, "Peso base de la casilla", code: "CraftQuality.weight"),
        TuningField("multiplier", 0.1, 5, "Multiplicador de estadísticas y valor del objeto", code: "CraftQuality.multiplier"),
    ]

    // MARK: Economía

    /// Pesos de la familia de minerales de un continente (5 valores, de común a muy rara).
    public static let lootWeight = TuningField("continentLootWeights", 0, 100, "Peso de cada mineral de la familia del continente",
                                               code: "Continent.familyWeights")

    public static let economy: [EconomyField] = [
        e("mineralDropRate", 0, 5, "Multiplica la probabilidad de soltar mineral de los monstruos normales",
          code: "Mineral.dropRateMultiplier", \.mineralDropRate, \.mineralDropRate),
        e("arenaStartingGold", 0, 100_000, int: true, "Oro al empezar una partida de arena",
          code: "PlayerProfile.arenaRun · gold", \.arenaStartingGold, \.arenaStartingGold),
        e("arenaRewardBase", 0, 10_000, int: true, "Oro fijo por superar una oleada de la arena",
          code: "Arena.reward(wave:) = base + porOleada × oleada", \.arenaRewardBase, \.arenaRewardBase),
        e("arenaRewardPerWave", 0, 1_000, int: true, "Oro extra por número de oleada",
          code: "Arena.reward(wave:)", \.arenaRewardPerWave, \.arenaRewardPerWave),
        e("arenaWavesPerShopLevel", 1, 10, int: true, "Oleadas por cada nivel de la forja de la arena (nivel = oleada ÷ esto)",
          code: "Arena.shopLevel(wave:)", \.arenaWavesPerShopLevel, \.arenaWavesPerShopLevel),
        e("wallWave", 5, 200, int: true, "Oleada del muro: desde ella los monstruos suben 2 niveles por oleada",
          code: "Arena.wallWave", \.wallWave, \.wallWave),
        e("arenaBossXPMultiplier", 0, 50, "Multiplicador de XP de los jefes en la arena",
          code: "Leveling.arenaBossMultiplier", \.arenaBossXPMultiplier, \.arenaBossXPMultiplier),
        e("storyBossXPMultiplier", 0, 50, "Multiplicador de XP de los jefes en la historia",
          code: "Leveling.storyBossMultiplier", \.storyBossXPMultiplier, \.storyBossXPMultiplier),
        e("respawningXPMultiplier", 0, 10, "Multiplicador de XP de los monstruos que reaparecen (campo y mazmorras repetibles)",
          code: "Leveling.respawningMultiplier", \.respawningXPMultiplier, \.respawningXPMultiplier),
        e("xpCurveBase", 1, 1_000, "XP para subir de nivel = base × nivel^exponente + fija",
          code: "Leveling.xpToNext", \.xpCurveBase, \.xpCurveBase),
        e("xpCurveExponent", 1, 3, "Exponente de la curva de XP", code: "Leveling.xpToNext", \.xpCurveExponent, \.xpCurveExponent),
        e("xpCurveFlat", 0, 1_000, int: true, "Parte fija de la XP por nivel", code: "Leveling.xpToNext", \.xpCurveFlat, \.xpCurveFlat),
        e("levelHPGrowth", 0, 1, "Vida extra por nivel (fracción de la vida de la raza)",
          code: "Leveling.levelBonus", \.levelHPGrowth, \.levelHPGrowth),
        e("levelAttackGrowth", 0, 1, "Ataque extra por nivel (fracción del ataque de la raza)",
          code: "Leveling.levelBonus", \.levelAttackGrowth, \.levelAttackGrowth),
        e("levelDefensePerLevel", 0, 10, "Defensa extra por nivel", code: "Leveling.levelBonus", \.levelDefensePerLevel, \.levelDefensePerLevel),
        e("enemyHPPerLevel", 0, 1, "Vida extra del monstruo por cada nivel por encima del suyo",
          code: "EnemyDefinition.stats(level:)", \.enemyHPPerLevel, \.enemyHPPerLevel),
        e("enemyHPDifficulty", 0, 1, "Vida extra del monstruo por nivel de juego (dificultad global)",
          code: "EnemyDefinition.stats(level:)", \.enemyHPDifficulty, \.enemyHPDifficulty),
        e("enemyDamagePerLevel", 0, 1, "Daño extra del monstruo por cada nivel por encima del suyo",
          code: "EnemyDefinition.stats(level:)", \.enemyDamagePerLevel, \.enemyDamagePerLevel),
        e("enemyDamageDifficulty", 0, 1, "Daño extra del monstruo por nivel de juego (dificultad global)",
          code: "EnemyDefinition.stats(level:)", \.enemyDamageDifficulty, \.enemyDamageDifficulty),
        e("enemySpeedPerLevel", 0, 0.2, "Velocidad extra del monstruo por cada nivel por encima del suyo",
          code: "EnemyDefinition.stats(level:)", \.enemySpeedPerLevel, \.enemySpeedPerLevel),
        e("storyKillGoldBase", 0, 1_000, int: true, "Oro fijo por monstruo en la historia",
          code: "StoryEconomy.killGold = base + nivel ÷ nivelesPorMoneda (+ jefe)", \.storyKillGoldBase, \.storyKillGoldBase),
        e("storyKillGoldLevelsPerCoin", 1, 60, int: true, "Niveles de zona por cada moneda extra por monstruo",
          code: "StoryEconomy.killGold", \.storyKillGoldLevelsPerCoin, \.storyKillGoldLevelsPerCoin),
        e("storyBossGoldPerLevel", 0, 1_000, int: true, "Oro extra de un jefe de la historia por nivel",
          code: "StoryEconomy.bossGoldPerLevel", \.storyBossGoldPerLevel, \.storyBossGoldPerLevel),
        e("storyZoneGoldPerLevel", 0, 1_000, int: true, "Oro por nivel al liberar una zona por primera vez",
          code: "StoryEconomy.zoneGold", \.storyZoneGoldPerLevel, \.storyZoneGoldPerLevel),
        e("storyDungeonRepeatPartChance", 0, 1, "Probabilidad de que el jefe de una mazmorra repetida suelte su pieza",
          code: "StoryDungeon.repeatPartChance", \.storyDungeonRepeatPartChance, \.storyDungeonRepeatPartChance),
        e("forgeGoldBase", 0, 10_000, int: true, "Oro fijo del ritual de un arma (precio = base + porTier × tier)",
          code: "WeaponRecipe.goldCost", \.forgeGoldBase, \.forgeGoldBase),
        e("forgeGoldPerTier", 0, 10_000, int: true, "Oro del ritual por tier del arma",
          code: "WeaponRecipe.goldCost", \.forgeGoldPerTier, \.forgeGoldPerTier),
        e("rerollBaseCost", 0, 10_000, int: true, "Precio de la primera renovación de la forja",
          code: "ShopGenerator.rerollCost", \.rerollBaseCost, \.rerollBaseCost),
        e("rerollCostStep", 0, 10_000, int: true, "Cuánto sube cada renovación siguiente",
          code: "ShopGenerator.rerollCost", \.rerollCostStep, \.rerollCostStep),
        e("potionBasePrice", 0, 10_000, int: true, "Precio fijo de la poción (precio = base + porNivel × nivel de la forja)",
          code: "ShopGenerator.offers · poción", \.potionBasePrice, \.potionBasePrice),
        e("potionPricePerLevel", 0, 1_000, int: true, "Precio de la poción por nivel de la forja",
          code: "ShopGenerator.offers · poción", \.potionPricePerLevel, \.potionPricePerLevel),
        e("potionHeal", 0.05, 1, "Fracción de la vida máxima que cura la poción",
          code: "ShopGenerator.offers · healFraction", \.potionHeal, \.potionHeal),
    ]

    private static func e(_ key: String, _ min: Double, _ max: Double, int: Bool = false, _ description: String, code: String,
                          _ tuning: WritableKeyPath<EconomyTuning, Double?>,
                          _ value: WritableKeyPath<EconomyValues, Double>) -> EconomyField {
        EconomyField(field: TuningField(key, min, max, integer: int, description, code: code), tuning: tuning, value: value)
    }

    // MARK: Campos desconocidos

    /// Avisos de los campos del JSON que no existen en el contrato (p. ej. una errata `"hpp"`).
    static func unknownKeys(in raw: JSONValue) -> [String] {
        guard case .object(let root) = raw else { return ["El documento de ajustes no es un objeto JSON"] }
        var warnings: [String] = []
        let top = Set(GameTuning.CodingKeys.allCases.map(\.rawValue))
        for key in root.keys.sorted() where !top.contains(key) {
            warnings.append("\(key): apartado desconocido; se ignora")
        }
        let statKeys = Set(StatKind.allCases.map(\.rawValue))
        func keys(_ fields: [TuningField]) -> Set<String> { Set(fields.map(\.key)) }
        // Apartado → campos conocidos de cada entrada (y subcampos que son mapas de estadísticas).
        let sections: [String: (fields: Set<String>, statMaps: Set<String>)] = [
            "enemies": (keys(enemy), []),
            "parts": (keys(part).union(["stats"]), ["stats"]),
            "armor": (keys(armor).union(["stats"]), ["stats"]),
            "minerals": (keys(mineral).union(["stats"]), ["stats"]),
            "areas": (keys(area), []),
            "zones": (keys(zone), []),
            "dungeons": (keys(dungeon).union(["waves", "bossEscort"]), []),
            "quests": (keys(reward).union(["minerals"]), []),
            "rescues": (keys(reward).union(["minerals"]), []),
            "roulette": (keys(roulette), []),
        ]
        for (section, known) in sections {
            guard case .object(let entries)? = root[section] else { continue }
            for (id, entry) in entries {
                guard case .object(let fields) = entry else { continue }
                for key in fields.keys.sorted() where !known.fields.contains(key) {
                    warnings.append("\(section).\(id).\(key): campo desconocido; se ignora")
                }
                for map in known.statMaps {
                    guard case .object(let stats)? = fields[map] else { continue }
                    for key in stats.keys.sorted() where !statKeys.contains(key) {
                        warnings.append("\(section).\(id).\(map).\(key): estadística desconocida; se ignora")
                    }
                }
            }
        }
        if case .object(let economy)? = root["economy"] {
            let known = Set(Self.economy.map(\.field.key)).union([lootWeight.key])
            for key in economy.keys.sorted() where !known.contains(key) {
                warnings.append("economy.\(key): campo desconocido; se ignora")
            }
        }
        return warnings
    }
}
