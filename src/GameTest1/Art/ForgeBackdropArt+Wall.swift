import Foundation

// La pared de la derecha: baldas con lingotes y minerales, ventanuco con luz azul, escudos y
// módulos de armería que se repiten (armas, escudos, piezas de arma, cadenas y farolillos).

extension ForgeBackdropArt {
    static func drawArmoryWall(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        shelves(&L, g)
        window(&L, g)
        // Bajo el ventanuco: hachas cruzadas detrás de un escudo redondo.
        let sx = g.windowX + 11, sy = g.floorY - 34
        let a = axe(handle: 30, double: false).rotatedDiag()
        L.place(a, sx - 14, sy - 17)
        L.place(a.flippedX(), sx - a.w + 14, sy - 17)
        L.place(roundShield(radius: 10, paint: ForgePal.blue, seed: 1), sx - 10, sy - 10)
        // Módulos de armería hasta el borde derecho.
        var mx = g.armoryX
        var i = 0
        while mx < g.w {
            armoryModule(&L, g, mx, index: i)
            mx += ForgeGeo.moduleWidth
            i += 1
        }
        for x in g.lanternXs { lantern(&L, g, x) }
        if let c = g.chandelier { chandelier(&L, c.x, c.y) }
    }

    /// Rueda de velas colgada en lo alto (solo en pantallas altas, donde se ve el techo).
    static func chandelier(_ L: inout ForgeLayer, _ cx: Int, _ cy: Int) {
        let i = ForgePal.iron, fire = ForgePal.fire
        // Cadenas desde arriba: tres que convergen en la anilla.
        for (dx, top) in [(0, 0)] {
            var y = top
            while y < cy - 9 {
                L.put(cx + dx, y, i[3]); L.put(cx + dx, y + 1, i[1])
                L.put(cx + dx + 1, y, ForgePal.outline)
                y += 2
            }
        }
        var o = ForgeLayer(33, 16)
        // Tirantes de la anilla a la rueda.
        o.line(16, 0, 2, 9, i[2]); o.line(16, 0, 30, 9, i[2]); o.line(16, 0, 16, 9, i[3])
        o.rect(15, 0, 3, 2, i[4])
        // Rueda (elipse en 3/4).
        for x in 0..<33 {
            let dx = (Double(x) - 16) / 16.5
            let k = (1 - dx * dx).squareRoot()
            let yf = 11 + Int((k * 3).rounded()), yb = 11 - Int((k * 3).rounded())
            o.put(x, yf, i[4]); o.put(x, yf + 1, i[1])
            o.put(x, yb, i[2])
        }
        // Velas con su llama.
        for (k, x) in [3, 10, 16, 22, 29].enumerated() {
            let base = 11 + (k == 2 ? -3 : (k == 0 || k == 4 ? 0 : 2))
            let hgt = 4 + (k % 2)
            o.rect(x, base - hgt, 2, hgt, 0xE8DCC0); o.put(x + 1, base - hgt + 1, 0xB8A888); o.put(x, base - 1, 0xF8F0DC)
            o.put(x, base - hgt - 1, fire[5], glow: 255); o.put(x + 1, base - hgt - 1, fire[4], glow: 255)
            o.put(x, base - hgt - 2, fire[4], glow: 255)
            o.put(x, base - hgt - 3, fire[3], glow: 255)
        }
        L.place(o, cx - 16, cy - 9, shadow: nil)
    }

    // MARK: - Baldas

