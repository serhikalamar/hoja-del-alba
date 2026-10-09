# Los 6 continentes de Ardenia

Responsable: `world-designer`. Estado: **revisión de coherencia 1** (2026-10-09). Historia global en `mundo.md`; niveles y tiers en `progresion.md`.
**Los ids de este documento son estables**: se guardan en las partidas y no se renombran. Si un `continent-lead`
necesita cambiar algo de aquí, lo propone en la sección "Propuestas al world-designer" de su carpeta.

## Tabla principal

| # | Id | Nombre | Niveles | Bioma | Tema / emoción | Capital (hub) | Familias de monstruos | Familia de minerales | Tier de material | Jefe final | Relación con la historia principal |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `valdemar` | Reino de Valdemar | 1-10 | Praderas, robledales, granjas, colinas pedregosas | Hogar, primera aventura | **Valdehierro** (ya existe) | Goblins, bandidos, no-muertos de la abadía, bestias del campo, orcos del Pedregal | Cobre, hierro, plata, oro, esmeralda | 1 (cobre · roble · piel curtida · lino) | **Rey Goblin** (`goblinKing`, ya existe) | El Eclipse quiere la Hoja del Alba. Heraldo: Abad Morcar (`abbot`). Se gana la Hoja del Alba (I). |
| 2 | `rocaforja` | Montes de Rocaforja | 10-20 | Montañas, minas, cumbres nevadas, forjas subterráneas | Orgullo y deuda (patria del enano herrero) | **Hondoyunque** (ciudad enana excavada) | Kóbolds, trogloditas, gólems y elementales de piedra, bestias de montaña, Clan Hollín (enanos renegados) | Cobalto, estaño, topacio, piedra rúnica, diamante | 2 (hierro · cuero · cuero de jabalí · lana) | **Thane Durgan Hollín** (`thaneDurgan`) | El Clan Hollín forja con fuego negro el Molde del Ocaso. Heraldo: Hermana Brasa (no pelea). Hoja (II). |
| 3 | `lunaria` | Bosque de Lunaria | 20-30 | Bosque antiguo de árboles de plata, claros lunares, ríos, ruinas élficas | Misterio y reconciliación | **Velaluna** (elfos, en los árboles) + **Colmillo Gris** (clanes lobo) | Arañas tejedoras, árboles corruptos, duendes, Mala Luna, elfos marchitos, espíritus | Azogue, ámbar, jade, piedra lunar, amatista | 3 (plata · fresno · piel de lobo · seda) | **Ysolde, la Archimaga Marchita** (`ysolde`, Heraldo) | El Eclipse envenena la luz de la Luna y enfrenta a elfos y lobos; Ysolde templa el Molde. Pacto de la Luna. Hoja (III). |
| 4 | `cenizas` | Yermo de Cenizas | 30-40 | Desierto de ceniza y arena negra, volcanes, ruinas imperiales enterradas | Ruina y verdad | **Fortín del Oasis** (avanzada de la Alianza) | Momias y legionarios de Solarum, elementales de fuego, trolls de ceniza, escorpiones y salamandras | Azufre, granate, piedra solar, ópalo de fuego, rubí | 4 (obsidiana · hueso · cuero de troll · terciopelo) | **Severián, el Emperador Ceniciento** (`ashEmperor`) | Ozrán (`ashHerald`, Heraldo) despierta al primer Heraldo; los murales revelan la verdad; primera colada en el Molde. Hoja (IV). |
| 5 | `escarcha` | Tierras de Escarcha | 40-50 | Tundra, glaciares, auroras, cráteres de esquirlas de luna | Soledad y presagio | **Hielomar** (puerto de los hombres del norte) | Yetis, gigantes de escarcha, bestias de hielo, no-muertos helados, Caballeros de la Luna Rota | Cuarzo, hierro gélido, aguamarina, esquirla de luna, zafiro | 5 (glacita · ébano · cuero sombrío · seda lunar) | **Reina Astrid de la Luna Rota** (`brokenQueen`) | Caen trozos de la Luna; Corvino (Heraldo, no pelea aquí) roba el Ascua de Escarcha y sube al cielo. Hoja (V) con la Corona de Esquirlas. |
| 6 | `umbral` | Islas de Umbral | 50-60 | Islas flotantes, ruinas celestes, cielo nocturno, grietas del vacío | Desafío final | **Bastión del Alba** (última fortaleza de la Alianza) | Dragones y dragonantes, criaturas del vacío, constructos celestes, élite del Eclipse | Adamantita, metal estelar, piedra del vacío, dragonita, mithril | 6 (mithril · escama de dragón · piel de dragón · tela de estrellas) | **Morvath, el Herrero Hueco** (`morvath`, banda, nivel 60) | Vesper (`grandHerald`, Gran Heraldo) arranca el Ascua de Umbral; se recuperan las dos Ascuas; Hoja (VI); el Yunque. Final del juego. |

