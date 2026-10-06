import Foundation

// MARK: - Casillas

/// Tipos de casilla. Los mapas se escriben como texto: un carácter por casilla.
public enum Tile: Character, CaseIterable, Sendable {
    // Exterior
    case grass = "."
    case flowers = ","
    case street = "#"
    case plaza = "="
    case tree = "T"
    case water = "~"
    case fountain = "F"
    case fence = "f"
    case wall = "w"
    case stairs = "S"
    case lamp = "l"
    case stall = "m"
    case crates = "c"
    case bush = "b"
    // Interior
    case interiorWall = "X"
    case woodFloor = "_"
    case stoneFloor = ":"
    case carpet = "r"
    case shelf = "s"
    case oven = "k"
    case table = "t"
    case bed = "z"
    case barrel = "o"
    case pillar = "I"
    case throne = "Y"
    case exit = "D"

    public var isSolid: Bool {
        switch self {
        case .grass, .flowers, .street, .plaza, .stairs, .woodFloor, .stoneFloor, .carpet, .exit: false
        default: true
        }
    }
}

// MARK: - Elementos del mapa

public struct TilePoint: Hashable, Codable, Sendable {
    public let x: Int
    public let y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

public enum BuildingStyle: String, Sendable {
    case house, bakery, inn, smithy, chapel, mill, alchemist, castle
}

/// Edificio del pueblo. Ocupa un rectángulo sólido; la puerta está en la fila de abajo.
public struct Building: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let style: BuildingStyle
    public let x: Int, y: Int, width: Int, height: Int
    /// Columnas de la puerta (en la última fila del edificio).
    public let doorX: Int
    public let doorWidth: Int
    /// Área a la que lleva la puerta (nil = cerrada).
    public let interiorID: String?

    public var doorTiles: [TilePoint] { (0..<doorWidth).map { TilePoint(doorX + $0, y + height - 1) } }

    public func contains(_ p: TilePoint) -> Bool {
        p.x >= x && p.x < x + width && p.y >= y && p.y < y + height
    }
}

public struct Spawn: Identifiable, Sendable {
    /// Id único y estable (se guarda al morir).
    public let id: String
    public let enemyID: String
    public let position: TilePoint
}

public struct Zone: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let x: Int, y: Int, width: Int, height: Int
    /// Nivel de dificultad de los enemigos (1...10).
    public let level: Int

    public func contains(_ p: TilePoint) -> Bool {
        p.x >= x && p.x < x + width && p.y >= y && p.y < y + height
    }
}

public struct Reward: Sendable {
    public var gold: Int = 0
    public var minerals: [Mineral: Int] = [:]
    public var partID: String?
}

public enum NPCRole: Sendable {
    /// Aldeano atrapado: se rescata al limpiar la casa.
    case villager
    /// La princesa del castillo: se rescata al derrotar al jefe.
    case princess
}

public struct NPC: Identifiable, Sendable {
    public let id: String
    public let name: String
    /// Aspecto (la app lo interpreta).
    public let look: String
    public let role: NPCRole
    public let position: TilePoint
    /// Antes de liberar la sala.
    public let plea: String
    /// Al rescatarlo.
    public let thanks: [String]
    public let reward: Reward
}

/// Un área explorable: el pueblo o el interior de un edificio.
public struct AreaMap: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let rows: [String]
    public let buildings: [Building]
    public let zones: [Zone]
    public let spawns: [Spawn]
    public let npcs: [NPC]
    /// Nivel de dificultad de un interior (en el pueblo manda la zona).
    public let level: Int
    /// Punto de entrada del jugador.
    public let entry: TilePoint

    public var width: Int { rows.map(\.count).max() ?? 0 }
    public var height: Int { rows.count }

    public func tile(_ x: Int, _ y: Int) -> Tile {
        guard y >= 0, y < rows.count else { return .tree }
        let row = Array(rows[y])
        guard x >= 0, x < row.count else { return .tree }
        return Tile(rawValue: row[x]) ?? .grass
    }

    public func building(at p: TilePoint) -> Building? {
        buildings.first { $0.contains(p) }
    }

    /// ¿Se puede pisar? Los edificios son sólidos salvo su puerta.
    public func isWalkable(_ p: TilePoint) -> Bool {
        if let b = building(at: p) { return b.doorTiles.contains(p) }
        return !tile(p.x, p.y).isSolid
    }

    public func zone(at p: TilePoint) -> Zone? {
        zones.first { $0.contains(p) }
    }

    public func level(at p: TilePoint) -> Int {
        zone(at: p)?.level ?? level
    }

    public var exitTiles: [TilePoint] {
        rows.enumerated().flatMap { y, row in
            row.enumerated().compactMap { x, c in c == Tile.exit.rawValue ? TilePoint(x, y) : nil }
        }
    }

    public var isInterior: Bool { id != Valdehierro.townID }
}

