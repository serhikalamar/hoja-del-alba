# Valdemar · encargos para el equipo

Responsable: `continent-lead` de `valdemar`. Cada encargo se puede pegar tal cual al agente. Todos deben leer antes
`CLAUDE.md`, `assets/world/continentes/valdemar/historia.md`, `zonas.md` y lo que su encargo cite.
Ninguno hace commits (solo el usuario los pide). Al terminar, cada uno anota su línea en `assets/design/tareas.md`.

## Orden y paralelismo

```
Fase 0  game-programmer ── P0 "contrato de datos" (corto; bloquea todo lo que es código)
           │
Fase 1  ┌─ game-programmer  P1 motor (M1-M7) y luego P2 (M8-M10)
(paral.)├─ map-designer     MD áreas nuevas + cambios del pueblo           ← solo datos de mapas
        ├─ character-designer CD acólito + NPC nuevos + filtro de la arena ← solo Enemy.swift / NPCLooks
        └─ story-writer     SW1 guion completo en assets/story/ (sin tocar src/)
           │
Fase 2  ┌─ environment-artist EA bioma Valdemar, casillas y edificios nuevos   (necesita P0 + MD)
(paral.)├─ pixel-artist     PA acólito, Capitán, carta, cartel, "!"/"?"        (necesita CD)
        └─ story-writer     SW2 textos al código                              (necesita P1 + MD)
           │
Fase 3  balance-designer   B1 ritmo 1→10, jefes, piezas, minerales, forja     (con todo jugable)
           │
Fase 4  qa-tester          QA verificación completa
```

## Quién toca qué (para no pisarse)

| Fichero | Dueño en fase 1-2 | Otros (solo después, en fases posteriores) |
|---|---|---|
| `src/GameCore/Sources/GameCore/Town.swift` — **tipos** (`Tile`, `Building`, `BuildingStyle`, `Spawn`, `Zone`, `NPC`, `NPCRole`, `AreaMap`, `TownProgress`) | game-programmer | — |
| `Town.swift` — **datos** dentro de `enum Valdehierro { … }` (filas, edificios, zonas, spawns, interiores, NPC) | map-designer | story-writer (SW2: textos de `plea`/`thanks`), balance-designer (B1: `Reward`) |
| `GameCore/World.swift` (nuevo: `Continent`, `World`, `AreaExit`, `AreaKind`, `Biome`) | game-programmer | — |
| `GameCore/Quest.swift` (nuevo: modelo y motor de misiones) | game-programmer | — |
| `GameCore/StoryDungeon.swift` (nuevo: mazmorras de historia) | game-programmer | — |
| `GameCore/Valdemar.swift` (nuevo: las 5 áreas + `mayor` + `StoryDungeon` cripta/calabozos) | map-designer | balance-designer (B1: oleadas) |
| `GameCore/ValdemarQuests.swift` (nuevo: las 11 misiones como datos) | game-programmer (con textos provisionales de `historia.md`) | story-writer (SW2: textos), balance-designer (B1: recompensas) |
| `GameCore/Enemy.swift` | character-designer (acólito) | balance-designer (B1: fórmula y números) |
| `GameCore/Arena.swift` | character-designer (filtro: solo los 50 originales) | — |
| `GameCore/Mineral.swift`, `Leveling.swift`, `Shop.swift`, `PlayerProfile.swift` | game-programmer | balance-designer (B1: números) |
| `GameCore/Parts.swift` | — | balance-designer (B1) |
| `GameTest1/Game/ExploreScene.swift`, `ExploreSession.swift`, `BattleSession.swift`, `Views/*` | game-programmer | story-writer (SW2: textos de `ExploreSession`) |
| `GameTest1/Art/TownArt*.swift`, `VillageArt.swift`, nuevo `Art/FieldArt*.swift` | environment-artist | — |
| `GameTest1/Art/EnemyArt.swift`, `NPCLooks.swift`, `HeroArt.swift` | character-designer (aspecto básico) → pixel-artist (fase 2) | — |
| `tools/Harness/Sources/Harness/main.swift` | game-programmer | balance-designer (B1: simulación de historia) |
| `src/GameCore/Tests/…` | cada uno sus tests nuevos (ficheros propios: `WorldTests`, `QuestTests`, `ValdemarMapTests`, …) | — |
| `assets/story/` | story-writer | — |
| `assets/maps/` | map-designer | — |
| `assets/characters/` | character-designer | — |
| `assets/art/` | environment-artist / pixel-artist (cada uno su sección) | — |
| `assets/balance/` | balance-designer | — |
| `project.yml` / `make project` | quien añada ficheros a la app (programmer, environment-artist) — avisar antes | — |

