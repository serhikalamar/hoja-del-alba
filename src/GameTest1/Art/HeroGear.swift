import CoreGraphics
import GameCore

// Armadura del héroe por huecos: el material da los tonos de la pieza y el tinte colorea
// tela, penachos, ribetes y emblemas. Cada pieza se adapta al cuerpo de la raza.

extension HeroArt.Painter {
    typealias Ramp = HeroArt.Ramp
    typealias Pt = HeroArt.Pt
    typealias V = HeroArt.V
    typealias Canvas = HeroArt.Canvas
    typealias Pen = HeroArt.Pen
    typealias Ink = HeroArt.Ink
    func mat(_ g: GearLook) -> Ramp { Ramp(material: g.material) }
    func dye(_ g: GearLook) -> Ramp { Ramp(base: g.dye) }
    static let gold = HeroArt.Ramp(material: [0xFFE08A, 0xE0A838, 0x9A6420])
    static let ivory = HeroArt.Ramp(material: [0xF8F0DC, 0xD0C0A0, 0x8A7A5A])

    // MARK: - Mangas y hombreras (dependen del peto)

    func sleeveRamp(_ chest: GearLook?) -> Ramp? {
        guard let chest else { return clothes.sleeve }
        switch chest.styleID {
        case "chest.plate", "chest.chain", "chest.leather", "chest.robe", "chest.tabard": return mat(chest)
        default: return clothes.sleeve
        }
    }

    func forearmRamp(_ chest: GearLook?) -> Ramp? {
        guard let chest else { return clothes.forearm }
        switch chest.styleID {
        case "chest.chain", "chest.robe", "chest.tabard": return mat(chest)
        default: return clothes.forearm ?? (race == .werewolf ? nil : clothes.sleeve)
        }
    }

    mutating func drawSleeveDetail(_ chest: GearLook, shoulder: V, elbow: V, hand: V, front: Bool) {
        let m = front ? mat(chest) : mat(chest).behind
        switch chest.styleID {
        case "chest.chain":
            chainLimb(shoulder, elbow, w: body.upperW, m)
            chainLimb(elbow, hand, w: body.foreW, m)
        case "chest.plate":
            // Codera
            let e = elbow.px
            canvas.fill(Canvas.rect(e.x - 1, e.y - 1, 3, 3), m, .gear)
            canvas.set(e.x - 1, e.y - 1, m.hi, .gear)
        case "chest.robe":
            // Manga ancha con ribete teñido.
            let d = front ? dye(chest) : dye(chest).behind
            let a = elbow.lerp(hand, 0.45)
            let pts = Set(Canvas.segment(a, hand, w: body.foreW + 2).map(\.0))
            canvas.fill(pts, m, .cloth)
            for (p, _) in Canvas.segment(hand.lerp(a, 0.25), hand, w: body.foreW + 2) { canvas.set(p.x, p.y, d.md, .cloth) }
        default:
            break
        }
    }

    mutating func chainLimb(_ a: V, _ b: V, w: Int, _ m: Ramp) {
        let tones = Canvas.tones(w)
        for (p, i) in Canvas.segment(a, b, w: w) {
            let t = tones[min(i, tones.count - 1)]
            let ring = (p.x + p.y) % 2 == 0
            let tone: HeroArt.Tone = switch t {
            case .hi, .lt: ring ? .hi : .md
            case .md: ring ? .lt : .dk
            default: ring ? .md : .dp
            }
            canvas.set(p.x, p.y, m[tone], .gear)
        }
    }

    mutating func drawPauldron(_ chest: GearLook, shoulder: V, front: Bool) {
        let m = front ? mat(chest) : mat(chest).behind
        let half = Double(body.upperW) / 2
        switch chest.styleID {
        case "chest.plate":
            let cap = Canvas.ellipse(shoulder.x, shoulder.y + 0.5, half + 1.6, 2.6).filter { $0.y <= Int(shoulder.y) + 2 }
            canvas.fill(cap, m, .gear, soft: true)
            let bottom = cap.map(\.y).max() ?? 0
            for p in cap where p.y == bottom { canvas.set(p.x, p.y + 1, m.dk, .gear) }
            for p in cap where p.y == bottom - 1 { canvas.set(p.x, p.y, m.dk, .gear) }
            let d = front ? dye(chest) : dye(chest).behind
            let minX = cap.map(\.x).min() ?? 0
            canvas.set(minX + 1, bottom, d.md, .gear)
        case "chest.leather":
            let cap = Canvas.ellipse(shoulder.x, shoulder.y, half + 0.8, 1.8).filter { $0.y <= Int(shoulder.y) + 1 }
            canvas.fill(cap, m, .gear)
            canvas.set(Int(shoulder.x), Int(shoulder.y) - 1, HeroArt.Painter.gold.lt, .gear)
        default:
            break
        }
    }

    // MARK: - Guantes

