# Lunaria · encargos para el equipo (fase futura)

Responsable: `continent-lead` de `lunaria`. **Se lanzan después de Rocaforja** (Lunaria necesita su Túnel de los Thanes
y el despertar de la Hoja II). Cada encargo se puede pegar tal cual al agente. Todos leen antes `CLAUDE.md`,
`assets/world/continentes/lunaria/historia.md`, `zonas.md` y lo que cite su encargo. Referencia práctica del motor:
`assets/world/continentes/valdemar/contrato.md` y `src/GameCore/Sources/GameCore/Valdemar.swift` /
`ValdemarQuests.swift` (Lunaria copia ese formato). Ninguno hace commits. Al terminar, cada uno anota su línea en
`assets/design/tareas.md`.

## Orden y paralelismo

```
Fase 0  game-programmer ── L0 "datos y motor de Lunaria" (corto: casi todo el motor ya existe por Valdemar)
           │
Fase 1  ┌─ map-designer       MD  7 áreas + 10 interiores + pisos webs/hollow + 2 StoryDungeon   ← Lunaria.swift, LunariaFloors.swift
(paral.)├─ character-designer CD  15 monstruos + 4 jefes + plantillas spider/treant + NPC looks   ← Enemy.swift (al final), EnemyArt, NPCLooks
        ├─ story-writer       SW1 guion del capítulo 3 en assets/story/lunaria.md (sin tocar src/)
        └─ game-programmer    LQ  LunariaQuests.swift con textos provisionales (23 misiones)
           │
Fase 2  ┌─ environment-artist EA  biomas lunaria/copas/marchito, edificios élficos y lobo, pisos webs/hollow (necesita L0 + MD)
(paral.)├─ pixel-artist       PA  monstruos, jefes, NPC, formas glaive/leaf/moon, conjunto lunaria (necesita CD)
        └─ story-writer       SW2 textos al código (necesita LQ + MD)
           │
Fase 3  balance-designer   B   ritmo 20→30, jefes, piezas, minerales, forja tier 3, armadura (con todo jugable)
           │
Fase 4  qa-tester          QA  verificación completa
```

## Quién toca qué

| Fichero (`src/GameCore/Sources/GameCore/` salvo que se diga) | Dueño | Después |
|---|---|---|
| `World.swift` (registro de Lunaria, `Biome`), `WorldRules.swift`, `Shop.swift`, `Mineral.swift`, `Parts.swift` (enums), `Armor.swift` | game-programmer (L0) | balance-designer (B: números) |
| `Lunaria.swift` (nuevo: áreas, interiores, `StoryDungeon` nido/hueco) | map-designer | balance-designer (oleadas) |
| `LunariaFloors.swift` (nuevo: pisos `webs`, `hollow`, fuera de la rotación de la arena) | map-designer | environment-artist (arte) |
| `LunariaQuests.swift` (nuevo) / `LunariaDialogue.swift` (nuevo) | game-programmer (LQ) | story-writer (SW2), balance-designer (B) |
| `Enemy.swift` (añadir **al final**), `Arena.swift` (no tocar: `originalEnemyIDs` ya protege la arena) | character-designer | balance-designer |
| `GameTest1/Art/EnemyArt.swift`, `NPCLooks.swift`, `WeaponArt.swift` | character-designer → pixel-artist | — |
| `GameTest1/Art/FieldArt*.swift`, `TownArt*.swift`, `DungeonArt.swift` | environment-artist | — |
| Tests: `LunariaMapTests`, `LunariaQuestTests` | quien crea los datos | — |

---

## L0 · game-programmer · datos y motor de Lunaria (Fase 0, bloquea)

> **Motor común (revisión del world-designer, 2026-10-09)**: lo que se repite entre continentes está una sola vez en
> `assets/world/motor_comun.md`, ordenado y con el continente que lo estrena. Lunaria estrena el paquete **C** (C1-C5) y usa A y B (los hace Rocaforja). Equivalencias: N1→A4 (biomas `lunaria`, `lunariaCanopy`, `lunariaWithered`), N2→C5, N3→C1, N4→A3+C2, N5→B7, N6→C3; minerales, formas y armadura→B1-B4; Hoja (III)→B6.
> Antes de implementar una fila de esta tabla, mira allí: si ya está hecha, solo se usa; si es de otro paquete, se hace
> con el nombre y la forma de allí (no con los de esta tabla).

