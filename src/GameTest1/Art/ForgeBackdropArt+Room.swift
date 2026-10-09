import Foundation

// La sala: pared de sillares, vigas y pies derechos de madera, y suelo de losas.

extension ForgeBackdropArt {
    // MARK: - Pared

    /// Pared de sillares irregulares, anclada a la línea del suelo (las hiladas suben desde ahí).
    static func drawWall(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let s = ForgePal.stone
        var bottom = g.floorY
        var row = 0
        while bottom > 0 {
            // La hilada de abajo es un zócalo más alto y oscuro.
            let rh = row == 0 ? 9 : 6 + h(row, 0, 11) % 3
            let top = bottom - rh
            var x = -(h(row, 1, 12) % 16) - 2
            var col = 0
            while x < g.w {
                let bw = (row == 0 ? 18 : 11) + h(col, row, 13) % 9
                stoneBlock(&L, x, top, bw, rh, seed: h(col, row, 14), ramp: s, base: row == 0 ? 1 : 2)
                x += bw
                col += 1
            }
            bottom = top
            row += 1
        }
        // Manchas: humedad y hollín irregular (ruido grande), más hollín arriba.
        for y in 0..<max(0, g.floorY) {
            let up = max(0, Double(g.floorY - 70 - y) / 90)
            for x in 0..<g.w {
                let n = TownArt.noise(Double(x) / 13, Double(y) / 9, 31)
                let k = n * 0.5 + up * 0.35
                if k > 0.36 + TownArt.bayer(x, y) * 0.14 { L.shade(x, y, 0.86) }
                if k > 0.5 + TownArt.bayer(x, y) * 0.12 { L.shade(x, y, 0.88) }
            }
        }
        // Sombra de contacto al pie del muro (el suelo sobresale un poco).
        for x in 0..<g.w {
            L.shade(x, g.floorY - 1, 0.7)
        }
    }

    /// Un sillar con bisel (luz arriba-izquierda), textura, desconchones y alguna grieta.
    static func stoneBlock(_ L: inout ForgeLayer, _ x0: Int, _ y0: Int, _ bw: Int, _ bh: Int, seed: Int,
                           ramp s: [UInt32], base: Int) {
        guard bw > 0, bh > 0 else { return }
        let shift = seed % 5 == 0 ? -1 : (seed % 7 == 0 ? 1 : 0)
        let b = base + shift
        for y in y0..<(y0 + bh) {
            for x in x0..<(x0 + bw) {
                let lx = x - x0, ly = y - y0
                var c: UInt32
                if lx == bw - 1 || ly == bh - 1 {
                    c = s[0]
                } else if ly == 0 || lx == 0 {
                    c = ramp(s, b + 1)
                } else if ly == bh - 2 || lx == bw - 2 {
                    c = ramp(s, b - 1)
                } else {
                    let n = TownArt.noise(Double(x) / 3.2, Double(y) / 2.4, seed % 97)
                    let t = Double(b) + (n - 0.5) * 1.6 + (TownArt.bayer(x, y) - 0.5) * 0.6
                    c = ramp(s, Int(t.rounded()))
                    if chance(x, y, 3, 0.04) { c = ramp(s, b - 1) }
                    if chance(x, y, 4, 0.025) { c = ramp(s, b + 2) }
                }
                L.put(x, y, c)
            }
        }
        // Esquinas desconchadas.
        if seed % 3 == 0 { L.put(x0, y0, s[0]); L.put(x0 + 1, y0, ramp(s, b - 1)) }
        if seed % 4 == 1 { L.put(x0 + bw - 2, y0 + bh - 2, s[0]) }
        // Grieta.
        if seed % 6 == 2 && bw > 9 {
            var cx = x0 + 2 + (seed >> 4) % max(1, bw - 6), cy = y0 + 1
            for i in 0..<max(0, bh - 2) {
                L.put(cx, cy, s[0])
                L.put(cx - 1, cy, ramp(s, b + 1))
                cy += 1
                if (seed >> (i + 6)) & 1 == 1 { cx += 1 }
            }
        }
    }

    // MARK: - Vigas y pies derechos

