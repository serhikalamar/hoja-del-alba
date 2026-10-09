import Foundation

// MARK: - Valdemar: textos de la historia que no van en un mapa ni en una misión
//
// Dueño: story-writer (textos) · game-programmer (dónde se usan). Fuente: `assets/story/valdemar.md`.
// Las misiones llevan sus diálogos en `ValdemarQuests.swift`; los NPC, en `NPC.thanks/plea/talk` (`Town.swift`,
// `Valdemar.swift`); los avisos de salidas, en `AreaExit.lockedMessage`; los de edificios, en `Building.lockedMessage`.

public enum ValdemarDialogue {
    // MARK: Introducción (`escena.intro`, §2)

    /// Las líneas de la introducción; la 2.ª depende de la raza.
    public static func intro(race: Race) -> [String] {
        [
            "Noche sin luna. Los goblins han entrado en Valdehierro por la puerta sur.",
            introRaceLine[race] ?? introRaceLine[.human]!,
            "El Rey Goblin se ha hecho con el castillo. Tiene encerrada a la princesa Aurora.",
            "Libera las calles, entra en las casas y rescata a los aldeanos.",
        ]
    }

    static let introRaceLine: [Race: String] = [
        .human: "Volvías a casa tras años fuera. No esperabas esta bienvenida.",
        .dwarf: "Vienes de Rocaforja buscando a un herrero enano. Dicen que forja aquí… si sigue vivo.",
        .elf: "Traes un aviso de Velaluna para la princesa: la Luna se apaga. Llegas una noche tarde.",
        .werewolf: "Seguiste un olor a ceniza desde el bosque. Sin luna, la sangre te arde. Aquí huele más.",
    ]

    // MARK: Variantes por raza (§12)

    /// Una línea extra según la raza, insertada tras la línea `after` (0…) de un diálogo conocido.
    public struct RaceLine: Sendable {
        public let after: Int
        public let line: String
    }

    /// Diálogo (id de NPC o `smithy` para el epílogo) → raza → línea extra.
    public static let raceLines: [String: [Race: RaceLine]] = [
        "princess": [
            .human: RaceLine(after: 0, line: "Eres de aquí, ¿verdad? Valdehierro siempre cuida de los suyos."),
            .elf: RaceLine(after: 0, line: "¿Un aviso de Velaluna? Llega tarde… pero llega. Gracias."),
            .werewolf: RaceLine(after: 0, line: "Tus ojos brillan como los de un lobo. Esta noche, me alegro de tenerlos de mi lado."),
        ],
        ValdemarQuests.smithID: [
            .dwarf: RaceLine(after: 3, line: "Hondoyunque te mandó a buscarme, ¿eh? Pues mira: volvemos juntos."),
        ],
    ]

    /// Inserta la línea de raza (si la hay) en un diálogo.
    public static func withRaceLine(_ lines: [String], dialogID: String, race: Race) -> [String] {
        guard let extra = raceLines[dialogID]?[race], extra.after < lines.count else { return lines }
        var result = lines
        result.insert(extra.line, at: extra.after + 1)
        return result
    }

    // MARK: Herrero (§10)

    /// Nombre del herrero antes y después de presentarse (en el epílogo dice su nombre en la línea 4).
    public static let smithName = "El herrero"
    public static let smithFullName = "Brokk, el herrero"
    /// Línea del epílogo (`valdemar.paso_norte.offer`) a partir de la cual habla ya como «Brokk».
    public static let epilogueRenameAt = 4

    /// Bocadillos de la forja que valen siempre (y los únicos en la arena).
    public static let smithBubbles = [
        "¡Acero de Valdehierro! Nada de baratijas.",
        "Una buena hoja necesita una buena guarda.",
        "Mezcla elementos… y el ritual hará el resto.",
        "Los jefes llevan piezas que ni yo sé forjar.",
        "¿Una poción? Tienes mala cara, muchacho.",
        "Obsidiana y roble… huele a magma. Je, je.",
    ]

    /// Bocadillos que se suman según el momento de la historia (`smithy.bocadillo.*`): valen todos los que se cumplen.
    public static let smithStoryBubbles: [NPCLine] = [
        // Etapa «fuera»: el pueblo liberado y el trono aún no.
        NPCLine(when: [.questDone(ValdemarQuests.liberar)], unless: [.questDone(ValdemarQuests.reyGoblin)],
                ["¿Plata de los huertos? ¿Oro del Pedregal? Tráemelo todo."]),
        // Tras el Pedregal y hasta el epílogo (después ya ha confesado de dónde son las hachas).
        NPCLine(when: [.questDone(ValdemarQuests.pedregal)], unless: [.questDone(ValdemarQuests.pasoNorte)],
                ["¿Hachas orcas negras? Ni me las nombres. Ni me las enseñes."]),
        // Tras el epílogo (`paso_norte`): ya es Brokk y vende tier 2.
        NPCLine(when: [.questDone(ValdemarQuests.pasoNorte)],
                ["Acero de verdad, como en Rocaforja. Bueno, casi.",
                 "Cuando quieras, subimos. Yo llevo el martillo; tú, las piernas."]),
    ]

    /// Frases del bocadillo de la forja. `profile` nil = arena (solo las de siempre).
    public static func smithBubbles(for profile: PlayerProfile?) -> [String] {
        guard let profile else { return smithBubbles }
        let story = smithStoryBubbles.filter { profile.isMet($0.when) && !$0.unless.contains(where: profile.isMet) }
        return smithBubbles + story.flatMap(\.lines)
    }

