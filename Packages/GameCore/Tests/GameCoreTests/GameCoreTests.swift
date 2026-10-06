import Foundation
import Testing
@testable import GameCore

@Suite("Minerales")
struct MineralTests {
    @Test func dropPercentsSumTo100() {
        let total = Mineral.allCases.reduce(0) { $0 + $1.dropPercent }
        #expect(abs(total - 100) < 0.0001)
        #expect(Mineral.allCases.count == 10)
    }

    @Test func rollDistributionMatchesPercents() {
        var rng = SeededGenerator(seed: 42)
        let samples = 200_000
        var counts: [Mineral: Int] = [:]
        for _ in 0..<samples { counts[Mineral.roll(using: &rng), default: 0] += 1 }
        for mineral in Mineral.allCases {
            let observed = Double(counts[mineral, default: 0]) / Double(samples) * 100
            #expect(abs(observed - mineral.dropPercent) < 0.5, "\(mineral) \(observed)")
        }
    }
}

@Suite("Niveles")
struct LevelTests {
    @Test func worldHasTenLevels() {
        #expect(Worlds.forest.levels.count == 10)
        #expect(Worlds.forest.levels.map(\.id) == Array(1...10))
    }

    @Test func onlyGoblinsAndGrowingWaves() {
        for level in Worlds.forest.levels {
            #expect(level.roundCount >= 3)
            let totals = level.waves.map(\.totalMonsters)
            #expect(totals == totals.sorted(), "Las rondas deben crecer en el nivel \(level.id)")
        }
        let firstTotal = Worlds.forest.levels[0].waves[0].totalMonsters
        let lastTotal = Worlds.forest.levels[9].waves[0].totalMonsters
        #expect(lastTotal > firstTotal * 3)
    }

    @Test func bossOnlyOnLastRoundOfLevel10() {
        let level10 = Worlds.forest.level(10)!
        #expect(level10.waves.last!.spawns[.goblinKing] == 1)
        for level in Worlds.forest.levels.dropLast() {
            #expect(!level.monsterKinds.contains(.goblinKing))
        }
        var rng = SeededGenerator(seed: 1)
        #expect(level10.waves.last!.spawnOrder(using: &rng).last == .goblinKing)
    }
}

@Suite("Combate")
struct CombatTests {
    @Test func defenseReducesDamageButNeverBelowOne() {
        #expect(Combat.incomingDamage(raw: 10, defense: 0) == 10)
        #expect(Combat.incomingDamage(raw: 10, defense: 60) == 5)
        #expect(Combat.incomingDamage(raw: 1, defense: 1000) == 1)
    }

    @Test func monsterScaling() {
        let l1 = MonsterKind.goblin.stats(level: 1)
        let l10 = MonsterKind.goblin.stats(level: 10)
        #expect(l10.hp > l1.hp * 2)
        #expect(l10.damage > l1.damage)
    }
}

@Suite("Tienda")
struct ShopTests {
    @Test func offersRespectTierLimit() {
        var rng = SeededGenerator(seed: 7)
        for _ in 0..<200 {
            let offers = ShopGenerator.offers(level: 1, using: &rng)
            #expect(offers.count == ShopGenerator.equipmentOfferCount + 1)
            for offer in offers {
                if let item = offer.item { #expect(item.tier == 1) }
            }
        }
    }

    @Test func buyingSpendsGold() throws {
        var profile = PlayerProfile.newGame()
        profile.gold = 1000
        var rng = SeededGenerator(seed: 3)
        let offer = ShopGenerator.offers(level: 5, using: &rng)[0]
        let item = try profile.buy(offer)
        #expect(item != nil)
        #expect(profile.gold == 1000 - offer.price)
        #expect(profile.inventory.contains { $0.id == item!.id })

        var poor = PlayerProfile.newGame()
        poor.gold = 0
        #expect(throws: PlayerProfile.PurchaseError.notEnoughGold) { try poor.buy(offer) }
    }
}

@Suite("Forja")
struct CraftingTests {
    @Test func luckImprovesOdds() {
        let noLuck = Roulette.probabilities(luck: 0)
        let lucky = Roulette.probabilities(luck: 1.5)
        #expect(lucky.last! > noLuck.last!)
        #expect(lucky.first! < noLuck.first!)
        #expect(abs(noLuck.reduce(0, +) - 1) < 0.0001)
    }

    @Test func craftConsumesResources() throws {
        var profile = PlayerProfile.newGame()
        profile.gold = 100
        profile.addMineral(.copper, count: 5)
        profile.addMineral(.ruby, count: 1)
        let recipe = CraftRecipe(blueprint: Catalog.blueprint(id: "short_sword")!, minerals: [.copper: 3, .ruby: 1])
        var rng = SeededGenerator(seed: 9)
        let result = try profile.craft(recipe, using: &rng)

        #expect(profile.count(of: .copper) == 2)
        #expect(profile.count(of: .ruby) == 0)
        #expect(profile.gold == 100 - recipe.goldCost)
        #expect(result.item.name == "Espada corta de Cobre")
        let expectedAttack = (6 + 3 * 2) * result.quality.multiplier
        #expect(abs(result.item.stats.attack - expectedAttack) < 0.0001)
        #expect(abs(result.item.stats.critChance - 0.03 * result.quality.multiplier) < 0.0001)
    }

    @Test func craftValidation() {
        var profile = PlayerProfile.newGame()
        profile.gold = 0
        let sword = Catalog.blueprint(id: "short_sword")!
        #expect(profile.validate(CraftRecipe(blueprint: sword, minerals: [.copper: 1])) == .notEnoughMinerals)
        #expect(profile.validate(CraftRecipe(blueprint: sword, minerals: [.copper: 3])) == .missingMineral(.copper))
        profile.addMineral(.copper, count: 3)
        #expect(profile.validate(CraftRecipe(blueprint: sword, minerals: [.copper: 3])) == .notEnoughGold)
        let hammer = Catalog.blueprint(id: "war_hammer")!
        #expect(profile.validate(CraftRecipe(blueprint: hammer, minerals: [.copper: 3])) == .blueprintLocked)
    }
}

@Suite("Perfil")
struct ProfileTests {
    @Test func newGameHasEquipment() {
        let profile = PlayerProfile.newGame()
        #expect(profile.equippedWeapon?.blueprintID == "wood_sword")
        #expect(profile.equippedArmor?.blueprintID == "padded_tunic")
        #expect(profile.totalStats.attack == Stats.knightBase.attack + 3)
    }

    @Test func cannotSellEquipped() {
        var profile = PlayerProfile.newGame()
        let weaponID = profile.equippedWeaponID!
        #expect(profile.sell(weaponID) == 0)
        #expect(profile.inventory.count == 2)
    }

    @Test func completingUnlocksNext() {
        var profile = PlayerProfile.newGame()
        profile.completeLevel(1)
        #expect(profile.highestUnlockedLevel == 2)
        profile.completeLevel(10)
        #expect(profile.highestUnlockedLevel == 10)
    }

    @Test func saveRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("save.json")
        let store = SaveStore(url: url)
        var profile = PlayerProfile.newGame()
        profile.addMineral(.mithril, count: 2)
        profile.completeLevel(3)
        try store.save(profile)
        #expect(store.load() == profile)
        store.delete()
    }
}
