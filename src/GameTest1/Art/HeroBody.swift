import CoreGraphics
import GameCore

// Cuerpo de cada raza: proporciones, cara, peinados (o barbas y melenas) y ropa base.
// Las plantillas de la cabeza usan la "caja de la cabeza" (20×20) como origen.

extension HeroArt {
    /// Capa de plantilla colocada respecto a la caja de la cabeza.
    struct Layer {
        var rows: [String]
        var x: Int
        var y: Int
    }

    /// Un peinado: delante de la cara, detrás del cuerpo y (opcional) sobre los hombros.
    struct HairStyle {
        var name: String
        var front: Layer?
        var back: Layer?
        var neck: Layer? = nil
        /// El pelo de detrás ondea al correr.
        var flows = true
    }

    /// Cráneo para colocar cascos (coordenadas de la caja de la cabeza).
    struct Skull {
        var left: Int, right: Int, top: Int
        /// Fila de la frente (borde inferior del casco, justo encima de los ojos).
        var brow: Int
        /// Fila de la mandíbula (fin de las carrilleras).
        var jaw: Int
    }

    /// Proporciones de una raza en la pose quieta (coordenadas del lienzo, suelo en y = 47).
    struct Body {
        var legLen: Double
        var thighW: Int, shinW: Int
        var hipBack: Double, hipFront: Double
        var footLen: Int
        var torsoTop: Int
        /// Tramos x0...x1 de cada fila del torso, desde `torsoTop`.
        var torso: [(Int, Int)]
        /// Fila (índice) del cinturón.
        var belt: Int
        var shoulderBack: V, shoulderFront: V
        /// Escala del brazo (1 = humano: brazo y antebrazo de 4).
        var armK: Double
        var upperW: Int, foreW: Int, fist: Int
        var head: Pt
        var skull: Skull
        var digitigrade = false

        var hipY: Double { Double(HeroArt.canvasHeight - 3) - legLen }
        var cx: Double { (hipBack + hipFront) / 2 }
    }

    static func body(_ race: Race) -> Body {
        switch race {
        case .human:
            Body(legLen: 9, thighW: 4, shinW: 4, hipBack: 17, hipFront: 22, footLen: 6, torsoTop: 27,
                 torso: [(15, 24), (14, 25), (14, 25), (14, 25), (14, 25), (15, 24), (15, 24), (15, 24),
                         (15, 24), (15, 24), (15, 24), (15, 24), (16, 23)],
                 belt: 8, shoulderBack: V(14, 29), shoulderFront: V(26, 29), armK: 1, upperW: 4, foreW: 4, fist: 4,
                 head: Pt(10, 7), skull: Skull(left: 0, right: 19, top: 0, brow: 9, jaw: 16))
        case .dwarf:
            Body(legLen: 5, thighW: 5, shinW: 5, hipBack: 16.5, hipFront: 22.5, footLen: 7, torsoTop: 32,
                 torso: [(14, 25), (13, 26), (12, 27), (12, 27), (12, 27), (12, 27), (12, 27), (13, 26),
                         (13, 26), (13, 26), (13, 26), (14, 25)],
                 belt: 7, shoulderBack: V(12.5, 34), shoulderFront: V(27, 34), armK: 0.85, upperW: 5, foreW: 4, fist: 4,
                 head: Pt(10, 14), skull: Skull(left: 0, right: 19, top: 0, brow: 9, jaw: 16))
        case .elf:
            Body(legLen: 10, thighW: 3, shinW: 3, hipBack: 17.5, hipFront: 21.5, footLen: 5, torsoTop: 26,
                 torso: [(16, 23), (15, 24), (15, 24), (15, 24), (15, 24), (16, 23), (16, 23), (16, 23),
                         (16, 23), (16, 23), (16, 23), (16, 23), (17, 22)],
                 belt: 8, shoulderBack: V(14.5, 28), shoulderFront: V(24.5, 28), armK: 1.05, upperW: 3, foreW: 3, fist: 3,
                 head: Pt(10, 6), skull: Skull(left: 0, right: 19, top: 0, brow: 9, jaw: 16))
        case .werewolf:
            Body(legLen: 9, thighW: 5, shinW: 4, hipBack: 16.5, hipFront: 22.5, footLen: 6, torsoTop: 27,
                 torso: [(15, 25), (13, 27), (12, 27), (12, 27), (13, 27), (13, 26), (14, 26), (14, 25),
                         (14, 25), (14, 25), (14, 25), (15, 24), (15, 24)],
                 belt: 8, shoulderBack: V(13.5, 29), shoulderFront: V(26.5, 29), armK: 1.1, upperW: 5, foreW: 4, fist: 4,
                 head: Pt(11, 9), skull: Skull(left: 0, right: 15, top: 1, brow: 6, jaw: 11), digitigrade: true)
        }
    }

