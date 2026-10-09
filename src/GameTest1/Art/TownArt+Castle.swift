import Foundation
import GameCore

/// El castillo de Valdehierro: torres cilíndricas con tejados cónicos de escamas turquesa, torre del
/// reloj, cuerpo central con tejado a cuatro aguas, muralla almenada con matacanes, estandartes,
/// antorchas y la puerta monumental (cerrada con rastrillo o abierta).
extension TownArt {
    static let castleStone: [UInt32] = [0x6E6878, 0x8C8698, 0xA6A0B2, 0xBEB8C8, 0xD6D0DE]
    static let castleRoof: [UInt32] = [0x14505E, 0x1C6C7A, 0x268A98, 0x38AAB6, 0x5CCAD0, 0x9AE6E6]
    static let gold: [UInt32] = [0x7A5418, 0xB0802A, 0xE0B040, 0xFFE07A]

    static func castle(_ b: Building, open: Bool) -> PixelGrid {
        let T = tile
        let W = b.width * T, H = b.height * T
        let M = 24
        var g = PixelGrid(width: W, height: H + M)
        let base = H + M
        let cx = (b.doorX - b.x) * T + b.doorWidth * T / 2
        let wallTop = base - 70

        // 1. Cuerpo central (detrás) con su tejado
        castleBlock(&g, 64, base - 124, W - 128, 62, seed: 3)
        for wx in stride(from: 82, to: W - 90, by: 30) where abs(wx + 5 - cx) > 50 {
            archWindow(&g, wx, base - 112, w: 10, h: 18, lit: true)
        }
        paintRoof(&g, x0: 58, x1: W - 58, top: base - 170, bottom: base - 120, hip: 30, kind: .slate, tones: Array(castleRoof[0...4]), seed: 21)
        for dx in [116, W - 132] { castleDormer(&g, dx, base - 154) }

        // 2. Torre del reloj
        let ct = base - 176
        castleBlock(&g, cx - 30, ct, 60, 110, seed: 5)
        vline(&g, cx - 30, ct, 110, castleStone[4])
        tintRect(&g, cx + 22, ct, 8, 110, (0.82, 0.82, 0.9))
        corbels(&g, cx - 32, cx + 32, ct + 2)
        clock(&g, cx, ct + 28)
        archWindow(&g, cx - 6, ct + 54, w: 12, h: 16, lit: true)
        // Tejado piramidal de la torre del reloj
        cone(&g, cx, ct - 4, rx: 36, ry: 6, height: 26, square: true)
        finial(&g, cx, ct - 30)

        // 3. Muralla delantera con matacanes y almenas
        castleBlock(&g, 40, wallTop, W - 80, 70, seed: 7)
        corbels(&g, 40, W - 40, wallTop - 2)
        battlements(&g, 40, W - 40, wallTop - 12)
        // Hiedra y musgo al pie
        ivy(&g, 70, wallTop + 20, 46, seed: 1)
        ivy(&g, W - 120, wallTop + 26, 40, seed: 2)
        for x in 40..<(W - 40) where noise(Double(x) / 4, 1, 9) > 0.55 {
            for y in (base - 6)..<(base - 2) where hash(x, y, 8) % 2 == 0 { g[x, y] = mix(g[x, y] ?? moss, moss, 0.6) }
        }
        // Ventanas saeteras en la muralla
        for wx in [92, 150, W - 160, W - 102] { slit(&g, wx, wallTop + 18) }

        // 4. Torres de la puerta
        for side in [-1, 1] {
            let tx = cx + side * 52
            cylinder(&g, tx, r: 20, top: base - 104, bottom: base - 4, seed: 11 + side)
            ringBattlements(&g, tx, r: 22, y: base - 112)
            slit(&g, tx - 2, base - 84)
            // Estandarte colgado
            banner(&g, tx - 7, base - 96)
        }

        // 5. Torres de las esquinas
        for (tx, s) in [(34, 1), (W - 34, 2)] {
            cylinder(&g, tx, r: 32, top: base - 136, bottom: base - 2, seed: 30 + s)
            ringBattlements(&g, tx, r: 35, y: base - 146)
            cone(&g, tx, base - 148, rx: 38, ry: 9, height: 52, square: false)
            finial(&g, tx, base - 200)
            archWindow(&g, tx - 5, base - 118, w: 10, h: 16, lit: s == 1)
            archWindow(&g, tx - 5, base - 80, w: 10, h: 16, lit: s == 2)
            slit(&g, tx - 16, base - 54); slit(&g, tx + 12, base - 54)
        }

        // 6. Puerta monumental
        gate(&g, cx, base, open: open)
        for side in [-1, 1] { torch(&g, cx + side * 34, base - 46) }
        return g.outlined()
    }

