import Foundation

// MARK: - Misiones (datos)
//
// Los tipos de las misiones. El motor (aceptar, contar, entregar, "!"/"?") está en `QuestEngine.swift`.
// Las misiones de Valdemar viven como datos en `ValdemarQuests.swift`.

/// Un hecho de la historia que se puede comprobar con el perfil guardado.
public enum StoryCondition: Hashable, Sendable {
    /// La misión (id) está completada.
    case questDone(String)
    /// El aldeano (id de `NPC`) está rescatado.
    case rescued(String)
    /// La zona (id de `Zone`, en cualquier área) está liberada.
    case zoneLiberated(String)
}

/// Un objetivo de misión. Cuentan todos a la vez, salvo `talk` y `read`, que solo cuentan cuando los anteriores
/// ya están cumplidos (así "mata 8 bandidos y vuelve a hablar con Elena" no se cumple hablando antes).
public enum QuestObjective: Hashable, Sendable {
    /// Rescatar a estos aldeanos (ids de `NPC`).
    case rescue([String])
    /// Matar `count` monstruos de estos tipos después de aceptar la misión, en esa área (nil = cualquier área
    /// del continente).
    case kill(enemyIDs: [String], count: Int, areaID: String?)
    /// Derrotar a un jefe (cuenta aunque muriera antes de aceptar la misión).
    case defeat(enemyID: String)
    /// Hablar con un NPC.
    case talk(npcID: String)
    /// Leer un objeto (NPC con rol `clue`: carta, cartel).
    case read(npcID: String)
    /// Despejar todos los monstruos de un área (un interior, p. ej. `mayor`).
    case clear(areaID: String)
    /// Ganar una mazmorra de historia (id de `StoryDungeon`).
    case dungeon(String)
    /// Llegar a un área.
    case reach(areaID: String)
}

/// Lo que da una misión al entregarla.
public struct QuestReward: Hashable, Sendable {
    public var xp: Int
    public var gold: Int
    public var minerals: [Mineral: Int]
    /// Pieza de arma (id de `PartCatalog`).
    public var partID: String?
    /// Pieza de equipo o armadura (id de catálogo), si la hay.
    public var gearID: String?

    public init(xp: Int = 0, gold: Int = 0, minerals: [Mineral: Int] = [:], partID: String? = nil, gearID: String? = nil) {
        self.xp = xp
        self.gold = gold
        self.minerals = minerals
        self.partID = partID
        self.gearID = gearID
    }
}

/// Una misión. Id estable `<continente>.<nombre>` (`valdemar.molino`): se guarda en el perfil, no se renombra.
public struct Quest: Identifiable, Sendable {
    public let id: String
    /// Quién la da (id de `NPC`; el enano herrero es `smithy`).
    public let giverID: String
    public let title: String
    /// Texto del diario (una línea).
    public let summary: String
    /// Todas deben cumplirse para que se ofrezca ("!" sobre el NPC).
    public let requires: [StoryCondition]
    public let objectives: [QuestObjective]
    public let reward: QuestReward
    /// Se acepta sola al cumplirse los requisitos (`valdemar.liberar`).
    public let autoAccept: Bool
    /// Se entrega sola al cumplir el último objetivo, sin volver a hablar con quien la dio
    /// (`valdemar.alcalde`, `valdemar.rey_goblin`, `valdemar.paso_norte`).
    public let completesOnLastObjective: Bool
    /// Lo que dice quien la da al ofrecerla (vacío = se usa `summary`). Textos: `assets/story/valdemar.md` §5.
    public let offer: [String]
    /// Lo que dice si se vuelve a hablar con él antes de terminarla (nil = una frase genérica).
    public let reminder: String?
    /// Lo que dice al entregarla (vacío = solo el aviso "Misión cumplida").
    public let turnIn: [String]
    /// Objetivo corto del HUD y del diario, uno por objetivo en el mismo orden (`{n}` = progreso).
    /// Vacío o más corto = se genera un texto con los nombres de monstruos, NPC y áreas.
    public let objectiveLabels: [String]

    public init(id: String, giverID: String, title: String, summary: String, requires: [StoryCondition] = [],
                objectives: [QuestObjective], reward: QuestReward, autoAccept: Bool = false,
                completesOnLastObjective: Bool = false, objectiveLabels: [String] = [], offer: [String] = [],
                reminder: String? = nil, turnIn: [String] = []) {
        self.id = id
        self.giverID = giverID
        self.title = title
        self.summary = summary
        self.requires = requires
        self.objectives = objectives
        self.reward = reward
        self.autoAccept = autoAccept
        self.completesOnLastObjective = completesOnLastObjective
        self.objectiveLabels = objectiveLabels
        self.offer = offer
        self.reminder = reminder
        self.turnIn = turnIn
    }

    /// Ids de monstruo que la misión menciona (para comprobar que existen).
    public var enemyIDs: [String] {
        objectives.flatMap { objective -> [String] in
            switch objective {
            case .kill(let ids, _, _): ids
            case .defeat(let id): [id]
            default: []
            }
        }
    }

    /// Ids de área que la misión menciona.
    public var areaIDs: [String] {
        objectives.compactMap { objective -> String? in
            switch objective {
            case .kill(_, _, let area): area
            case .clear(let area), .reach(let area): area
            default: nil
            }
        }
    }
}

/// Estado guardado de una misión en el perfil (`PlayerProfile.quests`).
public struct QuestState: Codable, Equatable, Sendable {
    /// Aceptada (está en el diario).
    public var accepted: Bool
    /// Progreso de cada objetivo, en el mismo orden que `Quest.objectives` (muertes contadas, 0/1…).
    public var progress: [Int]
    /// Entregada.
    public var done: Bool

    public init(accepted: Bool = false, progress: [Int] = [], done: Bool = false) {
        self.accepted = accepted
        self.progress = progress
        self.done = done
    }
}
