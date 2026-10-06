import Foundation

/// Habilidad secreta de un arma. Se decide por los elementos de sus tres piezas
/// (o por una pieza de jefe) y el jugador no la conoce hasta forjarla.
/// Cada campo es un efecto que la escena de combate sabe aplicar; 0 = sin efecto.
public struct Ability: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let elements: [Element]

    /// Quemadura: fracción del golpe repartida en 3 s.
    public var burn: Double = 0
    /// Veneno: igual que la quemadura, pero se acumula.
    public var poison: Double = 0
    /// Ralentiza al enemigo golpeado (0...1) durante 2 s.
    public var slow: Double = 0
    /// Rayo que salta a N enemigos cercanos con esta fracción del golpe.
    public var chain: Int = 0
    public var chainDamage: Double = 0
    /// Remata a los enemigos por debajo de esta fracción de vida.
    public var execute: Double = 0
    /// Cura esta fracción de la vida máxima al matar.
    public var healOnKill: Double = 0
    /// Cada N ataques, onda alrededor del héroe (radio en puntos, daño × ATQ).
    public var pulseEvery: Int = 0
    public var pulseRadius: Double = 0
    public var pulseDamage: Double = 0
    /// Cada N ataques, un rayo cae sobre el enemigo con más vida (daño × ATQ).
    public var strikeEvery: Int = 0
    public var strikeDamage: Double = 0
    /// Los críticos explotan en área (daño × ATQ).
    public var critExplosion: Double = 0
    /// Bonificación pasiva mientras el arma está equipada.
    public var bonus: Stats = .zero

    init(_ id: String, _ name: String, _ description: String, _ elements: [Element], configure: (inout Ability) -> Void = { _ in }) {
        self.id = id
        self.name = name
        self.description = description
        self.elements = elements
        configure(&self)
    }
}

public enum AbilityBook {
    /// Una por elemento: se activa con 2 o más piezas del mismo elemento.
    public static let single: [Element: Ability] = [
        .fire: Ability("blaze", "Llamarada", "Los golpes queman al enemigo.", [.fire]) { $0.burn = 0.6 },
        .ice: Ability("frostbite", "Escarcha", "Los golpes ralentizan un 40%.", [.ice]) { $0.slow = 0.4 },
        .storm: Ability("chain_lightning", "Rayo en cadena", "El golpe salta a 2 enemigos cercanos.", [.storm]) {
            $0.chain = 2; $0.chainDamage = 0.5
        },
        .poison: Ability("venom", "Veneno", "Envenena; el veneno se acumula.", [.poison]) { $0.poison = 0.5 },
        .holy: Ability("holy_light", "Luz sagrada", "Cada enemigo abatido te cura un 3%.", [.holy]) { $0.healOnKill = 0.03 },
        .shadow: Ability("execution", "Ejecución", "Remata a enemigos con menos del 15% de vida.", [.shadow]) { $0.execute = 0.15 },
        .blood: Ability("bloodthirst", "Sed de sangre", "+6% de robo de vida.", [.blood]) { $0.bonus = Stats(lifesteal: 0.06) },
        .wind: Ability("whirlwind", "Torbellino", "Cada 4 ataques, un giro golpea alrededor.", [.wind]) {
            $0.pulseEvery = 4; $0.pulseRadius = 70; $0.pulseDamage = 0.7
        },
        .earth: Ability("earthquake", "Terremoto", "Cada 6 ataques, la tierra tiembla.", [.earth]) {
            $0.pulseEvery = 6; $0.pulseRadius = 105; $0.pulseDamage = 1.1
        },
        .arcane: Ability("arcane_crit", "Crítico arcano", "+10% crítico; los críticos estallan.", [.arcane]) {
            $0.bonus = Stats(critChance: 0.10); $0.critExplosion = 0.6
        },
    ]

