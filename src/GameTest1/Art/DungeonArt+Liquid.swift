import Foundation
import GameCore

// Líquido de cada tema y sus orillas:
//   prison  agua sucia con ondas y verdín       sewer  agua verde con ondas, espuma y basura flotando
//   crypt   abismo con niebla violeta            mine   abismo con niebla de polvo y cristales al fondo
//   forge   lava con costra y bordes incandescentes
// La orilla de arriba se ve de lado (talud de piedra o pared de roca que baja); las demás, como un canto.
// Los puentes (`=`) son de tablones sobre el líquido (con cuerdas en la mina y herrajes en la forja).

extension DungeonPainter {
    private enum LiquidKind { case water, abyss, lava }

    private var kind: LiquidKind {
        switch s.theme {
        case .prison, .sewer: .water
        case .crypt, .mine: .abyss
        case .forge: .lava
        }
    }

    /// Oscurece aunque el pixel brille por sí mismo (sombras sobre la lava).
    private mutating func darken(_ x: Int, _ y: Int, _ f: Double) {
        guard let old = c.at(x, y) else { return }
        let i = y * c.w + x
        c.px[i] = 0xFF00_0000 | DColor.mul(old, f)
    }

    // MARK: - Líquido

    mutating func paintLiquid(_ x: Int, _ y: Int) {
        let x0 = x * T, y0 = y * T
        let l = s.liquid
        switch kind {
        case .water:
            // Profundidad: más claro (poco fondo) junto a la orilla, más oscuro en el centro del canal.
            let landL = isLand(x - 1, y), landR = isLand(x + 1, y), landU = isLand(x, y - 1) || isWall(x, y - 1), landD = isLand(x, y + 1)
            for py in y0..<(y0 + T) {
                for px in x0..<(x0 + T) {
                    let lx = px - x0, ly = py - y0
                    var dist = 30
                    if landL { dist = min(dist, lx) }; if landR { dist = min(dist, T - 1 - lx) }
                    if landU { dist = min(dist, ly) }; if landD { dist = min(dist, T - 1 - ly) }
                    let n = Noise.smooth(px, py * 2, 14, 3)
                    var col = n < 0.4 ? l[1] : n < 0.7 ? DColor.mix(l[1], l[2], 0.5) : l[2]
                    let shallow = Double(max(0, 10 - dist)) / 10 + (Noise.bayer(px, py) - 0.5) * 0.3
                    if shallow > 0.55 { col = DColor.mix(col, l[3], 0.45) } else if shallow > 0.2 { col = DColor.mix(col, l[3], 0.2) }
                    else if dist >= 30 && n < 0.3 { col = DColor.mix(col, l[0], 0.6) }
                    // Ondas: rayitas horizontales que siguen una curva suave.
                    let wave = (py + Int(sin(Double(px) / 6 + Double(py / 9)) * 1.6) + 400) % 7
                    if wave == 0 && Noise.smooth(px, py, 6, 8) > 0.5 { col = l[3] }
                    if wave == 0 && Noise.smooth(px, py, 6, 8) > 0.78 { col = l[4] }
                    if wave == 1 && Noise.smooth(px, py, 6, 8) > 0.7 { col = DColor.mix(l[1], l[0], 0.5) }
                    if Noise.hash(px, py, 4) > 0.996 { col = l[4] }
                    c.put(px, py, col)
                }
            }
            c.matRect(x0, y0, T, T, .liquid)
            var d = Dice(x, y, 13)
            if s.theme == .sewer {
                // Basura y verdín flotando, y burbujas.
                for _ in 0..<d.range(1, 3) {
                    let px = x0 + d.range(2, 20), py = y0 + d.range(3, 20)
                    c.hline(px, py, d.range(2, 4), s.moss[d.range(1, 3)])
                    c.put(px + 1, py + 1, s.moss[0])
                }
                if d.chance(0.35) {
                    let px = x0 + d.range(4, 19), py = y0 + d.range(5, 19)
                    c.put(px, py, l[4]); c.put(px + 1, py, l[3]); c.put(px, py + 1, l[3]); c.put(px + 2, py - 1, l[4])
                }
            } else {
                if d.chance(0.3) {
                    let px = x0 + d.range(3, 18), py = y0 + d.range(4, 18)
                    c.hline(px, py, 3, DColor.mix(l[2], 0x6A5A3A, 0.5)); c.put(px + 3, py + 1, DColor.mix(l[2], 0x6A5A3A, 0.3))
                }
            }
        case .abyss:
            let landL = isLand(x - 1, y), landR = isLand(x + 1, y), landD = isLand(x, y + 1)
            for py in y0..<(y0 + T) {
                for px in x0..<(x0 + T) {
                    let lx = px - x0, ly = py - y0
                    var dist = 30
                    if landL { dist = min(dist, lx) }; if landR { dist = min(dist, T - 1 - lx) }
                    if landD { dist = min(dist, T - 1 - ly) }
                    let mist = Double(max(0, 12 - dist)) / 12 * 0.35
                    // Niebla: bandas suaves que se traman sobre la oscuridad.
                    let fog = Noise.smooth(px, py * 2, 18, 5) * 0.7 + Noise.smooth(px, py, 7, 6) * 0.3 + mist
                    var col = l[0]
                    let b = Noise.bayer(px, py)
                    if fog > 0.5 + b * 0.25 { col = l[1] }
                    if fog > 0.66 + b * 0.2 { col = l[2] }
                    if fog > 0.8 + b * 0.15 { col = l[3] }
                    c.put(px, py, col)
                }
            }
            c.matRect(x0, y0, T, T, .liquid)
            var d = Dice(x, y, 13)
            if s.theme == .mine {
                // Cristales que brillan muy al fondo.
                for _ in 0..<d.range(0, 2) {
                    let px = x0 + d.range(2, 21), py = y0 + d.range(6, 21)
                    c.glow(px, py, DColor.mix(s.magic[1], l[0], 0.4)); c.glow(px, py - 1, DColor.mix(s.magic[2], l[0], 0.5))
                }
            } else {
                // Motas de polvo / almas que flotan.
                for _ in 0..<d.range(0, 2) { c.glow(x0 + d.range(2, 21), y0 + d.range(6, 21), DColor.mix(s.magic[1], l[1], 0.5)) }
            }
        case .lava:
            for py in y0..<(y0 + T) {
                for px in x0..<(x0 + T) {
                    let cell = Noise.voronoi(px, py, 9, 41, squash: 1.2)
                    let crust = Noise.hash(cell.id, 3) < 0.42
                    var col: UInt32
                    if crust {
                        // Placa de costra: oscura con canto que brilla.
                        if cell.edge < 1.3 { col = l[3] } else if cell.edge < 2.4 { col = l[1] } else {
                            let n = Noise.hash(px, py, 2)
                            col = n < 0.3 ? 0x3A1410 : n < 0.8 ? 0x521C12 : 0x6A2614
                            if cell.edge < 3.4 && Double(px) + 0.5 < cell.cx { col = 0x7A3018 }
                        }
                    } else {
                        // Lava fundida con remolinos.
                        let n = Noise.smooth(px, py, 6, 9)
                        col = n < 0.35 ? l[1] : n < 0.62 ? l[2] : n < 0.85 ? l[3] : l[4]
                        if cell.edge < 1.0 { col = l[1] }
                    }
                    c.glow(px, py, col)
                }
            }
            var d = Dice(x, y, 13)
            if d.chance(0.3) {
                // Burbuja.
                let px = x0 + d.range(4, 18), py = y0 + d.range(5, 18)
                c.glow(px, py, l[4]); c.glow(px + 1, py, l[3]); c.glow(px - 1, py, l[3]); c.glow(px, py - 1, l[4]); c.glow(px, py + 1, l[1])
            }
        }
    }

