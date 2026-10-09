import Foundation

// MARK: - Mundo: continentes, áreas y salidas
//
// Tipos que comparten el map-designer (rellena áreas, salidas y mazmorras), el character-designer, el
// story-writer y el game-programmer. Las reglas (viajar, bloqueos, reaparecer) están en `WorldRules.swift`
// y las misiones en `QuestEngine.swift`. Documentación: `assets/world/continentes/valdemar/contrato.md`.

/// Qué clase de área es. Decide si es interior (`AreaMap.isInterior`) y, en la fase 1, qué monstruos reaparecen.
public enum AreaKind: String, Codable, CaseIterable, Sendable {
    /// La capital de un continente (Valdehierro). Monstruos permanentes.
    case town
    /// El interior de un edificio. Monstruos permanentes; se sale por la puerta `D`.
    case interior
    /// Exterior de campo (Huertos, Robleda…). Los monstruos que no son jefe reaparecen (fase 1).
    case field
}

/// Cómo se dibujan las casillas de un área (`.` = hierba en Valdemar, roca en Rocaforja…).
/// Lo interpreta el arte de la app; cada continente añadirá el suyo.
public enum Biome: String, Codable, CaseIterable, Sendable {
    /// Praderas, robledales y granjas (verdes y ocres). También el pueblo de Valdehierro.
    case valdemar
}

/// Condición cerrada de una salida o de una bajada. Mientras no se cumple, el héroe no pasa y ve un aviso.
public enum ExitLock: Hashable, Sendable {
    /// Una zona (id de `Zone`) del área donde está la salida tiene que estar liberada.
    case zoneLiberated(String)
    /// Una misión tiene que estar completada.
    case questDone(String)
    /// El castillo del continente tiene que estar abierto (condición de la fase 1).
    case castleOpen
    /// Lleva a un continente que aún no existe (id del continente): siempre cerrada, aviso "Próximamente".
    case comingSoon(String)
}

/// Salida de un área a otra: un grupo de casillas `>` del borde.
public struct AreaExit: Identifiable, Hashable, Sendable {
    /// Id estable, `<área corta>.<punto cardinal>`: `town.oeste`, `huertos.sur`…
    public let id: String
    /// Casillas que activan la salida (las `>` del mapa).
    public let tiles: [TilePoint]
    /// Área de destino (id de `AreaMap`), o id de continente si el bloqueo es `comingSoon`.
    public let toArea: String
    /// Casilla de llegada en el destino (nil = no se viaja: solo aviso).
    public let arrival: TilePoint?
    /// Bloqueo (nil = siempre abierta).
    public let lock: ExitLock?
    /// Aviso cuando está cerrada (lo pule el story-writer).
    public let lockedMessage: String?

    public init(id: String, tiles: [TilePoint], toArea: String, arrival: TilePoint?,
                lock: ExitLock? = nil, lockedMessage: String? = nil) {
        self.id = id
        self.tiles = tiles
        self.toArea = toArea
        self.arrival = arrival
        self.lock = lock
        self.lockedMessage = lockedMessage
    }
}

/// Bajada a una mazmorra de historia: casillas `e` de un área (la cripta tiene dos, `ee`).
public struct DungeonEntrance: Hashable, Sendable {
    /// Id de la `StoryDungeon` (`valdemar.cripta`).
    public let dungeonID: String
    /// Casillas `e` que la activan. Al ganar se vuelve a la primera.
    public let tiles: [TilePoint]
    /// Bloqueo (nil = siempre abierta). Los calabozos: `.castleOpen`.
    public let lock: ExitLock?
    public let lockedMessage: String?

    public init(dungeonID: String, tiles: [TilePoint], lock: ExitLock? = nil, lockedMessage: String? = nil) {
        self.dungeonID = dungeonID
        self.tiles = tiles
        self.lock = lock
        self.lockedMessage = lockedMessage
    }
}

/// Un continente: tramo de niveles, capital, áreas, familia de minerales y tier de la forja.
public struct Continent: Identifiable, Sendable {
    public let id: String
    public let name: String
    /// Niveles del héroe que cubre (Valdemar 1-10).
    public let levels: ClosedRange<Int>
    /// Área capital (hub), p. ej. `town`.
    public let capitalID: String
    /// Todas sus áreas: capital, interiores y campos.
    public let areaIDs: [String]
    /// Familia de minerales que sueltan sus monstruos (fase 1, M6).
    public let minerals: [Mineral]
    /// Tier de material de su forja.
    public let tier: Int
    /// Misión final del continente: al completarla la forja vende también el tier siguiente.
    public let finalQuestID: String?
    /// Condición del castillo (`ExitLock.castleOpen`): todas deben cumplirse.
    public let castleRequires: [StoryCondition]
    /// Posición de cada área en el mapa del continente (columna, fila) para la pausa (M10).
    public let mapLayout: [String: TilePoint]

    public init(id: String, name: String, levels: ClosedRange<Int>, capitalID: String, areaIDs: [String],
                minerals: [Mineral], tier: Int, finalQuestID: String? = nil, castleRequires: [StoryCondition] = [],
                mapLayout: [String: TilePoint] = [:]) {
        self.id = id
        self.name = name
        self.levels = levels
        self.capitalID = capitalID
        self.areaIDs = areaIDs
        self.minerals = minerals
        self.tier = tier
        self.finalQuestID = finalQuestID
        self.castleRequires = castleRequires
        self.mapLayout = mapLayout
    }
}

/// Registro del mundo: continentes, áreas, mazmorras de historia y misiones.
public enum World {
    public static let valdemarID = "valdemar"

    public static let continents: [Continent] = [
        Continent(
            id: valdemarID, name: "Reino de Valdemar", levels: 1...10, capitalID: Valdehierro.townID,
            areaIDs: (Valdehierro.areas + Valdemar.areas).map(\.id),
            minerals: [.copper, .iron, .silver, .gold, .emerald], tier: 1,
            finalQuestID: ValdemarQuests.finalQuestID,
            castleRequires: ValdemarQuests.castleRequires,
            mapLayout: ValdemarQuests.mapLayout
        ),
    ]

    /// Todas las áreas explorables del juego.
    public static var areas: [AreaMap] { Valdehierro.areas + Valdemar.areas }

    public static func area(_ id: String) -> AreaMap? {
        areas.first { $0.id == id }
    }

    public static func continent(_ id: String) -> Continent? {
        continents.first { $0.id == id }
    }

    /// Mazmorras de historia (no confundir con los pisos de la arena, `Dungeon.floors`).
    public static var storyDungeons: [StoryDungeon] { Valdemar.dungeons }

    public static func storyDungeon(_ id: String) -> StoryDungeon? {
        storyDungeons.first { $0.id == id }
    }

    /// Todas las misiones.
    public static var quests: [Quest] { ValdemarQuests.all }

    public static func quest(_ id: String) -> Quest? {
        quests.first { $0.id == id }
    }
}
