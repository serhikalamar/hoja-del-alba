import Foundation

// MARK: - Atlas de Ardenia: los 6 continentes en el mapa del mundo
//
// El mapa de la pausa se aleja hasta ver el mundo entero. Cada continente tiene aquí su sitio (relativo a otro: "al
// norte de Valdemar, por el Paso"), su terreno, una frase sin destripes y, mientras no se pueda jugar, el boceto de sus
// áreas (nombre, tamaño y casilla del esquema, sacados de `assets/world/continentes/<id>/zonas.md` y `mapas/`).
//
// Un continente es **jugable** cuando está en `World.continents` con sus áreas: entonces el mapa lo dibuja en color con
// su mapa real (`ContinentLayout`), sin tocar la vista. Si no, se dibuja en gris con su boceto y "Próximamente".
// Geografía: `assets/world/mundo.md` §10 (Rocaforja al norte por el Paso, Lunaria al este por el Túnel de los Thanes,
// Cenizas al sur por mar, Escarcha en el norte helado, Umbral flotando sobre el Mar Quieto).

/// Cómo es la tierra de un continente (decide la silueta que se dibuja).
public enum ContinentTerrain: String, CaseIterable, Sendable {
    /// Praderas y robledales (Valdemar).
    case meadow
    /// Montañas, minas y cumbres nevadas (Rocaforja).
    case mountains
    /// Bosque de árboles de plata (Lunaria).
    case silverForest
    /// Desierto de ceniza y volcanes (Cenizas).
    case ashDesert
    /// Tundra y glaciares (Escarcha).
    case glacier
    /// Islas que flotan en el cielo (Umbral).
    case skyIslands
}

/// Algo que destaca en el boceto de un área (se dibuja en su silueta).
public enum PlannedLandmark: String, Sendable {
    case mine, volcano, crater, citadel
}

/// Área prevista de un continente que aún no se puede jugar (de su boceto).
public struct PlannedArea: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Tamaño del boceto en casillas.
    public let width: Int
    public let height: Int
    /// Columna y fila en el esquema del continente (como `Continent.mapLayout`).
    public let cell: TilePoint
    /// Niveles (nil = capital, segura).
    public let levels: ClosedRange<Int>?
    public let landmark: PlannedLandmark?

    public init(_ id: String, _ name: String, _ width: Int, _ height: Int, cell: TilePoint, levels: ClosedRange<Int>? = nil,
                landmark: PlannedLandmark? = nil) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.cell = cell
        self.levels = levels
        self.landmark = landmark
    }

    public var isCapital: Bool { levels == nil }
}

/// Cómo se viaja entre dos continentes.
public enum TravelKind: String, Sendable {
    /// A pie por un camino (el Paso del Norte).
    case road
    /// A pie por un túnel (el Túnel de los Thanes).
    case tunnel
    /// En barco (La Gaviota Tuerta, de Marga).
    case ship
    /// En dirigible (el Testaruda, de Borin).
    case airship
}

/// Ruta entre dos continentes (`mundo.md` §10). Sale y llega por el borde de las áreas indicadas.
public struct WorldRoute: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: TravelKind
    public let fromContinent: String
    public let fromArea: String
    public let toContinent: String
    public let toArea: String

    public init(id: String, name: String, kind: TravelKind, from: (String, String), to: (String, String)) {
        self.id = id
        self.name = name
        self.kind = kind
        fromContinent = from.0
        fromArea = from.1
        toContinent = to.0
        toArea = to.1
    }
}

/// Dónde va un continente respecto a otro ya colocado.
public struct WorldPlacement: Hashable, Sendable {
    /// Continente de referencia (nil = el primero, el origen).
    public let relativeTo: String?
    /// Lado del de referencia en el que va.
    public let side: MapSide
    /// Casillas de mar entre los dos lienzos (cada lienzo ya trae su margen de mar).
    public let gap: Int
    /// Desplazamiento a lo largo del lado (casillas), después de alinear.
    public let shift: Int
    /// Alinear por la ruta que los une (la boca de un área frente a la otra) en vez de por los centros.
    public let alignRoute: Bool