---

## P0 · game-programmer · contrato de datos (Fase 0, bloquea)

**Qué**: añadir los tipos que necesitan los demás, **sin lógica todavía**, con valores por defecto para que todo lo que
existe compile igual. Es corto (≤ medio día) y deja a map-designer y character-designer trabajar en paralelo.

1. `Tile`: casillas nuevas de exterior (leyenda común de `continentes.md`): `dirt "d"`, `tallGrass "%"`, `bridge "p"`,
   `rock "R"`, `cliff "^"`, `grave "+"`, `tent "n"`, `campfire "x"`, `cave "e"`, `areaExit ">"`.
   Sólidas: `R ^ + n x`. Pisables: `d % p e >`. (Hoy un carácter desconocido se lee como hierba: cuidado.)
2. `BuildingStyle`: `ruinedMill`, `burnedFarm`, `abbeyChurch`, `rangerHut`, `watchtower` (hasta que el
   environment-artist los dibuje, que usen el dibujo de `mill`, `house`, `chapel`, `house`, `house`).
3. `World.swift`: `enum AreaKind { town, interior, field }`, `enum Biome { valdemar }` (el pueblo usa `valdemar`),
   `struct AreaExit { id; tiles: [TilePoint]; toArea: String; arrival: TilePoint?; lock: ExitLock? }`,
   `enum ExitLock { zoneLiberated(String), questDone(String), castleOpen, comingSoon(String) }`,
   `struct Continent { id; name; levels: ClosedRange<Int>; capitalID; areaIDs; minerals: [Mineral]; tier: Int }`,
   `enum World { static let continents; static func area(_ id) -> AreaMap?; static var areas }`.
4. `AreaMap` gana (con valor por defecto): `kind`, `biome`, `continentID = "valdemar"`, `exits: [AreaExit] = []`,
   `safePoint: TilePoint? = nil`, `dungeonEntrances: [String: TilePoint] = [:]` (id de mazmorra → casilla `e`).
   `isInterior` pasa a ser `kind == .interior` (hoy es `id != "town"`: rompería las áreas nuevas).
5. `NPCRole`: `questGiver` (Capitán) y `clue` (carta, cartel). `NPC` gana `appearsWhen: StoryCondition? = nil`.
6. `Quest.swift` (solo tipos): `Quest { id, giverID, title, summary, requires: [StoryCondition], objectives:
   [QuestObjective], reward: QuestReward, autoAccept, completesOnLastObjective }`,
   `QuestObjective { rescue([String]), kill(enemyIDs: [String], count: Int, areaID: String?), defeat(enemyID),
   talk(npcID), read(npcID), clear(areaID), dungeon(id), reach(areaID) }`,
   `QuestReward { xp, gold, minerals, partID?, gearID? }`, `StoryCondition { questDone(id), rescued(id),
   zoneLiberated(id) }`.
7. `StoryDungeon.swift` (solo tipos): `StoryDungeon { id, name, floorID, level, waves: [[String: Int]],
   bossID: String?, bossEscort: [String: Int], repeatable, entranceAreaID }`.
8. `PlayerProfile` (todo **opcional**): `currentAreaID: String?`, `quests: [String: QuestState]?`
   (`QuestState { accepted, progress: [Int], done }`).

**Hecho cuando**: `make test` y `make verify` pasan sin cambiar el comportamiento del juego; los tipos están en
`main` del árbol de trabajo y se avisa al hilo principal para lanzar la fase 1.

---

## P1 · game-programmer · motor del continente (Fase 1)

