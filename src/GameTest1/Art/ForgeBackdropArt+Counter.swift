import Foundation

// El mostrador (delante del enano) y la capa animada: lenguas de fuego, chispas y vapor.

extension ForgeBackdropArt {
    // MARK: - Mostrador

    static func drawCounter(width cw: Int) -> PixelGrid {
        let H = counterHeight
        var o = ForgeLayer(cw, H)
        let w = ForgePal.wood, ir = ForgePal.iron
        let fire = ForgePal.fire
        let topEnd = 8  // filas de la tabla de arriba (1…7)
        // Tabla de arriba: tres tablones a lo largo, con vetas; la luz de la fragua entra por detrás.
        let seams = [3, 6]
        var butts: [Int: [Int]] = [:]
        for (k, _) in [1, 4, 7].enumerated() {
            var xs: [Int] = []
            var x = 10 + h(k, 0, 121) % 30
            while x < cw - 8 { xs.append(x); x += 34 + h(k, x, 122) % 26 }
            butts[k] = xs
        }
        for y in 1..<topEnd {
            let plank = y < 3 ? 0 : (y < 6 ? 1 : 2)
            for x in 0..<cw {
                var c: UInt32
                if seams.contains(y) {
                    c = w[1]
                } else if butts[plank]?.contains(x) == true {
                    c = w[1]
                } else {
                    let n = TownArt.noise(Double(x) / 9, Double(y) * 1.6 + Double(plank) * 7, 123)
                    let t = 2.6 + (n - 0.5) * 2.0 + (TownArt.bayer(x, y) - 0.5) * 0.6 - Double(y - 1) * 0.12
                    c = ramp(w, Int(t.rounded()))
                    if chance(x / 4, y, 124 + plank, 0.08) { c = w[2] }
                }
                o.put(x, y, c)
            }
        }
        // Borde trasero iluminado a contraluz por la fragua.
        for x in 0..<cw { o.put(x, 1, TownArt.mix(w[5], fire[4], 0.35)) }
        // Nudos y quemaduras en la tabla.
        for k in 0..<max(1, cw / 40) {
            let kx = 20 + h(k, 1, 125) % max(1, cw - 40), ky = 4 + h(k, 2, 126) % 2
            o.put(kx, ky, w[0]); o.put(kx + 1, ky, w[1]); o.put(kx - 1, ky, w[3]); o.put(kx + 2, ky, w[3])
        }
        burn(&o, Int(Double(cw) * 0.62), 4, 3, 2)
        burn(&o, Int(Double(cw) * 0.3), 5, 2, 1)
        // Canto redondeado.
        o.hline(0, topEnd, cw, w[5])
        o.hline(0, topEnd + 1, cw, w[3])
        o.hline(0, topEnd + 2, cw, w[1])
        o.hline(0, topEnd + 3, cw, ForgePal.outline)
        // Frente: tablas verticales en sombra (la luz está detrás del mostrador).
        let fy0 = topEnd + 4
        let dw: [UInt32] = [0x24140C, 0x40281A, 0x543422, 0x6A442C, 0x82583A]
        var x = 0
        var p = 0
        while x < cw {
            let pw = 8 + h(p, 0, 127) % 3
            let base = 2 + (h(p, 1, 128) % 3 == 0 ? -1 : 0)
            for yy in fy0..<H {
                for xx in x..<min(cw, x + pw) {
                    let lx = xx - x
                    var c: UInt32
                    if lx == pw - 1 { c = dw[0] } else if lx == 0 { c = ramp(dw, base + 1) } else {
                        let n = TownArt.noise(Double(xx) * 0.9, Double(yy) / 6, 129 + p)
                        c = ramp(dw, Int((Double(base) + (n - 0.5) * 1.8 + (TownArt.bayer(xx, yy) - 0.5) * 0.5).rounded()))
                    }
                    if yy == H - 1 { c = dw[0] }
                    o.put(xx, yy, c)
                }
            }
            // Nudo en algunas tablas.
            if p % 3 == 1 {
                let ky = fy0 + 5 + h(p, 3, 130) % 3
                o.put(x + pw / 2, ky, dw[0]); o.put(x + pw / 2, ky - 1, dw[3]); o.put(x + pw / 2 + 1, ky, dw[1])
            }
            p += 1
            x += pw
        }
        burn(&o, Int(Double(cw) * 0.45), fy0 + 4, 3, 3)
        // Fleje de hierro abajo, con un remache por tabla, y escuadras arriba.
        let sy = H - 7
        o.hline(0, sy, cw, ForgePal.outline)
        o.hline(0, sy + 1, cw, ir[3])
        o.hline(0, sy + 2, cw, ir[2])
        o.hline(0, sy + 3, cw, ForgePal.outline)
        var rx = 0
        var q = 0
        while rx < cw {
            let pw = 8 + h(q, 0, 127) % 3
            o.put(rx + pw / 2, sy + 1, ir[5]); o.put(rx + pw / 2, sy + 2, ir[0])
            o.put(rx + pw / 2, fy0 + 1, ir[4]); o.put(rx + pw / 2, fy0 + 2, dw[0])
            rx += pw
            q += 1
        }
        // Placa de latón con un yunque grabado en el centro del frente.
        if cw > 40 {
            let gd = ForgePal.gold
            let pcx = (cw - 7) / 2, py = fy0 + 1
            o.rect(pcx - 10, py, 21, 10, ForgePal.outline)
            o.rect(pcx - 9, py + 1, 19, 8, gd[2])
            o.hline(pcx - 9, py + 1, 19, gd[4]); o.vline(pcx - 9, py + 1, 8, gd[3])
            o.hline(pcx - 8, py + 8, 18, gd[1]); o.vline(pcx + 9, py + 2, 7, gd[1])
            o.put(pcx - 8, py + 2, gd[5]); o.put(pcx + 8, py + 2, gd[3]); o.put(pcx - 8, py + 7, gd[3]); o.put(pcx + 8, py + 7, gd[1])
            // Yunque grabado (oscuro) con su brillo.
            let e: UInt32 = 0x3A2008
            o.hline(pcx - 3, py + 2, 8, e); o.hline(pcx - 6, py + 3, 11, e); o.put(pcx - 6, py + 3, gd[1])
            o.hline(pcx - 1, py + 4, 4, e); o.hline(pcx - 1, py + 5, 4, e)
            o.hline(pcx - 3, py + 6, 8, e)
            o.hline(pcx - 2, py + 2, 6, gd[1])
        }
        // Pata del extremo derecho con cantonera de hierro.
        let px = cw - 7
        for yy in 1..<H {
            for xx in px..<cw {
                let lx = xx - px
                var c: UInt32 = lx == 0 ? w[4] : (lx >= 5 ? w[1] : w[2 + (lx < 3 ? 1 : 0)])
                if yy < topEnd { c = lx == 0 ? w[5] : w[3] }
                o.put(xx, yy, c)
            }
        }
        o.rect(px, 1, 7, 4, ir[3]); o.hline(px, 1, 7, ir[5]); o.put(px + 1, 3, ir[6]); o.put(px + 5, 3, ir[1])
        o.vline(cw - 1, 0, H, ForgePal.outline)
        o.vline(px - 1, topEnd + 4, H - topEnd - 4, ForgePal.outline)
        o.hline(0, 0, cw, ForgePal.outline)
        // Cosas encima, cerca de los bordes (el centro queda libre para las manos del enano).
        counterItems(&o, cw)
        return o.grid
    }

