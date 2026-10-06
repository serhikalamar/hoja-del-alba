import Foundation
import GameCore
import Observation

/// Opciones de desarrollo (ponlas a `false` para la versión final).
enum DevSettings {
    /// Todos los niveles del mundo disponibles desde el principio.
    static let unlockAllLevels = true
}

/// Estado global: perfil persistente y pantalla actual.
@Observable
final class GameStore {
    enum Screen: Equatable {
        case menu, worldMap, battle, forge, inventory, race
    }

    var profile: PlayerProfile
    private(set) var screen: Screen
    private(set) var battle: BattleSession?
    /// Nivel seleccionado en el mapa.
    var selectedLevel: Int

    let world = Worlds.village
    @ObservationIgnored private let saveStore: SaveStore

    init(saveStore: SaveStore = SaveStore(url: SaveStore.defaultURL())) {
        self.saveStore = saveStore
        var profile = saveStore.load() ?? PlayerProfile.newGame()
        Self.applyDevSettings(&profile, levels: Worlds.village.levels.count)
        self.profile = profile
        self.selectedLevel = profile.highestUnlockedLevel
        self.screen = profile.hasChosenRace ? .menu : .race
    }

    private static func applyDevSettings(_ profile: inout PlayerProfile, levels: Int) {
        if DevSettings.unlockAllLevels {
            profile.highestUnlockedLevel = levels
        }
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
        Self.applyDevSettings(&profile, levels: world.levels.count)
        selectedLevel = 1
        save()
        go(to: .race)
    }
}
