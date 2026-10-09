# Brief · Continente 5 · `escarcha` — Tierras de Escarcha (niveles 40-50)

> **Encargo original (2026-10-07).** Tras el diseño de los leads, lo vigente está en `assets/world/mundo.md` (§5, §13 y §14),
> `continentes.md` (registros comunes y renombres), `progresion.md` (XP de misiones y Hoja del Alba) y `motor_comun.md`.

Para: `continent-lead` de `escarcha`. De: `world-designer`. Lee antes `CLAUDE.md`, `assets/world/mundo.md`,
`assets/world/continentes.md`, `assets/world/progresion.md` y el brief de Valdemar
(`assets/world/continentes/valdemar/brief.md`, sección 7: el motor que habrá).

> Se **diseña ahora** y se implementa **después de Valdemar**. Encargos listos para más adelante, en ficheros de tu
> continente (p. ej. `Escarcha.swift`); en las listas compartidas (`Enemy`, `Mineral`, `Parts`) solo se añade al final.

## 1. Qué es Escarcha

El norte helado: tundra, glaciares azules, auroras violetas y **cráteres donde han caído trozos de la Luna**.
Blanco, cian y violeta. Emoción: *soledad y presagio*. Sin raza jugable propia; capital: **Hielomar**, puerto de los
hombres del norte (balleneros, desconfiados, hospitalarios con quien se lo gana).
Tier de material **5** (glacita · ébano · cuero sombrío · seda lunar).

## 2. Historia del capítulo (propuesta; desarróllala)

- El sello de Morvath se rompe: caen **esquirlas de luna** que congelan y enloquecen a quien las toca.
- Los **Caballeros de la Luna Rota**, orden que vigilaba el sello desde su ciudadela, han caído: su reina
  (*propuesta*: **la Reina de la Luna Rota**) escucha a Morvath y usa las esquirlas para abrir el camino al cielo.
- Es el **golpe bajo** de la historia: aquí el Eclipse gana algo (*a confirmar*: ¿roba el Ascua de Escarcha y hay que
  recuperarla en Umbral?, ¿muere un aliado?). Propón la opción que te parezca más fuerte en "Propuestas al world-designer".
- Final en la Ciudadela de la Luna Rota; la Hoja del Alba despierta (V) y se descubre cómo subir al Yunque del Alba
  (dirigible enano + portal de las Ascuas).

## 3. Zonas (plantilla de `progresion.md`; nombres e ids propuestos)

| Hueco | Niveles | Propuesta | Id propuesto |
|---|---|---|---|
| Capital | — | Hielomar | `escarcha.hielomar` |
| Zona 1 | 40-42 | Costa de los Balleneros (llegada en barco): lobos y osos de hielo | `escarcha.balleneros` |
| Zona 2 | 42-44 | Tundra Aullante: yetis, mamuts, wendigos | `escarcha.tundra` |
| Zona 3 | 44-46 | Cráter de la Esquirla: elementales de hielo, lunáticos | `escarcha.crater` |
| Mazmorra | 45-47 | Sima del Glaciar (piso nuevo `glacier`) | — |
| Zona 4 | 46-48 | Trono de los Gigantes: gigantes de escarcha | `escarcha.gigantes` |
| Zona 5 | 48-49 | Murallas de la Luna Rota: caballeros caídos, no-muertos helados | `escarcha.murallas` |
| Final | 49-50 | Ciudadela de la Luna Rota (piso nuevo `citadel`): la Reina | — |

Llegada: barco del norte (maestro de viajes) a la zona 1. Salida: dirigible enano hacia Umbral al terminar.

## 4. Monstruos (familias tuyas: yetis, gigantes de escarcha, bestias de hielo, no-muertos helados, Caballeros de la Luna Rota)

10-15 normales + 2-4 jefes. Ideas (ids propuestos):
`frostWolf` Lobo de escarcha (embestida) · `iceBear` Oso polar · `yeti` Yeti · `mammoth` Mamut (embestida, élite) ·
`wendigo` Wendigo (rápido) · `iceElemental` Elemental de hielo · `shardLunatic` Lunático de la esquirla (a distancia) ·
`frostGiant` Gigante de escarcha (élite) · `frozenDead` Muerto helado · `frostWraith` Espectro gélido ·
`brokenKnight` Caballero de la Luna Rota · `moonPriestess` Sacerdotisa de la Luna Rota (a distancia).
Jefes: el patriarca yeti, el **jarl de los gigantes**, el comandante de las murallas y **la Reina de la Luna Rota**.
Plantillas reutilizables: `dog` (lobos), `brute` (yeti, gigante, oso), `boar` (mamut), `ghost` (espectro),
`skeleton` (muertos helados), `human` (caballeros, sacerdotisa), `slime` (elemental). Ya existe `iceSlime` en Valdemar:
no lo reutilices aquí salvo como guiño.

## 5. Minerales, piezas y armadura (fijados en `continentes.md`)

- Minerales: `quartz` Cuarzo (ATQ, 35 %), `rimeiron` Hierro gélido (DEF, 27 %), `aquamarine` Aguamarina (REGEN., 20 %),
  `moonshard` Esquirla de luna (ROBO DE VIDA, 12 %), `sapphire` Zafiro (ALCANCE, 6 %, ya existe).
- Formas nuevas: `halberd` Alabarda (Hielo), `frost` Guarda escarchada (Hielo), `fur` Empuñadura forrada (Viento).
- Conjunto de armadura opcional: `helm.escarcha`, `chest.escarcha`, `gloves.escarcha`, `boots.escarcha`.
- Forja de Hielomar: tier 5.

## 6. Motor

Con M1-M10 de Valdemar. Particularidades posibles: bioma de nieve (`.` nieve, `~` agua helada), ventisca y aurora
como ambiente (`environment-artist`), cráteres con esquirlas que brillan. Pisos nuevos `glacier` y `citadel`.
Si quieres hielo resbaladizo u otra mecánica, en "Necesidades de motor" (no es imprescindible).

## 7. Lo que entregas (en `assets/world/continentes/escarcha/`)

Lo de tu fichero de agente (`historia.md`, `zonas.md`, `mapas/`, `bestiario.md`, `minerales.md`, `piezas.md`,
`encargos.md` como **fase futura**). Respeta niveles (40-50) e ids fijados; cambios del mundo en "Propuestas al
world-designer". No toques `src/` ni otras carpetas.