    static func shelves(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let x0 = g.shelfX, sw = 46
        let ys = [g.floorY - 74, g.floorY - 55, g.floorY - 36]
        for (i, y) in ys.enumerated() {
            // Objetos encima (apoyados en la tabla).
            switch i {
            case 0:
                L.place(ore(ForgePal.ruby, seed: 1), x0 + 2, y - 7)
                L.place(crystals(ForgePal.amethyst, seed: 2), x0 + 13, y - 10)
                L.place(jar(ForgePal.emerald), x0 + 22, y - 9)
                L.place(ore(ForgePal.sapphire, seed: 3), x0 + 31, y - 7)
                L.place(crystals(ForgePal.mithril, seed: 4), x0 + 40, y - 8)
            case 1:
                ingotStack(&L, x0 + 2, y, ForgePal.iron, count: 3)
                ingotStack(&L, x0 + 18, y, ForgePal.copper, count: 3)
                ingotStack(&L, x0 + 33, y, ForgePal.gold, count: 2)
            default:
                L.place(crucible(), x0 + 2, y - 8)
                L.place(ore(ForgePal.emerald, seed: 5), x0 + 13, y - 7)
                ingotStack(&L, x0 + 22, y, ForgePal.mithril, count: 1)
                L.place(crystals(ForgePal.ruby, seed: 6), x0 + 31, y - 9)
                L.place(ore(ForgePal.gold, seed: 7), x0 + 37, y - 6)
            }
            // La tabla y sus escuadras.
            var plank = ForgeLayer(sw, 3)
            for x in 0..<sw {
                plank.put(x, 0, ForgePal.wood[5])
                plank.put(x, 1, chance(x, y, 101, 0.2) ? ForgePal.wood[2] : ForgePal.wood[3])
                plank.put(x, 2, ForgePal.wood[1])
            }
            L.place(plank, x0, y, shadow: (1, 2, 0.5))
            for bx in [x0 + 3, x0 + sw - 6] {
                var br = ForgeLayer(4, 5)
                for k in 0..<4 { br.put(k, 0, ForgePal.iron[3]); br.put(0, k, ForgePal.iron[3]); br.put(k == 0 ? 0 : 4 - k, k, ForgePal.iron[2]) }
                br.put(0, 0, ForgePal.iron[5])
                L.place(br, bx, y + 3, shadow: (1, 1, 0.6))
            }
        }
    }

    /// Lingote en 3/4 (cara de arriba más clara).
    static func ingot(_ L: inout ForgeLayer, _ x: Int, _ y: Int, _ r: [UInt32]) {
        var o = ForgeLayer(7, 4)
        o.hline(1, 0, 5, ramp(r, 4)); o.put(1, 0, ramp(r, 5))
        o.hline(0, 1, 7, ramp(r, 3))
        o.hline(0, 2, 7, ramp(r, 2)); o.put(0, 2, ramp(r, 3))
        o.hline(0, 3, 7, ramp(r, 1))
        L.place(o, x, y, shadow: (1, 0, 0.6))
    }

    /// Pila de lingotes apoyada en `baseY` (la cara de arriba de la tabla).
    static func ingotStack(_ L: inout ForgeLayer, _ x: Int, _ baseY: Int, _ r: [UInt32], count: Int) {
        if count >= 2 {
            ingot(&L, x, baseY - 5, r)
            ingot(&L, x + 8, baseY - 5, r)
            if count >= 3 { ingot(&L, x + 4, baseY - 10, r) }
        } else {
            ingot(&L, x, baseY - 5, r)
        }
    }

    /// Mena: piedra con cristales de color que brillan un poco.
    static func ore(_ gem: [UInt32], seed: Int) -> ForgeLayer {
        var o = ForgeLayer(8, 6)
        let s = ForgePal.stone
        o.disc(4, 3.5, 4, 2.6, s[3])
        o.disc(3.3, 3, 2.6, 1.6, s[4])
        o.hline(1, 5, 6, s[2])
        let spots = [(2, 2), (5, 1), (4, 3), (6, 3), (1, 4)]
        for (k, p) in spots.enumerated() where (seed + k) % 4 != 0 {
            o.put(p.0, p.1, gem[3], glow: 140)
            o.put(p.0 + 1, p.1, gem[2], glow: 90)
            if k == 1 { o.put(p.0, p.1 - 1, gem[4], glow: 200) }
        }
        return o
    }

    /// Racimo de cristales puntiagudos (brillan).
    static func crystals(_ gem: [UInt32], seed: Int) -> ForgeLayer {
        var o = ForgeLayer(8, 11)
        let shards = [(1, 6), (3, 10), (5, 7)]
        for (k, sh) in shards.enumerated() {
            let (x, hgt) = sh
            let hh = hgt - (seed + k) % 2
            for y in (11 - hh)..<11 {
                let top = y == 11 - hh
                o.put(x, y, top ? gem[4] : gem[3], glow: 150)
                if !top { o.put(x + 1, y, gem[2], glow: 110) }
            }
            o.put(x + 1, 11 - hh + 1, gem[3], glow: 150)
        }
        o.hline(0, 10, 8, ForgePal.stone[2])
        return o
    }

