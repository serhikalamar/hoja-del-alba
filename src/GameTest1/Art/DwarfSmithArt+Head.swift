import CoreGraphics
import Foundation

// Cabeza del herrero: casco de acero con gafas de forja, cara (cejas, ojos, nariz, boca) y barba trenzada.

extension DwarfSmithArt {
    /// Expresión de la cara según la pose.
    enum Face { case open, closed, happy, focus }

    static func drawHead(_ p: inout Painter, pose: Pose) {
        let S = Ramp.skin
        // Orejas (asoman bajo el casco).
        p.ball(21.5, 24, 3.4, 4.8, S, bias: 0.05)
        p.ball(mirror(21.5), 24, 3.4, 4.8, S, bias: -0.1)
        for (x, y) in [(19, 22), (19, 23), (20, 24), (20, 25)] { p.put(x, y, S[1]); p.put(mirror(x), y, S[0]) }
        // Cara.
        p.ball(39, 26, 16.5, 13.5, S, bias: 0.05)
        drawHelmet(&p)
        drawBeard(&p)
        // Mejillas sonrosadas.
        let blush: Double = pose == .happy ? 0.45 : 0.25
        for (x, y) in [(27, 27), (28, 27), (29, 27), (30, 27), (28, 28), (29, 28), (27, 28)] {
            if p[x, y].map(S.contains) == true { p.tint(x, y, 0xE8606A, blush) }
            if p[mirror(x), y].map(S.contains) == true { p.tint(mirror(x), y, 0xE8606A, blush * 0.6) }
        }
        // Hollín de la forja en la frente y la mejilla.
        for (x, y, t) in [(30, 20, 0.35), (31, 20, 0.45), (32, 21, 0.3), (47, 28, 0.35), (48, 28, 0.25), (46, 29, 0.3)] {
            if p[x, y].map(S.contains) == true { p.tint(x, y, 0x3A3438, t) }
        }
        // Aro de oro en la oreja izquierda.
        let B = Ramp.brass
        for (x, y, i) in [(18, 26, 3), (18, 27, 2), (19, 28, 1), (20, 28, 2), (20, 27, 4)] { p.put(x, y, B[i]) }
        drawMouth(&p, pose: pose)
        drawMustache(&p)
        drawNose(&p)
        let face: Face
        switch pose {
        case .blink: face = .closed
        case .happy: face = .happy
        case .hammerUp, .hammerDown: face = .focus
        default: face = .open
        }
        drawEyes(&p, face)
        drawBrows(&p, face)
    }

    // MARK: Casco y gafas

    static func drawHelmet(_ p: inout Painter) {
        let S = Ramp.steel, B = Ramp.brass, L = Ramp.leather
        // Cúpula de acero.
        p.ball(39, 17.5, 19.5, 17.5, S, bias: -0.12, clip: { _, y in y <= 15 })
        // Juntas de las placas con remaches.
        for y in 2...14 {
            let ny = (Double(y) + 0.5 - 17.5) / 17.5
            let half = 19.5 * max(0, 1 - ny * ny).squareRoot()
            let xl = Int((39 - half * 0.62).rounded(.down)), xr = Int((39 + half * 0.62).rounded(.down))
            p.put(xl, y, S[1]); p.put(xl + 1, y, S[4])
            p.put(xr, y, S[0]); p.put(xr - 1, y, S[3])
            if y == 5 || y == 12 { p.put(xl - 2, y, S[5]); p.put(xl - 2, y + 1, S[1]); p.put(xr + 2, y, S[4]); p.put(xr + 2, y + 1, S[0]) }
        }
        // Arañazos y abolladuras.
        for (x, y) in [(26, 4), (27, 5), (50, 6), (51, 7), (31, 13), (46, 3)] { p.shift(x, y, S, 1) }
        for (x, y) in [(27, 4), (51, 6), (45, 13)] { p.shift(x, y, S, -1) }
        // Cresta central.
        for y in 0...14 {
            p.put(37, y, S[3]); p.put(38, y, y < 6 ? S[5] : S[4]); p.put(39, y, S[3]); p.put(40, y, S[1])
        }
        for y in [3, 8, 13] { p.put(38, y, S[5]); p.put(39, y + 1, S[0]) }
        // Aro de latón del borde.
        for y in 14...18 {
            let ny = (Double(y) - 15.6) / 2.6
            let l = y == 14 ? 19.5 : 17.5, r = y == 14 ? 58.5 : 60.5
            for x in Int(l)..<Int(r) {
                let nx = ((Double(x) + 0.5 - l) / (r - l)) * 2 - 1
                p.put(x, y, B[Painter.tone(nx * 0.75, ny, B.count)])
            }
        }
        for x in 18..<60 { p.put(x, 18, x < 39 ? B[1] : B[0]) }
        for x in [21, 27, 49, 55] { rivet(&p, x, 15, Ramp.steel) }
        // Gafas de forja: correa de cuero y dos lentes con aro de latón.
        for x in 19...58 where p[x, 9] != nil {
            p.put(x, 8, L[3]); p.put(x, 9, L[2]); p.put(x, 10, L[1])
            if x % 4 == 0 { p.put(x, 9, L[3]) }
        }
        for lx in [31.5, mirror(31.5)] { drawLens(&p, cx: lx, cy: 9.5) }
        for x in 36...41 { p.put(x, 9, B[3]); p.put(x, 10, B[1]) }
    }

