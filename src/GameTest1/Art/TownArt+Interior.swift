import Foundation
import GameCore

/// Interiores del pueblo: suelos de tablones, losas o mármol; pared del fondo en 3/4 con remate,
/// revoco o sillares, zócalo y rodapié; ventanas que dejan manchas de luz en el suelo; cuadros,
/// tapices y apliques; y muebles por edificio (estanterías con objetos, horno con fuego, mesas,
/// bancos de capilla, camas con manta, barriles, calderos, columnas, trono y altar).
extension TownArt {
    /// Ambientación de cada interior.
    struct RoomStyle {
        var floor: [UInt32]          // tablones o losas (de oscuro a claro)
        var stoneFloor: [UInt32]     // losas para las casillas ':'
        var wall: [UInt32]           // revoco o sillares de la pared del fondo
        var wainscot: [UInt32]       // zócalo de madera
        var stoneWall: Bool
        var blanket: [UInt32]
        var marble: Bool
    }

    static func roomStyle(_ id: String) -> RoomStyle {
        let oak: [UInt32] = [0x5A3620, 0x7A4C2C, 0x8E5C36, 0xA26C40]
        let honey: [UInt32] = [0x6E4A26, 0x926434, 0xA8783E, 0xBC8A4A]
        let darkWood: [UInt32] = [0x3E2618, 0x573620, 0x6A4428, 0x7E5232]
        let flags: [UInt32] = [0x5E5A60, 0x7A767E, 0x8C8890, 0x9E9AA2]
        let warmFlags: [UInt32] = [0x6A5E52, 0x857868, 0x978A78, 0xA89C88]
        let creamWall: [UInt32] = [0xB8A07C, 0xD0BC98, 0xE2D2B0, 0xEEE2C6]
        switch id {
        case "bakery":
            return RoomStyle(floor: honey, stoneFloor: warmFlags, wall: creamWall, wainscot: oak, stoneWall: false, blanket: [0x6A2A2A, 0x963C36, 0xB8584A, 0xD8806A], marble: false)
        case "weaver":
            return RoomStyle(floor: oak, stoneFloor: warmFlags, wall: [0xB08C84, 0xC8A69C, 0xDAB8AE, 0xE8CCC2], wainscot: darkWood, stoneWall: false, blanket: [0x2A4A7A, 0x3A62A0, 0x5A84C0, 0x86AADA], marble: false)
        case "mill":
            return RoomStyle(floor: oak, stoneFloor: warmFlags, wall: [0x7A6E62, 0x948878, 0xA89C8A, 0xBAAE9A], wainscot: darkWood, stoneWall: true, blanket: [0x4A6A2A, 0x648A3A, 0x80A84E, 0xA2C46C], marble: false)
        case "chapel":
            return RoomStyle(floor: oak, stoneFloor: flags, wall: [0x8A8694, 0xA4A0AE, 0xBAB6C4, 0xD0CCD8], wainscot: oak, stoneWall: true, blanket: [0x6A2A2A, 0x963C36, 0xB8584A, 0xD8806A], marble: false)
        case "inn":
            return RoomStyle(floor: darkWood, stoneFloor: warmFlags, wall: [0xA8906C, 0xC0A882, 0xD2BC96, 0xE0CCA8], wainscot: oak, stoneWall: false, blanket: [0x2E5A3A, 0x3E784A, 0x56965E, 0x7CB880], marble: false)
        case "alchemist":
            return RoomStyle(floor: [0x4A3040, 0x5E3E50, 0x704C5E, 0x825A6C], stoneFloor: flags, wall: [0x8C7A9C, 0xA492B4, 0xB8A8C6, 0xCABCD6], wainscot: darkWood, stoneWall: false, blanket: [0x4A2A6A, 0x643C8A, 0x8458AA, 0xA67ECA], marble: false)
        case "castle":
            return RoomStyle(floor: oak, stoneFloor: [0x8C8696, 0xA6A0B0, 0xC4BECC, 0xDCD6E2], wall: [0x6E6878, 0x8A8494, 0xA29CAC, 0xB8B2C2], wainscot: [0x4A4456, 0x5E5868, 0x726C7E, 0x88829A], stoneWall: true, blanket: [0x6A2A2A, 0x963C36, 0xB8584A, 0xD8806A], marble: true)
        default:
            return RoomStyle(floor: oak, stoneFloor: flags, wall: creamWall, wainscot: oak, stoneWall: false, blanket: [0x2A4A7A, 0x3A62A0, 0x5A84C0, 0x86AADA], marble: false)
        }
    }

    // MARK: - Composición

