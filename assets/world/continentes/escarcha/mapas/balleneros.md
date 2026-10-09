# Costa de los Balleneros (`escarcha.balleneros`) — 40-42

Borrador **ligero** (fase futura). Tamaño real: **56×36** casillas.
Boceto a **escala 1:2** (1 carácter = 2×2 casillas; el `map-designer` lo pasa a 1:1 con caminos de 3+ casillas).

```
^^^^^^^^^^^^>>>>^^^^^^^^^^^^
~~~^^^TT....dddd....TTT^^^^^
~~~~^^T.....dd.......TT..^^^
~~~~~,,.....dd...R.....3.*.^
~~~~~,,.....dd..RR.........^
~~~~RR,,....dd.......T.....^
~~~~RR,2....ddddddd........^
~~~~~~,,,.......ddd...RR...^
~~~~~,,,,...+.....dd.......T
~~~~RR,,,..+++....dd.......T
~~~~RR,,,.........ddddddddd>
~~~~~,,,,.x..+....1........>
~~~~~~,,,.....+++.....T....T
~~~~~~~,,,.................T
~~~~~~~~,,,,..R....R....TTTT
~~~~~~~~~~,,,,,,,..........T
~~~~~~~~~~~~~~~,,,,,,,,,TTTT
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

Leyenda del boceto (exterior, bioma nieve): `.` nieve · `,` hielo pisable / nieve pisada · `d` sendero ·
`p` puente · `S` escalinata · `T` pino nevado · `R` bloque de hielo o roca · `^` acantilado / pared de glaciar ·
`~` agua helada o abismo · `+` huesos, estela, tótem o esquirla (decorado sólido) · `n` tienda · `x` hoguera
(punto de reaparición) · `e` bajada a mazmorra de historia (`DungeonEntrance`) · `H` huella de edificio (`|` = puerta) · `*` pista (`.clue`) · `>` salida a otra área · `w` muralla ·
`B` jefe de campo · `1`-`3` centro aproximado de cada zona de nivel.

- **1 · Playa de los Huesos (40)**: costillares de ballena `+`, hoguera de los balleneros `x` (reaparición).
  `frostWolf` ×5, `drownedWhaler` ×3.
- **2 · Pecios helados (41)**: barcos atrapados en el hielo (`RR` = casco de 4×4 casillas). `drownedWhaler` ×3,
  `iceBear` ×2, `frostWolf` ×1.
- **3 · Acantilados del Arpón (42)**: `iceBear` ×2, manada de 3 `frostWolf`. `*` = **cráter pequeño** con la esquirla:
  NPC de pista `esquirlaCaida` (`.clue`, en (50, 6)) de `escarcha.esquirla_perdida`; el cráter es decorado pisable
  con brillo cian y la esquirla, un `+` al lado.
- Salidas: `balleneros.este` (55, 20-23) → Hielomar; `balleneros.norte` (24-31, 0) → Tundra (ver `zonas.md` §3).
- Sendero en Y para que haya dos rutas (playa o acantilados) entre Hielomar y la Tundra.
