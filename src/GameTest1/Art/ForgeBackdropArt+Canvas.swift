import Foundation

// Herramientas de dibujo de la forja del enano: un lienzo con color "sin luz" y cuánto brilla cada
// pixel por sí mismo, y un pase de luz horneada (fragua cálida, ventanuco frío) al final.

/// Lienzo de trabajo de la forja. `glow` = 0 recibe la luz de la escena; 255 brilla por sí mismo (fuego, brasas).
struct ForgeLayer {
    let w: Int
    let h: Int
    var px: [UInt32?]
    var glow: [UInt8]

    init(_ w: Int, _ h: Int) {
        self.w = max(1, w)
        self.h = max(1, h)
        px = Array(repeating: nil, count: self.w * self.h)
        glow = Array(repeating: 0, count: self.w * self.h)
    }

    @inline(__always) func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h }

    @inline(__always) func at(_ x: Int, _ y: Int) -> UInt32? { inside(x, y) ? px[y * w + x] : nil }

    @inline(__always) mutating func put(_ x: Int, _ y: Int, _ c: UInt32, glow g: UInt8 = 0) {
        guard inside(x, y) else { return }
        px[y * w + x] = c
        glow[y * w + x] = g
    }

    mutating func rect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int, _ c: UInt32, glow g: UInt8 = 0) {
        let y0 = max(0, y), y1 = min(h, y + rh), x0 = max(0, x), x1 = min(w, x + rw)
        guard y1 > y0, x1 > x0 else { return }
        for yy in y0..<y1 {
            for xx in x0..<x1 { px[yy * w + xx] = c; glow[yy * w + xx] = g }
        }
    }

    mutating func hline(_ x: Int, _ y: Int, _ len: Int, _ c: UInt32, glow g: UInt8 = 0) { rect(x, y, len, 1, c, glow: g) }
    mutating func vline(_ x: Int, _ y: Int, _ len: Int, _ c: UInt32, glow g: UInt8 = 0) { rect(x, y, 1, len, c, glow: g) }

    mutating func line(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ c: UInt32, glow g: UInt8 = 0) {
        var x = x0, y = y0
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            put(x, y, c, glow: g)
            if x == x1 && y == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x += sx }
            if e2 <= dx { err += dx; y += sy }
        }
    }

    /// Elipse rellena con centro en medio pixel si hace falta (`cx`, `cy` pueden ser x.5).
    mutating func disc(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ c: UInt32, glow g: UInt8 = 0) {
        for y in Int(floor(cy - ry))...Int(ceil(cy + ry)) {
            for x in Int(floor(cx - rx))...Int(ceil(cx + rx)) {
                let dx = (Double(x) + 0.5 - cx) / rx, dy = (Double(y) + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1 { put(x, y, c, glow: g) }
            }
        }
    }

    /// Multiplica el color que ya hay (sombras, hollín).
    @inline(__always) mutating func shade(_ x: Int, _ y: Int, _ f: Double) {
        guard inside(x, y), let c = px[y * w + x] else { return }
        px[y * w + x] = VillageArt.scale(c, (f, f, f))
    }

    mutating func shadeRect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int, _ f: Double) {
        for yy in y..<(y + max(0, rh)) { for xx in x..<(x + max(0, rw)) { shade(xx, yy, f) } }
    }

    /// Mezcla el color que ya hay hacia `c`.
    @inline(__always) mutating func tint(_ x: Int, _ y: Int, _ c: UInt32, _ t: Double) {
        guard inside(x, y), let old = px[y * w + x] else { return }
        px[y * w + x] = TownArt.mix(old, c, t)
    }

    /// Pega otra capa encima (sus pixeles opacos).
    mutating func paste(_ o: ForgeLayer, _ ox: Int, _ oy: Int) {
        for y in 0..<o.h {
            let ty = oy + y
            guard ty >= 0, ty < h else { continue }
            for x in 0..<o.w {
                let tx = ox + x
                guard tx >= 0, tx < w, let c = o.px[y * o.w + x] else { continue }
                px[ty * w + tx] = c
                glow[ty * w + tx] = o.glow[y * o.w + x]
            }
        }
    }

    /// Oscurece lo que hay debajo con la silueta de `o` desplazada (sombra proyectada sobre la pared).
    mutating func castShadow(_ o: ForgeLayer, _ ox: Int, _ oy: Int, dx: Int, dy: Int, _ f: Double) {
        for y in 0..<o.h {
            for x in 0..<o.w where o.px[y * o.w + x] != nil {
                let tx = ox + x + dx, ty = oy + y + dy
                guard inside(tx, ty), glow[ty * w + tx] < 128 else { continue }
                // Sombra con borde tramado: más suave en los bordes de la silueta.
                shade(tx, ty, f)
            }
        }
    }

    /// Pega con contorno oscuro y sombra hacia la derecha (la luz viene de la fragua, a la izquierda).
    mutating func place(_ o: ForgeLayer, _ x: Int, _ y: Int, outline: UInt32 = ForgePal.outline,
                        shadow: (dx: Int, dy: Int, f: Double)? = (2, 1, 0.55)) {
        let lined = o.outlined(outline)
        if let s = shadow { castShadow(lined, x - 1, y - 1, dx: s.dx, dy: s.dy, s.f) }
        paste(lined, x - 1, y - 1)
    }

    /// Contorno de 1 pixel alrededor de lo opaco (agranda 1 px por lado).
    func outlined(_ c: UInt32) -> ForgeLayer {
        var out = ForgeLayer(w + 2, h + 2)
        out.paste(self, 1, 1)
        for y in 0..<out.h {
            for x in 0..<out.w where out.px[y * out.w + x] == nil {
                if at(x - 2, y - 1) != nil || at(x, y - 1) != nil || at(x - 1, y - 2) != nil || at(x - 1, y) != nil {
                    out.px[y * out.w + x] = c
                }
            }
        }
        return out
    }

    func flippedX() -> ForgeLayer {
        var out = ForgeLayer(w, h)
        for y in 0..<h { for x in 0..<w { out.px[y * w + (w - 1 - x)] = px[y * w + x]; out.glow[y * w + (w - 1 - x)] = glow[y * w + x] } }
        return out
    }

    /// Sin luz: tal cual (para capas transparentes como las chispas).
    var grid: PixelGrid {
        var g = PixelGrid(width: w, height: h)
        g.pixels = px
        return g
    }
}