    static func interiorGround(_ map: AreaMap) -> PixelGrid {
        let T = tile
        let w = map.width, h = map.height
        var tiles = [Tile](repeating: .interiorWall, count: w * h)
        for y in 0..<h { for x in 0..<w { tiles[y * w + x] = map.tile(x, y) } }
        func at(_ x: Int, _ y: Int) -> Tile { (x < 0 || y < 0 || x >= w || y >= h) ? .interiorWall : tiles[y * w + x] }
        func isWall(_ x: Int, _ y: Int) -> Bool { at(x, y) == .interiorWall }
        let S = roomStyle(map.id)
        var g = PixelGrid(width: w * T, height: h * T)

        // 1. Suelos (bajo los muebles, el suelo que más los rodea)
        func floorKind(_ x: Int, _ y: Int) -> Tile {
            let t = at(x, y)
            switch t {
            case .woodFloor, .stoneFloor, .carpet: return t
            case .exit: return .woodFloor
            case .interiorWall: return .woodFloor
            default:
                var stone = 0, wood = 0
                for (dx, dy) in [(-1, 0), (1, 0), (0, 1), (0, -1), (-1, 1), (1, 1)] {
                    let n = at(x + dx, y + dy)
                    if n == .stoneFloor || n == .carpet || n == .pillar { stone += 1 } else if n == .woodFloor { wood += 1 }
                }
                return stone > wood ? .stoneFloor : .woodFloor
            }
        }
        for y in 0..<h {
            for x in 0..<w where !isWall(x, y) {
                let ox = x * T, oy = y * T
                switch floorKind(x, y) {
                case .stoneFloor:
                    for py in oy..<(oy + T) { for px in ox..<(ox + T) { g.pixels[py * g.width + px] = S.marble ? marbleColor(px, py) : flagColor(px, py, S.stoneFloor) } }
                    if S.marble {
                        // Cenefa de mármol oscuro con filete dorado junto a las paredes
                        for py in oy..<(oy + T) {
                            for px in ox..<(ox + T) {
                                let lx = px - ox, ly = py - oy
                                var d = 99
                                if isWall(x - 1, y) { d = min(d, lx) }
                                if isWall(x + 1, y) { d = min(d, T - 1 - lx) }
                                if isWall(x, y - 1) { d = min(d, ly) }
                                if isWall(x, y + 1) && at(x, y + 1) != .exit { d = min(d, T - 1 - ly) }
                                guard d < 8 else { continue }
                                var c: UInt32 = (px / 6 + py / 6) % 2 == 0 ? 0x5A5470 : 0x625C78
                                if d == 7 { c = 0xC8A040 } else if d == 6 { c = 0x4A4460 } else if d == 0 { c = 0x3E3850 }
                                g.pixels[py * g.width + px] = c
                            }
                        }
                    }
                case .carpet:
                    carpetTile(&g, x, y, left: at(x - 1, y) == .carpet, right: at(x + 1, y) == .carpet, up: at(x, y - 1) == .carpet || at(x, y - 1) == .throne, down: at(x, y + 1) == .carpet)
                default:
                    for py in oy..<(oy + T) { for px in ox..<(ox + T) { g.pixels[py * g.width + px] = plankColor(px, py, S.floor, seed: map.id.count) } }
                }
            }
        }

        // Paja y harina por el suelo del molino
        if map.id == "mill" {
            for i in 0..<(w * h * 3) {
                let px = hash(i, 1, 301) % (w * T), py = hash(i, 2, 301) % (h * T)
                guard !isWall(px / T, py / T) else { continue }
                if i % 3 == 0 { g[px, py] = 0xEEE6D2; g[px + 1, py] = 0xD8D0BC } else { line(&g, px, py, px + 2 + i % 3, py + (i % 2), i % 2 == 0 ? 0xD8B850 : 0xB8963A) }
            }
        }
        // Alfombra tejida en el hueco libre más céntrico (casas con suelo de madera)
        if !S.stoneWall {
            var best: (Int, Int)? = nil, bestD = Int.max
            for y in 2..<max(2, h - 2) {
                for x in 1..<max(1, w - 3) {
                    var free = true
                    for dy in 0..<2 { for dx in 0..<3 where at(x + dx, y + dy) != .woodFloor { free = false } }
                    let d = abs(2 * x + 3 - w) + abs(2 * y + 2 - h)
                    if free && d < bestD { bestD = d; best = (x, y) }
                }
            }
            if let (rx, ry) = best { rug(&g, rx * T + 3, ry * T + 4, 3 * T - 6, 2 * T - 8, colors: S.blanket) }
        }

        // 2. Paredes: cara del fondo (con suelo debajo) o remate visto desde arriba
        var windows: [Int] = []
        var fires: [(Int, Int, Double)] = []
        for y in 0..<h {
            for x in 0..<w where isWall(x, y) {
                if !isWall(x, y + 1) {
                    wallFace(&g, x, y, S, left: isWall(x - 1, y) && !isWall(x - 1, y + 1), right: isWall(x + 1, y) && !isWall(x + 1, y + 1))
                } else {
                    wallTop(&g, x, y, S, inner: (x > 0 && !isWall(x - 1, y), x < w - 1 && !isWall(x + 1, y), y > 0 && !isWall(x, y - 1), false))
                }
            }
        }
        // Decoración de la pared del fondo (donde no hay un mueble alto delante)
        for x in 0..<w where isWall(x, 0) && !isWall(x, 1) {
            let below = at(x, 1)
            guard below != .shelf && below != .oven && below != .throne else { continue }
            let kind = wallDecorKind(map.id, x, w)
            paintWallDecor(&g, x, kind, S, map.id)
            if kind == 1 { windows.append(x) }
            if kind == 3 { fires.append((x * T + T / 2, 8, 30)) }
        }

        // 3. Luces: manchas de sol bajo las ventanas y el resplandor del fuego
        for x in windows { sunPatch(&g, x * T + 4, T, h: h * T) }
        for y in 0..<h {
            for x in 0..<w {
                switch at(x, y) {
                case .oven where at(x - 1, y) != .oven: fires.append(((x + 1) * T, y * T + 18, 56))
                case .throne where at(x - 1, y) == .throne && map.id == "chapel": fires.append((x * T, y * T + 6, 40))
                default: break
                }
            }
        }
        for f in fires { warmGlow(&g, f.0, f.1, radius: f.2) }

        // 4. Sombras: al pie de la pared del fondo y a la derecha de la pared izquierda
        for y in 0..<h {
            for x in 0..<w where !isWall(x, y) {
                let ox = x * T, oy = y * T
                if isWall(x, y - 1) {
                    for i in 0..<5 { for px in ox..<(ox + T) where i < 3 || (px + i) % 2 == 0 { tint(&g, px, oy + i, i == 0 ? (0.62, 0.62, 0.72) : (0.8, 0.8, 0.88)) } }
                }
                if isWall(x - 1, y) {
                    for i in 0..<4 { for py in oy..<(oy + T) where i < 2 || (py + i) % 2 == 0 { tint(&g, ox + i, py, i == 0 ? (0.66, 0.66, 0.76) : (0.82, 0.82, 0.9)) } }
                }
            }
        }

        // 5. Muebles, fila a fila
        for y in 0..<h {
            for x in 0..<w {
                let ox = x * T, oy = y * T
                switch at(x, y) {
                case .exit: doorway(&g, ox, oy, joinLeft: at(x - 1, y) == .exit, joinRight: at(x + 1, y) == .exit)
                case .shelf: shelf(&g, ox, oy, joinLeft: at(x - 1, y) == .shelf, joinRight: at(x + 1, y) == .shelf, room: map.id, seed: x * 31 + y)
                case .oven where at(x - 1, y) != .oven: oven(&g, ox, oy, wide: at(x + 1, y) == .oven)
                case .table:
                    if map.id == "chapel" {
                        pew(&g, ox, oy, joinLeft: at(x - 1, y) == .table, joinRight: at(x + 1, y) == .table)
                    } else {
                        table(&g, ox, oy, joinLeft: at(x - 1, y) == .table, joinRight: at(x + 1, y) == .table, room: map.id, seed: x * 7 + y * 13)
                    }
                case .bed where at(x - 1, y) != .bed && at(x, y - 1) != .bed:
                    bed(&g, ox, oy, wide: at(x + 1, y) == .bed, tall: at(x, y + 1) == .bed, blanket: S.blanket)
                case .barrel:
                    if map.id == "alchemist" { cauldron(&g, ox, oy) } else if map.id == "mill" { sack(&g, ox + 6, oy + 8, flour: (x + y) % 2 == 0); sack(&g, ox + 1, oy + 11, flour: false) } else { tintRect(&g, ox + 7, oy + 19, 14, 3, shadowF); barrel(&g, ox + 6, oy + 3) }
                case .crates: crates(&g, ox, oy, kind: hash(x, y, 77))
                case .pillar: pillar(&g, ox, oy, marble: S.marble)
                case .throne where at(x - 1, y) != .throne:
                    if map.id == "chapel" { altar(&g, ox, oy) } else { throne(&g, ox, oy) }
                default: break
                }
            }
        }
        return g
    }

    // MARK: - Suelos

    /// Tablones horizontales de largo variable, con vetas, nudos y juntas.
    static func plankColor(_ px: Int, _ py: Int, _ tones: [UInt32], seed: Int) -> UInt32 {
        let ph = 6
        let row = py / ph, ly = py % ph
        let len = 42 + (hash(row, 0, seed + 61) % 4) * 8
        let off = hash(row, 1, seed + 62) % len
        let plank = (px + off) / len, lx = (px + off) % len
        let gap = mix(tones[0], tones[1], 0.45)
        if ly == ph - 1 || lx == 0 { return gap }
        let h = hash(plank, row, seed + 63)
        var c = mix(tones[1], tones[3], Double(h % 100) / 100 * 0.45 + 0.3)
        if ly == 0 { c = mix(c, tones[3], 0.25) } else if ly == ph - 2 { c = mix(c, tones[1], 0.3) }
        // Vetas suaves
        let grain = noise(Double(px) / 9 + Double(plank) * 3.1, Double(py) / 1.4, seed + 64)
        if grain > 0.72 { c = mix(c, tones[1], 0.35) } else if grain < 0.16 { c = mix(c, tones[3], 0.15) }
        // Nudo
        if h % 9 == 0 {
            let kx = (h >> 4) % max(1, len - 8) + 4
            let dx = lx - kx, dy = ly - 2
            if dx * dx / 3 + dy * dy <= 1 { c = mix(c, tones[0], 0.4) }
        }
        // Clavos en las juntas
        if (lx == 2 || lx == len - 2) && ly == 2 { c = mix(c, 0x2A2A30, 0.35) }
        return c
    }

    /// Losas irregulares en hiladas, con bisel claro arriba-izquierda, grietas y desgaste.
    static func flagColor(_ px: Int, _ py: Int, _ tones: [UInt32]) -> UInt32 {
        let rh = [11, 9, 12][(py / 32) % 3]
        let row = py / rh, ly = py % rh
        let rw = 14 + hash(row, 0, 81) % 6
        let off = hash(row, 1, 82) % rw
        let col = (px + off) / rw, lx = (px + off) % rw
        if ly == 0 || lx == 0 { return mix(tones[0], tones[1], 0.4) }
        let h = hash(col, row, 83)
        var c = mix(tones[1], tones[3], Double(h % 100) / 100 * 0.45 + 0.3)
        if ly == 1 || lx == 1 { c = mix(c, tones[3], 0.35) } else if ly == rh - 1 || lx == rw - 1 { c = mix(c, tones[1], 0.4) }
        if h % 6 == 0 && lx == 3 + ly / 2 && ly > 1 && ly < rh - 1 { c = mix(c, tones[0], 0.6) }
        if noise(Double(px) / 6, Double(py) / 5, 84) > 0.72 { c = mix(c, tones[0], 0.15) }
        if hash(px, py, 85) % 23 == 0 { c = mix(c, tones[0], 0.2) }
        return c
    }

