import GameCore
import Observation

/// Estado global: perfil persistente y pantalla actual.
@Observable
final class GameStore {
    enum Screen: Equatable {
        case menu, worldMap, battle, forge, equipment
    }

    var profile: PlayerProfile
    private(set) var screen: Screen = .menu
    private(set) var battle: BattleSession?
    /// Nivel seleccionado en el mapa.
    var selectedLevel: Int

    let world = Worlds.forest
    @ObservationIgnored private let saveStore: SaveStore

    init(saveStore: SaveStore = SaveStore(url: SaveStore.defaultURL())) {
        self.saveStore = saveStore
        let profile = saveStore.load() ?? PlayerProfile.newGame()
        self.profile = profile
        self.selectedLevel = profile.highestUnlockedLevel
    }

    func save() {
        try? saveStore.save(profile)
    }

    func go(to screen: Screen) {
        if screen != .battle {
            battle?.scene.setRunning(false)
            battle = nil
        }
        if screen == .worldMap {
            selectedLevel = min(selectedLevel, profile.highestUnlockedLevel)
        }
        self.screen = screen
    }

    func startBattle(level number: Int) {
        guard let level = world.level(number), profile.isUnlocked(level: number) else { return }
        selectedLevel = number
        battle?.scene.setRunning(false)
        battle = BattleSession(level: level, store: self)
        screen = .battle
    }

    /// Pausa la partida si la app pasa a segundo plano.
    func appWentToBackground() {
        battle?.pause()
        save()
    }

    // MARK: - Equipo y forja

    func equip(_ item: Item) {
        profile.equip(item.id)
        save()
    }

    func sell(_ item: Item) {
        profile.sell(item.id)
        save()
    }

    func craft(_ recipe: CraftRecipe) throws -> CraftResult {
        var rng = SystemRandomNumberGenerator()
        let result = try profile.craft(recipe, using: &rng)
        save()
        return result
    }

    func resetProgress() {
        saveStore.delete()
        profile = .newGame()
        selectedLevel = 1
        save()
    }
}
