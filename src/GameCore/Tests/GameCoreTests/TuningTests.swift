import Foundation
import Testing
@testable import GameCore

/// Ajustes en vivo del panel de administración (`GameTuning`): contrato, validación y aplicación.
/// Casi todo se comprueba con `GameTuning.resolve` (no toca el estado global: los tests corren en paralelo); solo
/// `applyInstallsAndRestores` instala de verdad, y lo hace con campos que no mira ningún otro test.
@Suite("Ajustes en vivo")
struct TuningTests {
    // MARK: Documento vacío

    @Test func emptyTuningChangesNothing() {
        let d = GameTuning.resolve(GameTuning())
        #expect(d.warnings.isEmpty)
        #expect(d.enemies == Bestiary.baseAll)
        #expect(d.storyBossTuning.count == EnemyDefinition.baseStoryBossTuning.count)
        for (id, t) in EnemyDefinition.baseStoryBossTuning {
            #expect(d.storyBossTuning[id]?.hp == t.hp && d.storyBossTuning[id]?.damage == t.damage)
        }
        #expect(d.allParts == PartCatalog.baseNormalParts + PartCatalog.baseSpecialParts + PartCatalog.baseStoryBossParts)
        #expect(d.armorStyles == ArmorCatalog.baseStyles)
        #expect(d.mineralValues == Mineral.allCases.map(\.baseValue))
        #expect(d.mineralDropPercents == Mineral.allCases.map(\.baseDropPercent))
        #expect(d.mineralBuffs == Mineral.allCases.map(\.baseBuffPerUnit))
        #expect(d.roulette == Roulette.baseSegments)
        #expect(d.economy == EconomyValues.base)
        #expect(d.quests.map(\.reward) == ValdemarQuests.baseQuests.map(\.reward))
        let areas = [d.town] + d.interiors + d.fieldAreas
        let base = [Valdehierro.baseTown] + Valdehierro.baseInteriors + Valdemar.baseAreas
        #expect(areas.map(\.id) == base.map(\.id))
        for (a, b) in zip(areas, base) {
            #expect(a.level == b.level)
            #expect(a.zones.map(\.level) == b.zones.map(\.level))
            #expect(a.spawns.map(\.enemyID) == b.spawns.map(\.enemyID))
            #expect(a.npcs.map(\.reward.gold) == b.npcs.map(\.reward.gold))
        }
        #expect(d.dungeons.map(\.waves) == Valdemar.baseDungeons.map(\.waves))
        #expect(GameTuning().isEmpty)
    }

    /// Los números que lee el juego son los del código mientras no se aplique nada (las constantes de antes).
    @Test func defaultsMatchTheOldConstants() {
        let k = EconomyValues.base
        #expect(Arena.reward(wave: 1) == 16 + 7 && Arena.reward(wave: 10) == 86)
        #expect(Arena.wallWave == 20 && Arena.shopLevel(wave: 7) == 3)
        #expect(Leveling.xpToNext(1) == 80 && Leveling.xpToNext(10) == Int((50 * pow(10.0, 1.6)).rounded()) + 30)
        #expect(Leveling.arenaBossMultiplier == 12 && Leveling.storyBossMultiplier == 6 && Leveling.respawningMultiplier == 0.3)
        #expect(StoryEconomy.killGold(level: 9, isBoss: false) == 4 && StoryEconomy.killGold(level: 5, isBoss: true) == 52)
        #expect(StoryEconomy.zoneGold(level: 5) == 15)
        #expect(Mineral.dropRateMultiplier == 0.15 && Mineral.copper.value == 2 && Mineral.mithril.dropPercent == 0.5)
        #expect(Continent.familyWeights == [35, 27, 20, 12, 6])
        #expect(ShopGenerator.rerollCost(rerollsSoFar: 2) == 30)
        #expect(WeaponRecipe(headID: "head.sword.copper", guardID: "guard.straight.copper", gripID: "grip.short.oak").goldCost == 15)
        #expect(ArmorCatalog.style("chest.plate")?.forgePrice == 30 && ArmorCatalog.style("gloves.wraps")?.forgePrice == 16)
        #expect(k.potionHeal == 0.5 && k.arenaStartingGold == 50 && StoryDungeon.repeatPartChance == 0.25)
    }