Paleta orientativa por continente (para `environment-artist` y `pixel-artist`): Valdemar verdes y ocres cálidos ·
Rocaforja grises, naranja de forja, blanco de nieve · Lunaria azul noche, plata, verde musgo · Cenizas negro, gris
ceniza, rojo lava, oro viejo · Escarcha blanco, cian, violeta de aurora · Umbral índigo, dorado, negro del vacío.

## Ids reservados (para trabajar en paralelo sin chocar)

Los 6 `continent-lead` trabajan a la vez. Para que no inventen el mismo id, **estos ids los fija el world-designer**.
Lo que no esté aquí (zonas, enemigos, jefes, NPC) lo crea cada lead siguiendo las reglas de abajo.

### Minerales (`Mineral`, se guardan en las partidas)

Cinco por continente: dos comunes (los que piden todas las recetas), uno poco común, uno raro y uno muy raro.
Los 10 actuales **no cambian de id ni de bonificación**: los cinco primeros son la familia de Valdemar y los cinco
más raros pasan a ser la joya "muy rara" de cada continente posterior. Detalle y porcentajes en `progresion.md`.

| Continente | Común A | Común B | Poco común | Rara | Muy rara |
|---|---|---|---|---|---|
| `valdemar` | `copper` Cobre (ATQ) | `iron` Hierro (DEF) | `silver` Plata (VEL. ATAQUE) | `gold` Oro (ORO) | `emerald` Esmeralda (REGEN.) |
| `rocaforja` | `cobalt` Cobalto (ATQ) | `tin` Estaño (DEF) | `topaz` Topacio (ORO) | `runestone` Piedra rúnica (VEL. ATAQUE) | `diamond` Diamante (MULT. CRÍTICO) |
| `lunaria` | `quicksilver` Azogue (ATQ) | `amber` Ámbar (VIDA) | `jade` Jade (REGEN.) | `moonstone` Piedra lunar (VEL. ATAQUE) | `amethyst` Amatista (ROBO DE VIDA) |
| `cenizas` | `sulfur` Azufre (ATQ) | `garnet` Granate (VIDA) | `sunstone` Piedra solar (ORO) | `fireopal` Ópalo de fuego (MULT. CRÍTICO) | `ruby` Rubí (CRÍTICO) |
| `escarcha` | `quartz` Cuarzo (ATQ) | `rimeiron` Hierro gélido (DEF) | `aquamarine` Aguamarina (REGEN.) | `moonshard` Esquirla de luna (ROBO DE VIDA) | `sapphire` Zafiro (ALCANCE) |
| `umbral` | `starmetal` Metal estelar (ATQ) | `adamantite` Adamantita (DEF + VIDA) | `voidstone` Piedra del vacío (ROBO DE VIDA) | `dragonite` Dragonita (CRÍTICO + MULT.) | `mithril` Mithril (VIDA + ATQ + DEF) |

El lead de cada continente decide **color, frase de descripción y en qué monstruos/zonas sale más**; el porcentaje
de aparición y la estadística principal están fijados (los números exactos los ajusta el `balance-designer`).

### Formas de arma nuevas (`WeaponShape`, `GuardShape`, `GripShape`)

Una hoja/cabeza, una guarda y una empuñadura nuevas por continente (Valdemar usa las que ya hay). El lead diseña
estadísticas y aspecto en su `piezas.md`; el id y el elemento están fijados.

| Continente | Hoja / cabeza | Guarda | Empuñadura |
|---|---|---|---|
| `valdemar` | — (las 9 actuales) | — (las 7 actuales) | — (las 5 actuales) |
| `rocaforja` | `warpick` Pico de guerra (Tierra) | `anvil` Guarda de yunque (Fuego) | `chain` Empuñadura de cadena (Sangre) |
| `lunaria` | `glaive` Guja (Viento) | `leaf` Guarda de hojas (Veneno) | `moon` Empuñadura lunar (Arcano) |
| `cenizas` | `khopesh` Jopesh (Fuego) | `sun` Guarda solar (Sagrado) | `scarab` Empuñadura de escarabajo (Veneno) |
| `escarcha` | `halberd` Alabarda (Hielo) | `frost` Guarda escarchada (Hielo) | `fur` Empuñadura forrada (Viento) |
| `umbral` | `staff` Báculo (Arcano) | `dragon` Guarda de dragón (Fuego) | `star` Empuñadura estelar (Sagrado) |

