# Rocaforja · encargos para el equipo (FASE FUTURA)

Responsable: `continent-lead` de `rocaforja`. **Fase futura**: se lanzan cuando el usuario lo pida, con Valdemar ya
jugable (su motor M1-M10 está hecho: `assets/world/continentes/valdemar/contrato.md` y `encargos.md`). Cada encargo
se puede pegar tal cual al agente. Todos leen antes `CLAUDE.md`, `assets/world/continentes/rocaforja/historia.md`,
`zonas.md`, el `contrato.md` de Valdemar y lo que su encargo cite. Nadie hace commits. Al terminar, cada uno anota su
línea en `assets/design/tareas.md` y en "Estado" (al final de este fichero).

**Referencia práctica**: hacer Rocaforja **como Valdemar**: `Rocaforja.swift` ≈ `Valdemar.swift`,
`RocaforjaQuests.swift` ≈ `ValdemarQuests.swift`, `RocaforjaDialogue.swift` ≈ `ValdemarDialogue.swift`,
`make check-rocaforja` ≈ `make check-valdemar`.

## Orden y paralelismo

```
Fase 0  game-programmer ── R0 "Rocaforja en el contrato" (corto; generaliza lo que hoy es solo de Valdemar)
           │
Fase 1  ┌─ game-programmer   R1 motor nuevo: despertar de la Hoja, maestro de viajes, forja de Hondoyunque, minerales,
(paral.)│                     formas y piezas nuevas  ← ficheros propios + añadir al final de enums compartidos
        ├─ map-designer      MD las 6 áreas + interiores + 2 mazmorras en Rocaforja.swift  ← solo datos de mapas
        ├─ character-designer CD 15 monstruos + 4 jefes + NPC  ← final de Bestiary.all, EnemyArt.spec, NPCLooks
        └─ story-writer      SW1 guion completo en assets/story/rocaforja.md (sin tocar src/)
           │
Fase 2  ┌─ environment-artist EA 5 biomas, Hondoyunque, lava, nieve, escoria, muralla   (necesita R0 + MD)
(paral.)├─ pixel-artist     PA monstruos, jefes, NPC, formas nuevas, minerales, Hoja (II) (necesita CD + R1)
        └─ story-writer      SW2 textos al código (RocaforjaQuests, RocaforjaDialogue, avisos) (necesita R1 + MD)
           │
Fase 3  balance-designer     B ritmo 10→20, monstruos, jefes, piezas, minerales, forja          (con todo jugable)
           │
Fase 4  qa-tester            QA verificación completa
```

Se puede lanzar **en paralelo con los encargos de otros continentes** si cada uno respeta sus ficheros y solo añade al
final de las listas compartidas (`Bestiary.all`, `Mineral`, `WeaponShape`/`GuardShape`/`GripShape`, `specialParts`,
habilidades de jefe, `Biome`, `World.continents`).

## Quién toca qué

| Fichero | Dueño | Notas |
|---|---|---|
| `GameCore/World.swift`, `WorldRules.swift`, `QuestEngine.swift`, `ContinentLoot.swift`, `PlayerProfile.swift` | game-programmer (R0, R1) | Generalizar lo de Valdemar; registrar Rocaforja |
| `GameCore/Rocaforja.swift` (nuevo) | map-designer | Áreas, interiores, `StoryDungeon` `rocaforja.minas` y `rocaforja.forja` |
| `GameCore/RocaforjaQuests.swift` (nuevo) | game-programmer (R0, textos provisionales de `zonas.md` §4) → story-writer (SW2) → balance-designer (B) | 22 misiones, `doorLocks`, `mapLayout`, `finalQuestID` |
| `GameCore/RocaforjaDialogue.swift` (nuevo) | story-writer (SW2) | Llegada por raza, jefes, avisos, HUD |
| `GameCore/Valdemar.swift` | map-designer | **Solo** la salida `paso.norte` (de `comingSoon` a `rocaforja.pastos`) |
| `GameCore/Enemy.swift` | character-designer → balance-designer | Al final de `Bestiary.all`, bajo `// Rocaforja` |
| `GameCore/Mineral.swift`, `Parts.swift`, `Ability.swift` | game-programmer (R1) → balance-designer | Casos nuevos al final; la arena no los ve |
| `GameTest1/Art/EnemyArt.swift`, `NPCLooks.swift`, `WeaponArt.swift` | character-designer (básico) → pixel-artist | |
| `GameTest1/Art/` biomas (nuevo `RocaforjaArt*.swift` o donde viva `FieldArt`) | environment-artist | `make project` si añade ficheros |
| `tools/Harness/…` | game-programmer (check-rocaforja) → balance-designer (simulación 10→20) | |
| `assets/maps/rocaforja.md`, `assets/characters/`, `assets/story/rocaforja.md`, `assets/art/`, `assets/balance/` | su especialista | |

