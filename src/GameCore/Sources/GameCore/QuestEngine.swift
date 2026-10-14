import Foundation

// MARK: - Motor de misiones (fase 1, M3)
//
// Reglas (historia.md §4):
// - Una misión se ofrece ("!") cuando se cumplen todos sus `requires`; se acepta hablando con quien la da
//   (o sola, si es `autoAccept`) y se entrega hablando con él otra vez ("?"), salvo `completesOnLastObjective`.
// - `kill` cuenta las muertes **después de aceptar** y solo en su área (nil = cualquiera).
// - `defeat`, `rescue`, `clear`, `dungeon` y `reach` se miran en el perfil: cuentan aunque se hicieran antes.
// - `talk` y `read` solo cuentan cuando los objetivos anteriores ya están cumplidos.

/// Algo que acaba de pasar en la partida y puede hacer avanzar una misión.
public enum QuestEvent: Hashable, Sendable {
    /// Monstruo muerto en un área (o en una mazmorra de historia: su id).
    case killed(enemyID: String, areaID: String)
    /// Conversación con un NPC (o con el herrero, `smithy`).
    case talked(npcID: String)
    /// Lectura de un objeto (NPC con rol `clue`).
    case read(npcID: String)
}

/// Icono sobre la cabeza de un NPC.
public enum QuestMarker: Equatable, Sendable {
    /// "!" amarillo: tiene una misión para ofrecer.
    case offer
    /// "?" amarillo: hay una misión que entregarle (o con la que hablar).
    case turnIn
}

/// Paso de una conversación con quien da misiones.
public enum QuestStep: Equatable, Sendable {
    case deliver(String)
    case offer(String)
    case remind(String)
}

/// Una misión entregada y lo que dio.
public struct QuestDelivery: Equatable, Sendable {
    public let questID: String
    public let xp: Int
    /// Oro ganado (con la bonificación de oro).
    public let gold: Int
    public let minerals: [Mineral: Int]
    public let partID: String?
    public let levelsGained: Int
}

/// Cambios en la historia tras un suceso (para avisar al jugador).
public struct StoryUpdate: Equatable, Sendable {
    /// Misiones aceptadas solas (`autoAccept`).
    public var accepted: [String] = []
    /// Misiones entregadas (solas o al hablar).
    public var delivered: [QuestDelivery] = []
    /// Misiones cuyo progreso ha cambiado.
    public var advanced: [String] = []

    public init() {}

    public var isEmpty: Bool { accepted.isEmpty && delivered.isEmpty && advanced.isEmpty }

    mutating func merge(_ other: StoryUpdate) {
        for id in other.accepted where !accepted.contains(id) { accepted.append(id) }
        delivered += other.delivered
        for id in other.advanced where !advanced.contains(id) { advanced.append(id) }
    }
}

/// Una línea del diario: objetivo, progreso y si está cumplido.
public struct QuestObjectiveLine: Equatable, Sendable {
    public let text: String
    public let progress: Int
    public let target: Int
    /// false si el texto ya lleva el contador dentro.
    public var showsCounter = true
    public var isDone: Bool { progress >= target }
    /// "4/6" (o vacío si el objetivo es de una sola vez o el texto ya lo lleva).
    public var counter: String { showsCounter && target > 1 ? "\(min(progress, target))/\(target)" : "" }
}

extension QuestObjective {
    /// Cuántas veces hay que cumplirlo.
    public var target: Int {
        switch self {
        case .rescue(let ids): ids.count
        case .kill(_, let count, _): max(1, count)
        default: 1
        }
    }

    /// `talk` y `read` esperan a que los objetivos anteriores estén cumplidos.
    var waitsForPrevious: Bool {
        switch self {
        case .talk, .read: true
        default: false
        }
    }
}

extension Quest {
    /// NPC que la misión menciona (quien la da y con quien hay que hablar, leer o rescatar).
    public var npcIDs: [String] {
        [giverID] + objectives.flatMap { objective -> [String] in
            switch objective {
            case .rescue(let ids): ids
            case .talk(let id), .read(let id): [id]
            default: []
            }
        }
    }

