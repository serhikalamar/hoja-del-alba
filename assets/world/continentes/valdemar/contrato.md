# Valdemar · contrato de datos (Fase 0)

Responsable: `game-programmer`. Hecho el 2026-10-07. Es la referencia de los **tipos** que usan en la fase 1 el
`map-designer`, el `character-designer`, el `story-writer` y el propio `game-programmer`. Aquí solo hay datos y
consultas sencillas: **no hay motor todavía** (viajar, reaparecer, misiones, mazmorras de historia → fase 1, `encargos.md` P1).

Todo lo existente funciona igual: Valdehierro y sus interiores, la arena y las partidas guardadas antiguas.
Tests del contrato: `src/GameCore/Tests/GameCoreTests/WorldTests.swift` (se aplican solos a los datos nuevos).

## 1. Ficheros

| Fichero (`src/GameCore/Sources/GameCore/`) | Qué hay | Quién lo rellena en la fase 1 |
|---|---|---|
| `Town.swift` (tipos) | `Tile` con 10 casillas nuevas, `BuildingStyle` con 5 estilos nuevos, `NPCRole.questGiver/.clue`, `NPC.appearsWhen`, `AreaMap.kind/biome/continentID/exits/safePoint/dungeonEntrances` | Tipos: game-programmer. Datos de `enum Valdehierro`: map-designer |
| `World.swift` (nuevo) | `AreaKind`, `Biome`, `ExitLock`, `AreaExit`, `DungeonEntrance`, `Continent`, `enum World` (registro) | game-programmer |
| `Quest.swift` (nuevo) | `StoryCondition`, `QuestObjective`, `QuestReward`, `Quest`, `QuestState` | game-programmer (motor M3) |
| `StoryDungeon.swift` (nuevo) | `StoryDungeon` | game-programmer (partida M8) |
| `Valdemar.swift` (nuevo, **vacío**) | `Valdemar.areas` (5 campos) y `Valdemar.dungeons` (cripta, calabozos) | **map-designer** |
| `ValdemarQuests.swift` (nuevo, **vacío**) | `ValdemarQuests.all` (las 11 misiones) | game-programmer → story-writer (SW2) → balance-designer (B1) |
| `PlayerProfile.swift` | `currentAreaID`, `quests`, `visitedAreaIDs` (opcionales) y accesos | game-programmer |

`Valdemar.areas`, `Valdemar.dungeons` y `ValdemarQuests.all` **ya están registrados** en `World`: basta con rellenarlos.

## 2. Casillas nuevas (`Tile`)

Leyenda común de `assets/world/continentes.md`. Se dibujan según el bioma del área (fase 2, environment-artist);
hasta entonces el suelo nuevo sale como hierba y las casillas sólidas son invisibles pero bloquean.

| Carácter | Caso | ¿Se pisa? | Notas |
|---|---|---|---|
| `d` | `dirt` | sí | Camino de tierra |
| `%` | `tallGrass` | sí | Hierba alta, trigal, maleza |
| `p` | `bridge` | sí | Puente sobre `~` |
| `e` | `cave` | sí | Bajada a mazmorra: va en `AreaMap.dungeonEntrances` |
| `>` | `areaExit` | sí | Salida: cada `>` tiene que pertenecer a un `AreaExit` (lo comprueba un test) |
| `R` | `rock` | no | Roca |
| `^` | `cliff` | no | Acantilado |
| `+` | `grave` | no | Lápida, estela, tótem |
| `n` | `tent` | no | Tienda de campaña |
| `x` | `campfire` | no | Hoguera, brasero |

Ojo: un carácter desconocido se sigue leyendo como hierba pisable (`AreaMap.tile`). Los tests de los mapas lo cazan
si cae en una casilla que debería ser `>` o `e`.

## 3. Edificios nuevos (`BuildingStyle`)

`ruinedMill`, `burnedFarm`, `abbeyChurch`, `rangerHut`, `watchtower`. Mientras no tengan arte propio se dibujan con
`BuildingStyle.placeholder` (`mill`, `house`, `chapel`, `house`, `house`): la app usa `Building.withPlaceholderStyle`
en `TownArt.building`. El environment-artist, al dibujarlos, cambia el `placeholder` del estilo a sí mismo.

