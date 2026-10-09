# Abadía de Valsombra · `valdemar.abadia`

Al este del pueblo. Cementerio vallado, claustro en ruinas con la iglesia atrancada y la bajada `ee` a la Cripta (mazmorra de historia, piso `crypt`), y el huerto de los monjes con un campamento del Eclipse. Misión: `valdemar.abadia` (Fray Anselmo) y parte de `valdemar.pociones`.

- Tamaño: **56×38** casillas · tipo: **exterior de campo** · bioma: `valdemar`
- `AreaMap.level` (fuera de zonas): **7** · entrada por defecto (`entry`): **(2, 17)** · punto seguro (reaparición, M9): **(4, 17)**
- Generado y validado (filas iguales, borde cerrado salvo salidas, todo conectado desde la entrada, spawns pisables y dentro de su zona, ningún monstruo a menos de 7 casillas de una llegada).

## Salidas (`>`)

| Id | Casillas | Lleva a | Llega a (casilla) | Bloqueo |
|---|---|---|---|---|
| `abadia.oeste` | (0,16), (0,17), (0,18) | `town` | (41, 17) | — |
| `abadia.sur` | (31,37), (32,37), (33,37) | `valdemar.pedregal` | (31, 2) | — |

Llegadas a esta área: desde `town` → (2, 17), desde `valdemar.pedregal` → (32, 35)

## Edificios (`Building`)

| Id | Nombre | Estilo | x, y, ancho, alto | Puerta (x, ancho) | Interior |
|---|---|---|---|---|---|
| `iglesia` | Iglesia de la abadía | `abbeyChurch` (nuevo) | 36, 4, 12, 6 | 41, 2 | nil (cerrado) |

## Zonas (`Zone`)

| Id | Nombre | x, y, ancho, alto | Nivel |
|---|---|---|---|
| `valdemar.abadia.cementerio` | Cementerio de Valsombra | 2, 2, 28, 21 | **7** |
| `valdemar.abadia.claustro` | Claustro en ruinas | 30, 2, 24, 21 | **8** |
| `valdemar.abadia.huerto` | Huerto de los monjes | 2, 23, 52, 13 | **7** |

## Monstruos (`Spawn`)

Grupos: los que están a menos de 3,5 casillas se avisan entre sí (alerta de manada de 170 pt). **Reaparece** = monstruo de campo (M2); **permanente** = se guarda en `killedSpawns`.

| Id | Enemigo | Casilla | Zona (nivel) | Tipo | Nota |
|---|---|---|---|---|---|
| `valdemar.abadia.1` | `skeleton` Esqueleto | (9,6) | Cementerio de Valsombra (7) | reaparece |  |
| `valdemar.abadia.2` | `skeleton` Esqueleto | (12,7) | Cementerio de Valsombra (7) | reaparece |  |
| `valdemar.abadia.3` | `skeletonArcher` Esqueleto arquero | (21,6) | Cementerio de Valsombra (7) | reaparece |  |
| `valdemar.abadia.4` | `ghoul` Necrófago | (19,9) | Cementerio de Valsombra (7) | reaparece |  |
| `valdemar.abadia.5` | `ghoul` Necrófago | (10,10) | Cementerio de Valsombra (7) | reaparece |  |
| `valdemar.abadia.6` | `skeleton` Esqueleto | (22,12) | Cementerio de Valsombra (7) | reaparece |  |
| `valdemar.abadia.7` | `gargoyle` Gárgola | (34,13) | Claustro en ruinas (8) | reaparece |  |
| `valdemar.abadia.8` | `blackKnight` Caballero negro | (36,15) | Claustro en ruinas (8) | reaparece |  |
| `valdemar.abadia.9` | `necromancer` Nigromante | (46,13) | Claustro en ruinas (8) | reaparece |  |
| `valdemar.abadia.10` | `wraith` Espectro | (48,15) | Claustro en ruinas (8) | reaparece |  |
| `valdemar.abadia.11` | `blackKnight` Caballero negro | (44,18) | Claustro en ruinas (8) | reaparece |  |
| `valdemar.abadia.12` | `gargoyle` Gárgola | (50,8) | Claustro en ruinas (8) | reaparece |  |
| `valdemar.abadia.13` | `eclipseAcolyte` Acólito del Eclipse (NUEVO) | (38,20) | Claustro en ruinas (8) | reaparece | guarda la bajada a la cripta |
| `valdemar.abadia.14` | `cultist` Cultista | (10,29) | Huerto de los monjes (7) | reaparece |  |
| `valdemar.abadia.15` | `eclipseAcolyte` Acólito del Eclipse (NUEVO) | (13,31) | Huerto de los monjes (7) | reaparece |  |
| `valdemar.abadia.16` | `cultist` Cultista | (15,29) | Huerto de los monjes (7) | reaparece |  |
| `valdemar.abadia.17` | `wraith` Espectro | (40,28) | Huerto de los monjes (7) | reaparece |  |
| `valdemar.abadia.18` | `wraith` Espectro | (42,31) | Huerto de los monjes (7) | reaparece |  |
| `valdemar.abadia.19` | `fireSlime` Limo de fuego | (22,25) | Huerto de los monjes (7) | reaparece |  |
| `valdemar.abadia.20` | `fireSlime` Limo de fuego | (50,26) | Huerto de los monjes (7) | reaparece |  |