    // MARK: - Opciones de personalización

    static func appearanceOptions(_ race: Race) -> AppearanceOptions {
        switch race {
        case .human:
            AppearanceOptions(
                skinTones: [0xFAD6B8, 0xF0BE98, 0xD9A07A, 0xB87A54, 0x8A563A, 0x5E3A28],
                hairStyles: humanHair.map(\.name),
                hairColors: [0x2A2C3E, 0x5A3A26, 0x8A5A30, 0xC0603A, 0xE8C060, 0xE8E4F0, 0x6A7AA8, 0xB13E53],
                eyeColors: [0x2FB6B8, 0x38B764, 0x3B5DC9, 0x8A5A2A, 0x6A6A7A, 0xC879F2])
        case .dwarf:
            AppearanceOptions(
                skinTones: [0xF6CCB0, 0xEAB090, 0xD08A68, 0xA8684A, 0x7A4A34, 0xE0B8A8],
                hairStyles: dwarfBeards.map(\.name),
                hairColors: [0xC0603A, 0x8A3A22, 0x5A3A26, 0x2A2C3E, 0xE8B850, 0xB8B8C0, 0xF0F0F0, 0x7A7A6A],
                eyeColors: [0x3B5DC9, 0x5A3A26, 0x38B764, 0x6A6A7A, 0x2FB6B8, 0xB13E53],
                hairStyleLabel: "Barba", hairColorLabel: "Color de barba")
        case .elf:
            AppearanceOptions(
                skinTones: [0xFCE2CC, 0xF2CCAE, 0xD8AC88, 0xA87A5A, 0xC8B8E8, 0x9AA8D8],
                hairStyles: elfHair.map(\.name),
                hairColors: [0xF4E6A0, 0xF8F8F0, 0xC8D0E0, 0x7AC870, 0xB89AE8, 0x2A2C3E, 0xD86A3A, 0x4AA8E0],
                eyeColors: [0x38B764, 0x2FB6B8, 0x73EFF7, 0xC879F2, 0xFFCD45, 0x3B5DC9],
                eyeLabel: "Ojos")
        case .werewolf:
            AppearanceOptions(
                skinTones: [0x8A8A96, 0x8A6A4A, 0x4A4A56, 0xD8D4CC, 0xA8643A, 0xC8A878],
                hairStyles: wolfManes.map(\.name),
                hairColors: [0x5A5A66, 0x3A2A22, 0x2A2A34, 0xF0ECE4, 0x8A3A22, 0xA8885A, 0x5A6A8A, 0x6A3A6A],
                eyeColors: [0xFFD040, 0xE8402A, 0x73EFF7, 0x7AE860, 0xFF9A30, 0xC879F2],
                skinLabel: "Pelaje", hairStyleLabel: "Melena", hairColorLabel: "Color de melena")
        }
    }

    static func hairStyles(_ race: Race) -> [HairStyle] {
        switch race {
        case .human: humanHair
        case .dwarf: dwarfBeards
        case .elf: elfHair
        case .werewolf: wolfManes
        }
    }

    // MARK: - Caras

    /// Cara (piel) de humano y elfo. Los ojos y la boca se estampan aparte.
    static let humanFace = [
        "......FFFFFFFF......",
        "....FFFFFFFFFFFF....",
        "...FFFFFFFFFFFFFFf..",
        "..FFFFFFFFFFFFFFFFf.",
        ".FFFFFFFFFFFFFFFFFFf",
        ".FFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFff",
        "FFFFFFFFFFFFFFFFFFff",
        "FFFFFFFFFFFFFFFFFFfs",
        "FFFFFFFFFFFFFFFFFFfs",
        "fFFFFFFFFFFFFFFFFFfs",
        "fFFFFFFFFFFFFFFFFffs",
        ".fFFbbFFFFFFFFbbFfs.",
        ".sfFFFFFFFFFFFFFffs.",
        "..sfFFFFFFFFFFFffs..",
        "...ssfFFFFFFFffss...",
        ".....sssfffssss.....",
    ]

