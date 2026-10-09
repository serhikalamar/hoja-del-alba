import Foundation

// MARK: - Mazmorra de la arena

/// Casillas de la mazmorra. Los pisos se escriben como texto: un carácter por casilla de 24 px.
/// Leyenda completa y reglas en `assets/maps/mazmorra.md`.
public enum DungeonTile: Character, CaseIterable, Sendable {
    // Paredes (sólidas). Una pared con suelo debajo se ve de frente (muro de ladrillo).
    case wall = "#"
    /// Pared con antorcha (luz).
    case torch = "t"
    /// Puerta de monstruos en la pared: los enemigos salen por la casilla pisable de al lado.
    case gate = "G"
    /// Gran puerta del jefe (2-3 casillas seguidas en la pared).
    case bossGate = "B"
    /// Rejas de celda en la pared (decoración).
    case bars = "k"

    // Suelo (pisable)
    case floor = "."
    /// Suelo agrietado / con escombros o musgo (decoración).
    case rubble = ","
    /// Huesos, cadenas o restos por el suelo (decoración).
    case bones = "b"
    /// Alfombra o camino ceremonial.
    case carpet = "r"
    /// Puente sobre el líquido.
    case bridge = "="
    /// Rejilla del suelo: también salen monstruos de aquí.
    case grate = "h"

    // Obstáculos (sólidos)
    /// Agua, lava, abismo… según el tema del piso.
    case liquid = "~"
    case pillar = "I"
    case statue = "s"
    /// Brasero encendido (luz).
    case brazier = "x"
    /// Cajas y barriles.
    case crates = "c"
    /// Cofre.
    case chest = "C"
    /// Altar (bloque 2×1).
    case altar = "A"

    public var isSolid: Bool {
        switch self {
        case .floor, .rubble, .bones, .carpet, .bridge, .grate: false
        default: true
        }
    }

    /// Partes del muro (se dibujan como pared).
    public var isWall: Bool {
        switch self {
        case .wall, .torch, .gate, .bossGate, .bars: true
        default: false
        }
    }

    /// Da luz (antorchas, braseros).
    public var isLight: Bool { self == .torch || self == .brazier }
}

/// Ambientación de un piso: decide colores, el líquido y la decoración.
public enum DungeonTheme: String, CaseIterable, Sendable {
    /// Calabozos del castillo: piedra gris, celdas, agua sucia.
    case prison
    /// Cripta: losas, sarcófagos, velas, abismo.
    case crypt
    /// Cloacas: ladrillo con musgo, canales de agua verde.
    case sewer
    /// Mina de cristal: roca, vías, cristales que brillan, abismo.
    case mine
    /// Forja de lava: roca volcánica, ríos de lava, rejas.
    case forge
}

/// Un piso de la mazmorra de la arena.
public struct DungeonFloor: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let theme: DungeonTheme
    public let rows: [String]
    /// Donde aparece el héroe al llegar al piso.
    public let start: TilePoint

    public init(id: String, name: String, theme: DungeonTheme, start: TilePoint, rows: [String]) {
        self.id = id
        self.name = name
        self.theme = theme
        self.start = start
        self.rows = rows
    }

    public var width: Int { rows.map(\.count).max() ?? 0 }
    public var height: Int { rows.count }

    /// Fuera del mapa cuenta como pared.
    public func tile(_ x: Int, _ y: Int) -> DungeonTile {
        guard y >= 0, y < rows.count else { return .wall }
        let row = Array(rows[y])
        guard x >= 0, x < row.count else { return .wall }
        return DungeonTile(rawValue: row[x]) ?? .floor
    }

    public func tile(_ p: TilePoint) -> DungeonTile { tile(p.x, p.y) }

    public func isWalkable(_ p: TilePoint) -> Bool { !tile(p).isSolid }

    private func points(where match: (DungeonTile) -> Bool) -> [TilePoint] {
        rows.enumerated().flatMap { y, row in
            row.enumerated().compactMap { x, c in
                DungeonTile(rawValue: c).map(match) == true ? TilePoint(x, y) : nil
            }
        }
    }

    /// Casilla pisable junto a una puerta (primero la de abajo).
    private func exit(of p: TilePoint) -> TilePoint? {
        [TilePoint(p.x, p.y + 1), TilePoint(p.x - 1, p.y), TilePoint(p.x + 1, p.y), TilePoint(p.x, p.y - 1)]
            .first(where: isWalkable)
    }

    /// Puntos por donde entran los monstruos: delante de cada puerta y sobre cada rejilla.
    public var spawnPoints: [TilePoint] {
        points { $0 == .gate }.compactMap(exit(of:)) + points { $0 == .grate }
    }

    /// Por donde entra el jefe: delante de la casilla central de la gran puerta.
    public var bossSpawn: TilePoint {
        let gate = points { $0 == .bossGate }
        guard !gate.isEmpty else { return spawnPoints.first ?? start }
        return exit(of: gate[gate.count / 2]) ?? start
    }

    /// Casillas pisables conectadas con la salida del héroe.
    public func reachable(from origin: TilePoint? = nil) -> Set<TilePoint> {
        let first = origin ?? start
        guard isWalkable(first) else { return [] }
        var seen: Set<TilePoint> = [first]
        var queue = [first]
        while let p = queue.popLast() {
            for n in [TilePoint(p.x + 1, p.y), TilePoint(p.x - 1, p.y), TilePoint(p.x, p.y + 1), TilePoint(p.x, p.y - 1)]
            where isWalkable(n) && !seen.contains(n) {
                seen.insert(n)
                queue.append(n)
            }
        }
        return seen
    }

    public var walkableTiles: [TilePoint] { points { !$0.isSolid } }
}

