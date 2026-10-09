import Foundation
import GameCore

/// Objetos del campo pegados al suelo: rocas, lápidas y tótems, tiendas, hogueras y braseros, bajadas a mazmorra,
/// vallas (de granja, de cementerio y empalizadas) y arbustos. Cada uno es un pequeño sprite con contorno que se
/// pega en el suelo, con su sombra hacia abajo a la derecha.
extension TownArt {
    // MARK: - Rocas

    static func boulder(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let mood = ctx.mood(x, y), seed = hash(x, y, 830)
        var tones: [UInt32] = [0x4A4038, 0x5E5248, 0x74675A, 0x8A7C6C, 0xA09280]
        var topping: [UInt32]? = nil
        var lichen = false
        switch mood {
        case .forest, .road, .banditCamp, .river, .farm:
            tones = [0x3E4244, 0x52575A, 0x686E70, 0x80878A, 0x9AA0A2]; topping = [0x3A6430, 0x548A3A, 0x74A84A]
        case .frozen, .pass:
            tones = [0x3E4656, 0x525C6E, 0x687286, 0x80899C, 0x9AA2B4]; topping = [0xC4D0DE, 0xE2EAF2, 0xFFFFFF]
        case .graveyard, .cloister, .monkGarden:
            tones = [0x48444E, 0x5C5864, 0x726E7A, 0x8A8692, 0xA29EAA]; topping = [0x445E34, 0x56723C, 0x6E8A48]
        default:
            lichen = true
        }
        var s = PixelGrid(width: 26, height: 23)
        let rx = 9 + seed % 3, ry = 7 + (seed >> 3) % 2
        let cy = 21 - ry
        // Sombra en el suelo
        for yy in -3...3 { for xx in -12...12 where xx * xx * 9 + yy * yy * 144 <= 1296 { tint(&g, ox + 14 + xx, oy + 21 + yy, shadowF) } }
        ball(&s, 12, cy, rx, ry, tones, seed: seed, texture: 0.3)
        // Cara plana de arriba (más clara) y grietas
        for xx in -rx / 2...rx / 3 { if s[12 + xx - 2, cy - ry + 2] != nil { s[12 + xx - 2, cy - ry + 2] = tones[4] } }
        var kx = 12 + seed % 5 - 2
        for yy in (cy - ry + 3)..<(cy + 2) { s[kx, yy] = tones[0]; if (yy + seed) % 3 == 0 { kx += seed % 2 == 0 ? 1 : -1 } }
        if seed % 3 != 0 {
            let side = seed % 2 == 0 ? 1 : -1
            ball(&s, 12 + side * 8, 18, 5, 4, tones, seed: seed + 1, texture: 0.3)
        }
        if let top = topping {
            for yy in 0..<s.height {
                for xx in 0..<s.width where s[xx, yy] != nil && s[xx, max(0, yy - 1)] != nil {
                    let above = yy == 0 || s[xx, yy - 2] == nil || s[xx, yy - 1] == nil
                    let n = noise(Double(xx + ox) / 4, Double(yy + oy) / 3, seed % 50 + 831)
                    if (above || (yy < cy - ry / 3 && n > 0.45)) && yy < cy + 1 {
                        s[xx, yy] = top[above ? 2 : (n > 0.6 ? 1 : 0)]
                    }
                }
            }
        }
        if lichen {
            for i in 0..<5 { let h = hash(seed, i, 832); let px = 6 + h % 14, py = cy - 3 + (h >> 4) % 6; if s[px, py] != nil { s[px, py] = 0xB8B070 } }
        }
        g.draw(s.outlined(rockLine), x: ox - 1, y: oy)
    }

    // MARK: - Lápidas y tótems

