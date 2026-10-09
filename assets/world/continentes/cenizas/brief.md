# Brief · Continente 4 · `cenizas` — Yermo de Cenizas (niveles 30-40)

> **Encargo original (2026-10-07).** Tras el diseño de los leads, lo vigente está en `assets/world/mundo.md` (§5, §13 y §14),
> `continentes.md` (registros comunes y renombres), `progresion.md` (XP de misiones y Hoja del Alba) y `motor_comun.md`.

Para: `continent-lead` de `cenizas`. De: `world-designer`. Lee antes `CLAUDE.md`, `assets/world/mundo.md`,
`assets/world/continentes.md`, `assets/world/progresion.md` y el brief de Valdemar
(`assets/world/continentes/valdemar/brief.md`, sección 7: el motor que habrá).

> Se **diseña ahora** y se implementa **después de Valdemar**. Encargos listos para más adelante, en ficheros de tu
> continente (p. ej. `Cenizas.swift`); en las listas compartidas (`Enemy`, `Mineral`, `Parts`) solo se añade al final.

## 1. Qué es Cenizas

Un desierto de **ceniza y arena negra** al sur, por mar. Volcanes que humean, oasis de vapor, costas de escoria y,
enterrado, el **Imperio de Solarum**. Negro, gris ceniza, rojo lava y oro viejo. Emoción: *ruina y verdad*.
Sin raza jugable propia: la capital es una **avanzada de la Alianza**, el **Fortín del Oasis** (soldados de Valdemar,
enanos, elfos y algún goblin mercader neutral). Tier de material **4** (obsidiana · hueso · cuero de troll · terciopelo).

## 2. Historia del capítulo (propuesta; desarróllala)

- Hace mil años, el Imperio de Solarum quiso robar el **Ascua de Cenizas** para su emperador y la tierra ardió.
- El Eclipse ha despertado al **Emperador Ceniciento** (*propuesta* de jefe final) y a sus legiones de momias para que
  termine lo que empezó. Un Heraldo (tuyo) dirige las excavaciones.
- **Es el capítulo de la verdad**: en la Tumba de Solarum, los murales cuentan la Guerra del Ocaso, quién es Morvath y
  por qué la Luna se apaga. Aurora (o un erudito) lo interpreta; la historia principal cambia de marcha.
- Final en la Caldera del volcán Brasamadre; la Hoja del Alba despierta (IV).

## 3. Zonas (plantilla de `progresion.md`; nombres e ids propuestos)

| Hueco | Niveles | Propuesta | Id propuesto |
|---|---|---|---|
| Capital | — | Fortín del Oasis | `cenizas.fortin` |
| Zona 1 | 30-32 | Costa de Escoria (llegada en barco): escorpiones, cangrejos, salamandras | `cenizas.costa` |
| Zona 2 | 32-34 | Dunas Negras: trolls de ceniza, buitres | `cenizas.dunas` |
| Zona 3 | 34-36 | Necrópolis de Solarum: momias, legionarios | `cenizas.necropolis` |
| Mazmorra | 35-37 | Tumba de Solarum (piso nuevo `tomb`) | — |
| Zona 4 | 36-38 | Laderas de Brasamadre: elementales de fuego, cultistas | `cenizas.laderas` |
| Zona 5 | 38-39 | Ciudad Sepultada de Solarum | `cenizas.sepultada` |
| Final | 39-40 | Caldera de Brasamadre (piso nuevo `caldera`): el Emperador Ceniciento | — |

Llegada: barco desde el Puerto de Valdemar (maestro de viajes) a la zona 1. Salida: barco del norte hacia Escarcha.

## 4. Monstruos (familias tuyas: Solarum no-muerto, elementales de fuego, trolls de ceniza, escorpiones y salamandras)

10-15 normales + 2-4 jefes. Ideas (ids propuestos):
`ashScorpion` Escorpión de ceniza · `cinderCrab` Cangrejo de escoria · `salamander` Salamandra (a distancia, fuego) ·
`ashTroll` Troll de ceniza (élite) · `trollHexer` Brujo troll (a distancia) · `ashVulture` Buitre de ceniza ·
`mummy` Momia · `solarLegionary` Legionario de Solarum · `sunPriest` Sacerdote del Sol (a distancia) ·
`scarabSwarm` Enjambre de escarabajos (rápido) · `fireElemental` Elemental de fuego · `magmaGolem` Gólem de magma (élite) ·
`eclipseZealot` Fanático del Eclipse (embestida).
Jefes: un rey troll, el **Gran Sacerdote** de la tumba, un escorpión colosal y el **Emperador Ceniciento**.
Plantillas reutilizables: `skeleton` (momias, legionarios), `brute` (trolls, gólem), `slime` (elemental), `bird`
(buitre), `rat`/`bat` (escarabajos). Escorpión y cangrejo necesitarán plantilla nueva.

## 5. Minerales, piezas y armadura (fijados en `continentes.md`)

- Minerales: `sulfur` Azufre (ATQ, 35 %), `garnet` Granate (VIDA, 27 %), `sunstone` Piedra solar (ORO, 20 %),
  `fireopal` Ópalo de fuego (MULT. CRÍTICO, 12 %), `ruby` Rubí (CRÍTICO, 6 %, ya existe).
- Formas nuevas: `khopesh` Jopesh (Fuego), `sun` Guarda solar (Sagrado), `scarab` Empuñadura de escarabajo (Veneno).
- Conjunto de armadura opcional: `helm.cenizas`, `chest.cenizas`, `gloves.cenizas`, `boots.cenizas`.
- Forja del Fortín: tier 4.

## 6. Motor

Con M1-M10 de Valdemar. Particularidades posibles: bioma de ceniza y lava (`~` = lava), ruinas medio enterradas,
murales que se "leen" (un NPC o una casilla que abre un diálogo: proponlo). Pisos nuevos `tomb` y `caldera`.
Lo que haga falta de más, en "Necesidades de motor".

## 7. Lo que entregas (en `assets/world/continentes/cenizas/`)

Lo de tu fichero de agente (`historia.md`, `zonas.md`, `mapas/`, `bestiario.md`, `minerales.md`, `piezas.md`,
`encargos.md` como **fase futura**). Respeta niveles (30-40) e ids fijados; cambios del mundo en "Propuestas al
world-designer" (sobre todo si la revelación de Morvath pide algo de los capítulos 1-3). No toques `src/` ni otras carpetas.
