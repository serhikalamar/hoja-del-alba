import Foundation

// MARK: - Mapa del continente: dónde va cada área y por dónde van los caminos
//
// El mapa de la pausa (`ContinentMapView`) dibuja cada área con su mapa real, colocada en un lienzo común en casillas.
// Este fichero decide, solo con los datos (`Continent.mapLayout`, el tamaño de cada área y sus salidas `AreaExit`),
// en qué casilla del continente empieza cada área y el trazado de los caminos que unen sus salidas. Así vale para
// cualquier continente sin coordenadas puestas a mano.
//
// Reglas:
// - Cada fila de `mapLayout` es una franja: todo lo de una fila queda por encima de lo de la siguiente, con `gap`
//   casillas de terreno entre medias. Dentro de una fila, las columnas van de izquierda a derecha con el mismo hueco.
//   Así nunca se pisan dos áreas.
// - Dentro de eso, cada área se desliza para que sus salidas queden enfrente de las de sus vecinas (mínimos cuadrados
//   por iteraciones, determinista). Lo que no encaja del todo lo absorbe el camino, que dobla en el hueco.
// - Las salidas a otro continente (`ExitLock.comingSoon`, o a un área que no existe) siguen recto hasta el borde.

/// Rectángulo en casillas del continente (origen arriba a la izquierda; `maxX`/`maxY` exclusivos).
public struct TileRect: Hashable, Sendable {
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Int { x + width }
    public var maxY: Int { y + height }
    public var center: MapPoint { MapPoint(Double(x) + Double(width) / 2, Double(y) + Double(height) / 2) }

    /// ¿Está el punto dentro (bordes incluidos a la izquierda y arriba)?
    public func contains(_ p: MapPoint) -> Bool {
        p.x >= Double(x) && p.x < Double(maxX) && p.y >= Double(y) && p.y < Double(maxY)
    }

    /// ¿Está el punto estrictamente dentro, a más de `inset` casillas del borde?
    public func containsStrictly(_ p: MapPoint, inset: Double = 0) -> Bool {
        p.x > Double(x) + inset && p.x < Double(maxX) - inset && p.y > Double(y) + inset && p.y < Double(maxY) - inset
    }

    /// Distancia (en casillas) del punto al rectángulo; 0 si está dentro.
    public func distance(to p: MapPoint) -> Double {
        let dx = max(Double(x) - p.x, 0, p.x - Double(maxX))
        let dy = max(Double(y) - p.y, 0, p.y - Double(maxY))
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Separación con otro rectángulo: casillas libres entre los dos por el eje en que se separan
    /// (negativo si se pisan).
    public func separation(from other: TileRect) -> Int {
        let sx = max(other.x - maxX, x - other.maxX)
        let sy = max(other.y - maxY, y - other.maxY)
        return max(sx, sy)
    }
}

/// Punto en casillas del continente (con decimales: el centro de una casilla es `x + 0.5`).
public struct MapPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

/// Lado de un área.
public enum MapSide: String, CaseIterable, Sendable {
    case north, south, east, west

    /// Hacia fuera del área (y crece hacia abajo).
    public var normal: (dx: Double, dy: Double) {
        switch self {
        case .north: (0, -1)
        case .south: (0, 1)
        case .east: (1, 0)
        case .west: (-1, 0)
        }
    }

    public var isVertical: Bool { self == .north || self == .south }
}

extension AreaExit {
    /// Lado del área en el que está la salida (por sus casillas `>`). nil si no está en el borde.
    public func side(in area: AreaMap) -> MapSide? {
        guard !tiles.isEmpty else { return nil }
        if tiles.allSatisfy({ $0.y == 0 }) { return .north }
        if tiles.allSatisfy({ $0.y == area.height - 1 }) { return .south }
        if tiles.allSatisfy({ $0.x == 0 }) { return .west }
        if tiles.allSatisfy({ $0.x == area.width - 1 }) { return .east }
        return nil
    }