    public init(relativeTo: String?, side: MapSide = .north, gap: Int = 0, shift: Int = 0, alignRoute: Bool = false) {
        self.relativeTo = relativeTo
        self.side = side
        self.gap = gap
        self.shift = shift
        self.alignRoute = alignRoute
    }
}

/// Un continente en el atlas del mundo.
public struct AtlasEntry: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let levels: ClosedRange<Int>
    public let terrain: ContinentTerrain
    /// Una frase sin destripes para la tarjeta.
    public let teaser: String
    /// Boceto de sus áreas (lo que se dibuja mientras no se puede jugar).
    public let plannedAreas: [PlannedArea]
    public let placement: WorldPlacement
}

extension World {
    /// Los 6 continentes de Ardenia (`assets/world/continentes.md`), en el orden en que se colocan.
    public static let atlas: [AtlasEntry] = [
        AtlasEntry(id: valdemarID, name: "Reino de Valdemar", levels: 1...10, terrain: .meadow,
                   teaser: "Praderas, robledales y granjas alrededor de Valdehierro. Aquí empieza todo.",
                   plannedAreas: [], placement: WorldPlacement(relativeTo: nil)),
        AtlasEntry(id: "rocaforja", name: "Montes de Rocaforja", levels: 10...20, terrain: .mountains,
                   teaser: "Montañas grises, minas y forjas bajo tierra: la patria de los enanos… y del herrero de Valdehierro.",
                   plannedAreas: [
                       // Esquema de las salidas de `rocaforja/zonas.md` §2: la capital al este (Túnel de los Thanes hacia
                       // Lunaria), los Pastos al sur (llegada del Paso), las Canteras al oeste de la capital.
                       PlannedArea("rocaforja.fortaleza", "Fortaleza Hollín", 48, 26, cell: TilePoint(1, 0), levels: 18...19, landmark: .citadel),
                       PlannedArea("rocaforja.cumbres", "Cumbres del Águila", 48, 36, cell: TilePoint(0, 1), levels: 14...16),
                       PlannedArea("rocaforja.escoriales", "Escoriales del Hollín", 52, 34, cell: TilePoint(1, 1), levels: 16...18),
                       PlannedArea("rocaforja.canteras", "Canteras de Cobalto", 52, 34, cell: TilePoint(0, 2), levels: 12...14, landmark: .mine),
                       PlannedArea("rocaforja.hondoyunque", "Hondoyunque", 56, 34, cell: TilePoint(1, 2)),
                       PlannedArea("rocaforja.pastos", "Pastos Altos", 52, 34, cell: TilePoint(1, 3), levels: 10...12),
                   ],
                   placement: WorldPlacement(relativeTo: valdemarID, side: .north, gap: 0, alignRoute: true)),
        AtlasEntry(id: "lunaria", name: "Bosque de Lunaria", levels: 20...30, terrain: .silverForest,
                   teaser: "Un bosque antiguo de árboles de plata, donde elfos y clanes lobo beben la luz de la luna.",
                   plannedAreas: [
                       PlannedArea("lunaria.velaluna", "Velaluna", 56, 36, cell: TilePoint(0, 0)),
                       PlannedArea("lunaria.raices", "Raíces de Plata", 60, 36, cell: TilePoint(0, 1), levels: 20...22),
                       PlannedArea("lunaria.claros", "Claros de la Luna", 60, 36, cell: TilePoint(1, 1), levels: 22...24),
                       PlannedArea("lunaria.lago", "Lago de la Luna Caída", 60, 36, cell: TilePoint(2, 1), levels: 28...29),
                       PlannedArea("lunaria.colmillo", "Colmillo Gris", 44, 32, cell: TilePoint(0, 2)),
                       PlannedArea("lunaria.espesura", "Espesura del Aullido", 60, 36, cell: TilePoint(1, 2), levels: 24...26),
                       PlannedArea("lunaria.marchito", "Bosque Marchito", 60, 36, cell: TilePoint(2, 2), levels: 26...28),
                   ],
                   placement: WorldPlacement(relativeTo: "rocaforja", side: .east, gap: 40, shift: -12, alignRoute: true)),
        AtlasEntry(id: "cenizas", name: "Yermo de Cenizas", levels: 30...40, terrain: .ashDesert,
                   teaser: "Al sur, por mar: un desierto de ceniza y volcanes que esconde bajo la arena un imperio entero.",
                   plannedAreas: [
                       PlannedArea("cenizas.costa", "Costa de Escoria", 56, 36, cell: TilePoint(0, 0), levels: 30...32),
                       PlannedArea("cenizas.fortin", "Fortín del Oasis", 48, 34, cell: TilePoint(1, 0)),
                       PlannedArea("cenizas.dunas", "Dunas Negras", 60, 38, cell: TilePoint(1, 1), levels: 32...34),
                       PlannedArea("cenizas.necropolis", "Necrópolis de Solarum", 60, 40, cell: TilePoint(2, 1), levels: 34...36),
                       PlannedArea("cenizas.sepultada", "Ciudad Sepultada de Solarum", 56, 34, cell: TilePoint(1, 2), levels: 38...39),
                       PlannedArea("cenizas.laderas", "Laderas de Brasamadre", 60, 40, cell: TilePoint(2, 2), levels: 36...38, landmark: .volcano),
                   ],
                   placement: WorldPlacement(relativeTo: valdemarID, side: .south, gap: 36, shift: 30)),
        AtlasEntry(id: "escarcha", name: "Tierras de Escarcha", levels: 40...50, terrain: .glacier,
                   teaser: "El norte helado: tundra, glaciares y auroras… y cráteres donde ha caído algo del cielo.",
                   plannedAreas: [
                       PlannedArea("escarcha.murallas", "Murallas de la Luna Rota", 56, 36, cell: TilePoint(1, 0), levels: 48...49, landmark: .citadel),
                       PlannedArea("escarcha.gigantes", "Trono de los Gigantes", 60, 40, cell: TilePoint(1, 1), levels: 46...48),
                       PlannedArea("escarcha.tundra", "Tundra Aullante", 64, 40, cell: TilePoint(0, 2), levels: 42...44),
                       PlannedArea("escarcha.crater", "Cráter de la Esquirla", 56, 40, cell: TilePoint(1, 2), levels: 44...46, landmark: .crater),
                       PlannedArea("escarcha.balleneros", "Costa de los Balleneros", 56, 36, cell: TilePoint(0, 3), levels: 40...42),
                       PlannedArea("escarcha.hielomar", "Hielomar", 48, 36, cell: TilePoint(1, 3)),
                   ],
                   placement: WorldPlacement(relativeTo: "rocaforja", side: .west, gap: 30, shift: -150)),
        AtlasEntry(id: "umbral", name: "Islas de Umbral", levels: 50...60, terrain: .skyIslands,
                   teaser: "Islas de piedra que flotan sobre el Mar Quieto, bajo la Luna agrietada. El último desafío.",
                   plannedAreas: [
                       PlannedArea("umbral.rotas", "Islas Rotas", 60, 36, cell: TilePoint(1, 0), levels: 54...56),
                       PlannedArea("umbral.observatorio", "Observatorio de los Herreros", 56, 36, cell: TilePoint(2, 0), levels: 56...58),
                       PlannedArea("umbral.puente", "Puente del Yunque", 64, 24, cell: TilePoint(3, 0), levels: 58...59),
                       PlannedArea("umbral.muelles", "Muelles del Cielo", 56, 32, cell: TilePoint(0, 1), levels: 50...52),
                       PlannedArea("umbral.bastion", "Bastión del Alba", 52, 34, cell: TilePoint(1, 1)),
                       PlannedArea("umbral.nidos", "Nidos del Vuelo del Alba", 56, 36, cell: TilePoint(2, 1), levels: 52...54),
                   ],
                   placement: WorldPlacement(relativeTo: "lunaria", side: .north, gap: 20, shift: 20)),
    ]

