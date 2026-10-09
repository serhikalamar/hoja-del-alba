import Foundation
import GameCore

/// Suelo del pueblo: hierba, calles de adoquín, plazas de losas, agua, muros almenados,
/// escalinata, fuente y objetos sólidos que van pegados al suelo (puestos, cajas, arbustos, vallas).
extension TownArt {
    /// Material de una casilla para unir bordes.
    enum Surface { case grass, street, plaza, water, other }

    /// Datos del mapa precalculados para dibujar rápido.
    struct TownContext {
        let map: AreaMap
        let w: Int, h: Int
        var surfaces: [Surface]
        var covered: [Bool]

        init(_ map: AreaMap) {
            self.map = map
            w = map.width; h = map.height
            covered = Array(repeating: false, count: w * h)
            surfaces = Array(repeating: .grass, count: w * h)
            for b in map.buildings {
                for y in b.y..<(b.y + b.height) { for x in b.x..<(b.x + b.width) where x >= 0 && y >= 0 && x < w && y < h { covered[y * w + x] = true } }
            }
            for y in 0..<h { for x in 0..<w { surfaces[y * w + x] = covered[y * w + x] ? .other : TownArt.surface(map, x, y) } }
        }

        func surface(_ x: Int, _ y: Int) -> Surface {
            guard x >= 0, y >= 0, x < w, y < h else { return .grass }
            return surfaces[y * w + x]
        }

        func tile(_ x: Int, _ y: Int) -> Tile { map.tile(x, y) }
    }

    static func surface(_ map: AreaMap, _ x: Int, _ y: Int) -> Surface {
        switch map.tile(x, y) {
        case .grass, .flowers, .tree, .fence: return .grass
        case .street: return .street
        case .plaza, .fountain, .stall, .crates: return .plaza
        case .water: return .water
        case .lamp, .bush: return decorBase(map, x, y)
        case .areaExit:
            // La salida sigue la calle si da a ella; si no, es un sendero sobre la hierba (`townFieldTiles`).
            let street = [(-1, 0), (1, 0), (0, -1), (0, 1)].contains { map.tile(x + $0.0, y + $0.1) == .street }
            return street ? .street : .grass
        default: return .other
        }
    }

