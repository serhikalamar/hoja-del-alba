# Mapas

Responsable: `map-designer`.

- **Fuente de verdad** (lo que se juega):
  - `src/GameCore/Sources/GameCore/Town.swift` → `enum Valdehierro`: el pueblo y sus interiores.
  - `src/GameCore/Sources/GameCore/Valdemar.swift` → `enum Valdemar`: las áreas de campo del continente 1 y sus
    mazmorras de historia (cripta, calabozos).
  - `src/GameCore/Sources/GameCore/Dungeon.swift`: pisos de la mazmorra de la arena.
  - Todas las áreas se registran en `World.areas` (`World.swift`, tipos del game-programmer).
- **Este directorio**: diseño, rutas y notas de cada mapa (`valdehierro.md`, `valdemar.md`, `mazmorra.md`) y
  `borradores/`, donde dejas tus mapas (imagen, dibujo, texto… cualquier formato). El `map-designer` los pasa al juego.
  Los borradores del continente Valdemar (ya validados por el continent-lead) están en
  `assets/world/continentes/valdemar/mapas/`.
- Para ver los mapas tal y como se dibujan: `make maps` → `tools/Harness/output/map_<id de área>.png`
  (`map_town.png`, `map_mayor.png`, `map_valdemar.huertos.png`…).

## Formato del mapa en el juego

Un carácter por casilla de 24×24 pixeles. Todas las filas de un mapa con la misma longitud.

**Exterior (pueblo y campo)**

| Carácter | Casilla | ¿Se pisa? | Notas |
|---|---|---|---|
| `.` `,` | hierba, flores | sí | |
| `#` | calle | sí | |
| `=` | plaza / losas | sí | En la abadía, losas del claustro |
| `S` | escalinata | sí | La del castillo se bloquea hasta abrir el castillo |
| `d` | camino de tierra | sí | **nuevo** (campo) |
| `%` | hierba alta, trigal, maleza | sí | **nuevo** (decorativa) |
| `p` | puente de madera | sí | **nuevo**, sobre `~` |
| `e` | bajada a mazmorra de historia | sí | **nuevo**; va en `AreaMap.dungeonEntrances` |
| `>` | salida a otra área | sí | **nuevo**; en el borde, cada `>` pertenece a un `AreaExit` |
| `T` | árbol | no | |
| `w` | muralla / muro | no | En la abadía, muro en ruinas |
| `l` | farola | no | |
| `b` | arbusto | no | |
| `m` | puesto del mercado | no | |
| `c` | cajas | no | |
| `F` | fuente | no | bloque 2×2 |
| `~` | agua | no | río, estanque, pozas |
| `f` | valla | no | valla, cementerio, empalizada |
| `I` | columna | no | también en exteriores (claustro) |
| `R` | roca | no | **nuevo** |
| `^` | acantilado | no | **nuevo**; borde de las áreas de montaña |
| `+` | lápida, estela, tótem | no | **nuevo** |
| `n` | tienda de campaña | no | **nuevo** |
| `x` | hoguera, brasero | no | **nuevo**; junto a los puntos seguros |

Las casillas nuevas tienen arte provisional hasta la fase 2 (environment-artist): el suelo nuevo sale como hierba y
las sólidas nuevas pueden no verse, pero bloquean igual.

**Interior**: `X` pared, `_` madera, `:` piedra, `r` alfombra, `s` estantería, `k` horno, `t` mesa, `z` cama,
`o` barril, `I` columna, `Y` trono, `D` salida.

Edificios, zonas, enemigos y aldeanos se colocan por (columna, fila), contando desde 0 arriba a la izquierda.

## Piezas de un área (`AreaMap`)

- `Building`: rectángulo sólido; puerta en la última fila (`doorX`, `doorWidth`) con casilla pisable debajo.
  `interiorID` = interior al que lleva (`nil` = cerrada).
- `Zone`: rectángulo con nombre y `level` (dificultad). Ids de campo: `valdemar.<área>.<zona>`.
- `Spawn`: monstruo del bestiario. Ids estables (se guardan): `south.3` en el pueblo, `bakery.2` en interiores,
  `valdemar.<área>.<n>` en el campo. **No se renombran.** En el campo reaparecen salvo los jefes.
- `NPC`: aldeano, princesa, `questGiver` (Capitán) o `clue` (carta, cartel). `appearsWhen` = cuándo aparece.
- `kind` (`town`, `interior`, `field`), `exits` (`AreaExit`: casillas `>`, destino, llegada, bloqueo y aviso),
  `safePoint` (reaparición al morir en el campo), `dungeonEntrances` (casillas `e`).

## Reglas de diseño

- Borde cerrado (sólido) salvo las `>`; todo conectado desde la entrada; pasillos de 2+ casillas.
- La llegada de cada salida está junto a la salida de vuelta y lejos (7+ casillas) de cualquier monstruo.
- La dificultad crece por la ruta; el jefe de cada área en su zona más difícil.
- Lo comprueban `WorldTests` (contrato) y `ValdemarMapTests` (diseño) con `make test`.

## Cómo preparar un borrador

Lo más cómodo para pasarlo al juego:
1. Una cuadrícula (papel, hoja de cálculo o texto) con un símbolo por casilla, usando la leyenda de arriba.
2. Edificios marcados como rectángulos con su nombre y dónde está la puerta.
3. Zonas con nombre y dificultad aproximada (fácil → difícil).
4. Qué hay dentro de cada casa: quién está atrapado y qué enemigos.
5. Salidas: por dónde se sale y adónde lleva.

Cualquier dibujo vale: el `map-designer` lo traduce y te devuelve el render para revisarlo.
