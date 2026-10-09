import GameCore

/// Paleta y ajustes de un tema de la mazmorra. Las rampas van de oscuro (0) a claro (último).
struct DungeonStyle {
    let theme: DungeonTheme
    /// Fondo fuera del mapa.
    var void: UInt32
    /// Luz de antorchas y braseros, cuánto aclaran y la luz ambiente lejos de ellas.
    var light: UInt32
    var lightGain: Double
    var ambient: Double
    /// Tinte de las zonas oscuras (r, g, b): sombras frías.
    var shadowTint: (Double, Double, Double)
    /// Cuánto ilumina el líquido (la lava mucho; el abismo de la cripta, un resplandor frío).
    var liquidLight: Double

    /// Suelo: [junta, oscuro, medio, claro, brillo].
    var floor: [UInt32]
    /// Cara de la pared: [junta, oscuro, medio, claro, brillo].
    var wall: [UInt32]
    /// Tapa de la pared: [fondo, oscuro, medio, borde medio, borde iluminado].
    var cap: [UInt32]
    var moss: [UInt32]
    /// Líquido: [profundo, oscuro, medio, claro, espuma/brillo].
    var liquid: [UInt32]
    /// Orilla vista de lado (talud de piedra o roca que baja al líquido).
    var bank: [UInt32]
    var carpet: [UInt32]
    var trim: [UInt32]
    var wood: [UInt32]
    var iron: [UInt32]
    var bone: [UInt32]
    /// Piedra de pilares y estatuas.
    var stone: [UInt32]
    /// Tela de estandartes y su emblema.
    var banner: [UInt32]
    var emblem: UInt32
    /// Brillo especial del tema (runas, cristales, brasas).
    var magic: [UInt32]
    /// Llama: [exterior, medio, interior, núcleo, punta].
    var flame: [UInt32]

    static func of(_ theme: DungeonTheme) -> DungeonStyle {
        switch theme {
        case .prison: prison
        case .crypt: crypt
        case .sewer: sewer
        case .mine: mine
        case .forge: forge
        }
    }

    static let ironRamp: [UInt32] = [0x16161E, 0x2C2C36, 0x464652, 0x6A6A78, 0x9C9CAA]
    static let woodRamp: [UInt32] = [0x2E1C14, 0x4C3020, 0x6A442A, 0x8A5C38, 0xAE7C4C]
    static let boneRamp: [UInt32] = [0x5E5648, 0x8E8470, 0xB8AE94, 0xDCD4BC, 0xF4EEDC]
    static let goldRamp: [UInt32] = [0x5A3A12, 0x8E6420, 0xC89A34, 0xF0CC5C, 0xFFF0A8]
    static let fireRamp: [UInt32] = [0xA8281A, 0xE85A1E, 0xFF9A2E, 0xFFD45C, 0xFFF6C8]

    static let prison = DungeonStyle(
        theme: .prison, void: 0x0A0A10,
        light: 0xFFB45A, lightGain: 0.62, ambient: 0.76, shadowTint: (0.92, 0.96, 1.08), liquidLight: 0,
        floor: [0x24242C, 0x44444E, 0x50505A, 0x5C5C66, 0x6C6C76],
        wall: [0x202028, 0x484854, 0x585864, 0x6A6A76, 0x84848E],
        cap: [0x16161C, 0x22222A, 0x2A2A33, 0x484854, 0x6A6A78],
        moss: [0x26301E, 0x34422A, 0x485A34, 0x607444],
        liquid: [0x16201E, 0x22312D, 0x2E433D, 0x52695E, 0x92A898],
        bank: [0x1A1A20, 0x2E2E36, 0x3E3E48, 0x4E4E58],
        carpet: [0x3E1218, 0x5E1C26, 0x7E2A34, 0x9A3C44],
        trim: goldRamp,
        wood: woodRamp, iron: ironRamp, bone: boneRamp,
        stone: [0x2E2E38, 0x4C4C58, 0x666672, 0x84848E, 0xA6A6B0],
        banner: [0x3E1218, 0x6A1E28, 0x8E2C34, 0xB04048],
        emblem: 0xE8C060,
        magic: [0x6A1A10, 0xC84A1A, 0xFF9A3A],
        flame: fireRamp
    )

    static let crypt = DungeonStyle(
        theme: .crypt, void: 0x08060E,
        light: 0x8CC8FF, lightGain: 0.58, ambient: 0.72, shadowTint: (0.94, 0.94, 1.12), liquidLight: 0.16,
        floor: [0x1E1A28, 0x3A3448, 0x463F55, 0x524A62, 0x625A74],
        wall: [0x1C1826, 0x3E384C, 0x4C455C, 0x5C546E, 0x766E8A],
        cap: [0x120F1A, 0x1E1A28, 0x262132, 0x40384F, 0x645A7A],
        moss: [0x1E2A2A, 0x2A3A3A, 0x3A5050, 0x4E6A68],
        liquid: [0x030208, 0x08060F, 0x100C1C, 0x2A2444, 0x6A5E9A],
        bank: [0x14101C, 0x24202E, 0x322C40, 0x403852],
        carpet: [0x241030, 0x3A1A4A, 0x522A64, 0x6A3C7E],
        trim: goldRamp,
        wood: [0x261810, 0x3E281A, 0x563824, 0x6E4A30, 0x8E643E],
        iron: ironRamp, bone: boneRamp,
        stone: [0x34303E, 0x5A5468, 0x7C7690, 0xA09AB4, 0xC8C2DA],
        banner: [0x241030, 0x3E1C52, 0x582C70, 0x744090],
        emblem: 0xF0CC5C,
        magic: [0x1E5A7A, 0x3AA8D8, 0x9AE8FF],
        flame: [0x1E2E9A, 0x3A64E0, 0x5AA8FF, 0xA8E4FF, 0xEAFAFF]
    )

