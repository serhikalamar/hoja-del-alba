import Foundation
import GameCore

/// Capas animadas opcionales para el pueblo (las conecta `ExploreScene`).
///
/// Todas las posiciones van en **pixeles de arte del mapa**, con origen arriba a la izquierda
/// (como `ground`). Para pasarlas a la escena: `CGPoint(x: x * PX, y: (map.height * tile - y) * PX)`.
extension TownArt {
    /// Fuente de luz para dibujar un halo que parpadea encima del suelo.
    struct LightSource {
        let x: Int, y: Int
        /// Radio aproximado del halo en pixeles de arte.
        let radius: Int
        let color: UInt32
        /// `true` si es fuego (antorcha, horno, vela): parpadeo rápido. `false`: farol o ventana, casi fijo.
        let flame: Bool
    }

    /// Luces de un área: farolas, antorchas de las puertas, fragua; en interiores, velas, hornos y calderos.
    static func lightSources(_ map: AreaMap) -> [LightSource] {
        let T = tile
        var list: [LightSource] = []
        if map.isInterior {
            let w = map.width
            for x in 0..<w where map.tile(x, 0) == .interiorWall && map.tile(x, 1) != .interiorWall {
                let below = map.tile(x, 1)
                guard below != .shelf && below != .oven && below != .throne else { continue }
                if wallDecorKind(map.id, x, w) == 3 { list.append(LightSource(x: x * T + 11, y: 4, radius: 22, color: 0xFFC060, flame: true)) }
            }
            for y in 0..<map.height {
                for x in 0..<w {
                    switch map.tile(x, y) {
                    case .oven where map.tile(x - 1, y) != .oven:
                        let wide = map.tile(x + 1, y) == .oven
                        list.append(LightSource(x: x * T + (wide ? 24 : 12), y: y * T + 12, radius: 46, color: 0xFF8A30, flame: true))
                    case .barrel where map.id == "alchemist":
                        list.append(LightSource(x: x * T + 12, y: y * T + 8, radius: 22, color: 0x60F080, flame: false))
                    case .throne where map.id == "chapel" && map.tile(x - 1, y) != .throne:
                        for dx in [-14, 13] { list.append(LightSource(x: x * T + T + dx, y: y * T - 11, radius: 18, color: 0xFFD070, flame: true)) }
                    default: break
                    }
                }
            }
        } else {
            for y in 0..<map.height {
                for x in 0..<map.width {
                    switch map.tile(x, y) {
                    case .lamp:
                        list.append(LightSource(x: x * T + 12, y: y * T + T - 40, radius: 30, color: 0xFFD070, flame: false))
                    case .campfire:
                        // Hogueras y braseros del campo (violeta en el campamento del Eclipse)
                        let kind = campfireKind(fieldMood(areaID: map.id, zoneID: map.zone(at: TilePoint(x, y))?.id))
                        list.append(LightSource(x: x * T + 12, y: y * T + (kind == .brazier ? 6 : 11), radius: 46,
                                                color: kind == .eclipse ? 0xA060F0 : 0xFFA040, flame: true))
                    case .cave where map.tile(x - 1, y) != .cave:
                        // Resplandor de las bajadas: violeta en la cripta, cálido en los calabozos
                        let wide = map.tile(x + 1, y) == .cave
                        list.append(LightSource(x: x * T + (wide ? T : T / 2), y: y * T + 4, radius: wide ? 34 : 24,
                                                color: map.kind == .field ? 0x9A60F0 : 0xC07030, flame: false))
                    case .wall where map.tile(x, y + 1) != .wall:
                        // Antorchas de los pilares de la puerta del pueblo
                        if map.tile(x + 1, y) == .street && map.tile(x - 1, y) == .wall { list.append(LightSource(x: x * T + T - 2, y: y * T + 4, radius: 20, color: 0xFFA040, flame: true)) }
                        if map.tile(x - 1, y) == .street && map.tile(x + 1, y) == .wall { list.append(LightSource(x: x * T + 2, y: y * T + 4, radius: 20, color: 0xFFA040, flame: true)) }
                    default: break
                    }
                }
            }
            for b in map.buildings {
                let doorC = b.x * T + (b.doorX - b.x) * T + b.doorWidth * T / 2
                let base = (b.y + b.height) * T
                if b.style == .castle {
                    for side in [-1, 1] { list.append(LightSource(x: doorC + side * 34, y: base - 48, radius: 26, color: 0xFFA040, flame: true)) }
                } else if b.style == .smithy {
                    let signSide = (b.doorX - b.x) * T + b.doorWidth * T / 2 < b.width * T / 2 ? 1 : -1
                    list.append(LightSource(x: doorC - signSide * 30, y: base - 12, radius: 30, color: 0xFF7A20, flame: true))
                }
            }
        }
        return list
    }

