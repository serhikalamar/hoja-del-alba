import Foundation

public enum EnemyBehavior: String, Codable, Sendable {
    /// Persigue y golpea cuerpo a cuerpo.
    case melee
    /// Se queda a distancia y dispara proyectiles.
    case ranged
    /// Se acerca y embiste a gran velocidad.
    case charger
}

/// Definición de un tipo de enemigo.
public struct EnemyDefinition: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Nivel en el que aparece por primera vez (1...10).
    public let level: Int
    /// Plantilla de dibujo (la app la interpreta).
    public let template: String
    public let behavior: EnemyBehavior
    public let hp: Double
    public let damage: Double
    public let speed: Double
    public let attackCooldown: Double
    /// Alcance del ataque: cuerpo a cuerpo (pocos puntos) o distancia de disparo.
    public let attackRange: Double
    public let bodyRadius: Double
    /// Escala del dibujo.
    public let scale: Double
    public let dropChance: Double
    public let dropRolls: Int
    public let isBoss: Bool
    /// Pieza única que suelta el jefe.
    public let specialPartID: String?

    /// Estadísticas al jugar en `level`: escalan con los niveles que han pasado desde que apareció
    /// y con un factor de dificultad global que crece con el nivel.
    public func stats(level playLevel: Int) -> MonsterStats {
        let l = Double(max(0, playLevel - level))
        let difficulty = Double(max(0, playLevel - 1))
        return MonsterStats(
            hp: hp * (1 + 0.13 * l) * (1 + 0.11 * difficulty),
            damage: damage * (1 + 0.10 * l) * (1 + 0.09 * difficulty),
            speed: speed * (1 + 0.02 * l),
            attackCooldown: attackCooldown,
            attackRange: attackRange,
            dropChance: dropChance,
            dropRolls: dropRolls
        )
    }
}

public struct MonsterStats: Equatable, Sendable {
    public var hp: Double
    public var damage: Double
    public var speed: Double
    public var attackCooldown: Double
    public var attackRange: Double
    /// Probabilidad de soltar un mineral en cada tirada.
    public var dropChance: Double
    public var dropRolls: Int

    /// Minerales soltados al morir.
    public func rollDrops<G: RandomNumberGenerator>(using rng: inout G) -> [Mineral] {
        // Los jefes siempre sueltan algo, pero la mitad que antes; el resto, mucho menos (minerales escasos).
        let rolls = dropChance >= 1 ? max(1, dropRolls / 2) : dropRolls
        let chance = dropChance >= 1 ? 1 : dropChance * Mineral.dropRateMultiplier
        return (0..<rolls).compactMap { _ in
            Double.random(in: 0..<1, using: &rng) < chance ? Mineral.roll(using: &rng) : nil
        }
    }
}

public enum Bestiary {
    // swiftlint:disable function_parameter_count
    private static func e(
        _ id: String, _ name: String, _ level: Int, _ template: String, _ behavior: EnemyBehavior = .melee,
        hp: Double, dmg: Double, speed: Double, cd: Double, range: Double = 6,
        radius: Double = 14, scale: Double = 1, drop: Double = 0.5, rolls: Int = 1
    ) -> EnemyDefinition {
        EnemyDefinition(id: id, name: name, level: level, template: template, behavior: behavior,
                        hp: hp, damage: dmg, speed: speed, attackCooldown: cd, attackRange: range,
                        bodyRadius: radius, scale: scale, dropChance: drop, dropRolls: rolls,
                        isBoss: false, specialPartID: nil)
    }

    private static func boss(
        _ id: String, _ name: String, _ level: Int, _ template: String, _ behavior: EnemyBehavior = .melee,
        hp: Double, dmg: Double, speed: Double, cd: Double, range: Double = 12,
        radius: Double, scale: Double
    ) -> EnemyDefinition {
        EnemyDefinition(id: id, name: name, level: level, template: template, behavior: behavior,
                        hp: hp, damage: dmg, speed: speed, attackCooldown: cd, attackRange: range,
                        bodyRadius: radius, scale: scale, dropChance: 1, dropRolls: 4 + level / 2,
                        isBoss: true, specialPartID: "boss.\(id)")
    }