    static func jar(_ liquid: [UInt32]) -> ForgeLayer {
        var o = ForgeLayer(7, 9)
        o.rect(2, 0, 3, 1, ForgePal.cloth[2]); o.put(2, 0, ForgePal.cloth[3])
        o.rect(2, 1, 3, 1, ForgePal.rope[1])
        o.rect(1, 2, 5, 7, 0x6A8A90)
        o.rect(1, 4, 5, 5, liquid[2], glow: 120)
        o.hline(1, 4, 5, liquid[3], glow: 160)
        o.vline(1, 2, 6, 0xC0E0E4)
        o.put(4, 6, liquid[4], glow: 200)
        return o
    }

    static func crucible() -> ForgeLayer {
        var o = ForgeLayer(9, 8)
        let c: [UInt32] = [0x3A2620, 0x5E3E30, 0x7E5642, 0x9C7058]
        o.hline(0, 0, 9, c[3]); o.hline(1, 1, 7, 0x1E1210)
        o.put(2, 1, ForgePal.gold[3], glow: 120); o.put(3, 1, ForgePal.gold[2], glow: 80)
        for y in 2..<8 {
            let inset = y >= 6 ? y - 5 : 0
            for x in inset..<(9 - inset) { o.put(x, y, x < 3 ? c[2] : (x < 6 ? c[1] : c[0])) }
        }
        o.put(1, 3, c[3])
        return o
    }

    // MARK: - Ventanuco

    static func window(_ L: inout ForgeLayer, _ g: ForgeGeo) {
        let x0 = g.windowX, ww = 22, top = g.floorY - 84, wh = 26
        let s = ForgePal.stone, sky = ForgePal.sky
        let cx = Double(x0) + Double(ww) / 2, r = Double(ww) / 2
        func inside(_ x: Int, _ y: Int, _ pad: Double) -> Bool {
            let px = Double(x) + 0.5, py = Double(y) + 0.5
            if px < Double(x0) + pad || px > Double(x0 + ww) - pad || py > Double(top + wh) - pad { return false }
            let ay = Double(top) + r
            if py >= ay { return true }
            let dx = px - cx, dy = py - ay
            return dx * dx + dy * dy <= (r - pad) * (r - pad)
        }
        for y in (top - 4)..<(top + wh + 4) {
            for x in (x0 - 4)..<(x0 + ww + 4) {
                if inside(x, y, 0) {
                    if !inside(x, y, 3) {
                        // Derrame (grosor del muro): más claro abajo-derecha, que recibe la luz de fuera.
                        let lower = Double(y - top) / Double(wh)
                        let c = Double(x) > cx ? s[3] : s[1]
                        L.put(x, y, lower > 0.6 && Double(x) > cx ? s[4] : c)
                        continue
                    }
                    // Cielo de atardecer frío con montañas y estrellas.
                    let t = Double(y - top) / Double(wh)
                    var c = ramp(sky, Int((t * 3.6 + (TownArt.bayer(x, y) - 0.5) * 0.8).rounded()))
                    let ridge = top + wh - 7 - Int(4 * TownArt.noise(Double(x) / 4, 1, 102))
                    if y > ridge { c = y > ridge + 3 ? 0x16243A : 0x22385A }
                    if y < top + 12 && chance(x, y, 103, 0.05) { c = sky[4] }
                    L.put(x, y, c, glow: 255)
                } else if inside(x - 2, y, -2) || inside(x + 2, y, -2) || inside(x, y + 2, -2) {
                    L.put(x, y, ForgePal.outline)
                }
            }
        }
        // Barrotes en cruz.
        let bx = x0 + ww / 2 - 1, by = top + 14
        for y in (top + 3)..<(top + wh - 3) { L.put(bx, y, ForgePal.iron[3]); L.put(bx + 1, y, ForgePal.iron[1]) }
        for x in (x0 + 3)..<(x0 + ww - 3) { L.put(x, by, ForgePal.iron[3]); L.put(x, by + 1, ForgePal.iron[1]) }
        L.put(bx, by, ForgePal.iron[5])
        // Alféizar.
        let sy = top + wh
        L.hline(x0 - 3, sy, ww + 6, ForgePal.outline)
        L.hline(x0 - 2, sy + 1, ww + 4, 0x9AB4C8)
        L.hline(x0 - 2, sy + 2, ww + 4, s[3])
        L.hline(x0 - 3, sy + 3, ww + 6, ForgePal.outline)
        L.shadeRect(x0 - 2, sy + 4, ww + 4, 2, 0.6)
        // Rayo de luz fría que cae en diagonal hacia el suelo.
        for y in (sy + 4)..<g.floorY + 14 {
            let k = y - sy
            let xa = x0 + 3 + k / 3, xb = x0 + ww - 3 + k / 3
            for x in xa..<xb where TownArt.bayer(x, y) < 0.35 - Double(k) / 260 {
                L.tint(x, y, sky[3], 0.22)
            }
        }
    }