    /// Rutas entre continentes (`mundo.md` §10).
    public static let worldRoutes: [WorldRoute] = [
        WorldRoute(id: "paso_del_norte", name: "Paso del Norte", kind: .road,
                   from: (valdemarID, Valdemar.pasoID), to: ("rocaforja", "rocaforja.pastos")),
        WorldRoute(id: "tunel_de_los_thanes", name: "Túnel de los Thanes", kind: .tunnel,
                   from: ("rocaforja", "rocaforja.hondoyunque"), to: ("lunaria", "lunaria.raices")),
        WorldRoute(id: "gaviota_tuerta_sur", name: "La Gaviota Tuerta", kind: .ship,
                   from: (valdemarID, Valdemar.robledaID), to: ("cenizas", "cenizas.costa")),
        WorldRoute(id: "gaviota_tuerta_norte", name: "La Gaviota Tuerta", kind: .ship,
                   from: ("cenizas", "cenizas.costa"), to: ("escarcha", "escarcha.hielomar")),
        WorldRoute(id: "testaruda", name: "El Testaruda", kind: .airship,
                   from: ("escarcha", "escarcha.hielomar"), to: ("umbral", "umbral.muelles")),
    ]

    public static func atlasEntry(_ id: String) -> AtlasEntry? { atlas.first { $0.id == id } }

