import CoreGraphics
import GameCore

// Detalles de personaje que solo llevan los NPC chibi (barba, capa, casco bajo el brazo, tabardo,
// armadura abollada). El héroe del jugador nunca los lleva: `HeroLook.extras` está vacío por defecto,
// así que su dibujo no cambia. Se piden desde `NPCLooks` y sirven para cualquier aldeano o personaje.

/// Barba para razas sin barba propia (humano y elfo; el enano la lleva como "peinado").
enum BeardStyle: String, Hashable {
    /// Recortada: patillas, bigote y mentón.
    case short
    /// Poblada: cubre mandíbula y cae sobre el pecho.
    case full
}

struct LookExtras: Hashable {
    /// Barba del color del pelo.
    var beard: BeardStyle? = nil
    /// Color de pelo y barba fuera de la paleta del jugador (canas, tintes raros). nil = el de `Appearance`.
    var hairColor: UInt32? = nil
    /// Capa a la espalda (color) y si está raída (bajo deshilachado, rotos).
    var cape: UInt32? = nil
    var capeTorn = false
    /// Casco que lleva sujeto bajo el brazo delantero (diseño, material y tinte del penacho).
    var heldHelmet: GearLook? = nil
    /// Tabardo sobre el peto (color), con ribete y emblema blancos.
    var tabard: UInt32? = nil
    /// Peto con abolladuras y arañazos (veteranos).
    var dented = false

    var isEmpty: Bool { self == LookExtras() }

    var cacheKey: String {
        var parts: [String] = []
        if let beard { parts.append("b\(beard.rawValue)") }
        if let hairColor { parts.append("p\(String(hairColor, radix: 16))") }
        if let cape { parts.append("c\(String(cape, radix: 16))\(capeTorn ? "t" : "")") }
        if let h = heldHelmet { parts.append("h\(h.styleID):\(h.material.map { String($0, radix: 16) }.joined(separator: ",")):\(String(h.dye, radix: 16))") }
        if let tabard { parts.append("t\(String(tabard, radix: 16))") }
        if dented { parts.append("d") }
        return parts.joined(separator: ",")
    }
}

extension HeroArt {
    /// Brazo delantero doblado, con la mano en la cadera (sujeta el casco bajo el brazo).
    static let armHoldHip = ArmKey(0.8, 3.6, 3.0, 5.8)
}

extension HeroArt.Painter {
    var extras: LookExtras { look.extras }

    // MARK: - Capa

    /// Capa por detrás de todo: cae de los hombros hasta casi el suelo, se abre hacia atrás y ondea al correr.
    mutating func drawCapeBack() {
        guard let color = extras.cape else { return }
        let r = Ramp(base: color, spread: 0.9)
        let top = body.torsoTop + upper.y - 1
        let bottom = HeroArt.canvasHeight - 3
        let left0 = Int(body.shoulderBack.x.rounded()) - 2 + upper.x
        let right0 = Int(body.shoulderFront.x.rounded()) + 1 + upper.x
        var rows: [Int: (Int, Int)] = [:]
        var pts = Set<Pt>()
        for y in top...bottom {
            let t = Double(y - top) / Double(max(1, bottom - top))
            let trail = Int((Double(-rig.flowX) * 1.6 * t).rounded())
            let x0 = left0 - Int((5.5 * t).rounded()) - trail
            let x1 = right0 + Int((2 * t).rounded()) - trail / 2
            rows[y] = (x0, x1)
            for x in x0...x1 { pts.insert(Pt(x, y)) }
        }
        if extras.capeTorn {
            // Bajo deshilachado: dientes de distinta largura.
            let teeth = [0, 2, 1, 3, 0, 1, 4, 2, 0, 3, 1]
            for p in pts where p.y > bottom - 5 {
                let k = teeth[((p.x % teeth.count) + teeth.count) % teeth.count]
                if p.y > bottom - k { pts.remove(p) }
            }
            // Mordiscos en el borde de atrás y un par de rotos.
            for y in [top + 9, top + 10, top + 15] { if let row = rows[y] { pts.remove(Pt(row.0, y)) } }
            for (dy, dx) in [(-6, 2), (-7, 2), (-7, 3), (-11, 4)] {
                if let row = rows[bottom + dy] { pts.remove(Pt(row.0 + dx, bottom + dy)) }
            }
        }
        canvas.fill(pts, r.behind, .cloth)
        // Pliegues verticales que se abren hacia abajo.
        for p in pts where p.y > top + 3 {
            guard let row = rows[p.y] else { continue }
            let fold = (p.x - row.0) % 4
            if fold == 2 { canvas.set(p.x, p.y, r.dk, .cloth) } else if fold == 1 && p.y > top + 6 { canvas.set(p.x, p.y, r.md, .cloth) }
        }
        // Forro claro en el borde de atrás (la luz viene de la izquierda).
        for (y, row) in rows where y > top + 1 && pts.contains(Pt(row.0, y)) { canvas.set(row.0, y, r.lt, .cloth) }
    }

    /// Broche y vuelta de la capa sobre los hombros (por delante del torso).
    mutating func drawCapeClasp() {
        guard let color = extras.cape else { return }
        let r = Ramp(base: color, spread: 0.9)
        let y0 = body.torsoTop + upper.y
        let cx = torsoCenter + 1
        let x0 = torsoRows[0].x0
        // Vuelta de la capa sobre el hombro de atrás.
        for x in (x0 - 1)...(cx - 3) { canvas.set(x, y0, x == x0 - 1 ? r.lt : r.md, .cloth) }
        for x in (x0 - 1)...(cx - 4) { canvas.set(x, y0 + 1, r.dk, .cloth) }
        // Broche dorado.
        let gold = HeroArt.Painter.gold
        canvas.set(cx - 3, y0, gold.hi, .gear); canvas.set(cx - 2, y0, gold.md, .gear)
        canvas.set(cx - 3, y0 + 1, gold.md, .gear); canvas.set(cx - 2, y0 + 1, gold.dk, .gear)
    }

