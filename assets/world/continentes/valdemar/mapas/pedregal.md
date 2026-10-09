# Colinas del Pedregal · `valdemar.pedregal`

Al sureste: colinas de roca, crestas y pozas heladas. Al fondo, el campamento orco con empalizada y el Señor de la guerra. Se llega desde Robleda (oeste) o desde la abadía (norte). Misión: `valdemar.pedregal` (Capitán de la guardia) y parte de `valdemar.pociones`.

- Tamaño: **60×38** casillas · tipo: **exterior de campo** · bioma: `valdemar`
- `AreaMap.level` (fuera de zonas): **8** · entrada por defecto (`entry`): **(2, 17)** · punto seguro (reaparición, M9): **(5, 17)**
- Generado y validado (filas iguales, borde cerrado salvo salidas, todo conectado desde la entrada, spawns pisables y dentro de su zona, ningún monstruo a menos de 7 casillas de una llegada).

## Salidas (`>`)

| Id | Casillas | Lleva a | Llega a (casilla) | Bloqueo |
|---|---|---|---|---|
| `pedregal.oeste` | (0,16), (0,17), (0,18) | `valdemar.robleda` | (61, 23) | — |
| `pedregal.norte` | (30,0), (31,0), (32,0) | `valdemar.abadia` | (32, 35) | — |

Llegadas a esta área: desde `valdemar.robleda` → (2, 17), desde `valdemar.abadia` → (31, 2)

## Zonas (`Zone`)

| Id | Nombre | x, y, ancho, alto | Nivel |
|---|---|---|---|
| `valdemar.pedregal.laderas` | Laderas del Pedregal | 2, 2, 25, 34 | **8** |
| `valdemar.pedregal.pozas` | Pozas heladas | 27, 2, 31, 18 | **8** |
| `valdemar.pedregal.campamento` | Campamento orco | 27, 20, 31, 16 | **9** |

## Monstruos (`Spawn`)

Grupos: los que están a menos de 3,5 casillas se avisan entre sí (alerta de manada de 170 pt). **Reaparece** = monstruo de campo (M2); **permanente** = se guarda en `killedSpawns`.

| Id | Enemigo | Casilla | Zona (nivel) | Tipo | Nota |
|---|---|---|---|---|---|
| `valdemar.pedregal.1` | `goblinBomber` Goblin bombardero | (14,7) | Laderas del Pedregal (8) | reaparece |  |
| `valdemar.pedregal.2` | `goblinBomber` Goblin bombardero | (17,9) | Laderas del Pedregal (8) | reaparece |  |
| `valdemar.pedregal.3` | `troll` Troll | (12,22) | Laderas del Pedregal (8) | reaparece |  |
| `valdemar.pedregal.4` | `wolfRider` Jinete de lobo | (21,27) | Laderas del Pedregal (8) | reaparece |  |
| `valdemar.pedregal.5` | `wolfRider` Jinete de lobo | (23,30) | Laderas del Pedregal (8) | reaparece |  |
| `valdemar.pedregal.6` | `assassin` Asesino sombrío | (7,33) | Laderas del Pedregal (8) | reaparece |  |
| `valdemar.pedregal.7` | `troll` Troll | (22,4) | Laderas del Pedregal (8) | reaparece |  |
| `valdemar.pedregal.8` | `iceSlime` Limo helado | (37,10) | Pozas heladas (8) | reaparece |  |
| `valdemar.pedregal.9` | `iceSlime` Limo helado | (40,11) | Pozas heladas (8) | reaparece |  |
| `valdemar.pedregal.10` | `iceSlime` Limo helado | (52,9) | Pozas heladas (8) | reaparece |  |
| `valdemar.pedregal.11` | `assassin` Asesino sombrío | (48,5) | Pozas heladas (8) | reaparece |  |
| `valdemar.pedregal.12` | `troll` Troll | (54,14) | Pozas heladas (8) | reaparece |  |
| `valdemar.pedregal.13` | `orc` Orco | (40,25) | Campamento orco (9) | reaparece |  |
| `valdemar.pedregal.14` | `orc` Orco | (42,27) | Campamento orco (9) | reaparece |  |
| `valdemar.pedregal.15` | `berserker` Orco berserker | (50,25) | Campamento orco (9) | reaparece |  |
| `valdemar.pedregal.16` | `orc` Orco | (52,26) | Campamento orco (9) | reaparece |  |
| `valdemar.pedregal.17` | `armoredBoar` Jabalí acorazado | (39,31) | Campamento orco (9) | reaparece | élite |
| `valdemar.pedregal.18` | `berserker` Orco berserker | (44,33) | Campamento orco (9) | reaparece |  |
| `valdemar.pedregal.19` | `warlord` Señor de la guerra orco | (51,31) | Campamento orco (9) | permanente | jefe: junto a los tótems del fondo |

