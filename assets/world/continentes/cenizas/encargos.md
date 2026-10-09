# Cenizas · encargos para el equipo (FASE FUTURA)

Responsable: `continent-lead` de `cenizas`. **Fase futura**: se lanzan cuando el usuario lo pida, con Valdemar,
Rocaforja y Lunaria ya jugables (Cenizas depende de lo que estrenan: maestro de viajes, despertar de la Hoja,
`doorLocks` por continente, minerales y formas por continente). Cada encargo se puede pegar tal cual al agente.
Todos leen antes `CLAUDE.md`, `assets/world/continentes/cenizas/historia.md`, `zonas.md`, el `contrato.md` de
Valdemar y lo que cite su encargo. Nadie hace commits. Al terminar, cada uno anota su línea en
`assets/design/tareas.md` y en "Estado" (al final de este fichero).

**Referencia práctica**: hacer Cenizas **como Valdemar y Rocaforja**: `Cenizas.swift` ≈ `Valdemar.swift`,
`CenizasQuests.swift` ≈ `ValdemarQuests.swift`, `CenizasDialogue.swift` ≈ `ValdemarDialogue.swift`,
`make check-cenizas` ≈ `make check-valdemar`.

## Orden y paralelismo

```
Fase 0  game-programmer ── C0 "Cenizas en el contrato" (corto: Continent, registro, biomas y estilos vacíos)
           │
Fase 1  ┌─ game-programmer    C1 motor: llegada por mar, pisos tomb/caldera, minerales, formas, piezas, Hoja (IV)
(paral.)├─ map-designer       MD 6 áreas + 10 interiores + 2 mazmorras en Cenizas.swift   ← solo datos de mapas
        ├─ character-designer CD 14 monstruos + élite + 4 jefes + NPC  ← final de Bestiary.all, EnemyArt.spec, NPCLooks
        └─ story-writer       SW1 guion completo en assets/story/cenizas.md (sin tocar src/)
           │
Fase 2  ┌─ environment-artist EA 3 biomas, 5 estilos de edificio, pisos tomb y caldera, lava   (necesita C0 + MD)
(paral.)├─ pixel-artist       PA plantillas scorpion/crab, monstruos, jefes, NPC, formas, minerales, Hoja (IV) (CD + C1)
        └─ story-writer       SW2 textos al código (CenizasQuests, CenizasDialogue, avisos, murales)  (C1 + MD)
           │
Fase 3  balance-designer      B ritmo 30→40, monstruos, jefes, piezas, minerales, forja, mazmorras  (con todo jugable)
           │
Fase 4  qa-tester             QA verificación completa
```

Se puede lanzar **en paralelo con los encargos de otros continentes** si cada uno respeta sus ficheros y solo añade
al final de las listas compartidas (`Bestiary.all`, `Mineral`, `WeaponShape`/`GuardShape`/`GripShape`,
`specialParts`, habilidades de jefe, `Biome`, `BuildingStyle`, `World.continents`, pisos de `Dungeon.swift`).

## Quién toca qué

| Fichero | Dueño | Notas |
|---|---|---|
| `GameCore/World.swift`, `WorldRules.swift`, `QuestEngine.swift`, `ContinentLoot.swift` | game-programmer (C0, C1) | Registrar Cenizas; llegada por mar |
| `GameCore/Cenizas.swift` (nuevo) | map-designer | Áreas, interiores, `StoryDungeon` `cenizas.tumba` y `cenizas.caldera` |
| `GameCore/CenizasQuests.swift` (nuevo) | game-programmer (C0, textos provisionales de `zonas.md` §6) → story-writer (SW2) → balance-designer (B) | 21 misiones, `doorLocks`, `mapLayout`, `finalQuestID` |
| `GameCore/CenizasDialogue.swift` (nuevo) | story-writer (SW2) | Llegada por raza, jefes, avisos, HUD, murales |
| `GameCore/Dungeon.swift` | map-designer (filas) + game-programmer (registro) | Pisos `tomb` y `caldera` **fuera** de la rotación de la arena |
| `GameCore/Enemy.swift` | character-designer → balance-designer | Al final de `Bestiary.all`, bajo `// Cenizas` |
| `GameCore/Mineral.swift`, `Parts.swift`, `Ability.swift` | game-programmer (C1) → balance-designer | Casos nuevos al final; la arena no los ve |
| `GameTest1/Art/EnemyArt.swift`, `NPCLooks.swift`, `WeaponArt.swift` | character-designer (básico) → pixel-artist | Plantillas `scorpion`, `crab` |
| `GameTest1/Art/` biomas y `DungeonArt` (pisos nuevos) | environment-artist | `make project` si añade ficheros |
| `tools/Harness/…` | game-programmer (`check-cenizas`) → balance-designer (simulación 30→40) | |
| `assets/maps/cenizas.md`, `assets/characters/`, `assets/story/cenizas.md`, `assets/art/`, `assets/balance/` | su especialista | |

