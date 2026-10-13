# Documento de diseño (GDD)

Responsable: `game-designer`. Estado: versión 0.3 (prototipo jugable, publicada). Nombre del juego: *pendiente*.

## Visión

Juego de acción incremental en pixel-art chibi (estilo JRPG de 16 bits, vista 3/4) para móvil en horizontal
y Mac. El jugador solo mueve al héroe: el ataque es automático. La profundidad está en **forjar armas propias**
combinando piezas, minerales y elementos, y en descubrir habilidades secretas.

## Pilares

1. **Moverse es jugar**: esquivar golpes avisados, elegir a quién acercarse, explorar.
2. **Forjar es progresar**: cada arma es única (piezas + minerales + ruleta + habilidad + dibujo propio).
3. **Descubrir**: habilidades secretas, piezas de jefe, casas por explorar, historia por desvelar.
4. **Siempre un paso más**: progresión incremental sin techo (arena infinita) y muros que piden mejorar el equipo.

## Bucle principal

Explorar / pelear → conseguir oro, minerales y piezas → forja del enano (comprar piezas, ritual) →
arma más fuerte → zonas más difíciles, rescates, jefes → piezas únicas → …

## Modos

| Modo | Descripción | Estado |
|---|---|---|
| Pueblo (historia) | Valdehierro explorable: 6 zonas, 6 casas con aldeanos, castillo con el Rey Goblin y la princesa | Hecho (prototipo) |
| Arena | Oleadas infinitas; forja cada 2 oleadas; jefe y escenario nuevo cada 5; récord | Hecho |

## Sistemas

| Sistema | Resumen | Código | Ficha |
|---|---|---|---|
| Personajes | Varios personajes por jugador; selección y creación al estilo MMORPG (nombre, raza, piel, peinado, colores) | `SaveStore.swift` (`Roster`), `CharacterScreens.swift` | — |
| Héroe y razas | 4 razas con estadísticas propias y diseño chibi propio; se dibuja por capas con `HeroLook` | `Race.swift`, `HeroLook.swift`, `HeroArt.swift` | `characters/razas.md` |
| Armadura | 4 huecos (casco, peto, guantes, botas), 18 diseños, materiales metal/cuero/tela, tinte; se forja en la armería con ruleta | `Armor.swift`, `ArmoryView.swift` | — |
| Combate | Ataque automático en arco; enemigos cuerpo a cuerpo, a distancia y de embestida con aviso | `CombatScene.swift`, `Nodes.swift` | — |
| Enemigos | 50 (4 por nivel + 10 jefes), cada jefe suelta una pieza única | `Enemy.swift`, `EnemyArt.swift` | `characters/enemigos.md` |
| Minerales | 10, con probabilidad de aparición y bonificación al forjar. En la historia sale solo la familia del continente (Valdemar: cobre, hierro, plata, oro, esmeralda, 35/27/20/12/6); la arena, los 10 | `Mineral.swift`, `ContinentLoot.swift` | — |
| Piezas | 120 normales (hoja, guarda, empuñadura × materiales) + 11 únicas | `Parts.swift`, `WeaponArt.swift` | `design/catalogo.md` |
| Ritual y ruleta | 3 piezas + minerales; la ruleta multiplica ×0,6 a ×2; la suerte la inclina | `Crafting.swift` | — |
| Habilidades | 39 secretas según los elementos de las piezas | `Ability.swift` | `design/catalogo.md` |
| Forja del enano | Tienda de piezas, armadura y pociones. En la historia vende el tier del continente (Valdemar: 1; 2 tras `valdemar.rey_goblin`) y el herrero cuenta el epílogo; en la arena sube con las oleadas | `Shop.swift`, `ShopModel.swift` | — |
| Pueblo | Mapas en texto, zonas, puertas, interiores, aldeanos, castillo | `Town.swift`, `ExploreScene.swift` | `maps/` |
| Mundo (continentes) | 6 continentes (niveles 1-60). Motor de Valdemar (fase 1): salidas `>` entre áreas con bloqueos y aviso, cartel de área y nivel, monstruos de campo que reaparecen (90 s lejos o al volver; jefes no), punto seguro al morir, misiones (aceptar con "!", entregar con "?", diario en la pausa, objetivo en el HUD), castillo = `liberar` + `abadia` + `pedregal`, casa del alcalde tras `hilos`, mazmorras de historia (oleadas fijas en un piso de la arena; el jefe habla con `StoryDungeon.bossSpeaker`, p. ej. «Abad Morcar»), presentaciones de jefe guardadas en el perfil (no se repiten), pistas que se releen más cortas (`NPC.talk`), escena corta la primera vez en un área (`ValdemarDialogue.firstVisitScenes`), bocadillos de la forja según la etapa (en la arena, los de siempre), botín de la familia del continente, forja de la historia con su tier (+1 tras la misión final), mapa del continente en la pausa | `World.swift`, `WorldRules.swift`, `Quest.swift`, `QuestEngine.swift`, `StoryDungeon.swift`, `ContinentLoot.swift`, `Valdemar.swift`, `ValdemarQuests.swift`, `ValdemarDialogue.swift`, `ExploreSession.swift`, `ExploreScene.swift`, `BattleSession.swift` | `world/`, `world/continentes/valdemar/contrato.md`, `story/valdemar.md` |
| Editor de armas | El jugador dibuja su arma en pixel-art | `PixelEditorView.swift` | — |
| Ajustes en vivo | El panel web publica un documento `GameTuning` (JSON, solo lo que cambia) y el juego lo aplica al abrirse sobre los valores del código: monstruos (vida, daño, velocidad, cadencia, alcance, nivel, botín, XP/oro, jefes de la historia), piezas, armaduras, minerales, niveles de áreas y zonas, qué monstruo sale en cada spawn, mazmorras de historia, recompensas de misiones y rescates, ruleta y economía global. Valida (ids desconocidos fuera, rangos recortados, avisos) y no toca lo ya forjado. `make datos` exporta los valores base a `admin/public/data/` | `GameTuning.swift`, `TuningSchema.swift`, `TunedData.swift`, `Harness/ExportarDatos.swift` | `admin/contrato.md` |
| Guardado | Perfil en JSON; campos nuevos opcionales (también `currentAreaID`, `quests`, `visitedAreaIDs`, `wonDungeons`, `seenBossIntros`, `readClueIDs` y `TownProgress.fieldZonesLiberated` del modo historia) | `PlayerProfile.swift`, `SaveStore.swift` | — |