    // MARK: Ajustes

    @Test func enemyTuningIsReflected() throws {
        let d = GameTuning.resolve(GameTuning(enemies: [
            "rat": EnemyTuning(hp: 50, damage: 4, attackCooldown: 1.1, level: 2, dropChance: 0.8, xpMultiplier: 2),
            "ogre": EnemyTuning(storyHPMultiplier: 2.5),
        ]))
        #expect(d.warnings.isEmpty)
        let rat = try #require(d.enemyByID["rat"])
        let baseRat = try #require(Bestiary.baseEnemy("rat"))
        #expect(rat.hp == 50 && rat.damage == 4 && rat.attackCooldown == 1.1 && rat.level == 2 && rat.dropChance == 0.8)
        #expect(rat.xpMultiplier == 2 && rat.speed == baseRat.speed && rat.name == baseRat.name)
        #expect(d.enemies.first { $0.id == "rat" }?.hp == 50)
        #expect(d.enemyByID["goblin"] == Bestiary.baseEnemy("goblin"))
        // El jefe: solo cambia la vida de la historia; el daño de la historia se queda como estaba.
        #expect(d.storyBossTuning["ogre"]?.hp == 2.5)
        #expect(d.storyBossTuning["ogre"]?.damage == EnemyDefinition.baseStoryBossTuning["ogre"]?.damage)
    }

    @Test func otherSectionsAreReflected() throws {
        let d = GameTuning.resolve(GameTuning(
            parts: ["head.sword.copper": PartTuning(stats: ["attack": 12, "critChance": 0.05], price: 40, tier: 2)],
            armor: ["chest.plate": ArmorTuning(stats: ["defense": 10], price: 35)],
            minerals: ["copper": MineralTuning(value: 3, dropWeight: 40, stats: ["attack": 3])],
            areas: ["inn": AreaTuning(level: 6)],
            zones: ["valdemar.huertos.molino": ZoneTuning(level: 7)],
            spawns: ["south.1": "goblin"],
            dungeons: ["valdemar.cripta": DungeonTuning(level: 9, bossEscort: ["ghoul": 3])],
            quests: ["valdemar.molino": RewardTuning(xp: 150, gold: 70, minerals: ["iron": 1])],
            rescues: ["marta": RewardTuning(gold: 99)],
            roulette: ["masterwork": RouletteTuning(weight: 8, multiplier: 2.2)],
            economy: {
                var e = EconomyTuning()
                e.arenaRewardBase = 20
                e.wallWave = 25
                e.continentLootWeights = [40, 25, 20, 10, 5]
                return e
            }()
        ))
        #expect(d.warnings.isEmpty)
        let sword = try #require(d.partByID["head.sword.copper"])
        #expect(sword.stats.attack == 12 && sword.stats.critChance == 0.05 && sword.price == 40 && sword.tier == 2)
        #expect(sword.stats.attackSpeed == PartCatalog.baseNormalParts.first { $0.id == sword.id }?.stats.attackSpeed)
        #expect(d.armorByID["chest.plate"]?.base.defense == 10 && d.armorByID["chest.plate"]?.forgePrice == 35)
        #expect(d.mineralValues[Mineral.copper.ordinal] == 3 && d.mineralDropPercents[0] == 40)
        #expect(d.mineralBuffs[0].attack == 3)
        #expect(d.interiors.first { $0.id == "inn" }?.level == 6)
        #expect(d.fieldAreas.flatMap(\.zones).first { $0.id == "valdemar.huertos.molino" }?.level == 7)
        #expect(d.town.spawns.first { $0.id == "south.1" }?.enemyID == "goblin")
        let crypt = try #require(d.dungeons.first { $0.id == "valdemar.cripta" })
        #expect(crypt.level == 9 && crypt.bossEscort == ["ghoul": 3] && crypt.waves == Valdemar.cripta.waves)
        let molino = try #require(d.quests.first { $0.id == "valdemar.molino" })
        #expect(molino.reward == QuestReward(xp: 150, gold: 70, minerals: [.iron: 1]))
        #expect(d.interiors.flatMap(\.npcs).first { $0.id == "marta" }?.reward.gold == 99)
        #expect(d.roulette.last?.weight == 8 && d.roulette.last?.multiplier == 2.2)
        #expect(d.economy.arenaRewardBase == 20 && d.economy.wallWave == 25)
        #expect(d.economy.continentLootWeights == [40, 25, 20, 10, 5])
    }

