# Bosque de Robleda · `valdemar.robleda`

Al sur del pueblo, por el camino real. Robledal denso con claros, el campamento bandido vallado (suroeste), el puesto del guardabosques junto a la llegada y la guarida del Lobo alfa (sureste). Misiones: `valdemar.caza_mayor` (Bruno) y `valdemar.hilos` (Elena).

- Tamaño: **64×36** casillas · tipo: **exterior de campo** · bioma: `valdemar`
- `AreaMap.level` (fuera de zonas): **6** · entrada por defecto (`entry`): **(43, 2)** · punto seguro (reaparición, M9): **(47, 8)**
- Generado y validado (filas iguales, borde cerrado salvo salidas, todo conectado desde la entrada, spawns pisables y dentro de su zona, ningún monstruo a menos de 7 casillas de una llegada).

## Salidas (`>`)

| Id | Casillas | Lleva a | Llega a (casilla) | Bloqueo |
|---|---|---|---|---|
| `robleda.norte` | (42,0), (43,0), (44,0), (45,0) | `town` | (21, 33) | — |
| `robleda.este` | (63,22), (63,23), (63,24) | `valdemar.pedregal` | (2, 17) | — |
| `robleda.huertos` | (8,0), (9,0), (10,0), (11,0) | `valdemar.huertos` | (12, 33) | — |

Llegadas a esta área: desde `town` → (43, 2), desde `valdemar.huertos` → (9, 2), desde `valdemar.pedregal` → (61, 23)

## Edificios (`Building`)

| Id | Nombre | Estilo | x, y, ancho, alto | Puerta (x, ancho) | Interior |
|---|---|---|---|---|---|
| `cabana` | Puesto del guardabosques | `rangerHut` (nuevo) | 49, 3, 5, 4 | 51, 1 | nil (cerrado) |

## Zonas (`Zone`)

| Id | Nombre | x, y, ancho, alto | Nivel |
|---|---|---|---|
| `valdemar.robleda.robledal` | Robledal | 2, 2, 28, 14 | **6** |
| `valdemar.robleda.campamento` | Campamento bandido | 2, 16, 28, 18 | **6** |
| `valdemar.robleda.camino` | Camino real | 30, 2, 32, 23 | **6** |
| `valdemar.robleda.guarida` | Guarida del lobo | 30, 25, 32, 9 | **7** |

## Monstruos (`Spawn`)

Grupos: los que están a menos de 3,5 casillas se avisan entre sí (alerta de manada de 170 pt). **Reaparece** = monstruo de campo (M2); **permanente** = se guarda en `killedSpawns`.

| Id | Enemigo | Casilla | Zona (nivel) | Tipo | Nota |
|---|---|---|---|---|---|
| `valdemar.robleda.1` | `wolf` Lobo gris | (20,6) | Robledal (6) | reaparece |  |
| `valdemar.robleda.2` | `wolf` Lobo gris | (22,7) | Robledal (6) | reaparece |  |
| `valdemar.robleda.3` | `boar` Jabalí | (18,10) | Robledal (6) | reaparece |  |
| `valdemar.robleda.4` | `hobgoblin` Hobgoblin | (28,13) | Robledal (6) | reaparece |  |
| `valdemar.robleda.5` | `bandit` Bandido | (10,23) | Campamento bandido (6) | reaparece |  |
| `valdemar.robleda.6` | `bandit` Bandido | (12,24) | Campamento bandido (6) | reaparece |  |
| `valdemar.robleda.7` | `mercenary` Mercenario | (18,23) | Campamento bandido (6) | reaparece |  |
| `valdemar.robleda.8` | `bandit` Bandido | (20,24) | Campamento bandido (6) | reaparece |  |
| `valdemar.robleda.9` | `mercenary` Mercenario | (10,28) | Campamento bandido (6) | reaparece |  |
| `valdemar.robleda.10` | `bandit` Bandido | (13,28) | Campamento bandido (6) | reaparece |  |
| `valdemar.robleda.11` | `mercenary` Mercenario | (19,28) | Campamento bandido (6) | reaparece |  |
| `valdemar.robleda.12` | `goblinSpearman` Goblin lancero | (37,18) | Camino real (6) | reaparece |  |
| `valdemar.robleda.13` | `goblinSpearman` Goblin lancero | (39,20) | Camino real (6) | reaparece |  |
| `valdemar.robleda.14` | `goblinShaman` Chamán goblin | (36,21) | Camino real (6) | reaparece |  |
| `valdemar.robleda.15` | `boar` Jabalí | (33,6) | Camino real (6) | reaparece |  |
| `valdemar.robleda.16` | `hobgoblin` Hobgoblin | (54,16) | Camino real (6) | reaparece |  |
| `valdemar.robleda.17` | `goblinShaman` Chamán goblin | (57,17) | Camino real (6) | reaparece |  |
| `valdemar.robleda.18` | `alphaWolf` Lobo alfa | (55,30) | Guarida del lobo (7) | permanente | jefe: delante de las rocas de la guarida |
| `valdemar.robleda.19` | `wolf` Lobo gris | (47,30) | Guarida del lobo (7) | reaparece |  |
| `valdemar.robleda.20` | `wolf` Lobo gris | (49,32) | Guarida del lobo (7) | reaparece |  |
| `valdemar.robleda.21` | `wolf` Lobo gris | (36,30) | Guarida del lobo (7) | reaparece |  |

