# Escarcha · encargos para el equipo (FASE FUTURA)

Responsable: `continent-lead` de `escarcha`. Estado: **borrador 2** (2026-10-08). **No se lanzan** hasta que estén
hechos Valdemar (motor M1-M10 y contrato), Rocaforja (despertar de la Hoja del Alba, maestro de viajes), Lunaria y
Cenizas (llegada por mar con Marga, `cenizas.cuarta_brasa`).
Diseño de referencia en esta carpeta: `historia.md`, `zonas.md` (datos en formato de contrato), `mapas/`,
`bestiario.md`, `minerales.md`, `piezas.md`. Tipos: `../valdemar/contrato.md`.

**Referencia práctica**: hacer Escarcha **como Valdemar y Cenizas**: `Escarcha.swift` ≈ `Valdemar.swift`,
`EscarchaQuests.swift` ≈ `ValdemarQuests.swift`, `EscarchaDialogue.swift` ≈ `ValdemarDialogue.swift`.
En las listas compartidas (`Bestiary.all`, `Mineral`, formas de `Parts`, `specialParts`, `AbilityBook`,
`ArmorStyle.styles`, `DungeonFloor`, `Biome`, `BuildingStyle`) **solo se añade al final**, bajo `// Escarcha`.
Ningún id existente se renombra; todo lo nuevo del perfil, opcional. Si se añaden ficheros: `make project`.

## Orden y paralelismo

```
X0 game-programmer  "Escarcha en el contrato" (registro vacío + tipos nuevos)   ← primero, corto
 │
 ├─(paral.)├─ MD  map-designer        7 áreas + 2 mazmorras en Escarcha.swift      ← solo datos de mapas
 │         ├─ CD  character-designer  20 enemigos, piezas de jefe, armadura, NPC   ← Enemy/Parts/Armor + looks
 │         ├─ SW1 story-writer        guion en assets/story/escarcha.md            ← solo documentos
 │         └─ X1  game-programmer     minerales, formas, habilidades, pisos, Corona ← Mineral/Parts/Ability/Dungeon
 │
 ├─(paral., tras MD y CD)├─ EA environment-artist  biomas, edificios, pisos glacier/citadel
 │                       └─ PA pixel-artist        monstruos, jefes, NPC, piezas, conjunto
 ├─ SW2 story-writer   textos al código (tras SW1 y X0)
 ├─ B   balance-designer (con todo jugable)
 └─ QA  qa-tester (al final)
```

## Quién toca qué

| Fichero | Quién | Qué |
|---|---|---|
| `GameCore/World.swift`, `WorldRules.swift`, `QuestEngine.swift`, `ContinentLoot.swift` | game-programmer (X0, X1) | Registrar `escarcha` (40-50, capital `escarcha.hielomar`, tier 5, familia `quartz/rimeiron/aquamarine/moonshard/sapphire`); `Biome` `escarchaPort/Snow/Shard/Silver`; `BuildingStyle` `longhouse/iceCave/giantHall` con `placeholder` |
| `GameCore/Escarcha.swift` (nuevo) | map-designer | Áreas, interiores, salidas, `safePoint`, `StoryDungeon` `escarcha.sima` y `escarcha.ciudadela` |
| `GameCore/EscarchaQuests.swift` (nuevo) | game-programmer (X0, textos provisionales de `zonas.md` §6) → story-writer (SW2) → balance-designer (B) | 21 misiones, `doorLocks` (cueva, trono, pista), `mapLayout`, misión final `escarcha.quinta_luz` |
| `GameCore/EscarchaDialogue.swift` (nuevo) | story-writer (SW2) | Llegada por raza, presentación de jefes, escenas (Cráter, Ciudadela), avisos, HUD |
| `GameCore/Dungeon.swift` | map-designer (filas) + game-programmer (registro) | Pisos `glacier` y `citadel` **fuera** de la rotación de la arena |
| `GameCore/Enemy.swift` | character-designer → balance-designer | 15 normales + 5 jefes al final de `Bestiary.all` |
| `GameCore/Mineral.swift`, `Parts.swift`, `Ability.swift`, `Armor.swift` | game-programmer (X1) / character-designer (CD) → balance-designer | Casos nuevos al final; la arena no los ve |
| `GameTest1/Art/*` | character-designer (básico) → pixel-artist / environment-artist | Ver PA y EA |
| `assets/story/escarcha.md`, `assets/story/historia.md` | story-writer | Guion y biblia |

