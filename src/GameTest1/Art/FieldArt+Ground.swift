import Foundation
import GameCore

/// Suelo del campo: hierba por ambiente, caminos de tierra con bordes que se funden, losas del claustro,
/// río, estanques y pozas heladas, puentes, mieses y maleza, y la bruma de las salidas.
extension TownArt {
    // MARK: - Materiales

    /// Ruido de borde (-0.35...0.35) para que orillas y caminos no sean rectos.
    static func wobble(_ px: Int, _ py: Int, _ s: Int) -> Double {
        (noise(Double(px) / 6, Double(py) / 6, s) - 0.5) * 0.5 + (noise(Double(px) / 2.5, Double(py) / 2.5, s + 1) - 0.5) * 0.2
    }

    static func fieldMaterials(_ g: inout PixelGrid, _ mat: inout [UInt8], _ ctx: FieldContext) {
        let T = tile, W = g.width, Hpx = g.height
        for y in 0..<ctx.h {
            for x in 0..<ctx.w {
                let i = y * ctx.w + x
                let t = ctx.tiles[i]
                let mood = ctx.moods[i]
                if t == .cliff {
                    for ly in 0..<T {
                        let row = (y * T + ly) * W + x * T
                        for lx in 0..<T { mat[row + lx] = FieldMaterial.cliff.rawValue }
                    }
                    continue
                }
                let ownWater = t == .water || t == .bridge
                let ownDirt = t == .dirt || t == .areaExit
                let ownSlab = ctx.slabField[i] > 0
                let grassy = !ownWater && !ownDirt && !ownSlab
                let nw = ctx.nearWater[i], nd = ctx.nearDirt[i], ns = ctx.nearSlab[i]
                var mixed = false
                for dy in -2...2 { for dx in -2...2 where ctx.mood(x + dx, y + dy) != mood { mixed = true } }
                let wet: (Tile) -> Bool = { $0 == .water || $0 == .bridge }
                let flowsDown = wet(ctx.tile(x, y - 1)) && wet(ctx.tile(x, y + 1))
                let here = fieldLooks[mood.rawValue]
                for ly in 0..<T {
                    let py = y * T + ly
                    for lx in 0..<T {
                        let px = x * T + lx
                        var m = FieldMaterial.grass
                        var depth = 99.0
                        if nw && (ownWater || grassy) {
                            let th = ownWater ? 0.44 : 0.56
                            let v = ctx.sample(ctx.waterField, px, py) + wobble(px, py, 61) * 0.55
                            if v > th { m = .water; depth = (v - th) * Double(T) }
                        }
                        if m == .grass && nd && !ownSlab {
                            let v = ctx.sample(ctx.dirtField, px, py) + wobble(px, py, 71) * 0.75
                            if v > (ownDirt ? 0.46 : 0.54) { m = .dirt }
                        }
                        if m == .grass && ns {
                            let v = ctx.sample(ctx.slabField, px, py) + wobble(px, py, 81) * 0.9
                            if v > (ownSlab ? 0.30 : 0.72) { m = .slab }
                        }
                        var pmood = mood
                        if mixed {
                            let jx = Int((noise(Double(px) / 14, Double(py) / 14, 17) - 0.5) * 64)
                            let jy = Int((noise(Double(px) / 14 + 40, Double(py) / 14, 17) - 0.5) * 64)
                            pmood = ctx.mood((px + jx) / T, (py + jy) / T)
                        }
                        let L = mixed ? fieldLooks[pmood.rawValue] : here
                        let c: UInt32
                        switch m {
                        case .grass:
                            let bias = pmood == .pass ? max(0, 0.22 - Double(py) / Double(Hpx) * 0.45) : 0
                            c = fieldGrassColor(px, py, L, bias: bias)
                        case .dirt: c = fieldDirtColor(px, py, L)
                        case .water: c = fieldWaterColor(px, py, depth, pmood, flowsDown: flowsDown)
                        case .slab: c = cloisterSlabColor(px, py)
                        case .cliff: c = 0
                        }
                        g.pixels[py * W + px] = c
                        mat[py * W + px] = m.rawValue
                    }
                }
            }
        }
    }

    /// Hierba de un ambiente con briznas sueltas y manchas (seca, ceniza, hojarasca, escarcha, nieve).
    static func fieldGrassColor(_ px: Int, _ py: Int, _ L: FieldLook, bias: Double) -> UInt32 {
        if hash(px, py, 13) % 41 == 0 { return L.bladeDark }
        if hash(px, py + 1, 13) % 41 == 0 { return L.grass[3] }
        let n = noise(Double(px) / 13, Double(py) / 9, 11) * 0.62 + noise(Double(px) / 4.5, Double(py) / 3.5, 12) * 0.38
        let amount = L.patchAmount + bias
        if amount > 0.01 {
            let m = noise(Double(px) / 30, Double(py) / 22, 15) * 0.8 + noise(Double(px) / 7, Double(py) / 6, 16) * 0.2
            let edge = 0.74 - amount * 1.1
            if m > edge || (m > edge - 0.025 && bayer(px, py) > 0.5) {
                let pc = tone(L.patch, (n - 0.5) * 1.3 + 0.45 + (m - edge) * 1.6, px, py, dither: 0.3)
                let gc = tone(L.grass, (n - 0.5) * 1.5 + 0.5, px, py, dither: 0.3)
                return mix(pc, gc, m - edge < 0.03 ? 0.6 : 0.3)
            }
        }
        return tone(L.grass, (n - 0.5) * 1.5 + 0.5, px, py, dither: 0.3)
    }

    static func fieldDirtColor(_ px: Int, _ py: Int, _ L: FieldLook) -> UInt32 {
        let h = hash(px, py, 23) % 61
        if h == 0 { return L.dirt[4] }
        if h == 1 { return L.dirt[0] }
        let n = noise(Double(px) / 12, Double(py) / 8, 21) * 0.7 + noise(Double(px) / 3.5, Double(py) / 2.5, 22) * 0.3
        return tone(L.dirt, (n - 0.5) * 1.1 + 0.55, px, py, dither: 0.22)
    }

    static func isMurky(_ mood: FieldMood) -> Bool { mood == .graveyard || mood == .cloister || mood == .monkGarden }

