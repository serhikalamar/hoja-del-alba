import Foundation

// MARK: - Ajustes en vivo (contrato)
//
// Documento JSON que el panel web de administración publica en Supabase y el juego descarga al abrirse. Todos los
// campos son opcionales: solo lo que viene cambia; lo demás se queda con el valor del código. Contrato completo,
// rangos y ejemplos: `assets/admin/contrato.md`. Valores base que muestra la web: `make datos` (`admin/public/data/`).
//
// Uso desde la app (lo hace `RemoteConfig`):
//     let tuning = try JSONDecoder().decode(GameTuning.self, from: data)
//     let avisos = GameTuning.apply(tuning)      // [String]: lo ignorado o recortado
//
// Reglas:
// - `apply` parte siempre de los valores del código (no acumula): `apply(GameTuning())` vuelve a los de serie.
// - Los ids desconocidos se ignoran y los números fuera de rango se recortan; todo eso sale en los avisos.
// - Lo ya guardado no cambia: un arma o armadura forjada conserva sus números (van en el `Item`).
// - Se precalcula todo al aplicar (`TunedData`): en el juego no se busca en diccionarios de ajustes en cada frame.
// - Llamar en el hilo principal, mejor antes de empezar una partida: los monstruos ya en pantalla no cambian.

/// Documento de ajustes del panel de administración.
public struct GameTuning: Codable, Equatable, Sendable {
    /// Versión del formato que entiende este código.
    public static let currentSchemaVersion = 1

    /// Versión del formato del documento (si es mayor que `currentSchemaVersion`, se aplica lo que se entienda).
    public var schemaVersion: Int
    /// Versión publicada en el panel (para saber qué ajustes tiene el jugador).
    public var version: Int?
    /// Nota libre de quien publica.
    public var note: String?

    /// Monstruos y jefes, por id del bestiario (`rat`, `ogre`…).
    public var enemies: [String: EnemyTuning]?
    /// Piezas de arma, por id de `PartCatalog` (`head.sword.copper`, `boss.ogre`, `boss.ogre.valdemar`…).
    public var parts: [String: PartTuning]?
    /// Diseños de armadura, por id de `ArmorCatalog` (`chest.plate`…).
    public var armor: [String: ArmorTuning]?
    /// Minerales, por id (`copper`…`mithril`).
    public var minerals: [String: MineralTuning]?
    /// Áreas (pueblo, interiores, campo), por id (`town`, `inn`, `valdemar.huertos`…).
    public var areas: [String: AreaTuning]?
    /// Zonas de un área, por id (`south`, `valdemar.huertos.molino`…).
    public var zones: [String: ZoneTuning]?
    /// Qué monstruo sale en cada punto de aparición, por id de spawn (`south.1` → `goblin`).
    public var spawns: [String: String]?
    /// Mazmorras de historia, por id (`valdemar.cripta`…).
    public var dungeons: [String: DungeonTuning]?
    /// Recompensas de misión, por id (`valdemar.molino`…).
    public var quests: [String: RewardTuning]?
    /// Recompensas de rescate de aldeanos y princesa, por id de NPC (`marta`, `princess`…).
    public var rescues: [String: RewardTuning]?
    /// Casillas de la ruleta de la forja, por id (`broken`, `crude`, `normal`, `fine`, `excellent`, `masterwork`).
    public var roulette: [String: RouletteTuning]?
    /// Números globales de economía y progresión.
    public var economy: EconomyTuning?

    /// Avisos de la decodificación (campos que no existen): se suman al informe de `apply`. No se guardan.
    public var decodingWarnings: [String] = []