## Necesidades de motor (lo que no traen Valdemar ni Cenizas)

> **Motor común (revisión del world-designer, 2026-10-09)**: lo que se repite entre continentes está una sola vez en
> `assets/world/motor_comun.md`, ordenado y con el continente que lo estrena. Escarcha puede estrenar el paquete **E** (fases de jefe, esbirros, área con aviso) si lo quiere usar; si no, lo hace Umbral. Equivalencias: X1.1→C1, X1.2→B3, X1.3→B1/B2, X1.4→B4, X1.5→B6 (la Corona es una bandera: `escarcha.reina` hecha), X1.6→ya existe (`bossDefeat`), X1.7→E1-E4, X1.8→B4 (combo `north_wind`).
> Antes de implementar una fila de esta tabla, mira allí: si ya está hecha, solo se usa; si es de otro paquete, se hace
> con el nombre y la forma de allí (no con los de esta tabla).

| # | Prioridad | Qué | Para qué |
|---|---|---|---|
| X1.1 | P1 | **Pisos `glacier` y `citadel`** en `DungeonFloor`, fuera de la arena. | Las 2 mazmorras de historia. |
| X1.2 | P1 | **Formas `halberd`, `frost`, `fur`** (al final de sus enums; `piezas.md` §1). | Piezas del tier 5. |
| X1.3 | P1 | **Minerales** `quartz`, `rimeiron`, `aquamarine`, `moonshard` (`sapphire` ya existe) con rareza por familia y bonificación escalada (`minerales.md`). | Botín del continente. |
| X1.4 | P1 | **Habilidades de jefe** `blizzard`, `shatter`, `avalanche`, `broken_oath`, `moonfall` (efectos que ya existen: `slow`, torbellino, onda, `healOnKill`, rayos, `bonus`). | Piezas `boss.*`. |
| X1.5 | P1 | **Corona de Esquirlas** como objeto de historia (una bandera: `escarcha.reina` hecha) que el despertar (V) acepta en lugar del Ascua. | El golpe bajo (`historia.md` §7.1). |
| X1.6 | P2 | **NPC de escena** en `bossDefeat` (Corvino; ya existe el patrón con la Hermana Brasa). | Final de la Ciudadela. |
| X1.7 | P3 | Proyectil enemigo que ralentiza; jefe que invoca esbirros; fase 2 de jefe (`bestiario.md`). | Opcionales: sin ellos el diseño funciona. |
| X1.8 | P3 | Combinación Hielo + Viento `north_wind` (`piezas.md` §5). | Opcional. |

---

## X0 · game-programmer — "Escarcha en el contrato"

> Registra Escarcha en `World` como se hizo con Valdemar y Cenizas: `Escarcha.swift` y `EscarchaQuests.swift`
> **vacíos pero registrados**, el `Continent` `escarcha`, los 4 `Biome` y los 3 `BuildingStyle` nuevos (con
> `placeholder`). Requisito de la primera misión: `.questDone("cenizas.cuarta_brasa")`; Marga añade Hielomar a su ruta
> (hasta ahora `.comingSoon("escarcha")`). **Comprobar**: `make test` (WorldTests) y partidas viejas cargan.

## X1 · game-programmer — motor de Escarcha

> X1.1-X1.5 (y X1.6 si hace falta) de la tabla. Tests nuevos en `Tests/GameCoreTests/EscarchaTests.swift`: la arena
> sigue con 10 minerales y 10 jefes, los pisos nuevos no están en la rotación, el despertar (V) pide la Corona y la (IV),
> las formas nuevas generan piezas de todos los materiales. **Comprobar**: `make test`, `make balance` (arena intacta),
> `make verify`.