    /// Bajo una farola o un arbusto va el suelo que más lo rodea.
    static func decorBase(_ map: AreaMap, _ x: Int, _ y: Int) -> Surface {
        var grass = 0, street = 0, plaza = 0
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            switch map.tile(x + dx, y + dy) {
            case .grass, .flowers, .tree, .fence: grass += 1
            case .street: street += 1
            case .plaza, .fountain, .stall, .crates: plaza += 1
            default: break
            }
        }
        if plaza > 0 && plaza >= max(grass, street) { return .plaza }
        return street > grass ? .street : .grass
    }

    // MARK: - Composición del pueblo

    static func townGround(_ map: AreaMap) -> PixelGrid {
        let T = tile
        let ctx = TownContext(map)
        var g = PixelGrid(width: map.width * T, height: map.height * T)
        let fountains = fountainCenters(map)

        // 1. Materiales
        for y in 0..<ctx.h {
            for x in 0..<ctx.w {
                let ox = x * T, oy = y * T
                switch ctx.surface(x, y) {
                case .street:
                    for py in oy..<(oy + T) { for px in ox..<(ox + T) { g.pixels[py * g.width + px] = cobbleColor(px, py) } }
                case .plaza:
                    for py in oy..<(oy + T) { for px in ox..<(ox + T) { g.pixels[py * g.width + px] = plazaColor(px, py, fountains) } }
                case .water:
                    waterTile(&g, ctx, x, y)
                case .grass, .other:
                    for py in oy..<(oy + T) { for px in ox..<(ox + T) { g.pixels[py * g.width + px] = grassColor(px, py) } }
                    if !ctx.covered[y * ctx.w + x] && ctx.tile(x, y) != .wall {
                        grassDetails(&g, x, y, flowers: ctx.tile(x, y) == .flowers)
                    }
                }
            }
        }
        // 2. Bordes: hierba que invade las piedras y bordillos de la plaza
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where ctx.surface(x, y) == .street || ctx.surface(x, y) == .plaza {
                edges(&g, ctx, x, y)
            }
        }
        // 3. Sombras proyectadas (luz arriba-izquierda: caen abajo-derecha) y charcos de luz de las farolas
        castShadows(&g, ctx)
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where ctx.tile(x, y) == .lamp { lampPool(&g, x * T + T / 2, y * T + T - 4) }
        }
        // 4. Objetos del suelo, fila a fila (lo de abajo tapa a lo de arriba)
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where !ctx.covered[y * ctx.w + x] {
                let ox = x * T, oy = y * T
                switch ctx.tile(x, y) {
                case .wall: wallTile(&g, ctx, x, y)
                case .stairs: stairsTile(&g, ctx, x, y)
                case .fountain where ctx.tile(x - 1, y) != .fountain && ctx.tile(x, y - 1) != .fountain:
                    fountain(&g, ox + T, oy + T + 2)
                case .stall where ctx.tile(x - 1, y) != .stall:
                    stall(&g, ox, oy, width: ctx.tile(x + 1, y) == .stall ? 2 * T : T, kind: hash(x, y, 501))
                case .crates: crates(&g, ox, oy, kind: hash(x, y, 502))
                case .bush: bush(&g, ox, oy, planter: ctx.surface(x, y) == .plaza, seed: hash(x, y, 503))
                case .fence:
                    fence(&g, ox, oy, left: ctx.tile(x - 1, y) == .fence, right: ctx.tile(x + 1, y) == .fence, seed: hash(x, y, 504))
                default: break
                }
            }
        }
        return g
    }

    // MARK: - Hierba

    static let grassTones: [UInt32] = [0x4B8F43, 0x559D48, 0x60A94E, 0x6BB454, 0x77BE5B]
    static let grassDark: UInt32 = 0x3F7E3D
    static let grassLight: UInt32 = 0x8ACB64

    /// Color de la hierba en un pixel (pura: sirve para casillas y para la hierba que invade).
    static func grassColor(_ x: Int, _ y: Int) -> UInt32 {
        // Briznas sueltas: base oscura y punta clara.
        let hb = hash(x, y, 13) % 41
        if hb == 0 { return grassDark }
        if hash(x, y + 1, 13) % 41 == 0 { return grassTones[3] }
        let n = noise(Double(x) / 13, Double(y) / 9, 11) * 0.62 + noise(Double(x) / 4.5, Double(y) / 3.5, 12) * 0.38
        return tone(grassTones, (n - 0.5) * 1.5 + 0.5, x, y, dither: 0.3)
    }

    /// Matas, flores y piedrecitas distintas en cada casilla.
    static func grassDetails(_ g: inout PixelGrid, _ x: Int, _ y: Int, flowers: Bool) {
        let T = tile, ox = x * T, oy = y * T
        var rng = SeededGenerator(seed: UInt64(hash(x, y, 77)))
        // Matas de hierba alta
        for _ in 0..<Int.random(in: 2...5, using: &rng) {
            let px = ox + Int.random(in: 2..<T - 2, using: &rng), py = oy + Int.random(in: 3..<T, using: &rng)
            tuft(&g, px, py, big: Int.random(in: 0..<3, using: &rng) == 0)
        }
        // Trébol / manchas oscuras
        if Int.random(in: 0..<3, using: &rng) == 0 {
            let px = ox + Int.random(in: 3..<T - 3, using: &rng), py = oy + Int.random(in: 3..<T - 3, using: &rng)
            for (dx, dy) in [(0, 0), (1, 0), (-1, 1), (0, 1), (1, 1), (2, 1), (0, 2)] where hash(px + dx, py + dy, 3) % 4 != 0 {
                g[px + dx, py + dy] = grassTones[0]
            }
            g[px, py] = grassTones[4]
        }
        // Piedrecita
        if Int.random(in: 0..<4, using: &rng) == 0 {
            pebble(&g, ox + Int.random(in: 3..<T - 4, using: &rng), oy + Int.random(in: 3..<T - 3, using: &rng), big: Int.random(in: 0..<3, using: &rng) == 0)
        }
        // Florecilla suelta
        if !flowers && Int.random(in: 0..<7, using: &rng) == 0 {
            let colors: [UInt32] = [0xF4F0E8, 0xF6D45A, 0xE88AB4]
            let px = ox + Int.random(in: 2..<T - 2, using: &rng), py = oy + Int.random(in: 2..<T - 2, using: &rng)
            g[px, py + 1] = grassDark
            g[px, py] = colors[Int.random(in: 0..<colors.count, using: &rng)]
        }
        if flowers {
            let palettes: [(UInt32, UInt32)] = [(0xF6F2EA, 0xF6D45A), (0xF6D45A, 0xE89A30), (0xEE8AB8, 0xFFF0A0), (0x8EC8F4, 0xFFF4C0), (0xD86A5A, 0xFFD060)]
            let count = Int.random(in: 4...6, using: &rng)
            for _ in 0..<count {
                let px = ox + Int.random(in: 2..<T - 2, using: &rng), py = oy + Int.random(in: 2..<T - 2, using: &rng)
                let (petal, heart) = palettes[Int.random(in: 0..<palettes.count, using: &rng)]
                g[px - 1, py + 2] = grassDark; g[px + 1, py + 2] = grassDark; g[px, py + 2] = grassLight
                g[px - 1, py] = petal; g[px + 1, py] = petal; g[px, py - 1] = petal
                g[px, py + 1] = dark(petal, 0.8)
                g[px, py] = heart
            }
        }
    }

    /// Mata de hierba en forma de W: base oscura y puntas claras.
    static func tuft(_ g: inout PixelGrid, _ x: Int, _ y: Int, big: Bool) {
        g[x - 1, y] = grassDark; g[x, y] = grassDark; g[x + 1, y] = grassDark
        g[x - 2, y - 1] = grassTones[4]; g[x, y - 1] = grassTones[3]; g[x + 2, y - 1] = grassTones[4]
        g[x, y - 2] = grassLight
        if big {
            g[x - 3, y - 2] = grassLight; g[x + 3, y - 2] = grassLight
            g[x - 1, y - 1] = grassTones[1]; g[x + 1, y - 1] = grassTones[1]
            g[x + 1, y - 3] = grassLight
        }
    }

    static func pebble(_ g: inout PixelGrid, _ x: Int, _ y: Int, big: Bool) {
        let w = big ? 3 : 2
        fill(&g, x, y, w, 2, 0xA8A49C)
        fill(&g, x, y, w - 1, 1, 0xD4D0C6)
        g[x + w - 1, y + 1] = 0x7E7A72
        fill(&g, x + 1, y + 2, w, 1, grassDark)
    }

    // MARK: - Adoquines

    static let cobbleTones: [UInt32] = [0xB7AC95, 0xC2B7A0, 0xCBC1AA, 0xAEA38C, 0xBDB39A]
    static let cobbleMortar: UInt32 = 0x8D826D

    /// Adoquines redondeados (celdas de Voronoi) con brillo arriba-izquierda y sombra abajo-derecha.
    static func cobbleColor(_ px: Int, _ py: Int) -> UInt32 {
        let cw = 7, ch = 5
        let cx = px / cw, cy = py / ch
        var best = 1e9, second = 1e9, bx = 0, by = 0, rx = 0.0, ry = 0.0
        for j in -1...1 {
            for i in -1...1 {
                let gx = cx + i, gy = cy + j
                let h = hash(gx, gy, 31)
                let fx = Double(gx * cw) + 1.5 + Double(h % 4)
                let fy = Double(gy * ch) + 1.0 + Double((h >> 4) % 3)
                let dx = (Double(px) - fx) * 0.8, dy = Double(py) - fy
                let d = dx * dx + dy * dy
                if d < best { second = best; best = d; bx = gx; by = gy; rx = dx; ry = dy } else if d < second { second = d }
            }
        }
        let edge = second.squareRoot() - best.squareRoot()
        if edge < 0.9 {
            // Junta: a veces con hierbajos que crecen entre las piedras.
            let weeds = noise(Double(px) / 14, Double(py) / 14, 35)
            if weeds > 0.68 && hash(px, py, 36) % 3 == 0 { return hash(px, py, 37) % 2 == 0 ? 0x5E9A47 : 0x4B8A40 }
            return cobbleMortar
        }
        let h = hash(bx, by, 32)
        var c = cobbleTones[h % cobbleTones.count]
        let lit = -(rx + ry)
        if edge < 1.9 {
            c = lit > 0 ? light(c, 1.07) : dark(c, 0.84)
        } else if lit > 2.4 && hash(px, py, 33) % 3 != 0 {
            c = light(c, 1.04)
        }
        // Desgaste y manchas suaves
        if noise(Double(px) / 9, Double(py) / 9, 34) > 0.74 { c = dark(c, 0.95) }
        return c
    }

    // MARK: - Losas de la plaza

    static let slabTones: [UInt32] = [0xDCCFB3, 0xD5C8AB, 0xE2D6BB, 0xCFC1A4]
    static let slabJoint: UInt32 = 0xA99B7F

    static func plazaColor(_ px: Int, _ py: Int, _ fountains: [(Int, Int)]) -> UInt32 {
        for (fx, fy) in fountains {
            let dx = Double(px - fx), dy = Double(py - fy) * 1.32
            let r = (dx * dx + dy * dy).squareRoot()
            if r < 58 { return fountainPaving(px, py, dx, dy, r) }
        }
        let rh = 8
        let row = py / rh, ly = py % rh
        let rw = [12, 16, 14][hash(row, 0, 41) % 3]
        let off = hash(row, 1, 42) % rw
        let col = (px + off) / rw, lx = (px + off) % rw
        let h = hash(col, row, 43)
        var c = slabTones[h % slabTones.count]
        if lx == 0 || ly == 0 { return slabJoint }
        if ly == 1 || lx == 1 { c = light(c, 1.04) } else if ly == rh - 1 || lx == rw - 1 { c = dark(c, 0.94) }
        // Grieta
        if h % 9 == 0 {
            let start = 3 + (h >> 6) % max(1, rw - 7)
            if ly > 1 && ly < rh - 1 && lx == start + ly / 2 { c = dark(c, 0.82) }
        }
        // Mancha de humedad / desgaste
        if noise(Double(px) / 7, Double(py) / 6, 44) > 0.73 { c = dark(c, 0.95) }
        if hash(px, py, 45) % 97 == 0 { c = dark(c, 0.88) }
        return c
    }

    /// Dibujo de losas en anillos alrededor de la fuente.
    private static func fountainPaving(_ px: Int, _ py: Int, _ dx: Double, _ dy: Double, _ r: Double) -> UInt32 {
        let ringW = 8.0
        let ring = Int(r / ringW)
        let fr = r - Double(ring) * ringW
        let angle = atan2(dy, dx) + Double.pi
        let segs = max(6, Int(2 * Double.pi * (Double(ring) + 0.5) * ringW / 11))
        let a = angle / (2 * Double.pi) * Double(segs) + (ring % 2 == 0 ? 0 : 0.5)
        let seg = Int(a) % segs
        let fa = a - floor(a)
        let tones: [UInt32] = ring == 6 ? [0xB8A487, 0xB29E80] : (ring % 2 == 0 ? [0xD9CBAE, 0xE0D3B7] : [0xC9B597, 0xC2AE8F])
        if fr < 1 || fa * Double(segs) * (r / Double(segs)) < 0.0 { return slabJoint }
        let arc = fa * 2 * Double.pi * r / Double(segs)
        if arc < 1 { return slabJoint }
        var c = tones[hash(seg, ring, 46) % tones.count]
        if fr < 2 { c = light(c, 1.04) } else if fr > ringW - 1.5 { c = dark(c, 0.94) }
        if hash(px, py, 47) % 83 == 0 { c = dark(c, 0.9) }
        return c
    }

    static func fountainCenters(_ map: AreaMap) -> [(Int, Int)] {
        var list: [(Int, Int)] = []
        for y in 0..<map.height {
            for x in 0..<map.width where map.tile(x, y) == .fountain && map.tile(x - 1, y) != .fountain && map.tile(x, y - 1) != .fountain {
                list.append(((x + 1) * tile, (y + 1) * tile + 2))
            }
        }
        return list
    }

    // MARK: - Bordes

    /// Distancia (en pixeles) al borde de la casilla que da a un vecino que cumple `test`, y si ese borde es horizontal.
    static func edgeDistance(_ lx: Int, _ ly: Int, _ test: (Int, Int) -> Bool) -> (Int, Bool) {
        let T = tile
        var d = 99, horizontal = true
        let L = test(-1, 0), R = test(1, 0), U = test(0, -1), D = test(0, 1)
        if U && ly < d { d = ly; horizontal = true }
        if D && T - 1 - ly < d { d = T - 1 - ly; horizontal = true }
        if L && lx < d { d = lx; horizontal = false }
        if R && T - 1 - lx < d { d = T - 1 - lx; horizontal = false }
        for (dx, dy) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] where test(dx, dy) && !test(dx, 0) && !test(0, dy) {
            let ex = dx < 0 ? lx : T - 1 - lx, ey = dy < 0 ? ly : T - 1 - ly
            let c = max(ex, ey)
            if c < d { d = c; horizontal = ey >= ex }
        }
        return (d, horizontal)
    }

    private static func edges(_ g: inout PixelGrid, _ ctx: TownContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let me = ctx.surface(x, y)
        let grassTest: (Int, Int) -> Bool = { dx, dy in ctx.surface(x + dx, y + dy) == .grass }
        let curbTest: (Int, Int) -> Bool = { dx, dy in
            let s = ctx.surface(x + dx, y + dy)
            return s == .street || s == .grass || s == .water
        }
        let hasGrass = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)].contains { grassTest($0.0, $0.1) }
        let hasCurb = me == .plaza && [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)].contains { curbTest($0.0, $0.1) }
        guard hasGrass || hasCurb else { return }
        for ly in 0..<T {
            for lx in 0..<T {
                let px = ox + lx, py = oy + ly
                if hasCurb {
                    let (d, horizontal) = edgeDistance(lx, ly, curbTest)
                    if d <= 4 {
                        let along = horizontal ? px : py
                        let joint = (along + (horizontal ? py / T : px / T) * 5) % 11 == 0
                        let c: UInt32
                        switch d {
                        case 0: c = 0x9C8F75
                        case 4: c = slabJoint
                        default: c = joint ? 0xB3A68B : (d == 1 ? 0xEEE5D0 : (d == 3 ? 0xD3C7AC : 0xE3D9C2))
                        }
                        g[px, py] = c
                    }
                }
                if hasGrass {
                    let (d, _) = edgeDistance(lx, ly, grassTest)
                    guard d < 9 else { continue }
                    let t = 0.6 + noise(Double(px) / 4.2, Double(py) / 4.2, 51) * 4.2
                    if Double(d) < t {
                        g[px, py] = grassColor(px, py)
                    } else if Double(d) < t + 1 {
                        if let c = g[px, py] { g[px, py] = dark(c, 0.8) }
                    } else if Double(d) < t + 4 && hash(px, py, 52) % 9 == 0 {
                        g[px, py] = hash(px, py, 53) % 2 == 0 ? grassTones[1] : grassDark
                    }
                }
            }
        }
    }

    // MARK: - Agua

    private static func waterTile(_ g: inout PixelGrid, _ ctx: TownContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let shore: (Int, Int) -> Bool = { dx, dy in ctx.surface(x + dx, y + dy) != .water }
        let deep: [UInt32] = [0x2C68AE, 0x3373B9, 0x3B7FC4]
        for ly in 0..<T {
            for lx in 0..<T {
                let px = ox + lx, py = oy + ly
                let (d, _) = edgeDistance(lx, ly, shore)
                let wobble = Int(noise(Double(px) / 5, Double(py) / 5, 61) * 2.5)
                let e = d - wobble
                var c: UInt32
                if e < 1 {
                    c = hash(px, py, 62) % 3 == 0 ? 0x8E8672 : 0xA49A82        // orilla de piedra y barro
                } else if e < 2 {
                    c = 0x6E6656                                               // borde mojado
                } else if e < 3 {
                    c = (px + py) % 2 == 0 ? 0xCDEBFA : 0x6FB0E2               // espuma
                } else if e < 6 {
                    c = 0x4E94D0                                               // agua poco profunda
                } else {
                    c = tone(deep, noise(Double(px) / 10, Double(py) / 6, 63), px, py, dither: 0.3)
                }
                if e >= 3 {
                    // Reflejos alargados y ondas
                    let streak = noise(Double(px) / 8, Double(py) / 1.6, 64)
                    if streak > 0.8 { c = 0x86C4EE } else if streak > 0.74 { c = 0x5FA2DA }
                    if hash(px, py, 65) % 211 == 0 { c = 0xFFFFFF }
                }
                g[px, py] = c
            }
        }
    }

    // MARK: - Sombras

    private static func castShadows(_ g: inout PixelGrid, _ ctx: TownContext) {
        let T = tile
        var mask = [UInt8](repeating: 0, count: g.width * g.height)
        func mark(_ x: Int, _ y: Int, _ v: UInt8) {
            guard x >= 0, y >= 0, x < g.width, y < g.height else { return }
            mask[y * g.width + x] = max(mask[y * g.width + x], v)
        }
        func markEllipse(_ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int) {
            for y in -ry - 1...ry + 1 {
                for x in -rx - 1...rx + 1 {
                    let d = Double(x * x) / Double(rx * rx) + Double(y * y) / Double(ry * ry)
                    if d <= 0.8 { mark(cx + x, cy + y, 2) } else if d <= 1.15 { mark(cx + x, cy + y, 1) }
                }
            }
        }
        for b in ctx.map.buildings {
            let right = (b.x + b.width) * T, top = b.y * T, bottom = (b.y + b.height) * T
            let band = b.style == .castle ? 16 : 10
            for i in 0..<band {
                let start = top + 16 + i
                for y in start..<(bottom + 3) { mark(right + i, y, i == band - 1 ? 1 : 2) }
            }
            for x in (b.x * T + 4)..<right { mark(x, bottom, 2); mark(x, bottom + 1, 2); mark(x, bottom + 2, 1) }
            for i in 0..<band { mark(right + i, bottom + 3, 1) }
        }
        for y in 0..<ctx.h {
            for x in 0..<ctx.w {
                let ox = x * T, oy = y * T
                switch ctx.tile(x, y) {
                case .tree: markEllipse(ox + 15, oy + 21, 14, 5)
                case .lamp: markEllipse(ox + 14, oy + 21, 6, 2)
                case .wall:
                    if ctx.tile(x, y + 1) != .wall {
                        for py in 0..<5 { for px in 0..<T { mark(ox + px, oy + T + py, py == 4 ? 1 : 2) } }
                    }
                    if ctx.tile(x + 1, y) != .wall && ctx.tile(x + 1, y) != .stairs {
                        for py in 4..<T + 4 { for px in 0..<5 { mark(ox + T + px, oy + py, px == 4 ? 1 : 2) } }
                    }
                default: break
                }
            }
        }
        for i in 0..<mask.count where mask[i] > 0 {
            let x = i % g.width, y = i / g.width
            if mask[i] == 2 || (x + y) % 2 == 0, let c = g.pixels[i] { g.pixels[i] = VillageArt.scale(c, shadowF) }
        }
    }

    /// Luz cálida de una farola en el suelo: más clara cerca, tramada en el borde.
    static func lampPool(_ g: inout PixelGrid, _ cx: Int, _ cy: Int) {
        for y in -12...12 {
            for x in -26...26 {
                let d = (Double(x * x) / 676 + Double(y * y) / 144).squareRoot()
                guard d < 1 else { continue }
                if d > 0.7 && (x + y) % 2 != 0 { continue }
                let k = (1 - d) * 0.16
                tint(&g, cx + x, cy + y, (1 + k * 1.2, 1 + k * 0.8, 1 - k * 0.1))
            }
        }
    }

    // MARK: - Muralla

    static let wallStone: [UInt32] = [0x8D8B9B, 0x9997A7, 0xA4A2B1, 0xAEACBA]
    static let wallMortar: UInt32 = 0x6C6A7A
    static let wallLine: UInt32 = 0x4A4858
    static let capStone: UInt32 = 0xBDBBC8

    private static func wallTile(_ g: inout PixelGrid, _ ctx: TownContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let isWall: (Int, Int) -> Bool = { ctx.tile($0, $1) == .wall }
        if isWall(x, y + 1) {
            wallWalkway(&g, ox, oy, topEnd: !isWall(x, y - 1))
            return
        }
        // Cara frontal de sillares
        let faceTop = oy + 7
        for py in faceTop..<(oy + T) {
            for px in ox..<(ox + T) { g[px, py] = ashlar(px, py - faceTop, faceBottom: oy + T - 1 - py) }
        }
        hline(&g, ox, oy + T - 1, T, wallLine)
        // Remate (adarve) con almenas
        fill(&g, ox, oy, T, 5, capStone)
        for px in ox..<(ox + T) where (px + 3) % 8 == 0 { g[px, oy + 1] = 0x9E9CAA; g[px, oy + 2] = 0x9E9CAA }
        hline(&g, ox, oy + 5, T, 0xD4D2DC)
        hline(&g, ox, oy + 6, T, 0x5E5C6C)
        hline(&g, ox, oy, T, wallLine)
        for px in ox..<(ox + T) {
            let m = px % 10
            guard m < 6 else { continue }
            // Almena: cara superior clara y frente de piedra
            for py in (oy - 4)...(oy + 4) {
                let c: UInt32
                if m == 0 || m == 5 || py == oy - 4 { c = wallLine } else if py <= oy - 2 { c = 0xDAD8E2 } else if m == 4 { c = 0x8E8C9C } else if m == 1 { c = 0xC6C4D0 } else { c = 0xAEACBA }
                g[px, py] = c
            }
        }
        let leftEnd = !isWall(x - 1, y), rightEnd = !isWall(x + 1, y)
        let gate = ctx.tile(x - 1, y) == .street || ctx.tile(x + 1, y) == .street
        if leftEnd { pilaster(&g, ox, oy, gate: gate, leftSide: true) }
        if rightEnd { pilaster(&g, ox + T - (gate ? 18 : 7), oy, gate: gate, leftSide: false) }
    }

    /// Sillares de la muralla: hileras de 5 pixeles con brillo arriba y musgo abajo.
    private static func ashlar(_ px: Int, _ fy: Int, faceBottom: Int) -> UInt32 {
        let rowH = 5
        let row = fy / rowH, ly = fy % rowH
        let rw = 9 + hash(row, 0, 71) % 4
        let off = (row * 5 + hash(px / 97, row, 72)) % rw
        let lx = (px + off) % rw
        let col = (px + off) / rw
        if ly == rowH - 1 || lx == 0 { return wallMortar }
        let h = hash(col, row, 73)
        var c = wallStone[h % wallStone.count]
        if ly == 0 { c = light(c, 1.08) } else if lx == rw - 1 || ly == rowH - 2 && lx > rw - 3 { c = dark(c, 0.9) }
        if faceBottom < 4 { c = dark(c, 0.9) }
        if faceBottom < 6 && noise(Double(px) / 3, Double(fy) / 2, 74) > 0.6 { c = hash(px, fy, 75) % 2 == 0 ? 0x6E9050 : 0x5A7C44 }
        if h % 11 == 0 && lx == 3 + ly { c = dark(c, 0.8) }
        return c
    }

    /// Pilastra al final de un tramo de muralla; en la puerta del pueblo, torreón con estandarte.
    private static func pilaster(_ g: inout PixelGrid, _ x: Int, _ oy: Int, gate: Bool, leftSide: Bool) {
        if gate { gateTower(&g, x, oy, leftSide: leftSide); return }
        let w = 7
        let top = oy - 7
        fill(&g, x, top, w, oy + tile - top, 0xA4A2B1)
        // Sillares de esquina alternos
        var yy = top + 5
        var i = 0
        while yy < oy + tile - 1 {
            let long = i % 2 == 0
            fill(&g, x, yy, long ? w : w - 3, 4, long ? 0xAEACBA : 0x9C9AAA)
            hline(&g, x, yy, long ? w : w - 3, 0xC8C6D2)
            hline(&g, x, yy + 4, w, wallMortar)
            yy += 5; i += 1
        }
        fill(&g, x, top, w, 4, 0xDAD8E2)
        hline(&g, x, top + 4, w, 0x7E7C8C)
        fill(&g, x + w - 2, top, 2, oy + tile - top, 0x7E7C8C)
        vline(&g, x, top, oy + tile - top, 0xC6C4D0)
        // Contorno
        hline(&g, x, top - 1, w, wallLine)
        vline(&g, x - 1, top, oy + tile - top, wallLine)
        vline(&g, x + w, top, oy + tile - top, wallLine)
        if gate {
            // Estandarte azul con escudo dorado
            let bx = x + 2, by = top + 8
            fill(&g, bx - 1, by - 1, 10, 1, 0x5A3A22)
            fill(&g, bx, by, 8, 13, 0x2E5AA8)
            vline(&g, bx, by, 13, 0x5A86D0)
            vline(&g, bx + 7, by, 13, 0x1E3E7A)
            fill(&g, bx + 2, by + 3, 4, 4, 0xE8B83A)
            g[bx + 3, by + 4] = 0xFFF0A0
            g[bx + 2, by + 7] = 0xE8B83A; g[bx + 5, by + 7] = 0xE8B83A
            g[bx + 3, by + 8] = 0xE8B83A; g[bx + 4, by + 8] = 0xE8B83A
            g[bx, by + 13] = 0x2E5AA8; g[bx + 7, by + 13] = 0x1E3E7A
            g[bx + 3, by + 13] = 0x2E5AA8; g[bx + 4, by + 13] = 0x1E3E7A
        }
    }

    /// Pilar de la puerta del pueblo: sillares, remate moldurado (donde se apoya la farola),
    /// estandarte y antorcha hacia la calle.
    private static func gateTower(_ g: inout PixelGrid, _ x: Int, _ oy: Int, leftSide: Bool) {
        let w = 18, T = tile
        let top = oy - 5
        let bottom = oy + T
        tintRect(&g, x + w + 1, top + 6, 5, bottom - top - 3, shadowF)
        for py in top..<bottom {
            for px in x..<(x + w) {
                var c = ashlar(px, py - top + 3, faceBottom: bottom - 1 - py)
                if px < x + 2 { c = light(c, 1.08) } else if px > x + w - 4 { c = dark(c, 0.8) }
                g[px, py] = c
            }
        }
        // Remate moldurado
        fill(&g, x - 2, top - 5, w + 4, 5, 0xC6C4D0); hline(&g, x - 2, top - 5, w + 4, 0xE8E6EE); hline(&g, x - 2, top - 4, w + 4, 0xDAD8E2)
        hline(&g, x - 2, top - 1, w + 4, 0x7E7C8C); vline(&g, x + w + 1, top - 4, 3, 0x8E8C9C)
        hline(&g, x - 2, top - 6, w + 4, wallLine); vline(&g, x - 3, top - 5, 5, wallLine); vline(&g, x + w + 2, top - 5, 5, wallLine)
        // Estandarte azul con escudo dorado
        let bx = x + 4, by = top + 4
        hline(&g, bx - 1, by - 1, 12, 0x5A3A22)
        fill(&g, bx, by, 10, 14, 0x2E5AA8)
        vline(&g, bx, by, 14, 0x5A86D0); vline(&g, bx + 9, by, 14, 0x1E3E7A)
        fill(&g, bx + 3, by + 3, 4, 4, 0xE8B83A); g[bx + 4, by + 4] = 0xFFF0A0
        g[bx + 3, by + 7] = 0xE8B83A; g[bx + 6, by + 7] = 0xE8B83A; g[bx + 4, by + 8] = 0xE8B83A; g[bx + 5, by + 8] = 0xE8B83A
        for i in 0..<5 { g[bx + i, by + 14 + i / 2] = 0x2E5AA8; g[bx + 9 - i, by + 14 + i / 2] = 0x1E3E7A }
        // Contorno
        vline(&g, x - 1, top, bottom - top, wallLine)
        vline(&g, x + w, top, bottom - top, wallLine)
        // Antorcha hacia la calle
        let tx = leftSide ? x + 1 : x + w - 3
        fill(&g, tx, oy + 6, 2, 5, 0x2C2C36)
        g[tx, oy + 5] = 0xF07A20; g[tx + 1, oy + 5] = 0xFFD050; g[tx, oy + 4] = 0xFFF6C8; g[tx + 1, oy + 3] = 0xF07A20
    }

    /// Tramo de muralla visto desde arriba: adarve de losas entre dos parapetos con merlones
    /// (cara superior clara, sombra hacia abajo a la derecha) y troneras más bajas.
    private static func wallWalkway(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, topEnd: Bool) {
        let T = tile
        for py in oy..<(oy + T) {
            for px in ox..<(ox + T) {
                let lx = px - ox
                var c: UInt32
                let m = (py + 2) % 10
                if lx < 5 || lx > T - 6 {
                    // Parapetos
                    let merlon = m < 6
                    let inner = lx < 5 ? lx : T - 1 - lx
                    if merlon {
                        c = m == 0 ? 0xE8E6EE : (m == 5 ? 0x7E7C8C : 0xCCCAD6)
                        if inner == 0 { c = wallLine } else if inner == 1 && lx < 5 { c = light(c, 1.05) } else if inner == 4 { c = dark(c, 0.86) }
                    } else {
                        c = m == 6 ? 0x6E6C7C : 0x9E9CAA
                        if inner == 0 { c = wallLine } else if inner >= 3 { c = 0x8E8C9C }
                    }
                } else {
                    // Losas del adarve con la sombra del parapeto izquierdo
                    let row = py / 7, ly = py % 7
                    let h = hash(row, (lx + row * 3) / 7, 81)
                    c = [0xA6A4B2, 0x9E9CAA, 0xACAAB7, 0xA2A0AE][h % 4]
                    if ly == 0 || (lx + row * 3) % 7 == 0 { c = 0x84828F }
                    if lx < 7 { c = dark(c, 0.84) }
                    if hash(px, py, 82) % 29 == 0 { c = 0x7A8A5A }      // hierbajo entre las losas
                }
                g[px, py] = c
            }
        }
        if topEnd {
            fill(&g, ox, oy, T, 5, 0xD2D0DA)
            hline(&g, ox, oy + 5, T, 0x8E8C9C)
            hline(&g, ox, oy, T, wallLine)
        }
    }

    // MARK: - Escalinata

    private static func stairsTile(_ g: inout PixelGrid, _ ctx: TownContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        for step in 0..<4 {
            let sy = oy + step * 6
            for px in ox..<(ox + T) {
                let joint = (px + step * 7) % 13 == 0
                let h = hash((px + step * 7) / 13, step + y * 4, 91)
                let tread: UInt32 = [0xDCD2BA, 0xD4C9AF, 0xE0D7C0][h % 3]
                g[px, sy] = joint ? 0xB0A58D : light(tread, 1.06)
                g[px, sy + 1] = joint ? 0xB0A58D : tread
                g[px, sy + 2] = joint ? 0xB0A58D : dark(tread, 0.96)
                g[px, sy + 3] = 0xA89C84
                g[px, sy + 4] = joint ? 0x8A7F6A : 0x9C9078
                g[px, sy + 5] = 0x7E7360
                if hash(px, sy, 92) % 17 == 0 { g[px, sy + 1] = dark(tread, 0.88) }
            }
        }
        // Barandillas de piedra a los lados de la escalinata
        if ctx.tile(x - 1, y) != .stairs {
            fill(&g, ox, oy - 4, 5, T + 4, 0xC4C2CE)
            vline(&g, ox + 1, oy - 4, T + 4, 0xDAD8E2)
            vline(&g, ox + 4, oy - 4, T + 4, 0x8E8C9C)
            for i in stride(from: 0, to: T + 4, by: 6) { hline(&g, ox, oy - 4 + i, 5, 0x9E9CAA) }
            hline(&g, ox, oy - 5, 5, wallLine)
            vline(&g, ox + 5, oy - 4, T + 4, wallLine)
        }
        if ctx.tile(x + 1, y) != .stairs {
            fill(&g, ox + T - 5, oy - 4, 5, T + 4, 0xB0AEBA)
            vline(&g, ox + T - 5, oy - 4, T + 4, 0xC6C4D0)
            vline(&g, ox + T - 1, oy - 4, T + 4, 0x7E7C8C)
            for i in stride(from: 0, to: T + 4, by: 6) { hline(&g, ox + T - 5, oy - 4 + i, 5, 0x9290A0) }
            hline(&g, ox + T - 5, oy - 5, 5, wallLine)
            vline(&g, ox + T - 6, oy - 4, T + 4, wallLine)
        }
    }

    // MARK: - Fuente

    /// Fuente de dos niveles (bloque de 2×2 casillas) centrada en `cx, cy`.
    static func fountain(_ g: inout PixelGrid, _ cx: Int, _ cy: Int) {
        // Sombra
        for y in -14...14 {
            for x in -24...26 where Double(x * x) / 676 + Double(y * y) / 196 <= 1 { tint(&g, cx + x + 4, cy + y + 6, shadowF) }
        }
        // Pared exterior del pilón
        for y in -15...19 {
            for x in -23...23 {
                let inFace = Double(x * x) / 529 + Double((y - 4) * (y - 4)) / 225 <= 1
                guard inFace else { continue }
                var c: UInt32 = x < -12 ? 0xB2AEBE : (x > 12 ? 0x8A8698 : 0x9E9AAC)
                if (x + 30) % 7 == 0 { c = 0x7A7688 }
                if y > 16 { c = 0x6E6A7C }
                g[cx + x, cy + y] = c
            }
        }
        // Borde superior del pilón
        for y in -15...15 {
            for x in -23...23 {
                let d = Double(x * x) / 529 + Double(y * y) / 225
                guard d <= 1 else { continue }
                let a = atan2(Double(y), Double(x))
                var c: UInt32 = (x + y) < 0 ? 0xDEDAE6 : 0xC6C2D0
                if Int((a + Double.pi) / (Double.pi / 8) * 100) % 100 < 6 { c = 0x9894A6 }
                if d > 0.9 { c = (x + y) < 0 ? 0xECE8F2 : 0xA8A4B6 }
                g[cx + x, cy + y] = c
            }
        }
        // Agua
        for y in -12...12 {
            for x in -19...19 {
                let u = Double(x) / 19, v = Double(y) / 12
                let d = u * u + v * v
                guard d <= 1 else { continue }
                var c: UInt32 = 0x3C82CC
                if v < -0.62 && d > 0.55 { c = 0x2C62A6 }                     // sombra del borde
                else if d > 0.86 { c = 0x3474BE }
                let r = d.squareRoot()
                if abs(r - 0.58) < 0.05 && hash(x, y, 93) % 3 != 0 { c = 0x7DBCEC }  // ondas
                if abs(r - 0.82) < 0.04 && hash(x, y, 94) % 2 == 0 && v > -0.4 { c = 0x6AAEE4 }
                if u < -0.3 && u > -0.7 && v > -0.4 && v < -0.1 { c = 0x5D9EDA }  // reflejo del cielo
                g[cx + x, cy + y] = c
            }
        }
        // Pie central
        fill(&g, cx - 3, cy - 13, 7, 15, 0xC6C2D0)
        vline(&g, cx - 3, cy - 13, 15, 0xE6E2EE)
        vline(&g, cx + 2, cy - 13, 15, 0x8E8A9C)
        vline(&g, cx + 3, cy - 13, 15, 0x6E6A7C)
        vline(&g, cx - 4, cy - 13, 15, 0x6E6A7C)
        fill(&g, cx - 5, cy - 2, 11, 3, 0xB4B0C0)
        hline(&g, cx - 5, cy - 2, 11, 0xDAD6E2)
        for (dx, dy) in [(-7, 1), (-6, 2), (6, 1), (7, 2), (-4, 3), (4, 3)] { g[cx + dx, cy + dy] = 0xCDEBFA }
        // Taza superior
        ellipse(&g, cx, cy - 12, 10, 4, 0x8E8A9C)
        ellipse(&g, cx, cy - 14, 10, 4, 0xD6D2DE)
        ellipse(&g, cx - 1, cy - 15, 7, 2, 0xE8E4EE)
        ellipse(&g, cx, cy - 14, 7, 2, 0x4A8ED4)
        hline(&g, cx - 4, cy - 15, 4, 0x8CC8F2)
        // Surtidor y chorros
        fill(&g, cx - 1, cy - 21, 3, 7, 0xC6C2D0)
        vline(&g, cx - 1, cy - 21, 7, 0xE6E2EE)
        ellipse(&g, cx, cy - 22, 2, 1, 0xDAD6E2)
        for (dx, dy) in [(0, -25), (0, -24), (-1, -26), (1, -26), (-2, -26), (2, -26), (-3, -25), (3, -25), (-4, -24), (4, -24), (-5, -22), (5, -22), (-6, -20), (6, -20), (-7, -18), (7, -18)] {
            g[cx + dx, cy + dy] = abs(dx) % 3 == 0 ? 0xFFFFFF : 0x9AD8FF
        }
        for side in [-1, 1] {
            let sx = cx + side * 10
            for yy in (cy - 12)...(cy - 1) { g[sx, yy] = (yy % 3 == 0) ? 0xFFFFFF : 0x8CCBF4; if yy % 2 == 0 { g[sx + side, yy] = 0x6AAEE4 } }
            for (dx, dy) in [(-2, 0), (2, 0), (-1, -1), (1, -1), (0, 1)] { g[sx + dx, cy + dy] = 0xDDF2FF }
        }
    }

    // MARK: - Objetos del suelo

    static let objLine: UInt32 = 0x2E2430

    /// Puesto del mercado con toldo a rayas, mostrador y mercancía.
    static func stall(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, width W: Int, kind: Int) {
        let awnings: [(UInt32, UInt32)] = [(0xEDE4CE, 0xC8463C), (0xEDE4CE, 0x3E8A5C), (0xEDE4CE, 0x3E66B4), (0xF2D676, 0xD07A34), (0xEDE4CE, 0x8A4AA0)]
        let (canvasA, canvasB) = awnings[kind % awnings.count]
        // Sombra en el suelo
        tintRect(&g, ox + 4, oy + 21, W - 2, 3, shadowF)
        tintRect(&g, ox + W, oy + 4, 3, 19, shadowF)
        // Postes
        for px in [ox + 1, ox + W - 3] {
            fill(&g, px, oy - 2, 2, 24, 0x7A4A28)
            vline(&g, px, oy - 2, 24, 0xA8703E)
        }
        // Mostrador: tablero claro y frente de tablas
        fill(&g, ox, oy + 11, W, 4, 0xC9935A)
        hline(&g, ox, oy + 11, W, 0xE2B27A)
        fill(&g, ox, oy + 15, W, 7, 0x93603A)
        for px in stride(from: ox + 3, to: ox + W, by: 5) { vline(&g, px, oy + 15, 7, 0x6E4426) }
        hline(&g, ox, oy + 15, W, 0x6E4426)
        hline(&g, ox, oy + 22, W, objLine)
        vline(&g, ox - 1, oy + 11, 12, objLine); vline(&g, ox + W, oy + 11, 12, objLine)
        // Mercancía en cestas
        let goodsKind = (kind >> 4) % 6
        var bx = ox + 2
        var i = 0
        while bx + 9 <= ox + W - 1 {
            basket(&g, bx, oy + 8, goods: (goodsKind + i) % 6, seed: kind + i)
            bx += 11; i += 1
        }
        // Toldo: faldón inclinado con rayas y volante festoneado
        for py in (oy - 9)...(oy + 3) {
            let t = py - (oy - 9)
            let inset = max(0, 3 - t / 2)
            for px in (ox - 1 + inset)...(ox + W - inset) {
                let stripe = ((px - ox) / 4) % 2 == 0
                var c = stripe ? canvasA : canvasB
                if t < 2 { c = light(c, 1.06) } else if t > 9 { c = dark(c, 0.86) }
                if px == ox - 1 + inset { c = light(c, 1.04) }
                g[px, py] = c
            }
        }
        for px in (ox - 1)...(ox + W) {
            let stripe = ((px - ox) / 4) % 2 == 0
            let c = dark(stripe ? canvasA : canvasB, 0.92)
            g[px, oy + 4] = c; g[px, oy + 5] = c
            if (px - ox) % 4 != 3 { g[px, oy + 6] = c }
            if (px - ox) % 4 == 1 || (px - ox) % 4 == 2 { g[px, oy + 7] = dark(c, 0.9) }
        }
        hline(&g, ox + 2, oy - 10, W - 4, objLine)
        line(&g, ox - 2, oy - 1, ox + 1, oy - 9, objLine)
        line(&g, ox + W + 1, oy - 1, ox + W - 2, oy - 9, objLine)
        for px in (ox - 1)...(ox + W) where (px - ox) % 4 != 3 { g[px, oy + 8] = (px - ox) % 4 == 1 || (px - ox) % 4 == 2 ? objLine : g[px, oy + 8] }
        vline(&g, ox - 2, oy - 1, 7, objLine); vline(&g, ox + W + 1, oy - 1, 7, objLine)
    }

    /// Cesta (10×6) con frutas, verduras, pan, pescado, cántaros o telas.
    static func basket(_ g: inout PixelGrid, _ x: Int, _ y: Int, goods: Int, seed: Int) {
        // Cesta de mimbre
        fill(&g, x, y + 2, 10, 5, 0xB07A3C)
        for px in x..<(x + 10) where (px + y) % 2 == 0 { g[px, y + 3] = 0x8A5A2A; g[px, y + 5] = 0x8A5A2A }
        hline(&g, x, y + 2, 10, 0xD8A460)
        hline(&g, x, y + 7, 10, objLine)
        vline(&g, x - 1, y + 2, 5, objLine); vline(&g, x + 10, y + 2, 5, objLine)
        switch goods {
        case 0: // manzanas
            for (dx, dy) in [(2, 1), (5, 1), (8, 1), (3, -1), (6, -1), (4, -3)] {
                ball(&g, x + dx, y + dy, 2, 2, [0x8A1E2A, 0xC8343C, 0xE8545A, 0xFFB0A0])
            }
        case 1: // naranjas y peras
            for (dx, dy, c) in [(2, 1, 0), (5, 1, 1), (8, 1, 0), (4, -1, 1), (7, -1, 0)] as [(Int, Int, Int)] {
                ball(&g, x + dx, y + dy, 2, 2, c == 0 ? [0xA8501E, 0xE07A2A, 0xF6A24A, 0xFFE0A0] : [0x6A8A1E, 0x9AB83A, 0xC8DC5A, 0xF0F6B0])
            }
        case 2: // hogazas de pan
            for (dx, dy) in [(1, 0), (5, 0), (3, -2)] {
                ellipse(&g, x + dx + 2, y + dy + 1, 3, 2, 0x8A4E1E)
                ellipse(&g, x + dx + 2, y + dy, 3, 2, 0xD08A40)
                hline(&g, x + dx + 1, y + dy - 1, 3, 0xF0C080)
                g[x + dx + 2, y + dy] = 0x9A5A26
            }
        case 3: // pescado
            for (dx, dy) in [(0, 1), (1, -1)] {
                hline(&g, x + dx + 1, y + dy, 7, 0xB8C4D0)
                hline(&g, x + dx + 1, y + dy + 1, 7, 0x7A8A9E)
                hline(&g, x + dx + 2, y + dy - 1, 4, 0xE6EEF6)
                g[x + dx + 8, y + dy - 1] = 0x7A8A9E; g[x + dx + 8, y + dy + 1] = 0x7A8A9E
                g[x + dx + 2, y + dy] = objLine
            }
        case 4: // coles y zanahorias
            ball(&g, x + 3, y, 3, 2, [0x2E6A2A, 0x4E9A3A, 0x7AC45A, 0xB8E890])
            for i in 0..<3 { line(&g, x + 6 + i, y - 1, x + 7 + i, y + 2, 0xE8782A); g[x + 6 + i, y - 2] = 0x4E9A3A }
        default: // cántaros de barro
            for (dx, c) in [(2, 0xB86A3A), (6, 0x9A7A5A)] as [(Int, UInt32)] {
                ellipse(&g, x + dx, y, 2, 3, c)
                g[x + dx - 1, y - 1] = light(c, 1.25)
                hline(&g, x + dx - 1, y - 4, 3, dark(c, 0.7))
            }
        }
    }

    /// Cajas, barriles, sacos y cestos apilados (varía por casilla).
    static func crates(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, kind: Int) {
        tintRect(&g, ox + 3, oy + 20, 20, 3, shadowF)
        switch kind % 5 {
        case 0:
            crate(&g, ox + 1, oy + 9)
            crate(&g, ox + 3, oy - 1)
            sack(&g, ox + 14, oy + 10, flour: false)
        case 1:
            barrel(&g, ox + 1, oy + 5)
            crate(&g, ox + 11, oy + 9)
        case 2:
            sack(&g, ox + 1, oy + 9, flour: true)
            sack(&g, ox + 10, oy + 10, flour: false)
            sack(&g, ox + 6, oy + 4, flour: true)
        case 3:
            crate(&g, ox + 1, oy + 9)
            basket(&g, ox + 13, oy + 13, goods: kind % 2 == 0 ? 0 : 4, seed: kind)
        default:
            barrel(&g, ox + 1, oy + 5)
            barrel(&g, ox + 12, oy + 6)
        }
    }

    static func crate(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        // Tapa (vista desde arriba) y frente con travesaños en diagonal
        fill(&g, x, y, 12, 13, objLine)
        fill(&g, x + 1, y + 1, 10, 3, 0xD9B07A)
        hline(&g, x + 1, y + 2, 10, 0xC49A64)
        fill(&g, x + 1, y + 4, 10, 8, 0xB88A54)
        fill(&g, x + 1, y + 4, 10, 1, 0x8A6236)
        for i in 0..<8 { g[x + 2 + i, y + 11 - i] = 0x9A6E3E; g[x + 2 + i, y + 10 - i] = 0xD0A470 }
        vline(&g, x + 1, y + 4, 8, 0xD0A470)
        vline(&g, x + 10, y + 4, 8, 0x8A6236)
        for (dx, dy) in [(2, 5), (9, 5), (2, 10), (9, 10)] { g[x + dx, y + dy] = 0x4A4250 }
    }

    static func barrel(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        // Cuerpo con duelas sombreadas, aros de hierro y tapa
        fill(&g, x + 1, y, 9, 17, objLine)
        fill(&g, x, y + 2, 11, 13, objLine)
        let staves: [UInt32] = [0xC88E56, 0xB47A44, 0xA06A3A, 0x8A5A30, 0x744A28]
        for py in (y + 3)..<(y + 15) {
            for px in (x + 1)..<(x + 10) {
                let i = min(4, max(0, (px - x - 1) * 5 / 9))
                g[px, py] = (px - x) % 3 == 0 ? dark(staves[i], 0.88) : staves[i]
            }
        }
        for px in (x + 2)..<(x + 9) { g[px, y + 2] = staves[1]; g[px, y + 15] = staves[3] }
        for hy in [y + 5, y + 12] {
            hline(&g, x + 1, hy, 9, 0x5E5E6E)
            hline(&g, x + 1, hy - 1, 3, 0x9A9AAA)
        }
        // Tapa elíptica
        fill(&g, x + 2, y + 1, 7, 3, 0xD8A86E)
        hline(&g, x + 3, y + 1, 5, 0xE8C08A)
        hline(&g, x + 2, y + 3, 7, 0x8A5A30)
        vline(&g, x + 5, y + 1, 2, 0xB4824A)
    }

    static func sack(_ g: inout PixelGrid, _ x: Int, _ y: Int, flour: Bool) {
        let c: UInt32 = flour ? 0xE6DCC6 : 0xC8A878
        ellipse(&g, x + 5, y + 6, 6, 5, objLine)
        ellipse(&g, x + 5, y + 6, 5, 4, c)
        ellipse(&g, x + 4, y + 5, 3, 2, light(c, 1.08))
        for (dx, dy) in [(7, 8), (8, 7), (6, 9), (8, 9), (9, 8)] { g[x + dx, y + dy] = dark(c, 0.8) }
        fill(&g, x + 3, y - 1, 5, 3, c)
        hline(&g, x + 3, y + 1, 5, 0x8A6A3A)
        hline(&g, x + 3, y - 2, 5, objLine)
        vline(&g, x + 2, y - 1, 3, objLine); vline(&g, x + 8, y - 1, 3, objLine)
        if flour { g[x + 4, y - 1] = 0xFFFFFF; g[x + 5, y - 1] = 0xFFFFFF } else { g[x + 4, y - 1] = 0xE8C84A; g[x + 6, y - 1] = 0xD8B43A }
    }

    /// Arbusto redondo de varias masas de hojas; en la plaza va en una jardinera de piedra.
    static func bush(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, planter: Bool, seed: Int) {
        let leaves: [UInt32] = [0x24603A, 0x2F7A3E, 0x3E9446, 0x58AE52, 0x86CC6A]
        if planter {
            tintRect(&g, ox + 3, oy + 21, 22, 3, shadowF)
            tintRect(&g, ox + 22, oy + 9, 3, 13, shadowF)
            fill(&g, ox + 1, oy + 8, 22, 15, objLine)
            fill(&g, ox + 2, oy + 9, 20, 4, 0xD6D0C0)
            hline(&g, ox + 2, oy + 9, 20, 0xEEE8DA)
            fill(&g, ox + 4, oy + 11, 16, 2, 0x5A3E2A)
            fill(&g, ox + 2, oy + 13, 20, 9, 0xB8AE9A)
            for px in stride(from: ox + 2, to: ox + 22, by: 7) { vline(&g, px, oy + 13, 9, 0x968C78) }
            hline(&g, ox + 2, oy + 13, 20, 0x968C78)
            vline(&g, ox + 21, oy + 13, 9, 0x968C78)
        } else {
            for y in -4...4 { for x in -11...11 where x * x * 16 + y * y * 121 <= 1936 { tint(&g, ox + 14 + x, oy + 20 + y, shadowF) } }
        }
        let base = planter ? oy + 9 : oy + 16
        let clumps: [(Int, Int, Int, Int)] = [(6, -2, 5, 4), (17, -2, 5, 4), (11, -5, 7, 5), (8, -7, 4, 3), (15, -7, 4, 3)]
        for (dx, dy, rx, ry) in clumps { ellipse(&g, ox + dx, base + dy, rx + 1, ry + 1, objLine) }
        for (dx, dy, rx, ry) in clumps { ball(&g, ox + dx, base + dy, rx, ry, leaves, seed: seed, texture: 0.35) }
        // Flores o bayas
        if seed % 3 != 0 {
            let c: UInt32 = [0xF27AA8, 0xF4F0E8, 0xE84A4A, 0xF6D45A][seed % 4]
            for i in 0..<5 {
                let h = hash(seed, i, 7)
                g[ox + 5 + h % 14, base - 9 + (h >> 5) % 8] = c
            }
        }
    }

    /// Valla de madera que se une con sus vecinas.
    static func fence(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, left: Bool, right: Bool, seed: Int) {
        let T = tile
        let x0 = left ? ox : ox + 2, x1 = right ? ox + T : ox + T - 2
        tintRect(&g, x0 + 2, oy + 19, x1 - x0, 2, shadowF)
        for ry in [oy + 9, oy + 14] {
            fill(&g, x0, ry - 1, x1 - x0, 4, objLine)
            fill(&g, x0, ry, x1 - x0, 2, 0xA8703E)
            hline(&g, x0, ry, x1 - x0, 0xC88E56)
        }
        for px in stride(from: ox + 2, to: ox + T, by: 8) {
            fill(&g, px - 1, oy + 3, 5, 17, objLine)
            fill(&g, px, oy + 4, 3, 15, 0x9A6236)
            vline(&g, px, oy + 4, 15, 0xC08048)
            vline(&g, px + 2, oy + 4, 15, 0x6E4426)
            g[px + 1, oy + 3] = 0x9A6236
            if hash(px, oy, seed) % 3 == 0 { g[px + 1, oy + 12] = 0x5A3A22 }
        }
    }
}