    /// ¿Se puede jugar ya? (Está registrado con áreas que existen.)
    public static func isPlayable(_ continentID: String) -> Bool {
        guard let continent = continent(continentID) else { return false }
        return !continent.mapLayout.isEmpty && continent.mapLayout.keys.allSatisfy { area($0) != nil }
    }
}

/// Un continente colocado en el mapa del mundo.
public struct PlacedContinent: Identifiable, Sendable {
    public let entry: AtlasEntry
    /// Jugable: se dibuja con su mapa real; si no, en gris con su boceto.
    public let isPlayable: Bool
    /// Colocación de sus áreas (las reales o las del boceto) en casillas del continente.
    public let layout: ContinentLayout
    /// Esquina del lienzo del continente en casillas del mundo.
    public let origin: TilePoint

    public var id: String { entry.id }
    /// Lienzo del continente (con su margen de mar) en casillas del mundo.
    public var frame: TileRect { TileRect(x: origin.x, y: origin.y, width: layout.width, height: layout.height) }
    /// Rectángulo de un área en casillas del mundo.
    public func frame(of areaID: String) -> TileRect? {
        layout.frame(of: areaID).map { TileRect(x: $0.x + origin.x, y: $0.y + origin.y, width: $0.width, height: $0.height) }
    }
    /// Lo que ocupan sus áreas (sin el mar) en casillas del mundo.
    public var landBounds: TileRect {
        let b = layout.areasBounds
        return TileRect(x: b.x + origin.x, y: b.y + origin.y, width: b.width, height: b.height)
    }
}

/// Ruta entre continentes ya colocada.
public struct PlacedRoute: Identifiable, Hashable, Sendable {
    public let route: WorldRoute
    /// Trazado en casillas del mundo (de la boca del área de salida a la de llegada).
    public let points: [MapPoint]
    public var id: String { route.id }
}

/// El mapa del mundo: dónde va cada continente y por dónde van las rutas.
public struct WorldLayout: Sendable {
    /// Casillas de mar alrededor de todo.
    public static let defaultMargin = 40

    public let width: Int
    public let height: Int
    public let continents: [PlacedContinent]
    public let routes: [PlacedRoute]

    public func continent(_ id: String) -> PlacedContinent? { continents.first { $0.id == id } }

    /// Centro de una casilla de un área (de cualquier continente) en casillas del mundo.
    public func point(of tile: TilePoint, in areaID: String) -> MapPoint? {
        for c in continents {
            if let p = c.layout.point(of: tile, in: areaID) {
                return MapPoint(p.x + Double(c.origin.x), p.y + Double(c.origin.y))
            }
        }
        return nil
    }