## MD · map-designer — mapas de Escarcha

> Pasa los borradores de `assets/world/continentes/escarcha/mapas/` a `Escarcha.swift`: `escarcha.hielomar`
> (`.town`, 48×36, 1:1 en `mapas/hielomar.md`, edificios y puertas de su tabla), sus 5 interiores; los 5 campos
> (`costa` 56×36, `tundra` 64×40, `crater` 56×40, `gigantes` 60×40, `murallas` 56×36) desde los bocetos 1:2 (caminos de
> 3+ casillas, claros, 3 zonas de nivel por área); los interiores `escarcha.tundra.cueva` y `escarcha.gigantes.trono`
> (bocetos 1:1). Salidas, bajadas, `doorLocks`, `safePoint`, zonas, spawns, pistas `.clue` y NPC con los ids y
> coordenadas de `zonas.md` §1-4 (ajusta las coordenadas al pasar a 1:1 y actualiza `zonas.md`). Pisos `glacier`
> (44×24) y `citadel` (46×26) en `Dungeon.swift` desde sus bocetos, con las reglas de `assets/maps/mazmorra.md`.
> `StoryDungeon` de `zonas.md` §5. **Comprobar**: `make test` (WorldTests + un `EscarchaMapTests` de conectividad y
> borde cerrado), `make maps`, `make dungeon` (mirar los PNG), `make balance` sin "⚠︎ atasco" en los pisos nuevos.

## CD · character-designer — monstruos, jefes y NPC

> Al final de `Bestiary.all`, bajo `// Escarcha`: los 15 monstruos y 5 jefes de `bestiario.md` (estadísticas
> orientativas, plantillas y comportamientos de la tabla). Piezas `boss.*` en `specialParts` (tier 5, `piezas.md` §2,
> con las habilidades de X1.4). Conjunto `helm/chest/gloves/boots.escarcha` en `ArmorStyle.styles`. NPC (looks
> básicos con los cuerpos existentes): `jarlaSigrun` (mano de plata), `ulfTresdedos`, `solveigTabernera`,
> `ragnaHerrera`, `ingridVidente` (ciega, velo), `torvaldTrampero`, `halvar` (armadura de la orden, vendado),
> `corvino` (escena); reutiliza `princess`, `brokk`, `margaCapitana`, `zigoMercader`, `hermanaBrasa`, `thessa` con
> `appearsWhen`. Pistas `.clue` (`esquirlaCaida`, `diarioTrampero`, `cartaBrasa`, `totemAurora1-3`). `EnemyArt.spec`
> provisional para cada id. **Comprobar**: `make test`, `make sprites`, `make fichas`.

## SW1 · story-writer — guion de Escarcha

> `assets/story/escarcha.md` desde `historia.md`: diálogos de los NPC antes y después de cada misión (21, `zonas.md`
> §6), escenas (llegada, Ingrid y la esquirla, carta de la Brasa, Corvino y la Brasa en el Cráter, el caballero
> congelado, confesión de Hrimgar, muerte de Eirik, final de la Reina, epílogo del dirigible), líneas por raza,
> carteles de zona ("Tundra Aullante · 42-44"), avisos de salidas y puertas. Frases cortas (móvil). Actualiza la biblia
> `assets/story/historia.md` (capítulo 5, glosario: esquirla de luna, Escala de Esquirlas, Corona de Esquirlas,
> Caballeros de la Luna Rota, Corvino). Coordinar con Umbral el paso de Ser Hálvar a Mariscal.

## SW2 · story-writer — textos al código

> Pasa `assets/story/escarcha.md` a `EscarchaQuests.swift` (`offer`, `reminder`, `turnIn`, `objectiveLabels`),
> `EscarchaDialogue.swift`, `NPC.talk`, `AreaExit.lockedMessage`, `DungeonEntrance.lockedMessage` y los textos de las
> mazmorras (`bossIntro`, `bossIntroRepeat`, `bossDefeat`). **Comprobar**: `make test`; que ningún texto pase de 2
> líneas en el iPhone (`-pantalla dialogo`).

