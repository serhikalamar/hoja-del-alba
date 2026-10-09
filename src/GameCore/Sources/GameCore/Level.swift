import Foundation

/// Una ronda (oleada) de enemigos.
public struct Wave: Equatable, Sendable {
    /// Enemigos por id del bestiario.
    public var spawns: [String: Int]
    /// Segundos entre apariciones.
    public var spawnInterval: Double

    public var totalMonsters: Int { spawns.values.reduce(0, +) }

    /// Orden de aparición barajado; los jefes siempre salen al final.
    public func spawnOrder<G: RandomNumberGenerator>(using rng: inout G) -> [String] {
        var normal: [String] = []
        var bosses: [String] = []
        for (id, count) in spawns.sorted(by: { $0.key < $1.key }) {
            if Bestiary.enemy(id)?.isBoss == true {
                bosses += Array(repeating: id, count: count)
            } else {
                normal += Array(repeating: id, count: count)
            }
        }
        normal.shuffle(using: &rng)
        return normal + bosses
    }
}

/// Momento del día del nivel (la app lo usa para el ambiente).
public enum TimeOfDay: String, Sendable {
    case day, sunset, night
}

public struct LevelDefinition: Identifiable, Equatable, Sendable {
    /// 1...10
    public let id: Int
    public let name: String
    /// Ambiente del suelo: "cobble", "farm", "graveyard", "castle".
    public let ground: String
    public let time: TimeOfDay
    public let waves: [Wave]

    public var roundCount: Int { waves.count }

    /// Enemigos nuevos de este nivel (incluido su jefe).
    public var newEnemies: [EnemyDefinition] { Bestiary.introduced(at: id) }

    public var boss: EnemyDefinition? { newEnemies.first(where: \.isBoss) }

    public var enemyIDs: Set<String> {
        Set(waves.flatMap { $0.spawns.keys })
    }

    /// Oro por superar la ronda `round` (1-based), antes de bonificaciones.
    public func roundReward(_ round: Int) -> Int {
        15 + 8 * round + 12 * id
    }

    /// Oro extra por completar el nivel.
    public var clearBonus: Int { 50 * id }
}

/// Mundo de niveles por oleadas (modo antiguo; se sigue usando para fondos). No confundir con `World` (continentes).
public struct LevelWorld: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let levels: [LevelDefinition]

    public func level(_ number: Int) -> LevelDefinition? {
        levels.first { $0.id == number }
    }
}

public enum Worlds {
    /// Mundo 1: el pueblo medieval de Valdehierro, tomado por los goblins.
    public static let village: LevelWorld = {
        let info: [(String, String, TimeOfDay)] = [
            ("Puerta del pueblo", "cobble", .day),
            ("Calle del mercado", "cobble", .day),
            ("Huertos del molino", "farm", .day),
            ("Plaza de la herrería", "cobble", .sunset),
            ("Cementerio de la capilla", "graveyard", .sunset),
            ("Pozo de la bruja", "cobble", .sunset),
            ("Molino en ruinas", "farm", .night),
            ("Abadía abandonada", "graveyard", .night),
            ("Murallas del castillo", "castle", .night),
            ("Salón del trono goblin", "castle", .night),
        ]
        let levels = info.enumerated().map { index, entry in
            let number = index + 1
            let rounds = 3 + (number - 1) / 3   // 3,3,3,4,4,4,5,5,5,6
            let waves = (1...rounds).map { makeWave(level: number, round: $0, totalRounds: rounds) }
            return LevelDefinition(id: number, name: entry.0, ground: entry.1, time: entry.2, waves: waves)
        }
        return LevelWorld(id: 1, name: "Pueblo de Valdehierro", levels: levels)
    }()

    /// Oleada determinista: la mitad de los enemigos son los nuevos del nivel, el resto de niveles anteriores.
    static func makeWave(level: Int, round: Int, totalRounds: Int) -> Wave {
        var rng = SeededGenerator(seed: UInt64(level * 1000 + round))
        // Solo los 50 originales (como la arena): los monstruos de continente no cambian estas oleadas.
        let original = Arena.enemies.filter { !$0.isBoss }
        let fresh = original.filter { $0.level == level }
        let older = original.filter { $0.level < level && $0.level >= level - 3 }
        var candidates = fresh.map { ($0.id, 2.0) } + older.map { ($0.id, 1.0) }
        // En la primera ronda de cada nivel solo salen los enemigos más débiles del nivel.
        if round == 1 && level == 1 {
            candidates = [("rat", 1), ("goblin", 2)]
        }

        let total = 3 + 2 * level + 2 * (round - 1)
        var spawns: [String: Int] = [:]
        for _ in 0..<total {
            spawns[WeightedPicker.pick(candidates, using: &rng), default: 0] += 1
        }
        if round == totalRounds, let boss = Bestiary.introduced(at: level).first(where: \.isBoss) {
            spawns[boss.id] = 1
        }
        let interval = max(0.6, 1.6 - 0.05 * Double(level) - 0.05 * Double(round))
        return Wave(spawns: spawns, spawnInterval: interval)
    }
}
