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
    // MARK: - Iconos de armaduras y espada de entrenamiento (12x12)

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
        var palette = itemPalette(icon)
        palette["K"] = Pal.outline
        return PixelSprite(rows: icon.hasPrefix("armor") ? armorRows : swordRows, palette: palette)
    }

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

    static let crown = PixelSprite(rows: [
        "Y..Y..Y",
        "YY.Y.YY",
        "YYYRYYY",
        "YYYYYYY",
    ], palette: ["Y": Pal.yellow, "R": Pal.red])

    // MARK: - El enano herrero (tienda)

    static let dwarf: PixelGrid = {
        let rows = [
            ".......SSSSSS",
            ".....SSWWSSSSSs",
            "....SSWSSSSSSSSs",
            "...sSSSSSSSSSSSSs",
            "...ddddYddddYdddd",
            "....FFFFFFFFFFFf",
            "...FFEeFFFFFEeFf",
            "...FFFFFfNNfFFFf",
            "...OBBBBFNNNFBBBB",
            "..OBBBBBBMMMBBBBBb",
            "..BBBBBBBBBBBBBBBb",
            "..BBBBbBBBBBBbBBBb",
            "...BBBBBBBBBBBBBb",
            ".CCBBBBbBBBbBBBBCC",
            "CCCCcBBBBBBBBBBcCCC",
            "CCCCABBBBYBBBBBACCC",
            "FFCCAAABBBBBBAAACFF",
            "FFC.AAAABBYBBAAAA.CFF",
            "ff..AAAAABBBAAAAA..ff",
            "....AAAAAABAAAAAA",
            "....AAaAAAAAAAaAA",
            "....AAAAAAAAAAAAA",
            "....aaaaaaaaaaaaa",
            ".....LLL.....LLL",
            ".....LLL.....LLL",
            "....EEEE....EEEE",
        ]
        let palette: [Character: UInt32] = [
            "S": Pal.steelLight, "s": 0x8B93AF, "W": 0xFFFFFF, "d": Pal.steelDark, "Y": Pal.yellow,
            "F": 0xF4C095, "f": 0xC8875E, "E": Pal.outline, "e": 0xFFFFFF, "N": 0xE89A7A,
            "O": 0xFFB060, "B": 0xE07A30, "b": 0xA04E1E, "M": 0x8A3A1A,
            "C": 0x4F7A3A, "c": 0x335228, "A": 0x8F563B, "a": 0x5E3A24, "L": 0x4A3A2A,
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: palette)).outlined()
    }()

    static let anvil: PixelGrid = {
        let rows = [
            "WSSSSSSSSSSSSSSSWW",
            ".sSSSSSSSSSSSSSSSs",
            "..ssssssSSSSSSSs",
            "......dSSSSd",
            ".......dSSd",
            ".......dSSd",
            ".....ddSSSSdd",
            "....dSSSSSSSSd",
            "....dddddddddd",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["W": 0xFFFFFF, "S": 0x6A6A78, "s": 0x4A4A56, "d": 0x33333C])).outlined()
    }()

    static let hammer: PixelGrid = {
        let rows = [
            "SSSSSS",
            "SWSSSs",
            "SSSSSs",
            "..HH",
            "..HH",
            "..HH",
            "..HH",
            "..hh",
        ]
        return PixelGrid(PixelSprite(rows: rows, palette: ["S": 0x8A8A96, "s": 0x4A4A56, "W": 0xFFFFFF, "H": Pal.woodLight, "h": Pal.wood])).outlined()
    }()

    // MARK: - Decoración del pueblo

    static let barrel = PixelSprite(rows: [
        ".KKKKKKK.",
        "KWWWWWWWK",
        "KBBBBBBbK",
        "KMMMMMMmK",
        "KBBBBBBbK",
        "KBBBBBBbK",
        "KMMMMMMmK",
        "KBBBBBBbK",
        ".KKKKKKK.",
    ], palette: ["K": Pal.outline, "W": 0xC08A5A, "B": 0x9A6A3A, "b": 0x6A4422, "M": 0x6A6A78, "m": 0x4A4A56])

    static let crate = PixelSprite(rows: [
        "KKKKKKKKKK",
        "KWWWWWWWbK",
        "KWbWWWWbbK",
        "KWWbWWbWbK",
        "KWWWbbWWbK",
        "KWWbWWbWbK",
        "KWbWWWWbbK",
        "KbbbbbbbbK",
        "KKKKKKKKKK",
    ], palette: ["K": Pal.outline, "W": 0xC8A070, "b": 0x8A6A40])

    static let lampPost = PixelSprite(rows: [
        ".KKKKK.",
        "KYWYYYK",
        "KYYYYYK",
        ".KKKKK.",
        "...K...",
        "...K...",
        "...K...",
        "...K...",
        "...K...",
        "...K...",
        "...K...",
        "...K...",
        "..KKK..",
        ".KKKKK.",
    ], palette: ["K": 0x2A2E40, "Y": 0xFFD870, "W": 0xFFFFFF])

    static let gravestone = PixelSprite(rows: [
        "..KKKK..",
        ".KSSSSK.",
        "KSSWSSsK",
        "KSWWWSsK",
        "KSSWSSsK",
        "KSSWSSsK",
        "KSSSSSsK",
        "KsssssssK",
    ], palette: ["K": Pal.outline, "S": 0x9A9AA6, "s": 0x6A6A78, "W": 0x5A5A66])

    static let hay = PixelSprite(rows: [
        "..KKKKKKK..",
        ".KYYYYYYYK.",
        "KYyYYyYYyYK",
        "KYYYYYYYYYK",
        "KyYYyYYyYYK",
        "KYYYYYYYYyK",
        ".KKKKKKKKK.",
    ], palette: ["K": Pal.outline, "Y": 0xE8C060, "y": 0xB08A30])

    static let banner = PixelSprite(rows: [
        "KKKKKKKKK",
        "KRRRRRRRK",
        "KRRYYYRRK",
        "KRYYRYYRK",
        "KRRYYYRRK",
        "KRRRYRRRK",
        "KRRRRRRRK",
        "KRRRRRRRK",
        "KRRK.KRRK",
        "KRK...KRK",
        "KK.....KK",
    ], palette: ["K": Pal.outline, "R": 0x2A7A3A, "Y": Pal.yellow])
}

