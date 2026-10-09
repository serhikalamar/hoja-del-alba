import Foundation
import GameCore

/// Edificios del campo de Valdemar: molino en ruinas (guarida del Ogro), granja quemada, iglesia gótica de la abadía,
/// puesto del guardabosques y atalaya derruida del Paso. Mismo convenio que las casas del pueblo: el sprite mide
/// `ancho × T` de ancho y `alto × T + margen` de alto, con el suelo en la última fila; la puerta, en `doorX`.
extension TownArt {
    /// Arte propio de un edificio de campo (nil = estilo del pueblo).
    static func fieldBuilding(_ b: Building) -> PixelGrid? {
        switch b.style {
        case .ruinedMill: return ruinedMill(b)
        case .burnedFarm: return burnedFarm(b)
        case .abbeyChurch: return abbeyChurch(b)
        case .rangerHut: return rangerHut(b)
        case .watchtower: return watchtower(b)
        default: return nil
        }
    }

    /// Estilos con arte de campo propio.
    static let fieldStyles: Set<BuildingStyle> = [.ruinedMill, .burnedFarm, .abbeyChurch, .rangerHut, .watchtower]

    /// Margen de arriba de cada edificio de campo (tejados, aspas y torres que sobresalen).
    static func fieldMargin(_ style: BuildingStyle) -> Int {
        switch style {
        case .ruinedMill: return 44
        case .burnedFarm: return 26
        case .abbeyChurch: return 76
        case .rangerHut: return 30
        case .watchtower: return 72
        default: return 26
        }
    }

    /// Bocas de humo de los edificios de campo, en pixeles del sprite (sin contorno): chimeneas y rescoldos.
    static func fieldSmoke(_ b: Building) -> [(x: Int, y: Int)] {
        let T = tile
        let W = b.width * T, M = fieldMargin(b.style)
        switch b.style {
        case .rangerHut: return [(W - 26, M + 2 + 14 - 22 - 4)]
        case .burnedFarm: return [(W - 26, M + 4 + 14 - 24 - 4), (W / 2 + 8, M + 26)]
        default: return []
        }
    }

    private static func canvas(_ b: Building) -> (PixelGrid, W: Int, base: Int, doorC: Int, seed: Int) {
        let T = tile
        let W = b.width * T, H = b.height * T, M = fieldMargin(b.style)
        let doorC = (b.doorX - b.x) * T + b.doorWidth * T / 2
        return (PixelGrid(width: W, height: H + M), W, H + M, doorC, hash(b.x, b.y, 900))
    }

    // MARK: - Utilidades

    /// ¿Dentro de un arco apuntado (gótico) de semiancho `a` que arranca a la altura `spring`?
    static func inPointedArch(_ x: Int, _ y: Int, cx: Int, spring: Int, a: Int) -> Bool {
        if y >= spring { return abs(Double(x) - Double(cx) + 0.5) <= Double(a) }
        let fx = Double(x) + 0.5, fy = Double(y)
        let ccx = fx < Double(cx) ? Double(cx + a) : Double(cx - a)
        let dx = fx - ccx, dy = fy - Double(spring)
        return dx * dx + dy * dy <= Double(4 * a * a)
    }

    /// Hollín: oscurece con manchas que suben desde un punto (ventanas y puerta de la granja quemada).
    private static func soot(_ g: inout PixelGrid, cx: Int, from y0: Int, up: Int, width: Int, seed: Int) {
        for y in (y0 - up)...y0 {
            let t = Double(y0 - y) / Double(up)
            let hw = Double(width) * (0.5 + t * 0.6)
            for x in Int(Double(cx) - hw)...Int(Double(cx) + hw) {
                let u = abs(Double(x - cx)) / hw
                let k = (1 - u) * (1 - t * 0.7) + (noise(Double(x) / 4, Double(y) / 5, seed) - 0.5) * 0.5
                if k > 0.55 { tint(&g, x, y, (0.45, 0.42, 0.42)) } else if k > 0.3 && (x + y) % 2 == 0 { tint(&g, x, y, (0.7, 0.66, 0.64)) }
            }
        }
    }

    /// Hueco quemado en un tejado: interior negro, cabios carbonizados y alguna brasa.
    private static func roofHole(_ g: inout PixelGrid, x0: Int, x1: Int, top: Int, bottom: Int, seed: Int) {
        let cx = Double(x0 + x1) / 2, cy = Double(top + bottom) / 2
        let rx = Double(x1 - x0) / 2, ry = Double(bottom - top) / 2
        for y in top...bottom {
            for x in x0...x1 {
                let u = (Double(x) - cx) / rx, v = (Double(y) - cy) / ry
                let d = u * u + v * v + (noise(Double(x) / 5, Double(y) / 4, seed) - 0.5) * 0.7
                guard d < 1 else { continue }
                if d > 0.82 { g[x, y] = 0x1E1612; continue }                        // borde chamuscado
                g[x, y] = v < -0.2 ? 0x120C0C : 0x1A1210
            }
        }
        // Cabios y una correa, carbonizados
        var x = x0 + 4
        while x < x1 - 2 {
            for y in top...bottom {
                let xx = x + (y - top) / 4
                guard let c = g[xx, y], c == 0x120C0C || c == 0x1A1210 || c == 0x1E1612 else { continue }
                g[xx, y] = 0x3A2A20; g[xx + 1, y] = 0x22180F
                if hash(xx, y, seed) % 23 == 0 { g[xx, y] = 0xE06A2A }
            }
            x += 11
        }
        let py = Int(cy)
        for xx in x0...x1 { if let c = g[xx, py], c == 0x120C0C || c == 0x1A1210 { g[xx, py] = 0x4A3424; g[xx, py + 1] = 0x22180F } }
    }