/// Una luz horneada: aclara y tiñe alrededor de un punto.
struct ForgeLight {
    var x: Double
    var y: Double
    var radius: Double
    var power: Double
    /// Tinte por canal (r, g, b).
    var color: (Double, Double, Double)
    /// Achatamiento vertical (1 = círculo).
    var squash: Double = 1
}

extension ForgeLayer {
    /// Aplica la luz a todo lo que no brilla por sí mismo. La intensidad se cuantiza con tramado
    /// ordenado (bandas de luz como en los 16 bits) para no llenar el dibujo de degradados lisos.
    func lit(lights: [ForgeLight], ambient: (Double, Double, Double), fill: UInt32 = 0x000000) -> PixelGrid {
        var g = PixelGrid(width: w, height: h)
        let steps = 7.0
        for y in 0..<h {
            for x in 0..<w {
                let i = y * w + x
                let c = px[i] ?? fill
                var f = ambient
                let b = TownArt.bayer(x, y)
                for l in lights {
                    let dx = Double(x) - l.x, dy = (Double(y) - l.y) / l.squash
                    let d = (dx * dx + dy * dy).squareRoot()
                    guard d < l.radius else { continue }
                    var t = 1 - d / l.radius
                    t = t * t
                    t = (t * steps + (b - 0.5) * 0.9).rounded() / steps
                    if t <= 0 { continue }
                    f.0 += t * l.power * l.color.0
                    f.1 += t * l.power * l.color.1
                    f.2 += t * l.power * l.color.2
                }
                var out = VillageArt.scale(c, f)
                let gl = glow[i]
                if gl > 0 { out = TownArt.mix(out, c, Double(gl) / 255) }
                g.pixels[i] = out
            }
        }
        return g
    }
}

