import Foundation
import Testing
@testable import GameCore

/// Mapa del continente de la pausa: colocación de las áreas, caminos entre salidas, iconos y marcas de misión.
@Suite("Mapa del continente")
struct ContinentMapTests {
    static var valdemar: Continent { World.continent(World.valdemarID)! }
    static var layout: ContinentLayout { valdemar.placement }

    @Test func everyAreaOfTheSchemeIsPlacedWithItsRealSize() {
        let layout = Self.layout
        #expect(Set(layout.areaIDs) == Set(Self.valdemar.mapLayout.keys))
        for id in layout.areaIDs {
            let frame = layout.frame(of: id)!, area = World.area(id)!
            #expect(frame.width == area.width && frame.height == area.height, "\(id)")
            #expect(frame.x >= layout.margin && frame.y >= layout.margin, "\(id) se sale por arriba o la izquierda")
            #expect(frame.maxX <= layout.width - layout.margin && frame.maxY <= layout.height - layout.margin, "\(id) se sale")
        }
    }

    @Test func areasNeverOverlapAndKeepTheGap() {
        let layout = Self.layout
        for (i, a) in layout.areaIDs.enumerated() {
            for b in layout.areaIDs.dropFirst(i + 1) {
                let sep = layout.frame(of: a)!.separation(from: layout.frame(of: b)!)
                #expect(sep >= layout.gap, "\(a) y \(b) a \(sep) casillas")
            }
        }
    }