---

## Necesidades de motor (lo que Valdemar, Rocaforja y Lunaria no tienen)

> **Motor común (revisión del world-designer, 2026-10-09)**: lo que se repite entre continentes está una sola vez en
> `assets/world/motor_comun.md`, ordenado y con el continente que lo estrena. Cenizas estrena el paquete **D** (D1, llegada por mar). Equivalencias: C1.1→A1, C1.2→D1+B7, C1.3→C1, C1.4→A4/A5, C1.5→B1-B4/B6, C1.6→B4 (combos), C1.7→C4, C1.8→arte.
> Antes de implementar una fila de esta tabla, mira allí: si ya está hecha, solo se usa; si es de otro paquete, se hace
> con el nombre y la forma de allí (no con los de esta tabla).

Se da por hecho lo que piden Rocaforja (N1-N8: generalizar `doorLocks`/HUD por continente, maestro de viajes,
despertar de la Hoja, forja por capital, minerales y formas por continente) y Lunaria. Si algo no está, C1 lo hace.

| # | Prioridad | Qué | Por qué |
|---|---|---|---|
| C1.1 | P1 | **Cenizas como datos**: `Continent(id: "cenizas", name: "Yermo de Cenizas", levels: 30...40, capitalID: "cenizas.fortin", minerals: [.sulfur, .garnet, .sunstone, .fireopal, .ruby], tier: 4, finalQuestID: "cenizas.cuarta_brasa", mapLayout: …)`; `World.areas/storyDungeons/quests` concatenan las de Cenizas. | M7. |
| C1.2 | P1 | **Llegada por mar al continente**: el maestro de viajes ofrece un continente **nuevo** cuando su requisito está hecho (`lunaria.pacto_de_la_luna`) aunque su capital no se haya visitado; la **primera** vez deja en el área y casilla de llegada del continente (propuesta: `Continent.arrival: (areaID: "cenizas.costa", tile: (12, 17))`); después, en la capital como siempre. `margaCapitana` añade Hielomar tras `cenizas.cuarta_brasa` (`comingSoon("escarcha")` hasta que exista). | Cenizas es el primer continente al que se llega en barco (`mundo.md` §10). |
| C1.3 | P1 | **Pisos nuevos** `tomb` y `caldera` en `Dungeon.swift` (filas del map-designer), que **no** entran en la rotación de la arena. | `StoryDungeon` de Cenizas. |
| C1.4 | P1 | **Biomas** `cenizasOasis`, `cenizasAsh`, `cenizasVolcano` en `Biome` (al final) y **estilos** `fortTent`, `adobeHouse`, `digSite`, `solarTemple`, `solarPalace` en `BuildingStyle` con `placeholder` `castle`, `house`, `house`, `chapel`, `castle`. | Dibujo por bioma (fase 2). |
| C1.5 | P1 | **Minerales** `sulfur`, `garnet`, `sunstone`, `fireopal` (datos explícitos, `minerales.md`); **formas** `khopesh`, `sun`, `scarab` (`piezas.md` §2); **piezas de jefe** y 4 habilidades nuevas (`piezas.md` §3); **Hoja del Alba (IV)** con el sistema de despertar. | Progresión del continente. |
| C1.6 | P2 | Combos nuevos opcionales `sunfire`, `pitch`, `embalm` (`piezas.md` §2), si el balance-designer los aprueba. | Que las formas nuevas combinen. |
| C1.7 | P2 | **Mismo NPC en varios continentes** (`princess`, `brokk`, `thessa`, `zigoMercader`, `hermanaBrasa`) con `appearsWhen`; si el registro exige ids únicos en todo el mundo, dar un id por continente con el mismo look (`thessaCenizas`) y avisar al story-writer. | Personajes que viajan. |
| C1.8 | P3 | `DungeonTile` de mural (decorativo) para la Tumba, o usar `#` con arte. | Opcional. |

