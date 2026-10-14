import Foundation
import Testing
@testable import GameCore

/// Hablar tocando a los NPC (alcance, a quién se toca, camino por casillas) y el panel de la misión seguida.
@Suite("Interacción y misión seguida")
struct InteractionTests {
    let tile = 48.0

    // MARK: Alcance y toque

    @Test func reachIsTwoTiles() {
        #expect(NPCInteraction.isInReach(dx: 2 * tile, dy: 0, tileSize: tile))
        #expect(NPCInteraction.isInReach(dx: tile, dy: tile, tileSize: tile))
        #expect(!NPCInteraction.isInReach(dx: 2 * tile, dy: tile, tileSize: tile))
    }

    @Test func tapDecision() {
        #expect(NPCInteraction.decide(distance: tile, tileSize: tile, hasPath: false) == .talk)
        #expect(NPCInteraction.decide(distance: 5 * tile, tileSize: tile, hasPath: true) == .walk)
        #expect(NPCInteraction.decide(distance: 5 * tile, tileSize: tile, hasPath: false) == .unreachable)
    }

    @Test func pickUsesAGenerousBoxAndPrefersTheClosest() {
        let a = NPCHitBox(id: "a", centerX: 100, centerY: 100, halfWidth: 20, halfHeight: 30)
        let b = NPCHitBox(id: "b", centerX: 150, centerY: 100, halfWidth: 20, halfHeight: 30)
        // Fuera del dibujo pero dentro del margen para el dedo (media casilla).
        #expect(NPCInteraction.pick(x: 100, y: 145, among: [a, b], tileSize: tile) == "a")
        // Entre los dos, gana el de centro más cercano.
        #expect(NPCInteraction.pick(x: 130, y: 100, among: [a, b], tileSize: tile) == "b")
        #expect(NPCInteraction.pick(x: 300, y: 100, among: [a, b], tileSize: tile) == nil)
    }

    @Test func actionKeyTalksToTheClosestInReach() {
        let near = [(id: "lejos", distance: 3 * tile), (id: "cerca", distance: 1.5 * tile), (id: "otro", distance: 1.9 * tile)]
        #expect(NPCInteraction.closestInReach(near, tileSize: tile) == "cerca")
        #expect(NPCInteraction.closestInReach([(id: "lejos", distance: 3 * tile)], tileSize: tile) == nil)
    }

    // MARK: Camino

    /// `#` muro, `.` suelo.
    func grid(_ rows: [String]) -> (TilePoint) -> Bool {
        { p in p.y >= 0 && p.y < rows.count && p.x >= 0 && p.x < rows[p.y].count && Array(rows[p.y])[p.x] == "." }
    }