    static func drawLens(_ p: inout Painter, cx: Double, cy: Double) {
        let B = Ramp.brass, G = Ramp.lens
        let r = 5.2
        for y in Int(cy - r)...Int(cy + r) {
            for x in Int(cx - r)...Int(cx + r) {
                let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
                let d = (dx * dx + dy * dy).squareRoot()
                guard d <= r else { continue }
                if d > 3.4 {
                    p.put(x, y, B[Painter.tone(dx / r, dy / r, B.count, bias: 0.1)])
                } else {
                    // Cristal oscuro: más claro abajo-derecha, donde refleja la fragua.
                    let v = (dx + dy) / 6.8
                    p.put(x, y, G[v < -0.25 ? 0 : (v < 0.15 ? 1 : (v < 0.4 ? 2 : 3))])
                }
            }
        }
        let ix = Int(cx.rounded(.down)), iy = Int(cy.rounded(.down))
        p.put(ix - 2, iy - 2, 0xFFFFFF); p.put(ix - 1, iy - 2, 0xD8F0EC); p.put(ix - 2, iy - 1, 0xD8F0EC)
        p.put(ix + 1, iy + 2, ember); p.put(ix + 2, iy + 1, 0xFFC070)
    }

    // MARK: Barba

    static func beardHalfWidth(_ y: Int) -> Double { y < 28 ? 17 : min(22, 17 + Double(y - 28) * 0.28) }

    /// Fila donde empieza la barba según la distancia al centro (patillas a los lados, bigote en medio).
    static func beardTop(_ adx: Double) -> Double {
        if adx >= 13.5 { return 17 }
        if adx >= 11.5 { return 24 }
        return 28.5 + (11.5 - adx) * 0.4
    }

    static let lockEnds = [50, 55, 59, 59, 55, 50]
    static let braidX = [28.0, mirror(28.0)]

