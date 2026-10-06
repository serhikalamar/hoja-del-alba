import CoreGraphics
import GameCore

/// Héroe chibi por capas (cabeza, torso, brazo delantero, piernas) para generar
/// todos los frames de animación de cada raza. Sin contorno exterior: se añade al final.
enum HeroArt {
    enum Pose: String, CaseIterable {
        case idle0, idle1, idle2
        case walk0, walk1, walk2, walk3
        case windup, strike, recover
        case hurt
    }

    enum ArmPose { case down, raised, forward }
    enum LegPose: Int { case stand = 0, stepA, pass, stepB }

    static let canvasWidth = 34
    static let canvasHeight = 40

    struct Arm {
        let rows: [String]
        let origin: (Int, Int)
        /// Mano, relativa al sprite del brazo.
        let hand: (Int, Int)
    }

    struct Design {
        let palette: [Character: UInt32]
        let head: [String]
        let headOrigin: (Int, Int)
        let torso: [String]
        let torsoOrigin: (Int, Int)
        let arms: [ArmPose: Arm]
        let legs: [[String]]
        let legsOrigin: (Int, Int)
    }

    // MARK: - Composición

    private static func layout(_ pose: Pose) -> (arm: ArmPose, legs: LegPose, bob: Int, lean: Int) {
        switch pose {
        case .idle0: (.down, .stand, 0, 0)
        case .idle1: (.down, .stand, 1, 0)
        case .idle2: (.down, .stand, 1, 0)
        case .walk0: (.down, .stepA, 0, 0)
        case .walk1: (.down, .pass, -1, 0)
        case .walk2: (.down, .stepB, 0, 0)
        case .walk3: (.down, .pass, -1, 0)
        case .windup: (.raised, .stand, 0, -1)
        case .strike: (.forward, .stepA, 1, 2)
        case .recover: (.down, .stand, 0, 1)
        case .hurt: (.down, .stand, 0, -2)
        }
    }

    static func grid(race: Race, armorIcon: String, pose: Pose) -> PixelGrid {
        let d = design(race, armorIcon: armorIcon)
        let l = layout(pose)
        var g = PixelGrid(width: canvasWidth, height: canvasHeight)
        let top = 2
        let legs = d.legs[min(l.legs.rawValue, d.legs.count - 1)]
        g.draw(PixelSprite(rows: legs, palette: d.palette), x: d.legsOrigin.0, y: top + d.legsOrigin.1)
        let bx = l.lean, by = top + l.bob
        g.draw(PixelSprite(rows: d.torso, palette: d.palette), x: d.torsoOrigin.0 + bx, y: d.torsoOrigin.1 + by)
        // En la preparación del golpe el brazo va detrás de la cabeza; si no, delante.
        let arm = d.arms[l.arm]!
        if l.arm == .raised {
            g.draw(PixelSprite(rows: arm.rows, palette: d.palette), x: arm.origin.0 + bx, y: arm.origin.1 + by)
        }
        var headRows = d.head
        if pose == .hurt || pose == .idle2 { headRows = closeEyes(headRows) }
        g.draw(PixelSprite(rows: headRows, palette: d.palette), x: d.headOrigin.0 + bx, y: d.headOrigin.1 + by)
        if l.arm != .raised {
            g.draw(PixelSprite(rows: arm.rows, palette: d.palette), x: arm.origin.0 + bx, y: arm.origin.1 + by)
        }
        return g.outlined()
    }

    /// Mano delantera (en pixeles del sprite ya contorneado).
    static func hand(race: Race, pose: Pose) -> CGPoint {
        let d = design(race, armorIcon: "armor_chain")
        let l = layout(pose)
        let arm = d.arms[l.arm]!
        return CGPoint(x: arm.origin.0 + l.lean + arm.hand.0 + 1, y: arm.origin.1 + 2 + l.bob + arm.hand.1 + 1)
    }

