# Brief · Continente 6 · `umbral` — Islas de Umbral (niveles 50-60)

> **Encargo original (2026-10-07).** Tras el diseño de los leads, lo vigente está en `assets/world/mundo.md` (§5, §13 y §14),
> `continentes.md` (registros comunes y renombres), `progresion.md` (XP de misiones y Hoja del Alba) y `motor_comun.md`.

Para: `continent-lead` de `umbral`. De: `world-designer`. Lee antes `CLAUDE.md`, `assets/world/mundo.md`,
`assets/world/continentes.md`, `assets/world/progresion.md` y el brief de Valdemar
(`assets/world/continentes/valdemar/brief.md`, sección 7: el motor que habrá).

> Se **diseña ahora** y se implementa **el último**. Encargos listos para más adelante, en ficheros de tu continente
> (p. ej. `Umbral.swift`); en las listas compartidas (`Enemy`, `Mineral`, `Parts`) solo se añade al final.

## 1. Qué es Umbral

Islas de piedra que **flotan sobre el Mar Quieto**, unidas por puentes de luz y cadenas, bajo la Luna de Plata
agrietada. Ruinas celestes de los Seis Herreros, nidos de dragones y grietas del vacío. Índigo, dorado y negro.
Emoción: *desafío final*. Capital: **Bastión del Alba**, la última fortaleza de la Alianza (todas las razas, Aurora al
mando, el enano herrero ante el último yunque). Tier de material **6** (mithril · escama de dragón · piel de dragón ·
tela de estrellas).

## 2. Historia del capítulo (propuesta; desarróllala)

- Con el sello roto, **Morvath, el Herrero Hueco**, está medio libre: su forma baja de la Luna al **Yunque del Alba**.
- Los dragones guardianes (el **Vuelo del Alba**) están casi todos corrompidos; uno (tuyo: nombre) ayuda al héroe.
- Los Heraldos supervivientes y la élite del Eclipse defienden el camino al Yunque.
- **Banda final, nivel 60**: Morvath en el Yunque del Alba. El héroe forja la **Hoja del Alba (VI)** con las seis
  Ascuas y lo vence (final según la decisión 5 de `mundo.md`, *a confirmar*).
- Después del final: Umbral sigue siendo zona de nivel 60 para repetir la banda y forjar (como el "endgame" de un MMO).

## 3. Zonas (plantilla de `progresion.md`; nombres e ids propuestos)

| Hueco | Niveles | Propuesta | Id propuesto |
|---|---|---|---|
| Capital | — | Bastión del Alba | `umbral.bastion` |
| Zona 1 | 50-52 | Muelles del Cielo (llegada en dirigible): constructos celestes, gárgolas estelares | `umbral.muelles` |
| Zona 2 | 52-54 | Nidos del Vuelo del Alba: dragonantes, crías | `umbral.nidos` |
| Zona 3 | 54-56 | Islas Rotas: criaturas del vacío | `umbral.rotas` |
| Mazmorra | 55-57 | Grieta del vacío (piso nuevo `void`) | — |
| Zona 4 | 56-58 | Observatorio de los Herreros: élite del Eclipse | `umbral.observatorio` |
| Zona 5 | 58-59 | Puente del Yunque | `umbral.puente` |
| Banda final | 60 | Yunque del Alba (piso nuevo `skyforge`): Morvath | — |

Llegada: dirigible enano desde Escarcha (maestro de viajes) a la zona 1.

## 4. Monstruos (familias tuyas: dragones y dragonantes, criaturas del vacío, constructos celestes, élite del Eclipse)

10-15 normales + 3-4 jefes. Ideas (ids propuestos):
`skyConstruct` Constructo celeste · `starGargoyle` Gárgola estelar · `dragonWhelp` Cría de dragón (rápida) ·
`drake` Dragonante (embestida) · `stormDrake` Dragonante de tormenta (a distancia) · `fallenDragon` Dragón caído (élite) ·
`voidWalker` Caminante del vacío · `voidLurker` Acechador del vacío (rápido) · `voidEye` Ojo del vacío (a distancia) ·
`eclipseKnight` Caballero del Eclipse · `eclipseProphet` Profeta del Eclipse (a distancia, élite) · `hollowSmith` Herrero hueco
(los siervos de Morvath).
Jefes: una dragona corrompida del Vuelo del Alba, el último Heraldo, el guardián de la grieta y **Morvath** (banda).
Plantillas reutilizables: `bat`/`bird` (crías, gárgolas), `ghost` (vacío), `human` (Eclipse), `brute` (constructos).
Los dragones y Morvath necesitan plantilla nueva (y probablemente sprites grandes: díselo al `pixel-artist`).

## 5. Minerales, piezas y armadura (fijados en `continentes.md`)

- Minerales: `starmetal` Metal estelar (ATQ, 35 %), `adamantite` Adamantita (DEF + VIDA, 27 %), `voidstone` Piedra del vacío
  (ROBO DE VIDA, 20 %), `dragonite` Dragonita (CRÍTICO + MULT., 12 %), `mithril` Mithril (VIDA + ATQ + DEF, 6 %, ya existe).
- Formas nuevas: `staff` Báculo (Arcano), `dragon` Guarda de dragón (Fuego), `star` Empuñadura estelar (Sagrado).
- Conjunto de armadura opcional: `helm.umbral`, `chest.umbral`, `gloves.umbral`, `boots.umbral`.
- Forja del Bastión: tier 6 (el máximo). La **Hoja del Alba (VI)** es el arma definitiva.

## 6. Motor

Con M1-M10 de Valdemar, más lo que pida una banda final. Probablemente necesites (escríbelo en "Necesidades de motor"):
**jefe con fases** (cambia de ataque a mitad de vida), **banda larga** (más oleadas, puntos de control), el **proyectil
mágico** opcional del Báculo y bordes de isla al vacío (`~` = vacío). Pisos nuevos `void` y `skyforge`.

## 7. Lo que entregas (en `assets/world/continentes/umbral/`)

Lo de tu fichero de agente (`historia.md`, `zonas.md`, `mapas/`, `bestiario.md`, `minerales.md`, `piezas.md`,
`encargos.md` como **fase futura**). Respeta niveles (50-60) e ids fijados; cambios del mundo (sobre todo del final)
en "Propuestas al world-designer". No toques `src/` ni otras carpetas.