    public static let all: [EnemyDefinition] = [
        // Nivel 1 · Puerta del pueblo
        e("rat", "Rata de alcantarilla", 1, "rat", hp: 12, dmg: 3, speed: 85, cd: 0.9, radius: 11, drop: 0.4),
        e("goblin", "Goblin", 1, "goblin", hp: 22, dmg: 5, speed: 55, cd: 1.2),
        e("goblinSlinger", "Goblin hondero", 1, "goblin", .ranged, hp: 16, dmg: 5, speed: 50, cd: 2.2, range: 150, radius: 13),
        e("mangyDog", "Perro sarnoso", 1, "dog", hp: 16, dmg: 4, speed: 105, cd: 0.9, radius: 13, drop: 0.4),
        boss("ratKing", "Rey de las ratas", 1, "rat", hp: 170, dmg: 7, speed: 55, cd: 1.3, radius: 26, scale: 2.2),
        // Nivel 2 · Calle del mercado
        e("goblinThief", "Goblin ladrón", 2, "goblin", hp: 16, dmg: 4, speed: 110, cd: 0.8, radius: 13),
        e("crow", "Cuervo carroñero", 2, "bird", hp: 10, dmg: 3, speed: 120, cd: 0.9, radius: 11, drop: 0.35),
        e("bandit", "Bandido", 2, "human", hp: 34, dmg: 7, speed: 60, cd: 1.2, radius: 15, drop: 0.6),
        e("goblinSpearman", "Goblin lancero", 2, "goblin", hp: 26, dmg: 7, speed: 50, cd: 1.4, range: 18),
        boss("banditChief", "Capitán bandido", 2, "human", hp: 380, dmg: 14, speed: 65, cd: 1.2, radius: 22, scale: 1.6),
        // Nivel 3 · Huertos del molino
        e("skeleton", "Esqueleto", 3, "skeleton", hp: 30, dmg: 7, speed: 55, cd: 1.2, drop: 0.55),
        e("zombieFarmer", "Granjero zombi", 3, "human", hp: 55, dmg: 9, speed: 35, cd: 1.6, radius: 15, drop: 0.6),
        e("boar", "Jabalí", 3, "boar", .charger, hp: 40, dmg: 10, speed: 70, cd: 2.5, radius: 16, drop: 0.6),
        e("goblinShaman", "Chamán goblin", 3, "goblin", .ranged, hp: 22, dmg: 8, speed: 45, cd: 2.4, range: 170, drop: 0.6),
        boss("scarecrow", "Espantapájaros maldito", 3, "human", hp: 520, dmg: 16, speed: 55, cd: 1.3, radius: 26, scale: 2),
        // Nivel 4 · Plaza de la herrería
        e("goblinBrute", "Goblin bruto", 4, "goblin", hp: 75, dmg: 12, speed: 38, cd: 1.6, range: 10, radius: 22, scale: 1.5, drop: 0.9, rolls: 2),
        e("cultist", "Cultista", 4, "human", .ranged, hp: 30, dmg: 9, speed: 50, cd: 2.2, range: 170, radius: 15, drop: 0.6),
        e("slime", "Limo verde", 4, "slime", hp: 45, dmg: 7, speed: 40, cd: 1.2, radius: 15, drop: 0.6),
        e("bat", "Murciélago", 4, "bat", hp: 14, dmg: 5, speed: 130, cd: 0.8, radius: 11, drop: 0.35),
        boss("possessedSmith", "Herrero poseído", 4, "brute", hp: 700, dmg: 20, speed: 50, cd: 1.4, radius: 26, scale: 1.6),
        // Nivel 5 · Cementerio de la capilla
        e("wolf", "Lobo gris", 5, "dog", .charger, hp: 45, dmg: 10, speed: 90, cd: 2.2, radius: 15, scale: 1.2, drop: 0.6),
        e("hobgoblin", "Hobgoblin", 5, "goblin", hp: 60, dmg: 11, speed: 55, cd: 1.3, radius: 17, scale: 1.3, drop: 0.7),
        e("skeletonArcher", "Esqueleto arquero", 5, "skeleton", .ranged, hp: 30, dmg: 10, speed: 45, cd: 2.2, range: 190, drop: 0.6),
        e("mudGolem", "Gólem de barro", 5, "brute", hp: 110, dmg: 13, speed: 32, cd: 1.8, range: 10, radius: 22, scale: 1.25, drop: 0.9, rolls: 2),
        boss("alphaWolf", "Lobo alfa", 5, "dog", .charger, hp: 850, dmg: 22, speed: 95, cd: 1.8, radius: 26, scale: 2),
        // Nivel 6 · Pozo de la bruja
        e("goblinBomber", "Goblin bombardero", 6, "goblin", .ranged, hp: 28, dmg: 14, speed: 45, cd: 2.8, range: 160, drop: 0.6),
        e("ghoul", "Necrófago", 6, "skeleton", hp: 40, dmg: 10, speed: 100, cd: 1.0, drop: 0.55),
        e("fireSlime", "Limo de fuego", 6, "slime", hp: 55, dmg: 10, speed: 45, cd: 1.2, radius: 15, drop: 0.6),
        e("mercenary", "Mercenario", 6, "human", hp: 70, dmg: 12, speed: 60, cd: 1.2, radius: 15, drop: 0.7),
        boss("witch", "Bruja del pozo", 6, "human", .ranged, hp: 900, dmg: 20, speed: 55, cd: 1.6, range: 200, radius: 22, scale: 1.6),
        // Nivel 7 · Molino en ruinas
        e("orc", "Orco", 7, "brute", hp: 85, dmg: 14, speed: 55, cd: 1.4, range: 10, radius: 18, scale: 1.05, drop: 0.8),
        e("plagueRat", "Rata de la peste", 7, "rat", hp: 30, dmg: 8, speed: 95, cd: 0.8, radius: 12, drop: 0.45),
        e("wraith", "Espectro", 7, "ghost", hp: 50, dmg: 12, speed: 80, cd: 1.2, radius: 14, drop: 0.6),
        e("wolfRider", "Jinete de lobo", 7, "dog", .charger, hp: 70, dmg: 14, speed: 95, cd: 2.2, radius: 18, scale: 1.4, drop: 0.8),
        boss("ogre", "Ogro del molino", 7, "brute", hp: 1300, dmg: 28, speed: 45, cd: 1.8, range: 16, radius: 34, scale: 2.1),
        // Nivel 8 · Abadía abandonada
        e("troll", "Troll", 8, "brute", hp: 120, dmg: 18, speed: 45, cd: 1.6, range: 12, radius: 22, scale: 1.35, drop: 0.9, rolls: 2),
        e("blackKnight", "Caballero negro", 8, "human", hp: 100, dmg: 15, speed: 55, cd: 1.3, radius: 16, scale: 1.15, drop: 0.8),
        e("gargoyle", "Gárgola", 8, "bat", hp: 70, dmg: 14, speed: 85, cd: 1.2, radius: 15, scale: 1.4, drop: 0.7),
        e("necromancer", "Nigromante", 8, "human", .ranged, hp: 55, dmg: 14, speed: 45, cd: 2.4, range: 200, radius: 15, drop: 0.7),
        boss("abbot", "Abad no-muerto", 8, "skeleton", .ranged, hp: 1150, dmg: 24, speed: 55, cd: 1.4, range: 200, radius: 24, scale: 1.8),
        // Nivel 9 · Murallas del castillo
        e("goblinElite", "Goblin de élite", 9, "goblin", hp: 70, dmg: 14, speed: 65, cd: 1.1, radius: 15, scale: 1.1, drop: 0.7),
        e("berserker", "Orco berserker", 9, "brute", .charger, hp: 120, dmg: 20, speed: 70, cd: 2.0, radius: 18, scale: 1.15, drop: 0.9),
        e("iceSlime", "Limo helado", 9, "slime", hp: 70, dmg: 12, speed: 45, cd: 1.2, radius: 16, scale: 1.15, drop: 0.7),
        e("assassin", "Asesino sombrío", 9, "human", hp: 60, dmg: 18, speed: 120, cd: 1.0, radius: 15, drop: 0.7),
        boss("warlord", "Señor de la guerra orco", 9, "brute", hp: 2000, dmg: 32, speed: 55, cd: 1.4, range: 16, radius: 30, scale: 1.9),
        // Nivel 10 · Salón del trono goblin
        e("goblinGuard", "Guardia real goblin", 10, "goblin", hp: 100, dmg: 16, speed: 50, cd: 1.3, radius: 16, scale: 1.2, drop: 0.8),
        e("goblinMage", "Mago goblin", 10, "goblin", .ranged, hp: 50, dmg: 16, speed: 45, cd: 2.2, range: 210, drop: 0.8),
        e("armoredBoar", "Jabalí acorazado", 10, "boar", .charger, hp: 120, dmg: 20, speed: 75, cd: 2.4, radius: 18, scale: 1.3, drop: 0.9),
        e("goblinStandard", "Abanderado goblin", 10, "goblin", hp: 160, dmg: 14, speed: 40, cd: 1.6, radius: 18, scale: 1.4, drop: 1, rolls: 2),
        boss("goblinKing", "Rey Goblin", 10, "goblin", hp: 2600, dmg: 34, speed: 50, cd: 1.4, range: 14, radius: 34, scale: 2.4),
        // Monstruos de continente (fuera de la arena: ver `Arena.originalEnemyIDs`)
        // Valdemar · Orden del Eclipse: dispara una esfera de sombra lenta, algo más dañina que la del cultista.
        e("eclipseAcolyte", "Acólito del Eclipse", 7, "human", .ranged, hp: 45, dmg: 13, speed: 50, cd: 2.4, range: 180, radius: 15, scale: 1.05, drop: 0.7),
    ]