## Mapa (filas listas para `rows:` del código)

```
TTTTTTTT>>>>TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT>>>>TTTTTTTTTTTTTTTTTT
TTTTTTTTddddTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTddddTTTTTTTTTTTTTTTTTT
TT.T....dddd..T..............T.....T......dddd............T...TT
TT......dddd........T..T........T........Tdddd................TT
TT......dddd..............................dddd...............TTT
TT......dddd.T..T...,.......T.........T...dddd...........T....TT
TT..T..Tdddd..............................dddd................TT
TT......dddd.....................,........dddd................TT
TT......dddd....T.............T......T....dddd................TT
TTT.....dddd............,.................dddd..x.....c.....T.TT
TT...T..dddd.......T......................dddd................TT
TT......dddd..............T..T......T.....dddd................TT
TT......dddddddddddddddddddddddddddddddddddddd.........T......TT
TT.T..T.dddddddddddddddddddddddddddddddddddddd..T.........T...TT
TT......dddddddddddddddddddddddddddddddddddddd................TT
TT.......T...Tddd.....T.....T.............dddd.........,......TT
TT.T..T.......ddd..............T......T...dddd...T............TT
TT............ddd..T......................dddd...............TTT
TT..ffffffffffdddffffffffff.T.............dddd................TT
TT..f.T...................f...............dddd.....T..........TT
TT..f........n............f...............dddd..T......T......TT
TT..f....n..........n.....f.T............Tdddd.............T..TT
TT..f.....................f.....T.........ddddddddddddddddddddd>
TT..f.....................f........T......ddddddddddddddddddddd>
TT..f.....................f............T..ddddddddddddddddddddd>
TT..f..........x..........f....T..........ddd...............T.TT
TT..f.....................ddddddddddddddddddd......T.RRRR.....TT
TT..f.....................ddddddddddddddddddd..R.....R..R.....TT
TT..f.....................ddddddddddddddddT...................TT
TT..f...n............n....f...T..............................TTT
TT..f......cc.............f................................R..TT
TT..f..T..........c.....T.f......T............................TT
TTT.fffffffffffffffffffffff.........T.........................TT
TT..........T...............T..............T.R................TT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

## Mapa anotado (solo para leer: `H` edificio, `u` su puerta, `@` monstruo, `&` jefe, `!` NPC/objeto, `*` punto seguro)

```
TTTTTTTT>>>>TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT>>>>TTTTTTTTTTTTTTTTTT
TTTTTTTTddddTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTddddTTTTTTTTTTTTTTTTTT
TT.T....dddd..T..............T.....T......dddd............T...TT
TT......dddd........T..T........T........Tdddd...HHHHH........TT
TT......dddd..............................dddd...HHHHH.......TTT
TT......dddd.T..T...,.......T.........T...dddd...HHHHH...T....TT
TT..T..Tdddd........@............@........dddd...HHuHH........TT
TT......dddd..........@..........,........dddd................TT
TT......dddd....T.............T......T....dddd.*..............TT
TTT.....dddd............,.................dddd..x.....c.....T.TT
TT...T..dddd......@T......................dddd................TT
TT......dddd..............T..T......T.....dddd................TT
TT......dddddddddddddddddddddddddddddddddddddd.........T......TT
TT.T..T.dddddddddddddddddddd@ddddddddddddddddd..T.........T...TT
TT......dddddddddddddddddddddddddddddddddddddd................TT
TT.......T...Tddd.....T.....T.............dddd.........,......TT
TT.T..T.......ddd..............T......T...dddd...T....@.......TT
TT............ddd..T......................dddd...........@...TTT
TT..ffffffffffdddffffffffff.T........@....dddd................TT
TT..f.T...................f...............dddd.....T..........TT
TT..f........n............f............@..dddd..T......T......TT
TT..f....n..........n.....f.T.......@....Tdddd.............T..TT
TT..f.....................f.....T.........ddddddddddddddddddddd>
TT..f.....@.......@.......f........T......ddddddddddddddddddddd>
TT..f.......@.......@.....f............T..ddddddddddddddddddddd>
TT..f..........x..........f....T..........ddd...............T.TT
TT..f.....................ddddddddddddddddddd......T.RRRR.....TT
TT..f.....................ddddddddddddddddddd..R.....R..R.....TT
TT..f.....@..@.....@......ddddddddddddddddT...................TT
TT..f...n............n....f...T..............................TTT
TT..f......cc.............f.........@..........@.......&...R..TT
TT..f..T..........c.....T.f......T............................TT
TTT.fffffffffffffffffffffff.........T............@............TT
TT..........T...............T..............T.R................TT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

Caracteres usados: `,` flores · `.` hierba · `>` salida a otra área · `R` roca · `T` árbol · `c` cajas · `d` camino de tierra · `f` valla / empalizada · `n` tienda · `x` hoguera / brasero