    static func graveTile(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let mood = ctx.mood(x, y), seed = hash(x, y, 840)
        if mood == .orcCamp { orcTotem(&g, ox, oy, seed: seed); return }
        let L = fieldLooks[mood.rawValue]
        let abbey = mood == .graveyard || mood == .cloister || mood == .monkGarden
        let stone: [UInt32] = abbey ? [0x55515F, 0x6A6676, 0x827E8C, 0x9A96A4, 0xB4B0BC] : [0x5E584E, 0x746C60, 0x8A8274, 0xA09888, 0xB6AE9C]
        // Montículo de tierra delante de la lápida
        for yy in -3...3 {
            for xx in -9...9 where xx * xx * 9 + yy * yy * 81 <= 729 {
                let c = yy < -1 ? L.dirt[3] : (yy > 1 ? L.dirt[0] : L.dirt[1 + (hash(xx, yy, seed) % 2)])
                g[ox + 12 + xx, oy + 18 + yy] = c
            }
        }
        tintRect(&g, ox + 4, oy + 21, 18, 1, shadowF)
        if seed % 5 == 0 {
            // Flores secas o un ramito de ofrenda
            for i in 0..<3 { g[ox + 9 + i * 3, oy + 17] = [0xE8E0F0, 0xB898D8, 0xF2D25A][i]; g[ox + 9 + i * 3, oy + 18] = 0x3E5A32 }
        }
        var s = PixelGrid(width: 18, height: 26)
        let kind = (seed >> 4) % 4
        let base = 24
        func face(_ x0: Int, _ x1: Int, _ top: Int, round: Bool) {
            let w = x1 - x0, r = w / 2
            for yy in top...base {
                for xx in x0..<x1 {
                    if round && yy < top + r {
                        let dx = Double(xx - x0) - Double(w - 1) / 2, dy = Double(top + r - yy)
                        if dx * dx + dy * dy > Double(r * r) + 1 { continue }
                    }
                    var c = stone[2]
                    if xx < x0 + 2 { c = stone[3] } else if xx >= x1 - 2 { c = stone[1] }
                    if yy == base { c = stone[0] }
                    if yy > base - 4 && noise(Double(xx) / 2, Double(yy) / 2, seed % 31) > 0.5 { c = hash(xx, yy, seed) % 2 == 0 ? 0x4E6A36 : 0x5E7A42 }
                    if hash(xx, yy, seed + 1) % 17 == 0 { c = 0xA8A878 }
                    s[xx, yy] = c
                }
            }
            // Grosor (lado derecho) y canto de arriba iluminado
            for yy in (top + (round ? r / 2 : 0))...base { s[x1, yy] = stone[0] }
            for xx in (x0 + (round ? 2 : 0))..<(x1 - (round ? 2 : 0)) { if s[xx, top] != nil { s[xx, top] = stone[4] } }
        }
        switch kind {
        case 0:
            // Lápida redonda con una cruz grabada
            face(4, 14, 8, round: true)
            for yy in 12...17 { s[9, yy] = stone[0] }
            for xx in 7...11 { s[xx, 13] = stone[0] }
            s[8, 12] = stone[4]
        case 1:
            // Cruz de piedra
            for yy in 4...base { for xx in 7...10 { s[xx, yy] = xx == 7 ? stone[3] : (xx == 10 ? stone[1] : stone[2]) } }
            for yy in 8...11 { for xx in 3...14 { s[xx, yy] = yy == 8 ? stone[4] : (yy == 11 ? stone[1] : stone[2]) } }
            for yy in 5...base { s[11, yy] = stone[0] }
            s[7, 4] = stone[4]; s[8, 4] = stone[4]
            for yy in (base - 3)...base { for xx in 5...12 { s[xx, yy] = yy == base - 3 ? stone[3] : stone[1] } }
        case 2:
            // Piedra vieja, pequeña e inclinada
            face(5, 13, 13, round: true)
            var t = PixelGrid(width: 18, height: 26)
            for yy in 0..<26 { for xx in 0..<18 { if let c = s[xx, yy] { t[xx + (base - yy) / 6, yy] = c } } }
            s = t
            s[9, 18] = stone[0]; s[10, 18] = stone[0]
        default:
            // Lápida rota: falta el remate, que está en el suelo
            face(4, 14, 11, round: false)
            for xx in 4..<14 {
                let dip = hash(xx, seed, 841) % 3
                for k in 0..<dip { s[xx, 11 + k] = nil }
                s[xx, 11 + dip] = stone[4]
            }
            for yy in 15...17 { for xx in 7...11 where hash(xx, yy, seed) % 3 != 0 { s[xx, yy] = stone[1] } }
        }
        tintRect(&g, ox + 16, oy + 4, 3, 13, shadowF)
        g.draw(s.outlined(rockLine), x: ox + 3 - 1, y: oy + 17 - base - 1)
        if kind >= 3 {
            var p = PixelGrid(width: 8, height: 4)
            for yy in 0..<4 { for xx in 0..<8 { p[xx, yy] = yy == 0 ? stone[4] : (yy == 3 ? stone[0] : stone[2]) } }
            g.draw(p.outlined(rockLine), x: ox + (seed % 2 == 0 ? 15 : -2), y: oy + 18)
        }
    }