Lee el brief (§7) y `zonas.md`. Prioridades del brief: M1-M7 (P1), luego M8-M9 (P2) y M10 (P3).

> **Estado (2026-10-08, game-programmer): HECHO M1-M10.** Reglas en GameCore (`WorldRules.swift`, `QuestEngine.swift`,
> `ContinentLoot.swift`, `StoryDungeon.swift`), datos en `ValdemarQuests.swift` (11 misiones con los textos de
> `assets/story/valdemar.md`) y `ValdemarDialogue.swift` (intro por raza, jefes, avisos, HUD). App: `ExploreSession`,
> `ExploreScene`, `BattleSession` (modo historia), `ExploreView` (diario y mapa en la pausa). Pruebas: `QuestTests`,
> `WorldRulesTests`, `make check-valdemar` (dentro de `make verify`) y `Harness valdemar-shots`.
> Decisiones: `kill` cuenta tras aceptar; `defeat`/`rescue`/`clear`/`dungeon`/`reach` se miran en el perfil; `talk`/`read`
> solo cuentan con los objetivos anteriores cumplidos. Perfiles con la princesa rescatada: `liberar` y `rey_goblin`
> hechas al cargar (sin recompensa). `Leveling.storyBossMultiplier` (hoy ×12, para B1). Sin hacer: sesgo ×1,5 de mineral
> por área (opcional), `forgeLevel`/`maxArmorTier` de la armería siguen como antes (B1 decide si pasan al tier del continente).

| # | Qué | Detalle y criterio |
|---|---|---|
| M1 | Viajar entre áreas | Pisar una casilla de un `AreaExit` → fundido → área `toArea` en `arrival` (si es `nil` o tiene `lock` cerrado: aviso, no se viaja). `ExploreSession` usa `World.area(id)` en vez de `Valdehierro.area`. Guardar `currentAreaID` y volver a ella al cargar. Nombre del área al entrar ("Bosque de Robleda · 6-7"). Avisos de bloqueo: textos en `mapas/valdehierro.md`. |
| M2 | Reaparición de campo | En áreas `kind == .field`, los spawns que **no** son jefe reaparecen: al volver a entrar en el área, o 90 s después de morir si el héroe está a más de 10 casillas. Se guardan en memoria (no en `killedSpawns`). Jefes de campo, pueblo, interiores y castillo: permanentes como hoy. El toast "¡Zona liberada!" solo la primera vez. |
| M3 | Misiones | Motor en `Quest.swift` + datos en `ValdemarQuests.swift` (las 11 de `historia.md` §4, con sus reglas: `kill` cuenta tras aceptar y solo en su área; `defeat` cuenta aunque el jefe muriera antes). "!"/"?" amarillos sobre el NPC; diálogo de oferta/entrega; diario en la pausa (activas y hechas, con progreso "4/6"). Entregar da XP (`gainXP`), oro, minerales, pieza. `valdemar.liberar` se acepta sola. Aldeanos rescatados aparecen en la calle (posiciones en `mapas/valdehierro.md`). |
| M4 | Castillo y alcalde | `castleOpen` = `liberar` + `abadia` + `pedregal` hechas (no usar `defeatedBosses`). Escalinata `S` bloqueada hasta entonces (aviso del Capitán). Ya no se abre al rescatar al 6.º aldeano: aparece el Capitán. Casa `mayor` cerrada hasta `valdemar.hilos`. NPC `clue` se lee al acercarse con la sala despejada. |
| M5 | Casillas y bioma | Lógica de las casillas nuevas (sólidas/pisables) y que `TownArt.ground` reciba el bioma (el dibujo lo hace el environment-artist en fase 2; mientras, un color plano por casilla). |
| M6 | Botín y forja por continente | En áreas con `continentID` = valdemar: `Mineral.roll` con los 5 de `minerales.md` (35/27/20/12/6). Arena intacta (sus 10). `rarityTier`/`value` a datos explícitos por mineral. Forja de la historia: tier 1; tier 2 tras `valdemar.rey_goblin`. XP de jefes de historia: dejar el multiplicador como parámetro (`Leveling.storyBossMultiplier`) para que B1 lo ajuste. |
| M7 | Continentes como datos | `World.continents` con Valdemar completo (áreas, familia, tier). Rocaforja solo como id reservado para la salida bloqueada del Paso. |
| M8 | Mazmorra de historia (P2) | Pisar una `e` con entrada registrada abre una partida de `BattleScene` en el piso indicado: oleadas fijas de `StoryDungeon`, nivel fijo, sin forja ni reinicio, jefe por la `BBB` (+ escolta y diálogo antes del jefe). Ganar → vuelve a la `e`, cuenta para `dungeon(id)`. Perder → punto seguro del área. Repetible. |
| M9 | Reaparecer en el punto seguro (P2) | Morir en un área de campo → `safePoint` del área; en el pueblo/interiores → Puerta sur como hoy. |
| M10 | Orientación (P3) | Cartel de área+nivel al cruzar de zona; mapa del continente en la pausa (esquema de `zonas.md` §1 con las áreas visitadas). |

