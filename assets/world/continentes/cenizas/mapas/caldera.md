# Mapa · piso `caldera` — Caldera de Brasamadre (banda corta, 39-40)

Tamaño real: **46 × 30**. Roca negra agrietada, `~` = **lava** (anillo alrededor del Ascua), `=` = puente de
basalto, `AA` = **altar del Ascua** (pedestal de obsidiana con la brasa viva), `I` = pilares de basalto,
`,` = escoria.

**Boceto ligero a escala 1:2** de un piso de mazmorra (`DungeonTile`, ver `assets/maps/mazmorra.md`): cada carácter
≈ 2×2 casillas. El `map-designer` lo pasa a tamaño real cumpliendo las reglas de los pisos (pared de arriba de 2 filas,
8-12 entradas `G`/`h`, pasillos de 3+, obstáculos con 2+ casillas libres, 300+ casillas pisables).

```
##########BBB##########
#t###t###.....###t###t#
#...G....~~.~~....G...#
#.......~~~.~~~.......#
#..x...~~~...~~~...x..#
#..h...~~.....~~...h..#
#.......~~.AA.~~......#
#..I....~~~===~~~...I.#
#.......~~~===~~~.....#
#..G.....~~...~~....G.#
#....x......,......x..#
#..h......,,,,,....h..#
#.....I...........I...#
#..........,..........#
#######################
```

- **Isla del Ascua** (centro): anillo de lava con dos accesos: el corredor norte desde la gran puerta `BBB` (por
  donde baja el Emperador) y el puente sur `===`.
- **Plataformas** este y oeste: pilares, braseros y rejillas; el héroe empieza al sur, en (23, 24).
- Entradas: 4 `G` + 4 `h` = 8.
- **Partida** (M8): 5 oleadas + jefe `ashEmperor` (`StoryDungeon` en `zonas.md` §5). Más larga que la Tumba: es la "banda"
  del continente (objetivo 60-120 s para el jefe).
