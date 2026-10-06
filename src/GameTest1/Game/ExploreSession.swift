import GameCore
import Observation
import SpriteKit
#if os(iOS)
import UIKit
#endif

/// Una conversación en pantalla.
struct Dialog: Equatable {
    var speaker: String
    var look: String?
    var lines: [String]
    var index = 0
    /// Id del personaje cuyo rescate se completa al terminar.
    var completesRescueOf: String?

    var line: String { lines[min(index, lines.count - 1)] }
    var isLast: Bool { index >= lines.count - 1 }
}

/// Puente entre la escena de exploración y la interfaz.
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
    private(set) var shop: ShopModel?

    @ObservationIgnored var joystick: CGVector = .zero
    @ObservationIgnored let scene: ExploreScene
    @ObservationIgnored private unowned let store: GameStore
    @ObservationIgnored private var talkedTo: Set<String> = []
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    #if os(iOS)
    @ObservationIgnored private let haptics = UIImpactFeedbackGenerator(style: .light)
    #endif

    init(store: GameStore) {
        self.store = store
        scene = ExploreScene(size: CGSize(width: 844, height: 390))
        scene.scaleMode = .resizeFill
        scene.session = self
        scene.combatDelegate = self
        let stats = store.profile.totalStats
        hp = stats.maxHP
        maxHP = stats.maxHP
        enter(Valdehierro.town, at: Valdehierro.town.entry, animated: false)
        scene.setRunning(true)
        showIntroDialog()
    }

    var progress: TownProgress { store.profile.town }

    var rescuedCount: Int { progress.rescued.count }
    var villagerCount: Int { Valdehierro.villagerIDs.count }

    var liberatedZones: Int {
        Valdehierro.town.zones.filter { progress.isLiberated($0, in: Valdehierro.town) }.count
    }

    var objective: String {
        if progress.princessRescued { return "¡Valdehierro es libre! Explora y forja tu leyenda." }
        if progress.castleOpen { return "¡El castillo está abierto! Rescata a la princesa." }
        return "Rescata a los aldeanos: \(rescuedCount)/\(villagerCount)"
    }

    // MARK: - Áreas

    private func applyEquipment() {
        let profile = store.profile
        scene.prepareHero(stats: profile.totalStats, hp: hp, armorIcon: profile.equippedArmor?.icon ?? "armor_tunic",
                          weapon: profile.equippedWeapon, race: profile.race)
    }

    private func enter(_ area: AreaMap, at start: TilePoint, animated: Bool = true) {
        let load = { [self] in
            areaID = area.id
            scene.load(area, heroAt: start, progress: progress)
            applyEquipment()
            updatePlaceName(force: true)
        }
        if animated { scene.fade(load) } else { load() }
    }

    func doorTouched(_ building: Building) {
        guard overlay == .none, let interiorID = building.interiorID else { return }
        if interiorID == "smithy" {
            openSmithy()
            return
        }
        guard let area = Valdehierro.area(interiorID) else { return }
        enter(area, at: area.entry)
        showToast(area.name.uppercased())
    }

    func exitTouched() {
        guard overlay == .none, let building = Valdehierro.building(leadingTo: areaID), let door = building.doorTiles.first else { return }
        enter(Valdehierro.town, at: TilePoint(door.x, door.y + 1))
    }

    func lockedDoorTouched(_ building: Building?) {
        guard let building else { return }
        if building.style == .castle {
            showToast("La puerta del castillo está cerrada. Rescata a los \(villagerCount) aldeanos.")
        } else {
            showToast("\(building.name): está cerrada.")
        }
    }

    /// Nombre del lugar: interior o zona del pueblo donde está el héroe.
    private func updatePlaceName(force: Bool = false) {
        let area = Valdehierro.area(areaID) ?? Valdehierro.town
        let name = area.isInterior ? area.name : (area.zone(at: scene.heroFeetTile())?.name ?? "Valdehierro")
        if force || name != placeName { placeName = name }
    }

    // MARK: - Forja del enano

    private func openSmithy() {
        joystick = .zero
        scene.setRunning(false)
        shop = ShopModel(store: store, level: progress.shopLevel,
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

    // MARK: - Diálogos y rescates

    private func showIntroDialog() {
        guard progress.rescued.isEmpty, progress.killedSpawns.isEmpty else { return }
        show(Dialog(speaker: "Valdehierro", look: nil, lines: [
            "Los goblins han tomado Valdehierro.",
            "Libera las calles, entra en las casas y rescata a los aldeanos.",
            "Cuando todos estén a salvo, abrirán el castillo... donde el Rey Goblin tiene a la princesa.",
        ]))
    }

    private func show(_ dialog: Dialog) {
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
            if let id = current.completesRescueOf { completeRescue(id) }
            if overlay == .none { scene.setRunning(true) }
        } else {
            current.index += 1
            dialog = current
        }
    }

    func npcReached(_ npc: NPC) {
        guard overlay == .none, !talkedTo.contains(npc.id) else { return }
        talkedTo.insert(npc.id)
        let rescued = npc.role == .princess ? progress.princessRescued : progress.rescued.contains(npc.id)
        if rescued {
            show(Dialog(speaker: npc.name, look: npc.look, lines: [npc.role == .princess
                ? "Valdehierro te debe todo, héroe."
                : "¡Gracias otra vez! El pueblo vuelve a la vida."]))
        } else {
            show(Dialog(speaker: npc.name, look: npc.look, lines: npc.thanks, completesRescueOf: npc.id))
        }
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
        let castleWasOpen = progress.castleOpen
        store.profile.town = town
        store.save()
        scene.refresh(progress: progress)

        var message = "¡\(npc.name.components(separatedBy: ",").first ?? npc.name) a salvo! +\(npc.reward.gold) oro"
        if let partID = npc.reward.partID, let part = PartCatalog.part(partID) { message += " · \(part.name)" }
        showToast(message)

        if npc.role == .princess {
            overlay = .victory
            scene.setRunning(false)
        } else if !castleWasOpen && progress.castleOpen {
            show(Dialog(speaker: "Valdehierro", look: nil, lines: [
                "¡Todos los aldeanos están a salvo!",
                "A lo lejos, la gran puerta del castillo cruje y se abre...",
            ]))
        }
    }

    func closeVictory() {
        overlay = .none
        scene.setRunning(true)
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

    func respawn() {
        overlay = .none
        hp = store.profile.totalStats.maxHP
        enter(Valdehierro.town, at: Valdehierro.town.entry, animated: false)
        scene.revive()
        applyEquipment()
        scene.setRunning(true)
    }

    // MARK: - Avisos

    func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            self?.toast = nil
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
        overlay = .dead
        store.save()
    }

    func enemyKilled(_ enemy: EnemyDefinition) {
        if enemy.isBoss { store.profile.defeatedBosses.insert(enemy.id) }
    }

    func spawnKilled(_ id: String, enemy: EnemyDefinition, at tile: TilePoint) {
        let area = Valdehierro.area(areaID) ?? Valdehierro.town
        let level = area.level(at: tile)
        store.profile.earnGold(2 + level * 2 + (enemy.isBoss ? 40 * level : 0))
        let wasLiberated = area.zone(at: tile).map { progress.isLiberated($0, in: area) } ?? true
        var town = store.profile.town
        town.killedSpawns.insert(id)
        store.profile.town = town

        if !area.isInterior, let zone = area.zone(at: tile), !wasLiberated, progress.isLiberated(zone, in: area) {
            let bonus = store.profile.earnGold(40 * zone.level)
            showToast("¡\(zone.name) liberado! +\(bonus) oro")
        } else if area.isInterior, progress.isCleared(area) {
            showToast("¡Sala despejada! Habla con quien estaba atrapado.")
        }
        store.save()
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