    // MARK: Piezas

    /// Bloque de sillares con luz arriba-izquierda (más claro arriba, más oscuro abajo).
    private static func castleBlock(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, seed: Int) {
        for yy in y..<(y + h) {
            for xx in x..<(x + w) {
                let row = (yy - y) / 7, ly = (yy - y) % 7
                let rw = 12 + hash(row, 0, seed) % 5
                let off = (row * 7 + hash(row, 1, seed)) % rw
                let lx = (xx + off) % rw
                let st = hash((xx + off) / rw, row, seed + 1)
                var l = 0.62 + Double(st % 5) * 0.04 - Double(yy - y) / Double(h) * 0.18
                if ly == 6 || lx == 0 { l = 0.12 } else if ly == 0 { l += 0.14 } else if lx == rw - 1 || ly == 5 { l -= 0.14 }
                if st % 11 == 0 && ly == 3 && lx == 4 { l -= 0.2 }                     // grieta
                l += (bayer(xx, yy) - 0.5) * 0.1
                var c = castleStone[max(0, min(4, Int(l * 5)))]
                if noise(Double(xx) / 7, Double(yy) / 6, seed + 3) > 0.76 { c = mix(c, 0x6E7A5A, 0.25) }   // humedad
                g[xx, yy] = c
            }
        }
    }

    /// Torre cilíndrica: sillares que se estrechan hacia los bordes y sombreado redondo.
    private static func cylinder(_ g: inout PixelGrid, _ cx: Int, r: Int, top: Int, bottom: Int, seed: Int) {
        let ry = max(3, r / 4)
        for x in -r...r {
            let u = Double(x) / Double(r)
            let s = (1 - u * u).squareRoot()
            let yb = bottom - ry + Int(Double(ry) * s)
            let yt = top + Int(Double(ry) * s)
            let ang = asin(max(-1, min(1, u)))
            for y in (top - ry)...yb where y >= yt - 1 {
                let row = (y - yt) / 7, ly = ((y - yt) % 7 + 7) % 7
                let a = (ang + Double.pi / 2) / Double.pi * Double(r) / 3.2 + (row % 2 == 0 ? 0 : 0.5)
                let col = Int(a), fa = a - floor(a)
                let st = hash(col, row, seed)
                var l = 0.66 - u * 0.36 - (1 - s) * 0.3 + Double(st % 4) * 0.04
                if ly == 6 || fa < 0.12 / max(0.25, s) { l -= 0.4 } else if ly == 0 { l += 0.1 }
                l += (bayer(cx + x, y) - 0.5) * 0.12
                g[cx + x, y] = castleStone[max(0, min(4, Int(l * 5)))]
            }
        }
    }

    /// Almenas en anillo sobre una torre cilíndrica (con su sombra y el suelo del adarve).
    private static func ringBattlements(_ g: inout PixelGrid, _ cx: Int, r: Int, y: Int) {
        let ry = max(3, r / 4)
        corbels(&g, cx - r, cx + r + 1, y + 10)
        for x in -r...r {
            let u = Double(x) / Double(r)
            let s = (1 - u * u).squareRoot()
            let front = y + 4 + Int(Double(ry) * s)
            let back = y + 4 - Int(Double(ry) * s)
            // Suelo del adarve (visto desde arriba) y parapeto de atrás
            for yy in back...front { g[cx + x, yy] = castleStone[1] }
            g[cx + x, back] = castleStone[3]; g[cx + x, back - 1] = castleStone[2]
            // Parapeto delantero con almenas
            let merlon = (Int((asin(max(-1, min(1, u))) + Double.pi / 2) * Double(r) / 4.5)) % 2 == 0
            let h = merlon ? 9 : 4
            for yy in (front - h + 4)...(front + 6) {
                var l = 0.66 - u * 0.36 - (1 - s) * 0.3
                if yy == front - h + 4 { l += 0.25 }
                if yy > front + 4 { l -= 0.15 }
                g[cx + x, yy] = castleStone[max(0, min(4, Int(l * 5)))]
            }
        }
    }

