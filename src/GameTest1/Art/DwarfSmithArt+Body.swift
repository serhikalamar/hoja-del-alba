import CoreGraphics
import Foundation

// Cuerpo del herrero: túnica, delantal de cuero, brazos, guantes, martillo y chispas.
// Coordenadas en el lienzo interior (sin contorno): 78×86, centro en x = 39 (continuo).

extension DwarfSmithArt {
    /// Ancho/alto interior (antes del contorno) y primera fila tapada por el mostrador.
    static let innerW = width - 2
    static let innerH = height - 2
    static let hiddenRow = height - counterLine - 1

    /// Espejo horizontal para coordenadas continuas (centros) y para índices de pixel.
    static func mirror(_ x: Double) -> Double { Double(innerW) - x }
    static func mirror(_ x: Int) -> Int { innerW - 1 - x }

    // MARK: Torso

    static func drawTorso(_ p: inout Painter) {
        let T = Ramp.tunic
        // Trapecios y pecho.
        for y in 29..<innerH {
            let k = Double(min(y, 42) - 29)
            let l = 25 - k * 1.15, r = 53 + k * 1.15
            let ny = y < 38 ? -0.55 : (y < 46 ? -0.2 : 0.1)
            for x in Int(l)..<Int(r.rounded(.up)) {
                let nx = ((Double(x) + 0.5 - l) / (r - l)) * 2 - 1
                p[x, y] = T[Painter.tone(nx * 0.9, ny, T.count)]
            }
        }
        // Hombros redondos.
        p.ball(12, 38.5, 11, 9, T, bias: 0.05)
        p.ball(mirror(12), 38.5, 11, 9, T, bias: -0.05)
        // Costura de la sisa (pespunte en arco) y arrugas en los hombros.
        for i in 0...12 {
            let a = Double(i) / 12 * 1.9 + 0.2
            let x = Int((12 + cos(a) * 8.5).rounded()), y = Int((38.5 - sin(a) * 7.5).rounded())
            p.put(x, y, i % 2 == 0 ? T[1] : T[3])
            p.put(mirror(x), y, i % 2 == 0 ? T[0] : T[2])
        }
        for (x, y) in [(5, 41), (6, 42), (7, 42), (8, 43)] { p.put(x, y, T[1]); p.put(mirror(x), y, T[0]) }
        for (x, y) in [(6, 40), (7, 41)] { p.put(x, y, T[4]) }
        drawApron(&p)
    }

    /// Delantal de herrero: tirantes sobre los hombros y peto con remaches y quemaduras.
    static func drawApron(_ p: inout Painter) {
        let L = Ramp.leather, B = Ramp.brass
        // Peto.
        for y in 49..<innerH {
            let l = 16.0 - Double(min(y, 56) - 49) * 0.3, r = 62.0 + Double(min(y, 56) - 49) * 0.3
            for x in Int(l)..<Int(r.rounded(.up)) {
                let nx = ((Double(x) + 0.5 - l) / (r - l)) * 2 - 1
                p[x, y] = L[Painter.tone(nx * 0.85, y == 49 ? -0.7 : -0.05, L.count)]
            }
        }
        // Dobladillo superior y pespunte.
        for x in 16...61 { p.put(x, 50, L[1]) }
        for x in stride(from: 18, through: 60, by: 3) { p.put(x, 52, L[4]) }
        // Tirantes (cruzan los hombros).
        p.capsule(20, 29, 17.5, 50, 2.6, 2.6, L, bias: 0.1, roundEnds: false)
        p.capsule(mirror(20), 29, mirror(17.5), 50, 2.6, 2.6, L, bias: -0.05, roundEnds: false)
        for y in 30...49 { p.put(Int(19.6 - Double(y - 29) * 0.12) - 2, y, L[0]) }
        for y in 30...49 { p.put(mirror(Int(19.6 - Double(y - 29) * 0.12) - 2), y, L[0]) }
        // Hebillas de latón en los tirantes.
        for side in [-1, 1] {
            let X: (Int) -> Int = { side < 0 ? $0 : mirror($0) }
            let hb = ["3332", "3..1", "3..1", "2110"]
            for (dy, row) in hb.enumerated() {
                for (dx, ch) in row.enumerated() {
                    if let i = Int(String(ch)) { p.put(X(16 + dx), 32 + dy, B[side < 0 ? i : max(0, i - 1)]) }
                    else { p.put(X(16 + dx), 32 + dy, L[1]) }
                }
            }
            p.put(X(17), 31, L[2]); p.put(X(17), 36, L[1])
        }
        // Remaches de latón.
        for (x, y) in [(18, 36), (18, 44), (17, 51), (59, 36), (59, 44), (60, 51), (24, 56), (53, 56)] {
            rivet(&p, x, y, B)
        }
        // Quemaduras y chamuscados.
        for (x, y) in [(22, 59), (23, 59), (22, 60), (21, 61), (55, 58), (56, 58), (56, 59), (33, 63), (34, 62), (45, 61)] {
            p.put(x, y, L[0])
        }
        for (x, y) in [(23, 58), (24, 59), (22, 58), (57, 59), (55, 57), (35, 62), (46, 60)] { p.put(x, y, 0x9C5A2C) }
        for (x, y) in [(21, 60), (57, 58), (33, 62)] { p.put(x, y, 0x3A1A10) }
    }

