import CoreGraphics
import GameCore

/// Dibujo de las piezas de arma. Cada pieza ocupa una franja de 16 pixeles de ancho,
/// centrada en las columnas 7-8. L/M/D = claro/medio/oscuro del material, A = gema.
enum WeaponArt {
    static let width = 16
    static let headHeight = 12
    static let guardHeight = 3
    static let gripHeight = 8
    /// Alto total del arma montada antes del contorno.
    static let height = headHeight + guardHeight + gripHeight

    static let heads: [String: [String]] = [
        "sword": [
            ".......LM.......",
            "......LLMD......",
            "......LWMD......",
            "......LWMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
        ],
        "greatsword": [
            ".......LM.......",
            "......LLMD......",
            ".....LLWMDD.....",
            ".....LLWMDD.....",
            ".....LLDMDD.....",
            ".....LLDMDD.....",
            ".....LLDMDD.....",
            ".....LLDMDD.....",
            ".....LLDMDD.....",
            ".....LLDMDD.....",
            ".....LLLMDD.....",
            ".....LLLMDD.....",
        ],
        "katana": [
            "..........LM....",
            ".........LWD....",
            ".........LMD....",
            "........LWD.....",
            "........LMD.....",
            ".......LMD......",
            ".......LMD......",
            ".......LMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
        ],
        "dagger": [
            "................",
            "................",
            "................",
            "................",
            ".......LM.......",
            "......LWMD......",
            "......LWMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
            "......LLMD......",
        ],
        "spear": [
            ".......LM.......",
            "......LWMD......",
            ".....LLWMDD.....",
            ".....LLLMDD.....",
            "......LLMD......",
            ".......LM.......",
            "......DMMD......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
        ],
        "axe": [
            ".......MD.......",
            "...LLM.MD.......",
            "..LWLMMMD.......",
            ".LWLLMMMDD......",
            ".LLLMMMMDD......",
            ".LLLMMMMDD......",
            "..LLMMMMD.......",
            "...LMM.MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
        ],
        "hammer": [
            "................",
            "..LLLLLLMMMMDD..",
            "..LWWLLLMMMMDD..",
            "..LLLLLLMMMMDD..",
            "..LMMMMMMMMMDD..",
            "..DDDDDDDDDDDD..",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
        ],
        "mace": [
            ".......LM.......",
            "....L.LLMD.D....",
            ".....LWLMDD.....",
            "...LLLWLMMDDD...",
            "....LLLMMMDD....",
            ".....LMMMDD.....",
            "....M.MMDD.D....",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
        ],
        "scythe": [
            ".LLLLLLMD.......",
            "LWMMMMMMD.......",
            "LMD....MD.......",
            "LD.....MD.......",
            "L......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
            ".......MD.......",
        ],
    ]

    static let guards: [String: [String]] = [
        "straight": [
            "..LLLLLLMMMMDD..",
            "..MMMMMMDDDDDD..",
            "......MMDD......",
        ],
        "curved": [
            ".LL.........DD..",
            "..LLLLLMMMMDD...",
            "......MMDD......",
        ],
        "winged": [
            "LL............DD",
            ".LLLL.LMMD.MMDD.",
            "...LLLLMMDDDD...",
        ],
        "ring": [
            ".....LLMMD......",
            "..LLLL.AA.DDDD..",
            ".....LMMDD......",
        ],
        "skull": [
            ".....LLLMMD.....",
            "..LL.LOLOD.DD...",
            ".....LMMMD......",
        ],
        "claw": [
            ".L.L........D.D.",
            "..LLLLLMMMMDD...",
            "......MMDD......",
        ],
        "crown": [
            "..L.L.LA.M.D.D..",
            "..LLLLLMMMMDDD..",
            "......MMDD......",
        ],
    ]

    static let grips: [String: [String]] = [
        "short": [
            "......LMMD......",
            "......MDMD......",
            "......LMMD......",
            "......MDMD......",
            ".....LLMMDD.....",
            "......LMDD......",
            "................",
            "................",
        ],
        "long": [
            "......LMMD......",
            "......MDMD......",
            "......LMMD......",
            "......MDMD......",
            "......LMMD......",
            "......MDMD......",
            ".....LLMMDD.....",
            "......LMDD......",
        ],
        "wrapped": [
            "......LLLD......",
            "......MMMD......",
            "......LLLD......",
            "......MMMD......",
            "......LLLD......",
            "......MMMD......",
            "......DDDD......",
            "................",
        ],
        "pommel": [
            "......LMMD......",
            "......LMMD......",
            "......LMMD......",
            "......LMMD......",
            ".....LLMMDD.....",
            "....LLWMMDDD....",
            ".....LMMMDD.....",
            "......DDDD......",
        ],
        "runic": [
            "......LMMD......",
            "......LAAD......",
            "......LMMD......",
            "......LAAD......",
            "......LMMD......",
            ".....LMAMDD.....",
            "......DDDD......",
            "................",
        ],
    ]

    private static func rows(for part: WeaponPart) -> [String] {
        switch part.slot {
        case .head: heads[part.shape] ?? heads["sword"]!
        case .hilt: guards[part.shape] ?? guards["straight"]!
        case .grip: grips[part.shape] ?? grips["short"]!
        }
    }

    private static func sprite(for part: WeaponPart) -> PixelSprite {
        let gem: UInt32 = part.isSpecial ? 0xE43B44 : 0x73EFF7
        let palette: [Character: UInt32] = [
            "L": part.palette[0], "M": part.palette[1], "D": part.palette[2],
            "W": 0xFFFFFF, "A": gem, "O": Pal.outline,
        ]
        return PixelSprite(rows: rows(for: part), palette: palette)
    }

    /// Arma montada: hoja arriba, guarda en medio, empuñadura abajo. Con contorno.
    static func composite(partIDs: [String]) -> PixelGrid {
        let parts = partIDs.compactMap(PartCatalog.part)
        var grid = PixelGrid(width: width, height: height)
        // La empuñadura se dibuja primero para que la guarda quede encima.
        if let grip = parts.first(where: { $0.slot == .grip }) {
            grid.draw(sprite(for: grip), x: 0, y: headHeight + guardHeight)
        }
        if let head = parts.first(where: { $0.slot == .head }) {
            grid.draw(sprite(for: head), x: 0, y: 0)
        }
        if let hilt = parts.first(where: { $0.slot == .hilt }) {
            grid.draw(sprite(for: hilt), x: 0, y: headHeight)
        }
        return grid.outlined()
    }

    /// Pieza suelta, para la tienda y el inventario.
    static func single(_ part: WeaponPart) -> PixelGrid {
        let s = sprite(for: part)
        var grid = PixelGrid(width: width, height: s.height)
        grid.draw(s, x: 0, y: 0)
        return grid.outlined()
    }

    /// Punto de agarre (en pixeles del arma contorneada, desde arriba).
    static let gripPoint = CGPoint(x: 8.5, y: Double(headHeight + guardHeight + 3))
}
