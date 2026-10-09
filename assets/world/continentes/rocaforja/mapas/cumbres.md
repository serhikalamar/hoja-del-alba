# Cumbres del Águila (`rocaforja.cumbres`) — zona 3, niveles 14-16 (boceto)

48×36, 1 367 pisables, todo conectado. Subida en zigzag por la nieve hasta el Nido del Roc. Aquí aparece el
Eclipse (ermita de los acólitos). **Bioma `rocaforjaSnow`**: `.` nieve · `d` sendero pisado en la nieve ·
`^` risco nevado · `~` lago helado (no se pisa) · `p` pasarela de tablas · `T` pino nevado · `R` roca con nieve ·
`+` estela rúnica (brilla cian si hay gólem cerca) · `n` tienda del Eclipse (ceniza sobre nieve) · `x` hoguera /
brasero negro · `1` atalaya de Thrain (`rocaforja.cumbres.atalaya`, puerta en (15, 32)).

```
     0         1         2         3         4       
     012345678901234567890123456789012345678901234567
  0  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  1  ^..............................^^^^^^^^^^^^^^^^^
  2  ^.....................................RR.......^
  3  ^..........................ddd...+..........+..^
  4  ^......+...................ddd.................^
  5  ^..+.......+...............ddd.................^
  6  ^..........................ddd.................^
  7  ^.....RR...................ddd.................^
  8  ^.....RR...................dddddddddddddddddddd>
  9  ^..........................dddddddddddddddddddd>
 10  ^..+.......+...............dddddddddddddddddddd>
 11  ^......+.....^^^^^^^^^^^^..ddd.................^
 12  ^............^^^^^^^^^^^^..ddd..^^^............^
 13  ^..........................ddd..^^^............^
 14  ^..........................ddd..^^^.~~~~ppp~~~.^
 15  ^.......dddddddddddddddddddddd..^^^.~~~~ppp~~~.^
 16  ^.......dddddddddddddddddddddd..^^^.~~~~ppp~~~.^
 17  ^.......dddddddddddddddddddddd..^^^............^
 18  ^..n....ddd.....................^^^............^
 19  ^.......ddd.....................^^^............^
 20  ^....x..ddd.^^^^^^^^^^^^^^^^^^^^^^^............^
 21  ^.......ddd.^^^^^^^^^^^^^^^^^^^^^^^............^
 22  ^..n....ddd.^^^^^^^^^^^^^^^^^^^^^^^............^
 23  ^.......ddd....................................^
 24  ^.......ddd.................T.........T........^
 25  ^.+.....ddd....................................^
 26  ^.......dddddddddddddddddd................T....^
 27  ^.......dddddddddddddddddd.........T...........^
 28  ^.......dddddddddddddddddd.....................^
 29  ^.T..........11111....dddd..........T..........^
 30  ^............11111....dddd....T................^
 31  ^...T........11111.x..dddd..................T..^
 32  ^............11111....dddd..............T......^
 33  ^.......T.............dddd.....................^
 34  ^.....................dddd.....................^
 35  ^^^^^^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^^^^^^^^^
```

## Salidas

| Salida | Casillas | Lleva a | Llegada aquí |
|---|---|---|---|
| Sur | (22-25, 35) | `rocaforja.canteras` (25, 2) | (23, 34) |
| Este (Paso de la Escoria) | (47, 8-10) | `rocaforja.escoriales` (1, 9) | (45, 9) |

## Subzonas y spawns

| Subzona | Nivel | Dónde | Monstruos |
|---|---|---|---|
| Ladera de la atalaya | 14 | sur, filas 23-34 | `rocaforja.cumbres.1-3` 3 `mountainGoat` (28-44, 24-33) · `rocaforja.cumbres.4-5` 2 `cliffEagle` (36-44, 26-31) |
| Círculo de estelas | 15 | noroeste, filas 2-12 | `rocaforja.cumbres.6-9` 4 `rockGolem` (2-12, 3-11) · `rocaforja.cumbres.10-13` 4 `earthElemental` (14-24, 3-10) |
| Ermita del Eclipse | 15 | oeste, filas 13-27 | `rocaforja.cumbres.14-16` 3 `emberAcolyte` (2-6, 17-24) |
| Paso alto | 15-16 | este, filas 11-22 | `rocaforja.cumbres.17-19` 3 `cliffEagle` (36-46, 11-21) |
| Nido del Roc | 16 | cima, filas 2-7 (31-46) | **`peakRoc`** (39, 4), no reaparece |

NPC: **Thrain** (16, 33) delante de la atalaya. Punto seguro: (20, 31), junto a la hoguera.

> Ids de salida, bloqueos (`ExitLock`) y avisos definitivos: `../zonas.md` §2. Ids de zona: `rocaforja.<área>.<zona>` (§3).
