import Foundation

// MARK: - Oro de la historia (balance, B1)
//
// Lo que paga cada cosa en el modo historia (pueblo, campo y mazmorras de historia). La arena tiene sus propias
// recompensas (`Arena.reward`). Medido con `make historia`: con los números de antes (2 + 2·nivel por monstruo,
// 40·nivel por zona liberada y por jefe) el héroe llegaba al patio con ~11 000 de oro y la forja de tier 1-2 cuesta
// ~80 un arma y ~165 las cuatro armaduras: el oro no pesaba nada. Ahora el continente da ~2 000-2 500: lo justo para
// rehacer el arma varias veces con minerales, vestir las 4 armaduras de tier 1 y llegar con lo del tier 2 al final.

public enum StoryEconomy {
    /// Oro por matar a un monstruo de ese nivel: 1 + nivel ÷ 3 (los jefes, además, `bossGoldPerLevel` por nivel).
    /// Ajustable: `economy.storyKillGoldBase`, `storyKillGoldLevelsPerCoin`.
    public static func killGold(level: Int, isBoss: Bool) -> Int {
        let k = TunedData.current.economy
        return Int(k.storyKillGoldBase) + max(0, level) / Int(k.storyKillGoldLevelsPerCoin) + (isBoss ? bossGoldPerLevel * level : 0)
    }

    /// Oro por matar a `enemy`, con su multiplicador propio (`EnemyDefinition.goldMultiplier`).
    public static func killGold(_ enemy: EnemyDefinition, level: Int) -> Int {
        let gold = killGold(level: level, isBoss: enemy.isBoss)
        return enemy.goldMultiplier == 1 ? gold : max(0, Int((Double(gold) * enemy.goldMultiplier).rounded()))
    }

    /// Oro extra de un jefe por nivel de zona: 10 (`economy.storyBossGoldPerLevel`).
    public static var bossGoldPerLevel: Int { Int(TunedData.current.economy.storyBossGoldPerLevel) }

    /// Oro al liberar una zona (pueblo o campo) la primera vez: 3 × nivel (`economy.storyZoneGoldPerLevel`).
    public static func zoneGold(level: Int) -> Int { Int(TunedData.current.economy.storyZoneGoldPerLevel) * level }
}

// MARK: - Premio de las mazmorras de historia al ganar

extension StoryDungeon {
    /// Premio extra en cada victoria (también al repetir), con su probabilidad. Cripta: 50 % de oro ×1 (`zonas.md` §3).
    public static let winBonus: [String: (reward: Reward, chance: Double)] = [
        "valdemar.cripta": (Reward(minerals: [.gold: 1]), 0.5),
    ]

    /// Lo que se gana al vencer: `reward` (la esmeralda de la Cripta) solo la primera vez, para que repetir no sea una
    /// mina de esmeraldas; el extra de `winBonus`, en cada victoria con su probabilidad.
    public func rewards<G: RandomNumberGenerator>(firstWin: Bool, using rng: inout G) -> [Reward] {
        var out: [Reward] = []
        if firstWin, let reward { out.append(reward) }
        if let bonus = Self.winBonus[id], Double.random(in: 0..<1, using: &rng) < bonus.chance { out.append(bonus.reward) }
        return out
    }
}
