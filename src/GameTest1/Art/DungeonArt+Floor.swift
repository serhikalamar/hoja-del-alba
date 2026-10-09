import GameCore

// Suelos de la mazmorra: losas, ladrillo, tierra o basalto según el tema, con variación por casilla
// (grietas, manchas de humedad, musgo, charcos, hollín), y lo que va encima: escombros, huesos,
// alfombras, rejillas y las sombras de paredes y obstáculos.

/// División entera hacia abajo (también con negativos).
@inline(__always) func fdiv(_ a: Int, _ b: Int) -> Int { a >= 0 ? a / b : -((-a + b - 1) / b) }

/// Piedra de un aparejo por hileras (losas o ladrillos): qué piedra toca a un pixel y su distancia a cada borde.
struct Course {
    var id: Int, row: Int, left: Int, right: Int, top: Int, bottom: Int

    static func at(_ px: Int, _ py: Int, rowH: Int, cellW: Int, jitter: Int, salt: Int, halfBond: Bool = false) -> Course {
        let r = fdiv(py, rowH)
        let top = py - r * rowH
        let off = halfBond ? (r & 1) * (cellW / 2) : Int(Noise.hash(r, 7, salt) * Double(cellW))
        let X = px + off
        @inline(__always) func edge(_ k: Int) -> Int {
            jitter == 0 ? k * cellW : k * cellW + Int(Noise.hash(k, r, salt + 1) * Double(2 * jitter + 1)) - jitter
        }
        var k = fdiv(X, cellW)
        if X < edge(k) { k -= 1 } else if X >= edge(k + 1) { k += 1 }
        let s = edge(k), e = edge(k + 1)
        return Course(id: k &* 7919 &+ r &* 104_729 &+ salt, row: r, left: X - s, right: e - 1 - X, top: top, bottom: rowH - 1 - top)
    }
}

extension DungeonPainter {
    // MARK: - Suelo base

    mutating func paintFloor(_ x: Int, _ y: Int) {
        let x0 = x * T, y0 = y * T
        for py in y0..<(y0 + T) {
            for px in x0..<(x0 + T) { c.put(px, py, floorColor(px, py)) }
        }
        var d = Dice(x, y, 11)
        floorDetails(x, y, &d)
    }

    /// Color del suelo en un pixel (los patrones son continuos entre casillas).
    func floorColor(_ px: Int, _ py: Int) -> UInt32 {
        let f = s.floor
        let speck = Noise.hash(px, py, 5)
        var col: UInt32
        switch s.theme {
        case .prison:
            // Losas grandes e irregulares (casi rectangulares), con canto claro arriba-izquierda.
            let cell = Noise.voronoi(px, py, 14, 3, squash: 1.3, square: true)
            if cell.edge < 0.9 { return DColor.mix(f[0], f[1], 0.35) }
            col = DColor.mix(f[1], f[3], 0.3 + 0.45 * Noise.hash(cell.id, 1))
            if cell.edge < 2.0 {
                let dx = Double(px) + 0.5 - cell.cx, dy = Double(py) + 0.5 - cell.cy
                col = dx + dy < 0 ? DColor.mix(col, f[4], 0.4) : DColor.mix(col, f[0], 0.35)
            }
        case .crypt:
            // Losas cuadradas pulidas, a dos tonos (ajedrezado suave).
            let gx = fdiv(px, 12), gy = fdiv(py, 12)
            let lx = px - gx * 12, ly = py - gy * 12
            if lx == 0 || ly == 0 { return f[0] }
            let id = gx &* 31 &+ gy &* 977
            let even = (gx + gy) & 1 == 0
            col = DColor.mix(even ? f[2] : f[1], f[3], (even ? 0.15 : 0.05) + 0.2 * Noise.hash(id, 3))
            if ly == 1 || lx == 1 { col = DColor.mix(col, f[4], 0.5) }
            else if ly == 11 || lx == 11 { col = DColor.mix(col, f[0], 0.4) }
            // Losas con un grabado (rombo) en el centro.
            if Noise.hash(id, 4) < 0.09 {
                let ax = abs(lx - 6), ay = abs(ly - 6)
                if ax + ay == 3 { col = DColor.mix(col, f[0], 0.55) }
                if ax + ay == 4 && lx < 6 && ly < 6 { col = DColor.mix(col, f[4], 0.3) }
            }
        case .sewer:
            // Adoquín grande y gastado, con verdín en las juntas.
            let st = Course.at(px, py + 2, rowH: 8, cellW: 13, jitter: 2, salt: 5)
            if st.left == 0 || st.top == 0 {
                let m = Noise.smooth(px, py, 14, 9)
                return m > 0.55 ? s.moss[m > 0.68 ? 2 : 1] : f[0]
            }
            col = DColor.mix(f[1], f[3], 0.15 + 0.6 * Noise.hash(st.id, 1))
            if st.top == 1 || st.left == 1 { col = DColor.mix(col, f[4], 0.4) }
            else if st.bottom == 0 || st.right == 0 { col = DColor.mix(col, f[0], 0.35) }
        case .mine:
            // Tierra apisonada con guijarros y lajas de roca.
            let n = Noise.smooth(px, py, 10, 1) * 0.65 + Noise.smooth(px, py, 4, 2) * 0.35
            col = n < 0.36 ? f[1] : n < 0.6 ? f[2] : f[3]
            let cell = Noise.voronoi(px, py, 8, 21)
            if Noise.hash(cell.id, 5) < 0.2 && cell.d1 < 2.2 {
                let dx = Double(px) + 0.5 - cell.cx, dy = Double(py) + 0.5 - cell.cy
                col = dx + dy < -0.8 ? f[4] : dx + dy > 1.2 ? f[0] : f[3]
            } else if Noise.hash(cell.id, 6) < 0.14 && cell.edge > 1.2 && cell.d1 < 5 {
                // Laja plana enterrada.
                col = DColor.mix(f[2], f[3], 0.5)
            }
        case .forge:
            // Adoquines de basalto.
            let cell = Noise.voronoi(px, py, 10, 31, squash: 1.25)
            if cell.edge < 1.1 { return f[0] }
            col = DColor.mix(f[1], f[3], 0.15 + 0.6 * Noise.hash(cell.id, 1))
            let dx = Double(px) + 0.5 - cell.cx, dy = Double(py) + 0.5 - cell.cy
            if cell.edge < 2.2 { col = dx + dy < 0 ? DColor.mix(col, f[4], 0.4) : DColor.mix(col, f[0], 0.4) }
        }
        if speck < 0.05 { col = DColor.mul(col, 0.86) } else if speck > 0.975 { col = DColor.mix(col, f[4], 0.5) }
        // Manchas grandes y suaves para que no se vea ningún patrón.
        let stain = Noise.smooth(px, py, 22, 13)
        if stain > 0.62 { col = DColor.mix(col, f[0], min(0.3, (stain - 0.62) * 1.2)) }
        return col
    }