    /// Quemadura en la madera: mancha negra irregular con borde chamuscado.
    static func burn(_ o: inout ForgeLayer, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int) {
        for y in (cy - ry - 1)...(cy + ry + 1) {
            for x in (cx - rx - 1)...(cx + rx + 1) {
                let dx = Double(x - cx) / Double(rx + 1), dy = Double(y - cy) / Double(ry + 1)
                let d = dx * dx + dy * dy + (TownArt.noise(Double(x), Double(y), 131) - 0.5) * 0.6
                if d < 0.35 { o.put(x, y, 0x1A0E0A) } else if d < 0.9 { o.shade(x, y, 0.6) }
            }
        }
    }

    static func counterItems(_ o: inout ForgeLayer, _ cw: Int) {
        let gd = ForgePal.gold, ir = ForgePal.iron, st = ForgePal.steel
        // Izquierda: dos lingotes de oro y uno de hierro encima.
        func ingot(_ x: Int, _ y: Int, _ r: [UInt32]) {
            o.hline(x, y - 1, 9, ForgePal.outline)
            o.put(x - 1, y, ForgePal.outline); o.hline(x, y, 9, r[4]); o.put(x, y, r[5]); o.put(x + 9, y, ForgePal.outline)
            o.put(x - 1, y + 1, ForgePal.outline); o.hline(x, y + 1, 9, r[3]); o.put(x + 9, y + 1, ForgePal.outline)
            o.put(x - 1, y + 2, ForgePal.outline); o.hline(x, y + 2, 9, r[2]); o.put(x + 9, y + 2, ForgePal.outline)
            o.hline(x, y + 3, 9, ForgePal.outline)
            o.hline(x + 1, y + 4, 9, ForgePal.wood[1])
        }
        ingot(3, 4, gd)
        ingot(2, 1, ir)
        // Gema suelta.
        o.put(15, 5, ForgePal.outline); o.put(16, 4, ForgePal.ruby[4]); o.put(16, 5, ForgePal.ruby[2]); o.put(17, 5, ForgePal.ruby[1])
        o.put(16, 3, ForgePal.outline); o.put(17, 4, ForgePal.outline); o.put(16, 6, ForgePal.outline)
        // Derecha: tenazas en diagonal y una hoja sin montar.
        let tx = cw - 30
        o.line(tx, 2, tx + 18, 6, ForgePal.outline)
        o.line(tx, 3, tx + 18, 7, ForgePal.outline)
        o.line(tx + 1, 2, tx + 18, 5, ir[5])
        o.line(tx + 1, 3, tx + 18, 6, ir[2])
        o.rect(tx - 1, 1, 3, 3, ir[3]); o.put(tx, 2, ForgePal.outline)
        // Hoja: de canto, con el filo brillante.
        let bx = cw - 24
        o.hline(bx - 1, 3, 15, ForgePal.outline)
        o.hline(bx, 4, 13, st[4]); o.put(bx + 3, 4, st[5])
        o.hline(bx, 5, 12, st[2])
        o.hline(bx - 1, 6, 14, ForgePal.outline)
        o.hline(bx + 13, 4, 2, ForgePal.outline); o.put(bx + 12, 5, ForgePal.outline)
        o.hline(bx - 4, 4, 4, ir[1]); o.hline(bx - 4, 5, 4, ir[0]); o.put(bx - 5, 4, ForgePal.outline); o.put(bx - 5, 5, ForgePal.outline)
        o.hline(bx - 3, 7, 15, ForgePal.wood[1])
    }

