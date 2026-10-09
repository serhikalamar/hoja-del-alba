import Foundation

// La fragua (boca en arco con fuego y brasas, repisa, campana de humos y chimenea) y su rincón de
// trabajo en la pared (fuelle y herramientas colgadas).

extension ForgeBackdropArt {
    static func drawForge(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        chimney(&L, g)
        forgeBody(&L, g)
        hood(&L, g)
        forgeMouth(&L, g)
    }

    // MARK: - Chimenea y campana

    static func chimney(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let x0 = g.f - 17, x1 = g.f + 17
        let bottom = g.hoodTop + 2
        guard bottom > 0 else { return }
        // Sombra sobre la pared a la derecha.
        L.shadeRect(x1 + 1, 0, 4, bottom + 6, 0.62)
        let b = ForgePal.brick.map { VillageArt.scale($0, (0.78, 0.74, 0.74)) }
        for y in 0..<bottom {
            for x in x0...x1 {
                if x == x0 || x == x1 { L.put(x, y, ForgePal.outline); continue }
                L.put(x, y, brickPixel(x, y, g.f, b, seed: 5))
            }
            L.put(x0 + 1, y, TownArt.mix(L.at(x0 + 1, y) ?? b[3], b[5], 0.4))
            L.shade(x1 - 1, y, 0.75)
        }
        // Hollín en el centro y abrazaderas de hierro.
        for y in 0..<bottom {
            for x in (x0 + 1)..<x1 {
                let n = TownArt.noise(Double(x) / 5, Double(y) / 7, 81)
                if n > 0.45 + TownArt.bayer(x, y) * 0.25 { L.shade(x, y, 0.7) }
            }
        }
        var y = bottom - 14
        while y > 2 {
            L.hline(x0 - 1, y, x1 - x0 + 3, ForgePal.outline)
            L.hline(x0, y + 1, x1 - x0 + 1, ForgePal.iron[3])
            L.hline(x0, y + 2, x1 - x0 + 1, ForgePal.iron[1])
            L.hline(x0 - 1, y + 3, x1 - x0 + 3, ForgePal.outline)
            L.put(x0 + 3, y + 1, ForgePal.iron[5]); L.put(x1 - 3, y + 1, ForgePal.iron[5])
            y -= 34
        }
    }

    /// Ladrillo en hiladas a soga (7×3 + junta), simétrico respecto a `cx`.
    static func brickPixel(_ x: Int, _ y: Int, _ cx: Int, _ b: [UInt32], seed: Int) -> UInt32 {
        let row = Int(floor(Double(y) / 4))
        let ly = y - row * 4
        let off = row % 2 == 0 ? 0 : 4
        let ux = x - cx + 400 + off
        let col = ux / 8
        let lx = ux - col * 8
        if ly == 3 || lx == 7 { return b[0] }
        let s = h(col, row, 90 + seed)
        let base = 2 + (s % 4 == 0 ? 1 : 0) - (s % 5 == 0 ? 1 : 0)
        if ly == 0 { return ramp(b, base + 1) }
        if lx == 6 { return ramp(b, base - 1) }
        if chance(x, y, 91 + seed, 0.06) { return ramp(b, base - 1) }
        if chance(x, y, 92 + seed, 0.04) { return ramp(b, base + 2) }
        return ramp(b, base)
    }

