import Foundation
import GameCore

/// Acantilados (tapa y cara en 3/4, como los muros de la mazmorra), muros en ruinas y columnas del claustro.
extension TownArt {
    static let rockLine: UInt32 = 0x221C1E

    struct CliffPalette {
        var face: [UInt32]
        var cap: [UInt32]
        var lip: [UInt32]
        var snow: Bool
    }

    static func cliffPalette(_ mood: FieldMood) -> CliffPalette {
        if mood == .pass {
            return CliffPalette(face: [0x30343F, 0x434957, 0x575E6E, 0x6D7486, 0x868DA0], cap: [0x4E5262, 0x60667A, 0x767C90, 0x8C92A4],
                                lip: [0xC6D2DE, 0xE2EAF2, 0xF6FAFC], snow: true)
        }
        return CliffPalette(face: [0x382E29, 0x4C4038, 0x605349, 0x76685B, 0x8C7D6D], cap: [0x5A4E44, 0x6C5E52, 0x7E7062, 0x908272],
                            lip: [0x55682F, 0x6E8438, 0x8CA04A], snow: false)
    }

    // MARK: - Acantilados

    static func fieldCliffs(_ g: inout PixelGrid, _ ctx: FieldContext) {
        let T = tile
        for y in 0..<ctx.h {
            for x in 0..<ctx.w where ctx.tile(x, y) == .cliff {
                let P = cliffPalette(ctx.mood(x, y))
                let ox = x * T, oy = y * T
                let face = ctx.tile(x, y + 1) != .cliff
                let openU = ctx.tile(x, y - 1) != .cliff
                let openL = ctx.tile(x - 1, y) != .cliff, openR = ctx.tile(x + 1, y) != .cliff
                let capRows = face ? (openU ? 6 : 0) : T
                for ly in 0..<T {
                    for lx in 0..<T {
                        let px = ox + lx, py = oy + ly
                        var c: UInt32
                        if ly < capRows {
                            c = cliffCapColor(px, py, P)
                            if openU && ly == 0 { c = rockLine } else if openU && ly == 1 { c = P.snow ? 0xFFFFFF : light(c, 1.12) }
                            if openL && lx == 0 { c = rockLine } else if openL && lx == 1 && ly > 0 { c = light(c, 1.1) }
                            if openR && lx == T - 1 { c = rockLine } else if openR && lx == T - 2 && ly > 0 { c = dark(c, 0.78) }
                        } else {
                            c = rockFaceColor(px, py, P.face)
                            let fy = ly - capRows, fh = T - capRows
                            if fy > fh - 6 { c = dark(c, 0.86) }
                            if fy > fh - 3 { c = dark(c, 0.86) }
                            if openL { if lx == 0 { c = rockLine } else if lx < 3 { c = light(c, 1.1) } }
                            if openR { if lx == T - 1 { c = rockLine } else if lx > T - 5 { c = dark(c, 0.76) } }
                        }
                        g[px, py] = c
                    }
                }
                guard face else { continue }
                // Bajo una tapa, la cara sube 8 pixeles más (se lee como un cortado alto)
                let rise = openU ? 0 : 8
                if rise > 0 {
                    let openLU = ctx.tile(x - 1, y - 1) != .cliff, openRU = ctx.tile(x + 1, y - 1) != .cliff
                    for py in (oy - rise)..<oy {
                        for lx in 0..<T {
                            let px = ox + lx
                            var c = rockFaceColor(px, py, P.face)
                            if (openL || openLU) { if lx == 0 { c = rockLine } else if lx < 3 { c = light(c, 1.1) } }
                            if (openR || openRU) { if lx == T - 1 { c = rockLine } else if lx > T - 5 { c = dark(c, 0.76) } }
                            g[px, py] = c
                        }
                    }
                }
                // Labio de hierba (o nieve) que cuelga del borde de arriba y sombra debajo
                let lipY = oy + capRows - rise
                for lx in 0..<T {
                    let px = ox + lx
                    let hang = 1 + hash(px / 2, y, 186) % 3 + (hash(px, y, 187) % 7 == 0 ? 2 : 0)
                    for k in 0..<hang {
                        if openL && lx == 0 || openR && lx == T - 1 { break }
                        g[px, lipY + k] = P.lip[k == 0 ? 2 : (k == hang - 1 ? 0 : 1)]
                    }
                    if let c = g[px, lipY + hang] { g[px, lipY + hang] = dark(c, 0.6) }
                    if let c = g[px, lipY + hang + 1] { g[px, lipY + hang + 1] = dark(c, 0.8) }
                }
                hline(&g, ox, oy + T - 1, T, dark(P.face[0], 0.8))
                // Cascotes al pie
                for i in 0..<3 {
                    let h = hash(x, y, 188 + i)
                    let sx = ox + 2 + h % (T - 6), sy = oy + T - 1 + (h >> 5) % 3
                    let w = 2 + (h >> 8) % 3
                    fill(&g, sx - 1, sy - 1, w + 2, 3, rockLine)
                    hline(&g, sx, sy - 1, w, P.face[3]); hline(&g, sx, sy, w, P.face[2])
                    g[sx + w - 1, sy] = P.face[1]
                }
            }
        }
    }