    /// Tótem orco: poste tallado con cara pintada de rojo, cráneo con cuernos y trapos; o estela con mano roja.
    static func orcTotem(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, seed: Int) {
        let wood: [UInt32] = [0x3A2418, 0x553822, 0x6E4A2C, 0x8A5E38, 0xA6764A]
        let red: UInt32 = 0xB0302A, redDark: UInt32 = 0x7A1E1C
        let bone: [UInt32] = [0x9A8E74, 0xC8BC9C, 0xEAE0C8, 0xFFF8E8]
        var s = PixelGrid(width: 24, height: 42)
        let base = 40
        // Piedras de la base
        for (dx, w) in [(3, 5), (9, 6), (15, 5)] {
            for yy in (base - 3)...base { for xx in dx..<(dx + w) { s[xx, yy] = yy == base - 3 ? 0x8A8278 : (xx == dx + w - 1 ? 0x4A4440 : 0x6A645C) } }
        }
        if seed % 2 == 0 {
            // Poste tallado
            for yy in 8..<(base - 2) {
                for xx in 9...14 { s[xx, yy] = xx == 9 ? wood[4] : (xx >= 13 ? wood[1] : wood[2 + (hash(xx, yy / 2, seed) % 2)]) }
            }
            // Cara tallada
            for yy in 16...27 { for xx in 7...16 { s[xx, yy] = yy == 16 ? wood[4] : (xx == 7 ? wood[3] : (xx >= 15 ? wood[0] : wood[2])) } }
            for xx in [9, 13] { s[xx, 19] = red; s[xx + 1, 19] = red; s[xx, 20] = 0x1A1010; s[xx + 1, 20] = 0x1A1010 }
            for xx in 9...14 { s[xx, 24] = redDark; if xx % 2 == 0 { s[xx, 23] = bone[2] } }
            for yy in 30...32 { for xx in 9...14 where (xx + yy) % 2 == 0 { s[xx, yy] = red } }
            // Cráneo con cuernos
            for yy in 2...9 { for xx in 8...15 where !((yy == 2 || yy == 9) && (xx == 8 || xx == 15)) { s[xx, yy] = xx < 10 ? bone[3] : (xx > 13 ? bone[1] : bone[2]) } }
            s[10, 5] = 0x1A1010; s[10, 6] = 0x1A1010; s[13, 5] = 0x1A1010; s[13, 6] = 0x1A1010; s[11, 8] = 0x3A2E24; s[12, 8] = 0x3A2E24
            for (k, (dx, dy)) in [(0, 0), (-1, -1), (-2, -2), (-3, -2), (-4, -1)].enumerated() { s[7 + dx, 4 + dy] = bone[k < 2 ? 2 : 1]; s[16 - dx, 4 + dy] = bone[k < 2 ? 1 : 0] }
            // Trapos y plumas que cuelgan de los cuernos
            for yy in 4...10 { s[3, yy] = yy % 3 == 0 ? 0x2A2A2A : red; s[20, yy + 1] = yy % 2 == 0 ? 0x2A2A2A : redDark }
        } else {
            // Estela de piedra con mano roja y runas
            for yy in 8..<(base - 2) {
                for xx in 6...17 {
                    if yy < 11 && (xx < 6 + (11 - yy) || xx > 17 - (11 - yy)) { continue }
                    var c: UInt32 = xx < 8 ? 0x9A948A : (xx > 15 ? 0x5E5850 : 0x7A746A)
                    if hash(xx, yy, seed) % 13 == 0 { c = 0x6A645A }
                    s[xx, yy] = c
                }
            }
            for (dx, dy) in [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (-1, -2), (0, -3), (1, -3), (2, -3), (3, -2), (3, 1)] { s[10 + dx, 17 + dy] = red }
            for yy in stride(from: 24, to: 34, by: 3) { for xx in 9...14 where hash(xx, yy, seed + 3) % 2 == 0 { s[xx, yy] = redDark } }
            for xx in 6...17 { s[xx, 8 + max(0, 3 - min(xx - 6, 17 - xx))] = 0xB4AEA2 }
        }
        tintRect(&g, ox + 17, oy + 6, 4, 15, shadowF)
        for i in 0..<8 { tintRect(&g, ox + 12 + i, oy + 20 + i / 3, 5, 1, shadowF) }
        g.draw(s.outlined(rockLine), x: ox - 1, y: oy + 21 - base - 1)
    }

    // MARK: - Tiendas

    static func tentTile(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let mood = ctx.mood(x, y), seed = hash(x, y, 850)
        // Sombra en el suelo
        for i in 0..<10 { tintRect(&g, ox + 2 + i, oy + 20 + i / 3, 26, 1, shadowF) }
        switch mood {
        case .orcCamp:
            g.draw(hideTent(seed: seed).outlined(rockLine), x: ox - 4, y: oy - 7)
        case .monkGarden, .graveyard, .cloister:
            g.draw(ridgeTent(canvas: [0x241C34, 0x362A4E, 0x4C3E6C, 0x64568A], patch: nil, eclipse: true, seed: seed).outlined(rockLine), x: ox - 4, y: oy - 5)
        default:
            g.draw(ridgeTent(canvas: [0x5E4A30, 0x7E6644, 0x9C8258, 0xB89E70], patch: [0x6A5A76, 0x8A7894][seed % 2], eclipse: false, seed: seed).outlined(rockLine), x: ox - 4, y: oy - 5)
        }
        // Vientos (cuerdas) y estacas
        let rope: UInt32 = 0xC8B48A
        line(&g, ox + 3, oy + 2, ox - 3, oy + 21, rope)
        line(&g, ox + 26, oy + 1, ox + 29, oy + 18, rope)
        for (sx, sy) in [(ox - 4, oy + 20), (ox + 29, oy + 17)] { fill(&g, sx, sy, 2, 3, 0x5A3A22); g[sx, sy] = 0x8A5A34 }
    }

