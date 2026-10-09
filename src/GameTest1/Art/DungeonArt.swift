import CoreGraphics
import GameCore

// CONTRATO ENTRE LA ARENA Y EL ARTE DE LA MAZMORRA
// `BattleScene` usa estas funciones; el `environment-artist` puede cambiar todo lo de dentro,
// pero no las firmas (ni `tile`, que debe ser igual que `TownArt.tile`).
//
// Coordenadas en pixeles de arte, origen arriba-izquierda: la casilla (x, y) ocupa
// [x*tile, x*tile+tile) × [y*tile, y*tile+tile) en la imagen de `ground`.
//
// Organización del arte (todo en pixel-art 16 bits, vista 3/4, luz arriba-izquierda):
//   DungeonArt.swift          contrato, lienzo, ruido y el orden de pintado del piso (+ luz horneada)
//   DungeonArt+Style.swift    paletas de los 5 temas
//   DungeonArt+Floor.swift    suelos, alfombras, rejillas, escombros, huesos y sombras
//   DungeonArt+Walls.swift    paredes 3/4, puertas, gran puerta del jefe, rejas, antorchas y decoración de muro
//   DungeonArt+Liquid.swift   agua, abismo, cloaca y lava, con sus orillas, y los puentes
//   DungeonArt+Props.swift    pilares, estatuas, braseros, cajas, cofres, altares y llamas

/// Arte de la mazmorra de la arena en vista 3/4.
enum DungeonArt {
    static let tile = 24

    /// Todo lo plano del piso en una sola imagen: suelo, paredes (con su cara de ladrillo cuando hay suelo
    /// debajo), puertas, rejas, líquido, puentes, alfombras, rejillas y restos. La luz de antorchas y braseros
    /// puede ir ya pintada aquí (más claro cerca de las luces, más oscuro lejos).
    static func ground(_ floor: DungeonFloor) -> PixelGrid {
        var painter = DungeonPainter(floor)
        painter.paint()
        return painter.c.grid
    }

    /// Obstáculos altos que se dibujan aparte para que los personajes pasen por detrás: pilares, estatuas,
    /// braseros, cajas, cofres y altar. `nil` si la casilla no lleva sprite.
    /// El sprite se coloca con su borde inferior en el borde inferior de la casilla, centrado en ella
    /// (el altar ocupa 2 casillas: se pide solo para la de la izquierda y se centra entre las dos).
    static func prop(_ tile: DungeonTile, theme: DungeonTheme, variant: Int) -> PixelGrid? {
        DungeonProps.sprite(tile, style: DungeonStyle.of(theme), variant: variant)?.grid.outlined()
    }

    /// Llama animada de antorchas y braseros (varios frames del mismo tamaño, anclados abajo-centro).
    static func flame(theme: DungeonTheme, frame: Int) -> PixelGrid {
        DungeonProps.flame(DungeonStyle.of(theme), frame: frame).grid
    }

    static let flameFrames = 6

    /// Color de la luz (halo de antorchas y braseros).
    static func lightColor(_ theme: DungeonTheme) -> UInt32 { DungeonStyle.of(theme).light }

    /// Fuera del mapa y en los bordes de la pantalla.
    static func voidColor(_ theme: DungeonTheme) -> UInt32 { DungeonStyle.of(theme).void }
}

// MARK: - Lienzo

/// Lienzo de trabajo: colores opacos (0 = transparente) y, para el suelo, el material de cada pixel
/// (lo usa la luz horneada: el suelo y las caras reciben luz, las tapas casi nada y lo que brilla, nada).
struct DCanvas {
    enum Mat: UInt8 { case floor = 0, face, cap, glow, liquid }

    let w: Int, h: Int
    var px: [UInt32]
    var mat: [UInt8]

    init(_ w: Int, _ h: Int) {
        self.w = w
        self.h = h
        px = Array(repeating: 0, count: w * h)
        mat = Array(repeating: 0, count: w * h)
    }

