# Bosque Marchito (`lunaria.marchito`) — boceto · niveles 26-28

Real **60 × 36**. Sub-bioma **marchito** (*necesidad de motor* N1): `T` = árbol gris muerto, `.` = hojarasca negra,
`%` = zarzas secas, niebla violeta. Aquí el conflicto es abierto: élites (árboles corruptos) y el campamento del Eclipse.

> **Boceto a escala 1:2**: cada carácter es un bloque de 2×2 casillas (el `map-designer` lo duplica y le da forma:
> bordes irregulares, caminos de 3+ casillas, claros para pelear). Coordenadas del boceto (col, fila) desde 0; en el
> mapa real, ×2. Leyenda: `assets/maps/README.md` + exteriores de `assets/world/continentes.md`; bioma `lunaria`
> (ver `zonas.md`). Los números `1`-`9` son huellas de edificios (en el mapa real, `.` + `Building`).

```
TT>>TTTTTTTTTTTTTTTT>>TTTTTTTT
T..dd.....T.T......dd...n.n..T
T..dd..T.......T...dd..x...x.T
T...ddd...T.T....dddddd.n.+..T
T.T...dd..........d.....n...TT
>ddddddddd..T.T...d...x....T.T
>dd....T.ddddddddddd.......TTT
T....T.T.dd...T.T..T.....T..TT
T..T.....dd.T...T....T.T.....T
T.....T..dddddddddd...T...T..T
T..T.T...dd...T..dd.T....T...T
T.%%.....dd.T...T.dd...T.T...T
T.%%%..T.dd.......dd.T.....T.T
TT.%%....ddddddddddd......T..T
TT...T...........T.......T..TT
TTT.....T....T........T...TTTT
TTTTTT...............TTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

- **Salidas**: oeste `>` (0, 5-6) → `lunaria.espesura` · noroeste `>>` (2-3, 0) → `lunaria.claros` · norte `>>` (20-21, 0)
  → `lunaria.lago`.
- **Campamento Marchito** (noreste, cols 19-28, filas 1-5): tiendas `n`, braseros violetas `x`, estandarte del Eclipse
  `+` (26, 3).
- **Arboleda Muerta** (centro): bosque denso de `T` con un laberinto de sendas `d` (siempre 2+ rutas).
- `%` (suroeste): zarzas secas de la Linde Gris.

| Zona | Bloque del boceto | Nivel | Spawns |
|---|---|---|---|
| Linde Gris | cols 0-9, filas 0-17 | 26 | `witheredArcher` ×3, `thornling` ×3, `wisp` ×2 |
| Arboleda Muerta | cols 10-29, filas 6-17 | 27 | `treant` ×3 (élite), `witheredBlade` ×3 |
| Campamento Marchito | cols 10-29, filas 0-5 | 28 | `witheredArcher` ×3, `witheredBlade` ×3, `owlbear` ×1 |

Tras la misión 8: patrulla conjunta (2 guardias élficos + 2 lobos del clan) de ambiente en (9, 6).
