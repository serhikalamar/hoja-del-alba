import CoreGraphics
import GameCore

/// Fondos procedurales del pueblo de Valdehierro. 1 pixel = 1 pixel de arte.
enum VillageArt {
    /// Alto (en pixeles de arte) de la franja superior con casas / muros.
    static let bandHeight = 30

    static func background(width w: Int, height h: Int, level: LevelDefinition) -> CGImage {
        var rng = SeededGenerator(seed: UInt64(level.id * 7919))
        var grid = PixelGrid(width: w, height: h)
        var lights: [(Int, Int, Int, Int)] = []   // ventanas encendidas (x, y, ancho, alto)

        switch level.ground {
        case "farm": drawFarm(&grid, &rng)
        case "graveyard": drawGraveyard(&grid, &rng)
        case "castle": drawCastleFloor(&grid, &rng, carpet: level.id == 10)
        default: drawCobble(&grid, &rng)
        }

        drawSky(&grid, time: level.time)
        switch level.ground {
        case "graveyard": drawChapel(&grid, &rng, lights: &lights)
        case "castle": drawCastleWall(&grid, &rng)
        default: drawHouses(&grid, &rng, lights: &lights, night: level.time != .day)
        }

        tint(&grid, time: level.time)
        for (x, y, lw, lh) in lights {
            fill(&grid, x, y, lw, lh, 0xFFD870)
            grid[x, y] = 0xFFF4C0
        }
        return grid.makeCGImage()
    }

    // MARK: - Suelos

    private static func drawCobble(_ g: inout PixelGrid, _ rng: inout SeededGenerator) {
        let mortar: UInt32 = 0x4A4440
        fill(&g, 0, 0, g.width, g.height, mortar)
        let stones: [UInt32] = [0x8A847A, 0x7E786E, 0x96907E, 0x857E74, 0x8E8676]
        let rowH = 7
        var y = 0
        var row = 0
        while y < g.height {
            var x = -(row % 2) * 5
            while x < g.width {
                let sw = Int.random(in: 8...12, using: &rng)
                var color = stones[Int.random(in: 0..<stones.count, using: &rng)]
                if Int.random(in: 0..<25, using: &rng) == 0 { color = 0x6A7A5A }   // musgo
                stone(&g, x + 1, y + 1, sw - 1, rowH - 1, color, mortar: mortar)
                x += sw
            }
            y += rowH
            row += 1
        }
        // Charcos
        for _ in 0..<(g.width * g.height / 4000) {
            let px = Int.random(in: 0..<g.width, using: &rng), py = Int.random(in: bandHeight..<max(bandHeight + 1, g.height), using: &rng)
            ellipse(&g, px, py, 6, 2, 0x5A7088)
            g[px - 2, py - 1] = 0x8AA0B8
        }
    }

    private static func drawFarm(_ g: inout PixelGrid, _ rng: inout SeededGenerator) {
        let dirt: [UInt32] = [0x8A6A44, 0x82623E, 0x92724A]
        for y in 0..<g.height {
            for x in 0..<g.width {
                g[x, y] = dirt[(x / 3 + y / 2 + Int.random(in: 0...1, using: &rng)) % dirt.count]
            }
        }
        // Surcos con brotes
        var y = bandHeight + 6
        while y < g.height {
            for x in 0..<g.width {
                g[x, y] = 0x5E4428
                g[x, y + 1] = 0xA0805A
            }
            var x = Int.random(in: 0...4, using: &rng)
            while x < g.width {
                g[x, y - 1] = 0x5DAA48
                g[x + 1, y - 2] = 0x8CD070
                g[x - 1, y - 2] = 0x5DAA48
                x += Int.random(in: 6...10, using: &rng)
            }
            y += 9
        }
        // Hierba en los bordes
        for _ in 0..<(g.width * g.height / 60) {
            let x = Int.random(in: 0..<g.width, using: &rng), yy = Int.random(in: 0..<g.height, using: &rng)
            if x < 18 || x > g.width - 18 { g[x, yy] = 0x4F9442; g[x, yy - 1] = 0x63AB52 }
        }
    }

