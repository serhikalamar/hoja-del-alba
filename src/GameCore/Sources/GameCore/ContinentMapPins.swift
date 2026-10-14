import Foundation

// MARK: - Mapa del continente: iconos, marcas de misión y tarjeta de cada área
//
// Todo lo que el mapa de la pausa señala, en casillas reales de un área exterior del continente (los interiores se
// marcan delante de la puerta de su edificio). La app lo pasa a casillas del continente con `ContinentLayout`.

/// Un sitio del mapa: área exterior y casilla.
public struct MapSpot: Hashable, Sendable {
    public let areaID: String
    public let tile: TilePoint

    public init(areaID: String, tile: TilePoint) {
        self.areaID = areaID
        self.tile = tile
    }
}

/// Qué señala un icono del mapa.
public enum MapPinKind: Hashable, Sendable {
    /// Hoguera: punto seguro del área (se reaparece aquí al morir).
    case safePoint
    /// Bajada a una mazmorra de historia (id de `StoryDungeon`).
    case dungeon(String)
    /// La forja del enano.
    case forge
    /// "!": alguien ofrece esta misión.
    case questOffer(String)
    /// "?": hay que volver a hablar con alguien (entregar la misión o su siguiente paso).
    case questTurnIn(String)
    /// Siguiente objetivo de la misión seguida.
    case questTarget(String)

    public var isQuest: Bool {
        switch self {
        case .questOffer, .questTurnIn, .questTarget: true
        default: false
        }
    }
}

/// Icono del mapa en su sitio real.
public struct MapPin: Identifiable, Hashable, Sendable {
    public let kind: MapPinKind
    public let spot: MapSpot
    /// Texto corto ("Cripta de la abadía", "Molino en llamas").
    public let title: String

    public var id: String { "\(kind)@\(spot.areaID).\(spot.tile.x).\(spot.tile.y)" }

    public init(kind: MapPinKind, spot: MapSpot, title: String) {
        self.kind = kind
        self.spot = spot
        self.title = title
    }
}

/// Lo que dice la tarjeta de un área al tocarla en el mapa.
public struct MapAreaSummary: Equatable, Sendable {
    public let areaID: String
    public let name: String
    public let levels: ClosedRange<Int>
    public let visited: Bool
    /// Misiones que alguien de aquí ofrece ("!").
    public let offers: [String]
    /// Misiones en curso con algo que hacer aquí (objetivo o entrega).
    public let active: [String]
    /// Mazmorras de historia que se bajan desde aquí (ids).
    public let dungeons: [String]
    public let hasForge: Bool
    public let hasSafePoint: Bool

    /// "Nv 6-7" o "Nv 10".
    public var levelText: String {
        levels.lowerBound == levels.upperBound ? "Nv \(levels.lowerBound)" : "Nv \(levels.lowerBound)-\(levels.upperBound)"
    }
}

extension World {
    /// Sitio de una casilla en el mapa: en un exterior, ella misma; en un interior, delante de la puerta de su edificio.
    public static func mapSpot(areaID: String, tile: TilePoint) -> MapSpot? {
        if let area = area(areaID), !area.isInterior { return MapSpot(areaID: areaID, tile: tile) }
        // Interior (o puerta sin interior propio, como la forja): delante de la puerta.
        return outside(of: areaID).map { MapSpot(areaID: $0.areaID, tile: $0.tile) }
    }

    /// Iconos fijos de un continente: hogueras (puntos seguros), bajadas a mazmorras y la forja.
    public static func landmarkPins(of continent: Continent) -> [MapPin] {
        var pins: [MapPin] = []
        for id in continent.areaIDs {
            guard let area = area(id), !area.isInterior else { continue }
            if area.isField, let safe = area.safePoint {
                pins.append(MapPin(kind: .safePoint, spot: MapSpot(areaID: id, tile: safe), title: "Punto seguro"))
            }
            for entrance in area.dungeonEntrances {
                guard let tile = entrance.tiles.first else { continue }
                pins.append(MapPin(kind: .dungeon(entrance.dungeonID), spot: MapSpot(areaID: id, tile: tile),
                                   title: placeName(entrance.dungeonID)))
            }
            for building in area.buildings where building.style == .smithy {
                let door = building.doorTiles.first ?? TilePoint(building.x, building.y)
                pins.append(MapPin(kind: .forge, spot: MapSpot(areaID: id, tile: TilePoint(door.x, door.y - 2)),
                                   title: building.name))
            }
        }
        return pins
    }
}

