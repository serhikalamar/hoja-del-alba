import CoreGraphics
import GameCore

/// Arte del pueblo explorable en vista 3/4. Cada casilla mide `tile` pixeles de arte.
/// El suelo se dibuja en una sola imagen; edificios, árboles y farolas son sprites aparte
/// para poder pasar por detrás de ellos.
enum TownArt {
    static let tile = 24

    // MARK: - Suelo

    static func ground(_ map: AreaMap) -> PixelGrid {
        let T = tile
        var g = PixelGrid(width: map.width * T, height: map.height * T)
        for y in 0..<map.height {
            for x in 0..<map.width {
                var rng = SeededGenerator(seed: UInt64(x * 7919 + y * 104_729 + map.id.count))
                drawTile(&g, map: map, x: x, y: y, rng: &rng)
            }
        }
        // Fuentes (bloques 2x2)
        for y in 0..<map.height {
            for x in 0..<map.width where map.tile(x, y) == .fountain && map.tile(x - 1, y) != .fountain && map.tile(x, y - 1) != .fountain {
                fountain(&g, x * T, y * T)
            }
        }
        return g
    }

    private static func drawTile(_ g: inout PixelGrid, map: AreaMap, x: Int, y: Int, rng: inout SeededGenerator) {
        let T = tile
        let ox = x * T, oy = y * T
        switch map.tile(x, y) {
        case .grass, .tree, .lamp, .bush, .fence:
            grass(&g, ox, oy, &rng, flowers: false)
            if map.tile(x, y) == .bush { bush(&g, ox, oy) }
            if map.tile(x, y) == .fence { fence(&g, ox, oy) }
        case .flowers:
            grass(&g, ox, oy, &rng, flowers: true)
        case .street:
            cobble(&g, ox, oy, &rng)
            edgeWithGrass(&g, map: map, x: x, y: y)
        case .plaza, .fountain:
            plaza(&g, ox, oy, &rng)
        case .stairs:
            stairs(&g, ox, oy)
        case .wall:
            wall(&g, ox, oy, top: !map.tile(x, y - 1).isWallLike, &rng)
        case .water:
            fill(&g, ox, oy, T, T, 0x3A7AC8)
            for _ in 0..<6 { fill(&g, ox + Int.random(in: 0..<T - 5, using: &rng), oy + Int.random(in: 0..<T, using: &rng), 5, 1, 0x8AC8F0) }
        case .stall:
            plaza(&g, ox, oy, &rng)
            stall(&g, ox, oy, left: map.tile(x - 1, y) != .stall, &rng)
        case .crates:
            plaza(&g, ox, oy, &rng)
            crates(&g, ox, oy, &rng)
        // Interiores
        case .interiorWall:
            interiorWall(&g, map: map, x: x, y: y)
        case .woodFloor, .exit:
            woodFloor(&g, ox, oy, y: y)
            if map.tile(x, y) == .exit { doorway(&g, ox, oy) }
        case .stoneFloor:
            stoneFloor(&g, ox, oy, &rng)
        case .carpet:
            carpet(&g, map: map, x: x, y: y)
        case .shelf:
            woodFloor(&g, ox, oy, y: y)
            shelf(&g, ox, oy, &rng)
        case .oven:
            woodFloor(&g, ox, oy, y: y)
            oven(&g, ox, oy)
        case .table:
            floorUnder(&g, map: map, x: x, y: y, &rng)
            table(&g, ox, oy, &rng)
        case .bed:
            woodFloor(&g, ox, oy, y: y)
            bed(&g, map: map, x: x, y: y)
        case .barrel:
            floorUnder(&g, map: map, x: x, y: y, &rng)
            barrel(&g, ox + 4, oy + 2)
        case .pillar:
            stoneFloor(&g, ox, oy, &rng)
            pillar(&g, ox, oy)
        case .throne:
            stoneFloor(&g, ox, oy, &rng)
            throne(&g, map: map, x: x, y: y)
        }
    }

    // MARK: Exterior

    private static func grass(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ rng: inout SeededGenerator, flowers: Bool) {
        let T = tile
        let shades: [UInt32] = [0x6ABE4E, 0x62B448, 0x72C656]
        for y in 0..<T {
            for x in 0..<T {
                g[ox + x, oy + y] = shades[((ox + x) / 5 + (oy + y) / 4 + ((ox + x) * 3 + oy + y) % 2) % 3]
            }
        }
        for _ in 0..<10 {
            let x = ox + Int.random(in: 1..<T - 1, using: &rng), y = oy + Int.random(in: 2..<T, using: &rng)
            g[x, y] = 0x4A9A3A; g[x, y - 1] = 0x4A9A3A; g[x + 1, y] = 0x58A842
        }
        if flowers {
            let colors: [UInt32] = [0xFFF4F0, 0xFFD840, 0xF27AA8, 0x8AD8FF]
            for _ in 0..<3 {
                let x = ox + Int.random(in: 2..<T - 2, using: &rng), y = oy + Int.random(in: 2..<T - 2, using: &rng)
                let c = colors[Int.random(in: 0..<colors.count, using: &rng)]
                g[x - 1, y] = c; g[x + 1, y] = c; g[x, y - 1] = c; g[x, y + 1] = c; g[x, y] = 0xFFC830
            }
        }
    }

