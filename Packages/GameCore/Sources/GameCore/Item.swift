import Foundation

public enum EquipmentSlot: String, Codable, CaseIterable, Sendable {
    case weapon, armor

    public var name: String {
        switch self {
        case .weapon: "Arma"
        case .armor: "Armadura"
        }
    }
}

public enum Rarity: Int, Codable, CaseIterable, Comparable, Sendable {
    case common, rare, epic, legendary

    public var name: String {
        switch self {
        case .common: "Común"
        case .rare: "Raro"
        case .epic: "Épico"
        case .legendary: "Legendario"
        }
    }

    public var statMultiplier: Double {
        switch self {
        case .common: 1
        case .rare: 1.25
        case .epic: 1.5
        case .legendary: 2
        }
    }

    public var priceMultiplier: Double {
        switch self {
        case .common: 1
        case .rare: 1.6
        case .epic: 2.4
        case .legendary: 4
        }
    }

    /// Probabilidad relativa de salir en la tienda.
    public var shopWeight: Double {
        switch self {
        case .common: 70
        case .rare: 22
        case .epic: 7
        case .legendary: 1
        }
    }

    public static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Un tipo de arma/armadura. La tienda vende instancias y la forja las fabrica.
public struct Blueprint: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let slot: EquipmentSlot
    /// 1...4. Se desbloquean con el nivel alcanzado.
    public let tier: Int
    /// Clave del icono pixel-art en la app.
    public let icon: String
    public let baseStats: Stats
    public let basePrice: Int
}

public struct Item: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var blueprintID: String
    public var name: String
    public var slot: EquipmentSlot
    public var tier: Int
    public var icon: String
    public var rarity: Rarity
    public var stats: Stats
    /// Resultado de la ruleta si el objeto es forjado.
    public var qualityName: String?
    public var qualityMultiplier: Double?
    /// Minerales usados al forjar.
    public var minerals: [Mineral: Int]
    /// Valor base en oro.
    public var value: Int

    public init(
        id: UUID = UUID(),
        blueprint: Blueprint,
        name: String? = nil,
        rarity: Rarity,
        stats: Stats,
        qualityName: String? = nil,
        qualityMultiplier: Double? = nil,
        minerals: [Mineral: Int] = [:],
        value: Int
    ) {
        self.id = id
        self.blueprintID = blueprint.id
        self.name = name ?? blueprint.name
        self.slot = blueprint.slot
        self.tier = blueprint.tier
        self.icon = blueprint.icon
        self.rarity = rarity
        self.stats = stats
        self.qualityName = qualityName
        self.qualityMultiplier = qualityMultiplier
        self.minerals = minerals
        self.value = value
    }

    public var isCrafted: Bool { qualityName != nil }

    public var sellPrice: Int { max(1, value * 4 / 10) }

    /// Puntuación aproximada para comparar objetos ("¿es mejor?").
    public var powerScore: Double {
        Item.powerScore(of: stats)
    }

    public static func powerScore(of s: Stats) -> Double {
        s.attack * 3
            + s.defense * 2.5
            + s.maxHP * 0.4
            + s.attackSpeed * 40
            + s.range * 0.6
            + s.moveSpeed * 0.3
            + s.critChance * 120
            + s.critMultiplier * 30
            + s.lifesteal * 200
            + s.goldBonus * 60
            + s.regen * 12
    }
}