No hace falta nada más: los murales y los braseros violeta son NPC `.clue` (como la carta del alcalde y los crisoles
de Rocaforja), la Sala de los Murales y el palacio son puertas cerradas por misión (`doorLocks`), Ozrán es un spawn
de interior, y la escena de la Hermana Brasa va en `StoryDungeon.bossDefeat` (como en Lunaria).

---

## C0 · game-programmer — "Cenizas en el contrato"

> Lee `assets/world/continentes/cenizas/zonas.md` y `encargos.md` (Necesidades de motor) y el `contrato.md` de
> Valdemar. Crea `Cenizas.swift` y `CenizasQuests.swift` **vacíos pero registrados** (como se hizo con Valdemar y
> Rocaforja), añade el `Continent` de Cenizas (C1.1), los 3 biomas y los 5 estilos de edificio (C1.4) al final de sus
> enums, y las 21 misiones de `zonas.md` §6 con textos provisionales (`title`/`summary` del propio documento).
> **Hecho**: `make test` en verde (los tests de `WorldTests` validan ids, requisitos y destinos).

## C1 · game-programmer — motor de Cenizas

> Implementa C1.2-C1.7 de "Necesidades de motor" en GameCore con tests: llegada por mar (y la vuelta), pisos
> `tomb`/`caldera` registrados fuera de la arena, minerales, formas, piezas de jefe y habilidades, Hoja del Alba (IV).
> La arena no cambia (sus 10 minerales, sus 50 enemigos y 10 jefes). Añade `make check-cenizas` (≈ `check-valdemar`):
> llegar en barco a la Costa, misiones 1-5, puertas cerradas (`fortin.sur`, `dunas.este`, Tumba, murales,
> `laderas.oeste`, palacio, Caldera, atajo), ganar las dos mazmorras y despertar la Hoja.
> **Hecho**: `make test`, `make check-cenizas`, `make verify` en verde; una partida de Lunaria terminada carga y
> puede viajar a Cenizas.

## MD · map-designer — mapas de Cenizas

> Pasa los borradores de `assets/world/continentes/cenizas/mapas/` a `Cenizas.swift`: `cenizas.fortin` (`.town`,
> **detallado**: filas listas en `mapas/fortin.md`), los 5 campos (`costa`, `dunas`, `necropolis`, `laderas`,
> `sepultada`; bocetos a escala 1:2 → tamaño real), los 10 interiores de `zonas.md` §1 y las dos mazmorras
> (`StoryDungeon` de `zonas.md` §5; pisos `tomb` y `caldera` desde `mapas/tomb.md` y `mapas/caldera.md`, con las
> reglas de `assets/maps/mazmorra.md`). Salidas, bajadas, bloqueos y puntos seguros: `zonas.md` §3 (ajusta las
> coordenadas al tamaño real y actualiza la tabla). Zonas y spawns: `zonas.md` §4 (ids `cenizas.<área>.<zona>` y
> `cenizas.<área>.<n>`). NPC: tablas de cada mapa. Documenta en `assets/maps/cenizas.md`.
> **Hecho**: `make test` (WorldTests + tests de mapa: conectividad, borde cerrado), `make maps`/`make dungeon` y
> revisar los PNG; 12-21 monstruos de campo por área, ninguno a menos de 8 casillas de una llegada.

## CD · character-designer — monstruos, jefes y NPC

> Añade al final de `Bestiary.all` (`// Cenizas`) los 14 monstruos, la élite `ashHerald` y los 4 jefes de
> `bestiario.md` (stats propuestas; `specialPartID` = `boss.<id>`), sus `EnemyArt.spec` básicos (plantillas nuevas
> `scorpion` y `crab` en versión sencilla; si no, `rat`/`boar` provisionales) y los looks de NPC de `bestiario.md`
> (resumen). Comprueba que la arena no los usa. Documenta en `assets/characters/`.
> **Hecho**: `make test`, `make sprites` (mirar las hojas), `make balance` igual que antes (la arena no cambia).

## SW1 · story-writer — guion de Cenizas

