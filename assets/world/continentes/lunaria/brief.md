# Brief · Continente 3 · `lunaria` — Bosque de Lunaria (niveles 20-30)

> **Encargo original (2026-10-07).** Tras el diseño de los leads, lo vigente está en `assets/world/mundo.md` (§5, §13 y §14),
> `continentes.md` (registros comunes y renombres), `progresion.md` (XP de misiones y Hoja del Alba) y `motor_comun.md`.

Para: `continent-lead` de `lunaria`. De: `world-designer`. Lee antes `CLAUDE.md`, `assets/world/mundo.md`,
`assets/world/continentes.md`, `assets/world/progresion.md` y el brief de Valdemar
(`assets/world/continentes/valdemar/brief.md`, sección 7: el motor que habrá).

> Se **diseña ahora** y se implementa **después de Valdemar**. Encargos listos para más adelante, en ficheros de tu
> continente (p. ej. `Lunaria.swift`); en las listas compartidas (`Enemy`, `Mineral`, `Parts`) solo se añade al final.

## 1. Qué es Lunaria

Un bosque antiguo de **árboles de plata**, claros donde se bebe la luz de la luna, ríos, setas que brillan y ruinas
élficas. Azul noche, plata y verde musgo. Emoción: *misterio y reconciliación*. Patria de los **elfos** y de los
**hombres lobo**: dos razas jugables, dos hubs.
Capitales: **Velaluna** (ciudad élfica en las copas) y **Colmillo Gris** (aldea de los clanes lobo, en el bosque
profundo). Tier de material **3** (plata · fresno · piel de lobo · seda).

## 2. Historia del capítulo (propuesta; desarróllala)

- Con la Luna apagándose, la luz de los claros enferma: los árboles se marchitan y algunos lobos enloquecen
  (la **Mala Luna**). Los elfos culpan a los clanes; los clanes, a la magia élfica. Están al borde de la guerra.
- La culpable es una **archimaga élfica**, Heraldo del Eclipse (*propuesta*: **Ysolde, la Archimaga Marchita**), que
  envenena los claros para abrir el camino al **Ascua de Lunaria**, en el corazón del **Árbol Madre**.
- El héroe trabaja para ambos bandos, destapa a Ysolde y sella el **Pacto de la Luna**: elfos y lobos entran en la
  Alianza del Alba. Final en el Hueco del Árbol Madre; la Hoja del Alba despierta (III).
- **Elfo** u **hombre lobo**: es su capítulo. Dales líneas propias y que el otro hub los reciba con desconfianza
  al principio (solo diálogo; nada de bloquear contenido por raza).

## 3. Zonas (plantilla de `progresion.md`; nombres e ids propuestos)

| Hueco | Niveles | Propuesta | Id propuesto |
|---|---|---|---|
| Capitales | — | Velaluna (elfos) y Colmillo Gris (lobos) | `lunaria.velaluna`, `lunaria.colmillo` |
| Zona 1 | 20-22 | Raíces de Plata (llegada por el Túnel de los Thanes): duendes, setas, ciervos | `lunaria.raices` |
| Zona 2 | 22-24 | Claros de la Luna (territorio élfico): arañas, espíritus | `lunaria.claros` |
| Zona 3 | 24-26 | Espesura del Aullido (territorio lobo): Mala Luna | `lunaria.espesura` |
| Mazmorra | 25-27 | Nido de las Tejedoras (piso nuevo `webs`) | — |
| Zona 4 | 26-28 | Bosque Marchito: árboles corruptos, elfos marchitos | `lunaria.marchito` |
| Zona 5 | 28-29 | Lago de la Luna Caída y ruinas élficas | `lunaria.lago` |
| Final | 29-30 | Hueco del Árbol Madre (piso nuevo `hollow`): Ysolde | — |

Salidas: llegada desde el Túnel de los Thanes (zona 1); al terminar, Aurora fleta un barco en el Puerto de Valdemar
hacia Cenizas (el viaje lo hace el maestro de viajes; no necesitas puerto propio).

## 4. Monstruos (familias tuyas: arañas, árboles corruptos, duendes, Mala Luna, elfos marchitos, espíritus)

10-15 normales + 2-4 jefes. Ideas (ids propuestos):
`moonSpider` Tejedora lunar · `spiderling` Arañita (en grupo, rápida) · `webSpitter` Escupetelas (a distancia) ·
`treant` Árbol corrupto (lento, élite) · `thornling` Espinoso · `pixie` Duende travieso (rápido) · `wisp` Fuego fatuo
(a distancia) · `feralWerewolf` Lobo de la Mala Luna (embestida) · `moonHowler` Aullador (a distancia) ·
`witheredArcher` Arquero marchito (a distancia) · `witheredBlade` Danzante marchito · `forestSpirit` Espíritu del bosque ·
`owlbear` Osolechuza (élite) · `corruptStag` Ciervo corrupto (embestida).
Jefes: **Madre Tejedora** (mazmorra), **Garra Negra** (líder de la Mala Luna), un árbol ancestral podrido y **Ysolde**.
Plantillas reutilizables: `dog` (lobos), `ghost` (espíritus, fuegos fatuos), `human` (elfos), `slime`/`bat` (duendes),
`brute` (osolechuza). Las arañas y los árboles necesitarán plantilla nueva.

## 5. Minerales, piezas y armadura (fijados en `continentes.md`)

- Minerales: `quicksilver` Azogue (ATQ, 35 %), `amber` Ámbar (VIDA, 27 %), `jade` Jade (REGEN., 20 %), `moonstone` Piedra
  lunar (VEL. ATAQUE, 12 %), `amethyst` Amatista (ROBO DE VIDA, 6 %, ya existe).
- Formas nuevas: `glaive` Guja (Viento), `leaf` Guarda de hojas (Veneno), `moon` Empuñadura lunar (Arcano).
- Conjunto de armadura opcional: `helm.lunaria`, `chest.lunaria`, `gloves.lunaria`, `boots.lunaria`.
- Forja (en Velaluna; *propuesta*: el herrero élfico y el curtidor lobo, uno vende armas y otro cueros): tier 3.

## 6. Motor

Con M1-M10 de Valdemar. Particularidades posibles: **dos capitales** (dos posadas/forjas), ambiente nocturno con
luces de luna (`environment-artist`), puentes colgantes entre árboles (casillas `p`). Pisos nuevos `webs` y `hollow`
(`map-designer` + `environment-artist`). Lo que haga falta de más, en "Necesidades de motor".

## 7. Lo que entregas (en `assets/world/continentes/lunaria/`)

Lo de tu fichero de agente (`historia.md`, `zonas.md`, `mapas/`, `bestiario.md`, `minerales.md`, `piezas.md`,
`encargos.md` como **fase futura**). Respeta niveles (20-30) e ids fijados; cambios del mundo en "Propuestas al
world-designer". No toques `src/` ni otras carpetas.