    /// Mármol del salón del trono: ajedrezado de losas claras y grises con vetas y brillo.
    static func marbleColor(_ px: Int, _ py: Int) -> UInt32 {
        let s = 12
        let cx = px / s, cy = py / s, lx = px % s, ly = py % s
        let lightTile = (cx + cy) % 2 == 0
        let tones: [UInt32] = lightTile ? [0xB0A8B8, 0xC0B8C8, 0xCCC4D2, 0xDAD4E0] : [0x8E86A0, 0x9C94AE, 0xA8A0BA, 0xB6AEC6]
        if lx == 0 || ly == 0 { return 0x8A8298 }
        var c = tones[2]
        let v = noise(Double(px) / 7 + Double(py) / 11, Double(py) / 4, 91)
        if abs(v - 0.5) < 0.025 { c = tones[1] }
        if lx + ly < 4 && lx > 0 { c = tones[3] }                  // brillo pulido
        if lx == s - 1 || ly == s - 1 { c = tones[1] }
        return c
    }

    /// Alfombra roja con cenefa dorada, rombos y flecos en los extremos.
    private static func carpetTile(_ g: inout PixelGrid, _ x: Int, _ y: Int, left: Bool, right: Bool, up: Bool, down: Bool) {
        let T = tile, ox = x * T, oy = y * T
        let red: [UInt32] = [0x5A1018, 0x7A1A24, 0x962430, 0xAE3440]
        let goldT: [UInt32] = [0x8A6020, 0xC08A30, 0xE8B848]
        for ly in 0..<T {
            for lx in 0..<T {
                let px = ox + lx, py = oy + ly
                var c = red[2]
                let dl = left ? 99 : lx, dr = right ? 99 : T - 1 - lx
                let du = up ? 99 : ly, dd = down ? 99 : T - 1 - ly
                let d = min(dl, dr, du, dd)
                if d == 0 { c = red[0] } else if d == 1 || d == 4 { c = goldT[1] } else if d == 2 || d == 3 { c = red[1] }
                else {
                    // Rombos centrados en el ancho de la alfombra
                    let mx = ((px % 12) + 12) % 12 - 6, my = ((py % 12) + 12) % 12 - 6
                    let r = abs(mx) + abs(my)
                    if r == 4 { c = goldT[0] } else if r < 2 { c = goldT[2] } else if r < 4 { c = red[1] }
                    if hash(px, py, 95) % 9 == 0 { c = mix(c, red[3], 0.5) }
                }
                if d == 1 && (lx + ly) % 2 == 0 { c = goldT[2] }
                g[px, py] = c
                // Flecos sueltos fuera del borde
                if !up && ly == 0 && lx % 2 == 0 && lx > 1 && lx < T - 2 { g[px, py] = 0xE6D6B0 }
                if !down && ly == T - 1 && lx % 2 == 0 && lx > 1 && lx < T - 2 { g[px, py] = 0xE6D6B0 }
            }
        }
    }

    /// Alfombra tejida rectangular con cenefa, motivo central de rombos y flecos.
    private static func rug(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, colors: [UInt32]) {
        let cream: UInt32 = 0xE6D6B0
        for yy in 0..<h {
            for xx in 0..<w {
                let d = min(xx, yy, w - 1 - xx, h - 1 - yy)
                var c: UInt32
                switch d {
                case 0: c = colors[0]
                case 1, 4: c = cream
                case 2, 3: c = (xx + yy) % 4 < 2 ? colors[2] : colors[1]
                default:
                    let mx = abs(xx - w / 2), my = abs(yy - h / 2)
                    let r = mx * h / max(1, w) + my
                    c = colors[1]
                    if (mx + my) % 6 == 0 { c = colors[0] }
                    if r < h / 2 - 3 { c = (mx + my) % 4 < 2 ? colors[3] : colors[2] }
                    if r < 3 { c = cream }
                }
                g[x + xx, y + yy] = c
            }
        }
        for xx in stride(from: 1, to: w - 1, by: 2) { g[x + xx, y - 1] = cream; g[x + xx, y + h] = cream }
        tintRect(&g, x + 1, y + h + 1, w, 1, shadowF)
    }

    // MARK: - Paredes

    /// Pared del fondo en 3/4: remate oscuro arriba, pared (revoco o sillares), zócalo y rodapié.
    private static func wallFace(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ S: RoomStyle, left: Bool, right: Bool) {
        let T = tile, ox = x * T, oy = y * T
        for ly in 0..<T {
            for lx in 0..<T {
                let px = ox + lx, py = oy + ly
                var c: UInt32
                if ly < 3 {
                    // Remate (visto desde arriba)
                    c = ly == 2 ? 0x2A1E1C : (ly == 0 ? 0x3E302C : 0x4E3E38)
                } else if ly < 17 {
                    if S.stoneWall {
                        c = ashlarColor(px, py + 3, tones: S.wall, seed: 31)
                    } else {
                        let n = noise(Double(px) / 5, Double(py) / 4, 33)
                        c = tone(S.wall, 0.72 + (n - 0.5) * 0.3 - (ly < 5 ? 0.22 : 0), px, py, dither: 0.25)
                    }
                    if ly == 3 { c = mix(c, 0x1A1418, 0.45) }          // sombra del remate
                } else if ly == 17 {
                    c = S.wainscot[3]                                   // moldura
                } else if ly < T - 2 {
                    // Zócalo de paneles
                    let k = (px % 12)
                    c = S.wainscot[2]
                    if k == 0 { c = S.wainscot[0] } else if k == 1 || ly == 18 { c = S.wainscot[3] } else if k == 11 || ly == T - 3 { c = S.wainscot[1] }
                } else {
                    c = ly == T - 2 ? S.wainscot[1] : S.wainscot[0]     // rodapié
                }
                g[px, py] = c
            }
        }
        // Esquinas: el muro lateral asoma como una franja oscura
        if !left && x > 0 { fill(&g, ox, oy, 3, T, 0x3A2E2A); vline(&g, ox + 2, oy + 4, T - 4, 0x5A4A44) }
        if !right { fill(&g, ox + T - 3, oy, 3, T, 0x2E2422); vline(&g, ox + T - 3, oy + 4, T - 4, 0x4A3C36) }
    }

    /// Remate de muro visto desde arriba, con canto claro hacia la habitación.
    private static func wallTop(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ S: RoomStyle, inner: (Bool, Bool, Bool, Bool)) {
        let T = tile, ox = x * T, oy = y * T
        for ly in 0..<T {
            for lx in 0..<T {
                let px = ox + lx, py = oy + ly
                let n = hash(px / 6, py / 6, 41) % 3
                var c: UInt32 = [0x3A2E2A, 0x40322E, 0x362A26][n]
                if (px % 6 == 0) || (py % 6 == 0) { c = 0x2E2420 }
                if inner.0 && lx < 2 { c = lx == 0 ? 0x6A5A50 : 0x54463E }
                if inner.1 && lx > T - 3 { c = lx == T - 1 ? 0x6A5A50 : 0x54463E }
                if inner.2 && ly < 2 { c = ly == 0 ? 0x6A5A50 : 0x54463E }
                if inner.3 && ly > T - 3 { c = 0x22181A }
                g[px, py] = c
            }
        }
    }