    private static func drawGraveyard(_ g: inout PixelGrid, _ rng: inout SeededGenerator) {
        let grass: [UInt32] = [0x3F6A3A, 0x46743E, 0x3A6234, 0x4A7A44]
        let cell = 5
        for y in 0..<g.height {
            for x in 0..<g.width {
                let jitter = (x * 7 + y * 13) % 3
                var r = SeededGenerator(seed: UInt64(((x + jitter) / cell) * 9973 + ((y + jitter) / cell)))
                g[x, y] = grass[Int(r.next() % UInt64(grass.count))]
            }
        }
        // Camino de tierra que cruza
        let mid = (g.height + bandHeight) / 2
        for x in 0..<g.width {
            let wobble = Int((sin(Double(x) / 9) * 2).rounded())
            for y in (mid - 5 + wobble)...(mid + 5 + wobble) {
                g[x, y] = (x + y) % 7 == 0 ? 0x6A5640 : 0x7A6448
            }
        }
        for _ in 0..<(g.width * g.height / 45) {
            let x = Int.random(in: 0..<g.width, using: &rng), y = Int.random(in: 0..<g.height, using: &rng)
            if g[x, y] != 0x7A6448 { g[x, y] = 0x2E5228; g[x, y - 1] = 0x2E5228 }
        }
    }

    private static func drawCastleFloor(_ g: inout PixelGrid, _ rng: inout SeededGenerator, carpet: Bool) {
        fill(&g, 0, 0, g.width, g.height, 0x3A3A44)
        let tiles: [UInt32] = [0x6A6A78, 0x646472, 0x70707E, 0x5E5E6C]
        var y = 0
        var row = 0
        while y < g.height {
            var x = -(row % 2) * 6
            while x < g.width {
                stone(&g, x + 1, y + 1, 11, 6, tiles[Int.random(in: 0..<tiles.count, using: &rng)], mortar: 0x3A3A44)
                x += 12
            }
            y += 7
            row += 1
        }
        if carpet {
            let cx = g.width / 2
            fill(&g, cx - 14, bandHeight, 28, g.height - bandHeight, 0x8A1A2A)
            fill(&g, cx - 14, bandHeight, 2, g.height - bandHeight, 0xC8A030)
            fill(&g, cx + 12, bandHeight, 2, g.height - bandHeight, 0xC8A030)
            var yy = bandHeight + 4
            while yy < g.height {
                g[cx, yy] = 0xC8A030; g[cx - 1, yy + 1] = 0xC8A030; g[cx + 1, yy + 1] = 0xC8A030; g[cx, yy + 2] = 0xC8A030
                yy += 10
            }
        }
    }

    // MARK: - Franja superior

    private static func drawSky(_ g: inout PixelGrid, time: TimeOfDay) {
        let sky: UInt32 = switch time {
        case .day: 0x8FC8F0
        case .sunset: 0xF0A070
        case .night: 0x24305A
        }
        fill(&g, 0, 0, g.width, bandHeight, sky)
    }

    private static func drawHouses(_ g: inout PixelGrid, _ rng: inout SeededGenerator, lights: inout [(Int, Int, Int, Int)], night: Bool) {
        let base = bandHeight - 1
        let roofs: [UInt32] = [0xA04030, 0x8A5A3A, 0x5A6A8A, 0x9A6A2A]
        let plasters: [UInt32] = [0xE8D8B0, 0xE0C8A0, 0xD8D0C0]
        var x = Int.random(in: -8...0, using: &rng)
        while x < g.width {
            let w = Int.random(in: 20...30, using: &rng)
            let wallH = Int.random(in: 11...14, using: &rng)
            let roofH = Int.random(in: 8...11, using: &rng)
            house(&g, x0: x, base: base, w: w, wallH: wallH, roofH: roofH,
                  roof: roofs[Int.random(in: 0..<roofs.count, using: &rng)],
                  plaster: plasters[Int.random(in: 0..<plasters.count, using: &rng)],
                  rng: &rng, lights: &lights, night: night)
            x += w + Int.random(in: 1...4, using: &rng)
        }
        fill(&g, 0, base, g.width, 1, 0x3A3430)
    }