// MARK: - Accesos con caché

enum Art {
    static func heroTexture(_ pose: HeroArt.Pose, armorIcon: String, race: Race) -> SKTexture {
        ArtCache.texture("hero.\(pose.rawValue).\(armorIcon).\(race.rawValue)", grid: { HeroArt.grid(race: race, armorIcon: armorIcon, pose: pose) })
    }

    static func heroImage(armorIcon: String, race: Race) -> CGImage {
        ArtCache.image("hero.idle0.\(armorIcon).\(race.rawValue)", grid: { HeroArt.grid(race: race, armorIcon: armorIcon, pose: .idle0) })
    }

    static func mineralTexture(_ mineral: Mineral) -> SKTexture {
        ArtCache.texture("mineral.\(mineral.rawValue)") { Sprites.mineral(mineral) }
    }

    static func mineralImage(_ mineral: Mineral) -> CGImage {
        ArtCache.image("mineral.\(mineral.rawValue)") { Sprites.mineral(mineral) }
    }

    /// Icono de un objeto: armas forjadas (dibujo propio o compuesto) o iconos clásicos.
    static func itemImage(_ item: Item) -> CGImage {
        if item.slot == .weapon, item.partIDs != nil {
            return weaponImage(item)
        }
        return itemImage(icon: item.icon)
    }

    static func itemImage(icon: String) -> CGImage {
        ArtCache.image("item.\(icon)") { Sprites.item(icon: icon) }
    }

    static func itemTexture(_ item: Item) -> SKTexture {
        ArtCache.texture(fromImage: itemImage(item))
    }

    static func weaponImage(_ item: Item) -> CGImage {
        if let custom = item.customSprite, !custom.isEmpty {
            return PixelGrid(custom: custom).makeCGImage()
        }
        let ids = item.partIDs ?? []
        return ArtCache.image("weapon.\(ids.joined(separator: "|"))", grid: { WeaponArt.composite(partIDs: ids) })
    }

    static func partImage(_ part: WeaponPart) -> CGImage {
        ArtCache.image("part.\(part.id)", grid: { WeaponArt.single(part) })
    }

    static func gridImage(_ key: String, _ grid: @autoclosure () -> PixelGrid) -> CGImage {
        ArtCache.image(key, grid: grid)
    }

    static func gridTexture(_ key: String, _ grid: @autoclosure () -> PixelGrid) -> SKTexture {
        ArtCache.texture(key, grid: grid)
    }

    static var crown: SKTexture { ArtCache.texture("crown") { Sprites.crown } }
    static var coin: CGImage { ArtCache.image("coin") { Sprites.coin } }
    static var heart: CGImage { ArtCache.image("heart") { Sprites.heart } }
    static var potion: CGImage { ArtCache.image("potion") { Sprites.potion } }
    static var skull: CGImage { ArtCache.image("skull") { Sprites.skull } }
    static var dwarf: CGImage { gridImage("dwarf", Sprites.dwarf) }
    static var anvil: CGImage { gridImage("anvil", Sprites.anvil) }
    static var smithHammer: CGImage { gridImage("smithHammer", Sprites.hammer) }
}