    /// Tienda de lona a dos aguas vista de frente y de lado: hastial con la puerta abierta y el faldón derecho en sombra.
    static func ridgeTent(canvas: [UInt32], patch: UInt32?, eclipse: Bool, seed: Int) -> PixelGrid {
        var s = PixelGrid(width: 32, height: 30)
        let ax = 12, ay = 2, base = 27
        // Faldón del lado (al fondo a la derecha)
        for yy in 0...base {
            for xx in ax...31 {
                // Entre la arista delantera (ax..ax+12) y la trasera desplazada (+9, -3)
                let front = ax + (yy - ay) * 12 / (base - ay)
                let backTop = ay - 2
                guard yy >= backTop else { continue }
                let back = ax + 8 + (yy - backTop) * 12 / (base - backTop)
                guard xx >= front && xx <= back + 1 && yy >= ay - 2 + (xx - ax) * 0 else { continue }
                let ridge = Double(xx - ax) * 0.25
                guard Double(yy) >= Double(ay) - ridge else { continue }
                var c = canvas[1]
                if (xx - front) % 6 == 0 { c = canvas[0] }                  // costuras
                if yy > base - 2 { c = canvas[0] }
                if let p = patch, xx > front + 3 && xx < front + 9 && yy > 13 && yy < 19 { c = (xx + yy) % 4 == 0 ? dark(p, 0.8) : p }
                s[xx, yy] = c
            }
        }
        // Hastial delantero
        for yy in ay...base {
            let hw = (yy - ay) * 11 / (base - ay)
            for xx in (ax - hw)...(ax + hw) {
                var c = canvas[2]
                if xx < ax - hw + 2 { c = canvas[3] } else if xx > ax + hw - 2 { c = canvas[1] }
                if yy > base - 2 { c = canvas[1] }
                s[xx, yy] = c
            }
        }
        // Puerta abierta con la solapa recogida
        for yy in (ay + 9)...base {
            let hw = (yy - ay - 9) * 5 / (base - ay - 9)
            for xx in (ax - hw)...(ax + hw) { s[xx, yy] = yy > base - 3 ? 0x2A2018 : 0x140E10 }
            s[ax - hw - 1, yy] = canvas[3]
        }
        for yy in (ay + 12)...(base - 4) { s[ax + 3 + (yy - ay - 12) / 3, yy] = canvas[3] }
        // Palo de la cumbrera
        s[ax, ay - 1] = 0x5A3A22; s[ax, ay - 2] = 0x8A5A34
        if eclipse {
            // Símbolo del Eclipse en el faldón: luna pálida tapada por un disco oscuro
            let cx = ax + 11, cy = 15
            for yy in -3...3 { for xx in -3...3 where xx * xx + yy * yy <= 10 { s[cx + xx, cy + yy] = 0xD8D0EA } }
            for yy in -3...3 { for xx in -3...3 where (xx - 1) * (xx - 1) + (yy + 1) * (yy + 1) <= 6 { s[cx + xx, cy + yy] = 0x1A1424 } }
            s[cx - 2, cy + 2] = 0xB89AF0
        }
        return s
    }

    /// Tienda orca de pieles en cono, con los palos asomando, banda pintada de rojo, huesos y piel en el borde.
    static func hideTent(seed: Int) -> PixelGrid {
        var s = PixelGrid(width: 32, height: 31)
        let hide: [UInt32] = [0x4A3220, 0x654430, 0x80583C, 0x9C7048, 0xB48A5C]
        let cx = 15, top = 5, base = 28
        for yy in top...base {
            let hw = 2 + (yy - top) * 13 / (base - top)
            for xx in (cx - hw)...(cx + hw) {
                let u = Double(xx - cx) / Double(hw)
                var i = Int((0.62 - u * 0.45) * 5)
                if hash(xx / 3, yy / 4, seed) % 5 == 0 { i -= 1 }
                // Costuras en abanico
                if abs(Double(xx - cx) - Double(yy - top) * 0.45) < 0.6 || abs(Double(xx - cx) + Double(yy - top) * 0.45) < 0.6 { i = 0 }
                var c = hide[max(0, min(4, i))]
                if yy >= 17 && yy <= 19 { c = (xx + yy) % 3 == 0 ? 0x6A1A16 : 0xA02C24 }   // banda roja
                if yy > base - 2 { c = (xx % 2 == 0) ? 0x3A2A1E : 0x5A4630 }              // piel del borde
                s[xx, yy] = c
            }
        }
        // Puerta
        for yy in (base - 9)...(base - 1) {
            let hw = 1 + (yy - (base - 9)) / 3
            for xx in (cx - hw)...(cx + hw) { s[xx, yy] = 0x140E0C }
        }
        // Palos que asoman
        for (dx, k) in [(-3, 0), (0, 1), (3, 2)] {
            for i in 0..<6 { s[cx + dx * (6 - i) / 6 + (k - 1), top - i + 1] = i % 2 == 0 ? 0x6E4A2C : 0x8A5E38 }
        }
        // Huesos colgados
        for bx in [cx - 7, cx + 6] {
            for yy in 12...14 { s[bx, yy] = 0x6A5A44 }
            s[bx - 1, 15] = 0xEAE0C8; s[bx, 15] = 0xEAE0C8; s[bx + 1, 15] = 0xEAE0C8; s[bx, 16] = 0xC8BC9C
        }
        return s
    }

    // MARK: - Hogueras y braseros

    enum CampfireKind { case camp, brazier, eclipse }

    static func campfireKind(_ ctx: FieldContext, _ x: Int, _ y: Int) -> CampfireKind {
        campfireKind(ctx.mood(x, y))
    }

    static func campfireKind(_ mood: FieldMood) -> CampfireKind {
        switch mood {
        case .orcCamp: return .brazier
        case .monkGarden: return .eclipse
        default: return .camp
        }
    }