    @inline(__always) func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h }

    /// Color del pixel (`nil` si es transparente o está fuera).
    @inline(__always) func at(_ x: Int, _ y: Int) -> UInt32? {
        guard inside(x, y) else { return nil }
        let v = px[y * w + x]
        return v == 0 ? nil : v & 0xFFFFFF
    }

    @inline(__always) mutating func put(_ x: Int, _ y: Int, _ c: UInt32) {
        guard inside(x, y) else { return }
        px[y * w + x] = 0xFF00_0000 | c
    }

    /// Pixel que brilla por sí mismo (lava, runas, cristales, ojos): la luz horneada no lo oscurece.
    @inline(__always) mutating func glow(_ x: Int, _ y: Int, _ c: UInt32) {
        guard inside(x, y) else { return }
        px[y * w + x] = 0xFF00_0000 | c
        mat[y * w + x] = Mat.glow.rawValue
    }

    @inline(__always) mutating func setMat(_ x: Int, _ y: Int, _ m: Mat) {
        guard inside(x, y) else { return }
        mat[y * w + x] = m.rawValue
    }

    mutating func matRect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int, _ m: Mat) {
        for yy in max(0, y)..<max(max(0, y), min(h, y + rh)) {
            for xx in max(0, x)..<max(max(0, x), min(w, x + rw)) { mat[yy * w + xx] = m.rawValue }
        }
    }

    mutating func clear(_ x: Int, _ y: Int) {
        guard inside(x, y) else { return }
        px[y * w + x] = 0
    }

    mutating func rect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int, _ c: UInt32) {
        guard rw > 0, rh > 0 else { return }
        for yy in max(0, y)..<max(max(0, y), min(h, y + rh)) {
            for xx in max(0, x)..<max(max(0, x), min(w, x + rw)) { px[yy * w + xx] = 0xFF00_0000 | c }
        }
    }

    mutating func glowRect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int, _ c: UInt32) {
        guard rw > 0, rh > 0 else { return }
        for yy in max(0, y)..<max(max(0, y), min(h, y + rh)) {
            for xx in max(0, x)..<max(max(0, x), min(w, x + rw)) {
                px[yy * w + xx] = 0xFF00_0000 | c
                mat[yy * w + xx] = Mat.glow.rawValue
            }
        }
    }

    mutating func hline(_ x: Int, _ y: Int, _ len: Int, _ c: UInt32) { rect(x, y, len, 1, c) }
    mutating func vline(_ x: Int, _ y: Int, _ len: Int, _ c: UInt32) { rect(x, y, 1, len, c) }

    /// Mezcla el color con el que ya hay (t = 0 nada, 1 todo).
    @inline(__always) mutating func mix(_ x: Int, _ y: Int, _ c: UInt32, _ t: Double) {
        guard let old = at(x, y) else { return }
        put(x, y, DColor.mix(old, c, t))
    }

    /// Multiplica el brillo del pixel (sombras).
    @inline(__always) mutating func shade(_ x: Int, _ y: Int, _ f: Double) {
        guard inside(x, y), mat[y * w + x] != Mat.glow.rawValue, let old = at(x, y) else { return }
        put(x, y, DColor.mul(old, f))
    }

    mutating func shadeRect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int, _ f: Double) {
        for yy in y..<(y + rh) { for xx in x..<(x + rw) { shade(xx, yy, f) } }
    }

    mutating func ellipse(_ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ c: UInt32) {
        guard rx > 0, ry > 0 else { put(cx, cy, c); return }
        for yy in -ry...ry {
            for xx in -rx...rx where Double(xx * xx) / Double(rx * rx) + Double(yy * yy) / Double(ry * ry) <= 1.0 {
                put(cx + xx, cy + yy, c)
            }
        }
    }

    /// Elipse de sombra suave (más oscura en el centro).
    mutating func shadowEllipse(_ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ strength: Double) {
        guard rx > 0, ry > 0 else { return }
        for yy in -ry...ry {
            for xx in -rx...rx {
                let d = Double(xx * xx) / Double(rx * rx) + Double(yy * yy) / Double(ry * ry)
                guard d <= 1 else { continue }
                shade(cx + xx, cy + yy, 1 - strength * (d < 0.45 ? 1 : 0.6))
            }
        }
    }

    mutating func line(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ c: UInt32) {
        var x = x0, y = y0
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            put(x, y, c)
            if x == x1 && y == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x += sx }
            if e2 <= dx { err += dx; y += sy }
        }
    }

    /// Dibuja filas de caracteres con su paleta (los que no están en la paleta son transparentes).
    /// Los caracteres de `glowing` se marcan como luz propia.
    mutating func sprite(_ rows: [String], _ x: Int, _ y: Int, _ pal: [Character: UInt32],
                         flip: Bool = false, glowing: Set<Character> = []) {
        for (j, row) in rows.enumerated() {
            let chars = Array(row)
            for (i, ch) in chars.enumerated() {
                guard let col = pal[ch] else { continue }
                let xx = x + (flip ? chars.count - 1 - i : i)
                if glowing.contains(ch) { glow(xx, y + j, col) } else { put(xx, y + j, col) }
            }
        }
    }

    /// Pega otro lienzo encima (lo transparente no tapa).
    mutating func draw(_ o: DCanvas, _ x: Int, _ y: Int) {
        for yy in 0..<o.h {
            for xx in 0..<o.w {
                let v = o.px[yy * o.w + xx]
                guard v != 0, inside(x + xx, y + yy) else { continue }
                px[(y + yy) * w + x + xx] = v
                if o.mat[yy * o.w + xx] == Mat.glow.rawValue { mat[(y + yy) * w + x + xx] = Mat.glow.rawValue }
            }
        }
    }

    var grid: PixelGrid {
        var g = PixelGrid(width: w, height: h)
        g.pixels = px.map { $0 == 0 ? nil : $0 & 0xFFFFFF }
        return g
    }
}

