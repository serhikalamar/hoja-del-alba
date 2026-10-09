import Foundation

// Objetos apoyados en el suelo: carbón, yunque sobre su tocón, tina de templar, barriles, cajas y sacos.

extension ForgeBackdropArt {
    static func drawFloorProps(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let fy = g.floorY
        // (base en el suelo, dibujo): se pintan de atrás adelante.
        var items: [(Int, () -> Void)] = []
        var layer = L
        items.append((fy + 10, { place(&layer, barrel(lid: true, seed: 1), g.windowX - 3, fy + 10) }))
        items.append((fy + 13, { place(&layer, barrel(lid: false, seed: 2), g.windowX + 13, fy + 13) }))
        items.append((fy + 9, { place(&layer, coalPile(), g.f + 42, fy + 9) }))
        items.append((fy + 23, { place(&layer, anvil(), g.f + 60, fy + 23, stump: true) }))
        items.append((fy + 21, { place(&layer, tub(), g.f + 92, fy + 21) }))
        items.append((fy + 18, { place(&layer, bucket(), g.f + 121, fy + 18) }))
        var mx = g.armoryX
        var i = 0
        while mx < g.w {
            let x = mx, k = i
            switch k % 3 {
            case 0: items.append((fy + 12, { place(&layer, crate(seed: k), x + 8, fy + 12) }))
            case 1: items.append((fy + 14, { place(&layer, sack(seed: k), x + 30, fy + 14) }))
            default: items.append((fy + 11, { place(&layer, barrel(lid: true, seed: k), x + 50, fy + 11) }))
            }
            mx += ForgeGeo.moduleWidth
            i += 1
        }
        for item in items.sorted(by: { $0.0 < $1.0 }) { item.1() }
        L = layer
    }

    /// Coloca un objeto con su base en `baseY`: sombra de contacto en el suelo y sombra alargada a la derecha.
    static func place(_ L: inout ForgeLayer, _ o: ForgeLayer, _ x: Int, _ baseY: Int, stump: Bool = false) {
        let lined = o.outlined(ForgePal.outline)
        let y = baseY - lined.h
        // Sombra en el suelo: elipse aplastada bajo el objeto, desplazada a la derecha (luz de la fragua).
        let cx = Double(x) + Double(lined.w) / 2 + 3, cy = Double(baseY) - 0.5
        let rx = Double(lined.w) / 2 + 3, ry = 2.6
        for yy in Int(cy - ry)...Int(cy + ry) {
            for xx in Int(cx - rx)...Int(cx + rx) {
                let dx = (Double(xx) + 0.5 - cx) / rx, dy = (Double(yy) + 0.5 - cy) / ry
                let d = dx * dx + dy * dy
                if d <= 1 { L.shade(xx, yy, d < 0.5 ? 0.5 : 0.7) }
            }
        }
        L.paste(lined, x, y)
    }

    // MARK: - Objetos

    static func coalPile() -> ForgeLayer {
        var o = ForgeLayer(24, 10)
        let c = ForgePal.coal
        for x in 0..<24 {
            let dx = (Double(x) - 11.5) / 12
            let hp = Int((9 * (1 - dx * dx) + TownArt.noise(Double(x) / 2, 0, 111) * 2).rounded())
            for y in (10 - hp)..<10 {
                let lx = (x + (y / 2) % 2) % 3, ly = y % 2
                let s = h(x / 3, y / 2, 112)
                var col = ly == 0 ? c[2 + (s % 2)] : c[1]
                if lx == 2 { col = c[0] }
                if y == 10 - hp { col = c[3] }
                if chance(x, y, 113, 0.05) { col = ForgePal.iron[4] }
                o.put(x, y, col)
            }
        }
        // Pala clavada en el montón.
        for y in 0..<6 { o.put(18 + y / 3, y - 3 < 0 ? 0 : y, ForgePal.wood[3]) }
        return o
    }

