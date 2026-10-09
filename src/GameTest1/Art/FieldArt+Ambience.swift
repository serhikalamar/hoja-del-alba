import Foundation
import GameCore

/// Ambiente animado del campo (lo conecta `ExploreScene.buildAmbience`): llamas de hogueras y braseros,
/// niebla baja, ceniza, brasas, nieve y hojas que caen. Posiciones en pixeles de arte del mapa (origen arriba-izquierda).
extension TownArt {
    // MARK: - Llamas

    /// Pie de la llama de cada hoguera/brasero `x` (centro de abajo) y si es violeta (campamento del Eclipse).
    static func campfireSpots(_ map: AreaMap) -> [(x: Int, y: Int, violet: Bool)] {
        let T = tile
        var list: [(x: Int, y: Int, violet: Bool)] = []
        for y in 0..<map.height {
            for x in 0..<map.width where map.tile(x, y) == .campfire {
                let kind = campfireKind(fieldMood(areaID: map.id, zoneID: map.zone(at: TilePoint(x, y))?.id))
                list.append((x * T + 12, y * T + (kind == .brazier ? 9 : 15), kind == .eclipse))
            }
        }
        return list
    }

    /// Llama (6 fotogramas, 16×24): lenguas que suben y se mecen, con chispas.
    static func campfireFlame(frame: Int, violet: Bool) -> PixelGrid {
        let W = 16, H = 24
        var g = PixelGrid(width: W, height: H)
        let f = ((frame % 6) + 6) % 6
        let tones: [UInt32] = violet ? [0x3E1A78, 0x6A34C0, 0x9A62F0, 0xD0B0FF, 0xF6EEFF] : [0xA8261A, 0xE0501E, 0xF89A30, 0xFFD860, 0xFFF8D0]
        let phase = Double(f) / 6 * 2 * Double.pi
        let hgt = 15.0 + sin(phase) * 2 + sin(phase * 2 + 1) * 1
        for y in 0..<H {
            let yy = Double(H - 1 - y)
            let t = yy / hgt
            guard t <= 1 else { continue }
            let center = Double(W) / 2 - 0.5 + sin(t * 4.5 + phase) * t * 2.2
            var hw = pow(1 - t, 0.65) * 5.2
            if t < 0.12 { hw *= 0.75 + t * 2 }
            for x in 0..<W {
                let d = abs(Double(x) - center) / max(0.6, hw)
                guard d <= 1 else { continue }
                // Lengua secundaria que se separa arriba
                let heat = (1 - d) * (1 - t * 0.75) + (bayer(x, y + f) - 0.5) * 0.18
                let i = heat > 0.62 ? 4 : (heat > 0.42 ? 3 : (heat > 0.24 ? 2 : (heat > 0.1 ? 1 : 0)))
                g[x, y] = tones[i]
            }
        }
        // Lengua suelta y chispas
        let tx = 4 + (f * 5) % 8, ty = H - 1 - Int(hgt) - 1 + f % 2
        g[tx, ty] = tones[2]; g[tx, ty + 1] = tones[1]
        for k in 0..<2 {
            let sx = 2 + (f * 3 + k * 7) % 12, sy = (f * 4 + k * 9) % 8
            g[sx, sy] = tones[k == 0 ? 3 : 4]
        }
        return g
    }

    // MARK: - Partículas

    /// Un tipo de partícula de ambiente en un rectángulo del mapa.
    struct AmbientEffect {
        enum Kind: String { case mist, ash, ember, snow, leaf }
        let kind: Kind
        /// Rectángulo donde aparecen (pixeles de arte del mapa, origen arriba-izquierda).
        let x: Int, y: Int, width: Int, height: Int
        /// Cuántas a la vez.
        let count: Int
        /// Desplazamiento en cada ciclo (pixeles de arte; `dy` positivo = hacia abajo) y duración del ciclo.
        let dx: Int, dy: Int
        let duration: Double
        /// Opacidad máxima.
        let alpha: Double
        /// Altura sobre el suelo: la niebla va pegada al suelo (detrás de personajes y objetos); el resto, por encima.
        var groundLevel: Bool { kind == .mist }
    }