// MARK: - Color y azar

enum DColor {
    @inline(__always) static func rgb(_ c: UInt32) -> (Double, Double, Double) {
        (Double((c >> 16) & 0xFF), Double((c >> 8) & 0xFF), Double(c & 0xFF))
    }

    @inline(__always) static func pack(_ r: Double, _ g: Double, _ b: Double) -> UInt32 {
        let r = UInt32(max(0, min(255, r.rounded())))
        let g = UInt32(max(0, min(255, g.rounded())))
        let b = UInt32(max(0, min(255, b.rounded())))
        return (r << 16) | (g << 8) | b
    }

    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        let (ar, ag, ab) = rgb(a), (br, bg, bb) = rgb(b)
        return pack(ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)
    }

    static func mul(_ c: UInt32, _ f: Double) -> UInt32 {
        let (r, g, b) = rgb(c)
        return pack(r * f, g * f, b * f)
    }
}

/// Dados deterministas (SplitMix64): la misma casilla siempre se pinta igual.
struct Dice {
    private var state: UInt64

    init(_ a: Int, _ b: Int = 0, _ salt: Int = 0) {
        state = UInt64(bitPattern: Int64(a &* 73_856_093 ^ b &* 19_349_663 ^ salt &* 83_492_791)) &+ 0x9E37_79B9_7F4A_7C15
        _ = next()
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Entero en 0..<n.
    mutating func int(_ n: Int) -> Int { n <= 1 ? 0 : Int(next() % UInt64(n)) }
    mutating func range(_ a: Int, _ b: Int) -> Int { a + int(b - a + 1) }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
    mutating func pick<T>(_ items: [T]) -> T { items[int(items.count)] }
}

enum Noise {
    /// Valor pseudoaleatorio estable en [0, 1) para un punto entero.
    @inline(__always) static func hash(_ x: Int, _ y: Int, _ salt: Int = 0) -> Double {
        var h = UInt64(bitPattern: Int64(x &* 374_761_393 &+ y &* 668_265_263 &+ salt &* 2_147_483_647))
        h = (h ^ (h >> 13)) &* 1_274_126_177
        h = h ^ (h >> 16)
        return Double(h & 0xFFFF) / 65536.0
    }

    /// Ruido suave (interpolado) con celdas de `size` pixeles.
    static func smooth(_ x: Int, _ y: Int, _ size: Int, _ salt: Int = 0) -> Double {
        let gx = x / size, gy = y / size
        let fx = Double(x % size) / Double(size), fy = Double(y % size) / Double(size)
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        let a = hash(gx, gy, salt), b = hash(gx + 1, gy, salt)
        let c = hash(gx, gy + 1, salt), d = hash(gx + 1, gy + 1, salt)
        return (a + (b - a) * sx) + ((c + (d - c) * sx) - (a + (b - a) * sx)) * sy
    }

    /// Celdas de Voronoi (piedras, adoquines, roca): devuelve el centro más cercano, la distancia a él y
    /// la diferencia con el segundo (cerca de 0 = junta entre piedras).
    struct Cell { var cx: Double; var cy: Double; var id: Int; var d1: Double; var edge: Double }