    static func anvil() -> ForgeLayer {
        let i = ForgePal.iron
        var o = ForgeLayer(32, 27)
        // Cara y cuerno (a la izquierda, hacia la fragua).
        o.hline(5, 0, 24, i[6]); o.hline(5, 1, 24, i[5])
        o.rect(5, 2, 24, 3, i[3]); o.hline(5, 4, 24, i[2])
        for k in 0..<5 { o.vline(k, 2 - (k + 1) / 3, 1 + (k + 1) / 2, k < 2 ? i[4] : i[5]); o.put(k, 2 + (k + 1) / 2, i[2]) }
        o.put(25, 1, i[0]); o.put(22, 1, i[1])  // agujeros
        o.rect(26, 5, 3, 2, i[2])  // talón
        // Cintura y pies.
        for y in 5..<10 {
            let inset = y < 8 ? 9 + (y - 5) : 11
            o.hline(inset, y, 28 - 2 * inset + 5, i[2]); o.put(inset, y, i[3])
        }
        o.rect(6, 10, 22, 4, i[2]); o.hline(6, 10, 22, i[3]); o.hline(6, 13, 22, i[1]); o.vline(6, 10, 4, i[3])
        o.rect(15, 11, 4, 2, i[1])
        // Pieza al rojo encima del yunque.
        o.hline(9, 0, 11, ForgePal.fire[4], glow: 255); o.hline(10, 1, 9, ForgePal.fire[3], glow: 255)
        o.put(20, 0, ForgePal.fire[2], glow: 255); o.put(8, 0, ForgePal.fire[5], glow: 255)
        // Tocón de madera con aro de hierro.
        let w = ForgePal.wood
        for y in 14..<27 {
            for x in 8..<26 {
                var c = (x - 8) % 4 == 0 ? w[1] : w[2 + (h(x, y / 3, 114) % 2)]
                if x == 8 { c = w[3] }
                if x >= 24 { c = w[1] }
                o.put(x, y, c)
            }
        }
        o.hline(8, 14, 18, w[4])
        o.hline(8, 20, 18, i[3]); o.hline(8, 21, 18, i[1]); o.put(10, 20, i[5])
        return o
    }

    static func tub() -> ForgeLayer {
        var o = ForgeLayer(28, 18)
        let w = ForgePal.wood, water = ForgePal.water, i = ForgePal.iron
        // Cuerpo de duelas.
        for y in 3..<18 {
            let inset = y > 14 ? 1 : 0
            for x in inset..<(28 - inset) {
                var c = (x % 5 == 4) ? w[1] : w[2 + (x < 10 ? 1 : 0)]
                if x <= inset + 1 { c = w[4] }
                if x >= 26 - inset { c = w[1] }
                o.put(x, y, c)
            }
        }
        // Aros.
        for hy in [6, 14] {
            o.hline(0, hy, 28, i[3]); o.hline(0, hy + 1, 28, i[1])
            o.put(3, hy, i[5]); o.put(24, hy, i[2])
        }
        // Borde y agua (elipse) con reflejos del fuego.
        o.disc(14, 3, 14, 3.2, w[4])
        o.disc(14, 3.2, 12.4, 2.4, water[2])
        o.hline(5, 2, 10, water[3]); o.hline(8, 3, 6, water[1])
        o.put(7, 2, ForgePal.fire[4], glow: 220); o.put(8, 2, ForgePal.fire[3], glow: 200); o.put(17, 3, ForgePal.fire[3], glow: 180)
        o.put(20, 2, water[4])
        // Tenazas apoyadas en el borde.
        o.line(18, 0, 27, 4, i[4]); o.line(19, 0, 27, 5, i[2])
        return o
    }

    static func bucket() -> ForgeLayer {
        var o = ForgeLayer(10, 10)
        let w = ForgePal.wood
        for y in 2..<10 {
            for x in (y > 7 ? 1 : 0)..<(y > 7 ? 9 : 10) { o.put(x, y, x < 2 ? w[4] : (x % 3 == 2 ? w[1] : w[2])) }
        }
        o.hline(0, 2, 10, w[4]); o.disc(5, 2.5, 4, 1.2, ForgePal.water[1])
        o.hline(0, 4, 10, ForgePal.iron[3]); o.hline(0, 8, 10, ForgePal.iron[2])
        o.put(0, 0, ForgePal.iron[3]); o.put(9, 0, ForgePal.iron[3]); o.hline(1, 0, 8, ForgePal.iron[4])
        return o
    }