    // MARK: - Detalles por casilla

    private mutating func floorDetails(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let nearWall = isWall(x, y - 1) || isWall(x - 1, y) || isWall(x + 1, y)
        // Grietas.
        if d.chance(0.2) { crack(x0 + d.range(3, 18), y0 + d.range(3, 18), d.range(4, 10), &d) }
        switch s.theme {
        case .prison, .sewer:
            if d.chance(nearWall ? 0.35 : 0.12) { mossPatch(x0 + d.range(2, 20), y0 + d.range(2, 20), d.range(3, 6), &d) }
            if d.chance(0.14) { dampStain(x0 + d.range(4, 20), y0 + d.range(4, 20), d.range(4, 8), &d) }
            if d.chance(s.theme == .sewer ? 0.12 : 0.07) { puddle(x0 + d.range(6, 17), y0 + d.range(8, 18), d.range(3, 6), d.range(2, 3)) }
            if s.theme == .sewer && d.chance(0.1) { slimeTrail(x0 + d.range(2, 20), y0 + d.range(2, 20), &d) }
        case .crypt:
            if d.chance(nearWall ? 0.3 : 0.08) { mossPatch(x0 + d.range(2, 20), y0 + d.range(2, 20), d.range(2, 4), &d) }
            if d.chance(0.12) { dust(x0 + d.range(4, 20), y0 + d.range(4, 20), &d) }
            if d.chance(0.05) { rune(x0 + d.range(5, 15), y0 + d.range(5, 15), &d) }
        case .mine:
            if d.chance(0.08) { shards(x0 + d.range(4, 18), y0 + d.range(6, 18), &d) }
            if d.chance(0.12) { dampStain(x0 + d.range(4, 20), y0 + d.range(4, 20), d.range(3, 6), &d) }
            if d.chance(0.07) { footprints(x0 + d.range(4, 14), y0 + d.range(4, 14), &d) }
        case .forge:
            if d.chance(0.25) { soot(x0 + d.range(3, 21), y0 + d.range(3, 21), d.range(4, 8), &d) }
            if d.chance(0.1) { embers(x0 + d.range(3, 20), y0 + d.range(3, 20), &d) }
            if heat(x, y) > 0 { heatCracks(x, y, &d) }
        }
    }