    /// Qué cuelga en cada tramo de la pared del fondo (`wallDecorKind`): 0 nada, 1 ventana, 2 cuadro,
    /// 3 aplique, 4 tapiz o estandarte, 5 objeto del oficio.
    private static func paintWallDecor(_ g: inout PixelGrid, _ x: Int, _ kind: Int, _ S: RoomStyle, _ room: String) {
        let T = tile, ox = x * T, oy = 0
        switch kind {
        case 1:
            if room == "chapel" || room == "castle" {
                // Ventanal en arco con vidriera
                for ly in 4..<15 {
                    for lx in 7..<17 {
                        let dx = Double(lx) - 11.5, dy = Double(ly) - 8
                        guard ly >= 8 || dx * dx + dy * dy <= 20 else { continue }
                        let edge = lx == 7 || lx == 16 || (ly < 8 && dx * dx + dy * dy > 13)
                        let glass: [UInt32] = room == "chapel" ? [0x3E7AD8, 0xD8483C, 0xF2C440, 0x4EB060] : [0x8AC0E6, 0xB8DCF2, 0x6A9ACA, 0xD8ECF8]
                        var c = edge ? 0x4A4656 : glass[((lx / 2) + (ly / 3)) % 4]
                        if !edge && (lx == 11 || lx == 12 || ly == 10) { c = 0x4A4656 }
                        g[ox + lx, oy + ly] = c
                    }
                }
                hline(&g, ox + 6, oy + 15, 12, S.wall[3])
            } else {
                // Ventana con cortinas y alféizar
                fill(&g, ox + 5, oy + 5, 14, 10, S.wainscot[0])
                for ly in 6..<14 { for lx in 6..<18 { g[ox + lx, oy + ly] = tone([0xF2F8FF, 0xB8DCF2, 0x84B8E0, 0x6A9ACA], Double(lx - 6 + ly - 6) / 18, ox + lx, oy + ly) } }
                vline(&g, ox + 11, oy + 6, 8, S.wainscot[1]); vline(&g, ox + 12, oy + 6, 8, S.wainscot[0]); hline(&g, ox + 6, oy + 9, 12, S.wainscot[1])
                for ly in 5..<15 { g[ox + 5, oy + ly] = 0xC8463C; g[ox + 6, oy + ly] = ly < 9 ? 0xE0604E : 0xC8463C; g[ox + 18, oy + ly] = 0xA03430; g[ox + 17, oy + ly] = ly < 9 ? 0xC8463C : 0xA03430 }
                hline(&g, ox + 4, oy + 4, 16, S.wainscot[0])
                hline(&g, ox + 4, oy + 14, 16, S.wainscot[3])
                g[ox + 8, oy + 13] = 0xE84A6A; g[ox + 9, oy + 13] = 0x4E9A3A; g[ox + 10, oy + 13] = 0xF6C83A
            }
        case 2:
            // Cuadro con marco dorado (paisaje o retrato)
            let gx = ox + 5 + hash(x, 3, 52) % 3
            fill(&g, gx, oy + 5, 13, 9, 0x8A6020)
            hline(&g, gx, oy + 5, 13, 0xE8B848); vline(&g, gx, oy + 5, 9, 0xE8B848)
            let portrait = hash(x, 4, 53) % 2 == 0
            for ly in 1..<8 {
                for lx in 1..<12 {
                    var c: UInt32
                    if portrait {
                        c = 0x3A2A3A
                        let dx = lx - 6, dy = ly - 3
                        if dx * dx + dy * dy <= 4 { c = 0xE8B890 } else if ly > 5 && abs(dx) < 4 { c = 0x7A2A3A }
                    } else {
                        c = ly < 4 ? 0x8AC0E6 : (ly < 6 ? 0x4E8A4A : 0x3A6A3A)
                        if ly == 3 && lx > 6 && lx < 10 { c = 0x7A8A9A }
                        if ly == 2 && lx == 3 { c = 0xFFF0A0 }
                    }
                    g[gx + lx, oy + 5 + ly] = c
                }
            }
            tintRect(&g, gx + 13, oy + 6, 1, 9, (0.7, 0.7, 0.8))
        case 3:
            // Aplique de hierro con vela encendida
            fill(&g, ox + 11, oy + 9, 3, 4, 0x2C2C36); hline(&g, ox + 9, oy + 9, 7, 0x4A4A58)
            fill(&g, ox + 11, oy + 6, 2, 3, 0xF0E6D0)
            g[ox + 11, oy + 5] = 0xFFD050; g[ox + 11, oy + 4] = 0xFFF6C8; g[ox + 12, oy + 5] = 0xF07A20
            for yy in -6...8 { for xx in -8...8 where xx * xx + yy * yy < 64 && xx * xx + yy * yy > 3 { tint(&g, ox + 11 + xx, oy + 6 + yy, (1.1, 1.04, 0.9)) } }
        case 4:
            // Estandarte del reino (castillo) o tapiz
            let bx = ox + 6
            hline(&g, bx - 1, oy + 4, 14, 0xB0802A)
            for ly in 5..<22 {
                for lx in 0..<12 {
                    if ly > 18 && abs(lx - 6) < ly - 18 { continue }
                    var c: UInt32 = room == "castle" ? 0x2A56A4 : 0x7A2A3A
                    if lx < 2 { c = light(c, 1.2) } else if lx > 9 { c = dark(c, 0.75) }
                    if lx == 0 || lx == 11 { c = 0xE0B040 }
                    g[bx + lx, oy + ly] = c
                }
            }
            fill(&g, bx + 4, oy + 9, 4, 3, 0xE0B040); g[bx + 5, oy + 8] = 0xFFE07A; g[bx + 4, oy + 8] = 0xE0B040; g[bx + 7, oy + 8] = 0xE0B040
            fill(&g, bx + 3, oy + 13, 6, 2, 0xD8D8E0); fill(&g, bx + 4, oy + 15, 4, 1, 0xA8A8B4)
        case 5:
            craftDecor(&g, ox, oy, room)
        default:
            break
        }
    }

    /// Objeto del oficio colgado en la pared.
    private static func craftDecor(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ room: String) {
        switch room {
        case "bakery":
            // Sartenes y cucharones colgados
            hline(&g, ox + 3, oy + 5, 18, 0x4A2E1A)
            ellipse(&g, ox + 7, oy + 11, 3, 3, 0x2C2C36); ellipse(&g, ox + 7, oy + 11, 2, 2, 0x4A4A58); vline(&g, ox + 7, oy + 6, 3, 0x6A4026)
            vline(&g, ox + 14, oy + 6, 7, 0x8A5A34); ellipse(&g, ox + 14, oy + 13, 2, 1, 0x8A5A34)
            ellipse(&g, ox + 19, oy + 10, 2, 3, 0xB0603A); g[ox + 18, oy + 9] = 0xD0804A
        case "weaver":
            // Madejas de lana de colores
            hline(&g, ox + 3, oy + 5, 18, 0x4A2E1A)
            for (i, c) in [0xD84A6A, 0x3E7AD8, 0xF2C440, 0x4EB060].enumerated() {
                let cc = UInt32(c)
                fill(&g, ox + 4 + i * 4, oy + 6, 3, 7, cc); vline(&g, ox + 4 + i * 4, oy + 6, 7, light(cc, 1.2)); g[ox + 5 + i * 4, oy + 13] = dark(cc, 0.7)
            }
        case "inn":
            // Cabeza de jabalí disecada sobre una placa
            ellipse(&g, ox + 12, oy + 9, 7, 5, 0x6A4026); hline(&g, ox + 6, oy + 5, 13, 0x8A5A34)
            ellipse(&g, ox + 12, oy + 10, 4, 3, 0x4A3024); ellipse(&g, ox + 12, oy + 12, 2, 1, 0x7A5A4A)
            g[ox + 10, oy + 9] = 0xFFD050; g[ox + 14, oy + 9] = 0xFFD050
            g[ox + 9, oy + 13] = 0xF0E6D0; g[ox + 15, oy + 13] = 0xF0E6D0; g[ox + 8, oy + 12] = 0xF0E6D0; g[ox + 16, oy + 12] = 0xF0E6D0
            g[ox + 8, oy + 6] = 0x3A2418; g[ox + 16, oy + 6] = 0x3A2418
        case "alchemist":
            // Carta celeste
            fill(&g, ox + 4, oy + 5, 16, 10, 0x1E2A4A); hline(&g, ox + 4, oy + 5, 16, 0xC8B488); hline(&g, ox + 4, oy + 14, 16, 0xC8B488)
            for i in 0..<7 { g[ox + 5 + hash(i, 1, 54) % 14, oy + 6 + hash(i, 2, 54) % 8] = 0xFFF0A0 }
            ellipse(&g, ox + 14, oy + 9, 2, 2, 0xE8E0C0); g[ox + 15, oy + 8] = 0x1E2A4A
        case "mill":
            // Hoz y rastrillo
            line(&g, ox + 5, oy + 14, ox + 9, oy + 5, 0x8A5A34); line(&g, ox + 9, oy + 5, ox + 13, oy + 7, 0xB8B8C4); g[ox + 13, oy + 8] = 0xB8B8C4
            vline(&g, ox + 17, oy + 5, 10, 0x8A5A34); hline(&g, ox + 14, oy + 5, 7, 0x6A6A78); for i in 0..<4 { g[ox + 14 + i * 2, oy + 6] = 0x6A6A78 }
        default:
            // Escudo cruzado con espadas
            line(&g, ox + 6, oy + 5, ox + 18, oy + 14, 0xC8C8D2); line(&g, ox + 18, oy + 5, ox + 6, oy + 14, 0xC8C8D2)
            fill(&g, ox + 9, oy + 6, 7, 6, 0x8A2A2A); fill(&g, ox + 10, oy + 12, 5, 2, 0x8A2A2A); hline(&g, ox + 9, oy + 6, 7, 0xE0B040)
        }
    }

