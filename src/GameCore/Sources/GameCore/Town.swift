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
    // Exterior de campo (leyenda común de `assets/world/continentes.md`; el dibujo depende del bioma)
    /// Camino de tierra o sendero.
    case dirt = "d"
    /// Hierba alta, trigal o maleza (decorativa, se pisa).
    case tallGrass = "%"
    /// Puente de madera sobre el agua.
    case bridge = "p"
    /// Roca o peñasco.
    case rock = "R"
    /// Acantilado o pared de montaña.
    case cliff = "^"
    /// Lápida, estela o tótem.
    case grave = "+"
    /// Tienda de campaña.
    case tent = "n"
    /// Hoguera o brasero (da luz).
    case campfire = "x"
    /// Entrada de cueva o mazmorra de historia (ver `AreaMap.dungeonEntrances`).
    case cave = "e"
    /// Salida a otra área, en el borde del mapa (ver `AreaMap.exits`).
    case areaExit = ">"
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
        case .grass, .flowers, .street, .plaza, .stairs, .woodFloor, .stoneFloor, .carpet, .exit,
             .dirt, .tallGrass, .bridge, .cave, .areaExit: false
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
    // Edificios de campo de Valdemar (los dibuja el environment-artist en la fase 2)
    case ruinedMill, burnedFarm, abbeyChurch, rangerHut, watchtower

    /// Estilo con el que se dibuja mientras no tenga arte propio (los originales se dibujan como sí mismos).
    public var placeholder: BuildingStyle {
        switch self {
        case .ruinedMill: .mill
        case .burnedFarm: .house
        case .abbeyChurch: .chapel
        case .rangerHut, .watchtower: .house
        default: self
        }
    }
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
    /// Aviso al tocar la puerta de un edificio sin interior (nil = "{nombre}: no se puede entrar.").
    public var lockedMessage: String? = nil

    public var doorTiles: [TilePoint] { (0..<doorWidth).map { TilePoint(doorX + $0, y + height - 1) } }

    public func contains(_ p: TilePoint) -> Bool {
        p.x >= x && p.x < x + width && p.y >= y && p.y < y + height
    }

    /// El mismo edificio con el estilo provisional de dibujo (`BuildingStyle.placeholder`).
    public var withPlaceholderStyle: Building {
        Building(id: id, name: name, style: style.placeholder, x: x, y: y, width: width, height: height,
                 doorX: doorX, doorWidth: doorWidth, interiorID: interiorID, lockedMessage: lockedMessage)
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
    /// Da misiones y no hay que rescatarlo (el Capitán de la guardia).
    case questGiver
    /// Objeto que se lee al acercarse con la sala despejada (la carta del alcalde, un cartel).
    case clue
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
    /// Solo aparece cuando se cumple esta condición (nil = siempre). Ej.: el Capitán tras `valdemar.liberar`,
    /// un aldeano en la calle tras su rescate.
    public var appearsWhen: StoryCondition? = nil
    /// Lo que dice al volver a hablarle sin misiones pendientes, según el momento de la historia: vale la primera
    /// línea cuyas condiciones se cumplen (`npc.<id>.casa` en el NPC de su casa, `npc.<id>.calle.*` en el de la calle).
    /// Vacío = una frase genérica.
    public var talk: [NPCLine] = []
}

/// Diálogo de un NPC para un momento de la historia (`assets/story/valdemar.md` §3-4).
public struct NPCLine: Sendable {
    /// Todas deben cumplirse.
    public var when: [StoryCondition]
    /// Ninguna debe cumplirse (p. ej. etapa "fuera" = `liberar` hecha y `rey_goblin` no).
    public var unless: [StoryCondition]
    public var lines: [String]

    public init(when: [StoryCondition] = [], unless: [StoryCondition] = [], _ lines: [String]) {
        self.when = when
        self.unless = unless
        self.lines = lines
    }
}