    /// Parpadeo: sustituye el iris por la línea de las pestañas.
    private static func closeEyes(_ rows: [String]) -> [String] {
        rows.map { row in
            String(row.map { c in "ePE".contains(c) ? "F" : c })
        }
    }

    // MARK: - Diseños

    static func design(_ race: Race, armorIcon: String) -> Design {
        let base = tabard(armorIcon)
        let clothColors: [Character: UInt32] = [
            "B": base, "b": VillageArt.darken(base, 0.68), "N": VillageArt.lighten(base, 1.3),
        ]
        switch race {
        case .human: return human(clothColors)
        case .dwarf: return dwarf(clothColors)
        case .elf: return elf(clothColors)
        case .werewolf: return werewolf(clothColors)
        }
    }

    /// Color de la tela (tabardo, túnica, faldón) según la armadura equipada.
    static func tabard(_ armorIcon: String) -> UInt32 {
        switch armorIcon {
        case "armor_tunic": 0x9A6A44
        case "armor_leather": 0x7A4A2A
        case "armor_chain": 0x3B5DC9
        case "armor_scale": 0x2E8A44
        case "armor_plate": 0xB13E53
        case "armor_elven": 0x2A9AA0
        default: 0x3B5DC9
        }
    }

    private static let skin: [Character: UInt32] = [
        "F": 0xFAD4B4, "f": 0xDDA486, "k": 0x1A1C2C, "e": 0xFFFFFF, "m": 0xC0605A,
    ]

    private static let steel: [Character: UInt32] = [
        "S": 0xC8CEDC, "W": 0xFFFFFF, "s": 0x8890A6, "d": 0x515872,
    ]

    // Humano: caballero de pelo negro, ojos turquesa, armadura de placas y tabardo.
    private static func human(_ cloth: [Character: UInt32]) -> Design {
        var palette = skin.merging(steel) { a, _ in a }.merging(cloth) { _, b in b }
        palette.merge(["H": 0x2A2C3E, "h": 0x16182A, "J": 0x5A6488, "E": 0x2FB6B8, "P": 0x14424A,
                       "Y": 0xF4F4F4, "L": 0x5A3A22, "G": 0xFFCD45]) { _, b in b }
        return Design(
            palette: palette,
            head: [
                ".......hHHHHh",
                ".....hHHJJHHHHh",
                "....hHHJJHHHHHHHh",
                "...hHHJHHHHHHhHHHh",
                "..hHHHHHHHHHhHHHHHh",
                "..HHHHhHHHHHHhHHhHHh",
                ".hHHHhHHHHhHHHHhHHHH",
                ".HHHhHHHhHHHHhHHHhHHh",
                ".HHHHHhFFhHHhFFFhHHHH",
                "hHHHHhFFFFhhFFFFFFhHH",
                "hHHHhFFFFFFFFFFFFFFhH",
                ".HHHFFFkkkFFFFkkkFFFH",
                ".HHhFFFeEEFFFFeEEFFFh",
                ".HhFFFFePEFFFFePEFFFh",
                "..hFFFFEEEFFFFEEEFFf",
                "..hfFFFFFFFFFFFFFFFf",
                "...fFFFFFFFmmFFFFFf",
                "....ffFFFFFFFFFFff",
                ".......ffffffff",
            ],
            headOrigin: (6, 0),
            torso: [
                "..sSWWSs..fFFf..sSWWSs",
                ".sSWWSSSs.BNBb.sSSWWSSs",
                ".sSSSSSSdBNNYBbdSSSSSSs",
                ".dsSSSSsdBNYYYBbdsSSSSd",
                "..ddsssdBBNYBBbb.dsssd",
                "...sSs..BBBBBBBb",
                "...sSs.LLLLGLLLL",
                "...SWs..bBBNBBb",
                "...sSd..bBBNBBb",
                "..sSSd..bBBNBBb",
                "..dddd..bBBNBBb",
                "..........bNb",
            ],
            torsoOrigin: (5, 18),
            arms: [
                .down: Arm(rows: ["sSs", "sSs", "SWs", "sSd", "sSSd", "dddd"], origin: (21, 23), hand: (1, 4)),
                .raised: Arm(rows: ["sSSd", "sWSd", ".sSd", ".sSd", ".sSd"], origin: (22, 13), hand: (1, 0)),
                .forward: Arm(rows: ["ssSSSWSSs", "ddsssssdd"], origin: (21, 23), hand: (8, 0)),
            ],
            legs: [
                ["..sSSbBbSSs", "..sSSd.dSSs", "..sSSd.dSSs", "..sWSd.dWSs", "..sSSd.dSSs", ".sSSSd.dSSSs", ".dddd...dddd"],
                ["..sSSbBbSSs", ".sSSd...dSSs", "sSSd.....dSSs", "sWSd.....dWSs", "sSd.......dSs", "SSSd......dSSSs", "ddd........dddd"],
                ["..sSSbBbSSs", "...sSSdSSs", "...sSSdSSs", "...sWSdWSs", "...sSSdSSs", "..sSSSdSSSs", "..ddddddddd"],
                ["..sSSbBbSSs", "..sSSd.dSSs", "..sSSd.dSSs", "..sWSd.dWSs", "..sSSd.dSSSs", ".sSSSd..dddd", ".dddd"],
            ],
            legsOrigin: (10, 30)
        )
    }