    // MARK: Validación

    @Test func unknownIDsAreIgnoredWithWarning() {
        let d = GameTuning.resolve(GameTuning(
            enemies: ["dragon": EnemyTuning(hp: 10)], parts: ["head.laser.copper": PartTuning(price: 1)],
            armor: ["helm.tin": ArmorTuning(price: 1)], minerals: ["kryptonite": MineralTuning(value: 1)],
            areas: ["luna": AreaTuning(level: 3)], zones: ["marte": ZoneTuning(level: 3)],
            spawns: ["south.99": "goblin", "south.2": "dragon"], dungeons: ["valdemar.sotano": DungeonTuning(level: 2)],
            quests: ["valdemar.inventada": RewardTuning(gold: 1)], rescues: ["nadie": RewardTuning(gold: 1)],
            roulette: ["divine": RouletteTuning(weight: 1)]
        ))
        for id in ["dragon", "head.laser.copper", "helm.tin", "kryptonite", "luna", "marte", "south.99", "valdemar.sotano",
                   "valdemar.inventada", "nadie", "divine"] {
            #expect(d.warnings.contains { $0.contains(id) }, "falta aviso de \(id)")
        }
        #expect(d.warnings.contains { $0.hasPrefix("spawns.south.2") })
        #expect(d.enemies == Bestiary.baseAll)
        #expect(d.town.spawns.map(\.enemyID) == Valdehierro.baseTown.spawns.map(\.enemyID))
    }

    @Test func outOfRangeValuesAreClamped() throws {
        var economy = EconomyTuning()
        economy.mineralDropRate = 99
        economy.wallWave = 2
        economy.continentLootWeights = [1, 2]
        let d = GameTuning.resolve(GameTuning(
            enemies: [
                "rat": EnemyTuning(hp: -5, attackCooldown: 0.1, attackRange: 200, level: 2.6, dropChance: 3),
                "goblinSlinger": EnemyTuning(attackRange: 10),
                "goblin": EnemyTuning(storyHPMultiplier: 2),
            ],
            parts: ["head.sword.copper": PartTuning(stats: ["attack": 9_999, "luck": 1], tier: 9)],
            economy: economy
        ))
        let rat = try #require(d.enemyByID["rat"])
        #expect(rat.hp == 1 && rat.attackCooldown == 0.8 && rat.attackRange == 40 && rat.level == 3 && rat.dropChance == 1)
        #expect(d.enemyByID["goblinSlinger"]?.attackRange == 60)
        #expect(d.storyBossTuning["goblin"] == nil)
        #expect(d.partByID["head.sword.copper"]?.stats.attack == 500 && d.partByID["head.sword.copper"]?.tier == 6)
        #expect(d.economy.mineralDropRate == 5 && d.economy.wallWave == 5)
        #expect(d.economy.continentLootWeights == EconomyValues.base.continentLootWeights)
        for key in ["rat.hp", "rat.attackCooldown", "rat.attackRange", "rat.level", "rat.dropChance", "goblinSlinger.attackRange",
                    "enemies.goblin", "stats.luck", "stats.attack", ".tier", "mineralDropRate", "wallWave", "continentLootWeights"] {
            #expect(d.warnings.contains { $0.contains(key) }, "falta aviso de \(key)")
        }
    }