---

## Necesidades de motor (lo que Valdemar no tiene)

> **Motor común (revisión del world-designer, 2026-10-09)**: lo que se repite entre continentes está una sola vez en
> `assets/world/motor_comun.md`, ordenado y con el continente que lo estrena. Rocaforja estrena los paquetes **A** (R0) y **B** (R1): N1→A2/A3, N2→A1, N3→A4, N4→B1/B2/A6, N5→B3/B4/A6, N6→B5, N7→B6, N8→B7, N9→B8, N10→B9/E2.
> Antes de implementar una fila de esta tabla, mira allí: si ya está hecha, solo se usa; si es de otro paquete, se hace
> con el nombre y la forma de allí (no con los de esta tabla).

| # | Prioridad | Qué | Por qué |
|---|---|---|---|
| N1 | P1 | **Generalizar lo que es solo de Valdemar**: `ValdemarQuests.doorLocks` (hoy `WorldRules.doorLockMessage` solo mira el pueblo de Valdehierro) → `doorLocks` por continente/área; `isCastleOpen` devuelve `false` con `castleRequires` vacío y la escalinata `S` de un `.town` se bloquea → en Hondoyunque la escalinata del Salón debe estar siempre abierta; `respawnPoint` usa `continents[0]` de reserva → la capital del continente del área; `QuestEngine` nombra al herrero por `ValdemarQuests.smithID`; HUD/avisos de `ValdemarDialogue` → por continente. | Que un segundo continente funcione sin `if valdemar`. |
| N2 | P1 | **Rocaforja como datos**: `World.continents` + `Continent(id: "rocaforja", name: "Montes de Rocaforja", levels: 10...20, capitalID: "rocaforja.hondoyunque", minerals: [.cobalt, .tin, .topaz, .runestone, .diamond], tier: 2, finalQuestID: "rocaforja.despertar", mapLayout: …)`; `World.areas/storyDungeons/quests` concatenan las de Rocaforja. | Escalar a 6 (M7). |
| N3 | P1 | **Biomas**: `Biome.rocaforjaHall`, `.rocaforjaMeadow`, `.rocaforjaQuarry`, `.rocaforjaSnow`, `.rocaforjaSlag` (al final). En `rocaforjaHall`, `d` se dibuja como **vía de vagoneta**. | Mapas de `mapas/`. |
| N4 | P1 | **Minerales** `cobalt`, `tin`, `topaz`, `runestone` (al final de `Mineral`, datos explícitos) y la **arena con sus 10 originales** (`Mineral.arenaMinerals`; `roll` y tienda de la arena filtran). | `minerales.md`. |
| N5 | P1 | **Formas nuevas** `warpick`, `anvil`, `chain` (al final de cada enum; nombre, elemento, `baseStats`) solo en la forja de la historia; 4 piezas `boss.*` y 4 habilidades nuevas (`runaway_cart`, `skyfall`, `resonance`, `black_fire`) con efectos existentes. | `piezas.md`. |
| N6 | P1 | **Forja de Hondoyunque**: el interior `rocaforja.hondoyunque.forja` abre la tienda y el ritual (como `smithy`) con el tier del continente del área (`storyForgeTier` por continente: 2; 3 tras `rocaforja.despertar`). Brokk es un NPC de mapa (`brokk`, `.questGiver`) que aparece donde diga `appearsWhen`. Valdehierro conserva su forja (la lleva un aprendiz: ver Propuestas). | Forja por capital (`mundo.md` §11). |
| N7 | P1 | **Despertar de la Hoja del Alba** (I→II): objetivo/acción en la forja con el Ascua (objeto de historia que da `rocaforja.forja_profunda`); guardar el nivel de despertar (opcional en el perfil) y recalcular la `legend.dawn`. Reutilizable por los continentes 3-6. | `piezas.md` §4. Lunaria lo reutiliza (III). |
| N8 | P1 | **Maestro de viajes** (primero del juego): `NPCRole.travelMaster` (o similar); al hablar, lista de capitales visitadas (`visitedAreaIDs` ∩ capitales) y viaje a su entrada. Frida (`fridaArriera`) en Hondoyunque y **uno en Valdehierro** (ver Propuestas). Lunaria pone los suyos (Nimra, lobo mensajero) con la misma mecánica. | `mundo.md` §10. |
| N9 | P2 | Comprobar que `read(npcID:)` de un `.clue` funciona **en un área de campo** con la zona liberada alguna vez (crisoles de los Escoriales, cada uno en su zona). Si no, que baste con estar al lado. | `crisoles_negros`. |
| N10 | P3 (opcional) | Jefe que **llama refuerzos** al 50 % de vida (Durgan: 2 `ironConstruct` por las `G`) — campo opcional en `StoryDungeon`; **sesgo de mineral por monstruo** (`mineralBias`); cambio de paleta del piso al ganar (lava negra → naranja). Nada de esto bloquea. | Sabor. |

