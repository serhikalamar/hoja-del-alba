#if DEBUG
import Foundation
import GameCore

/// Solo en Debug: abrir el juego directamente en una pantalla, para revisarla en el simulador sin tocar.
/// `xcrun simctl launch <simulador> com.sergimartinez.gametest1 -pantalla tienda`
/// Pantallas: `dialogo`, `pausa`, `tienda`, `arena-tienda`, `arena-pausa`, `historia`, `arena`,
/// `campo` (Huertos del Molino con el pueblo liberado), `diario` (pausa con misiones en curso),
/// `mapa` (pausa con el mapa del continente), `capitan` (diálogo de misión del Capitán), `cripta` (mazmorra de historia).
enum DebugLaunch {
    static func apply(to store: GameStore) {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-pantalla"), i + 1 < args.count else { return }
        guard !store.roster.characters.isEmpty || store.createCharacter(name: "Prueba", race: .human, appearance: Appearance()) else { return }
        switch args[i + 1] {
        case "historia":
            store.startTown()
        case "dialogo":
            store.startTown()
            store.explore?.debugShowDialog()
        case "pausa":
            store.startTown()
            store.explore?.debugSkipDialogs()
            store.explore?.pause()
        case "tienda":
            store.startTown()
            store.explore?.debugSkipDialogs()
            store.explore?.debugOpenSmithy()
        case "campo":
            debugStoryProgress(store)
            store.startTown(at: ("valdemar.huertos", World.area("valdemar.huertos").map(World.startPoint) ?? TilePoint(2, 2)))
        case "diario", "mapa":
            debugStoryProgress(store)
            DebugLaunch.pauseTab = args[i + 1]
            store.startTown(at: (Valdehierro.townID, TilePoint(21, 14)))
            store.explore?.debugSkipDialogs()
            store.explore?.pause()
        case "capitan":
            debugStoryProgress(store, acceptQuests: false)
            store.startTown(at: (Valdehierro.townID, TilePoint(18, 14)))
            store.explore?.debugSkipDialogs()
            if let captain = World.npc(ValdemarQuests.captainID) { store.explore?.npcReached(captain) }
        case "cripta":
            debugStoryProgress(store)
            store.startStoryDungeon("valdemar.cripta", from: "valdemar.abadia", at: TilePoint(40, 15))
        case "arena":
            store.startArena()
        case "arena-pausa":
            store.startArena()
            store.battle?.startNextWave()
            store.battle?.pause()
        case "arena-tienda":
            store.startArena()
            for _ in 0..<2 { store.battle?.startNextWave(); store.battle?.roundCleared() }
        default:
            break
        }
    }
}

extension DebugLaunch {
    /// Pestaña inicial de la pausa (`mapa` para abrir el mapa del continente).
    static var pauseTab = ""

    /// Partida avanzada para revisar el modo historia: pueblo liberado, áreas visitadas y algunas misiones en curso.
    static func debugStoryProgress(_ store: GameStore, acceptQuests: Bool = true) {
        var profile = store.profile
        var town = profile.town
        town.rescued = Valdehierro.villagerIDs
        town.killedSpawns.formUnion(Valdehierro.town.spawns.filter { !$0.id.hasPrefix("courtyard") }.map(\.id))
        profile.town = town
        profile.gainXP(2_000)
        profile.syncStory()
        for id in ["valdemar.huertos", "valdemar.robleda", Valdehierro.townID] { profile.arrive(at: id) }
        if acceptQuests {
            for id in [ValdemarQuests.molino, ValdemarQuests.cazaMayor, ValdemarQuests.pedregal] { profile.accept(id) }
            profile.record(.killed(enemyID: "wolf", areaID: "valdemar.robleda"))
        }
        store.profile = profile
        store.save()
    }
}

extension ExploreSession {
    func debugSkipDialogs() {
        while overlay == .dialog { advanceDialog() }
    }

    func debugShowDialog() {
        debugSkipDialogs()
        show(Dialog(speaker: "Marta, la panadera", look: "baker", lines: [
            "¡Gracias por salvarme! Los goblins entraron por la puerta sur y se llevaron toda la harina.",
        ]))
    }
}
#endif
