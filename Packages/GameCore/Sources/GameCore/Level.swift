import Foundation

/// Una ronda (oleada) de monstruos.
public struct Wave: Equatable, Sendable {
    public var spawns: [MonsterKind: Int]
    /// Segundos entre apariciones.
    public var spawnInterval: Double

    public var totalMonsters: Int { spawns.values.reduce(0, +) }

    /// Orden de aparición barajado; los jefes siempre salen al final.
    public func spawnOrder<G: RandomNumberGenerator>(using rng: inout G) -> [MonsterKind] {
        var normal: [MonsterKind] = []
        var bosses: [MonsterKind] = []
        for kind in MonsterKind.allCases {
            let count = spawns[kind, default: 0]
            if kind.isBoss {
                bosses += Array(repeating: kind, count: count)
            } else {
                normal += Array(repeating: kind, count: count)
            }
        }
        normal.shuffle(using: &rng)
        return normal + bosses
    }
}

public struct LevelDefinition: Identifiable, Equatable, Sendable {
    /// 1...10
    public let id: Int
    public let name: String
    public let waves: [Wave]

    public var roundCount: Int { waves.count }

    public var monsterKinds: [MonsterKind] {
        MonsterKind.allCases.filter { kind in waves.contains { $0.spawns[kind, default: 0] > 0 } }
    }

    /// Oro por superar la ronda `round` (1-based), antes de bonificaciones.
    public func roundReward(_ round: Int) -> Int {
        15 + 8 * round + 12 * id
    }

    /// Oro extra por completar el nivel.
    public var clearBonus: Int { 50 * id }
}

public struct World: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let levels: [LevelDefinition]

    public func level(_ number: Int) -> LevelDefinition? {
        levels.first { $0.id == number }
    }
}

public enum Worlds {
    public static let forest: World = {
        let names = [
            "Linde del bosque",
            "Sendero musgoso",
            "Claro de los hongos",
            "Arroyo turbio",
            "Campamento goblin",
            "Cueva húmeda",
            "Ruinas cubiertas",
            "Pantano negro",
            "Empalizada goblin",
            "Trono del Rey Goblin",
        ]
        let levels = names.enumerated().map { index, name in
            let number = index + 1
            let rounds = 3 + (number - 1) / 3   // 3,3,3,4,4,4,5,5,5,6
            let waves = (1...rounds).map { makeWave(level: number, round: $0, totalRounds: rounds) }
            return LevelDefinition(id: number, name: name, waves: waves)
        }
        return World(id: 1, name: "Bosque Goblin", levels: levels)
    }()

    static func makeWave(level: Int, round: Int, totalRounds: Int) -> Wave {
        var spawns: [MonsterKind: Int] = [:]
        spawns[.goblin] = 2 + 2 * level + 2 * (round - 1)
        if level >= 2 {
            spawns[.goblinRunner] = (level - 1) / 2 + (round - 1) / 2 + 1
        }
        if level >= 4 {
            spawns[.goblinBrute] = (level - 2) / 2 + (round - 1) / 2
        }
        let isFinalRound = round == totalRounds
        if level == 5 && isFinalRound {
            spawns[.goblinBrute, default: 0] += 2   // mini-jefe
        }
        if level == 10 && isFinalRound {
            spawns[.goblinKing] = 1
        }
        let interval = max(0.6, 1.6 - 0.05 * Double(level) - 0.05 * Double(round))
        return Wave(spawns: spawns.filter { $0.value > 0 }, spawnInterval: interval)
    }
}