    static func rivet(_ p: inout Painter, _ x: Int, _ y: Int, _ ramp: [UInt32]) {
        p.put(x, y, ramp[3]); p.put(x + 1, y, ramp[2])
        p.put(x, y + 1, ramp[2]); p.put(x + 1, y + 1, ramp[0])
        p.put(x, y, ramp[4])
    }

    // MARK: Brazos

    /// Manga remangada (parte superior del brazo). `side` -1 = izquierda de la pantalla, 1 = derecha.
    static func drawUpperArm(_ p: inout Painter, side: Int) {
        let T = Ramp.tunic
        let X: (Double) -> Double = { side < 0 ? $0 : mirror($0) }
        p.capsule(X(11), 40, X(10.5), 43, 8.5, 8, T, bias: side < 0 ? 0 : -0.08, maxY: 47)
        // Remangado: rollo de tela más claro con pliegues.
        for y in 43...47 {
            for xi in 1...21 {
                let x = side < 0 ? xi : mirror(xi)
                guard p[x, y] != nil else { continue }
                let nx = (Double(xi) - 10.5) / 10
                let c: UInt32
                switch y {
                case 43: c = T[0]
                case 44: c = T[Painter.tone(nx * Double(side) * -1, -0.6, T.count, bias: 0.25)]
                case 45, 46: c = T[Painter.tone(nx * Double(side) * -1, 0.1, T.count, bias: 0.2)]
                default: c = T[0]
                }
                p.put(x, y, c)
            }
        }
        for xi in [5, 11, 16] { p.put(side < 0 ? xi : mirror(xi), 45, T[1]) }
    }

    /// Antebrazo desnudo y velludo, de (ex, ey) a la muñeca (wx, wy), con el puño del guante de cuero.
    static func drawForearm(_ p: inout Painter, ex: Double, ey: Double, wx: Double, wy: Double, bias: Double,
                            ra: Double = 7.6, rb: Double = 5.6) {
        let S = Ramp.skin, G = Ramp.glove, B = Ramp.brass
        p.capsule(ex, ey, wx, wy, ra, rb, S, bias: bias)
        // Vello: trazos cortos en diagonal sobre la parte iluminada y media.
        let vx = wx - ex, vy = wy - ey
        let len = (vx * vx + vy * vy).squareRoot()
        let px = -vy / len, py = vx / len
        for i in 0..<5 {
            let t = 0.12 + Double(i) * 0.14
            for j in [-3.5, -0.5, 2.5] where (i + Int(j + 4)) % 2 == 0 {
                let x = Int((ex + vx * t + px * j).rounded(.down)), y = Int((ey + vy * t + py * j).rounded(.down))
                p.shift(x, y, S, -1); p.shift(x + 1, y - 1, S, -1)
            }
        }
        // Puño del guante (manopla de herrero acampanada) con remaches.
        let ax = ex + vx * 0.74, ay = ey + vy * 0.74
        p.capsule(ax, ay, wx + vx * 0.1, wy + vy * 0.1, rb + 2, rb + 1.4, G, bias: bias + 0.05, roundEnds: false)
        for k in -6...6 {
            let x = Int((ax + px * Double(k)).rounded(.down)), y = Int((ay + py * Double(k)).rounded(.down))
            if p[x, y] != nil { p.put(x, y, G[1]) }
            if p[x, y + 1] != nil && k % 2 == 0 { p.put(x, y + 1, G[4]) }
        }
        rivet(&p, Int(wx) - 4, Int(wy) - 1, B)
        rivet(&p, Int(wx) + 2, Int(wy) - 1, B)
    }

    /// Puño enguantado de frente (nudillos hacia el jugador). `thumbRight` = el pulgar va hacia la derecha.
    static func drawFist(_ p: inout Painter, cx: Double, cy: Double, thumbRight: Bool, bias: Double) {
        let G = Ramp.glove
        // Puño de la manopla (más ancho que la muñeca).
        p.ball(cx, cy - 3.5, 7.5, 3.8, G, bias: bias - 0.05)
        p.ball(cx, cy, 8.5, 5.5, G, bias: bias)
        // Dedos doblados.
        for i in 0..<4 {
            let fx = cx - 5.4 + Double(i) * 3.6
            p.ball(fx, cy + 2.2, 2.1, 2.8, G, bias: bias + 0.1)
        }
        for i in 1..<4 {
            let x = Int((cx - 5.4 + Double(i) * 3.6 - 1.8).rounded(.down))
            for y in Int(cy + 0.5)...Int(cy + 5) { p.put(x, y, G[0]) }
        }
        // Pulgar por encima de los dedos.
        let tx = thumbRight ? cx + 3.5 : cx - 3.5
        p.ball(tx, cy - 0.5, 4.2, 2.3, G, bias: bias + 0.15)
        let tipX = Int(thumbRight ? cx - 0.5 : cx - 0.5)
        p.put(tipX, Int(cy + 1), G[0])
        // Costura del guante.
        for x in stride(from: Int(cx - 6), through: Int(cx + 6), by: 2) { p.put(x, Int(cy - 4), G[1]) }
    }