    /// Fila de matacanes (ménsulas) bajo un adarve.
    private static func corbels(_ g: inout PixelGrid, _ x0: Int, _ x1: Int, _ y: Int) {
        for x in x0..<x1 {
            let k = (x - x0) % 6
            g[x, y] = castleStone[3]
            g[x, y + 1] = k < 4 ? castleStone[2] : castleStone[0]
            g[x, y + 2] = k < 4 ? (k == 0 ? castleStone[3] : castleStone[1]) : 0x3A3644
            g[x, y + 3] = k == 1 || k == 2 ? castleStone[1] : 0x3A3644
        }
    }

    /// Almenas rectas: merlones de 7 con huecos de 5 y la cara superior iluminada.
    private static func battlements(_ g: inout PixelGrid, _ x0: Int, _ x1: Int, _ y: Int) {
        fill(&g, x0, y + 5, x1 - x0, 6, castleStone[2])
        hline(&g, x0, y + 5, x1 - x0, castleStone[3])
        for x in x0..<x1 {
            let k = (x - x0) % 12
            guard k < 7 else { continue }
            for yy in y..<(y + 6) {
                var c = castleStone[2]
                if yy < y + 2 { c = castleStone[4] } else if k == 0 { c = castleStone[3] } else if k == 6 { c = castleStone[0] }
                g[x, yy] = c
            }
        }
    }

    /// Tejado cónico (o piramidal) de escamas turquesa con alero y luz en el lado izquierdo.
    private static func cone(_ g: inout PixelGrid, _ cx: Int, _ baseY: Int, rx: Int, ry: Int, height: Int, square: Bool) {
        let n = Double(castleRoof.count)
        for i in 0...height {
            let t = Double(i) / Double(height)                       // 0 en el vértice, 1 en la base
            let hw = Double(rx) * (square ? t : pow(t, 0.85))
            guard hw >= 0.5 else { g[cx, baseY - height] = castleRoof[4]; continue }
            let y0 = baseY - height + i
            for x in Int(-hw)...Int(hw) {
                let u = Double(x) / max(1, hw)
                let s = (1 - u * u).squareRoot()
                let curve = square ? 0 : Int(Double(ry) * t * s)
                let y = y0 + curve
                let row = (i + (square ? 0 : Int(Double(ry) * t * s))) / 4
                let ly = (i) % 4
                let a = square ? Double(x + rx) / 4 : (asin(max(-1, min(1, u))) + Double.pi / 2) / Double.pi * Double(max(3, Int(hw))) / 2.2
                let fa = a + (row % 2 == 0 ? 0 : 0.5)
                var l = 0.7 - u * 0.42 - t * 0.08
                if square && x > 0 { l -= 0.12 }
                if ly == 3 { l -= 0.22 } else if ly == 0 { l += 0.06 }
                if fa - floor(fa) < 0.18 { l -= 0.14 }
                l += (bayer(cx + x, y) - 0.5) * 0.14
                g[cx + x, y] = castleRoof[max(0, min(castleRoof.count - 1, Int(l * n)))]
                if !square && i == height { for k in 1...3 { g[cx + x, y + k] = k == 3 ? castleRoof[0] : castleRoof[1] } }
            }
            if square && i == height {
                hline(&g, cx - rx, y0 + 1, rx * 2 + 1, castleRoof[1]); hline(&g, cx - rx, y0 + 2, rx * 2 + 1, castleRoof[0])
            }
        }
        // Arista central del tejado piramidal
        if square { line(&g, cx, baseY - height, cx, baseY, castleRoof[5]) }
    }

