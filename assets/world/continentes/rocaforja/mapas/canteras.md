# Canteras de Cobalto (`rocaforja.canteras`) — zona 2, niveles 12-14 (boceto)

52×34, 1 430 pisables, todo conectado. Cantera a cielo abierto en terrazas, con el campamento del jefe kóbold
arriba y la boca de las Minas profundas abajo. **Bioma `rocaforjaQuarry`**: `.` roca gris con vetas azules ·
`d` camino de cantera (grava) · `^` cara de la terraza / pared de roca · `S` rampa tallada · `~` poza de agua
estancada · `R` bloque de piedra cortado · `c` vagoneta / cajas de cobalto · `l` farol · `n` tienda kóbold ·
`x` brasero · `e` boca de la mina (con puntales) · `1` cobertizo de Odila (`rocaforja.canteras.cobertizo`, puerta en (7, 12)).

```
     0         1         2         3         4         5 
     0123456789012345678901234567890123456789012345678901
  0  ^^^^^^^^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^^^^^^^^^^^
  1  ^.......................dddd.......................^
  2  ^.......................dddd.....n......n...x..n...^
  3  ^.......................dddd.......................^
  4  ^.......................dddd...^^^^^SSS^^^^^^......^
  5  >ddddddddddddddddddddddddddd...^^^^^SSS^^^^^^......^
  6  >ddddddddddddddddddddddddddd.......................^
  7  >ddddddddddddddddddddddddddd.....RR...........c....^
  8  ^.......................dddd.....RR...........c....^
  9  ^...1111111.............dddd.......................^
 10  ^...1111111.cc..........dddd...^^^^^^^^^^SSS^^^....^
 11  ^...1111111.c...........dddd...^^^^^^^^^^SSS^^^....^
 12  ^...1111111.............dddd.......................^
 13  ^.......................dddd..............RR...c...^
 14  ^..........l......l.....dddd..............RR.......^
 15  >ddddddddddddddddddddddddddd.......................^
 16  >ddddddddddddddddddddddddddd...^^^SSS^^^^^^^^......^
 17  >ddddddddddddddddddddddddddd...^^^SSS^^^^^^^^......^
 18  ^.......................dddd.......................^
 19  ^...ccc.................dddd.......................^
 20  ^.......................dddd.......................^
 21  ^.......................dddd.......................^
 22  ^............RR.........dddd.......................^
 23  ^............RR.........dddd.......................^
 24  ^....~~~~~~........RR...dddd.......................^
 25  ^....~~~~~~........RR...dddd.......................^
 26  ^....~~~~~~.............ddddddddddddddddddddddddddd>
 27  ^.......................ddddddddddddddddddddddddddd>
 28  ^..............~~~~~....ddddddddddddddddddddddddddd>
 29  ^..............~~~~~....dddd.........x^^ee^^x......^
 30  ^.....RR................dddd..........^^^^^^.......^
 31  ^.....................................^^^^^^.......^
 32  ^.....................................^^^^^^.......^
 33  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## Salidas

| Salida | Casillas | Lleva a | Llegada aquí |
|---|---|---|---|
| Oeste | (0, 15-17) | `rocaforja.pastos` (49, 17) | (1, 16) |
| Noroeste (galería de vagonetas) | (0, 5-7) | `rocaforja.hondoyunque` (2, 21) | (2, 6). Cerrada hasta `rocaforja.prueba_del_thane` |
| Norte | (24-27, 0) | `rocaforja.cumbres` (23, 34) | (25, 2) |
| Este | (51, 26-28) | `rocaforja.escoriales` (1, 27) | (49, 27). Derrumbe hasta `rocaforja.minas_profundas` |
| `e` Minas profundas | (40-41, 29) | Mazmorra piso `mine` | (40, 28) al salir |

## Subzonas y spawns

| Subzona | Nivel | Dónde | Monstruos |
|---|---|---|---|
| Patio de carga | 12 | oeste, filas 1-21 | `rocaforja.canteras.1-4` 4 `kobold` (3-20, 2-20) · `rocaforja.canteras.5-7` 3 `koboldCandle` (10-14, 18-21) |
| Gradas de cobalto | 13 | centro-este, filas 4-25 | `rocaforja.canteras.8-11` 4 `koboldGeomancer` (en lo alto de cada terraza: (40,7), (35,13), (46,13), (40,19)) |
| Madriguera troglodita | 13-14 | sur, filas 21-32 | `rocaforja.canteras.12-16` 5 `trogg` (3-22, 22-32) · `rocaforja.canteras.17-18` 2 `troggBrute` (8, 28) y (30, 31) |
| Campamento de Mechacorta | 13 | norte-este, filas 1-3 | **`koboldChief`** (37, 2), no reaparece; 2 `koboldCandle` de escolta (reaparecen, como todo lo que no es jefe en el campo) |

NPC: **Odila** (8, 14) delante del cobertizo. Punto seguro: (15, 14), entre las farolas del patio.

> Ids de salida, bloqueos (`ExitLock`) y avisos definitivos: `../zonas.md` §2. Ids de zona: `rocaforja.<área>.<zona>` (§3).
