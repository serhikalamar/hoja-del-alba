# Lago de la Luna Caída (`lunaria.lago`) — boceto · niveles 28-29

Real **60 × 36**. Un lago enorme que refleja una luna que ya no está; ruinas élficas de **Selenar**; en la isla, el
**Árbol Madre** (`TTTT` 4×2 en el boceto = tronco de 8×4 casillas, sólido).

> **Boceto a escala 1:2**: cada carácter es un bloque de 2×2 casillas (el `map-designer` lo duplica y le da forma:
> bordes irregulares, caminos de 3+ casillas, claros para pelear). Coordenadas del boceto (col, fila) desde 0; en el
> mapa real, ×2. Leyenda: `assets/maps/README.md` + exteriores de `assets/world/continentes.md`; bioma `lunaria`
> (ver `zonas.md`). Los números `1`-`9` son huellas de edificios (en el mapa real, `.` + `Building`).

```
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
T..R+R...~~~~~~~~~~~~...R+R..T
T..ddd..~~~~~~TTTT~~~~~..ddd.T
T.T.dd.~~~~~~.TTTT.~~~~~.dd..T
T...dd.~~~~~~..e...~~~~~.dd.TT
T...dd.~~~~~~......~~~~~.dd..T
TT..dd..~~~~~~~pp~~~~~~..dd..T
T...dd..~~~~~~~pp~~~~~~..dd..T
T.R.dd...~~~~~~pp~~~~~...dd..T
T+R.ddd...~~~~~pp~~~~...ddd.RT
T.R..ddd...~~~~..~~~...ddd..+T
T......dddd..........dddd...RT
T.T.......ddddddddddd.......TT
TT....,,.......dd.......,,...T
T...T..,,......dd..T....,,...T
TT.........T...dd.........T.TT
TTTT...........dd.........TTTT
TTTTTTTTTTTTTTT>>TTTTTTTTTTTTT
```

- **Salida**: sur `>>` (15-16, 17) → `lunaria.marchito` (llegada en (15, 16)). Único acceso por tierra: el lago hace de
  muro y obliga a rodearlo (anillo de sendas por los dos lados).
- **Isla del Árbol Madre**: entrada `e` (15, 4) al **Hueco del Árbol Madre** (`lunaria.hueco`, piso `hollow`). Puente
  `pp` (15-16, 6-9) desde el sur, siempre abierto. La `e` está sellada por raíces negras: `DungeonEntrance` con
  `lock: .questDone("lunaria.aras_lunares")` (motor actual; no hace falta cambiar casillas).
- **Aras lunares** (`+`): ara oeste (1, 9), ara noreste (25, 1) y ara este (28, 10); las `R` alrededor son columnas
  rotas de Selenar. Cada ara tiene un guardián élite (`treant` u `owlbear`, `scale` 1,5) en la casilla de delante.
  La ruina noroeste (4, 1) es decorado (Thessa la nombra en `lunaria.ruinas_de_selenar`).
- `,`: lirios de luna en la orilla sur.

| Zona | Bloque del boceto | Nivel | Spawns |
|---|---|---|---|
| Orilla de los Sauces | filas 11-17 | 28 | `witheredBlade` ×3, `wisp` ×3, `forestSpirit` ×2 |
| Ruinas de Selenar | cols 0-6 y 23-29, filas 0-10 | 29 | `witheredArcher` ×4, `treant` ×2, 3 guardianes de ara |
| Isla del Árbol Madre | cols 13-18, filas 2-5 | 29 | `witheredBlade` ×2, `witheredArcher` ×2 |

Al final (misión 12) aparecen en la orilla sur Elarith, Ulma, Sylra, Rhovan, Varg y Thessa para el Pacto (posiciones a
decidir por el `map-designer`, en fila delante de los lirios).
