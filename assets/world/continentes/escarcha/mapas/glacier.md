# Sima del Glaciar (piso `glacier`) — mazmorra 45-47

Borrador **ligero** (fase futura). Tamaño real: **44×24** casillas.

```
######################
#tt#t#G##BB##G#t#tt#G#
#....,..I....I..,....#
#.x....,........,..x.#
#..,,..~~~~====~~~...#
#.h....~~~~====~~~.h.#
##G#,..............###
#.....tt...@...tt....#
#..I..##.......##..I.#
#.......,..h..,......#
#..~~~~==~~~~~~==~~..#
######################
```

Leyenda (`DungeonTile`, ver `assets/maps/mazmorra.md`): `#` pared · `t` pared con antorcha (aquí: cristal de luna
que brilla) · `G` puerta de monstruos · `B` gran puerta del jefe · `.` suelo de hielo · `,` hielo agrietado / nieve ·
`b` huesos, restos de caballeros · `r` camino ceremonial · `=` puente · `h` rejilla (aquí: grieta en el hielo de la que
salen monstruos) · `~` abismo / agua helada · `I` pilar (columna de hielo) · `s` estatua · `x` brasero (fuego azul) ·
`c` cajas, barriles · `C` cofre · `A` altar.

Boceto a **escala 1:2** (1 carácter = 2×2 casillas): el piso real mide **44×24**, como `mine` y `crypt`.
`@` = salida del héroe (en 1:1, hacia (22, 15)).

- **Bóveda norte** (filas 2-5): techo de hielo azul con cristales de luna `t` cada 5-7 casillas, gran puerta del jefe
  `BB` en el centro, dos braseros de fuego azul `x`. Columnas de hielo `I`.
- **Gran grieta** central: abismo `~` (agua negra bajo el hielo) cruzado por un **puente de hielo** `=` de 3+ de
  ancho; se rodea por los dos lados.
- **Saliente de cristal** en el centro (bloques `tt`/`##` de 2+ filas, con tapa y cara).
- **Río helado sur**: segundo abismo con dos puentes; la zona sur es abierta para esquivar.
- Entradas: 5 `G` + 4 `h` (grietas) = **9**. El héroe empieza a 10+ casillas de la más cercana.
- Tema para el `environment-artist`: hielo azul translúcido, nieve en el suelo, cristales cian que iluminan,
  un caballero congelado dentro de la pared norte (decorado: el que se ve al vencer al Engendro).