public enum Catalog {
    public static let blueprints: [Blueprint] = [
        // Armas
        Blueprint(id: "wood_sword", name: "Espada de madera", slot: .weapon, tier: 1, icon: "sword_wood",
                  baseStats: Stats(attack: 3), basePrice: 20),
        Blueprint(id: "short_sword", name: "Espada corta", slot: .weapon, tier: 1, icon: "sword_iron",
                  baseStats: Stats(attack: 6, attackSpeed: 0.1), basePrice: 45),
        Blueprint(id: "hand_axe", name: "Hacha de mano", slot: .weapon, tier: 2, icon: "axe",
                  baseStats: Stats(attack: 15, attackSpeed: -0.1, critMultiplier: 0.1), basePrice: 110),
        Blueprint(id: "long_sword", name: "Espada larga", slot: .weapon, tier: 2, icon: "sword_steel",
                  baseStats: Stats(attack: 14, range: 6), basePrice: 120),
        Blueprint(id: "spear", name: "Lanza", slot: .weapon, tier: 3, icon: "spear",
                  baseStats: Stats(attack: 18, range: 20), basePrice: 220),
        Blueprint(id: "greatsword", name: "Mandoble", slot: .weapon, tier: 3, icon: "greatsword",
                  baseStats: Stats(attack: 24, attackSpeed: -0.1, range: 8), basePrice: 260),
        Blueprint(id: "war_hammer", name: "Martillo de guerra", slot: .weapon, tier: 4, icon: "hammer",
                  baseStats: Stats(attack: 36, attackSpeed: -0.25, critMultiplier: 0.3), basePrice: 420),
        Blueprint(id: "rune_sword", name: "Espada rúnica", slot: .weapon, tier: 4, icon: "sword_rune",
                  baseStats: Stats(attack: 30, attackSpeed: 0.1, critChance: 0.08), basePrice: 450),
        // Armaduras
        Blueprint(id: "padded_tunic", name: "Túnica acolchada", slot: .armor, tier: 1, icon: "armor_tunic",
                  baseStats: Stats(maxHP: 10, defense: 2), basePrice: 20),
        Blueprint(id: "leather_armor", name: "Cota de cuero", slot: .armor, tier: 1, icon: "armor_leather",
                  baseStats: Stats(maxHP: 15, defense: 5), basePrice: 50),
        Blueprint(id: "chainmail", name: "Cota de malla", slot: .armor, tier: 2, icon: "armor_chain",
                  baseStats: Stats(maxHP: 25, defense: 13, moveSpeed: -5), basePrice: 120),
        Blueprint(id: "scale_armor", name: "Armadura de escamas", slot: .armor, tier: 3, icon: "armor_scale",
                  baseStats: Stats(maxHP: 45, defense: 22, moveSpeed: -8), basePrice: 230),
        Blueprint(id: "plate_armor", name: "Armadura de placas", slot: .armor, tier: 4, icon: "armor_plate",
                  baseStats: Stats(maxHP: 80, defense: 32, moveSpeed: -15), basePrice: 430),
        Blueprint(id: "elven_mail", name: "Malla élfica", slot: .armor, tier: 4, icon: "armor_elven",
                  baseStats: Stats(maxHP: 50, defense: 22, moveSpeed: 10, regen: 1), basePrice: 440),
    ]

    public static func blueprint(id: String) -> Blueprint? {
        blueprints.first { $0.id == id }
    }

    /// Nivel máximo de equipo disponible según el nivel de juego: 1-2 → T1, 3-5 → T2, 6-8 → T3, 9-10 → T4.
    public static func maxTier(forLevel level: Int) -> Int {
        min(4, 1 + level / 3)
    }

    public static func blueprints(upToTier tier: Int) -> [Blueprint] {
        blueprints.filter { $0.tier <= tier }
    }

    /// Crea un objeto de tienda con la rareza indicada. Escala un poco con el nivel.
    public static func makeShopItem(_ blueprint: Blueprint, rarity: Rarity, level: Int) -> Item {
        let levelScale = 1 + 0.1 * Double(max(0, level - 1))
        let stats = blueprint.baseStats * (rarity.statMultiplier * levelScale)
        let value = Int((Double(blueprint.basePrice) * rarity.priceMultiplier * levelScale).rounded())
        let name = rarity == .common ? blueprint.name : "\(blueprint.name) \(rarity.adjective(for: blueprint))"
        return Item(blueprint: blueprint, name: name, rarity: rarity, stats: stats, value: value)
    }

    static let starterWeaponID = "wood_sword"
    static let starterArmorID = "padded_tunic"
}

extension Rarity {
    /// Adjetivo para el nombre del objeto ("Espada corta afilada").
    func adjective(for blueprint: Blueprint) -> String {
        switch (self, blueprint.slot) {
        case (.common, _): ""
        case (.rare, .weapon): "afilada"
        case (.rare, .armor): "reforzada"
        case (.epic, .weapon): "del campeón"
        case (.epic, .armor): "del guardián"
        case (.legendary, _): "legendaria"
        }
    }
}
