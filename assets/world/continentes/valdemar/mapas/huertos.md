# Huertos del Molino · `valdemar.huertos`

Al oeste del pueblo. Trigales quemados por los goblins, granjas arrasadas, el río Plata con dos puentes y, al noroeste, el molino en ruinas donde se ha hecho fuerte el Ogro. Misiones: `valdemar.molino` (Tomás), parte de `valdemar.pociones` (Iris).

- Tamaño: **56×36** casillas · tipo: **exterior de campo** · bioma: `valdemar`
- `AreaMap.level` (fuera de zonas): **5** · entrada por defecto (`entry`): **(53, 17)** · punto seguro (reaparición, M9): **(50, 17)**
- Generado y validado (filas iguales, borde cerrado salvo salidas, todo conectado desde la entrada, spawns pisables y dentro de su zona, ningún monstruo a menos de 7 casillas de una llegada).

## Salidas (`>`)

| Id | Casillas | Lleva a | Llega a (casilla) | Bloqueo |
|---|---|---|---|---|
| `huertos.este` | (55,16), (55,17), (55,18) | `town` | (2, 17) | — |
| `huertos.sur` | (11,35), (12,35), (13,35), (14,35) | `valdemar.robleda` | (9, 2) | — |

Llegadas a esta área: desde `town` → (53, 17), desde `valdemar.robleda` → (12, 33)

## Edificios (`Building`)

| Id | Nombre | Estilo | x, y, ancho, alto | Puerta (x, ancho) | Interior |
|---|---|---|---|---|---|
| `molino` | Molino en ruinas | `ruinedMill` (nuevo) | 6, 3, 6, 6 | 8, 1 | nil (cerrado) |
| `granja1` | Granja quemada | `burnedFarm` (nuevo) | 31, 4, 6, 5 | 33, 1 | nil (cerrado) |
| `granja2` | Granja quemada | `burnedFarm` (nuevo) | 43, 23, 6, 5 | 45, 1 | nil (cerrado) |

## Zonas (`Zone`)

| Id | Nombre | x, y, ancho, alto | Nivel |
|---|---|---|---|
| `valdemar.huertos.molino` | Molino en ruinas | 2, 2, 22, 13 | **6** |
| `valdemar.huertos.ribera` | Ribera del Plata | 2, 15, 22, 19 | **5** |
| `valdemar.huertos.trigales` | Trigales quemados | 27, 2, 27, 32 | **5** |

## Monstruos (`Spawn`)

Grupos: los que están a menos de 3,5 casillas se avisan entre sí (alerta de manada de 170 pt). **Reaparece** = monstruo de campo (M2); **permanente** = se guarda en `killedSpawns`.

| Id | Enemigo | Casilla | Zona (nivel) | Tipo | Nota |
|---|---|---|---|---|---|
| `valdemar.huertos.1` | `ogre` Ogro del molino | (9,11) | Molino en ruinas (6) | permanente | jefe: delante de la puerta del molino |
| `valdemar.huertos.2` | `mudGolem` Gólem de barro | (7,13) | Molino en ruinas (6) | reaparece | escolta del Ogro |
| `valdemar.huertos.3` | `skeleton` Esqueleto | (19,5) | Molino en ruinas (6) | reaparece |  |
| `valdemar.huertos.4` | `skeleton` Esqueleto | (21,7) | Molino en ruinas (6) | reaparece |  |
| `valdemar.huertos.5` | `plagueRat` Rata de la peste | (16,9) | Molino en ruinas (6) | reaparece |  |
| `valdemar.huertos.6` | `plagueRat` Rata de la peste | (18,10) | Molino en ruinas (6) | reaparece |  |
| `valdemar.huertos.7` | `slime` Limo verde | (9,25) | Ribera del Plata (5) | reaparece |  |
| `valdemar.huertos.8` | `slime` Limo verde | (4,21) | Ribera del Plata (5) | reaparece |  |
| `valdemar.huertos.9` | `skeleton` Esqueleto | (18,21) | Ribera del Plata (5) | reaparece | entre las tumbas |
| `valdemar.huertos.10` | `skeleton` Esqueleto | (20,22) | Ribera del Plata (5) | reaparece |  |
| `valdemar.huertos.11` | `crow` Cuervo carroñero | (19,31) | Ribera del Plata (5) | reaparece |  |
| `valdemar.huertos.12` | `plagueRat` Rata de la peste | (5,32) | Ribera del Plata (5) | reaparece |  |
| `valdemar.huertos.13` | `zombieFarmer` Granjero zombi | (34,11) | Trigales quemados (5) | reaparece |  |
| `valdemar.huertos.14` | `zombieFarmer` Granjero zombi | (37,12) | Trigales quemados (5) | reaparece |  |
| `valdemar.huertos.15` | `boar` Jabalí | (45,6) | Trigales quemados (5) | reaparece |  |
| `valdemar.huertos.16` | `goblinBomber` Goblin bombardero | (44,12) | Trigales quemados (5) | reaparece | quema el trigal |
| `valdemar.huertos.17` | `crow` Cuervo carroñero | (29,13) | Trigales quemados (5) | reaparece |  |
| `valdemar.huertos.18` | `zombieFarmer` Granjero zombi | (40,26) | Trigales quemados (5) | reaparece |  |
| `valdemar.huertos.19` | `zombieFarmer` Granjero zombi | (39,29) | Trigales quemados (5) | reaparece |  |
| `valdemar.huertos.20` | `mudGolem` Gólem de barro | (49,31) | Trigales quemados (5) | reaparece |  |
| `valdemar.huertos.21` | `boar` Jabalí | (31,24) | Trigales quemados (5) | reaparece | en el trigal sur |

