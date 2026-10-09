# Hueco del Árbol Madre (`lunaria.hueco`, piso `hollow`) — boceto

Mazmorra final de Lunaria (nivel 30, 5 oleadas + `ysolde`). Piso nuevo `hollow` en `Dungeon.storyFloors`. Real
**46 × 24**. Leyenda `DungeonTile` (`assets/maps/mazmorra.md`).

> **Boceto a escala 1:2** (cada carácter = 2×2 casillas).

```
#t##G##t##BBB##t##G##t#
#....x....sAAs....x...#
#..I.......rrr.....I..#
G..h.......rrr.....h..G
#.I.....I..rrr..I.....#
#~~~~==~~~~~==~~~~==~~#
#~~~~==~~~~~==~~~~==~~#
#.,,....,,..rr...,,...G
G..x..I.......I...x..h#
#.h...,,.........,,...#
#..c..s.........s..c..#
#######################
```

Tema: el interior del tronco del Árbol Madre. Anillos de madera clara en el suelo, raíces vivas, savia de luz azul que
cae a una sima; al fondo, el **Ascua de Lunaria** en un altar de raíz (blanco-dorado, la única luz cálida).

| Carácter | En este piso |
|---|---|
| `~` | Sima de savia de luz (abismo luminoso, no se pisa) |
| `=` | Puente de raíz |
| `r` | Camino ceremonial de raíz hasta el Ascua |
| `AA` | Altar del Ascua · `s` estatuas élficas antiguas · `I` raíces-pilar · `x` flores de luz · `c` raíces caídas |
| `G` / `h` | Grietas en la corteza / nudos del suelo: 6 + 4 = 10 entradas |
| `BBB` | Gran grieta por donde entra Ysolde, justo detrás del altar (rodea el Ascua para llegar) |

- **Santuario del Ascua** (norte, filas 1-4): altar entre estatuas, camino de raíz, flores de luz y dos raíces-pilar.
- **Sima de savia** (filas 5-6) de lado a lado, cruzada por **tres puentes de raíz** (cols 5-6, 12-13, 18-19).
- **Sala de las raíces** (sur): el héroe empieza en (11, 9) → real (22, 18). Estatuas y raíces caídas a los lados.
- Al vencer a Ysolde, escena de la Hermana Brasa junto al altar (texto en `StoryDungeon.bossDefeat`; no pelea).
