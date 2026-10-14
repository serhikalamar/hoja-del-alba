import CoreGraphics
import Foundation
import GameCore

// MARK: - Mapa ilustrado del continente (pausa)
//
// Tres capas que se dibujan una vez y se guardan en `ContinentMapCache` (no se recalculan al hacer zoom):
// - **Áreas**: el mapa real de cada área con el arte del juego (`TownArt.ground`, edificios, árboles), 24 px por casilla.
//   Con el zoom máximo se ven como en la escena, y con filtro nearest no se difuminan.
// - **Fondo**: terreno que une las áreas, `backgroundScale` px por casilla: mar con costa irregular, praderas, bosques y
//   montañas que "sangran" del borde de cada área (árboles → bosque, acantilados → montañas), ríos que siguen el agua
//   que toca el borde de un área, caminos entre salidas con puentes y el paso hacia otro continente. Sale de los datos
//   (`ContinentLayout`), así que vale para cualquier continente.
// - **Niebla**: nubes sobre las áreas sin visitar, con su silueta (lo sólido algo más oscuro) pero sin detalle.
// Todo es puro (sin `ArtCache`, que es del hilo principal): se puede dibujar en segundo plano.

/// Caché de las imágenes del mapa del continente, segura entre hilos.
final class ContinentMapCache: @unchecked Sendable {
    static let shared = ContinentMapCache()
    private let lock = NSLock()
    private var images: [String: CGImage] = [:]

    func image(_ key: String) -> CGImage? {
        lock.lock(); defer { lock.unlock() }
        return images[key]
    }

    /// La imagen de la caché o, si no está, la dibuja (fuera del cerrojo) y la guarda.
    func image(_ key: String, build: () -> CGImage) -> CGImage {
        if let cached = image(key) { return cached }
        let made = build()
        lock.lock(); defer { lock.unlock() }
        if let raced = images[key] { return raced }
        images[key] = made
        return made
    }
}

/// Lienzo opaco rápido (un UInt32 RGB por pixel) para el fondo y la niebla.
struct MapCanvas {
    let width: Int
    let height: Int
    var pixels: [UInt32]
    /// Alfa (solo la niebla lo usa; el resto es opaco).
    var alpha: [Bool]?

    init(width: Int, height: Int, fill: UInt32, transparent: Bool = false) {
        self.width = width
        self.height = height
        pixels = Array(repeating: fill, count: width * height)
        alpha = transparent ? Array(repeating: false, count: width * height) : nil
    }

    @inline(__always) func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < width && y < height }

    @inline(__always) subscript(x: Int, y: Int) -> UInt32 {
        get { pixels[y * width + x] }
        set {
            guard inside(x, y) else { return }
            pixels[y * width + x] = newValue
            if alpha != nil { alpha![y * width + x] = true }
        }
    }

    /// Pega un sprite (lo transparente no pinta), opcionalmente ampliado `scale` veces.
    mutating func draw(_ grid: PixelGrid, x ox: Int, y oy: Int, scale: Int = 1) {
        for y in 0..<(grid.height * scale) {
            for x in 0..<(grid.width * scale) {
                if let c = grid[x / scale, y / scale] { self[ox + x, oy + y] = c }
            }
        }
    }

    func makeCGImage() -> CGImage {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for i in 0..<(width * height) {
            if let alpha, !alpha[i] { continue }
            let c = pixels[i]
            bytes[i * 4] = UInt8((c >> 16) & 0xFF)
            bytes[i * 4 + 1] = UInt8((c >> 8) & 0xFF)
            bytes[i * 4 + 2] = UInt8(c & 0xFF)
            bytes[i * 4 + 3] = 255
        }
        return PixelCanvas.image(width: width, height: height, pixels: bytes)
    }
}

enum ContinentMapArt {
    /// Pixeles de arte de las áreas por casilla (los del juego).
    static let areaScale = TownArt.tile
    /// Pixeles del fondo por casilla (cada pixel del fondo = 3 del arte de las áreas).
    static let backgroundScale = 8
    /// Pixeles de la niebla por casilla.
    static let fogScale = 4
    /// Casillas de niebla que sobresalen alrededor de un área sin visitar.
    static let fogPad = 1

    // MARK: Caché

    static func areaKey(_ id: String, castleOpen: Bool) -> String { "area.\(id).\(castleOpen)" }
    static func backgroundKey(_ layout: ContinentLayout, framed: Bool = true) -> String {
        "fondo.\(layout.continentID).\(layout.width)x\(layout.height).\(framed)"
    }
    static func fogKey(_ id: String) -> String { "niebla.\(id)" }

