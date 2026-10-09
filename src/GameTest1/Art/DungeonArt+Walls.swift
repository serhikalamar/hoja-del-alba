import Foundation
import GameCore

// Paredes en vista 3/4. Una pared con suelo debajo se ve de frente: su cara sube 10 pixeles dentro de la
// casilla de encima (la tapa), así los muros miden 34 pixeles y parecen altos al lado del héroe.
//   tapa oscura con borde iluminado → canto (fy 0-3) → sillería/ladrillo/roca → zócalo (5 px) → sombra en el suelo.
// Encima van las puertas de monstruos, las rejas de celda, las antorchas, la gran puerta del jefe y la
// decoración por semilla (estandartes, cadenas, telarañas, humedad, tuberías, cristales, runas, rejillas de forja).

extension DungeonPainter {
    /// Pixeles que la cara del muro sube dentro de la casilla de encima.
    var faceRise: Int { 10 }

    // MARK: - Tapa

    mutating func paintCap(_ x: Int, _ y: Int) {
        let x0 = x * T, y0 = y * T
        let cp = s.cap
        for py in y0..<(y0 + T) {
            for px in x0..<(x0 + T) {
                c.put(px, py, capColor(px, py))
            }
        }
        c.matRect(x0, y0, T, T, .cap)
        let top = !isWall(x, y - 1), left = !isCap(x - 1, y), right = !isCap(x + 1, y)
        // Bordes: claro arriba e izquierda, más apagado a la derecha, con una línea oscura por dentro.
        if top {
            c.hline(x0, y0, T, cp[4]); c.hline(x0, y0 + 1, T, cp[3]); c.hline(x0, y0 + 2, T, cp[0])
            c.matRect(x0, y0, T, 2, .face)
        }
        if left {
            c.vline(x0, y0, T, cp[4]); c.vline(x0 + 1, y0, T, cp[3]); c.vline(x0 + 2, y0 + (top ? 2 : 0), T - (top ? 2 : 0), cp[0])
            c.matRect(x0, y0, 2, T, .face)
        }
        if right {
            c.vline(x0 + T - 1, y0, T, cp[3]); c.vline(x0 + T - 2, y0, T, cp[2]); c.vline(x0 + T - 3, y0 + (top ? 2 : 0), T - (top ? 2 : 0), cp[0])
            c.matRect(x0 + T - 2, y0, 2, T, .face)
        }
        if top && left { c.put(x0, y0, cp[3]) }
        if top && right { c.put(x0 + T - 1, y0, cp[2]) }
        // Esquinas interiores: el borde dobla la esquina.
        if !top && !left && !isWall(x - 1, y - 1) {
            c.put(x0, y0, cp[4]); c.put(x0 + 1, y0, cp[3]); c.put(x0, y0 + 1, cp[3])
            c.put(x0 + 2, y0, cp[0]); c.put(x0 + 2, y0 + 1, cp[0]); c.put(x0, y0 + 2, cp[0]); c.put(x0 + 1, y0 + 2, cp[0])
        }
        if !top && !right && !isWall(x + 1, y - 1) {
            c.put(x0 + T - 1, y0, cp[3]); c.put(x0 + T - 2, y0, cp[2]); c.put(x0 + T - 1, y0 + 1, cp[2])
            c.put(x0 + T - 3, y0, cp[0]); c.put(x0 + T - 3, y0 + 1, cp[0]); c.put(x0 + T - 1, y0 + 2, cp[0]); c.put(x0 + T - 2, y0 + 2, cp[0])
        }
        // Detalle: grietas finas y, según el tema, musgo o brasas en la tapa.
        var d = Dice(x, y, 3)
        if d.chance(0.3) {
            var px = x0 + d.range(5, 18), py = y0 + d.range(4, 12)
            for _ in 0..<d.range(3, 6) { c.put(px, py, cp[0]); px += d.range(-1, 1); py += 1 }
        }
        if s.theme == .sewer && d.chance(0.25) {
            for _ in 0..<d.range(3, 7) { c.put(x0 + d.range(3, 20), y0 + d.range(3, 12), s.moss[d.range(0, 1)]) }
        }
        if s.theme == .forge && d.chance(0.15) { c.glow(x0 + d.range(4, 19), y0 + d.range(4, 12), s.magic[0]) }
    }

    func capColor(_ px: Int, _ py: Int) -> UInt32 {
        let cp = s.cap
        var col: UInt32
        if s.theme == .mine {
            let cell = Noise.voronoi(px, py, 9, 61)
            if cell.edge < 1 { return cp[0] }
            col = DColor.mix(cp[1], cp[2], Noise.hash(cell.id, 2))
        } else {
            let st = Course.at(px, py + 3, rowH: 8, cellW: s.theme == .sewer ? 10 : 14, jitter: s.theme == .sewer ? 0 : 3,
                               salt: 17, halfBond: s.theme == .sewer)
            if st.left == 0 || st.top == 0 { return cp[0] }
            col = DColor.mix(cp[1], cp[2], 0.2 + 0.8 * Noise.hash(st.id, 2))
        }
        if Noise.hash(px, py, 9) < 0.06 { col = cp[0] }
        return col
    }

    // MARK: - Cara del muro

    /// Primera fila (pixel absoluto) de la cara del muro de la casilla (x, y).
    func faceTop(_ x: Int, _ y: Int) -> Int { isWall(x, y - 1) ? y * T - faceRise : y * T + 8 }

    mutating func paintFace(_ x: Int, _ y: Int) {
        let x0 = x * T, y0 = y * T
        let tall = isWall(x, y - 1)
        let top = faceTop(x, y), bottom = y0 + T
        if !tall {
            // Muro de una sola fila con suelo encima: un poco de tapa arriba.
            paintCap(x, y)
        }
        let salt = y &* 131
        for py in top..<bottom {
            let fy = py - top, fb = bottom - 1 - py
            for px in x0..<(x0 + T) {
                c.put(px, py, faceColor(px, py, fy, fb, salt))
            }
        }
        c.matRect(x0, top, T, bottom - top, .face)

        // Lados: esquina exterior (canto) o interior (sombra del muro que sobresale).
        let w = s.wall
        let leftOpen = !isWall(x - 1, y), rightOpen = !isWall(x + 1, y)
        if leftOpen {
            for py in (top + 1)..<bottom { c.put(x0, py, w[4]); c.mix(x0 + 1, py, w[4], 0.35) }
        } else if isCap(x - 1, y) {
            for py in top..<bottom { c.shade(x0, py, 0.55); c.shade(x0 + 1, py, 0.7); c.shade(x0 + 2, py, 0.85) }
        }
        if rightOpen {
            for py in (top + 1)..<bottom { c.put(x0 + T - 1, py, w[0]); c.mix(x0 + T - 2, py, w[0], 0.5) }
        } else if isCap(x + 1, y) {
            for py in top..<bottom { c.put(x0 + T - 1, py, w[0]); c.shade(x0 + T - 2, py, 0.8) }
        }
        faceDetails(x, y, top)
    }