    mutating func drawGlove(_ g: GearLook, elbow: V, hand: V, fist: Pt, front: Bool) {
        let m = front ? mat(g) : mat(g).behind
        let d = front ? dye(g) : dye(g).behind
        let f = body.fist
        let skinR = front ? skin : skin.behind
        let skinTag: HeroArt.Tag = race == .werewolf ? .fur : .skin
        switch g.styleID {
        case "gloves.gauntlets":
            canvas.limb(elbow.lerp(hand, 0.3), hand, w: body.foreW + 1, m, .gear, metal: true)
            let flare = Canvas.segment(elbow.lerp(hand, 0.3), elbow.lerp(hand, 0.5), w: body.foreW + 2)
            for (p, i) in flare { canvas.set(p.x, p.y, m[Canvas.tones(body.foreW + 2, metal: true)[i]], .gear) }
            for (p, _) in Canvas.segment(elbow.lerp(hand, 0.42), elbow.lerp(hand, 0.5), w: body.foreW + 2) {
                canvas.set(p.x, p.y, d.md, .gear)
            }
            let box = Canvas.rect(fist.x, fist.y, f + 1, f)
            canvas.fill(box, m, .gear)
            for x in fist.x..<(fist.x + f + 1) { canvas.set(x, fist.y + f / 2, m.dk, .gear) }
            canvas.set(fist.x + 1, fist.y, m.hi, .gear)
        case "gloves.leather":
            canvas.limb(elbow.lerp(hand, 0.55), hand, w: body.foreW + 1, m, .gear)
            for (p, _) in Canvas.segment(elbow.lerp(hand, 0.55), elbow.lerp(hand, 0.62), w: body.foreW + 1) {
                canvas.set(p.x, p.y, m.lt, .gear)
            }
            canvas.fill(Canvas.rect(fist.x, fist.y, f, f), m, .gear)
            canvas.set(fist.x + f - 1, fist.y + 1, d.md, .gear)
            canvas.set(fist.x, fist.y + f - 1, d.dk, .gear)
        case "gloves.bracers":
            canvas.limb(elbow.lerp(hand, 0.2), elbow.lerp(hand, 0.8), w: body.foreW + 1, m, .gear, metal: true)
            for (p, _) in Canvas.segment(elbow.lerp(hand, 0.46), elbow.lerp(hand, 0.56), w: body.foreW + 1) {
                canvas.set(p.x, p.y, d.md, .gear)
            }
            canvas.fill(Canvas.rect(fist.x, fist.y, f, f), skinR, skinTag)
        default: // gloves.wraps
            let pts = canvas.limb(elbow.lerp(hand, 0.3), hand, w: body.foreW, m, .cloth)
            for p in pts where (p.x + 2 * p.y) % 4 == 0 { canvas.set(p.x, p.y, m.dk, .cloth) }
            canvas.fill(Canvas.rect(fist.x, fist.y, f, f), m, .cloth)
            for x in fist.x..<(fist.x + f) { canvas.set(x, fist.y + 1, d.md, .cloth) }
            // Cabo suelto que ondea hacia atrás.
            let w = elbow.lerp(hand, 0.35).px
            canvas.set(w.x - 1, w.y + 1, d.md, .cloth)
            canvas.set(w.x - 2 + rig.flowX / 2, w.y + 2, d.dk, .cloth)
        }
    }

    // MARK: - Botas

    mutating func drawBoot(_ g: GearLook, knee: V, ankle: V, foot: HeroArt.Foot, shinW: Int, front: Bool) {
        let m = front ? mat(g) : mat(g).behind
        let d = front ? dye(g) : dye(g).behind
        let len = body.footLen
        switch g.styleID {
        case "boots.greaves":
            canvas.limb(knee, ankle, w: shinW + 1, m, .gear, metal: true)
            drawFoot(ankle: ankle, w: shinW + 1, kind: foot, ramp: m, len: len + 1)
            // Rodillera
            let cop = Canvas.ellipse(knee.x, knee.y, Double(shinW) / 2 + 1, 1.7)
            canvas.fill(cop, m, .gear, soft: true)
            let k = knee.px
            canvas.set(k.x, k.y, d.md, .gear)
            // Junta de la espinilla
            let mid = knee.lerp(ankle, 0.6).px
            canvas.set(mid.x - 1, mid.y, m.dk, .gear); canvas.set(mid.x, mid.y, m.dk, .gear)
        case "boots.leather":
            let top = knee.lerp(ankle, 0.25)
            canvas.limb(top, ankle, w: shinW + 1, m, .gear)
            drawFoot(ankle: ankle, w: shinW + 1, kind: foot, ramp: m, len: len)
            // Vuelta de la caña
            let cuff = Set(Canvas.segment(top, knee.lerp(ankle, 0.42), w: shinW + 2).map(\.0))
            canvas.fill(cuff, Ramp(hi: m.hi, lt: m.hi, md: m.lt, dk: m.md, dp: m.dk), .gear)
            let lace = knee.lerp(ankle, 0.7).px
            canvas.set(lace.x + 1, lace.y, d.md, .gear)
            canvas.set(lace.x + 1, lace.y + 2, d.md, .gear)
        case "boots.fur":
            let top = knee.lerp(ankle, 0.4)
            canvas.limb(top, ankle, w: shinW + 1, m, .gear)
            drawFoot(ankle: ankle, w: shinW + 2, kind: foot, ramp: m, len: len)
            // Borde de piel mullido
            let c = top.px
            let fur = Ramp(hi: 0xFFFFFF, lt: Ink.mix(m.hi, 0xFFFFFF, 0.4), md: m.hi, dk: m.lt, dp: m.md)
            var tuft = Canvas.rect(c.x - shinW / 2 - 2, c.y - 1, shinW + 4, 3)
            for x in stride(from: c.x - shinW / 2 - 2, through: c.x + shinW / 2 + 1, by: 2) { tuft.insert(Pt(x, c.y + 2)) }
            for x in stride(from: c.x - shinW / 2 - 1, through: c.x + shinW / 2 + 1, by: 2) { tuft.insert(Pt(x, c.y - 2)) }
            canvas.fill(tuft, fur, .fur)
            let s = knee.lerp(ankle, 0.75).px
            canvas.set(s.x - 1, s.y, d.md, .gear); canvas.set(s.x, s.y + 1, d.md, .gear); canvas.set(s.x + 1, s.y, d.md, .gear)
        default: // boots.winged
            let top = knee.lerp(ankle, 0.35)
            canvas.limb(top, ankle, w: shinW + 1, m, .cloth)
            drawFoot(ankle: ankle, w: shinW + 1, kind: foot, ramp: m, len: len, tag: .cloth)
            for (p, _) in Canvas.segment(top, knee.lerp(ankle, 0.45), w: shinW + 1) { canvas.set(p.x, p.y, d.md, .cloth) }
            // Alita en el tobillo, hacia atrás.
            let a = ankle.px
            let wing = Ramp(base: Ink.mix(g.dye, 0xFFFFFF, 0.55), spread: 0.8)
            let wx = Int((ankle.x - Double(shinW) / 2).rounded()) - 4
            let rows = front ? ["W....", "WW...", ".WWWW", "..WWW", "...WW"] : ["W...", ".WWW", "..WW"]
            canvas.stamp(rows, x: wx + rig.flowX / 2, y: a.y - (front ? 3 : 2), ["W": Pen(wing, nil, .gear)])
        }
    }