    /// Base de la hoguera (piedras, troncos y brasas) o del brasero. La llama animada va encima (`campfireFlame`).
    static func campfireBase(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, kind: CampfireKind, seed: Int) {
        let cx = ox + 12, cy = oy + 16
        if kind == .brazier {
            // Brasero de hierro sobre tres patas
            let iron: [UInt32] = [0x1E1E26, 0x2E2E3A, 0x4A4A5A, 0x6E6E82]
            for i in 0..<8 { tintRect(&g, cx - 2 + i, oy + 21 + i / 3, 8, 1, shadowF) }
            line(&g, cx - 6, oy + 21, cx - 3, oy + 12, iron[1]); line(&g, cx + 6, oy + 21, cx + 3, oy + 12, iron[0]); line(&g, cx, oy + 22, cx, oy + 13, iron[2])
            g[cx - 7, oy + 21] = rockLine; g[cx + 7, oy + 21] = rockLine
            for yy in -3...3 {
                for xx in -8...8 where xx * xx * 9 + yy * yy * 64 <= 576 {
                    g[cx + xx, oy + 10 + yy] = yy < 0 ? (xx < 0 ? iron[3] : iron[2]) : (xx < -3 ? iron[2] : (xx > 3 ? iron[0] : iron[1]))
                }
            }
            for xx in -6...6 { g[cx + xx, oy + 8] = hash(xx, seed, 851) % 3 == 0 ? 0xFFD060 : (xx % 2 == 0 ? 0xE0602A : 0x9A2A1A) }
            for xx in -5...5 { g[cx + xx, oy + 7] = hash(xx, seed, 852) % 2 == 0 ? 0xF08A30 : 0x5A2A1A }
            hline(&g, cx - 8, oy + 13, 17, rockLine)
            // Cráneos de adorno en el borde
            for sx in [cx - 6, cx + 4] { fill(&g, sx, oy + 10, 3, 2, 0xEAE0C8); g[sx, oy + 11] = 0x2A1A14; g[sx + 2, oy + 11] = 0x2A1A14 }
            return
        }
        let eclipse = kind == .eclipse
        // Lecho de ceniza
        for yy in -4...4 {
            for xx in -9...9 where xx * xx * 16 + yy * yy * 81 <= 1296 {
                g[cx + xx, cy + yy] = hash(xx, yy, seed) % 5 == 0 ? 0x6A645E : (yy < 0 ? 0x2E2824 : 0x221C1A)
            }
        }
        // Troncos cruzados, quemados por la punta
        let logs: [((Int, Int), (Int, Int))] = [((-7, 3), (6, -2)), ((-6, -2), (7, 3))]
        for (a, b) in logs {
            for t in 0...12 {
                let px = cx + a.0 + (b.0 - a.0) * t / 12, py = cy + a.1 + (b.1 - a.1) * t / 12
                let charred = t > 4 && t < 9
                g[px, py - 1] = charred ? 0x3A2A22 : 0x9A6A3E
                g[px, py] = charred ? 0x221814 : 0x6E4A2C
                g[px, py + 1] = 0x3A2418
            }
        }
        // Brasas
        let embers: [UInt32] = eclipse ? [0x6A2AA8, 0xA060F0, 0xE0C8FF] : [0xB8301A, 0xF07A2A, 0xFFD060]
        for i in 0..<9 { let h = hash(seed, i, 853); g[cx - 4 + h % 9, cy - 1 + (h >> 4) % 3] = embers[(h >> 8) % 3] }
        // Llamita fija (la animada la tapa)
        for (dx, dy, k) in [(0, -2, 1), (-1, -2, 0), (1, -3, 1), (0, -3, 2), (0, -4, 2), (-1, -4, 1), (0, -5, 2)] as [(Int, Int, Int)] { g[cx + dx, cy + dy] = embers[k] }
        // Corro de piedras (las de delante tapan los troncos)
        let stoneTones: [UInt32] = eclipse ? [0x2A2434, 0x3E3650, 0x564C6C, 0x6E648A] : [0x4A4440, 0x6A645C, 0x8A847A, 0xAAA498]
        for i in 0..<11 {
            let a = Double(i) / 11 * 2 * Double.pi + Double(seed % 7) * 0.1
            let sx = cx + Int((cos(a) * 10).rounded()), sy = cy + Int((sin(a) * 5).rounded())
            fill(&g, sx - 2, sy - 1, 5, 4, rockLine)
            fill(&g, sx - 1, sy, 3, 2, stoneTones[1]); hline(&g, sx - 1, sy, 2, stoneTones[3]); g[sx + 1, sy + 1] = stoneTones[0]
            if eclipse && i % 3 == 0 { g[sx, sy] = 0xC890FF }
        }
    }

    // MARK: - Bajada a mazmorra