## 4. Áreas (`AreaMap`) y el mundo

Campos nuevos (con valor por defecto, así que los `AreaMap(...)` existentes no cambian):

| Campo | Tipo | Defecto | Para qué |
|---|---|---|---|
| `kind` | `AreaKind` (`town`, `interior`, `field`) | `.field` | `isInterior` ahora es `kind == .interior` (antes `id != "town"`); `isField` para la reaparición (M2) |
| `biome` | `Biome` (`valdemar`) | `.valdemar` | Cómo se dibujan las casillas |
| `continentID` | `String` | `"valdemar"` | Botín y forja por continente (M6) |
| `exits` | `[AreaExit]` | `[]` | Salidas `>` |
| `safePoint` | `TilePoint?` | `nil` | Reaparición al morir (M9). `nil` = Puerta sur del pueblo |
| `dungeonEntrances` | `[DungeonEntrance]` | `[]` | Bajadas `e` a mazmorras de historia |

Consultas: `exit(at:)`, `dungeonEntrance(at:)`, `tiles(of:)`. El pueblo es `.town` y los interiores `.interior`
(ya puesto en `Valdehierro`). Las áreas nuevas se construyen con el inicializador de siempre añadiendo al final
`kind: .field, exits: [...], safePoint: ..., dungeonEntrances: [...]` (en ese orden; `biome` y `continentID` solo si
no son Valdemar).

```swift
AreaExit(id: "huertos.este", tiles: [TilePoint(55, 16), TilePoint(55, 17), TilePoint(55, 18)],
         toArea: Valdehierro.townID, arrival: TilePoint(2, 17))
AreaExit(id: "town.oeste", tiles: [TilePoint(0, 17), TilePoint(0, 18)], toArea: "valdemar.huertos",
         arrival: TilePoint(53, 17), lock: .zoneLiberated("west"),
         lockedMessage: "Los goblins del barrio oeste cortan el camino de los huertos.")
AreaExit(id: "paso.norte", tiles: [...], toArea: "rocaforja", arrival: nil, lock: .comingSoon("rocaforja"),
         lockedMessage: "Montes de Rocaforja: próximamente.")
DungeonEntrance(dungeonID: "valdemar.cripta", tiles: [TilePoint(40, 15), TilePoint(41, 15)])
DungeonEntrance(dungeonID: "valdemar.calabozos", tiles: [TilePoint(34, 7)], lock: .castleOpen)
```

- **`AreaExit`**: `id` (estable, `<área corta>.<punto cardinal>` como en los borradores), `tiles` (las `>`),
  `toArea` (id de área; con `comingSoon`, id del continente), `arrival` (casilla pisable del destino; `nil` = no se
  viaja), `lock`, `lockedMessage` (aviso; lo pule el story-writer).
- **`ExitLock`**: `zoneLiberated(idDeZona)` (zona **del área donde está la salida**: `west`, `east`),
  `questDone(idDeMisión)`, `castleOpen` (la condición nueva del castillo, fase 1), `comingSoon(idDeContinente)`.
- **`DungeonEntrance`**: cambio respecto a `encargos.md` (que pedía `[String: TilePoint]`): es una lista de
  `DungeonEntrance { dungeonID, tiles, lock, lockedMessage }` porque la cripta tiene **dos** casillas (`ee`) y los
  calabozos llevan bloqueo. Al ganar se vuelve a la primera casilla de `tiles`.
- **`Continent`**: `id`, `name`, `levels` (1...10), `capitalID`, `areaIDs` (capital, interiores y campos),
  `minerals` (familia: cobre, hierro, plata, oro, esmeralda), `tier` (1).
- **`World`**: `continents`, `areas`, `area(_:)`, `continent(_:)`, `storyDungeons`, `storyDungeon(_:)`, `quests`,
  `quest(_:)`, `valdemarID`. Hoy `World.continents` solo tiene Valdemar; sus `areaIDs` se calculan solos con
  `Valdehierro.areas + Valdemar.areas`. Rocaforja solo existe como id dentro de `comingSoon` (M7).