    // MARK: - Petos

    /// Falda que cuelga del cinturón hasta `y1`, se abre con las piernas.
    func skirtPixels(_ rows: [(y: Int, x0: Int, x1: Int, upper: Bool)], from y0: Int, to y1: Int,
                     flare: Double, wrapLegs: Bool) -> Set<Pt> {
        let base = rows[body.belt]
        var pts = Set<Pt>()
        guard y1 >= y0 else { return pts }
        for y in y0...y1 {
            let t = y1 == y0 ? 1 : Double(y - y0) / Double(y1 - y0)
            var a = base.x0 - Int((flare * t).rounded()), b = base.x1 + Int((flare * t).rounded())
            if wrapLegs {
                let xs = legPixels.filter { $0.y == y }.map(\.x)
                if let mn = xs.min(), let mx = xs.max() { a = min(a, mn); b = max(b, mx) }
            }
            for x in a...b { pts.insert(Pt(x, y)) }
        }
        return pts
    }

    mutating func drawChest(_ g: GearLook, rows: [(y: Int, x0: Int, x1: Int, upper: Bool)]) {
        let m = mat(g), d = dye(g)
        var top = Set<Pt>()
        for r in rows where r.upper { for x in r.x0...r.x1 { top.insert(Pt(x, r.y)) } }
        let beltY = rows[body.belt].y
        let cx = torsoCenter + 1
        let y0 = rows[0].y, lastUpper = rows[body.belt - 1].y
        var belt = Set<Pt>()
        for r in rows where !r.upper && r.y <= beltY + 1 { for x in r.x0...r.x1 { belt.insert(Pt(x, r.y)) } }
        let ground = HeroArt.canvasHeight - 1

        switch g.styleID {
        case "chest.plate":
            // Faldón teñido bajo las escarcelas.
            let skirt = skirtPixels(rows, from: beltY + 2, to: beltY + 6, flare: 1.5, wrapLegs: true)
            canvas.fill(skirt, d, .cloth)
            for p in skirt where (p.x - cx) % 3 == 0 && p.y > beltY + 3 { canvas.set(p.x, p.y, d.dk, .cloth) }
            let tassets = skirtPixels(rows, from: beltY + 2, to: beltY + 3, flare: 1, wrapLegs: false)
            canvas.fill(tassets, m, .gear)
            // Peto con volumen: claro a la izquierda, arista central brillante, sombra a la derecha.
            for r in rows where r.upper {
                for x in r.x0...r.x1 {
                    let t = Double(x - r.x0) / Double(max(1, r.x1 - r.x0))
                    var tone: HeroArt.Tone = t < 0.15 ? .lt : (t < 0.45 ? .lt : (t < 0.8 ? .md : .dk))
                    if x == r.x1 || r.y == lastUpper { tone = .dp }
                    if x == r.x0 && r.y > y0 { tone = .md }
                    canvas.set(x, r.y, m[tone], .gear)
                }
            }
            // Borde inferior del pectoral
            for r in rows where r.upper && r.y == y0 + 4 { for x in (r.x0 + 1)..<r.x1 { canvas.set(x, r.y, m.dk, .gear) } }
            // Gola
            for x in (cx - 3)...(cx + 2) { canvas.set(x, y0, x < cx ? m.lt : m.md, .gear) }
            canvas.set(cx - 2, y0, m.hi, .gear)
            // Arista central y brillo del peto.
            for y in (y0 + 2)..<lastUpper { canvas.set(cx - 1, y, m.hi, .gear); canvas.set(cx, y, m.md, .gear) }
            if let r = rows.dropFirst(2).first { canvas.set(r.x0 + 2, r.y, m.hi, .gear); canvas.set(r.x0 + 2, r.y + 1, m.hi, .gear) }
            // Lamas del vientre
            for r in rows where r.upper && (r.y == lastUpper - 1 || r.y == lastUpper - 3) {
                for x in r.x0...r.x1 { canvas.set(x, r.y, m.dk, .gear) }
            }
            canvas.fill(belt, d, .cloth)
            canvas.fill(Canvas.rect(cx, beltY, 2, 2), m, .gear)
        case "chest.chain":
            let skirt = skirtPixels(rows, from: beltY + 2, to: beltY + 5, flare: 1.5, wrapLegs: true)
            let mail = top.union(skirt).union(belt)
            for p in mail {
                let t = Canvas.edgeTone(p, mail, soft: false, corner: false)
                let ring = (p.x + p.y) % 2 == 0
                let tone: HeroArt.Tone = switch t {
                case .hi, .lt: ring ? .hi : .lt
                case .md: ring ? .lt : .dk
                default: ring ? .md : .dp
                }
                canvas.set(p.x, p.y, m[tone], .gear)
            }
            let hem = skirt.map(\.y).max() ?? 0
            for p in skirt where p.y == hem { canvas.set(p.x, p.y, m.dk, .gear) }
            // Cuello de tela y cinturón teñidos.
            for x in (cx - 3)...(cx + 2) { canvas.set(x, y0, x < cx ? d.lt : d.md, .cloth) }
            canvas.set(cx - 1, y0 + 1, d.md, .cloth); canvas.set(cx, y0 + 1, d.dk, .cloth)
            canvas.fill(belt, d, .cloth)
            canvas.fill(Canvas.rect(cx, beltY, 2, 2), HeroArt.Painter.gold, .gear)
        case "chest.leather":
            let skirt = skirtPixels(rows, from: beltY + 2, to: beltY + 4, flare: 1, wrapLegs: true)
            var flaps = Set<Pt>()
            for p in skirt where (p.x - cx) % 4 != 2 || p.y == beltY + 2 { flaps.insert(p) }
            canvas.fill(flaps, m, .gear)
            canvas.fill(top, m, .gear, soft: true)
            for r in rows where r.upper && r.y > y0 {
                // Costuras laterales
                canvas.set(r.x0 + 2, r.y, (r.y % 2 == 0) ? d.md : m.dk, .gear)
                canvas.set(r.x1 - 2, r.y, (r.y % 2 == 0) ? d.dk : m.dk, .gear)
            }
            // Cordones cruzados
            for y in (y0 + 1)..<lastUpper {
                if (y - y0) % 2 == 1 { canvas.set(cx - 1, y, d.lt, .cloth); canvas.set(cx + 1, y, d.md, .cloth) }
                else { canvas.set(cx, y, d.md, .cloth) }
            }
            for x in (cx - 3)...(cx + 3) { canvas.set(x, y0, x < cx ? m.hi : m.lt, .gear) }
            canvas.fill(belt, Ramp(material: [m.md, m.dk, m.dp]), .gear)
            canvas.fill(Canvas.rect(cx, beltY, 2, 2), Ramp(material: [0xF0F0F8, 0xB0B4C4, 0x6A6E80]), .gear)
            for p in flaps where p.y == beltY + 2 && (p.x - cx) % 4 == 0 { canvas.set(p.x, p.y, HeroArt.Painter.gold.lt, .gear) }
        case "chest.robe":
            let hemY = ground - 3
            let skirt = skirtPixels(rows, from: beltY + 2, to: hemY, flare: 3, wrapLegs: true)
            var robe = skirt
            for p in skirt { let sh = rig.flowX / 2; if sh != 0, p.y >= hemY - 2 { robe.insert(Pt(p.x + sh, p.y)) } }
            canvas.fill(robe, m, .cloth)
            for p in robe where p.y >= hemY - 1 { canvas.set(p.x, p.y, p.y == hemY ? d.dk : d.md, .cloth) }
            // Pliegues
            for p in robe where p.y > beltY + 3 && p.y < hemY - 1 && (p.x - cx) % 3 == 1 { canvas.set(p.x, p.y, m.dk, .cloth) }
            canvas.fill(top, m, .cloth, soft: true)
            // Abertura delantera y cuello teñidos.
            for y in y0...hemY {
                let x = cx + (y > beltY ? (y - beltY) / 6 : 0)
                if canvas[x, y] != nil { canvas.set(x, y, d.lt, .cloth); canvas.set(x + 1, y, d.dk, .cloth) }
            }
            canvas.set(cx - 2, y0, d.md, .cloth); canvas.set(cx - 1, y0 + 1, d.md, .cloth)
            canvas.set(cx + 3, y0, d.dk, .cloth); canvas.set(cx + 2, y0 + 1, d.dk, .cloth)
            canvas.fill(belt, d, .cloth)
            // Nudo del fajín
            let side = rows[body.belt].x1 - 1
            canvas.set(side, beltY + 2, d.md, .cloth); canvas.set(side, beltY + 3, d.dk, .cloth)
            canvas.set(side - 1, beltY + 4 + max(0, -rig.flowX / 2), d.dk, .cloth)
        default: // chest.tabard
            // Gambesón acolchado del material.
            canvas.fill(top, m, .cloth, soft: true)
            for r in rows where r.upper && (r.y - y0) % 3 == 2 { for x in r.x0...r.x1 { canvas.set(x, r.y, m.dk, .cloth) } }
            // Tabardo teñido: panel delantero que cuelga entre las piernas.
            let hang = beltY + 7
            var panel = Set<Pt>()
            for y in y0...hang {
                let sway = y > beltY + 1 ? (rig.flowX * (y - beltY - 1)) / 6 : 0
                let half = y < y0 + 2 ? 2 : 3
                for x in (cx - half + sway)...(cx + half - 1 + sway) { panel.insert(Pt(x, y)) }
            }
            canvas.fill(panel, d, .cloth)
            for p in panel where p.y == hang { canvas.set(p.x, p.y, m.lt, .cloth) }
            // Emblema
            let ey = y0 + 2
            let emblem = [(0, 0), (-1, 1), (0, 1), (1, 1), (0, 2), (0, 3)]
            for (ex, dy) in emblem { canvas.set(cx - 1 + ex, ey + dy, dy == 1 && ex == 1 ? m.md : m.hi, .cloth) }
            canvas.fill(belt, clothes.belt, .gear)
            canvas.fill(Canvas.rect(cx, beltY, 2, 2), HeroArt.Painter.gold, .gear)
        }
    }

