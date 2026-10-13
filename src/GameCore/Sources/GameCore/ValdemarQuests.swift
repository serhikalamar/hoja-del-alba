import Foundation

// MARK: - Misiones de Valdemar
//
// Dueño: game-programmer (fase 1, M3), con los datos de `assets/world/continentes/valdemar/historia.md` §4.
// TEXTOS PROVISIONALES: los definitivos los pega el story-writer (SW2) en `title`, `summary`, `offer`, `reminder`
// y `delivery`; las recompensas las ajusta el balance-designer (B1). Los ids no se renombran (se guardan).
// Ya registradas en `World.quests`.

public enum ValdemarQuests {
    public static let liberar = "valdemar.liberar"
    public static let molino = "valdemar.molino"
    public static let cazaMayor = "valdemar.caza_mayor"
    public static let hilos = "valdemar.hilos"
    public static let alcalde = "valdemar.alcalde"
    public static let pociones = "valdemar.pociones"
    public static let abadia = "valdemar.abadia"
    public static let pedregal = "valdemar.pedregal"
    public static let reyGoblin = "valdemar.rey_goblin"
    public static let pasoNorte = "valdemar.paso_norte"
    public static let calabozos = "valdemar.calabozos"

    /// Id del Capitán de la guardia (NPC con rol `questGiver`).
    public static let captainID = "capitanGuardia"
    /// El enano herrero no es un NPC del mapa: habla al entrar en la forja.
    public static let smithID = "smithy"

    /// Condición nueva del castillo (M4): `liberar` + `abadia` + `pedregal`. No usa `defeatedBosses`.
    public static let castleRequires: [StoryCondition] = [.questDone(liberar), .questDone(abadia), .questDone(pedregal)]

    /// Al completarla, la forja vende también el tier siguiente.
    public static let finalQuestID = reyGoblin

    /// Las 11 misiones del continente, en el orden previsto de la historia (el HUD sigue la primera activa).
    /// Recompensas (balance, B1, medido con `make historia`): las de fuera del pueblo dan ~55 % de la XP y ~40 % del
    /// oro de la primera versión, para llegar al patio con nivel ~9 y que el oro de la forja pese.
    /// Textos de `assets/story/valdemar.md` §5 (story-writer).
    public static var all: [Quest] { TunedData.current.quests }

