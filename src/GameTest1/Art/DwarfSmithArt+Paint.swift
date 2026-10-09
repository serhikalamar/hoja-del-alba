import CoreGraphics

// Utilidades de pintado del herrero enano: volúmenes sombreados con luz arriba-izquierda,
// cápsulas (brazos, mangos), sellos de filas de caracteres y contraluz de la fragua.

extension DwarfSmithArt {
    /// Rampas de color de cada material, de oscuro a claro (el último es el brillo puntual).
    enum Ramp {
        static let skin: [UInt32] = [0x6A2E26, 0x9E4C3C, 0xCC7656, 0xEBA076, 0xFCCBA2]
        static let nose: [UInt32] = [0x74282A, 0xA84640, 0xD66A58, 0xF2967A, 0xFFC8B0]
        static let beard: [UInt32] = [0x461810, 0x792C16, 0xAE4C1C, 0xD8742A, 0xF29E46, 0xFFCF7C]
        static let steel: [UInt32] = [0x1E2436, 0x37425C, 0x596886, 0x8696B2, 0xBAC6DA, 0xF0F4FA]
        static let brass: [UInt32] = [0x45290F, 0x7A4F1E, 0xB2802C, 0xE0B04C, 0xFFE494]
        static let tunic: [UInt32] = [0x11241C, 0x1B3B2C, 0x28573E, 0x3B7553, 0x5E9A6C]
        static let leather: [UInt32] = [0x24130B, 0x422414, 0x663B22, 0x8A5733, 0xB07D4A]
        static let glove: [UInt32] = [0x2A170C, 0x55331A, 0x84582C, 0xB28244, 0xDAAE6E]
        static let iron: [UInt32] = [0x15171E, 0x2A2E3C, 0x464D62, 0x6E7890, 0xA4AEC4, 0xE8ECF4]
        static let wood: [UInt32] = [0x2C180B, 0x523017, 0x7A4B24, 0xA46C38, 0xC99256]
        static let lens: [UInt32] = [0x0C2228, 0x17403F, 0x266862, 0x4C9C8C]
    }