    /// Escalera de piedra que baja hacia el fondo (arriba en pantalla), con brocal de sillares y paredes que se
    /// estrechan con la profundidad. En la abadía, resplandor violeta desde abajo; en el pueblo (calabozos), penumbra cálida.
    static func caveStairs(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, width W: Int, violet: Bool, seed: Int) {
        let T = tile
        let x0 = ox + 1, x1 = ox + W - 1, y0 = oy - 5, y1 = oy + T - 1
        let frame: [UInt32] = [0x4A4652, 0x6A6672, 0x8E8A96, 0xB2AEBA, 0xD0CCD6]
        let deep: UInt32 = violet ? 0x140A24 : 0x120E0C
        let glow: UInt32 = violet ? 0x8A52E0 : 0xA0602A
        // Sombra alrededor y brocal
        tintRect(&g, x1 + 1, y0 + 3, 3, y1 - y0, shadowF)
        for py in y0...y1 {
            for px in x0..<x1 {
                let inX = px - x0, inY = py - y0
                let fx = min(inX, x1 - 1 - px), fy = min(inY, y1 - py)
                guard fx < 3 || fy < 3 else { continue }
                var c: UInt32
                if fy < 3 && inY < 3 {
                    c = inY == 0 ? frame[4] : (inY == 1 ? frame[3] : frame[1])          // borde de atrás (lo vemos desde arriba)
                } else if fy < 3 {
                    c = py == y1 ? frame[0] : (py == y1 - 1 ? frame[2] : frame[4])     // borde de delante
                } else {
                    c = inX < 3 ? (inX == 0 ? frame[3] : frame[4]) : (px == x1 - 1 ? frame[1] : frame[2])
                }
                if (fy < 3 ? (px - x0) % 8 == 0 : (py - y0) % 7 == 0) { c = frame[0] }
                if hash(px, py, seed) % 23 == 0 { c = 0x5E7A3E }                        // musgo
                g[px, py] = c
            }
        }
        hline(&g, x0, y0 - 1, x1 - x0, rockLine); vline(&g, x0 - 1, y0, y1 - y0 + 1, rockLine); vline(&g, x1, y0, y1 - y0 + 1, rockLine)
        // Hueco
        let ix0 = x0 + 3, ix1 = x1 - 3, iy0 = y0 + 3, iy1 = y1 - 2
        let H = iy1 - iy0
        let steps = 4, stepH = max(3, (H - 6) / steps)
        for py in iy0..<iy1 {
            let fromNear = iy1 - 1 - py
            let depth = Double(fromNear) / Double(H)                            // 0 delante, 1 al fondo
            let inset = Int(depth * 7)
            for px in ix0..<ix1 {
                var c: UInt32
                let lx = px - ix0, rx = ix1 - 1 - px
                if lx < inset || rx < inset {
                    // Paredes laterales que se estrechan: la izquierda en sombra, la derecha iluminada
                    let left = lx < inset
                    let base: UInt32 = left ? 0x3E3A48 : 0x76727E
                    c = mix(base, deep, depth * 0.7)
                    if (py - iy0) % 5 == 0 || (left ? lx : rx) == inset - 1 { c = dark(c, 0.75) }
                } else if fromNear >= steps * stepH {
                    // El fondo: oscuridad con el resplandor
                    let t = Double(fromNear - steps * stepH) / Double(max(1, H - steps * stepH))
                    c = mix(glow, deep, min(1, 0.35 + t * 1.2 + (bayer(px, py) - 0.5) * 0.3))
                } else {
                    let k = fromNear / stepH, ry = fromNear % stepH
                    let f = Double(k) / Double(steps)
                    let stone: UInt32 = [0xA6A2AC, 0x9C98A4, 0xAEAAB4][hash(px / 6, k, seed) % 3]
                    c = mix(stone, deep, 0.05 + f * 0.7)
                    if ry == stepH - 1 { c = mix(c, 0xF0ECF4, 0.35 - f * 0.25) }        // canto del peldaño
                    else if ry == 0 { c = mix(c, deep, 0.7) }                            // sombra del peldaño siguiente
                    if violet { c = mix(c, glow, f * 0.14) }
                    if hash(px, py, seed + 3) % 17 == 0 { c = dark(c, 0.85) }
                }
                g[px, py] = c
            }
        }
        if violet {
            // Losa de la tapa, rota y apartada a un lado
            let lx = x1 + 2, ly = oy + 8
            tintRect(&g, lx + 2, ly + 10, 16, 3, shadowF)
            var lid = PixelGrid(width: 16, height: 10)
            for yy in 0..<10 { for xx in 0..<16 where !(xx > 10 && yy < xx - 10) {
                lid[xx, yy] = yy < 3 ? frame[4] : (yy > 7 ? frame[1] : frame[3]); if xx == 6 + yy / 3 { lid[xx, yy] = frame[0] } } }
            g.draw(lid.outlined(rockLine), x: lx, y: ly)
            for i in 0..<5 { let h = hash(seed, i, 854); g[ix0 + 7 + h % max(1, ix1 - ix0 - 14), iy0 + (h >> 5) % 4] = i % 2 == 0 ? 0xD8B8FF : 0xA878F0 }
        }
    }

    // MARK: - Vallas

    static func fieldFence(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let isF: (Int, Int) -> Bool = { ctx.tile($0, $1) == .fence }
        let L = isF(x - 1, y), R = isF(x + 1, y), U = isF(x, y - 1), D = isF(x, y + 1)
        let mood = ctx.mood(x, y), seed = hash(x, y, 860)
        switch mood {
        case .graveyard, .cloister, .monkGarden:
            ironFence(&g, ox, oy, L: L, R: R, U: U, D: D, seed: seed)
        case .banditCamp, .orcCamp:
            palisade(&g, ox, oy, L: L, R: R, U: U, D: D, orc: mood == .orcCamp, seed: seed)
        default:
            farmFence(&g, ox, oy, L: L, R: R, D: D, charred: mood == .burnt, seed: seed)
        }
        _ = T
    }