El motor de Valdemar (M1-M10) ya hace casi todo. Falta lo propio de Lunaria (necesidades N1-N7):

1. **Registro** (`World.swift`): `Continent(id: "lunaria", name: "Bosque de Lunaria", levels: 20...30, capitalID:
   "lunaria.velaluna", areaIDs: Lunaria.areas…, minerals: [.quicksilver, .amber, .jade, .moonstone, .amethyst], tier: 3,
   finalQuestID: "lunaria.pacto_de_la_luna", castleRequires: [], mapLayout: LunariaQuests.mapLayout)`. `World.areas`,
   `storyDungeons` y `quests` suman `Lunaria.areas`, `Lunaria.dungeons`, `LunariaQuests.all` (ficheros nuevos, vacíos).
2. **N1 · biomas**: `Biome.lunaria` (suelo del bosque), `Biome.lunariaCanopy` (Velaluna: `~` = vacío entre copas) y
   `Biome.lunariaWithered` (Bosque Marchito). Solo los casos; el dibujo, EA.
3. **N2 · segunda tienda**: Colmillo Gris tiene una curtiduría (Hirsa) que vende armadura de cuero/tela tier 3 sin
   ritual. Generalizar la tienda para que un edificio/NPC abra una tienda con su catálogo (la forja con ritual sigue
   siendo la de Velaluna). Si es caro, *alternativa*: Hirsa solo vende en diálogo una lista fija.
4. **N3 · pisos de historia**: `Dungeon.floor(id)` hoy busca solo en `Dungeon.floors` (la rotación de la arena). Añadir
   `Dungeon.storyFloors` (los pisos de los continentes) y que `floor(id)` busque en ambos; la arena sigue con sus 5.
   Añadir a `DungeonTheme` los casos `webs` y `hollow`.
5. **N4 · dos `.town` en un continente** y escalinata: `lockedTiles` bloquea las `S` de cualquier `.town` si el castillo
   del continente no está abierto, y usa `ValdemarQuests.stairsMessage`. Con `castleRequires: []` debe contar como
   abierto (comprobarlo con un test) y el aviso debe salir del continente, no de Valdemar.
6. **N5 · maestro de viajes**: si Rocaforja no lo ha hecho ya, NPC que lleva a las capitales visitadas
   (`visitedAreaIDs`). En Lunaria: `nimra` (Velaluna) y el lobo mensajero `mensajeroColmillo` (Colmillo).
7. **N6 · NPC que desaparecen**: `NPC.appearsWhen` solo admite condiciones positivas. Ysolde desaparece tras
   `lunaria.la_verdad`: añadir `NPC.hiddenWhen: StoryCondition?` (defecto nil) o `StoryCondition.not(...)`.
8. **Minerales** `quicksilver`, `amber`, `jade`, `moonstone` al final de `Mineral` (con nombre, color, bonificación de
   `minerales.md`; `rarityTier` por familia). **Formas** `glaive`, `leaf`, `moon` al final de sus enums (`piezas.md`).
   **Armadura** `helm/chest/gloves/boots.lunaria` en `ArmorStyle` (no en la tienda: solo por `QuestReward.gearID`).
9. Hoja del Alba (III): reutilizar el despertar que haga Rocaforja (II) con el Ascua de Lunaria.

**Comprobar**: `make test` (WorldTests se aplica solo a los datos nuevos), `make balance` igual que antes (la arena no
cambia), `make verify`. **Hecho cuando** compila, los tests pasan y Lunaria aparece registrada vacía.

---

## MD · map-designer · áreas, interiores y pisos (Fase 1, tras L0)

**Fuente**: `lunaria/mapas/*.md` y `zonas.md` ("Ids para el código"). Velaluna está a escala real (transcribir). Las
otras 6 áreas son **bocetos 1:2**: cada carácter = bloque 2×2; ampliarlos a 60×36 (Colmillo 44×32) dándoles forma
orgánica (bordes irregulares, caminos de 3+ casillas, claros para pelear, 2+ rutas), respetando salidas, zonas, puntos
y spawns de las tablas.

