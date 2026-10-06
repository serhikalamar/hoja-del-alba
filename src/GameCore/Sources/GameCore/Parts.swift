import Foundation

/// Afinidad mágica de una pieza. Las combinaciones de elementos despiertan habilidades secretas.
public enum Element: String, CaseIterable, Codable, Identifiable, Sendable {
    case fire, ice, storm, poison, holy, shadow, blood, wind, earth, arcane

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .fire: "Fuego"
        case .ice: "Hielo"
        case .storm: "Tormenta"
        case .poison: "Veneno"
        case .holy: "Sagrado"
        case .shadow: "Sombra"
        case .blood: "Sangre"
        case .wind: "Viento"
        case .earth: "Tierra"
        case .arcane: "Arcano"
        }
    }

    /// Color representativo (RGB) para la interfaz.
    public var color: UInt32 {
        switch self {
        case .fire: 0xEF7D57
        case .ice: 0x8FD8F0
        case .storm: 0xFFE066
        case .poison: 0x8BD450
        case .holy: 0xFFF4C0
        case .shadow: 0x8A6AAA
        case .blood: 0xE43B44
        case .wind: 0xA7F0D0
        case .earth: 0xB8864E
        case .arcane: 0xC879F2
        }
    }
}

/// Las tres partes de un arma.
public enum PartSlot: String, CaseIterable, Codable, Identifiable, Sendable {
    case head, hilt = "guard", grip

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .head: "Hoja / cabeza"
        case .hilt: "Guarda"
        case .grip: "Empuñadura"
        }
    }
}

/// Tipo de arma, decidido por la hoja / cabeza.
public enum WeaponShape: String, CaseIterable, Codable, Sendable {
    case sword, axe, hammer, spear, dagger, scythe, mace, katana, greatsword

    public var name: String {
        switch self {
        case .sword: "Espada"
        case .axe: "Hacha"
        case .hammer: "Martillo"
        case .spear: "Lanza"
        case .dagger: "Daga"
        case .scythe: "Guadaña"
        case .mace: "Maza"
        case .katana: "Katana"
        case .greatsword: "Mandoble"
        }
    }

    var partName: String {
        switch self {
        case .sword: "Hoja de espada"
        case .axe: "Cabeza de hacha"
        case .hammer: "Cabeza de martillo"
        case .spear: "Punta de lanza"
        case .dagger: "Hoja de daga"
        case .scythe: "Hoja de guadaña"
        case .mace: "Bola de maza"
        case .katana: "Hoja de katana"
        case .greatsword: "Hoja de mandoble"
        }
    }

    var element: Element? {
        switch self {
        case .sword, .greatsword: nil
        case .axe: .blood
        case .hammer: .earth
        case .spear: .wind
        case .dagger: .poison
        case .scythe: .shadow
        case .mace: .holy
        case .katana: .storm
        }
    }

    var baseStats: Stats {
        switch self {
        case .sword: Stats(attack: 9, attackSpeed: 0.1)
        case .axe: Stats(attack: 13, attackSpeed: -0.1, critMultiplier: 0.2)
        case .hammer: Stats(attack: 17, attackSpeed: -0.25, critMultiplier: 0.3)
        case .spear: Stats(attack: 10, range: 18)
        case .dagger: Stats(attack: 6, attackSpeed: 0.35, critChance: 0.06)
        case .scythe: Stats(attack: 13, range: 10, critMultiplier: 0.15)
        case .mace: Stats(attack: 14, defense: 2, attackSpeed: -0.15)
        case .katana: Stats(attack: 10, attackSpeed: 0.15, critChance: 0.05)
        case .greatsword: Stats(attack: 17, attackSpeed: -0.15, range: 8)
        }
    }
}

public enum GuardShape: String, CaseIterable, Codable, Sendable {
    case straight, curved, winged, ring, skull, claw, crown

    var partName: String {
        switch self {
        case .straight: "Guarda recta"
        case .curved: "Guarda curva"
        case .winged: "Guarda alada"
        case .ring: "Guarda de anillo"
        case .skull: "Guarda de calavera"
        case .claw: "Guarda de garra"
        case .crown: "Guarda coronada"
        }
    }

    var element: Element? {
        switch self {
        case .straight: .holy
        case .curved, .crown: nil
        case .winged: .wind
        case .ring: .arcane
        case .skull: .shadow
        case .claw: .blood
        }
    }

    var baseStats: Stats {
        switch self {
        case .straight: Stats(defense: 2)
        case .curved: Stats(critChance: 0.03)
        case .winged: Stats(attackSpeed: 0.08)
        case .ring: Stats(critMultiplier: 0.1)
        case .skull: Stats(attack: 2, lifesteal: 0.01)
        case .claw: Stats(attack: 1, critChance: 0.02)
        case .crown: Stats(attack: 3, critChance: 0.03, goldBonus: 0.1)
        }
    }
}

public enum GripShape: String, CaseIterable, Codable, Sendable {
    case short, long, wrapped, pommel, runic

    var partName: String {
        switch self {
        case .short: "Empuñadura corta"
        case .long: "Empuñadura larga"
        case .wrapped: "Empuñadura vendada"
        case .pommel: "Empuñadura con pomo"
        case .runic: "Empuñadura rúnica"
        }
    }