    static func drawBeams(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let wood = ForgePal.wood
        // Pies derechos: separan el rincón de trabajo, el ventanuco y cada módulo de la armería.
        var posts = [g.postX, g.armoryX - 4]
        var px = g.armoryX + ForgeGeo.moduleWidth - 4
        while px < g.w + 8 { posts.append(px); px += ForgeGeo.moduleWidth }
        for x in posts { post(&L, x, top: 0, bottom: g.floorY + 1, g) }

        // Vigas horizontales: la maestra y, en pantallas altas, otras más arriba (más finas).
        var y = g.beamY
        var level = 0
        while y > -8 {
            let bh = level == 0 ? 8 : 6
            beam(&L, y, bh, g, seed: level)
            // Cabezas de las viguetas del techo apoyadas encima.
            if level == 0 {
                var jx = -(h(level, 3, 41) % 10)
                var j = 0
                while jx < g.w {
                    joistEnd(&L, jx, y - 6, seed: j)
                    jx += 24 + h(j, 0, 42) % 4
                    j += 1
                }
            }
            y -= 62
            level += 1
            if level > 1 { break }  // en pantallas muy altas, una sola viga más: arriba se pierde en la penumbra
        }
        // Penumbra hacia el techo: cuanto más alto, más oscuro (con tramado).
        if g.beamY > 0 {
            for yy in 0..<g.beamY {
                let k = Double(g.beamY - yy) / 140
                for xx in 0..<g.w where TownArt.bayer(xx, yy) < k { L.shade(xx, yy, 0.72) }
            }
        }
        // Tornapuntas (jabalcones) entre los pies derechos y la viga maestra.
        for x in posts {
            brace(&L, x - 1, g.beamY + 8, dir: -1, wood)
            brace(&L, x + 7, g.beamY + 8, dir: 1, wood)
        }
    }

    static func beam(_ L: inout ForgeLayer, _ y0: Int, _ bh: Int, _ g: ForgeGeo, seed: Int) {
        let w = ForgePal.wood
        for y in y0..<(y0 + bh) {
            for x in 0..<g.w {
                let ly = y - y0
                var c: UInt32
                if ly == 0 { c = ForgePal.outline } else if ly == 1 { c = w[4] } else if ly == bh - 1 { c = w[0] } else if ly == bh - 2 { c = w[1] } else {
                    // Vetas horizontales largas.
                    let n = TownArt.noise(Double(x) / 11, Double(y) * 1.3, 51 + seed)
                    c = ramp(w, 2 + Int((n * 2.2 + TownArt.bayer(x, y) * 0.5).rounded()) - 1)
                    if chance(x / 3, y, 52 + seed, 0.06) { c = w[1] }
                }
                L.put(x, y, c)
            }
        }
        // Nudos y fendas.
        var x = h(seed, 9, 53) % 30
        while x < g.w {
            let ky = y0 + 3 + h(x, seed, 54) % max(1, bh - 5)
            L.put(x, ky, w[0]); L.put(x + 1, ky, w[1]); L.put(x - 1, ky, w[3])
            L.hline(x + 4, ky + (bh > 6 ? 1 : 0), 5 + h(x, 1, 55) % 6, w[1])
            x += 37 + h(x, 2, 56) % 30
        }
        // Sombra bajo la viga sobre la pared.
        for x in 0..<g.w { L.shade(x, y0 + bh, 0.62); L.shade(x, y0 + bh + 1, 0.8) }
    }

    static func joistEnd(_ L: inout ForgeLayer, _ x0: Int, _ y0: Int, seed: Int) {
        let w = ForgePal.wood
        L.rect(x0, y0, 7, 6, ForgePal.outline)
        L.rect(x0 + 1, y0 + 1, 5, 5, w[3])
        L.rect(x0 + 2, y0 + 2, 3, 3, w[2])
        L.put(x0 + 3, y0 + 3, w[4])
        L.hline(x0 + 1, y0 + 1, 5, w[4])
        L.vline(x0 + 5, y0 + 2, 4, w[1])
        if seed % 3 == 0 { L.put(x0 + 4, y0 + 2, w[1]); L.put(x0 + 4, y0 + 3, w[1]) }
    }

