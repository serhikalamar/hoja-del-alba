import Testing
@testable import GameCore

/// Números de la historia de Valdemar (balance, B1): XP y oro de los monstruos, recompensas de misiones y aldeanos.
@Suite("Balance de la historia")
struct StoryBalanceTests {
    @Test func respawningMonstersGiveLessXPButBossesDoNot() {
        let full = Leveling.storyXPForKill(enemyLevel: 7, heroLevel: 7, isBoss: false, respawns: false)
        let field = Leveling.storyXPForKill(enemyLevel: 7, heroLevel: 7, isBoss: false, respawns: true)
        #expect(field < full)
        #expect(field == Int((Double(full) * Leveling.respawningMultiplier).rounded()))
        let boss = Leveling.storyXPForKill(enemyLevel: 7, heroLevel: 7, isBoss: true, respawns: true)
        #expect(boss == Leveling.xpForKill(enemyLevel: 7, heroLevel: 7, isBoss: true, bossMultiplier: Leveling.storyBossMultiplier))
        #expect(Leveling.storyXPForKill(enemyLevel: 1, heroLevel: 20, isBoss: false, respawns: true) >= 1)
    }

    @Test func storyGoldGrowsWithLevelAndBossesPayMore() {
        #expect(StoryEconomy.killGold(level: 9, isBoss: false) > StoryEconomy.killGold(level: 1, isBoss: false))
        #expect(StoryEconomy.killGold(level: 5, isBoss: true) > StoryEconomy.killGold(level: 5, isBoss: false) * 10)
        #expect(StoryEconomy.zoneGold(level: 5) > 0)
    }

    /// En Valdemar solo sale la familia del continente (`minerales.md`): ni aldeanos ni misiones dan otros.
    @Test func rewardsOnlyUseValdemarMinerals() throws {
        let family = Set(try #require(World.continent(World.valdemarID)).minerals)
        let npcs = Valdehierro.interiors.flatMap(\.npcs)
        for npc in npcs {
            for mineral in npc.reward.minerals.keys { #expect(family.contains(mineral), "\(npc.id): \(mineral)") }
        }
        for quest in World.quests {
            for mineral in quest.reward.minerals.keys { #expect(family.contains(mineral), "\(quest.id): \(mineral)") }
        }
    }

    /// Las piezas normales que regalan los aldeanos no pasan del tier 2 (la forja de Valdemar vende el 1).
    @Test func villagerPartsStayNearTheContinentTier() {
        for npc in Valdehierro.interiors.flatMap(\.npcs) {
            guard let id = npc.reward.partID, let part = PartCatalog.part(id), !part.isSpecial else { continue }
            #expect(part.tier <= 2, "\(npc.id): \(id)")
        }
    }

    /// Las piezas de jefe de Valdemar: tier 1, ≈1,5-1,75× una pieza de tier 1 del mismo hueco; las de la arena, igual.
    @Test func valdemarBossPartsStayInTierOne() throws {
        #expect(PartCatalog.storyBossParts.count == 10)
        for part in PartCatalog.storyBossParts {
            #expect(part.tier == 1 && part.isSpecial && part.abilityID != nil, "\(part.id)")
            let bestNormal = PartCatalog.normalParts.filter { $0.slot == part.slot && $0.tier == 1 }.map(\.stats.attack).max() ?? 0
            #expect(part.stats.attack <= max(6, bestNormal * 1.8), "\(part.id): \(part.stats.attack)")
        }
        // La arena no cambia: el Martillo del Herrero sigue con ATQ 40.
        #expect(PartCatalog.part("boss.possessedSmith")?.stats.attack == 40)
        let ogre = try #require(Bestiary.enemy("ogre"))
        #expect(PartCatalog.bossPartID(for: ogre, continent: nil) == "boss.ogre")
        #expect(PartCatalog.bossPartID(for: ogre, continent: World.continent(World.valdemarID)) == "boss.ogre.valdemar")
        #expect(PartCatalog.part("legend.dawn")?.tier == 2)
    }

    @Test func storyBossTuningOnlyTouchesStoryBosses() throws {
        let ogre = try #require(Bestiary.enemy("ogre"))
        #expect(ogre.forStory.hp > ogre.hp)
        #expect(ogre.forStory.damage < ogre.damage)
        #expect(ogre.forStory.id == ogre.id && ogre.forStory.specialPartID == ogre.specialPartID)
        let wolf = try #require(Bestiary.enemy("wolf"))
        #expect(wolf.forStory == wolf)
        for id in EnemyDefinition.storyBossTuning.keys { #expect(Bestiary.enemy(id)?.isBoss == true, "\(id)") }
    }

    /// Cripta: la esmeralda solo la primera vez; el oro (mineral), el 50 % de las victorias.
    @Test func cryptRewardsOnRepeat() throws {
        let crypt = try #require(World.storyDungeon("valdemar.cripta"))
        var rng = SeededGenerator(seed: 7)
        let first = crypt.rewards(firstWin: true, using: &rng)
        #expect(first.contains { $0.minerals[.emerald] == 1 })
        var gold = 0
        for _ in 0..<1000 {
            let r = crypt.rewards(firstWin: false, using: &rng)
            #expect(!r.contains { ($0.minerals[.emerald] ?? 0) > 0 })
            gold += r.reduce(0) { $0 + ($1.minerals[.gold] ?? 0) }
        }
        #expect(gold > 400 && gold < 600)
    }
}