    // Enano: casco con cuernos, barba trenzada enorme, armadura de bronce, bajo y ancho.
    private static func dwarf(_ cloth: [Character: UInt32]) -> Design {
        var palette = skin.merging(cloth) { _, b in b }
        palette.merge([
            "S": 0xD8A050, "W": 0xFFE6A8, "s": 0xA87030, "d": 0x6A4418,
            "T": 0xF4ECD8, "t": 0xC8B898,
            "R": 0xE07A30, "r": 0xA04E1E, "O": 0xFFA860, "N": 0xE89A7A, "P": 0x2A2A3A,
            "L": 0x6A4A2A, "l": 0x4A3018, "E": 0x4A3020, "G": 0xFFCD45,
        ]) { _, b in b }
        return Design(
            palette: palette,
            head: [
                "T...................T",
                "Tt.......SSSS......tT",
                ".Tt....SSWWSSSs...tT",
                "..TtSSSWSSSSSSSSsTt",
                "...SSSSSSSSSSSSSSSs",
                "..sSSSSSSSSSSSSSSSs",
                "..dGddGddGddGddGddd",
                "..FFFFFFFFFFFFFFFFf",
                "..FFFkkFFFFFFkkFFFf",
                "..FFFePFFNNFFePFFFf",
                "..OFFFFFFNNNFFFFFOf",
                ".ORRRRRRFNNNFRRRRRO",
                "ORRRRRRRRRRRRRRRRRRO",
                "ORRrRRRRRRRRRRRrRRRO",
                ".RRRRRrRRRRRRrRRRRR",
            ],
            headOrigin: (6, 6),
            torso: [
                "sSSSs.RRRRRRRRRR.sSSSs",
                "SWSSSdRRrRRRRrRRdSSWSSs",
                "SSSSSdRRRRRRRRRRdSSSSSs",
                "dSSSSdBRRRGRRRRBdsSSSSd",
                ".ddd.BBRRROGRRRBB.ddd",
                "..sSs.BBRRrRRRBB",
                ".sSSs.LLLGGLLLLL",
                ".dddd.BBBBBBBBBB",
                "......bBBBbBBBBb",
            ],
            torsoOrigin: (5, 21),
            arms: [
                .down: Arm(rows: ["sSSs", "sSSs", "FFFf", "FFFf", "fFFf"], origin: (22, 25), hand: (1, 4)),
                .raised: Arm(rows: ["fFFf", "FFFf", "sSSs", "sSSs"], origin: (23, 18), hand: (1, 0)),
                .forward: Arm(rows: ["sSSsFFFFf", "sSSsfFFFf"], origin: (22, 25), hand: (8, 0)),
            ],
            legs: [
                ["..bBBb.bBBb", "..LLLl.LLLl", "..LLLl.LLLl", ".EEEEl.EEEEl", ".EEEEE.EEEEE"],
                ["..bBBb.bBBb", ".LLLl...LLLl", "LLLl.....LLLl", "EEEEl....EEEEl", "EEEEE.....EEEEE"],
                ["..bBBb.bBBb", "...LLLlLLLl", "...LLLlLLLl", "..EEEElEEEEl", "..EEEEEEEEEE"],
                ["..bBBb.bBBb", "..LLLl.LLLl", "..LLLl.EEEEl", ".EEEEl.EEEEE", ".EEEEE"],
            ],
            legsOrigin: (10, 30)
        )
    }

