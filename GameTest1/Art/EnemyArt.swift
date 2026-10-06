import CoreGraphics
import GameCore
import SpriteKit

/// Los 50 enemigos se construyen con ~10 cuerpos detallados + accesorios (gorros, armas, coronas)
/// y paletas propias. Todo se compone en un `PixelGrid` y se le añade contorno.
enum EnemyArt {
    // MARK: - Cuerpos (mirando a la derecha, sin contorno)

    struct Template {
        let rows: [String]
        let palette: [Character: UInt32]
        /// Esquina superior izquierda de la cabeza (para gorros).
        let head: (Int, Int)
        /// Mano delantera (para armas).
        let hand: (Int, Int)
    }

    static let templates: [String: Template] = [
        "goblin": Template(rows: [
            "....GGGGG",
            "gg.GHHGGGG.gg",
            "gAgGHGGGGGGgAg",
            ".gAGGGGEeGEeG",
            "..gGGGGGGGGGGN",
            "...gGGGMTMTMG",
            "....ggGGGGGg",
            ".....gggggg",
            "....CCCCCCC",
            "...GCCcCCCCG",
            "..GGCbbbbbCGG",
            "..Gg.CcCCcC.gG",
            ".....CCcCCC",
            ".....gG.gG",
            ".....gG.gG",
            "....FFF.FFF",
        ], palette: [
            "G": 0x5DAA48, "g": 0x3A7A3A, "H": 0x8CD070, "A": 0x2A5A2A, "E": 0xFFE070, "e": 0xB01A1A,
            "N": 0x4A9A3A, "M": 0x3A1A1A, "T": 0xFFFFFF, "C": 0x8F5A32, "c": 0x5E3A24, "b": 0x3A2A1A, "F": 0x3A2A1A,
        ], head: (3, -1), hand: (12, 10)),

        "human": Template(rows: [
            "...hHHHh",
            "..hHHHHHh",
            "..hHFFFFF",
            "..hFFFEFE",
            "..hFFFFFFf",
            "...fFFFFf",
            "....ffff",
            "..cCCCCCCc",
            ".cCCCCCCCCc",
            ".cCcCCCCcCc",
            ".cCcCCCCcCc",
            ".cCcBBBBcCc",
            ".FF.CCcCC.FF",
            "....PPPpPP",
            "....PPp.PPp",
            "....PPp.PPp",
            "....PPp.PPp",
            "...SSSs.SSSs",
        ], palette: [
            "H": 0x5A3A22, "h": 0x3A2414, "F": 0xF4C095, "f": 0xC8875E, "E": 0x1A1C2C,
            "C": 0x7A4A2A, "c": 0x4E2E1A, "B": 0x2A1A10, "P": 0x4A4A5A, "p": 0x33333F, "S": 0x2A2018,
        ], head: (1, -1), hand: (11, 11)),

        "skeleton": Template(rows: [
            "...WWWWW",
            "..WWWWWWw",
            "..WWWWEEWE",
            "..WWWWEEWE",
            "..WWWWWWWw",
            "...WwOwOw",
            "....wwww",
            ".....Ww",
            "..wWWWWWWw",
            ".W.wOWOWw.W",
            ".W.WOwOwW.W",
            ".w.wOWOWw.w",
            ".W..wWWw..W",
            "...WWwwWW",
            "...Ww...Ww",
            "...Ww...Ww",
            "...Ww...Ww",
            "..WWw..WWw",
        ], palette: ["W": 0xEDE6D0, "w": 0xB8AE90, "E": 0x1A1C2C, "O": 0x2A2A34], head: (1, -2), hand: (10, 10)),

        "rat": Template(rows: [
            "..........ff",
            ".........fFFf",
            "....ffffFFFFEf",
            "..fFFFFFFFFFFFN",
            "TfFHHFFFFFFFFf",
            "T.fFFFFFFFFFf",
            "T..ffFfffFf",
            ".T..f.f..f.f",
        ], palette: ["F": 0x8A7A6A, "f": 0x5A4E44, "H": 0xB0A08E, "E": 0xE03030, "N": 0xF0A0A0, "T": 0xE0A0A0],
           head: (9, -2), hand: (13, 4)),

        "dog": Template(rows: [
            ".............ff",
            "............fFFf",
            "...........fFFFFf",
            "..........fFFEFFN",
            "f.........fFFFFFFn",
            "Ff.ffffffffFFFFff",
            ".FfFFFHHHHFFFFff",
            "..FFFFFFFFFFFFf",
            "..fFFFFFFFFFFf",
            "..fF.fF...fF.fF",
            "..fF.fF...fF.fF",
            ".ff..ff..ff..ff",
        ], palette: ["F": 0x9A7A5A, "f": 0x6A4E36, "H": 0xC8A880, "E": 0x1A1C2C, "N": 0x1A1C2C, "n": 0x6A3A3A],
           head: (10, -2), hand: (16, 5)),

        "boar": Template(rows: [
            "...........ff",
            "....ffffffFFFf",
            "..fFFFFFFFFFFFEf",
            ".fFHHHFFFFFFFFFFN",
            "fFFFFFFFFFFFFFFNN",
            "fFFFFFFFFFFFFFFTw",
            ".fFFFFFFFFFFFFf",
            "..fffffffffff",
            "..fF.fF..fF.fF",
            "..fF.fF..fF.fF",
            "..ff.ff..ff.ff",
        ], palette: ["F": 0x6A4A36, "f": 0x45301F, "H": 0x8F6A4E, "E": 0x1A1C2C, "N": 0xD08A7A, "T": 0xFFF4D8, "w": 0xC8B898],
           head: (10, -2), hand: (15, 3)),

        "bird": Template(rows: [
            "F..........F",
            "FF........FF",
            ".FFf....fFF",
            "..fFFffFFf.HH",
            "...fFFFFFFHEHB",
            "....fFFFFFHHH",
            ".....fFFFf",
            "....ff..ff",
        ], palette: ["F": 0x2A2A3A, "f": 0x1A1A26, "H": 0x3A3A4E, "E": 0xFFE070, "B": 0xE0A040],
           head: (9, 1), hand: (10, 5)),

        "bat": Template(rows: [
            "F..............F",
            "FF....f..f....FF",
            "FFF..fFFFFf..FFF",
            "FFFFfFEFFEFfFFFF",
            ".FFFFFFFFFFFFFF.",
            "..FF.fFTTFf.FF..",
            "...F..fFFf..F...",
            "........f.......",
        ], palette: ["F": 0x5A3A5A, "f": 0x3A2440, "E": 0xFF4040, "T": 0xFFFFFF],
           head: (5, -2), hand: (12, 4)),

        "slime": Template(rows: [
            ".....HHHH",
            "...HHGGGGGg",
            "..HGGGGGGGGg",
            ".HGGGGGGGGGGg",
            ".GGGGGEGGGEGg",
            "GGGGGGEGGGEGGg",
            "GGGGGGGGGGGGGg",
            "GGGGGGMMMGGGGg",
            ".gGGGGGGGGGGg",
            "..ggggggggggg",
        ], palette: ["H": 0xC8F8A0, "G": 0x6ACC50, "g": 0x3A8A30, "E": 0x1A1C2C, "M": 0x2A5A2A],
           head: (3, -3), hand: (12, 5)),

        "ghost": Template(rows: [
            "....WWWWW",
            "...WWWWWWWw",
            "..WWWWWWWWWw",
            "..WWWEEWEEWw",
            "..WWWEEWEEWw",
            "..WWWWWWWWWw",
            ".WWWWWMMWWWWw",
            "WWWWWWWWWWWWw",
            "wWWWWWWWWWWWw",
            ".wWWWWWWWWWWw",
            "..wWWWWWWWWw",
            "..wWWwWWwWWw",
            "...ww.ww.ww",
        ], palette: ["W": 0xD8F0F0, "w": 0x8AB0C0, "E": 0x1A2A3A, "M": 0x3A4A5A],
           head: (2, -2), hand: (12, 7)),

        "brute": Template(rows: [
            ".....gGGGGg",
            "....gGHHGGGg",
            "....GGGGGEGEg",
            "....GGGGGGGGGg",
            "....gGGTGGGTGg",
            ".....gGGGGGGg",
            "..gGGGGgggGGGGg",
            ".gGHHGGGGGGGGGGg",
            "gGGGGGCCCCCCGGGGg",
            "gGGg.CCCCCCCC.gGGg",
            "gMMg.CCcCCcCC.gMMg",
            "gGGg.BBBBBBBB.gGGg",
            ".GGg.CCCCCCCC.gGG",
            "..g..CCc..cCC..g",
            ".....gGG..GGg",
            ".....gGG..GGg",
            ".....gGG..GGg",
            "....ccCC..CCcc",
        ], palette: [
            "G": 0x6A9A4A, "g": 0x45683A, "H": 0x8ABA6A, "E": 0xFF5040, "T": 0xFFF4D8,
            "C": 0x6A4A36, "c": 0x45301F, "B": 0x2A1A10, "M": 0x8A8A96,
        ], head: (4, -2), hand: (16, 11)),
    ]