    private static func rubblePile(_ g: inout PixelGrid, cx: Int, base: Int, width: Int, tones: [UInt32], seed: Int, snow: Bool = false) {
        for i in 0..<(width / 2) {
            let h = hash(seed, i, 901)
            let x = cx - width / 2 + h % width
            let hgt = max(1, (width / 2 - abs(x - cx)) / 3)
            let y = base - 2 - h / 7 % max(1, hgt)
            let w = 3 + (h >> 5) % 4
            fill(&g, x - 1, y - 1, w + 2, 4, rockLine)
            fill(&g, x, y, w, 2, tones[2]); hline(&g, x, y, w, snow ? 0xF0F4FA : tones[3]); g[x + w - 1, y + 1] = tones[0]
        }
    }

    // MARK: - Molino en ruinas

    private static func ruinedMill(_ b: Building) -> PixelGrid {
        var (g, W, base, doorC, seed) = canvas(b)
        let stone: [UInt32] = [0x5A5450, 0x6E6862, 0x857E76, 0x9C948A, 0xB2AA9E]
        let tx = doorC
        let towerTop = base - 112
        // Anejo derruido a la derecha: muros bajos de mampuesto sin tejado
        let ax0 = tx + 30, ax1 = W - 3
        for x in ax0..<ax1 {
            let hgt = 26 + Int((noise(Double(x) / 7, 3, seed) - 0.5) * 22) - (x > ax1 - 10 ? (x - (ax1 - 10)) * 2 : 0)
            let top = base - max(8, hgt)
            for y in top..<base {
                var c = ruinStoneColor(x, y - top, seed: seed % 7)
                c = mix(c, stone[2], 0.4)
                if y < top + 2 { c = stone[4] }
                if x > ax1 - 4 { c = dark(c, 0.8) }
                g[x, y] = c
            }
            g[x, top - 1] = ruinLine
        }
        // Vigas caídas apoyadas en el anejo
        line(&g, ax0 + 4, base - 30, ax1 - 6, base - 6, 0x4A3020); line(&g, ax0 + 5, base - 30, ax1 - 5, base - 6, 0x6E4A2C)
        line(&g, ax0 + 14, base - 4, ax1 - 4, base - 26, 0x3A2418); line(&g, ax0 + 14, base - 5, ax1 - 4, base - 27, 0x5E3E24)
        sack(&g, ax0 + 6, base - 13, flour: true); sack(&g, ax0 + 16, base - 11, flour: false)
        // Torre: cilindro de piedra que se estrecha hacia arriba
        for y in towerTop..<base {
            let t = Double(base - y) / Double(base - towerTop)
            let hw = Int(32 - t * 9)
            for x in (tx - hw)...(tx + hw) {
                let u = Double(x - tx) / Double(hw)
                let row = (y - towerTop) / 6, ly = (y - towerTop) % 6
                let rw = 9 + hash(row, 2, seed) % 4
                let lxs = (x + row * 5) % rw
                let st = hash((x + row * 5) / rw, row, seed + 1)
                var l = 0.62 - u * 0.42 - abs(u) * abs(u) * 0.18
                l += Double(st % 3) * 0.05 - 0.05
                if ly == 5 || lxs == 0 { l -= 0.22 } else if ly == 0 { l += 0.08 }
                var c = tone(stone, l, x, y, dither: 0.15)
                if st % 17 == 0 && ly > 0 && ly < 5 && lxs > 0 { c = 0x2A2622 }            // piedra caída
                if y > base - 10 && noise(Double(x) / 3, Double(y) / 2, seed + 2) > 0.5 { c = hash(x, y, 3) % 2 == 0 ? 0x5E7A3E : 0x4E6A34 }
                g[x, y] = c
            }
        }
        // Grieta grande y brecha arriba a la derecha con el interior a oscuras
        var kx = tx - 6
        for y in stride(from: towerTop + 30, to: base - 30, by: 1) { g[kx, y] = 0x2A2420; if y % 3 == 0 { kx += (y / 7) % 2 == 0 ? 1 : -1 } }
        for y in (towerTop + 4)..<(towerTop + 34) {
            for x in (tx + 6)...(tx + 26) {
                let d = Double((x - tx - 18) * (x - tx - 18)) / 100 + Double((y - towerTop - 14) * (y - towerTop - 14)) / 260
                if d + (noise(Double(x) / 3, Double(y) / 3, seed + 4) - 0.5) * 0.6 < 1 { g[x, y] = y < towerTop + 10 ? 0x1A1614 : 0x241E1A }
            }
        }
        hline(&g, tx + 8, towerTop + 22, 16, 0x5A3A22); hline(&g, tx + 8, towerTop + 23, 16, 0x3A2416)   // viga del piso
        // Saeteras y ventanuco
        for (wx, wy) in [(tx - 14, towerTop + 40), (tx + 4, towerTop + 62)] {
            fill(&g, wx, wy, 4, 9, 0x1A1614); vline(&g, wx - 1, wy, 9, stone[4]); hline(&g, wx - 1, wy + 9, 6, stone[4])
        }
        // Caperuza cónica de paja, medio hundida: queda el lado izquierdo y los cabios del derecho
        let capBase = towerTop + 2, capTop = towerTop - 30
        for y in capTop..<capBase {
            let t = Double(y - capTop) / Double(capBase - capTop)
            let hw = Int(3 + t * 26)
            for x in (tx - hw)...(tx + hw) {
                let collapsed = x > tx - 2 + Int(noise(Double(y) / 4, 1, seed) * 6) && y < capBase - 6
                if collapsed {
                    if (x - tx) % 8 == 0 || (x - tx + y) % 13 == 0 && y > capTop + 10 { g[x, y] = 0x3A2418 }
                    continue
                }
                let u = Double(x - tx) / Double(max(1, hw))
                var l = 0.66 - u * 0.4 - t * 0.12
                l += [0.06, 0, -0.04, -0.12, -0.2][(y - capTop) % 5] + Double(hash(x, (y - capTop) / 5, seed) % 5 - 2) * 0.04
                g[x, y] = tone([0x4A3818, 0x6A5226, 0x8A6E34, 0xA88A46, 0xC4A65E], l, x, y, dither: 0.2)
            }
        }
        for k in 0..<4 { line(&g, tx, capTop + 2, tx + 8 + k * 6, capBase - 2, k % 2 == 0 ? 0x3A2418 : 0x5A3A22) }
        hline(&g, tx - 30, capBase, 60, 0x4A3A30)
        // Aspas: una entera, otra partida, otra colgando y un muñón
        let hub = (x: tx - 2, y: towerTop + 12)
        func sail(_ angle: Double, _ length: Int, lattice: Bool, broken: Bool) {
            let ca = cos(angle), sa = sin(angle)
            let px = -sa, py = ca                                   // perpendicular
            for s in 0..<length {
                let x = Double(hub.x) + ca * Double(s), y = Double(hub.y) + sa * Double(s)
                for w in -1...1 {
                    let xx = Int((x + px * Double(w)).rounded()), yy = Int((y + py * Double(w)).rounded())
                    g[xx, yy] = w == -1 ? 0x9A6A3E : (w == 0 ? 0x6E4A2C : 0x4A3020)
                }
                guard lattice, s > 6 else { continue }
                if broken && s > length - 10 && hash(s, 0, seed) % 2 == 0 { continue }
                // Enrejado de la vela
                for w in 2...10 {
                    let xx = Int((x + px * Double(w)).rounded()), yy = Int((y + py * Double(w)).rounded())
                    if s % 6 == 0 || w == 10 || w == 6 { g[xx, yy] = w == 10 ? 0x4A3020 : 0x7A5634 }
                    else if hash(s / 6, w / 4, seed + Int(angle * 10)) % 3 == 0 { g[xx, yy] = (s + w) % 2 == 0 ? 0xD8CCB0 : 0xB8AA8C }   // jirones de lona
                }
            }
            // Punta astillada
            let ex = Double(hub.x) + ca * Double(length), ey = Double(hub.y) + sa * Double(length)
            g[Int(ex), Int(ey)] = 0xB08050; g[Int(ex + ca * 2 + px), Int(ey + sa * 2 + py)] = 0x8A5A34
        }
        sail(-Double.pi * 0.78, 54, lattice: true, broken: false)
        sail(-Double.pi * 0.18, 24, lattice: true, broken: true)
        sail(Double.pi * 0.36, 46, lattice: true, broken: true)
        sail(Double.pi * 0.86, 9, lattice: false, broken: false)
        ball(&g, hub.x, hub.y, 4, 4, [0x2A2A32, 0x4A4A58, 0x6E6E7E, 0x9A9AAA])
        // Puerta reventada: hueco oscuro y tablas por el suelo; huesos de la guarida del Ogro
        door(&g, doorC, base, width: 16, height: 26, wood: 0x5A3A22, stoneFrame: true, double: false)
        for y in (base - 24)..<(base - 2) { for x in (doorC - 6)...(doorC + 4) where (x + y) % 5 != 0 || y > base - 12 { g[x, y] = 0x16100E } }
        line(&g, doorC - 14, base - 3, doorC - 4, base - 6, 0x6A4026); line(&g, doorC + 6, base - 2, doorC + 18, base - 4, 0x5A3A22)
        for (bx, by) in [(doorC - 22, base - 4), (doorC + 14, base - 7), (doorC + 24, base - 3)] {
            hline(&g, bx, by, 6, 0xE8E0CC); hline(&g, bx, by + 1, 6, 0xB0A890); g[bx - 1, by - 1] = 0xE8E0CC; g[bx + 6, by - 1] = 0xE8E0CC
        }
        // Cascotes al pie y hiedra
        rubblePile(&g, cx: tx - 30, base: base, width: 18, tones: stone, seed: seed)
        rubblePile(&g, cx: tx + 34, base: base, width: 14, tones: stone, seed: seed + 1)
        for x in stride(from: tx - 28, to: tx - 12, by: 1) {
            let len = 10 + hash(x, seed, 5) % 22
            for k in 0..<len where hash(x, k, seed) % 3 != 0 { g[x, base - 40 - k + len / 2] = k % 2 == 0 ? 0x3E7A36 : 0x5E9A44 }
        }
        return g.outlined()
    }

