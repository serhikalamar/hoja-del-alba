# Tablero de tareas

Lo mantiene `game-designer`. Cada tarea tiene un **agente responsable**, un estado y, si hace falta, de qué depende.
Los especialistas marcan su tarea como hecha y anotan el resultado en una línea.

Estados: `pendiente` · `en curso` · `bloqueada` · `hecha`

## En curso / próximas

| # | Tarea | Responsable | Estado | Depende de | Notas |
|---|---|---|---|---|---|
| 1 | Pasar al juego el mapa definitivo del Mundo 1 | `map-designer` | bloqueada | Mapa del usuario en `maps/borradores/` | |
| 2 | Escribir la historia del Mundo 1 a partir de la biblia | `story-writer` | pendiente | Decisiones del usuario (origen del héroe, villano) | |
| 3 | Diálogos nuevos de aldeanos según la historia | `story-writer` | pendiente | 2 | |

## Hechas

| # | Tarea | Responsable | Resultado |
|---|---|---|---|
| — | Pueblo explorable con casas, aldeanos y castillo | `game-programmer` | v0.3 |
| — | Arena de oleadas infinitas | `game-programmer` + `balance-designer` | v0.3 |
| — | Héroe chibi con diseño por raza y animaciones | `pixel-artist` | v0.3 |
| — | Organización por agentes: src/, assets/, tools/ y 8 agentes | `game-designer` | v0.3 |
| — | Selección y creación de personaje, lista de personajes | `game-programmer` | v0.4 |
| — | Casco, peto, guantes y botas: datos, armería, tinte e inventario | `game-programmer` | v0.4 |
| 4 | Diseño propio para cada jefe (corona, capa, cicatrices, cuernos…) | `pixel-artist` | v0.4 |
| 5 | Héroe detallado: 4 razas, aspecto, 18 diseños de armadura, carrera de 6 frames | `pixel-artist` | v0.4 |
| 7 | Diseñar los 5 pisos de la mazmorra de la arena (calabozos, cripta, cloacas, mina, forja) | `map-designer` | 5 mapas propios de 44-46×22-24 con 10-11 entradas cada uno; detalle en `assets/maps/mazmorra.md` |
| 6 | Enemigos, aldeanos y princesa detallados; paso de 4 frames, preparación y golpe | `pixel-artist` | v0.4 |
| — | Arena como mazmorra con cámara, puertas de monstruos y caminos alrededor de obstáculos | `game-programmer` | v0.5 |
| — | Agente `environment-artist` (escenarios) | `game-designer` | v0.5 |
| 8 | Arte de la mazmorra: 5 temas, paredes 3/4, luces, líquidos animados | `environment-artist` | v0.5 |
| 9 | Arte del pueblo, castillo e interiores mucho más detallado; luces, humo y fuente | `environment-artist` | v0.5 |
| — | Aldeanos a la escala del héroe (HeroArt) y profundidad por los pies | `game-programmer` | v0.5 |
| — | Sin menú: JUGAR / ARENA desde la selección; inventario en la pausa; diálogos compactos | `game-programmer` | v0.5 |
| — | Nueva forja del enano: herrero grande animado, fragua detallada, interfaz grande para el dedo | `pixel-artist` + `environment-artist` + `game-programmer` | v0.5 |
| P0 | Valdemar · contrato de datos (fase 0): casillas de campo, estilos de edificio, `World`/`Continent`/`AreaExit`/`ExitLock`/`DungeonEntrance`, `AreaKind`/`Biome`, tipos de misión y de mazmorra de historia, campos opcionales del perfil | `game-programmer` | Hecho sin cambiar el juego; 17 tests nuevos (`WorldTests.swift`); documentado en `assets/world/continentes/valdemar/contrato.md` |
| MD | Valdemar · áreas de campo y cambios del pueblo (fase 1): Huertos, Robleda, Abadía, Pedregal, Paso; casa del alcalde; cripta y calabozos; 4 salidas del pueblo, entrada (21,33), patio a nivel 9, NPC de la calle | `map-designer` | `Valdemar.swift` + datos de `Valdehierro`; 87 spawns de campo; poternas en la muralla del patio para que la salida norte no quede aislada; 8 tests (`ValdemarMapTests.swift`); `make maps` dibuja todas las áreas (+ planos `plan_*.png`); `assets/maps/valdemar.md` |
| P1 | Valdemar · motor del continente (fase 1, M1-M10): viajes por salidas `>` con bloqueos, reaparición de campo, misiones (11 en `ValdemarQuests.swift` con los textos de `story/valdemar.md`), "!"/"?", diario y mapa en la pausa, condición nueva del castillo, casa del alcalde, mazmorras de historia, botín y forja por continente, punto seguro, cartel de área | `game-programmer` | Hecho M1-M10. GameCore: `QuestEngine.swift`, `WorldRules.swift`, `ContinentLoot.swift`, `ValdemarDialogue.swift`; campos de texto nuevos (`Quest.offer/reminder/turnIn/objectiveLabels`, `NPC.talk`, `Building.lockedMessage`, `StoryDungeon.bossIntroRepeat/bossDefeat`). 34 tests nuevos (`QuestTests` 16, `WorldRulesTests` 18). `make check-valdemar` (44 comprobaciones, en `make verify`) y `Harness valdemar-shots`. Pendiente: arte de "!"/"?" y de las casillas de campo (provisional), `NPC.talk` por etapa (SW2), sesgo de mineral por área (opcional) |
| SW2 | Valdemar · textos del guion al código: rescates, `casa`/`calle.*` por etapa (`NPC.talk`), Capitán, carta «— M.», cartel del Paso, Aurora, avisos de salidas y edificios, confesión, repetición y derrota del Abad | `story-writer` | `Town.swift` (datos de `Valdehierro`), `Valdemar.swift`; misiones y diálogos sueltos ya estaban bien. Sin colocar (falta momento en el código): carta releída, bocadillos de la forja por etapa, entrada al Paso; las líneas `casa` no se oyen hasta que `converse` use el NPC del área actual. Ver `story/valdemar.md` §15 |
| P2 | Valdemar · los 4 textos sin colocar de SW2 (`story/valdemar.md` §15) + intros de jefe guardadas | `game-programmer` | Hecho. Cripta con hablante «Abad Morcar» (`StoryDungeon.bossSpeaker`, también en repetición y derrota: «Abad Morcar: «…»» + narración); carta del alcalde releída con `npc.cartaAlcalde.otra_vez` (`PlayerProfile.clueLines`, `readClueIDs`); bocadillos `smithy.bocadillo.*` por etapa (`ValdemarDialogue.smithBubbles(for:)`, arena = los de siempre); `escena.paso.entrar` la primera vez en el Paso (`firstVisitScenes`); `seenBossIntros` en el perfil. 5 tests en `QuestTests`, 7 comprobaciones nuevas en `make check-valdemar` |
| B1 | Valdemar: simulación del modo historia (`make historia`), ritmo 1→10, oro y minerales de la historia | `balance-designer` | Pueblo 6,2 · patio 9,0 · Rey 9,8 · fin 10,0; oro ÷5; piezas de jefe de Valdemar (T1) y jefes de historia 40-60 s sin muros (`assets/balance/README.md`) |
| ADM1 | Panel de administración · lado del juego: contrato de ajustes `GameTuning`, aplicación validada y exportación de valores base | `game-programmer` | Hecho. `GameTuning` (Codable, todo opcional: `enemies`, `parts`, `armor`, `minerals`, `areas`, `zones`, `spawns`, `dungeons`, `quests`, `rescues`, `roulette`, `economy`), `GameTuning.apply(_:) -> [String]` y `GameTuning.current`; tablas precalculadas en `TunedData` (con documento vacío, huella de 935 líneas idéntica a la de antes). `make datos` → `admin/public/data/*.json` (+ `esquema.json`); `Harness <comando> --ajustes f.json` para medir un documento. 13 tests (`TuningTests`). Contrato: `assets/admin/contrato.md` |
| P3 | Hablar con los NPC al tocarlos (camino por casillas, "…" al alcance, tecla de acción en Mac); retrato del héroe en el HUD con su ficha (también en la arena); botón "!" con el panel de la misión seguida | `game-programmer` | Hecho. GameCore: `Interaction.swift` (`NPCInteraction`, `TilePathfinder`, `AreaMap.isStrollable`), `QuestTracker.swift` (`track`, `questAlerts`, `destination(of:)`, `rewardText`), `PlayerProfile.trackedQuestID` (opcional); 14 tests (`InteractionTests`). App: `ExploreSession.interact(with:)`/`tap(atScreen:)`/`talkToNearest()`/`talk(to:)` (antes `npcReached`), `JoystickArea` con toque, `HUDPanels.swift`. Harness: `check-town` (+8), `check-valdemar` y `historia` tocan a los NPC; `-pantalla perfil|mision|alcance|paseo|arena-perfil` |
| MAPA | Mapa del continente detallado con zoom (pausa → ✦ MAPA, pantalla completa) | `game-programmer` | Hecho. Áreas con su mapa real (24 px/casilla), colocadas por `ContinentLayout` (GameCore, de `mapLayout` + salidas; 13 tests en `ContinentMapTests`), fondo de terreno generado (costa, bosques, montañas, ríos, caminos, paso a Rocaforja), niebla en lo no visitado, carteles, iconos, héroe y marcas de misión, tarjeta al tocar un área; pellizcar/arrastrar/doble toque/+−◎, rueda y trackpad en Mac. `Harness mapa-continente` (`make mapa-continente`): fondo ~0,4 s y 6 áreas ~0,5-0,7 s en release, una vez (caché) |
