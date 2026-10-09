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
        // Los 50 originales (los de la arena) siguen en el bestiario; los de continente se suman aparte.
        #expect(Arena.originalEnemyIDs.count == 50)
        #expect(Arena.enemies.count == 50)
        #expect(Arena.enemies.filter(\.isBoss).count == 10)
        #expect(Set(Bestiary.all.map(\.id)).count == Bestiary.all.count)
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
        for enemy in Arena.enemies { #expect(used.contains(enemy.id), "\(enemy.id) nunca aparece") }
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
            // Siempre se puede montar un arma con lo que hay a la venta.
            #expect(Set(offers.compactMap { $0.part?.slot }) == Set(PartSlot.allCases))
            for offer in offers {
                if let part = offer.part { #expect(part.tier <= 2 && !part.isSpecial) }
                if let item = offer.item { #expect(item.tier <= 2 && item.styleID != nil) }
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
        // Hoja del Alba (I): a la altura del tier 2 (balance B1, `progresion.md` §6).
        #expect(part.isSpecial && part.tier == 2)
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
        // Sin contar las de jefe (que traen la mitad de monstruos normales), cada oleada es más grande.
        let sizes = (1...30).filter { !Arena.isBossWave($0) }.map { Arena.wave($0).totalMonsters }
        #expect(sizes == sizes.sorted())
        #expect(Arena.wave(10).totalMonsters < Arena.wave(9).totalMonsters)
        let levels = (1...40).map { Arena.enemyLevel(wave: $0) }
        #expect(levels == levels.sorted())
        // Tras el muro, los enemigos suben de nivel más deprisa.
        #expect(Arena.enemyLevel(wave: Arena.wallWave + 5) - Arena.enemyLevel(wave: Arena.wallWave) > 5 / 2)
        #expect(Arena.enemyLevel(wave: 1) == 1)
        #expect(Arena.enemyLevel(wave: 40) > 10)
        #expect(Arena.wave(1).spawns.keys.allSatisfy { Bestiary.enemy($0)!.level == 1 })
    }

    @Test func bossEveryFiveWavesAndStageChanges() {
        for n in 1...20 {
            let hasBoss = Arena.wave(n).spawns.keys.contains { Bestiary.enemy($0)!.isBoss }
            #expect(hasBoss == (n % 5 == 0), "oleada \(n)")
        }
        #expect(Arena.floor(wave: 1).id == Arena.floor(wave: 5).id)
        #expect(Arena.floor(wave: 6).id != Arena.floor(wave: 5).id)
        #expect(Arena.floor(wave: 5 * Dungeon.floors.count + 1).id == Arena.floor(wave: 1).id)
        #expect(Arena.depth(wave: 6) == 2)
    }

    @Test func shopEveryTwoWaves() {
        #expect(!Arena.isShopWave(1))
        #expect(Arena.isShopWave(2))
        #expect(Arena.isShopWave(4))
        #expect(!Arena.isShopWave(5))
    }
}

@Suite("Mazmorra de la arena")
struct DungeonTests {
    @Test func floorsAreWellFormed() {
        #expect(Set(Dungeon.floors.map(\.id)).count == Dungeon.floors.count)
        for floor in Dungeon.floors {
            let width = floor.rows[0].count
            #expect(floor.rows.allSatisfy { $0.count == width }, "\(floor.id): filas de distinta longitud")
            for row in floor.rows {
                for c in row { #expect(DungeonTile(rawValue: c) != nil, "\(floor.id): carácter desconocido '\(c)'") }
            }
            // Borde cerrado: nadie se sale del mapa.
            for x in 0..<width {
                #expect(floor.tile(x, 0).isSolid && floor.tile(x, floor.height - 1).isSolid, "\(floor.id): borde abierto en x=\(x)")
            }
            for y in 0..<floor.height {
                #expect(floor.tile(0, y).isSolid && floor.tile(width - 1, y).isSolid, "\(floor.id): borde abierto en y=\(y)")
            }
        }
    }

    @Test func everythingIsReachable() {
        for floor in Dungeon.floors {
            #expect(floor.isWalkable(floor.start), "\(floor.id): el héroe empieza en una casilla sólida")
            let reachable = floor.reachable()
            #expect(Set(floor.walkableTiles) == reachable, "\(floor.id): hay suelo aislado")
            #expect(floor.spawnPoints.count >= 6, "\(floor.id): pocas entradas de monstruos")
            #expect(floor.spawnPoints.allSatisfy(reachable.contains), "\(floor.id): entrada de monstruos aislada")
            #expect(reachable.contains(floor.bossSpawn), "\(floor.id): el jefe no puede entrar")
            // Sitio para pelear: la mazmorra es bastante más grande que la pantalla.
            #expect(reachable.count >= 300, "\(floor.id): poco espacio")
        }
    }
}

@Suite("Niveles y arena roguelike")
struct LevelingTests {
    @Test func levelsGrowWithExperience() {
        var hero = PlayerProfile.newGame()
        #expect(hero.characterLevel == 1)
        let before = hero.totalStats
        let gained = hero.gainXP(Leveling.xpToNext(1) + Leveling.xpToNext(2) + 5)
        #expect(gained == 2)
        #expect(hero.characterLevel == 3)
        #expect(hero.levelXP == 5)
        #expect(hero.totalStats.maxHP > before.maxHP && hero.totalStats.attack > before.attack)
        hero.gainXP(10_000_000)
        #expect(hero.characterLevel == Leveling.maxLevel)
    }

    @Test func experienceDependsOnLevelDifference() {
        let even = Leveling.xpForKill(enemyLevel: 5, heroLevel: 5, isBoss: false)
        #expect(Leveling.xpForKill(enemyLevel: 1, heroLevel: 10, isBoss: false) < even / 4)
        #expect(Leveling.xpForKill(enemyLevel: 8, heroLevel: 5, isBoss: false) > even)
        #expect(Leveling.xpForKill(enemyLevel: 5, heroLevel: 5, isBoss: true) > even * 5)
        #expect(Leveling.damageFactor(attackerLevel: 1, defenderLevel: 10) < 0.5)
        #expect(Leveling.damageFactor(attackerLevel: 5, defenderLevel: 5) == 1)
    }

    @Test func arenaRunStartsFromScratch() {
        var hero = PlayerProfile.newCharacter(name: "Aria", race: .elf, appearance: Appearance())
        hero.gainXP(5_000)
        hero.gold = 999
        hero.addMineral(.diamond, count: 5)
        let run = PlayerProfile.arenaRun(for: hero)
        #expect(run.characterLevel == 1)
        #expect(run.gold < 100 && run.minerals.isEmpty && run.parts.isEmpty)
        #expect(run.name == "Aria" && run.race == .elf && run.characterID == hero.characterID)
        #expect(run.equippedWeapon != nil)
    }

    @Test func mineralsAreScarce() {
        var rng = SeededGenerator(seed: 3)
        let goblin = Bestiary.enemy("goblin")!.stats(level: 1)
        let drops = (0..<1_000).reduce(0) { total, _ in total + goblin.rollDrops(using: &rng).count }
        #expect(drops < 250, "un goblin suelta mineral muy pocas veces")
    }
}

@Suite("Personajes y armadura")
struct CharacterTests {
    @Test func legacyArmorSlotBecomesChest() throws {
        let json = #"["armor","weapon","boots"]"#.data(using: .utf8)!
        let slots = try JSONDecoder().decode([EquipmentSlot].self, from: json)
        #expect(slots == [.chest, .weapon, .boots])
        // El peto inicial (guardado como armadura antigua) sigue equipado.
        let profile = PlayerProfile.newGame()
        #expect(profile.equipped(.chest)?.blueprintID == "padded_tunic")
    }

    @Test func fourGearSlotsAddStats() throws {
        var profile = PlayerProfile.newGame()
        let before = profile.totalStats.defense
        for style in ["helm.knight", "chest.plate", "gloves.gauntlets", "boots.greaves"] {
            let item = ArmorRecipe(styleID: style, materialID: "iron", dye: 0x3B5DC9).makeItem(quality: Roulette.segments[2])
            profile.inventory.append(item)
            profile.equip(item.id)
        }
        #expect(EquipmentSlot.gear.allSatisfy { profile.equipped($0) != nil })
        #expect(profile.totalStats.defense > before + 10)
        profile.unequip(.helmet)
        #expect(profile.equipped(.helmet) == nil)
    }

    @Test func armorCraftingWithDyeAndRoulette() throws {
        var profile = PlayerProfile.newGame()
        profile.gold = 100
        profile.addMineral(.iron, count: 2)
        let recipe = ArmorRecipe(styleID: "boots.leather", materialID: "wolfhide", dye: 0xB13E53, minerals: [.iron: 2])
        var rng = SeededGenerator(seed: 4)
        let result = try profile.craft(recipe, using: &rng)
        #expect(result.item.slot == .boots)
        #expect(result.item.dye == 0xB13E53 && result.item.styleID == "boots.leather" && result.item.materialID == "wolfhide")
        #expect(result.item.name == "Botas de cuero de Piel de lobo")
        #expect(profile.gold == 100 - recipe.goldCost && profile.count(of: .iron) == 0)
        #expect(ArmorCatalog.styles.allSatisfy { ArmorCatalog.styles(for: $0.slot).count >= 4 })
    }

    @Test func rosterMigratesOldSaveAndStoresCharacters() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let legacy = SaveStore(url: dir.appendingPathComponent("save-v2.json"))
        var old = PlayerProfile.newGame(race: .dwarf)
        old.gold = 777
        try legacy.save(old)
        let store = RosterStore(url: dir.appendingPathComponent("roster.json"), legacy: legacy)
        var roster = store.load()
        #expect(roster.characters.count == 1 && roster.selected?.gold == 777 && roster.selected?.name == "Héroe")

        let elf = PlayerProfile.newCharacter(name: "Lúthien", race: .elf, appearance: Appearance(hairStyle: 2, hairColor: 3))
        roster.upsert(elf)
        roster.selectedID = elf.characterID
        try store.save(roster)
        let loaded = store.load()
        #expect(loaded.characters.count == 2 && loaded.selected?.name == "Lúthien" && loaded.selected?.appearance?.hairStyle == 2)
        #expect(loaded.isNameTaken("lúthien"))
    }

    @Test func nameValidation() {
        #expect(PlayerProfile.isValidName("Arthas"))
        #expect(PlayerProfile.isValidName("Gimli Hijo-de-Glóin") == false)   // más de 14
        #expect(PlayerProfile.isValidName("O'Neil"))
        #expect(!PlayerProfile.isValidName("A"))
        #expect(!PlayerProfile.isValidName("12abc"))
    }
}