    /// `square`: distancia de Chebyshev (piedras más rectangulares, como losas).
    static func voronoi(_ x: Int, _ y: Int, _ size: Int, _ salt: Int = 0, squash: Double = 1, square: Bool = false) -> Cell {
        let gx = Int((Double(x) / Double(size)).rounded(.down)), gy = Int((Double(y) / Double(size)).rounded(.down))
        var best = Cell(cx: 0, cy: 0, id: 0, d1: 1e9, edge: 0)
        var second = 1e9
        let px = Double(x) + 0.5, py = Double(y) + 0.5
        for j in -1...1 {
            for i in -1...1 {
                let cx = gx + i, cy = gy + j
                let fx = Double(cx * size) + (0.15 + 0.7 * hash(cx, cy, salt)) * Double(size)
                let fy = Double(cy * size) + (0.15 + 0.7 * hash(cx, cy, salt + 77)) * Double(size)
                let dx = px - fx, dy = (py - fy) * squash
                let d = square ? max(abs(dx), abs(dy)) : (dx * dx + dy * dy).squareRoot()
                if d < best.d1 {
                    second = best.d1
                    best = Cell(cx: fx, cy: fy, id: cx &* 92821 ^ cy &* 68917, d1: d, edge: 0)
                } else if d < second {
                    second = d
                }
            }
        }
        best.edge = second - best.d1
        return best
    }

    /// Umbral de tramado ordenado (Bayer 4×4) en [0, 1).
    @inline(__always) static func bayer(_ x: Int, _ y: Int) -> Double {
        let m: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
        return (m[(y & 3) * 4 + (x & 3)] + 0.5) / 16
    }
}

// MARK: - Pintor del piso

/// Pinta un piso entero por pasadas: casillas, gran puerta, puentes, orillas, sombras, decoración y luz.
struct DungeonPainter {
    let floor: DungeonFloor
    let s: DungeonStyle
    let W: Int, H: Int
    let T = DungeonArt.tile
    private let tiles: [DungeonTile]
    var c: DCanvas
    var lights: [DLight] = []

    init(_ floor: DungeonFloor) {
        self.floor = floor
        s = DungeonStyle.of(floor.theme)
        W = floor.width
        H = floor.height
        var list: [DungeonTile] = []
        list.reserveCapacity(W * H)
        for row in floor.rows {
            var chars = Array(row)
            if chars.count < W { chars += Array(repeating: "#", count: W - chars.count) }
            for ch in chars { list.append(DungeonTile(rawValue: ch) ?? .floor) }
        }
        tiles = list
        c = DCanvas(W * DungeonArt.tile, H * DungeonArt.tile)
    }

    // Consultas de vecinos (fuera del mapa = pared).
    @inline(__always) func t(_ x: Int, _ y: Int) -> DungeonTile {
        guard x >= 0, y >= 0, x < W, y < H else { return .wall }
        return tiles[y * W + x]
    }
    @inline(__always) func isWall(_ x: Int, _ y: Int) -> Bool { t(x, y).isWall }
    /// Pared que se ve de frente (tiene algo que no es pared debajo).
    @inline(__always) func isFace(_ x: Int, _ y: Int) -> Bool { isWall(x, y) && !isWall(x, y + 1) }
    @inline(__always) func isCap(_ x: Int, _ y: Int) -> Bool { isWall(x, y) && isWall(x, y + 1) }
    /// Agua, lava o abismo (el puente cuenta como líquido para las orillas: el líquido sigue por debajo).
    @inline(__always) func isWet(_ x: Int, _ y: Int) -> Bool { let k = t(x, y); return k == .liquid || k == .bridge }
    /// Suelo firme (incluye lo que hay bajo pilares, cofres…).
    @inline(__always) func isLand(_ x: Int, _ y: Int) -> Bool { !isWall(x, y) && !isWet(x, y) }

    mutating func paint() {
        for y in 0..<H {
            for x in 0..<W {
                let k = t(x, y)
                if k.isWall {
                    if isFace(x, y) || k == .gate || k == .bossGate || k == .bars || k == .torch {
                        paintFace(x, y)
                    } else {
                        paintCap(x, y)
                    }
                } else if k == .liquid || k == .bridge {
                    paintLiquid(x, y)
                } else {
                    paintFloor(x, y)
                }
            }
        }
        for y in 0..<H { for x in 0..<W where t(x, y).isWall { paintWallFeature(x, y) } }
        paintBossGates()
        for y in 0..<H { for x in 0..<W where t(x, y) == .bridge { paintBridge(x, y) } }
        for y in 0..<H { for x in 0..<W { paintShores(x, y) } }
        for y in 0..<H { for x in 0..<W where !t(x, y).isWall && t(x, y) != .liquid { paintFloorOverlay(x, y) } }
        for y in 0..<H { for x in 0..<W { paintShadows(x, y) } }
        for y in 0..<H { for x in 0..<W where isFace(x, y) && t(x, y) == .wall { paintWallDecor(x, y) } }
        collectLights()
        bakeLight()
    }

