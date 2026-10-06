import Foundation

public struct ShopOffer: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case equipment(Item)
        /// Pieza de arma para el ritual.
        case part(WeaponPart)
        /// Cura inmediata: fracción de la vida máxima.
        case potion(healFraction: Double)
    }

    public let id: UUID
    public let kind: Kind
    public let price: Int
    public var sold: Bool

    public init(id: UUID = UUID(), kind: Kind, price: Int, sold: Bool = false) {
        self.id = id
        self.kind = kind
        self.price = price
        self.sold = sold
    }

    public var item: Item? {
        if case .equipment(let item) = kind { return item }
        return nil
    }

    public var part: WeaponPart? {
        if case .part(let part) = kind { return part }
        return nil
    }
}

/// La forja del enano: vende piezas de arma, una armadura y una poción.
public enum ShopGenerator {
    public static let partOfferCount = 5

    public static func offers<G: RandomNumberGenerator>(level: Int, using rng: inout G) -> [ShopOffer] {
        let parts = PartCatalog.shopParts(level: level)
        let slotWeights: [(PartSlot, Double)] = [(.head, 4), (.hilt, 3), (.grip, 3)]
        var offers: [ShopOffer] = []
        var used = Set<String>()
        while offers.count < partOfferCount {
            let slot = WeightedPicker.pick(slotWeights, using: &rng)
            // Favorece los materiales de tier alto disponibles: peso = tier^2.
            let pool = parts.filter { $0.slot == slot && !used.contains($0.id) }
            guard !pool.isEmpty else { continue }
            let part = WeightedPicker.pick(pool.map { ($0, Double($0.tier * $0.tier)) }, using: &rng)
            used.insert(part.id)
            offers.append(ShopOffer(kind: .part(part), price: part.price))
        }

        let armors = Catalog.armors.filter { $0.tier <= Catalog.maxTier(forLevel: level) }
        if let blueprint = armors.randomElement(using: &rng) {
            let rarity = WeightedPicker.pick(Rarity.allCases.map { ($0, $0.shopWeight) }, using: &rng)
            let item = Catalog.makeShopItem(blueprint, rarity: rarity, level: level)
            offers.append(ShopOffer(kind: .equipment(item), price: item.value))
        }
        offers.append(ShopOffer(kind: .potion(healFraction: 0.5), price: 15 + 5 * level))
        return offers
    }

    public static func rerollCost(rerollsSoFar: Int) -> Int {
        10 + 10 * rerollsSoFar
    }
}