    @Test func pathGoesAroundWallsWithoutCuttingCorners() {
        let passable = grid([
            ".....",
            "####.",
            ".....",
        ])
        let path = TilePathfinder.path(from: TilePoint(0, 0), isGoal: { $0 == TilePoint(0, 2) }, passable: passable)
        #expect(path?.first == TilePoint(0, 0) && path?.last == TilePoint(0, 2))
        #expect(path?.contains(TilePoint(4, 1)) == true, "rodea el muro por el único hueco")
        for (a, b) in zip(path ?? [], (path ?? []).dropFirst()) {
            #expect(abs(a.x - b.x) <= 1 && abs(a.y - b.y) <= 1)
            #expect(passable(b))
            if a.x != b.x && a.y != b.y { #expect(passable(TilePoint(b.x, a.y)) && passable(TilePoint(a.x, b.y))) }
        }
    }

    @Test func noPathThroughWalls() {
        let passable = grid([
            "..#..",
            "..#..",
        ])
        #expect(TilePathfinder.path(from: TilePoint(0, 0), isGoal: { $0.x == 4 }, passable: passable) == nil)
        #expect(TilePathfinder.path(from: TilePoint(0, 0), isGoal: { $0 == TilePoint(0, 0) }, passable: passable) == [TilePoint(0, 0)])
    }

    @Test func talkTilesEndWithinReach() {
        let npc = TilePoint(10, 10)
        #expect(NPCInteraction.isTalkTile(TilePoint(11, 11), npc: npc))
        #expect(!NPCInteraction.isTalkTile(TilePoint(12, 11), npc: npc))
        // Al centro de una casilla de hablar ya se está al alcance.
        for x in 7...13 { for y in 7...13 where NPCInteraction.isTalkTile(TilePoint(x, y), npc: npc) {
            #expect(NPCInteraction.isInReach(dx: Double(x - 10) * tile, dy: Double(y - 10) * tile, tileSize: tile))
        } }
    }

    @Test func everyNPCCanBeReachedOnFootFromTheEntry() {
        for area in World.areas {
            for npc in area.npcs {
                let path = TilePathfinder.path(from: area.entry, isGoal: { NPCInteraction.isTalkTile($0, npc: npc.position) && area.isStrollable($0) },
                                               passable: area.isStrollable)
                #expect(path != nil, "\(area.id): no se llega andando a \(npc.id) desde la entrada")
            }
        }
    }

    @Test func strollAvoidsDoorsExitsAndDungeons() {
        let town = Valdehierro.town
        for b in town.buildings { for d in b.doorTiles { #expect(!town.isStrollable(d), "puerta de \(b.id)") } }
        for exit in town.exits { for t in exit.tiles { #expect(!town.isStrollable(t), "salida \(exit.id)") } }
        for area in World.areas { for e in area.dungeonEntrances { for t in e.tiles { #expect(!area.isStrollable(t)) } } }
        for area in World.areas where area.isInterior { for t in area.exitTiles { #expect(!area.isStrollable(t)) } }
    }

    // MARK: Misión seguida

    func profile(rescued: [String] = []) -> PlayerProfile {
        var p = PlayerProfile.newGame()
        var town = p.town
        town.rescued = Set(rescued)
        p.town = town
        p.syncStory()
        return p
    }

    @Test func playerChoosesTheTrackedQuest() {
        var p = profile(rescued: ["tomas", "bruno"])
        let accepted = p.accept(ValdemarQuests.molino) && p.accept(ValdemarQuests.cazaMayor)
        #expect(accepted)
        #expect(p.trackedQuest?.id == ValdemarQuests.liberar, "sin elegir, la primera activa")
        let tracked = p.track(ValdemarQuests.cazaMayor)
        #expect(tracked)
        #expect(p.trackedQuest?.id == ValdemarQuests.cazaMayor)
        #expect(p.isTracked(World.quest(ValdemarQuests.cazaMayor)!))
        let notAccepted = p.track(ValdemarQuests.calabozos)
        #expect(!notAccepted, "no se sigue una misión sin aceptar")
        #expect(p.trackedQuest?.id == ValdemarQuests.cazaMayor)
        // Entregada, el HUD vuelve a la primera activa.
        var all = p.quests ?? [:]
        all[ValdemarQuests.cazaMayor]?.done = true
        p.quests = all
        #expect(p.trackedQuest?.id == ValdemarQuests.liberar)
    }

    @Test func trackedQuestSurvivesSaving() throws {
        var p = profile(rescued: ["tomas"])
        p.accept(ValdemarQuests.molino)
        p.track(ValdemarQuests.molino)
        let loaded = try JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(p))
        #expect(loaded.trackedQuest?.id == ValdemarQuests.molino)
    }

    @Test func alertsForNewQuestsAndTurnIns() {
        var p = profile()
        #expect(!p.questAlerts.contains { $0.questID == ValdemarQuests.molino }, "Tomás aún no está rescatado")
        p = profile(rescued: ["tomas"])
        #expect(p.questAlerts.contains(QuestAlert(questID: ValdemarQuests.molino, npcID: "tomas", kind: .newQuest)))
        p.accept(ValdemarQuests.molino)
        #expect(!p.questAlerts.contains { $0.questID == ValdemarQuests.molino })
        // Cumplida (6 zombis + Ogro): hay que volver con Tomás.
        var all = p.quests ?? [:]
        all[ValdemarQuests.molino]?.progress = World.quest(ValdemarQuests.molino)!.objectives.map(\.target)
        p.quests = all
        #expect(p.questAlerts.contains(QuestAlert(questID: ValdemarQuests.molino, npcID: "tomas", kind: .turnIn)))
    }

    @Test func destinationFollowsTheNextObjective() {
        var p = profile(rescued: ["tomas"])
        let liberar = World.quest(ValdemarQuests.liberar)!
        // Rescatar: la casa del primer aldeano que falta.
        let marta = p.destination(of: liberar)
        #expect(marta != nil && World.area(marta!.areaID)?.npcs.contains { $0.id == "marta" } == true)
        p.accept(ValdemarQuests.molino)
        let molino = World.quest(ValdemarQuests.molino)!
        #expect(p.destination(of: molino)?.areaID == "valdemar.huertos")
        var all = p.quests ?? [:]
        all[ValdemarQuests.molino]?.progress = molino.objectives.map(\.target)
        p.quests = all
        // Cumplida: Tomás, mejor en la calle que en su casa.
        let back = p.destination(of: molino)
        #expect(back != nil && World.area(back!.areaID)?.isInterior == false)
    }

    @Test func rewardTextListsEverything() {
        let text = PlayerProfile.rewardText(QuestReward(xp: 100, gold: 50, minerals: [.silver: 2]))
        #expect(text.contains("100 XP") && text.contains("50 oro") && text.contains("2 \(Mineral.silver.name)"))
        #expect(PlayerProfile.rewardText(QuestReward()) == "—")
    }
}