    // MARK: - Luces

    /// Mancha de luz que entra por una ventana del fondo y cae hacia abajo a la derecha.
    private static func sunPatch(_ g: inout PixelGrid, _ x: Int, _ y: Int, h: Int) {
        for i in 0..<34 {
            let yy = y + 2 + i
            guard yy < h else { break }
            let shift = i / 3
            let fade = 1 - Double(i) / 40
            for xx in (x + shift)..<(x + 16 + shift) where (i < 26 || (xx + yy) % 2 == 0) {
                let k = 1 + 0.26 * fade
                tint(&g, xx, yy, (k * 1.04, k * 1.02, k * 0.94))
            }
        }
    }

    /// Resplandor cálido del fuego (más fuerte cerca, tramado al borde).
    private static func warmGlow(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, radius: Double) {
        let r = Int(radius)
        for y in -r...r {
            for x in -r...r {
                let d = Double(x * x + y * y * 2).squareRoot() / radius
                guard d < 1 else { continue }
                let k = (1 - d) * 0.3
                if d > 0.75 && (x + y) % 2 != 0 { continue }
                tint(&g, cx + x, cy + y, (1 + k * 1.1, 1 + k * 0.55, 1 - k * 0.2))
            }
        }
    }

    // MARK: - Muebles

    static let woodTones: [UInt32] = [0x3A2416, 0x5A3820, 0x74492A, 0x8E5C36, 0xAA7444]

    /// Estantería alta apoyada en la pared del fondo, con objetos según el oficio.
    private static func shelf(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, joinLeft: Bool, joinRight: Bool, room: String, seed: Int) {
        let T = tile
        let top = oy - 14, bottom = oy + 20
        let x0 = ox + (joinLeft ? 0 : 1), x1 = ox + T - (joinRight ? 0 : 1)
        tintRect(&g, x0 + 2, bottom, x1 - x0, 3, shadowF)
        // Fondo y laterales
        fill(&g, x0, top, x1 - x0, bottom - top, woodTones[0])
        fill(&g, x0, top + 2, x1 - x0, bottom - top - 2, 0x2A1A12)
        if !joinLeft { fill(&g, x0, top, 2, bottom - top, woodTones[3]); vline(&g, x0, top, bottom - top, woodTones[4]) }
        if !joinRight { fill(&g, x1 - 2, top, 2, bottom - top, woodTones[2]); vline(&g, x1 - 1, top, bottom - top, woodTones[1]) }
        if joinRight { vline(&g, x1 - 1, top, bottom - top, woodTones[1]); vline(&g, x1 - 2, top, bottom - top, woodTones[3]) }
        // Cornisa
        fill(&g, x0 - (joinLeft ? 0 : 1), top - 2, x1 - x0 + (joinLeft ? 0 : 1) + (joinRight ? 0 : 1), 3, woodTones[3])
        hline(&g, x0 - (joinLeft ? 0 : 1), top - 2, x1 - x0 + (joinLeft ? 0 : 1) + (joinRight ? 0 : 1), woodTones[4])
        // Baldas con objetos
        let boards = [top + 10, top + 21, bottom - 2]
        var rng = SeededGenerator(seed: UInt64(seed * 97 + room.count))
        for (bi, by) in boards.enumerated() {
            fill(&g, x0 + 1, by, x1 - x0 - 2, 2, woodTones[3]); hline(&g, x0 + 1, by, x1 - x0 - 2, woodTones[4])
            var ix = x0 + 3
            while ix < x1 - 4 {
                let w = shelfItem(&g, ix, by, room: room, kind: Int.random(in: 0..<8, using: &rng), level: bi)
                ix += w + Int.random(in: 0...1, using: &rng)
            }
            tintRect(&g, x0 + 2, by + 2, x1 - x0 - 4, 1, (0.6, 0.6, 0.7))
        }
    }

    /// Dibuja un objeto apoyado en `y` y devuelve su ancho.
    private static func shelfItem(_ g: inout PixelGrid, _ x: Int, _ y: Int, room: String, kind: Int, level: Int) -> Int {
        func bottle(_ c: UInt32, tall: Int) -> Int {
            fill(&g, x, y - tall, 3, tall, c); g[x, y - tall] = light(c, 1.4); vline(&g, x + 2, y - tall, tall, dark(c, 0.7))
            fill(&g, x + 1, y - tall - 2, 1, 2, 0xC8B488)
            return 3
        }
        func book(_ c: UInt32, tall: Int) -> Int {
            fill(&g, x, y - tall, 2, tall, c); vline(&g, x, y - tall, tall, light(c, 1.25)); g[x + 1, y - tall + 2] = 0xE0B040
            return 2
        }
        switch room {
        case "bakery":
            switch kind % 4 {
            case 0: ellipse(&g, x + 3, y - 2, 3, 2, 0x8A4E1E); ellipse(&g, x + 3, y - 3, 3, 2, 0xD08A40); hline(&g, x + 2, y - 4, 2, 0xF0C080); return 7
            case 1: fill(&g, x, y - 6, 5, 6, 0xC8A878); hline(&g, x, y - 6, 5, 0x8A6A3A); g[x + 1, y - 4] = 0xE6DCC6; return 5
            case 2: fill(&g, x, y - 5, 4, 5, 0xB86A3A); hline(&g, x, y - 6, 4, 0x8A4A2A); g[x, y - 4] = 0xD8885A; return 4
            default: ellipse(&g, x + 2, y - 2, 2, 2, 0xE8C080); g[x + 1, y - 3] = 0xFFE0B0; return 5
            }
        case "weaver":
            let colors: [UInt32] = [0xD84A6A, 0x3E7AD8, 0xF2C440, 0x4EB060, 0x9A58C8, 0xE8E0D0, 0xE87A3A, 0x2E8A8A]
            let c = colors[kind]
            if kind % 3 == 0 { ellipse(&g, x + 2, y - 2, 2, 2, c); g[x + 1, y - 3] = light(c, 1.3); return 5 }
            fill(&g, x, y - 7, 4, 7, c); vline(&g, x, y - 7, 7, light(c, 1.25)); vline(&g, x + 3, y - 7, 7, dark(c, 0.7)); hline(&g, x, y - 4, 4, dark(c, 0.85)); return 4
        case "alchemist":
            let colors: [UInt32] = [0x7A3ACA, 0x3EC86A, 0xE8483C, 0x3E9AE8, 0xF2C440, 0xE87AB0]
            if kind == 7 { ellipse(&g, x + 2, y - 3, 2, 3, 0xE8E0C8); g[x + 1, y - 3] = 0x2A2A30; g[x + 3, y - 3] = 0x2A2A30; return 5 }
            if kind == 6 { _ = book(0x6A3A2A, tall: 7); return book(0x2A4A6A, tall: 6) + 2 }
            let c = colors[kind % colors.count]
            if kind % 2 == 0 {
                ellipse(&g, x + 2, y - 2, 2, 2, c); g[x + 1, y - 3] = 0xFFFFFF; fill(&g, x + 2, y - 6, 1, 3, 0xD8E8F0); return 5
            }
            return bottle(c, tall: 5 + kind % 3)
        case "inn":
            switch kind % 4 {
            case 0: return bottle([0x3E7A3A, 0x7A2A2A, 0x8A6A2A][level % 3], tall: 6)
            case 1: fill(&g, x, y - 5, 4, 5, 0xB0B0BC); hline(&g, x, y - 5, 4, 0xF4F4F4); vline(&g, x + 4, y - 4, 2, 0xB0B0BC); return 5
            case 2: ellipse(&g, x + 3, y - 4, 3, 3, 0xE0D8C8); ellipse(&g, x + 3, y - 4, 1, 1, 0xC0B8A8); return 6
            default: return bottle(0x5A3A2A, tall: 5)
            }
        case "mill":
            if kind % 2 == 0 { fill(&g, x, y - 6, 5, 6, 0xC8A878); hline(&g, x, y - 6, 5, 0x8A6A3A); return 5 }
            fill(&g, x, y - 5, 4, 5, 0xE6DCC6); hline(&g, x, y - 6, 4, 0xB8A888); return 4
        default:
            let colors: [UInt32] = [0x8A2A2A, 0x2A4A8A, 0x3A6A3A, 0x6A4A2A, 0x5A2A6A]
            return book(colors[kind % colors.count], tall: 6 + kind % 3) + (kind % 3 == 0 ? 1 : 0)
        }
    }