    // MARK: - Orillas

    mutating func paintShores(_ x: Int, _ y: Int) {
        let k = t(x, y)
        if k == .liquid { liquidEdges(x, y) } else if isLand(x, y) { landEdges(x, y) }
    }

    /// Bordes dentro de la casilla de líquido: talud arriba, espuma o brillo en los lados.
    private mutating func liquidEdges(_ x: Int, _ y: Int) {
        let x0 = x * T, y0 = y * T
        let l = s.liquid, bk = s.bank
        let upLand = isLand(x, y - 1), upWall = isWall(x, y - 1)
        if upLand || upWall {
            let bh = kind == .abyss ? (upWall ? 10 : 14) : 5
            for py in y0..<(y0 + bh) {
                let ly = py - y0
                let f = Double(ly) / Double(bh)
                for px in x0..<(x0 + T) {
                    var col: UInt32
                    switch kind {
                    case .abyss:
                        // Pared de roca que se pierde en la oscuridad.
                        let cell = Noise.voronoi(px, py, 7, 71, squash: 0.6)
                        col = cell.edge < 1 ? bk[0] : DColor.mix(bk[1], bk[3], Noise.hash(cell.id, 1) * 0.8)
                        if cell.edge < 2 && Double(px) + 0.5 < cell.cx { col = DColor.mix(col, bk[3], 0.6) }
                        col = DColor.mix(col, l[0], min(1, f * f * 1.1 + (Noise.bayer(px, py) - 0.5) * 0.25))
                    case .water, .lava:
                        let st = Course.at(px, ly, rowH: 99, cellW: 10, jitter: 2, salt: 9)
                        col = st.left == 0 ? bk[0] : ly == 0 ? bk[3] : ly < 3 ? bk[2] : bk[1]
                    }
                    c.put(px, py, col)
                    c.setMat(px, py, .face)
                }
            }
            let wl = y0 + bh
            switch kind {
            case .water:
                // Línea de agua con espuma y el reflejo oscuro del talud.
                for px in x0..<(x0 + T) {
                    c.put(px, wl, Noise.hash(px, y, 2) > 0.45 ? l[4] : l[3])
                    c.setMat(px, wl, .face)
                    c.shade(px, wl + 1, 0.6); c.shade(px, wl + 2, 0.75); c.shade(px, wl + 3, 0.9)
                    if Noise.hash(px, y, 3) > 0.75 { c.put(px, wl + 2, l[3]) }
                }
                if s.theme == .sewer {
                    for px in x0..<(x0 + T) where Noise.hash(px, y, 5) > 0.5 { c.put(px, wl - 1, s.moss[Noise.hash(px, y, 6) > 0.5 ? 2 : 1]) }
                }
            case .lava:
                for px in x0..<(x0 + T) {
                    c.glow(px, wl - 1, DColor.mix(bk[1], l[1], 0.6))
                    c.glow(px, wl, l[4]); c.glow(px, wl + 1, l[3])
                    if Noise.hash(px, y, 2) > 0.6 { c.glow(px, wl + 2, l[4]) }
                }
            case .abyss:
                break
            }
        }
        // Lados.
        for (dx, side) in [(-1, 0), (1, 1)] where isLand(x + dx, y) {
            let ex = side == 0 ? x0 : x0 + T - 1
            let inward = side == 0 ? 1 : -1
            for py in y0..<(y0 + T) {
                switch kind {
                case .water:
                    c.put(ex, py, Noise.hash(py, x, 4) > 0.4 ? l[3] : l[4])
                    c.shade(ex + inward, py, 0.85)
                case .lava:
                    c.glow(ex, py, l[4]); c.glow(ex + inward, py, l[3])
                    if Noise.hash(py, x, 4) > 0.5 { c.glow(ex + 2 * inward, py, l[3]) }
                case .abyss:
                    // Pared lateral del abismo.
                    let depth = 3
                    for k in 0..<depth {
                        let col = DColor.mix(side == 0 ? bk[3] : bk[1], l[0], Double(k) / Double(depth) + Double(max(0, py - y0 - 12)) / 24)
                        c.put(ex + k * inward, py, col)
                    }
                }
            }
        }
        if isLand(x, y + 1) {
            let ey = y0 + T - 1
            for px in x0..<(x0 + T) {
                switch kind {
                case .water: c.put(px, ey, Noise.hash(px, y, 7) > 0.5 ? l[3] : l[4])
                case .lava: c.glow(px, ey, l[4]); c.glow(px, ey - 1, l[3])
                case .abyss: break
                }
            }
        }
        // Esquinas interiores (tierra en diagonal).
        for (dx, dy) in [(-1, -1), (1, -1)] where isLand(x + dx, y + dy) && !isLand(x + dx, y) && !isLand(x, y + dy) && !isWall(x, y + dy) {
            let cx = dx < 0 ? x0 : x0 + T - 4
            for j in 0..<4 { for i in 0..<4 where (dx < 0 ? i : 3 - i) + j < 4 {
                switch kind {
                case .water: c.put(cx + i, y0 + j, j == 3 - (dx < 0 ? i : 3 - i) ? l[4] : bk[2])
                case .lava: c.glow(cx + i, y0 + j, l[4])
                case .abyss: c.put(cx + i, y0 + j, bk[1])
                }
            } }
        }
    }