    /// Mazmorras de historia que la misión menciona.
    public var dungeonIDs: [String] {
        objectives.compactMap { if case .dungeon(let id) = $0 { id } else { nil } }
    }
}

extension World {
    /// Cualquier NPC del mundo por id (el primero que aparezca: un aldeano está en su casa y en la calle).
    public static func npc(_ id: String) -> NPC? {
        for area in areas { if let npc = area.npcs.first(where: { $0.id == id }) { return npc } }
        return nil
    }

    /// Nombre corto para los textos ("Elena, la tejedora" → "Elena").
    public static func npcShortName(_ id: String) -> String {
        if id == ValdemarQuests.smithID { return "el herrero" }
        guard let npc = npc(id) else { return id }
        return npc.name.components(separatedBy: ",").first ?? npc.name
    }

    /// Nombre de un área o de una mazmorra de historia.
    public static func placeName(_ id: String) -> String {
        area(id)?.name ?? storyDungeon(id)?.name ?? id
    }
}

// MARK: - Condiciones de la historia

extension PlayerProfile {
    /// ¿Se cumple este hecho de la historia?
    public func isMet(_ condition: StoryCondition) -> Bool {
        switch condition {
        case .questDone(let id): isQuestDone(id)
        case .rescued(let id): isRescued(id)
        case .zoneLiberated(let id): isZoneLiberated(id)
        }
    }

    public func isMet(_ conditions: [StoryCondition]) -> Bool { conditions.allSatisfy(isMet) }

    /// ¿Está rescatado este NPC? (la princesa tiene su propia marca).
    public func isRescued(_ npcID: String) -> Bool {
        if town.rescued.contains(npcID) { return true }
        return town.princessRescued && World.npc(npcID)?.role == .princess
    }

    /// ¿Está liberada la zona? En el pueblo e interiores, cuando no queda ningún monstruo; en el campo (donde
    /// reaparecen), si se liberó alguna vez.
    public func isZoneLiberated(_ zoneID: String) -> Bool {
        for area in World.areas {
            guard let zone = area.zones.first(where: { $0.id == zoneID }) else { continue }
            return isLiberated(zone, in: area)
        }
        return false
    }

    public func isLiberated(_ zone: Zone, in area: AreaMap) -> Bool {
        area.isField ? (town.fieldZonesLiberated?.contains(zone.id) ?? false) : town.isLiberated(zone, in: area)
    }

    /// Condición del castillo del continente (M4): sus misiones (en Valdemar, `liberar` + `abadia` + `pedregal`).
    /// Las partidas antiguas con la princesa ya rescatada lo tienen abierto.
    public func isCastleOpen(continentID: String = World.valdemarID) -> Bool {
        if town.princessRescued { return true }
        guard let continent = World.continent(continentID), !continent.castleRequires.isEmpty else { return false }
        return isMet(continent.castleRequires)
    }

    /// ¿Ha matado ya a este jefe en la historia? (spawn permanente muerto o jefe de una mazmorra ganada).
    /// No usa `defeatedBosses`, que también rellenaba la arena en versiones antiguas.
    public func hasDefeatedInStory(_ enemyID: String) -> Bool {
        let killed = town.killedSpawns
        for area in World.areas where area.spawns.contains(where: { $0.enemyID == enemyID && killed.contains($0.id) }) {
            return true
        }
        let won = wonDungeons ?? []
        return World.storyDungeons.contains { won.contains($0.id) && $0.bossID == enemyID }
    }
}

// MARK: - Misiones

extension PlayerProfile {
    /// Misiones que se pueden ofrecer ya (requisitos cumplidos, sin aceptar).
    public func isAvailable(_ quest: Quest) -> Bool {
        let state = questState(quest.id)
        return !state.accepted && !state.done && isMet(quest.requires)
    }

