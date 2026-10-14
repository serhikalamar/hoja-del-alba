import Foundation

// MARK: - Panel de la misión seguida (botón "!" del HUD)
//
// Qué misión se sigue (la elige el jugador entre las activas), dónde hay que ir para el siguiente objetivo y los
// avisos del botón: una misión nueva que ofrecer o una lista para entregar.

/// Aviso del botón "!" del HUD.
public struct QuestAlert: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        /// Alguien tiene una misión nueva ("!" sobre su cabeza).
        case newQuest
        /// Hay que volver a hablar con alguien: entregarla o el siguiente paso ("?").
        case turnIn
    }

    public let questID: String
    /// Con quién hay que hablar.
    public let npcID: String
    public let kind: Kind

    public init(questID: String, npcID: String, kind: Kind) {
        self.questID = questID
        self.npcID = npcID
        self.kind = kind
    }
}

/// Dónde hacer algo: un área y su nombre para el panel ("Bosque de Robleda").
public struct QuestPlace: Equatable, Sendable {
    public let areaID: String
    public let name: String
}

extension PlayerProfile {
    /// Elige la misión que sigue el HUD. Solo vale una activa; devuelve si se ha cambiado.
    @discardableResult
    public mutating func track(_ questID: String) -> Bool {
        guard let quest = World.quest(questID), isActive(quest) else { return false }
        trackedQuestID = questID
        return true
    }

    /// ¿Es esta la misión seguida?
    public func isTracked(_ quest: Quest) -> Bool { trackedQuest?.id == quest.id }

    /// Avisos del botón "!": misiones que alguien visible ofrece y misiones con las que hay que volver a hablar.
    public var questAlerts: [QuestAlert] {
        var out: [QuestAlert] = []
        for quest in World.quests {
            if isActive(quest) {
                if !quest.completesOnLastObjective, isComplete(quest) {
                    out.append(QuestAlert(questID: quest.id, npcID: quest.giverID, kind: .turnIn))
                } else if let next = nextObjective(of: quest) {
                    switch next {
                    case .talk(let id), .read(let id): out.append(QuestAlert(questID: quest.id, npcID: id, kind: .turnIn))
                    default: break
                    }
                }
            } else if !quest.autoAccept, isAvailable(quest), isVisibleSomewhere(quest.giverID) {
                out.append(QuestAlert(questID: quest.id, npcID: quest.giverID, kind: .newQuest))
            }
        }
        return out
    }

    /// ¿Se puede encontrar ahora a este NPC en algún área? (El herrero siempre está en su forja.)
    func isVisibleSomewhere(_ npcID: String) -> Bool {
        npcID == ValdemarQuests.smithID || World.areas.contains { visibleNPCs(in: $0).contains { $0.id == npcID } }
    }

    /// Dónde está ahora un NPC (mejor en la calle que en su casa: los rescatados salen a la plaza).
    public func place(ofNPC npcID: String) -> QuestPlace? {
        if npcID == ValdemarQuests.smithID {
            return QuestPlace(areaID: Valdehierro.townID, name: "Forja del enano (\(World.placeName(Valdehierro.townID)))")
        }
        let areas = World.areas.filter { visibleNPCs(in: $0).contains { $0.id == npcID } }
        guard let area = areas.first(where: { !$0.isInterior }) ?? areas.first else { return nil }
        return QuestPlace(areaID: area.id, name: area.name)
    }

    /// Dónde hay que ir para el siguiente objetivo de la misión (o a entregarla). nil si no se sabe.
    public func destination(of quest: Quest) -> QuestPlace? {
        guard let next = nextObjective(of: quest) else {
            // Cumplida: a quien la dio (las que se entregan solas no llegan aquí: ya no están activas).
            return place(ofNPC: quest.giverID)
        }
        switch next {
        case .rescue(let ids):
            return ids.first { !isRescued($0) }.flatMap { place(ofNPC: $0) }
        case .kill(let enemyIDs, _, let areaID):
            if let areaID { return World.area(areaID).map { QuestPlace(areaID: $0.id, name: $0.name) } }
            return World.areas.first { area in area.spawns.contains { enemyIDs.contains($0.enemyID) } }
                .map { QuestPlace(areaID: $0.id, name: $0.name) }
        case .defeat(let enemyID):
            if let area = World.areas.first(where: { $0.spawns.contains { $0.enemyID == enemyID } }) {
                return QuestPlace(areaID: area.id, name: area.name)
            }
            return World.storyDungeons.first { $0.bossID == enemyID }.flatMap { dungeonPlace($0.id) }
        case .talk(let id), .read(let id):
            return place(ofNPC: id)
        case .clear(let areaID), .reach(let areaID):
            return World.area(areaID).map { QuestPlace(areaID: $0.id, name: $0.name) }
        case .dungeon(let id):
            return dungeonPlace(id)
        }
    }

    /// La bajada a una mazmorra de historia: "Cripta de la abadía (Abadía de San Ciprián)".
    private func dungeonPlace(_ dungeonID: String) -> QuestPlace? {
        guard let area = World.areas.first(where: { $0.dungeonEntrances.contains { $0.dungeonID == dungeonID } }) else { return nil }
        return QuestPlace(areaID: area.id, name: "\(World.placeName(dungeonID)) (\(area.name))")
    }

    /// Texto corto de la recompensa: "120 XP · 50 oro · 2 Plata · pieza".
    public static func rewardText(_ reward: QuestReward) -> String {
        var parts: [String] = []
        if reward.xp > 0 { parts.append("\(reward.xp) XP") }
        if reward.gold > 0 { parts.append("\(reward.gold) oro") }
        for (mineral, count) in reward.minerals.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            parts.append("\(count) \(mineral.name)")
        }
        if let partID = reward.partID { parts.append(PartCatalog.part(partID)?.name ?? "una pieza") }
        if reward.gearID != nil { parts.append("una pieza de equipo") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}