    /// Agua del río y los estanques (en la abadía, turbia); en las pozas del Pedregal, hielo.
    static func fieldWaterColor(_ px: Int, _ py: Int, _ depth: Double, _ mood: FieldMood, flowsDown: Bool) -> UInt32 {
        if mood == .frozen { return iceColor(px, py, depth) }
        let murky = isMurky(mood)
        if depth < 1.2 { return murky ? 0x4A4438 : (hash(px, py, 62) % 3 == 0 ? 0x7E7662 : 0x948A72) }   // orilla de barro y piedra
        if depth < 2.2 { return murky ? 0x36403A : 0x5E6A5E }                                             // borde mojado
        if depth < 3.2 {                                                                                   // espuma
            if murky { return (px + py) % 2 == 0 ? 0x5E7A70 : 0x3E5E5A }
            return (px + py) % 2 == 0 ? 0xCDEBFA : 0x6FB0E2
        }
        let deep: [UInt32] = murky ? [0x1E3C40, 0x24464A, 0x2A5054] : [0x2A66A6, 0x3170B2, 0x387CBE]
        var c: UInt32 = depth < 6 ? (murky ? 0x325A58 : 0x4A90CA) : tone(deep, noise(Double(px) / 10, Double(py) / 6, 63), px, py, dither: 0.3)
        // Corriente (a lo largo del río) o reflejos (en los estanques)
        let streak = flowsDown ? noise(Double(px) / 1.8, Double(py) / 9, 64) : noise(Double(px) / 8, Double(py) / 1.6, 64)
        if streak > 0.8 { c = murky ? 0x4E7470 : 0x86C4EE } else if streak > 0.74 { c = murky ? 0x3A625E : 0x5FA2DA }
        if hash(px, py, 65) % 211 == 0 { c = murky ? 0x8AA8A0 : 0xFFFFFF }
        return c
    }

    /// Hielo de las pozas: nieve en la orilla, grietas, reflejos y algún ojo de agua abierta.
    static func iceColor(_ px: Int, _ py: Int, _ depth: Double) -> UInt32 {
        if depth < 1.6 { return hash(px, py, 69) % 4 == 0 ? 0xD8E4EE : 0xEEF4F8 }
        if depth < 3 { return (px + py) % 2 == 0 ? 0xF6FAFC : 0xC8DCE8 }
        if depth > 13 && noise(Double(px) / 7, Double(py) / 6, 68) > 0.74 {
            return depth > 12.5 ? tone([0x1E4A74, 0x285A86, 0x346A96], noise(Double(px) / 5, Double(py) / 3, 70), px, py) : 0xA8C8E0
        }
        let n = noise(Double(px) / 9, Double(py) / 6, 66)
        var c = tone([0x86AECC, 0x98BED8, 0xACCCE4, 0xC2DCEE], n * 1.2 - 0.15 + min(0.25, depth / 40), px, py, dither: 0.3)
        let k = noise(Double(px) / 7, Double(py) / 7, 67)
        if abs(k - 0.5) < 0.016 { c = 0x5A82A4 } else if abs(k - 0.5) < 0.032 && (px + py) % 2 == 0 { c = 0xE2F0FA }
        if (px - py * 2 + 4000) % 41 < 2 && noise(Double(px) / 12, Double(py) / 12, 72) > 0.55 { c = 0xF0F8FF }
        return c
    }

    /// Losas viejas del claustro: juntas con musgo, grietas, losas hundidas y huecos con hierbajos.
    static func cloisterSlabColor(_ px: Int, _ py: Int) -> UInt32 {
        // Losas irregulares (celdas de Voronoi grandes), gastadas y con musgo en las juntas
        let cw = 16, ch = 11
        let cx = px / cw, cy = py / ch
        var best = 1e9, second = 1e9, bx = 0, by = 0, rx = 0.0, ry = 0.0
        for j in -1...1 {
            for i in -1...1 {
                let gx = cx + i, gy = cy + j
                let h = hash(gx, gy, 140)
                let fx = Double(gx * cw) + 2 + Double(h % 12)
                let fy = Double(gy * ch) + 1.5 + Double((h >> 4) % 8)
                let dx = (Double(px) - fx) * 0.72, dy = Double(py) - fy
                let d = dx * dx + dy * dy
                if d < best { second = best; best = d; bx = gx; by = gy; rx = dx; ry = dy } else if d < second { second = d }
            }
        }
        let edge = second.squareRoot() - best.squareRoot()
        let h = hash(bx, by, 143)
        if h % 19 == 0 && edge > 1.2 {
            // Losa que falta: tierra y hierbajos
            let n = noise(Double(px) / 3, Double(py) / 3, 148)
            return n > 0.55 ? (hash(px, py, 149) % 3 == 0 ? 0x6E8A50 : 0x4E6A36) : (n > 0.38 ? 0x4A4232 : 0x3A3428)
        }
        if edge < 1.0 {
            if noise(Double(px) / 6, Double(py) / 6, 144) > 0.5 { return hash(px, py, 145) % 2 == 0 ? 0x5E7040 : 0x4C5E36 }
            return 0x6A6458
        }
        let tones: [UInt32] = [0x9A9486, 0xA39D8E, 0xACA696, 0x948E80, 0xB2AC9C]
        var c = tones[h % tones.count]
        let lit = -(rx + ry)
        if edge < 2 { c = lit > 0 ? light(c, 1.05) : dark(c, 0.9) }
        if h % 7 == 0 && abs(Double(px - bx * cw) * 0.8 - Double(py - by * ch) * 1.3 - 4) < 0.7 { c = dark(c, 0.78) }   // grieta
        if h % 11 == 0 { c = dark(c, 0.92) }
        let n = noise(Double(px) / 8, Double(py) / 7, 146)
        if n > 0.66 { c = mix(c, 0x5A6A48, min(0.45, (n - 0.66) * 3)) }
        if hash(px, py, 147) % 71 == 0 { c = dark(c, 0.86) }
        return c
    }

    // MARK: - Bordes

    /// La hierba es un poco más alta que el camino y las losas: canto oscuro arriba, briznas que cuelgan,
    /// barro (o nieve) en la orilla del agua.
    static func fieldEdges(_ g: inout PixelGrid, _ mat: [UInt8], _ ctx: FieldContext) {
        let W = g.width, H = g.height, T = tile
        let grass = FieldMaterial.grass.rawValue, dirt = FieldMaterial.dirt.rawValue
        let water = FieldMaterial.water.rawValue, slab = FieldMaterial.slab.rawValue
        for py in 2..<(H - 2) {
            for px in 2..<(W - 2) {
                let i = py * W + px
                let m = mat[i]
                guard let c = g.pixels[i] else { continue }
                if m == dirt {
                    if mat[i - W] == grass { g.pixels[i] = dark(c, 0.72) }
                    else if mat[i - 2 * W] == grass { g.pixels[i] = dark(c, 0.86) }
                    else if mat[i + W] == grass && hash(px, py, 91) % 3 != 0 { g.pixels[i] = dark(c, 0.92) }
                    else if mat[i - 1] == grass || mat[i + 1] == grass { g.pixels[i] = dark(c, 0.9) }
                    if mat[i - W] == water || mat[i + W] == water || mat[i - 1] == water || mat[i + 1] == water { g.pixels[i] = dark(c, 0.7) }
                } else if m == slab {
                    let up = mat[i - W], down = mat[i + W]
                    if up == grass || up == dirt { g.pixels[i] = dark(c, 0.76) }
                    else if down == grass || down == dirt { g.pixels[i] = dark(c, 0.66) }
                    else if mat[i + 2 * W] == grass || mat[i + 2 * W] == dirt { g.pixels[i] = dark(c, 0.84) }
                } else if m == grass {
                    let mood = ctx.mood(px / T, py / T)
                    let L = fieldLooks[mood.rawValue]
                    let nearWater1 = mat[i - W] == water || mat[i + W] == water || mat[i - 1] == water || mat[i + 1] == water
                    let nearWater2 = mat[i - 2 * W] == water || mat[i + 2 * W] == water || mat[i - 2] == water || mat[i + 2] == water
                    if nearWater1 || (nearWater2 && (px + py) % 2 == 0) {
                        if mood == .frozen { g.pixels[i] = nearWater1 ? 0xE6EEF4 : 0xC8D8E0 }
                        else { g.pixels[i] = nearWater1 ? L.dirt[0] : dark(c, 0.8) }
                        continue
                    }
                    if (mat[i + W] == dirt || mat[i + W] == slab) && hash(px, py, 92) % 3 == 0 {
                        g.pixels[i] = L.bladeLight
                        if hash(px, py, 93) % 3 == 0 { g.pixels[i + W] = L.bladeDark }
                    }
                }
            }
        }
    }