    /// Horno de ladrillo con boca encendida y campana de humos (ocupa una o dos casillas).
    private static func oven(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, wide: Bool) {
        let w = wide ? 46 : 22
        let x0 = ox + 1, cx = x0 + w / 2
        let top = oy - 12, bottom = oy + 21
        tintRect(&g, x0 + 3, bottom, w, 3, shadowF)
        // Campana y chimenea que sube por la pared
        fill(&g, cx - 7, oy - 24, 14, 14, 0x7A3E2E)
        for yy in stride(from: oy - 24, to: oy - 10, by: 3) { hline(&g, cx - 7, yy, 14, 0x5A2A20) }
        vline(&g, cx - 7, oy - 24, 14, 0xA05A44)
        // Cuerpo de ladrillo con cúpula
        for yy in top..<bottom {
            for xx in x0..<(x0 + w) {
                let dy = Double(yy - (top + 10)), dx = Double(xx - cx) / Double(w) * 2
                guard yy >= top + 10 || dx * dx + (dy / 10) * (dy / 10) <= 1 else { continue }
                let row = (yy - top) / 4, ly = (yy - top) % 4
                let lx = (xx - x0 + (row % 2) * 4) % 8
                var c: UInt32 = [0xA0503A, 0xB05C42, 0x96482E][hash((xx - x0 + (row % 2) * 4) / 8, row, 71) % 3]
                if ly == 3 || lx == 0 { c = 0x6A3022 }
                if xx < x0 + 3 { c = light(c, 1.1) } else if xx > x0 + w - 4 { c = dark(c, 0.75) }
                g[xx, yy] = c
            }
        }
        // Boca con fuego
        let mw = wide ? 18 : 12
        for yy in (oy + 2)..<(oy + 16) {
            for xx in (cx - mw / 2)..<(cx + mw / 2) {
                let dx = Double(xx - cx) + 0.5, dy = Double(yy - (oy + 2 + mw / 2))
                guard yy >= oy + 2 + mw / 2 || dx * dx + dy * dy <= Double(mw * mw) / 4 else { continue }
                let t = Double(yy - (oy + 2)) / 14
                var c = tone([0x1A0E0A, 0x5A1A0E, 0xC8401A, 0xF89A30, 0xFFE070], t * 1.1 + (bayer(xx, yy) - 0.5) * 0.35 - abs(dx) / Double(mw) * 0.6, xx, yy)
                if yy > oy + 12 && (xx + yy) % 3 == 0 { c = 0xFFF0A0 }
                g[xx, yy] = c
            }
        }
        // Arco de la boca, repisa y leña
        for xx in (cx - mw / 2 - 1)...(cx + mw / 2) { g[xx, oy + 16] = 0xD8C8B0; g[xx, oy + 17] = 0x8A7A68 }
        for (i, c) in [0x6A4026, 0x8A5A34, 0x5A3420].enumerated() {
            let lx = x0 + w - 10 + (i % 2) * 3
            fill(&g, lx, bottom - 4 - i * 2, 8, 2, UInt32(c)); g[lx, bottom - 4 - i * 2] = 0xC8A070
        }
        // Pala de panadero apoyada
        line(&g, x0 + 2, bottom - 1, x0 + 6, top + 12, 0x8A5A34)
        ellipse(&g, x0 + 7, top + 10, 2, 3, 0xA87444)
    }

    /// Mesa de madera con mantel en la posada, tablero con vetas y cosas encima.
    private static func table(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, joinLeft: Bool, joinRight: Bool, room: String, seed: Int) {
        let T = tile
        let x0 = ox + (joinLeft ? 0 : 2), x1 = ox + T - (joinRight ? 0 : 2)
        let top = oy + 3
        tintRect(&g, x0 + 3, oy + 18, x1 - x0, 4, shadowF)
        // Patas
        if !joinLeft { fill(&g, x0 + 1, top + 10, 3, 9, woodTones[1]); vline(&g, x0 + 1, top + 10, 9, woodTones[3]) }
        if !joinRight { fill(&g, x1 - 4, top + 10, 3, 9, woodTones[0]) }
        // Faldón y tablero
        fill(&g, x0, top + 8, x1 - x0, 3, woodTones[1]); hline(&g, x0, top + 10, x1 - x0, woodTones[0])
        for yy in (top - 3)..<(top + 8) {
            for xx in x0..<x1 {
                var c = mix(woodTones[3], woodTones[4], yy == top - 3 ? 0.75 : 0.3)
                if (yy - top + 3) % 4 == 3 { c = mix(woodTones[2], woodTones[3], 0.4) }
                if noise(Double(xx) / 6, Double(yy) / 1.5, 72) > 0.72 { c = mix(c, woodTones[2], 0.4) }
                if yy == top + 7 { c = woodTones[2] }
                g[xx, yy] = c
            }
        }
        if !joinLeft { vline(&g, x0, top - 3, 14, woodTones[4]) }
        if !joinRight { vline(&g, x1 - 1, top - 3, 14, woodTones[1]) }
        // Objetos
        let h = hash(seed, room.count, 73)
        let mx = ox + 5 + h % 6
        switch room {
        case "inn":
            // Jarras de cerveza y un plato con comida
            for (i, dx) in [0, 9].enumerated() where (h >> (i + 3)) % 3 != 0 {
                fill(&g, mx + dx, top - 2, 4, 5, 0xB07A3A); hline(&g, mx + dx, top - 3, 4, 0xF8F4E8); vline(&g, mx + dx + 4, top - 1, 2, 0x8A5A2A)
                vline(&g, mx + dx, top - 2, 5, 0xD8A050)
            }
            if h % 2 == 0 {
                ellipse(&g, mx + 6, top + 4, 4, 2, 0xB8B0A4); ellipse(&g, mx + 6, top + 3, 4, 2, 0xF0ECE4)
                ellipse(&g, mx + 6, top + 3, 2, 1, 0xA85A2A); g[mx + 5, top + 2] = 0xD88A4A; g[mx + 8, top + 3] = 0x5A9A3A
            }
        case "bakery":
            ellipse(&g, mx + 4, top + 3, 4, 2, 0xF0E0C0); g[mx + 3, top + 2] = 0xFFF8E8
            if h % 2 == 0 { hline(&g, mx + 9, top + 5, 7, 0xC89A60); g[mx + 9, top + 5] = 0x8A5A34; g[mx + 15, top + 5] = 0x8A5A34 }
            ellipse(&g, mx + 11, top + 2, 3, 2, 0xD08A40)
        case "weaver":
            fill(&g, mx, top + 1, 10, 5, [0xD84A6A, 0x3E7AD8, 0x4EB060][h % 3]); hline(&g, mx, top + 1, 10, 0xF4E8E0)
            line(&g, mx + 11, top + 2, mx + 14, top + 5, 0xB8B8C4); line(&g, mx + 14, top + 2, mx + 11, top + 5, 0xB8B8C4)
        case "alchemist":
            // Alambique, matraz burbujeante y libro abierto
            ellipse(&g, mx + 3, top + 1, 3, 3, 0xD8E8F0); ellipse(&g, mx + 3, top + 2, 2, 1, [0x3EC86A, 0x7A3ACA, 0xE8483C][h % 3])
            vline(&g, mx + 3, top - 5, 3, 0xD8E8F0); line(&g, mx + 3, top - 5, mx + 7, top - 3, 0xD8E8F0)
            fill(&g, mx + 9, top + 2, 7, 4, 0xF0E6D0); vline(&g, mx + 12, top + 2, 4, 0x8A7A68); hline(&g, mx + 10, top + 3, 2, 0x5A5A68)
        default:
            fill(&g, mx + 2, top - 3, 2, 4, 0xF0E6D0); g[mx + 2, top - 4] = 0xFFD050
        }
        // Taburete delante
        if !joinRight && h % 3 != 0 {
            let sx = ox + T / 2 - 3
            fill(&g, sx, oy + 20, 7, 2, woodTones[3]); hline(&g, sx, oy + 20, 7, woodTones[4])
            vline(&g, sx + 1, oy + 22, 2, woodTones[1]); vline(&g, sx + 5, oy + 22, 2, woodTones[0])
        }
    }