    static func cliffCapColor(_ px: Int, _ py: Int, _ P: CliffPalette) -> UInt32 {
        let n = noise(Double(px) / 7, Double(py) / 6, 181) * 0.6 + noise(Double(px) / 2.5, Double(py) / 2.5, 182) * 0.4
        if P.snow {
            let rockN = noise(Double(px) / 14, Double(py) / 11, 183) * 0.8 + noise(Double(px) / 4, Double(py) / 4, 194) * 0.2
            if rockN > 0.75 { return tone(P.cap, n * 1.3 - 0.15 + (rockN - 0.75) * 2, px, py) }
            if rockN > 0.72 { return 0xA8B4C4 }
            let soft = noise(Double(px) / 16, Double(py) / 12, 195)
            return tone([0xC4D0DE, 0xD4DEEA, 0xE2EAF2, 0xF0F4FA], soft * 1.3 - 0.1, px, py, dither: 0.2)
        }
        let grassN = noise(Double(px) / 11, Double(py) / 9, 184)
        if grassN > 0.66 {
            if hash(px, py, 189) % 23 == 0 { return 0xA8B460 }
            return tone([0x4A5A2E, 0x5A6A36, 0x6A7A40, 0x7A8A4A], n * 1.3 - 0.15 + (grassN - 0.66), px, py, dither: 0.3)
        }
        var c = tone(P.cap, n * 1.3 - 0.15, px, py, dither: 0.3)
        let k = noise(Double(px) / 8, Double(py) / 8, 185)
        if abs(k - 0.5) < 0.02 { c = P.cap[0] } else if abs(k - 0.5) < 0.04 && (px + py) % 2 == 0 { c = light(c, 1.08) }
        return c
    }

    /// Roca de la cara del acantilado: bloques en estratos (celdas), con luz arriba a la izquierda y grietas.
    static func rockFaceColor(_ px: Int, _ py: Int, _ tones: [UInt32]) -> UInt32 {
        let cw = 13, ch = 9
        let cx = px / cw, cy = py / ch
        var best = 1e9, second = 1e9, bx = 0, by = 0, rx = 0.0, ry = 0.0
        for j in -1...1 {
            for i in -1...1 {
                let gx = cx + i, gy = cy + j
                let h = hash(gx, gy, 190)
                let fx = Double(gx * cw) + 1.5 + Double(h % 10)
                let fy = Double(gy * ch) + 1.0 + Double((h >> 4) % 7)
                let dx = (Double(px) - fx) * 0.9, dy = (Double(py) - fy) * 0.8
                let d = dx * dx + dy * dy
                if d < best { second = best; best = d; bx = gx; by = gy; rx = dx; ry = dy } else if d < second { second = d }
            }
        }
        let edge = second.squareRoot() - best.squareRoot()
        if edge < 0.8 { return tones[0] }
        let h = hash(bx, by, 191)
        var i = 2 + (h % 3 == 0 ? -1 : (h % 3 == 1 ? 0 : 1))
        let lit = -(rx + ry)
        if edge < 1.8 { i += lit > 0 ? 1 : -1 } else if lit > 2.5 && hash(px, py, 192) % 3 != 0 { i += 1 }
        if noise(Double(px) / 5, Double(py) / 3, 193) > 0.72 { i -= 1 }
        // Vetas verticales de la roca
        let streak = noise(Double(px) / 1.6, Double(py) / 14, 196)
        if streak > 0.74 { i -= 1 } else if streak < 0.2 && edge > 2.5 { i += 1 }
        return tones[max(0, min(tones.count - 1, i))]
    }