    static let elfFace = [
        "......FFFFFFFF......",
        "....FFFFFFFFFFFF....",
        "...FFFFFFFFFFFFFFf..",
        "..FFFFFFFFFFFFFFFFf.",
        ".FFFFFFFFFFFFFFFFFFf",
        ".FFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFff",
        "FFFFFFFFFFFFFFFFFFff",
        "FFFFFFFFFFFFFFFFFFfs",
        "fFFFFFFFFFFFFFFFFFfs",
        "fFFFFFFFFFFFFFFFFffs",
        ".fFFFFFFFFFFFFFFFfs.",
        ".sfFbbFFFFFFFFbbfs..",
        "..sfFFFFFFFFFFFffs..",
        "...sfFFFFFFFFFffs...",
        "....ssfFFFFFffss....",
        "......sssffsss......",
    ]

    static let dwarfFace = [
        "......FFFFFFFF......",
        "....FFFFFFFFFFFF....",
        "...FFFFFFFFFFFFFFf..",
        "..FFFFFFFFFFFFFFFFf.",
        ".FFFFFFFFFFFFFFFFFFf",
        ".FFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFFf",
        "FFFFFFFFFFFFFFFFFFff",
        "FFFFFFFFFFFFFFFFFFff",
        "FFFFFFFFFFFFFFFFFFfs",
        "FFFFFFFFFFFFhFFFFFfs",
        "fFFFFFFFFFFhFFfFFFfs",
        "fFFbbFFFFFFFFFsbbffs",
        ".fFbbFFFFFfFFsfbbfs.",
        ".sfFFFFFFFFssfFFffs.",
        "..sfFFFFFFFFFFFffs..",
        "...ssfFFFFFFFffss...",
        ".....sssfffssss.....",
    ]

    /// Cabeza de lobo completa (pelaje F, hocico W, orejas A). Caja desplazada (-2, -6).
    static let wolfHead = Layer(rows: [
        "...DD.......DD............",
        "..DLFD.....DLFD...........",
        "..DLAFD...DLAAFD..........",
        ".DLAAFD..DLAAAFD..........",
        ".DLAAAFDDDLAAAFD..........",
        ".dLFAAFFLLFFAAFFd.........",
        "dLLFFFFLLLLLFFFFFd........",
        "dLLLFFFFLLLFFFFFFFd.......",
        "dLLFFFFFFFFFFFFFFFFd......",
        "dLFFFFFFFFFFFFFFFFFFd.....",
        "dLFFFFFFFFFFFFFFFFFFF.....",
        "dFFFFFFFFFFFFFFFFFFFw.....",
        "dFFFFFFFFFFFFFFFFFFwwW....",
        "dFFFFFFFFFFFFFFFFwwwWWW...",
        "ddFFFFFFFFFFFFFFwwWWWWWWW.",
        "dFdFFFFFFFFFFFFwwWWWWWWWnn",
        ".ddFFFFFFFFFFFwWWWWWWWWWnn",
        "dFdFFFFFFFFFFwWWWWWWWWWWW.",
        ".dFdFFFFFFFFWWmmmmmmmmmm..",
        "..dFdFFFFFFFWWTWWWWWTWW...",
        "..ddFdFFFFFFFWWWWWWWWW....",
        "...d.dFdFFFFFdWWWWWW......",
        ".....d.dFFdFFd............",
        ".......d.dd.d.............",
    ], x: -2, y: -6)

    // MARK: - Ojos y bocas

    enum Face { case open, blink, hurt, shout }

    /// Ojo abierto (3×4): pestaña, brillo, pupila, iris claro abajo.
    static let eyeOpen = ["kkk", "wpi", "ipI", "iII"]
    static let eyeBlink = ["...", "...", "kkk", "..."]
    static let eyeHurtLeft = ["k..", ".kk", "k..", "..."]
    static let eyeHurtRight = ["..k", "kk.", "..k", "..."]
    /// Ojos pequeños del enano (2×3) y del lobo (2×2).
    static let dwarfEye = ["kk", "wp", "ip"]
    static let dwarfBlink = ["..", "kk", ".."]
    static let wolfEye = ["kk", "wi", "ip"]
    static let wolfBlink = ["..", "kk", ".."]

