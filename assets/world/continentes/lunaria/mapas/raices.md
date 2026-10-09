# Raíces de Plata (`lunaria.raices`) — boceto · niveles 20-22

Real **60 × 36**. Primera zona del continente: raíces gigantes, setas que brillan, un río.

> **Boceto a escala 1:2**: cada carácter es un bloque de 2×2 casillas (el `map-designer` lo duplica y le da forma:
> bordes irregulares, caminos de 3+ casillas, claros para pelear). Coordenadas del boceto (col, fila) desde 0; en el
> mapa real, ×2. Leyenda: `assets/maps/README.md` + exteriores de `assets/world/continentes.md`; bioma `lunaria`
> (ver `zonas.md`). Los números `1`-`9` son huellas de edificios (en el mapa real, `.` + `Building`).

```
TTTTTTTTTTTT>>TTTTTTTTTTTTTTTT
^^^^.....T..dd.....T...,,..TTT
^^R.......T.dd....T....,,....T
^^..x.n.....dd.......%%......T
^^........dddd.....T.........T
>dddddddddddddddddddddddddddd>
>ddd....T...dd...R.....dddddd>
^^.......,,.dd..........RR...T
^^...T..,,,.dd....%%%.......TT
T~~~~~~~~~~ppp~~~~~~~~pp~~~~~T
T....,,....dd.....T....dd...TT
T.T..,,,...dd..,,......dd....T
T....,,..T.dd.,,,..T...dd..R.T
TT.......%%dd......%%..dd....T
TT..R..,....ddddddddddddd...TT
TTT....T........dd.......TTTTT
TTTT............dd......TTTTTT
TTTTTTTTTTTTTTTT>>TTTTTTTTTTTT
```

- **Salidas**: oeste `>` (0, 5-6) → Túnel de los Thanes (área de Rocaforja; id lo fija su lead, *a confirmar*) ·
  norte `>>` (12-13, 0) → `lunaria.velaluna` (base del Gran Ascensor) · este `>` (29, 5-6) → `lunaria.claros` ·
  sur `>>` (16-17, 17) → `lunaria.colmillo`.
- `^` a la izquierda: la ladera de la montaña por donde sale el Túnel. Campamento de **Trapisonda** (hoguera `x` (4, 3),
  tienda `n` (6, 3)): punto seguro y de reaparición (M9). Llegada desde el Túnel: (2, 5).
- Río `~` de oeste a este (fila 9) con dos puentes `p` (11-13 y 22-23). `,`: setas luminosas; `%`: helechos altos; `R`: raíces gigantes.

| Zona (`Zone`) | Bloque del boceto | Nivel | Spawns |
|---|---|---|---|
| Boca del Túnel | cols 0-11, filas 0-8 | 20 | `pixie` ×4, `thornling` ×3 |
| Hongal Brillante | cols 0-15, filas 9-17 | 21 | `glowcap` ×4, `thornling` ×2, `wisp` ×2 |
| Sendero de los Ciervos | cols 14-29, filas 0-17 (salvo el norte del río junto a la Boca) | 22 | `corruptStag` ×3, `pixie` ×2 |

Spawns `lunaria.raices.1` … `.20`, en grupos de 2-3 en los claros, nunca encima del camino principal (fila 5).