    // MARK: - Muros en ruinas (abadía)

    static let ruinTones: [UInt32] = [0x4E4A56, 0x625E6A, 0x76727E, 0x8A8692, 0x9E9AA6, 0xB2AEB8]
    static let ruinLine: UInt32 = 0x26222C

    static func ruinedWallTile(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let isW: (Int, Int) -> Bool = { ctx.tile($0, $1) == .wall }
        if isW(x, y + 1) {
            ruinedWallTop(&g, ox, oy, topEnd: !isW(x, y - 1), seed: hash(x, y, 801))
            return
        }
        let leftEnd = !isW(x - 1, y), rightEnd = !isW(x + 1, y)
        let fromAbove = isW(x, y - 1)
        let x0 = leftEnd ? ox + 1 : ox, x1 = rightEnd ? ox + T - 1 : ox + T
        let bottom = oy + T - 1
        for px in x0..<x1 {
            // Altura del muro en esta columna: irregular, con mellas y extremos derrumbados
            var hgt = 27 + Int((noise(Double(px) / 9, Double(y) * 3.1, 802) - 0.5) * 18)
            if hash(px / 5, y, 803) % 7 == 0 { hgt -= 8 }
            if leftEnd { hgt -= max(0, 9 - (px - x0)) * 2 }
            if rightEnd { hgt -= max(0, 9 - (x1 - 1 - px)) * 2 }
            hgt = max(9, hgt)
            var topY = bottom - hgt
            if fromAbove && px >= ox + 3 && px < ox + T - 3 { topY = min(topY, oy - 1) }
            let capEnd = topY + 5
            for py in topY...bottom {
                var c: UInt32
                if py < capEnd {
                    // Lomo del muro visto desde arriba: piedras sueltas, musgo
                    let n = noise(Double(px) / 3, Double(py) / 2, 804)
                    c = n > 0.62 ? (hash(px, py, 805) % 2 == 0 ? 0x5E7A3E : 0x4E6A36) : tone(Array(ruinTones[2...5]), n * 1.2, px, py)
                    if py == capEnd - 1 { c = ruinTones[1] }
                } else {
                    c = ruinStoneColor(px, py - capEnd, seed: y)
                    if py > bottom - 5 && noise(Double(px) / 3, Double(py) / 2, 806) > 0.5 { c = hash(px, py, 807) % 2 == 0 ? 0x4E6A36 : 0x5E7A42 }
                    if py > bottom - 3 { c = dark(c, 0.85) }
                    if py < capEnd + 2 { c = dark(c, 0.8) }
                }
                if leftEnd && px < x0 + 2 { c = light(c, 1.08) }
                if rightEnd && px > x1 - 3 { c = dark(c, 0.78) }
                g[px, py] = c
            }
            g[px, topY - 1] = ruinLine
            // Hiedra que cuelga del borde
            let ivy = noise(Double(px) / 6, Double(y) * 2.3, 808)
            if ivy > 0.6 {
                let len = 4 + Int((ivy - 0.6) * 60) + hash(px, y, 809) % 4
                for k in 0..<len where hash(px, topY + k, 810) % 4 != 0 {
                    let py = topY + 2 + k
                    guard py < bottom - 1 else { break }
                    g[px, py] = k % 3 == 0 ? 0x6EA046 : (px % 2 == 0 ? 0x3E7A36 : 0x2E5E2C)
                }
            }
        }
        if leftEnd { vline(&g, x0 - 1, oy + 4, T - 4, ruinLine) }
        if rightEnd { vline(&g, x1, oy + 4, T - 4, ruinLine) }
        hline(&g, x0, bottom, x1 - x0, ruinLine)
        // Cascotes caídos junto a los extremos
        if leftEnd { rubbleStone(&g, ox - 6, oy + T - 5, tones: Array(ruinTones[1...4])); rubbleStone(&g, ox - 3, oy + T, tones: Array(ruinTones[1...4])) }
        if rightEnd { rubbleStone(&g, ox + T + 1, oy + T - 4, tones: Array(ruinTones[1...4])) }
    }