    /// Grieta zigzagueante con su labio iluminado.
    mutating func crack(_ sx: Int, _ sy: Int, _ len: Int, _ d: inout Dice) {
        var x = sx, y = sy
        let dir = d.chance(0.5) ? 1 : -1
        for i in 0..<len {
            c.put(x, y, s.floor[0])
            if c.at(x + 1, y + 1) != s.floor[0] { c.mix(x + 1, y + 1, s.floor[4], 0.35) }
            if i == len / 2 && d.chance(0.6) {
                // Rama.
                var bx = x, by = y
                for _ in 0..<d.range(2, 4) { bx -= dir; by += 1; c.put(bx, by, s.floor[0]) }
            }
            if d.chance(0.55) { x += dir } else { y += 1 }
            if d.chance(0.25) { y += 1 }
        }
    }

    mutating func mossPatch(_ cx: Int, _ cy: Int, _ r: Int, _ d: inout Dice) {
        let m = s.moss
        let salt = d.int(1000)
        for yy in -r...r {
            for xx in -r - 1...r + 1 {
                let dist = Double(xx * xx) / Double((r + 1) * (r + 1)) + Double(yy * yy) / Double(r * r)
                let n = Noise.hash(cx + xx, cy + yy, salt)
                guard dist < 1, n > dist * 0.8 else { continue }
                let k = yy < 0 && n > 0.75 ? 3 : n > 0.55 ? 2 : 1
                c.put(cx + xx, cy + yy, m[k])
            }
        }
    }

    mutating func dampStain(_ cx: Int, _ cy: Int, _ r: Int, _ d: inout Dice) {
        let salt = d.int(1000)
        for yy in -r...r {
            for xx in -r - 2...r + 2 {
                let dist = Double(xx * xx) / Double((r + 2) * (r + 2)) + Double(yy * yy) / Double(r * r)
                guard dist < 1, Noise.hash(cx + xx, cy + yy, salt) > dist * 0.7 else { continue }
                c.shade(cx + xx, cy + yy, 0.86)
            }
        }
    }

    /// Charco con reflejo.
    mutating func puddle(_ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int) {
        let l = s.liquid
        for yy in -ry...ry {
            for xx in -rx...rx {
                let dist = Double(xx * xx) / Double(rx * rx) + Double(yy * yy) / Double(ry * ry)
                guard dist <= 1 else { continue }
                c.put(cx + xx, cy + yy, dist > 0.6 ? l[2] : l[1])
            }
        }
        c.hline(cx - rx + 2, cy - ry + 1, max(1, rx - 1), l[3])
        c.put(cx - rx + 1, cy - ry + 1, l[4])
        c.hline(cx + 1, cy + ry - 1, max(1, rx / 2), l[3])
    }

    mutating func slimeTrail(_ sx: Int, _ sy: Int, _ d: inout Dice) {
        var x = sx, y = sy
        for _ in 0..<d.range(5, 10) {
            c.put(x, y, s.moss[2]); c.put(x, y + 1, s.moss[1])
            if d.chance(0.3) { c.put(x, y - 1, s.moss[3]) }
            x += d.chance(0.7) ? 1 : 0
            y += d.range(-1, 1)
        }
    }

    mutating func dust(_ cx: Int, _ cy: Int, _ d: inout Dice) {
        for _ in 0..<d.range(6, 12) { c.mix(cx + d.range(-4, 4), cy + d.range(-2, 2), s.floor[4], 0.35) }
    }

    /// Runa grabada en el suelo que brilla un poco.
    mutating func rune(_ x: Int, _ y: Int, _ d: inout Dice) {
        let glyphs: [[String]] = [
            [".###.", "#...#", "#.#.#", "#...#", ".###."],
            ["..#..", ".#.#.", "#.#.#", ".#.#.", "..#.."],
            ["#.#.#", ".....", "#.#.#", ".....", "#.#.#"],
            [".#.#.", "#...#", "..#..", "#...#", ".#.#."],
        ]
        let g = d.pick(glyphs)
        for (j, row) in g.enumerated() {
            for (i, ch) in row.enumerated() where ch == "#" { c.glow(x + i, y + j, DColor.mix(s.floor[2], s.magic[1], 0.45)) }
        }
        extraLights.append(DLight(x: Double(x + 2), y: Double(y + 2), r: 22, k: 0.25))
    }

    /// Esquirlas de cristal en el suelo (mina).
    mutating func shards(_ x: Int, _ y: Int, _ d: inout Dice) {
        let m = s.magic
        for _ in 0..<d.range(2, 4) {
            let sx = x + d.range(-4, 4), sy = y + d.range(-2, 2)
            c.glow(sx, sy, m[2]); c.glow(sx, sy - 1, m[3])
            if d.chance(0.5) { c.glow(sx + 1, sy, m[1]) }
        }
    }

