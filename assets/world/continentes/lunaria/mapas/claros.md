# Claros de la Luna (`lunaria.claros`) — boceto · niveles 22-24

Real **60 × 36**. Territorio élfico: claros con estanques de luz, telarañas plateadas, estelas élficas.

> **Boceto a escala 1:2**: cada carácter es un bloque de 2×2 casillas (el `map-designer` lo duplica y le da forma:
> bordes irregulares, caminos de 3+ casillas, claros para pelear). Coordenadas del boceto (col, fila) desde 0; en el
> mapa real, ×2. Leyenda: `assets/maps/README.md` + exteriores de `assets/world/continentes.md`; bioma `lunaria`
> (ver `zonas.md`). Los números `1`-`9` son huellas de edificios (en el mapa real, `.` + `Building`).

```
TTT>>TTTTTTTTTTTTTTTTTTTTTTTTT
TT.dd....T.......,.....T.....T
T..dd.......~~~.......%%..RR.T
T..dd..+...~~~~~......%...RR.T
T..ddd.....~~~~~.........R...T
>ddddddddd..~~~..dddddddd....T
>dd..,,..dddddddddd.....dd...T
T....,,,.......dd...T...dd.,.T
T..+......T...dd.......ddddddT
T.....%%%%....dd.......d....TT
T....%%RR%%%...dddddddddd...TT
T...%%%RR%%%%..dddddddddddddd>
T....%%%%%%...dd....~~~.....d>
T.T...%%%%....dd...~~~~~.....T
T.......T.....dd....~~~...T..T
TT...........dd............TTT
TTTT........dd..........TTTTTT
TTTTTTTTTTTT>>TTTTTTTTTTTTTTTT
```

- **Salidas**: oeste `>` (0, 5-6) → `lunaria.raices` · noroeste `>>` (3-4, 0) → `lunaria.velaluna` (Pasarela del Este,
  sube a las copas) · sur `>>` (12-13, 17) → `lunaria.espesura` · este `>` (29, 11-12) → `lunaria.marchito`.
- `~`: estanques de luz lunar (la "luz enferma" se dibuja violeta en las misiones 2-10). `+` (7, 3): **Ara de los
  Claros**, punto seguro con **Thessa**; `+` (3, 8): estela.
- `%` en el suroeste: **los Telares** (telarañas en el suelo; se pisan) con dos peñas `RR`.
- `RR` (26-27, 2-3): el tronco del **Abuelo Fresno** (sólido). El jefe `rottenElder` espera delante, en (24, 3).

| Zona | Bloque del boceto | Nivel | Spawns |
|---|---|---|---|
| Claro de las Luciérnagas | cols 0-17, filas 0-8 | 22 | `wisp` ×3, `forestSpirit` ×3, `pixie` ×2 |
| Los Telares | cols 0-17, filas 9-17 | 23 | `moonSpider` ×3, `spiderling` ×4 (2 grupos), `webSpitter` ×2 |
| Claro del Abuelo | cols 18-29, filas 0-17 | 24 | `forestSpirit` ×2, `owlbear` ×1, **jefe** `rottenElder` |

NPC: Thessa (8, 3). Tras la misión 3, dos guardias élficos de ambiente en el Ara.