    /// Mampostería del muro: hiladas de piedras irregulares, algunas caídas (huecos oscuros).
    static func ruinStoneColor(_ px: Int, _ fy: Int, seed: Int) -> UInt32 {
        let rowH = 5
        let row = fy / rowH, ly = fy % rowH
        let rw = 6 + hash(row, seed, 811) % 5
        let off = (row * 4 + hash(row, seed, 812)) % rw
        let lx = (px + off) % rw, col = (px + off) / rw
        let h = hash(col, row + seed * 31, 813)
        if h % 13 == 0 {
            // Piedra que falta
            if ly == rowH - 1 { return ruinTones[2] }
            return ly == 0 ? 0x1E1A22 : 0x2E2A34
        }
        if ly == rowH - 1 || lx == 0 { return 0x3E3A46 }
        var c = ruinTones[2 + h % 3]
        if ly == 0 { c = light(c, 1.07) } else if lx == rw - 1 || ly == rowH - 2 { c = dark(c, 0.88) }
        if h % 9 == 0 && lx == 2 + ly { c = dark(c, 0.76) }
        if hash(px, fy, 814) % 37 == 0 { c = 0x7A8A5A }                          // liquen
        return c
    }

    /// Tramo de muro que baja, visto desde arriba: lomo de mampuesto con musgo y una sombra a la derecha.
    static func ruinedWallTop(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, topEnd: Bool, seed: Int) {
        let T = tile
        let x0 = ox + 3, x1 = ox + T - 3
        for py in oy..<(oy + T) {
            for px in x0..<x1 {
                let row = (py + 1) / 4, ly = (py + 1) % 4
                let off = (row % 2) * 3
                let lx = (px - x0 + off) % 6
                let h = hash((px - x0 + off) / 6, row, seed % 97 + 815)
                var c = ruinTones[3 + h % 3]
                if ly == 3 || lx == 0 { c = ruinTones[1] } else if ly == 0 { c = light(c, 1.05) }
                if noise(Double(px) / 4, Double(py) / 4, 816) > 0.6 { c = hash(px, py, 817) % 2 == 0 ? 0x5E7A3E : 0x4A6634 }
                if px == x0 { c = ruinLine } else if px == x0 + 1 { c = light(c, 1.1) }
                if px == x1 - 1 { c = ruinLine } else if px == x1 - 2 { c = ruinTones[1] }
                g[px, py] = c
            }
        }
        if topEnd {
            // Remate de arriba: una cara corta con su labio
            fill(&g, x0, oy - 4, x1 - x0, 4, ruinTones[4])
            hline(&g, x0, oy - 5, x1 - x0, ruinLine)
            hline(&g, x0 + 1, oy - 4, x1 - x0 - 2, ruinTones[5])
        }
    }

    // MARK: - Columnas del claustro