    private static func cobble(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ rng: inout SeededGenerator) {
        let T = tile
        let mortar: UInt32 = 0x8A8070
        fill(&g, ox, oy, T, T, mortar)
        let stones: [UInt32] = [0xC8BCA4, 0xBEB298, 0xD2C6AE, 0xB8AC92]
        var y = 0
        var row = 0
        while y < T {
            var x = (row % 2) * 3 - 3
            while x < T {
                let w = Int.random(in: 5...7, using: &rng)
                roundedStone(&g, ox + x + 1, oy + y + 1, w - 1, 4, stones[Int.random(in: 0..<stones.count, using: &rng)], mortar: mortar, clipX: ox, clipW: T)
                x += w
            }
            y += 5
            row += 1
        }
    }

    private static func plaza(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ rng: inout SeededGenerator) {
        let T = tile
        let mortar: UInt32 = 0xA89A80
        fill(&g, ox, oy, T, T, mortar)
        let slabs: [UInt32] = [0xE8DCC0, 0xE0D4B6, 0xF0E6CC]
        for sy in stride(from: 0, to: T, by: 12) {
            for sx in stride(from: 0, to: T, by: 12) {
                let c = slabs[Int.random(in: 0..<slabs.count, using: &rng)]
                fill(&g, ox + sx + 1, oy + sy + 1, 10, 10, c)
                fill(&g, ox + sx + 1, oy + sy + 1, 10, 1, VillageArt.lighten(c, 1.06))
                fill(&g, ox + sx + 1, oy + sy + 10, 10, 1, VillageArt.darken(c, 0.9))
                if Int.random(in: 0..<4, using: &rng) == 0 {
                    g[ox + sx + Int.random(in: 3...8, using: &rng), oy + sy + Int.random(in: 3...8, using: &rng)] = VillageArt.darken(c, 0.85)
                }
            }
        }
    }

    private static func edgeWithGrass(_ g: inout PixelGrid, map: AreaMap, x: Int, y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let grassy: Set<Tile> = [.grass, .flowers, .tree, .bush]
        if grassy.contains(map.tile(x, y - 1)) { fill(&g, ox, oy, T, 2, 0x58A842) }
        if grassy.contains(map.tile(x, y + 1)) { fill(&g, ox, oy + T - 2, T, 2, 0x4A8A3A) }
    }

    private static func stairs(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        let T = tile
        for step in 0..<4 {
            let y = oy + step * 6
            fill(&g, ox, y, T, 4, 0xD8CCB0)
            fill(&g, ox, y, T, 1, 0xF0E6CC)
            fill(&g, ox, y + 4, T, 2, 0x8A8070)
        }
    }

    private static func wall(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, top: Bool, _ rng: inout SeededGenerator) {
        let T = tile
        fill(&g, ox, oy, T, T, 0x7A7A88)
        for row in 0..<4 {
            let y = oy + row * 6
            let shift = (row % 2) * 6
            for bx in stride(from: -shift, to: T, by: 12) {
                let c: UInt32 = [0xA8A8B4, 0x9C9CAA, 0xB2B2BE][Int.random(in: 0..<3, using: &rng)]
                fill(&g, ox + max(0, bx) + 1, y + 1, min(11, T - max(0, bx) - 1), 4, c)
                fill(&g, ox + max(0, bx) + 1, y + 1, min(11, T - max(0, bx) - 1), 1, VillageArt.lighten(c, 1.1))
            }
        }
        if top {
            fill(&g, ox, oy, T, 4, 0xC8C8D2)
            fill(&g, ox, oy + 4, T, 1, 0x5A5A68)
            for cx in stride(from: 2, to: T, by: 8) { fill(&g, ox + cx, oy, 4, 2, 0xE0E0E8) }
        }
    }

    private static func bush(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        ellipse(&g, ox + 12, oy + 14, 10, 8, 0x2E7A3A)
        ellipse(&g, ox + 12, oy + 12, 9, 7, 0x3E9A48)
        ellipse(&g, ox + 9, oy + 9, 4, 3, 0x6ACC5A)
        for (x, y) in [(7, 14), (15, 10), (13, 16)] { g[ox + x, oy + y] = 0xF27AA8 }
    }

    private static func fence(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        for x in stride(from: 2, to: tile, by: 8) {
            fill(&g, ox + x, oy + 6, 3, 14, 0x8F5A32)
            fill(&g, ox + x, oy + 6, 1, 14, 0xB87A4A)
        }
        fill(&g, ox, oy + 9, tile, 2, 0x7A4A2A)
        fill(&g, ox, oy + 15, tile, 2, 0x7A4A2A)
    }

