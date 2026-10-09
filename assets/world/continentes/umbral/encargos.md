# Umbral · encargos para el equipo (FASE FUTURA)

Responsable: `continent-lead` de `umbral`. Estado: **borrador 2** (2026-10-08). **No se lanzan** hasta que estén hechos
Valdemar (motor M1-M10 y contrato), Rocaforja (despertar de la Hoja del Alba, maestro de viajes), Lunaria, Cenizas y
Escarcha (`escarcha.quinta_luz`, el dirigible *Testaruda*, Hálvar y Corvino ya registrados como NPC).
Diseño de referencia en esta carpeta: `historia.md`, `zonas.md` (datos en formato de contrato), `mapas/`,
`bestiario.md`, `minerales.md`, `piezas.md`. Tipos: `../valdemar/contrato.md`.

**Referencia práctica**: hacer Umbral **como Valdemar, Cenizas y Escarcha**: `Umbral.swift` ≈ `Valdemar.swift`,
`UmbralQuests.swift` ≈ `ValdemarQuests.swift`, `UmbralDialogue.swift` ≈ `ValdemarDialogue.swift`.
En las listas compartidas (`Bestiary.all`, `Mineral`, formas de `Parts`, `specialParts`, `AbilityBook`,
`ArmorStyle.styles`, `DungeonFloor`, `Biome`, `BuildingStyle`) **solo se añade al final**, bajo `// Umbral`.
Ningún id existente se renombra; todo lo nuevo del perfil, opcional. Si se añaden ficheros: `make project`.

## Orden y paralelismo

```
U0 game-programmer  "Umbral en el contrato" (registro vacío + tipos nuevos)          ← primero, corto
 │
 ├─(paral.)├─ MD  map-designer        6 áreas + 6 interiores + 2 pisos en Umbral.swift  ← solo datos de mapas
 │         ├─ CD  character-designer  19 enemigos, piezas de jefe, armadura, NPC        ← Enemy/Parts/Armor + looks
 │         ├─ SW1 story-writer        guion en assets/story/umbral.md + epílogo         ← solo documentos
 │         └─ U1  game-programmer     motor de Umbral (fases, banda, repetible, Hoja VI) ← Mineral/Parts/Ability/Dungeon/Quest
 │
 ├─(paral., tras MD y CD)├─ EA environment-artist  biomas, vacío, edificios, pisos void/skyforge
 │                       └─ PA pixel-artist        dragones, Morvath (sprite grande), NPC, piezas, conjunto
 ├─ SW2 story-writer   textos al código (tras SW1 y U0)
 ├─ B   balance-designer (con todo jugable; mide la banda de 3-4 min)
 └─ QA  qa-tester (al final; partida completa 50→60 con el bot)
```

En paralelo y sin pisarse: MD, CD, SW1 y U1 (cada uno en sus ficheros, tabla de abajo). EA y PA en paralelo entre sí.

## Quién toca qué

| Fichero | Quién | Qué |
|---|---|---|
| `GameCore/World.swift`, `WorldRules.swift`, `QuestEngine.swift`, `ContinentLoot.swift` | game-programmer (U0, U1) | Registrar `umbral` (50-60, capital `umbral.bastion`, tier 6, familia `starmetal/adamantite/voidstone/dragonite/mithril`); `Biome` `umbralBastion/Sky/Void/Star`; `BuildingStyle` `starTower` (→ `alchemist`), `skyDome` (→ `castle`) |
| `GameCore/Umbral.swift` (nuevo) | map-designer | Áreas, interiores, salidas, `safePoint`, `StoryDungeon` `umbral.grieta` y `umbral.yunque` |
| `GameCore/UmbralQuests.swift` (nuevo) | game-programmer (U0, textos provisionales de `zonas.md` §6) → story-writer (SW2) → balance-designer (B) | 19 misiones, `mapLayout`, misión final `umbral.herrero_hueco` y repetible `umbral.eco_de_morvath` |
| `GameCore/UmbralDialogue.swift` (nuevo) | story-writer (SW2) | Llegada por raza, presentación de jefes, escenas (Nixara, Corvino, la Brasa, Vesper, Morvath), epílogo, avisos, HUD |
| `GameCore/Dungeon.swift` | map-designer (filas) + game-programmer (registro) | Pisos `void` y `skyforge` **fuera** de la rotación de la arena |
| `GameCore/Enemy.swift` | character-designer → balance-designer | 14 normales + 5 jefes al final de `Bestiary.all` |
| `GameCore/Arena.swift` | game-programmer (U1) | `Arena.wave` elige jefe solo entre los 10 de la arena (`progresion.md` §8): **imprescindible** antes de añadir a Morvath |
| `GameCore/Mineral.swift`, `Parts.swift`, `Ability.swift`, `Armor.swift` | game-programmer (U1) / character-designer (CD) → balance-designer | Casos nuevos al final; la arena no los ve |
| `GameTest1/Art/*` | character-designer (básico) → pixel-artist / environment-artist | Ver PA y EA |
| `assets/story/umbral.md`, `assets/story/historia.md` | story-writer | Guion, epílogo y biblia |

