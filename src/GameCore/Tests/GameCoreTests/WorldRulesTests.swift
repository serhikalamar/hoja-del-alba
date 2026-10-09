import Foundation
import Testing
@testable import GameCore

/// Reglas del mundo (M1, M2, M4, M6, M9, M10) y mazmorras de historia (M8).
@Suite("Reglas del mundo")
struct WorldRulesTests {
    /// Área de campo de prueba (por si los datos del map-designer cambian): 12×8, salida al este, jefe y monstruos.
    static let testField: AreaMap = {
        let area = AreaMap(
            id: "prueba.campo", name: "Campo de prueba",
            rows: [
                "TTTTTTTTTTTT",
                "T..........T",
                "T..........T",
                "T..........>",
                "T..........>",
                "T..........T",
                "T..........T",
                "TTTTTTTTTTTT",
            ],
            buildings: [], zones: [Zone(id: "prueba.zona", name: "Prado", x: 0, y: 0, width: 12, height: 8, level: 5)],
            spawns: [Spawn(id: "prueba.1", enemyID: "wolf", position: TilePoint(3, 3)),
                     Spawn(id: "prueba.2", enemyID: "wolf", position: TilePoint(8, 5)),
                     Spawn(id: "prueba.3", enemyID: "ogre", position: TilePoint(5, 2))],
            npcs: [], level: 5, entry: TilePoint(10, 3), kind: .field,
            exits: [AreaExit(id: "prueba.este", tiles: [TilePoint(11, 3), TilePoint(11, 4)], toArea: Valdehierro.townID,
                             arrival: Valdehierro.town.entry, lock: .questDone(ValdemarQuests.molino),
                             lockedMessage: "Cerrado")],
            safePoint: TilePoint(2, 6)
        )
        return area
    }()

    // MARK: Viajar (M1)

    @Test func lockedExitsShowTheirMessageAndOpenExitsTravel() {
        var p = PlayerProfile.newGame()
        let area = Self.testField
        let exit = area.exits[0]
        #expect(p.travel(through: exit, from: area) == .blocked("Cerrado"))
        #expect(p.lockedTiles(in: area)[TilePoint(11, 3)] == "Cerrado")
        p.quests = [ValdemarQuests.molino: QuestState(accepted: true, progress: [6, 1], done: true)]
        #expect(p.travel(through: exit, from: area) == .travel(areaID: Valdehierro.townID, arrival: Valdehierro.town.entry))
        #expect(p.lockedTiles(in: area)[TilePoint(11, 3)] == nil)
    }

    @Test func comingSoonIsAlwaysClosed() {
        let exit = AreaExit(id: "x.norte", tiles: [TilePoint(1, 0)], toArea: "rocaforja", arrival: nil, lock: .comingSoon("rocaforja"))
        var p = PlayerProfile.newGame()
        p.quests = Dictionary(uniqueKeysWithValues: World.quests.map { ($0.id, QuestState(accepted: true, done: true)) })
        guard case .blocked(let message) = p.travel(through: exit, from: Self.testField) else {
            Issue.record("debería estar cerrada"); return
        }
        #expect(message.contains("próximamente"))
    }

    @Test func townWestExitNeedsTheWestQuarterLiberated() throws {
        let town = Valdehierro.town
        guard let west = town.exits.first(where: { $0.id == "town.oeste" }) else { return }
        var p = PlayerProfile.newGame()
        guard case .blocked = p.travel(through: west, from: town) else { Issue.record("abierta sin liberar"); return }
        let zone = try #require(town.zones.first { $0.id == "west" })
        var progress = p.town
        progress.killedSpawns.formUnion(town.spawns.filter { zone.contains($0.position) }.map(\.id))
        p.town = progress
        guard case .travel(let areaID, let arrival) = p.travel(through: west, from: town) else {
            Issue.record("no se abre al liberar el barrio oeste"); return
        }
        #expect(World.area(areaID)?.isWalkable(arrival) == true)
    }

