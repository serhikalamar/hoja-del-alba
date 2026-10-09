import Foundation

// MARK: - Valdemar: áreas de campo y mazmorras de historia
//
// Dueño: map-designer. Transcrito de los borradores validados del continent-lead
// (`assets/world/continentes/valdemar/mapas/*.md`, oleadas en `zonas.md` §3). Resumen y renders:
// `assets/maps/valdemar.md`. Contrato de los tipos: `assets/world/continentes/valdemar/contrato.md`.
//
// Ids estables (se guardan en partidas): áreas `valdemar.<área>`, zonas `valdemar.<área>.<zona>`,
// spawns `valdemar.<área>.<n>` (en el orden de las tablas de los borradores), salidas `<área>.<punto cardinal>`.
// Los monstruos de campo reaparecen (M2) salvo los jefes (`ogre`, `alphaWolf`, `warlord`).
//
// Ruta prevista (dos anillos desde el pueblo, sin callejones):
//   pueblo 1-5 → Huertos 5/6 (oeste) → Robleda 6/7 (sur) → casa del alcalde 7 → Abadía 7/8 + Cripta 8 (este)
//   → Pedregal 8/9 → patio 9 → trono 10 → Paso del Norte 10 (norte, tras `valdemar.paso_norte`).

public enum Valdemar {
    // Ids de área (los usan las salidas del pueblo y las misiones).
    public static let huertosID = "valdemar.huertos"
    public static let robledaID = "valdemar.robleda"
    public static let abadiaID = "valdemar.abadia"
    public static let pedregalID = "valdemar.pedregal"
    public static let pasoID = "valdemar.paso"

    /// Exteriores de campo del continente (el pueblo y sus interiores están en `Valdehierro`).
    public static let areas: [AreaMap] = [huertos, robleda, abadia, pedregal, paso]

    /// Mazmorras de historia del continente.
    public static let dungeons: [StoryDungeon] = [cripta, calabozos]

    public static func area(_ id: String) -> AreaMap? {
        areas.first { $0.id == id }
    }

    // MARK: Huertos del Molino (oeste del pueblo · 5/6)