    // MARK: - Granja quemada

    private static func burnedFarm(_ b: Building) -> PixelGrid {
        var (g, W, base, doorC, seed) = canvas(b)
        let M = fieldMargin(b.style)
        let wallTop = base - 54, roofTop = M + 4, eave = wallTop + 6
        plasterWall(&g, 3, wallTop, W - 6, base - 8 - wallTop, tones: [0x8E806A, 0xA8977C, 0xBCAA8C, 0xCCBC9E], seed: seed)
        plinth(&g, 2, base - 8, W - 4, 8, seed: seed)
        var bays: [Int] = []
        var x = 12
        while x + 14 < W - 8 { if abs(x + 7 - doorC) > 21 { bays.append(x); x += 34 } else { x += 6 } }
        timberFrame(&g, W: W, top: eave, bottom: base - 8, bays: bays, doorC: doorC, seed: seed)
        // Ventanas reventadas: sin cristal, con un postigo colgando
        let winY = eave + 9
        for (i, bx) in bays.enumerated() {
            window(&g, bx, winY, shutter: nil, lit: false, flowers: nil)
            for yy in winY..<(winY + 14) { for xx in bx..<(bx + 14) { g[xx, yy] = (xx + yy) % 7 == 0 ? 0x2A1E18 : 0x140E0C } }
            for k in 0..<4 { g[bx + 1 + k, winY + 13 - k] = 0x8A9AA8 }                 // esquirla de cristal
            if i % 2 == 0 {
                for yy in 0..<12 { g[bx - 5 + yy / 3, winY + 2 + yy] = 0x3E2A1A; g[bx - 4 + yy / 3, winY + 2 + yy] = 0x5A3E26 }
            }
            soot(&g, cx: bx + 7, from: winY, up: 22, width: 9, seed: seed + i)
        }
        door(&g, doorC, base, width: 14, height: 24, wood: 0x3A2618, stoneFrame: true, double: false)
        for yy in (base - 22)..<(base - 2) { for xx in (doorC - 6)...(doorC - 1) { g[xx, yy] = 0x140E0C } }
        soot(&g, cx: doorC, from: base - 24, up: 24, width: 10, seed: seed + 9)
        // Tejado de paja quemado con un gran hueco
        let hip = min(26, (eave - roofTop) / 2)
        paintRoof(&g, x0: 0, x1: W, top: roofTop, bottom: eave, hip: hip, kind: .thatch,
                  tones: [0x2A2016, 0x3E3020, 0x56442A, 0x6E5A36, 0x8A7446], seed: seed)
        for y in roofTop..<eave { for x in 0..<W where noise(Double(x) / 9, Double(y) / 6, seed + 3) > 0.62 { tint(&g, x, y, (0.5, 0.46, 0.44)) } }
        roofHole(&g, x0: W / 2 - 34, x1: W / 2 + 38, top: roofTop + 4, bottom: eave - 4, seed: seed)
        tintRect(&g, 3, eave, W - 6, 2, (0.55, 0.55, 0.62))
        chimney(&g, W - 30, roofTop + 14, height: 24, wide: false, seed: seed)
        // Escombros carbonizados delante
        for (x0, y0, x1, y1) in [(8, base - 3, 30, base - 7), (W - 40, base - 2, W - 14, base - 5)] {
            line(&g, x0, y0, x1, y1, 0x1E1612); line(&g, x0, y0 - 1, x1, y1 - 1, 0x3A2A20)
        }
        for (ax, aw) in [(36, 9), (W - 52, 7)] {
            for yy in -2...0 { for xx in -aw...aw where xx * xx * 4 + yy * yy * aw * aw <= aw * aw * 4 { g[ax + xx, base - 2 + yy] = yy == -2 ? 0x9A948C : 0x7A746C } }
            g[ax, base - 3] = 0xE06A2A
        }
        // Rueda de carro rota apoyada en la pared
        let wx = doorC < W / 2 ? W - 22 : 18, wy = base - 14
        for a in 0..<24 {
            let ang = Double(a) / 24 * 2 * Double.pi
            g[wx + Int(cos(ang) * 9), wy + Int(sin(ang) * 9)] = a % 6 == 0 ? 0x2A1C14 : 0x5A3A22
            if a % 4 == 0 && a < 16 { line(&g, wx, wy, wx + Int(cos(ang) * 8), wy + Int(sin(ang) * 8), 0x4A3020) }
        }
        return g.outlined()
    }