## Necesidades de motor (lo que no traen Valdemar ni los otros continentes)

> **Motor común (revisión del world-designer, 2026-10-09)**: lo que se repite entre continentes está una sola vez en
> `assets/world/motor_comun.md`, ordenado y con el continente que lo estrena. Umbral estrena el paquete **F** y hace lo que falte del **E**. Equivalencias: M-U1→C1, M-U2→E1, M-U3→F1, M-U4→F2, M-U5/M-U6/M-U13→F4, M-U7→B4/F4, M-U8→B1-B3, M-U9→B6, M-U10→E5, M-U11→E2/E3, M-U12→F3. El filtro de jefes de la arena (`Arena.wave`) **ya está hecho** en el código (usa `Arena.originalEnemyIDs`).
> Antes de implementar una fila de esta tabla, mira allí: si ya está hecha, solo se usa; si es de otro paquete, se hace
> con el nombre y la forma de allí (no con los de esta tabla).

| # | Prioridad | Qué | Para qué |
|---|---|---|---|
| M-U1 | P1 | **Pisos `void` y `skyforge`** en `DungeonFloor`, fuera de la arena; `~` como vacío en el arte del piso. | Mazmorra y banda. |
| M-U2 | P1 | **Fases de jefe**: lista de fases por % de vida que cambian `behavior`, velocidad, enfriamiento y alcance (Vesper 2 fases, Morvath 3). Si Escarcha/Cenizas ya lo hicieron, reutilizar. | Banda de Morvath (`bestiario.md`). |
| M-U3 | P1 | **Banda larga**: `StoryDungeon.checkpointAfterWave: Int?` (al morir, se vuelve a la oleada siguiente al punto de control, no a la 1). Campo opcional. | `umbral.yunque` (6-8 min). |
| M-U4 | P2 | **Misión repetible**: `Quest.repeatable` (al entregarla vuelve a ofrecerse; `QuestState` se reinicia). | `umbral.eco_de_morvath`. |
| M-U5 | P3 | **Vuelo de Albor**: NPC que lleva a las `safePoint` de las áreas visitadas del continente (como el maestro de viajes, pero dentro de Umbral). | Atajo; opcional. |
| M-U6 | P3 | **Proyectil mágico del Báculo** (cada 3 ataques, orbe al enemigo más cercano, 60 %). | Forma `staff`; opcional. |
| M-U7 | P2 | **Habilidades** `dragon_breath`, `void_siphon`, `astral_lens`, `eclipse_veil`, `hollow_hammer`, la combinación `constellation` y "Alba plena" de `dawn` (VI) (`piezas.md`). `eclipse_veil` e `hollow_hammer` piden un efecto nuevo pequeño (invisibilidad corta; cargas por muerte); si no, la versión simple de `piezas.md`. | Piezas `boss.*` y la Hoja (VI). |
| M-U8 | P1 | **Formas** `staff`, `dragon`, `star` y **minerales** `starmetal`, `adamantite`, `voidstone`, `dragonite` (`mithril` ya existe) con rareza por familia y bonificación escalada; factor de continente para el mithril en la historia (propuesta). | Botín y forja tier 6. |
| M-U9 | P1 | **Despertar (VI)** con dos objetos de historia (`umbral.gran_heraldo` hecha = Ascua de Escarcha + Ascua de Umbral) sobre la (V). | `umbral.sexta_brasa`. |
| M-U10 | P1 | **Sprites grandes** de enemigo (`dragon` grande, `hollowTitan` 2×3) en `EnemyArt` y en las colisiones (`bodyRadius` grande ya existe). | Nixara, Morvath. |
| M-U11 | P2 | **Invocar esbirros** y **ataque en área con aviso** (lo piden también Escarcha y Cenizas: hacerlo una vez). | Jefes de Umbral. |
| M-U12 | P2 | **Final del juego**: `bossDefeat` largo de Morvath → epílogo (una línea por capital) → créditos → volver al Bastión con el juego "terminado" (bandera en el perfil, opcional). | Cierre. |
| M-U13 | P3 | Braseros de la fase 3 de Morvath (`mapas/skyforge.md`). | Opcional. |