    // MARK: - Cascos

    /// Cráneo desplazado a coordenadas del lienzo.
    var skullBox: (l: Int, r: Int, t: Int, brow: Int, jaw: Int, c: Int) {
        let o = headOrigin, s = body.skull
        return (o.x + s.left, o.x + s.right, o.y + s.top, o.y + s.brow, o.y + s.jaw, o.x + (s.left + s.right + 1) / 2)
    }

    func dome(extra: Double = 1) -> Set<Pt> {
        let k = skullBox
        let cx = Double(k.l + k.r + 1) / 2
        let rx = Double(k.r - k.l + 1) / 2 + extra
        let cy = Double(k.brow) + 1.5
        let ry = cy - Double(k.t - 2)
        return Canvas.ellipse(cx, cy, rx, ry).filter { $0.y <= k.brow + 1 }
    }

    mutating func drawHelmetBack(_ g: GearLook) {
        let k = skullBox
        let d = dye(g), m = mat(g)
        switch g.styleID {
        case "helm.knight":
            // Penacho teñido: nace en la cima y cae hacia atrás (ondea al correr).
            let plume = [
                "........QQPP.",
                "......QQPPPPP",
                "....QQPPPPPDP",
                "...QPPPPDPPP.",
                "..QPPPDPPPP..",
                ".QPPDPPPPP...",
                "QPPDPPPDP....",
                "PPDPPPDP.....",
                "PDPP.DP......",
                "PDP..D.......",
                ".D...........",
            ]
            let pens: [Character: Pen] = ["P": Pen(d, nil, .cloth), "D": Pen(d, .dk, .cloth), "Q": Pen(d, .lt, .cloth)]
            canvas.stamp(plume, x: k.c - 11 + rig.flowX, y: k.t - 7 + max(rig.flowY, -1), pens)
        case "helm.hood":
            // Pico de la capucha cayendo por la espalda.
            let rows = ["MMMM....", "MMMMM...", ".MMMMM..", "..MMMMM.", "...MMMM.", "....MMM.", ".....MM.", "......M."]
            canvas.stamp(rows, x: k.l - 6 + rig.flowX, y: k.brow + 2 + rig.flowY, ["M": Pen(m.behind, nil, .cloth)], flip: true)
        case "helm.great":
            // Lambrequín teñido.
            let rows = [".DDDDD...", "DDDDDDD..", "DDDDDDDD.", ".DDDDDDDD", "..DDD.DDD", "..DD..DD.", "...D...D."]
            canvas.stamp(rows, x: k.l - 6 + rig.flowX, y: k.t + 2 + rig.flowY, ["D": Pen(d.behind, nil, .cloth)])
        default:
            break
        }
    }