    // MARK: - Accesorios

    struct Accessory {
        let rows: [String]
        let palette: [Character: UInt32]
        /// Punto del accesorio que se coloca en el ancla (cabeza o mano).
        let pivot: (Int, Int)
        /// `true` = se ancla a la mano; `false` = a la cabeza.
        let inHand: Bool
    }

    static let accessories: [String: Accessory] = [
        // Cabeza
        "crown": Accessory(rows: ["Y.Y.Y.Y", "YYYRYYY", "YYYYYYY"],
                           palette: ["Y": 0xFFCD45, "R": 0xE43B44], pivot: (0, 0), inHand: false),
        "helmet": Accessory(rows: ["..SSSSS", ".SWSSSSs", "SSSSSSSSs", "dddddddd"],
                            palette: ["S": 0xA8AEB8, "s": 0x6A7080, "W": 0xFFFFFF, "d": 0x4A4E5A], pivot: (0, 0), inHand: false),
        "leatherCap": Accessory(rows: ["..LLLLL", ".LLLLLLl", "llllllll"],
                                palette: ["L": 0x9A6A3A, "l": 0x6A4422], pivot: (0, 0), inHand: false),
        "hood": Accessory(rows: ["...HHHHH", "..HHHHHHH", ".HHhHHHHHH", ".HHh.....", ".HHh.....", ".HHh....", "..Hh...."],
                          palette: ["H": 0x5A1A2A, "h": 0x3A0F1A], pivot: (0, 0), inHand: false),
        "bandana": Accessory(rows: ["..RRRRRR", ".RRWRRRRR", "R.R"],
                             palette: ["R": 0xC03030, "W": 0xFFFFFF], pivot: (0, 2), inHand: false),
        "witchHat": Accessory(rows: ["......PP", ".....PPp", "....PPPp", "...PPPPp", "...PPPPPp", "..YYYYYYY", "PPPPPPPPPPP"],
                              palette: ["P": 0x4A2A6A, "p": 0x2A1A40, "Y": 0xFFCD45], pivot: (1, 5), inHand: false),
        "mageHat": Accessory(rows: ["....B", "...BBb", "..BYBb", "..BBBBb", ".BBBBBBb", "BBBBBBBBB"],
                             palette: ["B": 0x3B5DC9, "b": 0x29366F, "Y": 0xFFCD45], pivot: (0, 4), inHand: false),
        "strawHat": Accessory(rows: ["...YYYY", "..YYYYYy", "YYYYYYYYYYy"],
                              palette: ["Y": 0xE8C060, "y": 0xB08A30], pivot: (1, 2), inHand: false),
        "hornedHelmet": Accessory(rows: ["W.........W", "WW.SSSSS.WW", ".WSSWSSSSW", "..SSSSSSSs", "..dddddddd"],
                                  palette: ["W": 0xFFF4D8, "S": 0x8A8A96, "s": 0x5A5A66, "d": 0x3A3A46], pivot: (2, 2), inHand: false),
        "visor": Accessory(rows: ["..SSSSSS", ".SSSSSSSs", ".SSSKKKKK", ".SSSSSSSs", "..sssssss"],
                           palette: ["S": 0x3A3A46, "s": 0x22222C, "K": 0xE03030], pivot: (0, 0), inHand: false),
        "rider": Accessory(rows: ["..gg..gg", "..gGGGGg", "...GEGE", "...GGGG", "..CCCCC", ".GCCCCCG"],
                           palette: ["G": 0x5DAA48, "g": 0x3A7A3A, "E": 0xFFE070, "C": 0x8F5A32], pivot: (7, -3), inHand: false),
        // Mano
        "club": Accessory(rows: [".WW", "WWWw", "WWWw", "WWw", ".Ww", ".Ww", ".Ww", ".ww"],
                          palette: ["W": 0x9A6A3A, "w": 0x6A4422], pivot: (1, 6), inHand: true),
        "dagger": Accessory(rows: [".W", "WWs", "WWs", "WWs", "YYY", ".H", ".H"],
                            palette: ["W": 0xE0E4EC, "s": 0x8A8A96, "Y": 0xB08A30, "H": 0x5A3A22], pivot: (1, 5), inHand: true),
        "sword": Accessory(rows: [".W", "WWs", "WWs", "WWs", "WWs", "WWs", "WWs", "YYYY", ".H", ".H"],
                           palette: ["W": 0xE0E4EC, "s": 0x8A8A96, "Y": 0xB08A30, "H": 0x5A3A22], pivot: (1, 8), inHand: true),
        "bigSword": Accessory(rows: [".WW", "WWWs", "WWWs", "WWWs", "WWWs", "WWWs", "WWWs", "WWWs", "WWWs", "YYYYYY", "..HH", "..HH", "..HH"],
                              palette: ["W": 0xE0E4EC, "s": 0x8A8A96, "Y": 0xFFCD45, "H": 0x5A1A1A], pivot: (2, 10), inHand: true),
        "spear": Accessory(rows: [".W", "WWs", "WWs", ".s", ".H", ".H", ".H", ".H", ".H", ".H", ".H", ".H", ".H", ".H"],
                           palette: ["W": 0xE0E4EC, "s": 0x8A8A96, "H": 0x8F5A32], pivot: (1, 8), inHand: true),
        "pitchfork": Accessory(rows: ["S.S.S", "S.S.S", "SSSSS", "..H", "..H", "..H", "..H", "..H", "..H", "..H", "..H"],
                               palette: ["S": 0x8A8A96, "H": 0x8F5A32], pivot: (2, 6), inHand: true),
        "staff": Accessory(rows: [".O.", "OOO", ".O.", ".H", ".H", ".H", ".H", ".H", ".H", ".H", ".H", ".H"],
                           palette: ["O": 0x9BE0FF, "H": 0x6A4422], pivot: (1, 7), inHand: true),
        "skullStaff": Accessory(rows: ["WWW", "WKW", "WWW", ".H", ".H", ".H", ".H", ".H", ".H", ".H", ".H"],
                                palette: ["W": 0xEDE6D0, "K": 0xA040FF, "H": 0x3A2A3A], pivot: (1, 7), inHand: true),
        "bow": Accessory(rows: [".HH", "H..s", "H...s", "H...s", "H...s", "H...s", "H..s", ".HH"],
                         palette: ["H": 0x8F5A32, "s": 0xE0E0E0], pivot: (0, 4), inHand: true),
        "sling": Accessory(rows: ["H...H", ".H.H", "..H", "..H", "..H"],
                           palette: ["H": 0x8F5A32], pivot: (2, 3), inHand: true),
        "axe": Accessory(rows: ["SS.H", "SSSH", "SSSH", "SS.H", "...H", "...H", "...H", "...H"],
                         palette: ["S": 0xC0C4CC, "H": 0x6A4422], pivot: (3, 5), inHand: true),
        "bomb": Accessory(rows: ["..Y", ".Y", "BBB", "BBBB", "BBB"],
                          palette: ["B": 0x2A2A3A, "Y": 0xFFB030], pivot: (1, 3), inHand: true),
        "flag": Accessory(rows: ["HRRRRRR", "HRRYYRR", "HRYYYYR", "HRRYYRR", "HRRRRRR", "H", "H", "H", "H", "H", "H", "H"],
                          palette: ["H": 0x6A4422, "R": 0xB01A1A, "Y": 0xFFCD45], pivot: (0, 8), inHand: true),
        "scythe": Accessory(rows: ["SSSSH", "S...H", "S...H", "....H", "....H", "....H", "....H", "....H", "....H"],
                            palette: ["S": 0xC0C4CC, "H": 0x6A4422], pivot: (4, 6), inHand: true),
        "hammer": Accessory(rows: ["SSSSS", "SSSSS", "..H", "..H", "..H", "..H", "..H"],
                            palette: ["S": 0x4A4A56, "H": 0x6A4422], pivot: (2, 5), inHand: true),
        "claws": Accessory(rows: ["W.W.W", ".W.W"], palette: ["W": 0xFFF4D8], pivot: (1, 1), inHand: true),
    ]