    // MARK: - Peinados del humano

    static let humanHair: [HairStyle] = [
        HairStyle(name: "Corto", front: Layer(rows: [
            ".........HH..HH...........",
            "........HHJHHHHH.HH.......",
            "......HHJJHHHHHHDHHH......",
            ".....HHJJHHHHHHDHHHHHH....",
            "....HHJJHHHHHHDHHHHHHHH...",
            "...HHHHHHHHHDHHHHHHHHHHH..",
            "..HHHHHHHHHDHHHHHDHHHHHHH.",
            "..HHHHHHHHDHHHHHDHHHHHHHH.",
            ".HHHHDHHHDHHHHHDHHHHDHHHHH",
            ".HHHDHHHDHHHHHDHHHHDHHHHHH",
            "HHHDHHHDHHHHHDHHHHDHHHHHH.",
            "HHDHHHDHHHHHDHHHHHDHHHHHH.",
            "HHHHHHHHHHH.HHHHHHHHHHHH..",
            "HHHHHHHHH....HHHHH.HHHHH..",
            "HHHHHHHH......HHH...HHHH..",
            "HHHHHH.........H.....HHH..",
            "HHHHH.................HH..",
            "HHHH..................H...",
            ".HHH......................",
            ".HH.......................",
            "..H.......................",
        ], x: -3, y: -5), back: nil),
        HairStyle(name: "Melena", front: Layer(rows: [
            ".......HHHHHHHHH..........",
            ".....HHJJHHHHHHHHH........",
            "....HHJJHHHHHHHHHHHH......",
            "...HHJJHHHHHHHHHHHHHH.....",
            "..HHJHHHHHHHHHHHHHHHHH....",
            "..HHHHHHHHHHHHHHHHHHHHH...",
            ".HHHHHHHHHHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHDDHHHHHHHH..",
            ".HHHHHHHHHHHDDHHHHHHHHHHH.",
            "HHHHHHHHHDDDHHHHHHHHHHHHH.",
            "HHHHHHDDDHHHHHHHHHHHHHHHH.",
            "HHHHDDHHHHHHHHHHHHHHHHHHH.",
            "HHHHHHH.HHHHHHHHHHHHHHHHH.",
            "HHHHHH...HHHHHHHHH..HHHHH.",
            "HHHHH.......HHHH.....HHHH.",
            "HHHHH........HH.......HHH.",
            "HHHH...................HH.",
            "HHHH...................HH.",
            "HHHH...................HH.",
            "HHH....................H..",
            "HHH.......................",
            "HH........................",
            ".H........................",
        ], x: -3, y: -4), back: Layer(rows: [
            "..HHHHHHHHHH......",
            ".HHHHHHHHHHHH.....",
            "HHHHHHHHHHHHH.....",
            "HHHHHHHHHHHHH.....",
            "HHHHHHHHHHHHH.....",
            "HHHHDHHHHHHHH.....",
            "HHHHDHHHHHHHH.....",
            "HHHDHHHHHHHHH.....",
            "HHHDHHHDHHHH......",
            "HHDHHHHDHHHH......",
            "HHDHHHDHHHH.......",
            "HHHHHHDHHH........",
            ".HHHHHHHH.........",
            ".HH.HHH...........",
        ], x: -4, y: 8)),
        HairStyle(name: "Coleta", front: Layer(rows: [
            ".......HHHHHHHH...........",
            ".....HHJJHHHHHHHH.........",
            "....HHJJHHHHHHHHHHH.......",
            "...HHJJHHHHHHHHHHHHH......",
            "..HHJHHHHHDHHHHHHHHHH.....",
            "..HHHHHHHDHHHHHHDHHHHH....",
            ".HHHHHHHDHHHHHHDHHHHHHH...",
            ".HHHHHHDHHHHHHDHHHHHHHHH..",
            ".HHHHHDHHHHHHDHHHHHHHHHH..",
            "HHHHHDHHHHHHDHHHHHHHHHHHH.",
            "HHHHHHHHHHHHHHHHHHHHHHHHH.",
            "HHHHHHHHH.HHHHH.HHHHHHHHH.",
            "HHHHHH......H.....H.HHHHH.",
            "HHHH...............HHHHH..",
            "HHH..................HHH..",
            ".HH...................H...",
            "..H.......................",
        ], x: -3, y: -4), back: Layer(rows: [
            "...HHH.",
            "..HHHHH",
            ".HHJHHH",
            "kkkkkkk",
            ".HHHHH.",
            "HHJHHHD",
            "HHHHHDD",
            "HHHHHD.",
            "HHHHDD.",
            ".HHHD..",
            ".HHD...",
            "..HD...",
            "..D....",
        ], x: -6, y: 4)),
    ]