    static func hood(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let top = g.hoodTop, bottom = g.bodyTop - 3
        let iron: [UInt32] = [0x1E1210, 0x3A2419, 0x583624, 0x784C30, 0x9C6840, 0xC48C58], cu = ForgePal.copper
        let span = Double(bottom - top)
        func half(_ y: Int) -> Int { 21 + Int(Double(y - top) / span * 39) }
        // Sombra de la campana sobre la pared (a la derecha y abajo).
        for y in top..<bottom {
            let hw = half(y)
            for x in (g.f + hw + 1)...(g.f + hw + 4) { L.shade(x, y + 2, 0.6) }
        }
        for y in top..<bottom {
            let hw = half(y)
            let ly = y - top
            for x in (g.f - hw)...(g.f + hw) {
                let dx = x - g.f
                var c: UInt32
                if x == g.f - hw || x == g.f + hw || ly == 0 {
                    c = ForgePal.outline
                } else if x <= g.f - hw + 2 {
                    c = iron[4]
                } else if x >= g.f + hw - 2 {
                    c = iron[1]
                } else {
                    // Planchas: más claras a la izquierda, oscuras a la derecha; hollín arriba.
                    let side = Double(-dx) / Double(hw)
                    let n = TownArt.noise(Double(x) / 4, Double(y) / 3, 82)
                    let t = 2.3 + side * 0.9 + (n - 0.5) * 0.9 - Double(bottom - y) / span * 0.6
                    c = ramp(iron, Int((t + (TownArt.bayer(x, y) - 0.5) * 0.7).rounded()))
                }
                L.put(x, y, c)
            }
            // Costuras horizontales con remaches.
            if ly > 0 && ly % 7 == 0 {
                for x in (g.f - hw + 1)..<(g.f + hw) {
                    L.put(x, y, iron[0])
                    L.put(x, y + 1, iron[4])
                    if (x - g.f + 300) % 6 == 0 { L.put(x, y - 1, iron[5]); L.put(x, y + 1, iron[1]) }
                }
            }
        }
        // Costuras verticales que siguen la inclinación.
        for frac in [-0.5, 0.5] {
            for y in (top + 1)..<bottom {
                let x = g.f + Int(Double(half(y)) * frac)
                L.put(x, y, iron[0])
                L.put(x - 1, y, iron[4])
            }
        }
        // Reborde de cobre enrollado abajo.
        let rw = half(bottom) + 3
        L.hline(g.f - rw, bottom, 2 * rw + 1, ForgePal.outline)
        L.hline(g.f - rw + 1, bottom + 1, 2 * rw - 1, cu[5])
        L.hline(g.f - rw + 1, bottom + 2, 2 * rw - 1, cu[3])
        L.hline(g.f - rw + 1, bottom + 3, 2 * rw - 1, cu[1])
        L.hline(g.f - rw, bottom + 4, 2 * rw + 1, ForgePal.outline)
        L.vline(g.f - rw, bottom, 5, ForgePal.outline)
        L.vline(g.f + rw, bottom, 5, ForgePal.outline)
        var x = g.f - rw + 4
        while x < g.f + rw - 2 { L.put(x, bottom + 2, cu[5]); L.put(x + 1, bottom + 2, cu[2]); x += 9 }
        emblem(&L, g.f, top + 10)
    }

    /// Emblema de latón en la campana: yunque con dos martillos cruzados.
    static func emblem(_ L: inout ForgeLayer, _ cx: Int, _ cy: Int) {
        var o = ForgeLayer(19, 13)
        let gd = ForgePal.gold
        // Martillos cruzados (mangos en diagonal).
        for i in 0..<10 {
            o.put(3 + i, 1 + i, gd[2]); o.put(15 - i, 1 + i, gd[1])
        }
        o.rect(0, 0, 6, 3, gd[3]); o.hline(0, 0, 6, gd[4]); o.put(1, 1, gd[5])
        o.rect(13, 0, 6, 3, gd[2]); o.hline(13, 0, 6, gd[4])
        // Yunque.
        o.rect(3, 6, 13, 3, gd[3]); o.hline(3, 6, 13, gd[5]); o.hline(4, 8, 11, gd[1])
        o.rect(1, 6, 3, 2, gd[3]); o.put(1, 6, gd[4])
        o.rect(7, 9, 5, 2, gd[2])
        o.rect(5, 11, 9, 2, gd[2]); o.hline(5, 11, 9, gd[3]); o.hline(5, 12, 9, gd[1])
        L.place(o, cx - 9, cy - 6, shadow: (1, 1, 0.6))
    }

    // MARK: - Cuerpo y boca