    // MARK: - Iglesia de la abadía

    private static func abbeyChurch(_ b: Building) -> PixelGrid {
        var (g, W, base, doorC, seed) = canvas(b)
        let M = fieldMargin(b.style)
        let stone: [UInt32] = [0x5E5A68, 0x76727E, 0x8E8A96, 0xA6A2AE, 0xBEBAC6]
        let wallTop = base - 72, eave = wallTop + 6, roofTop = M + 12
        // Muros de la nave
        for y in wallTop..<base {
            for x in 3..<(W - 3) {
                var c = ashlarColor(x, y, tones: stone, seed: seed)
                if x > W - 9 { c = dark(c, 0.86) }
                if y > base - 7 && noise(Double(x) / 3, Double(y) / 2, seed + 5) > 0.5 { c = mix(c, 0x4E6A36, 0.7) }
                if noise(Double(x) / 10, Double(y) / 14, seed + 6) > 0.7 { c = dark(c, 0.88) }                 // manchas de humedad
                g[x, y] = c
            }
        }
        // Tejado de pizarra empinado, con huecos
        let slate: [UInt32] = [0x1A1E2A, 0x262C3A, 0x343C4E, 0x465066, 0x5E6A80]
        paintRoof(&g, x0: 0, x1: W, top: roofTop, bottom: eave, hip: 34, kind: .slate, tones: slate, seed: seed)
        roofHole(&g, x0: 38, x1: 86, top: roofTop + 14, bottom: eave - 8, seed: seed + 1)
        roofHole(&g, x0: W - 92, x1: W - 58, top: roofTop + 8, bottom: eave - 18, seed: seed + 2)
        for i in 0..<30 { let h = hash(i, seed, 902); let x = 20 + h % (W - 40), y = roofTop + 4 + (h >> 6) % max(1, eave - roofTop - 8); if g[x, y] != 0x120C0C { g[x, y] = slate[0] } }   // pizarras sueltas
        tintRect(&g, 3, eave, W - 6, 3, (0.6, 0.6, 0.7))
        // Contrafuertes y ventanas ojivales rotas entre ellos (sin pisar la fachada)
        let facadeHW = 50
        var bx = 16
        while bx < W - 16 {
            if abs(bx - doorC) > facadeHW + 6 {
                // Contrafuerte escalonado
                for y in (eave + 2)..<base {
                    let step = y > base - 26 ? 2 : 0
                    for k in -step..<(6 + step) { g[bx + k, y] = k < 1 - step + 1 ? stone[4] : (k > 3 + step ? stone[0] : stone[2]) }
                }
                for k in -2..<8 { g[bx + k, base - 27] = stone[4] }
                vline(&g, bx + 8, eave + 2, base - eave - 2, ruinLine)
            }
            let wx = bx + 14
            if wx + 12 < W - 8 && abs(wx + 6 - doorC) > facadeHW + 4 {
                brokenLancet(&g, wx, eave + 12, w: 12, h: 30, seed: seed + wx)
            }
            bx += 40
        }
        // Campanario a la izquierda, con el remate derrumbado
        let tw0 = 18, tw1 = 62, tTop = M - 50 + 40
        for y in tTop..<base {
            for x in tw0..<tw1 {
                let broken = y < tTop + 22 && x > tw0 + 16 + Int(noise(Double(y) / 3, 2, seed) * 10) + (y - tTop)
                if broken { continue }
                var c = ashlarColor(x, y, tones: stone, seed: seed + 7)
                if x < tw0 + 3 { c = light(c, 1.08) } else if x > tw1 - 5 { c = dark(c, 0.8) }
                g[x, y] = c
            }
        }
        // Hueco del campanario (sin campana) y aspillera
        let bcx = (tw0 + tw1) / 2
        for y in (tTop + 10)..<(tTop + 34) { for x in (bcx - 8)...(bcx + 7) where inPointedArch(x, y, cx: bcx, spring: tTop + 18, a: 8) { if g[x, y] != nil { g[x, y] = y > tTop + 30 ? 0x2A2630 : 0x16121C } } }
        for x in (bcx - 10)...(bcx + 9) { if g[x, tTop + 34] != nil { g[x, tTop + 34] = stone[4] } }
        line(&g, bcx - 4, tTop + 24, bcx + 3, tTop + 33, 0x5A3A22)                                    // viga caída
        fill(&g, bcx - 1, tTop + 48, 3, 10, 0x16121C)
        // Fachada con hastial gótico en el centro
        let fx0 = doorC - facadeHW, fx1 = doorC + facadeHW
        let apex = wallTop - 8 - facadeHW * 2
        for y in apex..<base {
            for x in fx0..<fx1 {
                let gableEdge = wallTop - 8 - (facadeHW - abs(x - doorC + (x < doorC ? 0 : 1))) * 2
                guard y >= max(apex, gableEdge) else { continue }
                var c = ashlarColor(x, y, tones: [0x6A6674, 0x84808C, 0x9C98A4, 0xB6B2BE, 0xCECAD4], seed: seed + 11)
                if x < fx0 + 4 { c = light(c, 1.08) } else if x > fx1 - 5 { c = dark(c, 0.82) }
                if y > base - 7 && noise(Double(x) / 3, Double(y) / 2, seed + 12) > 0.45 { c = mix(c, 0x4E6A36, 0.7) }
                g[x, y] = c
            }
        }
        // Remate de la fachada (albardilla) y cruz torcida
        for x in fx0..<fx1 {
            let ey = wallTop - 8 - (facadeHW - abs(x - doorC + (x < doorC ? 0 : 1))) * 2
            if ey >= apex { g[x, ey] = 0xDAD6E0; g[x, ey + 1] = stone[3]; g[x, ey - 1] = ruinLine }
        }
        for k in 0..<10 { g[doorC + k / 4, apex - 1 - k] = 0x3A3A44 }
        hline(&g, doorC - 3, apex - 7, 8, 0x3A3A44)
        // Rosetón roto
        let ry = apex + 48
        for y in -13...13 {
            for x in -13...13 {
                let d2 = x * x + y * y
                guard d2 <= 169 else { continue }
                if d2 > 132 { g[doorC + x, ry + y] = d2 > 156 ? 0xD2CED8 : 0x6A6674; continue }
                let a = (atan2(Double(y), Double(x)) + Double.pi) / (2 * Double.pi) * 8
                var c: UInt32 = 0x16121C
                if hash(Int(a), 0, seed) % 3 == 0 && d2 > 20 { c = [0x9A2A2A, 0x2E4E9A, 0xB08A2A][Int(a) % 3] }
                if Int(a * 10) % 10 == 0 || d2 <= 9 { c = 0x7A7684 }
                g[doorC + x, ry + y] = c
            }
        }
        // Portada: arquivoltas apuntadas, puerta doble atrancada con tablones
        let pa = 24, pBase = base - 1, spring = pBase - 34
        for (k, c) in [(0, UInt32(0xC6C2CE)), (3, 0x8E8A96), (6, 0xA6A2AE), (9, 0x6A6674)] {
            for y in (spring - pa * 2)...pBase {
                for x in (doorC - pa + k)...(doorC + pa - k - 1) where inPointedArch(x, y, cx: doorC, spring: spring, a: pa - k) {
                    g[x, y] = c
                }
            }
        }
        let da = pa - 11
        for y in (spring - da * 2)...pBase {
            for x in (doorC - da)...(doorC + da - 1) where inPointedArch(x, y, cx: doorC, spring: spring, a: da) {
                var c: UInt32 = (x - doorC + 40) % 5 == 0 ? 0x3A2416 : ((x < doorC) ? 0x6A4026 : 0x5A361E)
                if x == doorC || x == doorC - 1 { c = 0x22140C }
                if (y - spring) % 12 == 0 { c = 0x3A3A44 }                                       // herrajes
                g[x, y] = c
            }
        }
        for (dy, dir) in [(10, 1), (20, -1)] {
            for k in -(da + 3)...(da + 3) {
                let x = doorC + k, y = spring + dy + dir * k / 3
                g[x, y] = 0xA87442; g[x, y + 1] = 0x8A5A30; g[x, y + 2] = 0x5A361E; g[x, y - 1] = 0x2A1A10
                if abs(k) == da { g[x, y] = 0x2E2A2A }
            }
        }
        fill(&g, doorC - pa - 2, pBase - 2, pa * 2 + 4, 3, stone[3]); hline(&g, doorC - pa - 2, pBase - 2, pa * 2 + 4, stone[4])
        // Hiedra trepando por la fachada y el campanario, grietas y cascotes
        for (x0, x1, top) in [(fx0 + 2, fx0 + 18, wallTop - 20), (tw0 + 2, tw0 + 14, tTop + 30), (W - 60, W - 40, wallTop + 6)] {
            for x in x0..<x1 {
                let len = 12 + hash(x, seed, 903) % 40
                for k in 0..<len where hash(x, k, seed + 1) % 3 != 0 {
                    let y = base - 6 - k
                    if y < top { break }
                    if g[x, y] != nil { g[x, y] = k % 3 == 0 ? 0x6EA046 : (x % 2 == 0 ? 0x3E7A36 : 0x2E5E2C) }
                }
            }
        }
        var kx = fx1 - 16
        for y in (wallTop - 30)..<(wallTop + 30) { if g[kx, y] != nil { g[kx, y] = ruinLine }; if y % 4 == 0 { kx += 1 } }
        rubblePile(&g, cx: tw1 + 6, base: base, width: 20, tones: stone, seed: seed)
        rubblePile(&g, cx: W - 70, base: base, width: 16, tones: stone, seed: seed + 3)
        return g.outlined()
    }