    // MARK: - Peinados del elfo

    static let elfHair: [HairStyle] = [
        HairStyle(name: "Melena larga", front: Layer(rows: [
            ".......HHHHHHHHH..........",
            ".....HHHHJJHHHHHHH........",
            "....HHHHJJHHHHHHHHHH......",
            "...HHHHJJHHHHHHHHHHHH.....",
            "..HHHHJJHHHHHHHHHHHHHH....",
            "..HHHHHHHHHHHHHHHHHHHHH...",
            ".HHHHDHHHHHHHHHHHDHHHHHH..",
            ".HHHDHHHHHHHHHHHHHDHHHHH..",
            ".HHDHHHHHHHHHHHHHHHDHHHHH.",
            "HHHDHHHHHHHDHHHHHHHDHHHHH.",
            "HHDHHHHHHHDHHHHHHHHHDHHHH.",
            "HHDHHHHHH..HHHHHHHHHDHHHH.",
            "HHDHHHH.......HHHHHHDHHHH.",
            "HHDHHH...........HHHHHHHH.",
            "HHHHHH............HHHHHH..",
            "HHHHH..............HHHHH..",
            "HHHH................HHHH..",
            "HHHH................HHHH..",
            "HHHH................HHHH..",
            "HHHH................HHHH..",
            "HHHH................HHHH..",
            "HHH.................HHHH..",
            "HHH.................HHH...",
            "HH..................HHH...",
            ".H...................H....",
        ], x: -3, y: -4), back: Layer(rows: [
            "..HHHHHHHHHHHH....",
            ".HHHHHHHHHHHHHH...",
            "HHHHHHHHHHHHHHH...",
            "HHHHHHHHHHHHHHH...",
            "HHHHDHHHHHHHHHH...",
            "HHHHDHHHHHHHHHH...",
            "HHHDHHHHHHHHHHH...",
            "HHHDHHHHDHHHHH....",
            "HHDHHHHHDHHHHH....",
            "HHDHHHHDHHHHH.....",
            "HDHHHHHDHHHHH.....",
            "HDHHHHDHHHHH......",
            "HHHHHHDHHHHH......",
            "HHHHHDHHHHH.......",
            "HHHHHDHHHH........",
            ".HHHDHHHH.........",
            ".HHHDHHH..........",
            "..HH.HH...........",
        ], x: -4, y: 6)),
        HairStyle(name: "Trenza", front: Layer(rows: [
            ".......HHHHHHHHH..........",
            ".....HHHHJJHHHHHHH........",
            "....HHHHJJHHHHHHHHHH......",
            "...HHHHJJHHHHHHHHHHHH.....",
            "..HHHHJJHHHHDHHHHHHHHH....",
            "..HHHHHHHHHDHHHHHHHHHHH...",
            ".HHHHHHHHHDHHHHHHHDHHHHH..",
            ".HHHHHHHHDHHHHHHHDHHHHHH..",
            ".HHHHHHHDHHHHHHHDHHHHHHHH.",
            "HHHHHHHDHHHHHHHDHHHHHHHHH.",
            "HHHHHHHHHHHHHHHHHHHHHHHHH.",
            "HHHHHHH.HHH..HHHH.HHHHHHH.",
            "HHHHH..........H....HHHH..",
            "HHHH.................HHH..",
            "HHH..................HH...",
            ".HH...................H...",
            ".H........................",
        ], x: -3, y: -4), back: Layer(rows: [
            "..HHHH..",
            ".HHHHHH.",
            "HHHHHHH.",
            ".HJHHD..",
            ".DHHJH..",
            ".HJHHD..",
            "..DHHJH.",
            "..HJHHD.",
            "..DHHJH.",
            "...HJHD.",
            "...kkk..",
            "...HHH..",
            "..HHHHH.",
            "...H.H..",
        ], x: -5, y: 9)),
        HairStyle(name: "Cola alta", front: Layer(rows: [
            ".......HHHHHHHH...........",
            ".....HHJJHHHHHHHH.........",
            "....HHJJHHHHHHHHHHH.......",
            "...HHJJHHHHHHHHHHHHH......",
            "..HHJHHHHHHHHHHHHHHHH.....",
            "..HHHHHHHHHHHHHHHHHHHH....",
            ".HHHHHHHHHHHHHHHHHHHHHH...",
            ".HHHHHHHHHHHHHDHHHHHHHHH..",
            ".HHHHHHHHHHHDDHHHHHHHHHH..",
            "HHHHHHHHHDDDHHHHHHHHHHHHH.",
            "HHHHHHDDDHHHHHHHHHHHHHHHH.",
            "HHHHDDHHHHHHHHHH.HHHHHHHH.",
            "HHHHHH.....HHHH....HHHHH..",
            "HHHH...............HHHHH..",
            "HHH..................HHH..",
            "HHH..................HH...",
            ".HH...................H...",
            ".H........................",
        ], x: -3, y: -4), back: Layer(rows: [
            ".......kkk",
            ".....HHHHH",
            "...HHHJHHH",
            "..HHJHHHHD",
            ".HHJHHHHD.",
            "HHHHHHHD..",
            "HHHHHHD...",
            "HHHHHD....",
            "HHHHD.....",
            "HHHD......",
            "HHD.......",
            ".HD.......",
            ".H........",
            ".D........",
        ], x: -7, y: -4)),
    ]