    /// Canto de piedra en el suelo firme que da al líquido.
    private mutating func landEdges(_ x: Int, _ y: Int) {
        let x0 = x * T, y0 = y * T
        let f = s.floor, bk = s.bank
        let lavaHot = kind == .lava
        if isWet(x, y + 1) {
            // Bordillo de piedras con su canto iluminado.
            for px in x0..<(x0 + T) {
                let st = Course.at(px, 0, rowH: 99, cellW: 8, jitter: 2, salt: y &* 7)
                let joint = st.left == 0
                c.put(px, y0 + T - 4, joint ? f[0] : f[4])
                c.put(px, y0 + T - 3, joint ? f[0] : f[3])
                c.put(px, y0 + T - 2, joint ? bk[0] : f[2])
                c.put(px, y0 + T - 1, bk[1])
                if lavaHot { c.glow(px, y0 + T - 1, DColor.mix(bk[2], s.liquid[2], 0.5)) }
            }
            c.matRect(x0, y0 + T - 4, T, 4, .face)
        }
        if isWet(x, y - 1) {
            for px in x0..<(x0 + T) {
                c.put(px, y0, bk[0]); c.put(px, y0 + 1, f[4])
                if lavaHot { c.glow(px, y0, s.liquid[1]) }
            }
        }
        if isWet(x - 1, y) {
            for py in y0..<(y0 + T) {
                c.put(x0, py, bk[2]); c.put(x0 + 1, py, f[4])
                if lavaHot { c.glow(x0, py, s.liquid[2]) }
            }
        }
        if isWet(x + 1, y) {
            for py in y0..<(y0 + T) {
                c.put(x0 + T - 1, py, bk[0]); c.put(x0 + T - 2, py, f[1])
                if lavaHot { c.glow(x0 + T - 1, py, s.liquid[1]) }
            }
        }
        // Musgo en el borde del agua.
        if kind == .water {
            var d = Dice(x, y, 19)
            if [isWet(x, y + 1), isWet(x - 1, y), isWet(x + 1, y), isWet(x, y - 1)].contains(true) && d.chance(0.6) {
                let mx = isWet(x - 1, y) ? x0 + 3 : isWet(x + 1, y) ? x0 + T - 4 : x0 + d.range(4, 19)
                let my = isWet(x, y + 1) ? y0 + T - 6 : isWet(x, y - 1) ? y0 + 3 : y0 + d.range(4, 19)
                mossPatch(mx, my, 2, &d)
            }
        }
    }

