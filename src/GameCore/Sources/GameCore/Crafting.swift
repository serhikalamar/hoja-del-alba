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

/// Lo que el jugador pone en el ritual: hoja, guarda, empuñadura y minerales.
public struct WeaponRecipe: Equatable, Sendable {
    public static let maxMinerals = 12

    public var headID: String
    public var guardID: String
    public var gripID: String
    public var minerals: [Mineral: Int]

    public init(headID: String, guardID: String, gripID: String, minerals: [Mineral: Int] = [:]) {
        self.headID = headID
        self.guardID = guardID
        self.gripID = gripID
        self.minerals = minerals.filter { $0.value > 0 }
    }

    public var partIDs: [String] { [headID, guardID, gripID] }

    public var parts: [WeaponPart] { partIDs.compactMap(PartCatalog.part) }

    public var head: WeaponPart? { PartCatalog.part(headID) }

    public var totalMinerals: Int { minerals.values.reduce(0, +) }

    public var tier: Int { parts.map(\.tier).max() ?? 1 }

    public var goldCost: Int { 10 * tier + 5 }

    /// Suerte de la ruleta: minerales raros y piezas de jefe (máx. 1.5).
    public var luck: Double {
        let mineralLuck = minerals.reduce(0.0) { acc, entry in
            acc + Double(entry.value * (entry.key.rarityTier - 1)) * 0.03
        }
        let specialLuck = Double(parts.filter(\.isSpecial).count) * 0.3
        return min(1.5, mineralLuck + specialLuck)
    }

    public var mineralBuffs: Stats {
        minerals.reduce(Stats.zero) { acc, entry in
            acc + entry.key.buffPerUnit * Double(entry.value)
        }
    }

    public var partStats: Stats {
        parts.reduce(Stats.zero) { $0 + $1.stats }
    }

    public func stats(multiplier: Double) -> Stats {
        (partStats + mineralBuffs) * multiplier
    }

    /// Habilidad secreta que despertará esta combinación.
    public var ability: Ability? { AbilityBook.resolve(parts: parts) }

    /// "Hacha de Obsidiana"
    public var weaponName: String {
        guard let head, let shape = head.weaponShape else { return "Arma" }
        if head.isSpecial { return head.name }
        return "\(shape.name) de \(head.materialName)"
    }

    public func makeItem(quality: CraftQuality) -> Item {
        let mineralValue = minerals.reduce(0) { $0 + $1.key.value * $1.value }
        let partValue = parts.reduce(0) { $0 + ($1.isSpecial ? 300 : $1.price) }
        let value = Int((Double(partValue + mineralValue) * quality.multiplier).rounded())
        return Item(
            forgedName: weaponName,
            partIDs: partIDs,
            tier: tier,
            stats: stats(multiplier: quality.multiplier),
            rarity: quality.rarity,
            qualityName: quality.name,
            qualityMultiplier: quality.multiplier,
            minerals: minerals,
            value: value,
            abilityID: ability?.id
        )
    }
}

public enum CraftError: Error, Equatable {
    case missingPart(PartSlot)
    case wrongSlot(PartSlot)
    case tooManyMinerals
    case missingMineral(Mineral)
    case notEnoughGold

    public var message: String {
        switch self {
        case .missingPart(let slot): "Falta la pieza: \(slot.name.lowercased())"
        case .wrongSlot(let slot): "Esa pieza no sirve como \(slot.name.lowercased())"
        case .tooManyMinerals: "Máximo \(WeaponRecipe.maxMinerals) minerales"
        case .missingMineral(let m): "No tienes suficiente \(m.name)"
        case .notEnoughGold: "No tienes oro suficiente"
        }
    }
}

public struct CraftResult: Equatable, Sendable {
    public let item: Item
    public let segmentIndex: Int
    /// `true` si es la primera vez que se descubre esta habilidad.
    public let discoveredNewAbility: Bool
    public var quality: CraftQuality { Roulette.segments[segmentIndex] }
}
