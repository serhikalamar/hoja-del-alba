# Cráter de la Esquirla (`escarcha.crater`) — 44-46

Borrador **ligero** (fase futura). Tamaño real: **56×40** casillas.
Boceto a **escala 1:2** (1 carácter = 2×2 casillas; el `map-designer` lo pasa a 1:1 con caminos de 3+ casillas).

```
^^^^^^^^^^^^^^^^^^^>>>>^^^^^
^TT.......RRRRRR....dd...TT^
^T....RRRR,,,,,,RRRR.dd....^
^...RR,,,,,,2,,,,,,,RR.d...^
^..R,,,+,,,,,,,,,,,,,,R.d..^
^.R,,,,,,,,,n,n,,,,,,,,R.d.^
^.R,,,,,,,,,,,,,,,,+,,,R..d^
>dd,,,,,,,~~~~~~,,,,,,,R...^
>dd,,,,,,~~~~~~~~,,,,,,dd..^
>dd,,,,,,~~~3e~~~,,,,,,,dd.^
^.R,,,,,,~~~~~~~~,,,,,,,,R.^
^.R,,,,,,,~~~~~~,,,,,,,,R..^
^..R,,,,,,,,,,,,,,,+,,,R...^
^...R,,,,,,,,,,,,,,,,,R....^
^....RR,,,,,,,,,,,,,RR.....^
^......RRRR,,dd,RRRR.......^
^...x.........dd....1......^
^TT...........dd........TTT^
^TTTT.........dd.......TTTT^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Leyenda del boceto (exterior, bioma nieve): `.` nieve · `,` hielo pisable / nieve pisada · `d` sendero ·
`p` puente · `S` escalinata · `T` pino nevado · `R` bloque de hielo o roca · `^` acantilado / pared de glaciar ·
`~` agua helada o abismo · `+` huesos, estela, tótem o esquirla (decorado sólido) · `n` tienda · `x` hoguera
(punto de reaparición) · `e` bajada a mazmorra de historia (`DungeonEntrance`) · `H` huella de edificio (`|` = puerta) · `*` pista (`.clue`) · `>` salida a otra área · `w` muralla ·
`B` jefe de campo · `1`-`3` centro aproximado de cada zona de nivel.

- **1 · Borde del cráter (44)**: anillo de bloques `R` con dos brechas (sur y noreste). `iceElemental` ×3,
  `shardLunatic` ×3. Hoguera `x` (reaparición) fuera del anillo.
- **2 · Campo de esquirlas (45)**: suelo vitrificado `,`, campamento del Eclipse (tiendas negras `n`), esquirlas
  `+` que brillan. `shardLunatic` ×3, `rimeCultist` ×3, `iceElemental` ×2. Los tres `+` más grandes son los
  **tótems de la aurora** (objetivos de `escarcha.tres_auroras`).
- **3 · Corazón del cráter (46)**: lago helado `~` (no se pisa) con una isla y la **entrada a la Sima** `e`
  (se llega por un puente de hielo `p` de 3 casillas, a dibujar en el borrador 1:1). Escena de Corvino aquí.
  `rimeCultist` ×2, `iceElemental` ×2.
- Salidas: `crater.oeste` (0, 14-19) → Tundra; `crater.norte` (38-45, 0) → Gigantes. `e` = `DungeonEntrance` de
  `escarcha.sima` en (24-25, 18). Pistas `cartaBrasa` (24, 10) y `totemAurora1-3` (ver `zonas.md` §4).
- El anillo tiene dos brechas: nunca un solo camino al centro.