Hielo y Arcano no tenían forma de hoja propia: la Alabarda y el Báculo los completan. Ninguna forma nueva necesita
mecánicas nuevas (todas son golpes en arco); el Báculo puede pedir un proyectil mágico como mejora opcional.

### Materiales (tier por continente) y conjunto de armadura

Los 24 materiales que ya existen (6 metales, 6 maderas, 6 cueros, 6 telas) cubren exactamente los 6 tiers:
**un tier por continente** (tabla principal). No hace falta crear materiales nuevos.
Cada continente puede añadir **un conjunto de armadura temático** (casco, peto, guantes, botas) con ids fijos:
`helm.<id>`, `chest.<id>`, `gloves.<id>`, `boots.<id>` (p. ej. `helm.rocaforja`). Opcional; lo propone el lead.

### Pisos de mazmorra (`DungeonFloor`, para mazmorras y bandas de historia)

| Continente | Pisos | Notas |
|---|---|---|
| `valdemar` | `crypt` (ya existe), `prison` (ya existe) | Cripta de la abadía · calabozos del castillo |
| `rocaforja` | `mine` (ya existe), `forge` (ya existe) | Minas de cobalto · Forja Profunda |
| `lunaria` | `webs`, `hollow` | Nido de las tejedoras · Hueco del Árbol Madre |
| `cenizas` | `tomb`, `caldera` | Tumba de Solarum · Caldera del volcán |
| `escarcha` | `glacier`, `citadel` | Grieta del glaciar · Ciudadela de la Luna Rota |
| `umbral` | `skyforge`, `void` | Yunque del Alba (banda final) · Grieta del vacío |

Los pisos nuevos **no** entran en la rotación de la arena salvo que se decida (la arena sigue con sus 5).

### Áreas, zonas, spawns y NPC

- **Áreas nuevas** (mapas): `<continente>.<zona>` en minúsculas sin acentos, p. ej. `rocaforja.minas`,
  `valdemar.huertos`. Interiores dentro de un área: `<continente>.<zona>.<sitio>` (`valdemar.abadia.capilla`).
- Las áreas que ya existen **no se renombran**: `town` (Valdehierro), `bakery`, `weaver`, `mill`, `chapel`, `inn`,
  `alchemist`, `castle`, `smithy`; zonas del pueblo `south`, `market`, `west`, `east`, `plaza`, `courtyard`.
- **Spawns**: `<id del área>.<n>` (como ahora: `south.3`, `bakery.2`).
- **NPC**: camelCase o minúsculas, únicos; si el nombre es corriente, añade el sitio (`guardaHondoyunque`).
- **Misiones**: `<continente>.<nombre>` (`valdemar.caza_mayor`).

### Enemigos y jefes (`Bestiary`)

- Ids en camelCase en inglés, como los actuales (`goblinShaman`). Únicos en todo el juego.
- **No uses** ninguno de los 50 que ya existen (lista en `assets/characters/enemigos.md`) salvo para reutilizarlo
  tal cual. Si tu bicho es una variante de uno corriente (lobo, esqueleto, limo, araña), ponle el calificativo
  de tu bioma: `frostWolf`, `ashSkeleton`, `moonSpider`, `stoneKobold`.
- La pieza única de un jefe se llama `boss.<idDelJefe>` (lo hace el código solo).
- Cada familia la "posee" un continente (tabla principal). Si quieres un bicho de la familia de otro (p. ej. un
  troll en Escarcha), anótalo en "Propuestas al world-designer".


## Revisión de coherencia 1 (2026-10-09): registros comunes

Comprobado con grep contra los seis continentes y contra el código (`Enemy.swift`, `Mineral.swift`, `Parts.swift`,
`Ability.swift`, `World.swift`, `Valdemar.swift`, `Town.swift`): **ningún id de enemigo, mineral, forma, piso,
misión ni mazmorra se repite** entre continentes ni con el código. Los choques y parecidos que había se han corregido
en los documentos de los leads (lista abajo). Ninguno estaba aún en el código.

### Reglas nuevas

- **Ids de salida únicos en todo el juego** (`WorldTests.exitIDsAreUnique` lo exige): el `<área corta>` de una salida
  no puede repetirse entre continentes. Áreas cortas ya usadas: Valdemar `town`, `huertos`, `robleda`, `abadia`,
  `pedregal`, `paso` · Rocaforja `hondoyunque`, `pastos`, `canteras`, `cumbres`, `escoriales`, `fortaleza` · Lunaria
  `velaluna`, `colmillo`, `raices`, `claros`, `espesura`, `marchito`, `lago` · Cenizas `fortin`, `costa`, `dunas`,
  `necropolis`, `laderas`, `sepultada` · Escarcha `hielomar`, `balleneros`, `tundra`, `crater`, `gigantes`, `murallas` ·
  Umbral `bastion`, `muelles`, `nidos`, `rotas`, `observatorio`, `puente`.
