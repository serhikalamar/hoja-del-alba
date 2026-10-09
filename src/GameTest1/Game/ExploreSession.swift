import GameCore
import Observation
import SpriteKit
#if os(iOS)
import UIKit
#endif

/// Qué pasa al cerrar un diálogo.
enum DialogAction: Equatable {
    /// Completa el rescate de un aldeano o de la princesa.
    case rescue(String)
    /// Acepta una misión.
    case accept(String)
    /// Entrega una misión.
    case deliver(String)
    /// Lee un objeto (`clue`): cuenta para las misiones `read`.
    case read(String)
    /// Sigue la conversación con ese NPC (entregas y ofertas encadenadas).
    case converse(String)
    /// Abre la tienda de la forja.
    case openShop
}

/// Una conversación en pantalla.
struct Dialog: Equatable {
    var speaker: String
    var look: String?
    var lines: [String]
    var index = 0
    /// Lo que pasa al cerrarlo, en orden.
    var onClose: [DialogAction] = []
    /// Cambia el nombre del que habla a partir de una línea (el herrero se presenta en el epílogo).
    var renameAt: (index: Int, speaker: String)?

    var line: String { lines[min(index, lines.count - 1)] }
    var isLast: Bool { index >= lines.count - 1 }
    var currentSpeaker: String {
        if let renameAt, index >= renameAt.index { return renameAt.speaker }
        return speaker
    }

    static func == (a: Dialog, b: Dialog) -> Bool {
        a.speaker == b.speaker && a.look == b.look && a.lines == b.lines && a.index == b.index && a.onClose == b.onClose
    }
}

/// Puente entre la escena de exploración y la interfaz. Aplica las reglas de GameCore: viajes entre áreas,
/// bloqueos, misiones, rescates, reaparecer y la forja.
@Observable
final class ExploreSession: CombatDelegate {
    enum Overlay: Equatable {
        case none, dialog, paused, smithy, dead, victory
    }

    private(set) var overlay: Overlay = .none
    private(set) var areaID = Valdehierro.townID
    private(set) var hp: Double = 0
    private(set) var maxHP: Double = 0
    private(set) var placeName = "Valdehierro"
    private(set) var dialog: Dialog?
    private(set) var toast: String?
    /// El último aviso pedido (aunque esté en cola detrás de otro).
    @ObservationIgnored private(set) var lastToast: String?
    /// Cartel grande al entrar en un área ("Bosque de Robleda · 6-7").
    private(set) var areaBanner: String?
    private(set) var shop: ShopModel?
    /// Texto de la pantalla de muerte.
    private(set) var deathMessage = ValdemarDialogue.death(inField: nil)

    @ObservationIgnored var joystick: CGVector = .zero
    @ObservationIgnored let scene: ExploreScene
    @ObservationIgnored private unowned let store: GameStore
    @ObservationIgnored private var dialogQueue: [Dialog] = []
    @ObservationIgnored private var toastQueue: [String] = []
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    #if os(iOS)
    @ObservationIgnored private let haptics = UIImpactFeedbackGenerator(style: .light)
    #endif

    /// - Parameters:
    ///   - start: área y casilla donde aparecer (nil = donde se guardó la partida).
    ///   - message: aviso al llegar (p. ej. al volver de una mazmorra).
    init(store: GameStore, start: (areaID: String, tile: TilePoint)? = nil, message: String? = nil) {
        self.store = store
        scene = ExploreScene(size: CGSize(width: 844, height: 390))
        scene.scaleMode = .resizeFill
        scene.session = self
        scene.combatDelegate = self
        let stats = store.profile.totalStats
        hp = stats.maxHP
        maxHP = stats.maxHP
        store.profile.migrateStory()
        let update = store.profile.syncStory()
        let area = World.area(start?.areaID ?? store.profile.areaID) ?? Valdehierro.town
        enter(area, at: start?.tile ?? World.startPoint(in: area), animated: false)
        scene.setRunning(true)
        showIntroDialog()
        report(update)
        if let message { showToast(message) }
    }

    var progress: TownProgress { store.profile.town }

    var level: Int { store.profile.characterLevel }
    var xpProgress: Double {
        let need = Leveling.xpToNext(store.profile.characterLevel)
        return need > 0 ? Double(store.profile.levelXP) / Double(need) : 1
    }