    /// Trigales quemados, granjas arrasadas, el río Plata con dos puentes y el molino en ruinas del Ogro (NO).
    /// 56×36 · nivel de fuera de zonas 5 · borrador: `mapas/huertos.md`.
    public static let huertos = AreaMap(
        id: "valdemar.huertos",
        name: "Huertos del Molino",
        rows: [
            "TTTTTTTTTTTTTTTTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TTTTTTTTTTTTTTTTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TT......................~~~.............fffffffffff...TT",
            "TT......................~~~..T.........f%%%%%%%%%%%f..TT",
            "TT...........cc....R....~~~............f%%%%%%%%%%%f..TT",
            "TT...........c..........~~~............f%%%%%%%%%%%f..TT",
            "TT......................~~~............f%%%%%%%%%%%f..TT",
            "TT......................~~~............f%%%%%%%%%%%...TT",
            "TT......................~~~............f%%%%%%%%%%%...TT",
            "TT..........ddd%%%%%....~~~...........cf%%%%%%%%%%%...TT",
            "TT.R........ddd%%%%%....~~~............f%%%%%%%%%%%...TT",
            "TT..........ddd.....R...~~~...T........f%%%%%%%%%%%...TT",
            "TT..........ddd.........~~~.......................x...TT",
            "TT..........ddd..b......~~~...........................TT",
            "TT..........ddd.........~~~....................b......TT",
            "TT..........ddd.........~~~...........................TT",
            "TT..........ddddddddddddpppdddddddddddddddddddddddddddd>",
            "TT..........ddddddddddddpppdddddddddddddddddddddddddddd>",
            "TT..........ddddddddddddpppdddddddddddddddddddddddddddd>",
            "TT......T..dddd......,..~~~......ddd..................TT",
            "TT.........dddd.f+.+.+f.~~~ffffffddd..................TT",
            "TT.........dddd.f.....f.~~~.%%%%%ddd................T.TT",
            "TT.........dddd.f+.+.+f.~~~.%%%%%ddd..................TT",
            "TT.,.....,.dddd.........~~~.%%%%%ddd..................TT",
            "TT...~~~...dddd.........~~~.%%%%%ddd..................TT",
            "TT..~~~~~..dddd.......,.~~~.%%%%%ddd..................TT",
            "TT.~~~~~~~.dddd.........~~~.%%%%%ddd..................TT",
            "TT..~~~~~..dddddddddddddpppd%%%%%ddd..................TT",
            "TT...~~~...dddddddddddddpppd%%%%%ddd..................TT",
            "TT..,.....,dddddddddddddpppd%%%%%ddd..................TT",
            "TT.........dddd...T.....~~~.%%%%%...%%%%%%..........T.TT",
            "TT....,....dddd.....,...~~~.........%%%%%%............TT",
            "TT.........dddd.........~~~.........%%%%R%............TT",
            "TT.b.......dddd.......b.~~~...........................TT",
            "TTTTTTTTTTTddddTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TTTTTTTTTTT>>>>TTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
        ],
        buildings: [
            Building(id: "molino", name: "Molino en ruinas", style: .ruinedMill, x: 6, y: 3, width: 6, height: 6, doorX: 8, doorWidth: 1, interiorID: nil,
                     lockedMessage: "El molino está medio derruido. Dentro, harina podrida y olor a ogro."),
            Building(id: "granja1", name: "Granja quemada", style: .burnedFarm, x: 31, y: 4, width: 6, height: 5, doorX: 33, doorWidth: 1, interiorID: nil,
                     lockedMessage: "Solo quedan vigas quemadas. Aquí ya no vive nadie."),
            Building(id: "granja2", name: "Granja quemada", style: .burnedFarm, x: 43, y: 23, width: 6, height: 5, doorX: 45, doorWidth: 1, interiorID: nil,
                     lockedMessage: "Solo quedan vigas quemadas. Aquí ya no vive nadie."),
        ],
        zones: [
            Zone(id: "valdemar.huertos.molino", name: "Molino en ruinas", x: 2, y: 2, width: 22, height: 13, level: 6),
            Zone(id: "valdemar.huertos.ribera", name: "Ribera del Plata", x: 2, y: 15, width: 22, height: 19, level: 5),
            Zone(id: "valdemar.huertos.trigales", name: "Trigales quemados", x: 27, y: 2, width: 27, height: 32, level: 5),
        ],
        spawns: [
            Spawn(id: "valdemar.huertos.1", enemyID: "ogre", position: TilePoint(9, 11)), // jefe: delante de la puerta del molino
            Spawn(id: "valdemar.huertos.2", enemyID: "mudGolem", position: TilePoint(7, 13)), // escolta del Ogro
            Spawn(id: "valdemar.huertos.3", enemyID: "skeleton", position: TilePoint(19, 5)),
            Spawn(id: "valdemar.huertos.4", enemyID: "skeleton", position: TilePoint(21, 7)),
            Spawn(id: "valdemar.huertos.5", enemyID: "plagueRat", position: TilePoint(16, 9)),
            Spawn(id: "valdemar.huertos.6", enemyID: "plagueRat", position: TilePoint(18, 10)),
            Spawn(id: "valdemar.huertos.7", enemyID: "slime", position: TilePoint(9, 25)),
            Spawn(id: "valdemar.huertos.8", enemyID: "slime", position: TilePoint(4, 21)),
            Spawn(id: "valdemar.huertos.9", enemyID: "skeleton", position: TilePoint(18, 21)), // entre las tumbas
            Spawn(id: "valdemar.huertos.10", enemyID: "skeleton", position: TilePoint(20, 22)),
            Spawn(id: "valdemar.huertos.11", enemyID: "crow", position: TilePoint(19, 31)),
            Spawn(id: "valdemar.huertos.12", enemyID: "plagueRat", position: TilePoint(5, 32)),
            Spawn(id: "valdemar.huertos.13", enemyID: "zombieFarmer", position: TilePoint(34, 11)),
            Spawn(id: "valdemar.huertos.14", enemyID: "zombieFarmer", position: TilePoint(37, 12)),
            Spawn(id: "valdemar.huertos.15", enemyID: "boar", position: TilePoint(45, 6)),
            Spawn(id: "valdemar.huertos.16", enemyID: "goblinBomber", position: TilePoint(44, 12)), // quema el trigal
            Spawn(id: "valdemar.huertos.17", enemyID: "crow", position: TilePoint(29, 13)),
            Spawn(id: "valdemar.huertos.18", enemyID: "zombieFarmer", position: TilePoint(40, 26)),
            Spawn(id: "valdemar.huertos.19", enemyID: "zombieFarmer", position: TilePoint(39, 29)),
            Spawn(id: "valdemar.huertos.20", enemyID: "mudGolem", position: TilePoint(49, 31)),
            Spawn(id: "valdemar.huertos.21", enemyID: "boar", position: TilePoint(31, 24)), // en el trigal sur
        ],
        npcs: [],
        level: 5,
        entry: TilePoint(53, 17),
        kind: .field,
        exits: [
            AreaExit(id: "huertos.este", tiles: [TilePoint(55, 16), TilePoint(55, 17), TilePoint(55, 18)],
                     toArea: Valdehierro.townID, arrival: TilePoint(2, 17)),
            AreaExit(id: "huertos.sur", tiles: [TilePoint(11, 35), TilePoint(12, 35), TilePoint(13, 35), TilePoint(14, 35)],
                     toArea: robledaID, arrival: TilePoint(9, 2)),
        ],
        safePoint: TilePoint(50, 17)
    )

