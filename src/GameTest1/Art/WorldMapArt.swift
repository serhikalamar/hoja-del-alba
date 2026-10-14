import CoreGraphics
import Foundation
import GameCore

// MARK: - Mapa del mundo (Ardenia) para la pausa
//
// Fondo del mundo entero a `worldScale` px por casilla, dibujado una vez en segundo plano (`ContinentMapCache`):
// mar, rosa de los vientos, la Luna agrietada, marco de pergamino, rutas punteadas entre continentes y la silueta de
// cada continente según su terreno (`ContinentTerrain`). Los que aún no se pueden jugar salen **en gris**, con sus
// áreas del boceto como manchas claras de borde punteado y sus sitios señalados (capital, minas, volcán, cráter,
// ciudadela). Los jugables se tapan luego con su mapa detallado (`ContinentMapArt`), así que aquí solo hace falta su
// costa para que el mar case.
extension ContinentMapArt {
    /// Pixeles del fondo del mundo por casilla.
    static let worldScale = 2

    static func worldKey(_ world: WorldLayout) -> String {
        "mundo.\(world.width)x\(world.height)." + world.continents.map { "\($0.id)\($0.isPlayable ? 1 : 0)" }.joined()
    }

    static func cachedWorld(_ world: WorldLayout) -> CGImage {
        ContinentMapCache.shared.image(worldKey(world)) { worldBackground(world).makeCGImage() }
    }

    /// Tonos de cada terreno (de oscuro a claro). Los no jugables se pasan a gris al final.
    private static func groundTones(_ terrain: ContinentTerrain) -> [UInt32] {
        switch terrain {
        case .meadow: Ink.meadow
        case .mountains: [0x5E5A54, 0x6C675F, 0x7A746A, 0x888176]
        case .silverForest: [0x2A3A46, 0x31444F, 0x384E58, 0x415864]
        case .ashDesert: [0x3C3634, 0x48413D, 0x544B45, 0x60574F]
        case .glacier: [0xB8CCD8, 0xC8DAE4, 0xD8E6EE, 0xE6F0F4]
        case .skyIslands: [0x5A6A4E, 0x667858, 0x728462, 0x7E906C]
        }
    }

