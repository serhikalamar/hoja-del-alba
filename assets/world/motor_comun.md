# Motor común de los continentes 2-6

Responsable: `world-designer` (lista y orden) → `game-programmer` (lo implementa). Estado: **revisión 1** (2026-10-09).
Fuente: las "Necesidades de motor" de `continentes/rocaforja/encargos.md` (N1-N10), `lunaria/encargos.md` (L0, N1-N6),
`cenizas/encargos.md` (C1.1-C1.8), `escarcha/encargos.md` (X1.1-X1.8) y `umbral/encargos.md` (M-U1-M-U13), más lo que ya
hace el código de Valdemar (`src/GameCore/Sources/GameCore/`).

**Para qué sirve**: los cinco leads pidieron, cada uno por su lado, cosas que se solapan (maestro de viajes, pisos de
historia, biomas, quitar lo que solo funciona para Valdemar, fases de jefe…). Aquí están **una sola vez**, ordenadas y
con el continente que las **estrena** (el primero que las necesita: su encargo de Fase 0/1 las hace; los siguientes
solo las usan). Los encargos de cada continente remiten a esta lista: si un punto ya está hecho, no se repite.

Reglas de siempre: todo lo nuevo del perfil es **opcional**; en las listas compartidas solo se **añade al final**; los ids
no se renombran; **la arena no cambia** (`make balance` igual que `assets/balance/README.md`). Cada punto con tests en
GameCore.

## 0. Lo que ya hace el código (no pedirlo otra vez)

| Ya existe | Dónde |
|---|---|
| `Continent` (niveles, capital, áreas, familia de minerales, tier, misión final, castillo, `mapLayout`) | `World.swift` |
| Botín por continente (35/27/20/12/6) y tier de la forja de la historia (+1 tras la misión final) | `ContinentLoot.swift` |
| La arena solo usa los 50 enemigos y 10 jefes originales (`Arena.originalEnemyIDs`; `Arena.wave` elige jefe entre ellos) | `Arena.swift` |
| `rarityTier`, `value`, `dropPercent`, `buffPerUnit` explícitos por mineral | `Mineral.swift` |
| Misiones (`kill`, `defeat`, `talk`, `read`, `rescue`, `clear`, `dungeon`, `reach`), `autoAccept`, `completesOnLastObjective`, `QuestReward.partID/gearID` | `Quest.swift`, `QuestEngine.swift` |
| Mazmorras de historia con oleadas, escolta del jefe, `repeatable`, `bossIntro/bossIntroRepeat/bossDefeat`, `bossSpeaker` | `StoryDungeon.swift` |
| NPC con `appearsWhen` (el mismo id puede estar en dos sitios con condiciones distintas: casa y calle), roles `.villager`, `.princess`, `.questGiver`, `.clue` | `Town.swift` |
| XP de jefes de historia ×6 (`Leveling.storyBossMultiplier`); arena ×12 | `Leveling.swift` |
| Perfil: `currentAreaID`, `quests`, `visitedAreaIDs`, `wonDungeons`, `seenBossIntros`, `readClueIDs` (opcionales) | `PlayerProfile.swift` |
| Tests: ids únicos de áreas, **salidas** (globales), mazmorras y misiones | `WorldTests.swift` |

## 1. Lista única (por orden de construcción)

`P1` = imprescindible para el continente que lo estrena · `P2` = muy recomendable · `P3` = opcional (el diseño
funciona sin ello). "Lo piden" = los ids de las necesidades de cada `encargos.md`, para tacharlas.

### Paquete A · Mundo multi-continente — lo estrena **Rocaforja** (encargo R0)