/// Los pisos de la mazmorra, de arriba abajo. Cada 5 oleadas se baja uno (y al acabar, se vuelve a empezar).
public enum Dungeon {
    public static let floors: [DungeonFloor] = [prison, crypt, sewer, mine, forge]

    public static func floor(_ id: String) -> DungeonFloor? { floors.first { $0.id == id } }

    // Calabozos del castillo: galería de celdas arriba (jefe por el centro); abajo, sala de guardia,
    // sala de tortura con braseros y aljibe de agua sucia.
    static let prison = DungeonFloor(id: "prison", name: "Calabozos del castillo", theme: .prison,
                                     start: TilePoint(21, 15), rows: prisonRows)
    private static let prisonRows = [
        "############################################",
        "#t#kGk#t#kkk#t#G##t#BBB##t##G#t#kkk#t#kGk#t#",
        "#..b......b......................b....b....#",
        "#....,..............,........,.............#",
        "#................x.......x.................#",
        "#.....I.....I.......b..........I.....I.....#",
        "#..b.................................,.....#",
        "#........h.......................h.........#",
        "#....b...........,..........b..........,...#",
        "####....###########......##########....#####",
        "#t##....#G#t##kkk#t......t#kkk##tG#....#t###",
        "#...........c#b..........,....#..b.........#",
        "#..b........c#................#.........b..#",
        "#....cc......#...x........x...#....h.......#",
        "#.,........................................#",
        "#.........b....,.......................,~~~#",
        "#..h................bb.b....,........,~~~~~#",
        "#.....x...............b.............,~~~~~~#",
        "#.........,..#...x........x...#....,~~~~~~~#",
        "#c.......b...#................#c...,~~~~~~~#",
        "#cc...C......#.....,........b.#cc..,~~~~~~~#",
        "############################################",
    ]

    // Cripta de los reyes: nave con alfombra hasta el altar (el jefe sale detrás), abismo con dos puentes
    // al oeste y tres capillas encadenadas al este.
    static let crypt = DungeonFloor(id: "crypt", name: "Cripta de los reyes", theme: .crypt,
                                    start: TilePoint(22, 18), rows: cryptRows)
    private static let cryptRows = [
        "############################################",
        "#t##G##t##Gkkt####t#BBB##t####t##kk#t##G##t#",
        "#..............................#..........C#",
        "#.....,..h.....................#.b.........#",
        "#..b..........x...........,.x..............#",
        "#.................s..AA..s.........s....x..#",
        "#....~~~~~...........rr....................#",
        "#...~~~~~~~.b........rr......,.#...........#",
        "#,..~~~~~~~..........rr........########....#",
        "#...=======.....I....rr....I...##t#kGk#....#",
        "#...=======..........rr........#...........#",
        "#...=======..........rr.b..................#",
        "#.h.~~~~~~~........,.rr...........s..s..s..#",
        "#...~~~~~~~.....I....rr....I...............#",
        "#....~~~~~~..........rr..............b...h.#",
        "#...=======...b......rr........#...........#",
        "#...=======..........rr..,.....########....#",
        "#...=======.....I....rr....I...##k#t#G#....#",
        "#...~~~~~~~..........rr........#...........#",
        "#....~~~~~..,........rr...............h....#",
        "#..................x.rr.x..........x.......#",
        "#.h..........b.......rr......b.........,..c#",
        "#....................rr..................cc#",
        "############################################",
    ]

