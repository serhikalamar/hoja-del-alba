import Foundation
import Testing
@testable import GameCore

/// Motor de misiones (M3) y condición del castillo (M4) con las misiones de Valdemar.
@Suite("Misiones")
struct QuestTests {
    static let villagers = ["marta", "elena", "tomas", "anselmo", "bruno", "iris"]

    /// Perfil con estos aldeanos rescatados y la historia al día.
    func profile(rescued: [String] = [], done: [String] = []) -> PlayerProfile {
        var p = PlayerProfile.newGame()
        var town = p.town
        town.rescued = Set(rescued)
        p.town = town
        for id in done {
            var all = p.quests ?? [:]
            all[id] = QuestState(accepted: true, progress: World.quest(id)!.objectives.map(\.target), done: true)
            p.quests = all
        }
        p.syncStory()
        return p
    }

    func spawnID(_ enemyID: String) -> String? {
        World.areas.flatMap(\.spawns).first { $0.enemyID == enemyID }?.id
    }

    // MARK: Datos

    @Test func valdemarHasElevenQuestsWithUniqueIDs() {
        let ids = ValdemarQuests.all.map(\.id)
        #expect(ids.count == 11)
        #expect(Set(ids).count == ids.count)
        for id in ids { #expect(id.hasPrefix("valdemar."), "\(id)") }
    }

    @Test func questDataPointsToThingsThatExist() {
        for quest in World.quests {
            for npc in quest.npcIDs where npc != ValdemarQuests.smithID {
                #expect(World.npc(npc) != nil, "\(quest.id): NPC \(npc) no existe")
            }
            for enemy in quest.enemyIDs { #expect(Bestiary.enemy(enemy) != nil, "\(quest.id): \(enemy)") }
            for area in quest.areaIDs { #expect(World.area(area) != nil, "\(quest.id): área \(area)") }
            for dungeon in quest.dungeonIDs { #expect(World.storyDungeon(dungeon) != nil, "\(quest.id): \(dungeon)") }
            for case .questDone(let id) in quest.requires { #expect(World.quest(id) != nil, "\(quest.id) pide \(id)") }
            #expect(quest.objectiveLabels.count <= quest.objectives.count, "\(quest.id): sobran textos de HUD")
            #expect(!quest.title.isEmpty && !quest.summary.isEmpty)
        }
    }

    // MARK: Liberar el pueblo

    @Test func liberarIsAcceptedAloneAndDeliveredWhenAllSixAreSafe() {
        var p = profile()
        #expect(p.isActive(World.quest(ValdemarQuests.liberar)!))
        #expect(p.trackedQuest?.id == ValdemarQuests.liberar)
        #expect(p.trackerText(p.trackedQuest!) == "Rescata a los aldeanos: 0/6")

        var town = p.town
        town.rescued = Set(Self.villagers.dropLast())
        p.town = town
        let r1 = p.syncStory()
        #expect(r1.delivered.isEmpty)
        #expect(p.trackerText(p.trackedQuest!) == "Rescata a los aldeanos: 5/6")

        let xp = p.levelXP, level = p.characterLevel, gold = p.gold
        town.rescued.insert("iris")
        p.town = town
        let update = p.syncStory()
        #expect(update.delivered.map(\.questID) == [ValdemarQuests.liberar])
        #expect(p.isQuestDone(ValdemarQuests.liberar))
        #expect(p.characterLevel > level || p.levelXP > xp)
        #expect(p.gold > gold)
        // Ya no abre el castillo: aparece el Capitán con su misión.
        #expect(!p.isCastleOpen())
        #expect(p.marker(for: ValdemarQuests.captainID) == .offer)
    }

    // MARK: Matar y derrotar

    @Test func killCountsOnlyAfterAcceptingAndInItsArea() throws {
        var p = profile(rescued: ["tomas"])
        let molino = try #require(World.quest(ValdemarQuests.molino))
        #expect(p.marker(for: "tomas") == .offer)
        #expect(p.conversation(with: "tomas") == [.offer(molino.id)])

        p.record(.killed(enemyID: "zombieFarmer", areaID: "valdemar.huertos"))
        #expect(p.questState(molino.id).progress.isEmpty, "antes de aceptar no cuenta")

        let r2 = p.accept(molino.id)
        #expect(r2)
        let r3 = p.accept(molino.id)
        #expect(!r3, "no se acepta dos veces")
        p.record(.killed(enemyID: "zombieFarmer", areaID: Valdehierro.townID))
        #expect(p.progress(of: molino)[0] == 0, "fuera de su área no cuenta")
        for _ in 0..<9 { p.record(.killed(enemyID: "zombieFarmer", areaID: "valdemar.huertos")) }
        #expect(p.progress(of: molino)[0] == 6, "no pasa del objetivo")
        #expect(!p.isComplete(molino))
        #expect(p.marker(for: "tomas") == nil)
        #expect(p.conversation(with: "tomas") == [.remind(molino.id)])
    }

    @Test func defeatCountsEvenIfTheBossDiedBeforeAccepting() throws {
        var p = profile(rescued: ["tomas"])
        let molino = try #require(World.quest(ValdemarQuests.molino))
        // El Ogro murió antes de aceptar la misión (es permanente: queda en `killedSpawns`).
        if let ogre = spawnID("ogre") {
            var town = p.town
            town.killedSpawns.insert(ogre)
            p.town = town
        } else {
            p.record(.killed(enemyID: "ogre", areaID: "valdemar.huertos"))
        }
        p.accept(molino.id)
        for _ in 0..<6 { p.record(.killed(enemyID: "zombieFarmer", areaID: "valdemar.huertos")) }
        if spawnID("ogre") == nil { p.record(.killed(enemyID: "ogre", areaID: "valdemar.huertos")) }
        #expect(p.isComplete(molino))
        #expect(p.marker(for: "tomas") == .turnIn)
        #expect(p.conversation(with: "tomas") == [.deliver(molino.id)])

        let silver = p.count(of: .silver)
        let r4 = p.deliver(molino.id)
        let delivery = try #require(r4)
        #expect(delivery.xp == molino.reward.xp)
        #expect(p.count(of: .silver) == silver + (molino.reward.minerals[.silver] ?? 0))
        #expect(p.isQuestDone(molino.id))
        let r5 = p.deliver(molino.id)
        #expect(r5 == nil, "no se entrega dos veces")
        #expect(p.marker(for: "tomas") == nil)
        #expect(p.finishedQuests.contains { $0.id == molino.id })
    }

    @Test func defeatedBossesFromTheArenaDoNotCount() {
        var p = profile(rescued: ["tomas"])
        p.defeatedBosses = ["ogre", "goblinKing", "abbot", "warlord"]
        p.accept(ValdemarQuests.molino)
        #expect(p.progress(of: World.quest(ValdemarQuests.molino)!)[1] == 0)
        #expect(!p.isCastleOpen())
    }

    @Test func slimesCountInAnyAreaAndInDungeons() throws {
        var p = profile(rescued: ["iris"])
        let pociones = try #require(World.quest(ValdemarQuests.pociones))
        p.accept(pociones.id)
        p.record(.killed(enemyID: "slime", areaID: Valdehierro.townID))
        p.record(.killed(enemyID: "fireSlime", areaID: "valdemar.cripta"))
        p.record(.killed(enemyID: "iceSlime", areaID: "valdemar.pedregal"))
        p.record(.killed(enemyID: "wolf", areaID: "valdemar.robleda"))
        #expect(p.progress(of: pociones) == [3])
        #expect(p.trackerText(pociones) == "Limos de cualquier color: 3/6")
    }

    // MARK: Hablar y leer

    @Test func talkOnlyCountsAfterThePreviousObjectives() throws {
        var p = profile(rescued: ["elena"])
        let hilos = try #require(World.quest(ValdemarQuests.hilos))
        p.accept(hilos.id)
        p.record(.talked(npcID: "elena"))
        #expect(p.progress(of: hilos) == [0, 0], "hablar antes de matar no cuenta")
        #expect(p.marker(for: "elena") == nil)
        for _ in 0..<4 { p.record(.killed(enemyID: "bandit", areaID: "valdemar.robleda")) }
        for _ in 0..<4 { p.record(.killed(enemyID: "mercenary", areaID: "valdemar.robleda")) }
        #expect(p.marker(for: "elena") == .turnIn, "con los bandidos muertos, \"?\" sobre Elena")
        p.record(.talked(npcID: "elena"))
        #expect(p.isComplete(hilos))
        // Al hablar: entrega `hilos` y, después, ofrece `alcalde`.
        #expect(p.conversation(with: "elena") == [.deliver(hilos.id)])
        p.deliver(hilos.id)
        #expect(p.conversation(with: "elena") == [.offer(ValdemarQuests.alcalde)])
    }

    @Test func mayorLetterCompletesTheQuestByItself() throws {
        var p = profile(rescued: ["elena"], done: [ValdemarQuests.hilos])
        let alcalde = try #require(World.quest(ValdemarQuests.alcalde))
        let r6 = p.accept(alcalde.id)
        #expect(r6)
        p.record(.read(npcID: "cartaAlcalde"))
        #expect(!p.isQuestDone(alcalde.id), "sin despejar la casa, leer no cuenta")
        if let mayor = World.area("mayor") {
            var town = p.town
            town.killedSpawns.formUnion(mayor.spawns.map(\.id))
            p.town = town
            p.syncStory()
            #expect(p.progress(of: alcalde)[0] == 1)
            let update = p.record(.read(npcID: "cartaAlcalde"))
            #expect(update.delivered.map(\.questID) == [alcalde.id])
            #expect(p.isQuestDone(alcalde.id))
            // Ya se ofrece la abadía (si Anselmo está rescatado).
            var town2 = p.town
            town2.rescued.insert("anselmo")
            p.town = town2
            #expect(p.marker(for: "anselmo") == .offer)
        }
    }

    @Test func smithEpilogueIsAcceptedAndDeliveredAtOnce() {
        var p = profile(done: [ValdemarQuests.reyGoblin])
        #expect(p.conversation(with: ValdemarQuests.smithID) == [.offer(ValdemarQuests.pasoNorte)])
        let r7 = p.accept(ValdemarQuests.pasoNorte)
        #expect(r7)
        let update = p.record(.talked(npcID: ValdemarQuests.smithID))
        #expect(update.delivered.map(\.questID) == [ValdemarQuests.pasoNorte])
    }

    // MARK: Castillo (M4)

    @Test func castleOpensWithLiberarAbadiaAndPedregalOnly() {
        #expect(!profile(rescued: Self.villagers).isCastleOpen())
        #expect(!profile(rescued: Self.villagers, done: [ValdemarQuests.abadia]).isCastleOpen())
        let open = profile(rescued: Self.villagers, done: [ValdemarQuests.abadia, ValdemarQuests.pedregal])
        #expect(open.isQuestDone(ValdemarQuests.liberar))
        #expect(open.isCastleOpen())
        #expect(open.marker(for: ValdemarQuests.captainID) == .offer, "rey_goblin y calabozos")
        let steps = open.conversation(with: ValdemarQuests.captainID)
        #expect(steps.contains(.offer(ValdemarQuests.reyGoblin)))
    }

    @Test func oldSavesWithThePrincessRescuedKeepTheCastleOpen() {
        var p = PlayerProfile.newGame()
        var town = p.town
        town.rescued = Set(Self.villagers)
        town.princessRescued = true
        p.town = town
        p.migrateStory()
        p.syncStory()
        #expect(p.isQuestDone(ValdemarQuests.liberar))
        #expect(p.isQuestDone(ValdemarQuests.reyGoblin))
        #expect(p.isCastleOpen())
        #expect(p.conversation(with: ValdemarQuests.smithID) == [.offer(ValdemarQuests.pasoNorte)])
    }

    @Test func storyConditions() {
        var p = profile(rescued: ["marta"])
        #expect(p.isMet(.rescued("marta")))
        #expect(!p.isMet(.rescued("princess")))
        var town = p.town
        town.princessRescued = true
        p.town = town
        #expect(p.isMet(.rescued("princess")))
        #expect(!p.isMet(.zoneLiberated("south")))
        town.killedSpawns.formUnion(Valdehierro.town.spawns.filter { $0.id.hasPrefix("south.") }.map(\.id))
        p.town = town
        #expect(p.isMet(.zoneLiberated("south")))
    }

    // MARK: NPC y guardado

    @Test func npcLinesFollowTheStory() {
        let npc = NPC(id: "x", name: "X", look: "baker", role: .villager, position: TilePoint(0, 0), plea: "", thanks: [],
                      reward: Reward(), talk: [
                          NPCLine(when: [.questDone(ValdemarQuests.reyGoblin)], ["libre"]),
                          NPCLine(when: [.questDone(ValdemarQuests.liberar)], ["fuera"]),
                          NPCLine(["pueblo"]),
                      ])
        #expect(profile().idleLines(for: npc) == ["pueblo"])
        #expect(profile(rescued: Self.villagers).idleLines(for: npc) == ["fuera"])
        #expect(profile(done: [ValdemarQuests.reyGoblin]).idleLines(for: npc) == ["libre"])
    }

    // MARK: Textos que dependen de la historia (`valdemar.md` §15)

    @Test func cryptBossSpeaksAsAbbotMorcar() throws {
        let cripta = try #require(World.storyDungeon("valdemar.cripta"))
        #expect(cripta.bossSpeakerName == "Abad Morcar")
        #expect(cripta.bossIntroLines(firstWin: true) == cripta.bossIntro)
        #expect(cripta.bossIntroLines(firstWin: false) == ["¿Otra vez tú? La muerte me sienta mejor que a ti."])
        let defeat = try #require(cripta.bossDefeatText)
        #expect(defeat.hasPrefix("Abad Morcar: «La Orden… no muere conmigo."))
        #expect(defeat.contains("\nAl fondo de la cripta"), "la 2.ª línea la narra Valdehierro, sin hablante")
        // Sin hablante propio, el del bestiario; sin repetición, el mismo diálogo.
        let plain = StoryDungeon(id: "x", name: "X", floorID: "crypt", level: 1, waves: [], bossID: "abbot",
                                 entranceAreaID: Valdehierro.townID, bossIntro: ["hola"])
        #expect(plain.bossSpeakerName == Bestiary.enemy("abbot")!.name)
        #expect(plain.bossIntroLines(firstWin: false) == ["hola"])
        #expect(plain.bossDefeatText == nil)
    }

    @Test func clueReadsShorterTheSecondTime() throws {
        let carta = try #require(Valdehierro.interiors.flatMap(\.npcs).first { $0.id == "cartaAlcalde" })
        var p = profile(rescued: ["elena"], done: [ValdemarQuests.hilos])
        #expect(p.clueLines(for: carta) == carta.thanks)
        p.accept(ValdemarQuests.alcalde)
        // Leída antes de despejar la casa: no cuenta para la misión…
        p.record(.read(npcID: "cartaAlcalde"))
        #expect(p.readClueIDs?.contains("cartaAlcalde") == true)
        var town = p.town
        town.killedSpawns.formUnion(World.area("mayor")!.spawns.map(\.id))
        p.town = town
        p.syncStory()
        // …así que, mientras la misión espera leerla, se lee entera otra vez.
        #expect(p.marker(for: "cartaAlcalde") == .turnIn)
        #expect(p.clueLines(for: carta) == carta.thanks)
        p.record(.read(npcID: "cartaAlcalde"))
        #expect(p.isQuestDone(ValdemarQuests.alcalde))
        #expect(p.clueLines(for: carta) == ["«…El Abad cumple lo que promete. — M.»"])
        // Una pista sin línea de relectura repite la suya.
        let cartel = try #require(World.npc("cartelPaso"))
        p.record(.read(npcID: "cartelPaso"))
        #expect(p.clueLines(for: cartel) == cartel.thanks)
    }

    @Test func smithBubblesFollowTheStoryAndNotInTheArena() {
        let generic = ValdemarDialogue.smithBubbles
        #expect(ValdemarDialogue.smithBubbles(for: nil) == generic, "en la arena, las de siempre")
        #expect(ValdemarDialogue.smithBubbles(for: profile()) == generic, "en el pueblo, nada antes de liberarlo")
        let outside = ValdemarDialogue.smithBubbles(for: profile(rescued: Self.villagers))
        #expect(outside.contains("¿Plata de los huertos? ¿Oro del Pedregal? Tráemelo todo."))
        #expect(!outside.contains { $0.contains("Hachas") || $0.contains("Rocaforja") })
        let axes = ValdemarDialogue.smithBubbles(for: profile(rescued: Self.villagers, done: [ValdemarQuests.pedregal]))
        #expect(axes.contains("¿Hachas orcas negras? Ni me las nombres. Ni me las enseñes."))
        #expect(!axes.contains { $0.contains("Rocaforja") })
        let free = ValdemarDialogue.smithBubbles(for: profile(rescued: Self.villagers, done: [
            ValdemarQuests.pedregal, ValdemarQuests.reyGoblin, ValdemarQuests.pasoNorte,
        ]))
        #expect(free.contains("Acero de verdad, como en Rocaforja. Bueno, casi."))
        #expect(free.contains("Cuando quieras, subimos. Yo llevo el martillo; tú, las piernas."))
        #expect(!free.contains { $0.contains("Hachas") || $0.contains("huertos") })
    }

    @Test func firstVisitSceneOnlyTheFirstTime() {
        var p = profile()
        let scene = p.firstVisitScene(Valdemar.pasoID)
        #expect(scene?.lines == ["Goblins rezagados huyen del castillo… hacia las montañas."])
        #expect(p.firstVisitScene(Valdemar.huertosID) == nil, "solo las áreas que tienen escena")
        p.arrive(at: Valdemar.pasoID)
        #expect(p.firstVisitScene(Valdemar.pasoID) == nil)
        for id in ValdemarDialogue.firstVisitScenes.keys { #expect(World.area(id) != nil, "\(id)") }
    }

    @Test func bossIntrosAreRememberedAcrossSaves() throws {
        var p = profile()
        let first = p.markBossIntroSeen("ogre"), again = p.markBossIntroSeen("ogre")
        #expect(first && !again)
        let data = try JSONEncoder().encode(p)
        var loaded = try JSONDecoder().decode(PlayerProfile.self, from: data)
        let afterLoad = loaded.markBossIntroSeen("ogre"), other = loaded.markBossIntroSeen("warlord")
        #expect(!afterLoad && other)
        // Partidas viejas, sin el campo: cargan y empiezan sin intros vistas.
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["seenBossIntros"] = nil
        json["readClueIDs"] = nil
        var old = try JSONDecoder().decode(PlayerProfile.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(old.seenBossIntros == nil)
        let oldFirst = old.markBossIntroSeen("ogre")
        #expect(oldFirst)
    }

    @Test func questProgressSurvivesSaving() throws {
        var p = profile(rescued: ["bruno"])
        p.accept(ValdemarQuests.cazaMayor)
        p.record(.killed(enemyID: "wolf", areaID: "valdemar.robleda"))
        let data = try JSONEncoder().encode(p)
        let loaded = try JSONDecoder().decode(PlayerProfile.self, from: data)
        #expect(loaded.questState(ValdemarQuests.cazaMayor) == p.questState(ValdemarQuests.cazaMayor))
        #expect(loaded.progress(of: World.quest(ValdemarQuests.cazaMayor)!)[0] == 1)
    }

    @Test func journalTextsUseLabelsOrNames() {
        let generic = PlayerProfile.describe(.kill(enemyIDs: ["wolf", "boar"], count: 3, areaID: "valdemar.robleda"))
        #expect(generic.contains(Bestiary.enemy("wolf")!.name))
        #expect(PlayerProfile.describe(.talk(npcID: "elena")) == "Habla con Elena")
        #expect(PlayerProfile.describe(.talk(npcID: ValdemarQuests.smithID)) == "Habla con el herrero")
        let p = profile(rescued: ["bruno"])
        let lines = p.journal(World.quest(ValdemarQuests.cazaMayor)!)
        #expect(lines.count == 2)
        #expect(lines[0].text == "Lobos grises en Robleda: 0/6")
        #expect(lines[0].counter.isEmpty)
    }
}

@Test func veteranCaptainOfferDoesNotMentionTheLockedCastle() throws {
    var profile = PlayerProfile.newGame(race: .human)
    let quest = try #require(World.quest(ValdemarQuests.pedregal))
    #expect(ValdemarQuests.offerLines(for: quest, profile: profile) == quest.offer)
    profile.quests = [ValdemarQuests.reyGoblin: QuestState(accepted: true, done: true)]
    let lines = ValdemarQuests.offerLines(for: quest, profile: profile)
    #expect(!lines.joined().contains("atrancado"))
    #expect(lines.joined().contains("Señor de la guerra"))
}