| # | P | Qué | Lo piden |
|---|---|---|---|
| A1 | P1 | **Registro por continente**: `World.continents`, `areas`, `storyDungeons` y `quests` se construyen concatenando cada continente (`Rocaforja.areas`, `RocaforjaQuests.all`…). Cada continente nuevo = 1 `Continent` + sus ficheros (`<Continente>.swift`, `<Continente>Quests.swift`, `<Continente>Dialogue.swift`), vacíos al principio y registrados. | R N2, L0.1, C1.1, X0, U0 |
| A2 | P1 | **Quitar lo que solo funciona para Valdemar**: `WorldRules.doorLockMessage` lee `ValdemarQuests.doorLocks` → `Continent.doorLocks` (por id de edificio y área); `ValdemarQuests.stairsMessage` → aviso del continente; `QuestEngine` nombra al herrero con `ValdemarQuests.smithID` → nombre del NPC por id (registro de nombres); `respawnPoint` cae a `continents[0]` → capital del continente del área; HUD, avisos y textos de `ValdemarDialogue` → un `<Continente>Dialogue` por continente con una interfaz común. | R N1, L0.5, C (implícito), X, U |
| A3 | P1 | **Castillo vacío = abierto**: con `castleRequires: []`, `castleOpen` debe ser `true` (hoy `false`) y la escalinata `S` de un `.town` no se bloquea. Test. | R N1, L N4 |
| A4 | P1 | **Biomas**: casos nuevos de `Biome` al final, con la regla de nombres de `continentes.md` (§ Biomas): el base se llama como el continente, las variantes `<continente><Variante>`. Dibujo provisional = color plano hasta la fase de arte. Lista cerrada en `continentes.md`. | R N3, L N1, C1.4, X0, U0 |
| A5 | P1 | **Estilos de edificio** nuevos (`BuildingStyle`) con `placeholder` (un estilo existente) hasta que el environment-artist los dibuje, como los de campo de Valdemar. | C1.4, X0, U0 (y los enanos/élficos de R y L si se quieren distintos) |
| A6 | P1 | **Protección de la arena** en un solo sitio: `Mineral.arenaMinerals` (los 10 de hoy; `Mineral.roll` y la tienda de la arena los usan en vez de `allCases`), formas de la arena (`PartCatalog` genera las piezas de la arena solo con las 9/7/5 formas actuales: hoy recorre `allCases`), pisos de la arena (`Dungeon.floors` = los 5 de hoy). Test `ArenaUnchangedTests`: 10 minerales, 50 enemigos, 10 jefes, 9/7/5 formas, 5 pisos. | R N4-N5, C1.3, X1, U0 |

### Paquete B · Progresión por continente — lo estrena **Rocaforja** (encargo R1)

| # | P | Qué | Lo piden |
|---|---|---|---|
| B1 | P1 | **Minerales por familia**: casos nuevos al final de `Mineral` (ids de `continentes.md`). Cada mineral sabe su **continente** y su **rareza en la familia (1-5)**. La suerte del ritual (`Crafting`, `Armor`: hoy `rarityTier - 1`) pasa a usar rareza en la familia + un extra pequeño por continente, para que el mithril no quede por debajo del cobalto. | R N4, L0.8, C1.5, X1.3, M-U8 |
| B2 | P1 | **Bonificación escalada por continente (solo historia)**: las estadísticas planas (ATQ, DEF, VIDA, REGEN.) de un mineral se multiplican por el factor del **continente de su familia** (×1 · ×1,6 · ×2,4 · ×3,3 · ×4,4 · ×5,6); las de porcentaje casi no suben. En la arena, sin factor. Así las 5 joyas antiguas (diamante, amatista, rubí, zafiro, mithril) valen lo que les toca: el mithril de Umbral da VIDA ~67, ATQ ~11, DEF ~11 (`progresion.md` §5). Números: balance-designer. | M-U8 (mithril), C, X (bonos ×3,3/×4,4) |
| B3 | P1 | **Formas nuevas** (`WeaponShape`, `GuardShape`, `GripShape`) al final, solo en las forjas de la historia (la tienda ofrece las del continente del área y las de antes; la arena no, ver A6). | R N5, L0.8, C1.5, X1.2, M-U8 |
| B4 | P1 | **Piezas de jefe y habilidades nuevas**: `specialParts` `boss.<id>` y habilidades al final de `AbilityBook.boss`, hechas con efectos que ya existen (quemar, ralentizar, rayos, veneno, ondas "cada N ataques", cura al matar, rematar, críticos que estallan, bonos). Ids reservados en `continentes.md`. Los **combos** nuevos de dos elementos (`sunfire`, `pitch`, `embalm`, `north_wind`, `constellation`) son P3 y los aprueba el balance-designer. | R N5, C1.5-C1.6, X1.4/X1.8, M-U7 |
| B5 | P1 | **Forja por capital**: un edificio/interior de cada capital abre tienda y ritual con el tier del continente del área (`storyForgeTier`, ya existe). Cada forja tiene su **herrero** (look en la escena de la tienda: Brokk, Fendril, Tova, Ragna; en Valdehierro, tras `valdemar.paso_norte`, el aprendiz de Brokk). El **despertar** de la Hoja solo lo hace Brokk (B6). | R N6, L (Fendril), C (Tova), X (Ragna), U (Brokk) |
| B6 | P1 | **Despertar de la Hoja del Alba** (I→VI): `PlayerProfile.dawnAwakening: Int?` (nil = I). Acción en la forja hablando con `brokk`, que pide la misión de la brasa del continente hecha (no hay objeto en el inventario: la **brasa** es una bandera de misión, ver `mundo.md` §3). La `legend.dawn` recalcula sus números desde el nivel (piezas ya forjadas: se actualizan al despertar) y su habilidad `dawn` gana un matiz por nivel. **Los elementos de la Hoja no cambian** (sagrado, tormenta, fuego): así no salta a otros combos. Tabla de niveles en `progresion.md` §6. | R N7, L0.9, C1.5, X1.5, M-U9 |
| B7 | P1 | **Maestro de viajes** (`NPCRole.travelMaster`): al hablarle, lista de capitales visitadas (`visitedAreaIDs` ∩ capitales y pueblos seguros) y viaje a su entrada. El medio (cabra, búho, barco, dirigible) es solo estética y texto: **cualquier** maestro lleva a **cualquier** capital visitada. Uno en cada capital (lista en `continentes.md`), incluido Valdehierro (`arrieroValdehierro`). | R N8, L N5, C1.2, X, U |
| B8 | P2 | **Pistas `.clue` en áreas de campo**: `read(npcID:)` funciona fuera de interiores; se lee al acercarse si la zona de la pista está liberada alguna vez (o, si es más sencillo, solo con estar al lado). Lo usan los crisoles, las aras, los braseros violeta, los tótems, los murales. | R N9, L (aras), C (braseros), X (tótems) |
| B9 | P3 | **Sesgo de mineral por monstruo** (`EnemyDefinition.mineralBias: [Mineral: Double]?`). Sin él, todos tiran la tabla del continente. | R N10, C, X, U ("dónde sale más") |

