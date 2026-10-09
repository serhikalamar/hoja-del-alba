# Paso del Norte · `valdemar.paso`

Al norte del pueblo, junto a la muralla del castillo. Sendero de montaña en zigzag con rezagados goblins que huyen del castillo. Cerrado hasta completar `valdemar.paso_norte`; su salida norte lleva a Rocaforja ("Próximamente" hasta que exista el continente 2).

- Tamaño: **48×32** casillas · tipo: **exterior de campo** · bioma: `valdemar`
- `AreaMap.level` (fuera de zonas): **10** · entrada por defecto (`entry`): **(23, 29)** · punto seguro (reaparición, M9): **(23, 27)**
- Generado y validado (filas iguales, borde cerrado salvo salidas, todo conectado desde la entrada, spawns pisables y dentro de su zona, ningún monstruo a menos de 7 casillas de una llegada).

## Salidas (`>`)

| Id | Casillas | Lleva a | Llega a (casilla) | Bloqueo |
|---|---|---|---|---|
| `paso.sur` | (22,31), (23,31), (24,31) | `town` | (4, 2) | — |
| `paso.norte` | (22,0), (23,0), (24,0) | `rocaforja` | — | `comingSoon("rocaforja")` · "Montes de Rocaforja: próximamente." |

Llegadas a esta área: desde `town` → (23, 29)

## Edificios (`Building`)

| Id | Nombre | Estilo | x, y, ancho, alto | Puerta (x, ancho) | Interior |
|---|---|---|---|---|---|
| `atalaya` | Atalaya derruida | `watchtower` (nuevo) | 30, 22, 4, 5 | 31, 1 | nil (cerrado) |

## Zonas (`Zone`)

| Id | Nombre | x, y, ancho, alto | Nivel |
|---|---|---|---|
| `valdemar.paso.sendero` | Paso del Norte | 2, 2, 44, 28 | **10** |

## Monstruos (`Spawn`)

Grupos: los que están a menos de 3,5 casillas se avisan entre sí (alerta de manada de 170 pt). **Reaparece** = monstruo de campo (M2); **permanente** = se guarda en `killedSpawns`.

| Id | Enemigo | Casilla | Zona (nivel) | Tipo | Nota |
|---|---|---|---|---|---|
| `valdemar.paso.1` | `wolfRider` Jinete de lobo | (9,21) | Paso del Norte (10) | reaparece |  |
| `valdemar.paso.2` | `wolfRider` Jinete de lobo | (12,23) | Paso del Norte (10) | reaparece |  |
| `valdemar.paso.3` | `goblinElite` Goblin de élite | (20,15) | Paso del Norte (10) | reaparece |  |
| `valdemar.paso.4` | `goblinMage` Mago goblin | (22,13) | Paso del Norte (10) | reaparece |  |
| `valdemar.paso.5` | `goblinElite` Goblin de élite | (38,9) | Paso del Norte (10) | reaparece |  |
| `valdemar.paso.6` | `armoredBoar` Jabalí acorazado | (14,6) | Paso del Norte (10) | reaparece |  |

## NPC y objetos

| Id | Nombre | Casilla | Nota |
|---|---|---|---|
| `cartelPaso` | Cartel del camino | (26,2) | objeto: 'Montes de Rocaforja' |

## Mapa (filas listas para `rows:` del código)

```
^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^
^^........T..T........ddd...T..........T......^^
^^....T............T..ddd...c.c...............^^
^^............R.......ddd..........T.......T..^^
^^.............T......ddddddddddddddddd.......^^
^^T..T......T......T..ddddddddddddddddd.......^^
^^....................ddddddddddddddddd.......^^
^^.......T..........................dddT......^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^.T.ddd...T...^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^...ddd.......^^
^^..................................ddd.......^^
^^..........................T..T....ddd.T.R...^^
^^........T...T..T.....T............ddd.......^^
^^....ddddddddddddddddddddddddddddddddd.......^^
^^..T.ddddddddddddddddddddddddddddddddd.......^^
^^....ddddddddddddddddddddddddddddddddd.......^^
^^....ddd......T.......................T....T.^^
^^....ddd.T..........T........................^^
^^....ddd.^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^..^^
^^T...ddd.^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^..^^
^^....ddd.T..T..............T................T^^
^^....ddd...........................T.........^^
^^....ddd...............................T.....^^
^^....ddddddddddddddddddd.....................^^
^^....dddddddddddddddddddT..............R.....^^
^^....ddddddddddddddddddd.....................^^
^^........T.R.T...T...ddd...T.....T....T......^^
^^....................ddd.x...................^^
^^..T.................ddd.....................^^
^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^
```

## Mapa anotado (solo para leer: `H` edificio, `u` su puerta, `@` monstruo, `&` jefe, `!` NPC/objeto, `*` punto seguro)

```
^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^
^^........T..T........ddd.!.T..........T......^^
^^....T............T..ddd...c.c...............^^
^^............R.......ddd..........T.......T..^^
^^.............T......ddddddddddddddddd.......^^
^^T..T......T.@....T..ddddddddddddddddd.......^^
^^....................ddddddddddddddddd.......^^
^^.......T..........................dddT......^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^.T.dd@...T...^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^...ddd.......^^
^^..................................ddd.......^^
^^..........................T..T....ddd.T.R...^^
^^........T...T..T....@T............ddd.......^^
^^....ddddddddddddddddddddddddddddddddd.......^^
^^..T.dddddddddddddd@dddddddddddddddddd.......^^
^^....ddddddddddddddddddddddddddddddddd.......^^
^^....ddd......T.......................T....T.^^
^^....ddd.T..........T........................^^
^^....ddd.^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^..^^
^^T...ddd.^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^..^^
^^....ddd@T..T..............T................T^^
^^....ddd.....................HHHH..T.........^^
^^....ddd...@.................HHHH......T.....^^
^^....ddddddddddddddddddd.....HHHH............^^
^^....dddddddddddddddddddT....HHHH......R.....^^
^^....ddddddddddddddddddd.....HuHH............^^
^^........T.R.T...T...d*d...T.....T....T......^^
^^....................ddd.x...................^^
^^..T.................ddd.....................^^
^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^
```

Caracteres usados: `.` hierba · `>` salida a otra área · `R` roca · `T` árbol · `^` acantilado · `c` cajas · `d` camino de tierra · `x` hoguera / brasero