    /// Una misión de "mata N de X en tal área" no se puede quedar sin esos monstruos; los jefes no se mueven.
    @Test func spawnChangesKeepQuestsAndBossesPlayable() throws {
        let huertos = try #require(Valdemar.baseAreas.first { $0.id == Valdemar.huertosID })
        let zombies = huertos.spawns.filter { $0.enemyID == "zombieFarmer" }.map(\.id)
        #expect(!zombies.isEmpty)
        var spawns = Dictionary(uniqueKeysWithValues: zombies.map { ($0, "goblin") })
        spawns["valdemar.huertos.1"] = "goblin"       // el Ogro
        spawns["south.1"] = "ogre"                    // un jefe en otro sitio
        spawns["valdemar.huertos.3"] = "ghoul"        // otro cambio de la misma área (se deshace con los zombis)
        let d = GameTuning.resolve(GameTuning(spawns: spawns))
        let tuned = try #require(d.fieldAreas.first { $0.id == Valdemar.huertosID })
        #expect(tuned.spawns.map(\.enemyID) == huertos.spawns.map(\.enemyID))
        #expect(d.town.spawns.first { $0.id == "south.1" }?.enemyID == "rat")
        #expect(d.warnings.contains { $0.contains("valdemar.molino") })
        #expect(d.warnings.filter { $0.contains("jefes") }.count == 2)
    }

    @Test func dungeonWavesAreValidated() throws {
        let bad = GameTuning.resolve(GameTuning(dungeons: [
            "valdemar.cripta": DungeonTuning(waves: [["skeleton": 3], ["abbot": 1]]),
            "valdemar.calabozos": DungeonTuning(waves: []),
        ]))
        #expect(bad.dungeons.map(\.waves) == Valdemar.baseDungeons.map(\.waves))
        #expect(bad.warnings.contains { $0.contains("abbot") } && bad.warnings.contains { $0.contains("calabozos.waves") })
        let good = GameTuning.resolve(GameTuning(dungeons: ["valdemar.calabozos": DungeonTuning(waves: [["orc": 50], ["troll": 2, "rat": 0]])]))
        #expect(good.dungeons.first { $0.id == "valdemar.calabozos" }?.waves == [["orc": 40], ["troll": 2]])
    }

    // MARK: JSON

    @Test func jsonRoundTrip() throws {
        var economy = EconomyTuning()
        economy.arenaStartingGold = 80
        economy.continentLootWeights = [30, 30, 20, 12, 8]
        let tuning = GameTuning(version: 12, note: "Ratas más duras", enemies: ["rat": EnemyTuning(hp: 20, level: 2)],
                                parts: ["boss.ogre.valdemar": PartTuning(stats: ["attack": 20])],
                                minerals: ["gold": MineralTuning(dropWeight: 12)], spawns: ["south.1": "goblin"],
                                dungeons: ["valdemar.cripta": DungeonTuning(waves: [["skeleton": 4]])],
                                quests: ["valdemar.molino": RewardTuning(minerals: [:])], economy: economy)
        let data = try JSONEncoder().encode(tuning)
        let back = try JSONDecoder().decode(GameTuning.self, from: data)
        #expect(back == tuning)
        #expect(back.decodingWarnings.isEmpty)
        // Vacío: `{}` es un documento válido (schemaVersion 1) y no cambia nada.
        let empty = try JSONDecoder().decode(GameTuning.self, from: Data("{}".utf8))
        #expect(empty.isEmpty && empty.schemaVersion == 1 && empty.decodingWarnings.isEmpty)
    }

    @Test func unknownJSONFieldsAreReported() throws {
        let json = """
        {"schemaVersion": 1, "enemigos": {}, "enemies": {"rat": {"hpp": 30, "hp": 20}},
         "parts": {"head.sword.copper": {"stats": {"atk": 3}}}, "economy": {"oroInicial": 10, "wallWave": 22}}
        """
        let tuning = try JSONDecoder().decode(GameTuning.self, from: Data(json.utf8))
        #expect(tuning.enemies?["rat"]?.hp == 20)
        #expect(tuning.economy?.wallWave == 22)
        let warnings = GameTuning.resolve(tuning).warnings
        for key in ["enemigos", "enemies.rat.hpp", "stats.atk", "economy.oroInicial"] {
            #expect(warnings.contains { $0.contains(key) }, "falta aviso de \(key)")
        }
    }