    // Elfo: melena rubia larga, orejas puntiagudas, ojos verdes, túnica ligera con oro.
    private static func elf(_ cloth: [Character: UInt32]) -> Design {
        var palette = skin.merging(cloth) { _, b in b }
        palette.merge([
            "H": 0xF0D070, "h": 0xC09A40, "J": 0xFFF4C0, "E": 0x38B764, "P": 0x1A4A2A,
            "L": 0xA07A4A, "l": 0x6A4A2A, "G": 0xFFCD45, "Y": 0x73EFF7,
            "T": 0xE8DCB8, "t": 0xB0A078,
        ]) { _, b in b }
        return Design(
            palette: palette,
            head: [
                "......HHHHHH",
                "....HHJJHHHHHH",
                "...HHJJHHHHHHHHh",
                "..HHJHHHHHHHHhHHh",
                "..HHHHHHHHHHHHhHHh",
                ".HHHHhHHHHHHHHHhHHh",
                ".HHHhFFhHHHHhFFFhHH",
                ".HHhFFFFhHHhFFFFFhH",
                "fHHFFFFFFFFFFFFFFFHf",
                "FfHFFkkkFFFFkkkFFFHfF",
                ".FHFFeEEFFFFeEEFFFHF",
                "..HFFePEFFFFePEFFFH",
                "..HFFEEEFFFFEEEFFFH",
                "..HhFFFFFFFFFFFFFhH",
                "..HHfFFFFFmFFFFFfHH",
                "..HHHfFFFFFFFFFfHHH",
                "..HHH.ffffffff.HHH",
                "..HHh..........hHH",
                "..Hhh..........hhH",
                "...h............h",
            ],
            headOrigin: (6, 0),
            torso: [
                "..lLLl.fFFf.lLLl",
                ".lLLLLGNNNNGLLLLl",
                ".LLLLGBNNBBBGLLLL",
                ".lLLlGBBYBBBGlLLl",
                "..ll.GBBBBBBG.ll",
                "...Ff.BBBBBBb",
                "...Ff.GGGYGGG",
                "...Ff.BBBNBBb",
                "..fFf.bBBNBBb",
                "......bB.N.Bb",
                "......b..N..b",
            ],
            torsoOrigin: (7, 19),
            arms: [
                .down: Arm(rows: ["lL", "Ff", "Ff", "Ff", "fF"], origin: (21, 24), hand: (1, 4)),
                .raised: Arm(rows: ["fF", "Ff", "Ff", "lL"], origin: (22, 15), hand: (0, 0)),
                .forward: Arm(rows: ["lLFFFFf", "lLffFFf"], origin: (21, 24), hand: (6, 0)),
            ],
            legs: [
                [".TTt.TTt", ".TTt.TTt", ".TTt.TTt", ".LLl.LLl", ".LLl.LLl", "LLLl.LLLl"],
                [".TTt..TTt", "TTt....TTt", "TTt....TTt", "LLl.....LLl", "LLl.....LLl", "LLLl....LLLl"],
                ["..TTtTTt", "..TTtTTt", "..TTtTTt", "..LLlLLl", "..LLlLLl", ".LLLLLLLl"],
                [".TTt.TTt", ".TTt.TTt", ".TTt.LLl", ".LLl.LLLl", ".LLl", "LLLl"],
            ],
            legsOrigin: (12, 31)
        )
    }