    mutating func footprints(_ x: Int, _ y: Int, _ d: inout Dice) {
        for i in 0..<3 {
            let fx = x + i * 4, fy = y + (i & 1) * 3
            c.shade(fx, fy, 0.8); c.shade(fx + 1, fy, 0.8); c.shade(fx, fy + 1, 0.85)
        }
    }

    mutating func soot(_ cx: Int, _ cy: Int, _ r: Int, _ d: inout Dice) {
        let salt = d.int(1000)
        for yy in -r...r {
            for xx in -r...r {
                let dist = Double(xx * xx + yy * yy) / Double(r * r)
                guard dist < 1, Noise.hash(cx + xx, cy + yy, salt) > dist * 0.9 else { continue }
                c.shade(cx + xx, cy + yy, 0.78)
            }
        }
    }

    mutating func embers(_ x: Int, _ y: Int, _ d: inout Dice) {
        for _ in 0..<d.range(2, 4) {
            c.glow(x + d.range(-3, 3), y + d.range(-2, 2), d.chance(0.5) ? s.magic[1] : s.magic[2])
        }
    }

    /// Casillas de lava a 1 casilla de distancia (para el calor de los bordes).
    func heat(_ x: Int, _ y: Int) -> Int {
        guard s.theme == .forge else { return 0 }
        var n = 0
        for j in -1...1 { for i in -1...1 where t(x + i, y + j) == .liquid { n += 1 } }
        return n
    }