    /// Color de la cara del muro. `fy` = filas desde arriba de la cara; `fb` = filas desde abajo.
    func faceColor(_ px: Int, _ py: Int, _ fy: Int, _ fb: Int, _ salt: Int) -> UInt32 {
        let w = s.wall
        // Zócalo.
        if fb <= 4 {
            if fb == 4 { return w[4] }
            if fb == 0 { return w[0] }
            let st = Course.at(px, 0, rowH: 99, cellW: 16, jitter: 3, salt: salt + 7)
            if st.left == 0 { return w[0] }
            if st.left == 1 { return DColor.mix(w[3], w[2], 0.3) }
            return fb == 3 ? w[3] : fb == 1 ? DColor.mix(w[1], w[0], 0.3) : w[2]
        }
        if fb == 5 { return w[0] }
        // Canto superior (en la mina, la roca acaba irregular).
        if s.theme == .mine {
            let jag = Int(Noise.smooth(px, salt, 5, 2) * 4)
            if fy < jag { return s.cap[fy == jag - 1 ? 4 : 2] }
            if fy == jag { return s.cap[4] }
            if fy == jag + 1 { return w[3] }
            if fy == jag + 2 { return w[0] }
            if fy < 4 { return w[2] }
        }
        switch fy {
        case 0: return s.cap[4]
        case 1: return w[3]
        case 2: return w[2]
        case 3: return w[0]
        default: break
        }
        let my = fy - 4
        var col: UInt32
        switch s.theme {
        case .prison:
            let st = Course.at(px, my, rowH: 8, cellW: 13, jitter: 3, salt: salt)
            if st.left == 0 || st.top == 0 { return w[0] }
            col = DColor.mix(w[1], w[3], 0.15 + 0.7 * Noise.hash(st.id, 1))
            if st.top == 1 { col = DColor.mix(col, w[4], 0.5) } else if st.left == 1 { col = DColor.mix(col, w[4], 0.3) }
            else if st.bottom == 0 { col = DColor.mix(col, w[0], 0.45) } else if st.right == 0 { col = DColor.mix(col, w[0], 0.3) }
        case .crypt:
            if my < 5 {
                // Friso de dentículos.
                if my == 4 { return w[0] }
                if my == 0 { return w[3] }
                let k = ((px % 6) + 6) % 6
                return k < 3 ? (k == 0 ? w[4] : w[3]) : (k == 5 ? w[0] : w[1])
            }
            let st = Course.at(px, my - 5, rowH: 10, cellW: 20, jitter: 2, salt: salt)
            if st.left == 0 || st.top == 0 { return w[0] }
            col = DColor.mix(w[1], w[3], 0.3 + 0.4 * Noise.hash(st.id, 1))
            if st.top == 1 || st.left == 1 { col = DColor.mix(col, w[4], 0.45) }
            else if st.bottom == 0 || st.right == 0 { col = DColor.mix(col, w[0], 0.4) }
            return col
        case .sewer:
            let st = Course.at(px, my, rowH: 4, cellW: 9, jitter: 0, salt: salt, halfBond: true)
            if st.left == 0 || st.top == 0 { return w[0] }
            let h = Noise.hash(st.id, 1)
            col = h < 0.15 ? DColor.mix(w[1], 0x5A2E22, 0.4) : DColor.mix(w[1], w[3], 0.2 + 0.7 * h)
            if st.top == 1 { col = DColor.mix(col, w[4], 0.4) } else if st.right == 0 { col = DColor.mix(col, w[0], 0.3) }
        case .mine:
            let cell = Noise.voronoi(px, py, 9, salt &+ 3, squash: 1.3)
            if cell.edge < 1 { return w[0] }
            let dx = Double(px) + 0.5 - cell.cx, dy = Double(py) + 0.5 - cell.cy
            col = DColor.mix(w[1], w[3], 0.2 + 0.6 * Noise.hash(cell.id, 1))
            if cell.edge < 2.4 { col = dx + dy < 0 ? DColor.mix(col, w[4], 0.5) : DColor.mix(col, w[0], 0.45) }
        case .forge:
            let st = Course.at(px, my, rowH: 12, cellW: 17, jitter: 4, salt: salt)
            if st.left == 0 || st.top == 0 { return w[0] }
            col = DColor.mix(w[1], w[3], 0.15 + 0.6 * Noise.hash(st.id, 1))
            if st.top == 1 { col = DColor.mix(col, w[4], 0.5) } else if st.left == 1 { col = DColor.mix(col, w[4], 0.25) }
            else if st.bottom == 0 || st.right == 0 { col = DColor.mix(col, w[0], 0.45) }
        }
        let n = Noise.hash(px, py, 4)
        if n < 0.06 { col = DColor.mul(col, 0.85) } else if n > 0.98 { col = DColor.mix(col, w[4], 0.4) }
        return col
    }

    /// Variación de cada tramo de muro: grietas, humedad, musgo en el zócalo, hollín, grietas de brasa.
    private mutating func faceDetails(_ x: Int, _ y: Int, _ top: Int) {
        let x0 = x * T, y0 = y * T
        let w = s.wall
        var d = Dice(x, y, 41)
        if d.chance(0.25) {
            // Grieta en la cara.
            var px = x0 + d.range(4, 19), py = top + d.range(6, 14)
            for _ in 0..<d.range(5, 10) {
                c.put(px, py, w[0]); c.mix(px + 1, py, w[4], 0.3)
                px += d.range(-1, 1); py += 1
            }
        }
        if d.chance(0.18) {
            // Sillar desconchado.
            let px = x0 + d.range(3, 17), py = top + d.range(8, 20)
            c.rect(px, py, 4, 2, w[1]); c.hline(px, py, 4, w[0]); c.put(px + 4, py + 1, w[3])
        }
        switch s.theme {
        case .prison, .sewer, .crypt:
            if d.chance(s.theme == .crypt ? 0.2 : 0.4) {
                // Chorreón de humedad que baja desde el canto.
                let cx = x0 + d.range(3, 19)
                let len = d.range(8, 20)
                for i in 0..<len {
                    let py = top + 4 + i
                    let wobble = Int(Noise.hash(cx, py / 3, 8) * 2.0)
                    c.shade(cx + wobble, py, 0.8); c.shade(cx + wobble + 1, py, 0.88)
                    if i < len / 2 { c.shade(cx + wobble - 1, py, 0.9) }
                    if s.theme == .sewer && i < 4 { c.put(cx + wobble, py, s.moss[1]) }
                }
                c.put(cx, top + 4 + len, s.liquid[3])
            }
            if s.theme != .crypt {
                // Musgo que sube por el zócalo.
                let amount = s.theme == .sewer ? 0.85 : 0.45
                if d.chance(amount) {
                    let salt = d.int(999)
                    for px in x0..<(x0 + T) {
                        let hgt = Int(Noise.smooth(px, y, 5, salt) * 9) - 2
                        guard hgt > 0 else { continue }
                        for k in 0..<hgt {
                            let py = y0 + T - 1 - k
                            let m = k == hgt - 1 ? s.moss[3] : Noise.hash(px, py, salt) > 0.5 ? s.moss[2] : s.moss[1]
                            c.put(px, py, m)
                        }
                        if Noise.hash(px, 3, salt) > 0.85 { c.put(px, y0 + T - hgt - 1, s.moss[3]) }
                    }
                }
            }
        case .mine:
            if d.chance(0.2) {
                // Veta de mineral.
                var px = x0 + d.range(2, 10), py = top + d.range(8, 20)
                for _ in 0..<d.range(5, 9) {
                    c.put(px, py, 0x8A7A5A); c.put(px, py + 1, 0x5A4A36)
                    if d.chance(0.25) { c.glow(px, py, s.magic[2]) }
                    px += 1; py += d.range(-1, 1)
                }
            }
        case .forge:
            if d.chance(0.3) {
                // Grieta incandescente.
                var px = x0 + d.range(4, 19), py = top + d.range(8, 14)
                for i in 0..<d.range(5, 9) {
                    c.glow(px, py, i % 3 == 0 ? s.magic[2] : s.magic[1])
                    c.mix(px + 1, py, s.magic[0], 0.5)
                    px += d.range(-1, 1); py += 1
                }
                extraLights.append(DLight(x: Double(px), y: Double(py - 4), r: 26, k: 0.3))
            }
            // Hollín que sube desde abajo.
            for px in x0..<(x0 + T) {
                let hgt = Int(Noise.smooth(px, y, 6, 3) * 12)
                for k in 0..<hgt { c.shade(px, top + k, 0.8 + Double(k) * 0.015) }
            }
        }
    }