    /// Punto medio de la salida sobre el borde exterior del área, en casillas del área.
    public func edgeAnchor(in area: AreaMap) -> MapPoint? {
        guard let side = side(in: area) else { return nil }
        let mx = Double(tiles.map(\.x).reduce(0, +)) / Double(tiles.count) + 0.5
        let my = Double(tiles.map(\.y).reduce(0, +)) / Double(tiles.count) + 0.5
        switch side {
        case .north: return MapPoint(mx, 0)
        case .south: return MapPoint(mx, Double(area.height))
        case .west: return MapPoint(0, my)
        case .east: return MapPoint(Double(area.width), my)
        }
    }

    /// Lleva a otro continente (todavía cerrado) en vez de a un área.
    public var isFrontier: Bool {
        if case .comingSoon? = lock { return true }
        return World.area(toArea) == nil
    }
}

/// Camino dibujado en el mapa del continente entre dos salidas (o de una salida al borde, hacia otro continente).
public struct ContinentRoad: Identifiable, Hashable, Sendable {
    /// `<salida de origen>` o `<salida de origen>+<salida de destino>`.
    public let id: String
    public let fromAreaID: String
    public let fromExitID: String
    /// Área de destino (nil = va a otro continente).
    public let toAreaID: String?
    public let toExitID: String?
    /// Id del área o del continente al que lleva.
    public let destinationID: String
    /// Ancho en casillas (las casillas `>` de la salida, entre 2 y 4).
    public let width: Int
    /// Trazado en casillas del continente: de la salida de origen a la de destino (o al borde del mapa).
    public let points: [MapPoint]
    /// Cartel para los caminos a otro continente: "Rocaforja · próximamente".
    public let label: String?

    public var isFrontier: Bool { toAreaID == nil }
}

/// Dónde va cada área en el mapa de un continente y por dónde van los caminos.
public struct ContinentLayout: Sendable {
    /// Casillas de terreno entre dos áreas vecinas.
    public static let defaultGap = 10
    /// Casillas de terreno y mar alrededor de todo.
    public static let defaultMargin = 18

    public let continentID: String
    /// Tamaño del mapa en casillas.
    public let width: Int
    public let height: Int
    public let gap: Int
    public let margin: Int
    /// Áreas del mapa, por filas y columnas de `mapLayout`.
    public let areaIDs: [String]
    /// Rectángulo de cada área en casillas del continente (mismo tamaño que su mapa).
    public let frames: [String: TileRect]
    public let roads: [ContinentRoad]

    /// Rectángulo de un área (nil si no está en el mapa).
    public func frame(of areaID: String) -> TileRect? { frames[areaID] }

    /// Centro de una casilla de un área, en casillas del continente.
    public func point(of tile: TilePoint, in areaID: String) -> MapPoint? {
        guard let frame = frames[areaID] else { return nil }
        return MapPoint(Double(frame.x + tile.x) + 0.5, Double(frame.y + tile.y) + 0.5)
    }

    /// Área bajo un punto del mapa (nil si es terreno entre áreas).
    public func areaID(at point: MapPoint) -> String? {
        areaIDs.first { frames[$0]?.contains(point) ?? false }
    }

