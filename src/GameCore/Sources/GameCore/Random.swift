import Foundation

/// Generador determinista (SplitMix64). Útil para tests y para reproducir partidas.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public enum WeightedPicker {
    /// Elige un índice según los pesos dados. Los pesos <= 0 nunca salen.
    public static func pickIndex<G: RandomNumberGenerator>(weights: [Double], using rng: inout G) -> Int {
        let total = weights.reduce(0) { $0 + max(0, $1) }
        precondition(total > 0, "Al menos un peso debe ser positivo")
        var roll = Double.random(in: 0..<total, using: &rng)
        for (index, weight) in weights.enumerated() where weight > 0 {
            if roll < weight { return index }
            roll -= weight
        }
        return weights.lastIndex { $0 > 0 }!
    }

    public static func pick<T, G: RandomNumberGenerator>(_ items: [(T, Double)], using rng: inout G) -> T {
        items[pickIndex(weights: items.map(\.1), using: &rng)].0
    }
}