    private static func house(_ g: inout PixelGrid, x0: Int, base: Int, w: Int, wallH: Int, roofH: Int,
                              roof: UInt32, plaster: UInt32, rng: inout SeededGenerator,
                              lights: inout [(Int, Int, Int, Int)], night: Bool) {
        let beam: UInt32 = 0x5A3A22
        let top = base - wallH
        fill(&g, x0, top, w, wallH, plaster)
        fill(&g, x0 + w - 2, top, 2, wallH, darken(plaster, 0.85))
        // Entramado de madera
        for bx in [x0, x0 + w / 2, x0 + w - 1] { fill(&g, bx, top, 1, wallH, beam) }
        for by in [top, top + wallH / 2] { fill(&g, x0, by, w, 1, beam) }
        for i in 0..<(wallH / 2) {
            g[x0 + 1 + i, top + wallH / 2 - i] = beam
            g[x0 + w - 2 - i, top + wallH / 2 - i] = beam
        }
        // Ventanas
        for wx in [x0 + w / 4 - 1, x0 + 3 * w / 4 - 2] {
            let wy = top + 2
            fill(&g, wx - 1, wy - 1, 5, 5, beam)
            let lit = night && Int.random(in: 0..<10, using: &rng) < 7
            if lit {
                lights.append((wx, wy, 3, 3))
            } else {
                fill(&g, wx, wy, 3, 3, 0x3A5A7A)
                g[wx, wy] = 0x8AB0D0
            }
        }
        // Puerta
        let dx = x0 + w / 2 - 2
        fill(&g, dx, base - 6, 4, 6, 0x6A4422)
        fill(&g, dx, base - 6, 4, 1, beam)
        g[dx + 3, base - 3] = 0xFFCD75
        // Tejado escalonado
        for r in 0..<roofH {
            let inset = (r * (w / 2 + 2)) / roofH
            let y = top - 1 - r
            let color = r % 2 == 0 ? roof : darken(roof, 0.82)
            fill(&g, x0 - 2 + inset, y, w + 4 - inset * 2, 1, color)
            var tx = x0 - 2 + inset + (r % 2) * 2
            while tx < x0 + w + 2 - inset {
                g[tx, y] = darken(roof, 0.7)
                tx += 4
            }
        }
        // Chimenea
        if Int.random(in: 0..<2, using: &rng) == 0 {
            let cx = x0 + w - 7
            fill(&g, cx, top - roofH + 1, 3, roofH / 2 + 1, 0x7A5A4A)
            fill(&g, cx - 1, top - roofH, 5, 1, 0x5A4034)
        }
    }

    private static func drawChapel(_ g: inout PixelGrid, _ rng: inout SeededGenerator, lights: inout [(Int, Int, Int, Int)]) {
        let base = bandHeight - 1
        let stoneColor: UInt32 = 0x8A8A96
        // Muro de piedra con capilla en el centro
        fill(&g, 0, base - 8, g.width, 8, 0x6A6A78)
        var x = 0
        while x < g.width {
            fill(&g, x, base - 8, 1, 8, 0x4A4A56)
            x += 6
        }
        let cx = g.width / 2
        fill(&g, cx - 18, base - 18, 36, 18, stoneColor)
        for r in 0..<9 {
            fill(&g, cx - 20 + r * 2, base - 19 - r, 40 - r * 4, 1, r % 2 == 0 ? 0x4A3A4A : 0x3A2E3A)
        }
        // Campanario
        fill(&g, cx - 4, 0, 8, base - 18, 0x9A9AA6)
        fill(&g, cx - 2, 4, 4, 5, 0x2A2A36)
        g[cx, 2] = 0xFFCD75; g[cx, 1] = 0xFFCD75; g[cx - 1, 2] = 0xFFCD75; g[cx + 1, 2] = 0xFFCD75
        // Vidriera
        lights.append((cx - 3, base - 14, 6, 7))
        fill(&g, cx - 3, base - 6, 6, 6, 0x4A2A1A)
        // Verja de hierro
        var fx = 0
        while fx < g.width {
            if abs(fx - cx) > 20 {
                fill(&g, fx, base - 4, 1, 4, 0x2A2A36)
                g[fx, base - 5] = 0x4A4A56
            }
            fx += 3
        }
        _ = rng.next()
    }

