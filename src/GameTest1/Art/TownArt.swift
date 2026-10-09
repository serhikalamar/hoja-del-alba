import CoreGraphics
import Foundation
import GameCore

/// Arte del pueblo explorable (modo historia) en vista 3/4 con luz desde arriba a la izquierda.
/// Cada casilla mide `tile` pixeles de arte.
///
/// El suelo se dibuja en una sola imagen por capas: materiales (hierba, adoquín, losas, madera…),
/// bordes que se rompen, sombras de edificios y árboles, y encima los objetos planos o sólidos
/// (muros, fuente, puestos, muebles). Edificios, árboles y farolas son sprites aparte para poder
/// pasar por detrás de ellos.
///
/// **Contrato** (lo usan `ExploreScene` y el banco de pruebas; no cambiar estas firmas):
/// `tile`, `ground(_:)`, `building(_:open:)`, `tree(variant:)`, `lamp`.
///
/// Ficheros:
/// - `TownArt.swift`: este núcleo y las utilidades de dibujo (ruido, mezclas, volúmenes).
/// - `TownArt+Ground.swift`: suelo del pueblo (hierba, calles, plaza, agua, muros, escalinata, fuente).
/// - `TownArt+Props.swift`: árboles, farolas, arbustos, vallas, puestos del mercado, cajas y barriles.
/// - `TownArt+Buildings.swift`: casas por estilo y el castillo.
/// - `TownArt+Interior.swift`: interiores (suelos, paredes y muebles por edificio).
/// - `TownArt+Animated.swift`: capas animadas opcionales (humo, agua de la fuente, llamas).
enum TownArt {
    static let tile = 24

    // MARK: - Suelo

    static func ground(_ map: AreaMap) -> PixelGrid {
        if map.isInterior { return interiorGround(map) }
        if map.kind == .field { return fieldGround(map) }    // campos de Valdemar (`FieldArt.swift`)
        var g = townGround(map)
        townFieldTiles(&g, map)                                // salidas `>` y bajada `e` del pueblo
        return g
    }

    // MARK: - Utilidades de dibujo

    static func fill(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: UInt32) {
        guard w > 0, h > 0 else { return }
        let x0 = max(0, x), y0 = max(0, y), x1 = min(g.width, x + w), y1 = min(g.height, y + h)
        guard x0 < x1, y0 < y1 else { return }
        for yy in y0..<y1 {
            let row = yy * g.width
            for xx in x0..<x1 { g.pixels[row + xx] = color }
        }
    }

    static func ellipse(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ color: UInt32) {
        guard rx > 0, ry > 0 else { g[cx, cy] = color; return }
        for y in -ry...ry {
            for x in -rx...rx where Double(x * x) / Double(rx * rx) + Double(y * y) / Double(ry * ry) <= 1.0001 {
                g[cx + x, cy + y] = color
            }
        }
    }

    /// Elipse con volumen: tonos de oscuro a claro (luz arriba-izquierda) con tramado entre tonos.
    static func ball(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ tones: [UInt32], seed: Int = 0, texture: Double = 0) {
        guard rx > 0, ry > 0 else { g[cx, cy] = tones.last!; return }
        let n = Double(tones.count)
        for y in -ry...ry {
            for x in -rx...rx {
                let u = Double(x) / Double(rx), v = Double(y) / Double(ry)
                let d = u * u + v * v
                guard d <= 1.0001 else { continue }
                // Luz: más clara arriba a la izquierda, borde de abajo a la derecha oscuro.
                var l = 0.55 - (u * 0.55 + v * 0.75) * 0.5 - d * 0.28
                if texture > 0 { l += (Double(hash(cx + x, cy + y, seed) % 100) / 100 - 0.5) * texture }
                l += (bayer(cx + x, cy + y) - 0.5) * 0.16
                let i = max(0, min(tones.count - 1, Int(l * n)))
                g[cx + x, cy + y] = tones[i]
            }
        }
    }

    static func hline(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ c: UInt32) { fill(&g, x, y, w, 1, c) }
    static func vline(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ h: Int, _ c: UInt32) { fill(&g, x, y, 1, h, c) }