    static func forgeBody(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let b = ForgePal.brick
        let s = ForgePal.stone
        // Sombra del cuerpo sobre la pared, a la derecha.
        L.shadeRect(g.bodyX1 + 1, g.bodyTop, 5, g.floorY - g.bodyTop, 0.6)
        for y in g.bodyTop..<g.floorY {
            for x in g.bodyX0...g.bodyX1 {
                var c = brickPixel(x, y, g.f, b, seed: 0)
                // Calor: los ladrillos cerca de la boca se enrojecen.
                let dx = Double(x - g.f) / 44, dy = Double(y - g.fireY) / 30
                let heat = max(0, 1 - (dx * dx + dy * dy).squareRoot())
                if heat > 0 { c = TownArt.mix(c, ForgePal.hotBrick[2], heat * 0.45) }
                L.put(x, y, c)
            }
        }
        // Hollín sobre la boca: penacho que sube hasta la cornisa.
        for y in g.bodyTop..<g.crownY {
            let spread = 18 + Double(g.crownY - y) * 0.5
            for x in (g.f - Int(spread))...(g.f + Int(spread)) {
                let k = 1 - abs(Double(x - g.f)) / spread
                let n = TownArt.noise(Double(x) / 4, Double(y) / 3, 83)
                if k * 0.8 + n * 0.4 > 0.55 + TownArt.bayer(x, y) * 0.25 { L.shade(x, y, 0.62) }
            }
        }
        // Pilastras de sillería a los lados.
        for (px, flip) in [(g.bodyX0, false), (g.bodyX1 - 7, true)] {
            var y = g.floorY
            var i = 0
            while y > g.bodyTop {
                let bh = 6 + (i % 2)
                stoneBlock(&L, px, max(g.bodyTop, y - bh), 8, min(bh, y - g.bodyTop), seed: h(px, i, 84), ramp: s, base: 3)
                y -= bh
                i += 1
            }
            L.vline(flip ? px + 7 : px, g.bodyTop, g.floorY - g.bodyTop, ForgePal.outline)
        }
        // Cornisa de piedra encima.
        let cx0 = g.bodyX0 - 3, cw = g.bodyX1 - g.bodyX0 + 7
        L.hline(cx0, g.bodyTop - 3, cw, ForgePal.outline)
        L.hline(cx0, g.bodyTop - 2, cw, s[5])
        L.hline(cx0, g.bodyTop - 1, cw, s[4])
        L.hline(cx0, g.bodyTop, cw, s[3])
        L.hline(cx0, g.bodyTop + 1, cw, s[1])
        L.hline(cx0, g.bodyTop + 2, cw, ForgePal.outline)
        L.vline(cx0, g.bodyTop - 3, 6, ForgePal.outline)
        L.vline(cx0 + cw - 1, g.bodyTop - 3, 6, ForgePal.outline)
        for x in stride(from: cx0 + 6, to: cx0 + cw - 2, by: 12) { L.vline(x, g.bodyTop - 2, 3, s[1]) }
        L.shadeRect(g.bodyX0, g.bodyTop + 3, g.bodyX1 - g.bodyX0 + 1, 1, 0.6)
        // Cenicero bajo la repisa: pequeña boca oscura con brasas caídas.
        let ay = g.floorY - 16
        for y in ay..<(g.floorY - 2) {
            for x in (g.f - 11)...(g.f + 11) {
                let dx = Double(x - g.f) / 11.5, dy = Double(ay + 5 - y) / 5.5
                if y < ay + 5 && dx * dx + dy * dy > 1 { continue }
                let edge = abs(x - g.f) >= 10 || (y < ay + 5 && dx * dx + dy * dy > 0.7)
                if edge { L.put(x, y, s[4]); continue }
                var c: UInt32 = 0x1A0A08
                var gl: UInt8 = 200
                if y > g.floorY - 7 {
                    c = chance(x, y, 85, 0.35) ? ForgePal.fire[2] : (chance(x, y, 86, 0.3) ? ForgePal.fire[1] : 0x3A1208)
                    gl = 255
                }
                L.put(x, y, c, glow: gl)
            }
        }
        L.hline(g.f - 12, g.floorY - 2, 25, s[2])
    }