    private static func stall(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, left: Bool, _ rng: inout SeededGenerator) {
        let T = tile
        // Mostrador con mercancía
        fill(&g, ox, oy + 12, T, 10, 0x9A6A3A)
        fill(&g, ox, oy + 12, T, 2, 0xC8925A)
        fill(&g, ox, oy + 21, T, 1, 0x5A3A22)
        let goods: [UInt32] = [0xE43B44, 0xFFCD45, 0x6ACC5A, 0xEF7D57, 0xC879F2]
        for i in 0..<4 {
            ellipse(&g, ox + 3 + i * 6, oy + 11, 2, 2, goods[Int.random(in: 0..<goods.count, using: &rng)])
        }
        // Toldo a rayas
        for x in 0..<T {
            let stripe = ((ox + x) / 4) % 2 == 0 ? UInt32(0xF4ECD8) : UInt32(0xD84A4A)
            fill(&g, ox + x, oy, 1, 7, stripe)
            g[ox + x, oy + 7 + (x % 4 == 0 ? 1 : 0)] = stripe
        }
        fill(&g, ox, oy + 7, T, 1, 0x8A2A2A)
        if left { fill(&g, ox + 1, oy + 8, 2, 4, 0x6A4422) } else { fill(&g, ox + T - 3, oy + 8, 2, 4, 0x6A4422) }
    }

    private static func crates(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ rng: inout SeededGenerator) {
        crate(&g, ox + 1, oy + 8)
        barrel(&g, ox + 12, oy + 5)
    }

    static func crate(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        fill(&g, ox, oy, 12, 12, 0x1A1C2C)
        fill(&g, ox + 1, oy + 1, 10, 10, 0xC8A070)
        fill(&g, ox + 1, oy + 1, 10, 2, 0xE0BC88)
        for i in 1..<10 { g[ox + i, oy + i] = 0x8A6A40; g[ox + 11 - i, oy + i] = 0x8A6A40 }
    }

    static func barrel(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        fill(&g, ox, oy, 11, 16, 0x1A1C2C)
        fill(&g, ox + 1, oy + 1, 9, 14, 0x9A6A3A)
        fill(&g, ox + 1, oy + 1, 9, 2, 0xC08A5A)
        fill(&g, ox + 1, oy + 4, 9, 1, 0x6A6A78)
        fill(&g, ox + 1, oy + 11, 9, 1, 0x6A6A78)
        fill(&g, ox + 8, oy + 3, 2, 12, 0x6A4422)
    }

    private static func fountain(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        let c = (ox + tile, oy + tile)
        ellipse(&g, c.0, c.1 + 2, 22, 18, 0x6A6A78)
        ellipse(&g, c.0, c.1 + 1, 21, 17, 0xC8C8D2)
        ellipse(&g, c.0, c.1 + 1, 17, 13, 0x3A8AD8)
        ellipse(&g, c.0 - 4, c.1 - 3, 8, 4, 0x6AB4F0)
        ellipse(&g, c.0, c.1, 6, 5, 0xB8B8C4)
        fill(&g, c.0 - 2, c.1 - 14, 4, 14, 0xD8D8E0)
        fill(&g, c.0 - 1, c.1 - 18, 2, 4, 0x9AD8FF)
        for (dx, dy) in [(-5, -10), (5, -10), (-8, -4), (8, -4)] { g[c.0 + dx, c.1 + dy] = 0x9AD8FF }
    }

    // MARK: Interior

    private static func interiorWall(_ g: inout PixelGrid, map: AreaMap, x: Int, y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let below = map.tile(x, y + 1)
        if y == 0 && !below.isWallLike {
            // Pared del fondo: zócalo de madera y yeso.
            fill(&g, ox, oy, T, T, 0xE8D8B8)
            fill(&g, ox, oy, T, 3, 0x5A3A22)
            fill(&g, ox, oy + 14, T, 10, 0x8F5A32)
            fill(&g, ox, oy + 14, T, 1, 0xB87A4A)
            for bx in stride(from: 0, to: T, by: 8) { fill(&g, ox + bx, oy + 15, 1, 9, 0x6A4422) }
        } else {
            fill(&g, ox, oy, T, T, 0x3A2E2A)
            fill(&g, ox + 2, oy + 2, T - 4, T - 4, 0x4E3E38)
        }
    }

    private static func woodFloor(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, y: Int) {
        let T = tile
        for row in 0..<4 {
            let c: UInt32 = row % 2 == 0 ? 0xB0804E : 0xA87848
            fill(&g, ox, oy + row * 6, T, 6, c)
            fill(&g, ox, oy + row * 6 + 5, T, 1, 0x7A5030)
            let seam = ((y * 4 + row) * 7) % T
            fill(&g, ox + seam, oy + row * 6, 1, 5, 0x7A5030)
        }
    }