    static func farmFence(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, L: Bool, R: Bool, D: Bool, charred: Bool, seed: Int) {
        let T = tile
        let wood: [UInt32] = charred ? [0x1E1814, 0x2E2620, 0x463A30, 0x5E4E40] : [0x5A3A22, 0x7A4A28, 0xA06838, 0xC88E56]
        let px = ox + 10
        let x0 = L ? ox : px, x1 = R ? ox + T : px + 4
        if L || R {
            tintRect(&g, x0 + 2, oy + 19, x1 - x0, 2, shadowF)
            for (k, ry) in [oy + 9, oy + 14].enumerated() {
                if charred && hash(seed, k, 861) % 3 == 0 { continue }        // travesaño caído
                fill(&g, x0, ry - 1, x1 - x0, 4, objLine)
                fill(&g, x0, ry, x1 - x0, 2, wood[2])
                hline(&g, x0, ry, x1 - x0, wood[3])
            }
        }
        if D {
            tintRect(&g, px + 4, oy + 8, 3, T, shadowF)
            fill(&g, px, oy + 7, 4, T + 1, objLine)
            fill(&g, px + 1, oy + 8, 2, T - 1, wood[2]); vline(&g, px + 1, oy + 8, T - 1, wood[3])
        }
        // Poste
        tintRect(&g, px + 4, oy + 6, 2, 14, shadowF)
        fill(&g, px - 1, oy + 3, 6, 17, objLine)
        fill(&g, px, oy + 4, 4, 15, wood[1])
        vline(&g, px, oy + 4, 15, wood[3]); vline(&g, px + 3, oy + 4, 15, wood[0])
        g[px + 1, oy + 3] = wood[2]; g[px + 2, oy + 3] = wood[2]
        if seed % 3 == 0 { g[px + 2, oy + 12] = wood[0] }
        if charred && seed % 2 == 0 { fill(&g, px, oy + 4, 4, 3, 0x14100E) }
    }

    /// Verja de cementerio: barrotes de hierro con puntas de lanza entre pilares de piedra.
    static func ironFence(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, L: Bool, R: Bool, U: Bool, D: Bool, seed: Int) {
        let T = tile
        let iron: [UInt32] = [0x16161E, 0x26262F, 0x3E3E4C, 0x60606E]
        let px = ox + 9
        if L || R {
            let x0 = L ? ox : px, x1 = R ? ox + T : px + 6
            tintRect(&g, x0 + 2, oy + 20, x1 - x0, 2, shadowF)
            for ry in [oy + 7, oy + 17] { hline(&g, x0, ry, x1 - x0, iron[1]); hline(&g, x0, ry - 1, x1 - x0, iron[3]) }
            var bx = x0 + 1
            while bx < x1 {
                let missing = hash(bx, seed, 862) % 13 == 0
                if !missing {
                    let bent = hash(bx, seed, 863) % 9 == 0 ? 1 : 0
                    for yy in (oy + 4)...(oy + 19) { g[bx + (yy < oy + 9 ? bent : 0), yy] = yy % 5 == 0 ? iron[2] : iron[1] }
                    g[bx + bent, oy + 3] = iron[3]; g[bx - 1 + bent, oy + 4] = iron[2]; g[bx + 1 + bent, oy + 4] = iron[0]
                }
                bx += 3
            }
        }
        if D {
            for yy in (oy + 8)..<(oy + T + 8) {
                g[px + 2, yy] = iron[1]; g[px + 3, yy] = iron[2]
                if yy % 3 == 0 { g[px + 1, yy] = iron[3]; g[px + 4, yy] = iron[0] }
            }
        }
        // Pilar de piedra en esquinas, extremos y cada tres casillas
        let pillar = !(L && R) || U || D || (ox / T) % 3 == 0
        if pillar {
            let stone: [UInt32] = [0x4A4652, 0x6A6672, 0x8A8692, 0xA8A4B0, 0xC4C0CA]
            tintRect(&g, px + 6, oy + 4, 3, 17, shadowF)
            fill(&g, px - 1, oy, 8, 21, ruinLine)
            fill(&g, px, oy + 3, 6, 17, stone[2])
            vline(&g, px, oy + 3, 17, stone[3]); vline(&g, px + 5, oy + 3, 17, stone[1])
            for yy in stride(from: oy + 7, to: oy + 20, by: 5) { hline(&g, px, yy, 6, stone[1]) }
            fill(&g, px - 1, oy, 8, 3, stone[4]); hline(&g, px - 1, oy + 2, 8, stone[1])
            g[px + 2, oy - 1] = stone[3]; g[px + 3, oy - 1] = stone[2]; hline(&g, px + 1, oy - 2, 4, ruinLine)
            if seed % 2 == 0 { g[px + 1, oy + 17] = 0x5E7A3E; g[px + 2, oy + 18] = 0x4E6A36; g[px + 4, oy + 16] = 0x5E7A3E }
        }
    }