    /// Banco de capilla con respaldo y reclinatorio.
    private static func pew(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, joinLeft: Bool, joinRight: Bool) {
        let T = tile
        let x0 = ox + (joinLeft ? 0 : 2), x1 = ox + T - (joinRight ? 0 : 2)
        tintRect(&g, x0 + 3, oy + 18, x1 - x0, 4, shadowF)
        // Respaldo
        fill(&g, x0, oy + 1, x1 - x0, 8, woodTones[2])
        hline(&g, x0, oy + 1, x1 - x0, woodTones[4]); hline(&g, x0, oy + 2, x1 - x0, woodTones[3])
        for xx in stride(from: x0 + 3, to: x1, by: 6) { vline(&g, xx, oy + 3, 5, woodTones[1]) }
        // Asiento
        fill(&g, x0, oy + 9, x1 - x0, 4, woodTones[3]); hline(&g, x0, oy + 9, x1 - x0, woodTones[4])
        fill(&g, x0, oy + 13, x1 - x0, 3, woodTones[1]); hline(&g, x0, oy + 15, x1 - x0, woodTones[0])
        // Brazos tallados en los extremos
        if !joinLeft { fill(&g, x0 - 1, oy, 3, 18, woodTones[3]); vline(&g, x0 - 1, oy, 18, woodTones[4]); g[x0, oy - 1] = woodTones[3] }
        if !joinRight { fill(&g, x1 - 2, oy, 3, 18, woodTones[1]); vline(&g, x1, oy, 18, woodTones[0]); g[x1 - 1, oy - 1] = woodTones[2] }
    }

    /// Cama de una o dos casillas de ancho y alto: cabecero, almohadas y manta de retales.
    private static func bed(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, wide: Bool, tall: Bool, blanket: [UInt32]) {
        let T = tile
        let w = wide ? 2 * T - 4 : T - 4, h = tall ? 2 * T - 4 : T - 2
        let x0 = ox + 2, y0 = oy + 2
        tintRect(&g, x0 + 3, y0 + h - 2, w, 4, shadowF)
        tintRect(&g, x0 + w, y0 + 4, 3, h - 4, shadowF)
        // Armazón
        fill(&g, x0, y0 - 6, w, h + 6, woodTones[1])
        // Cabecero tallado
        fill(&g, x0, y0 - 8, w, 9, woodTones[2]); hline(&g, x0, y0 - 8, w, woodTones[4]); hline(&g, x0, y0, w, woodTones[0])
        for xx in stride(from: x0 + 4, to: x0 + w - 2, by: 5) { fill(&g, xx, y0 - 5, 2, 4, woodTones[1]) }
        fill(&g, x0, y0 - 10, 3, h + 10, woodTones[3]); fill(&g, x0 + w - 3, y0 - 10, 3, h + 10, woodTones[1])
        ball(&g, x0 + 1, y0 - 10, 2, 2, [woodTones[1], woodTones[3], woodTones[4]]); ball(&g, x0 + w - 2, y0 - 10, 2, 2, [woodTones[0], woodTones[2], woodTones[3]])
        // Sábana y almohadas
        fill(&g, x0 + 3, y0 + 1, w - 6, h - 4, 0xE8E2D8)
        let pillows = wide ? 2 : 1
        for i in 0..<pillows {
            let pw = (w - 6) / pillows - 2
            let px = x0 + 4 + i * (pw + 2)
            fill(&g, px, y0 + 2, pw, 7, 0xF6F2EA); hline(&g, px, y0 + 2, pw, 0xFFFFFF); hline(&g, px, y0 + 8, pw, 0xC8C0B4)
            vline(&g, px + pw - 1, y0 + 3, 5, 0xD8D0C4)
        }
        // Manta de retales con el embozo vuelto
        let by = y0 + 11
        for yy in by..<(y0 + h - 3) {
            for xx in (x0 + 3)..<(x0 + w - 3) {
                let qx = (xx - x0 - 3) / 6, qy = (yy - by) / 6
                let lx = (xx - x0 - 3) % 6, ly = (yy - by) % 6
                var c = blanket[1 + (qx + qy) % 3]
                if (qx + qy) % 4 == 3 { c = 0xE8D8B0 }
                if lx == 0 || ly == 0 { c = blanket[0] }
                if lx == 3 && ly == 3 { c = light(c, 1.2) }
                if xx > x0 + w - 6 { c = dark(c, 0.85) }
                g[xx, yy] = c
            }
        }
        fill(&g, x0 + 3, by - 1, w - 6, 2, 0xF6F2EA); hline(&g, x0 + 3, by + 1, w - 6, blanket[0])
        // Pie de cama
        fill(&g, x0, y0 + h - 3, w, 3, woodTones[2]); hline(&g, x0, y0 + h - 3, w, woodTones[4]); hline(&g, x0, y0 + h - 1, w, woodTones[0])
    }

    /// Caldero de la alquimista sobre brasas, con líquido verde burbujeante.
    private static func cauldron(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        let cx = ox + 12, cy = oy + 12
        tintRect(&g, cx - 7, cy + 7, 18, 3, shadowF)
        warmGlow(&g, cx, cy + 6, radius: 16)
        // Brasas y patas
        for (dx, c) in [(-6, 0xF07A20), (-2, 0xFFD050), (3, 0xD8401A), (6, 0xF89A30)] as [(Int, UInt32)] { g[cx + dx, cy + 9] = c; g[cx + dx + 1, cy + 9] = dark(c, 0.7) }
        fill(&g, cx - 7, cy + 6, 2, 3, 0x2C2C36); fill(&g, cx + 6, cy + 6, 2, 3, 0x2C2C36)
        ball(&g, cx, cy + 2, 9, 7, [0x1A1A22, 0x2C2C36, 0x3E3E4C, 0x5A5A6C])
        ellipse(&g, cx, cy - 4, 9, 3, 0x2C2C36)
        ellipse(&g, cx, cy - 4, 8, 2, 0x3EC86A)
        hline(&g, cx - 4, cy - 5, 4, 0x9AF0A8)
        for (dx, dy) in [(-3, -4), (2, -5), (5, -4)] { g[cx + dx, cy + dy] = 0xC8FFD0 }
        // Burbujas y vapor
        for (dx, dy) in [(-1, -9), (2, -12), (-2, -15), (1, -18)] { g[cx + dx, cy + dy] = 0x9AF0A8 }
        hline(&g, cx - 9, cy - 4, 2, 0x5A5A6C); hline(&g, cx + 8, cy - 4, 2, 0x5A5A6C)
    }

    /// Columna de piedra (o mármol) con basa, fuste estriado y capitel; sube por encima de su casilla.
    private static func pillar(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, marble: Bool) {
        let tones: [UInt32] = marble ? [0x4A4258, 0x625A74, 0x7C7490, 0x968EAA, 0xB4ACC6] : [0x6E6A78, 0x8E8A98, 0xAAA6B4, 0xC4C0CE, 0xDAD6E2]
        let cx = ox + 12
        // Sombra en el suelo
        for y in -3...3 { for x in -10...12 where x * x * 9 + y * y * 100 <= 900 { tint(&g, cx + 4 + x, oy + 21 + y, shadowF) } }
        // Fuste con estrías y sombreado cilíndrico
        let top = oy - 16, bottom = oy + 17
        for y in top..<bottom {
            for x in -6...6 {
                let u = Double(x) / 6.5
                var l = 0.7 - u * 0.42 - u * u * 0.2
                if (x + 6) % 3 == 0 { l -= 0.14 }
                l += (bayer(cx + x, y) - 0.5) * 0.1
                g[cx + x, y] = tones[max(0, min(4, Int(l * 5)))]
            }
        }
        // Basa y capitel
        for (yy, hw, hgt) in [(bottom, 9, 4), (top - 5, 9, 5)] {
            for y in yy..<(yy + hgt) {
                for x in -hw...hw {
                    let u = Double(x) / Double(hw)
                    var l = 0.72 - u * 0.4
                    if y == yy { l += 0.2 } else if y == yy + hgt - 1 { l -= 0.25 }
                    g[cx + x, y] = tones[max(0, min(4, Int(l * 5)))]
                }
            }
        }
        // Volutas del capitel
        g[cx - 8, top - 2] = tones[1]; g[cx + 8, top - 2] = tones[0]; g[cx - 7, top - 1] = tones[4]
        if marble { hline(&g, cx - 7, top - 1, 15, 0xE0B040) }
    }