    static func post(_ L: inout ForgeLayer, _ x0: Int, top: Int, bottom: Int, _ g: ForgeGeo) {
        let w = ForgePal.wood
        let pw = 7
        guard bottom > top else { return }
        // Sombra del poste a su derecha.
        for y in top..<bottom { L.shade(x0 + pw, y, 0.6); L.shade(x0 + pw + 1, y, 0.8) }
        for y in top..<bottom {
            for x in x0..<(x0 + pw) {
                let lx = x - x0
                var c: UInt32
                if lx == 0 || lx == pw - 1 { c = ForgePal.outline } else if lx == 1 { c = w[4] } else if lx == pw - 2 { c = w[1] } else {
                    let n = TownArt.noise(Double(x) * 1.4, Double(y) / 9, 61 + x0)
                    c = ramp(w, 1 + Int((n * 2.4 + TownArt.bayer(x, y) * 0.5).rounded()))
                }
                L.put(x, y, c)
            }
        }
        // Grietas verticales y clavos de forja.
        var y = top + h(x0, 1, 62) % 12
        while y < bottom - 6 {
            L.vline(x0 + 3, y, 4 + h(x0, y, 63) % 5, w[0])
            y += 17 + h(x0, y, 64) % 12
        }
        // Base de piedra y herraje a la altura de la viga.
        L.rect(x0 - 1, bottom - 5, pw + 2, 5, ForgePal.outline)
        L.rect(x0, bottom - 4, pw, 3, ForgePal.stone[3])
        L.hline(x0, bottom - 4, pw, ForgePal.stone[4])
        let by = g.beamY + 9
        L.rect(x0 - 1, by, pw + 2, 3, ForgePal.iron[1])
        L.hline(x0 - 1, by, pw + 2, ForgePal.iron[3])
        L.put(x0 + 1, by + 1, ForgePal.iron[5]); L.put(x0 + pw - 2, by + 1, ForgePal.iron[5])
    }

    static func brace(_ L: inout ForgeLayer, _ x0: Int, _ y0: Int, dir: Int, _ w: [UInt32]) {
        for i in 0..<11 {
            let x = x0 + dir * i, y = y0 + 10 - i
            L.put(x, y - 1, ForgePal.outline)
            L.put(x, y, w[dir < 0 ? 4 : 3])
            L.put(x, y + 1, w[2])
            L.put(x, y + 2, w[1])
            L.put(x, y + 3, ForgePal.outline)
            L.shade(x + 1, y + 4, 0.7)
        }
    }

    // MARK: - Suelo

    /// Losas de piedra en perspectiva (las juntas convergen un poco hacia el fondo), con hollín y limaduras.
    static func drawFloor(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let s = ForgePal.floor
        let vx = Double(g.f + 60), vy = Double(g.floorY - 150)
        // Filas cada vez más altas hacia delante.
        var rows: [(Int, Int)] = []
        var y = g.floorY
        var rh = 4
        while y < g.h { rows.append((y, rh)); y += rh; rh += 1 }
        for (r, (y0, rh)) in rows.enumerated() {
            let off = Double(h(r, 0, 71) % 20)
            let slab = 22.0 + Double(h(r, 1, 72) % 8)
            for y in y0..<min(g.h, y0 + rh) {
                let depth = Double(150) / (Double(y) - vy)
                for x in 0..<g.w {
                    let u = (Double(x) - vx) * depth + off + 400
                    let col = Int(floor(u / slab))
                    let lu = u - Double(col) * slab
                    let ly = y - y0
                    let seed = h(col, r, 73)
                    let b = 2 + (seed % 5 == 0 ? -1 : (seed % 7 == 0 ? 1 : 0))
                    var c: UInt32
                    if ly == 0 || lu < depth * 1.0 {
                        c = s[0]
                    } else if ly == 1 || lu < depth * 2.0 {
                        c = ramp(s, b + 1)
                    } else if ly == rh - 1 {
                        c = ramp(s, b - 1)
                    } else {
                        let n = TownArt.noise(Double(x) / 4, Double(y) / 2, seed % 89)
                        c = ramp(s, Int((Double(b) + (n - 0.5) * 1.5 + (TownArt.bayer(x, y) - 0.5) * 0.6).rounded()))
                        if chance(x, y, 74, 0.03) { c = s[1] }
                    }
                    L.put(x, y, c)
                }
            }
        }
        // Hollín y polvo de carbón alrededor de la fragua; limaduras brillantes; sombra de contacto del muro.
        for y in max(0, g.floorY)..<max(max(0, g.floorY), g.h) {
            for x in 0..<g.w {
                let dx = Double(x - g.f) / 90, dy = Double(y - g.floorY) / 30
                let near = max(0, 1 - (dx * dx + dy * dy).squareRoot())
                let n = TownArt.noise(Double(x) / 6, Double(y) / 3, 75)
                if n * 0.6 + near * 0.7 > 0.62 + TownArt.bayer(x, y) * 0.2 { L.shade(x, y, 0.72) }
                if chance(x, y, 76, 0.012 + near * 0.03) { L.put(x, y, ForgePal.coal[1]) }
                if chance(x, y, 77, 0.006) { L.put(x, y, ForgePal.iron[4]) }
            }
        }
        for x in 0..<g.w {
            L.shade(x, g.floorY, 0.5)
            L.shade(x, g.floorY + 1, 0.65)
            L.shade(x, g.floorY + 2, 0.82)
        }
    }
}
