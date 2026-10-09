import Foundation

// MARK: - Reglas del mundo (fase 1: M1, M2, M4, M9, M10)
//
// Viajar por las salidas `>`, bloqueos (`ExitLock`), puertas de la historia, reaparecer al morir, monstruos de
// campo que reaparecen y el cartel del área. Todo puro: la app (`ExploreSession`/`ExploreScene`) solo lo aplica.

/// Qué pasa al pisar una salida.
public enum TravelDecision: Equatable, Sendable {
    /// Se viaja a esa área y casilla.
    case travel(areaID: String, arrival: TilePoint)
    /// Cerrada: no se pasa y se ve el aviso.
    case blocked(String)
}

/// Qué pasa al pisar una bajada `e`.
public enum DungeonDecision: Equatable, Sendable {
    case enter(String)
    case blocked(String)
}

extension PlayerProfile {
    /// ¿Está abierto este bloqueo? `zoneLiberated` se refiere a una zona del área donde está la salida.
    public func isOpen(_ lock: ExitLock?, in area: AreaMap) -> Bool {
        guard let lock else { return true }
        switch lock {
        case .zoneLiberated(let id):
            if let zone = area.zones.first(where: { $0.id == id }) { return isLiberated(zone, in: area) }
            return isZoneLiberated(id)
        case .questDone(let id):
            return isQuestDone(id)
        case .castleOpen:
            return isCastleOpen(continentID: area.continentID)
        case .comingSoon:
            return false
        }
    }

    /// Pisar una salida: viajar o el aviso del bloqueo.
    public func travel(through exit: AreaExit, from area: AreaMap) -> TravelDecision {
        guard isOpen(exit.lock, in: area), let arrival = exit.arrival, World.area(exit.toArea) != nil else {
            return .blocked(exit.lockedMessage ?? Self.defaultLockMessage(exit.lock))
        }
        return .travel(areaID: exit.toArea, arrival: arrival)
    }

    /// Pisar una bajada a mazmorra de historia.
    public func enter(_ entrance: DungeonEntrance, in area: AreaMap) -> DungeonDecision {
        guard isOpen(entrance.lock, in: area), World.storyDungeon(entrance.dungeonID) != nil else {
            return .blocked(entrance.lockedMessage ?? Self.defaultLockMessage(entrance.lock))
        }
        return .enter(entrance.dungeonID)
    }

    static func defaultLockMessage(_ lock: ExitLock?) -> String {
        switch lock {
        case .comingSoon(let id)?: "\(id.capitalized): próximamente."
        case .castleOpen?: "El castillo sigue cerrado."
        default: "El camino está cerrado."
        }
    }

    /// Aviso de una puerta de edificio cerrada (nil = se puede entrar).
    public func doorLockMessage(_ building: Building) -> String? {
        guard building.interiorID != nil else { return building.lockedMessage ?? "\(building.name): no se puede entrar." }
        guard let rule = ValdemarQuests.doorLocks[building.id] else { return nil }
        return isOpen(rule.lock, in: World.area(Valdehierro.townID) ?? Valdehierro.town) ? nil : rule.message
    }

    /// Casillas que no se pueden pisar ahora mismo por la historia, con su aviso: puertas cerradas, la escalinata del
    /// castillo, salidas y bajadas bloqueadas. (Las salidas y bajadas abiertas se pisan y hacen viajar.)
    public func lockedTiles(in area: AreaMap) -> [TilePoint: String] {
        var locked: [TilePoint: String] = [:]
        if !area.isInterior {
            for building in area.buildings {
                guard let message = doorLockMessage(building) else { continue }
                for tile in building.doorTiles { locked[tile] = message }
            }
        }
        if area.kind == .town, !isCastleOpen(continentID: area.continentID) {
            let message = ValdemarQuests.stairsMessage(self)
            for tile in area.tiles(of: .stairs) { locked[tile] = message }
        }
        for exit in area.exits {
            guard case .blocked(let message) = travel(through: exit, from: area) else { continue }
            for tile in exit.tiles { locked[tile] = message }
        }
        for entrance in area.dungeonEntrances {
            guard case .blocked(let message) = enter(entrance, in: area) else { continue }
            for tile in entrance.tiles { locked[tile] = message }
        }
        return locked
    }

    /// NPC que se ven en un área: los que no tienen condición o la cumplen. En los interiores, los aldeanos
    /// siguen en su casa también después del rescate.
    public func visibleNPCs(in area: AreaMap) -> [NPC] {
        area.npcs.filter { npc in npc.appearsWhen.map(isMet) ?? true }
    }

    /// Apunta que el héroe está en un área (para guardar y para el mapa del continente).
    public mutating func arrive(at areaID: String) {
        currentAreaID = areaID
        var visited = visitedAreaIDs ?? []
        visited.insert(areaID)
        visitedAreaIDs = visited
    }

    /// Gana una mazmorra de historia. Devuelve si era la primera vez.
    @discardableResult
    public mutating func winDungeon(_ id: String) -> Bool {
        var won = wonDungeons ?? []
        let first = won.insert(id).inserted
        wonDungeons = won
        return first
    }

    /// Apunta que un jefe ya se ha presentado. Devuelve si era la primera vez (entonces se muestra su presentación).
    @discardableResult
    public mutating func markBossIntroSeen(_ enemyID: String) -> Bool {
        var seen = seenBossIntros ?? []
        let first = seen.insert(enemyID).inserted
        seenBossIntros = seen
        return first
    }