    // MARK: - Puentes

    /// Sentido de paso: horizontal si el tramo de puente tiene suelo firme a izquierda y derecha.
    private func bridgeHorizontal(_ x: Int, _ y: Int) -> Bool {
        var l = x, r = x, u = y, d = y
        while t(l, y) == .bridge { l -= 1 }
        while t(r, y) == .bridge { r += 1 }
        while t(x, u) == .bridge { u -= 1 }
        while t(x, d) == .bridge { d += 1 }
        let h = isLand(l, y) && isLand(r, y), v = isLand(x, u) && isLand(x, d)
        if h != v { return h }
        if h { return true }
        return isLand(l, y) || isLand(r, y) || !(isLand(x, u) || isLand(x, d))
    }

    mutating func paintBridge(_ x: Int, _ y: Int) {
        let x0 = x * T, y0 = y * T
        let w = s.wood, ir = s.iron
        let rope = s.theme == .mine
        let ropeC: (UInt32, UInt32) = (0xA88A58, 0x6A5434)
        let horizontal = bridgeHorizontal(x, y)
        // Primera fila/columna del tramo: los tablones son piezas enteras de un borde al otro.
        var run = horizontal ? y : x
        while (horizontal ? t(x, run - 1) : t(run - 1, y)) == .bridge { run -= 1 }
        // Gira el dibujo: (a, b) = (a lo largo del tablón, a lo ancho del puente).
        let firstEdge = horizontal ? t(x, y - 1) != .bridge : t(x - 1, y) != .bridge
        let lastEdge = horizontal ? t(x, y + 1) != .bridge : t(x + 1, y) != .bridge
        let startLand = horizontal ? isLand(x - 1, y) : isLand(x, y - 1)
        let endLand = horizontal ? isLand(x + 1, y) : isLand(x, y + 1)
        @inline(__always) func P(_ a: Int, _ b: Int) -> (Int, Int) { horizontal ? (x0 + b, y0 + a) : (x0 + a, y0 + b) }
        // a: 0..<T a lo largo del tablón; b: 0..<T en el sentido de la marcha.
        let a0 = firstEdge ? 4 : 0, a1 = lastEdge ? 19 : T - 1
        // Sombra en el líquido por debajo/derecha del puente.
        if lastEdge {
            for b in 0..<T {
                for (k, f) in [(21, 0.5), (22, 0.62), (23, 0.8)] { let (px, py) = P(k, b); darken(px, py, f) }
            }
        }
        for b in 0..<T {
            let gb = (horizontal ? x0 : y0) + b
            let plank = fdiv(gb, 4), i = gb - plank * 4
            if rope && i == 3 { continue }   // hueco entre tablones: se ve el abismo
            let tone = 1 + Int(Noise.hash(plank, run, 3) * 2.99)
            let joint = Noise.hash(plank, horizontal ? y : x, 4) < 0.35 ? Int(Noise.hash(plank, run, 5) * 18) + 3 : -9
            for a in a0...a1 {
                var col = i == 0 ? w[min(4, tone + 1)] : i == 3 ? w[0] : w[tone]
                if a == a0 && firstEdge { col = w[4] }
                if a == a1 && lastEdge { col = w[0] }
                if a == joint && !rope { col = w[0] }
                if a == joint + 1 && !rope && i < 3 { col = w[min(4, tone + 1)] }
                if i == 1 && Noise.hash(plank, (a + (horizontal ? y0 : x0)) / 5, 5) < 0.12 { col = w[max(0, tone - 1)] }   // veta
                let (px, py) = P(a, b)
                c.put(px, py, col); c.setMat(px, py, .floor)
            }
            // Clavos donde el tablón cruza las vigas.
            if i == 1 && !rope {
                for a in [a0 + 2, a1 - 2] { let (px, py) = P(a, b); c.put(px, py, ir[3]) }
            }
        }
        if s.theme == .forge {
            // Flejes de hierro a lo ancho.
            for a in stride(from: (firstEdge ? 8 : 4), to: a1 - 2, by: 8) {
                for b in 0..<T {
                    let (px, py) = P(a, b), (qx, qy) = P(a + 1, b)
                    c.put(px, py, b % 4 == 1 ? ir[4] : ir[2]); c.put(qx, qy, ir[0])
                }
            }
        }
        // Barandas (o cuerdas) en los bordes del puente.
        for (edge, a) in [(firstEdge, 2), (lastEdge, 19)] where edge {
            for b in 0..<T {
                let (px, py) = P(a, b), (qx, qy) = P(a + 1, b)
                c.put(px, py, rope ? ropeC.0 : w[3]); c.put(qx, qy, rope ? ropeC.1 : w[1])
                c.setMat(px, py, .floor); c.setMat(qx, qy, .floor)
                if !rope && (b + (horizontal ? x0 : y0)) % 12 == 5 {
                    // Balaustre.
                    let (rx, ry) = P(a - 1, b)
                    c.put(rx, ry, w[4])
                }
            }
        }
        // Postes en los extremos, junto al suelo firme.
        for (land, b) in [(startLand, 0), (endLand, T - 4)] where land {
            for a in [firstEdge ? 0 : -1, lastEdge ? 16 : -1] where a >= 0 {
                for da in 0..<7 {
                    for db in 0..<4 {
                        var col = db == 0 ? w[3] : db == 3 ? w[0] : w[2]
                        if da == 0 { col = w[4] }
                        let (px, py) = P(a + da, b + db)
                        c.put(px, py, col); c.setMat(px, py, .floor)
                    }
                }
                if rope { let (px, py) = P(a + 2, b + 1); c.put(px, py, ropeC.0) }
            }
        }
    }
}

