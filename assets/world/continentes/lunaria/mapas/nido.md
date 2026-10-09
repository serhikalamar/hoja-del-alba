# Nido de las Tejedoras (`lunaria.nido`, piso `webs`) — boceto

Mazmorra de historia de la Espesura (nivel 26, 4 oleadas + `broodMother`). Piso nuevo `webs` en
`Dungeon.storyFloors` (no entra en la arena). Real **44 × 22**. Leyenda `DungeonTile` (`assets/maps/mazmorra.md`).

> **Boceto a escala 1:2** (cada carácter = 2×2 casillas; en el mapa real, la pared de arriba son 2 filas: tapa + cara).

```
#t##G#t###BB###t#G#t##
#.,,....c..x..c....,.#
#..I....,,....,,..I..#
G...~~~==~~~....h....#
#...~~~==~~~..c...,,.G
#.h..........,,......#
#..#t##....##t##...#G#
#.....,,...c.....,..h#
#.c..~~~....s...~~~..#
#..h.~~~..,,....~~~.c#
######################
```

Tema: cueva de raíces forrada de seda plateada; charcos de savia negra; capullos colgando; setas que dan luz.

| Carácter | En este piso |
|---|---|
| `~` | Pozo de savia negra / sima cubierta de telaraña (no se pisa) |
| `=` | Puente de seda tensa |
| `,` | Seda en el suelo |
| `c` | Capullos (obstáculo) · `s` gran capullo con un elfo dentro (decorado) |
| `I` | Raíz gruesa (pilar) · `x` hongo luminoso (luz) · `t` pared con setas luminosas |
| `G` / `h` | Agujeros de araña en la pared / en el suelo (entradas de monstruos): 5 + 4 = 9 |
| `BB` | Gran agujero de la Madre Tejedora (en el real, `BBB`) |

- **Galería norte** (filas 1-5): la Madre entra por el centro; dos raíces-pilar, capullos y un hongo-luz.
- **Sima de seda** (oeste, filas 3-4) cruzada por un puente de seda de norte a sur; se rodea por los lados.
- **Muro de raíces** (fila 6) con tres pasos anchos (cols 1-2, 7-10, 16-18).
- **Despensa** (sur): dos pozos de savia, el gran capullo `s` y capullos sueltos. El héroe empieza en (9, 8) → real
  (18, 16), a 10+ casillas de la entrada más cercana.