## Mapa (filas listas para `rows:` del código)

```
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^.............%%%%%%%%.......ddd.........................^^
^^.............%%%%%%%%.......ddd.........................^^
^^....R.......................ddd.............R...........^^
^^............R...............ddd........~................^^
^^............................ddd.....~~~~~~~.............^^
^^............................ddd....~~~~~~~~~..........R.^^
^^..................R.........ddd.....~~~~~~~.............^^
^^.^^^^^^^^^..................ddd........~................^^
^^.^^^^^^^^^..................ddd.........................^^
^^............................ddd................~~~~~....^^
^^......................R.....ddd...R...........~~~~~~~...^^
^^..x...R........R............ddd................~~~~~....^^
^^............................ddd.........................^^
^^............................ddd.....R...................^^
>dddddddddddddddddddddddddddddddddddddddddddddd.......R...^^
>dddddddddddddddddddddddddddddddddddddddddddddd...........^^
>dddddddddddddddddddddddddddddddddddddddddddddd...........^^
^^.........................ddd..............ddd...........^^
^^.........................ddd..............ddd...........^^
^^..............R..........ddd..............ddd...........^^
^^.........................ddd.....fffffffffdddfffffffff..^^
^^.....................R...ddd.....f...................f..^^
^^.........................ddd.....f..n.............n..f..^^
^^.^^^^^^^^^^^^^^^^........ddd.....f...................f..^^
^^.^^^^^^^^^^^^^^^^........ddd.....f.....+.......+.....f..^^
^^.........................ddddddddd...................f..^^
^^...........%%%%%%%.......ddddddddd.................ccf..^^
^^...........%%%%%%%......Rddddddddd...................f..^^
^^...R.......%%%%%%%...............f.........x.........f..^^
^^..........R......................f...................f..^^
^^.................................f..n.............n..f..^^
^^...................R.............f............+.+....f..^^
^^.................................fffffffffffffffffffff..^^
^^........................................................^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## Mapa anotado (solo para leer: `H` edificio, `u` su puerta, `@` monstruo, `&` jefe, `!` NPC/objeto, `*` punto seguro)

```
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^>>>^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ddd^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^.............%%%%%%%%.......ddd.........................^^
^^.............%%%%%%%%.......ddd.........................^^
^^....R...............@.......ddd.............R...........^^
^^............R...............ddd........~......@.........^^
^^............................ddd.....~~~~~~~.............^^
^^............@...............ddd....~~~~~~~~~..........R.^^
^^..................R.........ddd.....~~~~~~~.............^^
^^.^^^^^^^^^.....@............ddd........~..........@.....^^
^^.^^^^^^^^^..................ddd....@....................^^
^^............................ddd.......@........~~~~~....^^
^^......................R.....ddd...R...........~~~~~~~...^^
^^..x...R........R............ddd................~~~~~....^^
^^............................ddd.....................@...^^
^^............................ddd.....R...................^^
>dddddddddddddddddddddddddddddddddddddddddddddd.......R...^^
>dddd*ddddddddddddddddddddddddddddddddddddddddd...........^^
>dddddddddddddddddddddddddddddddddddddddddddddd...........^^
^^.........................ddd..............ddd...........^^
^^.........................ddd..............ddd...........^^
^^..............R..........ddd..............ddd...........^^
^^..........@..............ddd.....fffffffffdddfffffffff..^^
^^.....................R...ddd.....f...................f..^^
^^.........................ddd.....f..n.............n..f..^^
^^.^^^^^^^^^^^^^^^^........ddd.....f....@.........@....f..^^
^^.^^^^^^^^^^^^^^^^........ddd.....f.....+.......+..@..f..^^
^^...................@.....ddddddddd......@............f..^^
^^...........%%%%%%%.......ddddddddd.................ccf..^^
^^...........%%%%%%%......Rddddddddd...................f..^^
^^...R.......%%%%%%%...@...........f.........x.........f..^^
^^..........R......................f...@...........&...f..^^
^^.................................f..n.............n..f..^^
^^.....@.............R.............f........@...+.+....f..^^
^^.................................fffffffffffffffffffff..^^
^^........................................................^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Caracteres usados: `%` hierba alta / trigal / maleza · `+` lápida / tótem · `.` hierba · `>` salida a otra área · `R` roca · `^` acantilado · `c` cajas · `d` camino de tierra · `f` valla / empalizada · `n` tienda · `x` hoguera / brasero · `~` agua