    // MARK: - Detalles por casilla

    static func fieldTileDetails(_ g: inout PixelGrid, _ mat: [UInt8], _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T, W = g.width, H = g.height
        let t = ctx.tile(x, y)
        let mood = ctx.mood(x, y)
        let L = fieldLooks[mood.rawValue]
        var rng = SeededGenerator(seed: UInt64(hash(x, y, 77)))
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a..<b, using: &rng) }
        func one(_ n: Int) -> Bool { n > 0 && Int.random(in: 0..<n, using: &rng) == 0 }
        func matAt(_ px: Int, _ py: Int) -> UInt8 { px >= 0 && py >= 0 && px < W && py < H ? mat[py * W + px] : 255 }
        func putG(_ px: Int, _ py: Int, _ c: UInt32) { if matAt(px, py) == FieldMaterial.grass.rawValue { g[px, py] = c } }
        func putD(_ px: Int, _ py: Int, _ c: UInt32) { if matAt(px, py) == FieldMaterial.dirt.rawValue { g[px, py] = c } }

        switch t {
        case .cliff, .water, .bridge, .tallGrass, .wall, .cave:
            return
        case .plaza, .pillar where ctx.slabField[y * ctx.w + x] > 0:
            // Hierbajos entre las losas y cascotes
            for _ in 0..<r(1, 4) {
                let px = ox + r(2, T - 2), py = oy + r(3, T - 1)
                g[px, py] = 0x4E6A3A; g[px - 1, py - 1] = 0x6E8A50; g[px + 1, py - 1] = 0x5E7A44
            }
            if one(4) { rubbleStone(&g, ox + r(3, T - 6), oy + r(4, T - 4), tones: [0x5E5A54, 0x7E7A72, 0x9E9A90, 0xBAB6AC]) }
            return
        case .dirt, .areaExit:
            // Piedrecitas
            for _ in 0..<r(0, 4) {
                let px = ox + r(2, T - 3), py = oy + r(2, T - 2)
                putD(px, py, L.dirt[4]); putD(px + 1, py, L.dirt[3]); putD(px, py + 1, L.dirt[0]); putD(px + 1, py + 1, L.dirt[0])
            }
            // Grietas en la tierra seca
            if [.slopes, .burnt, .orcCamp, .wolfDen].contains(mood) && one(3) {
                var px = ox + r(3, T - 8), py = oy + r(3, T - 6)
                for _ in 0..<r(4, 8) { putD(px, py, L.dirt[0]); px += 1; if one(2) { py += one(2) ? 1 : -1 } }
            }
            // Charco con el cielo reflejado
            if [.farm, .river, .forest, .road, .banditCamp, .graveyard, .monkGarden, .pass].contains(mood) && one(26) {
                puddle(&g, ox + r(8, T - 8), oy + r(7, T - 5), rx: r(4, 7), mud: L.dirt[0])
            }
            // Huellas de cascos o de botas
            if [.road, .farm, .river, .pass, .slopes].contains(mood) && one(5) {
                let px = ox + r(3, T - 8), py = oy + r(3, T - 6)
                for k in 0..<3 { putD(px + k * 3, py + (k % 2) * 3, L.dirt[0]); putD(px + k * 3 + 1, py + (k % 2) * 3, L.dirt[1]) }
            }
            // Hojarasca, ceniza, nieve, huesos
            switch mood {
            case .forest, .road, .banditCamp, .wolfDen:
                if one(2) { leafLitter(ox + r(3, T - 4), oy + r(3, T - 4), count: r(2, 5), seed: hash(x, y, 78), only: putD) }
            case .burnt:
                for _ in 0..<r(2, 7) { putD(ox + r(1, T - 1), oy + r(1, T - 1), one(3) ? 0x3A3430 : 0x8E8880) }
            case .pass where y < ctx.h / 2:
                for _ in 0..<r(2, 8) { let px = ox + r(1, T - 2), py = oy + r(1, T - 1); putD(px, py, 0xE8EEF4); putD(px + 1, py, 0xC8D4E0) }
            case .orcCamp:
                if one(12) { bone(ox + r(4, T - 8), oy + r(5, T - 4), only: putD) }
            default: break
            }
            if one(7) { fieldTuft(ox + r(3, T - 3), oy + r(4, T - 1), L, big: false, only: putD) }
            return
        default:
            break
        }

        // Hierba (y bajo objetos: lo que asome alrededor)
        let tufts = [.forest, .banditCamp].contains(mood) ? r(1, 4) : r(2, 6)
        for _ in 0..<tufts {
            fieldTuft(ox + r(2, T - 2), oy + r(3, T), L, big: one(3), only: putG)
        }
        if [.farm, .river, .road].contains(mood) && one(3) {
            let px = ox + r(3, T - 3), py = oy + r(3, T - 3)
            for (dx, dy) in [(0, 0), (1, 0), (-1, 1), (0, 1), (1, 1), (2, 1), (0, 2)] where hash(px + dx, py + dy, 3) % 4 != 0 { putG(px + dx, py + dy, L.grass[0]) }
            putG(px, py, L.grass[4])
        }
        let pebbleOdds = [.slopes, .wolfDen, .pass, .frozen, .cloister].contains(mood) ? 2 : 5
        if one(pebbleOdds) { fieldPebble(ox + r(3, T - 4), oy + r(3, T - 3), L, big: one(3), only: putG) }
        if t == .flowers {
            let palettes: [(UInt32, UInt32)] = L.flowers.isEmpty
                ? [(0xF6F2EA, 0xF6D45A)]
                : L.flowers.map { ($0, $0 == 0xF6D45A || $0 == 0xF2D25A ? 0xE89A30 : 0xFFF0A0) }
            for _ in 0..<r(4, 7) {
                let px = ox + r(2, T - 2), py = oy + r(2, T - 2)
                let (petal, heart) = palettes[r(0, palettes.count)]
                putG(px - 1, py + 2, L.bladeDark); putG(px + 1, py + 2, L.bladeDark); putG(px, py + 2, L.bladeLight)
                putG(px - 1, py, petal); putG(px + 1, py, petal); putG(px, py - 1, petal)
                putG(px, py + 1, dark(petal, 0.8)); putG(px, py, heart)
            }
        } else if !L.flowers.isEmpty && one(L.flowerOdds) {
            let px = ox + r(2, T - 2), py = oy + r(2, T - 2)
            putG(px, py + 1, L.bladeDark); putG(px, py, L.flowers[r(0, L.flowers.count)])
        }
        switch mood {
        case .forest, .road, .banditCamp:
            if one(2) { leafLitter(ox + r(3, T - 4), oy + r(3, T - 4), count: r(3, 7), seed: hash(x, y, 79), only: putG) }
            if mood != .banditCamp && one(8) { mushroom(ox + r(4, T - 4), oy + r(6, T - 2), red: one(2), only: putG) }
            if mood == .forest && one(4) { fern(ox + r(6, T - 6), oy + r(10, T - 1), only: putG) }
            if one(6) { twig(ox + r(3, T - 8), oy + r(4, T - 3), only: putG) }
        case .burnt:
            for _ in 0..<r(3, 9) { putG(ox + r(1, T - 1), oy + r(1, T - 1), one(3) ? 0x8E8880 : 0x4A423C) }
            if one(4) { twig(ox + r(3, T - 8), oy + r(4, T - 3), only: putG, color: 0x2A2420) }
        case .graveyard, .cloister:
            if one(2) { deadTuft(ox + r(3, T - 3), oy + r(5, T - 1), only: putG) }
            if one(16) { bone(ox + r(4, T - 8), oy + r(5, T - 4), only: putG) }
        case .monkGarden:
            if one(3) { herbClump(ox + r(5, T - 5), oy + r(6, T - 3), lavender: one(2), only: putG) }
        case .wolfDen, .orcCamp:
            if one(9) { bone(ox + r(4, T - 8), oy + r(5, T - 4), only: putG) }
            if mood == .wolfDen && one(5) {
                let px = ox + r(4, T - 6), py = oy + r(4, T - 4)
                for (dx, dy) in [(0, 1), (2, 0), (4, 1), (1, 3), (2, 3), (3, 3)] { putG(px + dx, py + dy, L.grass[0]) }
            }
        case .frozen:
            for _ in 0..<r(4, 10) { putG(ox + r(1, T - 1), oy + r(1, T - 1), one(2) ? 0xF2F8FC : 0xC4D6E0) }
        case .pass:
            if one(5) { snowDrift(ox + r(6, T - 6), oy + r(5, T - 4), only: putG) }
        default: break
        }
        // Juncos en la orilla
        if ![.frozen, .slopes, .orcCamp, .pass].contains(mood) {
            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] where ctx.tile(x + dx, y + dy) == .water && one(2) {
                let px = ox + (dx < 0 ? r(1, 6) : (dx > 0 ? r(T - 7, T - 2) : r(4, T - 4)))
                let py = oy + (dy < 0 ? r(6, 10) : (dy > 0 ? r(T - 3, T) : r(8, T - 2)))
                reeds(px, py, seed: hash(x, y, 80 + dx * 3 + dy), only: putG)
            }
        }
        // Cascotes junto a los muros en ruinas
        if [(-1, 0), (1, 0), (0, -1), (0, 1)].contains(where: { ctx.tile(x + $0.0, y + $0.1) == .wall || ctx.tile(x + $0.0, y + $0.1) == .pillar }) {
            for _ in 0..<r(1, 4) { rubbleStone(&g, ox + r(2, T - 6), oy + r(4, T - 3), tones: [0x4E4A52, 0x6A6670, 0x8A8690, 0xA6A2AC]) }
        }
    }

    /// Mata de hierba en forma de W con los colores del ambiente.
    static func fieldTuft(_ x: Int, _ y: Int, _ L: FieldLook, big: Bool, only put: (Int, Int, UInt32) -> Void) {
        put(x - 1, y, L.bladeDark); put(x, y, L.bladeDark); put(x + 1, y, L.bladeDark)
        put(x - 2, y - 1, L.grass[4]); put(x, y - 1, L.grass[3]); put(x + 2, y - 1, L.grass[4])
        put(x, y - 2, L.bladeLight)
        if big {
            put(x - 3, y - 2, L.bladeLight); put(x + 3, y - 2, L.bladeLight)
            put(x - 1, y - 1, L.grass[1]); put(x + 1, y - 1, L.grass[1])
            put(x + 1, y - 3, L.bladeLight)
        }
    }

    static func fieldPebble(_ x: Int, _ y: Int, _ L: FieldLook, big: Bool, only put: (Int, Int, UInt32) -> Void) {
        let w = big ? 3 : 2
        for dx in 0..<w { put(x + dx, y, dx < w - 1 ? 0xC8C2B6 : 0x9C968A); put(x + dx, y + 1, dx == w - 1 ? 0x76706A : 0xA49E92) }
        for dx in 1...w { put(x + dx, y + 2, L.bladeDark) }
    }

    static func rubbleStone(_ g: inout PixelGrid, _ x: Int, _ y: Int, tones: [UInt32]) {
        let w = 3 + (hash(x, y, 150) % 3)
        tintRect(&g, x + 1, y + 3, w, 1, shadowF)
        for dx in 0..<w { g[x + dx, y] = dx == 0 ? tones[3] : tones[2]; g[x + dx, y + 1] = dx == w - 1 ? tones[1] : tones[2]; g[x + dx, y + 2] = tones[1] }
        g[x + w - 1, y + 2] = tones[0]
        g[x - 1, y + 1] = tones[0]; g[x + w, y + 1] = tones[0]; g[x, y - 1] = tones[0]
    }

    static func puddle(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, rx: Int, mud: UInt32) {
        let ry = max(2, rx / 2)
        for y in -ry - 1...ry + 1 {
            for x in -rx - 1...rx + 1 {
                let d = Double(x * x) / Double(rx * rx) + Double(y * y) / Double(ry * ry)
                if d <= 1 {
                    var c: UInt32 = y < 0 ? 0x485E6E : 0x5C7A90
                    if y == -ry || (y < 0 && d > 0.7) { c = 0x3A5266 }                // borde de arriba en sombra
                    if y == 0 && x > -rx / 2 && x < rx / 3 { c = 0x9AB6CA }           // cielo reflejado
                    g[cx + x, cy + y] = c
                } else if d <= 1.5 && (x + y) % 2 == 0 {
                    g[cx + x, cy + y] = mud
                }
            }
        }
    }

    static func leafLitter(_ x: Int, _ y: Int, count: Int, seed: Int, only put: (Int, Int, UInt32) -> Void) {
        let colors: [(UInt32, UInt32)] = [(0xC07A30, 0x8A5222), (0xD8A840, 0xA07428), (0x9A5A2A, 0x6A3A1A), (0x7A8A34, 0x56662A)]
        for i in 0..<count {
            let h = hash(seed, i, 151)
            let px = x + h % 9 - 4, py = y + (h >> 4) % 7 - 3
            let (a, b) = colors[(h >> 8) % colors.count]
            put(px, py, a); put(px + 1, py, a); put(px + 1, py + 1, b)
        }
    }

    static func mushroom(_ x: Int, _ y: Int, red: Bool, only put: (Int, Int, UInt32) -> Void) {
        let cap: (UInt32, UInt32, UInt32) = red ? (0xD83A2E, 0x9A2420, 0xFFE8D8) : (0xB8885A, 0x7E5A3A, 0xEAD8B8)
        put(x, y, 0xE8E0CC); put(x, y - 1, 0xD8D0BC); put(x + 1, y, 0x9A9282)
        for dx in -1...2 { put(x + dx, y - 2, dx == 2 ? cap.1 : cap.0) }
        put(x, y - 3, cap.0); put(x + 1, y - 3, cap.1)
        put(x - 1, y - 2, cap.0); put(x, y - 2, cap.2)
        put(x + 2, y, 0x2A4A2A)
    }

    static func fern(_ x: Int, _ y: Int, only put: (Int, Int, UInt32) -> Void) {
        let tones: [UInt32] = [0x1E4A2A, 0x2E6634, 0x468A40, 0x68A84E]
        for side in [-1, 1] {
            for i in 0..<6 {
                let fx = x + side * (i + 1), fy = y - 1 - i / 2 - (i > 3 ? 1 : 0)
                put(fx, fy, tones[side < 0 ? 2 : 1])
                if i % 2 == 0 { put(fx, fy - 1, tones[side < 0 ? 3 : 2]); put(fx, fy + 1, tones[0]) }
            }
        }
        for i in 0..<6 { put(x, y - i, i < 2 ? tones[0] : tones[2]); if i % 2 == 1 { put(x - 1, y - i - 1, tones[3]); put(x + 1, y - i - 1, tones[1]) } }
    }

    static func twig(_ x: Int, _ y: Int, only put: (Int, Int, UInt32) -> Void, color: UInt32 = 0x5A3E26) {
        for i in 0..<6 { put(x + i, y + i / 3, i % 2 == 0 ? color : light(color, 1.2)) }
        put(x + 3, y - 1, color); put(x + 4, y - 2, color)
    }

    static func bone(_ x: Int, _ y: Int, only put: (Int, Int, UInt32) -> Void) {
        let c: UInt32 = 0xE8E0CC, s: UInt32 = 0xB0A890
        for i in 0..<5 { put(x + i, y, c); put(x + i, y + 1, s) }
        put(x - 1, y - 1, c); put(x - 1, y + 1, c); put(x + 5, y - 1, c); put(x + 5, y + 1, s)
        put(x, y + 2, 0x3A3A2A); put(x + 4, y + 2, 0x3A3A2A)
    }

    static func deadTuft(_ x: Int, _ y: Int, only put: (Int, Int, UInt32) -> Void) {
        let a: UInt32 = 0x8A8458, b: UInt32 = 0xA8A070, d: UInt32 = 0x5E5A3C
        put(x - 1, y, d); put(x, y, d); put(x + 1, y, d)
        put(x - 2, y - 2, b); put(x - 1, y - 1, a); put(x, y - 2, a); put(x, y - 3, b); put(x + 1, y - 1, a); put(x + 2, y - 2, a); put(x + 3, y - 3, b)
    }

    static func herbClump(_ x: Int, _ y: Int, lavender: Bool, only put: (Int, Int, UInt32) -> Void) {
        let tones: [UInt32] = lavender ? [0x3E5A3A, 0x56744A, 0x7A9466] : [0x2E5A2E, 0x447A3A, 0x64984A]
        for dy in -3...0 {
            for dx in -3...3 where dx * dx * 2 + dy * dy * 4 <= 18 {
                put(x + dx, y + dy, dy == 0 ? tones[0] : (dx + dy < -2 ? tones[2] : tones[1]))
            }
        }
        if lavender { for dx in [-2, 0, 2] { put(x + dx, y - 4, 0xA884D0); put(x + dx, y - 5, 0xC8A8EC) } }
    }

    static func snowDrift(_ x: Int, _ y: Int, only put: (Int, Int, UInt32) -> Void) {
        for dy in -2...2 {
            for dx in -5...5 where dx * dx * 4 + dy * dy * 25 <= 100 {
                put(x + dx, y + dy, dy >= 1 ? 0xC4D2DE : (dx + dy < -3 ? 0xFFFFFF : 0xE6EEF4))
            }
        }
    }

    static func reeds(_ x: Int, _ y: Int, seed: Int, only put: (Int, Int, UInt32) -> Void) {
        for i in 0..<4 {
            let h = hash(seed, i, 152)
            let rx = x + i * 2 - 3 + h % 2, hgt = 5 + h % 5, lean = (h >> 3) % 3 - 1
            for k in 0..<hgt {
                let px = rx + (k > hgt / 2 ? lean : 0)
                put(px, y - k, k < 2 ? 0x2E5A2A : (i % 2 == 0 ? 0x5A8A3A : 0x467A32))
            }
            if (h >> 6) % 2 == 0 {
                let tx = rx + lean
                put(tx, y - hgt, 0x6A3E1E); put(tx, y - hgt - 1, 0x8A5428); put(tx, y - hgt - 2, 0x6A3E1E)
            }
        }
    }

    // MARK: - Agua: nenúfares y puentes

    static func fieldWaterDetails(_ g: inout PixelGrid, _ mat: [UInt8], _ ctx: FieldContext) {
        let T = tile
        for y in 0..<ctx.h {
            for x in 0..<ctx.w {
                let t = ctx.tile(x, y)
                if t == .water && isMurky(ctx.mood(x, y)) && hash(x, y, 160) % 2 == 0 {
                    let cx = x * T + 6 + hash(x, y, 161) % 12, cy = y * T + 6 + hash(x, y, 162) % 12
                    guard mat[cy * g.width + cx] == FieldMaterial.water.rawValue else { continue }
                    lilyPad(&g, cx, cy, flower: hash(x, y, 163) % 3 == 0)
                }
                if t == .bridge && ctx.tile(x - 1, y) != .bridge && ctx.tile(x, y - 1) != .bridge {
                    bridgeBlock(&g, ctx, x, y)
                }
            }
        }
    }

    static func lilyPad(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, flower: Bool) {
        for y in -2...2 {
            for x in -3...3 where x * x * 4 + y * y * 9 <= 36 {
                if x > 0 && y == 0 { continue }                                     // muesca
                g[cx + x, cy + y] = (x + y) < -1 ? 0x6EA44A : (y > 0 ? 0x3A6A2E : 0x4E8A3A)
            }
        }
        g[cx - 1, cy + 3] = 0x1E3C40; g[cx, cy + 3] = 0x1E3C40
        if flower { g[cx - 1, cy - 1] = 0xF0B8D0; g[cx, cy - 2] = 0xFFFFFF; g[cx - 2, cy - 1] = 0xE890B8; g[cx - 1, cy - 2] = 0xFFE8F0 }
    }

    /// Puente de tablones con barandillas (las de delante tapan la tablazón) y estribos de piedra.
    static func bridgeBlock(_ g: inout PixelGrid, _ ctx: FieldContext, _ x0: Int, _ y0: Int) {
        let T = tile
        var x1 = x0, y1 = y0
        while x1 + 1 < ctx.w && ctx.tile(x1 + 1, y0) == .bridge { x1 += 1 }
        while y1 + 1 < ctx.h && ctx.tile(x0, y1 + 1) == .bridge { y1 += 1 }
        let horizontal = ctx.tile(x0, y0 - 1) == .water || ctx.tile(x0, y1 + 1) == .water
        let left = x0 * T, right = (x1 + 1) * T, top = y0 * T, bottom = (y1 + 1) * T
        let wood: [UInt32] = [0x5A361C, 0x7A4A26, 0x8E5A30, 0xA06A3A, 0xB27C48]
        let line: UInt32 = 0x3A2212
        if horizontal {
            let dt = top + 3, db = bottom - 3
            // Sombra en el agua bajo el tablero y estribos en las orillas
            tintRect(&g, left - 2, db, right - left + 4, 5, (0.55, 0.6, 0.72))
            for sx in [left - 6, right] {
                for yy in (dt - 1)..<(db + 3) {
                    for xx in sx..<(sx + 6) {
                        let st = hash((xx - sx) / 3, (yy - dt) / 4, 164)
                        var c: UInt32 = [0x7A766E, 0x8A867C, 0x969286][st % 3]
                        if (yy - dt) % 4 == 3 || (xx - sx) % 3 == 0 && (yy - dt) % 8 < 4 { c = 0x5A564E }
                        g[xx, yy] = c
                    }
                }
            }
            // Tablones (perpendiculares al paso)
            var px = left - 2
            var k = 0
            while px < right + 2 {
                let pw = 4 + hash(k, x0, 165) % 2
                let tone = wood[1 + hash(k, y0, 166) % 3]
                let broken = hash(k, x0 + y0, 167) % 11 == 0
                for xx in px..<min(px + pw, right + 2) {
                    for yy in dt..<db {
                        if broken && yy > db - 9 && yy < db - 4 { continue }   // tablón roto: se ve el agua
                        var c = tone
                        if xx == px { c = line } else if xx == px + 1 { c = light(tone, 1.08) } else if xx == px + pw - 1 { c = dark(tone, 0.82) }
                        if hash(xx, yy / 3, 168) % 13 == 0 && xx != px { c = dark(tone, 0.88) }      // vetas
                        if (yy == dt + 2 || yy == db - 3) && xx == px + 2 { c = 0x2E2A2A }            // clavos
                        let worn = noise(Double(xx) / 20, Double(yy) / 4, 169)
                        if worn > 0.6 && xx != px { c = light(c, 1.05) }
                        g[xx, yy] = c
                    }
                }
                px += pw; k += 1
            }
            // Vigas de borde
            fill(&g, left - 2, dt - 2, right - left + 4, 2, wood[0]); hline(&g, left - 2, dt - 2, right - left + 4, wood[2])
            fill(&g, left - 2, db, right - left + 4, 2, wood[0])
            // Barandillas: la de detrás (arriba) y la de delante (abajo), con postes
            for (ry, front) in [(dt - 2, false), (db + 1, true)] {
                let postTop = ry - 11
                var pxp = left - 2
                while pxp <= right {
                    fill(&g, pxp, postTop, 3, ry - postTop + 1, wood[1]); vline(&g, pxp, postTop, ry - postTop + 1, wood[3]); vline(&g, pxp + 2, postTop, ry - postTop + 1, wood[0])
                    hline(&g, pxp - 1, postTop - 1, 5, line); vline(&g, pxp - 1, postTop, ry - postTop + 1, line); vline(&g, pxp + 3, postTop, ry - postTop + 1, line)
                    if front { tintRect(&g, pxp + 3, ry + 1, 3, 3, shadowF) }
                    pxp += right - left > 50 ? 24 : 20
                }
                fill(&g, left - 3, postTop + 1, right - left + 6, 3, wood[2])
                hline(&g, left - 3, postTop + 1, right - left + 6, wood[4]); hline(&g, left - 3, postTop + 3, right - left + 6, wood[0])
                hline(&g, left - 3, postTop, right - left + 6, line); hline(&g, left - 3, postTop + 4, right - left + 6, line)
                fill(&g, left - 3, postTop + 6, right - left + 6, 2, wood[1]); hline(&g, left - 3, postTop + 8, right - left + 6, line)
            }
        } else {
            let dl = left + 3, dr = right - 3
            tintRect(&g, dr, top, 5, bottom - top, (0.55, 0.6, 0.72))
            var py = top - 2
            var k = 0
            while py < bottom + 2 {
                let tone = wood[1 + hash(k, x0, 166) % 3]
                for yy in py..<min(py + 4, bottom + 2) {
                    for xx in dl..<dr {
                        var c = tone
                        if yy == py { c = line } else if yy == py + 1 { c = light(tone, 1.08) } else if yy == py + 3 { c = dark(tone, 0.84) }
                        g[xx, yy] = c
                    }
                }
                py += 4; k += 1
            }
            for rx in [dl - 2, dr] { fill(&g, rx, top - 12, 3, bottom - top + 12, wood[2]); vline(&g, rx, top - 12, bottom - top + 12, wood[4]); vline(&g, rx + 2, top - 12, bottom - top + 12, wood[0]) }
        }
    }

    // MARK: - Mieses, hierba alta y maleza

    enum TallGrassKind { case wheat, burnt, weeds, dry }

    static func tallGrassKind(_ mood: FieldMood) -> TallGrassKind {
        switch mood {
        case .burnt: return .burnt
        case .graveyard, .cloister, .monkGarden: return .weeds
        case .slopes, .frozen, .orcCamp, .pass, .wolfDen, .banditCamp: return .dry
        default: return .wheat
        }
    }

    static func tallGrassTile(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let kind = tallGrassKind(ctx.mood(x, y))
        let isTall: (Int, Int) -> Bool = { ctx.tile($0, $1) == .tallGrass && !ctx.isCovered($0, $1) }
        let up = isTall(x, y - 1), down = isTall(x, y + 1), left = isTall(x - 1, y), right = isTall(x + 1, y)
        // Suelo bajo las espigas
        let soil: [UInt32]
        switch kind {
        case .wheat: soil = [0x6A5020, 0x7A5E26, 0x8A6C2E]
        case .burnt: soil = [0x2E2824, 0x3E3630, 0x544A40]
        case .weeds: soil = [0x2A3A26, 0x34462C, 0x3E5232]
        case .dry: soil = [0x5E6434, 0x6E743C, 0x7E8446]
        }
        for ly in 0..<T {
            for lx in 0..<T {
                let px = ox + lx, py = oy + ly
                // Bordes deshilachados: cerca de un lado sin mies, el suelo de abajo asoma
                let edgeD = min(left ? 99 : lx, right ? 99 : T - 1 - lx, up ? 99 : ly - 3, down ? 99 : T - 1 - ly)
                if edgeD < 1 + Int(noise(Double(px) / 3.5, Double(py) / 3.5, 170) * 6) { continue }
                var c = tone(soil, noise(Double(px) / 4, Double(py) / 3, 171) * 1.2 - 0.1, px, py, dither: 0.4)
                if kind == .burnt {
                    let ash = noise(Double(px) / 7, Double(py) / 6, 172)
                    if ash > 0.6 { c = tone([0x5E5850, 0x726C64, 0x8A847A], (ash - 0.6) * 4, px, py) }
                    if hash(px, py, 173) % 53 == 0 { c = 0xE0702A }                  // brasa
                }
                g[px, py] = c
            }
        }
        // Tallos, fila a fila (los de abajo tapan a los de arriba)
        var row = up ? -2 : 4
        while row < T {
            let base = oy + row + 2
            var col = (row / 3) % 2 == 0 ? 0 : 1
            while col < T {
                let px = ox + col + hash(ox + col, base, 174) % 2
                defer { col += 2 }
                let rag = Int(noise(Double(px) / 3.5, Double(base) / 3.5, 170) * 6)
                if !left && col < rag { continue }
                if !right && col > T - 1 - rag { continue }
                if !down && row > T - 2 - rag / 2 { continue }
                if base > oy + T + (down ? 1 : -1) { continue }
                stalk(&g, px, base, kind: kind, seed: hash(px, base, 177))
            }
            row += 3
        }
    }

    /// Un tallo: trigo dorado, rastrojo quemado (con alguna espiga que sobrevive), maleza o hierba seca.
    private static func stalk(_ g: inout PixelGrid, _ x: Int, _ base: Int, kind: TallGrassKind, seed: Int) {
        let lean = seed % 3 - 1
        switch kind {
        case .wheat, .burnt:
            let alive = kind == .wheat || noise(Double(x) / 20, Double(base) / 16, 178) > 0.64
            if !alive {
                // Rastrojo carbonizado
                let hgt = 1 + seed % 3
                for k in 0..<hgt { g[x, base - k] = k == hgt - 1 ? 0x4A3E34 : 0x221C18 }
                if seed % 37 == 0 { g[x, base - hgt] = 0xF08A3A }
                return
            }
            let hgt = 6 + seed % 4
            let stem: [UInt32] = [0x8A6A22, 0xA8862C, 0xC4A040]
            for k in 0..<hgt - 3 { g[x + (k > hgt / 2 ? lean : 0), base - k] = stem[(seed >> 3) % 3] }
            let hx = x + lean, top = base - hgt
            // Espiga: 3 pixeles con brillo a la izquierda y barbas
            g[hx, top + 2] = 0xC89A34; g[hx, top + 1] = 0xE6C25A; g[hx, top] = 0xF4DC8A
            g[hx - 1, top + 1] = 0xF6E6A8; g[hx + 1, top + 2] = 0xA87E28
            if seed % 4 == 0 { g[hx + 1, top - 1] = 0xF8ECB8 }
            if kind == .burnt && seed % 5 == 0 { g[hx, top + 2] = 0x5A4430 }       // chamuscada
        case .weeds:
            let hgt = 4 + seed % 6
            let greens: [UInt32] = [0x2C4628, 0x3C5C32, 0x4E7240, 0x6A8C50]
            for k in 0..<hgt {
                let px = x + (k * lean) / 3
                g[px, base - k] = greens[min(3, k * 4 / hgt)]
            }
            if seed % 5 == 0 { g[x + lean * 2 - 1, base - hgt + 1] = 0x6E8A50; g[x + lean * 2 + 1, base - hgt + 2] = 0x3A5A32 }  // hojas
            if seed % 17 == 0 {                                                        // cardo
                let tx = x + (hgt * lean) / 3
                g[tx, base - hgt] = 0x9A5AB8; g[tx, base - hgt - 1] = 0xC08ADA; g[tx - 1, base - hgt] = 0x7A4498
            }
            if seed % 23 == 0 {                                                        // zarza con espinas
                for k in 0..<5 { g[x + k, base - 2 - (k == 2 ? 1 : 0)] = 0x4A2E3A }
                g[x + 1, base - 4] = 0x6A4A56; g[x + 3, base - 4] = 0x6A4A56
            }
        case .dry:
            let hgt = 5 + seed % 5
            let tones: [UInt32] = [0x6E7238, 0x8E9450, 0xA8AA5E, 0xC4C27A]
            for k in 0..<hgt {
                let px = x + (k >= hgt - 2 ? lean : 0) + (k == hgt - 1 ? lean : 0)
                g[px, base - k] = tones[min(3, k * 4 / hgt)]
            }
            if seed % 4 == 0 { g[x + lean * 2, base - hgt] = 0xDCD898; g[x + lean * 2 + (lean == 0 ? 1 : lean), base - hgt + 1] = 0xDCD898 }
        }
    }

    // MARK: - Salidas

    /// Bruma clara hacia el borde del mapa y dos marcas de piedra en el camino que señalan la salida.
    static func exitMist(_ g: inout PixelGrid, _ ctx: FieldContext, _ x: Int, _ y: Int) {
        exitMist(&g, mapW: ctx.w, mapH: ctx.h, x, y, isExit: { ctx.tile($0, $1) == .areaExit })
    }

    static func exitMist(_ g: inout PixelGrid, mapW: Int, mapH: Int, _ x: Int, _ y: Int, isExit: (Int, Int) -> Bool) {
        let T = tile
        // Hacia dónde sale: el borde del mapa más cercano
        let dir: (Int, Int)
        if x == 0 { dir = (-1, 0) } else if x == mapW - 1 { dir = (1, 0) } else if y == 0 { dir = (0, -1) } else { dir = (0, 1) }
        let mist: UInt32 = 0xE4E8E0
        let reach = T * 3 / 2
        for k in 0..<reach {
            let s = 1 - Double(k) / Double(reach)                    // 1 en el borde, 0 hacia dentro
            for j in 0..<T {
                let px: Int, py: Int
                switch dir {
                case (-1, 0): px = x * T + k; py = y * T + j
                case (1, 0): px = x * T + T - 1 - k; py = y * T + j
                case (0, -1): px = x * T + j; py = y * T + k
                default: px = x * T + j; py = y * T + T - 1 - k
                }
                guard let c = g[px, py] else { continue }
                let wav = noise(Double(px) / 7, Double(py) / 7, 179) * 0.35
                let a = s * s * 0.75 + wav * s
                if a > 0.05 && bayer(px, py) < min(1, a * 1.6) { g[px, py] = mix(c, mist, min(0.75, 0.25 + a * 0.6)) }
            }
        }
        // Marcas en el suelo (una flecha de piedrecitas) en la casilla central de la salida
        // Solo en la casilla central del tramo de salida
        let step = dir.0 == 0 ? (1, 0) : (0, 1)
        var a = 0, b = 0
        while isExit(x - step.0 * (a + 1), y - step.1 * (a + 1)) && a < 40 { a += 1 }
        while isExit(x + step.0 * (b + 1), y + step.1 * (b + 1)) && b < 40 { b += 1 }
        guard a == (a + b) / 2 else { return }
        let cx = x * T + T / 2 - dir.0 * 14, cy = y * T + T / 2 - dir.1 * 14
        let pts: [(Int, Int)] = [(-2, -3), (-1, -2), (0, -1), (1, 0), (0, 1), (-1, 2), (-2, 3)]
        for i in 0..<2 {
            for (a, b) in pts {
                let off = i * 4 - 2
                let (dx, dy): (Int, Int)
                switch dir {
                case (-1, 0): dx = -a - off; dy = b
                case (1, 0): dx = a + off; dy = b
                case (0, -1): dx = b; dy = -a - off
                default: dx = b; dy = a + off
                }
                g[cx + dx, cy + dy + 1] = 0x6A5A44
                g[cx + dx, cy + dy] = 0xE6DCC4
            }
        }
    }

    // MARK: - Sombras

    static func fieldShadows(_ g: inout PixelGrid, _ ctx: FieldContext) {
        let T = tile
        var mask = [UInt8](repeating: 0, count: g.width * g.height)
        func mark(_ x: Int, _ y: Int, _ v: UInt8) {
            guard x >= 0, y >= 0, x < g.width, y < g.height else { return }
            mask[y * g.width + x] = max(mask[y * g.width + x], v)
        }
        func markEllipse(_ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int) {
            for y in -ry - 1...ry + 1 {
                for x in -rx - 1...rx + 1 {
                    let d = Double(x * x) / Double(rx * rx) + Double(y * y) / Double(ry * ry)
                    if d <= 0.8 { mark(cx + x, cy + y, 2) } else if d <= 1.15 { mark(cx + x, cy + y, 1) }
                }
            }
        }
        for b in ctx.map.buildings {
            // La atalaya es más estrecha que su solar (12 px a cada lado): la sombra sale de la torre.
            let inset = b.style == .watchtower ? 12 : 0
            let right = (b.x + b.width) * T - inset, top = b.y * T, bottom = (b.y + b.height) * T
            let band = b.style == .watchtower || b.style == .abbeyChurch ? 16 : 10
            let start = b.style == .ruinedMill ? bottom - 30 : top + 16      // el anejo del molino es bajo
            for i in 0..<band {
                for y in (start + i)..<(bottom + 3) { mark(right + i, y, i == band - 1 ? 1 : 2) }
            }
            for x in (b.x * T + 4)..<right { mark(x, bottom, 2); mark(x, bottom + 1, 2); mark(x, bottom + 2, 1) }
            for i in 0..<band { mark(right + i, bottom + 3, 1) }
        }
        for y in 0..<ctx.h {
            for x in 0..<ctx.w {
                let ox = x * T, oy = y * T
                switch ctx.tile(x, y) {
                case .tree:
                    let v = treeVariant(ctx.map, x, y)
                    if v == 8 { markEllipse(ox + 15, oy + 21, 9, 4) } else { markEllipse(ox + 15, oy + 21, 14, 5) }
                case .cliff:
                    if ctx.tile(x, y + 1) != .cliff {
                        for py in 0..<7 { for px in 0..<T { mark(ox + px, oy + T + py, py >= 5 ? 1 : 2) } }
                    }
                    if ctx.tile(x + 1, y) != .cliff {
                        for py in 3..<(T + 3) { for px in 0..<6 { mark(ox + T + px, oy + py, px >= 4 ? 1 : 2) } }
                    }
                case .wall:
                    if ctx.tile(x, y + 1) != .wall {
                        for py in 0..<4 { for px in 2..<T { mark(ox + px, oy + T + py, py == 3 ? 1 : 2) } }
                    }
                    if ctx.tile(x + 1, y) != .wall {
                        for py in 2..<(T + 2) { for px in 0..<5 { mark(ox + T - 2 + px, oy + py, px == 4 ? 1 : 2) } }
                    }
                default: break
                }
            }
        }
        for i in 0..<mask.count where mask[i] > 0 {
            let x = i % g.width, y = i / g.width
            if mask[i] == 2 || (x + y) % 2 == 0, let c = g.pixels[i] { g.pixels[i] = VillageArt.scale(c, shadowF) }
        }
    }

    // MARK: - Casillas de campo en el pueblo

    /// En Valdehierro solo hay salidas `>` (la calle o un sendero que sigue, con bruma) y la bajada `e` a los calabozos.
    static func townFieldTiles(_ g: inout PixelGrid, _ map: AreaMap) {
        let T = tile
        let L = fieldLooks[FieldMood.farm.rawValue]
        for y in 0..<map.height {
            for x in 0..<map.width {
                switch map.tile(x, y) {
                case .areaExit:
                    if surface(map, x, y) != .street {
                        // Sendero de tierra que se pierde en la hierba
                        for ly in 0..<T {
                            for lx in 0..<T {
                                let px = x * T + lx, py = y * T + ly
                                let sideL = map.tile(x - 1, y) == .areaExit ? 99 : lx, sideR = map.tile(x + 1, y) == .areaExit ? 99 : T - 1 - lx
                                let d = Double(min(sideL, sideR)) + wobble(px, py, 71) * 10
                                if d > 3 { g[px, py] = d < 4.5 ? dark(fieldDirtColor(px, py, L), 0.82) : fieldDirtColor(px, py, L) }
                            }
                        }
                    }
                    exitMist(&g, mapW: map.width, mapH: map.height, x, y, isExit: { map.tile($0, $1) == .areaExit })
                case .cave where map.tile(x - 1, y) != .cave:
                    caveStairs(&g, x * T, y * T, width: map.tile(x + 1, y) == .cave ? 2 * T : T, violet: false, seed: hash(x, y, 701))
                default: break
                }
            }
        }
    }
}