// MARK: - Progreso

public struct TownProgress: Codable, Equatable, Sendable {
    public var killedSpawns: Set<String> = []
    public var rescued: Set<String> = []
    public var princessRescued = false

    public init() {}

    public func isLiberated(_ zone: Zone, in map: AreaMap) -> Bool {
        map.spawns.filter { zone.contains($0.position) }.allSatisfy { killedSpawns.contains($0.id) }
    }

    public func isCleared(_ map: AreaMap) -> Bool {
        map.spawns.allSatisfy { killedSpawns.contains($0.id) }
    }

    public var castleOpen: Bool {
        rescued.isSuperset(of: Valdehierro.villagerIDs)
    }

    /// Nivel de la forja del enano: sube al liberar zonas y rescatar aldeanos.
    public var shopLevel: Int {
        let town = Valdehierro.town
        let zones = town.zones.filter { isLiberated($0, in: town) }.count
        return min(10, 1 + zones + rescued.count)
    }
}

// MARK: - El pueblo de Valdehierro

public enum Valdehierro {
    public static let townID = "town"

    public static let town = AreaMap(
        id: townID,
        name: "Valdehierro",
        rows: [
            "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TT.....w............................w.....TT",
            "TT.....w............................w.....TT",
            "TT.....w.T.......................T..w.....TT",
            "TT....,w............................w.,...TT",
            "TT.....w............................w.....TT",
            "TT.....w..T.......................T.w....,TT",
            "TT,.,..w............................w.....TT",
            "TT.....w............................w.....TT",
            "TT.....w=l==l==================l==l=w.....TT",
            "TT.....w============================w.....TT",
            "TT.....wwwwwwwwwwwwSSSSSSwwwwwwwwwwww.....TT",
            "TT............#==============#............TT",
            "TT............#=lb========bl=#..........,.TT",
            "TT..........,.#==============#............TT",
            "TT,...........#==============#.......,....TT",
            "TT.......,....#======FF======#.....,......TT",
            "TT#############======FF======#############TT",
            "TT#############==============#############TT",
            "TT............#==============#............TT",
            "TT............#=lb========bl=#............TT",
            "TT............#==============#.....,......TT",
            "TT..,...............####..........,.......TT",
            "TT....,.............####..............,...TT",
            "TT########################################TT",
            "TT..................####............,...,.TT",
            "TT.===============..####.===============..TT",
            "TT.=mm==mm==mm==mm..####.=mm==mm==mm==mm,.TT",
            "TT.===============..####.===============..TT",
            "TT.=c===c===c===c=..####.==c====c====c==..TT",
            "TT.===============..####.===============,.TT",
            "TT...........,....l.####.l................TT",
            "wwwwwwwwwwwwwwwwwww######wwwwwwwwwwwwwwwwwww",
            "TT................########................TT",
            "TT,.....,.........########..........,.....TT",
            "TT................########....,...........TT",
        ],
        buildings: [
            Building(id: "castle", name: "Castillo de Valdehierro", style: .castle, x: 12, y: 1, width: 20, height: 8, doorX: 21, doorWidth: 2, interiorID: "castle"),
            Building(id: "bakery", name: "Panadería", style: .bakery, x: 2, y: 12, width: 6, height: 5, doorX: 4, doorWidth: 1, interiorID: "bakery"),
            Building(id: "weaver", name: "Casa de la tejedora", style: .house, x: 8, y: 12, width: 5, height: 5, doorX: 10, doorWidth: 1, interiorID: "weaver"),
            Building(id: "mill", name: "Casa del molinero", style: .mill, x: 2, y: 19, width: 6, height: 5, doorX: 4, doorWidth: 1, interiorID: "mill"),
            Building(id: "chapel", name: "Capilla", style: .chapel, x: 8, y: 19, width: 6, height: 5, doorX: 11, doorWidth: 1, interiorID: "chapel"),
            Building(id: "inn", name: "Posada del Jabalí", style: .inn, x: 30, y: 12, width: 7, height: 5, doorX: 33, doorWidth: 1, interiorID: "inn"),
            Building(id: "smithy", name: "Forja del enano", style: .smithy, x: 37, y: 12, width: 5, height: 5, doorX: 39, doorWidth: 1, interiorID: "smithy"),
            Building(id: "alchemist", name: "Casa de la alquimista", style: .alchemist, x: 30, y: 19, width: 6, height: 5, doorX: 32, doorWidth: 1, interiorID: "alchemist"),
            Building(id: "mayor", name: "Casa del alcalde", style: .house, x: 36, y: 19, width: 6, height: 5, doorX: 38, doorWidth: 1, interiorID: nil),
        ],
        zones: [
            Zone(id: "south", name: "Puerta sur", x: 0, y: 31, width: 44, height: 5, level: 1),
            Zone(id: "market", name: "Mercado", x: 0, y: 25, width: 44, height: 6, level: 2),
            Zone(id: "west", name: "Barrio oeste", x: 0, y: 12, width: 14, height: 13, level: 3),
            Zone(id: "east", name: "Barrio este", x: 30, y: 12, width: 14, height: 13, level: 4),
            Zone(id: "plaza", name: "Plaza mayor", x: 14, y: 12, width: 16, height: 13, level: 5),
            Zone(id: "courtyard", name: "Patio del castillo", x: 7, y: 1, width: 30, height: 11, level: 7),
        ],
        spawns: [
            Spawn(id: "south.1", enemyID: "rat", position: TilePoint(9, 34)),
            Spawn(id: "south.2", enemyID: "rat", position: TilePoint(33, 34)),
            Spawn(id: "south.3", enemyID: "goblin", position: TilePoint(14, 34)),
            Spawn(id: "south.4", enemyID: "goblin", position: TilePoint(29, 34)),
            Spawn(id: "south.5", enemyID: "goblinSlinger", position: TilePoint(22, 31)),
            Spawn(id: "south.6", enemyID: "mangyDog", position: TilePoint(12, 31)),

            Spawn(id: "market.1", enemyID: "bandit", position: TilePoint(6, 28)),
            Spawn(id: "market.2", enemyID: "goblinThief", position: TilePoint(10, 26)),
            Spawn(id: "market.3", enemyID: "goblinThief", position: TilePoint(30, 28)),
            Spawn(id: "market.4", enemyID: "crow", position: TilePoint(14, 30)),
            Spawn(id: "market.5", enemyID: "crow", position: TilePoint(35, 26)),
            Spawn(id: "market.6", enemyID: "mangyDog", position: TilePoint(28, 30)),
            Spawn(id: "market.7", enemyID: "bandit", position: TilePoint(38, 28)),
            Spawn(id: "market.8", enemyID: "goblinSpearman", position: TilePoint(22, 27)),

            Spawn(id: "west.1", enemyID: "skeleton", position: TilePoint(4, 18)),
            Spawn(id: "west.2", enemyID: "zombieFarmer", position: TilePoint(9, 17)),
            Spawn(id: "west.3", enemyID: "goblinShaman", position: TilePoint(12, 18)),
            Spawn(id: "west.4", enemyID: "boar", position: TilePoint(6, 24)),
            Spawn(id: "west.5", enemyID: "skeleton", position: TilePoint(13, 14)),

            Spawn(id: "east.1", enemyID: "cultist", position: TilePoint(34, 18)),
            Spawn(id: "east.2", enemyID: "slime", position: TilePoint(31, 17)),
            Spawn(id: "east.3", enemyID: "bat", position: TilePoint(38, 18)),
            Spawn(id: "east.4", enemyID: "goblinBrute", position: TilePoint(41, 17)),
            Spawn(id: "east.5", enemyID: "cultist", position: TilePoint(36, 24)),

            Spawn(id: "plaza.1", enemyID: "hobgoblin", position: TilePoint(18, 15)),
            Spawn(id: "plaza.2", enemyID: "skeletonArcher", position: TilePoint(25, 14)),
            Spawn(id: "plaza.3", enemyID: "wolf", position: TilePoint(19, 19)),
            Spawn(id: "plaza.4", enemyID: "mercenary", position: TilePoint(25, 19)),
            Spawn(id: "plaza.5", enemyID: "banditChief", position: TilePoint(22, 14)),

            Spawn(id: "courtyard.1", enemyID: "goblinGuard", position: TilePoint(14, 10)),
            Spawn(id: "courtyard.2", enemyID: "goblinGuard", position: TilePoint(29, 10)),
            Spawn(id: "courtyard.3", enemyID: "goblinMage", position: TilePoint(10, 4)),
            Spawn(id: "courtyard.4", enemyID: "goblinMage", position: TilePoint(34, 4)),
            Spawn(id: "courtyard.5", enemyID: "goblinElite", position: TilePoint(22, 10)),
            Spawn(id: "courtyard.6", enemyID: "orc", position: TilePoint(18, 9)),
            Spawn(id: "courtyard.7", enemyID: "wolfRider", position: TilePoint(26, 9)),
        ],
        npcs: [],
        level: 1,
        entry: TilePoint(21, 35)
    )