    public init(schemaVersion: Int = GameTuning.currentSchemaVersion, version: Int? = nil, note: String? = nil,
                enemies: [String: EnemyTuning]? = nil, parts: [String: PartTuning]? = nil,
                armor: [String: ArmorTuning]? = nil, minerals: [String: MineralTuning]? = nil,
                areas: [String: AreaTuning]? = nil, zones: [String: ZoneTuning]? = nil, spawns: [String: String]? = nil,
                dungeons: [String: DungeonTuning]? = nil, quests: [String: RewardTuning]? = nil,
                rescues: [String: RewardTuning]? = nil, roulette: [String: RouletteTuning]? = nil,
                economy: EconomyTuning? = nil) {
        self.schemaVersion = schemaVersion
        self.version = version
        self.note = note
        self.enemies = enemies
        self.parts = parts
        self.armor = armor
        self.minerals = minerals
        self.areas = areas
        self.zones = zones
        self.spawns = spawns
        self.dungeons = dungeons
        self.quests = quests
        self.rescues = rescues
        self.roulette = roulette
        self.economy = economy
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case schemaVersion, version, note, enemies, parts, armor, minerals, areas, zones, spawns, dungeons, quests
        case rescues, roulette, economy
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        version = try c.decodeIfPresent(Int.self, forKey: .version)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        enemies = try c.decodeIfPresent([String: EnemyTuning].self, forKey: .enemies)
        parts = try c.decodeIfPresent([String: PartTuning].self, forKey: .parts)
        armor = try c.decodeIfPresent([String: ArmorTuning].self, forKey: .armor)
        minerals = try c.decodeIfPresent([String: MineralTuning].self, forKey: .minerals)
        areas = try c.decodeIfPresent([String: AreaTuning].self, forKey: .areas)
        zones = try c.decodeIfPresent([String: ZoneTuning].self, forKey: .zones)
        spawns = try c.decodeIfPresent([String: String].self, forKey: .spawns)
        dungeons = try c.decodeIfPresent([String: DungeonTuning].self, forKey: .dungeons)
        quests = try c.decodeIfPresent([String: RewardTuning].self, forKey: .quests)
        rescues = try c.decodeIfPresent([String: RewardTuning].self, forKey: .rescues)
        roulette = try c.decodeIfPresent([String: RouletteTuning].self, forKey: .roulette)
        economy = try c.decodeIfPresent(EconomyTuning.self, forKey: .economy)
        // Segunda pasada sobre el JSON en bruto: avisa de los campos con nombre desconocido (erratas del panel).
        if let raw = try? JSONValue(from: decoder) {
            decodingWarnings = TuningSchema.unknownKeys(in: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encodeIfPresent(version, forKey: .version)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(enemies, forKey: .enemies)
        try c.encodeIfPresent(parts, forKey: .parts)
        try c.encodeIfPresent(armor, forKey: .armor)
        try c.encodeIfPresent(minerals, forKey: .minerals)
        try c.encodeIfPresent(areas, forKey: .areas)
        try c.encodeIfPresent(zones, forKey: .zones)
        try c.encodeIfPresent(spawns, forKey: .spawns)
        try c.encodeIfPresent(dungeons, forKey: .dungeons)
        try c.encodeIfPresent(quests, forKey: .quests)
        try c.encodeIfPresent(rescues, forKey: .rescues)
        try c.encodeIfPresent(roulette, forKey: .roulette)
        try c.encodeIfPresent(economy, forKey: .economy)
    }

    /// No cambia nada (ningún apartado con contenido).
    public var isEmpty: Bool {
        (enemies ?? [:]).isEmpty && (parts ?? [:]).isEmpty && (armor ?? [:]).isEmpty && (minerals ?? [:]).isEmpty
            && (areas ?? [:]).isEmpty && (zones ?? [:]).isEmpty && (spawns ?? [:]).isEmpty && (dungeons ?? [:]).isEmpty
            && (quests ?? [:]).isEmpty && (rescues ?? [:]).isEmpty && (roulette ?? [:]).isEmpty
            && (economy ?? EconomyTuning()) == EconomyTuning()
    }
}

// MARK: - Apartados

/// Ajuste de un monstruo (`EnemyDefinition`). Los números son los de su nivel de aparición: luego escalan con el nivel
/// de la zona u oleada (`EnemyDefinition.stats(level:)`).
public struct EnemyTuning: Codable, Equatable, Sendable {
    /// Vida (`hp`).
    public var hp: Double?
    /// Daño por golpe o proyectil (`damage`).
    public var damage: Double?
    /// Velocidad de movimiento en puntos/s (`speed`).
    public var speed: Double?
    /// Segundos entre ataques (`attackCooldown`).
    public var attackCooldown: Double?
    /// Alcance del ataque (`attackRange`).
    public var attackRange: Double?
    /// Nivel de aparición (`level`): decide en qué oleadas de la arena sale y cuánto escala.
    public var level: Double?
    /// Probabilidad de soltar un mineral en cada tirada (`dropChance`; 1 = siempre, como los jefes).
    public var dropChance: Double?
    /// Tiradas de mineral (`dropRolls`).
    public var dropRolls: Double?
    /// Multiplicador de la experiencia que da al morir (`xpMultiplier`).
    public var xpMultiplier: Double?
    /// Multiplicador del oro que da al morir en la historia (`goldMultiplier`).
    public var goldMultiplier: Double?
    /// Solo jefes: multiplicador de vida en la historia (`EnemyDefinition.storyBossTuning`).
    public var storyHPMultiplier: Double?
    /// Solo jefes: multiplicador de daño en la historia (`EnemyDefinition.storyBossTuning`).
    public var storyDamageMultiplier: Double?

    public init(hp: Double? = nil, damage: Double? = nil, speed: Double? = nil, attackCooldown: Double? = nil,
                attackRange: Double? = nil, level: Double? = nil, dropChance: Double? = nil, dropRolls: Double? = nil,
                xpMultiplier: Double? = nil, goldMultiplier: Double? = nil, storyHPMultiplier: Double? = nil,
                storyDamageMultiplier: Double? = nil) {
        self.hp = hp
        self.damage = damage
        self.speed = speed
        self.attackCooldown = attackCooldown
        self.attackRange = attackRange
        self.level = level
        self.dropChance = dropChance
        self.dropRolls = dropRolls
        self.xpMultiplier = xpMultiplier
        self.goldMultiplier = goldMultiplier
        self.storyHPMultiplier = storyHPMultiplier
        self.storyDamageMultiplier = storyDamageMultiplier
    }
}

/// Ajuste de una pieza de arma (`WeaponPart`).
public struct PartTuning: Codable, Equatable, Sendable {
    /// Estadísticas que se cambian (clave de `StatKind` → valor final); las demás se quedan como están.
    public var stats: [String: Double]?
    /// Precio en la forja (`price`). Las piezas únicas no se venden (0).
    public var price: Double?
    /// Tier (1-6): decide desde cuándo la vende la forja y el precio del ritual.
    public var tier: Double?

    public init(stats: [String: Double]? = nil, price: Double? = nil, tier: Double? = nil) {
        self.stats = stats
        self.price = price
        self.tier = tier
    }
}

/// Ajuste de un diseño de armadura (`ArmorStyle`).
public struct ArmorTuning: Codable, Equatable, Sendable {
    /// Estadísticas con material de tier 1 (`ArmorStyle.base`), clave de `StatKind` → valor.
    public var stats: [String: Double]?
    /// Oro base de la forja a tier 1 (`ArmorStyle.forgePrice`): coste = precio × poder^1,3 + 5.
    public var price: Double?

    public init(stats: [String: Double]? = nil, price: Double? = nil) {
        self.stats = stats
        self.price = price
    }
}

/// Ajuste de un mineral (`Mineral`).
public struct MineralTuning: Codable, Equatable, Sendable {
    /// Valor en oro por unidad (`value`).
    public var value: Double?
    /// Peso en el botín de la arena (`dropPercent`; los 10 suman 100 de serie).
    public var dropWeight: Double?
    /// Bonificación por unidad al forjar (`buffPerUnit`), clave de `StatKind` → valor.
    public var stats: [String: Double]?

    public init(value: Double? = nil, dropWeight: Double? = nil, stats: [String: Double]? = nil) {
        self.value = value
        self.dropWeight = dropWeight
        self.stats = stats
    }
}

/// Ajuste de un área (`AreaMap`).
public struct AreaTuning: Codable, Equatable, Sendable {
    /// Nivel de los monstruos fuera de las zonas (interiores y campo) (`AreaMap.level`).
    public var level: Double?

    public init(level: Double? = nil) { self.level = level }
}

/// Ajuste de una zona (`Zone`).
public struct ZoneTuning: Codable, Equatable, Sendable {
    /// Nivel de los monstruos de la zona (`Zone.level`; también el oro al liberarla).
    public var level: Double?

    public init(level: Double? = nil) { self.level = level }
}

/// Ajuste de una mazmorra de historia (`StoryDungeon`).
public struct DungeonTuning: Codable, Equatable, Sendable {
    /// Nivel fijo de los monstruos.
    public var level: Double?
    /// Oleadas (sustituyen a todas): cada una, id de monstruo → cuántos. El jefe no se toca.
    public var waves: [[String: Int]]?
    /// Escolta del jefe: id de monstruo → cuántos.
    public var bossEscort: [String: Int]?

    public init(level: Double? = nil, waves: [[String: Int]]? = nil, bossEscort: [String: Int]? = nil) {
        self.level = level
        self.waves = waves
        self.bossEscort = bossEscort
    }
}

/// Recompensa de una misión (`QuestReward`) o de un rescate (`NPC.reward`).
public struct RewardTuning: Codable, Equatable, Sendable {
    /// Experiencia (solo misiones).
    public var xp: Double?
    /// Oro.
    public var gold: Double?
    /// Minerales: id → cuántos. Si viene, sustituye a todos los de la recompensa (vacío = ninguno).
    public var minerals: [String: Int]?

    public init(xp: Double? = nil, gold: Double? = nil, minerals: [String: Int]? = nil) {
        self.xp = xp
        self.gold = gold
        self.minerals = minerals
    }
}

/// Ajuste de una casilla de la ruleta (`CraftQuality`).
public struct RouletteTuning: Codable, Equatable, Sendable {
    /// Peso base de la casilla.
    public var weight: Double?
    /// Multiplicador de estadísticas y valor del objeto forjado.
    public var multiplier: Double?

    public init(weight: Double? = nil, multiplier: Double? = nil) {
        self.weight = weight
        self.multiplier = multiplier
    }
}

/// Números globales. Cada campo corresponde a una constante del código (ver `TuningSchema.economy`).
public struct EconomyTuning: Codable, Equatable, Sendable {
    // Minerales
    public var mineralDropRate: Double?
    public var continentLootWeights: [Double]?
    // Arena
    public var arenaStartingGold: Double?
    public var arenaRewardBase: Double?
    public var arenaRewardPerWave: Double?
    public var arenaWavesPerShopLevel: Double?
    public var wallWave: Double?
    // Experiencia y niveles
    public var arenaBossXPMultiplier: Double?
    public var storyBossXPMultiplier: Double?
    public var respawningXPMultiplier: Double?
    public var xpCurveBase: Double?
    public var xpCurveExponent: Double?
    public var xpCurveFlat: Double?
    public var levelHPGrowth: Double?
    public var levelAttackGrowth: Double?
    public var levelDefensePerLevel: Double?
    // Escalado de los monstruos con el nivel
    public var enemyHPPerLevel: Double?
    public var enemyHPDifficulty: Double?
    public var enemyDamagePerLevel: Double?
    public var enemyDamageDifficulty: Double?
    public var enemySpeedPerLevel: Double?
    // Oro de la historia
    public var storyKillGoldBase: Double?
    public var storyKillGoldLevelsPerCoin: Double?
    public var storyBossGoldPerLevel: Double?
    public var storyZoneGoldPerLevel: Double?
    public var storyDungeonRepeatPartChance: Double?
    // Forja
    public var forgeGoldBase: Double?
    public var forgeGoldPerTier: Double?
    public var rerollBaseCost: Double?
    public var rerollCostStep: Double?
    public var potionBasePrice: Double?
    public var potionPricePerLevel: Double?
    public var potionHeal: Double?

    public init() {}
}

// MARK: - JSON en bruto (para avisar de campos desconocidos)

/// Valor JSON cualquiera. Solo lo usa la comprobación de campos desconocidos.
public indirect enum JSONValue: Decodable, Equatable, Sendable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }
}
