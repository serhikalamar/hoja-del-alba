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

    /// Posición en `allCases` (índice de las tablas ajustadas de `TunedData`).
    var ordinal: Int {
        switch self {
        case .copper: 0
        case .iron: 1
        case .silver: 2
        case .gold: 3
        case .emerald: 4
        case .sapphire: 5
        case .ruby: 6
        case .amethyst: 7
        case .diamond: 8
        case .mithril: 9
        }
    }

    /// Porcentaje de aparición cuando un monstruo suelta un mineral (con los ajustes del panel: `dropWeight`).
    public var dropPercent: Double { TunedData.current.mineralDropPercents[ordinal] }

    /// Bonificación que aporta cada unidad al forjar (con los ajustes del panel: `stats`).
    public var buffPerUnit: Stats { TunedData.current.mineralBuffs[ordinal] }

    /// Valor en oro de cada unidad (con los ajustes del panel: `value`).
    public var value: Int { TunedData.current.mineralValues[ordinal] }

    /// Porcentaje de aparición del código. Suman 100.
    var baseDropPercent: Double {
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

    /// 1 (común) ... 10 (legendario). Dato explícito por mineral (no depende del orden de la lista: al añadir
    /// minerales de otros continentes, estos no cambian).
    public var rarityTier: Int {
        switch self {
        case .copper: 1
        case .iron: 2
        case .silver: 3
        case .gold: 4
        case .emerald: 5
        case .sapphire: 6
        case .ruby: 7
        case .amethyst: 8
        case .diamond: 9
        case .mithril: 10
        }
    }

    /// Bonificación por unidad del código.
    var baseBuffPerUnit: Stats {
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

    /// Valor en oro de cada unidad del código (afecta al precio de venta de lo forjado).
    var baseValue: Int {
        switch self {
        case .copper: 2
        case .iron: 3
        case .silver: 5
        case .gold: 8
        case .emerald: 12
        case .sapphire: 16
        case .ruby: 24
        case .amethyst: 32
        case .diamond: 50
        case .mithril: 80
        }
    }

    /// Los minerales son escasos: multiplica la probabilidad de soltar de cada enemigo (0,15; `economy.mineralDropRate`).
    public static var dropRateMultiplier: Double { TunedData.current.economy.mineralDropRate }

    /// Tira el dado de minerales según `dropPercent`.
    public static func roll<G: RandomNumberGenerator>(using rng: inout G) -> Mineral {
        WeightedPicker.pick(TunedData.current.mineralLoot, using: &rng)
    }
}
