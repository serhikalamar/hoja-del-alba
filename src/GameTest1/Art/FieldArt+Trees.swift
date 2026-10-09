import Foundation
import GameCore

/// Árboles del campo (variantes de `TownArt.tree(variant:)` a partir de la 3) y qué árbol va en cada casilla `T`.
///
/// | Variante | Árbol |
/// |---|---|
/// | 0, 1, 2 | roble, manzano y pino (los del pueblo) |
/// | 3, 4 | árbol muerto (retorcido / tronchado con un cuervo) |
/// | 5 | pino nevado |
/// | 6 | roble del bosque, oscuro y frondoso |
/// | 7 | roble otoñal (ocres) |
/// | 8 | ciprés |
extension TownArt {
    static let fieldTrees: [PixelGrid] = [deadTree(0), deadTree(1), snowyPine(), oak(darkOakTones, seed: 61), oak(autumnTones, seed: 73), cypress()]

    /// Árbol de una casilla `T`. En el pueblo, el de siempre; en el campo, según el área y la zona.
    /// Lo usan `ExploreScene.buildProps`, el banco de pruebas y la sombra del suelo.
    static func treeVariant(_ map: AreaMap, _ x: Int, _ y: Int) -> Int {
        guard map.kind == .field else { return (x * 7 + y) % 3 }
        let h = hash(x, y, 870) % 100
        let dead = 3 + hash(x, y, 871) % 2
        let border = x < 2 || y < 2 || x >= map.width - 2 || y >= map.height - 2
        let zone = map.zone(at: TilePoint(x, y))?.id ?? ""
        switch map.id {
        case "valdemar.huertos":
            if zone == "valdemar.huertos.trigales" && h < 45 { return dead }
            return h < 45 ? 0 : (h < 75 ? 1 : (h < 88 ? 7 : 2))
        case "valdemar.robleda":
            return h < 45 ? 6 : (h < 68 ? 0 : (h < 82 ? 7 : 2))
        case "valdemar.abadia":
            if border { return h < 40 ? 8 : (h < 72 ? dead : 2) }
            return h < 60 ? dead : (h < 85 ? 8 : 6)
        case "valdemar.pedregal":
            return h < 55 ? dead : 2
        case "valdemar.paso":
            return h < 72 ? 5 : (h < 90 ? 2 : 4)
        default:
            return (x * 7 + y) % 3
        }
    }

    static let darkOakTones: [UInt32] = [0x0E2E20, 0x143E28, 0x1C4E30, 0x286238, 0x387842, 0x50924C, 0x74AE5C]
    static let autumnTones: [UInt32] = [0x4A2414, 0x6A3418, 0x8E4C1E, 0xB06624, 0xCC842C, 0xE0A63E, 0xF0CA6A]

    private static func oak(_ tones: [UInt32], seed: Int) -> PixelGrid {
        let W = 46, H = 56
        var g = PixelGrid(width: W, height: H)
        let cx = W / 2
        trunk(&g, cx, H - 2, top: H - 22, wide: true)
        canopy(&g, cx, 22, rx: 21, ry: 19, tones: tones, seed: seed)
        // Hiedra o un nido de hojas sueltas
        for y in (H - 16)...(H - 6) where hash(y, seed, 872) % 3 == 0 { g[cx - 3 + (y % 2), y] = 0x3E7A36 }
        if tones == autumnTones {
            for (x, y) in [(10, 30), (35, 28), (17, 36), (30, 37)] { g[x, y] = tones[5] }
        }
        return g.outlined(0x13261A)
    }