    // MARK: - Armería

    static func armoryModule(_ L: inout ForgeLayer, _ g: ForgeGeo, _ mx: Int, index i: Int) {
        let v = i % 3
        let fy = g.floorY
        switch v {
        case 0:
            // Armero de espadas: listón con espadas colgadas de punta y un hacha y un martillo.
            var rail = ForgeLayer(54, 3)
            rail.hline(0, 0, 54, ForgePal.wood[4]); rail.hline(0, 1, 54, ForgePal.wood[2]); rail.hline(0, 2, 54, ForgePal.wood[1])
            L.place(heaterShield(paint: ForgePal.red, seed: i), mx + 24, fy - 86)
            let swords: [(Int, Int, Int)] = [(30, 7, 0), (26, 9, 1), (34, 7, 2), (24, 5, 3)]
            for (k, s) in swords.enumerated() {
                L.place(sword(blade: s.0, guard: s.1, style: s.2 + i), mx + 4 + k * 10, fy - 64)
            }
            L.place(rail, mx + 2, fy - 66)
            L.place(axe(handle: 30, double: true), mx + 44, fy - 66)
            L.place(warhammer(handle: 30), mx + 58, fy - 64)
            chain(&L, mx + 70, g.beamY + 8, fy - 40)
        case 1:
            // Escudos y espadas cruzadas.
            L.place(roundShield(radius: 11, paint: ForgePal.red, seed: i), mx + 4, fy - 80)
            L.place(heaterShield(paint: ForgePal.blue, seed: i + 1), mx + 48, fy - 80)
            L.place(sword(blade: 30, guard: 9, style: i).rotatedDiag(), mx + 18, fy - 52)
            L.place(sword(blade: 30, guard: 9, style: i + 1).rotatedDiag().flippedX(), mx + 18, fy - 52)
            chain(&L, mx + 34, g.beamY + 8, fy - 70)
        default:
            // Tablero de piezas: hojas sin montar, guardas, empuñaduras y pomos colgados de ganchos.
            var board = ForgeLayer(60, 44)
            for y in 0..<44 {
                for x in 0..<60 {
                    let edge = x < 2 || x > 57 || y < 2 || y > 41
                    let plank = (x / 10) % 2
                    var c = edge ? ForgePal.darkWood[3] : (plank == 0 ? ForgePal.darkWood[2] : ForgePal.darkWood[1])
                    if !edge && x % 10 == 9 { c = ForgePal.darkWood[0] }
                    if edge && (x == 0 || y == 0) { c = ForgePal.darkWood[4] }
                    board.put(x, y, c)
                }
            }
            L.place(board, mx + 6, fy - 80, shadow: (2, 2, 0.6))
            let bx = mx + 6, by = fy - 80
            for k in 0..<4 {
                L.place(bladeBlank(length: 18 + (k * 5) % 9, width: k % 2 == 0 ? 3 : 4), bx + 5 + k * 8, by + 4)
            }
            L.place(guardPiece(width: 11, curved: false), bx + 38, by + 5)
            L.place(guardPiece(width: 9, curved: true), bx + 38, by + 13)
            L.place(gripPiece(length: 9, seed: i), bx + 38, by + 22)
            L.place(gripPiece(length: 7, seed: i + 1), bx + 45, by + 22)
            L.place(pommel(ForgePal.gold), bx + 51, by + 6)
            L.place(pommel(ForgePal.iron), bx + 51, by + 13)
            L.place(tongs(length: 18, open: 1), bx + 52, by + 22)
        }
    }