    /// Combinaciones de dos elementos distintos (tienen prioridad).
    public static let combos: [Ability] = [
        Ability("steam", "Vapor", "Cada 4 ataques, una nube hirviente quema y ralentiza.", [.fire, .ice]) {
            $0.pulseEvery = 4; $0.pulseRadius = 75; $0.pulseDamage = 0.8; $0.slow = 0.3
        },
        Ability("plasma", "Plasma", "Rayos que saltan a 3 enemigos y los queman.", [.fire, .storm]) {
            $0.chain = 3; $0.chainDamage = 0.5; $0.burn = 0.3
        },
        Ability("magma", "Magma", "Cada 5 ataques, erupción que quema.", [.fire, .earth]) {
            $0.pulseEvery = 5; $0.pulseRadius = 95; $0.pulseDamage = 1.2; $0.burn = 0.4
        },
        Ability("fury", "Furia", "+25% velocidad de ataque y +4 ATQ.", [.fire, .blood]) {
            $0.bonus = Stats(attack: 4, attackSpeed: 0.25)
        },
        Ability("frozen_storm", "Tormenta helada", "Rayos que ralentizan.", [.ice, .storm]) {
            $0.chain = 2; $0.chainDamage = 0.6; $0.slow = 0.35
        },
        Ability("deadly_frost", "Escarcha mortal", "Ralentiza y remata por debajo del 20%.", [.ice, .shadow]) {
            $0.slow = 0.3; $0.execute = 0.2
        },
        Ability("judgement", "Juicio", "Cada 5 ataques, un rayo divino (×3).", [.storm, .holy]) {
            $0.strikeEvery = 5; $0.strikeDamage = 3
        },
        Ability("vampirism", "Vampirismo", "Matar cura un 4% y +4% robo de vida.", [.shadow, .blood]) {
            $0.healOnKill = 0.04; $0.bonus = Stats(lifesteal: 0.04)
        },
        Ability("plague", "Plaga", "Veneno potente que remata por debajo del 12%.", [.poison, .shadow]) {
            $0.poison = 0.6; $0.execute = 0.12
        },
        Ability("toxic_cloud", "Nube tóxica", "Cada 4 ataques, nube venenosa alrededor.", [.poison, .wind]) {
            $0.pulseEvery = 4; $0.pulseRadius = 80; $0.pulseDamage = 0.4; $0.poison = 0.4
        },
        Ability("bastion", "Bastión", "+12 DEF y +40 vida.", [.holy, .earth]) {
            $0.bonus = Stats(maxHP: 40, defense: 12)
        },
        Ability("hurricane", "Huracán", "Cada 3 ataques, un torbellino.", [.wind, .storm]) {
            $0.pulseEvery = 3; $0.pulseRadius = 80; $0.pulseDamage = 0.7
        },
        Ability("meteor", "Meteoro", "Los críticos provocan explosiones enormes.", [.arcane, .fire]) {
            $0.critExplosion = 1.5; $0.bonus = Stats(critChance: 0.05)
        },
        Ability("prism", "Prisma", "+12% crítico y los golpes ralentizan.", [.arcane, .ice]) {
            $0.bonus = Stats(critChance: 0.12); $0.slow = 0.25
        },
        Ability("void", "Vacío", "Cada 6 ataques, rayo del vacío (×4); remata al 10%.", [.arcane, .shadow]) {
            $0.strikeEvery = 6; $0.strikeDamage = 4; $0.execute = 0.1
        },
        Ability("titan", "Titán", "+60 vida y +6 ATQ.", [.blood, .earth]) {
            $0.bonus = Stats(maxHP: 60, attack: 6)
        },
        Ability("blessing", "Bendición", "+2 vida/s y +20 velocidad.", [.holy, .wind]) {
            $0.bonus = Stats(moveSpeed: 20, regen: 2)
        },
        Ability("hemorrhage", "Hemorragia", "Veneno y cura al matar.", [.poison, .blood]) {
            $0.poison = 0.5; $0.healOnKill = 0.02
        },
    ]