    static let sewer = DungeonStyle(
        theme: .sewer, void: 0x060A08,
        light: 0xFFC064, lightGain: 0.6, ambient: 0.76, shadowTint: (0.9, 1.0, 1.02), liquidLight: 0,
        floor: [0x20241C, 0x3C4234, 0x484E3E, 0x545A48, 0x646A56],
        wall: [0x241C18, 0x4C3A30, 0x5C463A, 0x6C5444, 0x846A56],
        cap: [0x12140F, 0x1E2219, 0x262B20, 0x404A36, 0x5E6A4E],
        moss: [0x203018, 0x2E4620, 0x426228, 0x5E8236],
        liquid: [0x10261A, 0x1A3A26, 0x245032, 0x3E7046, 0x86B87A],
        bank: [0x1E1814, 0x34281F, 0x46362A, 0x564434],
        carpet: [0x3A2614, 0x5A3C20, 0x74502C, 0x8E6638],
        trim: [0x2A1A10, 0x3E2A1A, 0x584020, 0x6E5430, 0x8A6E44],
        wood: [0x2A2014, 0x463420, 0x5E462C, 0x765A38, 0x927048],
        iron: [0x1A1A16, 0x2E2C26, 0x4A4236, 0x6E5E46, 0x8E7A5A],
        bone: boneRamp,
        stone: [0x2C2E26, 0x484C3E, 0x5E6450, 0x787E66, 0x989E84],
        banner: [0x1E2A16, 0x2E4020, 0x3E542A, 0x506836],
        emblem: 0xA8B060,
        magic: [0x3A6A1A, 0x7AB42E, 0xC8F05A],
        flame: fireRamp
    )

    static let mine = DungeonStyle(
        theme: .mine, void: 0x0B0807,
        light: 0x8EF0D8, lightGain: 0.56, ambient: 0.76, shadowTint: (1.0, 0.95, 0.98), liquidLight: 0,
        floor: [0x2A201A, 0x46382C, 0x544334, 0x624F3E, 0x74604C],
        wall: [0x221A16, 0x463830, 0x56463A, 0x685646, 0x80705C],
        cap: [0x17120F, 0x261F1A, 0x30271F, 0x524333, 0x786450],
        moss: [0x2A2A1E, 0x3A3A28, 0x4E4E34, 0x646440],
        liquid: [0x040303, 0x0A0806, 0x14100C, 0x2A221A, 0x4A3E30],
        bank: [0x1A1410, 0x2E241C, 0x3E3226, 0x4E4030],
        carpet: [0x2E241C, 0x4A3A2C, 0x5E4A38, 0x725C46],
        trim: ironRamp,
        wood: woodRamp, iron: ironRamp, bone: boneRamp,
        stone: [0x2E2620, 0x4E4236, 0x6A5C4C, 0x887862, 0xA8987E],
        banner: [0x2E3A3A, 0x3E5050, 0x506A68, 0x648482],
        emblem: 0x8EF0D8,
        magic: [0x0E5A5A, 0x1E9C94, 0x4AD8CC, 0xA4FFF2, 0xF0FFFC],
        flame: [0x0E6A5A, 0x1EB09A, 0x5AE8C8, 0xB4FFEC, 0xF2FFFA]
    )

    static let forge = DungeonStyle(
        theme: .forge, void: 0x0C0505,
        light: 0xFF9A48, lightGain: 0.66, ambient: 0.70, shadowTint: (1.04, 0.92, 0.94), liquidLight: 0.42,
        floor: [0x1A1212, 0x342826, 0x40322E, 0x4C3C36, 0x5C4A42],
        wall: [0x181010, 0x382A26, 0x463430, 0x54403A, 0x6A5248],
        cap: [0x110A0A, 0x1E1414, 0x281A18, 0x4A3028, 0x6E4636],
        moss: [0x2A1A14, 0x3A241A, 0x4A2E20, 0x5E3A28],
        liquid: [0x8A1A0A, 0xD03A0E, 0xF8701A, 0xFFB234, 0xFFEE8A],
        bank: [0x1A0F0D, 0x2E1C18, 0x40281F, 0x523428],
        carpet: [0x1E1A1C, 0x34302E, 0x4A4442, 0x625C58],
        trim: [0x4A1E10, 0x8A3414, 0xC85A1E, 0xF08A30, 0xFFC060],
        wood: [0x261612, 0x3E241A, 0x563222, 0x6E422C, 0x8A5638],
        iron: [0x141216, 0x2A2628, 0x423C3C, 0x625A56, 0x8E847A],
        bone: [0x4E4238, 0x766654, 0x9A8A74, 0xBEAE92, 0xDCCEB0],
        stone: [0x241A18, 0x3E2E2A, 0x544038, 0x6C5448, 0x8A6E5E],
        banner: [0x3A0E0A, 0x5E1810, 0x822418, 0xA03420],
        emblem: 0xF0A040,
        magic: [0x8A1E0A, 0xE8501A, 0xFFA030, 0xFFE070],
        flame: [0xC0300E, 0xFF6A1A, 0xFFAA30, 0xFFE46A, 0xFFFBD8]
    )
}