    public func isActive(_ quest: Quest) -> Bool {
        let state = questState(quest.id)
        return state.accepted && !state.done
    }

    /// Progreso de cada objetivo (guardado + lo que se mira en el perfil), sin pasar del objetivo.
    public func progress(of quest: Quest) -> [Int] {
        let stored = questState(quest.id).progress
        return quest.objectives.enumerated().map { i, objective in
            let saved = i < stored.count ? stored[i] : 0
            return min(objective.target, max(saved, derivedProgress(objective)))
        }
    }

    /// Lo que un objetivo ya tiene cumplido según el perfil (0 para los que solo cuentan sucesos).
    private func derivedProgress(_ objective: QuestObjective) -> Int {
        switch objective {
        case .rescue(let ids):
            return ids.filter(isRescued).count
        case .defeat(let enemyID):
            return hasDefeatedInStory(enemyID) ? 1 : 0
        case .clear(let areaID):
            guard let area = World.area(areaID) else { return 0 }
            return town.isCleared(area) ? 1 : 0
        case .dungeon(let id):
            return (wonDungeons ?? []).contains(id) ? 1 : 0
        case .reach(let areaID):
            return (visitedAreaIDs ?? []).contains(areaID) || currentAreaID == areaID ? 1 : 0
        case .kill, .talk, .read:
            return 0
        }
    }

    public func isComplete(_ quest: Quest) -> Bool {
        zip(progress(of: quest), quest.objectives).allSatisfy { $0 >= $1.target }
    }

    /// Primer objetivo sin cumplir (nil si están todos).
    public func nextObjective(of quest: Quest) -> QuestObjective? {
        zip(progress(of: quest), quest.objectives).first { $0 < $1.target }?.1
    }

    /// Acepta una misión disponible. Devuelve si se aceptó.
    @discardableResult
    public mutating func accept(_ questID: String) -> Bool {
        guard let quest = World.quest(questID), isAvailable(quest) else { return false }
        var state = QuestState(accepted: true, progress: Array(repeating: 0, count: quest.objectives.count), done: false)
        state.progress = progress(of: quest, stored: state.progress)
        setQuestState(state, for: questID)
        return true
    }

    private func progress(of quest: Quest, stored: [Int]) -> [Int] {
        quest.objectives.enumerated().map { i, objective in
            min(objective.target, max(i < stored.count ? stored[i] : 0, derivedProgress(objective)))
        }
    }

    private mutating func setQuestState(_ state: QuestState, for id: String) {
        var all = quests ?? [:]
        all[id] = state
        quests = all
    }

    /// Entrega una misión cumplida y da su recompensa (XP, oro, minerales, pieza).
    @discardableResult
    public mutating func deliver(_ questID: String) -> QuestDelivery? {
        guard let quest = World.quest(questID), isActive(quest), isComplete(quest) else { return nil }
        var state = questState(questID)
        state.progress = progress(of: quest)
        state.done = true
        setQuestState(state, for: questID)
        let reward = quest.reward
        let levels = gainXP(reward.xp)
        let gold = reward.gold > 0 ? earnGold(reward.gold) : 0
        for (mineral, count) in reward.minerals { addMineral(mineral, count: count) }
        if let part = reward.partID { addPart(part) }
        if let gearID = reward.gearID, let blueprint = Catalog.blueprint(id: gearID) {
            inventory.append(Catalog.makeShopItem(blueprint, rarity: .rare, level: characterLevel))
        }
        return QuestDelivery(questID: questID, xp: reward.xp, gold: gold, minerals: reward.minerals,
                             partID: reward.partID, levelsGained: levels)
    }