    // MARK: - Barbas del enano (el pelo de la cabeza es fijo)

    static let dwarfTopHair = Layer(rows: [
        ".......HHHHHHH..........",
        ".....HHJJHHHHHHH........",
        "...HHHJJHHHHHHDHHH......",
        "..HHHJHHHHHHHDHHHHH.....",
        ".HHHHHHHHHDHHHHHDHHHH...",
        ".HHHHHHHHDHHHHHDHHHHHH..",
        "HHHHHHHHDHHHHHDHHHHHHH..",
        "HHHHHHDHHHHHDHHHHDHHHHH.",
        "HHHHDHHHHHHHHHHHHHHHHHH.",
        "HHHHHHH.HHHHHH..HHHHHHH.",
        "HHHHH.....H.......HHHH..",
        "HHHH...............HHH..",
        "HHHH...............HH...",
        "HHH.....................",
        ".HH.....................",
        ".H......................",
    ], x: -2, y: -4)

    /// Cejas pobladas del enano (color de pelo).
    static let dwarfBrows = Layer(rows: [
        "HHHHH..HHHHH",
        ".DDD....DDD.",
    ], x: 5, y: 9)

    static let dwarfBeards: [HairStyle] = [
        HairStyle(name: "Trenzada", front: Layer(rows: [
            ".....HHHHH.HHHHHH.",
            "..HHHHHHHHHHHHHHHH",
            ".HHHJHHHHH.HHHHHHH",
            "HHJHHHHHH...HHHHHH",
            "HJHHHDHHHHHHHDHHHD",
            "HHHHDHHHHHHHDHHHDD",
            ".HHDHHHDHHHDHHHHD.",
            ".HHHHHDHHHDHHHHDD.",
            "..HHHDHHHHHHHHDD..",
            "...HHHHHHHHHHHD...",
            "....HJHD..HJHD....",
            "....kkkk..kkkk....",
            "....GGGG..GGGG....",
            "....HJHD..HJHD....",
            ".....GG....GG.....",
            ".....HD....HD.....",
        ], x: 1, y: 14), back: nil, flows: false),
        HairStyle(name: "Poblada", front: Layer(rows: [
            "......HHHHH.HHHHHH..",
            "...HHHHHHHHHHHHHHHH.",
            "..HHHJHHHHH.HHHHHHHH",
            ".HHJHHHHHH...HHHHHHH",
            "HHJHHHHHHHHHHHHHHHHH",
            "HJHHHDHHHHHHHDHHHHHD",
            "HHHHDHHHHDHHHHDHHHHD",
            "HHHDHHHHDHHHHDHHHHDD",
            ".HHHHHDHHHHDHHHHHDD.",
            ".HHHHHDHHHDHHHHHDD..",
            "..HHH.HHHHHHHH.HD...",
            "...H...HHHHH...D....",
        ], x: 0, y: 14), back: nil, flows: false),
        HairStyle(name: "Bifurcada", front: Layer(rows: [
            ".....HHHHH.HHHHHH.",
            "..HHHHHHHHHHHHHHHH",
            ".HHHJHHHHH.HHHHHHH",
            "HHJHHHHHH...HHHHHH",
            "HJHHHDHHHHHHHDHHHD",
            "HHHHDHHHHHHHDHHHDD",
            ".HHHDHHHDHHDHHHHD.",
            ".HHDHHHDHH.HDHHHD.",
            "..HHHHDHH...HDHD..",
            "..HHHDHH....HHD...",
            "...HDHH.....HHD...",
            "...HHH......HD....",
            "....HH......D.....",
            "....H.............",
        ], x: 1, y: 14), back: nil, flows: false),
    ]