    /// Árbol muerto: tronco retorcido y ramas desnudas que se abren; la variante 1 está tronchada y tiene un cuervo.
    private static func deadTree(_ v: Int) -> PixelGrid {
        let W = 46, H = 56
        var g = PixelGrid(width: W, height: H)
        let bark: [UInt32] = [0x2A221E, 0x3E342E, 0x564A40, 0x6E6254, 0x8A7C6C]
        let cx = 23, bottom = H - 2, top = v == 0 ? 24 : 30
        var topX = cx
        for y in top...bottom {
            let lean = v == 0 ? Int(sin(Double(y) / 6) * 2) : (bottom - y) / 5
            let flare = y > bottom - 4 ? y - (bottom - 4) : 0
            let hw = 2 + flare + (y > bottom - 12 ? 1 : 0)
            let x0 = cx + lean
            if y == top { topX = x0 }
            for x in (x0 - hw)...(x0 + hw) {
                let u = Double(x - x0) / Double(hw + 1)
                var i = Int((0.6 - u * 0.55) * 4.6)
                if hash(x, y / 3, 873) % 4 == 0 { i -= 1 }
                g[x, y] = bark[max(0, min(4, i))]
            }
        }
        // Raíces
        for (dx, c) in [(-6, 1), (-5, 2), (5, 1), (6, 0)] { g[cx + dx, bottom] = bark[c] }
        // Hueco en el tronco
        g[cx, bottom - 10] = 0x140E0C; g[cx + 1, bottom - 10] = 0x140E0C; g[cx, bottom - 9] = 0x140E0C; g[cx - 1, bottom - 11] = bark[4]
        func branch(_ x: Double, _ y: Double, _ a: Double, _ len: Double, _ w: Int, _ depth: Int) {
            let steps = Int(len)
            var px = x, py = y
            for _ in 0..<steps {
                px += cos(a); py += sin(a)
                let ix = Int(px.rounded()), iy = Int(py.rounded())
                g[ix, iy] = w > 1 ? bark[3] : (depth > 2 ? bark[2] : bark[3])
                if w > 1 { g[ix + 1, iy] = bark[1]; g[ix, iy + 1] = bark[1] }
            }
            guard depth < 4, len > 3 else { return }
            let s = hash(Int(x * 10), Int(y * 10), 874 + v)
            let spread = 0.45 + Double(s % 30) / 100
            branch(px, py, a - spread, len * 0.66, max(1, w - 1), depth + 1)
            if s % 4 != 0 { branch(px, py, a + spread * 0.8, len * 0.6, max(1, w - 1), depth + 1) }
        }
        if v == 0 {
            branch(Double(topX), Double(top), -Double.pi / 2 - 0.5, 10, 2, 0)
            branch(Double(topX), Double(top), -Double.pi / 2 + 0.55, 11, 2, 0)
            branch(Double(topX - 1), Double(top + 8), -Double.pi + 0.5, 8, 2, 1)
        } else {
            // Tronchado: puntas astilladas y una rama grande hacia la derecha
            for (dx, dy) in [(-2, -1), (-1, -3), (0, -1), (1, -4), (2, -2)] { g[topX + dx, top + dy] = bark[4]; g[topX + dx, top + dy + 1] = bark[3] }
            branch(Double(topX + 1), Double(top + 4), -0.6, 13, 2, 0)
            branch(Double(topX - 1), Double(top + 10), -Double.pi + 0.7, 7, 1, 2)
            // Cuervo posado
            let bx = topX + 9, by = top - 4
            for (dx, dy) in [(0, 0), (1, 0), (2, 0), (1, -1), (2, -1), (3, -2), (-1, 1), (0, 1), (1, 1), (2, 1), (-2, 2)] { g[bx + dx, by + dy] = 0x16141C }
            g[bx + 3, by - 2] = 0x16141C; g[bx + 4, by - 2] = 0x8A7A3A; g[bx + 2, by - 2] = 0xC8C8D8
        }
        // Algún liquen y hojas secas que no se han caído
        for i in 0..<6 {
            let h = hash(i, v, 875)
            let x = 8 + h % 30, y = 6 + (h >> 5) % 22
            if g[x, y] != nil { g[x, y] = i % 2 == 0 ? 0x8A7A3A : 0x6E7A4A }
        }
        return g.outlined(0x161012)
    }

    private static func snowyPine() -> PixelGrid {
        let W = 46, H = 56
        var g = PixelGrid(width: W, height: H)
        let cx = W / 2
        trunk(&g, cx, H - 2, top: H - 14, wide: false)
        pine(&g, cx, H)
        // Nieve encima de cada piso (donde no hay nada encima) y en los hombros del lado iluminado
        var snow: [(Int, Int, UInt32)] = []
        for y in 1..<(H - 12) {
            for x in 0..<W where g[x, y] != nil && g[x, y - 1] == nil {
                snow.append((x, y, x < cx + 4 ? 0xFFFFFF : 0xD6E2EE))
                if hash(x, y, 876) % 3 != 0 { snow.append((x, y + 1, x < cx ? 0xE6EEF6 : 0xB8C8DA)) }
            }
        }
        for (x, y, c) in snow { g[x, y] = c }
        return g.outlined(0x13261A)
    }

    private static func cypress() -> PixelGrid {
        let W = 46, H = 56
        var g = PixelGrid(width: W, height: H)
        let cx = W / 2
        trunk(&g, cx, H - 2, top: H - 10, wide: false)
        let tones: [UInt32] = [0x0C2420, 0x123028, 0x1A3E30, 0x24503A, 0x346646, 0x4E7E52]
        for y in 2..<(H - 8) {
            let t = Double(y - 2) / Double(H - 10)
            let hw = Int(2 + sin(min(1, t * 1.25) * Double.pi * 0.62) * 9)
            for x in (cx - hw)...(cx + hw) {
                let u = Double(x - cx) / Double(max(1, hw))
                var l = 0.62 - u * 0.4 - t * 0.12
                if (x * 5 + y * 3) % 9 == 0 { l += 0.12 }
                if (x + y * 2) % 7 == 0 { l -= 0.14 }
                if hash(x, y / 3, 877) % 6 == 0 && abs(u) > 0.7 { continue }
                l += (bayer(x, y) - 0.5) * 0.18
                g[x, y] = tones[max(0, min(tones.count - 1, Int(l * Double(tones.count))))]
            }
        }
        g[cx, 1] = tones[3]; g[cx, 0] = tones[4]
        return g.outlined(0x0E1A16)
    }
}