- El antiguo `struct World` de `Level.swift` (mundo de 10 niveles por oleadas, solo se usa para fondos) pasa a
  llamarse `LevelWorld`; `Worlds.village` sigue igual.

## 5. NPC

- `NPCRole` gana `questGiver` (el Capitán Vela: da misiones, no se rescata) y `clue` (carta del alcalde, cartel del
  Paso: se lee al acercarse con la sala despejada).
- `NPC.appearsWhen: StoryCondition?` (defecto `nil` = siempre). Capitán: `.questDone("valdemar.liberar")`.
  Aldeanos en la calle tras el rescate: **mismo id** que en su casa (así `Quest.giverID` es uno solo), rol
  `.villager`, `appearsWhen: .rescued("<id>")`, en `Valdehierro.town.npcs`.
- Hasta que llegue el motor (M3-M4), la app **no** mira `appearsWhen` ni los roles nuevos: un NPC añadido al pueblo
  se vería siempre y diría sus `thanks`. Si el map-designer añade NPC antes que el motor, es esperado.

## 6. Misiones (`Quest.swift`)

- **`Quest`**: `id` (`valdemar.<nombre>`, estable: se guarda), `giverID` (id de NPC; el enano herrero es `smithy`),
  `title`, `summary` (línea del diario), `requires: [StoryCondition]` (todas), `objectives`, `reward`, `autoAccept`
  (`liberar`), `completesOnLastObjective` (`alcalde`, `rey_goblin`, `paso_norte`). Ayudas: `enemyIDs`, `areaIDs`.
- **`QuestObjective`**: `rescue([ids])`, `kill(enemyIDs:count:areaID:)` (`areaID: nil` = cualquier área del
  continente; cuenta desde que se acepta), `defeat(enemyID:)` (cuenta aunque el jefe muriera antes),
  `talk(npcID:)`, `read(npcID:)`, `clear(areaID:)`, `dungeon(idDeMazmorra)`, `reach(areaID:)`.
- **`QuestReward`**: `xp`, `gold`, `minerals`, `partID?`, `gearID?`.
- **`StoryCondition`**: `questDone(id)`, `rescued(idNPC)`, `zoneLiberated(idZona)`.
  Ej. `valdemar.abadia`: `requires: [.rescued("anselmo"), .questDone("valdemar.alcalde")]`.
- **`QuestState`** (se guarda): `accepted`, `progress: [Int]` (uno por objetivo, mismo orden), `done`.

## 7. Mazmorras de historia (`StoryDungeon.swift`)

`StoryDungeon { id, name, floorID, level, waves: [[String: Int]], bossID?, bossEscort, repeatable, entranceAreaID,
bossIntro, reward? }`. Añadidos respecto a `encargos.md`: `bossIntro` (diálogo del Abad antes de abrir la `BBB`,
story-writer) y `reward` (premio fijo al ganar; los porcentajes, balance-designer). `floorID` es un piso de la arena
(`crypt`, `prison`…). Ayuda: `enemyIDs` (oleadas + jefe + escolta).

## 8. Perfil (`PlayerProfile`, todo opcional)

| Campo | Tipo | Partida antigua | Acceso con defecto |
|---|---|---|---|
| `currentAreaID` | `String?` | `nil` → el pueblo | `areaID`, `continentID` |
| `quests` | `[String: QuestState]?` | `nil` → ninguna | `questState(_:)`, `isQuestDone(_:)` |
| `visitedAreaIDs` | `Set<String>?` | `nil` | (mapa del continente, M10) |

Un perfil nuevo no escribe estas claves en el JSON. Hay un test que decodifica una partida v0.5 escrita a mano.

## 9. Lo que comprueban los tests (`WorldTests.swift`)