## Decisiones tomadas

| Fecha | Decisión | Motivo |
|---|---|---|
| 2026-10-06 | Ataque automático, el jugador solo se mueve | Juego de móvil, una mano, foco en la forja |
| 2026-10-06 | Todo el pixel-art se dibuja en código | Variantes por paleta, sin depender de ficheros de imagen |
| 2026-10-06 | Mismo tamaño de pixel para todo | El arma no cuadraba con el cuerpo |
| 2026-10-06 | El modo principal es un pueblo explorable, no niveles | Petición del usuario: zonas, casas, aldeanos, castillo |
| 2026-10-06 | La arena son oleadas infinitas | Progresión incremental sin final y para conseguir botín |
| 2026-10-07 | Inicio con selección y creación de personaje (estilo World of Warcraft) | Petición del usuario: nombre, raza visible, varios personajes |
| 2026-10-07 | La armadura se divide en casco, peto, guantes y botas, forjables y teñibles | Petición del usuario: equipo personalizable de diseño |

## Preguntas abiertas

- Nombre del juego.
- Historia completa (ver `story/historia.md`) y qué hay después de Valdehierro (Mundo 2).
- ¿Las razas tendrán habilidades propias además de estadísticas?
- ¿Misiones secundarias? ¿Sonido y música?
- Mapa definitivo del Mundo 1 (lo prepara el usuario → `maps/borradores/`).

## Decisiones del 2026-10-07: niveles, arena roguelike, mundo y cuentas

- **Niveles del personaje 1-60** (como un MMO). Experiencia por matar según la diferencia de nivel; cada nivel da
  vida, ataque y defensa. Pegar a enemigos de más nivel cuesta (0,4-1,5× según la diferencia). (`Leveling.swift`)
- **Minerales escasos**: los enemigos sueltan un 30% de lo que soltaban; los jefes, la mitad de tiradas.
- **Arena roguelike pura**: cada partida empieza desde cero (nivel 1, espada de entrenamiento, 20 de oro); se sube de
  nivel y se forja dentro de la partida; al acabar, todo se pierde menos el récord. Si no mejoras el equipo, la
  dificultad te pasa por encima.
- **Modo historia: 6 continentes** de 10 niveles cada uno; el primero empieza en Valdehierro. Biblia en `assets/world/`.
  Se diseñan los 6 y se implementa el primero entero.
- **Cuentas con usuario y contraseña en Supabase**; los personajes se guardan en la nube (`backend/`).