    private static func finial(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        vline(&g, x, y - 8, 10, gold[1]); g[x - 1, y - 2] = gold[2]
        ball(&g, x, y - 2, 2, 2, gold)
        // Banderola
        fill(&g, x + 1, y - 8, 7, 3, 0x2E5AA8); g[x + 8, y - 7] = 0x2E5AA8; hline(&g, x + 1, y - 8, 7, 0x5A86D0)
        g[x, y - 9] = gold[3]
    }

    private static func castleDormer(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        fill(&g, x, y + 6, 16, 16, castleStone[3])
        vline(&g, x, y + 6, 16, castleStone[4]); vline(&g, x + 15, y + 6, 16, castleStone[1])
        archWindow(&g, x + 4, y + 9, w: 8, h: 11, lit: true)
        for i in 0..<9 {
            for xx in (x + 7 - i)...(x + 8 + i) { g[xx, y + i - 2] = castleRoof[xx <= x + 7 ? 4 : 1] }
            g[x + 7 - i, y + i - 2] = castleRoof[5]
        }
        tintRect(&g, x + 16, y + 8, 4, 14, (0.62, 0.62, 0.74))
    }

    /// Ventana con arco de medio punto, dovelas y vidrio (encendido o con reflejo).
    private static func archWindow(_ g: inout PixelGrid, _ x: Int, _ y: Int, w: Int, h: Int, lit: Bool) {
        let r = Double(w) / 2
        for yy in -2..<(h + 2) {
            for xx in -2..<(w + 2) {
                let dx = Double(xx) - r + 0.5, dy = Double(yy) - r
                let inFrame = yy >= Int(r) || dx * dx + dy * dy <= (r + 2) * (r + 2)
                guard inFrame else { continue }
                let inGlass = xx >= 0 && xx < w && yy < h && (yy >= Int(r) || dx * dx + dy * dy <= r * r)
                if inGlass {
                    let t = Double(xx + yy) / Double(w + h)
                    var c = lit ? tone([0xFFF2C0, 0xFFD070, 0xE8962E, 0xB0601E], t * 1.2, x + xx, y + yy)
                                : tone([0x8AC0E6, 0x4A7AAA, 0x2E4E78, 0x1E3456], t * 1.3, x + xx, y + yy)
                    if xx == w / 2 || yy == h / 2 + 2 { c = 0x3A3644 }
                    g[x + xx, y + yy] = c
                } else {
                    g[x + xx, y + yy] = xx < w / 2 ? castleStone[4] : castleStone[1]
                }
            }
        }
        hline(&g, x - 2, y + h + 2, w + 4, castleStone[4])
    }

    private static func slit(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        fill(&g, x - 1, y - 1, 5, 14, castleStone[3])
        fill(&g, x, y, 3, 12, 0x24202C)
        vline(&g, x + 1, y + 2, 8, 0x3A3644)
        hline(&g, x - 1, y + 13, 5, castleStone[4])
    }

    /// Reloj de la torre: aro dorado, esfera clara, marcas de las horas y agujas.
    private static func clock(_ g: inout PixelGrid, _ cx: Int, _ cy: Int) {
        ellipse(&g, cx, cy, 19, 19, castleStone[0])
        for y in -18...18 {
            for x in -18...18 {
                let d = Double(x * x + y * y).squareRoot()
                guard d <= 18 else { continue }
                if d > 14.5 {
                    let l = 0.6 - Double(x + y) / 36 * 0.6 + (d > 17 ? -0.2 : 0.1)
                    g[cx + x, cy + y] = tone(gold, l, cx + x, cy + y)
                } else {
                    let l = 0.75 - Double(x + y) / 30 * 0.25
                    g[cx + x, cy + y] = tone([0xB8AC8E, 0xD8CCAE, 0xF0E6CC, 0xFFF8E6], l, cx + x, cy + y)
                }
            }
        }
        for h in 0..<12 {
            let a = Double(h) / 12 * 2 * Double.pi
            let px = cx + Int((sin(a) * 12).rounded()), py = cy - Int((cos(a) * 12).rounded())
            g[px, py] = 0x3A2A1A
            if h % 3 == 0 { g[px + (h == 3 ? -1 : (h == 9 ? 1 : 0)), py + (h == 0 ? 1 : (h == 6 ? -1 : 0))] = 0x3A2A1A }
        }
        line(&g, cx, cy, cx, cy - 10, 0x2A1E14)                // minutero
        line(&g, cx, cy, cx + 6, cy + 3, 0x2A1E14)             // horario
        g[cx, cy] = gold[2]
        hline(&g, cx - 18, cy + 20, 37, castleStone[4])
    }