    static func sword(blade: Int, guard gw: Int, style: Int) -> ForgeLayer {
        let w = gw, cx = gw / 2
        var o = ForgeLayer(w, blade + 9)
        let st = ForgePal.steel, lt = ForgePal.leather
        let metal = style % 3 == 1 ? ForgePal.iron : ForgePal.gold
        // Pomo.
        o.rect(cx - 1, 0, 3, 2, metal[3]); o.put(cx - 1, 0, metal[5]); o.put(cx + 1, 1, metal[1])
        if style % 4 == 2 { o.put(cx, 1, ForgePal.ruby[3], glow: 120) }
        // Puño con tiras de cuero.
        for y in 2..<7 {
            o.put(cx - 1, y, (y % 2 == 0) ? lt[4] : lt[2]); o.put(cx, y, lt[3]); o.put(cx + 1, y, lt[1])
        }
        // Guarda.
        o.hline(0, 7, w, metal[4]); o.hline(0, 8, w, metal[2])
        if style % 2 == 1 { o.put(0, 9, metal[2]); o.put(w - 1, 9, metal[1]) }
        o.put(cx, 7, metal[5])
        // Hoja.
        let start = 9, end = blade + 9
        for y in start..<end {
            let left = end - y
            if left <= 1 { o.put(cx, y, st[3]); continue }
            if left <= 3 { o.put(cx - 1, y, st[4]); o.put(cx, y, st[2]); continue }
            o.put(cx - 1, y, st[4]); o.put(cx, y, blade > 28 && y < end - 6 ? st[2] : st[3]); o.put(cx + 1, y, st[1])
        }
        o.put(cx - 1, start + 3 + style % 5, st[5])
        return o
    }

    static func axe(handle: Int, double: Bool) -> ForgeLayer {
        var o = ForgeLayer(15, handle)
        let hx = 7
        let w = ForgePal.wood, st = ForgePal.steel
        for y in 0..<handle { o.put(hx, y, w[4]); o.put(hx + 1, y, w[2]) }
        for y in stride(from: handle - 6, to: handle - 1, by: 2) { o.put(hx, y, ForgePal.leather[3]); o.put(hx + 1, y, ForgePal.leather[1]) }
        // Hoja barbada a la derecha (y a la izquierda si es doble).
        let profile = [3, 4, 5, 6, 6, 6, 5, 5, 4, 3]
        for (y, pw) in profile.enumerated() {
            for k in 0..<pw {
                let x = hx + 2 + k
                o.put(x, y + 1, k == pw - 1 ? st[5] : (k == pw - 2 ? st[3] : (y < 3 ? st[3] : st[2])))
            }
            if double {
                for k in 0..<pw {
                    let x = hx - 1 - k
                    o.put(x, y + 1, k == pw - 1 ? st[4] : (y < 3 ? st[3] : st[2]))
                }
            } else if y >= 2 && y <= 6 {
                o.put(hx - 1, y + 1, st[2])
            }
        }
        o.rect(hx, 0, 2, 12, ForgePal.iron[2]); o.put(hx, 0, ForgePal.iron[4])
        return o
    }

    static func warhammer(handle: Int) -> ForgeLayer {
        var o = ForgeLayer(9, handle)
        let w = ForgePal.wood, i = ForgePal.iron
        for y in 0..<handle { o.put(4, y, w[4]); o.put(5, y, w[2]) }
        o.rect(0, 3, 9, 6, i[3]); o.hline(0, 3, 9, i[5]); o.vline(0, 3, 6, i[4]); o.hline(0, 8, 9, i[1]); o.vline(8, 4, 5, i[1])
        o.hline(1, 5, 7, i[2]); o.put(4, 5, ForgePal.gold[3])
        o.rect(4, 0, 2, 3, i[3]); o.put(4, 0, i[5])
        for y in stride(from: handle - 7, to: handle - 1, by: 2) { o.put(4, y, ForgePal.leather[3]); o.put(5, y, ForgePal.leather[1]) }
        return o
    }

