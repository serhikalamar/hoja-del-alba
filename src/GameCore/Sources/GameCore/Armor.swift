import Foundation

/// Tipo de material de una pieza de armadura (decide qué materiales se pueden usar).
public enum ArmorMaterialKind: String, Sendable {
    case metal, leather, cloth

    public var materials: [PartMaterial] {
        switch self {
        case .metal: PartMaterial.metals
        case .leather: PartMaterial.leathers
        case .cloth: PartMaterial.cloths
        }
    }
}

/// Un diseño de armadura (casco, peto, guantes o botas). El arte se dibuja en la app por `id`.
public struct ArmorStyle: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let slot: EquipmentSlot
    public let materialKind: ArmorMaterialKind
    /// Estadísticas con material de tier 1 (se multiplican por el poder del material). Ajustable: `armor.<id>.stats`.
    public internal(set) var base: Stats
    /// Oro base de la forja puesto por el panel (`armor.<id>.price`); nil = el de su hueco.
    var priceOverride: Double? = nil

    /// Oro base de la forja a tier 1: el peto vale como una hoja (30), el casco 22, las botas 20 y los guantes 16.
    /// Coste final: `ArmorRecipe.goldCost`.
    public var forgePrice: Double {
        if let priceOverride { return priceOverride }
        return switch slot {
        case .chest: 30
        case .helmet: 22
        case .boots: 20
        default: 16
        }
    }
}

public enum ArmorCatalog {
    /// Diseños con los ajustes del panel aplicados.
    public static var styles: [ArmorStyle] { TunedData.current.armorStyles }

    /// Diseños del código.
    static let baseStyles: [ArmorStyle] = [
        // Cascos
        ArmorStyle(id: "helm.knight", name: "Yelmo de caballero", slot: .helmet, materialKind: .metal, base: Stats(maxHP: 8, defense: 3)),
        ArmorStyle(id: "helm.horned", name: "Casco astado", slot: .helmet, materialKind: .metal, base: Stats(maxHP: 6, attack: 1, defense: 2)),
        ArmorStyle(id: "helm.great", name: "Gran yelmo", slot: .helmet, materialKind: .metal, base: Stats(maxHP: 10, defense: 5, moveSpeed: -3)),
        ArmorStyle(id: "helm.hood", name: "Capucha", slot: .helmet, materialKind: .cloth, base: Stats(defense: 1, critChance: 0.02)),
        ArmorStyle(id: "helm.circlet", name: "Diadema", slot: .helmet, materialKind: .metal, base: Stats(attackSpeed: 0.03, critChance: 0.03)),
        // Petos
        ArmorStyle(id: "chest.plate", name: "Peto de placas", slot: .chest, materialKind: .metal, base: Stats(maxHP: 25, defense: 8, moveSpeed: -6)),
        ArmorStyle(id: "chest.chain", name: "Cota de malla", slot: .chest, materialKind: .metal, base: Stats(maxHP: 18, defense: 6)),
        ArmorStyle(id: "chest.leather", name: "Jubón de cuero", slot: .chest, materialKind: .leather, base: Stats(maxHP: 12, defense: 4, moveSpeed: 4)),
        ArmorStyle(id: "chest.robe", name: "Túnica arcana", slot: .chest, materialKind: .cloth, base: Stats(maxHP: 10, defense: 2, critChance: 0.03, regen: 0.3)),
        ArmorStyle(id: "chest.tabard", name: "Tabardo de guardia", slot: .chest, materialKind: .cloth, base: Stats(maxHP: 15, defense: 5, goldBonus: 0.03)),
        // Guantes
        ArmorStyle(id: "gloves.gauntlets", name: "Guanteletes", slot: .gloves, materialKind: .metal, base: Stats(attack: 1, defense: 2)),
        ArmorStyle(id: "gloves.leather", name: "Guantes de cuero", slot: .gloves, materialKind: .leather, base: Stats(defense: 1, attackSpeed: 0.05)),
        ArmorStyle(id: "gloves.bracers", name: "Brazales", slot: .gloves, materialKind: .metal, base: Stats(attack: 2, critChance: 0.01)),
        ArmorStyle(id: "gloves.wraps", name: "Vendas de luchador", slot: .gloves, materialKind: .cloth, base: Stats(attackSpeed: 0.08)),
        // Botas
        ArmorStyle(id: "boots.greaves", name: "Grebas", slot: .boots, materialKind: .metal, base: Stats(maxHP: 6, defense: 3, moveSpeed: -2)),
        ArmorStyle(id: "boots.leather", name: "Botas de cuero", slot: .boots, materialKind: .leather, base: Stats(defense: 1, moveSpeed: 8)),
        ArmorStyle(id: "boots.fur", name: "Botas de piel", slot: .boots, materialKind: .leather, base: Stats(maxHP: 10, regen: 0.2)),
        ArmorStyle(id: "boots.winged", name: "Botas aladas", slot: .boots, materialKind: .cloth, base: Stats(moveSpeed: 14)),
    ]

    public static func style(_ id: String?) -> ArmorStyle? { id.flatMap { TunedData.current.armorByID[$0] } }

    public static func styles(for slot: EquipmentSlot) -> [ArmorStyle] { styles.filter { $0.slot == slot } }

    public static func material(_ id: String?) -> PartMaterial? {
        guard let id else { return nil }
        return (PartMaterial.metals + PartMaterial.leathers + PartMaterial.cloths).first { $0.id == id }
    }