---

## R0 · game-programmer · Rocaforja en el contrato (Fase 0, bloquea el código)

**Hace el paquete A de `assets/world/motor_comun.md` (A1-A6)**; R1 hace el paquete B (B1-B8). Lo de abajo es lo propio de Rocaforja.

1. N1 (generalizar) y N2 (registrar `Continent` y huecos vacíos `Rocaforja.areas`, `Rocaforja.dungeons`,
   `RocaforjaQuests.all`, como se hizo con Valdemar en P0). N3 (`Biome` nuevos, dibujo provisional = color plano).
2. `RocaforjaQuests.swift` con las 22 misiones de `zonas.md` §4 (ids, `giverID`, `requires`, `objectives`, recompensas
   provisionales, textos de `historia.md`), `doorLocks` (`forja`, `ascua`) y `mapLayout` (`zonas.md` §2).
3. Anotar en `contrato.md` de Valdemar (o en uno nuevo `rocaforja/contrato.md`) qué cambió.

**Comprobar**: `make test` (los `WorldTests` validan los datos nuevos solos), `make verify`; Valdemar y la arena,
idénticos (`make check-valdemar`, `make balance`). **Hecho cuando** todo pasa y los huecos están registrados.

## R1 · game-programmer · motor nuevo (Fase 1, tras R0)

N4, N5, N6, N7, N8 y N9 (N10 si sobra tiempo). Tests propios (`RocaforjaRulesTests`, `TravelTests`, `AwakeningTests`).
`make check-rocaforja` (Harness): entrar desde el Paso, ir a Hondoyunque, aceptar y entregar `cabras_perdidas`,
`prueba_del_thane` abre la galería y la forja, entrar en las Minas, crisoles y barracón abren la Fortaleza, ganar la
Forja Profunda, despertar la Hoja (II), viajar con Frida a Valdehierro y volver.

**Hecho cuando** `make verify` y `make check-rocaforja` pasan y la arena no cambia (`make balance` igual que
`assets/balance/README.md`).

## MD · map-designer · áreas de Rocaforja (Fase 1, tras R0)

**Fuente**: `rocaforja/mapas/*.md` — filas ya comprobadas (iguales, borde cerrado salvo `>`, todo conectado), con
edificios, zonas, spawns, NPC y salidas; ids y bloqueos en `zonas.md` §2-3. Transcribir y revisar, no rediseñar.

1. Nuevo `GameCore/Rocaforja.swift`: `enum Rocaforja` con `hondoyunque` (`kind: .town`, edificios de la tabla,
   interiores `salon`, `forja`, `posada`, `cuartel`, `establo`, `ascua`), `pastos`, `canteras`, `cumbres`,
   `escoriales` (+ interior `barracon` con los 3 mineros y 6 guardias), `fortaleza` (`kind: .field`, su `biome`,
   `continentID: "rocaforja"`, `exits`, `safePoint`, `dungeonEntrances`, zonas `rocaforja.<área>.<zona>`, spawns
   `rocaforja.<área>.<n>`) y las `StoryDungeon` `rocaforja.minas` y `rocaforja.forja` (`mapas/mazmorras.md`).
   Los dígitos de los borradores son huellas de edificios: en las filas van como suelo (`#` o `.`) bajo el `Building`.
2. NPC con sus `appearsWhen` (Brokk en los Pastos hasta `prueba_del_thane`, luego en la Gran Forja; Brokk y Runa en
   la Fortaleza tras `crisoles_negros`; Fausto tras `forja_profunda`; crisoles `.clue`).
