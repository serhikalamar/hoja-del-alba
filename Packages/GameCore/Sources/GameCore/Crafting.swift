import Foundation

/// Casilla de la ruleta de forja.
public struct CraftQuality: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let multiplier: Double
    /// Peso base de la casilla.
    public let weight: Double
    /// Cómo afecta la suerte: positivo = más probable con minerales raros.
    public let luckFactor: Double
    public let rarity: Rarity
}

public enum Roulette {
    public static let segments: [CraftQuality] = [
        CraftQuality(id: "broken", name: "Rota", multiplier: 0.6, weight: 10, luckFactor: -0.5, rarity: .common),
        CraftQuality(id: "crude", name: "Tosca", multiplier: 0.8, weight: 20, luckFactor: -0.3, rarity: .common),
        CraftQuality(id: "normal", name: "Normal", multiplier: 1.0, weight: 30, luckFactor: 0, rarity: .common),
        CraftQuality(id: "fine", name: "Fina", multiplier: 1.2, weight: 22, luckFactor: 0.3, rarity: .rare),
        CraftQuality(id: "excellent", name: "Excelente", multiplier: 1.5, weight: 13, luckFactor: 0.7, rarity: .epic),
        CraftQuality(id: "masterwork", name: "Obra maestra", multiplier: 2.0, weight: 5, luckFactor: 1.2, rarity: .legendary),
    ]

    /// Pesos efectivos de cada casilla con la suerte dada (0 = sin suerte).
    public static func weights(luck: Double) -> [Double] {
        segments.map { seg in
            max(seg.weight * 0.15, seg.weight * (1 + luck * seg.luckFactor))
        }
    }

    /// Probabilidad (0...1) de cada casilla.
    public static func probabilities(luck: Double) -> [Double] {
        let w = weights(luck: luck)
        let total = w.reduce(0, +)
        return w.map { $0 / total }
    }

    public static func spin<G: RandomNumberGenerator>(luck: Double, using rng: inout G) -> Int {
        WeightedPicker.pickIndex(weights: weights(luck: luck), using: &rng)
    }
}

/// Lo que el jugador elige en la forja: tipo de objeto + minerales.
public struct CraftRecipe: Equatable, Sendable {
    public static let minMinerals = 3
    public static let maxMinerals = 12

    public var blueprint: Blueprint
    public var minerals: [Mineral: Int]

    public init(blueprint: Blueprint, minerals: [Mineral: Int] = [:]) {
        self.blueprint = blueprint
        self.minerals = minerals.filter { $0.value > 0 }
    }

    public var totalMinerals: Int { minerals.values.reduce(0, +) }

    public var goldCost: Int { 15 * blueprint.tier }

    /// Suerte de la ruleta: los minerales raros la aumentan (máx. 1.5).
    public var luck: Double {
        let raw = minerals.reduce(0.0) { acc, entry in
            acc + Double(entry.value * (entry.key.rarityTier - 1)) * 0.03
        }
        return min(1.5, raw)
    }

    /// Bonificaciones de los minerales sin multiplicador.
    public var mineralBuffs: Stats {
        minerals.reduce(Stats.zero) { acc, entry in
            acc + entry.key.buffPerUnit * Double(entry.value)
        }
    }

    public func stats(multiplier: Double) -> Stats {
        (blueprint.baseStats + mineralBuffs) * multiplier
    }

    /// Mineral con más unidades (da nombre al objeto).
    public var dominantMineral: Mineral? {
        minerals.max { a, b in
            a.value != b.value ? a.value < b.value : a.key.rarityTier < b.key.rarityTier
        }?.key
    }

    public func makeItem(quality: CraftQuality) -> Item {
        let mineralValue = minerals.reduce(0) { $0 + $1.key.value * $1.value }
        let value = Int((Double(blueprint.basePrice + mineralValue) * quality.multiplier).rounded())
        let name = dominantMineral.map { "\(blueprint.name) de \($0.name)" } ?? blueprint.name
        return Item(
            blueprint: blueprint,
            name: name,
            rarity: quality.rarity,
            stats: stats(multiplier: quality.multiplier),
            qualityName: quality.name,
            qualityMultiplier: quality.multiplier,
            minerals: minerals,
            value: value
        )
    }
}

public enum CraftError: Error, Equatable {
    case notEnoughMinerals
    case tooManyMinerals
    case missingMineral(Mineral)
    case notEnoughGold
    case blueprintLocked

    public var message: String {
        switch self {
        case .notEnoughMinerals: "Necesitas al menos \(CraftRecipe.minMinerals) minerales"
        case .tooManyMinerals: "Máximo \(CraftRecipe.maxMinerals) minerales"
        case .missingMineral(let m): "No tienes suficiente \(m.name)"
        case .notEnoughGold: "No tienes oro suficiente"
        case .blueprintLocked: "Este objeto aún no está desbloqueado"
        }
    }
}

public struct CraftResult: Equatable, Sendable {
    public let item: Item
    public let segmentIndex: Int
    public var quality: CraftQuality { Roulette.segments[segmentIndex] }
}