    private static func stoneFloor(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ rng: inout SeededGenerator) {
        let T = tile
        fill(&g, ox, oy, T, T, 0x5A5A68)
        for sy in stride(from: 0, to: T, by: 12) {
            for sx in stride(from: 0, to: T, by: 12) {
                let c: UInt32 = [0x9A9AA8, 0x8E8E9C, 0xA4A4B0][Int.random(in: 0..<3, using: &rng)]
                fill(&g, ox + sx + 1, oy + sy + 1, 10, 10, c)
                fill(&g, ox + sx + 1, oy + sy + 1, 10, 1, VillageArt.lighten(c, 1.1))
            }
        }
    }

    private static func floorUnder(_ g: inout PixelGrid, map: AreaMap, x: Int, y: Int, _ rng: inout SeededGenerator) {
        let neighbours = [map.tile(x - 1, y), map.tile(x + 1, y), map.tile(x, y + 1)]
        if neighbours.contains(.stoneFloor) || neighbours.contains(.carpet) {
            stoneFloor(&g, x * tile, y * tile, &rng)
        } else {
            woodFloor(&g, x * tile, y * tile, y: y)
        }
    }

    private static func carpet(_ g: inout PixelGrid, map: AreaMap, x: Int, y: Int) {
        let T = tile, ox = x * T, oy = y * T
        fill(&g, ox, oy, T, T, 0xA0242E)
        for i in stride(from: 0, to: T, by: 6) { g[ox + i + 3, oy + 12] = 0xD8A040 }
        if map.tile(x - 1, y) != .carpet { fill(&g, ox, oy, 2, T, 0xD8A040) }
        if map.tile(x + 1, y) != .carpet { fill(&g, ox + T - 2, oy, 2, T, 0xD8A040) }
    }

    private static func shelf(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ rng: inout SeededGenerator) {
        let T = tile
        fill(&g, ox + 1, oy, T - 2, T - 2, 0x6A4422)
        fill(&g, ox + 2, oy + 1, T - 4, T - 4, 0x4A2E16)
        let items: [UInt32] = [0xE8C080, 0xC0603A, 0x73EFF7, 0xC879F2, 0xF4F4F4, 0x6ACC5A]
        for shelfY in [8, 16] {
            fill(&g, ox + 2, oy + shelfY, T - 4, 2, 0x8F5A32)
            var ix = ox + 3
            while ix < ox + T - 5 {
                let h = Int.random(in: 3...5, using: &rng)
                fill(&g, ix, oy + shelfY - h, 3, h, items[Int.random(in: 0..<items.count, using: &rng)])
                ix += 4
            }
        }
    }

    private static func oven(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        fill(&g, ox + 1, oy, 22, 22, 0x8A3A2A)
        for row in 0..<5 { for col in 0..<4 { fill(&g, ox + 2 + col * 5 + (row % 2) * 2, oy + 1 + row * 4, 4, 3, 0xB0503A) } }
        ellipse(&g, ox + 12, oy + 15, 6, 5, 0x2A1A10)
        ellipse(&g, ox + 12, oy + 17, 4, 2, 0xFF9A30)
        ellipse(&g, ox + 12, oy + 18, 2, 1, 0xFFE070)
    }

    private static func table(_ g: inout PixelGrid, _ ox: Int, _ oy: Int, _ rng: inout SeededGenerator) {
        fill(&g, ox + 1, oy + 4, 22, 12, 0x1A1C2C)
        fill(&g, ox + 2, oy + 5, 20, 10, 0xB07A44)
        fill(&g, ox + 2, oy + 5, 20, 2, 0xD09A5E)
        fill(&g, ox + 3, oy + 16, 3, 6, 0x6A4422)
        fill(&g, ox + 18, oy + 16, 3, 6, 0x6A4422)
        ellipse(&g, ox + 8, oy + 9, 3, 2, 0xF4F4F4)
        ellipse(&g, ox + 16, oy + 9, 2, 2, [0xE8C080, 0xC0603A, 0x6ACC5A][Int.random(in: 0..<3, using: &rng)])
    }

    private static func bed(_ g: inout PixelGrid, map: AreaMap, x: Int, y: Int) {
        let T = tile, ox = x * T, oy = y * T
        let isLeft = map.tile(x - 1, y) != .bed
        let isTop = map.tile(x, y - 1) != .bed
        fill(&g, ox, oy, T, T, 0x6A4422)
        fill(&g, isLeft ? ox + 2 : ox, oy, isLeft ? T - 2 : T - 2, T, 0x3B5DC9)
        if isTop {
            fill(&g, isLeft ? ox + 2 : ox, oy, isLeft ? T - 2 : T - 2, 9, 0xF4F4F4)
            fill(&g, isLeft ? ox + 4 : ox, oy + 2, isLeft ? T - 6 : T - 4, 5, 0xE0E0E8)
        }
        for i in stride(from: 0, to: T, by: 6) { fill(&g, ox + i, oy + (isTop ? 12 : 0), 3, 3, 0x6A8AE8) }
    }