    // MARK: Bosque de Robleda (sur del pueblo · 6/7)

    /// Robledal con claros, campamento bandido vallado (SO), puesto del guardabosques y guarida del Lobo alfa (SE).
    /// 64×36 · nivel de fuera de zonas 6 · borrador: `mapas/robleda.md`.
    public static let robleda = AreaMap(
        id: "valdemar.robleda",
        name: "Bosque de Robleda",
        rows: [
            "TTTTTTTT>>>>TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT>>>>TTTTTTTTTTTTTTTTTT",
            "TTTTTTTTddddTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTddddTTTTTTTTTTTTTTTTTT",
            "TT.T....dddd..T..............T.....T......dddd............T...TT",
            "TT......dddd........T..T........T........Tdddd................TT",
            "TT......dddd..............................dddd...............TTT",
            "TT......dddd.T..T...,.......T.........T...dddd...........T....TT",
            "TT..T..Tdddd..............................dddd................TT",
            "TT......dddd.....................,........dddd................TT",
            "TT......dddd....T.............T......T....dddd................TT",
            "TTT.....dddd............,.................dddd..x.....c.....T.TT",
            "TT...T..dddd.......T......................dddd................TT",
            "TT......dddd..............T..T......T.....dddd................TT",
            "TT......dddddddddddddddddddddddddddddddddddddd.........T......TT",
            "TT.T..T.dddddddddddddddddddddddddddddddddddddd..T.........T...TT",
            "TT......dddddddddddddddddddddddddddddddddddddd................TT",
            "TT.......T...Tddd.....T.....T.............dddd.........,......TT",
            "TT.T..T.......ddd..............T......T...dddd...T............TT",
            "TT............ddd..T......................dddd...............TTT",
            "TT..ffffffffffdddffffffffff.T.............dddd................TT",
            "TT..f.T...................f...............dddd.....T..........TT",
            "TT..f........n............f...............dddd..T......T......TT",
            "TT..f....n..........n.....f.T............Tdddd.............T..TT",
            "TT..f.....................f.....T.........ddddddddddddddddddddd>",
            "TT..f.....................f........T......ddddddddddddddddddddd>",
            "TT..f.....................f............T..ddddddddddddddddddddd>",
            "TT..f..........x..........f....T..........ddd...............T.TT",
            "TT..f.....................ddddddddddddddddddd......T.RRRR.....TT",
            "TT..f.....................ddddddddddddddddddd..R.....R..R.....TT",
            "TT..f.....................ddddddddddddddddT...................TT",
            "TT..f...n............n....f...T..............................TTT",
            "TT..f......cc.............f................................R..TT",
            "TT..f..T..........c.....T.f......T............................TT",
            "TTT.fffffffffffffffffffffff.........T.........................TT",
            "TT..........T...............T..............T.R................TT",
            "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
        ],
        buildings: [
            Building(id: "cabana", name: "Puesto del guardabosques", style: .rangerHut, x: 49, y: 3, width: 5, height: 4, doorX: 51, doorWidth: 1, interiorID: nil,
                     lockedMessage: "El puesto del guardabosques está cerrado. Huyó cuando llegaron los lobos."),
        ],
        zones: [
            Zone(id: "valdemar.robleda.robledal", name: "Robledal", x: 2, y: 2, width: 28, height: 14, level: 6),
            Zone(id: "valdemar.robleda.campamento", name: "Campamento bandido", x: 2, y: 16, width: 28, height: 18, level: 6),
            Zone(id: "valdemar.robleda.camino", name: "Camino real", x: 30, y: 2, width: 32, height: 23, level: 6),
            Zone(id: "valdemar.robleda.guarida", name: "Guarida del lobo", x: 30, y: 25, width: 32, height: 9, level: 7),
        ],
        spawns: [
            Spawn(id: "valdemar.robleda.1", enemyID: "wolf", position: TilePoint(20, 6)),
            Spawn(id: "valdemar.robleda.2", enemyID: "wolf", position: TilePoint(22, 7)),
            Spawn(id: "valdemar.robleda.3", enemyID: "boar", position: TilePoint(18, 10)),
            Spawn(id: "valdemar.robleda.4", enemyID: "hobgoblin", position: TilePoint(28, 13)),
            Spawn(id: "valdemar.robleda.5", enemyID: "bandit", position: TilePoint(10, 23)),
            Spawn(id: "valdemar.robleda.6", enemyID: "bandit", position: TilePoint(12, 24)),
            Spawn(id: "valdemar.robleda.7", enemyID: "mercenary", position: TilePoint(18, 23)),
            Spawn(id: "valdemar.robleda.8", enemyID: "bandit", position: TilePoint(20, 24)),
            Spawn(id: "valdemar.robleda.9", enemyID: "mercenary", position: TilePoint(10, 28)),
            Spawn(id: "valdemar.robleda.10", enemyID: "bandit", position: TilePoint(13, 28)),
            Spawn(id: "valdemar.robleda.11", enemyID: "mercenary", position: TilePoint(19, 28)),
            Spawn(id: "valdemar.robleda.12", enemyID: "goblinSpearman", position: TilePoint(37, 18)),
            Spawn(id: "valdemar.robleda.13", enemyID: "goblinSpearman", position: TilePoint(39, 20)),
            Spawn(id: "valdemar.robleda.14", enemyID: "goblinShaman", position: TilePoint(36, 21)),
            Spawn(id: "valdemar.robleda.15", enemyID: "boar", position: TilePoint(33, 6)),
            Spawn(id: "valdemar.robleda.16", enemyID: "hobgoblin", position: TilePoint(54, 16)),
            Spawn(id: "valdemar.robleda.17", enemyID: "goblinShaman", position: TilePoint(57, 17)),
            Spawn(id: "valdemar.robleda.18", enemyID: "alphaWolf", position: TilePoint(55, 30)), // jefe: delante de las rocas de la guarida
            Spawn(id: "valdemar.robleda.19", enemyID: "wolf", position: TilePoint(47, 30)),
            Spawn(id: "valdemar.robleda.20", enemyID: "wolf", position: TilePoint(49, 32)),
            Spawn(id: "valdemar.robleda.21", enemyID: "wolf", position: TilePoint(36, 30)),
        ],
        npcs: [],
        level: 6,
        entry: TilePoint(43, 2),
        kind: .field,
        exits: [
            AreaExit(id: "robleda.norte", tiles: [TilePoint(42, 0), TilePoint(43, 0), TilePoint(44, 0), TilePoint(45, 0)],
                     toArea: Valdehierro.townID, arrival: TilePoint(21, 33)),
            AreaExit(id: "robleda.este", tiles: [TilePoint(63, 22), TilePoint(63, 23), TilePoint(63, 24)],
                     toArea: pedregalID, arrival: TilePoint(2, 17)),
            AreaExit(id: "robleda.huertos", tiles: [TilePoint(8, 0), TilePoint(9, 0), TilePoint(10, 0), TilePoint(11, 0)],
                     toArea: huertosID, arrival: TilePoint(12, 33)),
        ],
        safePoint: TilePoint(47, 8)
    )