### Paquete C · Lo que estrena **Lunaria** (encargo L0)

| # | P | Qué | Lo piden |
|---|---|---|---|
| C1 | P1 | **Pisos de historia**: `Dungeon.storyFloors` (pisos de los continentes) y `Dungeon.floor(id)` busca en los dos; casos nuevos de `DungeonTheme`. Los pisos de historia **no** entran en la rotación de la arena (A6). Pisos: `webs`, `hollow` (Lunaria), `tomb`, `caldera` (Cenizas), `glacier`, `citadel` (Escarcha), `void`, `skyforge` (Umbral). Rocaforja usa `mine` y `forge`, que ya existen. | L N3, C1.3, X1.1, M-U1 |
| C2 | P1 | **Dos pueblos seguros en un continente** (Velaluna y Colmillo Gris): `capitalID` es el principal; otros `.town` también son seguros, tienen reaparición y cuentan para el maestro de viajes. Se reaparece en el último pueblo seguro visitado del continente. | L N4 |
| C3 | P1 | **NPC que desaparecen**: `NPC.hiddenWhen: StoryCondition?` (nil por defecto). Ysolde se va de Velaluna tras `lunaria.la_verdad`. | L N6 |
| C4 | P1 | **NPC que viajan**: el mismo id de NPC en áreas de varios continentes, con `appearsWhen`/`hiddenWhen` (`princess`, `brokk`, `thessa`, `zigoMercader`, `hermanaBrasa`, `margaCapitana`, `halvar`, `corvino`). Test: el estado de misiones de un NPC es uno solo aunque esté en varias áreas. | C1.7, L, X, U |
| C5 | P2 | **Tienda sin ritual** (curtiduría de Hirsa en Colmillo Gris: armadura de cuero y tela del tier): un edificio o NPC abre una tienda con su catálogo. Alternativa barata: lista fija en el diálogo. | L N2 |

### Paquete D · Lo que estrena **Cenizas** (encargo C0/C1)

| # | P | Qué | Lo piden |
|---|---|---|---|
| D1 | P1 | **Primera llegada a un continente nuevo**: `Continent.arrival` (área y casilla de la primera llegada) y `Continent.arrivalRequires` (la misión final del continente anterior). El maestro de viajes ofrece el continente nuevo en cuanto se cumple el requisito, aunque su capital no se haya visitado; la primera vez deja en `arrival` (Cenizas: embarcadero de la Costa; Escarcha: muelle de Hielomar; Umbral: pantalán de los Muelles), después en la capital. Mientras el continente no exista: `comingSoon`. Rocaforja y Lunaria no lo necesitan (se llega andando: Paso del Norte y Túnel de los Thanes). | C1.2, X (Marga → Hielomar), U (Borin → Muelles) |

