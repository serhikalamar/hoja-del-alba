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

    /// Ofertas de la forja. `maxTier` = tier de material de la historia (`PlayerProfile.storyForgeTier`);
    /// nil = el que toque por `level` (arena).
    public static func offers<G: RandomNumberGenerator>(level: Int, maxTier: Int? = nil, using rng: inout G) -> [ShopOffer] {
        let tierCap = maxTier ?? PartCatalog.maxShopTier(forLevel: level)
        let parts = PartCatalog.shopParts(level: maxTier == nil ? level : 10).filter { $0.tier <= tierCap }
        let slotWeights: [(PartSlot, Double)] = [(.head, 4), (.hilt, 3), (.grip, 3)]
        var offers: [ShopOffer] = []
        var used = Set<String>()
        while offers.count < partOfferCount {
            // Siempre hay al menos una hoja, una guarda y una empuñadura (el ritual nunca se queda cojo); el resto, al azar.
            let slot = offers.count < PartSlot.allCases.count ? PartSlot.allCases[offers.count] : WeightedPicker.pick(slotWeights, using: &rng)
            // Favorece los materiales de tier alto disponibles: peso = tier^2.
            let pool = parts.filter { $0.slot == slot && !used.contains($0.id) }
            guard !pool.isEmpty else { continue }
            let part = WeightedPicker.pick(pool.map { ($0, Double($0.tier * $0.tier)) }, using: &rng)
            used.insert(part.id)
            offers.append(ShopOffer(kind: .part(part), price: part.price))
        }

        // Una pieza de armadura (casco, peto, guantes o botas) del material disponible.
        if let style = ArmorCatalog.styles.randomElement(using: &rng),
           let dye = ArmorCatalog.dyes.randomElement(using: &rng) {
            let item = ArmorCatalog.makeShopItem(style, tier: tierCap, dye: dye)
            offers.append(ShopOffer(kind: .equipment(item), price: item.value))
        }
        // Poción: cura el 50 % y cuesta 15 + 5 × nivel (`economy.potionHeal`, `potionBasePrice`, `potionPricePerLevel`).
        let k = TunedData.current.economy
        offers.append(ShopOffer(kind: .potion(healFraction: k.potionHeal), price: Int(k.potionBasePrice) + Int(k.potionPricePerLevel) * level))
        return offers
    }

    /// 10 + 10 × renovaciones (`economy.rerollBaseCost`, `rerollCostStep`).
    public static func rerollCost(rerollsSoFar: Int) -> Int {
        let k = TunedData.current.economy
        return Int(k.rerollBaseCost) + Int(k.rerollCostStep) * rerollsSoFar
    }
}
