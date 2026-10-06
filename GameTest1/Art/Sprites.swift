import CoreGraphics
import GameCore
import SpriteKit

/// Paleta base (inspirada en Sweetie 16).
enum Pal {
    static let outline: UInt32 = 0x1A1C2C
    static let white: UInt32 = 0xF4F4F4
    static let steelLight: UInt32 = 0xC2C3C7
    static let steel: UInt32 = 0x94B0C2
    static let steelDark: UInt32 = 0x566C86
    static let night: UInt32 = 0x333C57
    static let red: UInt32 = 0xB13E53
    static let orange: UInt32 = 0xEF7D57
    static let yellow: UInt32 = 0xFFCD75
    static let lime: UInt32 = 0xA7F070
    static let green: UInt32 = 0x38B764
    static let teal: UInt32 = 0x257179
    static let blue: UInt32 = 0x3B5DC9
    static let navy: UInt32 = 0x29366F
    static let sky: UInt32 = 0x41A6F6
    static let cyan: UInt32 = 0x73EFF7
    static let purple: UInt32 = 0x5D275D
    static let wood: UInt32 = 0x7A4A2A
    static let woodLight: UInt32 = 0xB86F50
    static let woodDark: UInt32 = 0x4E2E1A
}

enum Sprites {
    // MARK: - Caballero (16x16, mirando a la derecha)

    private static let knightRows = [
        "......RR........",
        ".....RRRR.......",
        "....KKKKKK......",
        "...KWSSSSSK.....",
        "...KSSSSSSK.....",
        "...KSSSKKKK.....",
        "...KSSSSSsK.....",
        "....KKKKKK......",
        "...KBBBBBBK.....",
        "..KsBBBBBBBsK...",
        "..KsBYYYYYBsK...",
        "..KKBBBBBBBKK...",
        "...KbbbKbbbK....",
        "...KLLK.KLLK....",
        "...KLLK.KLLK....",
        "...KKKK.KKKK....",
    ]

    private static let knightWalkA = [
        "...KbbbKbbbK....",
        "..KLLK...KLLK...",
        "..KLLK...KLLK...",
        "..KKKK...KKKK...",
    ]

    private static let knightWalkB = [
        "...KbbbKbbbK....",
        "....KLLKLLK.....",
        "....KLLKLLK.....",
        "....KKKKKKK.....",
    ]

    enum KnightFrame: String { case idle, walkA, walkB }

    /// El color del cuerpo depende de la armadura equipada.
    static func knight(_ frame: KnightFrame, armorIcon: String) -> PixelSprite {
        let armor = itemPalette(armorIcon)
        let base = PixelSprite(rows: knightRows, palette: [
            "K": Pal.outline,
            "W": Pal.white,
            "S": Pal.steelLight,
            "s": Pal.steelDark,
            "R": Pal.red,
            "B": armor["S"] ?? Pal.blue,
            "b": armor["s"] ?? Pal.navy,
            "Y": Pal.yellow,
            "L": Pal.night,
        ])
        switch frame {
        case .idle: return base
        case .walkA: return base.replacingRows(from: 12, with: knightWalkA)
        case .walkB: return base.replacingRows(from: 12, with: knightWalkB)
        }
    }

    // MARK: - Goblins (14x14, mirando a la derecha)

    private static let goblinRows = [
        "..............",
        "..KK......KK..",
        "..KGKKKKKKGK..",
        "...KGGGGGGK...",
        "...KGGGEGEK...",
        "...KGGGGGGGK..",
        "...KGGKTKTK...",
        "....KKKKKK....",
        "...KCCCCCCK...",
        "..KGKCCCCKGK..",
        "..KGKCccCKGK..",
        "...KKCCCCKK...",
        "....KgKKgK....",
        "....KK..KK....",
    ]

    private static let goblinWalk = [
        "...KgK..KgK...",
        "...KK....KK...",
    ]

    static func goblinPalette(_ kind: MonsterKind) -> [Character: UInt32] {
        var p: [Character: UInt32] = ["K": Pal.outline, "T": Pal.white]
        switch kind {
        case .goblin:
            p["G"] = Pal.green; p["g"] = Pal.teal; p["E"] = Pal.yellow
            p["C"] = Pal.wood; p["c"] = Pal.woodDark
        case .goblinRunner:
            p["G"] = Pal.lime; p["g"] = Pal.green; p["E"] = Pal.orange
            p["C"] = Pal.purple; p["c"] = Pal.outline
        case .goblinBrute:
            p["G"] = 0x3E7A3A; p["g"] = 0x24502A; p["E"] = Pal.red
            p["C"] = Pal.steelDark; p["c"] = Pal.night
        case .goblinKing:
            p["G"] = 0x5A9E3A; p["g"] = Pal.teal; p["E"] = Pal.yellow
            p["C"] = Pal.red; p["c"] = Pal.purple
        }
        return p
    }