Además: `make maps` debe renderizar **todas** las áreas de `World.areas` (no solo el pueblo); `make check-town`
ampliado (o `make check-valdemar`) con: salir por las 4 salidas y volver, bloqueo del norte/oeste/este, aceptar y
entregar una misión de matar, reaparición de un monstruo de campo, condición nueva del castillo, entrada en `mayor`.

**Hecho cuando**: tests nuevos (`WorldTests`, `QuestTests`, `StoryDungeonTests`) en verde; `make verify` pasa; con un
perfil de prueba se puede ir del pueblo a las 5 áreas y volver, completar `valdemar.molino` y entrar en la cripta.

---

## MD · map-designer · áreas nuevas y cambios del pueblo (Fase 1, tras P0)

**Fuente**: `assets/world/continentes/valdemar/mapas/*.md` — filas ya validadas y listas, con tablas de edificios,
zonas, spawns (posición, enemigo, tipo), NPC, salidas y llegadas. **No hay que rediseñar**: transcribir y revisar.

1. Nuevo `src/GameCore/Sources/GameCore/Valdemar.swift`: `enum Valdemar` con `huertos`, `robleda`, `abadia`,
   `pedregal`, `paso` (`AreaMap` con `kind: .field`, `biome: .valdemar`, `exits`, `safePoint`, zonas, spawns con los
   ids exactos `valdemar.<zona>.<n>` en el orden de las tablas) y las dos `StoryDungeon` (`valdemar.cripta`,
   `valdemar.calabozos`) con las oleadas de `zonas.md` §3. Registrar todo en `World`.
2. En `Town.swift`, **solo dentro de `enum Valdehierro`**: filas nuevas del pueblo (`mapas/valdehierro.md`), `entry`
   (21,33), `courtyard` nivel 9, `exits` del pueblo con sus bloqueos, `mayor.interiorID = "mayor"`, interior `mayor`
   (`mapas/casa_alcalde.md`), entrada `e` de los calabozos, NPC `capitanGuardia` y posiciones de calle de los aldeanos.
   No cambiar ningún id existente.
3. Actualizar `assets/maps/valdehierro.md` y crear `assets/maps/valdemar.md` (resumen de áreas y render).

**Comprobar**: `make test` (añadir `ValdemarMapTests`: filas iguales, borde cerrado salvo `>`, todo conectado desde
`entry`, spawns pisables y en zona, cada `AreaExit` lleva a un área que existe y su `arrival` es pisable en el destino),
`make maps` y mirar los PNG de las 6 áreas. **Hecho cuando** los tests pasan y los renders coinciden con los borradores.

---

## CD · character-designer · acólito, NPC nuevos y arena (Fase 1, tras P0)

1. `Enemy.swift`: añadir `eclipseAcolyte` (ficha en `bestiario.md` §3; números provisionales, B1 los cierra).
2. `Arena.swift`: la arena solo usa **los 50 enemigos originales** (lista explícita o marca `inArena`), y los jefes de
   la arena son los 10 originales: así ni el acólito ni los futuros jefes de otros continentes entran en la arena.
