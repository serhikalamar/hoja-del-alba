# Murallas de la Luna Rota (`escarcha.murallas`) — 48-49

Borrador **ligero** (fase futura). Tamaño real: **56×36** casillas.
Boceto a **escala 1:2** (1 carácter = 2×2 casillas; el `map-designer` lo pasa a 1:1 con caminos de 3+ casillas).

```
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^wwwwwwwwwwweewwwwwwwwww^^
^^^w..+.......B.......+..w^^
^^^w.......rrrrrr........w^^
^^^w..+....r.3..r.....+..w^^
^^^w.......rrrrrr........w^^
^^^wwwwwww..........wwwwww^^
^^^w....+...........+....w^^
^^^w.......2.............w^^
^^^w..+..............+...w^^
^^^wwwwwwwwww....wwwwwwwww^^
^^.........................^
^^..~~~~~~pp~~~~~~pp~~~~~..^
^^..~~~~~~pp~~~~~~pp~~~~~..^
^^.........1.........x.....^
^^..T..+...........+....T..^
^^TT......dd.....dd.....TT.^
^^^^^^^^^^>>>^^^^>>>^^^^^^^^
```

Leyenda del boceto (exterior, bioma nieve): `.` nieve · `,` hielo pisable / nieve pisada · `d` sendero ·
`p` puente · `S` escalinata · `T` pino nevado · `R` bloque de hielo o roca · `^` acantilado / pared de glaciar ·
`~` agua helada o abismo · `+` huesos, estela, tótem o esquirla (decorado sólido) · `n` tienda · `x` hoguera
(punto de reaparición) · `e` bajada a mazmorra de historia (`DungeonEntrance`) · `H` huella de edificio (`|` = puerta) · `*` pista (`.clue`) · `>` salida a otra área · `w` muralla ·
`B` jefe de campo · `1`-`3` centro aproximado de cada zona de nivel.

- **1 · Foso helado (48)**: foso `~` con dos puentes `p` de 2 (4 casillas en 1:1). Campamento de Ser Hálvar
  con hoguera `x` (reaparición). `frozenDead` ×4, `frostWraith` ×2.
- **2 · Adarve (49)**: patio entre el primer lienzo de muralla (brecha central de 4 → 8 casillas) y el segundo.
  Estatuas de caballeros `+`. `brokenKnight` ×3, `moonPriestess` ×2, `frostWraith` ×2.
- **3 · Puerta de Plata (49)**: patio de honor con camino ceremonial `r` (alfombra de losas de plata).
  `brokenKnight` ×2, `moonPriestess` ×2 y **Comendador Eirik** (`B`, jefe de campo permanente).
  `ee` = **Puerta de Plata** → banda de la Ciudadela (piso `citadel`), cerrada hasta vencer a Eirik.
- Salidas: `murallas.suroeste` (20-25, 35) y `murallas.sureste` (34-39, 35) → Gigantes. `ee` = `DungeonEntrance`
  de `escarcha.ciudadela` en (27-28, 3).
- Dos puentes y dos bocas al sur: siempre hay dos caminos.