    // MARK: - Puertas, rejas y antorchas

    mutating func paintWallFeature(_ x: Int, _ y: Int) {
        var d = Dice(x, y, 57)
        switch t(x, y) {
        case .gate: gate(x, y, &d)
        case .bars: cell(x, y, &d)
        case .torch: sconce(x, y, &d)
        default: break
        }
    }

    /// Arco con dovelas y rastrillo de hierro; detrás, oscuridad (a veces, ojos).
    private mutating func gate(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let st = s.theme == .mine ? s.wood : s.stone
        let ir = s.iron
        let cx = Double(x0) + 12, springY = Double(y0) + 2   // arranque del arco
        let r = 8.0, ring = 11.5
        let top = y0 - 9, bottom = y0 + T - 2
        for py in top...bottom {
            for px in (x0 + 1)...(x0 + 22) {
                let dx = Double(px) + 0.5 - cx, dy = Double(py) + 0.5 - springY
                let dist = dy < 0 ? (dx * dx + dy * dy).squareRoot() : abs(dx)
                if dist < r {
                    // Hueco: oscuro arriba, se adivina el suelo abajo.
                    let f = Double(py - top) / Double(bottom - top)
                    var col = DColor.mix(0x040406, 0x14141A, f * f)
                    if py > bottom - 3 { col = DColor.mix(s.floor[1], 0x000000, 0.55) }
                    c.put(px, py, col)
                    c.setMat(px, py, .cap)
                } else if dist < ring {
                    // Dovelas (arco) o sillares de la jamba.
                    var col: UInt32
                    if dy < 0 {
                        let ang = atan2(dy, dx) + Double.pi   // 0...pi en la parte de arriba
                        let seg = ang / (Double.pi / 7)
                        let edge = seg - seg.rounded(.down)
                        if edge < 0.12 { col = st[0] } else {
                            col = Noise.hash(Int(seg), y, 3) < 0.5 ? st[2] : DColor.mix(st[2], st[3], 0.5)
                            if dist > ring - 1.2 { col = st[1] } else if dist < r + 1.2 { col = dx < 0 ? st[4] : st[3] }
                        }
                        // Clave más grande.
                        if abs(dx) < 2.5 && dist > r { col = abs(dx) < 1.5 ? st[3] : st[0] }
                    } else {
                        let k = (py - y0 + 40) / 6
                        let ly = (py - y0 + 40) % 6
                        if ly == 0 { col = st[0] } else {
                            col = k & 1 == 0 ? st[2] : DColor.mix(st[2], st[3], 0.4)
                            if dist < r + 1.2 { col = dx < 0 ? st[4] : st[1] } else if dist > ring - 1.2 { col = st[1] }
                        }
                    }
                    c.put(px, py, col)
                    c.setMat(px, py, .face)
                }
            }
        }
        // Ojos en la oscuridad.
        if d.chance(0.45) {
            let ex = x0 + d.range(7, 13), ey = y0 + d.range(-2, 6)
            let eye: UInt32 = s.theme == .crypt ? 0x9AE8FF : s.theme == .mine ? 0xB4FFEC : s.theme == .sewer ? 0xC8F05A : 0xFF4A2A
            c.glow(ex, ey, eye); c.glow(ex + 3, ey, eye)
        }
        // Rastrillo: barrotes con punta, a medio subir.
        let gateBottom = y0 + 17
        for bx in stride(from: x0 + 5, through: x0 + 18, by: 3) {
            for py in (top + 2)...gateBottom {
                let dx = Double(bx) + 0.5 - cx, dy = Double(py) + 0.5 - springY
                let dist = dy < 0 ? (dx * dx + dy * dy).squareRoot() : abs(dx)
                guard dist < r else { continue }
                c.put(bx, py, ir[2]); c.setMat(bx, py, .face)
                if py == gateBottom { c.put(bx, py, ir[3]) }
            }
            c.put(bx, gateBottom + 1, ir[1]); c.setMat(bx, gateBottom + 1, .face)
        }
        for by in [y0 - 1, y0 + 9] {
            for px in (x0 + 4)...(x0 + 19) where abs(Double(px) + 0.5 - cx) < r {
                c.put(px, by, ir[3]); c.put(px, by + 1, ir[1])
                c.setMat(px, by, .face); c.setMat(px, by + 1, .face)
            }
        }
        // Remaches en los cruces.
        for bx in stride(from: x0 + 5, through: x0 + 18, by: 3) { c.put(bx, y0 - 1, ir[4]); c.put(bx, y0 + 9, ir[4]) }
        // Umbral.
        c.hline(x0 + 3, y0 + T - 2, 18, st[3]); c.hline(x0 + 3, y0 + T - 1, 18, st[0])
        if s.theme == .mine {
            // Marco de madera de la galería con un farol apagado y cristales.
            c.glow(x0 + 3, y0 + 18, s.magic[2]); c.glow(x0 + 3, y0 + 17, s.magic[3]); c.glow(x0 + 20, y0 + 19, s.magic[2])
        }
    }

