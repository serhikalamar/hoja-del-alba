import Foundation
import Testing
@testable import GameCore

/// Contrato de datos del mundo (fase 0): coherencia de áreas, salidas, mazmorras y misiones registradas en `World`.
/// Con los datos de la fase 1 (map-designer, misiones) estos tests empiezan a vigilarlos sin cambios.
@Suite("Mundo: contrato de datos")
struct WorldTests {
    // MARK: Casillas y edificios

    @Test func newOutdoorTilesParseWithTheRightSolidity() {
        let walkable: [Character] = ["d", "%", "p", "e", ">"]
        let solid: [Character] = ["R", "^", "+", "n", "x"]
        for c in walkable {
            let tile = Tile(rawValue: c)
            #expect(tile != nil, "\(c) no es una casilla")
            #expect(tile?.isSolid == false, "\(c) debería pisarse")
        }
        for c in solid {
            let tile = Tile(rawValue: c)
            #expect(tile != nil, "\(c) no es una casilla")
            #expect(tile?.isSolid == true, "\(c) debería ser sólida")
        }
        #expect(Set(Tile.allCases.map(\.rawValue)).count == Tile.allCases.count)
    }

    @Test func newBuildingStylesHavePlaceholders() {
        let expected: [BuildingStyle: BuildingStyle] = [
            .ruinedMill: .mill, .burnedFarm: .house, .abbeyChurch: .chapel, .rangerHut: .house, .watchtower: .house,
        ]
        for (style, drawn) in expected { #expect(style.placeholder == drawn, "\(style)") }
        for style in [BuildingStyle.house, .bakery, .inn, .smithy, .chapel, .mill, .alchemist, .castle] {
            #expect(style.placeholder == style)
        }
    }

    // MARK: Áreas

    @Test func existingAreasKeepTheirKind() {
        #expect(Valdehierro.town.kind == .town)
        #expect(!Valdehierro.town.isInterior)
        for interior in Valdehierro.interiors {
            #expect(interior.kind == .interior, "\(interior.id)")
            #expect(interior.isInterior)
        }
        for area in Valdehierro.areas {
            #expect(area.biome == .valdemar)
            #expect(area.continentID == World.valdemarID)
        }
    }

    @Test func areaIDsAreUniqueAndRegistered() {
        let ids = World.areas.map(\.id)
        #expect(Set(ids).count == ids.count, "ids de área repetidos")
        for area in Valdehierro.areas {
            #expect(World.area(area.id)?.id == area.id, "\(area.id) no está en World")
        }
        #expect(World.area(Valdehierro.townID)?.kind == .town)
        #expect(World.area("no-existe") == nil)
    }

    @Test func fieldAreasAreWellFormed() {
        for area in World.areas where area.isField {
            #expect(Set(area.rows.map(\.count)).count == 1, "filas desiguales en \(area.id)")
            let entryOK = area.isWalkable(area.entry)
            #expect(entryOK, "entrada de \(area.id)")
            if let safe = area.safePoint {
                let safeOK = area.isWalkable(safe)
                #expect(safeOK, "punto seguro de \(area.id)")
            }
            for spawn in area.spawns {
                let spawnOK = area.isWalkable(spawn.position)
                #expect(spawnOK, "\(spawn.id) en \(area.id)")
                #expect(Bestiary.enemy(spawn.enemyID) != nil, "\(spawn.enemyID)")
            }
        }
    }

    // MARK: Salidas y bajadas

    @Test func exitIDsAreUnique() {
        let ids = World.areas.flatMap(\.exits).map(\.id)
        #expect(Set(ids).count == ids.count, "ids de salida repetidos")
    }

    @Test func exitsLeadToRealAreasWithWalkableArrivals() {
        for area in World.areas {
            for exit in area.exits {
                #expect(!exit.tiles.isEmpty, "\(exit.id) sin casillas")
                for tile in exit.tiles {
                    #expect(area.tile(tile.x, tile.y) == .areaExit, "\(exit.id): (\(tile.x),\(tile.y)) no es `>`")
                }
                if case .comingSoon = exit.lock {
                    // Lleva a un continente que aún no existe: no hay área de destino.
                    continue
                }
                guard let destination = World.area(exit.toArea) else {
                    Issue.record("\(exit.id) lleva a \(exit.toArea), que no existe")
                    continue
                }
                if let arrival = exit.arrival {
                    let walkable = destination.isWalkable(arrival)
                    let onAnotherExit = destination.exit(at: arrival) != nil
                    #expect(walkable, "\(exit.id): llegada no pisable en \(destination.id)")
                    #expect(!onAnotherExit, "\(exit.id): llega encima de otra salida")
                } else {
                    Issue.record("\(exit.id) sin casilla de llegada")
                }
            }
            // Ninguna `>` suelta: toda casilla de salida pertenece a un `AreaExit`.
            for tile in area.tiles(of: .areaExit) {
                #expect(area.exit(at: tile) != nil, "\(area.id): `>` en (\(tile.x),\(tile.y)) sin AreaExit")
            }
        }
    }

    @Test func exitLocksPointToThingsThatExist() {
        for area in World.areas {
            let locks = area.exits.compactMap(\.lock) + area.dungeonEntrances.compactMap(\.lock)
            for lock in locks {
                switch lock {
                case .zoneLiberated(let zone):
                    #expect(area.zones.contains { $0.id == zone }, "\(area.id): zona \(zone) no existe")
                case .questDone(let quest):
                    // Las misiones llegan en la fase 1: solo se comprueban cuando ya hay alguna registrada.
                    if !World.quests.isEmpty { #expect(World.quest(quest) != nil, "misión \(quest) no existe") }
                case .castleOpen, .comingSoon:
                    break
                }
            }
        }
    }

    @Test func dungeonEntrancesAreCoherent() {
        for area in World.areas {
            for entrance in area.dungeonEntrances {
                #expect(!entrance.tiles.isEmpty)
                for tile in entrance.tiles {
                    #expect(area.tile(tile.x, tile.y) == .cave, "\(entrance.dungeonID): (\(tile.x),\(tile.y)) no es `e`")
                }
                guard let dungeon = World.storyDungeon(entrance.dungeonID) else {
                    Issue.record("\(area.id): la mazmorra \(entrance.dungeonID) no existe")
                    continue
                }
                #expect(dungeon.entranceAreaID == area.id, "\(dungeon.id) dice que se entra desde \(dungeon.entranceAreaID)")
            }
        }
    }

    // MARK: Mazmorras de historia

    @Test func storyDungeonsUseRealFloorsAndEnemies() {
        let ids = World.storyDungeons.map(\.id)
        #expect(Set(ids).count == ids.count)
        for dungeon in World.storyDungeons {
            #expect(Dungeon.floor(dungeon.floorID) != nil, "\(dungeon.id): piso \(dungeon.floorID)")
            #expect(!dungeon.waves.isEmpty, "\(dungeon.id) sin oleadas")
            #expect(World.area(dungeon.entranceAreaID) != nil, "\(dungeon.id): área de entrada")
            for enemy in dungeon.enemyIDs { #expect(Bestiary.enemy(enemy) != nil, "\(dungeon.id): \(enemy)") }
            let hasEntrance = World.areas.contains { $0.dungeonEntrances.contains { $0.dungeonID == dungeon.id } }
            #expect(hasEntrance, "\(dungeon.id) no tiene bajada `e`")
        }
    }

    @Test func storyDungeonListsAllItsEnemies() {
        let dungeon = StoryDungeon(id: "prueba", name: "Prueba", floorID: "crypt", level: 8,
                                   waves: [["skeleton": 5], ["ghoul": 3]], bossID: "abbot",
                                   bossEscort: ["skeleton": 2], entranceAreaID: Valdehierro.townID)
        #expect(dungeon.enemyIDs == ["skeleton", "ghoul", "abbot"])
        #expect(dungeon.repeatable)
    }

    // MARK: Continentes

    @Test func continentsAreCoherent() {
        let valdemar = World.continent(World.valdemarID)
        #expect(valdemar != nil)
        #expect(valdemar?.levels == 1...10)
        #expect(valdemar?.capitalID == Valdehierro.townID)
        #expect(valdemar?.tier == 1)
        #expect(valdemar?.minerals == [.copper, .iron, .silver, .gold, .emerald])
        for continent in World.continents {
            #expect(continent.areaIDs.contains(continent.capitalID), "\(continent.id): capital fuera de sus áreas")
            for id in continent.areaIDs {
                #expect(World.area(id)?.continentID == continent.id, "\(id) no pertenece a \(continent.id)")
            }
        }
        // Cada área está en exactamente un continente.
        for area in World.areas {
            let owners = World.continents.filter { $0.areaIDs.contains(area.id) }
            #expect(owners.count == 1, "\(area.id) está en \(owners.count) continentes")
        }
    }

    // MARK: Misiones

    @Test func questsReferenceThingsThatExist() {
        let ids = World.quests.map(\.id)
        #expect(Set(ids).count == ids.count)
        for quest in World.quests {
            #expect(!quest.objectives.isEmpty, "\(quest.id) sin objetivos")
            for enemy in quest.enemyIDs { #expect(Bestiary.enemy(enemy) != nil, "\(quest.id): \(enemy)") }
            for area in quest.areaIDs { #expect(World.area(area) != nil, "\(quest.id): área \(area)") }
            for objective in quest.objectives {
                if case .dungeon(let id) = objective { #expect(World.storyDungeon(id) != nil, "\(quest.id): \(id)") }
                if case .kill(_, let count, _) = objective { #expect(count > 0, "\(quest.id)") }
            }
            for condition in quest.requires {
                if case .questDone(let other) = condition { #expect(World.quest(other) != nil, "\(quest.id) pide \(other)") }
            }
        }
    }

    @Test func questHelpersCollectEnemiesAndAreas() {
        let quest = Quest(id: "valdemar.prueba", giverID: "tomas", title: "Prueba", summary: "—",
                          requires: [.rescued("tomas")],
                          objectives: [.kill(enemyIDs: ["zombieFarmer"], count: 6, areaID: "valdemar.huertos"),
                                       .defeat(enemyID: "ogre"), .clear(areaID: "mayor"), .talk(npcID: "tomas")],
                          reward: QuestReward(xp: 182, gold: 120, minerals: [.silver: 2]))
        #expect(quest.enemyIDs == ["zombieFarmer", "ogre"])
        #expect(quest.areaIDs == ["valdemar.huertos", "mayor"])
        #expect(!quest.autoAccept && !quest.completesOnLastObjective)
    }
}

@Suite("Perfil: campos del modo historia")
struct StoryProfileTests {
    /// Partida guardada de la v0.5: sin `currentAreaID`, `quests` ni `visitedAreaIDs`.
    static let legacyJSON = """
    {
      "race": "elf",
      "hasChosenRace": true,
      "gold": 250,
      "minerals": ["copper", 4, "silver", 1],
      "parts": {"head.sword.copper": 1},
      "inventory": [],
      "highestUnlockedLevel": 3,
      "completedLevels": [1, 2],
      "discoveredAbilities": [],
      "defeatedBosses": ["ratKing"],
      "arenaBestWave": 7,
      "level": 4,
      "xp": 30,
      "townProgress": {"killedSpawns": ["south.1", "bakery.4"], "rescued": ["marta"], "princessRescued": false}
    }
    """

    @Test func legacySaveDecodesWithEmptyStoryFields() throws {
        let profile = try JSONDecoder().decode(PlayerProfile.self, from: Data(Self.legacyJSON.utf8))
        #expect(profile.race == .elf)
        #expect(profile.gold == 250)
        #expect(profile.count(of: .copper) == 4)
        #expect(profile.town.rescued == ["marta"])
        #expect(profile.town.killedSpawns.contains("bakery.4"))
        #expect(profile.currentAreaID == nil)
        #expect(profile.quests == nil)
        #expect(profile.visitedAreaIDs == nil)
        #expect(profile.areaID == Valdehierro.townID)
        #expect(profile.continentID == World.valdemarID)
        #expect(profile.questState("valdemar.liberar") == QuestState())
        #expect(!profile.isQuestDone("valdemar.liberar"))
    }

    @Test func newGameDoesNotWriteStoryFields() throws {
        let data = try JSONEncoder().encode(PlayerProfile.newGame())
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["currentAreaID"] == nil)
        #expect(json?["quests"] == nil)
        #expect(json?["visitedAreaIDs"] == nil)
    }

    @Test func storyFieldsRoundTrip() throws {
        var profile = PlayerProfile.newGame()
        profile.currentAreaID = "bakery"
        profile.quests = ["valdemar.liberar": QuestState(accepted: true, progress: [6], done: true),
                          "valdemar.molino": QuestState(accepted: true, progress: [3, 0])]
        profile.visitedAreaIDs = [Valdehierro.townID, "bakery"]
        let copy = try JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(profile))
        #expect(copy == profile)
        #expect(copy.areaID == "bakery")
        #expect(copy.isQuestDone("valdemar.liberar"))
        #expect(copy.questState("valdemar.molino").progress == [3, 0])
        #expect(!copy.isQuestDone("valdemar.molino"))
    }
}