/// Un área explorable: el pueblo, el interior de un edificio o un exterior de campo.
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

    // Contrato de datos del mundo (fase 0). Valores por defecto: lo existente compila igual.
    /// Pueblo, interior o campo. Decide `isInterior` y (en la fase 1) qué monstruos reaparecen.
    public internal(set) var kind: AreaKind = .field
    /// Cómo se dibujan las casillas (`.` hierba, `T` roble…).
    public internal(set) var biome: Biome = .valdemar
    /// Continente al que pertenece (botín y forja por continente).
    public internal(set) var continentID: String = World.valdemarID
    /// Salidas a otras áreas (casillas `>`).
    public internal(set) var exits: [AreaExit] = []
    /// Dónde reaparece el héroe al morir en esta área (nil = Puerta sur del pueblo, como hoy).
    public internal(set) var safePoint: TilePoint? = nil
    /// Bajadas a mazmorras de historia (casillas `e`).
    public internal(set) var dungeonEntrances: [DungeonEntrance] = []

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

    public var isInterior: Bool { kind == .interior }
    public var isField: Bool { kind == .field }

    /// Salida que ocupa esa casilla (si la hay).
    public func exit(at p: TilePoint) -> AreaExit? {
        exits.first { $0.tiles.contains(p) }
    }

    /// Bajada a mazmorra que ocupa esa casilla (si la hay).
    public func dungeonEntrance(at p: TilePoint) -> DungeonEntrance? {
        dungeonEntrances.first { $0.tiles.contains(p) }
    }

    /// Casillas del mapa con un carácter concreto (p. ej. todas las `>`).
    public func tiles(of kind: Tile) -> [TilePoint] {
        rows.enumerated().flatMap { y, row in
            row.enumerated().compactMap { x, c in c == kind.rawValue ? TilePoint(x, y) : nil }
        }
    }
}

// MARK: - Progreso

public struct TownProgress: Codable, Equatable, Sendable {
    /// Monstruos que no vuelven (pueblo, interiores y jefes de campo). Los de campo que reaparecen no se guardan.
    public var killedSpawns: Set<String> = []
    public var rescued: Set<String> = []
    public var princessRescued = false
    /// Zonas de campo liberadas alguna vez (sus monstruos reaparecen, así que se apunta la primera vez).
    /// Opcional: las partidas antiguas no lo tienen.
    public var fieldZonesLiberated: Set<String>?

    public init() {}

    public func isLiberated(_ zone: Zone, in map: AreaMap) -> Bool {
        map.spawns.filter { zone.contains($0.position) }.allSatisfy { killedSpawns.contains($0.id) }
    }

    public func isCleared(_ map: AreaMap) -> Bool {
        map.spawns.allSatisfy { killedSpawns.contains($0.id) }
    }