    /// Las misiones del código (recompensas sin ajustes; las del panel: `quests.<id>`).
    static let baseQuests: [Quest] = [
        Quest(
            id: liberar, giverID: captainID,
            title: "La noche sin luna",
            summary: "Libera las calles de Valdehierro y rescata a sus seis aldeanos.",
            objectives: [.rescue(["marta", "elena", "tomas", "anselmo", "bruno", "iris"])],
            reward: QuestReward(xp: 172, gold: 50),
            autoAccept: true, completesOnLastObjective: true,
            objectiveLabels: ["Rescata a los aldeanos: {n}/6"],
            turnIn: ["¡Todos los aldeanos están a salvo! Valdehierro vuelve a respirar.",
                     "Al pie de la escalinata del castillo, un soldado con la coraza abollada te hace señas."]
        ),
        Quest(
            id: molino, giverID: "tomas",
            title: "El molino de mi padre",
            summary: "Tomás: limpia de zombis los Huertos del Molino y echa al Ogro del molino viejo.",
            requires: [.rescued("tomas")],
            objectives: [.kill(enemyIDs: ["zombieFarmer"], count: 6, areaID: "valdemar.huertos"), .defeat(enemyID: "ogre")],
            reward: QuestReward(xp: 100, gold: 50, minerals: [.silver: 2]),
            objectiveLabels: ["Granjeros zombi en los Huertos: {n}/6", "Derrota al Ogro del molino"],
            offer: ["Mis trigales, al oeste del pueblo… quemados. Y ahora los pisan granjeros muertos.",
                    "En el molino viejo de mi padre se ha metido un ogro. ¡Un ogro! Duerme encima de mi harina.",
                    "Limpia los trigales y echa a ese bicho. Mi padre te lo agradecería. Y yo, más."],
            reminder: "Los huertos, por la salida oeste. El molino viejo queda al noroeste, pasado el trigal.",
            turnIn: ["¿El ogro, fuera? ¡Ja! Mi padre estaría orgulloso. Y muy sorprendido.",
                     "Esos muertos venían del este, de Valsombra. Allí los muertos no descansan.",
                     "Toma, plata de la buena. Era para un molino nuevo, pero te la has ganado."]
        ),
        Quest(
            id: cazaMayor, giverID: "bruno",
            title: "Caza mayor",
            summary: "Bruno: caza lobos en el Bosque de Robleda y acaba con el Lobo alfa.",
            requires: [.rescued("bruno")],
            objectives: [.kill(enemyIDs: ["wolf"], count: 6, areaID: "valdemar.robleda"), .defeat(enemyID: "alphaWolf")],
            reward: QuestReward(xp: 100, gold: 50, minerals: [.iron: 3]),
            objectiveLabels: ["Lobos grises en Robleda: {n}/6", "Derrota al Lobo alfa"],
            offer: ["Una posada sin venado ni jabalí es una casa con sillas, forastero.",
                    "Los lobos de Robleda no dejan pasar a un cazador. Y su jefe es grande como un carro.",
                    "Caza seis lobos y trae la cabeza del alfa. Bueno, la cabeza no, que luego huele."],
            reminder: "Robleda, por la puerta sur. La guarida del alfa está al sureste, entre las rocas.",
            turnIn: ["¡Ese colmillo va encima de la barra! «Lo cazó un cliente». Precioso.",
                     "Los arrieros dicen que los orcos del Pedregal llevan hachas nuevas. Negras.",
                     "Ten, hierro del bueno. Y vuelve a cenar: hay estofado. De lobo no, tranquilo."]
        ),
        Quest(
            id: hilos, giverID: "elena",
            title: "Tirar del hilo",
            summary: "Elena: desmonta el campamento bandido de Robleda y vuelve con lo que encuentres.",
            requires: [.rescued("elena")],
            objectives: [.kill(enemyIDs: ["bandit", "mercenary"], count: 8, areaID: "valdemar.robleda"), .talk(npcID: "elena")],
            reward: QuestReward(xp: 75, gold: 40),
            objectiveLabels: ["Bandidos o mercenarios en Robleda: {n}/8", "Vuelve con Elena"],
            offer: ["Esos bandidos no robaban por hambre: alguien les pagaba.",
                    "Se llevaron mis telas a su campamento, en el bosque de Robleda. Al sur, por el camino real.",
                    "Desmonta ese campamento y tráeme lo que encuentres. Quiero saber de quién es el oro."],
            reminder: "El campamento bandido está al suroeste de Robleda, tras la empalizada.",
            turnIn: ["¿Esto llevaban? Monedas nuevas… con el sello del concejo de Valdehierro.",
                     "Solo el alcalde tiene la llave del arca. Y desde la noche del ataque no ha salido de casa.",
                     "Su puerta no aguantará mucho. Yo tampoco pienso esperar."]
        ),
        Quest(
            id: alcalde, giverID: "elena",
            title: "La casa del alcalde",
            summary: "Elena: entra en la casa del alcalde Fausto y averigua qué esconde.",
            requires: [.questDone(hilos)],
            objectives: [.clear(areaID: "mayor"), .read(npcID: "cartaAlcalde")],
            reward: QuestReward(xp: 95, gold: 40, minerals: [.gold: 1]),
            completesOnLastObjective: true,
            objectiveLabels: ["Despeja la casa del alcalde (barrio este)", "Lee la carta del escritorio"],
            offer: ["Entra en casa del alcalde. Si es inocente, que me lo diga a la cara.",
                    "Y si no lo es, busca papeles. Los tramposos siempre lo apuntan todo."],
            reminder: "La casa del alcalde está en el barrio este, al lado de la de Iris."
            // Entrega: la propia lectura de la carta (`cartaAlcalde.thanks`).
        ),
        Quest(
            id: pociones, giverID: "iris",
            title: "Limo fresco",
            summary: "Iris: aplasta seis limos de cualquier color en Valdemar.",
            requires: [.rescued("iris")],
            objectives: [.kill(enemyIDs: ["slime", "fireSlime", "iceSlime"], count: 6, areaID: nil)],
            reward: QuestReward(xp: 65, gold: 40, minerals: [.emerald: 1]),
            objectiveLabels: ["Limos de cualquier color: {n}/6"],
            offer: ["Necesito limo para mis pociones. Fresco, a poder ser.",
                    "Verdes en los huertos, de fuego en la abadía, helados en las pozas del Pedregal.",
                    "Seis limos, del color que sea. No soy tiquismiquis."],
            reminder: "Limos verdes en los huertos, de fuego en la abadía y helados en el Pedregal.",
            turnIn: ["¡Qué textura! Este limo de fuego aún burbujea.",
                     "Ojo con los encapuchados grises de la abadía: sus esferas violetas queman por dentro.",
                     "Toma esta esmeralda. Tiene más magia que todo mi estante."]
        ),
        Quest(
            id: abadia, giverID: "anselmo",
            title: "Los muertos de Valsombra",
            summary: "Fray Anselmo: limpia el cementerio de Valsombra y baja a la cripta de la abadía.",
            requires: [.rescued("anselmo"), .questDone(alcalde)],
            objectives: [.kill(enemyIDs: ["skeleton", "skeletonArcher", "ghoul", "wraith"], count: 10, areaID: "valdemar.abadia"),
                         .dungeon("valdemar.cripta")],
            reward: QuestReward(xp: 130, gold: 80, minerals: [.emerald: 2]),
            objectiveLabels: ["No-muertos en la abadía: {n}/10", "Supera la Cripta de la abadía"],
            offer: ["¿«M.»? ¿Morcar? Imposible: yo mismo lo enterré hace un año.",
                    "Aunque… dicen que en Valsombra las lápidas amanecen abiertas.",
                    "Limpia el cementerio y baja a la cripta. Si Morcar sigue allí, no es por gracia de la Luna."],
            reminder: "Valsombra, por la salida este. La bajada a la cripta está en el claustro, junto a la iglesia.",
            turnIn: ["Así que Morcar volvió de la tumba para servir al Eclipse. Que la Luna lo perdone. Yo no.",
                     "¿Y dices que al fondo de la cripta brillaba una brasa dorada? Un Ascua del Alba…",
                     "Juro guardarla mientras viva. El Eclipse no volverá a tocarla."]
        ),
        Quest(
            id: pedregal, giverID: captainID,
            title: "Hachas en el Pedregal",
            summary: "Capitán Vela: deja al Rey Goblin sin orcos en las Colinas del Pedregal.",
            requires: [.questDone(liberar)],
            objectives: [.kill(enemyIDs: ["orc", "berserker"], count: 6, areaID: "valdemar.pedregal"),
                         .defeat(enemyID: "warlord")],
            reward: QuestReward(xp: 100, gold: 80, minerals: [.gold: 2]),
            objectiveLabels: ["Orcos en el Pedregal: {n}/6", "Derrota al Señor de la guerra orco"],
            // Primero, la presentación del Capitán (`npc.capitanGuardia.aparicion`), luego la oferta.
            offer: ["Capitán Rodrigo Vela, de la guardia. De lo que queda de ella. Buen trabajo ahí abajo.",
                    "El Rey Goblin ha atrancado el castillo… y no está solo.",
                    "Orcos en el Pedregal, muertos en la abadía. Y alguien les abrió la puerta sur desde dentro.",
                    "Hay que cortarle los apoyos antes de subir. Para eso te necesito.",
                    "Los orcos del Pedregal le venden brazos al Rey Goblin. Los manda un Señor de la guerra.",
                    "Están al sureste, pasado el bosque de Robleda. Mata orcos y tumba a su jefe.",
                    "Es mal sitio para novatos. Si aún no estás listo, ayuda antes a los vecinos: ellos también te necesitan."],
            reminder: "Pasado Robleda, hacia el este. El campamento orco está al fondo, tras la empalizada.",
            turnIn: ["¿El Señor de la guerra, muerto? Mis hombres brindarán por ti hasta el invierno.",
                     "¿Has visto sus hachas? Negras y sin una mella. Eso no lo forja un orco.",
                     "Enséñaselas al herrero algún día. Yo no sé de fuegos, pero ese huele mal."]
        ),
        Quest(
            id: reyGoblin, giverID: captainID,
            title: "El trono de Valdehierro",
            summary: "Sube al castillo, derrota al Rey Goblin y libera a la princesa Aurora.",
            requires: [.questDone(liberar), .questDone(abadia), .questDone(pedregal)],
            objectives: [.defeat(enemyID: "goblinKing"), .talk(npcID: "princess")],
            reward: QuestReward(xp: 505),
            completesOnLastObjective: true,
            objectiveLabels: ["Derrota al Rey Goblin", "Habla con la princesa Aurora"],
            offer: ["Sin orcos ni muertos, el Rey Goblin está solo. La escalinata es tuya.",
                    "El patio está lleno de su guardia. Mis hombres no pasarán de la puerta: tú sí.",
                    "Trae a la princesa a casa."],
            reminder: "El salón del trono está al fondo del patio. Aurora lleva demasiado tiempo esperando."
            // Entrega: `princess.thanks` (la recompensa de Aurora va en su NPC).
        ),
        Quest(
            id: pasoNorte, giverID: smithID,
            title: "Fuego Hollín",
            summary: "El herrero de la forja quiere hablar contigo.",
            requires: [.questDone(reyGoblin)],
            objectives: [.talk(npcID: smithID)],
            reward: QuestReward(xp: 150),
            completesOnLastObjective: true,
            objectiveLabels: ["Ve a la forja: el herrero quiere verte."],
            // `escena.epilogo`: la parte 2 la dice ya «Brokk, el herrero» (ver `ValdemarDialogue.epilogueSpeakers`).
            offer: ["Así que la princesa te ha dado la Hoja del Alba. Bah. Tráela al ritual cuando quieras.",
                    "Pero antes mira esto: un hacha de los orcos del Pedregal.",
                    "Este temple negro no se mella ni se enfría. Es fuego Hollín. Mi viejo clan.",
                    "Me llamo Brokk. Brokk Martillohondo. Ya iba siendo hora de que lo supieras.",
                    "Esta mañana, desde la muralla, vi a un encapuchado subir por el Paso del Norte.",
                    "Andaba como un alcalde gordo con prisa. Fausto, me apuesto el yunque.",
                    "Va hacia Rocaforja. Hacia mi tierra. Si vas tras él, voy contigo.",
                    "Y desde hoy vendo acero de verdad. Se acabó el cobre para críos."]
        ),
        Quest(
            id: calabozos, giverID: captainID,
            title: "Ronda por los calabozos",
            summary: "Capitán Vela: limpia los calabozos del castillo. Si se vuelven a llenar, vuelve.",
            requires: castleRequires,
            objectives: [.dungeon("valdemar.calabozos")],
            reward: QuestReward(xp: 100, gold: 60, minerals: [.silver: 2]),
            objectiveLabels: ["Supera los Calabozos del castillo"],
            offer: ["Bajo el patio están los calabozos. Hay goblins de élite atrincherados ahí abajo.",
                    "Límpialos y te pago de la caja de la guardia. Si vuelven a colarse… vuelve tú también."],
            reminder: "La reja de los calabozos está en el patio, a mano derecha.",
            turnIn: ["Ni un goblin en los calabozos. Así da gusto hacer la ronda.",
                     "Si vuelven a colarse, ya sabes dónde están."]
        ),
    ]

