# Pastos Altos (`rocaforja.pastos`) — zona 1, niveles 10-12 (boceto)

52×34, 1 304 pisables, todo conectado. Bienvenida del continente: pradera alpina entre la cordillera y el Paso del
Norte. **Bioma `rocaforjaMeadow`**: `.` hierba alpina corta con piedras · `%` hierba alta y flores de montaña ·
`d` sendero de tierra · `~` río de deshielo (agua clara y fría) · `p` puente de tablas · `T` pino · `R` peñasco ·
`^` pared de montaña / acantilado · `+` estela de los Thanes (a los lados de la Gran Puerta) · `n` tienda kóbold ·
`x` hoguera · `c` cajas robadas · `f` valla · `1` casa de Greta (`rocaforja.pastos.corral`, puerta en (6, 22)).

```
     0         1         2         3         4         5 
     0123456789012345678901234567890123456789012345678901
  0  ^^^^^^^^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^^^^^^^^^^^
  1  ^^^^^^^^^^^^^^^^^^^^^^^......^^^^^^^^^^^^^^^^^^^^^^^
  2  ^^^^^^^^^^^^^^^^^^^^^^^......^^^^^^^^^^^^^^^^^^^^^^^
  3  ^^^^^^^^^^^^^^^^^^^^^^+......+^^^^^^^^^^^^^^^^^^^^^^
  4  ^.......................dddd.......................^
  5  ^.............RR........dddd.......................^
  6  ^.....RR....%.RR........dddd..........n....n.......^
  7  ^.....RR................dddd.......................^
  8  ^..%%............%......dddddddddddddd...x.........^
  9  ^....%....R.......%.....ddddddddddddddc.......n....^
 10  ^.......................dddd.......................^
 11  ^.......................dddd.......................^
 12  ^~~~~~ppp~~~~~~~~~~~~~~ppppp~~~~~~~~~~~~~~~~~~~~~~~^
 13  ^~~~~~ppp~~~~~~~~~~~~~~ppppp~~~~~~~~~~~~~~~~~~~~~~~^
 14  ^.......................dddd.......................^
 15  ^.......................dddd.......................^
 16  ^.......................ddddddddddddddddddddddddddd>
 17  ^.......................ddddddddddddddddddddddddddd>
 18  ^...............RR......ddddddddddddddddddddddddddd>
 19  ^...111111......RR......dddd.......................^
 20  ^...111111..............dddd.......................^
 21  ^...111111dddddddddddddddddd........T.....T........^
 22  ^...111111dddddddddddddddddd.....T...........T.....^
 23  ^.......................dddd...........T...........^
 24  ^.......................dddd....................T..^
 25  ^..ffffffffffff.........dddd.......................^
 26  ^..f..........f.....%%..dddd......T.......T........^
 27  ^..f....................dddd..........T............^
 28  ^..f............%%......dddd..................T....^
 29  ^..f..........f...%%....dddd.......................^
 30  ^..ffffffffffff.........dddd....RR.T....T.......T..^
 31  ^...............%.....x.dddd....RR..........T......^
 32  ^.......................dddd.......................^
 33  ^^^^^^^^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^^^^^^^^^^^
```

## Salidas

| Salida | Casillas | Lleva a | Llegada aquí |
|---|---|---|---|
| Sur (Paso del Norte) | (24-27, 33) | `valdemar.paso` | (25, 32) |
| Norte (Gran Puerta) | (24-27, 0) | `rocaforja.hondoyunque` (27, 31) | (25, 5) |
| Este | (51, 16-18) | `rocaforja.canteras` (1, 16) | (49, 17) |

## Subzonas y spawns (posición aproximada; el `character-designer` los fija)

| Subzona | Nivel | Dónde | Monstruos |
|---|---|---|---|
| Prado del Paso | 10 | sur, filas 23-32 | `rocaforja.pastos.1-3` 3 `mountainGoat` (30-45, 24-31) · `rocaforja.pastos.4-5` 2 `kobold` (16-20, 27-31) |
| Corrales de Greta | 10-11 | oeste, filas 14-31 | `rocaforja.pastos.6-8` 3 `kobold` (5-12, 15-18) · `rocaforja.pastos.9-10` 2 `koboldCandle` (16-20, 15-19) |
| Prado alto | 11 | noroeste, filas 4-11 | `rocaforja.pastos.11-12` 2 `mountainGoat` (5-18, 5-10) · `rocaforja.pastos.13` 1 `koboldCandle` (12, 8) |
| Campamento kóbold | 11-12 | noreste, filas 4-11 | `rocaforja.pastos.14` 1 `kobold` (40, 7) (con los 3 `n` y la hoguera) |
| Pinar de los osos | 12 | este, filas 20-32 | `rocaforja.pastos.15-17` 3 `cliffBear` (36-48, 22-31) |

NPC: **Greta** (8, 23) delante de su casa; **Brokk** (11, 24) hasta `rocaforja.prueba_del_thane`. Punto seguro: (22, 30), junto a la
hoguera.

> Ids de salida, bloqueos (`ExitLock`) y avisos definitivos: `../zonas.md` §2. Ids de zona: `rocaforja.<área>.<zona>` (§3).