// MARK: - Capa animada del líquido (opcional, la conecta el programador)

extension DungeonArt {
    static let liquidFrames = 4

    /// Brillos que se mueven sobre el líquido: ondas en el agua, burbujas y venas que laten en la lava,
    /// motas de niebla en el abismo. Imagen del tamaño de `ground`, casi toda transparente: se pone justo
    /// encima del suelo y se alternan los frames (≈0,25 s cada uno).
    static func liquidOverlay(_ floor: DungeonFloor, frame: Int) -> PixelGrid {
        let s = DungeonStyle.of(floor.theme), T = tile
        var g = PixelGrid(width: floor.width * T, height: floor.height * T)
        let l = s.liquid
        for y in 0..<floor.height {
            for x in 0..<floor.width where floor.tile(x, y) == .liquid {
                let x0 = x * T, y0 = y * T
                // Lo de arriba de la casilla puede ser el talud: se deja libre.
                let top = floor.tile(x, y - 1) == .liquid || floor.tile(x, y - 1) == .bridge ? 0 : 8
                var d = Dice(x, y, 200 + frame)
                switch floor.theme {
                case .prison, .sewer:
                    for _ in 0..<3 {
                        let px = x0 + d.range(2, 18), py = y0 + top + d.range(1, T - top - 3)
                        let len = d.range(2, 5)
                        for i in 0..<len { g[px + i, py] = i == len / 2 ? l[4] : l[3] }
                    }
                case .forge:
                    for _ in 0..<2 {
                        let px = x0 + d.range(3, 20), py = y0 + top + d.range(2, T - top - 3)
                        g[px, py] = l[4]; g[px + 1, py] = l[3]; g[px - 1, py] = l[3]; g[px, py - 1] = l[4]
                    }
                    if d.chance(0.5) { let px = x0 + d.range(2, 20), py = y0 + top + d.range(2, T - top - 3); for i in 0..<4 { g[px + i, py + (i & 1)] = l[3] } }
                case .crypt, .mine:
                    for _ in 0..<2 {
                        let px = x0 + d.range(2, 21), py = y0 + top + d.range(2, T - top - 3)
                        g[px, py] = floor.theme == .mine ? s.magic[2] : l[3]
                        if d.chance(0.5) { g[px + 1, py] = l[2] }
                    }
                }
            }
        }
        return g
    }
}
