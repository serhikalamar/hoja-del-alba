# Tundra Aullante (`escarcha.tundra`) — 42-44

Borrador **ligero** (fase futura). Tamaño real: **64×40** casillas.
Boceto a **escala 1:2** (1 carácter = 2×2 casillas; el `map-designer` lo pasa a 1:1 con caminos de 3+ casillas).

```
^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^
^^TTT.........dddd.......TTT..^^
^TT...........dd..........HH3.^^
^T....R.......dd......+++..H|.^^
^.............dd.....+..+.....^^
^......T......dd.........R....^^
^..n.n........dd..............^^
^.x....2.....dddd.......T.....^^
^..n..........dd..............^^
^.............dd..........ddddd>
^...T.....R...dd......dddd....d>
^.............ddddddddd.......d>
^.......1.........dd..........^^
^.....T...........dd....R.....^^
^...............T.dd..........^^
^.........R.......dd..........^^
^TT...............dd.......TTT^^
^TTT..............dd......TTTT^^
^TTTT............dddd....TTTTT^^
^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^
```

Leyenda del boceto (exterior, bioma nieve): `.` nieve · `,` hielo pisable / nieve pisada · `d` sendero ·
`p` puente · `S` escalinata · `T` pino nevado · `R` bloque de hielo o roca · `^` acantilado / pared de glaciar ·
`~` agua helada o abismo · `+` huesos, estela, tótem o esquirla (decorado sólido) · `n` tienda · `x` hoguera
(punto de reaparición) · `e` bajada a mazmorra de historia (`DungeonEntrance`) · `H` huella de edificio (`|` = puerta) · `*` pista (`.clue`) · `>` salida a otra área · `w` muralla ·
`B` jefe de campo · `1`-`3` centro aproximado de cada zona de nivel.

- **1 · Llanura Aullante (42)**: gran claro abierto, ventisca. `yeti` ×4, `frostWolf` ×3.
- **2 · Campamento de tramperos (43)**: tiendas `n` rotas y la hoguera `x` (reaparición; objetivo "llegar" de
  `escarcha.caravana`). `wendigo` ×4, `yeti` ×2.
- **3 · Paso de los Mamuts (44)**: huesos y colmillos `+`. `mammoth` ×3 (élite), `yeti` ×2, `wendigo` ×2.
  `HH`/`|` = boca de la **cueva del Abuelo Ventisca** (edificio estilo `iceCave`, puerta en (56, 6) → interior
  `escarcha.tundra.cueva`; cerrada hasta `escarcha.ventisca`). No es una `e`: las `e` son solo para mazmorras.
- Salidas: `tundra.sur` (34-41, 39) → Costa; `tundra.este` (63, 18-23) → Cráter; `tundra.norte` (28-35, 0) → Gigantes.

**Cueva del Abuelo Ventisca** (`escarcha.tundra.cueva`, interior nivel 43, 16×10, boceto a escala 1:1;
`X` pared de hielo, `:` suelo de piedra helada, `o` montón de huesos, `D` salida):
```
XXXXXXXXXXXXXXXX
X::::::::::::::X
X::o:::::::::o:X
X::::::B:::::::X
X::::::::::::::X
X:::::::::::::oX
X:o::::::::::::X
X::::::::::::::X
X::::::::::::::X
XXXXXXXDDXXXXXXX
```
4 `yeti` alrededor; `B` = Abuelo Ventisca.
