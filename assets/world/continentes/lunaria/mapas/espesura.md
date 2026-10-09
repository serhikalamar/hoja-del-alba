# Espesura del Aullido (`lunaria.espesura`) — boceto · niveles 24-26

Real **60 × 36**. Territorio lobo: bosque cerrado, peñas, niebla, huesos.

> **Boceto a escala 1:2**: cada carácter es un bloque de 2×2 casillas (el `map-designer` lo duplica y le da forma:
> bordes irregulares, caminos de 3+ casillas, claros para pelear). Coordenadas del boceto (col, fila) desde 0; en el
> mapa real, ×2. Leyenda: `assets/maps/README.md` + exteriores de `assets/world/continentes.md`; bioma `lunaria`
> (ver `zonas.md`). Los números `1`-`9` son huellas de edificios (en el mapa real, `.` + `Building`).

```
TTTTTTTTTTTT>>TTTTTTTTTTTTTTTT
TTT.T....TT.dd.T..^^e^^..TT.TT
TT..T.T....dd...%%..d%%.T...TT
T..T....T..dd...R...d...T..T.T
T.T..R.....dddddddddd.....T..T
TT...T....T...dd.......dddddd>
T..R.....T....dd....dddd.....>
T.+..T..+.....dd..R.dd.......T
>dddddddddddddd....dd...RR...T
>dd....T......dd...ddd..RR...T
T....R.....T..dddddddd...T...T
TT..T....%%..........dd....TTT
T..T...%%%...R.......dd..R..TT
T....T..%%.......T..+.dd.+..TT
TT.......R...T.....b..ddd...TT
TTT..T.....RR..+...x...d..TTTT
TTTTT.....RRR.........dd.TTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

- **Salidas**: norte `>>` (12-13, 0) → `lunaria.claros` · oeste `>` (0, 8-9) → `lunaria.colmillo` · este `>` (29, 5-6)
  → `lunaria.marchito`.
- `^e^` (18-22, 1): **Cueva de seda**, entrada `e` (20, 1) a la mazmorra **Nido de las Tejedoras** (piso `webs`). Dos
  `moonSpider` de guardia en (19, 3) y (21, 3). Se abre con la misión 7.
- `+` (2, 7) y (8, 7): tótems del clan (Lindero). `+` (20, 13), (25, 13), (15, 15): tótems rotos del Cubil.
- **Cubil de la Mala Luna** (sureste, cols 17-25, filas 12-16): hoguera apagada `x` (19, 15); `R` peñas. Jefe
  `blackClaw` en (22, 16). Pico, el cachorro perdido, en el arbusto `b` (19, 14) (tronco hueco).
- `%`: maleza y helechos (hondonada).

| Zona | Bloque del boceto | Nivel | Spawns |
|---|---|---|---|
| Lindero del Clan | cols 0-10, filas 0-17 | 24 | `feralWerewolf` ×4, `corruptStag` ×2 |
| Hondonada del Aullido | cols 11-29, filas 0-10 | 25 | `moonHowler` ×3, `feralWerewolf` ×3, `owlbear` ×1 (+ 2 `moonSpider` de la cueva) |
| Cubil de la Mala Luna | cols 11-29, filas 11-17 | 26 | `feralWerewolf` ×3, `moonHowler` ×2, **jefe** `blackClaw` |