    /// Columna de piedra con basa, fuste y capitel; muchas están rotas, con un tambor caído al lado.
    static func cloisterColumn(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, seed: Int, onSlab: Bool) {
        let tones: [UInt32] = [0x6A6672, 0x827E8A, 0x9A96A2, 0xB2AEBA, 0xCAC6D2, 0xE0DCE6]
        let state = seed % 5            // 0-1 entera, 2-3 rota a media altura, 4 tocón
        let S = 40
        var s = PixelGrid(width: 26, height: S)
        let cx = 12, baseY = S - 4
        let shaftTop: Int
        switch state {
        case 0, 1: shaftTop = baseY - 30
        case 2, 3: shaftTop = baseY - 13 - (seed >> 4) % 8
        default: shaftTop = baseY - 7
        }
        // Basa
        for py in (baseY - 4)...(baseY) {
            for px in (cx - 8)...(cx + 7) {
                var c = tones[2]
                if py == baseY - 4 { c = tones[5] } else if py == baseY - 3 { c = tones[4] }
                else if px > cx + 4 { c = tones[1] } else if px < cx - 6 { c = tones[3] }
                if py == baseY { c = tones[0] }
                s[px, py] = c
            }
        }
        // Fuste con estrías
        let shade: [Int] = [3, 4, 4, 3, 3, 2, 2, 1, 0]
        for py in shaftTop..<(baseY - 4) {
            for dx in -4...4 {
                var i = shade[dx + 4]
                if (dx == -2 || dx == 1) && py % 1 == 0 { i -= 1 }
                if hash(cx + dx, py, seed) % 19 == 0 { i -= 1 }
                s[cx + dx, py] = tones[max(0, min(5, i))]
            }
        }
        // Grieta
        if seed % 3 == 0 {
            var gx = cx - 1
            for py in stride(from: shaftTop + 3, to: baseY - 6, by: 1) where (py + seed) % 3 != 0 { s[gx, py] = tones[0]; if py % 4 == 0 { gx += 1 } }
        }
        if state <= 1 {
            // Capitel: collarino, cesta y ábaco
            for px in (cx - 5)...(cx + 5) { s[px, shaftTop] = tones[1] }
            for py in (shaftTop - 4)..<shaftTop {
                let w = 5 + (shaftTop - py)
                for px in (cx - w)...(cx + w - 1) { s[px, py] = px < cx - w + 2 ? tones[4] : (px > cx + w - 3 ? tones[1] : tones[3]) }
            }
            for py in (shaftTop - 7)..<(shaftTop - 4) {
                for px in (cx - 10)...(cx + 9) { s[px, py] = py == shaftTop - 7 ? tones[5] : (px > cx + 7 ? tones[1] : tones[3]) }
            }
            s[cx - 8, shaftTop - 3] = tones[5]; s[cx + 7, shaftTop - 3] = tones[2]          // volutas
        } else {
            // Rotura: cara de arriba irregular vista desde arriba
            for dx in -4...4 {
                let dip = hash(cx + dx, seed, 820) % 3 + (dx > 1 ? 1 : 0)
                for k in 0..<dip { s[cx + dx, shaftTop + k] = nil }
                s[cx + dx, shaftTop + dip] = tones[5]
                s[cx + dx, shaftTop + dip + 1] = tones[4]
            }
        }
        // Musgo en la basa y algo de hiedra
        for px in (cx - 8)...(cx + 7) where hash(px, seed, 821) % 3 == 0 { s[px, baseY - 1] = 0x5E7A3E }
        if seed % 4 == 1 {
            for py in stride(from: max(shaftTop + 2, baseY - 22), to: baseY - 4, by: 1) where hash(py, seed, 822) % 3 != 0 {
                s[cx + (py % 5 < 2 ? -3 : 2), py] = py % 2 == 0 ? 0x3E7A36 : 0x5E9A44
            }
        }
        let out = s.outlined(ruinLine)
        // Sombra hacia abajo a la derecha
        let gx = ox - 1, gy = oy + 23 - S
        for i in 0..<10 { tintRect(&g, ox + 12 + i, oy + 20 + i / 3, 6, 2, shadowF) }
        g.draw(out, x: gx, y: gy)
        if state >= 2 {
            // Tambor caído en el suelo
            let side = seed % 2 == 0 ? 1 : -1
            let dx = ox + 12 + side * 11 - 6, dy = oy + 19
            var d = PixelGrid(width: 12, height: 7)
            for py in 0..<7 { for px in 0..<12 { d[px, py] = py < 2 ? tones[4] : (py > 4 ? tones[1] : tones[2 + (px % 3 == 0 ? 1 : 0)]) } }
            for py in 1..<6 { d[side > 0 ? 0 : 11, py] = tones[3]; d[side > 0 ? 1 : 10, py] = tones[4] }
            tintRect(&g, dx + 2, dy + 7, 12, 2, shadowF)
            g.draw(d.outlined(ruinLine), x: dx, y: dy)
        }
        _ = onSlab
    }
}
