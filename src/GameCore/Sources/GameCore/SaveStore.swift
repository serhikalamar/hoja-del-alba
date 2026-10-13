import Foundation

/// Guarda el perfil como JSON en disco.
public struct SaveStore: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("GameTest1", isDirectory: true).appendingPathComponent("save-v2.json")
    }

    public func load() -> PlayerProfile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PlayerProfile.self, from: data)
    }

    public func save(_ profile: PlayerProfile) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(profile)
        try data.write(to: url, options: .atomic)
    }

    public func delete() {
        try? FileManager.default.removeItem(at: url)
    }
}

/// Lista de personajes (como la pantalla de selección de personaje).
public struct Roster: Codable, Equatable, Sendable {
    public var characters: [PlayerProfile] = []
    public var selectedID: UUID?

    public init(characters: [PlayerProfile] = [], selectedID: UUID? = nil) {
        self.characters = characters
        self.selectedID = selectedID
    }

    public static let maxCharacters = 8

    public var selected: PlayerProfile? {
        characters.first { $0.characterID == selectedID } ?? characters.first
    }

    /// Añade o sustituye un personaje (por su id).
    public mutating func upsert(_ profile: PlayerProfile) {
        if let index = characters.firstIndex(where: { $0.characterID == profile.characterID }) {
            characters[index] = profile
        } else {
            characters.append(profile)
        }
    }

    public mutating func remove(_ id: UUID) {
        characters.removeAll { $0.characterID == id }
        if selectedID == id { selectedID = characters.first?.characterID }
    }

    public func isNameTaken(_ name: String) -> Bool {
        characters.contains { $0.name?.lowercased() == name.lowercased() }
    }
}

/// Guarda la lista de personajes. Si no existe, migra la partida antigua de un solo personaje.
public struct RosterStore: Sendable {
    public let url: URL
    public let legacy: SaveStore?

    public init(url: URL, legacy: SaveStore? = nil) {
        self.url = url
        self.legacy = legacy
    }

    public static func defaultURL() -> URL {
        SaveStore.defaultURL().deletingLastPathComponent().appendingPathComponent("roster.json")
    }

    public func load() -> Roster {
        if let data = try? Data(contentsOf: url), let roster = try? JSONDecoder().decode(Roster.self, from: data) {
            return roster
        }
        // Migración: la partida de un solo personaje pasa a ser el primero de la lista.
        guard var old = legacy?.load() else { return Roster() }
        old.characterID = old.characterID ?? UUID()
        old.name = old.name ?? "Héroe"
        old.appearance = old.appearance ?? Appearance()
        return Roster(characters: [old], selectedID: old.characterID)
    }

    public func save(_ roster: Roster) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(roster).write(to: url, options: .atomic)
    }
}

extension PlayerProfile {
    /// Personaje nuevo creado en la pantalla de creación.
    public static func newCharacter(name: String, race: Race, appearance: Appearance) -> PlayerProfile {
        var profile = PlayerProfile.newGame(race: race)
        profile.characterID = UUID()
        profile.name = name
        profile.appearance = appearance
        profile.hasChosenRace = true
        return profile
    }

    /// Partida de arena (roguelike puro): el mismo héroe, pero desde cero — nivel 1, espada de entrenamiento,
    /// túnica y poco oro. Nada de lo que pase en la partida vuelve al personaje.
    public static func arenaRun(for hero: PlayerProfile) -> PlayerProfile {
        var run = PlayerProfile.newGame(race: hero.race)
        run.characterID = hero.characterID
        run.name = hero.name
        run.appearance = hero.appearance
        run.hasChosenRace = true
        run.gold = Int(TunedData.current.economy.arenaStartingGold)  // 50 (`economy.arenaStartingGold`)
        run.minerals = [:]
        run.parts = [:]
        run.discoveredAbilities = hero.discoveredAbilities
        return run
    }

    /// Nombre válido: 2-14 letras (se permiten espacios, guiones y apóstrofos dentro).
    public static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard (2...14).contains(trimmed.count), trimmed.first?.isLetter == true else { return false }
        return trimmed.allSatisfy { $0.isLetter || $0 == " " || $0 == "-" || $0 == "'" }
    }
}