    /// Apunta un suceso y pone al día todas las misiones (acepta y entrega las automáticas).
    @discardableResult
    public mutating func record(_ event: QuestEvent) -> StoryUpdate {
        var update = StoryUpdate()
        if case .read(let id) = event {
            // La pista queda leída (aunque aún no cuente para ninguna misión): la próxima vez se lee más corta.
            var read = readClueIDs ?? []
            read.insert(id)
            readClueIDs = read
        }
        for quest in World.quests where isActive(quest) {
            var state = questState(quest.id)
            var progress = self.progress(of: quest)
            var changed = false
            for (i, objective) in quest.objectives.enumerated() where progress[i] < objective.target {
                switch (objective, event) {
                case let (.kill(ids, _, area), .killed(enemyID, areaID)) where ids.contains(enemyID) && (area == nil || area == areaID):
                    progress[i] += 1
                    changed = true
                case let (.defeat(id), .killed(enemyID, _)) where id == enemyID:
                    progress[i] = 1
                    changed = true
                case let (.talk(id), .talked(npcID)) where id == npcID,
                     let (.read(id), .read(npcID)) where id == npcID:
                    // Solo si todo lo anterior ya está cumplido.
                    if zip(progress[..<i], quest.objectives[..<i]).allSatisfy({ $0 >= $1.target }) {
                        progress[i] = 1
                        changed = true
                    }
                default:
                    break
                }
            }
            if changed {
                state.progress = progress
                setQuestState(state, for: quest.id)
                update.advanced.append(quest.id)
            }
        }
        update.merge(syncStory())
        return update
    }

    /// Pone al día la historia: acepta las misiones automáticas, recalcula lo que se mira en el perfil y entrega
    /// las que se completan solas. Llamarlo al cargar y tras cada cambio (rescate, muerte de un jefe, mazmorra…).
    @discardableResult
    public mutating func syncStory() -> StoryUpdate {
        var update = StoryUpdate()
        var changed = true
        var rounds = 0
        while changed && rounds < 20 {
            changed = false
            rounds += 1
            for quest in World.quests {
                if quest.autoAccept, isAvailable(quest), accept(quest.id) {
                    update.accepted.append(quest.id)
                    changed = true
                }
                guard isActive(quest) else { continue }
                let current = progress(of: quest)
                var state = questState(quest.id)
                if current != state.progress {
                    // Solo cuenta como avance si sube algo (no al rellenar la lista de una partida antigua).
                    if zip(current, state.progress + Array(repeating: 0, count: max(0, current.count - state.progress.count)))
                        .contains(where: { $0 > $1 }), !update.advanced.contains(quest.id) {
                        update.advanced.append(quest.id)
                    }
                    state.progress = current
                    setQuestState(state, for: quest.id)
                }
                if quest.completesOnLastObjective, isComplete(quest), let delivery = deliver(quest.id) {
                    update.delivered.append(delivery)
                    changed = true
                }
            }
        }
        return update
    }

    /// Partidas guardadas antes de las misiones: con la princesa rescatada, la historia del castillo ya pasó
    /// (se marcan hechas sin dar recompensa). Lo demás lo pone al día `syncStory`.
    public mutating func migrateStory() {
        guard town.princessRescued else { return }
        for id in [ValdemarQuests.liberar, ValdemarQuests.reyGoblin] where !isQuestDone(id) {
            guard let quest = World.quest(id) else { continue }
            setQuestState(QuestState(accepted: true, progress: quest.objectives.map(\.target), done: true), for: id)
        }
    }

    // MARK: Conversaciones y marcas

    /// "!" o "?" sobre un NPC (nil = nada que hacer con él).
    public func marker(for npcID: String) -> QuestMarker? {
        for quest in World.quests where isActive(quest) {
            if quest.giverID == npcID, !quest.completesOnLastObjective, isComplete(quest) { return .turnIn }
            switch nextObjective(of: quest) {
            case .talk(let id)?, .read(let id)?:
                if id == npcID { return .turnIn }
            default:
                break
            }
        }
        if World.quests.contains(where: { $0.giverID == npcID && !$0.autoAccept && isAvailable($0) }) { return .offer }
        return nil
    }

