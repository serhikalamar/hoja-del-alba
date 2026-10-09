# Trono de los Gigantes (`escarcha.gigantes`) — 46-48

Borrador **ligero** (fase futura). Tamaño real: **60×40** casillas.
Boceto a **escala 1:2** (1 carácter = 2×2 casillas; el `map-designer` lo pasa a 1:1 con caminos de 3+ casillas).

```
^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^
^^^^^^^^^^^^.dd.^^^^^^^^^^^^^^
^^^.........dddd.........^^^^^
^^....+..3.......+..H|....^^^^
^^.....RR.........RR......^^^^
^^^^^^^^^^SSSSSS^^^^^^^^^^^^^^
^^^.....x.......+........^^^^^
^^....+....n..n.....+.....^^^^
^^..........2..............^^^
^^....RR..........RR.......^^^
^^^^^^^^^^^SSSSSS^^^^^^^^^^^^^
^^^..........dd............^^^
^^......T....dd....+.......^^^
^^.........1.dd.............^^
^^....+......dd......T......^^
>dd..........dd.............^^
>dd..........dd.......RR....^^
^^...T.......dd.............^^
^^TTT........dd..........TTT^^
^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^
```

Leyenda del boceto (exterior, bioma nieve): `.` nieve · `,` hielo pisable / nieve pisada · `d` sendero ·
`p` puente · `S` escalinata · `T` pino nevado · `R` bloque de hielo o roca · `^` acantilado / pared de glaciar ·
`~` agua helada o abismo · `+` huesos, estela, tótem o esquirla (decorado sólido) · `n` tienda · `x` hoguera
(punto de reaparición) · `e` bajada a mazmorra de historia (`DungeonEntrance`) · `H` huella de edificio (`|` = puerta) · `*` pista (`.clue`) · `>` salida a otra área · `w` muralla ·
`B` jefe de campo · `1`-`3` centro aproximado de cada zona de nivel.

Tres **terrazas** separadas por paredes de roca `^` y unidas por escalinatas gigantes `S` (6 casillas de ancho
en 1:1 → 12 casillas; se ven desde lejos).
- **1 · Escalones de los Gigantes (46)**: terraza baja. `frostGiant` ×2 (élite), `yeti` ×2, `frostWolf` ×2.
- **2 · Campamento de Hrimgar (47)**: menhires rúnicos `+`, tiendas de piel `n`, hoguera azul `x` (reaparición).
  `frostGiant` ×2, `runeGiant` ×3.
- **3 · Puerta del Trono (48)**: terraza alta. `runeGiant` ×2, `frostGiant` ×1, `mammoth` ×2.
  `H|` = **salón del trono** (edificio estilo `giantHall`, puerta en (42, 6) → interior `escarcha.gigantes.trono`;
  cerrado hasta `escarcha.juramento`).
- Salidas: `gigantes.sur` (26-33, 39) → Tundra; `gigantes.oeste` (0, 30-33) → Cráter; `gigantes.norte` (26-33, 0)
  → Murallas (cerrada hasta `escarcha.trono_gigantes`).
- Cada escalinata tiene 12 casillas de ancho: los gigantes (escala 1,7) caben y se puede esquivar.

**Salón del trono** (`escarcha.gigantes.trono`, interior nivel 48, 20×12, 1:1): columnas `I` gigantes, trono `YY`,
hogueras `k`. 2 `frostGiant` + `B` = Jarl Hrimgar.
```
XXXXXXXXXXXXXXXXXXXX
X:::::::::YY:::::::X
X::I:::::::::::I:::X
X::::::::B:::::::::X
X:::k:::::::::::k::X
X::::::::::::::::::X
X::I:::::::::::I:::X
X::::::::::::::::::X
X:::k:::::::::::k::X
X::::::::::::::::::X
X::::::::::::::::::X
XXXXXXXXXDDXXXXXXXXX
```
