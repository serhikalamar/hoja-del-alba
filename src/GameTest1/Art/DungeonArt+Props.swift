import Foundation
import GameCore

// Obstáculos altos de la mazmorra (se dibujan aparte para que los personajes pasen por detrás) y llamas.
// Las figuras se modelan con siluetas (máscara) que se "esculpen" solas: claro arriba-izquierda, oscuro
// abajo-derecha; luego se añaden los detalles a mano. Cada tema tiene sus propias piezas:
//   prison  pilar de sillares, caballero, gárgola, cajas, barriles y sacos
//   crypt   columna estriada con anillo de oro, rey, plañidera encapuchada, urnas
//   sewer   pilar de ladrillo con musgo, fuente-gárgola, barriles con limo
//   mine    puntal de madera, enano minero, cristales gigantes, vagoneta de cristal, dinamita
//   forge   columna de basalto con flejes, enano herrero, ídolo con cuernos, yunque, carbón y lingotes

enum DungeonProps {
    static func sprite(_ tile: DungeonTile, style s: DungeonStyle, variant v: Int) -> DCanvas? {
        var p: PropPainter
        switch tile {
        case .pillar: p = PropPainter(24, 52, s); p.pillar(v)
        case .statue: p = PropPainter(24, 52, s); p.statue(v)
        case .brazier: p = PropPainter(18, 28, s); p.brazier(v)
        case .crates: p = PropPainter(24, 32, s); p.crates(v)
        case .chest: p = PropPainter(22, 18, s); p.chest(v)
        case .altar: p = PropPainter(48, 34, s); p.altar(v)
        default: return nil
        }
        return p.trimmed()
    }

    /// Llama de 10×16 que ondea; todos los frames miden lo mismo y apoyan la base abajo-centro.
    static func flame(_ s: DungeonStyle, frame: Int) -> DCanvas {
        let w = 10, h = 16
        var c = DCanvas(w, h)
        let f = s.flame
        let ph = Double(frame) / Double(DungeonArt.flameFrames) * 2 * Double.pi
        let tip = 2 + Int(((1 + sin(ph * 2)) * 1.5).rounded())          // 2...5: la llama crece y mengua
        for y in tip..<h {
            let u = Double(y - tip) / Double(h - 1 - tip)                  // 0 punta → 1 base
            var half = 4.4 * pow(u, 0.55)
            if u > 0.82 { half *= 1 - (u - 0.82) * 1.6 }                   // base redondeada
            let sway = 1.7 * sin(ph + Double(y) * 0.45) * (1 - u) * (1 - u)
            let cx = 4.5 + sway
            for x in 0..<w {
                let dx = abs(Double(x) + 0.5 - cx)
                guard dx <= half + 0.35 else { continue }
                let dn = dx / max(0.6, half)
                var col: UInt32
                if dn < 0.38 && u > 0.5 { col = f[4] }
                else if dn < 0.62 && u > 0.28 { col = f[3] }
                else if dn < 0.86 && u > 0.12 { col = f[2] }
                else { col = f[1] }
                if u < 0.12 || (dn > 0.95 && u < 0.5) { col = f[0] }
                c.put(x, y, col)
            }
        }
        // Chispas que suben.
        let sx = 2 + (frame * 3) % 6, sy = max(0, tip - 1 - frame % 3)
        if frame % 2 == 0 { c.put(sx, sy, f[3]) } else { c.put(9 - sx, sy, f[2]) }
        return c
    }
}

/// Lienzo de un obstáculo con su máscara de modelado.
struct PropPainter {
    var c: DCanvas
    let s: DungeonStyle
    private var mask: [Bool]

    init(_ w: Int, _ h: Int, _ s: DungeonStyle) {
        c = DCanvas(w, h)
        self.s = s
        mask = Array(repeating: false, count: w * h)
    }

    var w: Int { c.w }
    var h: Int { c.h }

    /// Recorta las filas vacías de arriba (el brasero necesita su cuenco arriba del todo).
    func trimmed() -> DCanvas {
        var first = 0
        outer: for y in 0..<h {
            for x in 0..<w where c.px[y * w + x] != 0 { first = y; break outer }
        }
        guard first > 0 else { return c }
        var out = DCanvas(w, h - first)
        for y in first..<h { for x in 0..<w { out.px[(y - first) * w + x] = c.px[y * w + x] } }
        return out
    }

    // MARK: Máscara