    /// Línea de Bresenham.
    static func line(_ g: inout PixelGrid, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ c: UInt32) {
        var x = x0, y = y0
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            g[x, y] = c
            if x == x1 && y == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x += sx }
            if e2 <= dx { err += dx; y += sy }
        }
    }

    /// Multiplica el color de los pixeles ya pintados (sombras y luces).
    static func tint(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ f: (Double, Double, Double)) {
        guard x >= 0, y >= 0, x < g.width, y < g.height, let c = g.pixels[y * g.width + x] else { return }
        g.pixels[y * g.width + x] = VillageArt.scale(c, f)
    }

    static func tintRect(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ f: (Double, Double, Double)) {
        for yy in y..<(y + max(0, h)) { for xx in x..<(x + max(0, w)) { tint(&g, xx, yy, f) } }
    }

    static let shadowF = (0.70, 0.72, 0.84)

    static func dark(_ c: UInt32, _ f: Double) -> UInt32 { VillageArt.darken(c, f) }
    static func light(_ c: UInt32, _ f: Double) -> UInt32 {
        // Aclara hacia el blanco (no satura el canal).
        let r = Double((c >> 16) & 0xFF), gg = Double((c >> 8) & 0xFF), b = Double(c & 0xFF)
        let k = f - 1
        func up(_ v: Double) -> UInt32 { UInt32(min(255, v + (255 - v) * k * 1.6 + v * k * 0.2)) }
        return (up(r) << 16) | (up(gg) << 8) | up(b)
    }

    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func ch(_ s: UInt32) -> Double { Double(s & 0xFF) }
        let r = ch(a >> 16) + (ch(b >> 16) - ch(a >> 16)) * t
        let g = ch(a >> 8) + (ch(b >> 8) - ch(a >> 8)) * t
        let bl = ch(a) + (ch(b) - ch(a)) * t
        return (UInt32(max(0, min(255, r))) << 16) | (UInt32(max(0, min(255, g))) << 8) | UInt32(max(0, min(255, bl)))
    }

    // MARK: - Azar determinista

    /// Hash entero por posición: misma casilla, mismo dibujo; casillas distintas, dibujos distintos.
    static func hash(_ x: Int, _ y: Int, _ s: Int = 0) -> Int {
        var h = UInt64(bitPattern: Int64(x &* 374_761_393 &+ y &* 668_265_263 &+ s &* 1_274_126_177))
        h = (h ^ (h >> 13)) &* 0x5BD1_E995
        h ^= h >> 15
        h = h &* 0x2C1B_3C6D
        h ^= h >> 12
        return Int(h & 0xFF_FFFF)
    }

    static func chance(_ x: Int, _ y: Int, _ s: Int, _ p: Double) -> Bool {
        Double(hash(x, y, s) % 10_000) < p * 10_000
    }

    static func pick<T>(_ list: [T], _ x: Int, _ y: Int, _ s: Int) -> T { list[hash(x, y, s) % list.count] }

    /// Ruido de valor suave (0...1).
    static func noise(_ x: Double, _ y: Double, _ s: Int) -> Double {
        let x0 = Int(floor(x)), y0 = Int(floor(y))
        let fx = x - Double(x0), fy = y - Double(y0)
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        func v(_ a: Int, _ b: Int) -> Double { Double(hash(a, b, s) % 1024) / 1023 }
        let top = v(x0, y0) + (v(x0 + 1, y0) - v(x0, y0)) * sx
        let bottom = v(x0, y0 + 1) + (v(x0 + 1, y0 + 1) - v(x0, y0 + 1)) * sx
        return top + (bottom - top) * sy
    }

    private static let bayerTable: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map { ($0 + 0.5) / 16 }

    /// Umbral de tramado ordenado 4×4 (0...1), para degradados al estilo 16 bits.
    static func bayer(_ x: Int, _ y: Int) -> Double { bayerTable[(y & 3) * 4 + (x & 3)] }

    /// Elige entre tonos con tramado: `t` en 0...1.
    static func tone(_ tones: [UInt32], _ t: Double, _ x: Int, _ y: Int, dither: Double = 0.2) -> UInt32 {
        let v = t + (bayer(x, y) - 0.5) * dither
        return tones[max(0, min(tones.count - 1, Int(v * Double(tones.count))))]
    }
}

extension Tile {
    var isWallLike: Bool { self == .wall || self == .interiorWall }
}