    static func cachedArea(_ area: AreaMap, castleOpen: Bool) -> CGImage {
        ContinentMapCache.shared.image(areaKey(area.id, castleOpen: castleOpen)) { areaGrid(area, castleOpen: castleOpen).makeCGImage() }
    }

    static func cachedBackground(_ layout: ContinentLayout, areas: [String: AreaMap], framed: Bool = true) -> CGImage {
        ContinentMapCache.shared.image(backgroundKey(layout, framed: framed)) { background(layout, areas: areas, framed: framed).makeCGImage() }
    }

    static func cachedFog(_ area: AreaMap) -> CGImage {
        ContinentMapCache.shared.image(fogKey(area.id)) { fog(area).makeCGImage() }
    }

    // MARK: Áreas: el mapa real

    /// Suelo + edificios + árboles y farolas, como la escena (y como `Harness maps`).
    static func areaGrid(_ area: AreaMap, castleOpen: Bool) -> PixelGrid {
        let T = TownArt.tile
        var grid = TownArt.ground(area)
        var items: [(Int, PixelGrid, Int, Int)] = []
        var trees: [Int: PixelGrid] = [:]
        for y in 0..<area.height {
            for x in 0..<area.width {
                switch area.tile(x, y) {
                case .tree:
                    let variant = TownArt.treeVariant(area, x, y)
                    let tree = trees[variant] ?? TownArt.tree(variant: variant)
                    trees[variant] = tree
                    items.append(((y + 1) * T, tree, x * T + T / 2 - tree.width / 2, (y + 1) * T - tree.height + 2))
                case .lamp:
                    items.append(((y + 1) * T, TownArt.lamp, x * T + T / 2 - TownArt.lamp.width / 2, (y + 1) * T - TownArt.lamp.height))
                default:
                    break
                }
            }
        }
        for b in area.buildings {
            let art = TownArt.building(b, open: b.style != .castle || castleOpen)
            items.append(((b.y + b.height) * T, art, b.x * T - 1, (b.y + b.height) * T - art.height + 1))
        }
        for item in items.sorted(by: { $0.0 < $1.0 }) { grid.draw(item.1, x: item.2, y: item.3) }
        return grid
    }

    // MARK: Fondo: terreno que une las áreas

    /// Lo que crece en una casilla del fondo.
    enum Feature: UInt8 { case meadow, forest, mountain, hills, clear }

    /// Paletas del fondo.
    enum Ink {
        static let deep: [UInt32] = [0x1E4A78, 0x22548A, 0x285F96]
        static let shallow: [UInt32] = [0x3A7CB4, 0x4689C0]
        static let wave: UInt32 = 0x7DB4DE
        static let foam: UInt32 = 0xCFE6F2
        static let sand: [UInt32] = [0xC8B07A, 0xD6BF88, 0xE0CB96]
        static let meadow: [UInt32] = [0x4E8A3E, 0x569443, 0x5F9E49, 0x68A84F, 0x72B055]
        static let forestFloor: [UInt32] = [0x2F5E2E, 0x356834, 0x3B7139]
        static let rocky: [UInt32] = [0x6E7458, 0x7A7F60, 0x868A6A, 0x92957A]
        static let dirt: [UInt32] = [0x8E6C44, 0x9C7A4E, 0xAA885A]
        static let dirtEdge: UInt32 = 0x5E4630
        static let water: [UInt32] = [0x2E6FB8, 0x3B7DD8, 0x4C8EE0]
        static let bank: UInt32 = 0x2C4A30
        static let plank: [UInt32] = [0x7A5634, 0x8E6A40, 0x6A4A2C]
        static let ink: UInt32 = 0x3A2A1E
        static let parchment: [UInt32] = [0xD9C49A, 0xE4D2AA, 0xCDB68A]
    }