    static func forgeMouth(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let f = g.f, mh = g.mouthHalf
        let ay = Double(g.springY - g.crownY)
        let s = ForgePal.stone, fire = ForgePal.fire
        // ¿Dentro de la boca?
        func inMouth(_ x: Int, _ y: Int) -> Bool {
            let dx = Double(x - f) / (Double(mh) + 0.5)
            if abs(dx) > 1 || y >= g.ledgeY { return false }
            if y >= g.springY { return true }
            let dy = Double(g.springY - y) / (ay + 0.5)
            return dx * dx + dy * dy <= 1
        }
        // Dovelas del arco.
        let ox = Double(mh + 7), oy = ay + 7
        let segs = 13
        for y in (g.crownY - 8)...g.springY {
            for x in (f - mh - 8)...(f + mh + 8) where !inMouth(x, y) {
                let dx = Double(x - f), dy = Double(g.springY - y) + 0.5
                let e = (dx / ox) * (dx / ox) + (dy / oy) * (dy / oy)
                guard e <= 1 else { continue }
                let ang = atan2(dy / oy, dx / ox)  // 0 (derecha) … π (izquierda)
                let pos = ang / Double.pi * Double(segs)
                let seg = Int(pos)
                let frac = pos - Double(seg)
                var c: UInt32
                if e > 0.86 {
                    c = ForgePal.outline
                } else if frac < 0.09 {
                    c = s[0]
                } else {
                    let key = seg == segs / 2
                    let base = key ? 4 : 3 + (h(seg, 0, 87) % 3 == 0 ? -1 : 0)
                    let inner = e < 0.55
                    c = ramp(s, base + (frac < 0.25 ? 1 : 0) - (inner ? 0 : 0))
                    if chance(x, y, 88, 0.05) { c = ramp(s, base - 1) }
                    // Calor del intradós.
                    if inner { c = TownArt.mix(c, ForgePal.hotBrick[3], 0.35) }
                }
                L.put(x, y, c)
            }
        }
        // Runa enana en la clave (brilla un poco).
        let ky = g.crownY - 5
        L.vline(f, ky - 1, 4, fire[3], glow: 160)
        L.put(f - 1, ky, fire[2], glow: 160); L.put(f + 1, ky, fire[2], glow: 160)
        L.put(f - 1, ky + 2, fire[2], glow: 160); L.put(f + 1, ky + 2, fire[2], glow: 160)
        // Jambas de sillería.
        for side in [-1, 1] {
            let jx = side < 0 ? f - mh - 6 : f + mh + 1
            var y = g.springY
            var i = 0
            while y < g.ledgeY {
                let bh = min(6, g.ledgeY - y)
                stoneBlock(&L, jx, y, 6, bh, seed: h(side + 5, i, 89), ramp: s, base: 3)
                y += bh
                i += 1
            }
            L.vline(side < 0 ? jx - 1 : jx + 6, g.springY, g.ledgeY - g.springY, ForgePal.outline)
            // Calor en la cara interior.
            for y in g.springY..<g.ledgeY {
                for k in 0..<3 { L.tint(side < 0 ? f - mh - 1 - k : f + mh + 1 + k, y, ForgePal.hotBrick[3], 0.5 - Double(k) * 0.15) }
            }
        }
        // Interior: ladrillo refractario al rojo, más claro abajo.
        for y in (g.crownY - 1)..<g.ledgeY {
            for x in (f - mh)...(f + mh) where inMouth(x, y) {
                let t = Double(y - g.crownY) / Double(g.ledgeY - g.crownY)
                let row = (y - g.crownY) / 3
                let lx = (x - f + 300 + (row % 2) * 3) % 6
                let joint = (y - g.crownY) % 3 == 2 || lx == 5
                var c = ramp(fire, Int((t * 2.6 + 0.3 + (TownArt.bayer(x, y) - 0.5) * 0.7).rounded()))
                if joint { c = ramp(fire, Int((t * 2.6 - 0.7).rounded())) }
                L.put(x, y, c, glow: 255)
            }
        }
        // Hollín bajo el intradós.
        for x in (f - mh)...(f + mh) {
            var y = g.crownY - 1
            while y < g.ledgeY && !inMouth(x, y) { y += 1 }
            L.put(x, y, 0x2A0A06, glow: 255)
            L.put(x, y + 1, fire[0], glow: 255)
            if chance(x, 0, 93, 0.5) { L.put(x, y + 2, fire[0], glow: 255) }
        }
        // Llamas fijas (el frame animado añade más encima).
        for x in (f - mh + 1)..<(f + mh) {
            let k = 1 - pow(Double(x - f) / Double(mh), 2)
            let fh = (5 + 13 * TownArt.noise(Double(x) / 3.2, 4.5, 94)) * pow(max(0, k), 0.5)
            let base = g.ledgeY - 4 - Int((4 * k).rounded())
            for i in 0..<Int(fh) {
                let y = base - i
                guard inMouth(x, y) else { continue }
                let t = Double(i) / max(1, fh)
                let c = ramp(fire, 6 - Int((t * 4 + TownArt.bayer(x, y) * 0.8).rounded()))
                L.put(x, y, c, glow: 255)
            }
        }
        // Lecho de carbón: brasas al rojo vivo con terrones oscuros encima (los del centro, al rojo).
        var bedTops: [Int: Int] = [:]
        for x in (f - mh)...(f + mh) {
            let k = 1 - pow(Double(x - f) / Double(mh), 2)
            let top = g.ledgeY - 3 - Int((4 * k).rounded())
            bedTops[x] = top
            for y in top..<g.ledgeY where inMouth(x, y) {
                let c = chance(x, y, 95, 0.3 + k * 0.3) ? fire[5] : (chance(x, y, 99, 0.5) ? fire[4] : fire[3])
                L.put(x, y, y == top ? fire[5] : c, glow: 255)
            }
        }
        var lx = f - mh + 1
        var li = 0
        while lx < f + mh - 1 {
            let r = 1.6 + Double(h(li, 0, 160) % 3) * 0.45
            let top = bedTops[lx] ?? g.ledgeY
            let cyl = Double(top) + 1 + Double(h(li, 1, 161) % 3)
            let k = 1 - pow(Double(lx - f) / Double(mh), 2)
            let hot = k > 0.6 && li % 3 != 1
            for y in Int(cyl - r)...Int(cyl + r) {
                for x in Int(Double(lx) - r)...Int(Double(lx) + r + 1) where inMouth(x, y) && y < g.ledgeY {
                    let dx = (Double(x) - Double(lx) - 0.5) / r, dy = (Double(y) + 0.5 - cyl) / (r * 0.8)
                    let d = dx * dx + dy * dy
                    guard d <= 1 else { continue }
                    var c: UInt32
                    if hot {
                        c = d > 0.5 ? fire[3] : (dx + dy < -0.3 ? fire[4] : fire[2])
                    } else if d > 0.6 {
                        c = fire[1]  // borde al rojo
                    } else {
                        c = dx + dy < -0.4 ? ForgePal.coal[3] : (dx + dy > 0.4 ? ForgePal.coal[1] : ForgePal.coal[2])
                    }
                    L.put(x, y, c, glow: 255)
                }
            }
            lx += 2 + h(li, 2, 162) % 3
            li += 1
        }
        // Barra de hierro calentándose: la punta al rojo dentro, el mango fuera apoyado en la repisa.
        let bx0 = f + 8, by0 = g.ledgeY - 7, bx1 = f + mh + 14, by1 = g.ledgeY - 2
        let len = Double(bx1 - bx0)
        for i in 0...(bx1 - bx0) {
            let x = bx0 + i
            let y = by0 + Int((Double(i) / len * Double(by1 - by0)).rounded())
            let t = Double(i) / len
            let hot: UInt32 = t < 0.25 ? fire[5] : (t < 0.45 ? fire[3] : (t < 0.6 ? fire[1] : ForgePal.iron[3]))
            let gl: UInt8 = t < 0.6 ? 255 : 0
            L.put(x, y - 1, ForgePal.outline)
            L.put(x, y, hot, glow: gl)
            L.put(x, y + 1, t < 0.6 ? TownArt.mix(hot, fire[0], 0.4) : ForgePal.iron[1], glow: gl)
            L.put(x, y + 2, ForgePal.outline)
        }
        L.rect(bx1 + 1, by1 - 1, 2, 4, ForgePal.outline)
        // Repisa de piedra.
        let lx0 = f - mh - 9, lw = 2 * mh + 19
        L.hline(lx0, g.ledgeY, lw, ForgePal.outline)
        L.hline(lx0, g.ledgeY + 1, lw, s[5])
        L.hline(lx0, g.ledgeY + 2, lw, s[4])
        for y in (g.ledgeY + 3)..<(g.ledgeY + 6) {
            for x in lx0..<(lx0 + lw) { L.put(x, y, ramp(s, 2 + (chance(x, y, 96, 0.15) ? -1 : 0) - (y - g.ledgeY - 3) / 2)) }
        }
        L.hline(lx0, g.ledgeY + 6, lw, ForgePal.outline)
        L.vline(lx0, g.ledgeY, 7, ForgePal.outline)
        L.vline(lx0 + lw - 1, g.ledgeY, 7, ForgePal.outline)
        for x in stride(from: lx0 + 9, to: lx0 + lw - 3, by: 15) { L.vline(x, g.ledgeY + 3, 3, s[0]) }
        L.shadeRect(lx0 + 1, g.ledgeY + 7, lw - 2, 2, 0.6)
        // El borde de la repisa recoge la luz del fuego.
        for x in (f - mh)...(f + mh) { L.tint(x, g.ledgeY + 1, fire[4], 0.55); L.tint(x, g.ledgeY + 2, fire[3], 0.35) }
        // Rescoldos caídos en la repisa.
        for x in (f - mh)...(f + mh) where chance(x, 1, 97, 0.12) {
            L.put(x, g.ledgeY + 1, chance(x, 2, 98, 0.5) ? fire[4] : fire[2], glow: 255)
        }
    }