    // MARK: - Melenas del hombre lobo

    static let wolfManes: [HairStyle] = [
        HairStyle(name: "Greñuda", front: Layer(rows: [
            "....HH.HH....",
            "..HHHHHHHHH..",
            ".HHJHHHDHHHH.",
            "HHJHHDHHHDHH.",
            ".HHHDHHHHH...",
        ], x: 3, y: -2), back: Layer(rows: [
            "..HH.HH.HHH.........",
            ".HHHHHHHHHHHH.......",
            "HHJHHHHHHHHHHH......",
            "HJHHHDHHHHHHHHH.....",
            "HHHHDHHHHHHHHHHH....",
            "HHHDHHHHHHHHHHHH....",
            "HHHHHHHHHHHHHHHH....",
            ".HHHHHHHHHHHHHH.....",
        ], x: -6, y: 6), neck: Layer(rows: [
            "....H..H.H..H..H....",
            "..HHHHHHHHHHHHHHHH..",
            ".HHJHHHDHHHHDHHHHHH.",
            "HHJHHHDHHHHDHHHHDHHH",
            "HHHHHDHHHHDHHHHDHHHH",
            "..HH.HHHHDHH.HHHH...",
            "...H..HH..H...H.....",
        ], x: 1, y: 14)),
        HairStyle(name: "Erizada", front: Layer(rows: [
            "...H..H..H...",
            "..HH.HH.HH...",
            ".HJHHHHHHH...",
            ".HHHDHHDHH...",
            "..HHHHHHH....",
        ], x: 3, y: -5), back: Layer(rows: [
            "H...H..H.......",
            "HH.HH.HH.......",
            "HHHHHHHH.......",
            ".HHHHHHHH......",
            "HHHHDHHHHH.....",
            ".HHHHHHHHH.....",
        ], x: -5, y: -1), neck: Layer(rows: [
            "..H.H.H.H.H.H.H.....",
            ".HHHHHHHHHHHHHHHH...",
            "HHJHHDHHHHDHHHHDHH..",
            "HHHHHHHHDHHHHHDHHHH.",
            ".HHHHHHHHHHHHHHHHH..",
            "..H.HH.HH.HH.HH.H...",
        ], x: 1, y: 15)),
        HairStyle(name: "Larga", front: Layer(rows: [
            "...HHHHHHH...",
            ".HHJHHHHHHH..",
            "HHJHHHDHHHHH.",
            "HJHHHDHHHHH..",
            ".HHHHHHHH....",
        ], x: 2, y: -2), back: Layer(rows: [
            "...HHHHHHHHHH.......",
            "..HHHHHHHHHHHHH.....",
            ".HHJHHHHHHHHHHHH....",
            "HHJHHHDHHHHHHHHH....",
            "HJHHHDHHHHHHHHHH....",
            "HHHHDHHHHHHHHHHH....",
            "HHHDHHHHDHHHHHHH....",
            "HHHDHHHDHHHHHHHH....",
            "HHDHHHDHHHHHHHH.....",
            "HHDHHDHHHHHHHH......",
            "HHHHHDHHHHHH........",
            ".HHHDHHHHH..........",
            ".HHHDHHH............",
            "..HH.HH.............",
            "..H..H..............",
        ], x: -7, y: 4), neck: Layer(rows: [
            "..HHHHHHHHHHHHHH....",
            ".HHJHHHDHHHHDHHHH...",
            "HHJHHHDHHHHDHHHHDH..",
            "HHHHHDHHHHDHHHHDHHH.",
            "..HH.HHHHDHH.HHH....",
            "...H..HH..H..H......",
        ], x: 1, y: 14)),
    ]

