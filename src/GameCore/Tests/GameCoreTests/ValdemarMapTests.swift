import Foundation
import Testing
@testable import GameCore

/// Mapas de Valdemar (map-designer): las 5 áreas de campo, los cambios del pueblo y la casa del alcalde.
/// Complementa a `WorldTests` (contrato de datos) con lo que comprueba el diseño: borde cerrado, todo conectado,
/// spawns dentro de su zona, ids estables y la ruta de niveles.
@Suite("Mapas de Valdemar")
struct ValdemarMapTests {
    /// Casillas pisables alcanzables desde la entrada (los edificios son sólidos salvo su puerta).
    static func reachable(_ area: AreaMap) -> Set<TilePoint> {
        var seen: Set<TilePoint> = [area.entry]
        var queue = [area.entry]
        while let p = queue.popLast() {
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let q = TilePoint(p.x + dx, p.y + dy)
                guard q.x >= 0, q.y >= 0, q.x < area.width, q.y < area.height,
                      !seen.contains(q), area.isWalkable(q) else { continue }
                seen.insert(q)
                queue.append(q)
            }
        }
        return seen
    }

    static var fields: [AreaMap] { Valdemar.areas }

    @Test func fiveFieldAreasAreRegistered() {
        #expect(Valdemar.areas.map(\.id) == ["valdemar.huertos", "valdemar.robleda", "valdemar.abadia",
                                             "valdemar.pedregal", "valdemar.paso"])
        for area in Valdemar.areas {
            #expect(area.kind == .field, "\(area.id)")
            #expect(World.area(area.id) != nil, "\(area.id) no está en World")
            #expect(area.safePoint != nil, "\(area.id) sin punto seguro")
        }
        #expect(Valdemar.dungeons.map(\.id) == ["valdemar.cripta", "valdemar.calabozos"])
    }

    @Test func bordersAreClosedExceptExits() {
        // El pueblo no entra: su fila de abajo es hierba desde siempre (fuera del mapa ya es sólido).
        for area in Self.fields {
            for y in 0..<area.height {
                for x in 0..<area.width where x == 0 || y == 0 || x == area.width - 1 || y == area.height - 1 {
                    let tile = area.tile(x, y)
                    #expect(tile.isSolid || tile == .areaExit, "\(area.id): borde abierto en (\(x),\(y)) `\(tile.rawValue)`")
                }
            }
        }
    }

    @Test func everythingIsConnectedFromTheEntry() {
        for area in Self.fields + [Valdehierro.town] {
            let reach = Self.reachable(area)
            for y in 0..<area.height {
                for x in 0..<area.width {
                    let p = TilePoint(x, y)
                    if area.isWalkable(p) { #expect(reach.contains(p), "\(area.id): (\(x),\(y)) aislada") }
                }
            }
            for spawn in area.spawns { #expect(reach.contains(spawn.position), "\(spawn.id) inalcanzable") }
            for npc in area.npcs { #expect(reach.contains(npc.position), "\(npc.id) inalcanzable") }
            for exit in area.exits { #expect(exit.tiles.allSatisfy(reach.contains), "\(exit.id) inalcanzable") }
            for entrance in area.dungeonEntrances {
                #expect(entrance.tiles.allSatisfy(reach.contains), "\(entrance.dungeonID) inalcanzable")
            }
            if let safe = area.safePoint { #expect(reach.contains(safe), "punto seguro de \(area.id)") }
        }
    }

    @Test func spawnsHaveStableIDsAndSitInTheirZone() {
        for area in Self.fields {
            for (i, spawn) in area.spawns.enumerated() {
                #expect(spawn.id == "\(area.id).\(i + 1)", "id \(spawn.id) fuera de orden")
                #expect(area.zone(at: spawn.position) != nil, "\(spawn.id) fuera de zona")
            }
            for zone in area.zones {
                #expect(zone.id.hasPrefix(area.id + "."), "zona \(zone.id)")
                #expect(area.spawns.contains { zone.contains($0.position) }, "zona \(zone.id) sin monstruos")
            }
            // Ningún monstruo justo en la llegada: al entrar hay al menos 7 casillas de margen.
            let arrivals = World.areas.flatMap(\.exits).filter { $0.toArea == area.id }.compactMap(\.arrival)
            for arrival in arrivals + [area.entry] {
                for spawn in area.spawns {
                    let dx = Double(spawn.position.x - arrival.x), dy = Double(spawn.position.y - arrival.y)
                    #expect((dx * dx + dy * dy).squareRoot() >= 7, "\(spawn.id) pegado a la llegada (\(arrival.x),\(arrival.y))")
                }
            }
        }
    }

    @Test func spawnCountsAndBossesMatchTheDrafts() {
        let counts = Dictionary(uniqueKeysWithValues: Self.fields.map { ($0.id, $0.spawns.count) })
        #expect(counts == ["valdemar.huertos": 21, "valdemar.robleda": 21, "valdemar.abadia": 20,
                           "valdemar.pedregal": 19, "valdemar.paso": 6])
        let bosses = Self.fields.flatMap { area in area.spawns.filter { Bestiary.enemy($0.enemyID)?.isBoss == true } }
        #expect(Set(bosses.map(\.enemyID)) == ["ogre", "alphaWolf", "warlord"])
        #expect(bosses.count == 3)
    }

    @Test func difficultyFollowsTheRoute() {
        func levels(_ id: String) -> ClosedRange<Int> {
            let zones = World.area(id)!.zones.map(\.level)
            return zones.min()!...zones.max()!
        }
        #expect(levels("valdemar.huertos") == 5...6)
        #expect(levels("valdemar.robleda") == 6...7)
        #expect(levels("valdemar.abadia") == 7...8)
        #expect(levels("valdemar.pedregal") == 8...9)
        #expect(levels("valdemar.paso") == 10...10)
        #expect(Valdehierro.town.zones.first { $0.id == "courtyard" }?.level == 9)
        #expect(Valdehierro.area("mayor")?.level == 7)
        // Los jefes de campo están en la zona más difícil de su área.
        for area in Self.fields {
            let top = area.zones.map(\.level).max()!
            for spawn in area.spawns where Bestiary.enemy(spawn.enemyID)?.isBoss == true {
                #expect(area.level(at: spawn.position) == top, "\(spawn.id)")
            }
        }
    }

    @Test func exitsComeBackTheWayYouWent() {
        // Cada salida abierta tiene una vuelta: el destino tiene una salida hacia aquí cuya llegada está junto a la ida.
        for area in World.areas {
            for exit in area.exits where exit.arrival != nil {
                guard let destination = World.area(exit.toArea) else { continue }
                let back = destination.exits.filter { $0.toArea == area.id }
                #expect(!back.isEmpty, "\(exit.id): \(destination.id) no tiene salida de vuelta")
                let near = back.contains { b in
                    guard let a = exit.arrival else { return false }
                    return b.tiles.contains { abs($0.x - a.x) + abs($0.y - a.y) <= 4 }
                }
                #expect(near, "\(exit.id): la llegada no está junto a la salida de vuelta")
            }
        }
    }

    @Test func townChangesForTheContinent() {
        let town = Valdehierro.town
        #expect(town.entry == TilePoint(21, 33))
        #expect(Set(town.exits.map(\.id)) == ["town.oeste", "town.este", "town.sur", "town.norte"])
        #expect(town.exits.first { $0.id == "town.sur" }?.lock == nil)
        #expect(town.exits.first { $0.id == "town.oeste" }?.lock == .zoneLiberated("west"))
        #expect(town.exits.first { $0.id == "town.este" }?.lock == .zoneLiberated("east"))
        #expect(town.exits.first { $0.id == "town.norte" }?.lock == .questDone("valdemar.paso_norte"))
        #expect(town.dungeonEntrances.first?.dungeonID == "valdemar.calabozos")
        #expect(town.dungeonEntrances.first?.lock == .castleOpen)
        #expect(Valdehierro.building(leadingTo: "mayor")?.id == "mayor")
        // Los aldeanos de la calle son los mismos de las casas y solo salen tras su rescate.
        let street = town.npcs.filter { $0.role == .villager }
        #expect(Set(street.map(\.id)) == Valdehierro.villagerIDs)
        for npc in street {
            #expect(npc.appearsWhen == .rescued(npc.id), "\(npc.id)")
            #expect(town.building(at: npc.position) == nil, "\(npc.id) dentro de un edificio")
        }
        let captain = town.npcs.first { $0.id == "capitanGuardia" }
        #expect(captain?.role == .questGiver)
        #expect(captain?.appearsWhen == .questDone("valdemar.liberar"))
        // La casa del alcalde no tiene aldeano: la carta es una pista (no cuenta para el castillo).
        let letter = Valdehierro.area("mayor")?.npcs.first
        #expect(letter?.id == "cartaAlcalde" && letter?.role == .clue)
        #expect(Valdehierro.villagerIDs.count == 6)
    }
}