    /// Rectángulo que abarca todas las áreas.
    public var areasBounds: TileRect {
        let rects = areaIDs.compactMap { frames[$0] }
        guard let first = rects.first else { return TileRect(x: 0, y: 0, width: width, height: height) }
        let x0 = rects.map(\.x).min() ?? first.x, y0 = rects.map(\.y).min() ?? first.y
        let x1 = rects.map(\.maxX).max() ?? first.maxX, y1 = rects.map(\.maxY).max() ?? first.maxY
        return TileRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    public init(_ continent: Continent, gap: Int = defaultGap, margin: Int = defaultMargin,
                areas lookup: (String) -> AreaMap? = World.area) {
        continentID = continent.id
        self.gap = gap
        self.margin = margin

        // Áreas del esquema que existen, por fila y columna.
        let cells = continent.mapLayout.compactMap { id, cell in lookup(id).map { (area: $0, cell: cell) } }
            .sorted { ($0.cell.y, $0.cell.x, $0.area.id) < ($1.cell.y, $1.cell.x, $1.area.id) }
        let areas = cells.map(\.area)
        areaIDs = areas.map(\.id)
        let index = Dictionary(uniqueKeysWithValues: areas.enumerated().map { ($1.id, $0) })
        let rowValues = Array(Set(cells.map(\.cell.y))).sorted()
        let colValues = Array(Set(cells.map(\.cell.x))).sorted()
        // Filas: índices de área de cada franja, de izquierda a derecha.
        let rows: [[Int]] = rowValues.map { r in cells.indices.filter { cells[$0].cell.y == r } }

        // Posición inicial: rejilla con el ancho/alto máximo de cada columna/fila, cada área centrada en su celda.
        let colWidth = colValues.map { c in cells.filter { $0.cell.x == c }.map(\.area.width).max() ?? 0 }
        let rowHeight = rowValues.map { r in cells.filter { $0.cell.y == r }.map(\.area.height).max() ?? 0 }
        var colX: [Int: Double] = [:], rowY: [Int: Double] = [:]
        var cursor = 0.0
        for (i, c) in colValues.enumerated() { colX[c] = cursor; cursor += Double(colWidth[i] + gap) }
        cursor = 0
        for (i, r) in rowValues.enumerated() { rowY[r] = cursor; cursor += Double(rowHeight[i] + gap) }
        let home: [MapPoint] = cells.map { item in
            let ci = colValues.firstIndex(of: item.cell.x)!, ri = rowValues.firstIndex(of: item.cell.y)!
            return MapPoint(colX[item.cell.x]! + Double(colWidth[ci] - item.area.width) / 2,
                            rowY[item.cell.y]! + Double(rowHeight[ri] - item.area.height) / 2)
        }

        // Uniones entre salidas de áreas del mapa (una por pareja de salidas).
        struct Link {
            let a: Int, b: Int
            let anchorA: MapPoint, anchorB: MapPoint
            let sideA: MapSide, sideB: MapSide
            let exitA: AreaExit, exitB: AreaExit?
            /// Vecinas en la rejilla (pesa 1); en diagonal o más lejos apenas tira (el camino ya dobla).
            let weight: Double
        }
        var links: [Link] = []
        var seen = Set<String>()
        for (i, area) in areas.enumerated() {
            for exit in area.exits {
                guard let j = index[exit.toArea], j != i, let sideA = exit.side(in: area),
                      let anchorA = exit.edgeAnchor(in: area) else { continue }
                let other = areas[j]
                // La salida de vuelta: la del área de destino que lleva aquí, la más cercana a la llegada.
                let back = other.exits.filter { $0.toArea == area.id && $0.side(in: other) != nil }
                    .min { Self.distance($0, to: exit.arrival) < Self.distance($1, to: exit.arrival) }
                let key = [exit.id, back?.id ?? "·\(other.id)"].sorted().joined(separator: "+")
                guard seen.insert(key).inserted else { continue }
                let sideB: MapSide, anchorB: MapPoint
                if let back, let s = back.side(in: other), let p = back.edgeAnchor(in: other) {
                    sideB = s
                    anchorB = p
                } else {
                    // Sin salida de vuelta: el borde más cercano a la casilla de llegada.
                    let arrival = exit.arrival ?? other.entry
                    let options: [(MapSide, MapPoint, Int)] = [
                        (.north, MapPoint(Double(arrival.x) + 0.5, 0), arrival.y),
                        (.south, MapPoint(Double(arrival.x) + 0.5, Double(other.height)), other.height - 1 - arrival.y),
                        (.west, MapPoint(0, Double(arrival.y) + 0.5), arrival.x),
                        (.east, MapPoint(Double(other.width), Double(arrival.y) + 0.5), other.width - 1 - arrival.x),
                    ]
                    let best = options.min { $0.2 < $1.2 }!
                    sideB = best.0
                    anchorB = best.1
                }
                let ci = cells[i].cell, cj = cells[j].cell
                let adjacent = abs(ci.x - cj.x) + abs(ci.y - cj.y) == 1
                links.append(Link(a: i, b: j, anchorA: anchorA, anchorB: anchorB, sideA: sideA, sideB: sideB,
                                  exitA: exit, exitB: back, weight: adjacent ? 1 : 0.05))
            }
        }

        // Deslizar las áreas para que sus salidas queden enfrente (Gauss-Seidel), respetando franjas y columnas.
        var pos = home
        let half = Double(gap) / 2
        for _ in 0..<300 {
            for i in areas.indices {
                var sx = home[i].x * 0.05, wx = 0.05, sy = home[i].y * 0.05, wy = 0.05
                for link in links where link.a == i || link.b == i {
                    let mine = link.a == i
                    let other = mine ? link.b : link.a
                    let myAnchor = mine ? link.anchorA : link.anchorB, otherAnchor = mine ? link.anchorB : link.anchorA
                    let mySide = mine ? link.sideA : link.sideB, otherSide = mine ? link.sideB : link.sideA
                    // Las dos bocas, separadas `gap` casillas en la dirección de cada salida, quieren coincidir.
                    let tx = pos[other].x + otherAnchor.x + otherSide.normal.dx * half - myAnchor.x - mySide.normal.dx * half
                    let ty = pos[other].y + otherAnchor.y + otherSide.normal.dy * half - myAnchor.y - mySide.normal.dy * half
                    sx += tx * link.weight; wx += link.weight
                    sy += ty * link.weight; wy += link.weight
                }
                pos[i] = MapPoint(sx / wx, sy / wy)
            }
            Self.separate(&pos, rows: rows, areas: areas, gap: Double(gap), soft: true)
        }
        Self.separate(&pos, rows: rows, areas: areas, gap: Double(gap), soft: false)

        // A casillas enteras, sin solapes (empujando hacia abajo y a la derecha) y con el margen alrededor.
        var rects = areas.indices.map { TileRect(x: Int(pos[$0].x.rounded()), y: Int(pos[$0].y.rounded()),
                                                   width: areas[$0].width, height: areas[$0].height) }
        for (r, row) in rows.enumerated() where r > 0 {
            let above = rows[..<r].flatMap { $0 }.map { rects[$0].maxY }.max() ?? 0
            let top = row.map { rects[$0].y }.min() ?? 0
            if top < above + gap { for i in rows[r...].flatMap({ $0 }) { rects[i].y += above + gap - top } }
        }
        for row in rows {
            for k in row.indices.dropFirst() where rects[row[k]].x < rects[row[k - 1]].maxX + gap {
                let shift = rects[row[k - 1]].maxX + gap - rects[row[k]].x
                for i in row[k...] { rects[i].x += shift }
            }
        }
        let minX = rects.map(\.x).min() ?? 0, minY = rects.map(\.y).min() ?? 0
        for i in rects.indices {
            rects[i].x += margin - minX
            rects[i].y += margin - minY
        }
        width = (rects.map(\.maxX).max() ?? 0) + margin
        height = (rects.map(\.maxY).max() ?? 0) + margin
        frames = Dictionary(uniqueKeysWithValues: areas.indices.map { (areas[$0].id, rects[$0]) })

        // Caminos: entre salidas, en codo por el hueco; a otro continente, recto hasta el borde.
        var roads: [ContinentRoad] = []
        for link in links {
            let ra = rects[link.a], rb = rects[link.b]
            let a = MapPoint(Double(ra.x) + link.anchorA.x, Double(ra.y) + link.anchorA.y)
            let b = MapPoint(Double(rb.x) + link.anchorB.x, Double(rb.y) + link.anchorB.y)
            var points: [MapPoint]
            switch (link.sideA.isVertical, link.sideB.isVertical) {
            case (true, true):
                let midY = (a.y + b.y) / 2
                points = [a, MapPoint(a.x, midY), MapPoint(b.x, midY), b]
            case (false, false):
                let midX = (a.x + b.x) / 2
                points = [a, MapPoint(midX, a.y), MapPoint(midX, b.y), b]
            case (true, false):
                points = [a, MapPoint(a.x, b.y), b]
            case (false, true):
                points = [a, MapPoint(b.x, a.y), b]
            }
            let id = [link.exitA.id] + (link.exitB.map { [$0.id] } ?? [])
            roads.append(ContinentRoad(id: id.joined(separator: "+"), fromAreaID: areas[link.a].id, fromExitID: link.exitA.id,
                                       toAreaID: areas[link.b].id, toExitID: link.exitB?.id, destinationID: areas[link.b].id,
                                       width: min(4, max(2, link.exitA.tiles.count)), points: Self.simplified(points), label: nil))
        }
        for (i, area) in areas.enumerated() {
            for exit in area.exits where index[exit.toArea] == nil && exit.isFrontier {
                guard let side = exit.side(in: area), let anchor = exit.edgeAnchor(in: area) else { continue }
                let a = MapPoint(Double(rects[i].x) + anchor.x, Double(rects[i].y) + anchor.y)
                let end: MapPoint
                switch side {
                case .north: end = MapPoint(a.x, 0)
                case .south: end = MapPoint(a.x, Double(height))
                case .west: end = MapPoint(0, a.y)
                case .east: end = MapPoint(Double(width), a.y)
                }
                let name = World.continent(exit.toArea)?.name ?? exit.toArea.capitalized
                let soon: Bool = if case .comingSoon? = exit.lock { true } else { false }
                roads.append(ContinentRoad(id: exit.id, fromAreaID: area.id, fromExitID: exit.id, toAreaID: nil, toExitID: nil,
                                           destinationID: exit.toArea, width: min(4, max(2, exit.tiles.count)),
                                           points: [a, end], label: soon ? "\(name) · próximamente" : name))
            }
        }
        self.roads = roads
    }

    /// Separa franjas (filas) y columnas dentro de cada fila. `soft`: reparte el empujón a medias entre los dos
    /// lados (para que la iteración no derive); si no, empuja solo hacia abajo y a la derecha.
    private static func separate(_ pos: inout [MapPoint], rows: [[Int]], areas: [AreaMap], gap: Double, soft: Bool) {
        for r in rows.indices.dropFirst() {
            let above = rows[..<r].flatMap { $0 }.map { pos[$0].y + Double(areas[$0].height) }.max() ?? 0
            let top = rows[r].map { pos[$0].y }.min() ?? 0
            let need = above + gap - top
            guard need > 0 else { continue }
            for i in rows[r...].flatMap({ $0 }) { pos[i].y += soft ? need / 2 : need }
            if soft { for i in rows[..<r].flatMap({ $0 }) { pos[i].y -= need / 2 } }
        }
        for row in rows {
            for k in row.indices.dropFirst() {
                let need = pos[row[k - 1]].x + Double(areas[row[k - 1]].width) + gap - pos[row[k]].x
                guard need > 0 else { continue }
                for i in row[k...] { pos[i].x += soft ? need / 2 : need }
                if soft { for i in row[..<k] { pos[i].x -= need / 2 } }
            }
        }
    }

    private static func distance(_ exit: AreaExit, to tile: TilePoint?) -> Int {
        guard let tile else { return 0 }
        return exit.tiles.map { abs($0.x - tile.x) + abs($0.y - tile.y) }.min() ?? .max
    }

    /// Quita puntos repetidos y los intermedios alineados.
    private static func simplified(_ points: [MapPoint]) -> [MapPoint] {
        var out: [MapPoint] = []
        for p in points {
            if let last = out.last, abs(last.x - p.x) < 0.001, abs(last.y - p.y) < 0.001 { continue }
            if out.count >= 2 {
                let a = out[out.count - 2], b = out[out.count - 1]
                let cross = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
                if abs(cross) < 0.001 { out[out.count - 1] = p; continue }
            }
            out.append(p)
        }
        return out
    }
}

extension Continent {
    /// Colocación de sus áreas y caminos en el mapa de la pausa (calculada con los datos de hoy).
    public var placement: ContinentLayout { ContinentLayout(self) }
}