    static func ambientEffects(_ map: AreaMap) -> [AmbientEffect] {
        guard map.kind == .field else { return [] }
        let T = tile
        var list: [AmbientEffect] = []
        for z in map.zones {
            let x = z.x * T, y = z.y * T, w = z.width * T, h = z.height * T
            let area = z.width * z.height
            switch fieldMood(areaID: map.id, zoneID: z.id) {
            case .graveyard, .cloister, .monkGarden:
                list.append(AmbientEffect(kind: .mist, x: x - 40, y: y, width: w, height: h, count: max(6, area / 34), dx: 56, dy: 0, duration: 14, alpha: 0.42))
            case .burnt:
                list.append(AmbientEffect(kind: .ash, x: x, y: y - 40, width: w, height: h, count: max(8, area / 26), dx: 26, dy: 70, duration: 7, alpha: 0.85))
                list.append(AmbientEffect(kind: .ember, x: x, y: y + 20, width: w, height: h, count: max(4, area / 70), dx: 10, dy: -50, duration: 3.5, alpha: 1))
            case .orcCamp:
                list.append(AmbientEffect(kind: .ash, x: x, y: y - 30, width: w, height: h, count: max(6, area / 50), dx: 22, dy: 60, duration: 7, alpha: 0.7))
            case .frozen:
                list.append(AmbientEffect(kind: .mist, x: x - 30, y: y, width: w, height: h, count: max(4, area / 60), dx: 36, dy: 0, duration: 16, alpha: 0.3))
            case .forest, .road:
                list.append(AmbientEffect(kind: .leaf, x: x, y: y - 40, width: w, height: h, count: max(4, area / 45), dx: 30, dy: 80, duration: 8, alpha: 1))
            case .pass:
                list.append(AmbientEffect(kind: .snow, x: x - 60, y: y - 60, width: w + 60, height: h, count: max(20, area / 9), dx: 34, dy: 110, duration: 7, alpha: 0.9))
            default: break
            }
        }
        return list
    }

    /// Textura de una partícula (3 variantes por tipo).
    static func ambientTexture(_ kind: AmbientEffect.Kind, variant v: Int) -> PixelGrid {
        switch kind {
        case .mist:
            // Jirón de niebla: elipse tramada, densa en el centro
            let W = 56 + v * 12, H = 14 + v * 2
            var g = PixelGrid(width: W, height: H)
            for y in 0..<H {
                for x in 0..<W {
                    let u = (Double(x) - Double(W) / 2) / (Double(W) / 2), w = (Double(y) - Double(H) / 2) / (Double(H) / 2)
                    let d = u * u + w * w + (noise(Double(x) / 6, Double(y) / 3, 40 + v) - 0.5) * 0.5
                    guard d < 1 else { continue }
                    if bayer(x, y) < (1 - d) * 1.3 { g[x, y] = d < 0.4 ? 0xE6EAF0 : 0xD2D8E2 }
                }
            }
            return g
        case .ash:
            var g = PixelGrid(width: 2, height: 2)
            let c: UInt32 = [0xA8A29A, 0x7E7870, 0xC8C2B8][v % 3]
            g[0, 0] = c; if v != 1 { g[1, 0] = dark(c, 0.85) }; if v == 2 { g[0, 1] = dark(c, 0.8) }
            return g
        case .ember:
            var g = PixelGrid(width: 2, height: 2)
            g[0, 0] = [0xFFD060, 0xFF9A30, 0xFFF0B0][v % 3]
            if v == 1 { g[1, 1] = 0xE0501E }
            return g
        case .snow:
            var g = PixelGrid(width: 2, height: 2)
            g[0, 0] = 0xFFFFFF
            if v > 0 { g[1, 0] = 0xE4ECF4; g[0, 1] = 0xD6E0EA }
            if v == 2 { g[1, 1] = 0xF4F8FC }
            return g
        case .leaf:
            var g = PixelGrid(width: 3, height: 2)
            let (a, b): (UInt32, UInt32) = [(0xD08A30, 0x9A5A22), (0xE0B040, 0xA87828), (0x7A9A3A, 0x4E6A2A)][v % 3]
            g[0, 0] = a; g[1, 0] = a; g[1, 1] = b; g[2, 1] = b
            return g
        }
    }
}
