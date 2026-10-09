# Valdehierro · `town` — cambios para el continente

Capital de Valdemar (ya existe, 44×36). **No se renombra nada**: ids de área, zonas, spawns, edificios y NPC se quedan.
Solo se añaden 4 salidas, la bajada opcional a los calabozos, la casa del alcalde y las posiciones de los aldeanos
rescatados en la calle. Quién lo hace: `map-designer` (datos dentro de `enum Valdehierro`), con los tipos que añade
el `game-programmer` en el paso 0 (ver `../encargos.md`).

## Cambios casilla a casilla

| Qué | Casillas | Antes | Después |
|---|---|---|---|
| Salida norte (Paso del Norte) | (3,0) (4,0) (5,0) | `TTT` | `>>>` |
| Salida oeste (Huertos) | (0,17) (0,18) · (1,17) (1,18) | `T` · `T` | `>` · `#` |
| Salida este (Abadía) | (43,17) (43,18) · (42,17) (42,18) | `T` · `T` | `>` · `#` |
| Salida sur (Robleda, camino real) | (18..25, 35) | `########` | `>>>>>>>>` |
| Bajada a los calabozos (opcional, P3) | (34,7) en el patio | `.` | `e` |

- `town.entry`: **(21,35) → (21,33)** (la fila 35 pasa a ser salida). La reaparición sigue en la Puerta sur.
- Zona `courtyard` (Patio del castillo): **nivel 7 → 9**. Spawns iguales.
- Edificio `mayor` (Casa del alcalde): `interiorID: nil → "mayor"`, **cerrado** hasta completar `valdemar.hilos`
  (aviso: "La puerta del alcalde está atrancada. Quizá Elena sepa algo."). Interior en `casa_alcalde.md`.
- **Escalinata** `S` (19..24, 11): se bloquea hasta que se cumpla la condición nueva del castillo
  (aldeanos + `valdemar.abadia` + `valdemar.pedregal` completadas). Aviso: "El Capitán: nadie sube hasta que el Abad y
  el Señor de la guerra caigan." Hoy el patio es accesible desde el principio: con nivel 9 ya no puede serlo.
- Puerta del castillo: misma condición (`castleOpen` ampliado).

## Salidas (`AreaExit`)

| Id | Casillas | Lleva a | Llega a | Bloqueo (aviso si está cerrada) |
|---|---|---|---|---|
| `town.oeste` | (0,17) (0,18) | `valdemar.huertos` | (53,17) | Zona `west` liberada · "Los goblins del barrio oeste cortan el camino de los huertos." |
| `town.este` | (43,17) (43,18) | `valdemar.abadia` | (2,17) | Zona `east` liberada · "Los cultistas del barrio este vigilan el camino de la abadía." |
| `town.sur` | (18..25,35) | `valdemar.robleda` | (43,2) | — (siempre abierta) |
| `town.norte` | (3..5,0) | `valdemar.paso` | (23,29) | Misión `valdemar.paso_norte` completada · "El Paso del Norte está cerrado. El herrero sabe por qué." |
| (`e`) calabozos | (34,7) | mazmorra `valdemar.calabozos` (piso `prison`) | — | Castillo abierto |

Por qué el oeste y el este piden su barrio liberado: la casilla de llegada desde fuera ((2,17) y (41,17)) está pegada
a `west.1` y `east.4`; así nunca se aparece encima de un monstruo del pueblo, y además enseña el orden (pueblo → fuera).

Llegadas al pueblo: desde Huertos (2,17) · desde la Abadía (41,17) · desde Robleda (21,33) · desde el Paso (4,2).

## NPC nuevos o que cambian de sitio

| Id | Quién | Casilla en `town` | Cuándo aparece | Papel |
|---|---|---|---|---|
| `capitanGuardia` | Capitán de la guardia (NUEVO, look `guardCaptain`) | (18,12), al pie de la escalinata | Al completar `valdemar.liberar` | Da `valdemar.pedregal` y `valdemar.rey_goblin`; bloquea la escalinata |
| `marta` | Marta, la panadera | (6,17) | Tras su rescate | Diálogo (sin misión; vende/regala pan: solo texto) |
| `elena` | Elena, la tejedora | (12,17) | Tras su rescate | Da `valdemar.hilos` y `valdemar.alcalde` |
| `tomas` | Tomás, el molinero | (6,24) | Tras su rescate | Da `valdemar.molino` |
| `anselmo` | Fray Anselmo | (12,24) | Tras su rescate | Da `valdemar.abadia` |
| `bruno` | Bruno, el posadero | (35,17) | Tras su rescate | Da `valdemar.caza_mayor` |
| `iris` | Iris, la alquimista | (34,24) | Tras su rescate | Da `valdemar.pociones` |
| (forja) | El enano herrero | — (al entrar en la forja) | Tras `valdemar.rey_goblin` | Da y completa `valdemar.paso_norte` con un diálogo antes de abrir la tienda |

Todos en casillas de calle/plaza, al lado (no encima) de la puerta de su casa. Dentro de su casa siguen estando
también (el diálogo de "gracias otra vez").

## Mapa nuevo (filas listas para el código)

```
TTT>>>TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TT.....w............................w.....TT
TT.....w............................w.....TT
TT.....w.T.......................T..w.....TT
TT....,w............................w.,...TT
TT.....w............................w.....TT
TT.....w..T.......................T.w....,TT
TT,.,..w..........................e.w.....TT
TT.....w............................w.....TT
TT.....w=l==l==================l==l=w.....TT
TT.....w============================w.....TT
TT.....wwwwwwwwwwwwSSSSSSwwwwwwwwwwww.....TT
TT............#==============#............TT
TT............#=lb========bl=#..........,.TT
TT..........,.#==============#............TT
TT,...........#==============#.......,....TT
TT.......,....#======FF======#.....,......TT
>##############======FF======##############>
>##############==============##############>
TT............#==============#............TT
TT............#=lb========bl=#............TT
TT............#==============#.....,......TT
TT..,...............####..........,.......TT
TT....,.............####..............,...TT
TT########################################TT
TT..................####............,...,.TT
TT.===============..####.===============..TT
TT.=mm==mm==mm==mm..####.=mm==mm==mm==mm,.TT
TT.===============..####.===============..TT
TT.=c===c===c===c=..####.==c====c====c==..TT
TT.===============..####.===============,.TT
TT...........,....l.####.l................TT
wwwwwwwwwwwwwwwwwww######wwwwwwwwwwwwwwwwwww
TT................########................TT
TT,.....,.........########..........,.....TT
TT................>>>>>>>>....,...........TT
```