/// Paleta de la forja. Rampas de oscuro a claro.
enum ForgePal {
    static let outline: UInt32 = 0x1A1214
    static let stone: [UInt32] = [0x1C1514, 0x3A2F2B, 0x483B35, 0x574840, 0x6A594E, 0x7E6C5E]
    static let floor: [UInt32] = [0x161110, 0x2E2522, 0x3A2F2A, 0x463932, 0x54453C, 0x66554A]
    static let brick: [UInt32] = [0x2A1612, 0x5A2A1E, 0x723826, 0x8A4630, 0xA45A3E, 0xBE7452]
    static let hotBrick: [UInt32] = [0x4A140C, 0x8A2A14, 0xB8401A, 0xE0662A, 0xFF9A48]
    static let wood: [UInt32] = [0x22150F, 0x3E2819, 0x563622, 0x6E472C, 0x8A5C3A, 0xA6764C]
    static let darkWood: [UInt32] = [0x1A100C, 0x2E1D14, 0x40291C, 0x543624, 0x6A4630]
    static let iron: [UInt32] = [0x16141A, 0x2C2A32, 0x46434C, 0x635F68, 0x8A8690, 0xBCB8C2, 0xEEECF2]
    static let steel: [UInt32] = [0x22283A, 0x3C4458, 0x5E687C, 0x8692A6, 0xB6C0D0, 0xEEF4FF]
    static let copper: [UInt32] = [0x2E140C, 0x5A2A16, 0x8A4424, 0xB4643A, 0xD88A56, 0xF4BC8A]
    static let gold: [UInt32] = [0x4A2E0E, 0x8A5C1C, 0xC08E2E, 0xE8BC4A, 0xFFE48A, 0xFFF8D0]
    static let leather: [UInt32] = [0x2A160E, 0x4A2818, 0x683A22, 0x86502E, 0xA26A40]
    static let fire: [UInt32] = [0x5A1006, 0xA0240E, 0xE0541A, 0xFF8C2A, 0xFFC24A, 0xFFEA94, 0xFFFBE0]
    static let coal: [UInt32] = [0x100C0E, 0x1E1A1E, 0x2E292C, 0x48403E]
    static let water: [UInt32] = [0x0E1A26, 0x1A3042, 0x2A4A60, 0x46708A, 0x7EA6BC, 0xC6E2EC]
    static let sky: [UInt32] = [0x1E3A6A, 0x2E5A9A, 0x4A86C8, 0x86BCEA, 0xD0ECFF]
    static let red: [UInt32] = [0x3A0C10, 0x64161A, 0x8E2424, 0xB43A30, 0xD25A44]
    static let blue: [UInt32] = [0x101A3A, 0x1C2E5E, 0x2C4A86, 0x4268AA, 0x6A90CC]
    static let ruby: [UInt32] = [0x4A0814, 0x8E1428, 0xD8304A, 0xFF7A8C, 0xFFD6DC]
    static let emerald: [UInt32] = [0x08341E, 0x146A38, 0x28A85A, 0x6AE896, 0xD4FFE4]
    static let sapphire: [UInt32] = [0x0C1A52, 0x1A3AA0, 0x3A72E8, 0x86B6FF, 0xE0EEFF]
    static let amethyst: [UInt32] = [0x2A0E4A, 0x4E1E86, 0x8248C8, 0xBC90F4, 0xF0E2FF]
    static let mithril: [UInt32] = [0x1E3A4A, 0x3A6E84, 0x64A8C0, 0xA4E0EC, 0xEAFCFF]
    static let rope: [UInt32] = [0x3A2A16, 0x5E4626, 0x86683A, 0xA88A52]
    static let cloth: [UInt32] = [0x2E2418, 0x4E3E28, 0x6E5A3A, 0x8C7650]
}

extension ForgeBackdropArt {
    @inline(__always) static func h(_ x: Int, _ y: Int, _ s: Int = 0) -> Int { TownArt.hash(x, y, s) }
    @inline(__always) static func chance(_ x: Int, _ y: Int, _ s: Int, _ p: Double) -> Bool { TownArt.chance(x, y, s, p) }
    @inline(__always) static func ramp(_ r: [UInt32], _ i: Int) -> UInt32 { r[max(0, min(r.count - 1, i))] }
    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 { TownArt.mix(a, b, t) }
}
