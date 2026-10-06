import Foundation

public struct ShopOffer: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case equipment(Item)
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
}

public enum ShopGenerator {
    public static let equipmentOfferCount = 4

    /// Ofertas tras una ronda: 4 piezas de equipo + 1 poción.
    public static func offers<G: RandomNumberGenerator>(level: Int, using rng: inout G) -> [ShopOffer] {
        let available = Catalog.blueprints(upToTier: Catalog.maxTier(forLevel: level))
        // Favorece los tiers altos disponibles: peso = tier^2.
        let blueprintWeights = available.map { ($0, Double($0.tier * $0.tier)) }
        let rarityWeights = Rarity.allCases.map { ($0, $0.shopWeight) }

        var offers: [ShopOffer] = (0..<equipmentOfferCount).map { _ in
            let blueprint = WeightedPicker.pick(blueprintWeights, using: &rng)
            let rarity = WeightedPicker.pick(rarityWeights, using: &rng)
            let item = Catalog.makeShopItem(blueprint, rarity: rarity, level: level)
            return ShopOffer(kind: .equipment(item), price: item.value)
        }
        offers.append(ShopOffer(kind: .potion(healFraction: 0.5), price: 15 + 5 * level))
        return offers
    }

    public static func rerollCost(rerollsSoFar: Int) -> Int {
        10 + 10 * rerollsSoFar
    }
}