    private func m(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && mask[y * w + x] }
    mutating func mark(_ x: Int, _ y: Int) { if x >= 0 && y >= 0 && x < w && y < h { mask[y * w + x] = true } }
    mutating func mRect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int) {
        for yy in y..<(y + rh) { for xx in x..<(x + rw) { mark(xx, yy) } }
    }
    mutating func mEllipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) {
        for yy in Int(cy - ry - 1)...Int(cy + ry + 1) {
            for xx in Int(cx - rx - 1)...Int(cx + rx + 1) {
                let dx = (Double(xx) + 0.5 - cx) / rx, dy = (Double(yy) + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1 { mark(xx, yy) }
            }
        }
    }
    mutating func mPoly(_ pts: [(Double, Double)]) {
        let ys = pts.map(\.1), xs = pts.map(\.0)
        for yy in Int(ys.min()!)...Int(ys.max()!) {
            for xx in Int(xs.min()!)...Int(xs.max()!) {
                let px = Double(xx) + 0.5, py = Double(yy) + 0.5
                var inside = false
                var j = pts.count - 1
                for i in 0..<pts.count {
                    let (xi, yi) = pts[i], (xj, yj) = pts[j]
                    if (yi > py) != (yj > py) && px < (xj - xi) * (py - yi) / (yj - yi) + xi { inside.toggle() }
                    j = i
                }
                if inside { mark(xx, yy) }
            }
        }
    }
    mutating func mLine(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ thick: Double) {
        let n = Int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in 0...n {
            let t = Double(i) / Double(n)
            mEllipse(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, thick / 2, thick / 2)
        }
    }

    /// Pinta la silueta con luz arriba-izquierda y limpia la máscara.
    mutating func sculpt(_ ramp: [UInt32], light: Double = 0, speckle: Bool = true) {
        for y in 0..<h {
            for x in 0..<w where m(x, y) {
                var v = 2.0 + light
                if !m(x - 1, y) { v += 1.3 } else if !m(x - 2, y) { v += 0.55 }
                if !m(x, y - 1) { v += 0.9 }
                if !m(x + 1, y) { v -= 1.2 } else if !m(x + 2, y) { v -= 0.5 }
                if !m(x, y + 1) { v -= 0.7 }
                var k = Int(v.rounded())
                if speckle && Noise.hash(x, y, 31) < 0.05 { k -= 1 }
                c.put(x, y, ramp[max(0, min(ramp.count - 1, k))])
            }
        }
        mask = Array(repeating: false, count: w * h)
    }

    // MARK: Formas básicas

    /// Bloque en 3/4: cara de arriba (`top` filas) y cara frontal.
    mutating func box(_ x: Int, _ y: Int, _ bw: Int, _ bh: Int, top: Int, _ r: [UInt32]) {
        for yy in 0..<bh {
            for xx in 0..<bw {
                var col: UInt32
                if yy < top {
                    col = yy == 0 ? r[2] : yy == top - 1 ? r[4] : r[3]
                    if xx == 0 { col = r[4] } else if xx == bw - 1 { col = r[2] }
                } else {
                    col = yy == bh - 1 ? r[0] : yy == bh - 2 ? r[1] : r[2]
                    if xx == 0 { col = r[3] } else if xx == bw - 1 { col = r[1] }
                }
                c.put(x + xx, y + yy, col)
            }
        }
    }

    /// Cilindro vertical con brillo a un cuarto desde la izquierda.
    mutating func cylinder(_ x: Int, _ y: Int, _ cw: Int, _ ch: Int, _ r: [UInt32]) {
        for xx in 0..<cw {
            let u = (Double(xx) + 0.5) / Double(cw)
            let k = u < 0.1 ? 3 : u < 0.32 ? 4 : u < 0.55 ? 3 : u < 0.8 ? 2 : 1
            c.vline(x + xx, y, ch, r[k])
        }
    }

    /// Tono de un material fuera de los del estilo.
    static let clay: [UInt32] = [0x3A2220, 0x5E3A2E, 0x845440, 0xA87458, 0xCC9C78]
    static let cloth: [UInt32] = [0x3A3020, 0x5E5034, 0x7E6E48, 0x9E8E62, 0xBEB084]
    static let coal: [UInt32] = [0x0E0C0E, 0x1A1618, 0x2A2428, 0x3E363A, 0x5A5056]
    static let leaf: [UInt32] = [0x1E2A16, 0x2E4220, 0x44602C, 0x5E7E3A, 0x80A050]

    /// Puntos de musgo en la parte de abajo de lo ya pintado.
    mutating func mossBase(_ x0: Int, _ x1: Int, _ y: Int, _ height: Int, salt: Int) {
        for x in x0...x1 {
            let hh = Int(Noise.hash(x, salt, 3) * Double(height))
            for k in 0..<hh where c.at(x, y - k) != nil { c.put(x, y - k, s.moss[k == hh - 1 ? 3 : (k & 1) + 1]) }
        }
    }

    // MARK: - Pilar

    mutating func pillar(_ v: Int) {
        let st = s.stone
        let broken = v == 2
        switch s.theme {
        case .mine:
            if v == 2 { crystalColumn(); return }
            minePost(lantern: v == 3)
            return
        default: break
        }
        // Basa en dos escalones.
        box(1, 44, 22, 8, top: 3, st)
        box(3, 39, 18, 6, top: 2, st)
        let shaftTop = broken ? 18 : 9
        let x0 = 5, sw = 14
        switch s.theme {
        case .prison:
            // Pilar cuadrado de sillares: cara izquierda iluminada, frente y lado derecho en sombra.
            for y in shaftTop..<39 {
                for xx in 0..<sw {
                    var col = xx < 3 ? st[3] : xx < 11 ? st[2] : st[1]
                    if xx == 0 { col = st[4] } else if xx == sw - 1 { col = st[0] }
                    let k = (y - 9) % 8
                    if k == 0 { col = st[0] } else if k == 1 && xx < sw - 1 { col = DColor.mix(col, st[4], 0.4) }
                    if xx == 3 && k != 0 { col = DColor.mix(col, st[4], 0.25) }
                    c.put(x0 + xx, y, col)
                }
            }
        case .crypt:
            cylinder(x0, shaftTop, sw, 39 - shaftTop, st)
            for fx in stride(from: x0 + 2, to: x0 + sw - 1, by: 3) { c.vline(fx, shaftTop + 2, 37 - shaftTop, DColor.mix(c.at(fx, 30) ?? st[2], st[0], 0.45)) }
            if !broken { c.hline(x0, 11, sw, s.trim[3]); c.hline(x0, 12, sw, s.trim[1]); c.put(x0 + 3, 11, s.trim[4]) }
            c.hline(x0, 37, sw, s.trim[2]); c.hline(x0, 38, sw, s.trim[0])
        case .sewer:
            // Pilar de ladrillo.
            for y in shaftTop..<39 {
                for xx in 0..<sw {
                    let row = (y - shaftTop) / 4, ly = (y - shaftTop) % 4
                    let bx = (xx + (row & 1) * 3) % 6
                    var col = xx < 3 ? s.wall[3] : xx < 11 ? s.wall[2] : s.wall[1]
                    if ly == 0 || bx == 0 { col = s.wall[0] } else if ly == 1 { col = DColor.mix(col, s.wall[4], 0.3) }
                    if xx == 0 { col = s.wall[4] } else if xx == sw - 1 { col = s.wall[0] }
                    c.put(x0 + xx, y, col)
                }
            }
        default:
            // Basalto con flejes de hierro.
            cylinder(x0, shaftTop, sw, 39 - shaftTop, st)
            let ir = s.iron
            for by in [14, 26, 35] where by > shaftTop {
                cylinder(x0 - 1, by, sw + 2, 2, ir)
                c.put(x0 + 2, by, ir[4]); c.put(x0 + 7, by, ir[4]); c.put(x0 + 12, by, ir[3])
            }
        }
        if broken {
            // Rotura irregular con la sección a la vista.
            for xx in 0..<sw {
                let top = shaftTop + Int(Noise.hash(xx, 1, Int(s.theme.rawValue.count)) * 6)
                for y in shaftTop..<top { c.clear(x0 + xx, y) }
                c.put(x0 + xx, top, st[4]); c.put(x0 + xx, top + 1, st[3])
            }
            // Cascotes al pie.
            box(0, 46, 5, 4, top: 2, st); box(19, 47, 4, 3, top: 1, st)
            c.put(3, 44, st[3]); c.put(21, 45, st[2])
        } else {
            // Capitel.
            for (i, row) in [(4, 2), (5, 3), (6, 4), (7, 5), (8, 5)] .enumerated() {
                let (y, inset) = row
                for xx in inset..<(24 - inset) {
                    let u = Double(xx - inset) / Double(24 - 2 * inset)
                    var col = u < 0.12 ? st[3] : u < 0.35 ? st[4] : u < 0.7 ? st[2] : st[1]
                    if i == 0 { col = st[3] }
                    if i == 4 { col = st[0] }
                    c.put(xx, y, col)
                }
            }
            box(1, 0, 22, 5, top: 2, st)
            if s.theme == .forge {
                // Runas incandescentes en el capitel.
                for k in 0..<4 { c.put(6 + k * 4, 3, s.magic[k & 1 == 0 ? 2 : 1]) }
            }
        }
        // Detalles por variante.
        switch v {
        case 1:
            // Grietas y musgo (o hollín en la forja).
            var y = shaftTop + 6, x = 10
            for _ in 0..<9 { c.put(x, y, st[0]); x += Noise.hash(x, y, 2) > 0.5 ? 1 : 0; y += 1 }
            if s.theme == .forge {
                for k in 0..<6 { c.put(9 + k % 2, 20 + k * 2, s.magic[k % 3 == 0 ? 2 : 1]) }
            } else {
                mossBase(1, 22, 51, 7, salt: 4); mossBase(5, 18, 38, 9, salt: 5)
            }
        case 3:
            if s.theme == .crypt {
                // Velas al pie.
                for (vx, vh) in [(2, 5), (19, 4), (21, 3)] {
                    c.rect(vx, 44 - vh, 2, vh, s.bone[3]); c.put(vx, 44 - vh, s.bone[4])
                    c.put(vx, 42 - vh, s.flame[3]); c.put(vx, 43 - vh, s.flame[2])
                }
            } else if s.theme == .sewer {
                // Tubería que sube por el pilar.
                cylinder(15, 12, 4, 30, s.iron); c.hline(14, 18, 6, s.iron[4]); c.hline(14, 32, 6, s.iron[4])
                mossBase(14, 19, 41, 6, salt: 9)
            } else {
                // Cadenas con grilletes enrolladas.
                let ir = s.iron
                for k in 0..<6 {
                    let y = 20 + k * 2
                    c.put(6 + k, y, ir[3]); c.put(7 + k, y, ir[1])
                }
                c.vline(12, 32, 6, ir[2]); c.put(11, 38, ir[3]); c.put(13, 38, ir[3]); c.put(12, 39, ir[1])
            }
        default:
            if s.theme == .sewer { mossBase(1, 22, 51, 5, salt: 2) }
        }
    }

    /// Puntal de madera de la mina con su viga y tornapuntas.
    private mutating func minePost(lantern: Bool) {
        let wd = s.wood
        // Montón de piedras en la base.
        mEllipse(12, 48, 10, 4); sculpt(s.stone)
        for (px, py) in [(4, 46), (16, 45), (10, 47)] { c.put(px, py, s.stone[4]); c.put(px + 1, py + 1, s.stone[1]) }
        // Poste.
        for y in 6..<48 {
            for xx in 0..<8 {
                var col = xx == 0 ? wd[4] : xx < 3 ? wd[3] : xx < 6 ? wd[2] : xx == 7 ? wd[0] : wd[1]
                if Noise.hash(xx, y / 4, 7) < 0.12 { col = wd[1] }
                c.put(8 + xx, y, col)
            }
        }
        // Viga.
        box(0, 2, 24, 7, top: 2, wd)
        for k in stride(from: 3, to: 22, by: 5) { c.put(k, 6, wd[1]); c.put(k + 1, 6, wd[1]) }
        // Tornapuntas.
        for i in 0..<7 {
            c.put(8 - i, 15 - i, wd[3]); c.put(8 - i, 16 - i, wd[1])
            c.put(15 + i, 15 - i, wd[2]); c.put(15 + i, 16 - i, wd[0])
        }
        c.put(9, 9, s.iron[4]); c.put(14, 9, s.iron[4]); c.put(10, 30, s.iron[3])
        if lantern {
            let ir = s.iron
            c.vline(19, 9, 3, ir[2])
            c.rect(17, 12, 5, 7, ir[1]); c.hline(17, 12, 5, ir[3])
            c.rect(18, 13, 3, 5, s.flame[3]); c.put(19, 14, s.flame[4])
            c.hline(17, 19, 5, ir[2])
        } else {
            // Pico apoyado.
            c.line(3, 47, 6, 30, wd[3]); c.line(4, 47, 7, 30, wd[1])
            c.line(2, 31, 9, 29, s.iron[3]); c.put(1, 32, s.iron[2]); c.put(10, 29, s.iron[4])
        }
    }

    /// Columna de roca con cristales (mina).
    private mutating func crystalColumn() {
        mPoly([(4, 52), (6, 20), (10, 8), (16, 10), (19, 24), (21, 52)])
        sculpt(s.stone)
        for y in stride(from: 14, to: 50, by: 6) { c.hline(7, y, 5, s.stone[1]) }
        crystal(14, 24, 10, 3, s.magic)
        crystal(6, 36, 7, 2, s.magic)
        crystal(18, 44, 6, 2, s.magic)
    }

    /// Cristal con cara iluminada, cara en sombra y brillo.
    mutating func crystal(_ x: Int, _ baseY: Int, _ len: Int, _ half: Int, _ m: [UInt32], tilt: Int = 0) {
        for k in 0..<len {
            let ww = k > len - 3 ? max(0, half - (k - (len - 3))) : half
            let cx = x + (tilt * k) / max(1, len)
            for i in -ww...ww {
                let col = i < 0 ? m[3] : i == 0 ? m[4] : m[1]
                c.put(cx + i, baseY - k, col)
            }
        }
        c.put(x, baseY - len, m[4])
    }

    // MARK: - Estatuas

    mutating func statue(_ v: Int) {
        let st = s.stone
        switch s.theme {
        case .mine where v % 2 == 1:
            crystalFormation(); return
        case .sewer where v % 2 == 0:
            fountain(); return
        default: break
        }
        // Pedestal con moldura.
        box(2, 42, 20, 10, top: 3, st)
        c.hline(3, 47, 18, st[1]); c.hline(3, 48, 18, st[3])
        switch (s.theme, v % 4) {
        case (.prison, 0), (.prison, 2): knight()
        case (.prison, _): gargoyle()
        case (.crypt, 0), (.crypt, 2): king()
        case (.crypt, 1): mourner()
        case (.crypt, _): gargoyle()
        case (.sewer, _): mourner()
        case (.mine, _): dwarf(smith: false)
        case (.forge, 0), (.forge, 2): dwarf(smith: true)
        case (.forge, _): idol()
        }
        if s.theme == .sewer || (s.theme == .prison && v >= 2) { mossBase(2, 21, 51, 6, salt: v); mossBase(6, 18, 43, 4, salt: v + 9) }
        if s.theme == .crypt && v == 2 {
            // Placa dorada en el pedestal.
            c.rect(9, 46, 6, 3, s.trim[2]); c.hline(9, 46, 6, s.trim[3])
        }
    }

    private mutating func knight() {
        let st = s.stone
        // Capa por detrás.
        mPoly([(7, 19), (17, 19), (19, 43), (5, 43)]); sculpt(st, light: -0.6)
        mRect(8, 35, 3, 8); mRect(13, 35, 3, 8)                 // piernas
        mPoly([(7, 28), (17, 28), (18, 36), (6, 36)])            // faldar
        mRect(7, 19, 10, 10)                                     // torso
        mEllipse(6.5, 20.5, 3.2, 2.6); mEllipse(17.5, 20.5, 3.2, 2.6)
        mLine(5.5, 22, 10, 27, 3); mLine(18.5, 22, 14, 27, 3)    // brazos hacia la empuñadura
        mRect(10, 17, 4, 3)
        mEllipse(12, 13.5, 4.2, 4.6)                             // yelmo
        sculpt(st)
        // Cimera.
        mEllipse(12, 8, 1.6, 2.2); mEllipse(14, 8.5, 2, 1.4); sculpt(st, light: 0.3)
        // Rendija del yelmo, peto y cinto.
        c.hline(9, 13, 6, st[0]); c.put(12, 14, st[0]); c.put(12, 15, st[1])
        c.vline(12, 20, 7, st[1]); c.hline(7, 28, 10, st[1]); c.put(12, 28, st[4])
        // Espada clavada delante.
        c.vline(11, 29, 14, st[4]); c.vline(12, 29, 14, st[2]); c.put(11, 42, st[3])
        c.hline(8, 28, 8, st[3]); c.hline(8, 29, 8, st[1])
        c.rect(11, 25, 2, 3, st[1]); c.put(11, 24, st[4]); c.put(12, 24, st[3])
        // Escudo en el brazo izquierdo.
        mPoly([(1, 23), (6, 23), (6, 31), (3.5, 34), (1, 31)]); sculpt(st, light: 0.2)
        c.vline(3, 25, 7, st[1]); c.hline(2, 27, 4, st[1])
    }

    private mutating func gargoyle() {
        let st = s.stone
        // Alas.
        mPoly([(7, 30), (1, 17), (0, 27), (3, 37)]); mPoly([(17, 30), (23, 17), (24, 27), (21, 37)])
        sculpt(st, light: -0.4)
        c.line(1, 18, 5, 31, st[0]); c.line(0, 25, 4, 33, st[1]); c.line(22, 18, 19, 31, st[0])
        mEllipse(12, 35, 7, 7)                                   // cuerpo
        mEllipse(7, 41.5, 3, 2); mEllipse(17, 41.5, 3, 2)        // patas
        mRect(8, 34, 3, 8); mRect(13, 34, 3, 8)                  // brazos
        sculpt(st)
        mEllipse(12, 26, 5, 4.2)                                 // cabeza
        mLine(8.5, 23, 6, 17.5, 2); mLine(15.5, 23, 18, 17.5, 2) // cuernos
        mEllipse(12, 29.5, 3, 2)                                 // hocico
        sculpt(st, light: 0.2)
        let eye: UInt32 = s.theme == .crypt ? s.magic[1] : 0xB8402A
        c.put(10, 26, eye); c.put(14, 26, eye)
        c.hline(10, 30, 5, st[0]); c.put(10, 31, st[4]); c.put(14, 31, st[4])
        for k in 0..<3 { c.put(9 + k * 3, 41, st[4]) }           // garras
    }

    private mutating func king() {
        let st = s.stone
        mPoly([(6, 19), (18, 19), (21, 43), (3, 43)]); sculpt(st, light: -0.5)   // manto
        mPoly([(8, 19), (16, 19), (17, 43), (7, 43)])                           // túnica
        mEllipse(6.5, 21, 2.8, 2.4); mEllipse(17.5, 21, 2.8, 2.4)
        mLine(6, 22, 10.5, 27, 3); mLine(18, 22, 13.5, 27, 3)
        mRect(10, 17, 4, 3)
        mEllipse(12, 14, 3.8, 4.2)
        sculpt(st)
        mPoly([(9, 16), (15, 16), (14, 22), (12, 24), (10, 22)]); sculpt(st, light: 0.4)   // barba
        c.hline(10, 14, 2, st[0]); c.hline(13, 14, 2, st[0])
        // Corona de oro.
        let g = s.trim
        c.hline(8, 11, 9, g[2]); c.hline(8, 10, 9, g[3])
        for k in [8, 10, 12, 14, 16] { c.put(k, 9, g[3]); c.put(k, 8, k == 12 ? g[4] : g[2]) }
        c.put(12, 10, s.magic[2])
        // Espada y cinto.
        c.vline(11, 29, 14, st[4]); c.vline(12, 29, 14, st[2])
        c.hline(9, 28, 6, g[2]); c.hline(9, 29, 6, g[0]); c.rect(11, 25, 2, 3, g[1]); c.put(11, 24, g[3])
        c.vline(8, 30, 13, st[1]); c.vline(16, 30, 13, st[1])
    }

    private mutating func mourner() {
        let st = s.stone
        mPoly([(8, 18), (16, 18), (20, 43), (4, 43)])
        mEllipse(12, 15, 5, 5.5)
        sculpt(st)
        // Cara en sombra bajo la capucha.
        mEllipse(12, 16.5, 2.6, 3); sculpt([st[0], st[0], st[0], st[1], st[1]], speckle: false)
        if s.theme == .sewer { c.put(11, 16, s.magic[1]); c.put(13, 16, s.magic[1]) }
        // Manos juntas y pliegues.
        mEllipse(12, 27, 2.5, 2); sculpt(st, light: 0.5)
        for (x0, x1) in [(9, 6), (12, 12), (15, 18)] { c.line(x0, 30, x1, 42, st[1]) }
        c.line(8, 20, 6, 30, st[3])
    }

    private mutating func dwarf(smith: Bool) {
        let st = s.stone
        mRect(8, 37, 3, 6); mRect(13, 37, 3, 6)
        mEllipse(7.5, 42.5, 2.5, 1.6); mEllipse(16.5, 42.5, 2.5, 1.6)
        mEllipse(12, 31, 6.8, 7)
        mEllipse(5, 29, 2.6, 4.2); mEllipse(19, 29, 2.6, 4.2)
        mEllipse(12, 20, 4.6, 4.6)
        sculpt(st)
        // Barba.
        mPoly([(7.5, 20), (16.5, 20), (15, 31), (12, 36), (9, 31)]); sculpt(st, light: 0.5)
        for k in 0..<4 { c.line(10 + k, 23, 10 + k, 33 - abs(k - 1), st[2]) }
        c.put(10, 19, st[0]); c.put(14, 19, st[0])
        c.hline(9, 27 + 7, 7, st[1])                              // cinturón
        if smith {
            // Martillo hacia abajo y delantal.
            c.vline(20, 27, 12, s.wood[3]); c.vline(21, 27, 12, s.wood[1])
            box(18, 38, 6, 5, top: 2, s.iron)
            c.hline(8, 17, 9, st[1])                              // cinta en la frente
        } else {
            // Casco con lámpara y pico al hombro.
            mPoly([(7, 19), (17, 19), (16, 14), (12, 12), (8, 14)]); sculpt(s.iron)
            c.put(12, 16, s.magic[3]); c.put(12, 15, s.magic[4])
            c.line(19, 34, 22, 13, s.wood[3]); c.line(20, 34, 23, 13, s.wood[1])
            c.line(16, 14, 23, 11, s.iron[3]); c.line(16, 15, 23, 12, s.iron[1]); c.put(15, 15, s.iron[2])
        }
    }

    private mutating func idol() {
        let st = s.stone
        mEllipse(12, 35, 8, 8)
        mRect(3, 26, 3, 12); mRect(18, 26, 3, 12)
        mEllipse(12, 23, 5.5, 5)
        sculpt(st)
        mLine(7.5, 21, 4, 14, 2.4); mLine(4, 14, 6, 10, 1.6)
        mLine(16.5, 21, 20, 14, 2.4); mLine(20, 14, 18, 10, 1.6)
        sculpt(st, light: 0.3)
        let m = s.magic
        c.put(10, 23, m[3]); c.put(14, 23, m[3]); c.put(9, 23, m[1]); c.put(15, 23, m[1])
        c.hline(10, 26, 5, m[1]); c.put(12, 26, m[2])
        // Runas en el vientre.
        c.vline(12, 31, 5, m[1]); c.hline(10, 33, 5, m[1]); c.put(12, 33, m[3])
    }

    /// Fuente con cabeza de gárgola que escupe agua (cloacas).
    private mutating func fountain() {
        let st = s.stone, l = s.liquid
        // Pilón.
        box(1, 40, 22, 12, top: 4, st)
        c.rect(3, 41, 18, 2, l[2]); c.hline(3, 41, 18, l[3]); c.put(6, 41, l[4]); c.put(15, 42, l[4])
        mossBase(1, 22, 51, 5, salt: 3)
        // Columna y cabeza.
        mRect(8, 22, 8, 18); sculpt(st)
        mEllipse(12, 18, 6, 5); mLine(8, 15, 5, 10, 2); mLine(16, 15, 19, 10, 2); sculpt(st, light: 0.2)
        mEllipse(12, 22.5, 3, 2.2); sculpt(st, light: 0.4)
        c.put(10, 17, s.magic[1]); c.put(14, 17, s.magic[1])
        c.hline(10, 23, 5, st[0])
        // Chorro.
        for y in 24..<41 { c.put(11, y, l[3]); c.put(12, y, l[4]); c.put(13, y, y % 3 == 0 ? l[4] : l[2]) }
        for (dx, dy) in [(-3, 0), (3, 0), (-2, -1), (2, -1), (-4, 1), (4, 1)] { c.put(12 + dx, 40 + dy, l[4]) }
        mossBase(8, 15, 39, 8, salt: 7)
    }

    /// Formación de cristales gigantes sobre roca (mina).
    private mutating func crystalFormation() {
        mEllipse(12, 46, 11, 5.5); sculpt(s.stone)
        let m = s.magic
        crystal(12, 44, 30, 3, m)
        crystal(6, 45, 18, 2, m, tilt: -4)
        crystal(18, 45, 20, 2, m, tilt: 4)
        crystal(9, 47, 9, 1, m, tilt: -2)
        crystal(16, 48, 8, 1, m, tilt: 2)
    }

    // MARK: - Brasero

    mutating func brazier(_ v: Int) {
        let ir = s.iron
        let coals: [UInt32] = [s.flame[0], s.flame[1], s.flame[2], s.flame[3]]
        let pedestal = s.theme == .crypt || v >= 2
        // Cuenco.
        for r in 0..<6 {
            let half = 8 - r - (r > 3 ? 1 : 0)
            for xx in -half..<half {
                let u = Double(xx + half) / Double(2 * half)
                let k = u < 0.15 ? 3 : u < 0.4 ? 4 : u < 0.7 ? 2 : 1
                c.put(9 + xx, 3 + r, (s.theme == .crypt ? s.stone : ir)[r == 5 ? 1 : k])
            }
        }
        // Boca con brasas.
        for xx in -7..<7 {
            c.put(9 + xx, 2, (s.theme == .crypt ? s.stone : ir)[3])
            c.put(9 + xx, 3, coals[Int(Noise.hash(xx, 1, 3) * 3) + (abs(xx) < 4 ? 1 : 0)])
        }
        c.put(2, 2, ir[4]); c.put(16, 3, ir[1])
        for xx in [-4, -1, 2, 5] { c.put(9 + xx, 2, coals[3]) }
        if s.theme == .forge {
            // Rejilla del cesto con fuego dentro.
            for xx in stride(from: -5, to: 6, by: 3) { c.put(9 + xx, 5, coals[2]); c.put(9 + xx, 6, coals[1]) }
        }
        if pedestal {
            let st = s.theme == .crypt ? s.stone : s.stone
            cylinder(6, 9, 6, 13, st)
            c.hline(6, 12, 6, st[1]); c.hline(6, 18, 6, st[1])
            box(3, 21, 12, 6, top: 2, st)
            if s.theme == .crypt { c.hline(6, 10, 6, s.trim[3]); c.hline(6, 11, 6, s.trim[1]) }
        } else {
            // Trípode de hierro con anilla.
            c.line(4, 9, 2, 26, ir[3]); c.line(5, 9, 3, 26, ir[1])
            c.line(14, 9, 16, 26, ir[2]); c.line(13, 9, 15, 26, ir[0])
            c.vline(9, 9, 18, ir[2]); c.vline(10, 9, 18, ir[1])
            c.hline(3, 18, 13, ir[3]); c.hline(3, 19, 13, ir[0])
            c.hline(1, 26, 3, ir[2]); c.hline(15, 26, 3, ir[1]); c.hline(8, 26, 3, ir[2])
            c.put(9, 8, ir[4])
        }
    }

    // MARK: - Cajas, barriles y compañía

    mutating func crates(_ v: Int) {
        switch s.theme {
        case .mine:
            switch v { case 0, 2: oreCart(); case 1: crate(1, 14, 20, 18); dynamite(4, 10); default: barrel(2, 13, 10, 19); barrel(12, 15, 10, 17) }
        case .forge:
            switch v { case 0, 2: anvil(); case 1: coalPile(); default: barrel(4, 12, 14, 20, water: true) }
        case .crypt:
            switch v { case 0, 2: urn(3, 12, 9, 20); urn(13, 16, 8, 16) ; default: crate(1, 16, 22, 16); urn(6, 6, 8, 12) }
        default:
            switch v {
            case 0: crate(1, 14, 20, 18); crate(5, 4, 14, 12)
            case 1: barrel(1, 13, 10, 19); crate(11, 18, 12, 14)
            case 2: barrel(2, 14, 10, 18); barrel(12, 12, 10, 20)
            default: crate(6, 12, 17, 20); sack(0, 18, 10, 14)
            }
        }
        if s.theme == .sewer {
            // Limo verde que cae.
            for x in stride(from: 3, to: 21, by: 4) where Noise.hash(x, v, 5) > 0.4 {
                var y = 31
                while y > 0, c.at(x, y) != nil { y -= 1 }
                for k in 1...Int(2 + Noise.hash(x, v, 6) * 5) where c.at(x, y + k) != nil { c.put(x, y + k, s.moss[k == 1 ? 3 : 2]) }
            }
            mossBase(0, 23, 31, 4, salt: v)
        }
    }

    /// Caja de madera en 3/4 con marco, tablas, cruceta y clavos.
    mutating func crate(_ x: Int, _ y: Int, _ cw: Int, _ ch: Int) {
        let wd = s.wood, ir = s.iron
        let top = max(4, ch / 4)
        for yy in 0..<ch {
            for xx in 0..<cw {
                var col: UInt32
                if yy < top {
                    col = (yy % 3 == 0) ? wd[2] : wd[3]
                    if yy == top - 1 { col = wd[4] }
                    if xx == 0 { col = wd[4] } else if xx == cw - 1 { col = wd[2] }
                } else {
                    let fy = yy - top, fh = ch - top
                    let frame = xx < 2 || xx >= cw - 2 || fy < 2 || fy >= fh - 2
                    col = frame ? wd[3] : ((fy - 2) % 4 == 3 ? wd[0] : wd[2])
                    if frame && (xx == cw - 1 || fy == fh - 1) { col = wd[1] }
                    if xx == 0 { col = wd[4] }
                    // Cruceta.
                    if !frame {
                        let diag = Double(xx - 2) / Double(cw - 4) - Double(fy - 2) / Double(fh - 4)
                        if abs(diag) < 1.6 / Double(cw - 4) { col = wd[3] }
                    }
                }
                c.put(x + xx, y + yy, col)
            }
        }
        for (px, py) in [(x + 1, y + top + 1), (x + cw - 2, y + top + 1), (x + 1, y + ch - 2), (x + cw - 2, y + ch - 2)] { c.put(px, py, ir[4]) }
        c.put(x + cw / 2, y + 1, wd[1]); c.hline(x + 2, y + top / 2, cw - 4, wd[1])
    }

    mutating func barrel(_ x: Int, _ y: Int, _ bw: Int, _ bh: Int, water: Bool = false) {
        let wd = s.wood, ir = s.iron
        // Cuerpo con barriga.
        for yy in 2..<bh {
            let bulge = (yy > 4 && yy < bh - 3) ? 1 : 0
            let u0 = x - bulge, ww = bw + 2 * bulge
            for xx in 0..<ww {
                let u = (Double(xx) + 0.5) / Double(ww)
                var k = u < 0.12 ? 3 : u < 0.32 ? 4 : u < 0.6 ? 3 : u < 0.82 ? 2 : 1
                if xx % 3 == 2 && k > 1 { k -= 1 }   // duelas
                c.put(u0 + xx, y + yy, wd[k])
            }
        }
        for hy in [y + 4, y + bh - 4] {
            for xx in -1...bw { let u = (Double(xx) + 1.5) / Double(bw + 2); c.put(x + xx, hy, ir[u < 0.35 ? 4 : u < 0.7 ? 3 : 1]); c.put(x + xx, hy + 1, ir[1]) }
        }
        // Tapa.
        for xx in 0..<bw { c.put(x + xx, y, wd[3]); c.put(x + xx, y + 1, wd[2]) }
        c.hline(x + 1, y, bw - 2, wd[4]); c.hline(x + 2, y + 1, bw - 4, water ? s.liquid[3] : wd[1])
        if water { c.hline(x + 2, y + 2, bw - 4, s.liquid[2]); c.put(x + 3, y + 1, s.liquid[4]) }
        c.hline(x, y + bh - 1, bw, wd[0])
    }

    private mutating func sack(_ x: Int, _ y: Int, _ sw: Int, _ sh: Int) {
        mEllipse(Double(x) + Double(sw) / 2, Double(y + sh) - Double(sh) * 0.42, Double(sw) / 2, Double(sh) * 0.42)
        mRect(x + sw / 2 - 2, y + 1, 4, 4)
        sculpt(Self.cloth)
        c.hline(x + sw / 2 - 2, y + 4, 4, Self.cloth[0]); c.put(x + sw / 2 - 1, y, Self.cloth[4])
        c.put(x + 3, y + sh - 5, Self.cloth[1]); c.put(x + 4, y + sh - 4, Self.cloth[1])
    }

    private mutating func urn(_ x: Int, _ y: Int, _ uw: Int, _ uh: Int) {
        let cx = Double(x) + Double(uw) / 2
        mEllipse(cx, Double(y) + Double(uh) * 0.62, Double(uw) / 2, Double(uh) * 0.38)
        mRect(Int(cx) - 2, y + 1, 4, Int(Double(uh) * 0.3))
        mRect(Int(cx) - 3, y, 6, 2)
        sculpt(s.stone)
        c.hline(Int(cx) - uw / 2 + 1, y + Int(Double(uh) * 0.5), uw - 2, s.trim[2])
        c.hline(Int(cx) - uw / 2 + 1, y + Int(Double(uh) * 0.5) + 1, uw - 2, s.trim[0])
        c.hline(Int(cx) - 2, y, 4, s.stone[0])
    }

    private mutating func dynamite(_ x: Int, _ y: Int) {
        for k in 0..<4 {
            c.rect(x + k * 3, y, 2, 6, 0xB8302A); c.vline(x + k * 3, y, 6, 0xE05A44); c.put(x + k * 3 + 1, y + 5, 0x6A1A16)
            c.put(x + k * 3, y - 1, 0xDCD4BC)
        }
        c.hline(x - 1, y + 3, 12, s.wood[1])
    }

    /// Vagoneta llena de cristal sobre sus ruedas (mina).
    private mutating func oreCart() {
        let ir = s.iron, wd = s.wood
        // Cristales asomando.
        crystal(8, 15, 9, 2, s.magic, tilt: -2)
        crystal(14, 14, 11, 2, s.magic, tilt: 2)
        crystal(18, 15, 6, 1, s.magic)
        for x in 4..<20 { c.put(x, 14, s.stone[Int(Noise.hash(x, 3, 1) * 3) + 1]) }
        // Caja trapezoidal.
        for yy in 0..<12 {
            let inset = yy / 4
            for xx in (1 + inset)..<(23 - inset) {
                var col = (yy % 4 == 0) ? wd[3] : wd[2]
                if xx <= 2 + inset { col = ir[3] } else if xx >= 21 - inset { col = ir[1] }
                if yy == 0 { col = ir[4] } else if yy == 11 { col = wd[0] }
                c.put(xx, 15 + yy, col)
            }
        }
        c.hline(2, 19, 20, ir[2]); c.hline(2, 20, 20, ir[0])
        for px in [4, 19] { c.put(px, 17, ir[4]); c.put(px, 23, ir[4]) }
        // Ruedas.
        for wx in [6, 17] {
            c.ellipse(wx, 28, 3, 3, ir[1]); c.ellipse(wx, 28, 2, 2, ir[2]); c.put(wx, 28, ir[4]); c.put(wx - 2, 26, ir[3])
        }
    }

    /// Yunque sobre un tocón (forja).
    private mutating func anvil() {
        let ir = s.iron, wd = s.wood
        // Tocón.
        box(5, 20, 14, 12, top: 4, wd)
        for k in [8, 12, 15] { c.vline(k, 25, 6, wd[1]) }
        c.ellipse(12, 21, 3, 1, wd[3])
        // Yunque.
        mPoly([(1, 10), (6, 8), (20, 8), (21, 13), (16, 14), (16, 17), (19, 21), (6, 21), (9, 17), (9, 14), (5, 13)])
        sculpt(ir)
        c.hline(6, 8, 14, ir[4]); c.hline(2, 10, 4, ir[3])
        // Lingote al rojo encima.
        c.rect(10, 6, 6, 2, s.magic[2]); c.hline(10, 6, 6, s.magic[3]); c.put(15, 7, s.magic[1])
    }

    /// Montón de carbón con lingotes (forja).
    private mutating func coalPile() {
        mPoly([(1, 31), (6, 20), (12, 16), (18, 21), (23, 31)]); sculpt(Self.coal)
        for k in 0..<14 {
            let x = 3 + Int(Noise.hash(k, 1, 2) * 18), y = 20 + Int(Noise.hash(k, 2, 2) * 10)
            guard c.at(x, y) != nil else { continue }
            c.put(x, y, Self.coal[4]); c.put(x + 1, y + 1, Self.coal[0])
        }
        c.put(9, 27, s.magic[1]); c.put(15, 25, s.magic[2]); c.put(12, 29, s.magic[1])
        // Lingotes apilados.
        for (bx, by) in [(13, 26), (17, 26), (15, 23)] {
            c.rect(bx, by, 5, 3, s.trim[2]); c.hline(bx, by, 5, s.trim[4]); c.hline(bx, by + 2, 5, s.trim[0]); c.put(bx + 4, by + 1, s.trim[1])
        }
    }

    // MARK: - Cofre

    mutating func chest(_ v: Int) {
        let wd = s.wood, ir = s.iron
        let gold = s.theme == .crypt ? s.trim : DungeonStyle.goldRamp
        let band = v % 2 == 0 ? ir : gold
        // Cuerpo.
        for yy in 7..<18 {
            for xx in 1..<21 {
                var col = (yy - 7) % 4 == 3 ? wd[1] : wd[2]
                if xx == 1 { col = wd[4] } else if xx == 20 { col = wd[0] } else if xx < 4 { col = wd[3] }
                if yy == 17 { col = wd[0] }
                c.put(xx, yy, col)
            }
        }
        // Tapa abombada.
        for yy in 0..<7 {
            let inset = yy == 0 ? 3 : yy == 1 ? 1 : 0
            for xx in (1 + inset)..<(21 - inset) {
                var col = yy < 2 ? wd[4] : yy < 4 ? wd[3] : wd[2]
                if xx >= 18 { col = wd[1] }
                if yy == 6 { col = wd[0] }
                c.put(xx, yy, col)
            }
        }
        // Flejes y cantoneras.
        for bx in [4, 16] {
            for yy in 0..<18 where c.at(bx, yy) != nil {
                c.put(bx, yy, band[yy < 3 ? 4 : 3]); c.put(bx + 1, yy, band[1])
            }
        }
        c.hline(1, 6, 20, band[1]); c.hline(1, 7, 20, band[3])
        for (px, py) in [(2, 9), (19, 9), (2, 15), (19, 15)] { c.put(px, py, band[4]) }
        // Cerradura.
        c.rect(9, 5, 4, 5, gold[2]); c.hline(9, 5, 4, gold[4]); c.vline(12, 5, 5, gold[0])
        c.put(10, 7, 0x1A1418); c.put(10, 8, 0x1A1418)
        if s.theme == .crypt { c.put(11, 2, s.magic[2]); c.put(6, 12, gold[3]); c.put(15, 12, gold[3]) }
    }

    // MARK: - Altar (2 casillas)

    mutating func altar(_ v: Int) {
        if s.theme == .forge { bigAnvil(); return }
        let st = s.stone
        // Peldaño ancho y bloque del altar.
        box(0, 27, 48, 7, top: 3, st)
        box(4, 12, 40, 17, top: 6, st)
        // Pilastras talladas en el frente.
        for px in [6, 39] {
            c.rect(px, 19, 3, 9, st[3]); c.vline(px, 19, 9, st[4]); c.vline(px + 2, 19, 9, st[1])
            c.hline(px - 1, 18, 5, st[4]); c.hline(px - 1, 27, 5, st[1])
        }
        c.hline(10, 26, 28, st[1]); c.hline(10, 27, 28, st[3])
        // Paño colgando por delante, con ribete y emblema.
        let b = s.banner, tr = s.trim
        for yy in 0..<17 {
            let y = 13 + yy
            for xx in 14..<34 {
                if yy >= 12 && abs(Double(xx) - 23.5) > Double(10 - (yy - 12) * 2) + 0.5 { continue }   // en punta
                var col = xx < 16 ? b[3] : xx > 31 ? b[0] : b[(xx * 3 + yy) % 7 == 0 ? 1 : 2]
                if yy < 5 { col = yy == 0 ? b[3] : b[2] }
                if xx == 15 || xx == 32 { col = tr[2] }
                if yy == 5 { col = tr[3] }
                c.put(xx, y, col)
            }
        }
        c.rect(21, 20, 6, 6, s.emblem); c.vline(23, 21, 4, DColor.mul(s.emblem, 0.6)); c.hline(22, 22, 4, DColor.mul(s.emblem, 0.6))
        c.put(21, 20, DColor.mix(s.emblem, 0xFFFFFF, 0.5))
        // Velas de distintas alturas con cera derramada.
        for (vx, vh) in [(6, 9), (9, 6), (12, 4), (35, 4), (38, 6), (41, 9)] {
            c.rect(vx, 15 - vh, 2, vh, s.bone[3]); c.vline(vx + 1, 15 - vh, vh, s.bone[1]); c.put(vx, 15 - vh, s.bone[4])
            c.put(vx, 13 - vh, s.flame[3]); c.put(vx, 14 - vh, s.flame[2]); c.put(vx + 1, 14 - vh, s.flame[1]); c.put(vx, 12 - vh, s.flame[1])
            c.put(vx - 1, 15, s.bone[2]); c.put(vx + 2, 16, s.bone[2])
        }
        let cx = 24
        switch s.theme {
        case .crypt:
            // Libro abierto y cáliz de oro.
            let g = s.trim
            c.rect(cx - 9, 11, 8, 4, 0xDCD4BC); c.vline(cx - 5, 11, 4, 0x8E8470); c.hline(cx - 9, 14, 8, 0x8E8470)
            for k in 0..<3 { c.hline(cx - 8, 12 + k, 2, 0x8E8470); c.hline(cx - 3, 12 + k, 2, 0x8E8470) }
            c.rect(cx + 3, 6, 5, 3, g[3]); c.put(cx + 3, 6, g[4]); c.vline(cx + 5, 9, 4, g[2]); c.hline(cx + 3, 13, 5, g[1])
            c.put(cx + 5, 7, s.magic[2])
        case .mine:
            crystal(cx, 15, 14, 3, s.magic)
            crystal(cx - 6, 16, 7, 1, s.magic, tilt: -2)
        default:
            skull(cx - 3, 9)
            for k in 0..<6 { c.put(cx - 13 + k * 2, 14, s.iron[3]); c.put(cx - 12 + k * 2, 14, s.iron[1]) }
        }
        _ = v
    }

    /// Gran yunque de enano sobre su bancada (forja: los `AA` son yunques).
    private mutating func bigAnvil() {
        let ir = s.iron, st = s.stone, wd = s.wood
        // Bancada de piedra con flejes.
        box(8, 21, 32, 13, top: 4, st)
        for px in [12, 35] { c.vline(px, 25, 8, ir[3]); c.vline(px + 1, 25, 8, ir[1]); c.put(px, 27, ir[4]); c.put(px, 31, ir[4]) }
        c.hline(9, 29, 30, st[1])
        // Yunque.
        mPoly([(0, 9), (9, 5), (40, 5), (42, 7), (47, 7), (47, 12), (37, 13), (33, 15), (33, 18), (39, 22), (9, 22), (15, 18), (15, 15), (11, 13), (3, 12)])
        sculpt(ir)
        c.hline(9, 5, 31, ir[4]); c.hline(10, 6, 29, ir[3]); c.hline(2, 9, 6, ir[3]); c.put(1, 9, ir[4])
        c.put(41, 8, ir[0]); c.put(42, 9, ir[0])   // agujeros de la tabla
        // Runas enanas grabadas que brillan en la cintura.
        for k in 0..<4 { c.put(19 + k * 3, 17, s.magic[k & 1 == 0 ? 2 : 1]); c.put(19 + k * 3, 18, s.magic[0]) }
        // Hoja al rojo encima y chispas.
        c.hline(14, 4, 20, s.magic[2]); c.hline(14, 3, 20, s.magic[3]); c.put(13, 4, s.magic[1]); c.put(33, 3, s.magic[1])
        c.rect(34, 2, 2, 4, ir[3]); c.rect(36, 3, 5, 2, wd[2]); c.hline(36, 3, 5, wd[3])
        for (sx, sy) in [(20, 0), (25, 1), (29, 0), (17, 1)] { c.put(sx, sy, s.flame[3]) }
        // Martillo apoyado contra la bancada.
        c.line(42, 33, 45, 20, wd[3]); c.line(43, 33, 46, 20, wd[1])
        c.rect(42, 17, 6, 4, ir[2]); c.hline(42, 17, 6, ir[4]); c.hline(42, 20, 6, ir[0])
    }

    private mutating func skull(_ x: Int, _ y: Int) {
        let rows = [
            ".abba.",
            "abccba",
            "bddcdb",
            "bddcdb",
            ".bccb.",
            ".b.b..",
        ]
        let b = s.bone
        c.sprite(rows, x, y, ["a": b[4], "b": b[2], "c": b[3], "d": 0x1A1418])
    }
}