3. Aspecto básico (`EnemyArt.spec` del acólito; looks `guardCaptain`, `letter`, `signpost` en `NPCLooks.swift`),
   suficiente para jugar; el detalle lo hace el pixel-artist.
4. `assets/characters/`: fichas del acólito y del Capitán Vela, el alcalde Fausto (no aparece) y la tabla "qué enemigo
   va en cada área" de `bestiario.md` §1. Regenerar fichas con `make fichas`.

**Comprobar**: `make test`, `make balance` (la arena igual que antes: mismas oleadas de caída que en
`assets/balance/README.md`), `make sprites` y mirar el acólito. **Hecho cuando** todo eso pasa.

---

## SW1 · story-writer · guion del capítulo 1 (Fase 1, sin tocar `src/`)

Escribe `assets/story/valdemar.md` (y actualiza `assets/story/historia.md`: decisiones ya tomadas, lugares nuevos,
personajes) a partir de `historia.md` del lead. Todo con **ids** para pegarlo después:
- Las 11 misiones: título, oferta (2-3 líneas), recordatorio (1), entrega (2-3), texto del diario (1).
- Diálogos nuevos de los 6 aldeanos tras el rescate (en la calle), del Capitán Vela (aparición, escalinata cerrada,
  apertura), carta del alcalde, cartel del Paso, confesión del Abad (antes del jefe de la cripta), Aurora (cambio
  menor: ahora menciona al Eclipse), epílogo del herrero, avisos de salidas cerradas, una línea de intro por raza.
- Nombres de zonas y áreas tal como están en `zonas.md` (si propones otro, anótalo; no cambia ids).

Frases cortas (móvil). **Hecho cuando** cada texto tiene su id y el lead/usuario lo da por bueno.

## SW2 · story-writer · textos al código (Fase 2, tras P1 y MD)

Pegar los textos de SW1 en `ValdemarQuests.swift`, en los NPC de `Valdehierro`/`Valdemar.swift` (`plea`, `thanks`,
diálogos) y en `ExploreSession` (intro, avisos). **Comprobar**: `make test`, `make check-town`. Nada de lógica.

---

## EA · environment-artist · bioma de Valdemar (Fase 2, tras P0 + MD)

Dibujar en código (nuevo `Art/FieldArt*.swift` si hace falta, enganchado desde `TownArt`) y verificar en los PNG:
- Casillas nuevas en bioma `valdemar`: camino de tierra `d` (con bordes que se funden con la hierba), hierba alta /
  trigal `%` (dorado en Huertos, verde-seco en el Pedregal, maleza en la abadía: puede depender del área o de la
  zona), puente de madera `p`, roca `R`, acantilado `^` (tapa + cara, como los muros de la mazmorra), lápida `+`
  (en el Pedregal, tótem orco: variante por área), tienda `n`, hoguera `x` (animada, con luz), bajada a la cripta `e`
  (escalera de piedra hacia abajo, con resplandor violeta tenue), salida `>` (el suelo del camino que sigue +
  una flecha/indicador sutil o niebla en el borde).
- Casillas existentes que ahora salen fuera del pueblo: `w` (muro **en ruinas** en la abadía), `=` (losas del
  claustro), `I` (columna exterior), `~` (río y estanque; pozas **heladas** en el Pedregal), `f` (valla de granja,
  valla de cementerio y empalizada de troncos: variantes por área), `T` (roble; árboles muertos en la abadía).
- Edificios nuevos: `ruinedMill`, `burnedFarm`, `abbeyChurch` (iglesia gótica pequeña en ruinas, puerta de 2),
  `rangerHut`, `watchtower`.
- Ambiente: niebla baja en la abadía, polvo/ceniza en los trigales quemados, humo en los campamentos.

**Comprobar**: `make maps` y `make shots`; mirar los 6 renders. **Hecho cuando** cada área se lee de un vistazo y
no hay casillas "planas" de color.

## PA · pixel-artist · personajes y objetos nuevos (Fase 2, tras CD)