    // MARK: - Los 50 enemigos

    struct Spec {
        var template: String
        var colors: [Character: UInt32] = [:]
        var accessories: [String] = []
    }

    static func spec(_ id: String) -> Spec {
        switch id {
        // Goblins
        case "goblin": Spec(template: "goblin", accessories: ["club"])
        case "goblinSlinger": Spec(template: "goblin", colors: ["C": 0x6A7A3A, "c": 0x4A5428], accessories: ["leatherCap", "sling"])
        case "goblinThief": Spec(template: "goblin", colors: ["C": 0x3A3A4E, "c": 0x22222E], accessories: ["bandana", "dagger"])
        case "goblinSpearman": Spec(template: "goblin", colors: ["C": 0x7A5A3A], accessories: ["leatherCap", "spear"])
        case "goblinShaman": Spec(template: "goblin", colors: ["C": 0xA03A2A, "c": 0x6A2418], accessories: ["staff"])
        case "goblinBrute": Spec(template: "goblin", colors: ["G": 0x4A8A3A, "g": 0x2A5A28, "C": 0x6A6A78, "c": 0x4A4A56], accessories: ["helmet", "club"])
        case "hobgoblin": Spec(template: "goblin", colors: ["G": 0xD08A4A, "g": 0x9A5A2A, "H": 0xF0B070, "A": 0x7A3A1A, "N": 0xB07030, "C": 0x5A3A6A, "c": 0x3A2440], accessories: ["helmet", "sword"])
        case "goblinBomber": Spec(template: "goblin", colors: ["C": 0xD07A30, "c": 0x8A4A18], accessories: ["leatherCap", "bomb"])
        case "goblinElite": Spec(template: "goblin", colors: ["G": 0x3A7A4A, "g": 0x24502E, "C": 0xA02A2A, "c": 0x6A1A1A], accessories: ["helmet", "axe"])
        case "goblinGuard": Spec(template: "goblin", colors: ["C": 0x2A4AA0, "c": 0x1A2A6A, "b": 0xFFCD45], accessories: ["helmet", "spear"])
        case "goblinMage": Spec(template: "goblin", colors: ["C": 0x4A2A8A, "c": 0x2A1A5A], accessories: ["mageHat", "staff"])
        case "goblinStandard": Spec(template: "goblin", colors: ["C": 0xC8A030, "c": 0x8A6A18], accessories: ["helmet", "flag"])
        case "goblinKing": Spec(template: "goblin", colors: ["G": 0x6AB050, "C": 0xB01A2A, "c": 0x6A0A18, "b": 0xFFCD45], accessories: ["crown", "bigSword"])
        // Humanos
        case "bandit": Spec(template: "human", accessories: ["bandana", "dagger"])
        case "banditChief": Spec(template: "human", colors: ["C": 0x8A1A2A, "c": 0x5A0A18, "H": 0x2A2A2A, "h": 0x1A1A1A], accessories: ["bandana", "bigSword"])
        case "zombieFarmer": Spec(template: "human", colors: ["F": 0x8AB07A, "f": 0x5A8050, "E": 0xFF4040, "C": 0x6A7A9A, "c": 0x4A5470], accessories: ["strawHat", "pitchfork"])
        case "scarecrow": Spec(template: "human", colors: ["F": 0xE8C060, "f": 0xB08A30, "E": 0xFF7A20, "C": 0x5A7A3A, "c": 0x3A5428, "P": 0x6A5A8A, "p": 0x4A3A6A], accessories: ["strawHat", "scythe"])
        case "cultist": Spec(template: "human", colors: ["C": 0x5A1A2A, "c": 0x3A0F1A], accessories: ["hood", "staff"])
        case "mercenary": Spec(template: "human", colors: ["C": 0x6A6A78, "c": 0x4A4A56], accessories: ["helmet", "sword"])
        case "blackKnight": Spec(template: "human", colors: ["F": 0x3A3A46, "f": 0x22222C, "C": 0x2A2A36, "c": 0x15151C, "P": 0x2A2A36, "p": 0x15151C, "B": 0xB01A1A], accessories: ["visor", "bigSword"])
        case "necromancer": Spec(template: "human", colors: ["F": 0xD8D0E0, "C": 0x2A1A3A, "c": 0x15101E], accessories: ["hood", "skullStaff"])
        case "assassin": Spec(template: "human", colors: ["C": 0x22222C, "c": 0x15151C, "P": 0x22222C], accessories: ["hood", "dagger"])
        case "witch": Spec(template: "human", colors: ["F": 0xA8D090, "f": 0x7AA060, "C": 0x4A2A6A, "c": 0x2A1A40, "P": 0x4A2A6A, "p": 0x2A1A40], accessories: ["witchHat", "skullStaff"])
        // Esqueletos
        case "skeleton": Spec(template: "skeleton", accessories: ["sword"])
        case "skeletonArcher": Spec(template: "skeleton", accessories: ["bow"])
        case "ghoul": Spec(template: "skeleton", colors: ["W": 0xA0B890, "w": 0x6A8060, "E": 0xFF4040], accessories: ["claws"])
        case "abbot": Spec(template: "skeleton", colors: ["E": 0x40E0FF], accessories: ["hood", "skullStaff"])
        // Bestias
        case "rat": Spec(template: "rat")
        case "plagueRat": Spec(template: "rat", colors: ["F": 0x7A8A5A, "f": 0x4E5A36, "H": 0xA0B07A, "E": 0xC0FF40])
        case "ratKing": Spec(template: "rat", colors: ["F": 0x5A4E5A, "f": 0x3A303A, "H": 0x8A7A8A], accessories: ["crown"])
        case "mangyDog": Spec(template: "dog")
        case "wolf": Spec(template: "dog", colors: ["F": 0x8A8A96, "f": 0x5A5A66, "H": 0xC0C4CC, "E": 0xFFE070])
        case "alphaWolf": Spec(template: "dog", colors: ["F": 0xD8D8E0, "f": 0x9A9AA6, "H": 0xFFFFFF, "E": 0xFF3030])
        case "wolfRider": Spec(template: "dog", colors: ["F": 0x6A6A78, "f": 0x45454F, "H": 0x9A9AA6, "E": 0xFFE070], accessories: ["rider"])
        case "boar": Spec(template: "boar")
        case "armoredBoar": Spec(template: "boar", colors: ["H": 0xC0C4CC, "F": 0x5A4030], accessories: ["helmet"])
        case "crow": Spec(template: "bird")
        case "bat": Spec(template: "bat")
        case "gargoyle": Spec(template: "bat", colors: ["F": 0x7A7A86, "f": 0x4A4A56, "E": 0xFFB030])
        // Limos y espectros
        case "slime": Spec(template: "slime")
        case "fireSlime": Spec(template: "slime", colors: ["H": 0xFFE0A0, "G": 0xF07A30, "g": 0xB03A18, "M": 0x6A1A0A])
        case "iceSlime": Spec(template: "slime", colors: ["H": 0xFFFFFF, "G": 0x8FD8F0, "g": 0x3C8CB0, "M": 0x1A4A6A])
        case "wraith": Spec(template: "ghost")
        // Brutos
        case "possessedSmith": Spec(template: "brute", colors: ["G": 0xB07A6A, "g": 0x7A4A3A, "H": 0xD8A090, "E": 0xFF7A20, "C": 0x5E3A24, "c": 0x3A2414], accessories: ["hammer"])
        case "mudGolem": Spec(template: "brute", colors: ["G": 0x8A6A44, "g": 0x5A4428, "H": 0xB08A5A, "E": 0x40E0FF, "C": 0x6A5034, "c": 0x45301F, "T": 0x8A6A44, "M": 0x5A4428])
        case "orc": Spec(template: "brute", accessories: ["axe"])
        case "troll": Spec(template: "brute", colors: ["G": 0x6A8AA0, "g": 0x456070, "H": 0x9AB8C8, "C": 0x5A4A3A], accessories: ["club"])
        case "ogre": Spec(template: "brute", colors: ["G": 0xC8A070, "g": 0x8A6A44, "H": 0xE8C898, "C": 0x6A7A3A, "c": 0x45501F], accessories: ["club"])
        case "berserker": Spec(template: "brute", colors: ["G": 0x7A8A3A, "C": 0xA02A2A, "c": 0x6A1A1A], accessories: ["hornedHelmet", "axe"])
        case "warlord": Spec(template: "brute", colors: ["G": 0x4A7A3A, "g": 0x2A5028, "C": 0x2A2A36, "c": 0x15151C, "M": 0xFFCD45], accessories: ["hornedHelmet", "bigSword"])
        default: Spec(template: "goblin")
        }
    }