    // Hombre lobo: cabeza de lobo, pelaje gris, colmillos, arnés de cuero y garras.
    private static func werewolf(_ cloth: [Character: UInt32]) -> Design {
        var palette = cloth
        palette.merge([
            "G": 0x8A8A96, "g": 0x5A5A66, "W": 0xD8D8E0, "A": 0xE0A0A0, "k": 0x1A1C2C,
            "Y": 0xFFD040, "T": 0xFFFFFF, "m": 0x7A1A2A, "L": 0x6A4422, "l": 0x4A2E16,
            "S": 0xC8CCD6, "s": 0x8A92A4, "d": 0x5A6278, "C": 0xF4ECD8,
        ]) { _, b in b }
        return Design(
            palette: palette,
            head: [
                "...gg.........gg",
                "..gGGg.......gGGg",
                "..gGAGg.....gGAGg",
                "..gGAGGgggggGGAGg",
                ".gGGGGGGGGGGGGGGGg",
                ".GGGGWGGGGGGGGWGGG",
                "gGGGkkGGGGGGGGkkGGg",
                "gGGGYkGGGGGGGGYkGGg",
                "gGGGGGGWWWWWWGGGGGg",
                ".gGGGGWWWWWWWWGGGg",
                ".gGGGWWWWkkWWWWGGg",
                "..gGGWWWWWWWWWWGg",
                "...gGWTWWWWWWTWg",
                "....gWWmmmmmmWWg",
                ".....gWWWWWWWWg",
                "......gggggggg",
            ],
            headOrigin: (8, 2),
            torso: [
                "..gGGGg..gGGGGg..sSSWs",
                ".gGGGGGggGGWWGGggSSWWSs",
                "gGGGGGGLWWWWWWWLgSSSSSs",
                "gGGgGGGGLWWWWWLGGdsssdd",
                ".gGGgGGGWLWWWLWGGgGg",
                "..GGg.gGWWLWLWWGg",
                "..GGg.gGWWWLWWWGg",
                "..GGg.LLLLLLLLLL",
                ".CgGC.bBBBBBBBb",
                ".C.C..bBBbBBBb",
            ],
            torsoOrigin: (4, 16),
            arms: [
                .down: Arm(rows: ["gGg", "gGg", "gGg", "gGg", "CGC", "C.C"], origin: (22, 20), hand: (1, 4)),
                .raised: Arm(rows: ["C.C", "gGg", "gGg", "gGg", "gGg"], origin: (23, 11), hand: (1, 0)),
                .forward: Arm(rows: ["gGGGGGC", "gGGGGg.C"], origin: (22, 20), hand: (6, 0)),
            ],
            legs: [
                ["..gGGg.gGGg", "..gGGg.gGGg", "...gGg.gGg", "...gGg.gGg", "..gGGg.gGGg", ".CgGGg.gGGgC", ".C.CC...CC.C"],
                [".gGGg...gGGg", "gGGg.....gGGg", "gGg.......gGg", "gGg.......gGg", "gGGg......gGGg", "CgGGg.....gGGgC", "C.CC.......CC.C"],
                ["..gGGgGGg", "...gGgGg", "...gGgGg", "...gGgGg", "..gGGgGGg", ".CgGGgGGgC", ".C.CCCC.C"],
                ["..gGGg.gGGg", "..gGGg.gGGg", "...gGg.gGg", "...gGg.gGGg", "..gGGg.CC.C", ".CgGGg", ".C.CC"],
            ],
            legsOrigin: (9, 27)
        )
    }
}