    // MARK: - Puertas y avisos de la historia (M4)

    /// Puertas de edificio con condición (id del edificio → bloqueo y aviso). Textos: `valdemar.md` §11.
    public static let doorLocks: [String: (lock: ExitLock, message: String)] = [
        "castle": (.castleOpen, "La puerta del castillo está atrancada. El Capitán Vela aún no la abrirá."),
        "mayor": (.questDone(hilos), "La casa del alcalde está atrancada por dentro. Elena, la tejedora, sospecha algo."),
    ]

    /// Aviso de la escalinata `S` del castillo mientras está cerrada (`aviso.escalinata.*`).
    public static func stairsMessage(_ profile: PlayerProfile) -> String {
        let abbey = profile.isQuestDone(abadia), rocks = profile.isQuestDone(pedregal)
        if !profile.isQuestDone(liberar) { return "La escalinata está atrancada desde arriba. Primero, libera el pueblo." }
        if !abbey && !rocks { return "Capitán Vela: nadie sube hasta que limpiemos la abadía y el Pedregal. Órdenes mías." }
        if !abbey { return "Capitán Vela: falta la abadía. Hasta que los muertos de Valsombra caigan, nadie sube." }
        return "Capitán Vela: falta el Pedregal. Hasta que caiga el Señor de la guerra, nadie sube."
    }

