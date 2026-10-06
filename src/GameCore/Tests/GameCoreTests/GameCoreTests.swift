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

@Suite("Bestiario y niveles")
struct LevelTests {
    @Test func fiftyEnemiesTenBosses() {
        #expect(Bestiary.all.count == 50)
        #expect(Set(Bestiary.all.map(\.id)).count == 50)
        #expect(Bestiary.bosses.count == 10)
        for boss in Bestiary.bosses {
            #expect(PartCatalog.part(boss.specialPartID ?? "")?.isSpecial == true, "\(boss.id)")
        }
    }

    @Test func worldHasTenLevelsWithBossAtTheEnd() {
        let world = Worlds.village
        #expect(world.levels.count == 10)
        for level in world.levels {
            let boss = level.boss!
            #expect(level.waves.last!.spawns[boss.id] == 1)
            #expect(level.waves.dropLast().allSatisfy { $0.spawns[boss.id] == nil })
            var rng = SeededGenerator(seed: 1)
            #expect(level.waves.last!.spawnOrder(using: &rng).last == boss.id)
            for wave in level.waves {
                for id in wave.spawns.keys { #expect(Bestiary.enemy(id) != nil, "\(id)") }
            }
        }
        #expect(world.level(10)!.boss!.id == "goblinKing")
    }

    @Test func wavesGrow() {
        for level in Worlds.village.levels {
            let totals = level.waves.map(\.totalMonsters)
            #expect(totals == totals.sorted(), "Nivel \(level.id)")
        }
    }

    @Test func everyEnemyAppearsSomewhere() {
        let used = Set(Worlds.village.levels.flatMap(\.enemyIDs))
        for enemy in Bestiary.all { #expect(used.contains(enemy.id), "\(enemy.id) nunca aparece") }
    }
}

@Suite("Combate")
struct CombatTests {
    @Test func defenseReducesDamageButNeverBelowOne() {
        #expect(Combat.incomingDamage(raw: 10, defense: 0) == 10)
        #expect(Combat.incomingDamage(raw: 10, defense: 60) == 5)
        #expect(Combat.incomingDamage(raw: 1, defense: 1000) == 1)
    }

    @Test func enemiesScaleAfterTheirLevel() {
        let goblin = Bestiary.enemy("goblin")!
        #expect(goblin.stats(level: 10).hp > goblin.stats(level: 1).hp * 2)
    }
}

@Suite("Piezas y habilidades")
struct PartTests {
    @Test func moreThanHundredParts() {
        #expect(PartCatalog.normalParts.count >= 100)
        #expect(Set(PartCatalog.all.map(\.id)).count == PartCatalog.all.count)
        for slot in PartSlot.allCases {
            #expect(PartCatalog.normalParts.contains { $0.slot == slot })
        }
    }

    @Test func comboAbility() {
        // Obsidiana = fuego (x2) + roble = tierra → Magma
        let parts = ["head.sword.obsidian", "guard.curved.obsidian", "grip.short.oak"].compactMap(PartCatalog.part)
        #expect(AbilityBook.resolve(parts: parts)?.id == "magma")
    }

    @Test func singleElementAbility() {
        // Cobre y katana = tormenta (x3) + roble = tierra; tormenta+tierra no es combinación → Rayo en cadena
        let parts = ["head.katana.copper", "guard.curved.copper", "grip.long.oak"].compactMap(PartCatalog.part)
        #expect(AbilityBook.resolve(parts: parts)?.id == "chain_lightning")
    }

    @Test func noAbilityWithoutFocus() {
        let parts = ["head.sword.copper", "guard.curved.iron", "grip.long.ash"].compactMap(PartCatalog.part)
        #expect(AbilityBook.resolve(parts: parts) == nil)
    }

    @Test func bossPartOverrides() {
        let parts = ["head.sword.obsidian", "boss.goblinKing", "grip.short.oak"].compactMap(PartCatalog.part)
        #expect(AbilityBook.resolve(parts: parts)?.id == "royal_decree")
    }

    @Test func everyAbilityIDResolves() {
        for part in PartCatalog.specialParts { #expect(AbilityBook.ability(part.abilityID) != nil) }
        #expect(Set(AbilityBook.all.map(\.id)).count == AbilityBook.all.count)
    }
}

@Suite("Forja del enano")
struct ShopTests {
    @Test func offersRespectTierLimit() {
        var rng = SeededGenerator(seed: 7)
        for _ in 0..<200 {
            let offers = ShopGenerator.offers(level: 1, using: &rng)
            #expect(offers.filter { $0.part != nil }.count == ShopGenerator.partOfferCount)
            for offer in offers {
                if let part = offer.part { #expect(part.tier <= 2 && !part.isSpecial) }
                if let item = offer.item { #expect(item.tier == 1) }
            }
        }
    }

    @Test func buyingPartAddsIt() throws {
        var profile = PlayerProfile.newGame()
        profile.gold = 1000
        let part = PartCatalog.part("head.axe.iron")!
        try profile.buy(ShopOffer(kind: .part(part), price: part.price))
        #expect(profile.partCount(part.id) == 1)
        #expect(profile.gold == 1000 - part.price)
    }
}

@Suite("Ritual")
struct CraftingTests {
    @Test func luckImprovesOdds() {
        let noLuck = Roulette.probabilities(luck: 0)
        let lucky = Roulette.probabilities(luck: 1.5)
        #expect(lucky.last! > noLuck.last!)
        #expect(abs(noLuck.reduce(0, +) - 1) < 0.0001)
    }

    @Test func craftConsumesPartsAndDiscovers() throws {
        var profile = PlayerProfile.newGame()
        profile.gold = 100
        for id in ["head.sword.obsidian", "guard.curved.obsidian", "grip.short.oak"] { profile.addPart(id) }
        profile.addMineral(.ruby, count: 1)
        let recipe = WeaponRecipe(headID: "head.sword.obsidian", guardID: "guard.curved.obsidian",
                                  gripID: "grip.short.oak", minerals: [.copper: 2, .ruby: 1])
        var rng = SeededGenerator(seed: 9)
        let result = try profile.craft(recipe, using: &rng)

        #expect(profile.partCount("head.sword.obsidian") == 0)
        #expect(profile.count(of: .copper) == 1)
        #expect(profile.gold == 100 - recipe.goldCost)
        #expect(result.item.name == "Espada de Obsidiana")
        #expect(result.item.abilityID == "magma")
        #expect(result.discoveredNewAbility)
        #expect(profile.discoveredAbilities.contains("magma"))
        let expectedAttack = (recipe.partStats.attack + 4) * result.quality.multiplier
        #expect(abs(result.item.stats.attack - expectedAttack) < 0.0001)
    }

    @Test func craftValidation() {
        var profile = PlayerProfile.newGame()
        let starter = WeaponRecipe(headID: "head.sword.copper", guardID: "guard.straight.copper", gripID: "grip.short.oak")
        #expect(profile.validate(starter) == nil)
        let wrong = WeaponRecipe(headID: "guard.straight.copper", guardID: "guard.straight.copper", gripID: "grip.short.oak")
        #expect(profile.validate(wrong) == .wrongSlot(.head))
        let missing = WeaponRecipe(headID: "head.axe.iron", guardID: "guard.straight.copper", gripID: "grip.short.oak")
        #expect(profile.validate(missing) == .missingPart(.head))
        profile.gold = 0
        #expect(profile.validate(starter) == .notEnoughGold)
    }
}

@Suite("Perfil")
struct ProfileTests {
    @Test func racesHaveDifferentStats() {
        let stats = Race.allCases.map { PlayerProfile.newGame(race: $0).totalStats }
        #expect(Set(stats).count == Race.allCases.count)
        #expect(PlayerProfile.newGame(race: .dwarf).totalStats.defense > PlayerProfile.newGame(race: .elf).totalStats.defense)
    }

    @Test func abilityBonusApplies() throws {
        var profile = PlayerProfile.newGame()
        profile.gold = 100
        for id in ["head.axe.copper", "guard.claw.copper", "grip.short.leather"] { profile.addPart(id) }
        var rng = SeededGenerator(seed: 1)
        let result = try profile.craft(WeaponRecipe(headID: "head.axe.copper", guardID: "guard.claw.copper", gripID: "grip.short.leather"), using: &rng)
        #expect(result.item.abilityID == "bloodthirst")
        profile.equip(result.item.id)
        #expect(profile.totalStats.lifesteal >= 0.06)
    }

    @Test func cannotSellEquipped() {
        var profile = PlayerProfile.newGame()
        #expect(profile.sell(profile.equippedWeaponID!) == 0)
    }

    @Test func saveRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("save.json")
        let store = SaveStore(url: url)
        var profile = PlayerProfile.newGame(race: .werewolf)
        profile.addMineral(.mithril, count: 2)
        profile.addPart("boss.goblinKing")
        profile.completeLevel(3)
        profile.inventory[0].customSprite = CustomSprite(width: 2, height: 1, pixels: [-1, 0xFF0000])
        try store.save(profile)
        #expect(store.load() == profile)
        store.delete()
    }
}

@Suite("Pueblo explorable")
struct TownTests {
    @Test func everySpawnAndNPCIsOnWalkableTiles() {
        for area in [Valdehierro.town] + Valdehierro.interiors {
            for spawn in area.spawns {
                #expect(area.isWalkable(spawn.position), "\(spawn.id) en \(area.id)")
                #expect(Bestiary.enemy(spawn.enemyID) != nil, "\(spawn.enemyID)")
            }
            for npc in area.npcs { #expect(area.isWalkable(npc.position), "\(npc.id)") }
            #expect(area.isWalkable(area.entry), "entrada de \(area.id)")
            #expect(Set(area.rows.map(\.count)).count == 1, "filas desiguales en \(area.id)")
        }
    }

    @Test func doorsLeadSomewhereAndOpenToWalkableTiles() {
        let town = Valdehierro.town
        for building in town.buildings {
            for door in building.doorTiles {
                #expect(town.isWalkable(door))
                #expect(town.isWalkable(TilePoint(door.x, door.y + 1)), "delante de \(building.id)")
            }
            if let id = building.interiorID, id != "smithy" {
                #expect(Valdehierro.area(id) != nil, "\(id)")
                #expect(!Valdehierro.area(id)!.exitTiles.isEmpty)
            }
        }
    }

    @Test func castleOpensWhenAllVillagersAreRescued() {
        var progress = TownProgress()
        #expect(!progress.castleOpen)
        progress.rescued = Valdehierro.villagerIDs
        #expect(progress.castleOpen)
        #expect(Valdehierro.villagerIDs.count == 6)
    }

    @Test func princessGivesLegendaryPart() {
        let princess = Valdehierro.area("castle")!.npcs.first { $0.role == .princess }!
        let part = PartCatalog.part(princess.reward.partID!)!
        #expect(part.isSpecial && part.tier == 6)
        #expect(AbilityBook.ability(part.abilityID)?.id == "dawn")
    }

    @Test func zonesLiberate() {
        var progress = TownProgress()
        let town = Valdehierro.town
        let south = town.zones.first { $0.id == "south" }!
        #expect(!progress.isLiberated(south, in: town))
        for spawn in town.spawns where south.contains(spawn.position) { progress.killedSpawns.insert(spawn.id) }
        #expect(progress.isLiberated(south, in: town))
        #expect(progress.shopLevel == 2)
    }
}

@Suite("Arena de oleadas")
struct ArenaTests {
    @Test func wavesGetHarder() {
        let sizes = (1...30).map { Arena.wave($0).totalMonsters }
        #expect(sizes == sizes.sorted())
        #expect(Arena.enemyLevel(wave: 1) == 1)
        #expect(Arena.enemyLevel(wave: 40) > 10)
        #expect(Arena.wave(1).spawns.keys.allSatisfy { Bestiary.enemy($0)!.level == 1 })
    }

    @Test func bossEveryFiveWavesAndStageChanges() {
        for n in 1...20 {
            let hasBoss = Arena.wave(n).spawns.keys.contains { Bestiary.enemy($0)!.isBoss }
            #expect(hasBoss == (n % 5 == 0), "oleada \(n)")
        }
        #expect(Arena.stage(wave: 1).id == Arena.stage(wave: 5).id)
        #expect(Arena.stage(wave: 6).id != Arena.stage(wave: 5).id)
        #expect(Arena.stage(wave: 51).id == Arena.stage(wave: 1).id)
    }

    @Test func shopEveryTwoWaves() {
        #expect(!Arena.isShopWave(1))
        #expect(Arena.isShopWave(2))
        #expect(Arena.isShopWave(4))
        #expect(!Arena.isShopWave(5))
    }
}