    private static func pillar(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        ellipse(&g, ox + 12, oy + 20, 9, 3, 0x3A3A46)
        fill(&g, ox + 5, oy - 10, 14, 30, 0xC8C8D2)
        fill(&g, ox + 5, oy - 10, 4, 30, 0xE8E8F0)
        fill(&g, ox + 15, oy - 10, 4, 30, 0x9A9AA8)
        fill(&g, ox + 3, oy - 12, 18, 3, 0xE0E0E8)
        fill(&g, ox + 3, oy + 18, 18, 3, 0x9A9AA8)
    }

    private static func throne(_ g: inout PixelGrid, map: AreaMap, x: Int, y: Int) {
        guard map.tile(x - 1, y) != .throne else { return }
        let ox = x * tile, oy = y * tile
        fill(&g, ox + 6, oy - 14, 36, 36, 0x1A1C2C)
        fill(&g, ox + 7, oy - 13, 34, 34, 0xD8A030)
        fill(&g, ox + 11, oy - 9, 26, 20, 0x8A1A2A)
        fill(&g, ox + 7, oy + 11, 34, 6, 0xB07A20)
        for (dx, c) in [(10, 0xE43B44), (24, 0x73EFF7), (38, 0x6ACC5A)] as [(Int, UInt32)] {
            ellipse(&g, ox + dx, oy - 12, 2, 2, c)
        }
    }

    private static func doorway(_ g: inout PixelGrid, _ ox: Int, _ oy: Int) {
        fill(&g, ox + 3, oy + 4, 18, 20, 0x2A1A10)
        fill(&g, ox + 5, oy + 16, 14, 8, 0xC8A050)
        fill(&g, ox + 5, oy + 16, 14, 1, 0xE8C878)
    }

    // MARK: - Sprites: árboles y farolas

    static func tree(variant: Int) -> PixelGrid {
        var g = PixelGrid(width: 34, height: 44)
        let greens: [(UInt32, UInt32, UInt32)] = [(0x2E7A3A, 0x3E9A48, 0x6ACC5A), (0x2A6A34, 0x3A8A42, 0x5ABA50), (0x3A7A2A, 0x4E9A38, 0x8ACC5A)]
        let c = greens[variant % greens.count]
        fill(&g, 14, 28, 6, 14, 0x5A3A22)
        fill(&g, 14, 28, 2, 14, 0x7A4A2A)
        fill(&g, 11, 40, 12, 3, 0x4A2E16)
        ellipse(&g, 17, 18, 16, 15, c.0)
        ellipse(&g, 16, 16, 14, 13, c.1)
        for (x, y, r) in [(10, 12, 5), (20, 9, 4), (24, 18, 4), (12, 21, 4)] { ellipse(&g, x, y, r, r - 1, c.2) }
        for (x, y) in [(8, 18), (22, 14), (15, 24), (26, 22)] { ellipse(&g, x, y, 2, 2, c.0) }
        if variant % 3 == 1 { for (x, y) in [(9, 16), (21, 21), (16, 10)] { ellipse(&g, x, y, 1, 1, 0xE43B44) } }
        return g.outlined()
    }

    static let lamp: PixelGrid = {
        var g = PixelGrid(width: 10, height: 38)
        fill(&g, 4, 10, 2, 26, 0x2A2E40)
        fill(&g, 2, 34, 6, 3, 0x2A2E40)
        fill(&g, 1, 2, 8, 9, 0x2A2E40)
        fill(&g, 2, 3, 6, 7, 0xFFD870)
        fill(&g, 3, 4, 2, 2, 0xFFFFFF)
        fill(&g, 0, 1, 10, 2, 0x3A3E52)
        g[4, 0] = 0x3A3E52; g[5, 0] = 0x3A3E52
        return g.outlined()
    }()

    // MARK: - Edificios

    struct Palette {
        let roof: UInt32, roofDark: UInt32, roofLight: UInt32
        let wall: UInt32, beam: UInt32
    }

    static func palette(_ style: BuildingStyle) -> Palette {
        switch style {
        case .bakery: Palette(roof: 0xC0603A, roofDark: 0x8A3A22, roofLight: 0xE08A5A, wall: 0xF0E2C0, beam: 0x6A4422)
        case .inn: Palette(roof: 0x8A5A3A, roofDark: 0x5A3A22, roofLight: 0xB07A4E, wall: 0xE8D8B0, beam: 0x5A3A22)
        case .smithy: Palette(roof: 0x5A5A6A, roofDark: 0x3A3A48, roofLight: 0x7A7A8A, wall: 0xB8AC98, beam: 0x4A3020)
        case .chapel: Palette(roof: 0x4A6AA0, roofDark: 0x2A4A78, roofLight: 0x7A9AD0, wall: 0xE8E8F0, beam: 0x8A8A9A)
        case .mill: Palette(roof: 0xC8A050, roofDark: 0x8A6A2A, roofLight: 0xE8C878, wall: 0xE0D0B0, beam: 0x6A4422)
        case .alchemist: Palette(roof: 0x7A4AA0, roofDark: 0x4A2A6A, roofLight: 0xA07AD0, wall: 0xE0D8E8, beam: 0x4A3A5A)
        case .house, .castle: Palette(roof: 0x3A8A9A, roofDark: 0x24606E, roofLight: 0x6AC0D0, wall: 0xE8DCC0, beam: 0x6A4422)
        }
    }