    /// Frames: 0 = normal, 1 = paso (el cuerpo baja 1 px), 2 = preparación del ataque (arma arriba),
    /// 3 = golpe (cuerpo y arma hacia delante).
    static let frameCount = 4

    static func grid(for id: String, frame: Int) -> PixelGrid {
        let frames = [
            canvas(for: id, bob: 0, shift: 0, hand: (0, 0)),
            canvas(for: id, bob: 1, shift: 0, hand: (0, 0)),
            canvas(for: id, bob: 1, shift: -1, hand: (-1, -4)),
            canvas(for: id, bob: 0, shift: 1, hand: (3, 1)),
        ]
        // Mismos límites para todos los frames, para que el movimiento se note.
        let bounds = frames.map(\.opaqueBounds).reduce(frames[0].opaqueBounds) { $0.union($1) }
        return frames[frame].cropped(to: bounds).outlined()
    }

    private static func canvas(for id: String, bob: Int, shift: Int, hand: (Int, Int)) -> PixelGrid {
        let spec = spec(id)
        let template = templates[spec.template] ?? templates["goblin"]!
        let body = PixelSprite(rows: template.rows, palette: template.palette.merging(spec.colors) { _, new in new })

        // Lienzo con margen para gorros y armas que sobresalen.
        let pad = 12
        var canvas = PixelGrid(width: body.width + pad * 2, height: body.height + pad * 2)
        canvas.draw(body, x: pad + shift, y: pad + bob)
        for name in spec.accessories {
            guard let acc = accessories[name] else { continue }
            let anchor = acc.inHand ? template.hand : template.head
            let extra = acc.inHand ? hand : (0, 0)
            let sprite = PixelSprite(rows: acc.rows, palette: acc.palette)
            canvas.draw(sprite, x: pad + shift + anchor.0 - acc.pivot.0 + extra.0,
                        y: pad + anchor.1 - acc.pivot.1 + bob + extra.1)
        }
        return canvas
    }
}

extension PixelGrid {
    /// Rectángulo que contiene todos los pixeles opacos.
    var opaqueBounds: CGRect {
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where self[x, y] != nil {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX else { return CGRect(x: 0, y: 0, width: width, height: height) }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    func cropped(to rect: CGRect) -> PixelGrid {
        let ox = Int(rect.minX), oy = Int(rect.minY)
        var out = PixelGrid(width: Int(rect.width), height: Int(rect.height))
        for y in 0..<out.height {
            for x in 0..<out.width { out[x, y] = self[ox + x, oy + y] }
        }
        return out
    }

    /// Recorta los bordes transparentes.
    func trimmed() -> PixelGrid { cropped(to: opaqueBounds) }
}

extension Art {
    static func enemyTextures(_ id: String) -> [SKTexture] {
        (0..<EnemyArt.frameCount).map { frame in ArtCache.texture("enemy.\(id).\(frame)", grid: { EnemyArt.grid(for: id, frame: frame) }) }
    }

    static func enemyImage(_ id: String) -> CGImage {
        ArtCache.image("enemy.\(id).0", grid: { EnemyArt.grid(for: id, frame: 0) })
    }
}