Acólito del Eclipse detallado (paso, ataque a distancia con esfera violeta, daño) según `bestiario.md` §3; Capitán
Rodrigo Vela (`guardCaptain`); objetos `letter` y `signpost`; iconos "!" y "?" de misión (amarillo, con contorno);
opcional: conjunto `*.valdemar` (piezas.md §3). **Comprobar**: `make sprites`, `make hero` si toca, mirar PNG.

---

## B1 · balance-designer · ritmo 1→10 y números (Fase 3, con todo jugable)

1. **Simulación nueva del modo historia** en el harness (`make historia`): bot con equipo tier 1 que recorre el
   orden de `historia.md` §5 matando cada monstruo de campo una vez, haciendo las misiones y la cripta; imprime el
   nivel en cada hito. Objetivo: **~6 al liberar el pueblo, ~9 al entrar al patio, 10 al vencer al Rey Goblin**
   (primera estimación del lead en `zonas.md` §4: hace falta bajar el ×12 de los jefes de historia a ~×6).
2. Recompensas de misiones (`ValdemarQuests.swift`), de aldeanos y princesa (`minerales.md`: nada fuera de la familia).
3. Piezas de jefe a la escala de Valdemar (`piezas.md` §2) y la Hoja del Alba (I) a la altura del tier 2.
4. `eclipseAcolyte` y jefes de campo (Ogro a nivel 6, Lobo alfa 7, Abad 8, Señor de la guerra 9): objetivos de
   `progresion.md` §7 (jefe de zona 40-60 s, jefe final 60-120 s).
5. Oleadas de la cripta y los calabozos (`zonas.md` §3) y premio de la cripta.
6. Fórmula de `EnemyDefinition.stats(level:)` medida de 1 a 60 (`progresion.md` §7), sin cambiar la arena.

**Comprobar**: `make balance` (arena sin cambios o con cambios explicados), `make historia`, `make test`.
Documentar antes/después en `assets/balance/`.

---

## QA · qa-tester · verificación (Fase 4)

- `make verify`, `make test`, `make check-town` (ampliado), `make maps`, `make shots`, `make balance`, `make historia`.
- Recorrido manual (simulador o Mac): partida nueva → pueblo → las 4 salidas (y sus avisos de bloqueo) → las 5 áreas
  → cada misión aceptada y entregada → reaparición de campo → morir en un área (punto seguro) → casa del alcalde →
  cripta (ganar y perder) → castillo cerrado hasta tener Abad + Señor de la guerra → Rey Goblin → Hoja del Alba →
  herrero → Paso del Norte → cartel "Próximamente" de Rocaforja.
- **Partida guardada antigua** (v0.5) carga sin perder nada; un perfil que ya tenía la princesa rescatada no queda
  bloqueado (decidir con el programmer: se marcan como hechas `liberar` y `rey_goblin`).
- La arena no ha cambiado (mismos enemigos, minerales y jefes).

Informe con pasos para reproducir. **Hecho cuando** no quedan fallos bloqueantes.

---

## Estado

- **Fase 0 (P0, contrato de datos): HECHA** (2026-10-07, `game-programmer`). Tipos y campos en `World.swift`,
  `Quest.swift`, `StoryDungeon.swift`, `Town.swift` y `PlayerProfile.swift`; huecos vacíos y ya registrados en
  `World` para `Valdemar.swift` (map-designer) y `ValdemarQuests.swift`. El juego no cambia. Referencia de los
  tipos, cambios respecto a este plan (`dungeonEntrances` es una lista de `DungeonEntrance` porque la cripta tiene
  `ee`; `AreaExit.lockedMessage`; `StoryDungeon.bossIntro`/`reward`; `PlayerProfile.visitedAreaIDs`; el antiguo
  `struct World` de `Level.swift` pasa a `LevelWorld`) y qué hace cada agente: **`contrato.md`**.
  Se puede lanzar la **Fase 1**.