    /// Ventana ojival de la abadía con la vidriera rota: quedan trozos de color y el plomo.
    private static func brokenLancet(_ g: inout PixelGrid, _ x: Int, _ y: Int, w: Int, h: Int, seed: Int) {
        let a = w / 2, cx = x + a, spring = y + a + 2
        for yy in (y - a)...(y + h) {
            for xx in (x - 2)..<(x + w + 2) where inPointedArch(xx, yy, cx: cx, spring: spring, a: a + 2) {
                g[xx, yy] = inPointedArch(xx, yy, cx: cx, spring: spring, a: a) ? 0x16121C : 0x9C98A4
            }
        }
        let glass: [UInt32] = [0x2E4E9A, 0x9A2A2A, 0xB08A2A, 0x3E7A4A]
        for yy in (y - a)...(y + h) {
            for xx in x..<(x + w) where inPointedArch(xx, yy, cx: cx, spring: spring, a: a) {
                let cell = hash((xx - x) / 3, (yy - y + 40) / 4, seed)
                if yy > y + h - 10 - (cell % 6) || cell % 4 == 0 { g[xx, yy] = glass[cell % 4] }
                if (xx - x) == a || (yy - y) % 8 == 0 { g[xx, yy] = 0x3A3646 }
            }
        }
        fill(&g, x - 3, y + h + 1, w + 6, 2, 0xC6C2CE)
    }