    /// Celda con rejas (o nicho, desagüe, galería u horno según el tema) con algo dentro.
    private mutating func cell(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let L = t(x - 1, y) == .bars, R = t(x + 1, y) == .bars
        let ox0 = L ? x0 : x0 + 3, ox1 = R ? x0 + T - 1 : x0 + 20
        let oy0 = y0 - 5, oy1 = y0 + 18
        let st = s.theme == .mine ? s.wood : s.stone
        let ir = s.iron
        let furnace = s.theme == .forge
        // Interior.
        for py in oy0...oy1 {
            let f = Double(py - oy0) / Double(oy1 - oy0)
            for px in ox0...ox1 {
                if furnace {
                    let n = Noise.hash(px, py, 3)
                    let heat = f * 0.8 + n * 0.2
                    let col = heat > 0.75 ? s.magic[2] : heat > 0.5 ? s.magic[1] : heat > 0.3 ? s.magic[0] : 0x2A0A06
                    c.glow(px, py, col)
                } else {
                    // Pared del fondo apenas visible.
                    var col = DColor.mix(0x050507, DColor.mul(s.wall[1], 0.35), f)
                    if (py - oy0) % 6 == 5 || ((px + (py - oy0) / 6 * 5) % 10 == 0) { col = DColor.mul(col, 0.7) }
                    c.put(px, py, col)
                    c.setMat(px, py, .cap)
                }
            }
        }
        // Suelo del fondo.
        if !furnace { c.hline(ox0, oy1, ox1 - ox0 + 1, DColor.mul(s.floor[1], 0.6)) }
        cellContents(x0, y0, ox0, ox1, oy0, oy1, &d)
        if furnace { extraLights.append(DLight(x: Double(x0 + 12), y: Double(y0 + 14), r: 46, k: 0.55)) }
        // Dintel.
        c.rect(ox0 - (L ? 0 : 3), oy0 - 3, (ox1 - ox0 + 1) + (L ? 0 : 3) + (R ? 0 : 3), 3, st[2])
        c.hline(ox0 - (L ? 0 : 3), oy0 - 3, (ox1 - ox0 + 1) + (L ? 0 : 3) + (R ? 0 : 3), st[4])
        c.hline(ox0 - (L ? 0 : 3), oy0 - 1, (ox1 - ox0 + 1) + (L ? 0 : 3) + (R ? 0 : 3), st[0])
        c.matRect(ox0 - 3, oy0 - 3, ox1 - ox0 + 7, 3, .face)
        // Jambas.
        if !L { c.rect(x0, oy0, 3, oy1 - oy0 + 1, st[2]); c.vline(x0, oy0, oy1 - oy0 + 1, st[4]); c.vline(x0 + 2, oy0, oy1 - oy0 + 1, st[1]); c.matRect(x0, oy0, 3, oy1 - oy0 + 1, .face) }
        if !R { c.rect(x0 + 21, oy0, 3, oy1 - oy0 + 1, st[2]); c.vline(x0 + 21, oy0, oy1 - oy0 + 1, st[3]); c.vline(x0 + 23, oy0, oy1 - oy0 + 1, st[0]); c.matRect(x0 + 21, oy0, 3, oy1 - oy0 + 1, .face) }
        // Barrotes.
        let barTone = furnace ? [0x1A1210, 0x2A1E1A, 0x3E302A, 0x5A4A40, 0x7A6A5E] : ir
        for px in ox0...ox1 where ((px % 4) + 4) % 4 == 1 {
            c.vline(px, oy0, oy1 - oy0 + 1, barTone[2]); c.vline(px + 1, oy0, oy1 - oy0 + 1, barTone[1])
            c.matRect(px, oy0, 2, oy1 - oy0 + 1, .face)
            c.put(px, oy0 + 2, barTone[4]); c.put(px, oy0 + 3, barTone[3])
            if !furnace && d.chance(0.3) { c.put(px, oy0 + d.range(6, 18), 0x6A3A1E) }   // óxido
        }
        for by in [oy0 + 3, oy1 - 4] {
            c.hline(ox0, by, ox1 - ox0 + 1, barTone[3]); c.hline(ox0, by + 1, ox1 - ox0 + 1, barTone[0])
            c.matRect(ox0, by, ox1 - ox0 + 1, 2, .face)
        }
        if s.theme == .sewer {
            // Agua que sale por la reja.
            for px in ox0...ox1 {
                c.put(px, oy1, s.liquid[2]); c.put(px, oy1 - 1, Noise.hash(px, y, 1) > 0.6 ? s.liquid[4] : s.liquid[3])
            }
            for px in stride(from: ox0 + 1, to: ox1, by: 5) { c.vline(px, oy1 + 1, 5, s.liquid[3]); c.put(px, oy1 + 6, s.liquid[4]) }
        }
    }

    private mutating func cellContents(_ x0: Int, _ y0: Int, _ ox0: Int, _ ox1: Int, _ oy0: Int, _ oy1: Int, _ d: inout Dice) {
        let b = s.bone, ir = s.iron
        let mid = (ox0 + ox1) / 2
        switch s.theme {
        case .prison:
            switch d.int(4) {
            case 0:
                // Esqueleto sentado contra la pared, encadenado.
                skull(mid - 3, oy1 - 13)
                c.vline(mid, oy1 - 7, 5, b[2]); c.hline(mid - 3, oy1 - 6, 7, b[2]); c.hline(mid - 2, oy1 - 4, 5, b[1])
                c.hline(mid - 4, oy1 - 1, 4, b[2]); c.hline(mid + 1, oy1 - 1, 4, b[2])
                c.vline(mid - 6, oy0 + 2, 9, ir[2]); c.put(mid - 5, oy0 + 11, ir[3])
            case 1:
                // Grilletes colgando de la pared.
                for gx in [mid - 5, mid + 4] {
                    for k in 0..<10 where k % 2 == 0 { c.put(gx, oy0 + 3 + k, ir[3]); c.put(gx, oy0 + 4 + k, ir[1]) }
                    c.rect(gx - 1, oy0 + 13, 3, 2, ir[2]); c.put(gx - 1, oy0 + 13, ir[4])
                }
            case 2:
                // Paja y cubo.
                for px in (ox0 + 1)..<(ox1 - 6) {
                    let hgt = 2 + Int(Noise.hash(px, 1, 4) * 3)
                    for k in 0..<hgt { c.put(px, oy1 - 1 - k, k == hgt - 1 ? 0xA8904A : 0x7A6630) }
                }
                c.rect(ox1 - 6, oy1 - 5, 4, 5, s.wood[2]); c.hline(ox1 - 6, oy1 - 5, 4, s.wood[4]); c.hline(ox1 - 6, oy1 - 3, 4, ir[2])
            default:
                // Algo que mira desde el fondo.
                c.ellipse(mid, oy1 - 6, 4, 6, 0x0A0A0E)
                c.glow(mid - 2, oy1 - 9, 0xFFE070); c.glow(mid + 1, oy1 - 9, 0xFFE070)
            }
        case .crypt:
            // Osario: calaveras apiladas y una vela.
            var row = 0
            for by in stride(from: oy1 - 6, to: oy0 + 6, by: -6) {
                for bx in stride(from: ox0 + 1 + (row & 1) * 3, to: ox1 - 4, by: 6) where Noise.hash(bx, by, 5) > 0.15 {
                    skull(bx, by)
                }
                row += 1
            }
            if d.chance(0.5) {
                let vx = ox0 + d.range(2, max(2, ox1 - ox0 - 3))
                c.rect(vx, oy1 - 4, 2, 4, 0xDCD4BC); c.glow(vx, oy1 - 6, s.flame[3]); c.glow(vx, oy1 - 5, s.flame[2])
            }
        case .sewer:
            // Túnel del desagüe: limo verde y una rata.
            for px in ox0...ox1 where Noise.hash(px, 2, 7) > 0.4 { c.vline(px, oy0, 1 + Int(Noise.hash(px, 3, 7) * 4), s.moss[1]) }
            if d.chance(0.5) {
                let rx = ox0 + d.range(2, max(2, ox1 - ox0 - 6))
                c.hline(rx, oy1 - 3, 4, 0x3A3430); c.hline(rx + 1, oy1 - 4, 3, 0x4A4440); c.put(rx + 4, oy1 - 3, 0x5A5450)
                c.glow(rx + 4, oy1 - 4, 0xFF3A2A); c.hline(rx - 3, oy1 - 2, 3, 0x6A4A4A)
            }
        case .mine:
            // Galería con cristales que brillan.
            for _ in 0..<d.range(2, 3) {
                let cx = ox0 + d.range(2, max(2, ox1 - ox0 - 3)), by = oy1 - 1
                let hgt = d.range(4, 8)
                for k in 0..<hgt {
                    c.glow(cx, by - k, s.magic[k > hgt - 3 ? 3 : 2]); c.glow(cx + 1, by - k, s.magic[1])
                }
                c.glow(cx - 1, by - 1, s.magic[2]); c.glow(cx + 2, by - 2, s.magic[1])
                extraLights.append(DLight(x: Double(cx), y: Double(by - 4), r: 30, k: 0.35))
            }
        case .forge:
            // Llamas dentro del horno.
            for fx in stride(from: ox0 + 2, to: ox1 - 1, by: 4) {
                let hgt = d.range(5, 10)
                for k in 0..<hgt { c.glow(fx, oy1 - k, s.flame[k > hgt - 3 ? 4 : 3]); c.glow(fx + 1, oy1 - k + 2, s.flame[2]) }
            }
        }
    }