    /// Fondo del continente (`backgroundScale` px por casilla).
    /// `framed`: con marco de pergamino y rosa de los vientos (el continente suelto); sin ellos va dentro del mundo.
    static func background(_ layout: ContinentLayout, areas: [String: AreaMap], framed: Bool = true) -> MapCanvas {
        let S = backgroundScale
        let W = layout.width, H = layout.height
        var c = MapCanvas(width: W * S, height: H * S, fill: Ink.deep[0])
        let rects = layout.areaIDs.compactMap { id in layout.frame(of: id).map { (id, $0) } }
        let frontier = layout.roads.filter(\.isFrontier)

        // Distancia (en casillas) al tramo de un camino.
        func segmentDistance(_ p: MapPoint, _ a: MapPoint, _ b: MapPoint) -> Double {
            let vx = b.x - a.x, vy = b.y - a.y
            let len = vx * vx + vy * vy
            let t = len > 0 ? max(0, min(1, ((p.x - a.x) * vx + (p.y - a.y) * vy) / len)) : 0
            let dx = p.x - (a.x + vx * t), dy = p.y - (a.y + vy * t)
            return (dx * dx + dy * dy).squareRoot()
        }
        func roadDistance(_ p: MapPoint, _ road: ContinentRoad) -> Double {
            zip(road.points, road.points.dropFirst()).map { segmentDistance(p, $0, $1) }.min() ?? .infinity
        }
        func fbm(_ x: Double, _ y: Double, _ s: Int) -> Double {
            TownArt.noise(x, y, s) * 0.62 + TownArt.noise(x * 2.1, y * 2.1, s + 1) * 0.28 + TownArt.noise(x * 4.3, y * 4.3, s + 2) * 0.10
        }
        /// > 0 en el mar (casillas hasta la costa); <= 0 en tierra.
        func coast(_ p: MapPoint) -> Double {
            let reach = 6.5 + 8 * fbm(p.x * 0.06, p.y * 0.06, 11)
            var d = rects.map { $0.1.distance(to: p) }.min() ?? .infinity
            for road in frontier { d = min(d, roadDistance(p, road) * 0.8) }
            return d - reach
        }

        // 1. Qué crece en cada casilla, según el borde del área más cercana.
        var feature = [Feature](repeating: .meadow, count: W * H)
        var coastTile = [Double](repeating: 0, count: W * H)
        func kind(of tile: Tile) -> Feature {
            switch tile {
            case .tree, .bush: .forest
            case .cliff, .rock: .mountain
            default: .meadow
            }
        }
        for ty in 0..<H {
            for tx in 0..<W {
                let p = MapPoint(Double(tx) + 0.5, Double(ty) + 0.5)
                coastTile[ty * W + tx] = coast(p)
                guard let (id, rect) = rects.min(by: { $0.1.distance(to: p) < $1.1.distance(to: p) }), let area = areas[id] else { continue }
                var d = rect.distance(to: p)
                if d == 0 { feature[ty * W + tx] = .clear; continue }
                // Borde más cercano: se mira un tramo de 7 casillas para no copiar casillas sueltas.
                let bx = max(0, min(area.width - 1, tx - rect.x)), by = max(0, min(area.height - 1, ty - rect.y))
                var votes: [Feature: Int] = [:]
                let alongX = by == 0 || by == area.height - 1
                for k in -3...3 {
                    let t = area.tile(alongX ? bx + k : bx, alongX ? by : by + k)
                    votes[kind(of: t), default: 0] += 1
                }
                var source = votes.max { ($0.value, $0.key.rawValue) < ($1.value, $1.key.rawValue) }?.key ?? .meadow
                // El paso a otro continente: montañas (o lo que haya en esa salida) a los lados del camino.
                for road in frontier {
                    let rd = roadDistance(p, road)
                    if rd < d, let from = areas[road.fromAreaID] {
                        d = rd - Double(road.width) / 2
                        let exit = from.exits.first { $0.id == road.fromExitID }
                        let edge = exit?.tiles.first ?? TilePoint(0, 0)
                        let across = exit?.side(in: from)?.isVertical ?? alongX
                        var near: [Feature: Int] = [:]
                        for k in [-6, -5, -4, 4, 5, 6] {
                            let t = from.tile(edge.x + (across ? k : 0), edge.y + (across ? 0 : k))
                            near[kind(of: t), default: 0] += 1
                        }
                        source = near.max { ($0.value, $0.key.rawValue) < ($1.value, $1.key.rawValue) }?.key ?? source
                    }
                }
                let n = fbm(Double(tx) * 0.18, Double(ty) * 0.18, 23)
                var f = Feature.meadow
                switch source {
                case .forest where d < 2.5 + 6 * n: f = .forest
                case .mountain where d < 3 + 9 * n: f = .mountain
                default: break
                }
                if f == .meadow, d > 3 {
                    // Bosquecillos y lomas sueltas en las praderas.
                    if fbm(Double(tx) * 0.11, Double(ty) * 0.11, 77) > 0.66 { f = .forest }
                    else if fbm(Double(tx) * 0.09, Double(ty) * 0.09, 91) > 0.70 { f = .hills }
                }
                feature[ty * W + tx] = f
            }
        }

        // 2. Ríos: el agua que toca el borde de un área sigue fuera, serpenteando, hasta el mar.
        var rivers: [(points: [MapPoint], width: Double)] = []
        for (id, rect) in rects {
            guard let area = areas[id] else { continue }
            for side in MapSide.allCases {
                let count = side.isVertical ? area.width : area.height
                var run: [Int] = []
                func flush() {
                    defer { run = [] }
                    guard run.count >= 2 else { return }
                    let mid = Double(run.first! + run.last! + 1) / 2
                    var p: MapPoint
                    switch side {
                    case .north: p = MapPoint(Double(rect.x) + mid, Double(rect.y))
                    case .south: p = MapPoint(Double(rect.x) + mid, Double(rect.maxY))
                    case .west: p = MapPoint(Double(rect.x), Double(rect.y) + mid)
                    case .east: p = MapPoint(Double(rect.maxX), Double(rect.y) + mid)
                    }
                    var points = [p]
                    let (nx, ny) = side.normal
                    for step in 1...90 {
                        let wiggle = (TownArt.noise(Double(step) * 0.12, Double(rect.x + rect.y), 5) - 0.5) * 1.6
                        p = MapPoint(p.x + nx + (side.isVertical ? wiggle : 0), p.y + ny + (side.isVertical ? 0 : wiggle))
                        points.append(p)
                        if coast(p) > 1.5 || p.x < 0 || p.y < 0 || p.x > Double(W) || p.y > Double(H) { break }
                        if step > 2, rects.contains(where: { $0.1.distance(to: p) < 1 }) { break }
                    }
                    rivers.append((points, Double(run.count)))
                }
                for i in 0..<count {
                    let t = switch side {
                    case .north: area.tile(i, 0)
                    case .south: area.tile(i, area.height - 1)
                    case .west: area.tile(0, i)
                    case .east: area.tile(area.width - 1, i)
                    }
                    if t == .water { run.append(i) } else { flush() }
                }
                flush()
            }
        }

        // 3. Suelo pixel a pixel: mar, costa, praderas, bosque y roca.
        let inv = 1 / Double(S)
        var isSea = [Bool](repeating: false, count: c.width * c.height)
        // El ruido del suelo cambia despacio: se calcula por bloques de 4×4 px (el tramado sigue siendo por pixel).
        let bw = (W * S + 3) / 4, bh = (H * S + 3) / 4
        var groundNoise = [Double](repeating: 0, count: bw * bh)
        for by in 0..<bh { for bx in 0..<bw { groundNoise[by * bw + bx] = fbm(Double(bx * 4) * 0.035, Double(by * 4) * 0.035, 7) } }
        for py in 0..<(H * S) {
            for px in 0..<(W * S) {
                let p = MapPoint((Double(px) + 0.5) * inv, (Double(py) + 0.5) * inv)
                let tx = min(W - 1, px / S), ty = min(H - 1, py / S)
                // La costa se calcula fina (pixel a pixel) solo cerca de la orilla.
                let coarse = coastTile[ty * W + tx]
                let k = abs(coarse) < 2.5 ? coast(p) : coarse
                let color: UInt32
                isSea[py * c.width + px] = k > 0
                if k > 1.6 {
                    let depth = min(1, (k - 1.6) / 6)
                    color = TownArt.tone(Ink.deep.reversed(), 1 - depth, px, py, dither: 0.35)
                } else if k > 0.25 {
                    color = TownArt.tone(Ink.shallow, (1.6 - k) / 1.4, px, py, dither: 0.3)
                } else if k > 0 {
                    color = Ink.foam
                } else if k > -0.9 {
                    color = TownArt.tone(Ink.sand, fbm(Double(px) * 0.2, Double(py) * 0.2, 3), px, py)
                } else {
                    let n = groundNoise[(py / 4) * bw + px / 4]
                    switch feature[ty * W + tx] {
                    case .forest: color = TownArt.tone(Ink.forestFloor, n, px, py)
                    case .mountain: color = TownArt.tone(Ink.rocky, n, px, py)
                    default:
                        // Pradera con briznas y alguna flor suelta.
                        let h = TownArt.hash(px, py, 13) % 1000
                        color = h < 9 ? 0x8CC462 : (h < 11 ? TownArt.pick([0xF6D45A, 0xF4F0E8, 0xE88AB4], px, py, 14)
                                                            : TownArt.tone(Ink.meadow, n, px, py, dither: 0.25))
                    }
                }
                c.pixels[py * c.width + px] = color
            }
        }
        // Olas sueltas en el mar (solo en el continente suelto: dentro del mundo, el mar es liso para que case).
        for gy in framed ? Array(stride(from: 4, to: H * S - 4, by: 11)) : [] {
            for gx in stride(from: 3, to: W * S - 6, by: 14) {
                let x = gx + TownArt.hash(gx, gy, 31) % 7, y = gy + TownArt.hash(gx, gy, 32) % 5
                guard TownArt.chance(gx, gy, 33, 0.45), coast(MapPoint(Double(x) * inv, Double(y) * inv)) > 2.2 else { continue }
                c[x, y + 1] = Ink.wave; c[x + 1, y] = Ink.wave; c[x + 2, y] = Ink.wave; c[x + 3, y + 1] = Ink.wave
            }
        }

        // 4. Ríos y caminos, estampando discos a lo largo del trazado (esquinas redondeadas).
        func stamp(_ points: [MapPoint], radius: Double, _ paint: (Int, Int, Double) -> Void) {
            let r = radius * Double(S), step = 0.25
            var done = Set<Int>()
            for (a, b) in zip(points, points.dropFirst()) {
                let len = ((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)).squareRoot()
                let n = max(1, Int(len / step))
                for i in 0...n {
                    let t = Double(i) / Double(n)
                    let cx = (a.x + (b.x - a.x) * t) * Double(S), cy = (a.y + (b.y - a.y) * t) * Double(S)
                    for y in Int(cy - r - 1)...Int(cy + r + 1) {
                        for x in Int(cx - r - 1)...Int(cx + r + 1) where c.inside(x, y) {
                            let d = ((Double(x) + 0.5 - cx) * (Double(x) + 0.5 - cx) + (Double(y) + 0.5 - cy) * (Double(y) + 0.5 - cy)).squareRoot()
                            guard d <= r else { continue }
                            let key = y * c.width + x
                            // Se pinta con la distancia más corta al trazado.
                            if done.contains(key) && d > r - 1.2 { continue }
                            done.insert(key)
                            paint(x, y, d / r)
                        }
                    }
                }
            }
        }
        var isRiver = [Bool](repeating: false, count: c.width * c.height)
        for river in rivers {
            stamp(river.points, radius: river.width / 2 + 0.35) { x, y, d in
                if isRiver[y * c.width + x] || isSea[y * c.width + x] { return }
                if d > 0.82 { c[x, y] = Ink.bank; return }
                c[x, y] = TownArt.tone(Ink.water, 0.55 + TownArt.noise(Double(x) * 0.3, Double(y) * 0.3, 8) * 0.4 - d * 0.2, x, y, dither: 0.3)
            }
            stamp(river.points, radius: river.width / 2) { x, y, _ in isRiver[y * c.width + x] = !isSea[y * c.width + x] }
        }
        for road in layout.roads {
            let horizontalAt: (Int, Int) -> Bool = { x, y in
                // Dirección del tramo más cercano (para las tablas de los puentes).
                let p = MapPoint(Double(x) * inv, Double(y) * inv)
                let seg = zip(road.points, road.points.dropFirst()).min { segmentDistance(p, $0.0, $0.1) < segmentDistance(p, $1.0, $1.1) }
                guard let seg else { return true }
                return abs(seg.1.x - seg.0.x) > abs(seg.1.y - seg.0.y)
            }
            stamp(road.points, radius: Double(road.width) / 2 + 0.15) { x, y, d in
                if isRiver[y * c.width + x] {
                    // Puente de tablas sobre el río.
                    let along = horizontalAt(x, y)
                    let line = along ? x % 3 == 0 : y % 3 == 0
                    c[x, y] = d > 0.86 ? Ink.plank[2] : (line ? Ink.plank[2] : TownArt.pick(Ink.plank, along ? x / 3 : y / 3, 0, 9))
                    return
                }
                if d > 0.88 { c[x, y] = Ink.dirtEdge; return }
                c[x, y] = TownArt.tone(Ink.dirt, 0.5 + (TownArt.noise(Double(x) * 0.4, Double(y) * 0.4, 12) - 0.5) * 0.9, x, y, dither: 0.4)
            }
        }
        // Casillas cerca de un camino o río: sin árboles ni montañas encima.
        var blocked = coastTile.map { $0 > -1.2 }
        func block(_ points: [MapPoint], radius: Double) {
            for (a, b) in zip(points, points.dropFirst()) {
                let len = ((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)).squareRoot()
                let n = max(1, Int(len * 2))
                for i in 0...n {
                    let t = Double(i) / Double(n)
                    let cx = a.x + (b.x - a.x) * t, cy = a.y + (b.y - a.y) * t
                    for ty in Int(cy - radius - 1)...Int(cy + radius + 1) where ty >= 0 && ty < H {
                        for tx in Int(cx - radius - 1)...Int(cx + radius + 1) where tx >= 0 && tx < W {
                            if hypot(Double(tx) + 0.5 - cx, Double(ty) + 0.5 - cy) < radius { blocked[ty * W + tx] = true }
                        }
                    }
                }
            }
        }
        for road in layout.roads { block(road.points, radius: Double(road.width) / 2 + 1.2) }
        for river in rivers { block(river.points, radius: river.width / 2 + 1) }

        // 5. Árboles, lomas y montañas, de atrás hacia delante.
        var sprites: [(y: Int, grid: PixelGrid, x: Int)] = []
        let oak = treeSprite(pine: false), pine = treeSprite(pine: true), hill = hillSprite()
        for ty in 0..<H {
            for tx in 0..<W {
                let i = ty * W + tx
                guard !blocked[i] else { continue }
                let h = TownArt.hash(tx, ty, 41)
                switch feature[i] {
                case .forest:
                    for k in 0..<2 {
                        let tree = TownArt.chance(tx, ty, 42 + k, 0.3) ? pine : oak
                        let x = tx * S + (h >> (k * 4)) % S - tree.width / 2, by = ty * S + (h >> (k * 4 + 8)) % S
                        sprites.append((by, tree, x))
                    }
                case .mountain:
                    guard tx % 3 == (ty % 2) * 1, TownArt.chance(tx, ty, 43, 0.85) else { continue }
                    let size = 3 + h % 4
                    let m = mountainSprite(width: size * S / 2 + 10, seed: h)
                    sprites.append((ty * S + S, m, tx * S + S / 2 - m.width / 2 + h % 5 - 2))
                case .hills:
                    guard (tx + ty) % 3 == 0, TownArt.chance(tx, ty, 44, 0.6) else { continue }
                    sprites.append((ty * S + S, hill, tx * S - hill.width / 2 + S / 2))
                default:
                    break
                }
            }
        }
        for s in sprites.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }) { c.draw(s.grid, x: s.x, y: s.y - s.grid.height) }

        // 6. Rosa de los vientos en el mar y marco de pergamino.
        guard framed else { return c }
        let rose = compassRose(), rs = 3, rw = rose.width * rs, rh = rose.height * rs, m = 3 * S
        let corners = [(m, H * S - rh - m), (W * S - rw - m, H * S - rh - m), (W * S - rw - m, m), (m, m)]
        if let spot = corners.first(where: { corner in
            [(0, 0), (rw, 0), (0, rh), (rw, rh), (rw / 2, rh / 2)].allSatisfy { coast(MapPoint(Double(corner.0 + $0.0) * inv, Double(corner.1 + $0.1) * inv)) > 1.6 }
        }) {
            c.draw(rose, x: spot.0, y: spot.1, scale: rs)
        }
        frame(&c, thickness: 2 * S)
        return c
    }

    /// Marco de pergamino con doble línea de tinta y esquinas.
    private static func frame(_ c: inout MapCanvas, thickness t: Int) {
        for y in 0..<c.height {
            let band = y < t || y >= c.height - t
            for x in band ? Array(0..<c.width) : Array(0..<t) + Array((c.width - t)..<c.width) {
                let e = min(x, y, c.width - 1 - x, c.height - 1 - y)
                guard e < t else { continue }
                if e == 0 || e == t - 1 || e == t - 4 { c[x, y] = Ink.ink; continue }
                c[x, y] = TownArt.tone(Ink.parchment, TownArt.noise(Double(x) * 0.15, Double(y) * 0.15, 4), x, y, dither: 0.4)
            }
        }
        for (cx, cy) in [(0, 0), (c.width - t, 0), (0, c.height - t), (c.width - t, c.height - t)] {
            for y in 0..<t { for x in 0..<t { c[cx + x, cy + y] = (x + y) % 2 == 0 || x == 0 || y == 0 || x == t - 1 || y == t - 1 ? Ink.ink : 0xA2443A } }
            for y in 3..<(t - 3) { for x in 3..<(t - 3) { c[cx + x, cy + y] = abs(x - t / 2) + abs(y - t / 2) <= t / 2 - 4 ? 0xE8C060 : 0x7A2C26 } }
        }
    }

    // MARK: Sprites del fondo

    static func treeSprite(pine: Bool) -> PixelGrid {
        let rows = pine ? [
            "...d...",
            "..dgd..",
            "..ggl..",
            ".dggld.",
            ".dgggl.",
            "ddggggl",
            "dddgggd",
            "...t...",
        ] : [
            "..ddd..",
            ".dgggl.",
            "dggglll",
            "dgggggl",
            "ddggggd",
            ".dddgd.",
            "...t...",
        ]
        let palette: [Character: UInt32] = pine ? ["d": 0x1C3E2A, "g": 0x2A5A3A, "l": 0x3F7A4A, "t": 0x4A3424]
                                                 : ["d": 0x24502A, "g": 0x356E36, "l": 0x4F8C44, "t": 0x553A26]
        return PixelGrid(PixelSprite(rows: rows, palette: palette)).outlined(0x13261A)
    }

    static func hillSprite() -> PixelGrid {
        let rows = [
            "....llll....",
            "..llmmmmdd..",
            ".lmmmmmmmdd.",
            "lmmmmmmmmmdd",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["l": 0x84BC5E, "m": 0x67A24C, "d": 0x4C8040])).outlined(0x2E4A26)
    }

    /// Monte con cara iluminada a la izquierda, sombra a la derecha y nieve en la cima si es alto.
    static func mountainSprite(width w: Int, seed: Int) -> PixelGrid {
        let h = max(8, w * 3 / 4)
        var g = PixelGrid(width: w, height: h)
        let peak = w / 2 + (seed % 5) - 2
        let lit: [UInt32] = [0x8F8574, 0xA69A84, 0xBBAF96], shade: [UInt32] = [0x5E5448, 0x6E6456]
        let snow: UInt32 = 0xF2F4F8, snowShade: UInt32 = 0xC4CCD8
        for y in 0..<h {
            let t = Double(y) / Double(h - 1)
            let left = Double(peak) - t * Double(peak), right = Double(peak) + t * Double(w - 1 - peak)
            for x in 0..<w where Double(x) >= left.rounded(.down) && Double(x) <= right.rounded(.up) {
                let east = x > peak + (y % 3 == 0 ? 1 : 0)
                var col = east ? TownArt.tone(shade, TownArt.noise(Double(x) * 0.5, Double(y) * 0.5, seed), x, y)
                               : TownArt.tone(lit, 0.3 + 0.7 * (1 - t) + (TownArt.noise(Double(x) * 0.5, Double(y) * 0.5, seed) - 0.5) * 0.4, x, y)
                if h >= 18, t < 0.32 + Double(TownArt.hash(x, 0, seed) % 3) * 0.04 { col = east ? snowShade : snow }
                g[x, y] = col
            }
        }
        return g.outlined(0x2A2420)
    }

    /// Rosa de los vientos (N arriba).
    static func compassRose() -> PixelGrid {
        let rows = [
            "......N......",
            "......l......",
            ".....lnl.....",
            ".....lnl.....",
            "..k..lnl..k..",
            "...k.lnl.k...",
            "llllllcdddddd",
            "...k.dnd.k...",
            "..k..dnd..k..",
            ".....dnd.....",
            ".....dnd.....",
            "......d......",
            ".............",
        ]
        let palette: [Character: UInt32] = ["N": 0xE8C060, "l": 0xF0E2C0, "n": 0xC8A050, "d": 0x8A6A40, "c": 0xA2443A, "k": 0xCFE6F2]
        return PixelGrid(PixelSprite(rows: rows, palette: palette)).outlined(Ink.ink)
    }

    // MARK: Niebla

    /// Nubes sobre un área sin visitar: se adivina su silueta (bosque, roca y agua más oscuros) pero no el detalle.
    static func fog(_ area: AreaMap) -> MapCanvas {
        let S = fogScale, pad = fogPad
        let W = area.width + 2 * pad, H = area.height + 2 * pad
        var c = MapCanvas(width: W * S, height: H * S, fill: 0, transparent: true)
        // Solidez suavizada (3×3 casillas): 0 claro, 1 bosque o roca.
        var solid = [Double](repeating: 0, count: W * H)
        for ty in 0..<H {
            for tx in 0..<W {
                var sum = 0.0, n = 0.0
                for dy in -1...1 {
                    for dx in -1...1 {
                        let x = tx - pad + dx, y = ty - pad + dy
                        guard x >= 0, y >= 0, x < area.width, y < area.height else { continue }
                        let t = area.tile(x, y)
                        sum += (t.isSolid && t != .water) || area.building(at: TilePoint(x, y)) != nil ? 1 : 0
                        n += 1
                    }
                }
                solid[ty * W + tx] = n > 0 ? sum / n : 1
            }
        }
        let cloud: [UInt32] = [0x9AA2B4, 0xAEB5C4, 0xC0C6D2, 0xD2D7E0, 0xE2E6EC]
        for py in 0..<(H * S) {
            for px in 0..<(W * S) {
                let x = Double(px) / Double(S), y = Double(py) / Double(S)
                // Borde de nube irregular en la casilla de margen.
                let edge = min(x, y, Double(W) - x, Double(H) - y)
                let puff = TownArt.noise(x * 0.3, y * 0.3, 61) * 1.5 + TownArt.noise(x * 1.1, y * 1.1, 64) * 0.4 + TownArt.bayer(px, py) * 0.25
                guard edge > puff else { continue }
                let s = solid[min(H - 1, py / S) * W + min(W - 1, px / S)]
                let n = TownArt.noise(x * 0.12, y * 0.12, 62) * 0.6 + TownArt.noise(x * 0.4, y * 0.4, 63) * 0.4
                // Borde de la nube algo más oscuro (se lee el contorno) y la silueta del área dentro.
                let rim = edge - puff < 0.25 ? 0.25 : 0
                c[px, py] = TownArt.tone(cloud, 0.3 + n * 0.75 - s * 0.55 - rim, px, py, dither: 0.3)
            }
        }
        return c
    }

    // MARK: Iconos del mapa

    static let campfire: PixelGrid = {
        let rows = [
            "....y....",
            "...yoy...",
            "..yoroy..",
            "..orrro..",
            ".b.ror.b.",
            "..bbbbb..",
            ".bBbBbBb.",
            "bB.....Bb",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["y": 0xFFE07A, "o": 0xFF9A2E, "r": 0xE0461E,
                                                           "b": 0x6A4426, "B": 0x8E5E34])).outlined()
    }()

    static let dungeon: PixelGrid = {
        let rows = [
            "...ssss...",
            "..sSSSSs..",
            ".sS....Ss.",
            ".S.kkkk.S.",
            "sS.kwwk.Ss",
            "sS.kkkk.Ss",
            "sS.k..k.Ss",
            "sS.kkkk.Ss",
            "SSSSSSSSSS",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["s": 0x6C6A7A, "S": 0x9997A7, "k": 0x1A1424, "w": 0xE8E2D0])).outlined()
    }()

    static let signpost: PixelGrid = {
        let rows = [
            "bbbbbbbbbB.",
            "bLLLLLLLLbB",
            "bbbbbbbbbB.",
            "....pp.....",
            "....pp.....",
            "....pp.....",
            "...gppg....",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["b": 0x9C6B3A, "B": 0x7A5030, "L": 0x5A3A22,
                                                           "p": 0x6A4426, "g": 0x4E8A3E])).outlined()
    }()

    static let targetFlag: PixelGrid = {
        let rows = [
            "prrrrr.",
            "prRRrrr",
            "prRRrr.",
            "prrrr..",
            "p......",
            "p......",
            "p......",
            "pp.....",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["p": 0x5A3A22, "r": 0xE43B44, "R": 0xFFCD75])).outlined()
    }()

    /// Cara chibi del héroe: la cabeza de su sprite de pie, recortada.
    static func heroFace(_ look: HeroLook) -> PixelGrid {
        let body = HeroArt.grid(look, pose: .idle0)
        var top = 0
        while top < body.height, !(0..<body.width).contains(where: { body[$0, top] != nil }) { top += 1 }
        let h = min(25, body.height - top)
        let cols = (0..<body.width).filter { x in (top..<(top + h)).contains { body[x, $0] != nil } }
        let x0 = cols.first ?? 0, x1 = cols.last ?? body.width - 1
        var face = PixelGrid(width: x1 - x0 + 1, height: h)
        for y in 0..<h { for x in 0..<face.width { face[x, y] = body[x0 + x, top + y] } }
        return face
    }
}