    // MARK: - Puesto del guardabosques

    private static func rangerHut(_ b: Building) -> PixelGrid {
        var (g, W, base, doorC, seed) = canvas(b)
        let M = fieldMargin(b.style)
        let wallTop = base - 46, roofTop = M + 2, eave = wallTop + 4
        let bark: [UInt32] = [0x3A2416, 0x55361E, 0x704A2A, 0x8E6238, 0xAA7C4A]
        // Muro de troncos horizontales
        for y in wallTop..<(base - 5) {
            let ly = (y - wallTop) % 6
            for x in 4..<(W - 4) {
                var i = [4, 3, 2, 2, 1, 0][ly]
                if hash(x / 5, (y - wallTop) / 6, seed) % 7 == 0 && ly == 2 { i = 1 }        // nudo
                if x > W - 10 { i -= 1 }
                g[x, y] = bark[max(0, i)]
            }
        }
        // Cabezas de los troncos en las esquinas
        for cx in [6, W - 7] {
            var y = wallTop + 3
            while y < base - 6 {
                ellipse(&g, cx, y, 3, 2, bark[1]); ellipse(&g, cx, y, 2, 1, 0xC8A070); g[cx, y] = 0x8A6A40
                y += 6
            }
        }
        // Zócalo de piedra
        for y in (base - 5)..<base { for x in 3..<(W - 3) { g[x, y] = ashlarColor(x, y, tones: stoneTones, seed: seed) } }
        // Tejado de tablillas con musgo
        paintRoof(&g, x0: 0, x1: W, top: roofTop, bottom: eave, hip: 16, kind: .slate,
                  tones: [0x3A2614, 0x553A1E, 0x6E4E28, 0x8A6634, 0xA88044], seed: seed)
        for y in roofTop..<eave { for x in 0..<W where noise(Double(x) / 5, Double(y) / 4, seed + 1) > 0.74 { if g[x, y] != nil { g[x, y] = hash(x, y, 4) % 2 == 0 ? 0x4E6A30 : 0x5E7A3A } } }
        tintRect(&g, 4, eave, W - 8, 3, (0.6, 0.6, 0.7))
        // Chimenea de piedra
        let chx = W - 30, chTop = roofTop + 14 - 22
        for y in chTop..<(roofTop + 16) { for x in chx..<(chx + 9) { var c = ashlarColor(x, y, tones: stoneTones, seed: seed + 2); if x > chx + 6 { c = dark(c, 0.75) }; g[x, y] = c } }
        fill(&g, chx - 1, chTop - 3, 11, 3, 0xA4A0AC); hline(&g, chx - 1, chTop - 3, 11, 0xCCC8D2); fill(&g, chx + 1, chTop - 4, 7, 1, 0x1E1A1E)
        // Puerta, ventana encendida y cornamenta
        door(&g, doorC, base, width: 14, height: 24, wood: 0x5A3A22, stoneFrame: false, double: false)
        window(&g, doorC + 20, wallTop + 12, shutter: 0x3E5A2A, lit: true, flowers: nil, small: true)
        window(&g, doorC - 34, wallTop + 12, shutter: 0x3E5A2A, lit: true, flowers: nil, small: true)
        let ay = wallTop + 4
        fill(&g, doorC - 2, ay, 5, 3, 0x8A6A4A)
        for side in [-1, 1] {
            for k in 0..<7 { g[doorC + side * (3 + k), ay - k / 2] = 0xE6DCC4 }
            g[doorC + side * 5, ay - 3] = 0xE6DCC4; g[doorC + side * 5, ay - 4] = 0xE6DCC4; g[doorC + side * 8, ay - 5] = 0xE6DCC4
        }
        // Leña apilada, farol y una piel tendida
        let wx = doorC < W / 2 ? W - 26 : 8
        for row in 0..<3 {
            for k in 0..<(5 - row) {
                let cx = wx + 2 + k * 4 + row * 2, cy = base - 4 - row * 4
                ellipse(&g, cx, cy, 2, 2, bark[1]); g[cx, cy] = 0xC8A070; g[cx - 1, cy - 1] = 0xD8B888
            }
        }
        fill(&g, doorC + 10, base - 28, 3, 4, 0x2E2E3A); g[doorC + 11, base - 27] = 0xFFD070
        let px = doorC < W / 2 ? 14 : W - 30
        for y in 0..<14 { let hw = 5 + (y < 7 ? y / 2 : (14 - y) / 2); for x in -hw...hw { g[px + 8 + x, wallTop + 10 + y] = (x + y) % 3 == 0 ? 0x7A5634 : 0x9A7046 } }
        return g.outlined()
    }