    /// Primera vez que se entra en un área: su escena corta, si la tiene (`escena.paso.entrar`).
    /// Llamar antes de `arrive(at:)`, que la apunta como visitada.
    public func firstVisitScene(_ areaID: String) -> (speaker: String, lines: [String])? {
        guard !(visitedAreaIDs ?? []).contains(areaID) else { return nil }
        return ValdemarDialogue.firstVisitScenes[areaID]
    }

    /// Lo que se lee en una pista (`role: .clue`): entera la primera vez y siempre que una misión espere leerla;
    /// después, su `talk` (`npc.cartaAlcalde.otra_vez`) o, si no tiene, otra vez entera.
    public func clueLines(for npc: NPC) -> [String] {
        let full = npc.thanks.isEmpty ? [npc.plea] : npc.thanks
        guard (readClueIDs ?? []).contains(npc.id), marker(for: npc.id) == nil,
              let again = idleLines(for: npc), !again.isEmpty else { return full }
        return again
    }

    /// Apunta un monstruo de campo muerto y libera su zona si es la primera vez que queda vacía.
    /// `dead` = monstruos de campo muertos ahora mismo (en memoria). Devuelve la zona liberada, si la hay.
    public mutating func noteFieldKill(at tile: TilePoint, in area: AreaMap, dead: Set<String>) -> Zone? {
        guard area.isField, let zone = area.zone(at: tile), !isLiberated(zone, in: area) else { return nil }
        let killed = town.killedSpawns.union(dead)
        guard area.spawns.filter({ zone.contains($0.position) }).allSatisfy({ killed.contains($0.id) }) else { return nil }
        var progress = town
        var zones = progress.fieldZonesLiberated ?? []
        zones.insert(zone.id)
        progress.fieldZonesLiberated = zones
        town = progress
        return zone
    }
}

extension AreaMap {
    /// ¿El monstruo no vuelve al morir? En el campo solo los jefes; en el pueblo e interiores, todos.
    public func isPermanent(_ spawn: Spawn) -> Bool {
        guard isField else { return true }
        return Bestiary.enemy(spawn.enemyID)?.isBoss ?? false
    }

    /// Niveles de sus zonas (o el del área si no tiene).
    public var levelRange: ClosedRange<Int> {
        let levels = zones.map(\.level)
        guard let low = levels.min(), let high = levels.max() else { return level...level }
        return low...high
    }

    /// Cartel al entrar: "Bosque de Robleda · 6-7".
    public var banner: String {
        let range = levelRange
        return "\(name) · " + (range.lowerBound == range.upperBound ? "\(range.lowerBound)" : "\(range.lowerBound)-\(range.upperBound)")
    }
}

extension World {
    /// Dónde reaparece el héroe al morir (M9): en el campo, el punto seguro del área; en el pueblo y sus interiores,
    /// la entrada del pueblo (Puerta sur); en una mazmorra de historia, como si muriera en el área de su bajada.
    public static func respawnPoint(afterDyingIn id: String) -> (areaID: String, tile: TilePoint) {
        if let dungeon = storyDungeon(id) { return respawnPoint(afterDyingIn: dungeon.entranceAreaID) }
        if let area = area(id), area.isField { return (area.id, area.safePoint ?? area.entry) }
        let home = area(id).flatMap { World.continent($0.continentID) } ?? continents[0]
        let capital = area(home.capitalID) ?? Valdehierro.town
        return (capital.id, capital.entry)
    }

    /// Dónde se sale de un interior: delante de la puerta del edificio que lleva a él.
    public static func outside(of interiorID: String) -> (areaID: String, tile: TilePoint)? {
        for area in areas where !area.isInterior {
            if let building = area.buildings.first(where: { $0.interiorID == interiorID }), let door = building.doorTiles.first {
                return (area.id, TilePoint(door.x, door.y + 1))
            }
        }
        return nil
    }

    /// Dónde aparece el héroe al cargar una partida guardada en un área.
    public static func startPoint(in area: AreaMap) -> TilePoint {
        area.isField ? (area.safePoint ?? area.entry) : area.entry
    }
}

// MARK: - Monstruos de campo que reaparecen (M2)

/// Monstruos de campo muertos (en memoria, no se guardan): vuelven al volver a entrar en el área, o
/// `delay` segundos después de morir si el héroe está a más de `minDistance` casillas.
public struct FieldRespawn: Sendable {
    public static let delay: TimeInterval = 90
    public static let minDistance: Double = 10

    /// Spawn → momento de la muerte.
    public private(set) var deaths: [String: TimeInterval] = [:]

    public init() {}

    public var deadIDs: Set<String> { Set(deaths.keys) }

    public mutating func died(_ spawnID: String, at time: TimeInterval) { deaths[spawnID] = time }

    /// Al entrar (o volver) a un área: todos vivos otra vez.
    public mutating func reset() { deaths.removeAll() }

    /// Los que ya pueden volver (y los quita de la lista de muertos).
    public mutating func due(in area: AreaMap, now: TimeInterval, hero: TilePoint) -> [Spawn] {
        let ready = area.spawns.filter { spawn in
            guard let died = deaths[spawn.id], now - died >= Self.delay else { return false }
            let dx = Double(spawn.position.x - hero.x), dy = Double(spawn.position.y - hero.y)
            return (dx * dx + dy * dy).squareRoot() > Self.minDistance
        }
        for spawn in ready { deaths[spawn.id] = nil }
        return ready
    }
}