    /// Empalizada de troncos afilados con cuerdas; la de los orcos, con puntas rojas y algún cráneo.
    static func palisade(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, L: Bool, R: Bool, U: Bool, D: Bool, orc: Bool, seed: Int) {
        let T = tile
        let bark: [UInt32] = [0x3A2618, 0x553820, 0x70492A, 0x8C5E36, 0xA87848]
        func log(_ x: Int, _ w: Int, top: Int, bottom: Int, k: Int, rope: Bool = true) {
            for yy in top...bottom {
                let narrow = yy - top < 3 ? (3 - (yy - top)) : 0
                let l0 = x + narrow / 2 + (narrow > 1 ? 1 : 0), l1 = x + w - 1 - narrow / 2
                guard l0 <= l1 else { continue }
                for xx in l0...l1 {
                    var c = bark[2 + hash(xx, yy / 3, k) % 2]
                    if xx == l0 { c = bark[4] } else if xx == l1 { c = bark[0] } else if xx == l1 - 1 { c = bark[1] }
                    if yy - top < 3 { c = orc && k % 2 == 0 ? 0xA8302A : (xx == l0 ? 0xD8B888 : 0xB89468) }   // punta (madera clara o pintada)
                    g[xx, yy] = c
                }
                g[l0 - 1, yy] = rockLine; g[l1 + 1, yy] = rockLine
            }
            g[x + w / 2, top - 1] = rockLine
            if rope { hline(&g, x, bottom - 9, w, 0xC4A874); hline(&g, x, bottom - 8, w, 0x8A7048) }   // cuerda
        }
        if L || R || !(U || D) {
            tintRect(&g, ox + 2, oy + 21, T, 3, shadowF)
            let x0 = L ? ox : ox + 6, x1 = R ? ox + T : ox + 18
            var lx = x0
            var k = 0
            while lx < x1 {
                let w = 5
                let top = oy - 4 - hash(lx, seed, 864) % 5
                log(lx, w, top: top, bottom: oy + 21, k: hash(lx, oy, 865))
                lx += w; k += 1
            }
        }
        if D || U {
            tintRect(&g, ox + 18, oy, 4, T + 4, shadowF)
            let start = U ? oy - 6 : oy
            var ly = start
            while ly <= oy + (D ? T - 6 : 0) {
                log(ox + 6, 11, top: ly - 4 - hash(ly, seed, 866) % 3, bottom: ly + 21, k: hash(ox, ly, 867), rope: false)
                ly += 6
            }
        }
        if orc && seed % 5 == 0 {
            // Cráneo clavado
            let sx = ox + 9, sy = oy + 2
            fill(&g, sx - 1, sy - 1, 8, 7, rockLine)
            fill(&g, sx, sy, 6, 5, 0xE6DCC4); hline(&g, sx, sy, 6, 0xFFF8E8); vline(&g, sx + 5, sy, 5, 0xB8AC90)
            g[sx + 1, sy + 2] = 0x1A1010; g[sx + 4, sy + 2] = 0x1A1010; g[sx + 2, sy + 4] = 0x4A3A2A; g[sx + 3, sy + 4] = 0x4A3A2A
        }
    }

    // MARK: - Arbustos

    static func fieldBush(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let mood = ctx.mood(x, y), seed = hash(x, y, 503)
        let leaves: [UInt32]
        var berries: UInt32? = nil
        switch mood {
        case .graveyard, .cloister, .monkGarden:
            leaves = [0x1E2E22, 0x2A3E2C, 0x3A5236, 0x4E6844, 0x6A8458]; berries = 0x6A2A5A
        case .pass, .frozen:
            leaves = [0x1A3436, 0x24484A, 0x34605E, 0x4C7C76, 0x74A49A]; berries = 0x5A6AC8
        case .forest, .road, .banditCamp, .wolfDen:
            leaves = [0x163C26, 0x205232, 0x2E6A3A, 0x46864A, 0x6AA45A]; berries = seed % 2 == 0 ? 0xD8343C : nil
        case .burnt, .slopes, .orcCamp:
            leaves = [0x3A4024, 0x4E5630, 0x66703A, 0x828C4A, 0xA0AA62]
        default:
            bush(&g, ox, oy, planter: false, seed: seed); return
        }
        for yy in -4...4 { for xx in -11...11 where xx * xx * 16 + yy * yy * 121 <= 1936 { tint(&g, ox + 14 + xx, oy + 20 + yy, shadowF) } }
        let base = oy + 16
        let clumps: [(Int, Int, Int, Int)] = [(6, -2, 5, 4), (17, -2, 5, 4), (11, -5, 7, 5), (8, -7, 4, 3), (15, -7, 4, 3)]
        for (dx, dy, rx, ry) in clumps { ellipse(&g, ox + dx, base + dy, rx + 1, ry + 1, objLine) }
        for (dx, dy, rx, ry) in clumps { ball(&g, ox + dx, base + dy, rx, ry, leaves, seed: seed, texture: 0.4) }
        if let c = berries {
            for i in 0..<6 { let h = hash(seed, i, 7); g[ox + 5 + h % 14, base - 9 + (h >> 5) % 8] = c }
        }
        if mood == .graveyard || mood == .cloister {
            // Ramas secas que asoman
            line(&g, ox + 4, base - 6, ox + 1, base - 11, 0x4A3A30); line(&g, ox + 19, base - 8, ox + 23, base - 13, 0x4A3A30)
        }
    }
}