    mutating func drawHelmet(_ g: GearLook) {
        drawHelmetShell(g)
        if race == .werewolf, g.styleID != "helm.circlet" {
            // Las orejas asoman por encima de cualquier casco.
            let o = headOrigin
            canvas.stamp(Array(HeroArt.wolfHead.rows.prefix(5)), x: o.x + HeroArt.wolfHead.x, y: o.y + HeroArt.wolfHead.y, wolfPens)
        }
    }

    mutating func drawHelmetShell(_ g: GearLook) {
        let k = skullBox
        let m = mat(g), d = dye(g)
        let wolf = race == .werewolf
        switch g.styleID {
        case "helm.knight":
            var shell = dome()
            for y in (k.brow + 2)...k.jaw {
                for x in (k.l - 1)...(k.l + 1) { shell.insert(Pt(x, y)) }
                for x in (k.r - 1)...(k.r + 1) { shell.insert(Pt(x, y)) }
            }
            canvas.fill(shell, m, .gear, soft: true)
            canvas.castShadow(from: shell, onto: .skin, skin.md)
            // Aro de la frente con remaches.
            for p in shell where p.y == k.brow { canvas.set(p.x, p.y, m.lt, .gear) }
            for p in shell where p.y == k.brow + 1 { canvas.set(p.x, p.y, m.dk, .gear) }
            for x in stride(from: k.l + 1, through: k.r, by: 4) { canvas.set(x, k.brow, m.hi, .gear) }
            // Visera levantada con rendija.
            let vy = k.brow - (wolf ? 4 : 5)
            let visor = Canvas.rect(k.c - 4, vy, k.r - k.c + 6, 3)
            canvas.fill(visor, m, .gear)
            for x in (k.c - 2)...(k.r + 1) { canvas.set(x, vy + 1, Ink.outline, .gear) }
            canvas.set(k.r + 2, vy + 1, m.md, .gear)
            // Cresta central
            for y in (k.t - 1)..<vy { canvas.set(k.c - 1, y, m.hi, .gear) }
            // Soporte del penacho
            canvas.set(k.c - 1, k.t - 3, m.lt, .gear); canvas.set(k.c, k.t - 3, m.dk, .gear)
        case "helm.horned":
            let shell = dome(extra: 0.5)
            canvas.fill(shell, m, .gear, soft: true)
            canvas.castShadow(from: shell, onto: .skin, skin.md)
            for p in shell where p.y >= k.brow { canvas.set(p.x, p.y, p.y == k.brow ? d.md : d.dk, .gear) }
            for p in shell where p.y == k.brow - 1 { canvas.set(p.x, p.y, m.dk, .gear) }
            for x in stride(from: k.l, through: k.r, by: 3) { canvas.set(x, k.brow, Self.gold.lt, .gear) }
            // Nasal
            if !wolf {
                for y in (k.brow + 1)...(k.brow + 4) { canvas.set(k.c + 1, y, m.lt, .gear); canvas.set(k.c + 2, y, m.dk, .gear) }
            }
            // Cuernos
            let horn = ["H........", "HH.......", ".HH......", ".HHH.....", "..HHH....", "..HHHH...", "...HHHHH.", "....HHHHH"]
            let pens: [Character: Pen] = ["H": Pen(Self.ivory, nil, .gear)]
            canvas.stamp(horn, x: k.l - 8, y: k.brow - 11, pens)
            canvas.stamp(Array(horn.dropFirst(2)), x: k.r - 1, y: k.brow - 9, pens, flip: true)
        case "helm.great":
            var shell = Canvas.rect(k.l - 1, k.t - 2, k.r - k.l + 3, k.jaw - k.t + 5)
            for x in (k.l - 2)...(k.r + 2) { shell.insert(Pt(x, k.jaw + 3)) }
            for (dx, dy) in [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (0, 2)] {
                shell.remove(Pt(k.l - 1 + dx, k.t - 2 + dy))
                shell.remove(Pt(k.r + 1 - dx, k.t - 2 + dy))
            }
            canvas.fill(shell, m, .gear, soft: true)
            // Arista vertical (mira a la derecha).
            let rx = k.c + 2
            for y in (k.t - 1)...(k.jaw + 2) { canvas.set(rx, y, m.hi, .gear); canvas.set(rx + 1, y, m.dk, .gear) }
            // Rendija de los ojos
            for x in (k.l + 3)...(k.r - 1) where x != rx && x != rx + 1 { canvas.set(x, k.brow + 2, Ink.outline, .gear) }
            for x in (k.l + 4)...(k.r - 2) where x != rx && x != rx + 1 { canvas.set(x, k.brow + 3, m.dp, .gear) }
            // Respiraderos
            for y in stride(from: k.jaw - 1, through: k.jaw + 1, by: 2) {
                for x in stride(from: rx + 3, through: k.r, by: 2) { canvas.set(x, y, Ink.outline, .gear) }
            }
            // Ribete teñido y remaches
            for x in (k.l)...(k.r) { canvas.set(x, k.t + 1, d.md, .gear) }
            canvas.set(k.l + 1, k.jaw + 1, m.hi, .gear)
            for x in (k.l - 2)...(k.r + 2) { canvas.set(x, k.jaw + 3, x == k.l - 2 ? m.md : m.dk, .gear) }
            for y in (k.t + 2)...(k.jaw + 2) { canvas.set(k.r + 1, y, m.dk, .gear) }
            if wolf {
                // El hocico asoma por delante.
                let o = headOrigin
                canvas.stamp(HeroArt.wolfHead.rows.enumerated().map { i, row in i >= 13 ? row : "" }, x: o.x + HeroArt.wolfHead.x, y: o.y + HeroArt.wolfHead.y,
                             wolfPens.filter { $0.key != "F" })
            }
        case "helm.hood":
            let cx = Double(k.l + k.r + 1) / 2
            let rx = Double(k.r - k.l + 1) / 2 + 2.2
            var hood = Canvas.ellipse(cx, Double(k.brow) + 2, rx, Double(k.brow - k.t) + 5).filter { $0.y <= k.jaw + 3 }
            for y in (k.brow + 2)...(k.jaw + 4) { for x in (k.l - 2)...(k.l + 1) { hood.insert(Pt(x, y)) } }
            let face = Canvas.ellipse(cx + 1.5, Double(k.brow) + 5.5, rx - 4.5, wolf ? 6.5 : 7.2)
            let snout = wolf ? Canvas.rect(k.r - 2, k.brow, 12, 10) : []
            hood.subtract(face)
            hood.subtract(snout)
            canvas.fill(hood, m, .cloth, soft: true)
            for p in hood where face.contains(Pt(p.x, p.y + 1)) || face.contains(Pt(p.x - 1, p.y)) || face.contains(Pt(p.x + 1, p.y)) {
                canvas.set(p.x, p.y, d.md, .cloth)
            }
            canvas.castShadow(from: hood, onto: .skin, skin.md)
            // Pliegue
            for y in (k.t)...(k.brow) { canvas.set(k.l + 3 + (y - k.t) / 4, y, m.dk, .cloth) }
        default: // helm.circlet
            let y = k.brow - 2
            for x in (k.l - 1)...(k.r + 1) {
                let edge = x <= k.l + 1 || x >= k.r - 1
                let yy = edge ? y + 1 : y
                canvas.set(x, yy, x < k.c ? m.lt : m.md, .gear)
                canvas.set(x, yy + 1, m.dk, .gear)
            }
            for x in stride(from: k.l + 2, through: k.r - 2, by: 3) { canvas.set(x, y, m.hi, .gear) }
            let gx = k.c + 1
            canvas.fill(Canvas.rect(gx - 1, y - 2, 4, 4), m, .gear)
            canvas.fill(Canvas.rect(gx, y - 1, 2, 2), d, .gear)
            canvas.set(gx, y - 1, 0xFFFFFF, .gear)
            canvas.set(gx + 1, y - 3, m.lt, .gear)
        }
    }
}

