import Foundation
import GameCore
import Observation

/// Estado global: lista de personajes, personaje activo y pantalla actual.
@Observable
final class GameStore {
    enum Screen: Equatable {
        /// Selección de personaje (al abrir el juego).
        case characterSelect
        /// Creación de personaje.
        case characterCreate
        /// Modo historia (pueblo) y arena.
        case town, battle
    }

    /// Personaje con el que se juega. Durante una partida de arena es una copia desde cero (ver `startArena`).
    var profile: PlayerProfile
    /// El personaje de verdad mientras dura una partida de arena (roguelike: la partida no le afecta).
    private var stashedProfile: PlayerProfile?
    /// El personaje guardado (fuera de la arena, el mismo que `profile`).
    var character: PlayerProfile { stashedProfile ?? profile }
    var isArenaRun: Bool { stashedProfile != nil }
    private(set) var roster: Roster
    private(set) var screen: Screen
    private(set) var battle: BattleSession?
    /// Exploración del pueblo en curso.
    private(set) var explore: ExploreSession?
    @ObservationIgnored private let rosterStore: RosterStore
    /// Cuenta (Account/AccountManager): avisos al guardar y al borrar personajes, para subirlos a la nube.
    @ObservationIgnored var onCharacterSaved: ((_ saved: PlayerProfile, _ previous: PlayerProfile?) -> Void)?
    @ObservationIgnored var onCharacterDeleted: ((UUID) -> Void)?

    init(rosterStore: RosterStore = RosterStore(url: RosterStore.defaultURL(), legacy: SaveStore(url: SaveStore.defaultURL()))) {
        self.rosterStore = rosterStore
        let roster = rosterStore.load()
        self.roster = roster
        self.profile = roster.selected ?? PlayerProfile.newGame()
        self.screen = roster.characters.isEmpty ? .characterCreate : .characterSelect
    }

    /// Para pruebas: guarda junto a `saveStore`.
    convenience init(saveStore: SaveStore) {
        let url = saveStore.url.deletingPathExtension().appendingPathExtension("roster.json")
        self.init(rosterStore: RosterStore(url: url, legacy: saveStore))
    }

    func save() {
        // Sin personajes (pantalla de creación vacía) no hay nada que guardar: el perfil provisional no tiene nombre.
        if roster.characters.isEmpty, character.name == nil { return }
        if profile.characterID == nil { profile.characterID = UUID() }
        if var real = stashedProfile, real.characterID == nil {
            real.characterID = profile.characterID
            stashedProfile = real
        }
        let saved = character
        let previous = roster.characters.first { $0.characterID == saved.characterID }
        roster.upsert(saved)
        roster.selectedID = saved.characterID
        try? rosterStore.save(roster)
        onCharacterSaved?(saved, previous)
    }

    // MARK: - Personajes

    func select(_ characterID: UUID) {
        guard let character = roster.characters.first(where: { $0.characterID == characterID }) else { return }
        save()
        profile = character
        roster.selectedID = characterID
        try? rosterStore.save(roster)
    }