    // MARK: Luz horneada

    struct DLight { var x: Double; var y: Double; var r: Double; var k: Double }

    private mutating func collectLights() {
        for y in 0..<H {
            for x in 0..<W {
                let k = t(x, y)
                let cx = Double(x * T + T / 2)
                if k == .torch { lights.append(DLight(x: cx, y: Double(y * T + 5), r: 118, k: 1.0)) }
                if k == .brazier { lights.append(DLight(x: cx, y: Double(y * T + 2), r: 104, k: 0.95)) }
                if k == .liquid && s.liquidLight > 0 {
                    // La lava ilumina todo; el abismo de la cripta solo desde las casillas de orilla (niebla fría).
                    let shore = !isWet(x - 1, y) || !isWet(x + 1, y) || !isWet(x, y - 1) || !isWet(x, y + 1)
                    if s.theme == .forge || shore {
                        lights.append(DLight(x: cx, y: Double(y * T + T / 2), r: s.theme == .forge ? 52 : 60, k: s.liquidLight))
                    }
                }
            }
        }
        lights += extraLights
    }

    /// Luces pequeñas que añade la decoración (cristales, runas, rejillas de forja).
    var extraLights: [DLight] = []

    private mutating func bakeLight() {
        // Mapa de luz a baja resolución (cada 4 px) con interpolación: rápido y suave.
        let step = 4
        let lw = c.w / step + 2, lh = c.h / step + 2
        var map = [Double](repeating: 0, count: lw * lh)
        for l in lights {
            let x0 = max(0, Int((l.x - l.r) / Double(step))), x1 = min(lw - 1, Int((l.x + l.r) / Double(step)) + 1)
            let y0 = max(0, Int((l.y - l.r) / Double(step))), y1 = min(lh - 1, Int((l.y + l.r) / Double(step)) + 1)
            guard x0 <= x1, y0 <= y1 else { continue }
            for gy in y0...y1 {
                for gx in x0...x1 {
                    let dx = Double(gx * step) - l.x, dy = (Double(gy * step) - l.y) * 1.15
                    let d = (dx * dx + dy * dy).squareRoot() / l.r
                    guard d < 1 else { continue }
                    let f = (1 - d) * (1 - d)
                    map[gy * lw + gx] += f * l.k
                }
            }
        }
        let (lr, lg, lb) = DColor.rgb(s.light)
        let amb = s.ambient
        let cool = s.shadowTint
        let steps = 7.0
        for y in 0..<c.h {
            let gy = y / step, fy = Double(y % step) / Double(step)
            for x in 0..<c.w {
                let i = y * c.w + x
                let v = c.px[i]
                guard v != 0 else { continue }
                let m = c.mat[i]
                if m == DCanvas.Mat.glow.rawValue { continue }
                let gx = x / step, fx = Double(x % step) / Double(step)
                let a = map[gy * lw + gx], b = map[gy * lw + gx + 1]
                let cc = map[(gy + 1) * lw + gx], d = map[(gy + 1) * lw + gx + 1]
                var L = (a + (b - a) * fx) + ((cc + (d - cc) * fx) - (a + (b - a) * fx)) * fy
                L = min(1.25, L)
                if m == DCanvas.Mat.cap.rawValue { L *= 0.45 }
                if m == DCanvas.Mat.liquid.rawValue { L *= 0.8 }
                // Cuantizado con tramado ordenado: bandas de luz al estilo 16 bits.
                let q = (L * steps + Noise.bayer(x, y) - 0.5).rounded(.down) / steps
                let lq = max(0, q)
                let dark = max(0, 1 - lq * 1.6)   // cuánto "frío" de sombra queda
                let fr = amb * (1 + (cool.0 - 1) * dark) + lq * s.lightGain * lr / 255
                let fg = amb * (1 + (cool.1 - 1) * dark) + lq * s.lightGain * lg / 255
                let fb = amb * (1 + (cool.2 - 1) * dark) + lq * s.lightGain * lb / 255
                let (r, g, bl) = DColor.rgb(v & 0xFFFFFF)
                c.px[i] = 0xFF00_0000 | DColor.pack(r * fr, g * fg, bl * fb)
            }
        }
    }
}
