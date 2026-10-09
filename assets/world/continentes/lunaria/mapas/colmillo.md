# Colmillo Gris (`lunaria.colmillo`) — boceto

Aldea de los clanes lobo en un claro del bosque profundo. Real **44 × 32**. Zona segura.

> **Boceto a escala 1:2**: cada carácter es un bloque de 2×2 casillas (el `map-designer` lo duplica y le da forma:
> bordes irregulares, caminos de 3+ casillas, claros para pelear). Coordenadas del boceto (col, fila) desde 0; en el
> mapa real, ×2. Leyenda: `assets/maps/README.md` + exteriores de `assets/world/continentes.md`; bioma `lunaria`
> (ver `zonas.md`). Los números `1`-`9` son huellas de edificios (en el mapa real, `.` + `Building`).

```
TTTTTTTTT>>TTTTTTTTTTT
TTT.....ddd.......RTTT
TT..n...d....n.....TTT
TT.....dd..1111111.TTT
T..+...d...1111111..TT
T......d.....d.....+TT
T.222..dddddxdddddddd>
T.222..d....d.......d>
T......d..+.d.+..333.T
TT..n..d....d....333.T
TT.....dddddd.......TT
T..~~~~~pp~~~~~..n..TT
T..RR...dd.....444..TT
TT..n...dd..+..444.TTT
TTT.....dd.........TTT
TTTTTTTTTTTTTTTTTTTTTT
```

- `x` en el centro (12, 6): **Gran Hoguera del Clan** (luz cálida, punto de reunión). Reaparición junto a ella.
- `+`: tótems de los clanes (cráneos de ciervo y colmillos). `n`: tiendas de piel. `~` arroyo con puente `pp`.
- Salidas: **norte** `>>` (9-10, 0) → `lunaria.raices` (llega al sur de Raíces); **este** `>` (21, 6-7) → `lunaria.espesura`.

| N.º | Id | Nombre | Estilo | Interior | Quién |
|---|---|---|---|---|---|
| 1 | `greyfangDen` | Gran Cubil | `mill` (variante: cabaña bajo raíces enormes) | `lunaria.colmillo.cubil` | Matriarca Ulma |
| 2 | `greyfangTannery` | Curtiduría | `smithy` (variante: pieles colgadas) | `lunaria.colmillo.curtiduria` | Hirsa (tienda de cueros y telas tier 3) |
| 3 | `greyfangLonghouse` | Casa Larga | `inn` | `lunaria.colmillo.casalarga` | Posada (reaparición alternativa) |
| 4 | `greyfangNursery` | Casa de los cachorros | `house` | `lunaria.colmillo.cachorros` | Pico tras su rescate; cachorros de ambiente |

NPC exteriores: Rhovan junto a la hoguera (13, 7); lobo mensajero `mensajeroColmillo` (maestro de viajes) junto a la salida norte (10, 2);
ancianos y cachorros de ambiente. Llegadas: desde Raíces (10, 1); desde la Espesura (20, 6).