    // MARK: Abadía de Valsombra (este del pueblo · 7/8)

    /// Cementerio vallado, claustro en ruinas con la iglesia y la bajada `ee` a la Cripta, huerto con campamento del Eclipse.
    /// 56×38 · nivel de fuera de zonas 7 · borrador: `mapas/abadia.md`.
    public static let abadia = AreaMap(
        id: "valdemar.abadia",
        name: "Abadía de Valsombra",
        rows: [
            "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TT....................................................TT",
            "TT...fffffffffffffffffffff....wwwwwwwwwwwwwwwwwwwwwww.TT",
            "TT...f...................f...Tw.....................w.TT",
            "TT..Tf..+..+.....+..+..+.f....w.R...................w.TT",
            "TT...f........T..........f....w...................R.w.TT",
            "TT...f........................w.....................w.TT",
            "TT...f..+..+.....+..+..+......w.....................w.TT",
            "TT...f......................T.w.......................TT",
            "TT...f...................f....w.......................TT",
            "TT...f..+..+.....+..+..+.f....w..I===I===I===I===I..w.TT",
            "TT.T.f...................f....w..=================..w.TT",
            "TT...ffffffffdddffffffffff....w..=================..w.TT",
            "TT...........ddd..............w..=================..w.TT",
            "TT.T.........ddd..............w..=======ee========..w.TT",
            ">dddddddddddddddddddddddddddddddd=================..w.TT",
            ">dddddddddddddddddddddddddddddddd=================..w.TT",
            ">dddddddddddddddddddddddddddddddd=================..w.TT",
            "TT............................w..I===I===I===I===I..w.TT",
            "TT............................w.....................w.TT",
            "TT..x......T..................w.c...................w.TT",
            "TT.................T..........wdddwwwwwwwwwww...wwwww.TT",
            "TT........................T..T.ddd....................TT",
            "TT..%%%%%%%%%%%%%%%%%%%%.......ddd.T.....T........T...TT",
            "TT..%%%%%%%%%%%%%%%%%%%%.......ddd....................TT",
            "TT..%%%%%%%%%%%%%%%%%%%%.......ddd.........~~~........TT",
            "TT........T....................ddd........~~~~~.......TT",
            "TT...............T.............ddd....T..T.~~~........TT",
            "TT....................+..T.....ddd....................TT",
            "TT.......n...n.................ddd..............T.....TT",
            "TT.......T.....................ddd..%%%%%%%%%%%%%%....TT",
            "TT.........x...................ddd..%%%%%%%%%%%%%%....TT",
            "TT............c...T......+.....ddd..%%%%%%%%%%%%%%....TT",
            "TT......T..T.................T.ddd....................TT",
            "TT.............................ddd....................TT",
            "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTdddTTTTTTTTTTTTTTTTTTTTTT",
            "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT>>>TTTTTTTTTTTTTTTTTTTTTT",
        ],
        buildings: [
            Building(id: "iglesia", name: "Iglesia de la abadía", style: .abbeyChurch, x: 36, y: 4, width: 12, height: 6, doorX: 41, doorWidth: 2, interiorID: nil,
                     lockedMessage: "La iglesia está tapiada. La bajada a la cripta está en el claustro."),
        ],
        zones: [
            Zone(id: "valdemar.abadia.cementerio", name: "Cementerio de Valsombra", x: 2, y: 2, width: 28, height: 21, level: 7),
            Zone(id: "valdemar.abadia.claustro", name: "Claustro en ruinas", x: 30, y: 2, width: 24, height: 21, level: 8),
            Zone(id: "valdemar.abadia.huerto", name: "Huerto de los monjes", x: 2, y: 23, width: 52, height: 13, level: 7),
        ],
        spawns: [
            Spawn(id: "valdemar.abadia.1", enemyID: "skeleton", position: TilePoint(9, 6)),
            Spawn(id: "valdemar.abadia.2", enemyID: "skeleton", position: TilePoint(12, 7)),
            Spawn(id: "valdemar.abadia.3", enemyID: "skeletonArcher", position: TilePoint(21, 6)),
            Spawn(id: "valdemar.abadia.4", enemyID: "ghoul", position: TilePoint(19, 9)),
            Spawn(id: "valdemar.abadia.5", enemyID: "ghoul", position: TilePoint(10, 10)),
            Spawn(id: "valdemar.abadia.6", enemyID: "skeleton", position: TilePoint(22, 12)),
            Spawn(id: "valdemar.abadia.7", enemyID: "gargoyle", position: TilePoint(34, 13)),
            Spawn(id: "valdemar.abadia.8", enemyID: "blackKnight", position: TilePoint(36, 15)),
            Spawn(id: "valdemar.abadia.9", enemyID: "necromancer", position: TilePoint(46, 13)),
            Spawn(id: "valdemar.abadia.10", enemyID: "wraith", position: TilePoint(48, 15)),
            Spawn(id: "valdemar.abadia.11", enemyID: "blackKnight", position: TilePoint(44, 18)),
            Spawn(id: "valdemar.abadia.12", enemyID: "gargoyle", position: TilePoint(50, 8)),
            Spawn(id: "valdemar.abadia.13", enemyID: "eclipseAcolyte", position: TilePoint(38, 20)), // guarda la bajada a la cripta
            Spawn(id: "valdemar.abadia.14", enemyID: "cultist", position: TilePoint(10, 29)),
            Spawn(id: "valdemar.abadia.15", enemyID: "eclipseAcolyte", position: TilePoint(13, 31)),
            Spawn(id: "valdemar.abadia.16", enemyID: "cultist", position: TilePoint(15, 29)),
            Spawn(id: "valdemar.abadia.17", enemyID: "wraith", position: TilePoint(40, 28)),
            Spawn(id: "valdemar.abadia.18", enemyID: "wraith", position: TilePoint(42, 31)),
            Spawn(id: "valdemar.abadia.19", enemyID: "fireSlime", position: TilePoint(22, 25)),
            Spawn(id: "valdemar.abadia.20", enemyID: "fireSlime", position: TilePoint(50, 26)),
        ],
        npcs: [],
        level: 7,
        entry: TilePoint(2, 17),
        kind: .field,
        exits: [
            AreaExit(id: "abadia.oeste", tiles: [TilePoint(0, 16), TilePoint(0, 17), TilePoint(0, 18)],
                     toArea: Valdehierro.townID, arrival: TilePoint(41, 17)),
            AreaExit(id: "abadia.sur", tiles: [TilePoint(31, 37), TilePoint(32, 37), TilePoint(33, 37)],
                     toArea: pedregalID, arrival: TilePoint(31, 2)),
        ],
        safePoint: TilePoint(4, 17),
        dungeonEntrances: [
            DungeonEntrance(dungeonID: "valdemar.cripta", tiles: [TilePoint(40, 15), TilePoint(41, 15)]),
        ]
    )