    // MARK: - Rincón de trabajo: herramientas y fuelle

    static func drawForgeCorner(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        // Tablero de herramientas: tablas oscuras con clavijas; las herramientas destacan encima.
        let bx = g.bellowsX - 1, by = g.floorY - 84, bw = 33, bh = 34
        var board = ForgeLayer(bw, bh)
        let dw = ForgePal.darkWood
        for y in 0..<bh {
            for x in 0..<bw {
                let plank = x / 8
                var c = ramp(dw, 2 + (plank % 2 == 0 ? 0 : -1))
                if x % 8 == 7 { c = dw[0] }
                if x % 8 == 0 { c = dw[3] }
                if TownArt.noise(Double(x) * 0.8, Double(y) / 5, 150 + plank) > 0.72 { c = ramp(dw, 1) }
                if y == 0 || x == 0 { c = dw[4] }
                if y == bh - 1 || x == bw - 1 { c = dw[0] }
                board.put(x, y, c)
            }
        }
        // Silueta pintada de cada herramienta (como en los talleres) para saber dónde va.
        L.place(board, bx, by, shadow: (2, 2, 0.55))
        L.place(tongs(length: 28, open: 2), bx + 2, by + 2)
        L.place(hammer(handle: 16, head: 9, big: true), bx + 10, by + 2)
        L.place(tongs(length: 24, open: 1), bx + 20, by + 2)
        L.place(horseshoe(), bx + 26, by + 3)
        L.place(hammer(handle: 12, head: 7, big: false), bx + 25, by + 15)
        L.place(file(length: 13), bx + 12, by + 21)
        // Gancho en la pilastra derecha con un atizador.
        L.place(poker(length: 30), g.bodyX1 + 1, g.floorY - 58)
        bellows(&L, g)
    }