    static func roundShield(radius r: Int, paint: [UInt32], seed: Int) -> ForgeLayer {
        let d = 2 * r + 1
        var o = ForgeLayer(d, d)
        let c = Double(r) + 0.5
        for y in 0..<d {
            for x in 0..<d {
                let dx = Double(x) + 0.5 - c, dy = Double(y) + 0.5 - c
                let dist = (dx * dx + dy * dy).squareRoot()
                guard dist <= Double(r) + 0.3 else { continue }
                var col: UInt32
                if dist > Double(r) - 1.6 {
                    col = (dx + dy < -2) ? ForgePal.iron[4] : (dx + dy > 4 ? ForgePal.iron[1] : ForgePal.iron[3])
                    if (x + y) % 5 == 0 && dist > Double(r) - 1 { col = ForgePal.iron[5] }
                } else {
                    // Tablas verticales pintadas a franjas.
                    let plank = (x + 1) / 4
                    let painted = (plank + seed) % 2 == 0
                    let ramp = painted ? paint : ForgePal.wood
                    let lightK = (-dx - dy) / Double(2 * r)
                    col = self.ramp(ramp, 2 + Int((lightK * 2 + (TownArt.bayer(x, y) - 0.5) * 0.6).rounded()))
                    if (x + 1) % 4 == 0 { col = ramp[0] }
                }
                o.put(x, y, col)
            }
        }
        // Umbo central.
        o.disc(c, c, 2.6, 2.6, ForgePal.iron[3])
        o.put(r - 1, r - 1, ForgePal.iron[5]); o.put(r + 1, r + 1, ForgePal.iron[1])
        return o
    }

    static func heaterShield(paint: [UInt32], seed: Int) -> ForgeLayer {
        var o = ForgeLayer(15, 18)
        for y in 0..<18 {
            let inset = y < 9 ? 0 : (y - 8) * 7 / 9
            for x in inset..<(15 - inset) {
                let edge = x == inset || x == 14 - inset || y == 0 || y == 17
                let border = x <= inset + 1 || x >= 13 - inset || y <= 1
                var c: UInt32
                if edge { c = ForgePal.gold[1] } else if border { c = (x < 7 && y < 9) ? ForgePal.gold[4] : ForgePal.gold[2] } else {
                    let half = seed % 2 == 0 ? (x < 7) : (y < 8)
                    c = half ? paint[3] : paint[2]
                    if x < 5 && y < 6 { c = paint[4] }
                    if x > 10 || y > 12 { c = paint[1] }
                }
                o.put(x, y, c)
            }
        }
        // Martillo de oro en el centro.
        o.rect(5, 5, 5, 2, ForgePal.gold[4]); o.vline(7, 7, 5, ForgePal.gold[3]); o.put(7, 5, ForgePal.gold[5])
        return o
    }

    static func bladeBlank(length: Int, width: Int) -> ForgeLayer {
        var o = ForgeLayer(width, length)
        let i = ForgePal.iron
        o.put(width / 2, 0, i[2]); o.put(width / 2, 1, i[1])  // agujero de colgar
        for y in 2..<6 { o.put(width / 2, y, i[2]) }  // espiga
        for y in 6..<length {
            let left = length - y
            for x in 0..<width {
                if left <= 2 && (x == 0 || x == width - 1) && width > 2 { continue }
                o.put(x, y, x == 0 ? i[5] : (x == width - 1 ? i[2] : i[3]))
            }
        }
        if length > 10 { o.put(0, 8, ForgePal.steel[5]) }
        return o
    }

    static func guardPiece(width: Int, curved: Bool) -> ForgeLayer {
        var o = ForgeLayer(width, 5)
        let gd = curved ? ForgePal.iron : ForgePal.gold
        o.put(width / 2, 0, ForgePal.iron[3])
        o.hline(0, 2, width, gd[4]); o.hline(0, 3, width, gd[2])
        o.rect(width / 2 - 1, 1, 3, 4, gd[3])
        if curved { o.put(0, 4, gd[2]); o.put(width - 1, 4, gd[2]) } else { o.put(0, 1, gd[3]); o.put(width - 1, 1, gd[3]) }
        return o
    }