    // MARK: Colinas del Pedregal (sureste · 8/9)

    /// Colinas de roca con crestas y pozas heladas; al fondo, el campamento orco del Señor de la guerra.
    /// 60×38 · nivel de fuera de zonas 8 · borrador: `mapas/pedregal.md`.
    public static let pedregal = AreaMap(
        id: "valdemar.pedregal",
        name: "Colinas del Pedregal",
        rows: [
            "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^^^^^",
            "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^^^^^",
            "^^.............%%%%%%%%.......ddd.........................^^",
            "^^.............%%%%%%%%.......ddd.........................^^",
            "^^....R.......................ddd.............R...........^^",
            "^^............R...............ddd........~................^^",
            "^^............................ddd.....~~~~~~~.............^^",
            "^^............................ddd....~~~~~~~~~..........R.^^",
            "^^..................R.........ddd.....~~~~~~~.............^^",
            "^^.^^^^^^^^^..................ddd........~................^^",
            "^^.^^^^^^^^^..................ddd.........................^^",
            "^^............................ddd................~~~~~....^^",
            "^^......................R.....ddd...R...........~~~~~~~...^^",
            "^^..x...R........R............ddd................~~~~~....^^",
            "^^............................ddd.........................^^",
            "^^............................ddd.....R...................^^",
            ">dddddddddddddddddddddddddddddddddddddddddddddd.......R...^^",
            ">dddddddddddddddddddddddddddddddddddddddddddddd...........^^",
            ">dddddddddddddddddddddddddddddddddddddddddddddd...........^^",
            "^^.........................ddd..............ddd...........^^",
            "^^.........................ddd..............ddd...........^^",
            "^^..............R..........ddd..............ddd...........^^",
            "^^.........................ddd.....fffffffffdddfffffffff..^^",
            "^^.....................R...ddd.....f...................f..^^",
            "^^.........................ddd.....f..n.............n..f..^^",
            "^^.^^^^^^^^^^^^^^^^........ddd.....f...................f..^^",
            "^^.^^^^^^^^^^^^^^^^........ddd.....f.....+.......+.....f..^^",
            "^^.........................ddddddddd...................f..^^",
            "^^...........%%%%%%%.......ddddddddd.................ccf..^^",
            "^^...........%%%%%%%......Rddddddddd...................f..^^",
            "^^...R.......%%%%%%%...............f.........x.........f..^^",
            "^^..........R......................f...................f..^^",
            "^^.................................f..n.............n..f..^^",
            "^^...................R.............f............+.+....f..^^",
            "^^.................................fffffffffffffffffffff..^^",
            "^^........................................................^^",
            "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
            "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
        ],
        buildings: [
        ],
        zones: [
            Zone(id: "valdemar.pedregal.laderas", name: "Laderas del Pedregal", x: 2, y: 2, width: 25, height: 34, level: 8),
            Zone(id: "valdemar.pedregal.pozas", name: "Pozas heladas", x: 27, y: 2, width: 31, height: 18, level: 8),
            Zone(id: "valdemar.pedregal.campamento", name: "Campamento orco", x: 27, y: 20, width: 31, height: 16, level: 9),
        ],
        spawns: [
            Spawn(id: "valdemar.pedregal.1", enemyID: "goblinBomber", position: TilePoint(14, 7)),
            Spawn(id: "valdemar.pedregal.2", enemyID: "goblinBomber", position: TilePoint(17, 9)),
            Spawn(id: "valdemar.pedregal.3", enemyID: "troll", position: TilePoint(12, 22)),
            Spawn(id: "valdemar.pedregal.4", enemyID: "wolfRider", position: TilePoint(21, 27)),
            Spawn(id: "valdemar.pedregal.5", enemyID: "wolfRider", position: TilePoint(23, 30)),
            Spawn(id: "valdemar.pedregal.6", enemyID: "assassin", position: TilePoint(7, 33)),
            Spawn(id: "valdemar.pedregal.7", enemyID: "troll", position: TilePoint(22, 4)),
            Spawn(id: "valdemar.pedregal.8", enemyID: "iceSlime", position: TilePoint(37, 10)),
            Spawn(id: "valdemar.pedregal.9", enemyID: "iceSlime", position: TilePoint(40, 11)),
            Spawn(id: "valdemar.pedregal.10", enemyID: "iceSlime", position: TilePoint(52, 9)),
            Spawn(id: "valdemar.pedregal.11", enemyID: "assassin", position: TilePoint(48, 5)),
            Spawn(id: "valdemar.pedregal.12", enemyID: "troll", position: TilePoint(54, 14)),
            Spawn(id: "valdemar.pedregal.13", enemyID: "orc", position: TilePoint(40, 25)),
            Spawn(id: "valdemar.pedregal.14", enemyID: "orc", position: TilePoint(42, 27)),
            Spawn(id: "valdemar.pedregal.15", enemyID: "berserker", position: TilePoint(50, 25)),
            Spawn(id: "valdemar.pedregal.16", enemyID: "orc", position: TilePoint(52, 26)),
            Spawn(id: "valdemar.pedregal.17", enemyID: "armoredBoar", position: TilePoint(39, 31)), // élite
            Spawn(id: "valdemar.pedregal.18", enemyID: "berserker", position: TilePoint(44, 33)),
            Spawn(id: "valdemar.pedregal.19", enemyID: "warlord", position: TilePoint(51, 31)), // jefe: junto a los tótems del fondo
        ],
        npcs: [],
        level: 8,
        entry: TilePoint(2, 17),
        kind: .field,
        exits: [
            AreaExit(id: "pedregal.oeste", tiles: [TilePoint(0, 16), TilePoint(0, 17), TilePoint(0, 18)],
                     toArea: robledaID, arrival: TilePoint(61, 23)),
            AreaExit(id: "pedregal.norte", tiles: [TilePoint(30, 0), TilePoint(31, 0), TilePoint(32, 0)],
                     toArea: abadiaID, arrival: TilePoint(32, 35)),
        ],
        safePoint: TilePoint(5, 17)
    )