// MARK: - Iconos de las piezas

extension HeroArt {
    /// Icono de una pieza de armadura para el inventario, la tienda y la armería (14×14 + contorno).
    static func gearIcon(_ gear: GearLook, slot: EquipmentSlot) -> PixelGrid {
        let m = Ramp(material: gear.material), d = Ramp(base: gear.dye)
        let pens: [Character: Pen] = [
            "H": Pen(m, .hi), "L": Pen(m, .lt), "M": Pen(m, .md), "D": Pen(m, .dk), "E": Pen(Ramp.flat(Ink.mix(m.dp, Ink.outline, 0.5)), .md),
            "Q": Pen(d, .lt), "P": Pen(d, .md), "p": Pen(d, .dk),
            "K": Pen(Ramp.flat(Ink.outline), .md), "W": Pen(Ramp.flat(0xFFFFFF), .md),
            "I": Pen(Painter.ivory, .lt), "i": Pen(Painter.ivory, .dk),
            "G": Pen(Painter.gold, .lt), "g": Pen(Painter.gold, .dk),
        ]
        var c = Canvas(width: 14, height: 14)
        c.stamp(iconRows(gear.styleID, slot: slot), x: 0, y: 0, pens)
        return c.grid.outlined()
    }

    static func iconRows(_ id: String, slot: EquipmentSlot) -> [String] {
        switch id {
        case "helm.knight": [
            "..QPP.........",
            ".QPPPpp.......",
            "..PpppHLMM....",
            "....HLLMMMMD..",
            "...HLLMMMMMMD.",
            "...LLMMMMMMMD.",
            "...LHHHHHHHMD.",
            "...LKKKKKKKKD.",
            "...LLLLLLLLLD.",
            "...LMDDDDDDMD.",
            "...LMEEEEELMD.",
            "...LMEEEEELMD.",
            "...LMDEEEEDMD.",
            "....DD.....D..",
        ]
        case "helm.horned": [
            "I............I",
            "Ii..........iI",
            ".Ii........iI.",
            ".IIi.HLMMD.iII",
            "..IIHLLMMMDII.",
            "...LLMMMMMMD..",
            "..HLLMMMMMMMD.",
            "..LMMMMMMMMMD.",
            "..DDDDDDDDDDD.",
            "..QGPPGPPGPPp.",
            "..L...MD....D.",
            "..L...MD....D.",
            "......MD......",
            "......D.......",
        ]
        case "helm.great": [
            "..QPPPP.......",
            "..HLLMMMMMD...",
            ".HLLMMMMMMMD..",
            ".LLMMMMHDMMD..",
            ".LMMMMMHDMMD..",
            ".LMMMMMHDMMD..",
            ".KKKKKKHDKKD..",
            ".LMMMMMHDMMD..",
            ".LMMMMMHDKMD..",
            ".LMMMMMHDMMD..",
            ".LMMMMMHDKMD..",
            ".LMMMMMHDMMD..",
            ".DDDDDDDDDDD..",
            "..............",
        ]
        case "helm.hood": [
            "....LLMM......",
            "...LLMMMM.....",
            "..LLMMMMMD....",
            ".LLMPPPPPMD...",
            ".LMPEEEEEPD...",
            "LLPEEEEEEEPD..",
            "LMPEEEEEEEPD..",
            "LMPEEEEEEEPD..",
            "LMMPEEEEEPMD..",
            "LMMMPPPPPMMD..",
            ".MMMMMMMMMMMD.",
            "..DMMMMMMMMMMD",
            "....DDDDDDDDD.",
            "..............",
        ]
        case "helm.circlet": [
            "..............",
            "..............",
            "..............",
            "......QPp.....",
            "....LMPWPMD...",
            "..HLM.pPp.MD..",
            ".HL.........D.",
            ".L..........D.",
            ".L..........D.",
            ".HL........MD.",
            "..HLMMMMMMMD..",
            "....LLMMMD....",
            "..............",
            "..............",
        ]
        case "chest.plate": [
            ".HLM......LMD.",
            "HLLMM.LM.LMMMD",
            "LLMMMLLMDMMMMD",
            "LMMMLLHMMDMMMD",
            ".MDMLLHMMMDMD.",
            "...LLLHMMMMD..",
            "...LLLHMMMMD..",
            "...DDDDDDDDD..",
            "...LLLHMMMMD..",
            "...DDDDDDDDD..",
            "...PPPPGPPPp..",
            "...LMDPPPLMD..",
            "...LMDPPpLMD..",
            "......PPp.....",
        ]
        case "chest.chain": [
            "..LM......MD..",
            ".LMLM.QP.MDMD.",
            "LMLMLMQPMDMDMD",
            "MLMLMLMLMLMDMD",
            "LMLMLMLMLMDMD.",
            "..LMLMLMLMDM..",
            "..MLMLMLMLMD..",
            "..LMLMLMLMDM..",
            "..PPPPGPPPPp..",
            "..LMLMLMLMDM..",
            ".LMLMLMLMLMDM.",
            ".MLMLMLMLMLMD.",
            ".DDDDDDDDDDDD.",
            "..............",
        ]
        case "chest.leather": [
            "..LM......MD..",
            ".HLLM.HL.LMMD.",
            "HLLLMLQ.QMMMMD",
            "LLLMMM.P.MMMMD",
            ".LMDMMQ.QMMDM.",
            "..LMDMM.PMDMD.",
            "..LMDMQ.QMDMD.",
            "..LMDMMPMMDMD.",
            "..DDDDDWDDDDD.",
            "..LMM.LMM.LMD.",
            "..LMM.LMM.LMD.",
            "..DGD.DGD.DGD.",
            "..............",
            "..............",
        ]
        case "chest.robe": [
            "..LM.QP..MD...",
            ".LLMMPpMMMMD..",
            "LLMMMQPMMMMMD.",
            "LMMMMQPMMMMMD.",
            ".LMMMQPMMMMD..",
            "..PPPPPPPPPp..",
            "..LMMMQPMMMD..",
            "..LMMMQPMMMD..",
            ".LLMMMQPMMMMD.",
            ".LMMMMQPMMMMD.",
            "LLMMMMQPMMMMMD",
            "LMMMMMQPMMMMMD",
            "PPPPPPPPPPPPPp",
            "..............",
        ]
        case "chest.tabard": [
            "..LM......MD..",
            ".LLMQPPPPpMMD.",
            "LLMMPPHPPpMMMD",
            "LMMMPHHHPpMMMD",
            ".DMMPPHPPpMMD.",
            "..LMPPHPPpMD..",
            "..DMPPPPPpMD..",
            "..LMPPPPPpMD..",
            "..KKKKGKKKKK..",
            "....PPPPPp....",
            "....PPPPPp....",
            "....PPPPPp....",
            "....LLLLLL....",
            "..............",
        ]
        case "gloves.gauntlets": [
            "......HLMD....",
            ".....HLMMD....",
            "..HL.LLMMD....",
            ".HLM.LMMMD.LD.",
            ".LMMLLMMMDLMD.",
            ".LMMLMMMMDMMD.",
            ".LMMMMMMMMMMD.",
            ".DLMMMMMMMMD..",
            "..DDDDDDDDD...",
            "..PPPPPPPPp...",
            "..HLMMMMMMD...",
            ".HLLMMMMMMMD..",
            ".LLMMMMMMMMD..",
            ".DDDDDDDDDDD..",
        ]
        case "gloves.leather": [
            "..............",
            ".....LM.......",
            "..LM.LM.LM....",
            "..LM.LMDLMD...",
            "..LMDLMDLMD...",
            "..LMMLMMLMD.LD",
            "..LMMMMMMMMLMD",
            "..LMMMMMMMMMD.",
            "..LMMMMMMMMD..",
            "...DMMMMMMD...",
            "...LLLLLLLD...",
            "...LPLPLPMD...",
            "...DDDDDDDD...",
            "..............",
        ]
        case "gloves.bracers": [
            "..............",
            "...HLLMMMMD...",
            "..HLLMMMMMMD..",
            "..LLMMMMMMMD..",
            "..LMDDDDDDMD..",
            "..PPPPGPPPPp..",
            "..PPPPGPPPPp..",
            "..LMDDDDDDMD..",
            "..LLMMMMMMMD..",
            "..HLMMMMMMMD..",
            "..LLMMMMMMMD..",
            "...DDDDDDDD...",
            "..............",
            "..............",
        ]
        case "gloves.wraps": [
            "..............",
            "....LMLM......",
            "...LMDPMD.....",
            "...LPLMDM.....",
            "...LMDMPMD....",
            "...PLMDMMD....",
            "...LMPMDMD....",
            "...LMDMPMD....",
            "...PLMDMMD....",
            "..LLMPMDPMD...",
            "..LMDMMPMMD...",
            "..DDDDDDDDD.P.",
            "...........Pp.",
            "............p.",
        ]
        case "boots.greaves": [
            "...HLMMD......",
            "..HLLMMMD.....",
            "..LLPPMMD.....",
            "..DLMMMDD.....",
            "...LHMMD......",
            "...LHMMD......",
            "...LHMMD......",
            "...DDDDD......",
            "...LHMMD......",
            "...LHMMMMMD...",
            "..LLHMMMMMMD..",
            "..LDMDMDMMMMD.",
            "..EEEEEEEEEEE.",
            "..............",
        ]
        case "boots.leather": [
            "..HHLLLL......",
            "..LLLMMMD.....",
            "...LMMMD......",
            "...LMMPD......",
            "...LMMMD......",
            "...LMMPD......",
            "...LMMMD......",
            "...LMMPD......",
            "...LMMMMMMD...",
            "..LLMMMMMMMD..",
            "..LMMMMMMMMMD.",
            "..EEEEEEEEEEE.",
            "..............",
            "..............",
        ]
        case "boots.fur": [
            "..W.W.W.W.....",
            ".WWWWWWWWW....",
            ".WHHHHHHHW....",
            "..WHHHHHW.....",
            "...LMMMD......",
            "...LPMPD......",
            "...LMPMD......",
            "...LPMPD......",
            "...LMMMMMMD...",
            "..LLMMMMMMMD..",
            "..LMMMMMMMMMD.",
            "..EEEEEEEEEEE.",
            "..............",
            "..............",
        ]
        default: [ // boots.winged
            "..............",
            ".W....LLMM....",
            "WW....PPPp....",
            ".WW...LMMD....",
            ".WQW..LMMD....",
            "..WQQWLMMD....",
            "...WQQLMMD....",
            "....WWLMMD....",
            "......LMMMMMD.",
            ".....LLMMMMMMD",
            ".....LMMMMMMMD",
            ".....DDDDDDDDD",
            "..............",
            "..............",
        ]
        }
    }
}
