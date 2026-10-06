import Foundation

/// Estadísticas del caballero. Los objetos y minerales aportan `Stats` que se suman.
public struct Stats: Codable, Equatable, Hashable, Sendable {
    public var maxHP: Double
    public var attack: Double
    public var defense: Double
    /// Ataques por segundo.
    public var attackSpeed: Double
    /// Alcance del ataque en puntos de pantalla.
    public var range: Double
    /// Puntos por segundo.
    public var moveSpeed: Double
    /// 0...1
    public var critChance: Double
    /// Multiplicador de daño crítico (1.5 = +50%).
    public var critMultiplier: Double
    /// Fracción del daño infligido que cura (0...1).
    public var lifesteal: Double
    /// Oro extra (0.10 = +10%).
    public var goldBonus: Double
    /// Vida regenerada por segundo.
    public var regen: Double

    public init(
        maxHP: Double = 0,
        attack: Double = 0,
        defense: Double = 0,
        attackSpeed: Double = 0,
        range: Double = 0,
        moveSpeed: Double = 0,
        critChance: Double = 0,
        critMultiplier: Double = 0,
        lifesteal: Double = 0,
        goldBonus: Double = 0,
        regen: Double = 0
    ) {
        self.maxHP = maxHP
        self.attack = attack
        self.defense = defense
        self.attackSpeed = attackSpeed
        self.range = range
        self.moveSpeed = moveSpeed
        self.critChance = critChance
        self.critMultiplier = critMultiplier
        self.lifesteal = lifesteal
        self.goldBonus = goldBonus
        self.regen = regen
    }

    public static let zero = Stats()

    public static let knightBase = Stats(
        maxHP: 120,
        attack: 9,
        defense: 0,
        attackSpeed: 1.3,
        range: 38,
        moveSpeed: 125,
        critChance: 0.05,
        critMultiplier: 1.5
    )

    public subscript(kind: StatKind) -> Double {
        get { self[keyPath: kind.keyPath] }
        set { self[keyPath: kind.keyPath] = newValue }
    }

    public static func + (lhs: Stats, rhs: Stats) -> Stats {
        var out = lhs
        for kind in StatKind.allCases { out[kind] += rhs[kind] }
        return out
    }

    public static func - (lhs: Stats, rhs: Stats) -> Stats {
        lhs + rhs * -1
    }

    public static func * (lhs: Stats, multiplier: Double) -> Stats {
        var out = lhs
        for kind in StatKind.allCases { out[kind] *= multiplier }
        return out
    }

    public static func += (lhs: inout Stats, rhs: Stats) {
        lhs = lhs + rhs
    }

    /// Límites para que ninguna combinación rompa el juego.
    public func clampedForPlay() -> Stats {
        var s = self
        s.maxHP = max(1, s.maxHP)
        s.attack = max(1, s.attack)
        s.defense = max(0, s.defense)
        s.attackSpeed = min(5, max(0.4, s.attackSpeed))
        s.range = min(140, max(20, s.range))
        s.moveSpeed = min(260, max(60, s.moveSpeed))
        s.critChance = min(0.75, max(0, s.critChance))
        s.critMultiplier = max(1, s.critMultiplier)
        s.lifesteal = min(0.4, max(0, s.lifesteal))
        s.goldBonus = max(0, s.goldBonus)
        s.regen = max(0, s.regen)
        return s
    }

    /// Las estadísticas distintas de cero, en orden de presentación.
    public var entries: [(kind: StatKind, value: Double)] {
        StatKind.allCases.compactMap { kind in
            let value = self[kind]
            return abs(value) > 0.0001 ? (kind, value) : nil
        }
    }
}

public enum StatKind: String, CaseIterable, Codable, Sendable {
    case maxHP, attack, defense, attackSpeed, range, moveSpeed
    case critChance, critMultiplier, lifesteal, goldBonus, regen

    public var keyPath: WritableKeyPath<Stats, Double> {
        switch self {
        case .maxHP: \.maxHP
        case .attack: \.attack
        case .defense: \.defense
        case .attackSpeed: \.attackSpeed
        case .range: \.range
        case .moveSpeed: \.moveSpeed
        case .critChance: \.critChance
        case .critMultiplier: \.critMultiplier
        case .lifesteal: \.lifesteal
        case .goldBonus: \.goldBonus
        case .regen: \.regen
        }
    }

    public var shortName: String {
        switch self {
        case .maxHP: "VIDA"
        case .attack: "ATQ"
        case .defense: "DEF"
        case .attackSpeed: "VEL.ATQ"
        case .range: "ALCANCE"
        case .moveSpeed: "VELOC."
        case .critChance: "CRÍTICO"
        case .critMultiplier: "DAÑO CRÍT."
        case .lifesteal: "ROBO VIDA"
        case .goldBonus: "ORO"
        case .regen: "REGEN."
        }
    }

    /// Formato con signo, para bonificaciones de objetos ("+3 ATQ").
    public func formatBonus(_ value: Double) -> String {
        let sign = value < 0 ? "-" : "+"
        if self == .critMultiplier {
            return sign + "\(Int((abs(value) * 100).rounded()))%"
        }
        return sign + formatValue(abs(value))
    }

    /// Formato sin signo, para totales del personaje.
    public func formatValue(_ value: Double) -> String {
        switch self {
        case .critChance, .lifesteal, .goldBonus:
            return "\(Int((value * 100).rounded()))%"
        case .attackSpeed:
            return String(format: "%.2f", value)
        case .critMultiplier:
            return String(format: "x%.2f", value)
        case .regen:
            return String(format: "%.1f/s", value)
        default:
            return "\(Int(value.rounded()))"
        }
    }
}