    var rescuedCount: Int { progress.rescued.count }
    var villagerCount: Int { Valdehierro.villagerIDs.count }

    var liberatedZones: Int {
        Valdehierro.town.zones.filter { progress.isLiberated($0, in: Valdehierro.town) }.count
    }

    /// Objetivo del HUD: la misión que se sigue o, si no hay, lo que toca en la historia.
    var objective: String {
        let profile = store.profile
        if let quest = profile.trackedQuest { return profile.trackerText(quest) }
        return ValdemarDialogue.hudObjective(profile)
    }

    /// Diario de la pausa.
    var activeQuests: [Quest] { store.profile.activeQuests }
    var finishedQuests: [Quest] { store.profile.finishedQuests }
    func journal(_ quest: Quest) -> [QuestObjectiveLine] { store.profile.journal(quest) }

    // MARK: - Áreas

    private func applyEquipment() {
        let profile = store.profile
        scene.prepareHero(stats: profile.totalStats, hp: hp, look: HeroLook(profile: profile), weapon: profile.equippedWeapon,
                          level: profile.characterLevel)
    }

    private var currentArea: AreaMap { World.area(areaID) ?? Valdehierro.town }

    private func enter(_ area: AreaMap, at start: TilePoint, animated: Bool = true) {
        let load = { [self] () -> (speaker: String, lines: [String])? in
            let firstVisit = !(store.profile.visitedAreaIDs ?? []).contains(area.id)
            let firstScene = store.profile.firstVisitScene(area.id)
            areaID = area.id
            store.profile.arrive(at: area.id)
            let update = store.profile.syncStory()
            scene.load(area, heroAt: start, progress: progress, story: storyState(for: area))
            applyEquipment()
            updatePlaceName(force: true)
            showBanner(area.banner)
            if firstVisit, area.id == "mayor" { showToast(ValdemarDialogue.mayorFirstVisit) }
            report(update)
            store.save()
            return firstScene
        }
        // Escena corta la primera vez en un área (`escena.paso.entrar`), cuando ya se ve el área.
        let showScene = { [self] (firstScene: (speaker: String, lines: [String])?) in
            if let firstScene { show(Dialog(speaker: firstScene.speaker, look: nil, lines: firstScene.lines)) }
        }
        if animated {
            var pending: (speaker: String, lines: [String])?
            scene.fade({ pending = load() }, then: { showScene(pending) })
        } else {
            showScene(load())
        }
    }

    /// Lo que la historia decide del área: casillas cerradas, NPC visibles y sus "!"/"?".
    func storyState(for area: AreaMap, progress: TownProgress? = nil) -> AreaStoryState {
        var profile = store.profile
        if let progress { profile.town = progress }
        var npcs = profile.visibleNPCs(in: area).map { ($0, $0.position) }
        // Partidas sin aldeanos en la calle (datos antiguos): los rescatados vuelven a la plaza.
        if area.kind == .town, !area.npcs.contains(where: { $0.role == .villager }) {
            for npc in Valdehierro.interiors.flatMap(\.npcs) where npc.role == .villager && profile.isRescued(npc.id) {
                if let spot = Self.plazaSpots[npc.id] { npcs.append((npc, spot)) }
            }
        }
        var markers: [String: QuestMarker] = [:]
        for (npc, _) in npcs { markers[npc.id] = profile.marker(for: npc.id) }
        return AreaStoryState(lockedTiles: profile.lockedTiles(in: area), npcs: npcs, markers: markers,
                              castleOpen: profile.isCastleOpen(continentID: area.continentID))
    }

    private static let plazaSpots: [String: TilePoint] = [
        "marta": TilePoint(17, 15), "elena": TilePoint(26, 15), "tomas": TilePoint(17, 18),
        "anselmo": TilePoint(26, 18), "bruno": TilePoint(19, 21), "iris": TilePoint(24, 21),
    ]

    private func refreshScene() {
        scene.refresh(progress: progress, story: storyState(for: currentArea))
    }

    /// Lleva al héroe a un área y casilla sin pasar por una salida (banco de pruebas, modo debug).
    func goTo(_ areaID: String, at tile: TilePoint) {
        guard let area = World.area(areaID) else { return }
        enter(area, at: tile, animated: false)
    }