    /// Puerta monumental: arco de dovelas, puerta de madera con herrajes o rastrillo alzado y escalones.
    private static func gate(_ g: inout PixelGrid, _ cx: Int, _ base: Int, open: Bool) {
        let w = 44, h = 54
        let r = Double(w) / 2
        let top = base - 8 - h
        // Dovelas del arco y jambas
        for yy in (top - 8)..<(base - 6) {
            for xx in (cx - w / 2 - 8)..<(cx + w / 2 + 8) {
                let dx = Double(xx - cx) + 0.5, dy = Double(yy - (top + Int(r)))
                let d = (dx * dx + dy * dy).squareRoot()
                let inOuter = yy >= top + Int(r) ? abs(dx) <= r + 8 : d <= r + 8
                guard inOuter else { continue }
                let seg: Int
                if yy >= top + Int(r) { seg = (yy - top) / 7 + (dx < 0 ? 0 : 1) } else { seg = Int((atan2(dy, dx) + Double.pi) / Double.pi * 11) }
                var c = castleStone[seg % 2 == 0 ? 3 : 2]
                if dx < 0 { c = light(c, 1.04) } else { c = dark(c, 0.9) }
                if yy >= top + Int(r) && (yy - top) % 7 == 0 { c = castleStone[0] }
                if yy < top + Int(r) && Int((atan2(dy, dx) + Double.pi) / Double.pi * 11 * 10) % 10 == 0 { c = castleStone[0] }
                g[xx, yy] = c
            }
        }
        // Clave del arco con escudo
        fill(&g, cx - 4, top - 9, 9, 10, castleStone[4]); vline(&g, cx + 4, top - 9, 10, castleStone[1])
        fill(&g, cx - 2, top - 7, 5, 5, 0x2E5AA8); g[cx, top - 5] = gold[2]; g[cx - 1, top - 2] = 0x2E5AA8; g[cx + 1, top - 2] = 0x2E5AA8; g[cx, top - 1] = 0x2E5AA8
        // Hueco
        for yy in top..<(base - 6) {
            for xx in (cx - w / 2)..<(cx + w / 2) {
                let dx = Double(xx - cx) + 0.5, dy = Double(yy - (top + Int(r)))
                guard yy >= top + Int(r) || dx * dx + dy * dy <= r * r else { continue }
                let lx = xx - (cx - w / 2)
                if open {
                    // Pasillo en penumbra con alfombra roja al fondo
                    var c: UInt32 = tone([0x120E16, 0x1E1824, 0x2C2434], Double(yy - top) / Double(h), xx, yy)
                    if yy > base - 26 && abs(xx - cx) < 8 + (yy - (base - 26)) / 2 { c = yy > base - 12 ? 0x8A1E2A : 0x5A141E }
                    g[xx, yy] = c
                } else {
                    let plank = lx % 5
                    var c: UInt32 = [0x5A3420, 0x6E4228, 0x7E4E30, 0x4A2A18, 0x6A3E26][hash(lx / 5, 0, 61) % 5]
                    if plank == 0 { c = 0x2E1A10 } else if plank == 1 { c = light(c, 1.12) }
                    g[xx, yy] = c
                }
            }
        }
        if open {
            // Rastrillo alzado: puntas asomando bajo el arco
            for xx in stride(from: cx - w / 2 + 2, to: cx + w / 2 - 1, by: 4) {
                for yy in (top + Int(r) - 6)...(top + Int(r)) where g[xx, yy] != nil { g[xx, yy] = 0x3A3A46 }
                g[xx, top + Int(r) + 1] = 0x5A5A68
            }
            hline(&g, cx - w / 2, top + Int(r) - 2, w, 0x3A3A46)
        } else {
            vline(&g, cx - 1, top, h, 0x1E120A); vline(&g, cx, top + 1, h - 1, 0x3E2414)
            for hy in [top + 18, top + 34, base - 16] {
                hline(&g, cx - w / 2, hy, w, 0x2C2C36); hline(&g, cx - w / 2, hy + 1, w, 0x4A4A58)
                for xx in stride(from: cx - w / 2 + 2, to: cx + w / 2, by: 4) { g[xx, hy] = 0x9A9AAA }
            }
            for side in [-1, 1] {
                ellipse(&g, cx + side * 5, top + 27, 2, 2, gold[1])
                g[cx + side * 5, top + 25] = gold[3]
            }
        }
        // Escalinata delante de la puerta
        for i in 0..<3 {
            let yy = base - 6 + i * 2
            let half = w / 2 + 6 + i * 4
            fill(&g, cx - half, yy, half * 2, 2, castleStone[3 - i % 2])
            hline(&g, cx - half, yy, half * 2, castleStone[4])
        }
    }