---

## U0 · game-programmer — "Umbral en el contrato"

> Registra Umbral en `World` como Valdemar, Cenizas y Escarcha: `Umbral.swift` y `UmbralQuests.swift` **vacíos pero
> registrados**, el `Continent` `umbral` (50…60, capital `umbral.bastion`, tier 6, familia de `minerales.md`), los 4
> `Biome` y los 2 `BuildingStyle` nuevos (con `placeholder`). Requisito de la primera misión:
> `.questDone("escarcha.quinta_luz")`; Borin/Ulf/Marga añaden el Bastión (en Escarcha hasta ahora
> `.comingSoon("umbral")`). Filtra los jefes de la arena (`Arena.wave`) a los 10 originales. **Comprobar**: `make test`
> (WorldTests), partidas viejas cargan, `make balance` (arena intacta).

## U1 · game-programmer — motor de Umbral

> M-U1 a M-U4, M-U7 a M-U12 de la tabla (M-U5, M-U6, M-U13 si sobra tiempo). Tests nuevos en
> `Tests/GameCoreTests/UmbralTests.swift`: la arena sigue con 10 minerales y 10 jefes; los pisos nuevos no rotan; las
> fases de jefe cambian de comportamiento al % correcto; el punto de control de la banda reinicia en la oleada 3; la
> misión repetible vuelve a ofrecerse; el despertar (VI) pide la (V) y `umbral.gran_heraldo`; las formas nuevas generan
> piezas de los 24 materiales. **Comprobar**: `make test`, `make balance`, `make verify`.

## MD · map-designer — mapas de Umbral

> Pasa los borradores de `assets/world/continentes/umbral/mapas/` a `Umbral.swift`: `umbral.bastion` (`.town`, 52×34,
> detallado en `mapas/bastion.md`: edificios, puertas, NPC y salidas de su tabla; los dígitos `1-5` son suelo bajo el
> `Building`), sus 5 interiores; los 5 campos desde los bocetos 1:1 (`muelles` 56×32, `nidos` 56×36, `rotas` 60×36,
> `observatorio` 56×36, `puente` 64×24: puedes mover islas y grupos, manteniendo tamaños, salidas y zonas) y el
> interior `umbral.observatorio.cupula`. Marcas de borrador (`@ * ! J`) → suelo + spawns/NPC/`safePoint`. Salidas,
> bajadas, `safePoint`, zonas, spawns, pistas `.clue` y NPC con los ids y coordenadas de `zonas.md` §1-4 (si mueves
> algo, actualiza `zonas.md`). Pisos `void` (44×24) y `skyforge` (48×26) en `Dungeon.swift` desde sus bocetos, con las
> reglas de `assets/maps/mazmorra.md`. `StoryDungeon` de `zonas.md` §5. **Comprobar**: `make test` (WorldTests + un
> `UmbralMapTests` de conectividad y borde cerrado: el vacío `~` cuenta como borde), `make maps`, `make dungeon` (mirar
> los PNG), `make balance` sin "⚠︎ atasco" en los pisos nuevos (puentes de 3).

## CD · character-designer — monstruos, jefes y NPC

> Al final de `Bestiary.all`, bajo `// Umbral`: los 14 monstruos y 5 jefes de `bestiario.md` (estadísticas
> orientativas; plantillas provisionales mientras no existan `dragon` y `hollowTitan`). Piezas `boss.*` en
> `specialParts` (tier 6, `piezas.md` §2, con las habilidades de M-U7 o su versión simple). Conjunto
> `helm/chest/gloves/boots.umbral` en `ArmorStyle.styles`. NPC (looks básicos con los cuerpos existentes): `borin`,
> `albor` (provisional: escala grande de una plantilla de bicho, sin combate), `fibulaEngranaje` (gnoma: cuerpo de enano
> más bajo), `noraPosadera`, relleno de la plaza (`enanoBastion`, `elfaBastion`, `lobaBastion`, `oasisBastion`,
> `guardiaBastion1/2`); reutiliza `princess`, `brokk`, `halvar`, `zigoMercader`, `thessa`, `hermanaBrasa` con
> `appearsWhen`. Pistas `.clue` (`estelaFarero`, `notaVesper`, `cartaBrasa2`). `EnemyArt.spec` provisional para cada id.
> **Comprobar**: `make test`, `make sprites`, `make fichas`.

## SW1 · story-writer — guion de Umbral