    func doorTouched(_ building: Building) {
        guard overlay == .none, let interiorID = building.interiorID else { return }
        if interiorID == "smithy" {
            openSmithy()
            return
        }
        guard let area = World.area(interiorID) else { return }
        enter(area, at: area.entry)
    }

    /// Puerta `D` de un interior: se sale delante del edificio.
    func exitTouched() {
        guard overlay == .none, let outside = World.outside(of: areaID), let area = World.area(outside.areaID) else { return }
        enter(area, at: outside.tile)
    }

    /// Salida `>` a otra área.
    func areaExitTouched(_ exit: AreaExit) {
        guard overlay == .none else { return }
        switch store.profile.travel(through: exit, from: currentArea) {
        case .travel(let id, let arrival):
            guard let area = World.area(id) else { return }
            enter(area, at: arrival)
        case .blocked(let message):
            showToast(message)
        }
    }

    /// Bajada `e` a una mazmorra de historia.
    func dungeonEntranceTouched(_ entrance: DungeonEntrance) {
        guard overlay == .none else { return }
        switch store.profile.enter(entrance, in: currentArea) {
        case .enter(let id):
            joystick = .zero
            scene.setRunning(false)
            store.save()
            store.startStoryDungeon(id, from: areaID, at: entrance.tiles.first ?? currentArea.entry)
        case .blocked(let message):
            showToast(message)
        }
    }

    /// Casilla cerrada por la historia (puerta, escalinata, salida o bajada).
    func lockedTileTouched(_ message: String) {
        showToast(message)
    }

    /// Nombre del lugar: interior, área o zona donde está el héroe.
    private func updatePlaceName(force: Bool = false) {
        let area = currentArea
        let name = area.isInterior ? area.name : (area.zone(at: scene.heroFeetTile())?.name ?? area.name)
        if force || name != placeName { placeName = name }
    }

    // MARK: - Forja del enano

    #if DEBUG
    func debugOpenSmithy() { openShop() }
    #endif

    /// Al entrar en la forja el herrero habla primero si tiene algo (epílogo de `valdemar.paso_norte`).
    private func openSmithy() {
        if store.profile.conversation(with: ValdemarQuests.smithID).isEmpty {
            openShop()
        } else {
            converse(ValdemarQuests.smithID, finally: .openShop)
        }
    }

    private func openShop() {
        joystick = .zero
        scene.setRunning(false)
        shop = ShopModel(store: store, level: progress.shopLevel, maxTier: store.profile.storyForgeTier,
                         heal: { [weak self] fraction in
                             guard let self else { return }
                             self.scene.heal(self.maxHP * fraction)
                         },
                         needsHealing: { [weak self] in (self?.hp ?? 0) < (self?.maxHP ?? 0) })
        overlay = .smithy
    }

    func closeSmithy() {
        overlay = .none
        applyEquipment()
        scene.setRunning(true)
    }

    // MARK: - Diálogos

    private func showIntroDialog() {
        guard progress.rescued.isEmpty, progress.killedSpawns.isEmpty, areaID == Valdehierro.townID else { return }
        show(Dialog(speaker: "Valdehierro", look: nil, lines: ValdemarDialogue.intro(race: store.profile.race)))
    }

    /// Muestra un diálogo (o lo pone en cola si ya hay otro).
    func show(_ dialog: Dialog) {
        if overlay == .dialog || overlay == .victory {
            dialogQueue.append(dialog)
            return
        }
        joystick = .zero
        scene.setRunning(false)
        self.dialog = dialog
        overlay = .dialog
    }

    func advanceDialog() {
        guard var current = dialog else { return }
        if current.isLast {
            dialog = nil
            overlay = .none
            for action in current.onClose { perform(action) }
            if overlay == .none, !dialogQueue.isEmpty {
                show(dialogQueue.removeFirst())
            }
            if overlay == .none { scene.setRunning(true) }
        } else {
            current.index += 1
            dialog = current
        }
    }

    private func perform(_ action: DialogAction) {
        switch action {
        case .rescue(let id):
            completeRescue(id)
        case .accept(let id):
            if store.profile.accept(id), let quest = World.quest(id) {
                showToast(ValdemarDialogue.newQuest(quest.title))
            }
            report(store.profile.syncStory())
        case .deliver(let id):
            if let delivery = store.profile.deliver(id) { reportDelivery(delivery) }
            report(store.profile.syncStory())
        case .read(let id):
            report(store.profile.record(.read(npcID: id)))
        case .converse(let id):
            converse(id, continuing: true)
        case .openShop:
            openShop()
        }
    }