### Paquete E · Jefes con más mecánica — lo estrena **Escarcha** si quiere usarlo; **obligatorio antes de Umbral**

Hacerlo **una vez** para todos (lo piden cuatro continentes con nombres distintos).

| # | P | Qué | Lo piden |
|---|---|---|---|
| E1 | P1 (Umbral) / P3 (antes) | **Fases de jefe**: `EnemyDefinition.phases` (umbral de vida → `behavior`, velocidad, enfriamiento, alcance). Reina Astrid (2 fases, opcional), Vesper (2), Morvath (3). | X1.7, M-U2 |
| E2 | P2 | **Invocar esbirros**: el jefe añade N enemigos cada X s o al cruzar un % de vida (Durgan, Engendro de la Esquirla, Reina, Nixara, Guardián, Vesper, Morvath). | R N10, X1.7, M-U11 |
| E3 | P2 | **Ataque en área con aviso** (círculo o cono que se marca 0,6-0,8 s antes): aliento, pisotón, pulso, onda. | X (Hrimgar), M-U11 |
| E4 | P3 | **Proyectil enemigo que ralentiza** (reutiliza `slow`). | X1.7 |
| E5 | P1 (Umbral) | **Sprites de enemigo grandes** (plantilla `dragon` grande, `hollowTitan` 2×3) en el arte y en las colisiones. | M-U10 |

### Paquete F · Lo que estrena **Umbral** (encargo U0/U1)

| # | P | Qué | Lo piden |
|---|---|---|---|
| F1 | P1 | **Banda larga con punto de control**: `StoryDungeon.checkpointAfterWave: Int?` (al morir se vuelve a la oleada siguiente al punto de control). | M-U3 |
| F2 | P2 | **Misión repetible**: `Quest.repeatable` (al entregarla se vuelve a ofrecer). | M-U4 |
| F3 | P2 | **Final del juego**: `bossDefeat` largo → epílogo (una línea por capital) → créditos → vuelta al Bastión con una bandera opcional en el perfil (`gameCompleted: Bool?`). | M-U12 |
| F4 | P3 | Vuelo dentro de un continente (Albor: a los puntos seguros de las áreas visitadas de Umbral); proyectil del Báculo; braseros de la fase 3 de Morvath; efectos nuevos `eclipse_veil` (invisibilidad corta) y `hollow_hammer` (cargas por muerte). | M-U5, M-U6, M-U7, M-U13 |

### Arte (no es motor, pero se pide en varios sitios: hacerlo una vez)

Plantillas de enemigo nuevas en `EnemyArt`: `spider`, `treant` (Lunaria, P1), `scorpion`, `crab` (Cenizas, P1),
`dragon`, `hollowTitan` (Umbral, P1); opcionales `werewolf` (Lunaria: cuerpo del héroe hombre lobo para la Mala Luna),
`giant` (Escarcha), `eye`, `lizard`. Accesorios compartidos: `lantern` (acólitos de Rocaforja y Cenizas), `beard`
(enanos: sale del arte de la raza enana), `goggles` (existe). Mientras no existan, cada bestiario dice qué plantilla
provisional usar.

## 2. Qué hace cada encargo de Fase 0/1 (resumen)

| Encargo | Hace de esta lista | Ya hecho por otros (solo usar) |
|---|---|---|
| Rocaforja **R0** | A1-A6 | — |
| Rocaforja **R1** | B1-B8 (B9 si sobra) | A |
| Lunaria **L0** | C1-C5 | A, B |
| Cenizas **C0/C1** | D1 (+ combos de B4 si el balance los aprueba) | A, B, C |
| Escarcha **X0/X1** | E1-E4 si los quiere usar (si no, quedan para Umbral) | A-D |
| Umbral **U0/U1** | E (lo que falte) + F | A-D |

Si los continentes se construyen en otro orden, el primero que llegue hace los paquetes que le falten. Lo que es
propio de un continente (sus datos, sus biomas, sus pisos, sus minerales, sus formas, sus habilidades) siempre lo
hace su encargo.