    /// Continente y área bajo un punto del mundo.
    public func hit(_ p: MapPoint) -> (continentID: String, areaID: String?)? {
        for c in continents {
            let local = MapPoint(p.x - Double(c.origin.x), p.y - Double(c.origin.y))
            if let area = c.layout.areaID(at: local) { return (c.id, area) }
        }
        // Fuera de las áreas: el continente cuya tierra está más cerca (si está a tiro).
        let near = continents.map { ($0, $0.landBounds.distance(to: p)) }.min { $0.1 < $1.1 }
        if let near, near.1 <= 12 { return (near.0.id, nil) }
        return nil
    }

    /// Continente al que pertenece un área.
    public func continentID(ofArea areaID: String) -> String? {
        continents.first { $0.layout.frame(of: areaID) != nil }?.id
    }

    public init(atlas: [AtlasEntry] = World.atlas, routes: [WorldRoute] = World.worldRoutes, margin: Int = defaultMargin,
                playable: (String) -> Continent? = { World.isPlayable($0) ? World.continent($0) : nil }) {
        // Lienzo de cada continente: el real si se puede jugar; si no, el de su boceto (áreas en blanco del mismo tamaño).
        var layouts: [String: (ContinentLayout, Bool)] = [:]
        for entry in atlas {
            if let real = playable(entry.id) {
                layouts[entry.id] = (real.placement, true)
            } else {
                let fake = Dictionary(uniqueKeysWithValues: entry.plannedAreas.map { planned in
                    (planned.id, AreaMap(id: planned.id, name: planned.name,
                                         rows: Array(repeating: String(repeating: ".", count: planned.width), count: planned.height),
                                         buildings: [], zones: [], spawns: [], npcs: [], level: planned.levels?.lowerBound ?? 1,
                                         entry: TilePoint(0, 0)))
                })
                let sketch = Continent(id: entry.id, name: entry.name, levels: entry.levels, capitalID: entry.plannedAreas.first?.id ?? "",
                                       areaIDs: entry.plannedAreas.map(\.id), minerals: [], tier: 0,
                                       mapLayout: Dictionary(uniqueKeysWithValues: entry.plannedAreas.map { ($0.id, $0.cell) }))
                layouts[entry.id] = (ContinentLayout(sketch, areas: { fake[$0] }), false)
            }
        }

        // Boca de un área hacia un lado, en casillas de su continente.
        func mouth(_ continentID: String, _ areaID: String, facing side: MapSide) -> MapPoint? {
            guard let f = layouts[continentID]?.0.frame(of: areaID) else { return nil }
            switch side {
            case .north: return MapPoint(Double(f.x) + Double(f.width) / 2, Double(f.y))
            case .south: return MapPoint(Double(f.x) + Double(f.width) / 2, Double(f.maxY))
            case .west: return MapPoint(Double(f.x), Double(f.y) + Double(f.height) / 2)
            case .east: return MapPoint(Double(f.maxX), Double(f.y) + Double(f.height) / 2)
            }
        }
        func opposite(_ s: MapSide) -> MapSide {
            switch s {
            case .north: .south
            case .south: .north
            case .east: .west
            case .west: .east
            }
        }

        // Colocar en orden, cada uno junto a su referencia.
        var origins: [String: (x: Int, y: Int)] = [:]
        for entry in atlas {
            guard let (layout, _) = layouts[entry.id] else { continue }
            let p = entry.placement
            guard let refID = p.relativeTo, let ref = origins[refID], let refLayout = layouts[refID]?.0 else {
                origins[entry.id] = (0, 0)
                continue
            }
            var x = 0, y = 0
            switch p.side {
            case .north: y = ref.y - p.gap - layout.height
            case .south: y = ref.y + refLayout.height + p.gap
            case .west: x = ref.x - p.gap - layout.width
            case .east: x = ref.x + refLayout.width + p.gap
            }
            // Alineación a lo largo del lado: por la ruta que los une o por los centros.
            let route = routes.first { Set([$0.fromContinent, $0.toContinent]) == Set([refID, entry.id]) }
            var along: Double
            if p.alignRoute, let route {
                let refArea = route.fromContinent == refID ? route.fromArea : route.toArea
                let myArea = route.fromContinent == refID ? route.toArea : route.fromArea
                let a = mouth(refID, refArea, facing: p.side), b = mouth(entry.id, myArea, facing: opposite(p.side))
                if let a, let b {
                    along = p.side.isVertical ? Double(ref.x) + a.x - b.x : Double(ref.y) + a.y - b.y
                } else {
                    along = p.side.isVertical ? Double(ref.x) + Double(refLayout.width - layout.width) / 2
                                              : Double(ref.y) + Double(refLayout.height - layout.height) / 2
                }
            } else {
                along = p.side.isVertical ? Double(ref.x) + Double(refLayout.width - layout.width) / 2
                                          : Double(ref.y) + Double(refLayout.height - layout.height) / 2
            }
            along += Double(p.shift)
            if p.side.isVertical { x = Int(along.rounded()) } else { y = Int(along.rounded()) }
            origins[entry.id] = (x, y)
        }
        let minX = origins.values.map(\.x).min() ?? 0, minY = origins.values.map(\.y).min() ?? 0
        var placed: [PlacedContinent] = []
        for entry in atlas {
            guard let (layout, isPlayable) = layouts[entry.id], let o = origins[entry.id] else { continue }
            placed.append(PlacedContinent(entry: entry, isPlayable: isPlayable, layout: layout,
                                          origin: TilePoint(o.x - minX + margin, o.y - minY + margin)))
        }
        continents = placed
        width = (placed.map(\.frame.maxX).max() ?? 0) + margin
        height = (placed.map(\.frame.maxY).max() ?? 0) + margin

        // Rutas: de la boca de un área a la de la otra; las de mar o aire rodean las tierras que se crucen.
        let lands = placed.map(\.landBounds)
        var placedRoutes: [PlacedRoute] = []
        for route in routes {
            guard let from = placed.first(where: { $0.id == route.fromContinent }),
                  let to = placed.first(where: { $0.id == route.toContinent }),
                  let fa = from.frame(of: route.fromArea), let ta = to.frame(of: route.toArea) else { continue }
            // Lado por el que se mira al otro continente.
            let dx = ta.center.x - fa.center.x, dy = ta.center.y - fa.center.y
            let side: MapSide = abs(dy) >= abs(dx) ? (dy < 0 ? .north : .south) : (dx < 0 ? .west : .east)
            func edge(_ r: TileRect, _ s: MapSide) -> MapPoint {
                switch s {
                case .north: MapPoint(r.center.x, Double(r.y))
                case .south: MapPoint(r.center.x, Double(r.maxY))
                case .west: MapPoint(Double(r.x), r.center.y)
                case .east: MapPoint(Double(r.maxX), r.center.y)
                }
            }
            let a = edge(fa, side), b = edge(ta, opposite(side))
            var points = [a, b]
            if route.kind == .ship || route.kind == .airship {
                // Si la línea recta pisa otra tierra, se va por mar abierto (por el oeste).
                let crosses = lands.enumerated().contains { i, land in
                    placed[i].id != from.id && placed[i].id != to.id
                        && (0...20).contains { k in
                            let t = Double(k) / 20
                            return land.containsStrictly(MapPoint(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t))
                        }
                }
                if crosses {
                    // Sale unas casillas mar adentro, va por el carril del oeste y entra igual por el otro lado.
                    let na = side.normal, nb = opposite(side).normal
                    let a2 = MapPoint(a.x + na.dx * 8, a.y + na.dy * 8), b2 = MapPoint(b.x + nb.dx * 8, b.y + nb.dy * 8)
                    let lane = Double((lands.map(\.x).min() ?? 0) - 14)
                    points = side.isVertical ? [a, a2, MapPoint(lane, a2.y), MapPoint(lane, b2.y), b2, b]
                                             : [a, a2, MapPoint(a2.x, a2.y), b2, b]
                }
            }
            placedRoutes.append(PlacedRoute(route: route, points: points))
        }
        self.routes = placedRoutes
    }
}

extension World {
    /// El mapa del mundo con los datos de hoy.
    public static var worldLayout: WorldLayout { WorldLayout() }
}