    static func drawBeard(_ p: inout Painter) {
        let R = Ramp.beard
        // Trenzas primero (cuelgan por detrás de las puntas).
        for (i, bx) in braidX.enumerated() { drawBraid(&p, bx: bx, side: i == 0 ? -1 : 1) }
        let n = lockEnds.count
        for y in 17..<64 {
            let hw = beardHalfWidth(y)
            for x in 0..<innerW {
                let dx = Double(x) + 0.5 - 39
                let adx = abs(dx)
                guard adx <= hw, Double(y) >= beardTop(adx) else { continue }
                let u = dx / hw
                let s = (u + 1) / 2 * Double(n) + 0.22 * sin(Double(y) * 0.32 + u * 2.2)
                let k = max(0, min(n - 1, Int(s.rounded(.down))))
                let f = s - Double(k)
                let rem = lockEnds[k] - y
                if rem < 0 { continue }
                if rem < 4 && abs(f - 0.5) > (Double(rem) + 0.6) / 8 { continue }
                let deep = y > 40 || adx > 13
                var i: Int
                if f < 0.1 { i = deep ? 0 : 2 }
                else if f < 0.18 { i = deep ? 1 : 2 }
                else if f < 0.45 { i = 4 }
                else if f < 0.75 { i = 3 }
                else { i = 2 }
                // Mechón interior: una raya oscura fina a media altura de cada mechón.
                if deep && f > 0.6 && f < 0.68 && (y + k * 4) % 9 < 4 { i = 1 }
                if u > 0.25 { i -= 1 }
                if u > 0.7 { i -= 1 }
                if adx > hw - 1.2 && u < 0 { i -= 1 }
                if y < Int(beardTop(adx)) + 3 && adx < 13 { i -= 1 }   // sombra del bigote
                if rem < 3 && f > 0.5 { i -= 1 }
                if f >= 0.2 && f < 0.32 && u < 0.2 && (y * 5 + k * 3) % 13 == 0 { i = 5 }
                p.put(x, y, R[max(0, min(5, i))])
            }
        }
    }

    static func drawBraid(_ p: inout Painter, bx: Double, side: Int) {
        let R = Ramp.beard, B = Ramp.brass, S = Ramp.steel
        let bias = side < 0 ? 0.05 : -0.12
        var y0 = 50
        var flip = false
        while y0 < 76 {
            p.ball(bx + (flip ? 0.9 : -0.9), Double(y0) + 1.8, 3.0, 2.3, R, bias: bias)
            let sx = Int(bx.rounded(.down)) + (flip ? -2 : 1)
            p.put(sx, y0 + 3, R[0])
            flip.toggle()
            y0 += 3
        }
        // Anillas: latón arriba, acero abajo.
        for (ry, ramp) in [(57, B), (63, S)] {
            for x in Int(bx - 4)...Int(bx + 3.5) {
                let edge = x == Int(bx - 4) || x == Int(bx + 3.5)
                p.put(x, ry, ramp[edge ? 2 : 3]); p.put(x, ry + 1, ramp[edge ? 1 : 2]); p.put(x, ry + 2, ramp[0])
            }
            p.put(Int(bx - 3), ry, ramp[ramp.count - 1]); p.put(Int(bx - 2), ry, ramp[ramp.count - 1])
            p.put(Int(bx + 1), ry + 1, ramp[ramp.count - 2])
        }
    }

    // MARK: Bigote, nariz, boca

    static func drawMustache(_ p: inout Painter) {
        let R = Ramp.beard
        p.overlay(shadow: { mix($0, 0x2A0A06, 0.55) }) { m in
            for side in [-1.0, 1.0] {
                let bias = side < 0 ? 0.3 : 0.1
                let X: (Double) -> Double = { side < 0 ? $0 : mirror($0) }
                m.ball(X(31.5), 33.2, 8.4, 3.5, R, bias: bias)
                m.ball(X(24.5), 35.4, 3.6, 2.8, R, bias: bias - 0.05)
                m.ball(X(22.4), 38.4, 2.3, 2.3, R, bias: bias - 0.1)
                // Mechones: trazos oscuros en abanico.
                for (x, y) in [(28, 33), (29, 34), (32, 34), (33, 35), (36, 33), (25, 35), (26, 36), (23, 37)] {
                    m.shift(side < 0 ? x : mirror(x), y, R, -2)
                }
                if side < 0 { for (x, y) in [(29, 31), (30, 31), (26, 33), (34, 32)] { m.put(x, y, R[5]) } }
            }
        }
    }

    static func drawNose(_ p: inout Painter) {
        let N = Ramp.nose
        // Puente y nariz grande y redonda.
        for y in 21...24 { p.put(37, y, Ramp.skin[3]); p.put(38, y, Ramp.skin[4]); p.put(39, y, Ramp.skin[3]); p.put(40, y, Ramp.skin[2]) }
        p.ball(39, 28.6, 5.8, 4.9, N, bias: 0.05)
        p.ball(34.4, 31, 2.2, 1.7, N, bias: -0.05)
        p.ball(mirror(34.4), 31, 2.2, 1.7, N, bias: -0.2)
        // Fosas nasales.
        p.put(36, 32, N[0]); p.put(37, 32, N[1]); p.put(41, 32, N[0]); p.put(40, 32, N[1])
        // Sombra bajo la nariz sobre el bigote.
        for x in 35...43 { p.shift(x, 34, Ramp.beard, -1) }
    }