    static func barrel(lid: Bool, seed: Int) -> ForgeLayer {
        var o = ForgeLayer(14, lid ? 18 : 28)
        let top = lid ? 0 : 10
        let w = ForgePal.wood, i = ForgePal.iron
        if !lid {
            // Armas metidas en el barril, asomando por arriba.
            for (k, x) in [2, 6, 10].enumerated() {
                let len = 12 - k * 2
                let y0 = top + 2 - len
                o.vline(x, y0, len, k == 1 ? ForgePal.wood[4] : ForgePal.steel[4])
                o.vline(x + 1, y0, len, k == 1 ? ForgePal.wood[2] : ForgePal.steel[2])
                if k != 1 { o.hline(x - 1, y0 + 4, 4, ForgePal.gold[3]); o.rect(x, y0, 2, 4, ForgePal.leather[3]) } else { o.rect(x - 1, y0, 4, 3, ForgePal.iron[3]) }
            }
        }
        for y in top..<(top + 18) {
            let ly = y - top
            let inset = (ly < 2 || ly > 15) ? 1 : 0
            for x in inset..<(14 - inset) {
                var c = (x % 4 == 3) ? w[1] : w[2 + (x < 6 ? 1 : 0)]
                if x <= inset + 1 { c = w[4] }
                if x >= 12 - inset { c = w[1] }
                o.put(x, y, c)
            }
        }
        for hy in [top + 3, top + 13] {
            o.hline(0, hy, 14, i[3]); o.hline(0, hy + 1, 14, i[1]); o.put(2, hy, i[5])
        }
        if lid {
            o.disc(7, 1.5, 6, 1.6, w[4]); o.hline(3, 1, 8, w[3]); o.put(7, 1, w[1])
        } else {
            o.disc(7, Double(top) + 1.5, 6, 1.6, w[1])
        }
        return o
    }

    static func crate(seed: Int) -> ForgeLayer {
        var o = ForgeLayer(18, 15)
        let w = ForgePal.wood
        // Tapa (vista desde arriba en 3/4).
        o.rect(1, 0, 16, 3, w[4]); o.hline(1, 0, 16, w[5]); o.vline(8, 0, 3, w[2])
        // Frente.
        for y in 3..<15 {
            for x in 0..<18 { o.put(x, y, (y - 3) % 4 == 3 ? w[1] : w[2 + (x < 4 ? 1 : 0)]) }
        }
        o.vline(0, 3, 12, w[4]); o.vline(17, 3, 12, w[1])
        o.line(1, 13, 16, 4, w[3]); o.line(1, 14, 16, 5, w[1])
        for (x, y) in [(1, 4), (16, 4), (1, 13), (16, 13)] { o.put(x, y, ForgePal.iron[4]) }
        // Lingotes asomando.
        o.hline(3, 0, 4, ForgePal.copper[4]); o.hline(10, 0, 4, ForgePal.iron[5])
        return o
    }

    static func sack(seed: Int) -> ForgeLayer {
        var o = ForgeLayer(16, 14)
        let c = ForgePal.cloth
        o.disc(8, 8.5, 7.5, 5.5, c[2])
        o.disc(6.5, 7.5, 4.5, 3.5, c[3])
        o.rect(6, 1, 4, 3, c[2]); o.hline(6, 3, 4, ForgePal.rope[2]); o.hline(5, 0, 6, c[1])
        for x in stride(from: 3, to: 14, by: 3) { o.put(x, 10, c[1]); o.put(x + 1, 11, c[1]) }
        // Mineral que se sale.
        o.put(13, 12, ForgePal.sapphire[3], glow: 120); o.put(14, 13, ForgePal.stone[3]); o.put(12, 13, ForgePal.stone[4])
        return o
    }
}