    private static func drawCastleWall(_ g: inout PixelGrid, _ rng: inout SeededGenerator) {
        let base = bandHeight - 1
        fill(&g, 0, 6, g.width, base - 6, 0x6A6A78)
        var y = 6
        var row = 0
        while y < base {
            fill(&g, 0, y, g.width, 1, 0x4A4A56)
            var x = (row % 2) * 4
            while x < g.width {
                fill(&g, x, y, 1, 4, 0x4A4A56)
                x += 8
            }
            y += 4
            row += 1
        }
        // Almenas
        var x = 0
        while x < g.width {
            fill(&g, x, 2, 5, 4, 0x7A7A86)
            x += 9
        }
        // Estandartes
        x = Int.random(in: 10...30, using: &rng)
        while x < g.width - 10 {
            fill(&g, x, 8, 8, 14, 0x2A7A3A)
            fill(&g, x, 8, 8, 1, 0xC8A030)
            fill(&g, x + 3, 12, 2, 5, 0xFFCD75)
            g[x + 2, 13] = 0xFFCD75; g[x + 5, 13] = 0xFFCD75
            g[x, 22] = 0x2A7A3A; g[x + 7, 22] = 0x2A7A3A
            x += Int.random(in: 40...70, using: &rng)
        }
        fill(&g, 0, base, g.width, 1, 0x2A2A36)
    }

    // MARK: - Utilidades

    private static func fill(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: UInt32) {
        guard w > 0, h > 0 else { return }
        for yy in y..<(y + h) {
            for xx in x..<(x + w) { g[xx, yy] = color }
        }
    }

    /// Piedra con luz arriba-izquierda y sombra abajo-derecha.
    private static func stone(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: UInt32, mortar: UInt32) {
        fill(&g, x, y, w, h, color)
        fill(&g, x + 1, y, w - 2, 1, lighten(color, 1.15))
        fill(&g, x + 1, y + h - 1, w - 2, 1, darken(color, 0.78))
        fill(&g, x + w - 1, y + 1, 1, h - 2, darken(color, 0.85))
        // Esquinas redondeadas
        for (cx, cy) in [(x, y), (x + w - 1, y), (x, y + h - 1), (x + w - 1, y + h - 1)] {
            g[cx, cy] = mortar
        }
    }

    private static func ellipse(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ color: UInt32) {
        for y in -ry...ry {
            for x in -rx...rx where Double(x * x) / Double(rx * rx) + Double(y * y) / Double(ry * ry) <= 1 {
                g[cx + x, cy + y] = color
            }
        }
    }

    private static func tint(_ g: inout PixelGrid, time: TimeOfDay) {
        let factors: (Double, Double, Double) = switch time {
        case .day: (1, 1, 1)
        case .sunset: (1.0, 0.84, 0.72)
        case .night: (0.5, 0.55, 0.85)
        }
        guard time != .day else { return }
        for i in 0..<g.pixels.count {
            guard let c = g.pixels[i] else { continue }
            g.pixels[i] = scale(c, factors)
        }
    }

    static func darken(_ c: UInt32, _ f: Double) -> UInt32 { scale(c, (f, f, f)) }
    static func lighten(_ c: UInt32, _ f: Double) -> UInt32 { scale(c, (f, f, f)) }

    static func scale(_ c: UInt32, _ f: (Double, Double, Double)) -> UInt32 {
        let r = min(255, Double((c >> 16) & 0xFF) * f.0)
        let g = min(255, Double((c >> 8) & 0xFF) * f.1)
        let b = min(255, Double(c & 0xFF) * f.2)
        return (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
    }
}