    /// Soporte de antorcha (la llama la pone el juego encima, con su base en y0 + 10).
    private mutating func sconce(_ x: Int, _ y: Int, _ d: inout Dice) {
        let x0 = x * T, y0 = y * T
        let ir = s.iron, w = s.wood
        let cx = x0 + 11
        // Hollín encima de la llama.
        for py in (y0 - 9)..<(y0 + 8) {
            let f = Double(py - (y0 - 9)) / 17
            for px in (cx - 4)...(cx + 5) {
                let dx = abs(Double(px) - Double(cx) - 0.5)
                if dx < 2 + f * 3 && Noise.hash(px, py, 6) > 0.35 { c.shade(px, py, 0.72 + (1 - f) * 0.1) }
            }
        }
        // Placa en la pared.
        c.rect(cx - 2, y0 + 12, 6, 8, ir[2]); c.hline(cx - 2, y0 + 12, 6, ir[4]); c.vline(cx - 2, y0 + 12, 8, ir[3])
        c.hline(cx - 2, y0 + 19, 6, ir[0]); c.vline(cx + 3, y0 + 12, 8, ir[1])
        c.put(cx, y0 + 14, ir[0]); c.put(cx + 1, y0 + 17, ir[0])
        // Brazo y copa.
        c.rect(cx, y0 + 12, 2, 4, ir[3])
        c.rect(cx - 2, y0 + 9, 6, 3, ir[2]); c.hline(cx - 2, y0 + 9, 6, ir[3]); c.hline(cx - 1, y0 + 11, 4, ir[1])
        c.put(cx - 3, y0 + 9, ir[1]); c.put(cx + 4, y0 + 9, ir[1])
        // Palo de la antorcha (asoma por debajo de la llama).
        c.vline(cx, y0 + 7, 3, w[3]); c.vline(cx + 1, y0 + 7, 3, w[1])
        c.glow(cx, y0 + 8, s.flame[1]); c.glow(cx + 1, y0 + 8, s.flame[0])
        c.matRect(cx - 3, y0 + 7, 8, 13, .face)
        _ = d
    }

    // MARK: - Gran puerta del jefe

    mutating func paintBossGates() {
        for y in 0..<H {
            var x = 0
            while x < W {
                guard t(x, y) == .bossGate else { x += 1; continue }
                var n = 0
                while t(x + n, y) == .bossGate { n += 1 }
                bossGate(x, y, n)
                x += n
            }
        }
    }

    private mutating func bossGate(_ tx: Int, _ ty: Int, _ n: Int) {
        let X0 = tx * T, Y0 = ty * T, Wd = n * T
        let X1 = X0 + Wd - 1
        let st = s.stone, ir = s.iron
        let top = Y0 - 20
        let cx = Double(X0) + Double(Wd) / 2
        var d = Dice(tx, ty, 99)
        // Marco: muro saliente con pilastras.
        for py in top..<(Y0 + T) {
            for px in X0...X1 {
                let ly = py - top
                var col: UInt32
                let st2 = Course.at(px, ly, rowH: 7, cellW: 12, jitter: 2, salt: 5)
                col = st2.left == 0 || st2.top == 0 ? st[0] : DColor.mix(st[1], st[2], Noise.hash(st2.id, 1))
                if st2.top == 1 { col = DColor.mix(col, st[3], 0.5) }
                c.put(px, py, col)
            }
        }
        c.matRect(X0, top, Wd, Y0 + T - top, .face)
        // Cornisa arriba.
        c.hline(X0 - 1, top, Wd + 2, st[4]); c.hline(X0 - 1, top + 1, Wd + 2, st[3]); c.hline(X0 - 1, top + 2, Wd + 2, st[1]); c.hline(X0 - 1, top + 3, Wd + 2, st[0])
        // Pilastras.
        for (px0, lit) in [(X0, true), (X1 - 6, false)] {
            c.rect(px0, top + 4, 7, Y0 + T - top - 4, st[2])
            c.vline(px0, top + 4, Y0 + T - top - 4, lit ? st[4] : st[3])
            c.vline(px0 + 1, top + 4, Y0 + T - top - 4, st[3])
            c.vline(px0 + 5, top + 4, Y0 + T - top - 4, st[1]); c.vline(px0 + 6, top + 4, Y0 + T - top - 4, st[0])
            c.rect(px0 - 1, top + 4, 9, 3, st[3]); c.hline(px0 - 1, top + 4, 9, st[4]); c.hline(px0 - 1, top + 6, 9, st[0])
            c.rect(px0 - 1, Y0 + T - 5, 9, 5, st[2]); c.hline(px0 - 1, Y0 + T - 5, 9, st[4]); c.hline(px0 - 1, Y0 + T - 1, 9, st[0])
            // Estrías.
            c.vline(px0 + 3, top + 9, Y0 + T - top - 16, st[1])
        }
        // Arco rebajado y hojas de la puerta.
        let rx = Double(Wd - 18) / 2, ry = 13.0, spring = Double(Y0) + 1
        let inner = { (px: Int, py: Int) -> Double in
            let dx = (Double(px) + 0.5 - cx) / rx, dy = (Double(py) + 0.5 - spring) / ry
            return dy < 0 ? (dx * dx + dy * dy).squareRoot() : abs(dx)
        }
        let doorTop = Int(spring - ry) - 4
        for py in doorTop..<(Y0 + T - 1) {
            for px in (X0 + 7)...(X1 - 7) {
                let e = inner(px, py)
                let ringW = 4.5 / rx
                if e < 1 {
                    c.put(px, py, doorColor(px, py, X0, X1, Y0, e))
                    c.setMat(px, py, .face)
                } else if e < 1 + ringW {
                    // Dovelas.
                    let dx = Double(px) + 0.5 - cx, dy = (Double(py) + 0.5 - spring) * rx / ry
                    let ang = atan2(dy, dx) + Double.pi
                    let seg = ang / (Double.pi / 11)
                    let edge = seg - seg.rounded(.down)
                    var col = edge < 0.12 ? st[0] : (Int(seg) & 1 == 0 ? st[3] : st[2])
                    if e > 1 + ringW * 0.8 { col = st[0] } else if e < 1 + ringW * 0.25 { col = dx < 0 ? st[4] : st[1] }
                    if py >= Int(spring) { col = (py - Y0) % 5 == 0 ? st[0] : (dx < 0 ? st[3] : st[1]) }
                    c.put(px, py, col)
                }
            }
        }
        // Peldaño.
        c.rect(X0 + 6, Y0 + T - 3, Wd - 12, 3, st[3]); c.hline(X0 + 6, Y0 + T - 3, Wd - 12, st[4]); c.hline(X0 + 6, Y0 + T - 1, Wd - 12, st[0])
        bossDecor(X0, X1, Y0, top, cx, &d)
        _ = ir
    }