    /// `escena.castillo_abierto`: en cuanto se cumple la condición del castillo.
    public static let castleOpensLines = [
        "Suena un cuerno en la plaza: ¡el Capitán Vela abre la escalinata del castillo!",
    ]

    /// Esquema del mapa del continente (columna, fila), como en `zonas.md` §1.
    public static let mapLayout: [String: TilePoint] = [
        "valdemar.paso": TilePoint(1, 0),
        "valdemar.huertos": TilePoint(0, 1),
        Valdehierro.townID: TilePoint(1, 1),
        "valdemar.abadia": TilePoint(2, 1),
        "valdemar.robleda": TilePoint(1, 2),
        "valdemar.pedregal": TilePoint(2, 2),
    ]

    /// Oferta de una misión según la partida. Las partidas de la v0.5 con la princesa ya rescatada llegan con el
    /// Rey Goblin vencido: el Capitán no puede decir que el castillo sigue atrancado.
    public static func offerLines(for quest: Quest, profile: PlayerProfile) -> [String] {
        if quest.id == pedregal, profile.isQuestDone(reyGoblin) {
            return ["Capitán Rodrigo Vela, de la guardia. De lo que queda de ella. Tú tumbaste al Rey Goblin, ¿verdad?",
                    "Pues sus aliados no se han enterado. Los orcos del Pedregal siguen armándose.",
                    "Los manda un Señor de la guerra. Están al sureste, pasado el bosque de Robleda.",
                    "Mata orcos y tumba a su jefe, antes de que vengan a por lo que queda del pueblo."]
        }
        return quest.offer.isEmpty ? [quest.summary] : quest.offer
    }
}