    // MARK: Jefes (§7)

    /// Presentación de un jefe al verlo por primera vez (id de monstruo → hablante y líneas).
    public static let bossIntros: [String: (speaker: String, lines: [String])] = [
        "ogre": ("Ogro del molino", ["¡GRRR! ¡Molino mío! ¡Harina mía!", "Tú… pequeño. Tú cabe en un pan."]),
        "alphaWolf": ("Valdehierro", ["Un aullido hace callar el bosque entero.",
                                      "El Lobo alfa sale de entre las rocas. Bruno no exageraba: es grande como un carro."]),
        "warlord": ("Señor de la guerra orco", ["¿Un enviado del Rey Goblin? No… tú hueles a pueblo libre.",
                                                "Mis hachas vienen del norte, templadas en fuego negro. No se mellan. ¡Pruébalas!"]),
        "goblinKing": ("Rey Goblin", ["¡Mi castillo! ¡Mi trono! ¡Mi princesa! ¡Todo mío!",
                                      "El encapuchado me lo prometió. ¡Y un rey goblin siempre cobra!",
                                      "¡Guardias! ¡Aplastad a ese… a ese… lo que sea!"]),
        "ratKing": ("Rey de las ratas", ["¡Iiiik! ¡Este pan es del rey! ¡Todo el pan es del rey!"]),
        "scarecrow": ("Espantapájaros maldito", ["(crujido de paja) … sombrero… nuevo…"]),
        "possessedSmith": ("Herrero poseído", ["¡Más fuego! ¡La voz quiere más fuego!"]),
        "witch": ("Bruja del pozo", ["¿Pociones gratis? Ji, ji. El encapuchado me prometió todas."]),
        "banditChief": ("Capitán bandido", ["Me han pagado por esta plaza. Y yo cumplo lo que cobro."]),
    ]

    // MARK: Mazmorras de historia (§8)

    /// Aviso al ganar (primera vez / repeticiones) y al perder.
    public static let dungeonTexts: [String: (firstWin: String, win: String, lose: String)] = [
        "valdemar.cripta": ("¡Cripta despejada! El Abad Morcar ha caído.", "¡Cripta despejada!",
                            "La oscuridad de la cripta te vence. Despiertas junto a la hoguera de Valsombra."),
        "valdemar.calabozos": ("¡Calabozos despejados!", "¡Calabozos despejados!",
                               "Te sacan a rastras de los calabozos. Despiertas en la Puerta sur."),
    ]

    // MARK: Avisos (§5, §11)

    public static func zoneLiberated(_ zone: String, gold: Int) -> String { "¡Zona liberada: \(zone)! +\(gold) oro" }
    public static func newQuest(_ title: String) -> String { "Nueva misión: \(title)" }
    public static func questDone(_ title: String, xp: Int, gold: Int) -> String {
        "Misión cumplida: \(title) · +\(xp) XP" + (gold > 0 ? " · +\(gold) oro" : "")
    }
    public static func objectiveDone(_ name: String) -> String { "¡Objetivo cumplido! Vuelve con \(name)." }
    public static let roomCleared = "¡Sala despejada! Habla con quien estaba atrapado."
    public static let mayorCleared = "¡Sala despejada! Hay una carta sobre el escritorio."
    public static let mayorFirstVisit = "Papeles ardiendo en la chimenea. Del alcalde, ni rastro."
    public static let mayorOpened = "La casa del alcalde ya no está atrancada."
    public static let northPassOpened = ["¡El Paso del Norte está abierto!", "Nuevas piezas en la forja (T2)"]
    public static let abbeyDoneWithoutRocks = "El Capitán Vela espera noticias del Pedregal."

    /// Escena corta la primera vez que se entra en un área (id de área → hablante y líneas).
    public static let firstVisitScenes: [String: (speaker: String, lines: [String])] = [
        // `escena.paso.entrar` (§11).
        Valdemar.pasoID: ("Valdehierro", ["Goblins rezagados huyen del castillo… hacia las montañas."]),
    ]

    /// Aviso de muerte (M9): en el campo se despierta junto a la hoguera del área.
    public static func death(inField area: String?) -> String {
        guard let area else { return "Conservas todo lo conseguido. Los aldeanos te llevan a la puerta sur." }
        return "Caes rendido… Despiertas junto a la hoguera de \(area)."
    }

    // MARK: Objetivo del HUD sin misión que seguir (§11)

    public static func hudObjective(_ profile: PlayerProfile) -> String {
        if profile.isQuestDone(ValdemarQuests.pasoNorte) { return "El Paso del Norte está abierto. Rocaforja espera… pronto." }
        if profile.isQuestDone(ValdemarQuests.reyGoblin) { return "Ve a la forja: el herrero quiere verte." }
        if profile.isCastleOpen() { return "¡El castillo está abierto! Derrota al Rey Goblin." }
        if profile.isQuestDone(ValdemarQuests.liberar), !profile.questState(ValdemarQuests.pedregal).accepted {
            return "Habla con el Capitán Vela, al pie de la escalinata."
        }
        if !profile.isQuestDone(ValdemarQuests.liberar) {
            let rescued = ["marta", "elena", "tomas", "anselmo", "bruno", "iris"].filter(profile.isRescued).count
            return "Rescata a los aldeanos: \(rescued)/6"
        }
        return "Los vecinos te necesitan: busca el «!» en la calle."
    }
}
