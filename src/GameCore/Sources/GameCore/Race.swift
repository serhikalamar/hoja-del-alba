import Foundation

/// Raza del héroe. De momento solo cambia las estadísticas base.
public enum Race: String, CaseIterable, Codable, Identifiable, Sendable {
    case human, dwarf, elf, werewolf

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .human: "Humano"
        case .dwarf: "Enano"
        case .elf: "Elfo"
        case .werewolf: "Hombre lobo"
        }
    }

    public var summary: String {
        switch self {
        case .human: "Equilibrado. Gana un 10% más de oro."
        case .dwarf: "Mucha vida y defensa, pero lento."
        case .elf: "Rápido, ataca deprisa y desde lejos. Frágil."
        case .werewolf: "Golpea fuerte, roba vida y se regenera. Sin defensa."
        }
    }

    public var baseStats: Stats {
        switch self {
        case .human:
            Stats(maxHP: 120, attack: 9, defense: 2, attackSpeed: 1.3, range: 38, moveSpeed: 125,
                  critChance: 0.05, critMultiplier: 1.5, goldBonus: 0.10)
        case .dwarf:
            Stats(maxHP: 155, attack: 9, defense: 8, attackSpeed: 1.15, range: 34, moveSpeed: 105,
                  critChance: 0.05, critMultiplier: 1.6)
        case .elf:
            Stats(maxHP: 100, attack: 8, defense: 0, attackSpeed: 1.55, range: 50, moveSpeed: 145,
                  critChance: 0.10, critMultiplier: 1.5)
        case .werewolf:
            Stats(maxHP: 130, attack: 12, defense: 0, attackSpeed: 1.4, range: 34, moveSpeed: 135,
                  critChance: 0.08, critMultiplier: 1.7, lifesteal: 0.04, regen: 0.5)
        }
    }
}
