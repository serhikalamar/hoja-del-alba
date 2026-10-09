# Valdemar · áreas de campo (continente 1, niveles 1-10)

Código: `enum Valdemar` en `src/GameCore/Sources/GameCore/Valdemar.swift` (registrado en `World.areas` y
`World.storyDungeons`). Borradores validados del continent-lead (filas, tablas completas de spawns y mapas anotados):
`assets/world/continentes/valdemar/mapas/*.md`; zonas y oleadas: `assets/world/continentes/valdemar/zonas.md`.
Renders: `make maps` → `tools/Harness/output/map_valdemar.<área>.png`. Pueblo: `valdehierro.md`.

## Mapa del continente

```
                     [ Paso del Norte · 10 ]
                               | norte (cerrada hasta valdemar.paso_norte) · su norte → Rocaforja (próximamente)
 [ Huertos 5/6 ] ── oeste ── VALDEHIERRO 1-5 (patio 9, trono 10) ── este ── [ Abadía 7/8 ] ── ee → Cripta 8
       | sur                           | sur                                     | sur
       └──────────── [ Bosque de Robleda 6/7 ] ──────── este ──────── [ Colinas del Pedregal 8/9 ]
```

Dos anillos sin callejones: pueblo → Huertos → Robleda → pueblo, y pueblo → Abadía → Pedregal → Robleda → pueblo.
Las salidas oeste y este del pueblo piden su barrio liberado; la norte, la misión del herrero.

## Ruta prevista y dificultad

| Orden | Área (id) | Tamaño | Zonas (nivel) | Jefe | Spawns |
|---|---|---|---|---|---|
| 0 | `town` | 44×36 | Puerta sur 1 · Mercado 2 · Barrio oeste 3 · Barrio este 4 · Plaza 5 | (en casas) | 36 (permanentes) |
| 1 | `valdemar.huertos` | 56×36 | Trigales quemados 5 · Ribera del Plata 5 · Molino en ruinas **6** | Ogro del molino (9,11) | 21 |
| 2 | `valdemar.robleda` | 64×36 | Robledal 6 · Campamento bandido 6 · Camino real 6 · Guarida del lobo **7** | Lobo alfa (55,30) | 21 |
| 3 | `mayor` (interior) | 14×9 | 7 | — (carta del alcalde) | 4 (permanentes) |
| 4 | `valdemar.abadia` | 56×38 | Cementerio 7 · Huerto de los monjes 7 · Claustro en ruinas **8** | (Abad en la Cripta) | 20 |
| 5 | Cripta (`valdemar.cripta`) | piso `crypt` | 8 | Abad no-muerto | 3 oleadas + jefe |
| 6 | `valdemar.pedregal` | 60×38 | Laderas 8 · Pozas heladas 8 · Campamento orco **9** | Señor de la guerra (51,31) | 19 |
| 7 | `town` patio → `castle` | — | Patio **9** → Salón del trono **10** | Rey Goblin | 7 + 6 |
| 8 | `valdemar.paso` | 48×32 | Paso del Norte **10** | — | 6 |
| opc. | Calabozos (`valdemar.calabozos`) | piso `prison` | 9 | — | 4 oleadas |

Dentro de cada área la entrada está en la zona fácil y el jefe en la difícil, al fondo. Los monstruos de campo
reaparecen (motor M2); los jefes de campo (`ogre`, `alphaWolf`, `warlord`) son permanentes.

## Áreas

| Área | Entrada | Punto seguro | Salidas (id: casillas → destino, llegada) | Edificios (todos cerrados) | NPC |
|---|---|---|---|---|---|
| Huertos del Molino | (53,17) | (50,17) | `huertos.este` (55,16-18) → `town` (2,17) · `huertos.sur` (11-14,35) → Robleda (9,2) | Molino en ruinas `ruinedMill`, 2 granjas quemadas `burnedFarm` | — |
| Bosque de Robleda | (43,2) | (47,8) | `robleda.norte` (42-45,0) → `town` (21,33) · `robleda.este` (63,22-24) → Pedregal (2,17) · `robleda.huertos` (8-11,0) → Huertos (12,33) | Puesto del guardabosques `rangerHut` | — |
| Abadía de Valsombra | (2,17) | (4,17) | `abadia.oeste` (0,16-18) → `town` (41,17) · `abadia.sur` (31-33,37) → Pedregal (32,35) · bajada `ee` (40-41,15) → Cripta | Iglesia de la abadía `abbeyChurch` (puerta de 2) | — |
| Colinas del Pedregal | (2,17) | (5,17) | `pedregal.oeste` (0,16-18) → Robleda (61,23) · `pedregal.norte` (30-32,0) → Abadía (31,2) | — | — |
| Paso del Norte | (23,29) | (23,27) | `paso.sur` (22-24,31) → `town` (4,2) · `paso.norte` (22-24,0) → Rocaforja: `comingSoon`, "Montes de Rocaforja: próximamente." | Atalaya derruida `watchtower` | `cartelPaso` (26,2), pista |

## Mazmorras de historia (`Valdemar.dungeons`)

| Id | Piso | Nivel | Oleadas | Jefe | Entrada | Premio fijo |
|---|---|---|---|---|---|---|
| `valdemar.cripta` | `crypt` | 8 | 3 × 10 (no-muertos, Eclipse) | `abbot` + 2 `skeleton` (con `bossIntro` provisional) | `ee` de la Abadía | `emerald` ×1 (el 50 % de `gold` lo decide el balance-designer) |
| `valdemar.calabozos` | `prison` | 9 | 4 (8-9 por oleada) | — | `e` (34,7) del patio, castillo abierto | — |

## Comprobaciones

- `make test`: `WorldTests` (contrato) + `ValdemarMapTests`: 5 áreas `field` registradas, borde cerrado salvo `>`,
  todo pisable conectado desde la entrada, spawns con ids `valdemar.<área>.<n>` en orden y dentro de una zona, 7+
  casillas entre cualquier llegada y el monstruo más cercano, número de spawns y jefes, niveles por la ruta, salidas
  con vuelta junto a la llegada, cambios del pueblo.
- Revisión con un héroe de 2×2 casillas (más estricto que la caja real de los pies, 22×8 pt en casillas de 48 pt):
  todo se alcanza salvo dos esqueletos del cementerio viejo de los Huertos (`valdemar.huertos.9` y `.10`), entre
  lápidas con huecos de 1 casilla; la caja real del héroe cabe y además salen a perseguirle.
- Arte provisional en las casillas nuevas y los 5 estilos de edificio nuevos (fase 2, environment-artist).