    var element: Element? {
        switch self {
        case .short, .long: nil
        case .wrapped: .poison
        case .pommel: .earth
        case .runic: .arcane
        }
    }

    var baseStats: Stats {
        switch self {
        case .short: Stats(attackSpeed: 0.1)
        case .long: Stats(range: 6)
        case .wrapped: Stats(critChance: 0.02)
        case .pommel: Stats(attack: 2)
        case .runic: Stats(critChance: 0.01, critMultiplier: 0.05)
        }
    }
}

/// Material de una pieza. Los metales son para hojas y guardas; las maderas/huesos para empuñaduras.
public struct PartMaterial: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// 1...6
    public let tier: Int
    public let element: Element?
    /// Colores (claro, medio, oscuro) para dibujar la pieza.
    public let palette: [UInt32]

    /// Multiplicador de estadísticas por tier.
    public var power: Double { [1.0, 1.6, 2.4, 3.3, 4.4, 5.6][tier - 1] }

    public static let metals: [PartMaterial] = [
        PartMaterial(id: "copper", name: "Cobre", tier: 1, element: .storm, palette: [0xF0A070, 0xC8693C, 0x7A3A1E]),
        PartMaterial(id: "iron", name: "Hierro", tier: 2, element: .earth, palette: [0xC8C8D0, 0x8A8A96, 0x4A4A56]),
        PartMaterial(id: "silver", name: "Plata", tier: 3, element: .holy, palette: [0xFFFFFF, 0xC0C8DC, 0x7C86A0]),
        PartMaterial(id: "obsidian", name: "Obsidiana", tier: 4, element: .fire, palette: [0x9A7ABA, 0x4A3A5A, 0x1F1428]),
        PartMaterial(id: "glacite", name: "Glacita", tier: 5, element: .ice, palette: [0xE8FFFF, 0x8FD8F0, 0x3C8CB0]),
        PartMaterial(id: "mithril", name: "Mithril", tier: 6, element: .wind, palette: [0xE0FFF8, 0x6FE0D0, 0x2A8A90]),
    ]

    public static let woods: [PartMaterial] = [
        PartMaterial(id: "oak", name: "Roble", tier: 1, element: .earth, palette: [0xC08A5A, 0x8F5A32, 0x5A3418]),
        PartMaterial(id: "leather", name: "Cuero", tier: 2, element: .blood, palette: [0xB07050, 0x7A4430, 0x4A2418]),
        PartMaterial(id: "ash", name: "Fresno", tier: 3, element: .wind, palette: [0xE8D098, 0xB89A5E, 0x7A6236]),
        PartMaterial(id: "bone", name: "Hueso", tier: 4, element: .shadow, palette: [0xF8F2DC, 0xCFC4A0, 0x8A7E5E]),
        PartMaterial(id: "ebony", name: "Ébano", tier: 5, element: .arcane, palette: [0x6A5A7A, 0x3A3046, 0x1A1420]),
        PartMaterial(id: "dragonscale", name: "Escama de dragón", tier: 6, element: .fire, palette: [0xF07050, 0xB02C2C, 0x581018]),
    ]
}

/// Una pieza de arma. Se compran al enano o las sueltan los jefes.
public struct WeaponPart: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let slot: PartSlot
    /// Forma (clave del dibujo): `WeaponShape`, `GuardShape` o `GripShape`.
    public let shape: String
    public let materialName: String
    public let tier: Int
    public let stats: Stats
    public let elements: [Element]
    public let palette: [UInt32]
    public let price: Int
    /// Pieza única de jefe.
    public let isSpecial: Bool
    /// Habilidad propia (solo piezas de jefe).
    public let abilityID: String?

    public var weaponShape: WeaponShape? { slot == .head ? WeaponShape(rawValue: shape) : nil }
}

public enum PartCatalog {
    public static let normalParts: [WeaponPart] = {
        var parts: [WeaponPart] = []
        let slotPrice: [PartSlot: Double] = [.head: 30, .hilt: 18, .grip: 15]
        func make(_ slot: PartSlot, shape: String, partName: String, shapeElement: Element?, base: Stats, material: PartMaterial) -> WeaponPart {
            var elements: [Element] = []
            if let e = material.element { elements.append(e) }
            if let e = shapeElement { elements.append(e) }
            return WeaponPart(
                id: "\(slot.rawValue).\(shape).\(material.id)",
                name: "\(partName) de \(material.name)",
                slot: slot,
                shape: shape,
                materialName: material.name,
                tier: material.tier,
                stats: base * material.power,
                elements: elements,
                palette: material.palette,
                price: Int((slotPrice[slot]! * pow(material.power, 1.3)).rounded()),
                isSpecial: false,
                abilityID: nil
            )
        }
        for material in PartMaterial.metals {
            for shape in WeaponShape.allCases {
                parts.append(make(.head, shape: shape.rawValue, partName: shape.partName, shapeElement: shape.element, base: shape.baseStats, material: material))
            }
        }
        for material in PartMaterial.metals {
            for shape in GuardShape.allCases where shape != .crown {
                parts.append(make(.hilt, shape: shape.rawValue, partName: shape.partName, shapeElement: shape.element, base: shape.baseStats, material: material))
            }
        }
        for material in PartMaterial.woods {
            for shape in GripShape.allCases {
                parts.append(make(.grip, shape: shape.rawValue, partName: shape.partName, shapeElement: shape.element, base: shape.baseStats, material: material))
            }
        }
        return parts
    }()