    static func worldBackground(_ world: WorldLayout) -> MapCanvas {
        let S = worldScale, W = world.width, H = world.height
        var c = MapCanvas(width: W * S, height: H * S, fill: Ink.deep[0])
        var gray = [Bool](repeating: false, count: c.width * c.height)
        let continents = world.continents
        let rects: [[TileRect]] = continents.map { pc in pc.layout.areaIDs.compactMap { pc.frame(of: $0) } }
        let islands = continents.map { $0.entry.terrain == .skyIslands }
        func fbm(_ x: Double, _ y: Double, _ s: Int) -> Double {
            TownArt.noise(x, y, s) * 0.62 + TownArt.noise(x * 2.1, y * 2.1, s + 1) * 0.28 + TownArt.noise(x * 4.3, y * 4.3, s + 2) * 0.10
        }
        func segmentDistance(_ p: MapPoint, _ a: MapPoint, _ b: MapPoint) -> Double {
            let vx = b.x - a.x, vy = b.y - a.y, len = vx * vx + vy * vy
            let t = len > 0 ? max(0, min(1, ((p.x - a.x) * vx + (p.y - a.y) * vy) / len)) : 0
            return hypot(p.x - (a.x + vx * t), p.y - (a.y + vy * t))
        }
        let landRoutes = world.routes.filter { $0.route.kind == .road || $0.route.kind == .tunnel }
        /// > 0 en el mar; <= 0 en tierra, para el continente `i`.
        func coast(_ p: MapPoint, _ i: Int) -> Double {
            if islands[i] {
                // Islas redondeadas: distancia a la elipse de cada área (en casillas, aproximada).
                let e = rects[i].map { r -> Double in
                    let rx = Double(r.width) / 2 + 2, ry = Double(r.height) / 2 + 2
                    let u = (p.x - r.center.x) / rx, v = (p.y - r.center.y) / ry
                    return ((u * u + v * v).squareRoot() - 1) * min(rx, ry)
                }.min() ?? .infinity
                return e - 2.5 * fbm(p.x * 0.15, p.y * 0.15, 21)
            }
            let d = rects[i].map { $0.distance(to: p) }.min() ?? .infinity
            var k = d - (6.5 + 8 * fbm(p.x * 0.06, p.y * 0.06, 11))
            for route in landRoutes where route.route.fromContinent == continents[i].id || route.route.toContinent == continents[i].id {
                let rd = zip(route.points, route.points.dropFirst()).map { segmentDistance(p, $0, $1) }.min() ?? .infinity
                k = min(k, rd - (4 + 3 * fbm(p.x * 0.1, p.y * 0.1, 12)))
            }
            return k
        }

        // 1. Por casilla: continente más cercano y costa aproximada.
        var owner = [Int](repeating: -1, count: W * H)
        var coarse = [Double](repeating: 99, count: W * H)
        for (i, pc) in continents.enumerated() {
            // Su tierra y la de sus caminos o túneles a otros continentes.
            let routePoints = landRoutes.filter { $0.route.fromContinent == pc.id || $0.route.toContinent == pc.id }.flatMap(\.points)
            let b = pc.landBounds
            let x0 = min(b.x, Int(routePoints.map(\.x).min() ?? Double(b.x))), x1 = max(b.maxX, Int(routePoints.map(\.x).max() ?? 0))
            let y0 = min(b.y, Int(routePoints.map(\.y).min() ?? Double(b.y))), y1 = max(b.maxY, Int(routePoints.map(\.y).max() ?? 0))
            let reach = 24
            for ty in max(0, y0 - reach)..<min(H, y1 + reach) {
                for tx in max(0, x0 - reach)..<min(W, x1 + reach) {
                    let k = coast(MapPoint(Double(tx) + 0.5, Double(ty) + 0.5), i)
                    if k < coarse[ty * W + tx] { coarse[ty * W + tx] = k; owner[ty * W + tx] = i }
                }
            }
        }

        // 2. Suelo pixel a pixel.
        let inv = 1 / Double(S)
        for py in 0..<(H * S) {
            for px in 0..<(W * S) {
                let tx = px / S, ty = py / S, ti = ty * W + tx
                let i = owner[ti]
                var k = coarse[ti]
                if i >= 0, abs(k) < 2 { k = coast(MapPoint((Double(px) + 0.5) * inv, (Double(py) + 0.5) * inv), i) }
                let color: UInt32
                if i < 0 || k > 1.6 {
                    let depth = i < 0 ? 1 : min(1, (k - 1.6) / 6)
                    color = TownArt.tone(Ink.deep.reversed(), 1 - depth, px, py, dither: 0.35)
                } else if k > 0.25 {
                    color = islands[i] ? TownArt.tone(Ink.deep.reversed(), 0.2, px, py, dither: 0.35)
                                       : TownArt.tone(Ink.shallow, (1.6 - k) / 1.4, px, py, dither: 0.3)
                } else if k > 0 {
                    color = islands[i] ? TownArt.tone(Ink.deep.reversed(), 0.2, px, py) : Ink.foam
                } else {
                    let terrain = continents[i].entry.terrain
                    let x = Double(px) * inv, y = Double(py) * inv
                    let n = fbm(x * 0.05, y * 0.05, 7)
                    var col: UInt32
                    if k > -0.9, !islands[i], terrain != .glacier {
                        col = TownArt.tone(Ink.sand, n, px, py)
                    } else if islands[i] && k > -0.7 {
                        col = 0x4A4038   // borde de roca de la isla
                    } else {
                        col = TownArt.tone(groundTones(terrain), n, px, py, dither: 0.3)
                        switch terrain {
                        case .ashDesert:
                            // Dunas: rayas oscuras onduladas.
                            if sin(x * 0.9 + y * 0.25 + fbm(x * 0.08, y * 0.08, 31) * 9) > 0.86 { col = TownArt.dark(col, 0.75) }
                        case .glacier:
                            // Grietas del glaciar.
                            if abs(fbm(x * 0.07, y * 0.07, 33) - 0.5) < 0.012 { col = 0x7E98AC }
                        default:
                            break
                        }
                    }
                    if !continents[i].isPlayable { gray[py * c.width + px] = true }
                    c.pixels[py * c.width + px] = col
                    continue
                }
                c.pixels[py * c.width + px] = color
            }
        }

        // 4. Relieve del terreno (de atrás hacia delante): montañas, árboles de plata, cumbres heladas.
        // Capa (0 relieve, 1 nubes, 2 sitios), pie del sprite, sprite, x, si se pasa a gris.
        var sprites: [(layer: Int, y: Int, grid: PixelGrid, x: Int, gray: Bool)] = []
        let silver = silverTree(), snowPine = treeSprite(pine: true)
        for ty in stride(from: 0, to: H, by: 1) {
            for tx in stride(from: 0, to: W, by: 1) {
                let ti = ty * W + tx, i = owner[ti]
                guard i >= 0, coarse[ti] < -1.5 else { continue }
                let pc = continents[i]
                // Los jugables van tapados por su mapa; dentro de las áreas del boceto, algo menos de relieve.
                guard !pc.isPlayable else { continue }
                let inside = rects[i].contains { $0.containsStrictly(MapPoint(Double(tx) + 0.5, Double(ty) + 0.5), inset: 1) }
                if inside, TownArt.chance(tx, ty, 50, 0.45) { continue }
                let h = TownArt.hash(tx, ty, 51)
                switch pc.entry.terrain {
                case .mountains:
                    guard tx % 4 == (ty % 3), TownArt.chance(tx, ty, 52, 0.8) else { continue }
                    let m = mountainSprite(width: 10 + h % 9, seed: h)
                    sprites.append((0, ty * S + S, m, tx * S - m.width / 2, true))
                case .silverForest:
                    guard (tx + ty * 2) % 3 == 0 || TownArt.chance(tx, ty, 56, 0.2) else { continue }
                    sprites.append((0, ty * S + S, silver, tx * S - silver.width / 2 + h % 3, true))
                case .glacier:
                    // Hielo abierto con alguna cumbre suelta y pinos nevados en la costa.
                    if tx % 11 == (ty % 7), TownArt.chance(tx, ty, 53, 0.35) {
                        let m = mountainSprite(width: 9 + h % 6, seed: h)
                        sprites.append((0, ty * S + S, m, tx * S - m.width / 2, true))
                    } else if coarse[ti] > -5, (tx * 3 + ty) % 5 == 0, TownArt.chance(tx, ty, 54, 0.5) {
                        sprites.append((0, ty * S + S, snowPine, tx * S - snowPine.width / 2, true))
                    }
                case .ashDesert:
                    if tx % 9 == (ty % 4), TownArt.chance(tx, ty, 55, 0.3) {
                        let m = mountainSprite(width: 8 + h % 5, seed: h)
                        sprites.append((0, ty * S + S, m, tx * S - m.width / 2, true))
                    }
                default:
                    break
                }
            }
        }
        // Islas del cielo: su quilla de roca colgando y nubes debajo.
        for (i, pc) in continents.enumerated() where islands[i] {
            for r in rects[i] {
                // Sombra en el mar, abajo a la derecha.
                let sx = (r.x + 10) * S, sy = (r.y + r.height / 2 + 14) * S
                let rx = r.width * S / 2, ry = r.height * S / 3
                for y in (sy - ry)...(sy + ry) {
                    for x in (sx - rx)...(sx + rx) where c.inside(x, y) {
                        let u = Double(x - sx) / Double(rx), v = Double(y - sy) / Double(ry)
                        if u * u + v * v <= 1, owner[min(H - 1, y / S) * W + min(W - 1, x / S)] == i || coarse[min(H - 1, y / S) * W + min(W - 1, x / S)] > 0 {
                            if !(rects[i].contains { $0.distance(to: MapPoint(Double(x) * inv, Double(y) * inv)) < 4 }) {
                                c[x, y] = TownArt.dark(c[x, y], 0.8)
                            }
                        }
                    }
                }
                let keel = islandKeel(width: (r.width + 4) * S, seed: r.x * 31 + r.y)
                sprites.append((0, (r.maxY + 2) * S - 1 + keel.height, keel, (r.x - 2) * S, !pc.isPlayable))
                for k in 0..<5 {
                    let cloud = cloudSprite(seed: r.x + k * 7)
                    let cx = (r.x - 6 + (r.width + 8) * k / 4) * S, cy = (r.maxY + 3 + (k % 2) * 3) * S + keel.height / 2
                    sprites.append((1, cy + cloud.height, cloud, cx - cloud.width / 2, false))
                }
            }
        }
        // Sitios del boceto: capital, minas, volcán, cráter, ciudadela.
        for pc in continents where !pc.isPlayable {
            for planned in pc.entry.plannedAreas {
                guard let r = pc.frame(of: planned.id) else { continue }
                let cx = Int(r.center.x) * S, cy = Int(r.center.y) * S
                var glyph: PixelGrid?
                if planned.isCapital { glyph = capitalGlyph() }
                switch planned.landmark {
                case .volcano?: glyph = volcanoSprite()
                case .mine?: glyph = mineGlyph()
                case .crater?: glyph = craterGlyph()
                case .citadel?: glyph = citadelGlyph()
                case nil: break
                }
                if let glyph { sprites.append((2, cy + glyph.height / 2, glyph, cx - glyph.width / 2, true)) }
            }
        }
        for s in sprites.sorted(by: { ($0.layer, $0.y, $0.x) < ($1.layer, $1.y, $1.x) }) {
            let top = s.y - s.grid.height
            for y in 0..<s.grid.height {
                for x in 0..<s.grid.width {
                    guard let col = s.grid[x, y] else { continue }
                    let px = s.x + x, py = top + y
                    guard c.inside(px, py) else { continue }
                    c[px, py] = col
                    if s.gray { gray[py * c.width + px] = true }
                }
            }
        }

        // 4b. Áreas del boceto (encima del relieve): manchas claras con borde punteado (se ve dónde irá cada zona).
        for (i, pc) in continents.enumerated() where !pc.isPlayable {
            for r in rects[i] {
                let x0 = r.x * S, y0 = r.y * S, x1 = r.maxX * S, y1 = r.maxY * S
                for y in y0..<y1 {
                    for x in x0..<x1 where c.inside(x, y) {
                        let edge = x == x0 || x == x1 - 1 || y == y0 || y == y1 - 1
                        // Solo el borde punteado: dentro se ve el terreno del continente.
                        guard edge, !islands[i] else { continue }
                        c[x, y] = (x + y) / 3 % 2 == 0 ? 0x2A2622 : 0xE8E2D4
                        gray[y * c.width + x] = true
                    }
                }
            }
        }

        // 5. Lo que aún no se puede jugar, en gris (algo frío).
        for idx in 0..<(c.width * c.height) where gray[idx] {
            let col = c.pixels[idx]
            let r = Double((col >> 16) & 0xFF), g = Double((col >> 8) & 0xFF), b = Double(col & 0xFF)
            let l = 0.30 * r + 0.59 * g + 0.11 * b
            let v = min(255, l * 0.92 + 18)
            c.pixels[idx] = (UInt32(v * 0.96) << 16) | (UInt32(v * 0.98) << 8) | UInt32(min(255, v * 1.03))
        }

        // 6. Rutas punteadas entre continentes, con su barco o dirigible a mitad.
        for route in world.routes {
            let color: UInt32 = route.route.kind == .ship || route.route.kind == .airship ? 0xF0E6CC : 0x6A4A2C
            var travelled = 0.0
            for (a, b) in zip(route.points, route.points.dropFirst()) {
                let len = hypot(b.x - a.x, b.y - a.y)
                let steps = max(1, Int(len * Double(S)))
                for k in 0...steps {
                    let t = Double(k) / Double(steps)
                    let d = travelled + len * t
                    guard Int(d * 1.2) % 3 == 0 else { continue }
                    let x = Int((a.x + (b.x - a.x) * t) * Double(S)), y = Int((a.y + (b.y - a.y) * t) * Double(S))
                    for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)] { c[x + dx, y + dy] = color }
                }
                travelled += len
            }
            if route.route.kind == .ship || route.route.kind == .airship, route.points.count >= 2 {
                let mid = route.points[route.points.count / 2 - (route.points.count % 2 == 0 ? 1 : 0)]
                let next = route.points[min(route.points.count - 1, route.points.count / 2)]
                let m = MapPoint((mid.x + next.x) / 2, (mid.y + next.y) / 2)
                let glyph = route.route.kind == .ship ? shipGlyph() : airshipGlyph()
                c.draw(glyph, x: Int(m.x * Double(S)) - glyph.width, y: Int(m.y * Double(S)) - glyph.height, scale: 2)
            }
        }

        // 7. La Luna agrietada arriba, rosa de los vientos y marco.
        if let sky = continents.first(where: { $0.entry.terrain == .skyIslands }) {
            let moon = moonSprite()
            let mx = (sky.landBounds.center.x - 30) * Double(S), my = Double(max(14, sky.landBounds.y - 30)) * Double(S)
            c.draw(moon, x: Int(mx) - moon.width, y: Int(my) - moon.height, scale: 2)
        }
        let rose = compassRose()
        c.draw(rose, x: 16 * S, y: c.height - rose.height * 3 - 16 * S, scale: 3)
        worldFrame(&c, thickness: 6 * S)
        return c
    }

    private static func worldFrame(_ c: inout MapCanvas, thickness t: Int) {
        for y in 0..<c.height {
            let band = y < t || y >= c.height - t
            for x in band ? Array(0..<c.width) : Array(0..<t) + Array((c.width - t)..<c.width) {
                let e = min(x, y, c.width - 1 - x, c.height - 1 - y)
                guard e < t else { continue }
                if e == 0 || e == t - 1 || e == t - 3 { c[x, y] = Ink.ink; continue }
                c[x, y] = TownArt.tone(Ink.parchment, TownArt.noise(Double(x) * 0.15, Double(y) * 0.15, 4), x, y, dither: 0.4)
            }
        }
    }

    // MARK: Sprites del mundo (pequeños: 2 px por casilla)

    static func silverTree() -> PixelGrid {
        let rows = [
            "...l...",
            "..lsl..",
            "..lsd..",
            ".lsssd.",
            ".lssdd.",
            "lsssssd",
            "lssssdd",
            "...t...",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["l": 0xD8E4EC, "s": 0xA8BCCC, "d": 0x6E8494, "t": 0x4A3A30])).outlined(0x1E2A34)
    }

    static func islandKeel(width w: Int, seed: Int) -> PixelGrid {
        let h = max(6, w * 2 / 5)
        var g = PixelGrid(width: w, height: h)
        for y in 0..<h {
            let t = Double(y) / Double(h)
            let half = Double(w) / 2 * (1 - t) * (0.9 + 0.1 * TownArt.noise(Double(y) * 0.3, 0, seed))
            let cx = Double(w) / 2 + (TownArt.noise(Double(y) * 0.1, 3, seed) - 0.5) * 4
            for x in 0..<w where abs(Double(x) - cx) <= half {
                let shade = Double(x) > cx ? 0.75 : 1
                g[x, y] = TownArt.dark(TownArt.tone([0x4A4038, 0x5C5046, 0x6E6054], 1 - t, x, y), shade)
            }
        }
        return g.outlined(0x221C18)
    }

    static func cloudSprite(seed: Int) -> PixelGrid {
        var g = PixelGrid(width: 26, height: 12)
        for (cx, cy, r) in [(7, 7, 5), (13, 5, 6), (19, 7, 5), (11, 8, 4), (16, 8, 4)] {
            let rr = r - (seed % 2)
            for y in -rr...rr {
                for x in -rr...rr where x * x + y * y <= rr * rr {
                    g[cx + x, cy + y] = y > rr / 2 ? 0xC8D0DC : 0xF2F4F8
                }
            }
        }
        return g
    }

    static func volcanoSprite() -> PixelGrid {
        let w = 40, h = 26
        var g = PixelGrid(width: w, height: h)
        for y in 6..<h {
            let t = Double(y - 6) / Double(h - 7)
            let half = 4 + t * Double(w / 2 - 4)
            for x in 0..<w where abs(Double(x) - Double(w) / 2) <= half {
                let east = Double(x) > Double(w) / 2
                var col: UInt32 = east ? 0x3A302C : 0x5A4A42
                // Ríos de lava.
                if abs(Double(x) - Double(w) / 2 - sin(Double(y) * 0.5) * 2) < 0.8, y < h - 4 { col = 0xE0461E }
                g[x, y] = col
            }
        }
        for x in (w / 2 - 4)...(w / 2 + 4) { g[x, 6] = 0xFF9A2E; g[x, 7] = 0xE0461E }
        // Humo.
        for (cx, cy, r) in [(20, 3, 3), (24, 1, 2), (16, 2, 2)] {
            for y in -r...r { for x in -r...r where x * x + y * y <= r * r { g[cx + x, cy + y] = 0x8A8480 } }
        }
        return g.outlined(0x1A1412)
    }

    static func capitalGlyph() -> PixelGrid {
        let rows = [
            "t.t.t.t",
            "ttttttt",
            "twwtwwt",
            "ttttttt",
            "ttwdwtt",
            "tttdttt",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["t": 0xC8C0B0, "w": 0x5A5048, "d": 0x2A2420])).outlined()
    }

    static func citadelGlyph() -> PixelGrid {
        let rows = [
            "t...t...t",
            "tt..t..tt",
            "tt.ttt.tt",
            "ttttttttt",
            "ttwttttwt",
            "ttttdtttt",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["t": 0xA8A098, "w": 0x403830, "d": 0x1E1A16])).outlined()
    }

    static func mineGlyph() -> PixelGrid {
        let rows = [
            ".bbbb.",
            "bkkkkb",
            "bk..kb",
            "bkkkkb",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["b": 0x8E6A40, "k": 0x141010])).outlined()
    }

    static func craterGlyph() -> PixelGrid {
        var g = PixelGrid(width: 22, height: 12)
        for y in 0..<12 {
            for x in 0..<22 {
                let u = (Double(x) - 10.5) / 10.5, v = (Double(y) - 5.5) / 5.5, d = u * u + v * v
                if d <= 1 { g[x, y] = d > 0.6 ? 0xD8E6EE : (d > 0.35 ? 0x8098AC : 0x405060) }
            }
        }
        return g.outlined(0x2A3440)
    }

    static func shipGlyph() -> PixelGrid {
        let rows = [
            "...w...",
            "..ww...",
            ".www...",
            "...m...",
            "bbbbbbb",
            ".bbbbb.",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["w": 0xF4F0E8, "m": 0x5A3A22, "b": 0x8E5E34])).outlined()
    }

    static func airshipGlyph() -> PixelGrid {
        let rows = [
            ".rrrrr.",
            "rrRRrrr",
            ".rrrrr.",
            "..l.l..",
            "..bbb..",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["r": 0xC0504D, "R": 0xE8A090, "l": 0x3A2A1E, "b": 0x8E5E34])).outlined()
    }

    static func moonSprite() -> PixelGrid {
        let r = 14
        var g = PixelGrid(width: 2 * r + 1, height: 2 * r + 1)
        for y in -r...r {
            for x in -r...r where x * x + y * y <= r * r {
                let lit = Double(x + y) / Double(2 * r)
                var col: UInt32 = lit < -0.2 ? 0xF0F2F6 : (lit < 0.3 ? 0xD4D8E0 : 0xA8AEBA)
                // Grieta.
                if abs(x - (y / 2) + 2) == 0 && y > -r + 3 && y < r - 2 { col = 0x3A3E48 }
                if (x == 5 && abs(y + 4) < 3) || (x == -6 && abs(y - 5) < 2) { col = 0x9096A2 }
                g[x + r, y + r] = col
            }
        }
        return g.outlined(0x2A2E38)
    }
}
