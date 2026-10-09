import Foundation
import GameCore

/// Árboles y farolas: sprites aparte para que los personajes puedan pasar por detrás.
extension TownArt {
    // MARK: - Árboles

    /// Árbol con copa voluminosa (variantes: roble, manzano y pino). La sombra la pinta el suelo.
    static func tree(variant: Int) -> PixelGrid { trees[((variant % trees.count) + trees.count) % trees.count] }

    /// 0-2: roble, manzano y pino del pueblo; 3 en adelante: árboles del campo (`FieldArt+Trees.swift`).
    private static let trees: [PixelGrid] = (0..<3).map { makeTree($0) } + fieldTrees

    private static func makeTree(_ variant: Int) -> PixelGrid {
        let W = 46, H = 56
        var g = PixelGrid(width: W, height: H)
        let cx = W / 2
        trunk(&g, cx, H - 2, top: variant == 2 ? H - 14 : H - 22, wide: variant != 2)
        switch variant {
        case 2: pine(&g, cx, H)
        default:
            let leaves: [UInt32] = variant == 0
                ? [0x173F2A, 0x1F5531, 0x2A6B38, 0x3A8540, 0x4F9E48, 0x6DB853, 0x9AD46A]
                : [0x1E4429, 0x2A5A2E, 0x3A7334, 0x4E8C3A, 0x68A842, 0x86C04E, 0xB6DC72]
            canopy(&g, cx, 22, rx: 20, ry: 18, tones: leaves, seed: 11 + variant * 17)
            if variant == 1 {
                // Manzanas con brillo
                for (x, y) in [(13, 18), (27, 12), (31, 24), (19, 28), (34, 17), (22, 20), (11, 27)] {
                    g[x, y] = 0xC8343C; g[x + 1, y] = 0xA0222E; g[x, y + 1] = 0x8A1E2A; g[x + 1, y + 1] = 0x7A1622
                    g[x, y - 1] = 0xFF9A8A
                }
            } else {
                // Florecillas blancas sueltas en la copa
                for (x, y) in [(15, 12), (29, 9), (33, 21), (12, 24), (24, 17)] { g[x, y] = 0xF2F6E0 }
            }
        }
        return g.outlined(0x13261A)
    }

    /// Tronco con corteza, raíces y la parte de arriba en sombra bajo la copa.
    static func trunk(_ g: inout PixelGrid, _ cx: Int, _ bottom: Int, top: Int, wide: Bool) {
        let bark: [UInt32] = [0x3A2416, 0x4E3220, 0x65432A, 0x7E5634, 0x9A6E44]
        let hw = wide ? 3 : 2
        for y in top...bottom {
            let flare = y > bottom - 4 ? (y - (bottom - 4)) : 0
            for x in (cx - hw - flare)...(cx + hw + flare) {
                let u = Double(x - cx) / Double(hw + flare + 1)
                var i = Int((0.55 - u * 0.5) * 4.6)
                if hash(x, y / 2, 5) % 5 == 0 { i -= 1 }       // vetas de la corteza
                if y < top + 5 { i -= 2 }                       // sombra de la copa
                g[x, y] = bark[max(0, min(4, i))]
            }
        }
        // Raíces que se abren
        for (dx, dy) in [(-hw - 4, 0), (-hw - 5, 0), (hw + 4, 0), (hw + 5, 0), (-1, 1), (0, 1), (1, 1)] {
            g[cx + dx, bottom + dy] = bark[1]
        }
        g[cx - hw - 3, bottom - 1] = bark[3]
        // Musgo y un nudo
        g[cx - hw, bottom - 2] = 0x5E8E3E; g[cx - hw + 1, bottom - 1] = 0x4E7E36
        g[cx + 1, top + 9] = bark[0]; g[cx + 1, top + 8] = bark[1]
    }

    /// Copa de "coliflor": masas de hojas superpuestas (las de abajo tapan a las de arriba),
    /// luz general arriba-izquierda, luz propia en cada masa y grietas oscuras entre ellas.
    static func canopy(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, rx: Int, ry: Int, tones: [UInt32], seed: Int) {
        var rng = SeededGenerator(seed: UInt64(seed))
        var blobs: [(x: Double, y: Double, r: Double)] = []
        // Anillo exterior y masas interiores
        let ringCount = 9
        for i in 0..<ringCount {
            let a = Double(i) / Double(ringCount) * 2 * Double.pi + Double.random(in: -0.15...0.15, using: &rng)
            let r = Double.random(in: 7.0...8.5, using: &rng)
            blobs.append((Double(cx) + cos(a) * (Double(rx) - r + 1), Double(cy) + sin(a) * (Double(ry) - r + 1), r))
        }
        for i in 0..<4 {
            let a = Double(i) / 4 * 2 * Double.pi + 0.6, d = 0.38
            blobs.append((Double(cx) + cos(a) * Double(rx) * d, Double(cy) + sin(a) * Double(ry) * d - 2, Double.random(in: 8.0...9.5, using: &rng)))
        }
        let n = Double(tones.count)
        for y in (cy - ry - 2)...(cy + ry + 2) {
            for x in (cx - rx - 2)...(cx + rx + 2) {
                var front = -1, frontKey = -1e9, inside = 0
                for (i, b) in blobs.enumerated() {
                    let dx = Double(x) - b.x, dy = Double(y) - b.y
                    if dx * dx + dy * dy <= b.r * b.r {
                        inside += 1
                        let key = b.y + b.r * 0.3
                        if key > frontKey { frontKey = key; front = i }
                    }
                }
                guard front >= 0 else { continue }
                let b = blobs[front]
                let lx = (Double(x) - b.x) / b.r, ly = (Double(y) - b.y) / b.r
                let d = (lx * lx + ly * ly).squareRoot()
                let u = Double(x - cx) / Double(rx), v = Double(y - cy) / Double(ry)
                var l = 0.6 - (u * 0.36 + v * 0.5) * 0.5            // luz general
                l += -(lx * 0.8 + ly) * 0.2 - d * d * 0.12             // luz de la masa
                if inside > 1 && d > 0.8 && ly > -0.4 { l -= 0.3 }     // grieta bajo la masa
                l += (bayer(x, y) - 0.5) * 0.1
                if hash(x, y, seed) % 9 == 0 && d < 0.8 { l += 0.1 }    // textura de hojas
                if hash(x, y, seed + 1) % 11 == 0 { l -= 0.1 }
                g[x, y] = tones[max(0, min(tones.count - 1, Int(l * n)))]
            }
        }
        // Brillos sueltos en el lado iluminado
        for i in 0..<14 {
            let h = hash(i, seed, 9)
            let x = cx - rx + 4 + h % (rx + 4), y = cy - ry + 3 + (h >> 8) % (ry + 2)
            if g[x, y] != nil && g[x, y - 1] != nil { g[x, y] = tones.last! }
        }
    }