## Mapa (filas listas para `rows:` del código)

```
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TT....................................................TT
TT...fffffffffffffffffffff....wwwwwwwwwwwwwwwwwwwwwww.TT
TT...f...................f...Tw.....................w.TT
TT..Tf..+..+.....+..+..+.f....w.R...................w.TT
TT...f........T..........f....w...................R.w.TT
TT...f........................w.....................w.TT
TT...f..+..+.....+..+..+......w.....................w.TT
TT...f......................T.w.......................TT
TT...f...................f....w.......................TT
TT...f..+..+.....+..+..+.f....w..I===I===I===I===I..w.TT
TT.T.f...................f....w..=================..w.TT
TT...ffffffffdddffffffffff....w..=================..w.TT
TT...........ddd..............w..=================..w.TT
TT.T.........ddd..............w..=======ee========..w.TT
>dddddddddddddddddddddddddddddddd=================..w.TT
>dddddddddddddddddddddddddddddddd=================..w.TT
>dddddddddddddddddddddddddddddddd=================..w.TT
TT............................w..I===I===I===I===I..w.TT
TT............................w.....................w.TT
TT..x......T..................w.c...................w.TT
TT.................T..........wdddwwwwwwwwwww...wwwww.TT
TT........................T..T.ddd....................TT
TT..%%%%%%%%%%%%%%%%%%%%.......ddd.T.....T........T...TT
TT..%%%%%%%%%%%%%%%%%%%%.......ddd....................TT
TT..%%%%%%%%%%%%%%%%%%%%.......ddd.........~~~........TT
TT........T....................ddd........~~~~~.......TT
TT...............T.............ddd....T..T.~~~........TT
TT....................+..T.....ddd....................TT
TT.......n...n.................ddd..............T.....TT
TT.......T.....................ddd..%%%%%%%%%%%%%%....TT
TT.........x...................ddd..%%%%%%%%%%%%%%....TT
TT............c...T......+.....ddd..%%%%%%%%%%%%%%....TT
TT......T..T.................T.ddd....................TT
TT.............................ddd....................TT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTdddTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT>>>TTTTTTTTTTTTTTTTTTTTTT
```

## Mapa anotado (solo para leer: `H` edificio, `u` su puerta, `@` monstruo, `&` jefe, `!` NPC/objeto, `*` punto seguro)

```
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TT....................................................TT
TT...fffffffffffffffffffff....wwwwwwwwwwwwwwwwwwwwwww.TT
TT...f...................f...Tw.....HHHHHHHHHHHH....w.TT
TT..Tf..+..+.....+..+..+.f....w.R...HHHHHHHHHHHH....w.TT
TT...f...@....T......@...f....w.....HHHHHHHHHHHH..R.w.TT
TT...f......@.................w.....HHHHHHHHHHHH....w.TT
TT...f..+..+.....+..+..+......w.....HHHHHHHHHHHH..@.w.TT
TT...f.............@........T.w.....HHHHHuuHHHHH......TT
TT...f....@..............f....w.......................TT
TT...f..+..+.....+..+..+.f....w..I===I===I===I===I..w.TT
TT.T.f................@..f....w..=================..w.TT
TT...ffffffffdddffffffffff....w..=@===========@===..w.TT
TT...........ddd..............w..=================..w.TT
TT.T.........ddd..............w..===@===ee======@=..w.TT
>dddddddddddddddddddddddddddddddd=================..w.TT
>ddd*dddddddddddddddddddddddddddd=================..w.TT
>dddddddddddddddddddddddddddddddd===========@=====..w.TT
TT............................w..I===I===I===I===I..w.TT
TT............................w.......@.............w.TT
TT..x......T..................w.c...................w.TT
TT.................T..........wdddwwwwwwwwwww...wwwww.TT
TT........................T..T.ddd....................TT
TT..%%%%%%%%%%%%%%%%%%%%.......ddd.T.....T........T...TT
TT..%%%%%%%%%%%%%%%%%%@%.......ddd....................TT
TT..%%%%%%%%%%%%%%%%%%%%.......ddd.........~~~....@...TT
TT........T....................ddd........~~~~~.......TT
TT...............T.............ddd....T.@T.~~~........TT
TT........@....@......+..T.....ddd....................TT
TT.......n...n.................ddd..............T.....TT
TT.......T...@.................ddd..%%%%%%@%%%%%%%....TT
TT.........x...................ddd..%%%%%%%%%%%%%%....TT
TT............c...T......+.....ddd..%%%%%%%%%%%%%%....TT
TT......T..T.................T.ddd....................TT
TT.............................ddd....................TT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTdddTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT>>>TTTTTTTTTTTTTTTTTTTTTT
```

Caracteres usados: `%` hierba alta / trigal / maleza · `+` lápida / tótem · `.` hierba · `=` losas (claustro) · `>` salida a otra área · `I` columna · `R` roca · `T` árbol · `c` cajas · `d` camino de tierra · `e` bajada a la cripta (mazmorra) · `f` valla / empalizada · `n` tienda · `w` muro en ruinas · `x` hoguera / brasero · `~` agua