    static func gripPiece(length: Int, seed: Int) -> ForgeLayer {
        var o = ForgeLayer(3, length)
        let lt = seed % 2 == 0 ? ForgePal.leather : ForgePal.wood
        for y in 0..<length {
            o.put(0, y, y % 2 == 0 ? lt[4] : lt[3]); o.put(1, y, lt[2]); o.put(2, y, lt[1])
        }
        o.hline(0, 0, 3, ForgePal.gold[3]); o.hline(0, length - 1, 3, ForgePal.gold[2])
        return o
    }

    static func pommel(_ r: [UInt32]) -> ForgeLayer {
        var o = ForgeLayer(4, 5)
        o.put(1, 0, ForgePal.iron[3])
        o.rect(0, 1, 4, 4, r[3]); o.put(0, 1, r[5]); o.hline(0, 4, 4, r[1]); o.vline(3, 2, 3, r[1])
        return o
    }

    static func chain(_ L: inout ForgeLayer, _ x: Int, _ y0: Int, _ y1: Int) {
        var o = ForgeLayer(3, max(1, y1 - y0))
        var y = 0
        var k = 0
        while y < o.h {
            if k % 2 == 0 {
                o.put(0, y, ForgePal.iron[4]); o.put(2, y, ForgePal.iron[2])
                o.put(0, y + 1, ForgePal.iron[3]); o.put(2, y + 1, ForgePal.iron[1])
                o.put(1, y - 1 < 0 ? 0 : y - 1, ForgePal.iron[4]); o.put(1, y + 2, ForgePal.iron[2])
            } else {
                o.put(1, y, ForgePal.iron[3]); o.put(1, y + 1, ForgePal.iron[3])
            }
            y += 3
            k += 1
        }
        // Gancho al final.
        o.put(1, o.h - 1, ForgePal.iron[4])
        L.place(o, x, y0, shadow: (2, 1, 0.6))
        var hook = ForgeLayer(4, 4)
        hook.vline(1, 0, 3, ForgePal.iron[3]); hook.hline(1, 3, 3, ForgePal.iron[2]); hook.put(3, 2, ForgePal.iron[4])
        L.place(hook, x, y1, shadow: (2, 1, 0.6))
    }

    /// Farolillo colgado de la viga (ilumina un poco la parte de la derecha).
    static func lantern(_ L: inout ForgeLayer, _ g: ForgeGeo, _ x: Int) {
        let top = g.floorY - 66
        var rope = ForgeLayer(1, max(1, top - g.beamY - 8))
        for y in 0..<rope.h { rope.put(0, y, y % 2 == 0 ? ForgePal.iron[3] : ForgePal.iron[1]) }
        L.place(rope, x, g.beamY + 8, shadow: (2, 1, 0.6))
        var o = ForgeLayer(9, 13)
        let i = ForgePal.iron, fire = ForgePal.fire
        o.put(4, 0, i[3]); o.rect(2, 1, 5, 2, i[3]); o.hline(2, 1, 5, i[4])
        o.rect(1, 3, 7, 8, i[2])
        o.rect(2, 4, 5, 6, fire[3], glow: 255)
        o.rect(3, 5, 3, 4, fire[5], glow: 255)
        o.put(4, 6, fire[6], glow: 255)
        o.vline(4, 3, 8, i[1])
        o.vline(1, 3, 8, i[4])
        o.rect(0, 11, 9, 2, i[3]); o.hline(0, 12, 9, i[1])
        L.place(o, x - 4, top, shadow: (2, 1, 0.6))
    }
}

extension ForgeLayer {
    /// Gira 45° aproximado (para espadas cruzadas): cada fila se desplaza una columna.
    func rotatedDiag() -> ForgeLayer {
        var out = ForgeLayer(w + h / 2 + 1, h)
        for y in 0..<h {
            for x in 0..<w where px[y * w + x] != nil {
                let tx = x + (h - 1 - y) / 2
                out.put(tx, y, px[y * w + x]!, glow: glow[y * w + x])
            }
        }
        return out
    }
}