    /// Tenazas colgadas por la boca: mordazas arriba, eje, y los dos mangos que se abren hacia abajo.
    static func tongs(length: Int, open: Int) -> ForgeLayer {
        let w = 7 + open
        var o = ForgeLayer(w, length)
        let i = ForgePal.iron
        let c = w / 2
        // Mordazas curvas.
        o.put(c - 2, 0, i[4]); o.put(c + 2, 0, i[3])
        o.put(c - 3, 1, i[4]); o.put(c + 3, 1, i[2])
        o.put(c - 3, 2, i[4]); o.put(c + 3, 2, i[2])
        o.put(c - 2, 3, i[4]); o.put(c + 2, 3, i[2])
        // Eje con remache.
        o.rect(c - 1, 4, 3, 3, i[3]); o.put(c, 5, i[6]); o.put(c - 1, 4, i[4]); o.put(c + 1, 6, i[1])
        // Mangos.
        for y in 7..<length {
            let spread = (y - 7) * (2 + open) / max(1, length - 7)
            o.put(c - 1 - spread, y, i[4])
            o.put(c + 1 + spread, y, i[2])
        }
        o.put(c - 1 - (2 + open) + 1, length - 1, i[5])
        return o
    }

    /// Martillo colgado por la cabeza, mango hacia abajo.
    static func hammer(handle: Int, head: Int, big: Bool) -> ForgeLayer {
        let hh = big ? 5 : 4
        var o = ForgeLayer(head, handle + hh)
        let w = ForgePal.wood, i = ForgePal.iron
        let hx = head / 2 - 1
        o.rect(0, 0, head, hh, i[3])
        o.hline(0, 0, head, i[5]); o.vline(0, 0, hh, i[4]); o.put(0, 0, i[6])
        o.hline(1, hh - 1, head - 1, i[1]); o.vline(head - 1, 1, hh - 1, i[2])
        if big { o.rect(head - 3, 1, 2, hh - 2, i[2]); o.vline(head - 3, 1, hh - 2, i[4]) } else { o.put(head - 2, 1, i[2]) }
        for y in hh..<(handle + hh) {
            o.put(hx, y, w[5]); o.put(hx + 1, y, w[2])
            if y > handle + hh - 6 && y % 2 == 0 { o.put(hx, y, ForgePal.leather[4]); o.put(hx + 1, y, ForgePal.leather[2]) }
        }
        return o
    }