> `assets/story/umbral.md` desde `historia.md`: diálogos de los NPC antes y después de cada misión (19, `zonas.md` §6),
> líneas por raza (llegada y Hoja VI), escenas (huevo de Nixara, estatua de Corvino, confesión de la Hermana Brasa,
> caída de Vesper, las tres fases de Morvath, la llave que gira), **epílogo** (una línea por capital y por los
> personajes que viajan: Aurora, Brokk, Hálvar, Thessa, Zigo, la Brasa, Albor) y créditos. Actualiza
> `assets/story/historia.md` (final del juego; los cambios de `historia.md` → "Propuestas al world-designer" solo si el
> usuario los confirma). Frases cortas. **Comprobar**: cada misión tiene oferta, recordatorio y entrega; cada jefe,
> presentación y caída.

## SW2 · story-writer — textos al código

> Pega los textos de `assets/story/umbral.md` en `UmbralQuests.swift` (`offer`, `reminder`, `turnIn`,
> `objectiveLabels`), NPC (`talk`), `AreaExit.lockedMessage`, `DungeonEntrance.lockedMessage`, `StoryDungeon.bossIntro`
> / `bossIntroRepeat` / `bossDefeat` y `UmbralDialogue.swift`. **Comprobar**: `make test`, `make verify`.

## EA · environment-artist — escenarios

> Los 4 biomas de Umbral (`zonas.md` §1): sobre todo el **vacío** (`~`: índigo con estrellas que se mueven despacio,
> bordes de isla con raíces de piedra colgando) y el **puente de luz** (`p`, dorado, con un brillo que recorre las
> cadenas; versión apagada para `bastion.norte` cerrada); árbol de cristal, cascarones gigantes, astrolabios, sauce del
> vacío. Edificios `starTower` y `skyDome`; Pozo de luz (`F` del Bastión). Pisos `void` (plataformas sobre la nada,
> grietas `h` violetas que laten) y `skyforge` (Yunque, anillo de fuego estelar, seis estatuas de los Herreros, séptimo
> pedestal vacío, Luna rota de fondo). **Comprobar**: `make maps`, `make dungeon`, capturas del Bastión y de la banda.

## PA · pixel-artist — personajes y objetos

> Plantilla `dragon` (crías, dragonantes, dragón caído, Nixara grande, Albor NPC) y `hollowTitan` (Morvath, sprite
> grande con pecho hueco animado); los 14 monstruos y 5 jefes con el aspecto de `bestiario.md`; NPC (Borin, Fíbula,
> Nora, Albor); iconos de los 4 minerales nuevos; formas `staff`, `dragon`, `star`; las 5 piezas `boss.*`; la Hoja del
> Alba (VI) con seis vetas; el conjunto `*.umbral`. **Comprobar**: `make sprites` (mirar los PNG), `make fichas`.

## B · balance-designer — números

> **XP de misiones (revisión del world-designer)**: el presupuesto es **≈400-450 %** de `xpToNext` por continente (suma de los % de todas sus misiones; `progresion.md` §2). Este continente suma hoy **~480 %**: casi en presupuesto: basta con bajar las secundarias al 15-20 %. Jefes de historia: ×6 (`Leveling.storyBossMultiplier`).

> Con todo jugable: niveles de zona 50-60, estadísticas de los 19 enemigos (objetivos de `progresion.md` §7: jefe de
> zona 40-60 s, Guardián 60-90 s, **Morvath 3-4 min** con daño de 25-30 % por golpe), oleadas de `umbral.grieta` y
> `umbral.yunque`, bonificaciones de los minerales (y la propuesta del mithril escalado), piezas `boss.*` (≈1,5× tier 6;
> el Martillo de Morvath frente a la Hoja VI), recompensas de misiones y ritmo 50→60 (~4-4,5 h) con la simulación del
> modo historia. **Comprobar**: `make balance` (arena intacta), simulación de Umbral con el bot de nivel = zona.

## QA · qa-tester — verificación

> `make verify`, `make test`; partida de prueba desde un perfil con `escarcha.quinta_luz` hecha: llegada en dirigible,
> las 19 misiones, los bloqueos de cada salida, Grieta y banda (fases, punto de control, repetición), despertar (VI),
> epílogo y vuelta al Bastión; la arena sin minerales ni jefes de Umbral; partidas viejas cargan. Informe con pasos.

## Estado

| Encargo | Estado |
|---|---|
| Diseño (`historia`, `zonas`, `mapas`, `bestiario`, `minerales`, `piezas`, `encargos`) | Hecho (borrador 2) |
| U0, U1, MD, CD, SW1, SW2, EA, PA, B, QA | Pendientes (fase futura: después de Escarcha) |