    static func building(_ b: Building, open: Bool) -> PixelGrid {
        b.style == .castle ? castle(b, open: open) : house(b)
    }

    /// Casa en 3/4: tejado grande arriba y fachada con entramado, ventanas y puerta abajo.
    private static func house(_ b: Building) -> PixelGrid {
        let T = tile
        let W = b.width * T, H = b.height * T
        let p = palette(b.style)
        var g = PixelGrid(width: W, height: H + 10)
        let top = 10
        let wallH = Int(Double(H) * 0.44)
        let wallTop = top + H - wallH
        let roofTop = top + 2

        // Fachada
        fill(&g, 2, wallTop, W - 4, wallH, p.wall)
        fill(&g, W - 8, wallTop, 6, wallH, VillageArt.darken(p.wall, 0.86))
        for bx in [2, W / 2 - 1, W - 5] { fill(&g, bx, wallTop, 3, wallH, p.beam) }
        fill(&g, 2, wallTop, W - 4, 3, p.beam)
        fill(&g, 2, wallTop + wallH / 2 - 1, W - 4, 2, p.beam)
        fill(&g, 2, top + H - 3, W - 4, 3, 0x6A6A78)   // zócalo de piedra
        // Ventanas
        let doorLocal = (b.doorX - b.x) * T + (b.doorWidth * T) / 2
        for wx in stride(from: 10, to: W - 14, by: 30) where abs(wx + 6 - doorLocal) > 16 {
            window(&g, wx, wallTop + 6, lit: false)
        }
        // Puerta
        door(&g, doorLocal - 8, top + H - 22)

        // Tejado: filas de tejas escalonadas con alero
        let roofBottom = wallTop + 2
        for y in roofTop..<roofBottom {
            let t = Double(y - roofTop) / Double(max(1, roofBottom - roofTop))
            let inset = Int((1 - t) * 6)
            let row = (y - roofTop) / 4
            let color = row % 2 == 0 ? p.roof : VillageArt.darken(p.roof, 0.9)
            fill(&g, inset, y, W - inset * 2, 1, color)
            if (y - roofTop) % 4 == 3 { fill(&g, inset, y, W - inset * 2, 1, p.roofDark) }
            var tx = inset + (row % 2) * 4
            while tx < W - inset {
                g[tx, y] = p.roofDark
                tx += 8
            }
        }
        fill(&g, 6, roofTop, W - 12, 2, p.roofLight)            // cumbrera
        fill(&g, 0, roofBottom - 3, W, 3, p.roofDark)            // alero
        fill(&g, 0, roofBottom - 3, W, 1, p.roofLight)
        // Buhardilla
        if W >= 120 {
            let dx = W / 2 - 10
            fill(&g, dx, roofTop + 8, 20, 18, p.wall)
            fill(&g, dx - 2, roofTop + 4, 24, 5, p.roofDark)
            window(&g, dx + 4, roofTop + 11, lit: false)
        }
        // Chimenea
        if b.style != .chapel {
            fill(&g, W - 26, 0, 10, roofTop + 12, 0x8A5A4A)
            fill(&g, W - 28, 0, 14, 3, 0x5A3A2A)
            for i in 0..<4 { fill(&g, W - 25 + (i % 2) * 4, 4 + i * 4, 3, 1, 0x6A4034) }
        }
        decorate(&g, b, W: W, top: top, wallTop: wallTop, doorLocal: doorLocal)
        return g.outlined()
    }

