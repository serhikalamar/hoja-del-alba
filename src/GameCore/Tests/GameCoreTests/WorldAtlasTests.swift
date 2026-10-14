import Foundation
import Testing
@testable import GameCore

/// Mapa del mundo (Ardenia): los 6 continentes en su sitio, los futuros en gris con su boceto y las rutas entre ellos.
@Suite("Mapa del mundo")
struct WorldAtlasTests {
    static var world: WorldLayout { World.worldLayout }

    @Test func sixContinentsWithTheirIdsAndLevels() {
        #expect(World.atlas.map(\.id) == ["valdemar", "rocaforja", "lunaria", "cenizas", "escarcha", "umbral"])
        // Tramos de 10 niveles seguidos (continentes.md).
        let byLevel = World.atlas.sorted { $0.levels.lowerBound < $1.levels.lowerBound }
        #expect(byLevel.first?.levels == 1...10)
        for (a, b) in zip(byLevel, byLevel.dropFirst()) { #expect(a.levels.upperBound == b.levels.lowerBound) }
        #expect(byLevel.last?.levels.upperBound == 60)
        for entry in World.atlas { #expect(!entry.teaser.isEmpty, "\(entry.id) sin frase") }
        // Valdemar coincide con su registro jugable.
        #expect(World.atlasEntry(World.valdemarID)?.name == World.continent(World.valdemarID)?.name)
    }

    @Test func onlyValdemarIsPlayableToday() {
        let world = Self.world
        #expect(world.continents.count == 6)
        for c in world.continents {
            #expect(c.isPlayable == (c.id == World.valdemarID), "\(c.id)")
            if !c.isPlayable {
                #expect(!c.entry.plannedAreas.isEmpty, "\(c.id) sin boceto")
                #expect(Set(c.layout.areaIDs) == Set(c.entry.plannedAreas.map(\.id)))
                #expect(c.entry.plannedAreas.filter(\.isCapital).count >= 1, "\(c.id) sin capital")
            }
        }
        // Valdemar va con su mapa real, el mismo que el del continente.
        let valdemar = world.continent(World.valdemarID)!
        #expect(valdemar.layout.frames == World.continent(World.valdemarID)!.placement.frames)
    }

    /// Cuando un continente se registra con sus áreas pasa a verse con su mapa real (aquí, fingiendo que Rocaforja es Valdemar).
    @Test func aContinentBecomesDetailedWhenPlayable() {
        let real = World.continent(World.valdemarID)!
        let world = WorldLayout(playable: { id in id == "rocaforja" || id == World.valdemarID ? real : nil })
        #expect(world.continent("rocaforja")?.isPlayable == true)
        #expect(world.continent("rocaforja")?.layout.frames == real.placement.frames)
        #expect(world.continent("lunaria")?.isPlayable == false)
    }

    @Test func continentsDoNotOverlap() {
        let world = Self.world
        for (i, a) in world.continents.enumerated() {
            #expect(a.frame.x >= 0 && a.frame.y >= 0 && a.frame.maxX <= world.width && a.frame.maxY <= world.height, "\(a.id)")
            for b in world.continents.dropFirst(i + 1) {
                #expect(a.frame.separation(from: b.frame) >= 0, "\(a.id) pisa a \(b.id)")
                #expect(a.landBounds.separation(from: b.landBounds) >= 20, "\(a.id) y \(b.id): poco mar entre medias")
            }
        }
    }

    @Test func geographyFollowsTheWorldBible() {
        let w = Self.world
        let v = w.continent("valdemar")!.landBounds, r = w.continent("rocaforja")!.landBounds
        let l = w.continent("lunaria")!.landBounds, c = w.continent("cenizas")!.landBounds
        let e = w.continent("escarcha")!.landBounds, u = w.continent("umbral")!.landBounds
        #expect(r.maxY <= v.y, "Rocaforja al norte de Valdemar")
        #expect(l.x >= r.maxX, "Lunaria al este de Rocaforja")
        #expect(c.y >= v.maxY, "Cenizas al sur, por mar")
        #expect(e.y < r.y && e.maxX <= r.x, "Escarcha en el norte, al oeste")
        #expect(u.maxY <= r.y && u.maxY <= l.y, "Umbral arriba, sobre el mar")
    }

    @Test func routesJoinTheirAreas() {
        let w = Self.world
        #expect(w.routes.map(\.id) == World.worldRoutes.map(\.id))
        let paso = w.routes.first { $0.id == "paso_del_norte" }!
        // El Paso del Norte sube recto: la boca del Paso frente a la de los Pastos Altos.
        #expect(abs(paso.points.first!.x - paso.points.last!.x) <= 1)
        #expect(paso.points.first!.y > paso.points.last!.y)
        // El túnel va de la capital enana (al este de Rocaforja) a las Raíces de Plata, casi a la misma altura.
        let tunnel = w.routes.first { $0.id == "tunel_de_los_thanes" }!
        #expect(abs(tunnel.points.first!.y - tunnel.points.last!.y) <= 12)
        #expect(tunnel.points.last!.x > tunnel.points.first!.x)
        for id in ["rocaforja.cumbres", "rocaforja.canteras", "rocaforja.escoriales"] {
            #expect(w.continent("rocaforja")!.frame(of: id)!.maxX <= Int(tunnel.points.first!.x), "el túnel no cruza \(id)")
        }
        for route in w.routes {
            let from = w.continent(route.route.fromContinent)!.frame(of: route.route.fromArea)!
            let to = w.continent(route.route.toContinent)!.frame(of: route.route.toArea)!
            #expect(from.distance(to: route.points.first!) < 0.01, "\(route.id) no sale de su área")
            #expect(to.distance(to: route.points.last!) < 0.01, "\(route.id) no llega a su área")
        }
        // El barco al norte rodea Valdemar y Rocaforja por mar.
        let north = w.routes.first { $0.id == "gaviota_tuerta_norte" }!
        for land in ["valdemar", "rocaforja"].map({ w.continent($0)!.landBounds }) {
            for (p, q) in zip(north.points, north.points.dropFirst()) {
                for k in 0...20 {
                    let t = Double(k) / 20
                    #expect(!land.containsStrictly(MapPoint(p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t)))
                }
            }
        }
    }

    @Test func worldPointsMatchTheContinentMap() {
        let w = Self.world
        let v = w.continent(World.valdemarID)!
        let local = v.layout.point(of: TilePoint(21, 14), in: Valdehierro.townID)!
        let p = w.point(of: TilePoint(21, 14), in: Valdehierro.townID)!
        #expect(p == MapPoint(local.x + Double(v.origin.x), local.y + Double(v.origin.y)))
        #expect(w.hit(p)?.continentID == World.valdemarID && w.hit(p)?.areaID == Valdehierro.townID)
        let pastos = w.continent("rocaforja")!.frame(of: "rocaforja.pastos")!
        #expect(w.hit(pastos.center)?.areaID == "rocaforja.pastos")
        #expect(w.hit(MapPoint(1, 1)) == nil, "en mitad del mar no hay nada")
        #expect(w.continentID(ofArea: "lunaria.velaluna") == "lunaria")
    }

    @Test func worldLayoutIsDeterministic() {
        let a = Self.world, b = Self.world
        #expect(a.width == b.width && a.height == b.height)
        #expect(a.continents.map(\.origin) == b.continents.map(\.origin))
        #expect(a.routes == b.routes)
    }
}