    private func doorColor(_ px: Int, _ py: Int, _ X0: Int, _ X1: Int, _ Y0: Int, _ e: Double) -> UInt32 {
        let mid = (X0 + X1) / 2
        let lx = px - X0
        let ir = s.iron
        // Separación central.
        if px == mid || px == mid + 1 { return px == mid ? 0x0A0A0C : ir[0] }
        if e > 0.93 { return 0x0A0A0C }
        let bands = [Y0 - 6, Y0 + 5, Y0 + 15]
        let isBand = bands.contains { py >= $0 && py < $0 + 3 }
        switch s.theme {
        case .prison, .mine:
            if isBand {
                let b = bands.first { py >= $0 && py < $0 + 3 }!
                if py == b { return ir[3] }
                if py == b + 2 { return ir[0] }
                return (lx % 5 == 2) ? ir[4] : ir[2]
            }
            let w = s.wood
            let plank = lx / 5
            let k = lx % 5
            if k == 0 { return w[0] }
            var col = DColor.mix(w[1], w[2], Noise.hash(plank, X0, 4))
            if k == 1 { col = DColor.mix(col, w[3], 0.6) }
            if Noise.hash(px, py / 3, 9) < 0.1 { col = w[1] }
            return col
        case .crypt:
            // Losas de piedra labradas.
            let stn = s.stone
            if isBand { return py % 3 == 0 ? stn[4] : stn[2] }
            let k = (py - Y0 + 30) % 10
            if k == 0 { return stn[0] }
            return lx % 12 == 3 ? stn[1] : (k == 1 ? stn[3] : stn[2])
        case .sewer, .forge:
            // Planchas de hierro remachadas.
            if isBand { return py % 3 == 0 ? ir[3] : ir[1] }
            let k = (lx % 9)
            if k == 0 { return ir[0] }
            if (py - Y0 + 30) % 5 == 0 && k == 4 { return ir[4] }
            return k == 1 ? ir[3] : ir[2]
        }
    }

    private mutating func bossDecor(_ X0: Int, _ X1: Int, _ Y0: Int, _ top: Int, _ cx: Double, _ d: inout Dice) {
        let ir = s.iron
        let mid = (X0 + X1) / 2
        // Emblema sobre la clave.
        let ey = top + 4
        switch s.theme {
        case .crypt:
            // Corona.
            let rows = [
                "a..a..a..a",
                "ba.ba.ba.b",
                "bbabbbbabb",
                "bccdccdccb",
                "bbbbbbbbbb",
            ]
            c.sprite(rows, mid - 4, ey, ["a": 0xFFF0A8, "b": 0xC89A34, "c": 0x8E6420, "d": 0x3AA8D8], glowing: ["d"])
            // Runas que brillan en las jambas.
            for k in 0..<4 {
                c.glow(X0 + 3, Y0 - 8 + k * 6, s.magic[2]); c.glow(X1 - 3, Y0 - 8 + k * 6, s.magic[2])
            }
            extraLights.append(DLight(x: cx, y: Double(ey + 2), r: 40, k: 0.35))
        default:
            // Calavera con cuernos y ojos que brillan.
            let rows = [
                "h..........h",
                "hh.abbbba.hh",
                ".hhbccccbhh.",
                "..bccccccb..",
                "..beecceeb..",
                "..beecceeb..",
                "..bcccdccb..",
                "...bcbcbcb..",
                "...b.b.b.b..",
            ]
            let horn: UInt32 = s.theme == .forge ? 0x2A1E1A : s.theme == .mine ? 0x6A5A46 : 0x5A5048
            let eye: UInt32 = s.theme == .mine ? s.magic[3] : s.theme == .sewer ? 0xC8F05A : 0xFF5A2A
            c.sprite(rows, mid - 5, ey - 2, ["h": horn, "a": s.bone[4], "b": s.bone[1], "c": s.bone[3], "d": s.bone[0], "e": eye],
                     glowing: ["e"])
            extraLights.append(DLight(x: cx, y: Double(ey + 4), r: 30, k: 0.25))
        }
        // Cadenas cruzadas con candado (válvula en las cloacas).
        let lockY = Y0 + 6
        for (sx, dir) in [(X0 + 9, 1), (X1 - 9, -1)] {
            let len = mid - (X0 + 9)
            for i in 0..<len {
                let px = sx + i * dir
                let py = Y0 - 6 + (i * (lockY - (Y0 - 6))) / max(1, len) + Int(sin(Double(i) / Double(len) * Double.pi) * 3)
                c.put(px, py, i % 3 == 0 ? ir[4] : ir[2]); c.put(px, py + 1, ir[0])
            }
        }
        if s.theme == .sewer {
            // Volante de la compuerta.
            c.ellipse(mid, lockY, 6, 6, ir[3]); c.ellipse(mid, lockY, 4, 4, ir[1]); c.ellipse(mid, lockY, 1, 1, ir[4])
            c.line(mid - 5, lockY, mid + 5, lockY, ir[3]); c.line(mid, lockY - 5, mid, lockY + 5, ir[3])
        } else {
            let lockC = s.theme == .crypt ? s.trim : DungeonStyle.goldRamp
            c.rect(mid - 3, lockY - 1, 7, 6, lockC[2]); c.hline(mid - 3, lockY - 1, 7, lockC[3]); c.hline(mid - 3, lockY + 4, 7, lockC[0])
            c.vline(mid - 3, lockY - 1, 6, lockC[3]); c.put(mid, lockY + 1, 0x1A1418); c.put(mid, lockY + 2, 0x1A1418)
            c.rect(mid - 2, lockY - 4, 1, 3, ir[3]); c.rect(mid + 2, lockY - 4, 1, 3, ir[2]); c.hline(mid - 1, lockY - 5, 3, ir[3])
        }
        // Aldabones.
        for kx in [mid - 9, mid + 9] {
            c.put(kx, Y0 + 9, ir[4]); c.put(kx - 1, Y0 + 10, ir[3]); c.put(kx + 1, Y0 + 10, ir[2]); c.put(kx - 1, Y0 + 11, ir[2]); c.put(kx + 1, Y0 + 11, ir[1]); c.put(kx, Y0 + 12, ir[1])
        }
        if s.theme == .forge {
            // Rendija de la puerta incandescente.
            for py in (Y0 - 4)..<(Y0 + T - 3) { c.glow(mid, py, py % 4 == 0 ? s.magic[2] : s.magic[1]) }
            c.hline(X0 + 10, Y0 + T - 4, X1 - X0 - 19, s.magic[1])
            for px in (X0 + 10)..<(X1 - 9) where px % 2 == 0 { c.glow(px, Y0 + T - 4, s.magic[2]) }
            extraLights.append(DLight(x: cx, y: Double(Y0 + 18), r: 40, k: 0.4))
        }
        if s.theme == .mine {
            // Cristales a los pies de las pilastras.
            for bx in [X0 + 2, X1 - 4] {
                for k in 0..<6 { c.glow(bx, Y0 + T - 6 - k, s.magic[k > 3 ? 3 : 2]); c.glow(bx + 1, Y0 + T - 5 - k, s.magic[1]) }
            }
        }
        _ = d
    }

    // MARK: - Decoración de muro