Casillas nuevas y su solidez · estilos provisionales · `kind` del pueblo e interiores · ids de área únicos y
registrados · campos: filas iguales, entrada, punto seguro y spawns pisables · ids de salida únicos · cada `>`
pertenece a un `AreaExit` y cada `AreaExit` está sobre `>` · el destino existe y la llegada es pisable y no está
encima de otra salida (salvo `comingSoon`) · los bloqueos apuntan a zonas/misiones que existen · las `e` son `cave`,
la mazmorra existe y su `entranceAreaID` coincide · pisos y monstruos de las mazmorras existen · cada área está en un
solo continente · misiones: ids únicos, monstruos/áreas/mazmorras/requisitos existentes · perfil antiguo, perfil
nuevo y viaje de ida y vuelta del JSON. El map-designer añade además `ValdemarMapTests` (conectividad, borde cerrado).

## 10. Para cada agente de la fase 1

- **map-designer**: rellena `Valdemar.areas` (`kind: .field`) y `Valdemar.dungeons`; en `Valdehierro`: filas,
  `exits` del pueblo (al final de `AreaMap(... entry:, kind: .town, exits: [...], dungeonEntrances: [...])`),
  `mayor.interiorID`, interior `mayor` (`interior(...)` ya pone `kind: .interior`), NPC nuevos con `appearsWhen`.
  `make test` debe seguir en verde: los tests de esta página validan tus datos.
- **character-designer**: no necesita tipos nuevos (acólito en `Enemy.swift`). Looks nuevos (`guardCaptain`,
  `letter`, `signpost`) son el `look` de los NPC con rol `questGiver`/`clue`.
- **story-writer**: los textos irán a `Quest.title/summary`, `NPC.plea/thanks`, `AreaExit.lockedMessage`,
  `DungeonEntrance.lockedMessage` y `StoryDungeon.bossIntro` (SW2). Los ids de misión de `historia.md` §4 son los
  definitivos.
- **game-programmer (P1)**: el motor lee estos datos: `World.area(id)` en vez de `Valdehierro.area`, `exit(at:)`,
  `dungeonEntrance(at:)`, `ExitLock`/`StoryCondition` contra el perfil, `QuestState` en `profile.quests`,
  `currentAreaID` al guardar. Pendiente de decidir con QA: perfiles con la princesa ya rescatada → marcar
  `valdemar.liberar` y `valdemar.rey_goblin` como hechas al cargar.

## 11. Fase 1 (motor): campos de texto y reglas añadidos

Todos con valor por defecto (los datos existentes compilan igual). Para pegar los textos de `assets/story/valdemar.md`:

| Tipo | Campo nuevo | Para qué |
|---|---|---|
| `Quest` | `offer: [String]`, `reminder: String?`, `turnIn: [String]`, `objectiveLabels: [String]` (`{n}` = progreso) | Oferta ("!"), recordatorio, entrega ("?") y objetivo corto del HUD/diario |
| `NPC` | `talk: [NPCLine]` (`NPCLine(when:unless:_ lines)`) | `npc.<id>.casa` en el NPC de la casa, `npc.<id>.calle.<etapa>` en el de la calle: vale la primera que se cumple |
| `Building` | `lockedMessage: String?` | Aviso de edificios sin interior (molino, granjas, cabaña, iglesia, atalaya) |
| `StoryDungeon` | `bossIntroRepeat`, `bossDefeat` | Diálogo del jefe al repetir y línea al caer (primera vez) |
| `ValdemarDialogue` (nuevo) | intro por raza, líneas de raza, presentaciones de jefes, textos de mazmorras, avisos y objetivo del HUD | Textos que no van en un mapa ni en una misión |
| `ValdemarQuests` | `doorLocks` (castillo, alcalde), `stairsMessage`, `castleOpensLines`, `mapLayout` | Puertas de la historia y mapa del continente |
| `PlayerProfile` | `wonDungeons: Set<String>?`; `TownProgress.fieldZonesLiberated: Set<String>?` | Mazmorras ganadas; zonas de campo liberadas alguna vez |

Reglas: `WorldRules.swift` (viajar, bloqueos, casillas cerradas, reaparecer, `FieldRespawn`, cartel), `QuestEngine.swift`
(misiones, marcas, conversaciones, diario), `ContinentLoot.swift` (familia de minerales, `storyForgeTier`).