- **MD (map-designer): HECHO** (2026-10-07). `Valdemar.swift` con las 5 áreas de campo (87 spawns, ids
  `valdemar.<área>.<n>`), `Valdemar.dungeons` (cripta y calabozos) y, en `enum Valdehierro`: filas nuevas, entrada
  (21,33), 4 salidas con bloqueos y avisos, `e` de los calabozos (`.castleOpen`), patio a nivel 9, casa del alcalde
  (`mayor`, interior 14×9 con `cartaAlcalde`), Capitán Vela y los 6 aldeanos en la calle (`appearsWhen`). Cambio sobre
  el borrador: **dos poternas** en la muralla del patio (7,4-5) y (36,4-5), porque la franja de la salida norte y la
  llegada desde el Paso (4,2) quedaban aisladas por la panadería y la tejedora. Tests: `ValdemarMapTests.swift`.
  `make maps` dibuja todas las áreas de `World.areas` y un plano esquemático `plan_<área>.png` por exterior.
  Resumen: `assets/maps/valdemar.md` y `valdehierro.md`.
- **CD (character-designer): HECHO** (2026-10-08). `eclipseAcolyte` en `Bestiary.all` (nivel 7, `human`, `ranged`,
  números de `bestiario.md` §3; B1 los cierra), al final de la lista bajo "Monstruos de continente". La arena usa solo
  `Arena.originalEnemyIDs` (lista explícita de los 50 originales; `Arena.enemies` conserva el orden del bestiario, así
  las oleadas salen idénticas) y sus jefes son los 10 originales; las oleadas antiguas de `Worlds.village`
  (`Level.swift`) filtran igual. Aspecto básico: `EnemyArt.spec("eclipseAcolyte")` (túnica ceniza, cara en sombra con
  ojos violeta, luna negra en el pecho `eclipseMoon`, faja `sash`, libro colgado del cinto con cadena, rasgo `tomeAtHip`; ataque `orbCaster`), esfera violeta en
  `ProjectileNode`; `guardCaptain` en `NPCLooks` (chibi) y `EnemyArt`; `letter` y `signpost` como objetos fijos
  (`EnemyArt.objectRows`). `make sprites` genera también `npcs_chibi.png`. Fichas en `assets/characters/conceptos.md`;
  tests `ContinentEnemyTests.swift`. `make test`, `make check-town`, `make check-valdemar` en verde. **Pendiente PA**:
  detalle del acólito (paso, ataque, esfera), Capitán (barba, capa, casco bajo el brazo), carta y cartel.
- **B1 (balance-designer): HECHO** (2026-10-09). (1) `make historia` (`tools/Harness/Sources/Harness/Historia.swift`):
  bot de partida nueva con combate real, esquiva, misiones, forja (piezas de jefe incluidas), mazmorras, ruleta y
  subida de nivel ante muros; mide nivel por zona, muertes, oro, minerales y duración de los jefes. (2) Ritmo: XP de los
  monstruos que reaparecen ×0,3 (`Leveling.respawningMultiplier`) y misiones de fuera ×~0,5 → pueblo 6,2 · patio 9,0 ·
  Rey Goblin 9,8 · fin 10,0 (8 partidas). (3) Oro de la historia en `StoryEconomy` (≈ ÷5); aldeanos, princesa y
  misiones solo con la familia de Valdemar (Anselmo: `head.mace.iron`); precios de la forja sin tocar (son los de la
  arena). (4) Piezas de jefe propias de Valdemar (`boss.<jefe>.valdemar`, tier 1, ≈1,5-1,75× T1) y Hoja del Alba (I) en
  tier 2. (5) Jefes de historia ajustados solo en la historia (`EnemyDefinition.storyBossTuning`): Ogro, Lobo alfa, Abad
  ~40-60 s; Señor de la guerra y Rey Goblin ~60 s, sin muros (~2 muertes por partida en total). (6) Cripta: esmeralda
  solo la primera vez, 50 % de oro ×1 en cada victoria. Oleadas de Cripta/Calabozos y acólito, sin cambios (cumplen).
  Bug arreglado en `CombatScene`: el rayo de `strikeEvery` despertaba jefes del otro extremo del mapa. Arena sin
  cambios. Tests `StoryBalanceTests`. Detalle: `assets/balance/README.md` § Historia. Pendiente (no bloquea):
  `stats(level:)` de 1 a 60 cuando exista el continente 2.