    func npcReached(_ npc: NPC) {
        guard overlay == .none else { return }
        let needsRescue = (npc.role == .villager || npc.role == .princess) && !store.profile.isRescued(npc.id)
        if needsRescue, !npc.thanks.isEmpty {
            let lines = ValdemarDialogue.withRaceLine(npc.thanks, dialogID: npc.id, race: store.profile.race)
            show(Dialog(speaker: npc.name, look: npc.look, lines: lines, onClose: [.rescue(npc.id), .converse(npc.id)]))
        } else if npc.role == .clue {
            // Entera la primera vez; al releerla, más corta (`npc.cartaAlcalde.otra_vez`).
            show(Dialog(speaker: npc.name, look: nil, lines: store.profile.clueLines(for: npc), onClose: [.read(npc.id)]))
        } else {
            converse(npc.id)
        }
    }

    /// Habla con alguien: cuenta para `talk`, entrega lo cumplido, ofrece lo nuevo; si no hay nada, su línea de siempre.
    /// - Parameters:
    ///   - continuing: tras otro diálogo con él (no repite el recordatorio ni la línea de siempre).
    ///   - finally: lo que pasa cuando ya no queda nada que decir (abrir la tienda del herrero).
    private func converse(_ id: String, continuing: Bool = false, finally: DialogAction? = nil) {
        report(store.profile.record(.talked(npcID: id)))
        // El NPC del área actual: así dentro de casa se oyen sus líneas de casa y no las de la calle.
        let npc = currentArea.npcs.first { $0.id == id } ?? World.npc(id)
        let isSmith = id == ValdemarQuests.smithID
        let speaker = isSmith ? ValdemarDialogue.smithName : (npc?.name ?? id)
        let look = npc?.look
        let then: [DialogAction] = [.converse(id)] + (finally.map { [$0] } ?? [])
        switch store.profile.conversation(with: id).first {
        case .deliver(let questID)?:
            let quest = World.quest(questID)
            show(Dialog(speaker: speaker, look: look, lines: quest?.turnIn.nilIfEmpty ?? ["¡Gracias! Te lo has ganado."],
                        onClose: [.deliver(questID)] + then))
        case .offer(let questID)?:
            guard let quest = World.quest(questID) else { return }
            var lines = ValdemarQuests.offerLines(for: quest, profile: store.profile)
            if isSmith { lines = ValdemarDialogue.withRaceLine(lines, dialogID: id, race: store.profile.race) }
            var dialog = Dialog(speaker: speaker, look: look, lines: lines, onClose: [.accept(questID)] + then)
            if isSmith { dialog.renameAt = (ValdemarDialogue.epilogueRenameAt, ValdemarDialogue.smithFullName) }
            show(dialog)
        case .remind(let questID)? where !continuing:
            let quest = World.quest(questID)
            show(Dialog(speaker: speaker, look: look,
                        lines: [quest?.reminder ?? "¿Cómo va lo mío? \(quest?.summary ?? "")"], onClose: finally.map { [$0] } ?? []))
        default:
            if continuing {
                if let finally { perform(finally) }
                return
            }
            if let finally {
                perform(finally)
                return
            }
            guard let npc else { return }
            show(Dialog(speaker: npc.name, look: npc.look, lines: idleLines(npc)))
        }
    }

    /// Lo que dice un NPC cuando no hay nada de misiones.
    private func idleLines(_ npc: NPC) -> [String] {
        if let lines = store.profile.idleLines(for: npc) { return lines }
        switch npc.role {
        case .princess: return ["Valdehierro te debe todo, héroe."]
        case .questGiver: return npc.thanks.nilIfEmpty ?? [npc.plea]
        case .clue: return store.profile.clueLines(for: npc)
        case .villager:
            // En la calle, sus frases de calle; en casa, el agradecimiento de siempre.
            if !currentArea.isInterior, let lines = npc.thanks.nilIfEmpty { return lines }
            return ["¡Gracias otra vez! El pueblo vuelve a la vida."]
        }
    }

