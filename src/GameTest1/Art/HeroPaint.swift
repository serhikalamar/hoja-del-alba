import CoreGraphics

// Herramientas de dibujo del héroe: lienzo con etiquetas, rampas de color de cinco tonos,
// extremidades sombreadas y plantillas de texto. Luz siempre desde arriba a la izquierda.

extension HeroArt {
    /// Punto entero del lienzo.
    struct Pt: Hashable {
        var x: Int, y: Int
        init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
    }

    /// Punto con decimales (articulaciones del esqueleto).
    struct V: Equatable {
        var x: Double, y: Double
        init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
        static func + (a: V, b: V) -> V { V(a.x + b.x, a.y + b.y) }
        static func - (a: V, b: V) -> V { V(a.x - b.x, a.y - b.y) }
        static func * (a: V, k: Double) -> V { V(a.x * k, a.y * k) }
        func lerp(_ b: V, _ t: Double) -> V { V(x + (b.x - x) * t, y + (b.y - y) * t) }
        var px: Pt { Pt(Int(x.rounded(.down)), Int(y.rounded(.down))) }
    }

    /// Tono dentro de una rampa: brillo, claro, medio, oscuro, sombra profunda.
    enum Tone { case hi, lt, md, dk, dp }

    /// Qué hay en cada pixel (para sombras proyectadas y parpadeos).
    enum Tag: UInt8 { case none, skin, hair, eye, gear, cloth, fur }

    enum Ink {
        static let outline: UInt32 = 0x1A1C2C
        static let shadow: UInt32 = 0x221735
        static let light: UInt32 = 0xFFF8E8