    @Test func everyOpenExitInTheWorldLeadsSomewhereWalkable() {
        var p = PlayerProfile.newGame()
        p.quests = Dictionary(uniqueKeysWithValues: World.quests.map { ($0.id, QuestState(accepted: true, done: true)) })
        var town = p.town
        town.killedSpawns = Set(World.areas.flatMap(\.spawns).map(\.id))
        p.town = town
        for area in World.areas {
            for exit in area.exits {
                switch p.travel(through: exit, from: area) {
                case .travel(let id, let tile):
                    #expect(World.area(id)?.isWalkable(tile) == true, "\(exit.id)")
                case .blocked:
                    if case .comingSoon = exit.lock { continue }
                    Issue.record("\(exit.id) sigue cerrada con todo hecho")
                }
            }
        }
    }

    // MARK: Puertas y escalinata (M4)

    @Test func stairsAndCastleDoorWaitForTheCastleCondition() {
        let town = Valdehierro.town
        var p = PlayerProfile.newGame()
        let stairs = town.tiles(of: .stairs)
        #expect(!stairs.isEmpty)
        let locked = p.lockedTiles(in: town)
        for tile in stairs { #expect(locked[tile] != nil) }
        if let castle = town.buildings.first(where: { $0.id == "castle" }) {
            #expect(p.doorLockMessage(castle)?.contains("castillo") == true)
        }
        p.quests = Dictionary(uniqueKeysWithValues: [ValdemarQuests.liberar, ValdemarQuests.abadia, ValdemarQuests.pedregal]
            .map { ($0, QuestState(accepted: true, done: true)) })
        let open = p.lockedTiles(in: town)
        for tile in stairs { #expect(open[tile] == nil) }
        if let castle = town.buildings.first(where: { $0.id == "castle" }) { #expect(p.doorLockMessage(castle) == nil) }
    }

    @Test func mayorHouseOpensWithHilos() throws {
        let mayor = try #require(Valdehierro.town.buildings.first { $0.id == "mayor" })
        var p = PlayerProfile.newGame()
        #expect(p.doorLockMessage(mayor) != nil)
        guard mayor.interiorID != nil else { return } // el map-designer aún no lo ha abierto
        p.quests = [ValdemarQuests.hilos: QuestState(accepted: true, done: true)]
        #expect(p.doorLockMessage(mayor) == nil)
    }

    @Test func npcsWithAConditionOnlyAppearWhenItIsMet() {
        let captain = NPC(id: "c", name: "C", look: "guardCaptain", role: .questGiver, position: TilePoint(1, 1), plea: "",
                          thanks: [], reward: Reward(), appearsWhen: .questDone(ValdemarQuests.liberar))
        var area = Self.testField
        area = AreaMap(id: area.id, name: area.name, rows: area.rows, buildings: [], zones: area.zones, spawns: [],
                       npcs: [captain], level: 5, entry: area.entry, kind: .field)
        var p = PlayerProfile.newGame()
        #expect(p.visibleNPCs(in: area).isEmpty)
        p.quests = [ValdemarQuests.liberar: QuestState(accepted: true, done: true)]
        #expect(p.visibleNPCs(in: area).map(\.id) == ["c"])
    }

    // MARK: Reaparecer (M2, M9)

    @Test func fieldMonstersRespawnButBossesDoNot() {
        let area = Self.testField
        #expect(!area.isPermanent(area.spawns[0]))
        #expect(area.isPermanent(area.spawns[2]), "el Ogro es jefe")
        for spawn in Valdehierro.town.spawns { #expect(Valdehierro.town.isPermanent(spawn)) }

        var respawn = FieldRespawn()
        respawn.died("prueba.1", at: 10)
        respawn.died("prueba.2", at: 10)
        let early = respawn.due(in: area, now: 50, hero: TilePoint(10, 6))
        #expect(early.isEmpty, "antes de 90 s")
        // A los 90 s, pero el héroe está a menos de 10 casillas (el área es pequeña).
        let near = respawn.due(in: area, now: 100, hero: TilePoint(8, 5))
        #expect(near.isEmpty, "el héroe está demasiado cerca")
        respawn.reset()
        #expect(respawn.deadIDs.isEmpty)

        let far = AreaMap(id: "lejos", name: "Lejos", rows: Array(repeating: String(repeating: ".", count: 40), count: 5),
                          buildings: [], zones: [], spawns: [Spawn(id: "l.1", enemyID: "wolf", position: TilePoint(1, 2))],
                          npcs: [], level: 1, entry: TilePoint(0, 0), kind: .field)
        respawn.died("l.1", at: 0)
        let notYet = respawn.due(in: far, now: 89, hero: TilePoint(30, 2))
        #expect(notYet.isEmpty)
        let back = respawn.due(in: far, now: 91, hero: TilePoint(30, 2))
        #expect(back.map(\.id) == ["l.1"])
        #expect(respawn.deadIDs.isEmpty)
    }

    @Test func fieldZoneIsLiberatedOnlyTheFirstTime() {
        let area = Self.testField
        var p = PlayerProfile.newGame()
        var progress = p.town
        progress.killedSpawns.insert("prueba.3") // el jefe, permanente
        p.town = progress
        let first = p.noteFieldKill(at: TilePoint(3, 3), in: area, dead: ["prueba.1"])
        #expect(first == nil)
        let second = p.noteFieldKill(at: TilePoint(8, 5), in: area, dead: ["prueba.1", "prueba.2"])
        #expect(second?.id == "prueba.zona")
        #expect(p.isLiberated(area.zones[0], in: area))
        let third = p.noteFieldKill(at: TilePoint(8, 5), in: area, dead: ["prueba.1", "prueba.2"])
        #expect(third == nil, "solo una vez")
    }

    @Test func respawnPoints() {
        for area in World.areas where area.isField {
            let point = World.respawnPoint(afterDyingIn: area.id)
            #expect(point.areaID == area.id)
            #expect(point.tile == (area.safePoint ?? area.entry))
        }
        let inTown = World.respawnPoint(afterDyingIn: "bakery")
        #expect(inTown.areaID == Valdehierro.townID && inTown.tile == Valdehierro.town.entry)
        for dungeon in World.storyDungeons {
            let point = World.respawnPoint(afterDyingIn: dungeon.id)
            #expect(point.areaID == World.respawnPoint(afterDyingIn: dungeon.entranceAreaID).areaID)
        }
        let outside = World.outside(of: "bakery")
        let bakery = Valdehierro.building(leadingTo: "bakery")!
        #expect(outside?.areaID == Valdehierro.townID)
        #expect(outside?.tile == TilePoint(bakery.doorX, bakery.y + bakery.height))
    }

    @Test func travelIsRemembered() {
        var p = PlayerProfile.newGame()
        #expect(p.areaID == Valdehierro.townID)
        p.arrive(at: "valdemar.huertos")
        p.arrive(at: Valdehierro.townID)
        #expect(p.areaID == Valdehierro.townID)
        #expect(p.visitedAreaIDs == ["valdemar.huertos", Valdehierro.townID])
    }

    // MARK: Cartel del área (M10)

    @Test func areaBanner() {
        #expect(Self.testField.banner == "Campo de prueba · 5")
        let bakery = Valdehierro.area("bakery")!
        #expect(bakery.banner == "Panadería · \(bakery.level)")
        if let robleda = World.area("valdemar.robleda") {
            #expect(robleda.banner == "Bosque de Robleda · 6-7")
        }
    }

    // MARK: Botín y forja (M6)

    @Test func storyLootOnlyDropsTheContinentFamily() throws {
        let valdemar = try #require(World.continent(World.valdemarID))
        #expect(valdemar.lootTable.map(\.1) == [35, 27, 20, 12, 6])
        var rng = SeededGenerator(seed: 7)
        var counts: [Mineral: Int] = [:]
        let samples = 50_000
        for _ in 0..<samples { counts[valdemar.rollMineral(using: &rng), default: 0] += 1 }
        #expect(Set(counts.keys).isSubset(of: Set(valdemar.minerals)))
        for (mineral, weight) in valdemar.lootTable {
            let observed = Double(counts[mineral, default: 0]) / Double(samples) * 100
            #expect(abs(observed - weight) < 1, "\(mineral) \(observed)")
        }
        let boss = try #require(Bestiary.enemy("ogre")).stats(level: 6)
        for _ in 0..<50 {
            for mineral in boss.rollDrops(in: valdemar, using: &rng) { #expect(valdemar.minerals.contains(mineral)) }
        }
        #expect(!boss.rollDrops(in: valdemar, using: &rng).isEmpty, "los jefes siempre sueltan algo")
    }

    @Test func mineralTiersAreExplicit() {
        #expect(Mineral.allCases.map(\.rarityTier) == Array(1...10))
        #expect(Mineral.allCases.map(\.value) == [2, 3, 5, 8, 12, 16, 24, 32, 50, 80])
    }

    @Test func storyForgeSellsTheContinentTier() {
        var p = PlayerProfile.newGame()
        #expect(p.storyForgeTier == 1)
        var rng = SeededGenerator(seed: 3)
        for _ in 0..<20 {
            let offers = ShopGenerator.offers(level: 10, maxTier: p.storyForgeTier, using: &rng)
            #expect(offers.compactMap(\.part).allSatisfy { $0.tier == 1 })
            #expect(offers.compactMap(\.part).count == ShopGenerator.partOfferCount)
        }
        p.quests = [ValdemarQuests.reyGoblin: QuestState(accepted: true, done: true)]
        #expect(p.storyForgeTier == 2)
        let offers = ShopGenerator.offers(level: 1, maxTier: 2, using: &rng)
        #expect(offers.compactMap(\.part).allSatisfy { $0.tier <= 2 })
    }

    @Test func storyBossXPUsesItsOwnMultiplier() {
        let normal = Leveling.xpForKill(enemyLevel: 6, heroLevel: 6, isBoss: false)
        #expect(Leveling.xpForKill(enemyLevel: 6, heroLevel: 6, isBoss: true) == Int((Double(normal) * Leveling.arenaBossMultiplier).rounded()))
        #expect(Leveling.xpForKill(enemyLevel: 6, heroLevel: 6, isBoss: true, bossMultiplier: 6) == normal * 6)
    }

    // MARK: Mazmorras de historia (M8)

    @Test func storyDungeonWaves() {
        let dungeon = StoryDungeon(id: "prueba.cripta", name: "Cripta", floorID: "crypt", level: 8,
                                   waves: [["skeleton": 3], ["ghoul": 2, "wraith": 1]],
                                   bossID: "abbot", bossEscort: ["skeleton": 2], entranceAreaID: "valdemar.abadia")
        #expect(dungeon.floor?.id == "crypt")
        #expect(dungeon.totalWaves == 3)
        #expect(dungeon.wave(1).spawns == ["skeleton": 3])
        #expect(dungeon.wave(2).totalMonsters == 3)
        #expect(!dungeon.isBossWave(2) && dungeon.isBossWave(3))
        #expect(dungeon.wave(3).spawns == ["skeleton": 2, "abbot": 1])
        var rng = SeededGenerator(seed: 1)
        #expect(dungeon.wave(3).spawnOrder(using: &rng).last == "abbot", "el jefe sale el último")
        #expect(dungeon.bossDropsPart(firstWin: true, using: &rng))
        let drops = (0..<2000).filter { _ in dungeon.bossDropsPart(firstWin: false, using: &rng) }.count
        #expect(abs(Double(drops) / 2000 - StoryDungeon.repeatPartChance) < 0.05)

        let noBoss = StoryDungeon(id: "x", name: "X", floorID: "prison", level: 9, waves: [["orc": 1]], entranceAreaID: "town")
        #expect(noBoss.totalWaves == 1 && !noBoss.isBossWave(1))
    }

    @Test func winningADungeonCountsForItsQuest() {
        var p = PlayerProfile.newGame()
        let firstWin = p.winDungeon("valdemar.calabozos")
        let secondWin = p.winDungeon("valdemar.calabozos")
        #expect(firstWin)
        #expect(!secondWin, "la segunda vez ya no es la primera")
        p.quests = Dictionary(uniqueKeysWithValues: [ValdemarQuests.liberar, ValdemarQuests.abadia, ValdemarQuests.pedregal]
            .map { ($0, QuestState(accepted: true, done: true)) })
        p.accept(ValdemarQuests.calabozos)
        #expect(p.isComplete(World.quest(ValdemarQuests.calabozos)!))
        #expect(p.conversation(with: ValdemarQuests.captainID).contains(.deliver(ValdemarQuests.calabozos)))
    }
}
