import Foundation

/// Aspecto del personaje elegido al crearlo. La app interpreta cada índice según la raza
/// (en el hombre lobo, el "pelo" es el pelaje).
public struct Appearance: Codable, Hashable, Sendable {
    public var skinTone: Int
    public var hairStyle: Int
    public var hairColor: Int
    public var eyeColor: Int

    public init(skinTone: Int = 0, hairStyle: Int = 0, hairColor: Int = 0, eyeColor: Int = 0) {
        self.skinTone = skinTone
        self.hairStyle = hairStyle
        self.hairColor = hairColor
        self.eyeColor = eyeColor
    }
}

/// Todo el progreso persistente de un personaje.
public struct PlayerProfile: Codable, Equatable, Sendable {
    /// Identificador del personaje (nil en partidas antiguas: se asigna al cargar).
    public var characterID: UUID?
    /// Nombre elegido al crear el personaje.
    public var name: String?
    public var appearance: Appearance?
    /// Armadura equipada por hueco (casco, peto, guantes, botas).
    public var equippedGear: [EquipmentSlot: UUID]?
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
    /// Mejor oleada alcanzada en la arena (opcional para no romper partidas antiguas).
    public var arenaBestWave: Int?

    /// Nivel del personaje y experiencia dentro del nivel (opcionales: partidas antiguas empiezan en el 1).
    public var level: Int?
    public var xp: Int?

    /// Progreso en el pueblo explorable (opcional para no romper partidas antiguas).
    public var townProgress: TownProgress?

    public var town: TownProgress {
        get { townProgress ?? TownProgress() }
        set { townProgress = newValue }
    }

    // Modo historia por continentes (todo opcional: las partidas antiguas cargan con nil).
    /// Área donde estaba el héroe al guardar (nil = el pueblo, como en las partidas antiguas).
    public var currentAreaID: String?
    /// Estado de cada misión por id (nil = ninguna empezada).
    public var quests: [String: QuestState]?
    /// Áreas que el héroe ha pisado alguna vez (mapa del continente, M10).
    public var visitedAreaIDs: Set<String>?
    /// Mazmorras de historia ganadas alguna vez (id de `StoryDungeon`).
    public var wonDungeons: Set<String>?
    /// Jefes que ya se han presentado (id de monstruo): su presentación no se repite al volver.
    public var seenBossIntros: Set<String>?
    /// Pistas (`role: .clue`) leídas alguna vez: la segunda lectura es más corta.
    public var readClueIDs: Set<String>?

    /// Área actual con valor por defecto.
    public var areaID: String { currentAreaID ?? Valdehierro.townID }

    /// Continente del área actual (Valdemar si el área no está registrada).
    public var continentID: String { World.area(areaID)?.continentID ?? World.valdemarID }

    /// Estado de una misión (vacío si no se ha empezado).
    public func questState(_ id: String) -> QuestState { quests?[id] ?? QuestState() }

    public func isQuestDone(_ id: String) -> Bool { quests?[id]?.done ?? false }

    /// Entrega una recompensa (oro con bonificación, minerales y pieza).
    public mutating func grant(_ reward: Reward) {
        if reward.gold > 0 { earnGold(reward.gold) }
        for (mineral, count) in reward.minerals { addMineral(mineral, count: count) }
        if let part = reward.partID { addPart(part) }
    }

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
    /// El peto (antes, la única armadura).
    public var equippedArmor: Item? { equipped(.chest) }

    private func equippedID(_ slot: EquipmentSlot) -> UUID? {
        switch slot {
        case .weapon: equippedWeaponID
        case .chest: equippedGear?[.chest] ?? equippedArmorID
        default: equippedGear?[slot]
        }
    }

    public func equipped(_ slot: EquipmentSlot) -> Item? {
        guard let id = equippedID(slot) else { return nil }
        return inventory.first { $0.id == id }
    }

    public func isEquipped(_ item: Item) -> Bool {
        EquipmentSlot.allCases.contains { equippedID($0) == item.id }
    }

    /// Quita una pieza de armadura (el arma no se puede quitar).
    public mutating func unequip(_ slot: EquipmentSlot) {
        guard slot != .weapon else { return }
        equippedGear?[slot] = nil
        if slot == .chest { equippedArmorID = nil }
    }

    /// Cambia el tinte de una pieza de armadura forjada.
    public mutating func setDye(_ dye: UInt32, for itemID: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == itemID }) else { return }
        inventory[index].dye = Int(dye)
    }

    /// Habilidad del arma equipada.
    public var activeAbility: Ability? { equippedWeapon?.ability }

    public var totalStats: Stats {
        var s = race.baseStats + Leveling.levelBonus(race: race, level: characterLevel)
        for slot in EquipmentSlot.allCases {
            if let item = equipped(slot) { s += item.stats }
        }
        if let ability = activeAbility { s += ability.bonus }
        return s.clampedForPlay()
    }

    public mutating func equip(_ itemID: UUID) {
        guard let item = inventory.first(where: { $0.id == itemID }) else { return }
        if item.slot == .weapon {
            equippedWeaponID = item.id
        } else {
            var gear = equippedGear ?? [:]
            gear[item.slot] = item.id
            equippedGear = gear
            if item.slot == .chest { equippedArmorID = nil }
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

    // MARK: - Armería

    /// Nivel de la forja para este personaje: lo mejor entre el pueblo y la arena.
    public var forgeLevel: Int {
        max(town.shopLevel, Arena.shopLevel(wave: arenaBestWave ?? 0))
    }

    /// Tier máximo de material que se puede usar en la armería.
    public var maxArmorTier: Int { PartCatalog.maxShopTier(forLevel: forgeLevel) }

    public func validate(_ recipe: ArmorRecipe) -> CraftError? {
        guard recipe.style != nil, recipe.material != nil else { return .missingPart(.head) }
        if recipe.totalMinerals > ArmorRecipe.maxMinerals { return .tooManyMinerals }
        for (mineral, amount) in recipe.minerals where count(of: mineral) < amount {
            return .missingMineral(mineral)
        }
        if gold < recipe.goldCost { return .notEnoughGold }
        return nil
    }

    /// Forja una pieza de armadura: consume oro y minerales, gira la ruleta y la añade al inventario.
    public mutating func craft<G: RandomNumberGenerator>(_ recipe: ArmorRecipe, using rng: inout G) throws -> CraftResult {
        if let error = validate(recipe) { throw error }
        for (mineral, amount) in recipe.minerals { minerals[mineral, default: 0] -= amount }
        gold -= recipe.goldCost
        let index = Roulette.spin(luck: recipe.luck, using: &rng)
        let item = recipe.makeItem(quality: Roulette.segments[index])
        inventory.append(item)
        return CraftResult(item: item, segmentIndex: index, discoveredNewAbility: false)
    }

    // MARK: - Niveles

    public func isUnlocked(level: Int) -> Bool { level <= highestUnlockedLevel }

    public mutating func completeLevel(_ level: Int, totalLevels: Int = 10) {
        completedLevels.insert(level)
        highestUnlockedLevel = min(totalLevels, max(highestUnlockedLevel, level + 1))
    }
}