    /// Piezas únicas que sueltan los jefes.
    public static let specialParts: [WeaponPart] = [
        special("boss.ratKing", "Diente del Rey Rata", .head, WeaponShape.dagger.rawValue, 3,
                Stats(attack: 14, attackSpeed: 0.4, critChance: 0.08), [.poison, .blood], [0xFFF6D0, 0xE0D0A0, 0x8A7040], "rat_bite"),
        special("boss.banditChief", "Guarda del Capitán", .hilt, GuardShape.skull.rawValue, 3,
                Stats(attack: 5, critChance: 0.08, goldBonus: 0.15), [.shadow, .blood], [0xFFE080, 0xD0A030, 0x805010], "low_blow"),
        special("boss.scarecrow", "Mango del Espantapájaros", .grip, GripShape.wrapped.rawValue, 4,
                Stats(attack: 6, range: 10, critChance: 0.04), [.shadow, .fire], [0xF0D070, 0xB08A3A, 0x6A4A1A], "burning_harvest"),
        special("boss.possessedSmith", "Martillo del Herrero", .head, WeaponShape.hammer.rawValue, 4,
                Stats(attack: 40, defense: 4, attackSpeed: -0.2, critMultiplier: 0.4), [.fire, .earth], [0xFFB070, 0xE04020, 0x601010], "hellforge"),
        special("boss.alphaWolf", "Colmillo Alfa", .hilt, GuardShape.claw.rawValue, 5,
                Stats(attack: 8, attackSpeed: 0.2, lifesteal: 0.03), [.blood, .wind], [0xF4F0E8, 0xC8C0B0, 0x6A6458], "frenzy"),
        special("boss.witch", "Escoba de la Bruja", .grip, GripShape.runic.rawValue, 5,
                Stats(attack: 6, attackSpeed: 0.15, critMultiplier: 0.25), [.poison, .arcane], [0x9BE070, 0x5A2A7A, 0x2A1040], "hex"),
        special("boss.ogre", "Piedra de molino", .head, WeaponShape.mace.rawValue, 5,
                Stats(maxHP: 40, attack: 55, defense: 6, attackSpeed: -0.3), [.earth, .earth], [0xD0C8B8, 0x8A8070, 0x4A4438], "crush"),
        special("boss.abbot", "Rosario del Abad", .hilt, GuardShape.ring.rawValue, 6,
                Stats(attack: 10, critChance: 0.06, regen: 1.5), [.holy, .shadow], [0xFFF4C0, 0xB070D0, 0x402060], "dark_communion"),
        special("boss.warlord", "Hoja del Señor de la Guerra", .head, WeaponShape.greatsword.rawValue, 6,
                Stats(attack: 75, attackSpeed: -0.1, range: 14, critMultiplier: 0.3), [.blood, .storm], [0xFF8070, 0xA02020, 0x380808], "carnage"),
        special("boss.goblinKing", "Corona del Rey Goblin", .hilt, GuardShape.crown.rawValue, 6,
                Stats(attack: 18, attackSpeed: 0.2, critChance: 0.1, goldBonus: 0.3), [.arcane, .holy, .storm], [0xFFF0A0, 0xFFC830, 0xA06A00], "royal_decree"),
        // Pieza legendaria: la entrega la princesa al ser rescatada.
        special("legend.dawn", "Hoja del Alba", .head, WeaponShape.greatsword.rawValue, 6,
                Stats(attack: 95, attackSpeed: 0.1, range: 16, critChance: 0.1, critMultiplier: 0.4), [.holy, .storm, .fire],
                [0xFFFCE8, 0xFFD870, 0xC07A20], "dawn"),
    ]

    private static func special(_ id: String, _ name: String, _ slot: PartSlot, _ shape: String, _ tier: Int,
                                _ stats: Stats, _ elements: [Element], _ palette: [UInt32], _ ability: String) -> WeaponPart {
        WeaponPart(id: id, name: name, slot: slot, shape: shape, materialName: "Único", tier: tier, stats: stats,
                   elements: elements, palette: palette, price: 0, isSpecial: true, abilityID: ability)
    }

    public static let all: [WeaponPart] = normalParts + specialParts

    private static let byID: [String: WeaponPart] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func part(_ id: String) -> WeaponPart? { byID[id] }

    /// Tier máximo de material a la venta según el nivel: 2,2,3,3,4,4,5,5,6,6.
    public static func maxShopTier(forLevel level: Int) -> Int {
        min(6, 1 + (level + 1) / 2)
    }

    public static func shopParts(level: Int) -> [WeaponPart] {
        let tier = maxShopTier(forLevel: level)
        return normalParts.filter { $0.tier <= tier }
    }
}