    /// Trono real de dos casillas sobre una tarima, con respaldo alto, terciopelo, oro y gemas.
    private static func throne(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        let cx = ox + tile
        let goldT: [UInt32] = [0x7A5418, 0xB0802A, 0xE0B040, 0xFFE07A]
        // Tarima de tres escalones con alfombra
        for (i, hw) in [32, 28, 24].enumerated() {
            let y = oy + 17 - i * 4
            fill(&g, cx - hw, y, hw * 2, 5, [0x5A5468, 0x6E6880, 0x847E96][i])
            hline(&g, cx - hw, y, hw * 2, [0x8A8498, 0xA09AB0, 0xB8B2C6][i])
            hline(&g, cx - hw, y + 4, hw * 2, 0x3A3448)
            fill(&g, cx - 10, y, 20, 5, 0x8A1E2A); hline(&g, cx - 10, y, 20, 0xAE3440)
        }
        tintRect(&g, cx + 19, oy - 20, 6, 32, shadowF)
        // Respaldo alto con remate en arco apuntado y corona
        let bt = oy - 22
        for y in bt..<(oy + 6) {
            let t = y - bt
            let hw = t < 8 ? 6 + t * 11 / 8 : 17
            for x in -hw...hw {
                var c: UInt32
                if abs(x) >= hw - 2 { c = x < 0 ? goldT[3] : goldT[1] }
                else if abs(x) == hw - 3 { c = goldT[0] }
                else {
                    // Terciopelo capitoné
                    c = x < -6 ? 0xA82838 : (x > 6 ? 0x6A1420 : 0x8A1E2A)
                    if (x + 40 + y) % 6 == 0 && (x + 40 - y) % 6 == 0 { c = goldT[2] }
                    else if ((x + 40 + y) % 6 == 0 || (x + 40 - y) % 6 == 0) { c = dark(c, 0.86) }
                }
                if t < 2 { c = goldT[3] }
                g[cx + x, y] = c
            }
        }
        // Rubí en lo alto
        ball(&g, cx, bt + 3, 2, 2, [0x8A1020, 0xD82838, 0xFF7080])
        // Escudo bordado
        fill(&g, cx - 4, oy - 14, 9, 8, goldT[2]); fill(&g, cx - 3, oy - 6, 7, 2, goldT[2]); fill(&g, cx - 1, oy - 4, 3, 1, goldT[2])
        fill(&g, cx - 3, oy - 13, 7, 6, 0x2A56A4); g[cx, oy - 11] = goldT[3]; g[cx - 1, oy - 10] = goldT[2]; g[cx + 1, oy - 10] = goldT[2]
        // Gemas
        ball(&g, cx - 12, oy - 8, 1, 1, [0x1A5AA0, 0x3E9AE8, 0xA0E0FF])
        ball(&g, cx + 12, oy - 8, 1, 1, [0x1A7A3A, 0x3EC86A, 0xA0FFB0])
        // Cojín del asiento y brazos con remate de león
        fill(&g, cx - 16, oy, 32, 7, 0x9A2430); hline(&g, cx - 16, oy, 32, 0xC8404A); hline(&g, cx - 16, oy + 6, 32, 0x6A1420)
        for side in [-1, 1] {
            let ax = cx + side * 19 - (side > 0 ? 4 : 0)
            fill(&g, ax, oy - 8, 5, 18, side < 0 ? goldT[2] : goldT[1])
            vline(&g, ax, oy - 8, 18, side < 0 ? goldT[3] : goldT[2]); vline(&g, ax + 4, oy - 8, 18, goldT[0])
            ball(&g, ax + 2, oy - 9, 3, 2, goldT)
        }
        fill(&g, cx - 16, oy + 7, 32, 4, goldT[1]); hline(&g, cx - 16, oy + 7, 32, goldT[2]); hline(&g, cx - 16, oy + 10, 32, goldT[0])
        for x in stride(from: cx - 14, to: cx + 16, by: 6) { g[x, oy + 8] = 0xD82838 }
    }

    /// Altar de la capilla: mesa con mantel, candelabros encendidos y cruz.
    private static func altar(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        let cx = ox + tile
        // Escalón
        fill(&g, cx - 22, oy + 15, 44, 5, 0xA4A0AC); hline(&g, cx - 22, oy + 15, 44, 0xCCC8D2); hline(&g, cx - 22, oy + 19, 44, 0x6E6A78)
        tintRect(&g, cx + 18, oy + 2, 4, 14, shadowF)
        // Mesa de piedra con mantel blanco y franja dorada
        fill(&g, cx - 18, oy + 2, 36, 13, 0xBAB6C2)
        fill(&g, cx - 18, oy, 36, 9, 0xF4F0E6); hline(&g, cx - 18, oy, 36, 0xFFFFFF)
        hline(&g, cx - 18, oy + 7, 36, 0xE0B040)
        fill(&g, cx - 4, oy + 1, 8, 8, 0x8A1E2A); vline(&g, cx, oy + 2, 6, 0xE0B040); hline(&g, cx - 2, oy + 4, 5, 0xE0B040)
        // Cruz dorada detrás
        fill(&g, cx - 1, oy - 20, 3, 18, 0xE0B040); fill(&g, cx - 6, oy - 15, 13, 3, 0xE0B040)
        vline(&g, cx - 1, oy - 20, 18, 0xFFE07A); hline(&g, cx - 6, oy - 15, 13, 0xFFE07A)
        // Candelabros
        for dx in [-14, 13] {
            fill(&g, cx + dx, oy - 6, 2, 7, 0xB0802A); hline(&g, cx + dx - 1, oy, 4, 0xE0B040)
            fill(&g, cx + dx, oy - 10, 2, 4, 0xF6F0E0)
            g[cx + dx, oy - 11] = 0xFFD050; g[cx + dx, oy - 12] = 0xFFF6C8; g[cx + dx + 1, oy - 11] = 0xF07A20
        }
    }

    /// Salida: umbral de piedra, luz de fuera y felpudo.
    private static func doorway(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, joinLeft: Bool, joinRight: Bool) {
        let T = tile
        // Luz del día que entra
        for y in oy..<(oy + T) { for x in (ox + 2)..<(ox + T - 2) { tint(&g, x, y, (1.12, 1.1, 1.02)) } }
        fill(&g, ox + 1, oy + T - 5, T - 2, 5, 0xB8B0A0); hline(&g, ox + 1, oy + T - 5, T - 2, 0xD8D0C0); hline(&g, ox + 1, oy + T - 1, T - 2, 0x8A8070)
        // Felpudo
        let mx0 = ox + (joinLeft ? 0 : 4), mx1 = ox + T - (joinRight ? 0 : 4)
        fill(&g, mx0, oy + 6, mx1 - mx0, 11, 0x8A6A3A)
        for y in (oy + 7)..<(oy + 16) { for x in (mx0 + 1)..<(mx1 - 1) where (x + y) % 2 == 0 { g[x, y] = 0xA8844A } }
        hline(&g, mx0, oy + 6, mx1 - mx0, 0xC8A060); hline(&g, mx0, oy + 16, mx1 - mx0, 0x5A4428)
        // Jambas
        if !joinLeft { fill(&g, ox, oy, 2, T, 0x5A4A44) }
        if !joinRight { fill(&g, ox + T - 2, oy, 2, T, 0x3A2E2A) }
    }
}