    // MARK: Paso del Norte (norte del pueblo · 10)

    /// Sendero de montaña en zigzag con rezagados goblins; al fondo, el cartel de Rocaforja. Se abre con `valdemar.paso_norte`.
    /// 48×32 · nivel de fuera de zonas 10 · borrador: `mapas/paso.md`.
    public static let paso = AreaMap(
        id: "valdemar.paso",
        name: "Paso del Norte",
        rows: [
            "^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^",
            "^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^",
            "^^........T..T........ddd...T..........T......^^",
            "^^....T............T..ddd...c.c...............^^",
            "^^............R.......ddd..........T.......T..^^",
            "^^.............T......ddddddddddddddddd.......^^",
            "^^T..T......T......T..ddddddddddddddddd.......^^",
            "^^....................ddddddddddddddddd.......^^",
            "^^.......T..........................dddT......^^",
            "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^.T.ddd...T...^^",
            "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^...ddd.......^^",
            "^^..................................ddd.......^^",
            "^^..........................T..T....ddd.T.R...^^",
            "^^........T...T..T.....T............ddd.......^^",
            "^^....ddddddddddddddddddddddddddddddddd.......^^",
            "^^..T.ddddddddddddddddddddddddddddddddd.......^^",
            "^^....ddddddddddddddddddddddddddddddddd.......^^",
            "^^....ddd......T.......................T....T.^^",
            "^^....ddd.T..........T........................^^",
            "^^....ddd.^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^..^^",
            "^^T...ddd.^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^..^^",
            "^^....ddd.T..T..............T................T^^",
            "^^....ddd...........................T.........^^",
            "^^....ddd...............................T.....^^",
            "^^....ddddddddddddddddddd.....................^^",
            "^^....dddddddddddddddddddT..............R.....^^",
            "^^....ddddddddddddddddddd.....................^^",
            "^^........T.R.T...T...ddd...T.....T....T......^^",
            "^^....................ddd.x...................^^",
            "^^..T.................ddd.....................^^",
            "^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^",
            "^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^",
        ],
        buildings: [
            Building(id: "atalaya", name: "Atalaya derruida", style: .watchtower, x: 30, y: 22, width: 4, height: 5, doorX: 31, doorWidth: 1, interiorID: nil,
                     lockedMessage: "La atalaya está derruida. Desde aquí se ve el castillo… y el camino al norte."),
        ],
        zones: [
            Zone(id: "valdemar.paso.sendero", name: "Paso del Norte", x: 2, y: 2, width: 44, height: 28, level: 10),
        ],
        spawns: [
            Spawn(id: "valdemar.paso.1", enemyID: "wolfRider", position: TilePoint(9, 21)),
            Spawn(id: "valdemar.paso.2", enemyID: "wolfRider", position: TilePoint(12, 23)),
            Spawn(id: "valdemar.paso.3", enemyID: "goblinElite", position: TilePoint(20, 15)),
            Spawn(id: "valdemar.paso.4", enemyID: "goblinMage", position: TilePoint(22, 13)),
            Spawn(id: "valdemar.paso.5", enemyID: "goblinElite", position: TilePoint(38, 9)),
            Spawn(id: "valdemar.paso.6", enemyID: "armoredBoar", position: TilePoint(14, 6)),
        ],
        npcs: [
            NPC(id: "cartelPaso", name: "Cartel del camino", look: "signpost", role: .clue, position: TilePoint(26, 2),
                plea: "Un cartel de madera señala hacia el norte.",
                // `npc.cartelPaso.leer` (`valdemar.md` §6).
                thanks: ["Un poste con dos tablas. Al sur: «Valdehierro». Al norte: «Montes de Rocaforja».",
                         "En el barro, huellas de botas recientes y un jirón de capa gris. Buen paño.",
                         "Elena reconocería ese punto en cualquier parte."],
                reward: Reward()),
        ],
        level: 10,
        entry: TilePoint(23, 29),
        kind: .field,
        exits: [
            AreaExit(id: "paso.sur", tiles: [TilePoint(22, 31), TilePoint(23, 31), TilePoint(24, 31)],
                     toArea: Valdehierro.townID, arrival: TilePoint(4, 2)),
            AreaExit(id: "paso.norte", tiles: [TilePoint(22, 0), TilePoint(23, 0), TilePoint(24, 0)],
                     toArea: "rocaforja", arrival: nil,
                     lock: .comingSoon("rocaforja"),
                     lockedMessage: "Montes de Rocaforja: próximamente. El camino sigue en el capítulo 2."),
        ],
        safePoint: TilePoint(23, 27)
    )

