import Foundation

public enum Combat {
    /// Fracción de daño bloqueada por la defensa (rendimientos decrecientes).
    public static func damageReduction(defense: Double) -> Double {
        let d = max(0, defense)
        return d / (d + 60)
    }

    /// Daño que recibe el caballero tras aplicar la defensa. Siempre al menos 1.
    public static func incomingDamage(raw: Double, defense: Double) -> Double {
        max(1, raw * (1 - damageReduction(defense: defense)))
    }

    public struct Hit: Equatable, Sendable {
        public var amount: Double
        public var isCrit: Bool
    }

    /// Golpe del caballero con un ±10% de variación.
    public static func rollHit<G: RandomNumberGenerator>(stats: Stats, using rng: inout G) -> Hit {
        let variance = Double.random(in: 0.9...1.1, using: &rng)
        let isCrit = Double.random(in: 0..<1, using: &rng) < stats.critChance
        let amount = stats.attack * variance * (isCrit ? stats.critMultiplier : 1)
        return Hit(amount: amount, isCrit: isCrit)
    }
}