    static func horseshoe() -> ForgeLayer {
        var o = ForgeLayer(7, 8)
        let i = ForgePal.iron
        for y in 0..<6 { o.put(0, y + 1, i[4]); o.put(6, y + 1, i[2]) }
        o.hline(1, 7, 5, i[2]); o.put(1, 6, i[3]); o.put(5, 6, i[1]); o.put(1, 7, i[3])
        o.put(0, 0, i[3]); o.put(6, 0, i[2])
        o.put(0, 3, i[1]); o.put(6, 4, i[0]); o.put(3, 7, i[1])
        return o
    }

    static func file(length: Int) -> ForgeLayer {
        var o = ForgeLayer(2, length)
        let i = ForgePal.iron
        o.rect(0, 0, 2, 5, ForgePal.wood[3]); o.put(1, 1, ForgePal.wood[1]); o.put(0, 0, ForgePal.wood[5])
        for y in 5..<length { o.put(0, y, y % 2 == 0 ? i[5] : i[3]); o.put(1, y, i[2]) }
        return o
    }

    static func poker(length: Int) -> ForgeLayer {
        var o = ForgeLayer(4, length)
        let i = ForgePal.iron
        o.rect(0, 0, 4, 3, i[3]); o.rect(1, 1, 2, 1, i[0])
        for y in 3..<length { o.put(1, y, i[4]); o.put(2, y, i[2]) }
        o.put(0, length - 2, i[3]); o.put(0, length - 1, i[2])
        return o
    }

