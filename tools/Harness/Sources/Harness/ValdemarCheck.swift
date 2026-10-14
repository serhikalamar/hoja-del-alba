import CoreGraphics
import Foundation
import GameCore
import SpriteKit

// MARK: - `make check-valdemar`: flujo del continente 1 (game-programmer)
//
// Recorre con la sesión de verdad (sin pantalla) el motor de la fase 1: salidas `>` y sus bloqueos, viajes de ida y
// vuelta, monstruos de campo que reaparecen (y jefes que no), una misión de matar aceptada y entregada, la condición
// nueva del castillo, la casa del alcalde, morir en el campo y la Cripta de la abadía (ganar y perder).
// Fichero aparte de `main.swift` para no pisar al balance-designer.

@MainActor
func checkValdemar() {
    print("Flujo de Valdemar:")
    let store = tempStore()
    store.profile = geared(tier: 3, quality: 3, armorTier: 2)
    store.profile.hasChosenRace = true
    store.profile.gainXP(4_000)
    store.startTown()
    var s = store.explore!
    var t: TimeInterval = 1
    func run(_ seconds: Double, joy: CGVector? = .zero) {
        for _ in 0..<Int(seconds * 60) {
            t += 1.0 / 60
            s.joystick = joy ?? steer(s.scene)
            s.scene.update(t)
        }
    }
    func skipDialogs() { var n = 0; while s.overlay == .dialog && n < 50 { s.advanceDialog(); n += 1 } }
    func area(_ id: String) -> AreaMap? {
        let found = World.area(id)
        if found == nil { print("  · (pendiente) el área \(id) aún no existe: se salta esa parte") }
        return found
    }
    func setTown(_ change: (inout TownProgress) -> Void) {
        var town = store.profile.town
        change(&town)
        store.profile.town = town
    }
    /// Toca a un NPC como el jugador: si no está en esta área, entra en `areaID`; si está lejos, camina hasta él
    /// (con la escena corriendo) y habla al llegar. Devuelve si se ha abierto su diálogo.
    @discardableResult
    func tapNPC(_ id: String, in areaID: String? = nil) -> Bool {
        if let areaID, s.areaID != areaID, let area = World.area(areaID) {
            s.goTo(area.id, at: area.entry)
            skipDialogs()
        }
        guard let decision = s.interact(with: id) else { return false }
        if decision == .walk {
            for _ in 0..<(60 * 30) where s.overlay != .dialog && s.scene.walkingTo != nil {
                t += 1.0 / 60
                s.joystick = .zero
                s.scene.update(t)
            }
        }
        return s.overlay == .dialog
    }
    func finish(_ ids: [String]) {
        var all = store.profile.quests ?? [:]
        for id in ids { all[id] = QuestState(accepted: true, progress: World.quest(id)!.objectives.map(\.target), done: true) }
        store.profile.quests = all
        store.profile.syncStory()
    }

    // 1. Partida nueva: la misión de liberar el pueblo se acepta sola.
    check(s.overlay == .dialog, "empieza con la introducción")
    skipDialogs()
    check(store.profile.trackedQuest?.id == ValdemarQuests.liberar, "«\(World.quest(ValdemarQuests.liberar)!.title)» se acepta sola")
    check(s.objective.contains("0/6"), "el HUD sigue la misión: «\(s.objective)»")

    // 2. Salida oeste cerrada hasta liberar el barrio oeste.
    let town = Valdehierro.town
    if let west = town.exits.first(where: { $0.id == "town.oeste" }) {
        s.goTo(town.id, at: TilePoint(1, 17))
        skipDialogs()
        run(1, joy: CGVector(dx: -1, dy: 0))
        check(s.areaID == town.id && s.lastToast == west.lockedMessage, "town.oeste cerrada avisa: «\(s.lastToast ?? "-")»")
        setTown { $0.killedSpawns.formUnion(town.spawns.filter { $0.id.hasPrefix("west.") }.map(\.id)) }
        s.goTo(town.id, at: TilePoint(1, 17))
        skipDialogs()
        run(0.6, joy: CGVector(dx: -1, dy: 0))
        check(s.areaID == west.toArea, "con el barrio oeste liberado, se viaja a \(west.toArea)")
        check(store.profile.currentAreaID == west.toArea && store.profile.visitedAreaIDs?.contains(west.toArea) == true,
              "el área actual se guarda en el perfil")
        check(s.areaBanner?.contains("·") == true, "cartel del área: «\(s.areaBanner ?? "-")»")
    }

    // 3. Monstruos de campo: reaparecen a los 90 s lejos del héroe; los jefes no.
    if let huertos = area("valdemar.huertos") {
        s.goTo(huertos.id, at: World.startPoint(in: huertos))
        skipDialogs()
        let hero = World.startPoint(in: huertos)
        let farthest = huertos.spawns.filter { !huertos.isPermanent($0) }.max { a, b in
            hypot(Double(a.position.x - hero.x), Double(a.position.y - hero.y)) < hypot(Double(b.position.x - hero.x), Double(b.position.y - hero.y))
        }
        if let spawn = farthest, let node = s.scene.enemies.first(where: { $0.spawnID == spawn.id }) {
            s.scene.kill(node)
            check(!store.profile.town.killedSpawns.contains(spawn.id) && s.scene.fieldDeadIDs.contains(spawn.id),
                  "un \(spawn.enemyID) de campo muerto no se guarda como permanente")
            run(60)
            check(!s.scene.enemies.contains { $0.spawnID == spawn.id }, "a los 60 s aún no ha vuelto")
            run(32)
            check(s.scene.enemies.contains { $0.spawnID == spawn.id }, "a los 90 s reaparece (\(spawn.id))")
        }
        if let boss = huertos.spawns.first(where: { huertos.isPermanent($0) }),
           let node = s.scene.enemies.first(where: { $0.spawnID == boss.id }) {
            s.scene.kill(node)
            check(store.profile.town.killedSpawns.contains(boss.id), "el jefe \(boss.enemyID) queda muerto para siempre")
            s.goTo(huertos.id, at: World.startPoint(in: huertos))
            skipDialogs()
            check(!s.scene.enemies.contains { $0.spawnID == boss.id }, "al volver a entrar, el jefe no está")
        }
    }

    // 4. Misión de matar (`valdemar.molino`): aceptar con Tomás, matar en los Huertos, entregar.
    setTown { $0.rescued.insert("tomas") }
    store.profile.syncStory()
    let molino = World.quest(ValdemarQuests.molino)!
    if let tomas = World.npc("tomas") {
        check(store.profile.marker(for: "tomas") == .offer, "«!» sobre Tomás")
        check(tapNPC(tomas.id, in: town.id), "se toca a Tomás en el pueblo: camina hasta él y habla")
        skipDialogs()
        check(store.profile.isActive(molino), "hablando con Tomás se acepta «\(molino.title)»")
    }
    if let huertos = area("valdemar.huertos") {
        var killed = 0
        for _ in 0..<3 where killed < 6 {
            s.goTo(huertos.id, at: World.startPoint(in: huertos))
            skipDialogs()
            for node in s.scene.enemies where node.definition.id == "zombieFarmer" && killed < 6 {
                s.scene.kill(node)
                killed += 1
            }
        }
        check(store.profile.progress(of: molino)[0] == 6, "6 granjeros zombi contados (reaparecen al volver a entrar)")
        check(store.profile.isComplete(molino), "con el Ogro muerto antes, la misión está cumplida")
        check(store.profile.marker(for: "tomas") == .turnIn, "«?» sobre Tomás")
        let xp = store.profile.levelXP, level = store.profile.characterLevel
        check(tapNPC("tomas", in: town.id), "se le vuelve a tocar para entregar")
        skipDialogs()
        check(store.profile.isQuestDone(molino.id), "entregada al hablar con Tomás")
        check(store.profile.levelXP != xp || store.profile.characterLevel != level, "da experiencia")
    }

    // 5. Condición nueva del castillo: liberar + abadía + Pedregal (no basta con los aldeanos).
    setTown { $0.rescued = Valdehierro.villagerIDs; $0.killedSpawns.formUnion(town.spawns.filter { !$0.id.hasPrefix("courtyard") }.map(\.id)) }
    store.profile.syncStory()
    check(store.profile.isQuestDone(ValdemarQuests.liberar), "con los 6 aldeanos se completa «\(World.quest(ValdemarQuests.liberar)!.title)»")
    check(!store.profile.isCastleOpen(), "pero el castillo sigue cerrado")
    s.goTo(town.id, at: TilePoint(21, 13))
    skipDialogs()
    run(1.2, joy: CGVector(dx: 0, dy: 1))
    check(s.lastToast?.contains("Capitán") == true && s.scene.heroFeetTile().y >= 12,
          "la escalinata está cerrada: «\(s.lastToast ?? "-")»")
    if let captain = World.npc(ValdemarQuests.captainID) {
        check(store.profile.visibleNPCs(in: town).contains { $0.id == captain.id }, "aparece el Capitán Vela")
        check(store.profile.marker(for: captain.id) == .offer, "«!» sobre el Capitán")
    }
    finish([ValdemarQuests.abadia, ValdemarQuests.pedregal])
    check(store.profile.isCastleOpen(), "con la abadía y el Pedregal, el castillo se abre")
    check(store.profile.lockedTiles(in: town).keys.allSatisfy { town.tile($0.x, $0.y) != .stairs }, "la escalinata ya se pisa")

    // 6. La casa del alcalde se abre con «Tirar del hilo».
    if let mayor = town.buildings.first(where: { $0.id == "mayor" }) {
        check(store.profile.doorLockMessage(mayor) != nil, "la casa del alcalde está cerrada al principio")
        if mayor.interiorID != nil {
            finish([ValdemarQuests.hilos])
            s.goTo(town.id, at: TilePoint(mayor.doorX, mayor.y + mayor.height))
            skipDialogs()
            s.doorTouched(mayor)
            check(s.areaID == mayor.interiorID, "tras «Tirar del hilo» se entra en \(mayor.interiorID!)")
            s.exitTouched()
            check(s.areaID == town.id, "y se sale por la puerta")
        } else {
            print("  · (pendiente) el edificio mayor aún no tiene interior")
        }
    }

    // 7. Las salidas del pueblo: ida y vuelta (todo hecho salvo el Paso, que se abre con el herrero).
    check(store.profile.lockedTiles(in: town).values.contains { $0.contains("Paso") }, "la salida norte está cerrada antes del epílogo")
    finish(World.quests.map(\.id))
    for exit in town.exits {
        s.goTo(town.id, at: town.entry)
        skipDialogs()
        s.areaExitTouched(exit)
        guard s.areaID == exit.toArea, let there = World.area(exit.toArea) else {
            check(false, "\(exit.id) lleva a \(exit.toArea)")
            continue
        }
        let back = there.exits.first { $0.toArea == town.id }
        skipDialogs()  // la primera vez en el Paso sale su escena (`escena.paso.entrar`)
        if let back {
            s.areaExitTouched(back)
            check(s.areaID == town.id, "\(exit.id) → \(there.name) → \(back.id) → pueblo")
        } else {
            check(false, "\(there.id) no tiene salida de vuelta al pueblo")
        }
    }
    if let paso = area("valdemar.paso"), let north = paso.exits.first(where: { if case .comingSoon = $0.lock { true } else { false } }) {
        s.goTo(paso.id, at: World.startPoint(in: paso))
        skipDialogs()
        s.areaExitTouched(north)
        check(s.areaID == paso.id && s.lastToast == north.lockedMessage, "Rocaforja: «\(s.lastToast ?? "-")»")
    }

    // 7b. Escena de primera visita, intros de jefe guardadas y relectura de una pista (`valdemar.md` §15).
    if let paso = area(Valdemar.pasoID) {
        store.profile.visitedAreaIDs?.remove(paso.id)
        s.goTo(paso.id, at: World.startPoint(in: paso))
        check(s.overlay == .dialog && s.dialog?.line == ValdemarDialogue.firstVisitScenes[paso.id]?.lines.first,
              "primera vez en el Paso: «\(s.dialog?.line ?? "-")»")
        skipDialogs()
        s.goTo(town.id, at: town.entry)
        skipDialogs()
        s.goTo(paso.id, at: World.startPoint(in: paso))
        check(s.overlay == .none, "la segunda vez en el Paso no hay escena")
    }
    if let ogre = Bestiary.enemy("ogre") {
        store.profile.seenBossIntros = nil
        s.bossSpotted(ogre)
        check(s.overlay == .dialog && s.dialog?.speaker == ValdemarDialogue.bossIntros["ogre"]?.speaker, "el Ogro se presenta")
        skipDialogs()
        let saved = store.profile.seenBossIntros?.contains("ogre") == true
        store.startTown(at: (Valdehierro.townID, town.entry))
        s = store.explore!
        skipDialogs()
        s.bossSpotted(ogre)
        check(saved && s.overlay == .none, "su presentación queda en el perfil y no se repite en otra sesión")
    }
    if let mayorArea = area("mayor"), let carta = mayorArea.npcs.first(where: { $0.role == .clue }) {
        setTown { $0.killedSpawns.subtract(mayorArea.spawns.map(\.id)) }
        s.goTo(mayorArea.id, at: mayorArea.entry)
        skipDialogs()
        s.interact(with: carta.id)
        check(s.overlay == .none && s.lastToast == ValdemarDialogue.roomNotCleared && s.scene.walkingTo == nil,
              "con monstruos en la sala, tocar la carta solo avisa: «\(s.lastToast ?? "-")»")
        setTown { $0.killedSpawns.formUnion(mayorArea.spawns.map(\.id)) }
        s.goTo(mayorArea.id, at: mayorArea.entry)
        skipDialogs()
        tapNPC(carta.id)
        let first = s.dialog?.lines ?? []
        skipDialogs()
        tapNPC(carta.id)
        let again = s.dialog?.lines ?? []
        skipDialogs()
        check(first == carta.thanks && again == ["«…El Abad cumple lo que promete. — M.»"],
              "la carta se relee más corta: «\(again.first ?? "-")»")
    }

    // 8. Morir en el campo: se reaparece en el punto seguro del área.
    if let robleda = area("valdemar.robleda") {
        s.goTo(robleda.id, at: robleda.entry)
        skipDialogs()
        s.heroDied()
        s.respawn()
        check(s.areaID == robleda.id && s.scene.heroFeetTile() == robleda.safePoint, "al morir en Robleda se vuelve a su hoguera")
    }

    // 9. La Cripta de la abadía: ganar (vuelve a la `e` y cuenta para la misión) y perder (punto seguro).
    if let abadia = area("valdemar.abadia"), let entrance = abadia.dungeonEntrances.first {
        store.profile.quests?[ValdemarQuests.abadia] = nil
        store.profile.syncStory()
        store.profile.accept(ValdemarQuests.abadia)
        let abbeyQuest = World.quest(ValdemarQuests.abadia)!
        s.goTo(abadia.id, at: entrance.tiles[0])
        skipDialogs()
        s.dungeonEntranceTouched(entrance)
        guard let b = store.battle, let dungeon = b.story else {
            check(false, "la `e` abre la mazmorra \(entrance.dungeonID)")
            print(failures == 0 ? "Todo correcto." : "\(failures) comprobaciones fallidas.")
            return
        }
        check(store.screen == .battle && b.phase == .fighting && b.floor.id == dungeon.floorID,
              "la `e` abre \(dungeon.name) en el piso \(dungeon.floorID), oleada 1/\(dungeon.totalWaves)")
        // Un rato de combate de verdad en la primera oleada.
        for _ in 0..<(60 * 20) where b.phase == .fighting {
            t += 1.0 / 60
            b.joystick = steer(b.scene)
            b.scene.update(t)
        }
        check(b.kills > 0, "se pelea en la cripta (\(b.kills) muertos en 20 s)")
        var bossSpeaker: String?
        while b.phase != .storyVictory && b.wave <= dungeon.totalWaves + 1 {
            if b.phase == .storyDialog {
                if bossSpeaker == nil { bossSpeaker = b.storyDialog?.speaker }
                b.advanceStoryDialog()
                continue
            }
            if b.phase == .defeat { break }
            b.roundCleared()
            if b.phase == .waveBreak { b.startNextWave() }
        }
        check(b.phase == .storyVictory, "se gana tras \(dungeon.totalWaves) oleadas (con el diálogo del jefe antes)")
        check(store.profile.wonDungeons?.contains(dungeon.id) == true, "la victoria queda guardada")
        check(bossSpeaker == dungeon.bossSpeakerName && bossSpeaker == "Abad Morcar", "el jefe se presenta como «\(bossSpeaker ?? "-")»")
        check(b.storyMessage.contains("Abad Morcar: «La Orden"), "la derrota lleva su hablante: «\(b.storyMessage)»")
        check(store.profile.progress(of: abbeyQuest)[1] == 1, "cuenta para «\(abbeyQuest.title)»")
        b.leaveStory()
        s = store.explore!
        check(store.screen == .town && s.areaID == abadia.id && s.scene.heroFeetTile() == entrance.tiles[0],
              "al ganar se vuelve a la bajada de la abadía")
        run(0.5)
        check(store.screen == .town, "y no se vuelve a bajar sin salir de la casilla")

        s.dungeonEntranceTouched(entrance)
        if let b2 = store.battle {
            b2.heroDied()
            b2.leaveStory()
            s = store.explore!
            check(s.areaID == abadia.id && s.scene.heroFeetTile() == abadia.safePoint, "al perder se despierta en la hoguera de la abadía")
        }
    }

    print(failures == 0 ? "Todo correcto." : "\(failures) comprobaciones fallidas.")
}