    private static let byID: [String: EnemyDefinition] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func enemy(_ id: String) -> EnemyDefinition? { byID[id] }

    public static var bosses: [EnemyDefinition] { all.filter(\.isBoss) }

    public static func introduced(at level: Int) -> [EnemyDefinition] {
        all.filter { $0.level == level }
    }
}

// MARK: - Jefes de la historia (balance, B1)

extension EnemyDefinition {
    /// Vida y daño de los jefes en el modo historia (pueblo, campo y mazmorras de historia); la arena usa los números
    /// base. Objetivos de `progresion.md` §7 medidos con `make historia`: jefe de zona 40-60 s, jefe final 60-120 s, y
    /// que el bot con equipo de tier 1 bien hecho los pase (con algún susto).
    public static let storyBossTuning: [String: (hp: Double, damage: Double)] = [
        "ogre": (1.8, 0.8),
        "alphaWolf": (1.5, 0.45),
        "abbot": (2.0, 0.6),
        "warlord": (1.0, 0.8),
        "goblinKing": (0.95, 0.5),
    ]

    /// La definición que se usa en la historia (igual que la base salvo los jefes de `storyBossTuning`).
    public var forStory: EnemyDefinition {
        guard let t = Self.storyBossTuning[id] else { return self }
        return EnemyDefinition(id: id, name: name, level: level, template: template, behavior: behavior,
                               hp: hp * t.hp, damage: damage * t.damage, speed: speed, attackCooldown: attackCooldown,
                               attackRange: attackRange, bodyRadius: bodyRadius, scale: scale, dropChance: dropChance,
                               dropRolls: dropRolls, isBoss: isBoss, specialPartID: specialPartID)
    }
}