    mutating func paintWallDecor(_ x: Int, _ y: Int) {
        var d = Dice(x, y, 77)
        let x0 = x * T, y0 = y * T
        let top = faceTop(x, y)
        // Telarañas en las esquinas de arriba.
        let cornerL = !isWall(x - 1, y) || isCap(x - 1, y), cornerR = !isWall(x + 1, y) || isCap(x + 1, y)
        if cornerL && d.chance(0.6) { cobweb(x0 + 1, top + 4, flip: false, &d) }
        if cornerR && d.chance(0.6) { cobweb(x0 + T - 2, top + 4, flip: true, &d) }
        // Deja respirar al lado de antorchas, puertas y rejas.
        let noisy: Set<DungeonTile> = [.torch, .gate, .bossGate]
        let busy = noisy.contains(t(x - 1, y)) || noisy.contains(t(x + 1, y))
        let roll = d.unit()
        guard !busy || roll < 0.3 else { return }
        switch s.theme {
        case .prison:
            if roll < 0.22 { banner(x0 + 7, top + 4, &d) }
            else if roll < 0.42 { hangingChains(x0, top, &d) }
            else if roll < 0.5 { cobweb(x0 + 6, top + 4, flip: d.chance(0.5), &d) }
        case .crypt:
            if roll < 0.2 { banner(x0 + 7, top + 4, &d) }
            else if roll < 0.45 { niche(x0, y0, top, &d) }
            else if roll < 0.62 { wallRune(x0 + d.range(6, 14), top + d.range(9, 14), &d) }
        case .sewer:
            if roll < 0.3 { pipeOutlet(x0, y0, top, &d) }
            else if roll < 0.55 { wallPipe(x0, top + d.range(6, 9), &d) }
        case .mine:
            if roll < 0.32 { timber(x0, y0, top, &d) }
            else if roll < 0.6 { crystalCluster(x0 + d.range(4, 16), y0 + T - 2, &d) }
            else if roll < 0.7 { lantern(x0 + d.range(8, 14), top + 6, &d) }
        case .forge:
            if roll < 0.28 { forgeVent(x0, y0, top, &d) }
            else if roll < 0.45 { banner(x0 + 7, top + 4, &d) }
            else if roll < 0.65 { tools(x0, top, &d) }
            else if roll < 0.75 { hangingChains(x0, top, &d) }
        }
    }

    /// Telaraña en una esquina: hilos que salen del rincón y arcos que los unen.
    private mutating func cobweb(_ x: Int, _ y: Int, flip: Bool, _ d: inout Dice) {
        let web: UInt32 = 0xD0D0D8
        let size = Double(d.range(7, 10))
        let dir = flip ? -1.0 : 1.0
        let angles = [0.0, 0.42, 0.85, 1.25, 1.5708]
        for ang in angles {
            let n = Int(size)
            for i in 0...n {
                let r = Double(i)
                c.mix(x + Int((cos(ang) * r * dir).rounded()), y + Int((sin(ang) * r).rounded()), web, i < 2 ? 0.55 : 0.38)
            }
        }
        for ring in [size * 0.4, size * 0.72, size * 0.98] {
            for k in 0..<(angles.count - 1) {
                let a0 = angles[k], a1 = angles[k + 1]
                let p0 = (cos(a0) * ring * dir, sin(a0) * ring), p1 = (cos(a1) * ring * dir, sin(a1) * ring)
                // Arco que cuelga un poco hacia el rincón.
                for i in 0...6 {
                    let tt = Double(i) / 6
                    let sag = sin(tt * Double.pi) * ring * 0.12
                    let px = p0.0 + (p1.0 - p0.0) * tt - dir * sag * 0.7, py = p0.1 + (p1.1 - p0.1) * tt - sag * 0.7
                    c.mix(x + Int(px.rounded()), y + Int(py.rounded()), web, 0.32)
                }
            }
        }
    }

    private mutating func banner(_ x: Int, _ y: Int, _ d: inout Dice) {
        let b = s.banner, tr = s.trim
        let w = 10, h = 17
        // Barra con remates.
        c.hline(x - 2, y, w + 4, tr[2]); c.hline(x - 2, y + 1, w + 4, tr[0]); c.put(x - 3, y, tr[3]); c.put(x + w + 2, y, tr[1])
        for yy in 0..<h {
            let tail = yy >= h - 4
            for xx in 0..<w {
                // Cola en punta (o en dos puntas).
                if tail {
                    let k = yy - (h - 4)
                    if d.chance(0) {}
                    if xx < k || xx >= w - k { continue }
                }
                var col = xx == 0 ? b[3] : xx == w - 1 ? b[0] : xx < 3 ? b[2] : b[1]
                if (yy + xx) % 7 == 0 && xx > 0 && xx < w - 1 { col = DColor.mix(col, b[0], 0.3) }   // pliegues
                if xx == 1 || xx == w - 2 { col = tr[2] }
                c.put(x + xx, y + 2 + yy, col)
            }
        }
        // Emblema (escudo con una cruz/llama/ojo).
        let ex = x + 3, ey = y + 6
        c.rect(ex, ey, 4, 5, s.emblem); c.hline(ex + 1, ey + 5, 2, s.emblem)
        c.vline(ex + 1, ey + 1, 4, DColor.mul(s.emblem, 0.6)); c.hline(ex, ey + 2, 4, DColor.mul(s.emblem, 0.6))
        c.put(ex, ey, DColor.mix(s.emblem, 0xFFFFFF, 0.4))
        // Sombra del estandarte en el muro.
        for yy in 0..<(h - 2) { c.shade(x + w, y + 3 + yy, 0.7) }
    }

    private mutating func hangingChains(_ x0: Int, _ top: Int, _ d: inout Dice) {
        let ir = s.iron
        for cx in [x0 + d.range(4, 8), x0 + d.range(14, 19)] {
            let len = d.range(10, 18)
            c.rect(cx - 1, top + 5, 3, 2, ir[2]); c.put(cx - 1, top + 5, ir[3])
            for k in 0..<len {
                c.put(cx, top + 7 + k, k % 2 == 0 ? ir[3] : ir[1])
                if k % 2 == 0 { c.put(cx + 1, top + 7 + k, ir[0]) }
                c.shade(cx + 2, top + 8 + k, 0.75)
            }
            // Grillete.
            let gy = top + 7 + len
            c.put(cx - 1, gy, ir[3]); c.put(cx + 1, gy, ir[2]); c.put(cx - 2, gy + 1, ir[3]); c.put(cx + 2, gy + 1, ir[1])
            c.put(cx - 1, gy + 2, ir[2]); c.put(cx + 1, gy + 2, ir[1]); c.put(cx, gy + 2, ir[1])
        }
    }

    /// Nicho funerario con una calavera (cripta).
    private mutating func niche(_ x0: Int, _ y0: Int, _ top: Int, _ d: inout Dice) {
        let nx = x0 + 6, ny = top + 8, w = 12, h = 12
        for yy in 0..<h {
            for xx in 0..<w {
                let dx = Double(xx) - 5.5, dy = Double(yy) - 5
                if yy < 5 && dx * dx + dy * dy > 36 { continue }
                c.put(nx + xx, ny + yy, DColor.mix(0x08060C, DColor.mul(s.wall[1], 0.5), Double(yy) / Double(h)))
            }
        }
        c.hline(nx - 1, ny + h, w + 2, s.wall[4]); c.hline(nx - 1, ny + h + 1, w + 2, s.wall[1])
        if d.chance(0.7) { skull(nx + 3, ny + h - 6) } else {
            c.rect(nx + 5, ny + h - 5, 2, 5, 0xDCD4BC); c.glow(nx + 5, ny + h - 7, s.flame[3]); c.glow(nx + 5, ny + h - 6, s.flame[2])
            extraLights.append(DLight(x: Double(nx + 6), y: Double(ny + h - 6), r: 22, k: 0.3))
        }
    }