## EA · environment-artist — escenarios

> Biomas `escarchaPort`, `escarchaSnow`, `escarchaShard`, `escarchaSilver` (`zonas.md` §1: nieve, hielo vitrificado,
> pinos nevados, agua del fiordo con témpanos, pared de glaciar, costillares de ballena, menhires rúnicos, esquirlas
> que brillan, losas de plata). Edificios `longhouse`, `iceCave`, `giantHall` (al dibujarlos, su `placeholder` pasa a
> ser él mismo). Interiores de Hielomar, cueva y trono. Pisos `glacier` (hielo azul translúcido, cristales que
> iluminan, caballero congelado en la pared norte) y `citadel` (plata, estandartes de la luna partida, techo abierto
> con la Luna rota, rayo de la Escala). Ambiente: ventisca (más fuerte en la Tundra), auroras violetas (Hielomar,
> Cráter), vaho de braseros; opcional, grieta en la Luna tras `escarcha.reina`. **Comprobar**: `make maps`,
> `make dungeon`, `make shots`; que el héroe se lea bien sobre la nieve (contorno oscuro).

## PA · pixel-artist — personajes y objetos

> Sprites y animaciones (paso, ataque, daño) de los 20 enemigos con las ideas y la paleta de `bestiario.md`;
> opcional, plantilla `giant` (más alta que `brute`). Accesorios de `human`: alabarda, velo, corona de esquirlas,
> chubasquero, tabardo de la orden, astrolabio (Corvino). NPC con más detalle. Piezas `halberd`/`frost`/`fur` en todos
> los materiales, las 5 piezas únicas (paletas de `piezas.md` §2), el conjunto `*.escarcha` en las 4 razas, iconos de
> los 4 minerales nuevos y la Corona de Esquirlas. **Comprobar**: `make sprites`, `make hero`, `make shop`.

## B · balance-designer — números

> **XP de misiones (revisión del world-designer)**: el presupuesto es **≈400-450 %** de `xpToNext` por continente (suma de los % de todas sus misiones; `progresion.md` §2). Este continente suma hoy **~720 %**: secundarias al 10-15 %, `sima` al 40 %, jefes de zona al 30 %. Jefes de historia: ×6 (`Leveling.storyBossMultiplier`).

> Con la simulación del modo historia (bot con equipo tier 5, calidad media, nivel = zona): objetivos de
> `progresion.md` §7 en las 5 áreas, la Sima y la Ciudadela; vida/daño de los 20 enemigos; formas nuevas, piezas
> únicas (≈1,5× tier 5) y conjunto; bonificaciones de los 4 minerales (×4,4 en planas); XP de las 21 misiones y ritmo
> 40→50 (~3,5-4 h); precios de la forja tier 5; recompensas de las mazmorras. Sección Escarcha en
> `assets/balance/README.md`. **Comprobar**: `make balance` y la simulación de historia antes/después.

## QA · qa-tester — verificación

> `make verify`. Con un perfil de nivel 40 (y uno de 50 para el final): llegada con Marga, Hielomar → Costa → Tundra →
> Cráter → Sima → Gigantes (por las dos rutas) → Murallas → Ciudadela; salidas en ambos sentidos y sus bloqueos,
> reaparición en hogueras y posada, misiones en orden, jefes permanentes, escena final, Corona y despertar (V), pista
> del dirigible, Ulf llevando a las capitales visitadas; la arena sin cambios y una partida antigua que carga.
> Informe con pasos para reproducir y capturas (`make shots`).

## Estado

| Encargo | Estado |
|---|---|
| Diseño (este continente) | Hecho (borrador 2): `historia.md`, `zonas.md`, `mapas/` (Hielomar 1:1, resto en bocetos 1:2), `bestiario.md`, `minerales.md`, `piezas.md` |
| X0 … QA | Pendientes (fase futura) |
| Propuestas al world-designer | `historia.md` §7 (golpe bajo, Brasa→Corvino, Hálvar compartido con Umbral, 5 jefes) |