extension PlayerProfile {
    /// ¿Ha estado el héroe en esta área exterior (o en alguno de sus interiores)?
    public func hasVisitedOnMap(_ areaID: String) -> Bool {
        let visited = (visitedAreaIDs ?? []).union([self.areaID])
        if visited.contains(areaID) { return true }
        return visited.contains { World.outside(of: $0)?.areaID == areaID }
    }

    /// Dónde está ahora un NPC en el mapa: mejor en la calle que en su casa (los rescatados salen a la plaza).
    /// El herrero (`smithy`) está en su forja.
    public func mapSpot(ofNPC npcID: String) -> MapSpot? {
        var inside: MapSpot?
        for area in World.areas {
            guard let npc = visibleNPCs(in: area).first(where: { $0.id == npcID }) else { continue }
            if !area.isInterior { return MapSpot(areaID: area.id, tile: npc.position) }
            if inside == nil { inside = World.mapSpot(areaID: area.id, tile: npc.position) }
        }
        if let inside { return inside }
        // Quien no es un NPC sino un edificio (el herrero en su forja): delante de su puerta.
        return World.mapSpot(areaID: npcID, tile: TilePoint(0, 0))
    }

    /// Dónde hay que ir para el siguiente objetivo de una misión (o a entregarla), con casilla.
    public func mapSpot(for quest: Quest) -> MapSpot? {
        guard let next = nextObjective(of: quest) else { return mapSpot(ofNPC: quest.giverID) }
        switch next {
        case .rescue(let ids):
            return ids.first { !isRescued($0) }.flatMap { mapSpot(ofNPC: $0) }
        case .kill(let enemyIDs, _, let areaID):
            let areas = areaID.flatMap { World.area($0) }.map { [$0] } ?? World.areas
            for area in areas {
                let spawns = area.spawns.filter { enemyIDs.contains($0.enemyID) }
                guard !spawns.isEmpty else { continue }
                // El monstruo más cercano al centro del grupo.
                let cx = Double(spawns.map(\.position.x).reduce(0, +)) / Double(spawns.count)
                let cy = Double(spawns.map(\.position.y).reduce(0, +)) / Double(spawns.count)
                let pick = spawns.min {
                    hypot(Double($0.position.x) - cx, Double($0.position.y) - cy) < hypot(Double($1.position.x) - cx, Double($1.position.y) - cy)
                }!
                return World.mapSpot(areaID: area.id, tile: pick.position)
            }
            return areaID.flatMap { Self.centerSpot(of: $0) }
        case .defeat(let enemyID):
            for area in World.areas {
                if let spawn = area.spawns.first(where: { $0.enemyID == enemyID }) {
                    return World.mapSpot(areaID: area.id, tile: spawn.position)
                }
            }
            return World.storyDungeons.first { $0.bossID == enemyID }.flatMap { Self.entranceSpot(of: $0.id) }
        case .talk(let id), .read(let id):
            return mapSpot(ofNPC: id)
        case .clear(let areaID), .reach(let areaID):
            return Self.centerSpot(of: areaID)
        case .dungeon(let id):
            return Self.entranceSpot(of: id)
        }
    }

