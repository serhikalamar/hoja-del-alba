# Mapa · piso `tomb` — Tumba de Solarum (mazmorra, 35-37)

Tamaño real: **46 × 32**. Arena dorada y piedra de sillería; luz de antorchas cálida. `~` no se usa (sin abismo):
la tumba es de **salas y corredores**. `r` = camino ceremonial de losas doradas, `s` = estatuas de sacerdotes,
`C` = cofre, `b` = vasijas rotas, `,` = arena acumulada. `M` = **mural** (casilla de pared nueva para la sala de
los murales, solo decorativa en la mazmorra; la lectura de verdad es en el interior `cenizas.necropolis.murales`). En `DungeonTile` no existe: usar `#` con arte de mural o añadir el carácter.

**Boceto ligero a escala 1:2** de un piso de mazmorra (`DungeonTile`, ver `assets/maps/mazmorra.md`): cada carácter
≈ 2×2 casillas. El `map-designer` lo pasa a tamaño real cumpliendo las reglas de los pisos (pared de arriba de 2 filas,
8-12 entradas `G`/`h`, pasillos de 3+, obstáculos con 2+ casillas libres, 300+ casillas pisables).

```
#########BBB###########
#t####t##...##t####t###
#.....G.r.....r.G.....#
#.s...........r.....s.#
#.....I..rrrrrr..I....#
#..h.......r.......h..#
###tt##..........##tt##
#,,,,,G....r....G,,,,,#
#,b.....I..r..I.....b,#
#.....h....r....h.....#
#..C.......r.......C..#
###G####...r...####G###
#.MMMM.....r.....MMMM.#
#.......s..r..s.......#
#.........x.x.........#
#######################
```

- **Santuario del Sol** (arriba): gran puerta `BBB` del jefe; el Gran Sacerdote aparece y baja por el camino `r`.
- **Galería de las ofrendas** (centro): dos alas de arena con vasijas, separadas por muros de 2 filas con antorchas.
- **Sala de los murales** (abajo): los dos paneles `MMMM`. El héroe empieza en (22, 26) entre los dos braseros.
- Entradas: 6 `G` + 4 `h` = 10.
- **Partida** (M8): 4 oleadas + jefe `sunHighPriest` (`StoryDungeon` en `zonas.md` §5). Al ganar se abre la Sala de los
  Murales de la Necrópolis (misión `cenizas.los_murales`, con el espíritu de Solano).