    /// Tintes que el jugador puede elegir para la tela y los detalles (RGB).
    public static let dyes: [UInt32] = [
        0x3B5DC9, 0xB13E53, 0x2E8A44, 0x5D275D, 0xEF7D57, 0xFFCD75,
        0x2A9AA0, 0x333C57, 0xF4F4F4, 0x7A4A2A, 0xF27AA8, 0x1A1C2C,
    ]

    /// Pieza de armadura de tienda: calidad normal, material del tier indicado.
    public static func makeShopItem(_ style: ArmorStyle, tier: Int, dye: UInt32) -> Item {
        let material = style.materialKind.materials[max(0, min(5, tier - 1))]
        return ArmorRecipe(styleID: style.id, materialID: material.id, dye: dye)
            .makeItem(quality: Roulette.segments[2])
    }
}

extension PartMaterial {
    /// Cueros para jubones, guantes y botas.
    public static let leathers: [PartMaterial] = [
        PartMaterial(id: "hide", name: "Piel curtida", tier: 1, element: nil, palette: [0xB07A50, 0x7A4A2A, 0x4A2A16]),
        PartMaterial(id: "boarhide", name: "Cuero de jabalí", tier: 2, element: .earth, palette: [0x9A6A44, 0x6A4428, 0x3A2414]),
        PartMaterial(id: "wolfhide", name: "Piel de lobo", tier: 3, element: .wind, palette: [0xB8B0A8, 0x7A7470, 0x4A4644]),
        PartMaterial(id: "trollhide", name: "Cuero de troll", tier: 4, element: .blood, palette: [0x7A9AA0, 0x4A6A70, 0x2A3E44]),
        PartMaterial(id: "shadowhide", name: "Cuero sombrío", tier: 5, element: .shadow, palette: [0x6A5A7A, 0x3A3046, 0x1A1420]),
        PartMaterial(id: "dragonhide", name: "Piel de dragón", tier: 6, element: .fire, palette: [0xF07050, 0xB02C2C, 0x581018]),
    ]

    /// Telas para capuchas, túnicas, tabardos, vendas y botas aladas.
    public static let cloths: [PartMaterial] = [
        PartMaterial(id: "linen", name: "Lino", tier: 1, element: nil, palette: [0xF0E6CC, 0xC8B898, 0x8A7A5A]),
        PartMaterial(id: "wool", name: "Lana", tier: 2, element: .earth, palette: [0xD8C8B0, 0xA8987E, 0x6A5C48]),
        PartMaterial(id: "silk", name: "Seda", tier: 3, element: .wind, palette: [0xFFF4F8, 0xE0C8D8, 0xA088A0]),
        PartMaterial(id: "velvet", name: "Terciopelo", tier: 4, element: .arcane, palette: [0xC86A9A, 0x8A3A6A, 0x4A1A3A]),
        PartMaterial(id: "moonsilk", name: "Seda lunar", tier: 5, element: .ice, palette: [0xE8FFFF, 0xA8D8F0, 0x5A8AB0]),
        PartMaterial(id: "starcloth", name: "Tela de estrellas", tier: 6, element: .holy, palette: [0xFFF8D0, 0xE0C060, 0x8A6A20]),
    ]
}

/// Lo que el jugador elige en la armería: diseño, material, tinte y minerales.
public struct ArmorRecipe: Equatable, Sendable {
    public static let maxMinerals = 8

    public var styleID: String
    public var materialID: String
    public var dye: UInt32
    public var minerals: [Mineral: Int]

    public init(styleID: String, materialID: String, dye: UInt32, minerals: [Mineral: Int] = [:]) {
        self.styleID = styleID
        self.materialID = materialID
        self.dye = dye
        self.minerals = minerals.filter { $0.value > 0 }
    }

    public var style: ArmorStyle? { ArmorCatalog.style(styleID) }
    public var material: PartMaterial? { ArmorCatalog.material(materialID) }
    public var tier: Int { material?.tier ?? 1 }
    /// Oro de la forja: como las piezas de arma (el peto vale como una hoja, los guantes como una empuñadura),
    /// para que el equipo completo cueste algo más que un arma del mismo tier.
    public var goldCost: Int {
        let slotPrice = style?.forgePrice ?? 30
        return Int((slotPrice * pow(material?.power ?? 1, 1.3)).rounded()) + 5
    }
    public var totalMinerals: Int { minerals.values.reduce(0, +) }

    public var luck: Double {
        min(1.5, minerals.reduce(0.0) { $0 + Double($1.value * ($1.key.rarityTier - 1)) * 0.03 })
    }

    public func stats(multiplier: Double) -> Stats {
        let base = material?.scale(style?.base ?? .zero) ?? (style?.base ?? .zero)
        let buffs = minerals.reduce(Stats.zero) { $0 + $1.key.buffPerUnit * Double($1.value) * 0.5 }
        return (base + buffs) * multiplier
    }

    public var itemName: String {
        guard let style, let material else { return "Armadura" }
        return "\(style.name) de \(material.name)"
    }

    public func makeItem(quality: CraftQuality) -> Item {
        let blueprint = Blueprint(id: "armor.\(styleID)", name: itemName, slot: style?.slot ?? .chest,
                                  tier: tier, icon: styleID, baseStats: .zero, basePrice: 0)
        // Valor: 1,5 veces lo que cuesta forjarla (la tienda la vende a ese precio, ya hecha y sin ruleta).
        let price = Int((Double(goldCost) * 1.5 * quality.multiplier).rounded())
        var item = Item(blueprint: blueprint, name: itemName, rarity: quality.rarity, stats: stats(multiplier: quality.multiplier),
                        qualityName: quality.name, qualityMultiplier: quality.multiplier, minerals: minerals, value: price)
        item.styleID = styleID
        item.materialID = materialID
        item.dye = Int(dye)
        return item
    }
}