## Mapa (filas listas para `rows:` del código)

```
TTTTTTTTTTTTTTTTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TT......................~~~.............fffffffffff...TT
TT......................~~~..T.........f%%%%%%%%%%%f..TT
TT...........cc....R....~~~............f%%%%%%%%%%%f..TT
TT...........c..........~~~............f%%%%%%%%%%%f..TT
TT......................~~~............f%%%%%%%%%%%f..TT
TT......................~~~............f%%%%%%%%%%%...TT
TT......................~~~............f%%%%%%%%%%%...TT
TT..........ddd%%%%%....~~~...........cf%%%%%%%%%%%...TT
TT.R........ddd%%%%%....~~~............f%%%%%%%%%%%...TT
TT..........ddd.....R...~~~...T........f%%%%%%%%%%%...TT
TT..........ddd.........~~~.......................x...TT
TT..........ddd..b......~~~...........................TT
TT..........ddd.........~~~....................b......TT
TT..........ddd.........~~~...........................TT
TT..........ddddddddddddpppdddddddddddddddddddddddddddd>
TT..........ddddddddddddpppdddddddddddddddddddddddddddd>
TT..........ddddddddddddpppdddddddddddddddddddddddddddd>
TT......T..dddd......,..~~~......ddd..................TT
TT.........dddd.f+.+.+f.~~~ffffffddd..................TT
TT.........dddd.f.....f.~~~.%%%%%ddd................T.TT
TT.........dddd.f+.+.+f.~~~.%%%%%ddd..................TT
TT.,.....,.dddd.........~~~.%%%%%ddd..................TT
TT...~~~...dddd.........~~~.%%%%%ddd..................TT
TT..~~~~~..dddd.......,.~~~.%%%%%ddd..................TT
TT.~~~~~~~.dddd.........~~~.%%%%%ddd..................TT
TT..~~~~~..dddddddddddddpppd%%%%%ddd..................TT
TT...~~~...dddddddddddddpppd%%%%%ddd..................TT
TT..,.....,dddddddddddddpppd%%%%%ddd..................TT
TT.........dddd...T.....~~~.%%%%%...%%%%%%..........T.TT
TT....,....dddd.....,...~~~.........%%%%%%............TT
TT.........dddd.........~~~.........%%%%R%............TT
TT.b.......dddd.......b.~~~...........................TT
TTTTTTTTTTTddddTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTT>>>>TTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

## Mapa anotado (solo para leer: `H` edificio, `u` su puerta, `@` monstruo, `&` jefe, `!` NPC/objeto, `*` punto seguro)

```
TTTTTTTTTTTTTTTTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TT......................~~~.............fffffffffff...TT
TT....HHHHHH............~~~..T.........f%%%%%%%%%%%f..TT
TT....HHHHHH.cc....R....~~~....HHHHHH..f%%%%%%%%%%%f..TT
TT....HHHHHH.c.....@....~~~....HHHHHH..f%%%%%%%%%%%f..TT
TT....HHHHHH............~~~....HHHHHH..f%%%%%@%%%%%f..TT
TT....HHHHHH.........@..~~~....HHHHHH..f%%%%%%%%%%%...TT
TT....HHuHHH............~~~....HHuHHH..f%%%%%%%%%%%...TT
TT..........ddd%@%%%....~~~...........cf%%%%%%%%%%%...TT
TT.R........ddd%%%@%....~~~............f%%%%%%%%%%%...TT
TT.......&..ddd.....R...~~~...T...@....f%%%%%%%%%%%...TT
TT..........ddd.........~~~..........@......@.....x...TT
TT.....@....ddd..b......~~~..@........................TT
TT..........ddd.........~~~....................b......TT
TT..........ddd.........~~~...........................TT
TT..........ddddddddddddpppdddddddddddddddddddddddddddd>
TT..........ddddddddddddpppddddddddddddddddddddddd*dddd>
TT..........ddddddddddddpppdddddddddddddddddddddddddddd>
TT......T..dddd......,..~~~......ddd..................TT
TT.........dddd.f+.+.+f.~~~ffffffddd..................TT
TT..@......dddd.f.@...f.~~~.%%%%%ddd................T.TT
TT.........dddd.f+.+@+f.~~~.%%%%%ddd..................TT
TT.,.....,.dddd.........~~~.%%%%%ddd.......HHHHHH.....TT
TT...~~~...dddd.........~~~.%%%@%ddd.......HHHHHH.....TT
TT..~~~~~@.dddd.......,.~~~.%%%%%ddd.......HHHHHH.....TT
TT.~~~~~~~.dddd.........~~~.%%%%%ddd....@..HHHHHH.....TT
TT..~~~~~..dddddddddddddpppd%%%%%ddd.......HHuHHH.....TT
TT...~~~...dddddddddddddpppd%%%%%ddd..................TT
TT..,.....,dddddddddddddpppd%%%%%ddd...@..............TT
TT.........dddd...T.....~~~.%%%%%...%%%%%%..........T.TT
TT....,....dddd....@,...~~~.........%%%%%%.......@....TT
TT...@.....dddd.........~~~.........%%%%R%............TT
TT.b.......dddd.......b.~~~...........................TT
TTTTTTTTTTTddddTTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTT>>>>TTTTTTTTT~~~TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

Caracteres usados: `%` hierba alta / trigal / maleza · `+` lápida / tótem · `,` flores · `.` hierba · `>` salida a otra área · `R` roca · `T` árbol · `b` arbusto · `c` cajas · `d` camino de tierra · `f` valla / empalizada · `p` puente · `x` hoguera / brasero · `~` agua
