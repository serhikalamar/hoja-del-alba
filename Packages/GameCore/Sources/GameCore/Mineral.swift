import Foundation

/// Los 10 minerales que sueltan los monstruos. Cuanto más raro, mejor bonificación.
public enum Mineral: String, CaseIterable, Codable, Identifiable, Sendable {
    case copper, iron, silver, gold, emerald, sapphire, ruby, amethyst, diamond, mithril

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .copper: "Cobre"
        case .iron: "Hierro"
        case .silver: "Plata"
        case .gold: "Oro"
        case .emerald: "Esmeralda"
        case .sapphire: "Zafiro"
        case .ruby: "Rubí"
        case .amethyst: "Amatista"
        case .diamond: "Diamante"
        case .mithril: "Mithril"
        }
    }

    /// Porcentaje de aparición cuando un monstruo suelta un mineral. Suman 100.
    public var dropPercent: Double {
        switch self {
        case .copper: 30
        case .iron: 22
        case .silver: 15
        case .gold: 10
        case .emerald: 8
        case .sapphire: 6
        case .ruby: 4
        case .amethyst: 3
        case .diamond: 1.5
        case .mithril: 0.5
        }
    }

    /// 1 (común) ... 10 (legendario).
    public var rarityTier: Int {
        Mineral.allCases.firstIndex(of: self)! + 1
    }

    /// Bonificación que aporta cada unidad al forjar.
    public var buffPerUnit: Stats {
        switch self {
        case .copper: Stats(attack: 2)
        case .iron: Stats(defense: 2)
        case .silver: Stats(attackSpeed: 0.05)
        case .gold: Stats(goldBonus: 0.04)
        case .emerald: Stats(regen: 0.4)
        case .sapphire: Stats(range: 3)
        case .ruby: Stats(critChance: 0.03)
        case .amethyst: Stats(lifesteal: 0.02)
        case .diamond: Stats(critMultiplier: 0.12)
        case .mithril: Stats(maxHP: 12, attack: 2, defense: 2)
        }
    }

    /// Valor en oro de cada unidad (afecta al precio de venta de lo forjado).
    public var value: Int {
        [2, 3, 5, 8, 12, 16, 24, 32, 50, 80][rarityTier - 1]
    }

    /// Tira el dado de minerales según `dropPercent`.
    public static func roll<G: RandomNumberGenerator>(using rng: inout G) -> Mineral {
        WeightedPicker.pick(allCases.map { ($0, $0.dropPercent) }, using: &rng)
    }
}