    // MARK: - Barba

    mutating func drawBeard() {
        guard let beard = extras.beard, race == .human || race == .elf else { return }
        let rows: [String]
        switch beard {
        case .short:
            rows = [
                ".H..................",
                ".HH...............H.",
                ".HHD..............HD",
                ".HHD....JHHHHD...HHD",
                "..HHD..HHD...DHHHHD.",
                "..JHHDHHHHHHHHHHHD..",
                "...HHHHHHHHHHHHHD...",
                "....DHHHHHHHHHDD....",
                "......DDHHHDD.......",
            ]
        case .full:
            rows = [
                ".H..................",
                ".HH...............H.",
                ".HHD..............HD",
                ".HHH....JHHHHD...HHD",
                ".HHHD..HHD...DHHHHHD",
                "..JHHHHHHHHHHHHHHHD.",
                "..HHHHDHHHHDHHHHHD..",
                "...HHHHHDHHHHDHHD...",
                "....HHHHHHDHHHDD....",
                ".....DHHHHHHHD......",
                "......DDHHHDD.......",
                "........DD..........",
            ]
        }
        stampHair(HeroArt.Layer(rows: rows, x: 0, y: 12), flow: false)
    }

    // MARK: - Tabardo y desgaste del peto

    mutating func drawTabardAndWear() {
        let rows = torsoRows
        let y0 = rows[0].y, beltY = rows[body.belt].y, lastUpper = rows[body.belt - 1].y
        let cx = torsoCenter + 1
        if extras.dented, let chest = gear(.chest) {
            // Abolladuras: hueco oscuro con el borde de abajo brillante, y un arañazo.
            let m = mat(chest)
            let r2 = rows[min(3, rows.count - 1)], r5 = rows[min(6, rows.count - 1)]
            for (x, y) in [(r2.x0 + 2, r2.y), (r5.x1 - 2, r5.y)] {
                canvas.set(x, y, m.dp, .gear); canvas.set(x + 1, y, m.dk, .gear); canvas.set(x, y + 1, m.hi, .gear)
            }
            canvas.set(r2.x1 - 2, r2.y - 1, m.hi, .gear); canvas.set(r2.x1 - 1, r2.y, m.hi, .gear)
        }
        guard let color = extras.tabard else { return }
        let d = Ramp(base: color)
        let white = Ramp(material: [0xFFFFFF, 0xE4E4EC, 0xA8A8BC])
        // Panel delantero sobre el peto, de los hombros al faldón (se mece al correr).
        let hang = beltY + 6
        var panel = Set<Pt>()
        for y in (y0 + 1)...hang {
            let sway = y > beltY + 1 ? (rig.flowX * (y - beltY - 1)) / 6 : 0
            let half = y < y0 + 3 ? 2 : 3
            let shift = y <= lastUpper ? 0 : hipShift - upper.x
            for x in (cx - half + sway + shift)...(cx + half - 1 + sway + shift) { panel.insert(Pt(x, y)) }
        }
        canvas.fill(panel, d, .cloth)
        // Ribete blanco a los lados y en el bajo.
        for y in (y0 + 1)...hang {
            let xs = panel.filter { $0.y == y }.map(\.x)
            guard let a = xs.min(), let b = xs.max() else { continue }
            canvas.set(a, y, white.lt, .cloth); canvas.set(b, y, white.dk, .cloth)
            if y == hang { for x in a...b { canvas.set(x, y, x == a ? white.lt : white.md, .cloth) } }
        }
        // Emblema blanco (torre de Valdemar): almenas, cuerpo y puerta.
        let ex = cx - 2, ey = y0 + 3
        for (dx, dy) in [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (2, 2), (0, 3), (1, 3), (2, 3)] {
            canvas.set(ex + dx, ey + dy, dx == 0 ? white.hi : white.md, .cloth)
        }
        canvas.set(ex + 1, ey + 2, d.dp, .cloth)
        // Cinturón por encima del tabardo.
        for x in rows[body.belt].x0...rows[body.belt].x1 where panel.contains(Pt(x, beltY)) {
            canvas.set(x, beltY, clothes.belt.md, .gear); canvas.set(x, beltY + 1, clothes.belt.dk, .gear)
        }
        canvas.fill(Canvas.rect(cx, beltY, 2, 2), HeroArt.Painter.gold, .gear)
    }

    // MARK: - Casco bajo el brazo

    /// Yelmo de lado (mira hacia delante) apoyado en la cadera; el brazo delantero se pinta encima.
    mutating func drawHeldHelmet() {
        guard let g = extras.heldHelmet else { return }
        let m = mat(g), d = dye(g)
        let rows = [
            "......QPP...",
            "....QPPPPD..",
            "...PPDHLLM..",
            "..PD.HLLLLMD",
            ".....LLLLLMD",
            "....HLKKKKKD",
            "....LLLMMMMD",
            "....LLKMKMKD",
            "....LMMMMMDD",
            "....DDDDDDD.",
        ]
        let pens: [Character: Pen] = [
            "H": Pen(m, .hi, .gear), "L": Pen(m, .lt, .gear), "M": Pen(m, .md, .gear), "D": Pen(m, .dk, .gear),
            "K": Pen(Ramp.flat(Ink.outline), .md, .gear),
            "P": Pen(d, .md, .cloth), "Q": Pen(d, .lt, .cloth),
        ]
        let hand = handPoint
        canvas.stamp(rows, x: Int(hand.x.rounded()) - 3, y: Int(hand.y.rounded()) - 6, pens)
    }
}