    private static func banner(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        hline(&g, x - 2, y - 1, 18, gold[1]); g[x - 3, y - 1] = gold[2]; g[x + 16, y - 1] = gold[2]
        for yy in 0..<34 {
            for xx in 0..<14 {
                if yy > 28 && abs(xx - 7) < (yy - 28) + 1 && yy > 29 { continue }   // punta en V
                var c: UInt32 = 0x2A56A4
                if xx < 2 { c = 0x4A7ACA } else if xx > 11 { c = 0x1C3C7A }
                if yy % 9 == 8 { c = dark(c, 0.86) }                                 // pliegues
                if xx == 0 || xx == 13 { c = gold[1] }
                g[x + xx, y + yy] = c
            }
        }
        // Emblema: corona dorada sobre un yunque
        fill(&g, x + 4, y + 10, 6, 3, gold[2]); g[x + 4, y + 9] = gold[2]; g[x + 7, y + 8] = gold[3]; g[x + 9, y + 9] = gold[2]
        hline(&g, x + 4, y + 10, 6, gold[3])
        fill(&g, x + 3, y + 15, 8, 2, 0xD8D8E0); fill(&g, x + 5, y + 17, 4, 2, 0xA8A8B4); fill(&g, x + 4, y + 19, 6, 1, 0xA8A8B4)
    }

    private static func torch(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        fill(&g, x - 1, y + 4, 3, 6, 0x2C2C36); hline(&g, x - 2, y + 4, 5, 0x4A4A58)
        fill(&g, x - 1, y + 1, 3, 3, 0x6A4026)
        ellipse(&g, x, y - 2, 2, 3, 0xF07A20)
        ellipse(&g, x, y - 1, 1, 2, 0xFFD050)
        g[x, y - 1] = 0xFFF6C8; g[x, y - 6] = 0xF07A20
        // Halo cálido pintado en la piedra
        for yy in -10...8 { for xx in -9...9 where xx * xx + yy * yy < 80 && xx * xx + yy * yy > 12 { tint(&g, x + xx, y + yy, (1.12, 1.04, 0.9)) } }
    }

    /// Hiedra que trepa por el muro: hojas de dos verdes sobre tallos.
    private static func ivy(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ h: Int, seed: Int) {
        for i in 0..<h {
            let wob = Int(sin(Double(i) / 5 + Double(seed)) * 3)
            let px = x + wob
            g[px, y + i] = 0x2E4A22
            if hash(i, seed, 1) % 2 == 0 {
                let side = hash(i, seed, 2) % 2 == 0 ? -1 : 1
                g[px + side, y + i] = 0x3E7A34; g[px + side * 2, y + i] = 0x5A9A44; g[px + side * 2, y + i - 1] = 0x7ABA54
            }
        }
    }
}