    /// Habilidades únicas de las piezas de jefe.
    public static let boss: [Ability] = [
        Ability("rat_bite", "Mordisco pestilente", "Veneno muy potente; matar cura un 2%.", [.poison, .blood]) {
            $0.poison = 0.8; $0.healOnKill = 0.02
        },
        Ability("low_blow", "Golpe bajo", "Remata al 20% y +8% crítico.", [.shadow, .blood]) {
            $0.execute = 0.2; $0.bonus = Stats(critChance: 0.08)
        },
        Ability("burning_harvest", "Cosecha ardiente", "Quema y, cada 5 ataques, siega alrededor.", [.shadow, .fire]) {
            $0.burn = 0.6; $0.pulseEvery = 5; $0.pulseRadius = 85; $0.pulseDamage = 0.8
        },
        Ability("hellforge", "Forja infernal", "Cada 4 ataques, explosión de fuego (×1.3).", [.fire, .earth]) {
            $0.pulseEvery = 4; $0.pulseRadius = 95; $0.pulseDamage = 1.3; $0.burn = 0.4
        },
        Ability("frenzy", "Frenesí", "+30% velocidad de ataque y +5% robo de vida.", [.blood, .wind]) {
            $0.bonus = Stats(attackSpeed: 0.3, lifesteal: 0.05)
        },
        Ability("hex", "Maleficio", "Envenena, ralentiza y los críticos estallan.", [.poison, .arcane]) {
            $0.poison = 0.6; $0.slow = 0.3; $0.critExplosion = 1
        },
        Ability("crush", "Aplastamiento", "Cada 3 ataques, onda de choque.", [.earth]) {
            $0.pulseEvery = 3; $0.pulseRadius = 100; $0.pulseDamage = 1
        },
        Ability("dark_communion", "Comunión oscura", "Cada 4 ataques, rayo (×3); matar cura un 3%.", [.holy, .shadow]) {
            $0.strikeEvery = 4; $0.strikeDamage = 3; $0.healOnKill = 0.03
        },
        Ability("carnage", "Carnicería", "Rayos a 4 enemigos y +10 ATQ.", [.blood, .storm]) {
            $0.chain = 4; $0.chainDamage = 0.6; $0.bonus = Stats(attack: 10)
        },
        Ability("royal_decree", "Decreto real", "Cada 3 ataques, rayo real (×4) y rayos en cadena.", [.arcane, .holy, .storm]) {
            $0.strikeEvery = 3; $0.strikeDamage = 4; $0.chain = 3; $0.chainDamage = 0.5
        },
    ]

    public static let all: [Ability] = Element.allCases.compactMap { single[$0] } + combos + boss

    private static let byID: [String: Ability] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func ability(_ id: String?) -> Ability? {
        id.flatMap { byID[$0] }
    }

    /// Decide la habilidad de un arma a partir de sus piezas.
    /// 1. Pieza de jefe (la de tier más alto).
    /// 2. Combinación de dos elementos presentes que sumen 3+ (la que más sume).
    /// 3. Un elemento repetido 2+ veces.
    public static func resolve(parts: [WeaponPart]) -> Ability? {
        if let bossPart = parts.filter(\.isSpecial).max(by: { $0.tier < $1.tier }) {
            return ability(bossPart.abilityID)
        }
        var counts: [Element: Int] = [:]
        for part in parts {
            for element in part.elements { counts[element, default: 0] += 1 }
        }
        let combo = combos
            .filter { $0.elements.allSatisfy { counts[$0, default: 0] > 0 } }
            // Hace falta "enfocar" la combinación: al menos 3 piezas-elemento entre los dos.
            .filter { $0.elements.reduce(0) { $0 + counts[$1, default: 0] } >= 3 }
            .max { a, b in
                let sa = a.elements.reduce(0) { $0 + counts[$1, default: 0] }
                let sb = b.elements.reduce(0) { $0 + counts[$1, default: 0] }
                return sa != sb ? sa < sb : a.id > b.id
            }
        if let combo { return combo }
        let repeated = counts
            .filter { $0.value >= 2 }
            .max { a, b in a.value != b.value ? a.value < b.value : a.key.rawValue > b.key.rawValue }
        return repeated.flatMap { single[$0.key] }
    }
}