    static func goblin(_ kind: MonsterKind, frame: Int) -> PixelSprite {
        let sprite = PixelSprite(rows: goblinRows, palette: goblinPalette(kind))
        return frame == 0 ? sprite : sprite.replacingRows(from: 12, with: goblinWalk)
    }

    static let crown = PixelSprite(rows: [
        "Y..Y..Y",
        "YY.Y.YY",
        "YYYRYYY",
        "YYYYYYY",
    ], palette: ["Y": Pal.yellow, "R": Pal.red])

    // MARK: - Minerales (7x7)

    private static let gemRows = [
        "..KKK..",
        ".KLMMK.",
        "KLMMMDK",
        "KMMMMDK",
        "KMMMDDK",
        ".KMDDK.",
        "..KKK..",
    ]

    static func mineralColors(_ mineral: Mineral) -> (light: UInt32, mid: UInt32, dark: UInt32) {
        switch mineral {
        case .copper: (0xF0A070, 0xC8693C, 0x7A3A1E)
        case .iron: (0xC8C8D0, 0x8A8A96, 0x4A4A56)
        case .silver: (0xFFFFFF, 0xC0C8DC, 0x7C86A0)
        case .gold: (0xFFF09A, 0xF4C430, 0xA67C00)
        case .emerald: (0x9CF0B0, 0x2ECC71, 0x157A40)
        case .sapphire: (0x9CC8FF, 0x2F6FDF, 0x183A80)
        case .ruby: (0xFF9CA8, 0xE0213A, 0x7A0E1E)
        case .amethyst: (0xE0B0FF, 0x9B4DD6, 0x552080)
        case .diamond: (0xFFFFFF, 0xB9F2FF, 0x5FB3C9)
        case .mithril: (0xE0FFF8, 0x6FE0D0, 0x2A8A90)
        }
    }

    static func mineral(_ mineral: Mineral) -> PixelSprite {
        let c = mineralColors(mineral)
        return PixelSprite(rows: gemRows, palette: ["K": Pal.outline, "L": c.light, "M": c.mid, "D": c.dark])
    }

    // MARK: - Iconos de objetos (12x12, verticales: también se usan en la mano)

    private static let swordRows = [
        ".....K......",
        "....KWK.....",
        "....KWK.....",
        "....KWK.....",
        "....KWK.....",
        "....KWK.....",
        "....KWK.....",
        "..KKKYKKK...",
        "..KYYYYYK...",
        "....KHK.....",
        "....KHK.....",
        "....KYK.....",
    ]

    private static let axeRows = [
        "..KKKKKKK...",
        ".KSSSSKHK...",
        "KSSSSSKHK...",
        "KSWSSSKHK...",
        "KSSSSSKHK...",
        ".KSSSSKHK...",
        "..KKKKKHK...",
        "......KHK...",
        "......KHK...",
        "......KHK...",
        "......KHK...",
        "......KKK...",
    ]

    private static let hammerRows = [
        "..KKKKKKKK..",
        "..KSSSSSSK..",
        "..KSWSSSSK..",
        "..KSSSSSSK..",
        "..KKKKKKKK..",
        ".....KHK....",
        ".....KHK....",
        ".....KHK....",
        ".....KHK....",
        ".....KHK....",
        ".....KHK....",
        ".....KKK....",
    ]

    private static let spearRows = [
        ".....K......",
        "....KWK.....",
        "....KWK.....",
        "...KWSWK....",
        "...KSSSK....",
        "....KYK.....",
        "....KHK.....",
        "....KHK.....",
        "....KHK.....",
        "....KHK.....",
        "....KHK.....",
        "....KKK.....",
    ]

    private static let greatswordRows = [
        ".....KK.....",
        "....KWSK....",
        "....KWSK....",
        "....KWSK....",
        "....KWSK....",
        "....KWSK....",
        "....KWSK....",
        "..KKKYYKKK..",
        "..KYYYYYYK..",
        ".....KHK....",
        ".....KHK....",
        ".....KYK....",
    ]

    private static let armorRows = [
        "..KK....KK..",
        ".KSSK..KSSK.",
        "KSSSSKKSSSSK",
        "KSSSSSSSSSSK",
        ".KKSSSSSSKK.",
        "..KSSSSSSK..",
        "..KSWSSSSK..",
        "..KSSSSSSK..",
        "..KsssssSK..",
        "..KSSSSSSK..",
        "..KsSsSsSK..",
        "..KKKKKKKK..",
    ]