    // Cloacas inundadas: canal principal de este a oeste con tres puentes anchos, canal norte que nace
    // del desagüe y canal sur hacia el sumidero; andenes con musgo y rejillas.
    static let sewer = DungeonFloor(id: "sewer", name: "Cloacas inundadas", theme: .sewer,
                                    start: TilePoint(22, 16), rows: sewerRows)
    private static let sewerRows = [
        "##############################################",
        "#t##G##t##G#t#kkk#t##G##t#BBB#t##G##t###G##t##",
        "#cc...........~~~..........................cc#",
        "#c.........h..~~~.............b.............c#",
        "#....b........~~~............................#",
        "#.......x.....===......................x.....#",
        "#.............===.....I..........I...........#",
        "#..b..........===..b......................h..#",
        "#.............~~~............................#",
        "#~~~..,..,..,.~~~.,..,..,..~~~,..,..,..,..,..#",
        "#~~~~~====~~~~~~~~~~~====~~~~~~~~~~~====~~~~~#",
        "#~~~~~====~~~~~~~~~~~====~~~~~~~~~~~====~~~~~#",
        "#~~~~~====~~~~~~~~~~~====~~~~~~~~~~~====~~~~~#",
        "#.,..,..,..,..,..,..,..,.~~~.,~~~..,..,..,~~~#",
        "#.............................~~~............#",
        "#.............................~~~........b...#",
        "#...h...I.....I.....x.........===............#",
        "#.........................I...===......x.....#",
        "#..........b..................===............#",
        "#c......................b.....~~~...h.......c#",
        "#cc.........h..............C..~~~..........cc#",
        "##############################################",
    ]

    // Mina de cristal: túnel norte, gran grieta central con dos puentes de madera, peñascos, pozo sin fondo
    // y caverna sur con vagonetas y cajas.
    static let mine = DungeonFloor(id: "mine", name: "Mina de cristal", theme: .mine,
                                   start: TilePoint(22, 19), rows: mineRows)
    private static let mineRows = [
        "############################################",
        "###tG##t##G##t######t#BBB##t##G##t###G#t####",
        "###............####cc....cc.............####",
        "#t#.........,..#G#t.b...................####",
        "#............................b..........#t##",
        "#........I...........x....................##",
        "#.....b....................I......I....,...#",
        "###..............,......h..................#",
        "###...........b.......................x....#",
        "###........,.....===~....................###",
        "#..............~~===~~~~...===~..b.......###",
        "#.....###.....~~~===~~~~~~~===~~.........###",
        "#....#####....~~~===~~~~~~~===~~....,......#",
        "#....#####....~~~===~~~~~~~===~~........h..#",
        "#..h..###.......~===~~~~~~~===.....###.....#",
        "#....,................~~~~....,...#####....#",
        "#...............,.................#####....#",
        "#....~~~....x..........b.......x...###.....#",
        "#...~~~~~..................................#",
        "#...~~~~~..................................#",
        "#....~~~..h..###.........,........h...b....#",
        "#c..........#####.............###.........c#",
        "#cc.....b...#####...cc...C....###........cc#",
        "############################################",
    ]

    // Forja de lava: dos ríos de lava de norte a sur con tres puentes cada uno; sala del trono del jefe
    // arriba, forja central con yunques y crisol, fundición al oeste y armería al este.
    static let forge = DungeonFloor(id: "forge", name: "Forja de lava", theme: .forge,
                                    start: TilePoint(23, 20), rows: forgeRows)
    private static let forgeRows = [
        "##############################################",
        "##t##G##t##kkk#t####t#BBB#t####tkkk##t##G##t##",
        "#cc........~~~.....s.......s....~~~........cc#",
        "#c......b..~~~.h................~~~.........c#",
        "#.....x....===..................===...AA.b...#",
        "#..........===...I.....x.....I..===..........#",
        "#...,......===............,.....===.,........#",
        "#..........~~~.....,............~~~......,...#",
        "###....####~~~....##########....~~~####....###",
        "#t#....#tG#~~~....t#kGk#kGkt....~~~#Gt#....t##",
        "#...b......~~~.,................~~~..........#",
        "#..........~~~................,.===......h...#",
        "#..h.......===...........,......===..,.......#",
        "#........,.===..AA..........AA..===..........#",
        "#..........===..................~~~...AA.....#",
        "#..........~~~......x~~~~.......~~~..........#",
        "#....x.....~~~...b...~~~~x......~~~.......x..#",
        "#..........~~~................b.===..........#",
        "#..,.......===..................===.h........#",
        "#......h...===..AA..........AA..===..........#",
        "#..........===..........b.......~~~...AA..,..#",
        "#c.........~~~......,...........~~~.........c#",
        "#cc.......C~~~..................~~~.....b..cc#",
        "##############################################",
    ]
}