    public static let interiors: [AreaMap] = [
        interior("bakery", "Panadería", level: 2, rows: [
            "XXXXXXXXXXXXXX",
            "XssskkX__ssssX",
            "X____________X",
            "X__t____t__o_X",
            "X____________X",
            "X_oo______zz_X",
            "X_________zz_X",
            "X____________X",
            "XXXXXXDXXXXXXX",
        ], spawns: [("rat", 3, 4), ("rat", 9, 6), ("rat", 6, 6), ("ratKing", 7, 3)],
        npc: NPC(id: "marta", name: "Marta, la panadera", look: "baker", role: .villager, position: TilePoint(12, 2),
                 plea: "¡Ratas! ¡Ratas por todas partes!",
                 thanks: ["¡Gracias, gracias! Creí que me comerían junto con el pan.",
                          "Los goblins entraron por la puerta sur una noche sin luna.",
                          "Toma, es todo lo que he podido ahorrar."],
                 reward: Reward(gold: 60, minerals: [.copper: 4, .iron: 2]))),

        interior("weaver", "Casa de la tejedora", level: 3, rows: [
            "XXXXXXXXXXXXX",
            "XsssssXsssssX",
            "X___________X",
            "X_tt_____oo_X",
            "X___________X",
            "X_____t_____X",
            "X_zz________X",
            "X___________X",
            "XXXXXXDXXXXXX",
        ], spawns: [("bandit", 3, 4), ("goblinThief", 9, 5), ("bandit", 6, 2)],
        npc: NPC(id: "elena", name: "Elena, la tejedora", look: "weaver", role: .villager, position: TilePoint(10, 7),
                 plea: "¡Se están llevando mis telas!",
                 thanks: ["Esos bandidos trabajan para el Rey Goblin, estoy segura.",
                          "Dicen que tiene a la princesa encerrada en el salón del trono."],
                 reward: Reward(gold: 80, minerals: [.silver: 3, .gold: 2]))),

        interior("mill", "Casa del molinero", level: 3, rows: [
            "XXXXXXXXXXXXXX",
            "Xoo::::::::ooX",
            "X::::::::::::X",
            "X::cc::::cc::X",
            "X::::::::::::X",
            "X::::::::::::X",
            "Xoo::::::::ooX",
            "X::::::::::::X",
            "XXXXXXDXXXXXXX",
        ], spawns: [("zombieFarmer", 3, 4), ("boar", 10, 4), ("scarecrow", 7, 2)],
        npc: NPC(id: "tomas", name: "Tomás, el molinero", look: "miller", role: .villager, position: TilePoint(11, 7),
                 plea: "¡El espantapájaros ha cobrado vida!",
                 thanks: ["Ese espantapájaros lo hechizó la bruja del pozo...",
                          "Llévate esto. A mí ya no me sirve de nada."],
                 reward: Reward(gold: 90, minerals: [.emerald: 3, .copper: 4]))),

        interior("chapel", "Capilla", level: 5, rows: [
            "XXXXXXXXXXXXXX",
            "X:::::YY:::::X",
            "X::I::::::I::X",
            "X::::rrrr::::X",
            "X:tt:rrrr:tt:X",
            "X::::rrrr::::X",
            "X:tt:rrrr:tt:X",
            "X::I:rrrr:I::X",
            "X::::rrrr::::X",
            "XXXXXXDXXXXXXX",
        ], spawns: [("skeleton", 3, 3), ("skeleton", 10, 3), ("ghoul", 4, 8), ("ghoul", 9, 8), ("skeletonArcher", 6, 2)],
        npc: NPC(id: "anselmo", name: "Fray Anselmo", look: "monk", role: .villager, position: TilePoint(9, 1),
                 plea: "¡Que la luz te guíe, joven! ¡Los muertos se levantan!",
                 thanks: ["Bendito seas. Los goblins profanaron el cementerio.",
                          "Esta reliquia te protegerá. Y que la Plata guíe tu acero."],
                 reward: Reward(gold: 120, minerals: [.silver: 4, .sapphire: 2], partID: "head.mace.silver"))),

        interior("inn", "Posada del Jabalí", level: 4, rows: [
            "XXXXXXXXXXXXXXXX",
            "Xsss_____sssoooX",
            "X______________X",
            "X_tt__tt__tt___X",
            "X______________X",
            "X_tt__tt____zz_X",
            "X___________zz_X",
            "X______________X",
            "XXXXXXXDXXXXXXXX",
        ], spawns: [("goblin", 3, 4), ("goblin", 8, 2), ("goblinSlinger", 12, 4), ("goblinBrute", 9, 6), ("possessedSmith", 5, 6)],
        npc: NPC(id: "bruno", name: "Bruno, el posadero", look: "innkeeper", role: .villager, position: TilePoint(13, 2),
                 plea: "¡Mi posada! ¡Se están bebiendo toda la cerveza!",
                 thanks: ["¡Ja! ¡Buen golpe, forastero!",
                          "El herrero de al lado es un enano gruñón, pero forja como nadie.",
                          "Invita la casa."],
                 reward: Reward(gold: 150, minerals: [.gold: 3, .ruby: 1]))),

        interior("alchemist", "Casa de la alquimista", level: 6, rows: [
            "XXXXXXXXXXXXX",
            "XsssssssssssX",
            "X___________X",
            "X_tt__o__tt_X",
            "X___________X",
            "X_o_______o_X",
            "X___________X",
            "X___________X",
            "XXXXXXDXXXXXX",
        ], spawns: [("slime", 3, 4), ("fireSlime", 9, 4), ("bat", 6, 6), ("witch", 6, 2)],
        npc: NPC(id: "iris", name: "Iris, la alquimista", look: "alchemist", role: .villager, position: TilePoint(11, 7),
                 plea: "¡La bruja quiere mis pociones!",
                 thanks: ["Con todos a salvo, los guardias abrirán el castillo.",
                          "Toma estos cristales: tienen magia dentro."],
                 reward: Reward(gold: 180, minerals: [.amethyst: 3, .diamond: 1]))),

        interior("castle", "Salón del trono", level: 10, rows: [
            "XXXXXXXXXXXXXXXXXXXXXX",
            "X:::::::::YY:::::::::X",
            "X::I::::::rr::::::I::X",
            "X:::::::::rr:::::::::X",
            "X::I::::::rr::::::I::X",
            "X:::::::::rr:::::::::X",
            "X::I::::::rr::::::I::X",
            "X:::::::::rr:::::::::X",
            "X::I::::::rr::::::I::X",
            "X:::::::::rr:::::::::X",
            "X::I::::::rr::::::I::X",
            "X:::::::::rr:::::::::X",
            "X:::::::::rr:::::::::X",
            "XXXXXXXXXXDDXXXXXXXXXX",
        ], spawns: [("goblinGuard", 5, 9), ("goblinGuard", 16, 9), ("goblinMage", 5, 4), ("goblinMage", 16, 4),
                    ("goblinStandard", 10, 7), ("goblinKing", 10, 3)],
        npc: NPC(id: "princess", name: "Princesa Aurora", look: "princess", role: .princess, position: TilePoint(13, 1),
                 plea: "¡Cuidado! ¡El Rey Goblin es muy fuerte!",
                 thanks: ["¡Has derrotado al Rey Goblin! Valdehierro vuelve a ser libre.",
                          "Mi familia guardó esto durante generaciones: la Hoja del Alba.",
                          "Llévala al ritual de forja. Solo un héroe puede despertarla."],
                 reward: Reward(gold: 500, minerals: [.mithril: 2, .diamond: 2], partID: "legend.dawn"))),
    ]

    private static func interior(_ id: String, _ name: String, level: Int, rows: [String],
                                 spawns: [(String, Int, Int)], npc: NPC) -> AreaMap {
        let door = rows.last.flatMap { $0.firstIndex(of: "D") }.map { rows.last!.distance(from: rows.last!.startIndex, to: $0) } ?? 1
        return AreaMap(
            id: id, name: name, rows: rows, buildings: [], zones: [],
            spawns: spawns.enumerated().map { i, s in Spawn(id: "\(id).\(i + 1)", enemyID: s.0, position: TilePoint(s.1, s.2)) },
            npcs: [npc], level: level, entry: TilePoint(door, rows.count - 2)
        )
    }

    public static func area(_ id: String) -> AreaMap? {
        id == townID ? town : interiors.first { $0.id == id }
    }

    public static var villagerIDs: Set<String> {
        Set(interiors.flatMap(\.npcs).filter { $0.role == .villager }.map(\.id))
    }

    /// Edificio del pueblo que lleva a un interior.
    public static func building(leadingTo interiorID: String) -> Building? {
        town.buildings.first { $0.interiorID == interiorID }
    }
}