1. `Lunaria.swift`: `enum Lunaria` con `velaluna` (`.town`, bioma `.lunariaCanopy`), `colmillo` (`.town`), `raices`, `claros`,
   `espesura`, `marchito`, `lago` (`.field`, bioma `.lunaria`/`.lunariaWithered`), `continentID: "lunaria"`, zonas
   `lunaria.<área>.<zona>`, spawns `lunaria.<área>.<n>`, `exits` y `safePoint` de `zonas.md`, edificios de
   `mapas/velaluna.md` y `mapas/colmillo.md` con sus 10 interiores (`kind: .interior`, sin monstruos), NPC con
   `appearsWhen` (y `hiddenWhen` de Ysolde si L0 lo añade). Aras y estelas del Lago como NPC `.clue`.
2. `LunariaFloors.swift`: pisos `webs` (Nido de las Tejedoras) y `hollow` (Hueco del Árbol Madre) en
   `Dungeon.storyFloors`, a partir de los bocetos de `mapas/nido.md` y `mapas/hueco.md`, con las reglas de
   `assets/maps/mazmorra.md` (8-12 entradas, 300+ casillas, pasillos de 3+).
3. `Lunaria.dungeons`: `StoryDungeon` `lunaria.nido` (piso `webs`, nivel 26, jefe `broodMother` + 4 `spiderling`) y
   `lunaria.hueco` (piso `hollow`, nivel 30, jefe `ysolde` + 2 `witheredBlade` + 1 `treant`), oleadas de `zonas.md`,
   entradas `e` con sus bloqueos.
4. Coordinar con Rocaforja: la salida `este` de `rocaforja.hondoyunque` lleva a `lunaria.raices` (2, 10).
5. `assets/maps/lunaria.md`: resumen y renders.

**Comprobar**: `make test` (+ `LunariaMapTests`: filas iguales, borde cerrado salvo `>`, todo conectado desde `entry`,
spawns pisables y en zona, salidas/llegadas válidas), `make maps`, `make dungeon` (mirar `webs` y `hollow`).
**Hecho cuando** los tests pasan y los renders siguen los bocetos.

---

## CD · character-designer · monstruos, jefes y NPC (Fase 1, tras L0; en paralelo con MD)

1. `Enemy.swift`, **al final de `Bestiary.all`**: los 15 monstruos y 4 jefes de `bestiario.md` §2-3 con sus números
   provisionales. No tocar `Arena.originalEnemyIDs` (ya deja fuera a todos los nuevos) y comprobar que los 4 jefes
   nuevos no entran en la arena.
2. Plantillas nuevas `spider` y `treant` en `EnemyArt.spec` (aspecto básico jugable) y las variantes de `bestiario.md`
   §1 (alas de libélula, sombrero de seta, astas…).
3. Looks de NPC en `NPCLooks.swift`: `elarith`, `sylra`, `ysolde` (normal), `thessa`, `fendril`, `mirla`, `ilmar`,
   `nimra`, `ulma`, `rhovan`, `hirsa`, `pico`, `trapisonda`, `varg`, `liria`, `posaderaVelaluna`, guardias élficos y
   lobos de ambiente, `ara`/`estela` (look de `clue`).
4. `assets/characters/`: fichas y `make fichas`.

**Comprobar**: `make test`, `make balance` (la arena igual: mismas oleadas de caída), `make sprites`.

---

## LQ · game-programmer · misiones de Lunaria (Fase 1, tras L0; en paralelo con MD y CD)

`LunariaQuests.swift` con las 12 principales (`historia.md` §4) y 11 secundarias (`zonas.md`), objetivos y requisitos
de `zonas.md` ("Misiones → QuestObjective"), textos provisionales de `historia.md`, recompensas orientativas
(principal normal ≈25 % de `xpToNext`; `la_verdad` y `pacto` ≈50 %; `arbol_madre` ≈100 %; secundarias 15-25 %),
`gearID` del conjunto lunaria y `partID` de jefes. `mapLayout` del continente con el esquema de `zonas.md`.
`lunaria.bajo_las_raices` se acepta sola al entrar en Raíces (`autoAccept`).
**Comprobar**: `make test` (+ `LunariaQuestTests`: cadena completa con un perfil de prueba hasta el Pacto).

---

## SW1 · story-writer · guion del capítulo 3 (Fase 1, sin tocar `src/`)