    /// Los seis aldeanos están a salvo (antes abría el castillo; ahora es el objetivo de `valdemar.liberar`).
    /// La condición del castillo es `PlayerProfile.isCastleOpen`.
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
            "TTT>>>TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
            "TT.....w............................w.....TT",
            "TT.....w............................w.....TT",
            "TT.....w.T.......................T..w.....TT",
            "TT....,...............................,...TT",
            "TT........................................TT",
            "TT.....w..T.......................T.w....,TT",
            "TT,.,..w..........................e.w.....TT",
            "TT.....w............................w.....TT",
            "TT.....w=l==l==================l==l=w.....TT",
            "TT.....w============================w.....TT",
            "TT.....wwwwwwwwwwwwSSSSSSwwwwwwwwwwww.....TT",
            "TT............#==============#............TT",
            "TT............#=lb========bl=#..........,.TT",
            "TT..........,.#==============#............TT",
            "TT,...........#==============#.......,....TT",
            "TT.......,....#======FF======#.....,......TT",
            ">##############======FF======##############>",
            ">##############==============##############>",
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
            "TT................>>>>>>>>....,...........TT",
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
            Building(id: "mayor", name: "Casa del alcalde", style: .house, x: 36, y: 19, width: 6, height: 5, doorX: 38, doorWidth: 1, interiorID: "mayor"),
        ],
        zones: [
            Zone(id: "south", name: "Puerta sur", x: 0, y: 31, width: 44, height: 5, level: 1),
            Zone(id: "market", name: "Mercado", x: 0, y: 25, width: 44, height: 6, level: 2),
            Zone(id: "west", name: "Barrio oeste", x: 0, y: 12, width: 14, height: 13, level: 3),
            Zone(id: "east", name: "Barrio este", x: 30, y: 12, width: 14, height: 13, level: 4),
            Zone(id: "plaza", name: "Plaza mayor", x: 14, y: 12, width: 16, height: 13, level: 5),
            Zone(id: "courtyard", name: "Patio del castillo", x: 7, y: 1, width: 30, height: 11, level: 9),
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
        npcs: streetNPCs,
        level: 1,
        // La fila 35 es la salida sur (camino real a Robleda): se entra un poco más arriba.
        entry: TilePoint(21, 33),
        kind: .town,
        exits: [
            AreaExit(id: "town.oeste", tiles: [TilePoint(0, 17), TilePoint(0, 18)],
                     toArea: Valdemar.huertosID, arrival: TilePoint(53, 17),
                     lock: .zoneLiberated("west"),
                     lockedMessage: "Los goblins del barrio oeste cortan el camino de los huertos."),
            AreaExit(id: "town.este", tiles: [TilePoint(43, 17), TilePoint(43, 18)],
                     toArea: Valdemar.abadiaID, arrival: TilePoint(2, 17),
                     lock: .zoneLiberated("east"),
                     lockedMessage: "Los cultistas del barrio este vigilan el camino de la abadía."),
            AreaExit(id: "town.sur", tiles: (18...25).map { TilePoint($0, 35) },
                     toArea: Valdemar.robledaID, arrival: TilePoint(43, 2)),
            AreaExit(id: "town.norte", tiles: [TilePoint(3, 0), TilePoint(4, 0), TilePoint(5, 0)],
                     toArea: Valdemar.pasoID, arrival: TilePoint(23, 29),
                     lock: .questDone("valdemar.paso_norte"),
                     lockedMessage: "El Paso del Norte está cerrado. Primero, el castillo; luego, habla con el herrero."),
        ],
        dungeonEntrances: [
            // Calabozos del castillo (opcional): bajada en el patio, con el castillo abierto.
            DungeonEntrance(dungeonID: "valdemar.calabozos", tiles: [TilePoint(34, 7)], lock: .castleOpen,
                            lockedMessage: "Una reja oxidada cierra los calabozos. Primero, el castillo."),
        ]
    )

    /// NPC de la calle (no se rescatan aquí): el Capitán de la guardia, que aparece al liberar el pueblo, y los
    /// aldeanos, que salen junto a su puerta tras su rescate (mismo id que en su casa: así una misión tiene un solo
    /// `giverID`). Textos de `assets/story/valdemar.md` §3-4 (`npc.<id>.calle.*`); las misiones van en `ValdemarQuests`.
    /// `talk`: vale la primera línea que se cumple; `thanks` es la frase de reserva si no se cumple ninguna.
    static let streetNPCs: [NPC] = [
        NPC(id: "capitanGuardia", name: "Capitán Rodrigo Vela", look: "guardCaptain", role: .questGiver,
            position: TilePoint(18, 13),
            plea: "Guardia de Valdehierro. Lo que queda de ella.",
            thanks: ["Mis hombres guardan la escalinata. Lo de fuera es cosa tuya."],
            reward: Reward(), appearsWhen: .questDone("valdemar.liberar"),
            talk: [
                // `npc.capitanGuardia.calle.epilogo`
                NPCLine(when: [.questDone("valdemar.paso_norte")],
                        ["Si subes al norte, vigila tu espalda. Lo que huyó por el Paso no iba de paseo."]),
                // `npc.capitanGuardia.calle.libre`
                NPCLine(when: [.questDone("valdemar.rey_goblin")],
                        ["El castillo vuelve a ser nuestro. Ve a la forja: el herrero lleva toda la mañana mirando al norte."]),
                // `npc.capitanGuardia.falta_abadia`
                NPCLine(when: [.questDone("valdemar.pedregal")], unless: [.questDone("valdemar.abadia")],
                        ["El Pedregal ya es nuestro. Falta la abadía: Fray Anselmo sabe de muertos más que yo."]),
                // `npc.capitanGuardia.falta_pedregal`
                NPCLine(when: [.questDone("valdemar.abadia")], unless: [.questDone("valdemar.pedregal")],
                        ["La abadía ya descansa. Faltan los orcos del Pedregal. Sin eso, nadie sube."]),
            ]),
        street("marta", "Marta, la panadera", look: "baker", at: TilePoint(6, 17),
               ["¿Pan? Recién hecho. Bueno, recién rescatado del horno. ¡Quedan vecinos encerrados!"],
               talk: [
                   NPCLine(when: [.questDone("valdemar.rey_goblin")],
                           ["¡Pan de fiesta para el héroe! Con pasas. No te acostumbres."]),
                   NPCLine(when: [.questDone("valdemar.liberar")],
                           ["El Capitán Vela me compra pan para sus hombres. Paga tarde, pero paga.",
                            "Los zombis de los huertos huelen peor que mi masa madre. Y mira que es vieja."]),
               ]),
        street("elena", "Elena, la tejedora", look: "weaver", at: TilePoint(12, 17),
               ["Botas nuevas, unos bandidos… Alguien les paga, y pienso saber quién."],
               talk: [
                   NPCLine(when: [.questDone("valdemar.rey_goblin")],
                           ["Voy a tejer un tapiz de tu hazaña. Te he puesto un poco más alto."]),
                   NPCLine(when: [.questDone("valdemar.alcalde")],
                           ["¿Fausto? Fue padrino de mi hija. Le tejí yo la capa con la que ha huido.",
                            "Fray Anselmo conocía al abad de Valsombra. Habla con él."]),
               ]),
        street("tomas", "Tomás, el molinero", look: "miller", at: TilePoint(6, 24),
               ["Mi molino de los huertos… y ahora dicen que duerme un ogro dentro."],
               talk: [
                   NPCLine(when: [.questDone("valdemar.rey_goblin")],
                           ["He puesto tu nombre a una espiga. Es una espiga preciosa."]),
                   NPCLine(when: [.questDone("valdemar.molino")],
                           ["En primavera vuelvo a sembrar. Si los muertos me dejan."]),
               ]),
        street("anselmo", "Fray Anselmo", look: "monk", at: TilePoint(12, 24),
               ["Rezo por los vivos y vigilo a los muertos. Últimamente, más lo segundo."],
               talk: [
                   NPCLine(when: [.questDone("valdemar.abadia")],
                           ["Cada noche bajo a rezar junto al Ascua. Nadie más le pondrá la mano encima."]),
                   NPCLine(unless: [.questDone("valdemar.alcalde")],
                           ["El abad Morcar murió hace un año. Lo enterré yo mismo. Que en paz descanse… espero."]),
               ]),
        street("bruno", "Bruno, el posadero", look: "innkeeper", at: TilePoint(35, 17),
               ["¡Quedan goblins sueltos! Cuando acabes, la cerveza estará fresquita."],
               talk: [
                   NPCLine(when: [.questDone("valdemar.rey_goblin")],
                           ["¡La Posada del Jabalí invita a todo el pueblo! A la primera ronda, ¿eh?"]),
                   NPCLine(when: [.questDone("valdemar.liberar")],
                           ["En el Pedregal hay orcos que no beben. ¡Desconfía siempre de quien no bebe!"]),
               ]),
        street("iris", "Iris, la alquimista", look: "alchemist", at: TilePoint(34, 24),
               ["Mientras queden goblins en el pueblo, mis matraces no salen de casa."],
               talk: [
                   NPCLine(when: [.questDone("valdemar.rey_goblin")],
                           ["Por fin hay paz. Ya puedo hacer explotar cosas a propósito."]),
                   NPCLine(when: [.questDone("valdemar.liberar")],
                           ["¿Te ha rozado una esfera violeta? Magia del Eclipse. No la lamas."]),
               ]),
    ]

    /// Aldeano rescatado que ya está en la calle (aparece tras su rescate; no da recompensa otra vez).
    /// `lines` = frase de reserva (etapa `pueblo`); `talk` = frases por momento de la historia.
    private static func street(_ id: String, _ name: String, look: String, at position: TilePoint,
                               _ lines: [String], talk: [NPCLine] = []) -> NPC {
        NPC(id: id, name: name, look: look, role: .villager, position: position, plea: lines[0], thanks: lines,
            reward: Reward(), appearsWhen: .rescued(id), talk: talk)
    }

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
                          "La puerta sur estaba abierta. ¡Abierta! Y el cerrojo, sin forzar.",
                          "Toma, es todo lo que he podido ahorrar."],
                 reward: Reward(gold: 25, minerals: [.copper: 3, .iron: 1]),
                 talk: [NPCLine(["Si ves otra rata, no me lo cuentes. Mátala y ya."])])),

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
                          "Y alguien les paga bien: llevaban botas nuevas. ¡Botas nuevas, unos bandidos!",
                          "Dicen que el Rey tiene a la princesa encerrada en el salón del trono."],
                 reward: Reward(gold: 30, minerals: [.silver: 2, .copper: 1]),
                 talk: [NPCLine(["Aquí sigo, cosiendo. Con las telas que me dejaron, al menos."])])),

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
                 thanks: ["La bruja del pozo hechizó a mi espantapájaros. ¡Con lo majo que era! Hasta le puse sombrero.",
                          "Llévate esto. A mí ya no me sirve de nada."],
                 reward: Reward(gold: 35, minerals: [.copper: 3, .emerald: 1]),
                 talk: [NPCLine(["Si un espantapájaros te mira raro, esta vez no es cosa mía."])])),

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
                 thanks: ["Bendito seas. Sin luna, los muertos no descansan: mira mi pobre cementerio.",
                          "En la abadía de Valsombra, al este, pasa algo peor. Desde que murió el abad, nadie va.",
                          "Esta reliquia te protegerá. Que la Luna de Plata guíe tu acero."],
                 reward: Reward(gold: 40, minerals: [.silver: 2, .emerald: 1], partID: "head.mace.iron"),
                 talk: [NPCLine(["Rezo por los vivos y vigilo a los muertos. Últimamente, más lo segundo."])])),

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
                 reward: Reward(gold: 45, minerals: [.gold: 1, .iron: 2]),
                 talk: [NPCLine(["¡Siéntate, forastero! La primera jarra corre de mi cuenta. La segunda, también."])])),

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
                 thanks: ["La bruja del pozo no trabajaba sola. La visitaba un encapuchado de túnica gris.",
                          "El Capitán de la guardia sigue vivo, escondido. Saldrá cuando el pueblo esté libre.",
                          "Toma estos cristales: tienen magia dentro."],
                 reward: Reward(gold: 50, minerals: [.emerald: 1, .silver: 1]),
                 talk: [NPCLine(["No toques nada de esa mesa. Ni de esa. Bueno, de ninguna."])])),

        interior("mayor", "Casa del alcalde", level: 7, rows: [
            "XXXXXXXXXXXXXX",
            "XsssssXXsssssX",
            "X____________X",
            "X_rrrrrr__tt_X",
            "X_rrrrrr_____X",
            "X_rrrrrr__zz_X",
            "X_o_______zz_X",
            "X____________X",
            "XXXXXXDXXXXXXX",
        ], spawns: [("cultist", 3, 4), ("eclipseAcolyte", 9, 2), ("cultist", 4, 6), ("eclipseAcolyte", 6, 4)],
        // No es un aldeano: la carta se lee con la sala despejada (completa `valdemar.alcalde`).
        // `npc.cartaAlcalde.leer` (`valdemar.md` §6): la recibió Fausto y la firma «M.» (el abad Morcar).
        npc: NPC(id: "cartaAlcalde", name: "Carta del alcalde", look: "letter", role: .clue, position: TilePoint(12, 2),
                 plea: "Una carta a medio quemar, con lacre negro.",
                 thanks: ["Media carta chamuscada. Lacre negro con una luna apagada.",
                          "«Fausto: la noche sin luna, deja abierta la puerta sur. Los goblins harán el resto.»",
                          "«Tu oro y tu sitio en la Orden te esperan. El Abad cumple lo que promete. — M.»",
                          "¿M.? El único abad de la comarca era Morcar, el de Valsombra. Y murió hace un año."],
                 reward: Reward(),
                 // `npc.cartaAlcalde.otra_vez`: al volver a leerla (`PlayerProfile.clueLines`).
                 talk: [NPCLine(["«…El Abad cumple lo que promete. — M.»"])])),

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
                 plea: "¡Cuidado, héroe! El Rey Goblin no es más que el perro del Eclipse… pero muerde.",
                 thanks: ["¡Has vencido al Rey Goblin! Valdehierro vuelve a ser libre.",
                          "No querían mi castillo. Querían esto: la Hoja del Alba. Mi familia la ha guardado siglos.",
                          "La Luna se apaga y el Eclipse quiere apagarla del todo. Esta hoja es lo único que lo frena.",
                          "Llévala al ritual de forja. Solo un héroe puede despertarla."],
                 reward: Reward(gold: 200, minerals: [.gold: 2, .emerald: 2], partID: "legend.dawn"),
                 talk: [
                     NPCLine(when: [.questDone("valdemar.paso_norte")],
                             ["La Alianza del Alba debe renacer. Empezaré escribiendo a Hondoyunque."]),
                     NPCLine(["Valdehierro te debe todo, héroe."]),
                 ])),
    ]

    private static func interior(_ id: String, _ name: String, level: Int, rows: [String],
                                 spawns: [(String, Int, Int)], npc: NPC) -> AreaMap {
        let door = rows.last.flatMap { $0.firstIndex(of: "D") }.map { rows.last!.distance(from: rows.last!.startIndex, to: $0) } ?? 1
        return AreaMap(
            id: id, name: name, rows: rows, buildings: [], zones: [],
            spawns: spawns.enumerated().map { i, s in Spawn(id: "\(id).\(i + 1)", enemyID: s.0, position: TilePoint(s.1, s.2)) },
            npcs: [npc], level: level, entry: TilePoint(door, rows.count - 2),
            kind: .interior
        )
    }

    public static func area(_ id: String) -> AreaMap? {
        id == townID ? town : interiors.first { $0.id == id }
    }

    /// El pueblo y sus interiores (se registran en `World.areas`).
    public static var areas: [AreaMap] { [town] + interiors }

    public static var villagerIDs: Set<String> {
        Set(interiors.flatMap(\.npcs).filter { $0.role == .villager }.map(\.id))
    }

    /// Edificio del pueblo que lleva a un interior.
    public static func building(leadingTo interiorID: String) -> Building? {
        town.buildings.first { $0.interiorID == interiorID }
    }
}