- **NPC que también son enemigo**: se permite el mismo id (`ysolde`) o dos ids (`corvino` NPC / `starHerald` enemigo);
  `talk`/`read` usan ids de NPC y `defeat`/`kill`, de enemigo. Un NPC que viaja usa **el mismo id** en todas partes.
- **La princesa es `princess`** (id del código) en todos los continentes, nunca `aurora`.
- **Biomas** (`Biome`): el bioma base de un continente se llama como el continente (`valdemar`, `lunaria`); las
  variantes, `<continente><Variante>` en inglés. Lista cerrada:
  `valdemar` · `rocaforjaHall` (Hondoyunque), `rocaforjaMeadow`, `rocaforjaQuarry`, `rocaforjaSnow`, `rocaforjaSlag` ·
  `lunaria`, `lunariaCanopy` (Velaluna), `lunariaWithered` (Bosque Marchito) · `cenizasOasis`, `cenizasAsh`,
  `cenizasVolcano` · `escarchaPort`, `escarchaSnow`, `escarchaShard`, `escarchaSilver` · `umbralBastion`, `umbralSky`,
  `umbralVoid`, `umbralStar`.
- **Nombres**: dos personajes del juego no pueden compartir las primeras letras y la terminación (Hilda/Hulda,
  Bruno/Bruna); ni dos jefes o mazmorras el mismo sustantivo principal (dos "Colosos", dos "Grietas").

### Habilidades nuevas reservadas (`AbilityBook`, al final; ninguna choca con las 39 actuales)

| Continente | Piezas de jefe | Combos (P3, los aprueba el balance-designer) |
|---|---|---|
| `rocaforja` | `runaway_cart`, `skyfall`, `resonance`, `black_fire` ("Fuego negro"; antes `black_forge` "Forja negra", demasiado cerca de `hellforge` "Forja infernal") | — |
| `lunaria` | `elder_bark`, `bad_moon`, `silk_snare`, `withered_moon` (asignadas en la revisión: el lead no había puesto ids) | — |
| `cenizas` | `troll_blood`, `black_sting`, `solar_flare`, `ashen_crown` | `sunfire` [Fuego+Sagrado], `pitch` [Fuego+Veneno], `embalm` [Sagrado+Veneno] |
| `escarcha` | `blizzard`, `shatter`, `avalanche`, `broken_oath`, `moonfall` | `north_wind` "Viento del norte" [Hielo+Viento] (antes `snowstorm` "Tormenta de nieve", casi igual que `frozen_storm` "Tormenta helada") |
| `umbral` | `dragon_breath`, `void_siphon`, `astral_lens`, `eclipse_veil`, `hollow_hammer` ("Martillo hueco"; antes `hollow_forge` "Forja hueca") | `constellation` [Arcano+Sagrado] |

### Maestros de viajes (uno por pueblo seguro; misma mecánica, `motor_comun.md` B7)

| Pueblo | NPC (id) | Estética |
|---|---|---|
| Valdehierro | Nicasio el arriero (`arrieroValdehierro`), Puerta sur, tras `valdemar.paso_norte` | carro de mulas |
| Hondoyunque | Frida la Arriera (`fridaArriera`) | cabras de carga |
| Velaluna | Nimra (`nimra`) | búhos gigantes |
| Colmillo Gris | el lobo mensajero (`mensajeroColmillo`) | lobos de carga |
| Fortín del Oasis | Capitana Marga Velasalada (`margaCapitana`) | barco *La Gaviota Tuerta* |
| Hielomar | Ulf Tresdedos (`ulfTresdedos`) | ballenero (y la pista del dirigible) |
| Bastión del Alba | Capitán Borin Nubehierro (`borin`) | dirigible *Testaruda* |

### Renombres de esta revisión (en los documentos de los leads; nada estaba en el código)