    private static func decorate(_ g: inout PixelGrid, _ b: Building, W: Int, top: Int, wallTop: Int, doorLocal: Int) {
        let signX = doorLocal + 12
        func sign(_ draw: (inout PixelGrid, Int, Int) -> Void) {
            fill(&g, signX, wallTop + 4, 12, 1, 0x2A2A36)
            fill(&g, signX + 1, wallTop + 5, 10, 10, 0x1A1C2C)
            fill(&g, signX + 2, wallTop + 6, 8, 8, 0xC8A070)
            draw(&g, signX + 2, wallTop + 6)
        }
        switch b.style {
        case .bakery: sign { g, x, y in ellipse(&g, x + 4, y + 4, 3, 2, 0xD08A40); fill(&g, x + 2, y + 3, 5, 1, 0xF0C080) }
        case .inn: sign { g, x, y in fill(&g, x + 2, y + 2, 4, 5, 0xFFCD45); fill(&g, x + 2, y + 1, 4, 1, 0xFFFFFF); fill(&g, x + 6, y + 3, 1, 3, 0xFFCD45) }
        case .smithy:
            sign { g, x, y in fill(&g, x + 1, y + 3, 6, 2, 0x4A4A56); fill(&g, x + 3, y + 5, 2, 2, 0x4A4A56) }
            for i in 0..<5 { ellipse(&g, W - 21 + (i % 2) * 3, 0 + i, 3 - i / 2, 2, 0xC8C8D2) }
        case .alchemist: sign { g, x, y in ellipse(&g, x + 4, y + 5, 3, 2, 0xC879F2); fill(&g, x + 3, y + 1, 2, 3, 0xF4F4F4) }
        case .mill:
            // Rueda de molino al lado
            ellipse(&g, 14, wallTop + 6, 10, 10, 0x6A4422)
            ellipse(&g, 14, wallTop + 6, 7, 7, 0x9A6A3A)
            for a in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
                g[14 + Int(cos(a) * 9), wallTop + 6 + Int(sin(a) * 9)] = 0x4A2E16
            }
        case .chapel:
            // Campanario con cruz y vidriera
            fill(&g, W / 2 - 7, 0, 14, top + 20, 0xE8E8F0)
            fill(&g, W / 2 - 9, top + 8, 18, 3, 0x2A4A78)
            fill(&g, W / 2 - 3, 4, 6, 8, 0x2A2A36)
            fill(&g, W / 2 - 1, 5, 2, 4, 0xFFCD45)
            ellipse(&g, W / 2, wallTop - 10, 6, 6, 0x1A1C2C)
            for (i, c) in [0xE43B44, 0x41A6F6, 0xFFCD45, 0x6ACC5A].enumerated() {
                ellipse(&g, W / 2 + (i % 2 == 0 ? -2 : 2), wallTop - 10 + (i < 2 ? -2 : 2), 2, 2, UInt32(c))
            }
        case .house, .castle: break
        }
    }

    private static func window(_ g: inout PixelGrid, _ x: Int, _ y: Int, lit: Bool) {
        fill(&g, x - 1, y - 1, 14, 14, 0x4A3020)
        fill(&g, x, y, 12, 12, lit ? 0xFFD870 : 0x3A6A9A)
        fill(&g, x, y, 5, 5, lit ? 0xFFF4C0 : 0x8AC0E8)
        fill(&g, x + 5, y, 2, 12, 0x4A3020)
        fill(&g, x, y + 5, 12, 2, 0x4A3020)
        // Jardinera
        fill(&g, x - 2, y + 13, 16, 3, 0x8F5A32)
        for i in 0..<4 { ellipse(&g, x + i * 4, y + 12, 1, 1, [0xE43B44, 0xFFCD45, 0xF27AA8, 0xFFFFFF][i]) }
    }

    private static func door(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        fill(&g, x - 2, y - 2, 20, 24, 0x5A5A68)
        fill(&g, x, y, 16, 22, 0x6A4422)
        for i in 0..<4 { fill(&g, x + 1 + i * 4, y + 1, 1, 21, 0x4A2E16) }
        fill(&g, x, y, 16, 2, 0x8F5A32)
        fill(&g, x + 12, y + 11, 2, 2, 0xFFCD45)
        fill(&g, x - 2, y + 22, 20, 2, 0x8A8070)
    }

    /// El castillo: torres con tejados turquesa, muralla almenada, puerta y estandartes.
    private static func castle(_ b: Building, open: Bool) -> PixelGrid {
        let T = tile
        let W = b.width * T, H = b.height * T
        var g = PixelGrid(width: W, height: H + 40)
        let base = H + 40
        let stone: UInt32 = 0xC8C4CC, stoneDark: UInt32 = 0x9894A4, stoneLight: UInt32 = 0xE4E0EA
        let roof: UInt32 = 0x3AA8B8, roofDark: UInt32 = 0x24707E, roofLight: UInt32 = 0x7AE0EE

        func bricks(_ x: Int, _ y: Int, _ w: Int, _ h: Int) {
            fill(&g, x, y, w, h, stone)
            var row = 0
            var yy = y
            while yy < y + h {
                fill(&g, x, yy, w, 1, stoneDark)
                var xx = x + (row % 2) * 5
                while xx < x + w { fill(&g, xx, yy, 1, 5, stoneDark); xx += 10 }
                yy += 5
                row += 1
            }
            fill(&g, x, y, 2, h, stoneLight)
        }
        func coneRoof(_ cx: Int, _ bottom: Int, _ halfW: Int, _ height: Int) {
            for i in 0..<height {
                let hw = max(1, halfW * (height - i) / height)
                let y = bottom - i
                fill(&g, cx - hw, y, hw * 2, 1, (i / 3) % 2 == 0 ? roof : VillageArt.darken(roof, 0.9))
                fill(&g, cx - hw, y, max(1, hw / 3), 1, roofLight)
                fill(&g, cx + hw - max(1, hw / 4), y, max(1, hw / 4), 1, roofDark)
            }
            fill(&g, cx - 1, bottom - height - 8, 2, 8, 0x8A8A9A)
            ellipse(&g, cx, bottom - height - 9, 2, 2, 0xFFCD45)
        }
        func windowArch(_ x: Int, _ y: Int, lit: Bool) {
            fill(&g, x - 1, y - 1, 10, 15, 0x3A3644)
            fill(&g, x, y + 2, 8, 12, lit ? 0xFFD870 : 0x2A5A8A)
            fill(&g, x + 2, y, 4, 2, lit ? 0xFFD870 : 0x2A5A8A)
            fill(&g, x + 3, y + 2, 2, 12, 0x3A3644)
        }

        // Cuerpo central
        let bodyTop = base - H + 50
        bricks(30, bodyTop, W - 60, H - 50)
        // Tejado central a dos aguas
        for i in 0..<34 {
            let y = bodyTop - i
            let inset = 30 + i
            fill(&g, inset, y, W - inset * 2, 1, (i / 3) % 2 == 0 ? roof : VillageArt.darken(roof, 0.9))
            fill(&g, inset, y, 4, 1, roofLight)
        }
        fill(&g, 30, bodyTop, W - 60, 3, roofDark)
        // Torre del reloj
        let cx = W / 2
        bricks(cx - 28, bodyTop - 60, 56, 70)
        coneRoof(cx, bodyTop - 60, 34, 40)
        ellipse(&g, cx, bodyTop - 28, 16, 16, 0xD8A030)
        ellipse(&g, cx, bodyTop - 28, 13, 13, 0xF4ECD8)
        fill(&g, cx - 1, bodyTop - 38, 2, 11, 0x1A1C2C)
        fill(&g, cx, bodyTop - 29, 8, 2, 0x1A1C2C)
        for a in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 6) {
            g[cx + Int(cos(a) * 11), bodyTop - 28 + Int(sin(a) * 11)] = 0x8A6A2A
        }
        // Torres laterales
        for tx in [28, W - 28] {
            bricks(tx - 26, base - H + 30, 52, H - 30)
            coneRoof(tx, base - H + 30, 32, 42)
            windowArch(tx - 4, base - H + 50, lit: false)
            windowArch(tx - 4, base - H + 90, lit: false)
            // Almenas
            for i in 0..<5 { fill(&g, tx - 26 + i * 11, base - H + 26, 7, 5, stoneLight) }
        }
        // Ventanas del cuerpo
        for wx in stride(from: 70, to: W - 80, by: 34) where abs(wx + 4 - cx) > 36 {
            windowArch(wx, bodyTop + 20, lit: true)
        }
        // Escalinata y puerta
        let doorLocal = (b.doorX - b.x) * T + (b.doorWidth * T) / 2
        fill(&g, doorLocal - 26, base - 52, 52, 52, 0x8A8494)
        fill(&g, doorLocal - 22, base - 48, 44, 44, open ? 0x2A1A10 : 0x6A4422)
        if !open {
            for i in 0..<6 { fill(&g, doorLocal - 21 + i * 7, base - 47, 2, 43, 0x4A2E16) }
            fill(&g, doorLocal - 22, base - 34, 44, 3, 0x3A3A46)
            fill(&g, doorLocal - 22, base - 18, 44, 3, 0x3A3A46)
        }
        for i in 0..<3 { fill(&g, doorLocal - 30 + i * 2, base - 4 + i, 60 - i * 4, 1, stoneLight) }
        // Estandartes
        for bx in [doorLocal - 46, doorLocal + 36] {
            fill(&g, bx, base - 90, 12, 34, 0x2A6AB0)
            fill(&g, bx, base - 90, 12, 2, 0xFFCD45)
            ellipse(&g, bx + 6, base - 76, 3, 3, 0xF4F4F4)
            g[bx, base - 56] = 0x2A6AB0; g[bx + 11, base - 56] = 0x2A6AB0
        }
        return g.outlined()
    }

    // MARK: - Utilidades

    static func fill(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: UInt32) {
        guard w > 0, h > 0 else { return }
        for yy in y..<(y + h) { for xx in x..<(x + w) { g[xx, yy] = color } }
    }

    static func ellipse(_ g: inout PixelGrid, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ color: UInt32) {
        guard rx > 0, ry > 0 else { g[cx, cy] = color; return }
        for y in -ry...ry {
            for x in -rx...rx where Double(x * x) / Double(rx * rx) + Double(y * y) / Double(ry * ry) <= 1 {
                g[cx + x, cy + y] = color
            }
        }
    }

    private static func roundedStone(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: UInt32, mortar: UInt32, clipX: Int, clipW: Int) {
        for yy in y..<(y + h) {
            for xx in x..<(x + w) where xx >= clipX && xx < clipX + clipW {
                let corner = (xx == x || xx == x + w - 1) && (yy == y || yy == y + h - 1)
                g[xx, yy] = corner ? mortar : (yy == y ? VillageArt.lighten(c, 1.08) : (yy == y + h - 1 ? VillageArt.darken(c, 0.85) : c))
            }
        }
    }
}

private extension Tile {
    var isWallLike: Bool { self == .wall || self == .interiorWall }
}
