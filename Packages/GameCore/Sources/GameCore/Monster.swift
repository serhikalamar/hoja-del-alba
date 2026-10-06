import Foundation

/// Tipos de monstruo. De momento solo goblins.
public enum MonsterKind: String, Codable, CaseIterable, Sendable {
    case goblin, goblinRunner, goblinBrute, goblinKing

    public var name: String {
        switch self {
        case .goblin: "Goblin"
        case .goblinRunner: "Goblin veloz"
        case .goblinBrute: "Goblin bruto"
        case .goblinKing: "Rey Goblin"
        }
    }

    public var isBoss: Bool { self == .goblinKing }

    /// Radio del cuerpo en puntos (colisión y alcance).
    public var bodyRadius: Double {
        switch self {
        case .goblin: 14
        case .goblinRunner: 12
        case .goblinBrute: 22
        case .goblinKing: 32
        }
    }

    private var base: MonsterStats {
        switch self {
        case .goblin:
            MonsterStats(hp: 22, damage: 5, speed: 55, attackCooldown: 1.2, attackRange: 6, dropChance: 0.5, dropRolls: 1)
        case .goblinRunner:
            MonsterStats(hp: 14, damage: 4, speed: 100, attackCooldown: 0.8, attackRange: 6, dropChance: 0.45, dropRolls: 1)
        case .goblinBrute:
            MonsterStats(hp: 75, damage: 12, speed: 38, attackCooldown: 1.6, attackRange: 10, dropChance: 0.9, dropRolls: 2)
        case .goblinKing:
            MonsterStats(hp: 600, damage: 22, speed: 48, attackCooldown: 1.4, attackRange: 14, dropChance: 1, dropRolls: 8)
        }
    }

    /// Estadísticas escaladas al nivel (1...10).
    public func stats(level: Int) -> MonsterStats {
        let l = Double(max(0, level - 1))
        var s = base
        s.hp *= 1 + 0.13 * l
        s.damage *= 1 + 0.12 * l
        s.speed *= 1 + 0.02 * l
        return s
    }
}

public struct MonsterStats: Equatable, Sendable {
    public var hp: Double
    public var damage: Double
    public var speed: Double
    public var attackCooldown: Double
    public var attackRange: Double
    /// Probabilidad de soltar un mineral en cada tirada.
    public var dropChance: Double
    public var dropRolls: Int

    /// Minerales soltados al morir.
    public func rollDrops<G: RandomNumberGenerator>(using rng: inout G) -> [Mineral] {
        (0..<dropRolls).compactMap { _ in
            Double.random(in: 0..<1, using: &rng) < dropChance ? Mineral.roll(using: &rng) : nil
        }
    }
}