> Escribe `assets/story/cenizas.md` a partir de `historia.md`: ofertas/recordatorios/entregas de las 21 misiones,
> diálogos de NPC por etapa, llegada y líneas por raza, `bossIntro`/`bossIntroRepeat`/`bossDefeat` (Solano,
> Severián + escena de la Hermana Brasa), textos de las pistas (`muralCata`, `diarioFaro`, los 4 murales,
> `braseroVioleta1-3`), avisos de bloqueo (`zonas.md` §3) y epílogo. Coordina el tono de Thessa con Lunaria y de la
> Brasa con Rocaforja. Frases cortas (móvil). Actualiza `assets/story/historia.md`.
> **Hecho**: el documento cubre todos los ids de misión, NPC y pistas de `zonas.md`.

## EA · environment-artist — escenarios

> Dibuja los biomas `cenizasOasis`, `cenizasAsh`, `cenizasVolcano` (`zonas.md` §1: qué es cada carácter en cada uno;
> lava `~` con luz y brillo animado, agua humeante con vapor), los estilos `fortTent`, `adobeHouse`, `digSite`,
> `solarTemple`, `solarPalace` (al dibujarlos, su `placeholder` pasa a sí mismo), el barco naufragado y el barco
> negro, y los pisos `tomb` (sillería dorada, antorchas cálidas) y `caldera` (basalto, anillo de lava, altar del
> Ascua). Paleta: negro, gris ceniza, rojo lava, oro viejo (`continentes.md`).
> **Hecho**: `make maps`, `make dungeon`, `make shots` y revisar los PNG; nada se lee mal a 24 px.

## PA · pixel-artist — personajes y objetos

> Plantillas `scorpion` y `crab` completas (paso, ataque, daño), los 19 enemigos de `bestiario.md` (accesorios ★),
> looks de NPC (incluidos `mural` y `violetBrazier`), las formas `khopesh`/`sun`/`scarab` en `WeaponArt`, las 4 piezas
> de jefe (paletas en `piezas.md` §3), iconos de `sulfur`/`garnet`/`sunstone`/`fireopal` y la Hoja del Alba (IV).
> **Hecho**: `make sprites` y `make shop`, revisar los PNG; los escorpiones se distinguen de las ratas a primera vista.

## SW2 · story-writer — textos al código

> Pasa `assets/story/cenizas.md` a `CenizasQuests.swift` (`offer`, `reminder`, `turnIn`, `objectiveLabels`),
> `CenizasDialogue.swift`, `NPC.talk`, `AreaExit.lockedMessage`, `DungeonEntrance.lockedMessage` y textos de
> `StoryDungeon`. **Hecho**: `make test` y `make check-cenizas` en verde; ninguna línea pasa de ~90 caracteres.

## B · balance-designer — números

> **XP de misiones (revisión del world-designer)**: el presupuesto es **≈400-450 %** de `xpToNext` por continente (suma de los % de todas sus misiones; `progresion.md` §2). Este continente suma hoy **~610 %**: lo que ya proponía `zonas.md` §6, más secundarias al 10-15 %. Jefes de historia: ×6 (`Leveling.storyBossMultiplier`).

> Con todo jugable: ritmo 30→40 (~145 000 XP; monstruos 50 % · misiones 40 % · jefes 10 %; ojo, `zonas.md` §6 deja
> las misiones algo por encima: recorta), stats de monstruos y jefes contra `progresion.md` §7 a niveles 30-40,
> élite `ashHerald`, oleadas y premios de `cenizas.tumba`/`cenizas.caldera`, minerales (`minerales.md`), formas y
> piezas (`piezas.md`), forja tier 4 → 5, Hoja (IV). Simulación nueva 30→40 en el harness.
> **Hecho**: informe en `assets/balance/` con antes/después; `make balance` de la arena sin cambios.

## QA · qa-tester — verificación

> `make verify`, `make check-cenizas`, recorrido completo (barco desde Lunaria → Costa → … → Caldera → Hoja (IV) →
> barco del norte), puertas cerradas y sus avisos, reaparición en cada punto seguro, mazmorras repetibles, partida
> guardada antigua (v0.5, Valdemar, Rocaforja, Lunaria) carga sin perder nada; la arena igual que antes.
> **Hecho**: informe con pasos para reproducir.

---

## Estado

| Encargo | Estado |
|---|---|
| Diseño del continente (`historia`, `zonas`, `mapas/`, `bestiario`, `minerales`, `piezas`, `encargos`) | Hecho (borrador 2, 2026-10-08) |
| C0, C1, MD, CD, SW1, EA, PA, SW2, B, QA | Pendientes — fase futura, después de Lunaria |