    static func itemPalette(_ icon: String) -> [Character: UInt32] {
        switch icon {
        case "sword_wood": ["W": 0xD9A066, "Y": Pal.wood, "H": Pal.woodDark]
        case "sword_iron": ["W": Pal.steelLight, "Y": Pal.steelDark, "H": Pal.wood]
        case "sword_steel": ["W": Pal.white, "Y": Pal.yellow, "H": Pal.purple]
        case "sword_rune": ["W": Pal.cyan, "Y": Pal.sky, "H": Pal.navy]
        case "axe": ["S": Pal.steel, "W": Pal.white, "H": Pal.wood]
        case "hammer": ["S": Pal.steelDark, "W": Pal.steel, "H": Pal.wood]
        case "spear": ["W": Pal.white, "S": Pal.steel, "Y": Pal.red, "H": Pal.woodLight]
        case "greatsword": ["W": Pal.white, "S": Pal.steel, "Y": Pal.yellow, "H": Pal.night]
        case "armor_tunic": ["S": 0xD9B48F, "s": 0xA77B5B, "W": 0xF0DCC0]
        case "armor_leather": ["S": 0x8F563B, "s": 0x5E3A24, "W": Pal.woodLight]
        case "armor_chain": ["S": Pal.steel, "s": Pal.steelDark, "W": Pal.white]
        case "armor_scale": ["S": Pal.green, "s": Pal.teal, "W": Pal.lime]
        case "armor_plate": ["S": Pal.steelLight, "s": 0x8B93AF, "W": 0xFFFFFF]
        case "armor_elven": ["S": Pal.cyan, "s": Pal.sky, "W": Pal.yellow]
        default: ["S": Pal.blue, "s": Pal.navy, "W": Pal.white]
        }
    }

    static func item(icon: String) -> PixelSprite {
        let rows: [String]
        switch icon {
        case "axe": rows = axeRows
        case "hammer": rows = hammerRows
        case "spear": rows = spearRows
        case "greatsword": rows = greatswordRows
        case let other where other.hasPrefix("armor"): rows = armorRows
        default: rows = swordRows
        }
        var palette = itemPalette(icon)
        palette["K"] = Pal.outline
        return PixelSprite(rows: rows, palette: palette)
    }

    // MARK: - Iconos de interfaz

    static let coin = PixelSprite(rows: [
        "..KKKK..",
        ".KYYYYK.",
        "KYWYYYOK",
        "KYYYYYOK",
        "KYYYYYOK",
        "KYYYYOOK",
        ".KOOOOK.",
        "..KKKK..",
    ], palette: ["K": Pal.outline, "Y": Pal.yellow, "O": Pal.orange, "W": Pal.white])

    static let heart = PixelSprite(rows: [
        ".KK...KK.",
        "KRRK.KRRK",
        "KRWRKRRRK",
        "KRRRRRRRK",
        ".KRRRRRK.",
        "..KRRRK..",
        "...KRK...",
        "....K....",
    ], palette: ["K": Pal.outline, "R": 0xE43B44, "W": Pal.white])

    static let potion = PixelSprite(rows: [
        "..KKKK..",
        "..KCCK..",
        "..KGGK..",
        ".KGGGGK.",
        "KGRRRRGK",
        "KRWRRRRK",
        "KRRRRRRK",
        "KRRRRRRK",
        ".KRRRRK.",
        "..KKKK..",
    ], palette: ["K": Pal.outline, "C": Pal.wood, "G": Pal.steel, "R": 0xE43B44, "W": Pal.white])

    static let skull = PixelSprite(rows: [
        ".KKKKK.",
        "KWWWWWK",
        "KWKWKWK",
        "KWWWWWK",
        ".KWKWK.",
        "..KKK..",
    ], palette: ["K": Pal.outline, "W": Pal.white])

    static let tree = PixelSprite(rows: [
        ".....KKKKKK.....",
        "...KKGGGGGGKK...",
        "..KGGGgGGGGGGK..",
        ".KGGGGGGGgGGGGK.",
        ".KGgGGGGGGGGGGK.",
        "KGGGGGGgGGGGGGGK",
        "KGGGGGGGGGGgGGGK",
        "KGgGGGGGGGGGGGGK",
        ".KGGGGgGGGGGGgK.",
        ".KGGGGGGGGGGGGK.",
        "..KKGGGGGGGGKK..",
        "....KKKKKKKK....",
        "......KTTK......",
        "......KTTK......",
        "......KTTK......",
        ".....KTTTTK.....",
    ], palette: ["K": 0x10241A, "G": 0x2E7D4A, "g": 0x1F5E3A, "T": Pal.wood])

    static let rock = PixelSprite(rows: [
        "..KKKK..",
        ".KSSWSK.",
        "KSSSSSsK",
        "KsSSSssK",
        ".KKKKKK.",
    ], palette: ["K": Pal.outline, "S": Pal.steel, "s": Pal.steelDark, "W": Pal.white])
}