    // MARK: Martillo

    /// Martillo de forja: cabeza de hierro horizontal (boca a `faceRight`) con mango vertical hasta `gripY`.
    static func drawHammer(_ p: inout Painter, cx: Int, headY: Int, gripY: Int, faceRight: Bool) {
        let I = Ramp.iron, W = Ramp.wood, L = Ramp.leather
        // Mango (3 px) con vetas y empuñadura de cuero.
        for y in min(headY + 8, gripY)...max(headY + 8, gripY) {
            p.put(cx - 1, y, W[3]); p.put(cx, y, W[2]); p.put(cx + 1, y, W[1])
            if (y + cx) % 5 == 0 { p.put(cx, y, W[1]) }
            if y > gripY - 9 {
                let band = (y - gripY) % 3 == 0
                p.put(cx - 1, y, band ? L[2] : L[4]); p.put(cx, y, band ? L[1] : L[3]); p.put(cx + 1, y, L[1])
            }
        }
        // Cabeza: boca grande, cuello, cuerpo y peña afilada.
        let head: [(Int, Int, Int)] = [   // (columna desde la boca, fila inicial, fila final)
            (0, 1, 9), (1, 0, 10), (2, 0, 10), (3, 0, 10), (4, 0, 10), (5, 0, 10), (6, 1, 9),
            (7, 1, 9), (8, 1, 9), (9, 1, 9), (10, 1, 9), (11, 1, 9), (12, 1, 9), (13, 1, 9),
            (14, 2, 8), (15, 2, 8), (16, 3, 7), (17, 3, 7), (18, 4, 6), (19, 4, 6), (20, 5, 5),
        ]
        let x0 = faceRight ? cx + 10 : cx - 10
        for (col, a, b) in head {
            let x = faceRight ? x0 - col : x0 + col
            for r in a...b {
                let v = Double(r - a) / Double(max(1, b - a))   // 0 arriba … 1 abajo
                var i = v < 0.2 ? 4 : (v < 0.5 ? 3 : (v < 0.8 ? 2 : 1))
                if col == 0 || (col == 6 && r > 1) { i = max(1, i - 1) }   // cantos
                if col == 5 { i = min(5, i + 1) }
                if col >= 14 && v > 0.45 { i = max(1, i - 1) }
                p.put(x, headY + r, I[i])
            }
        }
        // Brillos y aro del ojo del mango.
        p.put(faceRight ? x0 - 1 : x0 + 1, headY, I[5]); p.put(faceRight ? x0 - 2 : x0 + 2, headY, I[5])
        p.put(faceRight ? x0 - 8 : x0 + 8, headY + 1, I[5]); p.put(faceRight ? x0 - 9 : x0 + 9, headY + 1, I[4])
        for r in 1...9 { p.put(cx - 2, headY + r, I[1]); p.put(cx + 2, headY + r, I[1]) }
        // Marcas de uso en la boca del martillo.
        p.put(faceRight ? x0 - 2 : x0 + 2, headY + 6, I[2]); p.put(faceRight ? x0 - 3 : x0 + 3, headY + 3, I[5])
        p.put(cx, headY + 2, W[2]); p.put(cx - 1, headY + 2, W[4]); p.put(cx + 1, headY + 2, W[1])
        p.put(cx, headY + 3, I[0])   // cuña
    }

    /// Estrella de chispas del golpe, centrada en (x, y), con resplandor alrededor.
    static func drawSpark(_ p: inout Painter, x: Int, y: Int) {
        for yy in (y - 9)...(y + 3) {
            for xx in (x - 12)...(x + 6) {
                let d = Double((xx - x) * (xx - x) + (yy - y) * (yy - y) * 2).squareRoot()
                if d < 9 { p.tint(xx, yy, 0xFFB050, 0.45 * (1 - d / 9)) }
            }
        }
        let rows = [
            "........o........",
            "...o....y....o...",
            "....y...y...y....",
            ".....y.yWy.y.....",
            "......yWWWy......",
            "ooyyyyWWWWWyyyyoo",
            "......yWWWy......",
            ".....y.yWy.y.....",
            "....o...y...o....",
        ]
        p.stamp(rows, ["W": 0xFFFFFF, "y": 0xFFE27A, "o": ember], x - 8, y - 5)
        for (dx, dy) in [(-11, -8), (-14, -3), (10, -9), (13, -5), (-7, -11), (5, -12), (-3, -13)] {
            p.put(x + dx, y + dy, dx % 2 == 0 ? 0xFFE27A : ember)
        }
    }
}