    /// Un jefe ve al héroe por primera vez: su presentación (`valdemar.md` §7). Queda apuntada en el perfil, así que
    /// no se repite al volver al área ni en otra sesión.
    func bossSpotted(_ enemy: EnemyDefinition) {
        guard let intro = ValdemarDialogue.bossIntros[enemy.id], store.profile.markBossIntroSeen(enemy.id) else { return }
        store.save()
        show(Dialog(speaker: intro.speaker, look: nil, lines: intro.lines))
    }

    private func completeRescue(_ id: String) {
        guard let npc = Valdehierro.interiors.flatMap(\.npcs).first(where: { $0.id == id }) else { return }
        store.profile.grant(npc.reward)
        var town = store.profile.town
        if npc.role == .princess {
            town.princessRescued = true
        } else {
            town.rescued.insert(npc.id)
        }
        store.profile.town = town

        var message = "¡\(npc.name.components(separatedBy: ",").first ?? npc.name) a salvo! +\(npc.reward.gold) oro"
        if let partID = npc.reward.partID, let part = PartCatalog.part(partID) { message += " · \(part.name)" }
        showToast(message)
        report(store.profile.syncStory())

        if npc.role == .princess {
            overlay = .victory
            scene.setRunning(false)
        }
    }

    func closeVictory() {
        overlay = .none
        if !dialogQueue.isEmpty { show(dialogQueue.removeFirst()) }
        if overlay == .none { scene.setRunning(true) }
    }

    // MARK: - Historia: avisos de misiones

    @ObservationIgnored private var castleWasOpen: Bool?

    /// Avisa de lo que ha cambiado en las misiones y pone la escena al día.
    private func report(_ update: StoryUpdate) {
        let profile = store.profile
        for id in update.accepted {
            if let quest = World.quest(id) { showToast(ValdemarDialogue.newQuest(quest.title)) }
        }
        for delivery in update.delivered {
            reportDelivery(delivery)
            // Las que se entregan solas cuentan su final aquí (`liberar`: el Capitán aparece).
            if let quest = World.quest(delivery.questID), let lines = quest.turnIn.nilIfEmpty {
                show(Dialog(speaker: quest.autoAccept ? "Valdehierro" : World.npcShortName(quest.giverID), look: nil, lines: lines))
            }
        }
        for id in update.advanced where !update.delivered.contains(where: { $0.questID == id }) {
            guard let quest = World.quest(id), profile.isActive(quest) else { continue }
            if profile.isComplete(quest), !quest.completesOnLastObjective {
                showToast(ValdemarDialogue.objectiveDone(World.npcShortName(quest.giverID)))
            } else if case .talk(let npc)? = profile.nextObjective(of: quest), npc != ValdemarQuests.smithID {
                showToast(ValdemarDialogue.objectiveDone(World.npcShortName(npc)))
            }
        }
        let open = profile.isCastleOpen()
        if castleWasOpen == false, open, !profile.town.princessRescued {
            show(Dialog(speaker: "Valdehierro", look: nil, lines: ValdemarQuests.castleOpensLines))
        }
        castleWasOpen = open
        refreshScene()
        store.save()
    }

    private func reportDelivery(_ delivery: QuestDelivery) {
        guard let quest = World.quest(delivery.questID) else { return }
        showToast(ValdemarDialogue.questDone(quest.title, xp: delivery.xp, gold: delivery.gold))
        if delivery.levelsGained > 0 { leveledUp() }
        switch delivery.questID {
        case ValdemarQuests.hilos: showToast(ValdemarDialogue.mayorOpened)
        case ValdemarQuests.pasoNorte: ValdemarDialogue.northPassOpened.forEach(showToast)
        case ValdemarQuests.abadia where !store.profile.isCastleOpen(): showToast(ValdemarDialogue.abbeyDoneWithoutRocks)
        default: break
        }
    }

    private func leveledUp() {
        let oldMax = maxHP
        hp += max(0, store.profile.totalStats.maxHP - oldMax)
        applyEquipment()
        scene.levelUpEffect(store.profile.characterLevel)
    }

    // MARK: - Pausa y muerte

    func pause() {
        guard overlay == .none else { return }
        joystick = .zero
        scene.setRunning(false)
        overlay = .paused
    }

    func resume() {
        guard overlay == .paused else { return }
        overlay = .none
        applyEquipment()
        scene.setRunning(true)
    }