    @Test func gridOrderIsRespected() {
        let layout = Self.layout, grid = Self.valdemar.mapLayout
        for a in layout.areaIDs {
            for b in layout.areaIDs where a != b {
                let fa = layout.frame(of: a)!, fb = layout.frame(of: b)!
                // Filas en franjas: lo de una fila más arriba acaba antes de que empiece lo de abajo.
                if grid[a]!.y < grid[b]!.y { #expect(fa.maxY <= fb.y, "\(a) debería quedar encima de \(b)") }
                // En la misma fila, por columnas.
                if grid[a]!.y == grid[b]!.y, grid[a]!.x < grid[b]!.x { #expect(fa.maxX <= fb.x, "\(a) debería ir a la izquierda de \(b)") }
            }
        }
    }

    @Test func neighbouringExitsFaceEachOther() {
        let layout = Self.layout
        // Las salidas enfrentadas (sur↔norte, este↔oeste) quedan casi alineadas: el camino apenas dobla.
        for (fromID, toID) in [("town.sur", "robleda.norte"), ("town.este", "abadia.oeste"), ("town.oeste", "huertos.este"),
                               ("town.norte", "paso.sur"), ("abadia.sur", "pedregal.norte")] {
            let road = layout.roads.first { Set([$0.fromExitID, $0.toExitID]) == Set([fromID, toID]) }
            #expect(road != nil, "falta el camino \(fromID)–\(toID)")
            guard let road, let a = road.points.first, let b = road.points.last else { continue }
            let vertical = fromID.hasSuffix("sur") || fromID.hasSuffix("norte")
            let offset = vertical ? abs(a.x - b.x) : abs(a.y - b.y)
            #expect(offset <= 3, "\(road.id) desalineado \(offset) casillas")
            // El hueco entre franjas es `gap` más lo que una vecina de fila sea más alta.
            #expect(abs(vertical ? a.y - b.y : a.x - b.x) <= Double(layout.gap * 2), "\(road.id) demasiado largo")
        }
    }

    @Test func roadsJoinEveryConnectionAndStayOutsideTheAreas() {
        let layout = Self.layout
        let internalRoads = layout.roads.filter { !$0.isFrontier }
        // Cada salida entre áreas del esquema tiene su camino (una vez por pareja).
        for id in layout.areaIDs {
            for exit in World.area(id)!.exits where layout.frame(of: exit.toArea) != nil {
                #expect(internalRoads.contains { $0.fromExitID == exit.id || $0.toExitID == exit.id }, "\(exit.id) sin camino")
            }
        }
        #expect(Set(internalRoads.map(\.id)).count == internalRoads.count)
        for road in layout.roads {
            // Empieza en la boca de su salida, en el borde del área.
            let area = World.area(road.fromAreaID)!, exit = area.exits.first { $0.id == road.fromExitID }!
            let anchor = exit.edgeAnchor(in: area)!, frame = layout.frame(of: area.id)!
            #expect(road.points.first == MapPoint(Double(frame.x) + anchor.x, Double(frame.y) + anchor.y), "\(road.id)")
            // Ningún tramo cruza por dentro de un área.
            for (p, q) in zip(road.points, road.points.dropFirst()) {
                for step in 0...20 {
                    let t = Double(step) / 20
                    let s = MapPoint(p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t)
                    for other in layout.areaIDs {
                        #expect(!layout.frame(of: other)!.containsStrictly(s, inset: 0.5), "\(road.id) cruza \(other)")
                    }
                }
            }
        }
    }

    @Test func exitToAnotherContinentRunsToTheEdgeWithItsSign() {
        let layout = Self.layout
        let frontier = layout.roads.filter(\.isFrontier)
        #expect(frontier.map(\.fromExitID) == ["paso.norte"])
        let road = frontier[0]
        #expect(road.destinationID == "rocaforja")
        #expect(road.label == "Rocaforja · próximamente")
        #expect(road.points.last?.y == 0, "debe llegar al borde norte del mapa")
    }

    @Test func layoutIsDeterministic() {
        let a = Self.layout, b = Self.layout
        #expect(a.frames == b.frames)
        #expect(a.roads == b.roads)
        #expect(a.width == b.width && a.height == b.height)
    }

    @Test func pointsMapBothWays() {
        let layout = Self.layout
        let frame = layout.frame(of: Valdehierro.townID)!
        let p = layout.point(of: TilePoint(3, 4), in: Valdehierro.townID)!
        #expect(p == MapPoint(Double(frame.x) + 3.5, Double(frame.y) + 4.5))
        #expect(layout.areaID(at: p) == Valdehierro.townID)
        #expect(layout.areaID(at: MapPoint(1, 1)) == nil)
        #expect(layout.point(of: TilePoint(0, 0), in: "smithy") == nil, "los interiores no van en el mapa")
    }

    /// Un continente inventado (como uno futuro): solo con su esquema y sus salidas se coloca sin solapes y alineado.
    @Test func worksForAnyContinentFromItsData() {
        func field(_ id: String, _ w: Int, _ h: Int, exits: [AreaExit]) -> AreaMap {
            var area = AreaMap(id: id, name: id, rows: Array(repeating: String(repeating: ".", count: w), count: h),
                               buildings: [], zones: [], spawns: [], npcs: [], level: 1, entry: TilePoint(1, 1))
            area.exits = exits
            return area
        }
        let a = field("a", 30, 20, exits: [AreaExit(id: "a.este", tiles: [TilePoint(29, 5), TilePoint(29, 6)], toArea: "b", arrival: TilePoint(1, 15)),
                                           AreaExit(id: "a.sur", tiles: [TilePoint(10, 19)], toArea: "c", arrival: TilePoint(30, 1))])
        let b = field("b", 20, 30, exits: [AreaExit(id: "b.oeste", tiles: [TilePoint(0, 15), TilePoint(0, 16)], toArea: "a", arrival: TilePoint(28, 5))])
        let c = field("c", 40, 16, exits: [AreaExit(id: "c.norte", tiles: [TilePoint(30, 0)], toArea: "a", arrival: TilePoint(10, 18))])
        let areas = ["a": a, "b": b, "c": c]
        let continent = Continent(id: "prueba", name: "Prueba", levels: 1...2, capitalID: "a", areaIDs: ["a", "b", "c"],
                                  minerals: [], tier: 1, mapLayout: ["a": TilePoint(0, 0), "b": TilePoint(1, 0), "c": TilePoint(0, 1)])
        let layout = ContinentLayout(continent, areas: { areas[$0] })
        let fa = layout.frame(of: "a")!, fb = layout.frame(of: "b")!, fc = layout.frame(of: "c")!
        #expect(fa.separation(from: fb) >= layout.gap && fa.separation(from: fc) >= layout.gap && fb.separation(from: fc) >= layout.gap)
        // a.este (fila 5.5+…) frente a b.oeste: misma altura; a.sur frente a c.norte: misma columna.
        #expect(abs(Double(fa.y) + 6 - (Double(fb.y) + 16)) <= 1)
        #expect(abs(Double(fa.x) + 10.5 - (Double(fc.x) + 30.5)) <= 1)
        #expect(layout.roads.count == 2)
    }

    // MARK: Iconos y misiones

    @Test func landmarksComeFromTheAreaData() {
        let pins = World.landmarkPins(of: Self.valdemar)
        for area in Valdemar.areas {
            #expect(pins.contains { $0.kind == .safePoint && $0.spot == MapSpot(areaID: area.id, tile: area.safePoint!) }, "\(area.id)")
        }
        #expect(pins.contains { $0.kind == .dungeon("valdemar.cripta") && $0.spot.areaID == Valdemar.abadiaID })
        #expect(pins.contains { $0.kind == .dungeon("valdemar.calabozos") && $0.spot.areaID == Valdehierro.townID })
        let forge = pins.first { $0.kind == .forge }
        #expect(forge?.spot.areaID == Valdehierro.townID)
        // Encima de la puerta de la forja (dentro del edificio del pueblo).
        let smithy = Valdehierro.town.buildings.first { $0.style == .smithy }!
        #expect(forge.map { smithy.contains($0.spot.tile) } == true)
    }

    @Test func interiorsAreMarkedAtTheirDoor() {
        let spot = World.mapSpot(areaID: "smithy", tile: TilePoint(2, 2))
        let smithy = Valdehierro.town.buildings.first { $0.interiorID == "smithy" }!
        #expect(spot == MapSpot(areaID: Valdehierro.townID, tile: TilePoint(smithy.doorTiles[0].x, smithy.doorTiles[0].y + 1)))
        #expect(World.mapSpot(areaID: Valdemar.huertosID, tile: TilePoint(5, 6)) == MapSpot(areaID: Valdemar.huertosID, tile: TilePoint(5, 6)))
    }

    /// Partida con el pueblo liberado (como `-pantalla mapa`).
    static func storyProfile() -> PlayerProfile {
        var profile = PlayerProfile.newGame()
        profile.town.rescued = Valdehierro.villagerIDs
        profile.town.killedSpawns.formUnion(Valdehierro.town.spawns.filter { !$0.id.hasPrefix("courtyard") }.map(\.id))
        profile.syncStory()
        for id in [Valdemar.huertosID, Valdehierro.townID] { profile.arrive(at: id) }
        return profile
    }

    @Test func questMarkersSitOnTheirPeopleAndTheTrackedTarget() {
        var profile = Self.storyProfile()
        let offers = profile.questPins(in: Self.valdemar).filter { if case .questOffer = $0.kind { true } else { false } }
        #expect(!offers.isEmpty, "con el pueblo libre alguien ofrece misiones")
        for pin in offers {
            #expect(World.area(pin.spot.areaID)?.isInterior == false, "\(pin.title) marcado dentro de un interior")
        }
        // Al aceptar el molino, el objetivo son los granjeros zombi de los Huertos (primer objetivo), en su casilla.
        let accepted = profile.accept(ValdemarQuests.molino)
        #expect(accepted)
        let quest = World.quest(ValdemarQuests.molino)!
        let spot = profile.mapSpot(for: quest)
        let zombies = Valdemar.area(Valdemar.huertosID)!.spawns.filter { $0.enemyID == "zombieFarmer" }.map(\.position)
        #expect(spot?.areaID == Valdemar.huertosID && zombies.contains(spot!.tile))
        let pins = profile.questPins(in: Self.valdemar)
        if profile.trackedQuest?.id == quest.id {
            #expect(pins.contains { $0.kind == .questTarget(quest.id) && $0.spot == spot })
        }
    }

    @Test func areaCardSummarizesQuestsAndDungeons() {
        let profile = Self.storyProfile()
        let abadia = profile.mapSummary(of: Valdemar.abadiaID)!
        #expect(abadia.name == "Abadía de Valsombra")
        #expect(abadia.dungeons == ["valdemar.cripta"])
        #expect(abadia.hasSafePoint)
        #expect(!abadia.visited)
        let town = profile.mapSummary(of: Valdehierro.townID)!
        #expect(town.visited && town.hasForge && town.dungeons == ["valdemar.calabozos"])
        #expect(!town.offers.isEmpty, "las misiones del pueblo salen en su tarjeta")
        #expect(town.levelText.hasPrefix("Nv "))
        #expect(profile.hasVisitedOnMap(Valdemar.huertosID))
        #expect(!profile.hasVisitedOnMap(Valdemar.pasoID))
    }
}