    static func drawMouth(_ p: inout Painter, pose: Pose) {
        let pal: [Character: UInt32] = [
            "K": inkWarm, "D": 0x5A1820, "T": 0xD0605E, "t": 0xF08C80, "W": 0xF4ECE0, "w": 0xC8BCB0, "L": 0xC4605A, "l": 0xE88A78,
        ]
        switch pose {
        case .talk:
            p.stamp([
                ".KKKKKK.",
                "KWWwWWwK",
                "KDDDDDDK",
                "KDTTtTDK",
                ".KTTTTK.",
                "..KKKK..",
            ], pal, 35, 36)
        case .happy:
            p.stamp([
                "K..........K",
                "KKWWWwWWWWKK",
                ".KDDTTtTDDK.",
                "..KKTTTTKK..",
                "....KKKK....",
            ], pal, 33, 37)
        case .hammerUp, .hammerDown:
            p.stamp([
                ".KKKKKK.",
                "KWwWWwWK",
                ".KKKKKK.",
            ], pal, 35, 36)
        default:
            p.stamp([
                "..KKKK..",
                "...Ll...",
            ], pal, 35, 37)
        }
    }

    // MARK: Ojos y cejas

    static func drawEyes(_ p: inout Painter, _ face: Face) {
        let S = Ramp.skin
        let pal: [Character: UInt32] = [
            "K": ink, "W": 0xF4F4F4, "w": 0xC9CDD8, "h": 0xFFFFFF, "i": 0x4F7FD8, "I": 0x23305E,
            "s": S[3], "k": S[1], "d": S[2],
        ]
        let left: [String], right: [String]
        switch face {
        case .open, .focus:
            left = face == .focus ? ["dssssd", "KKKKKK", "WhIIiW", "wiiiiw", "dkkkkd"]
                                  : ["KKKKKK", "WhIIiW", "WiIIiW", "wiiiiw", "dkkkkd"]
            right = left
        case .closed:
            left = ["ssssss", "ssssss", "dssssd", "KKKKKK", "dkkkkd"]
            right = left
        case .happy:
            left = ["ssssss", ".KKKK.", "KssssK", "ssssss", "dddddd"]
            right = left
        }
        p.stamp(left, pal, 27, 22)
        p.stamp(right, pal, mirror(32), 22)
        // Patas de gallo.
        for (x, y) in [(25, 23), (25, 25), (26, 26)] { p.shift(x, y, S, -1); p.shift(mirror(x), y, S, -1) }
        // Bolsas bajo los ojos.
        for x in 28...31 { p.shift(x, 27, S, -1); p.shift(mirror(x), 27, S, -1) }
    }

    static func drawBrows(_ p: inout Painter, _ face: Face) {
        let R = Ramp.beard
        let rows: [String]
        switch face {
        case .focus:
            rows = [
                "....3445....",
                "..23455443..",
                ".2334444543.",
                "1221.2233442",
            ]
        default:
            rows = [
                "....34455...",
                "..2344554432",
                ".23344443321",
                "1221.2232.1.",
            ]
        }
        let oy = face == .happy ? 16 : (face == .focus ? 18 : 17)
        var palL: [Character: UInt32] = [:], palR: [Character: UInt32] = [:]
        for i in 0..<R.count {
            let ch = Character(String(i))
            palL[ch] = R[i]
            palR[ch] = R[max(0, i - (i >= 3 ? 1 : 0))]
        }
        p.overlay(shadow: { mix($0, 0x3A1010, 0.5) }) { b in
            b.stamp(rows, palL, 25, oy)
            b.stamp(rows, palR, mirror(36), oy, flip: true)
        }
    }
}