    /// Gran fuelle de cuero en forma de pera (vista 3/4), sobre un caballete, con la tobera metida en la fragua.
    static func bellows(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let x0 = g.bellowsX + 2, cy = g.floorY - 30
        let bl = 30
        // Tobera de hierro que entra en la pilastra.
        var pipe = ForgeLayer(max(1, x0 - g.bodyX1 + 3), 3)
        pipe.hline(0, 0, pipe.w, ForgePal.iron[4]); pipe.hline(0, 1, pipe.w, ForgePal.iron[2]); pipe.hline(0, 2, pipe.w, ForgePal.iron[1])
        pipe.put(pipe.w - 3, 0, ForgePal.iron[6])
        L.place(pipe, g.bodyX1 - 1, cy + 1)
        // Caballete (patas abiertas hasta el suelo).
        let lh = g.floorY - cy - 1
        var legs = ForgeLayer(bl + 4, max(1, lh))
        for (lx, d) in [(5, -1), (bl - 3, 1)] {
            for y in 0..<legs.h {
                let x = lx + d * (y / 5)
                legs.put(x, y, ForgePal.darkWood[4]); legs.put(x + 1, y, ForgePal.darkWood[2])
            }
        }
        legs.rect(3, 0, bl - 2, 2, ForgePal.darkWood[3]); legs.hline(3, 0, bl - 2, ForgePal.darkWood[4])
        L.place(legs, x0 - 1, cy + 6)
        // Fuelle.
        var o = ForgeLayer(bl + 6, 16)
        let w = ForgePal.wood, lt = ForgePal.leather
        let mid = 6
        func half(_ x: Int) -> Double {
            let t = Double(x) / Double(bl - 1)
            if t <= 0.8 { return 1.5 + 5 * sin(t / 0.8 * Double.pi / 2) }
            let k = (t - 0.8) / 0.2
            return 6.5 * (1 - k * k).squareRoot() + 0.5
        }
        for x in 0..<bl {
            let hb = half(x)
            let top = mid - Int(hb.rounded())
            let bottom = mid + Int((hb * 0.45).rounded())
            // Tabla de arriba (vista desde arriba en 3/4), con vetas a lo largo.
            for y in top...bottom {
                let n = TownArt.noise(Double(x) / 5, Double(y) * 0.9, 151)
                var c = ramp(w, 3 + Int(((n - 0.5) * 1.6).rounded()))
                if y == top { c = w[5] }
                if y == bottom { c = w[2] }
                o.put(x, y, c)
            }
            // Tachuelas en el borde.
            if x % 4 == 2 { o.put(x, top + 1, ForgePal.iron[5]) }
            // Cuero plegado debajo (pliegues verticales en acordeón), más alto en la parte ancha.
            let lh = 1 + Int((hb * 0.55).rounded())
            for k in 1...lh {
                let fold = (x + k / 2) % 3
                o.put(x, bottom + k, fold == 0 ? lt[4] : (fold == 1 ? lt[2] : lt[1]))
            }
            // Tabla de abajo (canto).
            o.put(x, bottom + lh + 1, w[1])
            o.put(x, bottom + lh + 2, ForgePal.darkWood[1])
        }
        // Remate de latón en la boquilla y asa en la parte ancha.
        o.rect(0, mid - 1, 2, 4, ForgePal.gold[3]); o.put(0, mid - 1, ForgePal.gold[5]); o.put(1, mid + 2, ForgePal.gold[1])
        o.hline(bl, mid - 2, 5, w[4]); o.hline(bl, mid - 1, 5, w[2]); o.rect(bl + 3, mid - 3, 2, 4, w[3])
        // Emblema: una runa de latón en la tabla.
        let ex = bl * 2 / 3
        o.put(ex, mid - 2, ForgePal.gold[4]); o.put(ex - 1, mid - 1, ForgePal.gold[3]); o.put(ex + 1, mid - 1, ForgePal.gold[3]); o.put(ex, mid, ForgePal.gold[2])
        L.place(o, x0, cy - mid)
    }
}