3. `Valdemar.swift`: **solo** `paso.norte` → `toArea: "rocaforja.pastos"`, `arrival: TilePoint(25, 32)`,
   `lock: .questDone("valdemar.paso_norte")`.
   Y en `Town.swift` (Valdehierro), **solo añadir** el NPC maestro de viajes `arrieroValdehierro` ("Nicasio el
   arriero", junto a la Puerta sur, `appearsWhen: .questDone("valdemar.paso_norte")`): aprobado por el world-designer.
4. `hondoyunque.este` → `lunaria.raices` (2, 10) **cuando exista Lunaria**; hasta entonces `.comingSoon("lunaria")`.
5. `assets/maps/rocaforja.md` (resumen y renders).

**Comprobar**: `make test` (+ `RocaforjaMapTests` como `ValdemarMapTests`), `make maps` y mirar los PNG de las 6
áreas. **Hecho cuando** pasan y los renders coinciden con los borradores.

## CD · character-designer · monstruos, jefes y NPC (Fase 1, tras R0)

1. `Enemy.swift`: los 15 monstruos y 4 jefes de `bestiario.md` al **final** de `Bestiary.all` bajo `// Rocaforja`
   (números provisionales; B los cierra). Comprobar que la arena no los ve (`Arena.originalEnemyIDs`).
2. Aspecto básico: `EnemyArt.spec` de cada uno reutilizando cuerpos (`goblin`, `brute`, `human`, `boar`, `bird`,
   `slime`) y los accesorios ★ de `bestiario.md` en versión sencilla; proyectiles (piedra, chispa negra, bala, llamarada).
3. NPC: looks de `brokk` (el herrero de Valdehierro, reutilizar), `thaneHilda`, `runaEscudohondo`, `gormPosadero`,
   `fridaArriera` (con cabra), `eddaGuardiana`, `zigoMercader` (goblin con mochila), `gretaCabrera`, `odilaCapataz`,
   `thrainVigia`, `mineroCautivo` (×3 variantes), `faustoCautivo` (el alcalde, con cadenas), `crisolNegro` (objeto),
   aldeanos enanos de ambiente. Raza enana del héroe como base de los enanos.
4. `assets/characters/`: fichas y la tabla "qué enemigo va en cada área" (`zonas.md` §3); `make fichas`.

**Comprobar**: `make test`, `make balance` (arena igual), `make sprites`. **Hecho cuando** pasa y se ven todos.

## SW1 · story-writer · guion del capítulo 2 (Fase 1, sin tocar `src/`)

`assets/story/rocaforja.md` como `valdemar.md`: llegada por raza (`historia.md` §6), oferta/recordatorio/entrega de
las 22 misiones, `bossIntro`/`bossDefeat` de Mechacorta, Roc, Coloso y Durgan (la escena de Brasa con el Molde), la
confesión de Brokk, la carta de Aurora, Fausto encadenado, avisos de bloqueo (`zonas.md` §2), textos de crisoles.
Frases cortas. Actualizar `assets/story/historia.md` (personajes, cronología, preguntas cerradas: "¿por qué Brokk
reconoce el fuego Hollín?" y "¿qué sabe Fausto?"). Coordinar con Lunaria: Brasa llega a Ysolde con el Molde.
**Hecho cuando** cubre todas las misiones y escenas de `historia.md` §4-6.

## SW2 · story-writer · textos al código (Fase 2, tras R1 + MD)

Pegar SW1 en `RocaforjaQuests.swift` (`title`, `summary`, `offer`, `reminder`, `turnIn`, `objectiveLabels`), NPC
(`talk`), `AreaExit.lockedMessage`, `StoryDungeon.bossIntro/bossIntroRepeat/bossDefeat`, `RocaforjaDialogue.swift`.
**Comprobar**: `make test`, `make check-rocaforja`.

## EA · environment-artist · biomas de Rocaforja (Fase 2, tras R0 + MD)

Los 5 biomas (`mapas/*.md` dicen qué es cada carácter en cada uno): `rocaforjaHall` (roca tallada, losas, columnas
colosales, canal y crisol de lava animados, vías de vagoneta, lámparas, sin cielo), `rocaforjaMeadow` (pradera alpina,
pinos, río frío), `rocaforjaQuarry` (terrazas grises con vetas azules, rampas, vagonetas), `rocaforjaSnow` (nieve,
riscos, lago helado, estelas con runas), `rocaforjaSlag` (escoria, lava, crisoles de fuego negro, muralla Hollín).
Edificios enanos (variantes de `castle`, `chapel`, `smithy`, `inn`, `house`; barracón; ruinas de fundición).
Paleta: grises, naranja de forja, blanco de nieve; fuego negro 0x1A1020 con borde 0xE07020.
**Comprobar**: `make maps`, `make shots` y mirar los PNG. **Hecho cuando** las 6 áreas se leen de un vistazo.

## PA · pixel-artist · personajes y objetos (Fase 2, tras CD + R1)

Detalle y animaciones (paso, ataque, daño) de los 15 monstruos y 4 jefes (`bestiario.md`), NPC de CD, las formas
`warpick`/`anvil`/`chain` y las 4 piezas de jefe (`piezas.md`), iconos de cobalto, estaño, topacio y piedra rúnica
(`minerales.md`), la Hoja del Alba (II) y el conjunto `*.rocaforja`. **Comprobar**: `make sprites`, `make shop`.

## B · balance-designer · ritmo 10→20 (Fase 3, con todo jugable)

> **XP de misiones (revisión del world-designer)**: el presupuesto es **≈400-450 %** de `xpToNext` por continente (suma de los % de todas sus misiones; `progresion.md` §2). Este continente suma hoy **~925 %**: recortar a la mitad: secundarias al 10-15 % y la historia según la tabla de `progresion.md` §2. Jefes de historia: ×6 (`Leveling.storyBossMultiplier`).

Números de los monstruos y jefes contra `progresion.md` §7; oleadas de las 2 mazmorras (4-6 min / 6-8 min); XP y oro
de las 22 misiones (≈ 10 niveles en ~2 h); minerales (bonos ×1,6, valores); formas nuevas y piezas de jefe (≈1,5×
tier 2; Coloso y Durgan, tier 3); Hoja del Alba (II); forja tier 2→3. Simulación de historia 10→20 en el Harness.
La arena no cambia. **Hecho cuando** la simulación cae dentro de los objetivos y `make balance` sigue igual.

## QA · qa-tester · verificación (Fase 4)

`make verify`, `make check-valdemar`, `make check-rocaforja`, `make balance`; recorrer con un perfil de nivel 10 tras
Valdemar: Paso → Pastos → Hondoyunque → todas las salidas y bloqueos → las 2 mazmorras → despertar → maestro de
viajes; partida guardada antigua (v0.5 y de Valdemar) carga sin perder nada. Informe con pasos para reproducir.

---

## Propuestas al world-designer

> **Respuesta del world-designer (revisión de coherencia 1, 2026-10-09)**: cada propuesta está aceptada, ajustada,
> rechazada o marcada PENDIENTE DEL USUARIO, con su razón, en `assets/world/mundo.md` §13; las contradicciones
> corregidas en este continente, en `mundo.md` §14; los renombres, en `assets/world/continentes.md` (registros comunes).

1. **Nombre del herrero**: ya canon en el código (Valdemar): **Brokk Martillohondo**, nacido **Brokk Hollín**, hermano
   del Thane Durgan. Confirmado por Rocaforja.
2. **Heraldo de Rocaforja: la Hermana Brasa**, que **no pelea** (huye en Rocaforja y en Lunaria) y carga el **Molde del
   Ocaso** (el molde de la hoja de Morvath) de Rocaforja → Lunaria → Cenizas. Lunaria ya lo usa. Propongo que el Molde
   sea un hilo de todo el juego (el Eclipse tiene el molde; le faltan las Ascuas).
3. **Durgan sobrevive** (encerrado en Hondoyunque): puede volver como forjador arrepentido en un capítulo posterior.
4. **Fausto** (el alcalde de Valdemar) acaba en Rocaforja, encadenado en la tienda de Brasa: cierra su hilo.
5. **Maestro de viajes en Valdehierro**: hace falta uno (Rocaforja lo estrena con Frida). Propuesta: un arriero con
   carro en la Puerta sur (`arrieroValdehierro`), visible tras `valdemar.paso_norte`. Lo pone el map-designer de
   Rocaforja en `Valdehierro` (solo añadir un NPC) si el world-designer lo aprueba.
6. **La forja de Valdehierro sin Brokk**: queda abierta con su aprendiz (sin NPC nuevo: el mismo `smithy`); el ritual
   de despertar de la Hoja solo lo hace Brokk (en la forja de la capital donde esté).
7. **Formas nuevas fuera de la arena** (la arena sigue con sus 9/7/5): confirmar.
8. **Biomas**: 5 casos de `Biome` para un continente (uno por área tipo). Si se prefiere uno por continente, el
   environment-artist puede variar por `AreaMap.id`; decidir antes de que otros continentes añadan los suyos.
9. **`d` = vía de vagoneta** solo en el bioma `rocaforjaHall` (regla de "el mismo carácter según el bioma").

## Estado

| Encargo | Estado |
|---|---|
| Diseño del continente (este directorio) | **HECHO** (2026-10-08, `continent-lead` de `rocaforja`) |
| R0, R1, MD, CD, SW1, SW2, EA, PA, B, QA | Pendientes — fase futura, después de Valdemar; antes que Lunaria (que necesita el Túnel, el despertar y el maestro de viajes) |