    @discardableResult
    func createCharacter(name: String, race: Race, appearance: Appearance) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard PlayerProfile.isValidName(trimmed), !roster.isNameTaken(trimmed),
              roster.characters.count < Roster.maxCharacters else { return false }
        if !roster.characters.isEmpty { save() }
        profile = PlayerProfile.newCharacter(name: trimmed, race: race, appearance: appearance)
        save()
        screen = .characterSelect
        return true
    }

    func deleteCharacter(_ characterID: UUID) {
        roster.remove(characterID)
        try? rosterStore.save(roster)
        onCharacterDeleted?(characterID)
        if let next = roster.selected {
            profile = next
            screen = .characterSelect
        } else {
            profile = PlayerProfile.newGame()
            screen = .characterCreate
        }
    }

    func go(to screen: Screen) {
        if screen != .battle { endArenaRun() }
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
        startTown(at: nil)
    }

    /// Modo historia en un área y casilla concretas (nil = donde se guardó), con un aviso opcional al llegar.
    func startTown(at start: (areaID: String, tile: TilePoint)?, message: String? = nil) {
        endArenaRun()
        battle?.scene.setRunning(false)
        battle = nil
        storyReturn = nil
        explore = ExploreSession(store: self, start: start, message: message)
        screen = .town
    }

    /// Bajada `e` desde la que se entró en la mazmorra de historia en curso.
    @ObservationIgnored private var storyReturn: (areaID: String, tile: TilePoint)?

    /// Mazmorra de historia (M8): una partida corta de la arena con el personaje de verdad.
    func startStoryDungeon(_ id: String, from areaID: String, at tile: TilePoint) {
        guard let dungeon = World.storyDungeon(id) else { return }
        endArenaRun()
        explore?.scene.setRunning(false)
        explore = nil
        battle?.scene.setRunning(false)
        storyReturn = (areaID, tile)
        save()
        battle = BattleSession(store: self, story: dungeon)
        screen = .battle
    }

    /// Fin de la mazmorra de historia: al ganar se vuelve a la bajada; al perder, al punto seguro del área.
    /// Al ganar o al salir desde la pausa (`abandoned`) se vuelve a la bajada; al perder, al punto seguro.
    func finishStoryDungeon(won: Bool, abandoned: Bool = false, message: String? = nil) {
        guard let dungeon = battle?.story else { return }
        let back = storyReturn ?? (dungeon.entranceAreaID, World.area(dungeon.entranceAreaID)?.entry ?? Valdehierro.town.entry)
        let start = won || abandoned ? back : World.respawnPoint(afterDyingIn: dungeon.id)
        save()
        startTown(at: start, message: message)
    }

    /// Arena de oleadas infinitas.
    func startArena() {
        explore?.scene.setRunning(false)
        explore = nil
        battle?.scene.setRunning(false)
        // Roguelike: cada partida empieza desde cero con una copia del héroe.
        endArenaRun()
        stashedProfile = profile
        profile = PlayerProfile.arenaRun(for: profile)
        battle = BattleSession(store: self)
        screen = .battle
    }

    /// Vuelve al personaje de verdad al salir de la arena.
    private func endArenaRun() {
        guard let real = stashedProfile else { return }
        stashedProfile = nil
        profile = real
    }

    /// Récord de la arena: lo único de la partida que se guarda en el personaje.
    func recordArenaWave(_ wave: Int) {
        profile.arenaBestWave = max(profile.arenaBestWave ?? 0, wave)
        if var real = stashedProfile {
            real.arenaBestWave = max(real.arenaBestWave ?? 0, wave)
            stashedProfile = real
        }
        save()
    }

    /// Pausa la partida si la app pasa a segundo plano.
    func appWentToBackground() {
        battle?.pause()
        explore?.pause()
        save()
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

    func unequip(_ slot: EquipmentSlot) {
        profile.unequip(slot)
        save()
    }

    func setDye(_ dye: UInt32, for item: Item) {
        profile.setDye(dye, for: item.id)
        save()
    }

    func craftArmor(_ recipe: ArmorRecipe) throws -> CraftResult {
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

    // MARK: - Cuenta (sincronización con la nube)

    /// Los cambios que bajan de la nube solo se aplican fuera de una partida.
    var canApplyCloudChanges: Bool { screen == .characterSelect || screen == .characterCreate }

    /// Aplica personajes bajados de la cuenta (o quita los borrados en otro dispositivo). No avisa a `onCharacterSaved`.
    @discardableResult
    func applyCloudChanges(upserts: [PlayerProfile], removals: [UUID]) -> Bool {
        guard canApplyCloudChanges else { return false }
        let wasEmpty = roster.characters.isEmpty
        for character in upserts { roster.upsert(character) }
        for id in removals { roster.remove(id) }
        if roster.selectedID == nil || !roster.characters.contains(where: { $0.characterID == roster.selectedID }) {
            roster.selectedID = roster.characters.first?.characterID
        }
        try? rosterStore.save(roster)
        profile = roster.selected ?? PlayerProfile.newGame()
        if roster.characters.isEmpty {
            screen = .characterCreate
        } else if wasEmpty {
            screen = .characterSelect
        }
        return true
    }

}