    // MARK: Mazmorras de historia (`zonas.md` §3)

    /// Cripta bajo la abadía (piso `crypt`, nivel 8): 3 oleadas y el Abad no-muerto. Se baja por la `ee` del claustro.
    public static let cripta = StoryDungeon(
        id: "valdemar.cripta", name: "Cripta de la abadía", floorID: "crypt", level: 8,
        waves: [
            ["skeleton": 5, "ghoul": 3, "skeletonArcher": 2],
            ["wraith": 3, "cultist": 2, "eclipseAcolyte": 2, "gargoyle": 2, "fireSlime": 1],
            ["necromancer": 2, "blackKnight": 2, "ghoul": 3, "skeletonArcher": 2, "iceSlime": 1],
        ],
        bossID: "abbot", bossEscort: ["skeleton": 2], repeatable: true, entranceAreaID: abadiaID,
        // `dungeon.valdemar.cripta.bossIntro` (`valdemar.md` §7): confesión a medias del Abad Morcar.
        bossIntro: ["Bienvenido a mi abadía, forastero. Perdona el polvo: llevo un año muerto.",
                    "¿El castillo? No buscaba el castillo, necio. Buscaba lo que tu princesa esconde.",
                    "La Luna se apaga… y Él despierta.",
                    "Arrodíllate. Quizá te deje ver el último amanecer."],
        // Fijo al ganar; el 50 % de oro ×1 lo decide el balance-designer.
        reward: Reward(minerals: [.emerald: 1]),
        bossIntroRepeat: ["¿Otra vez tú? La muerte me sienta mejor que a ti."],
        // `boss.abbot.derrota`: va debajo del aviso de victoria; la 1.ª línea la dice el Abad Morcar, la 2.ª narra.
        bossDefeat: ["La Orden… no muere conmigo. Quedan cinco brasas…",
                     "Al fondo de la cripta algo brilla, dorado y caliente como una brasa viva."],
        // `valdemar.md` §7: en la cripta habla como «Abad Morcar», no con el nombre del bestiario.
        bossSpeaker: "Abad Morcar"
    )

    /// Calabozos del castillo (piso `prison`, nivel 9, opcional): 4 oleadas sin jefe. Bajada `e` del patio, con el
    /// castillo abierto. Repetible para entrenar.
    public static let calabozos = StoryDungeon(
        id: "valdemar.calabozos", name: "Calabozos del castillo", floorID: "prison", level: 9,
        waves: [
            ["goblinElite": 4, "goblinMage": 2, "goblinGuard": 2],
            ["orc": 3, "berserker": 2, "assassin": 2, "goblinBomber": 2],
            ["goblinGuard": 3, "iceSlime": 2, "troll": 2, "wolfRider": 2],
            ["goblinStandard": 2, "goblinElite": 4, "goblinMage": 2],
        ],
        repeatable: true, entranceAreaID: Valdehierro.townID
    )
}