    /// Orejas largas del elfo: la de atrás (izquierda) grande, la de delante pequeña.
    static let elfEarBack = Layer(rows: [
        "FF.......",
        "FhF......",
        ".FhF.....",
        ".fFhF....",
        "..fFFF...",
        "..sfFFF..",
        "...sfFFF.",
        "....ssfF.",
        "......sf.",
    ], x: -7, y: 6)
    static let elfEarFront = Layer(rows: [
        "......F",
        ".....FF",
        "....FFs",
        "...FFs.",
        "..FFs..",
        ".FFs...",
        "Ffs....",
        "fs.....",
    ], x: 17, y: 6)

    /// Cola del hombre lobo (tres posiciones para el meneo).
    static let wolfTails: [Layer] = [
        Layer(rows: [
            "HHH.........",
            "HHHH........",
            "HHHHH.......",
            ".HHHHHH.....",
            "..HHHHHHH...",
            "...HHHHHHHH.",
            ".....HHHHHHH",
            ".......HHHHH",
        ], x: 0, y: 0),
        Layer(rows: [
            "............",
            "HHH.........",
            "HHHHHH......",
            "HHHHHHHHH...",
            ".HHHHHHHHHH.",
            "...HHHHHHHHH",
            "......HHHHHH",
            "........HHHH",
        ], x: 0, y: 0),
        Layer(rows: [
            "............",
            "............",
            "........HHHH",
            "....HHHHHHHH",
            ".HHHHHHHHHHH",
            "HHHHHHHHHHH.",
            "HHHHHHH.....",
            "HHHH........",
        ], x: 0, y: 0),
    ]

    // MARK: - Ropa base de cada raza (sin pieza en ese hueco)

    struct BaseClothes {
        var shirt: Ramp
        var shirtTrim: Ramp
        var sleeve: Ramp?       // nil = brazo desnudo (piel)
        var forearm: Ramp?
        var trousers: Ramp
        var shoes: Ramp?        // nil = pies desnudos (garras)
        var belt: Ramp
        var buckle: Ramp
    }

    static func baseClothes(_ race: Race) -> BaseClothes {
        let belt = Ramp(material: [0x8A5A34, 0x5E3A22, 0x3A2214])
        let gold = Ramp(material: [0xFFE08A, 0xE0A838, 0x9A6420])
        switch race {
        case .human:
            let shirt = Ramp(material: [0xF2EAD6, 0xC8BCA0, 0x8E8068])
            return BaseClothes(shirt: shirt, shirtTrim: Ramp(base: 0x6A5A4A), sleeve: shirt, forearm: shirt,
                               trousers: Ramp(material: [0x7A6A5A, 0x54483E, 0x352C28]),
                               shoes: Ramp(material: [0x8A5A34, 0x5E3A22, 0x3A2214]), belt: belt, buckle: gold)
        case .dwarf:
            let shirt = Ramp(material: [0xD06A44, 0xA0442C, 0x66261C])
            return BaseClothes(shirt: shirt, shirtTrim: Ramp(base: 0x5A3A22), sleeve: shirt, forearm: nil,
                               trousers: Ramp(material: [0x7A6050, 0x544036, 0x342420]),
                               shoes: Ramp(material: [0x6A4A36, 0x46302A, 0x2A1C18]), belt: belt, buckle: gold)
        case .elf:
            let shirt = Ramp(material: [0x7AC878, 0x3E8A4A, 0x1E5434])
            return BaseClothes(shirt: shirt, shirtTrim: gold, sleeve: shirt, forearm: shirt,
                               trousers: Ramp(material: [0xE8DDBC, 0xB8AA86, 0x7A6E54]),
                               shoes: Ramp(material: [0xA87A4A, 0x76502E, 0x4A301A]), belt: belt, buckle: gold)
        case .werewolf:
            return BaseClothes(shirt: Ramp(material: [0x6A6A88, 0x46465E, 0x2A2A3E]), shirtTrim: Ramp(base: 0x8A6A4A),
                               sleeve: nil, forearm: nil,
                               trousers: Ramp(material: [0x6A6A88, 0x46465E, 0x2A2A3E]),
                               shoes: nil, belt: Ramp(material: [0xC8A878, 0x8A7050, 0x5A4630]), buckle: gold)
        }
    }
}
