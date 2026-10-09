# Brief · Continente 2 · `rocaforja` — Montes de Rocaforja (niveles 10-20)

> **Encargo original (2026-10-07).** Tras el diseño de los leads, lo vigente está en `assets/world/mundo.md` (§5, §13 y §14),
> `continentes.md` (registros comunes y renombres), `progresion.md` (XP de misiones y Hoja del Alba) y `motor_comun.md`.

Para: `continent-lead` de `rocaforja`. De: `world-designer`. Lee antes `CLAUDE.md`, `assets/world/mundo.md`,
`assets/world/continentes.md`, `assets/world/progresion.md` y el brief de Valdemar
(`assets/world/continentes/valdemar/brief.md`, sección 7: es el motor que habrá cuando se construya tu continente).

> Se **diseña ahora** y se implementa **después de Valdemar**. Tus encargos deben quedar listos para lanzarse más
> adelante, en paralelo con los de otros continentes: cada especialista trabajará en ficheros de tu continente
> (p. ej. `Rocaforja.swift`) y solo **añadirá al final** de las listas compartidas (`Enemy`, `Mineral`, `Parts`).

## 1. Qué es Rocaforja

Montañas grises, minas, canteras, cumbres nevadas y forjas bajo tierra. Grises, naranja de forja y blanco de nieve.
Patria de los **enanos** (y del enano herrero de Valdehierro). Emoción: *orgullo y deuda*.
Capital: **Hondoyunque**, ciudad enana excavada en la montaña (Gran Forja, Salón de los Thanes, posada, maestro de
viajes). Tier de material **2** (hierro · cuero · cuero de jabalí · lana).

## 2. Historia del capítulo (propuesta; desarróllala)

- Hace 20 años, el **Clan Hollín** fue expulsado de Hondoyunque por forjar con fuego prohibido. El enano herrero de
  Valdehierro era uno de ellos y los abandonó (*propuesta*: es hermano del Thane).
- Ahora el Clan Hollín, con fuego del **Eclipse**, ha reabierto la **Forja Profunda** y excava hacia el **Ascua de
  Rocaforja**. Arma a kóbolds y trogloditas y funde gólems. Las armas orcas de Valdemar salieron de sus yunques.
- El héroe llega por el Paso del Norte con el herrero; el Thane de Hondoyunque desconfía hasta que el héroe demuestra
  su valía. Final: **Thane Durgan Hollín** (*propuesta*) en la Forja Profunda; el Ascua se salva y despierta la
  **Hoja del Alba (II)**. Un Heraldo del Eclipse (tuyo: nombre y papel) escapa hacia el este por el Túnel de los Thanes.
- Si el jugador es **enano**, es su capítulo: dale líneas propias (vuelve a casa, el Thane lo reconoce…).

## 3. Zonas (plantilla de `progresion.md`; nombres e ids propuestos, tú decides)

| Hueco | Niveles | Propuesta | Id propuesto |
|---|---|---|---|
| Capital | — | Hondoyunque | `rocaforja.hondoyunque` |
| Zona 1 | 10-12 | Pastos Altos (llegada desde el Paso del Norte): cabras, osos, kóbolds saqueadores | `rocaforja.pastos` |
| Zona 2 | 12-14 | Canteras de Cobalto: kóbolds, trogloditas; jefe kóbold | `rocaforja.canteras` |
| Zona 3 | 14-16 | Cumbres del Águila: nieve, águilas, gólems de piedra | `rocaforja.cumbres` |
| Mazmorra | 15-17 | Minas profundas (piso `mine`) | — |
| Zona 4 | 16-18 | Escoriales del Hollín: campos de escoria, enanos renegados | `rocaforja.escoriales` |
| Zona 5 | 18-19 | Fortaleza Hollín | `rocaforja.fortaleza` |
| Final | 19-20 | Forja Profunda (piso `forge`): Thane Durgan Hollín | — |

Salidas: entrada desde `valdemar.paso` a la zona 1; salida al **Túnel de los Thanes** (hacia Lunaria) desde la
capital o la zona 5, cerrada hasta el final.

## 4. Monstruos (familias tuyas: kóbolds, trogloditas, gólems/elementales de piedra, bestias de montaña, Clan Hollín)

10-15 normales + 2-4 jefes. Ideas (ids propuestos, camelCase, únicos):
`kobold` Kóbold minero · `koboldCandle` Kóbold de la vela (¡no toques su vela!) · `koboldGeomancer` Geomante kóbold
(a distancia) · `trogg` Troglodita · `troggBrute` Troglodita bruto (élite) · `mountainGoat` Cabra montesa (embestida) ·
`cliffBear` Oso de las cumbres · `cliffEagle` Águila de las cumbres · `rockGolem` Gólem de piedra ·
`earthElemental` Elemental de tierra · `hollinWarrior` Guerrero Hollín · `hollinRifleman` Arcabucero Hollín (a distancia) ·
`hollinPyromancer` Piromante Hollín (a distancia) · `ironConstruct` Autómata de hierro fundido (élite).
Jefes: el cabecilla kóbold (zona 2), un gólem o águila gigante de las cumbres (zona 3), el jefe de la mazmorra y
**Durgan** (final). Cada jefe, su pieza `boss.<id>`.
Plantillas de dibujo que se pueden reutilizar: `goblin` (kóbold), `brute` (troglodita, gólem), `bird` (águila),
`boar`/`dog` (cabra, oso), `human` (enanos, a escala baja). Indica cuáles necesitan plantilla nueva.

## 5. Minerales, piezas y armadura (fijados en `continentes.md`)

- Minerales: `cobalt` Cobalto (ATQ, 35 %), `tin` Estaño (DEF, 27 %), `topaz` Topacio (ORO, 20 %), `runestone` Piedra
  rúnica (VEL. ATAQUE, 12 %), `diamond` Diamante (MULT. CRÍTICO, 6 %, ya existe). Tú: color, descripción, dónde salen más.
- Formas nuevas: `warpick` Pico de guerra (Tierra), `anvil` Guarda de yunque (Fuego), `chain` Empuñadura de cadena (Sangre).
- Conjunto de armadura opcional: `helm.rocaforja`, `chest.rocaforja`, `gloves.rocaforja`, `boots.rocaforja`.
- La forja de Hondoyunque vende tier 2 (tier 3 al vencer a Durgan).

## 6. Motor

Todo debería construirse con M1-M10 del brief de Valdemar. Particularidades: la capital es una **ciudad bajo tierra**
(mapa grande de interior con bioma de roca); vagonetas y raíles como decoración. Si necesitas algo más (p. ej.
trampas de vapor, ascensores entre pisos), escríbelo en "Necesidades de motor" en tu `encargos.md`, no lo des por hecho.

## 7. Lo que entregas (en `assets/world/continentes/rocaforja/`)

Lo de tu fichero de agente: `historia.md`, `zonas.md`, `mapas/<zona>.md`, `bestiario.md`, `minerales.md`, `piezas.md`,
`encargos.md` (marcados como **fase futura**, con el mismo reparto que Valdemar: programador + mapas + historia +
personajes en paralelo → arte → balance → QA). Respeta niveles (10-20) e ids fijados. Lo que quieras cambiar del mundo,
en "Propuestas al world-designer". No toques `src/` ni carpetas de otros continentes.