    /// Líneas interiores (párpados, juntas, separaciones).
    static let ink: UInt32 = 0x1A1C2C
    static let inkWarm: UInt32 = 0x2E1414
    /// Luz de la fragua (contraluz).
    static let ember: UInt32 = 0xFF9A3C

    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func ch(_ c: UInt32, _ s: UInt32) -> Double { Double((c >> s) & 0xFF) }
        func m(_ s: UInt32) -> UInt32 { UInt32((ch(a, s) * (1 - t) + ch(b, s) * t).rounded()) << s }
        return m(16) | m(8) | m(0)
    }

    /// Lienzo con capas: `dy` desplaza todo lo que se pinta (respiración de la parte superior).
    struct Painter {
        var g: PixelGrid
        var dy = 0

        init(width: Int, height: Int) { g = PixelGrid(width: width, height: height) }

        subscript(x: Int, y: Int) -> UInt32? {
            get { g[x, y + dy] }
            set { g[x, y + dy] = newValue }
        }

        /// Índice de tono para una normal (nx, ny) de una superficie redondeada; luz arriba-izquierda y algo de frente.
        static func tone(_ nx: Double, _ ny: Double, _ n: Int, bias: Double = 0) -> Int {
            let nz = max(0, 1 - nx * nx - ny * ny).squareRoot()
            let d = -0.5 * nx - 0.58 * ny + 0.64 * nz + bias
            let t = (d + 0.3) / 1.3
            if t > 0.9 { return n - 1 }
            return max(0, min(n - 2, Int(t / 0.9 * Double(n - 1))))
        }

        /// Elipse sombreada como un volumen.
        mutating func ball(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ ramp: [UInt32],
                           bias: Double = 0, clip: (Int, Int) -> Bool = { _, _ in true }) {
            for y in Int((cy - ry).rounded(.down))...Int((cy + ry).rounded(.up)) {
                for x in Int((cx - rx).rounded(.down))...Int((cx + rx).rounded(.up)) {
                    let nx = (Double(x) + 0.5 - cx) / rx, ny = (Double(y) + 0.5 - cy) / ry
                    guard nx * nx + ny * ny <= 1, clip(x, y) else { continue }
                    self[x, y] = ramp[Painter.tone(nx, ny, ramp.count, bias: bias)]
                }
            }
        }

        /// Cápsula sombreada de A a B (brazos, mangos, trenzas), con radio que puede variar de `ra` a `rb`.
        mutating func capsule(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double, _ ra: Double, _ rb: Double,
                              _ ramp: [UInt32], bias: Double = 0, roundEnds: Bool = true, maxY: Int = .max) {
            let vx = bx - ax, vy = by - ay
            let len2 = vx * vx + vy * vy
            let len = len2.squareRoot()
            let px = -vy / len, py = vx / len   // perpendicular
            let r = max(ra, rb)
            for y in Int((min(ay, by) - r).rounded(.down))...Int((max(ay, by) + r).rounded(.up)) where y <= maxY {
                for x in Int((min(ax, bx) - r).rounded(.down))...Int((max(ax, bx) + r).rounded(.up)) {
                    let qx = Double(x) + 0.5 - ax, qy = Double(y) + 0.5 - ay
                    var t = (qx * vx + qy * vy) / len2
                    if !roundEnds && (t < 0 || t > 1) { continue }
                    t = min(1, max(0, t))
                    let cxp = ax + vx * t, cyp = ay + vy * t
                    let rr = ra + (rb - ra) * t
                    let dx = Double(x) + 0.5 - cxp, dy = Double(y) + 0.5 - cyp
                    let d2 = dx * dx + dy * dy
                    guard d2 <= rr * rr else { continue }
                    let s = (dx * px + dy * py) / rr   // -1…1 a lo ancho
                    let along = (dx * vx + dy * vy) / len / rr
                    self[x, y] = ramp[Painter.tone(s * px + along * vx / len * 0.6, s * py + along * vy / len * 0.6,
                                                   ramp.count, bias: bias)]
                }
            }
        }

        /// Sello de filas de caracteres con paleta ('.' o caracteres sin color = transparente).
        mutating func stamp(_ rows: [String], _ pal: [Character: UInt32], _ ox: Int, _ oy: Int, flip: Bool = false) {
            for (y, row) in rows.enumerated() {
                let chars = Array(row)
                for (x, ch) in chars.enumerated() {
                    guard let c = pal[ch] else { continue }
                    self[flip ? ox + chars.count - 1 - x : ox + x, oy + y] = c
                }
            }
        }

        /// Pinta en una capa aparte y la pone encima, oscureciendo 1 px por debajo (sombra proyectada).
        mutating func overlay(shadow: (UInt32) -> UInt32, offsets: [(Int, Int)] = [(0, 1)], _ build: (inout Painter) -> Void) {
            var layer = Painter(width: g.width, height: g.height)
            layer.dy = dy
            build(&layer)
            let base = g
            for y in 0..<g.height {
                for x in 0..<g.width where layer.g[x, y] != nil {
                    for (ox, oy) in offsets where layer.g[x + ox, y + oy] == nil {
                        if let c = base[x + ox, y + oy] { g[x + ox, y + oy] = shadow(c) }
                    }
                }
            }
            g.draw(layer.g, x: 0, y: 0)
        }

        mutating func put(_ x: Int, _ y: Int, _ c: UInt32) { self[x, y] = c }

        /// Mezcla el pixel con un color (si existe).
        mutating func tint(_ x: Int, _ y: Int, _ c: UInt32, _ t: Double) {
            if let old = self[x, y] { self[x, y] = DwarfSmithArt.mix(old, c, t) }
        }

        /// Mueve el pixel `steps` tonos dentro de la rampa (si es de esa rampa).
        mutating func shift(_ x: Int, _ y: Int, _ ramp: [UInt32], _ steps: Int) {
            guard let old = self[x, y], let i = ramp.firstIndex(of: old) else { return }
            self[x, y] = ramp[max(0, min(ramp.count - 1, i + steps))]
        }

        mutating func line(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ c: UInt32) {
            var x = x0, y = y0
            let dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1
            let dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1
            var err = dx + dy
            while true {
                self[x, y] = c
                if x == x1 && y == y1 { break }
                let e2 = 2 * err
                if e2 >= dy { err += dy; x += sx }
                if e2 <= dx { err += dx; y += sy }
            }
        }

        /// Contraluz naranja de la fragua en los bordes de la silueta (más fuerte a la derecha) hasta la fila `maxY`.
        mutating func forgeRim(maxY: Int) {
            let src = g
            for y in 0..<min(maxY, g.height) {
                for x in 0..<g.width {
                    guard let c = src[x, y] else { continue }
                    var t = 0.0
                    if src[x + 1, y] == nil { t = max(t, 0.6) }
                    else if src[x + 2, y] == nil { t = max(t, 0.28) }
                    if src[x - 1, y] == nil { t = max(t, 0.38) }
                    if src[x, y - 1] == nil { t = max(t, 0.3) }
                    if t > 0 { g[x, y] = DwarfSmithArt.mix(c, DwarfSmithArt.ember, t) }
                }
            }
        }
    }
}