// MARK: - Accesos con caché

enum Art {
    static func knightTexture(_ frame: Sprites.KnightFrame, armorIcon: String) -> SKTexture {
        ArtCache.texture("knight.\(frame.rawValue).\(armorIcon)") { Sprites.knight(frame, armorIcon: armorIcon) }
    }

    static func knightImage(armorIcon: String) -> CGImage {
        ArtCache.image("knight.idle.\(armorIcon)") { Sprites.knight(.idle, armorIcon: armorIcon) }
    }

    static func goblinTextures(_ kind: MonsterKind) -> [SKTexture] {
        (0...1).map { frame in
            ArtCache.texture("goblin.\(kind.rawValue).\(frame)") { Sprites.goblin(kind, frame: frame) }
        }
    }

    static func goblinImage(_ kind: MonsterKind) -> CGImage {
        ArtCache.image("goblin.\(kind.rawValue).0") { Sprites.goblin(kind, frame: 0) }
    }

    static func mineralTexture(_ mineral: Mineral) -> SKTexture {
        ArtCache.texture("mineral.\(mineral.rawValue)") { Sprites.mineral(mineral) }
    }

    static func mineralImage(_ mineral: Mineral) -> CGImage {
        ArtCache.image("mineral.\(mineral.rawValue)") { Sprites.mineral(mineral) }
    }

    static func itemTexture(icon: String) -> SKTexture {
        ArtCache.texture("item.\(icon)") { Sprites.item(icon: icon) }
    }

    static func itemImage(icon: String) -> CGImage {
        ArtCache.image("item.\(icon)") { Sprites.item(icon: icon) }
    }

    static var crown: SKTexture { ArtCache.texture("crown") { Sprites.crown } }
    static var tree: SKTexture { ArtCache.texture("tree") { Sprites.tree } }
    static var rock: SKTexture { ArtCache.texture("rock") { Sprites.rock } }
    static var treeImage: CGImage { ArtCache.image("tree") { Sprites.tree } }
    static var coin: CGImage { ArtCache.image("coin") { Sprites.coin } }
    static var heart: CGImage { ArtCache.image("heart") { Sprites.heart } }
    static var potion: CGImage { ArtCache.image("potion") { Sprites.potion } }
    static var skull: CGImage { ArtCache.image("skull") { Sprites.skull } }

    /// Fondo de hierba generado proceduralmente (1 pixel = 1 pixel de arte).
    static func grassBackground(width: Int, height: Int, seed: UInt64) -> CGImage {
        var rng = SeededGenerator(seed: seed)
        let shades: [UInt32] = [0x5AA04A, 0x4F9442, 0x63AB52, 0x56994A]
        let dark: UInt32 = 0x3F7D38
        let flowers: [UInt32] = [Pal.yellow, Pal.white, 0xF29AC0, Pal.cyan]
        let cell = 6
        let cellsX = width / cell + 2
        let cellsY = height / cell + 2
        let cellShade = (0..<(cellsX * cellsY)).map { _ in shades[Int.random(in: 0..<shades.count, using: &rng)] }

        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        func put(_ x: Int, _ y: Int, _ color: UInt32) {
            guard x >= 0, y >= 0, x < width, y < height else { return }
            let i = (y * width + x) * 4
            pixels[i] = UInt8((color >> 16) & 0xFF)
            pixels[i + 1] = UInt8((color >> 8) & 0xFF)
            pixels[i + 2] = UInt8(color & 0xFF)
            pixels[i + 3] = 255
        }
        for y in 0..<height {
            for x in 0..<width {
                // Celdas con un pequeño desplazamiento para que no se vea la cuadrícula.
                let jitter = (x * 7 + y * 13) % 3
                let cx = (x + jitter) / cell
                let cy = (y + jitter) / cell
                put(x, y, cellShade[cy * cellsX + cx])
            }
        }
        // Matas de hierba oscura
        for _ in 0..<(width * height / 40) {
            let x = Int.random(in: 0..<width, using: &rng)
            let y = Int.random(in: 0..<height, using: &rng)
            put(x, y, dark)
            put(x, y - 1, dark)
            if Bool.random(using: &rng) { put(x + 1, y, dark) }
        }
        // Flores
        for _ in 0..<(width * height / 500) {
            let x = Int.random(in: 0..<width, using: &rng)
            let y = Int.random(in: 0..<height, using: &rng)
            let color = flowers[Int.random(in: 0..<flowers.count, using: &rng)]
            put(x, y, Pal.yellow)
            put(x - 1, y, color)
            put(x + 1, y, color)
            put(x, y - 1, color)
            put(x, y + 1, color)
        }
        return PixelCanvas.image(width: width, height: height, pixels: pixels)
    }
}