    /// Marcas de misión del mapa: "!" y "?" sobre quien corresponda y el objetivo de la misión seguida.
    public func questPins(in continent: Continent) -> [MapPin] {
        var pins: [MapPin] = []
        var marked = Set<String>()
        let ids = Set(continent.areaIDs)
        for area in World.areas where ids.contains(area.id) {
            for npc in visibleNPCs(in: area) where !marked.contains(npc.id) {
                guard let marker = marker(for: npc.id), let spot = mapSpot(ofNPC: npc.id) else { continue }
                marked.insert(npc.id)
                let quest = questFor(marker: marker, npcID: npc.id)
                pins.append(MapPin(kind: marker == .offer ? .questOffer(quest?.id ?? "") : .questTurnIn(quest?.id ?? ""),
                                   spot: spot, title: World.npcShortName(npc.id)))
            }
        }
        // El herrero no es un NPC del mapa: su "!"/"?" va en la forja.
        let smith = ValdemarQuests.smithID
        if !marked.contains(smith), let marker = marker(for: smith), let spot = mapSpot(ofNPC: smith),
           ids.contains(spot.areaID) || World.area(spot.areaID)?.continentID == continent.id {
            let quest = questFor(marker: marker, npcID: smith)
            pins.append(MapPin(kind: marker == .offer ? .questOffer(quest?.id ?? "") : .questTurnIn(quest?.id ?? ""),
                               spot: spot, title: "Herrero"))
        }
        if let quest = trackedQuest, let spot = mapSpot(for: quest),
           !pins.contains(where: { $0.spot == spot && $0.kind == .questTurnIn(quest.id) }) {
            pins.append(MapPin(kind: .questTarget(quest.id), spot: spot, title: quest.title))
        }
        return pins
    }

    /// Tarjeta de un área del mapa: nombre, niveles, misiones de aquí y mazmorras.
    public func mapSummary(of areaID: String) -> MapAreaSummary? {
        guard let area = World.area(areaID), let continent = World.continent(area.continentID) else { return nil }
        let pins = questPins(in: continent).filter { $0.spot.areaID == areaID }
        var offers: [String] = [], active: [String] = []
        for pin in pins {
            if case .questOffer(let id) = pin.kind, !id.isEmpty, !offers.contains(id) { offers.append(id) }
        }
        for quest in activeQuests {
            let here = mapSpot(for: quest)?.areaID == areaID
                || quest.objectives.contains { if case .kill(_, _, let a?) = $0 { a == areaID } else { false } }
            if here, !active.contains(quest.id) { active.append(quest.id) }
        }
        return MapAreaSummary(areaID: areaID, name: area.name, levels: area.levelRange, visited: hasVisitedOnMap(areaID),
                              offers: offers, active: active, dungeons: area.dungeonEntrances.map(\.dungeonID),
                              hasForge: area.buildings.contains { $0.style == .smithy },
                              hasSafePoint: area.isField && area.safePoint != nil)
    }

    /// La misión a la que se refiere un "!" o un "?" sobre alguien.
    private func questFor(marker: QuestMarker, npcID: String) -> Quest? {
        switch marker {
        case .offer:
            return World.quests.first { $0.giverID == npcID && !$0.autoAccept && isAvailable($0) }
        case .turnIn:
            return World.quests.first { quest in
                guard isActive(quest) else { return false }
                if quest.giverID == npcID, !quest.completesOnLastObjective, isComplete(quest) { return true }
                switch nextObjective(of: quest) {
                case .talk(let id)?, .read(let id)?: return id == npcID
                default: return false
                }
            }
        }
    }

    /// Centro de un área (o la puerta de un interior).
    private static func centerSpot(of areaID: String) -> MapSpot? {
        guard let area = World.area(areaID) else { return nil }
        if area.isInterior { return World.mapSpot(areaID: areaID, tile: area.entry) }
        return MapSpot(areaID: areaID, tile: TilePoint(area.width / 2, area.height / 2))
    }

    /// Bajada a una mazmorra de historia.
    private static func entranceSpot(of dungeonID: String) -> MapSpot? {
        for area in World.areas {
            if let entrance = area.dungeonEntrances.first(where: { $0.dungeonID == dungeonID }), let tile = entrance.tiles.first {
                return World.mapSpot(areaID: area.id, tile: tile)
            }
        }
        return nil
    }
}