    /// Qué toca al hablar con alguien: primero entregar, luego ofrecer; si no hay nada, recordar la misión en curso.
    /// (Apuntar antes el suceso `.talked` para que cuenten los objetivos de hablar.)
    public func conversation(with npcID: String) -> [QuestStep] {
        let mine = World.quests.filter { $0.giverID == npcID }
        let deliver = mine.filter { isActive($0) && !$0.completesOnLastObjective && isComplete($0) }.map { QuestStep.deliver($0.id) }
        let offer = mine.filter { !$0.autoAccept && isAvailable($0) }.map { QuestStep.offer($0.id) }
        if !deliver.isEmpty || !offer.isEmpty { return deliver + offer }
        return mine.filter(isActive).prefix(1).map { QuestStep.remind($0.id) }
    }

    // MARK: Diario

    /// Misiones aceptadas sin entregar, en el orden de la historia.
    public var activeQuests: [Quest] { World.quests.filter(isActive) }

    /// Misiones entregadas.
    public var finishedQuests: [Quest] { World.quests.filter { isQuestDone($0.id) } }

    /// La misión que sigue el HUD: la elegida por el jugador (`track`) si sigue activa; si no, la primera activa
    /// (la historia va antes que las opcionales).
    public var trackedQuest: Quest? {
        if let id = trackedQuestID, let quest = World.quest(id), isActive(quest) { return quest }
        return activeQuests.first
    }

    /// Líneas del diario de una misión.
    public func journal(_ quest: Quest) -> [QuestObjectiveLine] {
        zip(quest.objectives, progress(of: quest)).enumerated().map { i, pair in
            let (objective, done) = pair
            if i < quest.objectiveLabels.count {
                let label = quest.objectiveLabels[i]
                // Con `{n}` el contador ya va en el texto ("Lobos grises en Robleda: 4/6").
                return QuestObjectiveLine(text: label.replacingOccurrences(of: "{n}", with: "\(min(done, objective.target))"),
                                          progress: done, target: objective.target, showsCounter: false)
            }
            return QuestObjectiveLine(text: Self.describe(objective), progress: done, target: objective.target)
        }
    }

    /// Texto corto de un objetivo (provisional; el story-writer puede pulirlo).
    public static func describe(_ objective: QuestObjective) -> String {
        switch objective {
        case .rescue(let ids):
            return ids.count == 1 ? "Rescata a \(World.npcShortName(ids[0]))" : "Rescata a los aldeanos"
        case .kill(let ids, _, let area):
            let names = ids.compactMap { Bestiary.enemy($0)?.name }
            let list = names.count > 1 ? names.dropLast().joined(separator: ", ") + " o " + names.last! : names.first ?? "monstruos"
            return area.map { "Mata: \(list) (\(World.placeName($0)))" } ?? "Mata: \(list)"
        case .defeat(let id):
            return "Derrota a: \(Bestiary.enemy(id)?.name ?? id)"
        case .talk(let id):
            return "Habla con \(World.npcShortName(id))"
        case .read(let id):
            return "Lee: \(World.npc(id)?.name ?? id)"
        case .clear(let id):
            return "Despeja: \(World.placeName(id))"
        case .dungeon(let id):
            return "Supera: \(World.placeName(id))"
        case .reach(let id):
            return "Llega a: \(World.placeName(id))"
        }
    }

    /// Una línea para el HUD: el siguiente objetivo de la misión ("Lobos grises en Robleda: 4/6").
    public func trackerText(_ quest: Quest) -> String {
        guard let index = Array(zip(progress(of: quest), quest.objectives)).firstIndex(where: { $0 < $1.target }) else {
            return "Vuelve con \(World.npcShortName(quest.giverID)): \(quest.title)"
        }
        let line = journal(quest)[index]
        return line.text + (line.counter.isEmpty ? "" : " \(line.counter)")
    }

    /// Lo que dice un NPC sin misiones que ofrecer ni entregar: su primera línea de `talk` que se cumpla.
    public func idleLines(for npc: NPC) -> [String]? {
        npc.talk.first { isMet($0.when) && !$0.unless.contains(where: isMet) }?.lines
    }
}