// MARK: - `valdemar-shots`: capturas del modo historia (campo, Capitán con «!», bajada a la cripta)

@MainActor
func valdemarShots() {
    print("Capturas de Valdemar:")
    let size = CGSize(width: 852, height: 393)
    let view = SKView(frame: CGRect(origin: .zero, size: size))
    let store = tempStore()
    store.profile = geared(tier: 3, quality: 3, armorTier: 2)
    var town = store.profile.town
    town.rescued = Valdehierro.villagerIDs
    town.killedSpawns = Set(Valdehierro.town.spawns.filter { !$0.id.hasPrefix("courtyard") }.map(\.id))
    store.profile.town = town
    store.profile.syncStory()
    store.startTown(at: (Valdehierro.townID, TilePoint(19, 15)))
    let s = store.explore!
    view.presentScene(s.scene)
    s.scene.size = size
    var t: TimeInterval = 1
    func settle() {
        var n = 0
        while s.overlay == .dialog && n < 30 { s.advanceDialog(); n += 1 }
        for _ in 0..<30 { t += 1.0 / 60; s.joystick = .zero; s.scene.update(t) }
    }
    func snap(_ name: String) {
        if let texture = view.texture(from: s.scene) { save(texture.cgImage(), name) }
    }
    settle()
    snap("shot_valdemar_capitan")
    for (name, id) in [("shot_valdemar_huertos", "valdemar.huertos"), ("shot_valdemar_robleda", "valdemar.robleda"),
                       ("shot_valdemar_abadia", "valdemar.abadia"), ("shot_valdemar_pedregal", "valdemar.pedregal"),
                       ("shot_valdemar_paso", "valdemar.paso")] {
        guard let area = World.area(id) else { continue }
        s.goTo(id, at: World.startPoint(in: area))
        settle()
        snap(name)
    }
    if let abadia = World.area("valdemar.abadia"), let e = abadia.dungeonEntrances.first?.tiles.first {
        s.goTo(abadia.id, at: TilePoint(e.x, e.y + 2))
        settle()
        snap("shot_valdemar_cripta_bajada")
    }
}
