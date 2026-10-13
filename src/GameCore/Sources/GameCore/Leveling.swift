import Foundation

/// Niveles del personaje (1…60, como un MMO): experiencia por matar, estadísticas por nivel
/// y diferencia de nivel en combate. Los 6 continentes del mundo van de 10 en 10 niveles.
public enum Leveling {
    public static let maxLevel = 60

    /// Experiencia necesaria para pasar de `level` al siguiente.
    /// 50 × nivel^1,6 + 30 (`economy.xpCurveBase`, `xpCurveExponent`, `xpCurveFlat`).
    public static func xpToNext(_ level: Int) -> Int {
        guard level < maxLevel else { return 0 }
        let k = TunedData.current.economy
        return Int((k.xpCurveBase * pow(Double(level), k.xpCurveExponent)).rounded()) + Int(k.xpCurveFlat)
    }

    /// Experiencia por matar a un enemigo de nivel `enemyLevel` siendo de nivel `heroLevel`.
    /// Los enemigos muy por debajo casi no dan; los que están por encima dan más.
    public static func xpForKill(enemyLevel: Int, heroLevel: Int, isBoss: Bool,
                                 bossMultiplier: Double = arenaBossMultiplier) -> Int {
        let base = 8 + 4 * Double(enemyLevel)
        let diff = Double(enemyLevel - heroLevel)
        let factor = diff >= 0 ? min(1.6, 1 + 0.12 * diff) : max(0.05, 1 + 0.18 * diff)
        return max(1, Int((base * factor * (isBoss ? bossMultiplier : 1)).rounded()))
    }

    /// Multiplicador de XP de los jefes en la arena: ×12 (`economy.arenaBossXPMultiplier`).
    public static var arenaBossMultiplier: Double { TunedData.current.economy.arenaBossXPMultiplier }
    /// Multiplicador de XP de los jefes de la historia (pueblo, campo, mazmorras de historia).
    /// ×6 (balance, B1): con ×12 el pueblo daba nivel ~7 al liberarlo; con ×6, ~6 (objetivo del brief). Medido con
    /// `Harness niveles`. Ajustable: `economy.storyBossXPMultiplier`.
    public static var storyBossMultiplier: Double { TunedData.current.economy.storyBossXPMultiplier }
    /// XP de los monstruos que se repiten en la historia: los de campo que reaparecen y los normales de las mazmorras
    /// de historia (repetibles). ×0,3 (balance, B1): con ×1 el campo de Valdemar llevaba al héroe al nivel ~10,6 antes
    /// del patio (objetivo ~9); con ×0,4, a ~9,8 (el bot repite monstruos para las misiones y al morir). Los permanentes
    /// (pueblo, interiores, jefes) dan la XP entera. Medido con `make historia`. Ajustable: `economy.respawningXPMultiplier`.
    public static var respawningMultiplier: Double { TunedData.current.economy.respawningXPMultiplier }

    /// XP de un monstruo de la historia (pueblo, campo y mazmorras de historia).
    /// - Parameter respawns: monstruo que vuelve a salir (campo o mazmorra repetible) y no es jefe.
    public static func storyXPForKill(enemyLevel: Int, heroLevel: Int, isBoss: Bool, respawns: Bool) -> Int {
        let xp = xpForKill(enemyLevel: enemyLevel, heroLevel: heroLevel, isBoss: isBoss, bossMultiplier: storyBossMultiplier)
        guard respawns, !isBoss else { return xp }
        return max(1, Int((Double(xp) * respawningMultiplier).rounded()))
    }

    /// XP de matar a `enemy` en la historia, con su multiplicador propio (`EnemyDefinition.xpMultiplier`).
    public static func storyXPForKill(_ enemy: EnemyDefinition, level: Int, heroLevel: Int, respawns: Bool) -> Int {
        let xp = storyXPForKill(enemyLevel: level, heroLevel: heroLevel, isBoss: enemy.isBoss, respawns: respawns)
        return enemy.xpMultiplier == 1 ? xp : max(0, Int((Double(xp) * enemy.xpMultiplier).rounded()))
    }

    /// XP de matar a `enemy` en la arena, con su multiplicador propio (`EnemyDefinition.xpMultiplier`).
    public static func xpForKill(_ enemy: EnemyDefinition, level: Int, heroLevel: Int) -> Int {
        let xp = xpForKill(enemyLevel: level, heroLevel: heroLevel, isBoss: enemy.isBoss)
        return enemy.xpMultiplier == 1 ? xp : max(0, Int((Double(xp) * enemy.xpMultiplier).rounded()))
    }

    /// Estadísticas extra por nivel sobre las de la raza (nivel 1 = nada).
    /// Vida 8 % y ataque 8,5 % de la raza por nivel y +0,6 de defensa (`economy.levelHPGrowth`, `levelAttackGrowth`,
    /// `levelDefensePerLevel`).
    public static func levelBonus(race: Race, level: Int) -> Stats {
        let n = Double(max(0, min(maxLevel, level) - 1))
        let base = race.baseStats
        let k = TunedData.current.economy
        return Stats(maxHP: base.maxHP * k.levelHPGrowth * n, attack: base.attack * k.levelAttackGrowth * n,
                     defense: k.levelDefensePerLevel * n)
    }

    /// Multiplicador de daño según la diferencia de nivel: pegar a alguien de más nivel cuesta,
    /// y los de mucho menos nivel apenas hacen daño. Entre 0,4 y 1,5.
    public static func damageFactor(attackerLevel: Int, defenderLevel: Int) -> Double {
        let diff = Double(attackerLevel - defenderLevel)
        return min(1.5, max(0.4, 1 + 0.07 * diff))
    }
}

extension PlayerProfile {
    /// Nivel del personaje (1…60).
    public var characterLevel: Int { max(1, min(Leveling.maxLevel, level ?? 1)) }

    /// Experiencia acumulada dentro del nivel actual.
    public var levelXP: Int { xp ?? 0 }

    /// Suma experiencia y sube de nivel las veces que haga falta. Devuelve los niveles ganados.
    @discardableResult
    public mutating func gainXP(_ amount: Int) -> Int {
        guard amount > 0, characterLevel < Leveling.maxLevel else { return 0 }
        var current = characterLevel
        var points = levelXP + amount
        var gained = 0
        while current < Leveling.maxLevel, points >= Leveling.xpToNext(current) {
            points -= Leveling.xpToNext(current)
            current += 1
            gained += 1
        }
        level = current
        xp = current >= Leveling.maxLevel ? 0 : points
        return gained
    }
}
