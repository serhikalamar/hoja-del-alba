import Foundation

// MARK: - Mazmorras de historia (M8)
//
// Partida corta en un piso de la arena (`Dungeon.floors`) con oleadas fijas y nivel fijo, con el personaje de
// verdad (no es roguelike), sin forja entre oleadas. Se entra por una `e`; al ganar se vuelve a ella y cuenta para
// las misiones `dungeon(id)`; al perder, al punto seguro del área. La partida la lleva `BattleSession` (modo historia).

public struct StoryDungeon: Identifiable, Sendable {
    /// Id estable (`valdemar.cripta`): lo usan las misiones `dungeon(id)` y `DungeonEntrance`.
    public let id: String
    public let name: String
    /// Piso de la arena donde se juega (id de `DungeonFloor`: `crypt`, `prison`…).
    public let floorID: String
    /// Nivel fijo de los monstruos.
    public let level: Int
    /// Oleadas en orden: id de monstruo → cuántos.
    public let waves: [[String: Int]]
    /// Jefe al final (sale por la `BBB`), nil = sin jefe.
    public let bossID: String?
    /// Escolta que sale con el jefe.
    public let bossEscort: [String: Int]
    /// Se puede volver a jugar después de ganarla.
    public let repeatable: Bool
    /// Área donde está la bajada `e` (allí se vuelve al ganar y allí está el punto seguro al perder).
    public let entranceAreaID: String
    /// Diálogo antes de abrir la `BBB` del jefe (lo escribe el story-writer).
    public let bossIntro: [String]
    /// Premio fijo al ganar (los porcentajes los decide el balance-designer en la fase 3).
    public let reward: Reward?
    /// Diálogo antes del jefe al repetir la mazmorra (vacío = el mismo `bossIntro`).
    public let bossIntroRepeat: [String]
    /// Lo que se dice al caer el jefe la primera vez (`boss.abbot.derrota`): la primera línea la dice el jefe
    /// (`bossSpeakerName`); las demás, el narrador.
    public let bossDefeat: [String]
    /// Quién habla en la presentación, la repetición y la derrota del jefe («Abad Morcar»).
    /// nil = el nombre del bestiario («Abad no-muerto»).
    public let bossSpeaker: String?

    public init(id: String, name: String, floorID: String, level: Int, waves: [[String: Int]], bossID: String? = nil,
                bossEscort: [String: Int] = [:], repeatable: Bool = true, entranceAreaID: String,
                bossIntro: [String] = [], reward: Reward? = nil, bossIntroRepeat: [String] = [],
                bossDefeat: [String] = [], bossSpeaker: String? = nil) {
        self.id = id
        self.name = name
        self.floorID = floorID
        self.level = level
        self.waves = waves
        self.bossID = bossID
        self.bossEscort = bossEscort
        self.repeatable = repeatable
        self.entranceAreaID = entranceAreaID
        self.bossIntro = bossIntro
        self.reward = reward
        self.bossIntroRepeat = bossIntroRepeat
        self.bossDefeat = bossDefeat
        self.bossSpeaker = bossSpeaker
    }

    /// Todos los ids de monstruo que aparecen (oleadas, jefe y escolta).
    public var enemyIDs: Set<String> {
        var ids = Set(waves.flatMap(\.keys)).union(bossEscort.keys)
        if let bossID { ids.insert(bossID) }
        return ids
    }
}

extension StoryDungeon {
    /// Probabilidad de que el jefe suelte su pieza única al repetir la mazmorra (la primera vez, segura).
    /// La ajusta el balance-designer.
    public static let repeatPartChance = 0.25

    /// Segundos entre apariciones de monstruos.
    public static let spawnInterval = 0.9

    /// Piso de la arena donde se juega.
    public var floor: DungeonFloor? { Dungeon.floor(floorID) }

    /// Oleadas en total (las normales + la del jefe, si lo hay).
    public var totalWaves: Int { waves.count + (bossID == nil ? 0 : 1) }

    /// ¿La oleada `n` (1…) es la del jefe?
    public func isBossWave(_ n: Int) -> Bool { bossID != nil && n == totalWaves }

    /// Oleada `n` (1…): las de la lista y, al final, el jefe con su escolta (el jefe sale el último, por la `BBB`).
    public func wave(_ n: Int) -> Wave {
        if isBossWave(n), let bossID {
            var spawns = bossEscort
            spawns[bossID, default: 0] += 1
            return Wave(spawns: spawns, spawnInterval: Self.spawnInterval)
        }
        let index = min(max(1, n), max(1, waves.count)) - 1
        return Wave(spawns: waves.isEmpty ? [:] : waves[index], spawnInterval: Self.spawnInterval)
    }

    /// Nombre del que habla por el jefe: `bossSpeaker` o, si no hay, el del bestiario (o el de la mazmorra).
    public var bossSpeakerName: String {
        bossSpeaker ?? bossID.flatMap(Bestiary.enemy)?.name ?? name
    }

    /// Diálogo antes del jefe: entero la primera vez; al repetir la mazmorra ya ganada, `bossIntroRepeat` (si lo hay).
    public func bossIntroLines(firstWin: Bool) -> [String] {
        firstWin || bossIntroRepeat.isEmpty ? bossIntro : bossIntroRepeat
    }

    /// Texto de la derrota del jefe (bajo el aviso de victoria): la primera línea, con el nombre del que habla;
    /// las demás, tal cual (narración).
    public var bossDefeatText: String? {
        guard let first = bossDefeat.first else { return nil }
        return (["\(bossSpeakerName): «\(first)»"] + bossDefeat.dropFirst()).joined(separator: "\n")
    }

    /// ¿Suelta el jefe su pieza? Siempre la primera vez; después, con `repeatPartChance`.
    public func bossDropsPart<G: RandomNumberGenerator>(firstWin: Bool, using rng: inout G) -> Bool {
        firstWin || Double.random(in: 0..<1, using: &rng) < Self.repeatPartChance
    }
}