    // MARK: - Capa animada

    static func drawEmbers(_ g: ForgeGeo, frame: Int) -> PixelGrid {
        var o = ForgeLayer(g.w, g.h)
        let fire = ForgePal.fire
        let f = g.f, mh = g.mouthHalf
        let ay = Double(g.springY - g.crownY)
        func inMouth(_ x: Int, _ y: Int) -> Bool {
            let dx = Double(x - f) / (Double(mh) + 0.5)
            if abs(dx) > 1 || y >= g.ledgeY { return false }
            if y >= g.springY { return true }
            let dy = Double(g.springY - y) / (ay + 0.5)
            return dx * dx + dy * dy <= 1
        }
        // Lenguas de fuego que cambian en cada frame.
        let ft = Double(frame) * 1.9
        for x in (f - mh + 1)..<(f + mh) {
            let k = 1 - pow(Double(x - f) / Double(mh), 2)
            let n = TownArt.noise(Double(x) / 2.6 + ft, ft * 0.7, 141)
            let fh = (4 + 17 * n) * pow(max(0, k), 0.45)
            let base = g.ledgeY - 4 - Int((4 * k).rounded())
            for i in 0..<Int(fh) {
                let y = base - i
                guard inMouth(x, y) else { continue }
                let t = Double(i) / max(1, fh)
                // Bordes deshilachados: arriba se rompe con tramado.
                if t > 0.7 && TownArt.bayer(x + frame, y) < (t - 0.7) * 3 { continue }
                o.put(x, y, ramp(fire, 6 - Int((t * 4.2 + TownArt.bayer(x, y) * 0.6).rounded())))
            }
        }
        // Chispas: cada una sube en un ciclo de `emberFrames` frames con su propio desfase.
        let n = emberFrames
        for k in 0..<26 {
            let phase = (frame + k * 5) % n
            let t = Double(phase) / Double(n)
            let rise = 26 + Double(h(k, 0, 142) % 40)
            let x0 = Double(f - 24 + h(k, 1, 143) % 48)
            let drift = Double(h(k, 2, 144) % 9) - 4
            let y0 = Double(g.fireY - 4 - h(k, 3, 145) % 6)
            let x = Int((x0 + drift * t * 3 + sin(t * 6.3 + Double(k)) * 1.5).rounded())
            let y = Int((y0 - rise * t - 8 * t * t).rounded())
            let c: UInt32 = t < 0.2 ? fire[6] : (t < 0.4 ? fire[5] : (t < 0.6 ? fire[4] : (t < 0.8 ? fire[3] : fire[2])))
            o.put(x, y, c)
            if t < 0.5 { o.put(x, y + 1, fire[3]) }
            if k % 4 == 0 && t < 0.35 { o.put(x - 1, y, fire[4]); o.put(x + 1, y, fire[4]); o.put(x, y - 1, fire[5]) }
        }
        // Vapor de la tina: bocanadas tramadas que suben y se deshacen.
        let tubX = f + 93, tubY = g.floorY + 3
        let steam: [UInt32] = [0xD8D0CA, 0xB0A8A6, 0x8E8888]
        // Hilos de vapor ondulados: tramos que suben 3 pixeles por frame (el ciclo cierra en `emberFrames`).
        let period = 3 * n
        for wisp in 0..<3 {
            let bx = tubX + 7 + wisp * 7
            for k in 0..<22 {
                let y = tubY - 1 - k
                let ph = k + 3 * frame + wisp * 7
                guard (ph % period) < period * 3 / 5 else { continue }
                let x = bx + Int((1.6 * sin(Double(ph) * 2 * Double.pi / Double(period)) + Double(k) * 0.08).rounded())
                if k > 13 && (k + frame) % 2 == 0 { continue }
                let c = steam[min(2, k / 7)]
                o.put(x, y, c)
                if k < 9 { o.put(x + 1, y, steam[min(2, k / 7 + 1)]) }
            }
        }
        return o.grid
    }
}