    private mutating func wallRune(_ x: Int, _ y: Int, _ d: inout Dice) {
        rune(x, y, &d)
        // Marco del grabado.
        c.hline(x - 2, y - 2, 9, s.wall[0]); c.hline(x - 2, y + 6, 9, s.wall[4])
    }

    /// Boca de tubería con verdín que gotea al suelo (cloacas).
    private mutating func pipeOutlet(_ x0: Int, _ y0: Int, _ top: Int, _ d: inout Dice) {
        let ir = s.iron
        let cx = x0 + d.range(8, 15), cy = top + d.range(12, 16)
        c.ellipse(cx, cy, 5, 5, ir[1]); c.ellipse(cx, cy, 4, 4, ir[3]); c.ellipse(cx, cy, 3, 3, 0x0A0C08)
        c.put(cx - 3, cy - 3, ir[4]); c.put(cx - 4, cy - 1, ir[4])
        // Chorro de agua sucia.
        for py in (cy + 2)..<(y0 + T + 4) {
            c.put(cx - 1, py, s.liquid[3]); c.put(cx, py, s.liquid[4]); c.put(cx + 1, py, s.liquid[2])
        }
        c.mix(cx - 1, cy + 4, s.moss[3], 0.6)
        for k in 0..<4 { c.put(cx - 3 + k * 2, y0 + T - 1, s.moss[2]) }
    }

    private mutating func wallPipe(_ x0: Int, _ py: Int, _ d: inout Dice) {
        let ir = s.iron
        c.hline(x0, py, T, ir[4]); c.hline(x0, py + 1, T, ir[3]); c.hline(x0, py + 2, T, ir[2]); c.hline(x0, py + 3, T, ir[1]); c.hline(x0, py + 4, T, ir[0])
        let jx = x0 + d.range(4, 18)
        c.rect(jx, py - 1, 3, 7, ir[2]); c.vline(jx, py - 1, 7, ir[4]); c.vline(jx + 2, py - 1, 7, ir[0])
        for k in 0..<d.range(2, 5) { c.put(jx + 1, py + 6 + k, s.moss[2]) }
        c.shadeRect(x0, py + 5, T, 2, 0.7)
    }

    /// Entibado de madera (mina).
    private mutating func timber(_ x0: Int, _ y0: Int, _ top: Int, _ d: inout Dice) {
        let w = s.wood
        for px in [x0 + 2, x0 + T - 6] {
            c.rect(px, top + 4, 4, y0 + T - top - 4, w[2])
            c.vline(px, top + 4, y0 + T - top - 4, w[3]); c.vline(px + 3, top + 4, y0 + T - top - 4, w[0])
            for k in stride(from: top + 8, to: y0 + T, by: 7) { c.put(px + 1, k, w[1]); c.put(px + 2, k + 1, w[1]) }
            c.shadeRect(px + 4, top + 6, 2, y0 + T - top - 6, 0.7)
        }
        c.rect(x0, top + 2, T, 4, w[2]); c.hline(x0, top + 2, T, w[4]); c.hline(x0, top + 5, T, w[0])
        c.shadeRect(x0, top + 6, T, 2, 0.7)
        c.put(x0 + 4, top + 3, s.iron[4]); c.put(x0 + T - 4, top + 3, s.iron[4])
        _ = d
    }

    /// Racimo de cristales que crece en la base del muro (mina).
    mutating func crystalCluster(_ x: Int, _ y: Int, _ d: inout Dice) {
        let m = s.magic
        let shards = [(0, 7, 2), (3, 11, 3), (7, 6, 2), (-3, 4, 2)]
        for (dx, h, w) in shards where d.chance(0.85) {
            for k in 0..<h {
                let ww = k > h - 3 ? 1 : w
                for i in 0..<ww {
                    let col = i == 0 ? m[3] : m[1]
                    c.glow(x + dx + i, y - k, k == h - 1 ? m[4] : col)
                }
                c.glow(x + dx + ww, y - k, m[0])
            }
        }
        extraLights.append(DLight(x: Double(x + 2), y: Double(y - 6), r: 34, k: 0.45))
    }

    private mutating func lantern(_ x: Int, _ y: Int, _ d: inout Dice) {
        let ir = s.iron
        c.vline(x + 1, y, 4, ir[2])
        c.rect(x - 1, y + 4, 5, 6, ir[1]); c.hline(x - 1, y + 4, 5, ir[3])
        c.glowRect(x, y + 5, 3, 4, s.flame[3]); c.glow(x + 1, y + 6, s.flame[4])
        c.hline(x - 1, y + 10, 5, ir[2])
        extraLights.append(DLight(x: Double(x + 1), y: Double(y + 7), r: 40, k: 0.5))
        _ = d
    }

    /// Respiradero de la forja con brasas detrás de una reja.
    private mutating func forgeVent(_ x0: Int, _ y0: Int, _ top: Int, _ d: inout Dice) {
        let ir = s.iron
        let vx = x0 + 5, vy = top + 9, w = 14, h = 10
        for yy in 0..<h {
            for xx in 0..<w {
                let f = Double(yy) / Double(h)
                let n = Noise.hash(vx + xx, vy + yy, 2)
                let col = f + n * 0.3 > 0.9 ? s.magic[2] : f + n * 0.3 > 0.5 ? s.magic[1] : s.magic[0]
                c.glow(vx + xx, vy + yy, col)
            }
        }
        for xx in stride(from: 0, to: w, by: 3) { c.vline(vx + xx, vy, h, ir[1]); c.put(vx + xx, vy, ir[3]) }
        c.hline(vx - 1, vy - 1, w + 2, ir[3]); c.hline(vx - 1, vy + h, w + 2, ir[0])
        c.vline(vx - 1, vy - 1, h + 2, ir[2]); c.vline(vx + w, vy - 1, h + 2, ir[0])
        extraLights.append(DLight(x: Double(vx + w / 2), y: Double(vy + h / 2), r: 40, k: 0.45))
        _ = d
    }

    /// Herramientas de herrero colgadas (forja).
    private mutating func tools(_ x0: Int, _ top: Int, _ d: inout Dice) {
        let ir = s.iron, w = s.wood
        c.hline(x0 + 2, top + 6, 20, w[2]); c.hline(x0 + 2, top + 7, 20, w[0])
        // Martillo.
        c.vline(x0 + 6, top + 8, 11, w[3]); c.vline(x0 + 7, top + 8, 11, w[1])
        c.rect(x0 + 3, top + 17, 8, 4, ir[2]); c.hline(x0 + 3, top + 17, 8, ir[4]); c.hline(x0 + 3, top + 20, 8, ir[0])
        // Tenazas.
        c.line(x0 + 14, top + 8, x0 + 12, top + 22, ir[3]); c.line(x0 + 15, top + 8, x0 + 17, top + 22, ir[2])
        c.put(x0 + 14, top + 13, ir[4])
        // Herradura o lima.
        c.vline(x0 + 20, top + 8, 10, ir[3]); c.vline(x0 + 21, top + 8, 10, ir[1])
        c.shadeRect(x0 + 22, top + 9, 1, 10, 0.7)
        _ = d
    }
}
