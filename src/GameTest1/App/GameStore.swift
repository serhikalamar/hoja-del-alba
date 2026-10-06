import Foundation
import GameCore
import Observation

/// Estado global: perfil persistente y pantalla actual.
@Observable
final class GameStore {
    enum Screen: Equatable {
        case menu, town, battle, forge, inventory, race
    }

    var profile: PlayerProfile
    private(set) var screen: Screen
    private(set) var battle: BattleSession?
    /// Exploración del pueblo en curso.
    private(set) var explore: ExploreSession?
    @ObservationIgnored private let saveStore: SaveStore

    init(saveStore: SaveStore = SaveStore(url: SaveStore.defaultURL())) {
        self.saveStore = saveStore
        let profile = saveStore.load() ?? PlayerProfile.newGame()
        self.profile = profile
        self.screen = profile.hasChosenRace ? .menu : .race
    }

    func save() {
        try? saveStore.save(profile)
    }

    func go(to screen: Screen) {
        if screen != .battle {
            battle?.scene.setRunning(false)
            battle = nil
        }
        if screen != .town {
            explore?.scene.setRunning(false)
            explore = nil
        }
        self.screen = screen
    }

    func startTown() {
        battle?.scene.setRunning(false)
        battle = nil
        explore = ExploreSession(store: self)
        screen = .town
    }

    /// Arena de oleadas infinitas.
    func startArena() {
        explore?.scene.setRunning(false)
        explore = nil
        battle?.scene.setRunning(false)
        battle = BattleSession(store: self)
        screen = .battle
    }

    /// Pausa la partida si la app pasa a segundo plano.
    func appWentToBackground() {
        battle?.pause()
        explore?.pause()
        save()
    }

    func chooseRace(_ race: Race) {
        profile.race = race
        profile.hasChosenRace = true
        save()
        go(to: .menu)
    }

    // MARK: - Equipo y ritual

    func equip(_ item: Item) {
        profile.equip(item.id)
        save()
    }

    func sell(_ item: Item) {
        profile.sell(item.id)
        save()
    }

    func craft(_ recipe: WeaponRecipe) throws -> CraftResult {
        var rng = SystemRandomNumberGenerator()
        let result = try profile.craft(recipe, using: &rng)
        save()
        return result
    }

    func setCustomSprite(_ sprite: CustomSprite?, for itemID: UUID) {
        profile.setCustomSprite(sprite, for: itemID)
        save()
    }

    func item(_ id: UUID) -> Item? {
        profile.inventory.first { $0.id == id }
    }

    func resetProgress() {
        saveStore.delete()
        profile = .newGame()
        save()
        go(to: .race)
    }
}
