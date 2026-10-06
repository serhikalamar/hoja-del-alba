import Foundation

/// Todo el progreso persistente del jugador.
public struct PlayerProfile: Codable, Equatable, Sendable {
    public var race: Race
    /// `false` hasta que el jugador elige raza en una partida nueva.
    public var hasChosenRace: Bool
    public var gold: Int
    public var minerals: [Mineral: Int]
    /// Piezas de arma guardadas (id → cantidad).
    public var parts: [String: Int]
    public var inventory: [Item]
    public var equippedWeaponID: UUID?
    public var equippedArmorID: UUID?
    /// Nivel más alto jugable (1...10).
    public var highestUnlockedLevel: Int
    public var completedLevels: Set<Int>
    /// Habilidades secretas ya descubiertas en el ritual.
    public var discoveredAbilities: Set<String>
    public var defeatedBosses: Set<String>

    public init(
        race: Race = .human,
        hasChosenRace: Bool = false,
        gold: Int = 0,
        minerals: [Mineral: Int] = [:],
        parts: [String: Int] = [:],
        inventory: [Item] = [],
        equippedWeaponID: UUID? = nil,
        equippedArmorID: UUID? = nil,
        highestUnlockedLevel: Int = 1,
        completedLevels: Set<Int> = [],
        discoveredAbilities: Set<String> = [],
        defeatedBosses: Set<String> = []
    ) {
        self.race = race
        self.hasChosenRace = hasChosenRace
        self.gold = gold
        self.minerals = minerals
        self.parts = parts
        self.inventory = inventory
        self.equippedWeaponID = equippedWeaponID
        self.equippedArmorID = equippedArmorID
        self.highestUnlockedLevel = highestUnlockedLevel
        self.completedLevels = completedLevels
        self.discoveredAbilities = discoveredAbilities
        self.defeatedBosses = defeatedBosses
    }

    /// Partida nueva: espada de entrenamiento, túnica y piezas para forjar la primera arma.
    public static func newGame(race: Race = .human) -> PlayerProfile {
        let weapon = Catalog.makeShopItem(Catalog.blueprint(id: Catalog.starterWeaponID)!, rarity: .common, level: 1)
        let armor = Catalog.makeShopItem(Catalog.blueprint(id: Catalog.starterArmorID)!, rarity: .common, level: 1)
        return PlayerProfile(
            race: race,
            gold: 30,
            minerals: [.copper: 3],
            parts: ["head.sword.copper": 1, "guard.straight.copper": 1, "grip.short.oak": 1],
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

    /// Habilidad del arma equipada.
    public var activeAbility: Ability? { equippedWeapon?.ability }

    public var totalStats: Stats {
        var s = race.baseStats
        if let w = equippedWeapon { s += w.stats }
        if let a = equippedArmor { s += a.stats }
        if let ability = activeAbility { s += ability.bonus }
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

    public mutating func setCustomSprite(_ sprite: CustomSprite?, for itemID: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == itemID }) else { return }
        inventory[index].customSprite = sprite
    }

    // MARK: - Oro, minerales y piezas

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

    public mutating func addPart(_ partID: String, count: Int = 1) {
        parts[partID, default: 0] += count
    }

    public func partCount(_ partID: String) -> Int {
        parts[partID, default: 0]
    }

    /// Piezas que tiene el jugador, de un hueco concreto.
    public func ownedParts(_ slot: PartSlot) -> [WeaponPart] {
        parts.filter { $0.value > 0 }
            .compactMap { PartCatalog.part($0.key) }
            .filter { $0.slot == slot }
            .sorted { a, b in
                if a.isSpecial != b.isSpecial { return a.isSpecial }
                return a.tier != b.tier ? a.tier > b.tier : a.name < b.name
            }
    }

    // MARK: - Tienda

    public enum PurchaseError: Error, Equatable {
        case notEnoughGold, alreadySold
    }

    /// Compra una oferta de equipo o pieza. Las pociones se gestionan en batalla.
    @discardableResult
    public mutating func buy(_ offer: ShopOffer) throws -> Item? {
        guard !offer.sold else { throw PurchaseError.alreadySold }
        guard gold >= offer.price else { throw PurchaseError.notEnoughGold }
        gold -= offer.price
        switch offer.kind {
        case .equipment(let item):
            inventory.append(item)
            return item
        case .part(let part):
            addPart(part.id)
            return nil
        case .potion:
            return nil
        }
    }

    // MARK: - Ritual de forja

    public func validate(_ recipe: WeaponRecipe) -> CraftError? {
        let slots: [(String, PartSlot)] = [(recipe.headID, .head), (recipe.guardID, .hilt), (recipe.gripID, .grip)]
        for (id, slot) in slots {
            guard let part = PartCatalog.part(id), partCount(id) > 0 else { return .missingPart(slot) }
            if part.slot != slot { return .wrongSlot(slot) }
        }
        if recipe.totalMinerals > WeaponRecipe.maxMinerals { return .tooManyMinerals }
        for (mineral, amount) in recipe.minerals where count(of: mineral) < amount {
            return .missingMineral(mineral)
        }
        if gold < recipe.goldCost { return .notEnoughGold }
        return nil
    }

    /// Consume piezas, minerales y oro, gira la ruleta y añade el arma al inventario.
    public mutating func craft<G: RandomNumberGenerator>(_ recipe: WeaponRecipe, using rng: inout G) throws -> CraftResult {
        if let error = validate(recipe) { throw error }
        for id in recipe.partIDs { parts[id, default: 0] -= 1 }
        parts = parts.filter { $0.value > 0 }
        for (mineral, amount) in recipe.minerals {
            minerals[mineral, default: 0] -= amount
        }
        gold -= recipe.goldCost
        let index = Roulette.spin(luck: recipe.luck, using: &rng)
        let item = recipe.makeItem(quality: Roulette.segments[index])
        inventory.append(item)
        var isNew = false
        if let ability = item.abilityID {
            isNew = discoveredAbilities.insert(ability).inserted
        }
        return CraftResult(item: item, segmentIndex: index, discoveredNewAbility: isNew)
    }

    // MARK: - Niveles

    public func isUnlocked(level: Int) -> Bool { level <= highestUnlockedLevel }

    public mutating func completeLevel(_ level: Int, totalLevels: Int = 10) {
        completedLevels.insert(level)
        highestUnlockedLevel = min(totalLevels, max(highestUnlockedLevel, level + 1))
    }
}