`assets/story/lunaria.md` (y `assets/story/historia.md`): con ids, todo lo que hablará el juego —
oferta/recordatorio/entrega de las 23 misiones; diálogos de ambiente por NPC y por etapa (`npc.<id>.<etapa>`); líneas
por raza (elfo, hombre lobo, humano/enano: `historia.md` §3); presentaciones y caídas de los 4 jefes
(`bossIntro`, `bossIntroRepeat`, `bossDefeat`; en el Hueco, la escena de la Hermana Brasa recogiendo el Molde); avisos
de bloqueo (Nido, Hueco); textos de aras y estelas; epílogo del Pacto y gancho de Cenizas. Frases cortas.

## SW2 · story-writer · textos al código (Fase 2, tras LQ y MD)

Pegar SW1 en `LunariaQuests.swift`, `LunariaDialogue.swift`, `NPC.talk`, `AreaExit/DungeonEntrance.lockedMessage` y
`StoryDungeon`. **Comprobar**: `make test` y `make check-lunaria` (si existe) sin textos provisionales.

---

## EA · environment-artist · escenarios de Lunaria (Fase 2, tras L0 + MD)

1. Bioma `lunaria`: musgo, setas luminosas `,`, árboles de plata `T`, helechos `b`/`%`, río `~`, raíces `R`, estelas y
   tótems `+`, hogueras, cueva `e` con seda. Paleta azul noche, plata, verde musgo; luces frías de luna.
2. Bioma `lunariaCanopy` (Velaluna): plataformas de tablas, vacío con el suelo del bosque abajo, puentes colgantes, farolillos.
3. Bioma `lunariaWithered`: árboles grises muertos, hojarasca negra, niebla violeta, braseros violetas y estandartes.
4. Estilos de edificio élficos (palacio, posada, forja, torre, santuario, casa) y lobo (Gran Cubil, curtiduría, casa
   larga, casa de cachorros) como variantes de bioma de los estilos existentes.
5. Pisos `webs` y `hollow` en `DungeonArt` (temas nuevos de N3) y ambiente nocturno general.
**Comprobar**: `make maps`, `make dungeon`, `make shots`; mirar los PNG.

## PA · pixel-artist · personajes y objetos (Fase 2, tras CD)

Monstruos y jefes de `bestiario.md` (arañas y árboles con plantilla nueva; animaciones de paso/ataque/daño), NPC de
`historia.md` §3 (Ysolde en dos formas), formas `glaive`/`leaf`/`moon` en `WeaponArt`, las 4 piezas de jefe y el
conjunto `*.lunaria` (`piezas.md`). **Comprobar**: `make sprites`, `make shop`.

---

## B · balance-designer · ritmo 20→30 y números (Fase 3, con todo jugable)

> **XP de misiones (revisión del world-designer)**: el presupuesto es **≈400-450 %** de `xpToNext` por continente (suma de los % de todas sus misiones; `progresion.md` §2). Este continente suma hoy **~625 %**: secundarias al 10-15 %, principales normales al 20 %. Jefes de historia: ×6 (`Leveling.storyBossMultiplier`).

Estadísticas de los 19 enemigos (objetivos de `progresion.md` §7), oleadas de Nido y Hueco, minerales (bonificación
×2,4 en planas), piezas de jefe (≈1,5× tier 3), formas nuevas, conjunto lunaria, recompensas de las 23 misiones,
forja tier 3 (tier 4 tras el Pacto), y el ritmo 20→30 (~84 000 XP; monstruos 50 % · misiones 40 % · jefes 10 %)
con la simulación del modo historia. **Comprobar**: `make balance` (arena intacta) y la simulación de historia.

## QA · qa-tester · verificación (Fase 4)

`make verify`; recorrer con un perfil de nivel 20 tras Rocaforja: Túnel → Raíces → las 2 capitales → todas las salidas,
las 2 mazmorras con sus bloqueos, la cadena principal hasta el Pacto, Ysolde desaparece de Velaluna tras `la_verdad`,
la tienda de Hirsa, el despertar de la Hoja (III) y la arena sin monstruos de Lunaria. Informe con pasos.

## Estado

| Encargo | Estado |
|---|---|
| Diseño del continente (este directorio) | Hecho (borrador 1, 2026-10-08) |
| L0, MD, CD, LQ, SW1, SW2, EA, PA, B, QA | Pendientes — fase futura, después de Rocaforja |