    /// El esquema (que valida y exporta `esquema.json`) cubre todos los campos de los tipos Codable.
    @Test func schemaCoversEveryCodableField() throws {
        func keys<T: Encodable>(_ value: T) throws -> Set<String> {
            let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any]
            return Set(object?.keys.map { $0 } ?? [])
        }
        let enemy = EnemyTuning(hp: 1, damage: 1, speed: 1, attackCooldown: 1, attackRange: 1, level: 1, dropChance: 1,
                                dropRolls: 1, xpMultiplier: 1, goldMultiplier: 1, storyHPMultiplier: 1, storyDamageMultiplier: 1)
        #expect(try keys(enemy) == Set(TuningSchema.enemy.map(\.key)))
        var economy = EconomyTuning()
        for entry in TuningSchema.economy { economy[keyPath: entry.tuning] = entry.base }
        economy.continentLootWeights = [1, 1, 1, 1, 1]
        let mirror = Mirror(reflecting: EconomyTuning()).children.compactMap(\.label)
        #expect(try keys(economy) == Set(mirror))
        #expect(Set(TuningSchema.economy.map(\.field.key)).count == TuningSchema.economy.count)
        #expect(TuningSchema.stats.count == StatKind.allCases.count)
        // Cada valor base está dentro de su rango.
        for entry in TuningSchema.economy {
            #expect(entry.field.min <= entry.base && entry.base <= entry.field.max, "\(entry.field.key)")
        }
        for e in Bestiary.baseAll {
            let fields = Dictionary(uniqueKeysWithValues: TuningSchema.enemy.map { ($0.key, $0) })
            for (key, v) in [("hp", e.hp), ("damage", e.damage), ("speed", e.speed), ("attackCooldown", e.attackCooldown),
                             ("level", Double(e.level)), ("dropChance", e.dropChance), ("dropRolls", Double(e.dropRolls))] {
                let f = try #require(fields[key])
                #expect(f.min <= v && v <= f.max, "\(e.id).\(key) = \(v)")
            }
            #expect(TuningSchema.rangeLimits(e.behavior).contains(e.attackRange), "\(e.id).attackRange")
        }
    }

    /// Los que instalan de verdad (estado global), de uno en uno para no pisarse.
    @Suite("Instalar ajustes", .serialized)
    struct Install {
        /// Con el documento vacío la arena saca las mismas oleadas (mismo orden del bestiario y mismas semillas).
        @Test func arenaWavesUnchangedWithEmptyTuning() {
            let before = (1...40).map { Arena.wave($0) }
            let warnings = GameTuning.apply(GameTuning())
            #expect(warnings.isEmpty)
            #expect((1...40).map { Arena.wave($0) } == before)
            #expect(GameTuning.resolve(GameTuning()).enemies.map(\.id) == Bestiary.all.map(\.id))
        }

        /// Instala de verdad (estado global) y vuelve a los valores de serie. Toca solo multiplicadores nuevos de un
        /// monstruo de continente, que no mira ningún otro test.
        @Test func applyInstallsAndRestores() throws {
            let base = try #require(Bestiary.enemy("eclipseAcolyte"))
            let gold = StoryEconomy.killGold(base, level: 7), xp = Leveling.storyXPForKill(base, level: 7, heroLevel: 7, respawns: false)
            let tuning = GameTuning(version: 3, enemies: ["eclipseAcolyte": EnemyTuning(xpMultiplier: 3, goldMultiplier: 2)])
            #expect(GameTuning.apply(tuning).isEmpty)
            #expect(GameTuning.current == tuning)
            let tuned = try #require(Bestiary.enemy("eclipseAcolyte"))
            #expect(tuned.goldMultiplier == 2 && tuned.xpMultiplier == 3)
            #expect(Bestiary.all.first { $0.id == "eclipseAcolyte" }?.goldMultiplier == 2)
            #expect(StoryEconomy.killGold(tuned, level: 7) == gold * 2)
            #expect(Leveling.storyXPForKill(tuned, level: 7, heroLevel: 7, respawns: false) == xp * 3)
            GameTuning.apply(GameTuning())
            #expect(Bestiary.enemy("eclipseAcolyte") == base)
            #expect(GameTuning.current.isEmpty)
        }
    }
}
