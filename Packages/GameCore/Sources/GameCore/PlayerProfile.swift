import Foundation

/// Todo el progreso persistente del jugador.
public struct PlayerProfile: Codable, Equatable, Sendable {
    public var gold: Int
    public var minerals: [Mineral: Int]
    public var inventory: [Item]
    public var equippedWeaponID: UUID?
    public var equippedArmorID: UUID?
    /// Nivel más alto jugable (1...10).
    public var highestUnlockedLevel: Int
    public var completedLevels: Set<Int>

    public init(
        gold: Int = 0,
        minerals: [Mineral: Int] = [:],
        inventory: [Item] = [],
        equippedWeaponID: UUID? = nil,
        equippedArmorID: UUID? = nil,
        highestUnlockedLevel: Int = 1,
        completedLevels: Set<Int> = []
    ) {
        self.gold = gold
        self.minerals = minerals
        self.inventory = inventory
        self.equippedWeaponID = equippedWeaponID
        self.equippedArmorID = equippedArmorID
        self.highestUnlockedLevel = highestUnlockedLevel
        self.completedLevels = completedLevels
    }

    /// Partida nueva con espada de madera y túnica equipadas.
    public static func newGame() -> PlayerProfile {
        let weapon = Catalog.makeShopItem(Catalog.blueprint(id: Catalog.starterWeaponID)!, rarity: .common, level: 1)
        let armor = Catalog.makeShopItem(Catalog.blueprint(id: Catalog.starterArmorID)!, rarity: .common, level: 1)
        return PlayerProfile(
            gold: 30,
            inventory: [weapon, armor],
            equippedWeaponID: weapon.id,
            equippedArmorID: armor.id
        )
    }

    // MARK: - Equipo

    public var equippedWeapon: Item? { inventory.first { $0.id == equippedWeaponID } }
    public var equippedArmor: Item? { inventory.first { $0.id == equippedArmorID } }

    public func equipped(_ slot: EquipmentSlot) -> Item? {
        slot == .weapon ? equippedWeapon : equippedArmor
    }

    public func isEquipped(_ item: Item) -> Bool {
        item.id == equippedWeaponID || item.id == equippedArmorID
    }

    public var totalStats: Stats {
        var s = Stats.knightBase
        if let w = equippedWeapon { s += w.stats }
        if let a = equippedArmor { s += a.stats }
        return s.clampedForPlay()
    }

    public mutating func equip(_ itemID: UUID) {
        guard let item = inventory.first(where: { $0.id == itemID }) else { return }
        switch item.slot {
        case .weapon: equippedWeaponID = item.id
        case .armor: equippedArmorID = item.id
        }
    }

    /// Vende un objeto no equipado. Devuelve el oro obtenido.
    @discardableResult
    public mutating func sell(_ itemID: UUID) -> Int {
        guard let index = inventory.firstIndex(where: { $0.id == itemID }),
              !isEquipped(inventory[index]) else { return 0 }
        let price = inventory[index].sellPrice
        inventory.remove(at: index)
        gold += price
        return price
    }

    // MARK: - Oro y minerales

    /// Añade oro aplicando la bonificación de oro. Devuelve lo ganado.
    @discardableResult
    public mutating func earnGold(_ base: Int) -> Int {
        let amount = Int((Double(base) * (1 + totalStats.goldBonus)).rounded())
        gold += amount
        return amount
    }

    public mutating func addMineral(_ mineral: Mineral, count: Int = 1) {
        minerals[mineral, default: 0] += count
    }

    public func count(of mineral: Mineral) -> Int {
        minerals[mineral, default: 0]
    }

    // MARK: - Tienda

    public enum PurchaseError: Error, Equatable {
        case notEnoughGold, alreadySold
    }

    /// Compra una oferta de equipo. Las pociones se gestionan en batalla.
    public mutating func buy(_ offer: ShopOffer) throws -> Item? {
        guard !offer.sold else { throw PurchaseError.alreadySold }
        guard gold >= offer.price else { throw PurchaseError.notEnoughGold }
        gold -= offer.price
        if let item = offer.item {
            inventory.append(item)
            return item
        }
        return nil
    }

    // MARK: - Forja

    public var maxCraftTier: Int { Catalog.maxTier(forLevel: highestUnlockedLevel) }

    public func validate(_ recipe: CraftRecipe) -> CraftError? {
        if recipe.blueprint.tier > maxCraftTier { return .blueprintLocked }
        if recipe.totalMinerals < CraftRecipe.minMinerals { return .notEnoughMinerals }
        if recipe.totalMinerals > CraftRecipe.maxMinerals { return .tooManyMinerals }
        for (mineral, amount) in recipe.minerals where count(of: mineral) < amount {
            return .missingMineral(mineral)
        }
        if gold < recipe.goldCost { return .notEnoughGold }
        return nil
    }

    /// Consume minerales y oro, gira la ruleta y añade el objeto al inventario.
    public mutating func craft<G: RandomNumberGenerator>(_ recipe: CraftRecipe, using rng: inout G) throws -> CraftResult {
        if let error = validate(recipe) { throw error }
        for (mineral, amount) in recipe.minerals {
            minerals[mineral, default: 0] -= amount
        }
        gold -= recipe.goldCost
        let index = Roulette.spin(luck: recipe.luck, using: &rng)
        let item = recipe.makeItem(quality: Roulette.segments[index])
        inventory.append(item)
        return CraftResult(item: item, segmentIndex: index)
    }

    // MARK: - Niveles

    public func isUnlocked(level: Int) -> Bool { level <= highestUnlockedLevel }

    public mutating func completeLevel(_ level: Int, totalLevels: Int = 10) {
        completedLevels.insert(level)
        highestUnlockedLevel = min(totalLevels, max(highestUnlockedLevel, level + 1))
    }
}