    /// Juntas que brillan junto a la lava.
    private mutating func heatCracks(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        for py in y0..<(y0 + T) {
            for px in x0..<(x0 + T) where c.at(px, py) == s.floor[0] {
                // Más brillo cuanto más cerca de la lava.
                var near = 99
                for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] where t(x + dx, y + dy) == .liquid {
                    let lx = px - x0, ly = py - y0
                    let dist = dx == -1 ? lx : dx == 1 ? T - 1 - lx : dy == -1 ? ly : T - 1 - ly
                    near = min(near, dist)
                }
                if near < 10 && Noise.hash(px, py, 77) > Double(near) / 10 {
                    c.glow(px, py, near < 4 ? s.magic[2] : s.magic[1])
                }
            }
        }
    }

    // MARK: - Encima del suelo: escombros, huesos, alfombras y rejillas

    mutating func paintFloorOverlay(_ x: Int, _ y: Int) {
        var d = Dice(x, y, 23)
        switch t(x, y) {
        case .rubble: rubble(x, y, &d)
        case .bones: bones(x, y, &d)
        case .carpet: carpet(x, y, &d)
        case .grate: grate(x, y, &d)
        default: break
        }
    }

    /// Piedrecita con luz arriba-izquierda.
    mutating func pebble(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ ramp: [UInt32]) {
        c.shadowEllipse(x + w / 2 + 1, y + h, max(1, w / 2 + 1), 1, 0.25)
        for yy in 0..<h {
            for xx in 0..<w {
                if (xx == 0 || xx == w - 1) && (yy == 0 || yy == h - 1) && w > 2 && h > 2 { continue }
                let k = yy == 0 || xx == 0 ? 3 : (yy == h - 1 || xx == w - 1) ? 1 : 2
                c.put(x + xx, y + yy, ramp[k])
            }
        }
        if w > 2 { c.put(x + 1, y, ramp[4]) }
    }

    private mutating func rubble(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        crack(x0 + d.range(2, 10), y0 + d.range(2, 8), d.range(8, 14), &d)
        crack(x0 + d.range(10, 20), y0 + d.range(8, 16), d.range(5, 9), &d)
        let base = s.theme == .crypt || s.theme == .prison ? s.wall : s.stone
        let rock = [base[1], base[2], base[3], base[4], DColor.mix(base[4], 0xFFFFFF, 0.25)]
        // Losa levantada.
        if d.chance(0.5) {
            let bx = x0 + d.range(3, 11), by = y0 + d.range(3, 12)
            let w = d.range(7, 10), h = d.range(4, 6)
            c.shadowEllipse(bx + w / 2 + 2, by + h, w / 2 + 1, 2, 0.28)
            for yy in 0..<h {
                for xx in 0..<w where !(yy == 0 && (xx == 0 || xx == w - 1)) && !(yy == h - 1 && xx == w - 1 && d.chance(0.5)) {
                    c.put(bx + xx, by + yy, yy == 0 ? s.floor[4] : yy == h - 1 ? s.floor[0] : DColor.mix(s.floor[2], s.floor[3], 0.5))
                }
            }
            c.hline(bx + 1, by + h - 2, w - 2, s.floor[1])
        }
        for _ in 0..<d.range(4, 7) {
            let w = d.range(2, 4), h = d.range(2, 3)
            pebble(x0 + d.range(1, 20), y0 + d.range(2, 20), w, h, rock)
        }
        // Gravilla.
        for _ in 0..<d.range(6, 12) { c.put(x0 + d.range(1, 22), y0 + d.range(1, 22), d.chance(0.5) ? rock[1] : rock[3]) }
        switch s.theme {
        case .sewer, .prison:
            if d.chance(0.6) { mossPatch(x0 + d.range(4, 18), y0 + d.range(4, 18), d.range(2, 4), &d) }
        case .mine:
            // Trozos de mineral con brillo.
            for _ in 0..<d.range(1, 3) {
                let px = x0 + d.range(3, 19), py = y0 + d.range(4, 19)
                pebble(px, py, 3, 3, s.stone)
                c.glow(px + 1, py + 1, s.magic[2]); c.glow(px, py, s.magic[3])
            }
        case .forge:
            // Escoria con brasas.
            for _ in 0..<d.range(1, 3) {
                let px = x0 + d.range(3, 19), py = y0 + d.range(4, 19)
                pebble(px, py, 4, 3, [0x140C0C, 0x221614, 0x2E1E1A, 0x3E2A24, 0x54382E])
                c.glow(px + 1, py + 1, s.magic[1])
            }
        case .crypt:
            // Restos de vasija.
            if d.chance(0.5) {
                let px = x0 + d.range(4, 16), py = y0 + d.range(6, 18)
                c.hline(px, py, 3, 0x7A5A6A); c.hline(px + 4, py + 2, 2, 0x5E4452); c.put(px, py - 1, 0x9A7A88)
            }
        }
    }

    private mutating func bones(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        var items = [0, 1, 2, 3, 4]
        // Mezcla determinista.
        for i in stride(from: items.count - 1, to: 0, by: -1) { items.swapAt(i, d.int(i + 1)) }
        let count = d.range(2, 3)
        let spots = [(4, 4), (13, 5), (5, 14), (14, 14), (9, 9)]
        for n in 0..<count {
            let (sx, sy) = spots[(n + d.int(5)) % 5]
            let px = x0 + sx + d.range(-1, 2), py = y0 + sy + d.range(-1, 2)
            switch items[n] {
            case 0: skull(px, py, flip: d.chance(0.5))
            case 1: longBone(px, py, diag: d.range(-1, 1))
            case 2: ribs(px, py)
            case 3: chain(px, py, len: d.range(5, 9), &d)
            default:
                for _ in 0..<3 { c.put(px + d.range(0, 5), py + d.range(0, 3), s.bone[d.range(2, 3)]) }
                longBone(px + 1, py + 3, diag: 0)
            }
        }
        if s.theme == .forge || s.theme == .mine { soot(x0 + 12, y0 + 12, 6, &d) }
    }

    mutating func skull(_ x: Int, _ y: Int, flip: Bool = false) {
        let rows = [
            ".abba.",
            "abccba",
            "bddcdb",
            "bddcdb",
            ".bccb.",
            ".b.b..",
        ]
        let b = s.bone
        c.shadowEllipse(x + 4, y + 6, 4, 1, 0.4)
        c.sprite(rows, x, y, ["a": b[4], "b": b[2], "c": b[3], "d": 0x1A1418], flip: flip)
    }

    mutating func longBone(_ x: Int, _ y: Int, diag: Int) {
        let b = s.bone
        c.shadowEllipse(x + 4, y + 2, 5, 1, 0.3)
        for i in 0..<8 {
            let yy = y + (diag * i) / 3
            c.put(x + i, yy, i < 2 || i > 5 ? b[3] : b[2])
            c.put(x + i, yy + 1, b[1])
        }
        c.put(x - 1, y, b[3]); c.put(x - 1, y + 1, b[2])
        c.put(x + 8, y + (diag * 7) / 3, b[3]); c.put(x + 8, y + (diag * 7) / 3 + 1, b[1])
        c.put(x, y - 1, b[4])
    }

    mutating func ribs(_ x: Int, _ y: Int) {
        let b = s.bone
        c.shadowEllipse(x + 4, y + 4, 5, 2, 0.35)
        c.hline(x, y + 2, 9, b[1])   // columna
        for i in 0..<4 {
            let rx = x + 1 + i * 2
            c.put(rx, y, b[3]); c.put(rx, y + 1, b[2]); c.put(rx, y + 3, b[2]); c.put(rx, y + 4, b[1])
            c.put(rx + 1, y - (i & 1), b[3])
        }
    }

    mutating func chain(_ x: Int, _ y: Int, len: Int, _ d: inout Dice) {
        let ir = s.iron
        var cx = x, cy = y
        for i in 0..<len {
            if i % 2 == 0 {
                c.put(cx, cy, ir[3]); c.put(cx + 1, cy, ir[2]); c.put(cx, cy + 1, ir[1])
            } else {
                c.put(cx, cy, ir[2]); c.put(cx, cy + 1, ir[1])
            }
            c.shade(cx + 1, cy + 2, 0.7)
            cx += 1
            if d.chance(0.35) { cy += d.chance(0.5) ? 1 : -1 }
        }
        // Grillete al final.
        c.put(cx, cy - 1, ir[3]); c.put(cx + 1, cy - 1, ir[3]); c.put(cx - 0, cy + 1, ir[2]); c.put(cx + 2, cy, ir[2])
        c.put(cx + 1, cy + 2, ir[1]); c.put(cx + 2, cy + 1, ir[1])
    }

    // MARK: Alfombra / camino

    private mutating func carpet(_ x: Int, _ y: Int, _ d: inout Dice) {
        switch s.theme {
        case .mine: rails(x, y, &d)
        case .sewer: boardwalk(x, y, &d)
        case .forge: ironPlates(x, y, &d)
        default: rug(x, y, &d)
        }
    }

    private func sameAs(_ x: Int, _ y: Int, _ k: DungeonTile) -> Bool { t(x, y) == k }

    /// Alfombra con ribete dorado y motivo, gastada en algunos pixeles.
    private mutating func rug(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let cp = s.carpet, tr = s.trim
        let L = !sameAs(x - 1, y, .carpet), R = !sameAs(x + 1, y, .carpet)
        let U = !sameAs(x, y - 1, .carpet), D = !sameAs(x, y + 1, .carpet)
        for ly in 0..<T {
            for lx in 0..<T {
                let px = x0 + lx, py = y0 + ly
                // Distancia al borde abierto más cercano.
                var e = 99
                if L { e = min(e, lx) }; if R { e = min(e, T - 1 - lx) }
                if U { e = min(e, ly) }; if D { e = min(e, T - 1 - ly) }
                var col: UInt32
                if e == 0 { col = cp[0] }
                else if e == 1 { col = tr[3] }
                else if e == 2 { col = tr[1] }
                else if e == 3 { col = cp[0] }
                else {
                    // Trama del tejido y motivo de rombos.
                    col = (px + py) & 1 == 0 ? cp[2] : DColor.mix(cp[2], cp[1], 0.4)
                    let mx = px % 12, my = py % 12
                    let ax = abs(mx - 6), ay = abs(my - 6)
                    if ax + ay == 4 { col = cp[3] } else if ax + ay < 2 { col = DColor.mix(cp[3], tr[2], 0.5) }
                    if (lx == 4 && L) || (ly == 4 && U) { col = cp[3] }
                    if (lx == T - 5 && R) || (ly == T - 5 && D) { col = cp[1] }
                }
                if e == 1 && ((L && lx == 1) || (U && ly == 1)) { col = tr[4] }
                c.put(px, py, col)
            }
        }
        // Desgaste.
        for _ in 0..<d.range(3, 8) {
            let px = x0 + d.range(3, 20), py = y0 + d.range(3, 20)
            c.mix(px, py, s.floor[2], 0.5)
        }
        // Flecos en los extremos abiertos de arriba y abajo.
        if D { for i in stride(from: 2, to: T - 2, by: 2) { c.put(x0 + i, y0 + T - 1, tr[2]) } }
        if U { for i in stride(from: 2, to: T - 2, by: 2) { c.put(x0 + i, y0, tr[2]) } }
    }

    /// Vías de vagoneta: traviesas de madera y dos raíles.
    private mutating func rails(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let vertical = sameAs(x, y - 1, .carpet) || sameAs(x, y + 1, .carpet)
        let w = s.wood, ir = s.iron
        // Grava del lecho.
        for _ in 0..<40 { c.put(x0 + d.range(2, 21), y0 + d.range(0, 23), d.chance(0.5) ? s.floor[1] : s.floor[3]) }
        if vertical {
            for k in 0..<4 {
                let sy = y0 + 1 + k * 6
                let jx = d.range(-1, 1)
                c.rect(x0 + 3 + jx, sy, 18, 3, w[2]); c.hline(x0 + 3 + jx, sy, 18, w[3]); c.hline(x0 + 3 + jx, sy + 3, 18, w[0])
                c.put(x0 + 5 + jx + d.int(10), sy + 1, w[1])
            }
            for rx in [x0 + 6, x0 + 16] {
                c.vline(rx, y0, T, ir[3]); c.vline(rx + 1, y0, T, ir[2]); c.vline(rx + 2, y0, T, ir[0])
                for k in 0..<4 { c.put(rx - 1, y0 + 2 + k * 6, ir[1]); c.put(rx + 3, y0 + 2 + k * 6, ir[1]) }
            }
        } else {
            for k in 0..<4 {
                let sx = x0 + 1 + k * 6
                let jy = d.range(-1, 1)
                c.rect(sx, y0 + 4 + jy, 3, 17, w[2]); c.vline(sx, y0 + 4 + jy, 17, w[3]); c.vline(sx + 3, y0 + 5 + jy, 16, w[0])
                c.put(sx + 1, y0 + 6 + jy + d.int(10), w[1])
            }
            for ry in [y0 + 7, y0 + 16] {
                c.hline(x0, ry, T, ir[4]); c.hline(x0, ry + 1, T, ir[2]); c.hline(x0, ry + 2, T, ir[0])
            }
        }
    }

    /// Pasarela de tablones sobre el suelo mojado (cloacas).
    private mutating func boardwalk(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let w = s.wood
        for k in 0..<4 {
            let py = y0 + k * 6
            let tone = d.range(1, 3)
            c.rect(x0 + 1, py, 22, 6, w[tone])
            c.hline(x0 + 1, py, 22, w[min(4, tone + 1)])
            c.hline(x0 + 1, py + 5, 22, w[0])
            for _ in 0..<3 { c.hline(x0 + d.range(2, 16), py + d.range(2, 3), d.range(3, 6), w[max(0, tone - 1)]) }
            c.put(x0 + 3, py + 2, s.iron[3]); c.put(x0 + 20, py + 2, s.iron[3])
            if d.chance(0.25) { mossPatch(x0 + d.range(3, 20), py + 3, 2, &d) }
        }
        if !sameAs(x - 1, y, .carpet) { c.vline(x0, y0, T, w[0]); c.vline(x0 + 1, y0, T, w[1]) }
        if !sameAs(x + 1, y, .carpet) { c.vline(x0 + T - 1, y0, T, w[0]) }
    }

    /// Planchas de hierro remachadas (forja).
    private mutating func ironPlates(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let ir = s.iron
        for py in 0..<2 {
            for pxi in 0..<2 {
                let bx = x0 + pxi * 12, by = y0 + py * 12
                c.rect(bx, by, 12, 12, ir[2])
                c.hline(bx, by, 12, ir[3]); c.vline(bx, by, 12, ir[3])
                c.hline(bx, by + 11, 12, ir[0]); c.vline(bx + 11, by, 12, ir[0])
                // Estrías antideslizantes.
                for k in stride(from: 2, to: 10, by: 3) {
                    if (pxi + py) & 1 == 0 { c.hline(bx + 2, by + k, 3, ir[1]); c.put(bx + 2, by + k - 1, ir[3]) } else { c.vline(bx + k, by + 2, 3, ir[1]); c.put(bx + k - 1, by + 2, ir[3]) }
                    if (pxi + py) & 1 == 0 { c.hline(bx + 7, by + k + 1, 3, ir[1]) } else { c.vline(bx + k + 1, by + 7, 3, ir[1]) }
                }
                for (rx, ry) in [(2, 2), (9, 2), (2, 9), (9, 9)] { c.put(bx + rx, by + ry, ir[4]); c.put(bx + rx + 1, by + ry + 1, ir[0]) }
                if d.chance(0.3) { soot(bx + 6, by + 6, 4, &d) }
            }
        }
    }

    // MARK: Rejilla

    private mutating func grate(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let st = s.theme == .mine ? s.stone : s.wall, ir = s.iron
        // Marco de piedra biselado.
        c.rect(x0 + 1, y0 + 1, 22, 22, st[2])
        c.hline(x0 + 1, y0 + 1, 22, st[4]); c.vline(x0 + 1, y0 + 1, 22, st[3])
        c.hline(x0 + 1, y0 + 22, 22, st[0]); c.vline(x0 + 22, y0 + 1, 22, st[1])
        for k in [0, 21] { c.put(x0 + 1 + k, y0 + 1, st[1]); c.put(x0 + 1 + k, y0 + 22, st[0]) }
        // Hueco oscuro (más claro abajo: se ve el fondo).
        let inner = (x: x0 + 4, y: y0 + 4, w: 16, h: 16)
        let deep: UInt32 = s.theme == .forge ? 0x2A0A04 : 0x07070A
        let mid: UInt32 = s.theme == .forge ? 0x8A2208 : s.theme == .sewer ? 0x12261A : 0x121218
        for yy in 0..<inner.h {
            for xx in 0..<inner.w {
                let f = Double(yy) / Double(inner.h)
                let col = DColor.mix(deep, mid, f * f)
                if s.theme == .forge && yy > 6 { c.glow(inner.x + xx, inner.y + yy, DColor.mix(col, s.magic[1], (f - 0.4) * 0.6)) }
                else { c.put(inner.x + xx, inner.y + yy, col) }
            }
        }
        // Lo que hay abajo: agua que brilla, ojos o brasas.
        let what = d.int(4)
        if s.theme == .sewer || (s.theme == .prison && what == 0) {
            c.hline(inner.x + 3, inner.y + 12, 5, s.liquid[3]); c.hline(inner.x + 9, inner.y + 14, 4, s.liquid[2])
        } else if what == 1 || what == 2 {
            let ex = inner.x + d.range(3, 9), ey = inner.y + d.range(5, 10)
            let eye: UInt32 = s.theme == .crypt ? 0x9AE8FF : s.theme == .mine ? 0xB4FFEC : 0xFF4A2A
            c.glow(ex, ey, eye); c.glow(ex + 4, ey, eye)
        }
        // Barrotes con brillo arriba y sombra abajo.
        for bx in stride(from: inner.x + 1, to: inner.x + inner.w, by: 4) {
            c.vline(bx, inner.y, inner.h, ir[2]); c.vline(bx + 1, inner.y, inner.h, ir[1])
            c.put(bx, inner.y, ir[4])
        }
        for by in [inner.y + 5, inner.y + 11] {
            c.hline(inner.x, by, inner.w, ir[3]); c.hline(inner.x, by + 1, inner.w, ir[1])
        }
        // Sombra dentro del marco y óxido.
        c.hline(inner.x, inner.y, inner.w, ir[0])
        c.vline(inner.x, inner.y, inner.h, ir[0])
        if s.theme != .forge {
            for _ in 0..<d.range(2, 5) { c.put(inner.x + d.int(inner.w), inner.y + d.int(inner.h), 0x6A3A1E) }
        }
        if s.theme == .sewer || s.theme == .prison { mossPatch(x0 + 3, y0 + 21, 2, &d) }
    }

    // MARK: - Sombras

    mutating func paintShadows(_ x: Int, _ y: Int) {
        let k = t(x, y)
        guard !k.isWall else { return }
        let x0 = x * T, y0 = y * T
        // Sombra del muro de arriba (luz arriba-izquierda: cae hacia abajo).
        if isWall(x, y - 1) {
            let f: [Double] = [0.5, 0.58, 0.68, 0.78, 0.88, 0.95]
            for (i, v) in f.enumerated() { for px in x0..<(x0 + T) { c.shade(px, y0 + i, v) } }
        } else if isWall(x - 1, y - 1) {
            // Esquina: triángulo de sombra.
            for i in 0..<5 { for j in 0..<(5 - i) { c.shade(x0 + j, y0 + i, 0.6 + Double(i + j) * 0.07) } }
        }
        // Sombra del muro de la izquierda (proyecta a la derecha).
        if isWall(x - 1, y) {
            let f: [Double] = [0.55, 0.68, 0.8, 0.92]
            for (i, v) in f.enumerated() { for py in y0..<(y0 + T) { c.shade(x0 + i, py, v) } }
        }
        // Oclusión suave contra el muro de la derecha.
        if isWall(x + 1, y) {
            for py in y0..<(y0 + T) { c.shade(x0 + T - 1, py, 0.75); c.shade(x0 + T - 2, py, 0.9) }
        }
        // Sombra de contacto de los obstáculos (asoma por abajo a la derecha).
        switch k {
        case .pillar, .statue:
            c.shadowEllipse(x0 + 15, y0 + 21, 11, 4, 0.42)
        case .brazier:
            c.shadowEllipse(x0 + 14, y0 + 21, 9, 3, 0.4)
        case .crates:
            c.shadowEllipse(x0 + 15, y0 + 21, 12, 4, 0.4)
        case .chest:
            c.shadowEllipse(x0 + 14, y0 + 21, 10, 3, 0.4)
        case .altar where t(x - 1, y) != .altar:
            c.shadowEllipse(x0 + T + 3, y0 + 21, 25, 4, 0.42)
        default: break
        }
    }
}