    /// Reaparece en el punto seguro del área (campo) o en la Puerta sur (pueblo e interiores).
    func respawn() {
        overlay = .none
        hp = store.profile.totalStats.maxHP
        let point = World.respawnPoint(afterDyingIn: areaID)
        enter(World.area(point.areaID) ?? Valdehierro.town, at: point.tile, animated: false)
        scene.revive()
        applyEquipment()
        scene.setRunning(true)
    }

    // MARK: - Avisos

    /// Aviso corto arriba; si llegan varios seguidos, salen uno detrás de otro.
    func showToast(_ text: String) {
        lastToast = text
        if toast != nil, toastTask != nil {
            if !toastQueue.contains(text), toast != text { toastQueue.append(text) }
            return
        }
        toast = text
        toastTask?.cancel()
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled, let self else { return }
            self.toastTask = nil
            if self.toastQueue.isEmpty {
                self.toast = nil
            } else {
                self.toast = nil
                self.showToast(self.toastQueue.removeFirst())
            }
        }
    }

    private func showBanner(_ text: String) {
        areaBanner = text
        bannerTask?.cancel()
        bannerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            self?.areaBanner = nil
        }
    }

    // MARK: - CombatDelegate

    func heroHPChanged(hp: Double, maxHP: Double) {
        self.hp = hp
        self.maxHP = maxHP
        updatePlaceName()
    }

    func heroWasHit() {
        #if os(iOS)
        haptics.impactOccurred()
        #endif
    }

    func heroDied() {
        joystick = .zero
        let area = currentArea
        deathMessage = ValdemarDialogue.death(inField: area.isField ? area.name : nil)
        overlay = .dead
        store.save()
    }

    func enemyKilled(_ enemy: EnemyDefinition) {
        if enemy.isBoss { store.profile.defeatedBosses.insert(enemy.id) }
    }

    func spawnKilled(_ id: String, enemy: EnemyDefinition, at tile: TilePoint) {
        let area = currentArea
        let level = area.level(at: tile)
        store.profile.earnGold(StoryEconomy.killGold(level: level, isBoss: enemy.isBoss))
        // Los de campo que reaparecen dan menos XP (`Leveling.respawningMultiplier`).
        let respawns = area.isField && area.spawns.first(where: { $0.id == id }).map { !area.isPermanent($0) } == true
        let xp = Leveling.storyXPForKill(enemyLevel: level, heroLevel: store.profile.characterLevel, isBoss: enemy.isBoss,
                                         respawns: respawns)
        if store.profile.gainXP(xp) > 0 { leveledUp() }

        let spawn = area.spawns.first { $0.id == id }
        if area.isField {
            if spawn.map(area.isPermanent) == true {
                var town = store.profile.town
                town.killedSpawns.insert(id)
                store.profile.town = town
            }
            if let zone = store.profile.noteFieldKill(at: tile, in: area, dead: scene.fieldDeadIDs.union([id])) {
                let bonus = store.profile.earnGold(StoryEconomy.zoneGold(level: zone.level))
                showToast(ValdemarDialogue.zoneLiberated(zone.name, gold: bonus))
            }
        } else {
            let wasLiberated = area.zone(at: tile).map { progress.isLiberated($0, in: area) } ?? true
            var town = store.profile.town
            town.killedSpawns.insert(id)
            store.profile.town = town
            if !area.isInterior, let zone = area.zone(at: tile), !wasLiberated, progress.isLiberated(zone, in: area) {
                let bonus = store.profile.earnGold(StoryEconomy.zoneGold(level: zone.level))
                showToast(ValdemarDialogue.zoneLiberated(zone.name, gold: bonus))
            } else if area.isInterior, progress.isCleared(area) {
                showToast(area.id == "mayor" ? ValdemarDialogue.mayorCleared : ValdemarDialogue.roomCleared)
            }
        }
        report(store.profile.record(.killed(enemyID: enemy.id, areaID: area.id)))
    }

    func mineralCollected(_ mineral: Mineral) {
        store.profile.addMineral(mineral)
    }

    func partCollected(_ part: WeaponPart) {
        store.profile.addPart(part.id)
        showToast("¡Pieza especial: \(part.name)!")
        store.save()
    }
}

extension Array {
    /// nil si está vacío (para elegir un texto por defecto).
    var nilIfEmpty: [Element]? { isEmpty ? nil : self }
}