    /// Bocas de humo (`smoke(frame:)`): chimeneas del pueblo, rescoldos de las granjas quemadas, la cabaña del
    /// guardabosques y las hogueras de los campamentos (bandidos, orcos y el Eclipse).
    static func chimneyMouths(_ map: AreaMap) -> [(x: Int, y: Int)] {
        let T = tile
        var list: [(x: Int, y: Int)] = []
        for b in map.buildings where fieldStyles.contains(b.style) {
            let M = fieldMargin(b.style)
            for m in fieldSmoke(b) { list.append((b.x * T + m.x, b.y * T - M + m.y)) }
        }
        for y in 0..<map.height {
            for x in 0..<map.width where map.tile(x, y) == .campfire {
                let mood = fieldMood(areaID: map.id, zoneID: map.zone(at: TilePoint(x, y))?.id)
                guard [.banditCamp, .orcCamp, .monkGarden].contains(mood) else { continue }
                list.append((x * T + 12, y * T + (mood == .orcCamp ? 0 : 4)))
            }
        }
        return list + map.buildings.compactMap { b in
            guard b.style != .castle && b.style != .chapel && !fieldStyles.contains(b.style) else { return nil }
            let W = b.width * T
            let doorC = (b.doorX - b.x) * T + b.doorWidth * T / 2
            let M = 26, roofTop = M + 4
            let height = b.style == .smithy ? 30 : 24
            let wide = b.style == .smithy || b.style == .bakery
            let cx = (doorC < W / 2 ? W - 30 : 22) + (wide ? 6 : 4)
            let top = roofTop + 14 - height - 4
            return (b.x * T + cx, b.y * T - M + top)
        }
    }

    /// Bocanada de humo (8 fotogramas, 12×20): sube, se ensancha y se desvanece hacia la derecha.
    /// Pensado para ponerlo con el borde de abajo en la boca de la chimenea y repetirlo en bucle.
    static func smoke(frame: Int) -> PixelGrid {
        var g = PixelGrid(width: 12, height: 20)
        let f = ((frame % 8) + 8) % 8
        let tones: [UInt32] = [0x8A8694, 0xA8A4B2, 0xC8C4D0, 0xE2DEE8]
        for i in 0..<3 {
            let t = Double((f + i * 3) % 8) / 8           // 0 recién salida, 1 a punto de desaparecer
            let cy = 18 - Int(t * 16)
            let cx = 4 + Int(t * 5)
            let r = 1 + Int(t * 3.2)
            guard t < 0.95 else { continue }
            for y in -r...r {
                for x in -r...r where x * x + y * y <= r * r {
                    // Se deshace con tramado al final
                    if t > 0.6 && (x + y + f) % 2 == 0 { continue }
                    let l = 0.7 - Double(x + y) / Double(max(1, r)) * 0.25
                    g[cx + x, cy + y] = tones[max(0, min(3, Int(l * 4)))]
                }
            }
        }
        return g
    }

    /// Destellos del agua de la fuente (4 fotogramas, 48×34): ponerlos centrados sobre el pilón,
    /// con el centro en `fountainCenters`.
    static func fountainSparkle(frame: Int) -> PixelGrid {
        var g = PixelGrid(width: 48, height: 34)
        let f = ((frame % 4) + 4) % 4
        let cx = 24, cy = 18
        // Chorros que caen del surtidor
        for side in [-1, 1] {
            for k in 0..<4 {
                let t = Double((k * 2 + f) % 8) / 8
                let x = cx + side * Int(2 + t * 8), y = cy - 16 + Int(t * t * 14)
                g[x, y] = k % 2 == 0 ? 0xFFFFFF : 0xBEE8FF
            }
        }
        // Ondas y brillos en el pilón
        for i in 0..<6 {
            let a = Double(i) / 6 * 2 * Double.pi + Double(f) * 0.4
            let x = cx + Int(cos(a) * 13), y = cy + 4 + Int(sin(a) * 7)
            if (i + f) % 2 == 0 { g[x, y] = 0xFFFFFF; g[x + 1, y] = 0xBEE8FF }
        }
        return g
    }

    static func wallDecorKind(_ room: String, _ x: Int, _ w: Int) -> Int {
        if x <= 0 || x >= w - 1 { return 0 }
        let h = hash(x, room.count, 51) % 10
        switch room {
        case "castle": return x % 3 == 0 ? 4 : (x % 3 == 1 ? 3 : 1)
        case "chapel": return x % 2 == 0 ? 1 : (h < 4 ? 3 : 0)
        default:
            if x % 4 == 2 { return 1 }
            return [0, 2, 3, 5, 0, 2, 5, 3, 0, 2][h]
        }
    }
}