        static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
            func ch(_ c: UInt32, _ s: UInt32) -> Double { Double((c >> s) & 0xFF) }
            func m(_ s: UInt32) -> UInt32 { UInt32(max(0, min(255, (ch(a, s) + (ch(b, s) - ch(a, s)) * t).rounded()))) }
            return (m(16) << 16) | (m(8) << 8) | m(0)
        }
    }

    /// Rampa de cinco tonos de un material.
    struct Ramp: Hashable {
        var hi: UInt32, lt: UInt32, md: UInt32, dk: UInt32, dp: UInt32

        init(hi: UInt32, lt: UInt32, md: UInt32, dk: UInt32, dp: UInt32) {
            self.hi = hi; self.lt = lt; self.md = md; self.dk = dk; self.dp = dp
        }

        /// Los tres colores de un material (claro, medio, oscuro).
        init(material m: [UInt32]) {
            let c = m.count >= 3 ? m : m + Array(repeating: m.last ?? 0x808080, count: 3 - m.count)
            self.init(hi: Ink.mix(c[0], Ink.light, 0.35), lt: Ink.mix(c[0], c[1], 0.45), md: c[1], dk: c[2],
                      dp: Ink.mix(c[2], Ink.shadow, 0.5))
        }

        /// Rampa alrededor de un color medio (tintes, piel, pelo, ropa).
        init(base c: UInt32, spread k: Double = 1) {
            self.init(hi: Ink.mix(c, Ink.light, 0.6 * k), lt: Ink.mix(c, Ink.light, 0.28 * k), md: c,
                      dk: Ink.mix(c, Ink.shadow, 0.32 * k), dp: Ink.mix(c, Ink.shadow, 0.58 * k))
        }

        /// Piel: sombras cálidas.
        static func skin(_ c: UInt32) -> Ramp {
            Ramp(hi: Ink.mix(c, 0xFFF6EC, 0.5), lt: c, md: Ink.mix(c, 0xB0503C, 0.2),
                 dk: Ink.mix(c, 0x7A2E3A, 0.38), dp: Ink.mix(c, 0x3A1A2E, 0.62))
        }

        /// Pelo: los colores muy oscuros se aclaran un poco para que se lean los mechones.
        static func hair(_ c: UInt32) -> Ramp {
            let lum = Double((c >> 16) & 0xFF) * 0.3 + Double((c >> 8) & 0xFF) * 0.59 + Double(c & 0xFF) * 0.11
            let base = lum < 70 ? Ink.mix(c, 0x8890B8, 0.16) : c
            return Ramp(hi: Ink.mix(base, 0xF0F4FF, 0.55), lt: Ink.mix(base, 0xF0F4FF, 0.25), md: base,
                        dk: Ink.mix(base, Ink.shadow, 0.4), dp: Ink.mix(base, Ink.outline, 0.7))
        }

        static func flat(_ c: UInt32) -> Ramp { Ramp(hi: c, lt: c, md: c, dk: c, dp: c) }

        subscript(_ t: Tone) -> UInt32 {
            switch t {
            case .hi: hi
            case .lt: lt
            case .md: md
            case .dk: dk
            case .dp: dp
            }
        }
    }

    /// Tinta de una plantilla: rampa + tono fijo (o automático por bordes si `tone` es nil).
    struct Pen {
        var ramp: Ramp
        var tone: Tone?
        var tag: Tag
        /// Pixeles del mismo grupo se sombrean juntos (bordes del grupo = bordes de la forma).
        var group: Int

        init(_ ramp: Ramp, _ tone: Tone? = nil, _ tag: Tag = .gear, group: Int = 1) {
            self.ramp = ramp; self.tone = tone; self.tag = tag; self.group = group
        }
    }

    /// Lienzo del héroe: colores + etiqueta de cada pixel.
    struct Canvas {
        let width: Int, height: Int
        private(set) var color: [UInt32?]
        private(set) var tags: [Tag]

        init(width: Int, height: Int) {
            self.width = width
            self.height = height
            color = Array(repeating: nil, count: width * height)
            tags = Array(repeating: .none, count: width * height)
        }

        func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < width && y < height }

        subscript(x: Int, y: Int) -> UInt32? { inside(x, y) ? color[y * width + x] : nil }

        func tag(_ x: Int, _ y: Int) -> Tag { inside(x, y) ? tags[y * width + x] : .none }

        mutating func set(_ x: Int, _ y: Int, _ c: UInt32, _ t: Tag = .gear) {
            guard inside(x, y) else { return }
            color[y * width + x] = c
            tags[y * width + x] = t
        }

        mutating func erase(_ x: Int, _ y: Int) {
            guard inside(x, y) else { return }
            color[y * width + x] = nil
            tags[y * width + x] = .none
        }

        var grid: PixelGrid {
            var g = PixelGrid(width: width, height: height)
            g.pixels = color
            return g
        }

        // MARK: Formas

        /// Pinta un conjunto de pixeles con sombreado por bordes: arriba/izquierda claro, abajo/derecha oscuro.
        /// `soft` añade una segunda franja (para formas grandes y redondeadas).
        mutating func fill(_ pts: Set<Pt>, _ r: Ramp, _ tag: Tag, soft: Bool = false, corner: Bool = true) {
            for p in pts {
                set(p.x, p.y, r[Self.edgeTone(p, pts, soft: soft, corner: corner)], tag)
            }
        }

        static func edgeTone(_ p: Pt, _ pts: Set<Pt>, soft: Bool, corner: Bool = true) -> Tone {
            let has = { (dx: Int, dy: Int) in pts.contains(Pt(p.x + dx, p.y + dy)) }
            let r = !has(1, 0), b = !has(0, 1), l = !has(-1, 0), t = !has(0, -1)
            if r && b && corner { return .dp }
            if r || b { return .dk }
            if l && t && corner { return .hi }
            if l || t { return .lt }
            if soft {
                if !has(2, 0) || !has(0, 2) { return .md }
                if !has(-2, 0) || !has(0, -2) { return .lt }
            }
            return .md
        }

        /// Pixeles de un tramo de grosor `w` entre dos puntos, con su índice a lo ancho
        /// (0 = lado iluminado: izquierda en tramos verticales, arriba en horizontales).
        static func segment(_ a: V, _ b: V, w: Int) -> [(Pt, Int)] {
            var out: [(Pt, Int)] = []
            let dx = b.x - a.x, dy = b.y - a.y
            if abs(dy) >= abs(dx) {
                let y0 = Int(min(a.y, b.y).rounded(.down)), y1 = Int(max(a.y, b.y).rounded(.down))
                for y in y0...max(y0, y1) {
                    let t = dy == 0 ? 0 : max(0, min(1, (Double(y) + 0.5 - a.y) / dy))
                    let cx = a.x + dx * t
                    let x0 = Int((cx - Double(w) / 2).rounded())
                    for i in 0..<w { out.append((Pt(x0 + i, y), i)) }
                }
            } else {
                let x0 = Int(min(a.x, b.x).rounded(.down)), x1 = Int(max(a.x, b.x).rounded(.down))
                for x in x0...max(x0, x1) {
                    let t = max(0, min(1, (Double(x) + 0.5 - a.x) / dx))
                    let cy = a.y + dy * t
                    let y0 = Int((cy - Double(w) / 2).rounded())
                    for i in 0..<w { out.append((Pt(x, y0 + i), i)) }
                }
            }
            return out
        }

        static func tones(_ w: Int, metal: Bool = false) -> [Tone] {
            switch w {
            case ...1: [.md]
            case 2: [.lt, .dk]
            case 3: metal ? [.hi, .md, .dk] : [.lt, .md, .dk]
            case 4: metal ? [.lt, .hi, .md, .dk] : [.lt, .md, .md, .dk]
            case 5: metal ? [.lt, .hi, .md, .md, .dk] : [.lt, .lt, .md, .md, .dk]
            default: [.lt, .lt] + Array(repeating: .md, count: w - 3) + [.dk]
            }
        }

        /// Extremidad sombreada a lo ancho. Devuelve los pixeles pintados.
        @discardableResult
        mutating func limb(_ a: V, _ b: V, w: Int, _ r: Ramp, _ tag: Tag, metal: Bool = false) -> Set<Pt> {
            let tones = Self.tones(w, metal: metal)
            var pts = Set<Pt>()
            for (p, i) in Self.segment(a, b, w: w) {
                set(p.x, p.y, r[tones[min(i, tones.count - 1)]], tag)
                pts.insert(p)
            }
            return pts
        }

        /// Rectángulo relleno (para piezas pequeñas) con sombreado por bordes.
        static func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> Set<Pt> {
            var s = Set<Pt>()
            for yy in y..<(y + h) { for xx in x..<(x + w) { s.insert(Pt(xx, yy)) } }
            return s
        }

        /// Elipse rellena de centro (cx, cy) y radios rx, ry (centros de pixel dentro).
        static func ellipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> Set<Pt> {
            var s = Set<Pt>()
            for y in Int((cy - ry - 1).rounded(.down))...Int((cy + ry + 1).rounded(.up)) {
                for x in Int((cx - rx - 1).rounded(.down))...Int((cx + rx + 1).rounded(.up)) {
                    let nx = (Double(x) + 0.5 - cx) / rx, ny = (Double(y) + 0.5 - cy) / ry
                    if nx * nx + ny * ny <= 1.0 { s.insert(Pt(x, y)) }
                }
            }
            return s
        }

        // MARK: Plantillas

        /// Estampa filas de caracteres. Los caracteres sin tinta son transparentes.
        mutating func stamp(_ rows: [String], x ox: Int, y oy: Int, _ pens: [Character: Pen], flip: Bool = false,
                            dx: Int = 0, skipAbove: Int? = nil) {
            let w = rows.map(\.count).max() ?? 0
            var groups: [Int: Set<Pt>] = [:]
            var cells: [(Pt, Pen)] = []
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let pen = pens[ch] else { continue }
                    let p = Pt(ox + (flip ? w - 1 - x : x) + dx, oy + y)
                    if let limit = skipAbove, p.y < limit { continue }
                    cells.append((p, pen))
                    groups[pen.group, default: []].insert(p)
                }
            }
            for (p, pen) in cells {
                let tone = pen.tone ?? Self.edgeTone(p, groups[pen.group] ?? [], soft: false, corner: false)
                set(p.x, p.y, pen.ramp[tone], pen.tag)
            }
        }

        /// Sombra que proyecta una capa sobre la piel de debajo (flequillo, cascos).
        mutating func castShadow(from pts: Set<Pt>, onto tag: Tag, _ shade: UInt32, depth: Int = 1) {
            for p in pts {
                for d in 1...depth {
                    let q = Pt(p.x, p.y + d)
                    if !pts.contains(q) && self.tag(q.x, q.y) == tag { set(q.x, q.y, shade, tag) }
                }
            }
        }

        /// Pixeles opacos con una etiqueta concreta.
        func pixels(tagged t: Tag) -> Set<Pt> {
            var s = Set<Pt>()
            for y in 0..<height { for x in 0..<width where tags[y * width + x] == t { s.insert(Pt(x, y)) } }
            return s
        }
    }
}