    /// Pino de pisos dentados, azulado, con nieve de luz en el lado izquierdo.
    static func pine(_ g: inout PixelGrid, _ cx: Int, _ H: Int) {
        let tones: [UInt32] = [0x10302A, 0x17422F, 0x205636, 0x2D6C3E, 0x3F844A, 0x5AA058]
        let tiers: [(top: Int, bottom: Int, half: Int)] = [(2, 18, 9), (9, 28, 14), (17, 38, 18), (26, 46, 21)]
        for (ti, tier) in tiers.enumerated() {
            for y in tier.top...tier.bottom {
                let t = Double(y - tier.top) / Double(tier.bottom - tier.top)
                var hw = Int(Double(tier.half) * t + 1)
                if y == tier.bottom || y == tier.bottom - 1 { hw += (hash(y, ti, 3) % 2) }
                for x in (cx - hw)...(cx + hw) {
                    // Puntas dentadas en el borde inferior del piso
                    if y >= tier.bottom - 2 && (x + y) % 4 == 0 && abs(x - cx) > 2 { continue }
                    let u = Double(x - cx) / Double(max(1, hw))
                    var l = 0.6 - u * 0.38 - t * 0.25
                    if y > tier.bottom - 4 { l -= 0.18 }
                    if (x * 3 + y * 2 + ti) % 7 == 0 { l += 0.14 }          // ramitas
                    l += (bayer(x, y) - 0.5) * 0.2
                    g[x, y] = tones[max(0, min(tones.count - 1, Int(l * Double(tones.count))))]
                }
            }
        }
        g[cx, 1] = tones[4]; g[cx, 0] = tones[5]
        _ = H
    }

    // MARK: - Farola

    /// Farola de hierro forjado con farol de cristal encendido sobre un pedestal de piedra.
    static let lamp: PixelGrid = {
        var g = PixelGrid(width: 14, height: 44)
        let iron: [UInt32] = [0x1E2030, 0x2E3246, 0x434A64, 0x6A7290]
        // Pedestal de piedra
        fill(&g, 2, 37, 10, 6, 0x8E8A98)
        fill(&g, 2, 37, 10, 1, 0xC6C2CE)
        vline(&g, 2, 37, 6, 0xB4B0BE)
        vline(&g, 11, 37, 6, 0x6A6676)
        hline(&g, 2, 42, 10, 0x5A5666)
        fill(&g, 3, 34, 8, 3, iron[1]); hline(&g, 3, 34, 8, iron[2])
        // Poste con anillos
        fill(&g, 6, 12, 3, 22, iron[1])
        vline(&g, 6, 12, 22, iron[3])
        vline(&g, 8, 12, 22, iron[0])
        for y in [16, 26, 31] { fill(&g, 5, y, 5, 2, iron[1]); hline(&g, 5, y, 5, iron[3]) }
        // Volutas bajo el farol
        g[4, 13] = iron[2]; g[3, 12] = iron[2]; g[3, 11] = iron[2]
        g[10, 13] = iron[1]; g[11, 12] = iron[1]; g[11, 11] = iron[1]
        // Farol: base, cristales encendidos, montantes y sombrerete
        fill(&g, 3, 10, 9, 2, iron[1]); hline(&g, 3, 10, 9, iron[3])
        fill(&g, 4, 3, 7, 7, 0xFFC850)
        fill(&g, 5, 4, 2, 3, 0xFFF6D0)
        fill(&g, 7, 4, 3, 5, 0xFFE08A)
        fill(&g, 4, 8, 7, 2, 0xF0A030)
        vline(&g, 4, 3, 7, iron[2]); vline(&g, 10, 3, 7, iron[0]); vline(&g, 7, 3, 7, iron[1])
        fill(&g, 3, 1, 9, 2, iron[1]); hline(&g, 3, 1, 9, iron[2]); hline(&g, 4, 0, 7, iron[2])
        g[7, 0] = iron[3]
        return g.outlined()
    }()
}