| Antes | Ahora | Por qué |
|---|---|---|
| NPC `aurora` (Lunaria, Cenizas, Escarcha, Umbral) | `princess` | Es el id del código. |
| Área `escarcha.costa`, salidas `costa.este`/`costa.norte` | `escarcha.balleneros`, `balleneros.este`/`balleneros.norte` (mapa `escarcha/mapas/balleneros.md`) | `costa.este` ya lo usa Cenizas: el test de salidas únicas fallaría. |
| Enemigo `cinderAcolyte` (Rocaforja) | `emberAcolyte` (mismo nombre: "Acólito de la brasa") | *cinder* y *ash* se confunden con `ashAcolyte` de Cenizas. |
| Enemigo `shardColossus` "Coloso de la Esquirla" (Escarcha) | `shardHorror` "Engendro de la Esquirla" | Ya está el Coloso de cobalto (Rocaforja). |
| Mazmorra y misión `escarcha.grieta` "Grieta del glaciar" | `escarcha.sima` "Sima del Glaciar" (piso `glacier` igual) | La Grieta del vacío es de Umbral. |
| Enemigo `eclipseHerald` "Heraldo menor" (Umbral) | `eclipseProphet` "Profeta del Eclipse" | "Heraldo" es el título de los seis villanos. |
| Enemigo `voidZealot` "Fanático del vacío", misión `umbral.fanaticos` | `voidZealot` "Enmascarado del vacío", `umbral.enmascarados` | Ya está el "Fanático del Eclipse" de Cenizas (`cenizas.fanaticos`). |
| Biomas `hondoyunque`, `copas`, `marchito` | `rocaforjaHall`, `lunariaCanopy`, `lunariaWithered` | Regla de nombres de biomas. |
| Hulda la Arriera (`huldaArriera`) | Frida (`fridaArriera`) | Con la Thane Hilda, en la misma ciudad. |
| Bruna la curtidora (`bruna`) | Hirsa (`hirsa`) | Con Bruno (`bruno`) de Valdehierro. |
| Comandante Brena (`brenaComandante`) | Dorna (`dornaComandante`) | Con la Hermana Brasa, en el mismo continente. |
| Gudrun (`gudrunTabernera`) | Solveig (`solveigTabernera`) | Con la Jarla Sigrun, en la misma ciudad. |
| Comendador Ulric | Comendador Eirik (`wallCommander` igual) | Con Ulf, en el mismo continente. |
| Maela (`maelaPosadera`) | Nora (`noraPosadera`) | Con Marga. |
| Aurelián, el Emperador Ceniciento | Severián (`ashEmperor` igual) | Con Aurora. |
| Templo de la Aurora (Hielomar) | Templo de las Luces | Con la princesa Aurora (que está en Hielomar). Los ids `totemAurora1-3` y `escarcha.tres_auroras` se quedan: hablan de la aurora boreal. |

Parecidos que se dejan (aceptables): `skyfall`/`moonfall`; Gárgola / Gárgola estelar; los acólitos locales
(Acólito del Eclipse, de la brasa, de la ceniza: es una familia a propósito); Matriarca Ulma / Nixara, Matriarca del
Vuelo (30 niveles de distancia); Borin / Brokk; el piso `void` y la habilidad `void` (tipos distintos); misiones que
se llaman como su área (`escarcha.crater`, como ya hace `valdemar.abadia`).

## Leyenda común para mapas exteriores (propuesta)

El formato de `assets/maps/README.md` sirve para todos. Para no inventar un carácter por continente:

1. **Bioma por área**: el mismo carácter se dibuja distinto según el bioma del área (`.` = hierba en Valdemar, roca
   en Rocaforja, musgo en Lunaria, ceniza en Cenizas, nieve en Escarcha, cristal/nube en Umbral; `T` = roble, pino
   nevado, árbol de plata, árbol muerto, cristal…; `~` = agua, lava, agua helada, vacío). Lo implementa el
   `environment-artist` con el `game-programmer`.
2. **Caracteres nuevos de exterior** (los usan todos los continentes; los valida el `map-designer`):

| Carácter | Casilla | ¿Se pisa? |
|---|---|---|
| `d` | Camino de tierra / sendero | Sí |
| `%` | Hierba alta, trigal, maleza (decorativo) | Sí |
| `p` | Puente (sobre `~`) | Sí |
| `R` | Roca, peñasco | No |
| `^` | Acantilado, pared de montaña | No |
| `+` | Lápida, estela, tótem | No |
| `n` | Tienda de campaña | No |
| `x` | Hoguera / brasero (luz) | No |
| `e` | Entrada de cueva o mazmorra (lleva a un interior o a una mazmorra de historia) | Sí |
| `>` | Salida a otra área (en el borde del mapa; a dónde lleva se dice en el código/borrador) | Sí |

Exteriores orientativos: **48-64 × 32-40 casillas** (la cámara sigue al héroe), 3-4 zonas de nivel por área,
caminos de 3+ casillas, claros para pelear y siempre más de una ruta.