    // MARK: - Atalaya derruida

    private static func watchtower(_ b: Building) -> PixelGrid {
        var (g, W, base, doorC, seed) = canvas(b)
        let stone: [UInt32] = [0x56586A, 0x6E7084, 0x868A9C, 0x9EA2B4, 0xB6BACA]
        let x0 = 12, x1 = W - 12
        // Silueta rota de arriba: más alta a la izquierda
        func topY(_ x: Int) -> Int {
            let t = Double(x - x0) / Double(x1 - x0)
            return 34 + Int(t * 26) + Int((noise(Double(x) / 4, 1, seed) - 0.5) * 14) + (x > x1 - 14 ? (x - (x1 - 14)) * 2 : 0)
        }
        for x in x0..<x1 {
            let ty = topY(x)
            for y in ty..<base {
                var c = ashlarColor(x, y, tones: stone, seed: seed)
                if x < x0 + 3 { c = light(c, 1.1) } else if x > x1 - 8 { c = dark(c, 0.78) }
                if y > base - 8 && noise(Double(x) / 3, Double(y) / 2, seed + 1) > 0.5 { c = mix(c, 0x4E6A3E, 0.6) }
                g[x, y] = c
            }
            // Nieve en el borde roto
            g[x, ty] = 0xF2F6FA; if hash(x, seed, 904) % 2 == 0 { g[x, ty + 1] = 0xD6E0EA }
            g[x, ty - 1] = ruinLine
        }
        // Almenas que quedan a la izquierda
        for mx in [x0, x0 + 12] {
            let ty = topY(mx + 3)
            for y in (ty - 7)..<ty { for x in mx..<(mx + 7) { g[x, y] = x == mx ? stone[4] : (x == mx + 6 ? stone[1] : stone[3]) } }
            hline(&g, mx, ty - 7, 7, 0xF2F6FA); hline(&g, mx, ty - 8, 7, ruinLine)
        }
        // Cornisa y vigas del cadalso que asoman rotas
        let ledge = base - 96
        for x in x0..<x1 { g[x, ledge] = stone[4]; g[x, ledge + 1] = stone[1]; if x % 3 != 0 { g[x, ledge - 1] = 0xEEF2F8 } }
        for (bx, len, dir) in [(x1 - 1, 12, 1), (x0 - 1, 8, -1)] {
            for k in 0..<len { let x = bx + dir * k; fill(&g, x, ledge + 3 + k / 5, 1, 3, k % 2 == 0 ? 0x5A3A22 : 0x6E4A2C); g[x, ledge + 2 + k / 5] = 0xF2F6FA }
        }
        // Saeteras
        for (sx, sy) in [(doorC + 16, base - 70), (x0 + 14, base - 112), (doorC + 20, base - 128)] {
            if sy > topY(sx) + 4 { fill(&g, sx, sy, 3, 10, 0x14121A); g[sx, sy + 10] = 0xF2F6FA; g[sx + 1, sy + 10] = 0xF2F6FA; g[sx + 2, sy + 10] = 0xDCE4EE }
        }
        // Estandarte desgarrado de Valdehierro
        let fx = x0 + 22, fy = ledge + 6
        hline(&g, fx - 1, fy - 1, 14, 0x4A3020)
        for y in 0..<22 {
            for x in 0..<12 {
                if y > 14 && (x + y) % 4 == 0 { continue }
                if y > 18 && x > 6 { continue }
                var c: UInt32 = x == 0 ? 0x5E7AA8 : (x > 9 ? 0x2A3E66 : 0x3E5888)
                if x >= 4 && x <= 7 && y >= 5 && y <= 8 { c = 0xB8A050 }
                g[fx + x, fy + y] = c
            }
        }
        // Puerta y cascotes con nieve
        door(&g, doorC, base, width: 14, height: 22, wood: 0x4A3020, stoneFrame: true, double: false)
        rubblePile(&g, cx: x1 + 2, base: base, width: 18, tones: stone, seed: seed, snow: true)
        rubblePile(&g, cx: x0 + 4, base: base, width: 10, tones: stone, seed: seed + 1, snow: true)
        return g.outlined()
    }
}
