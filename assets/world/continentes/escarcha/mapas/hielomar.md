# Hielomar (`escarcha.hielomar`) — capital de Escarcha

Borrador **detallado** (fase futura). 48×36 casillas de 24 px, `kind: .town`, `biome: escarchaPort`. Zona segura: sin monstruos.
Interiores, salidas y NPC con los ids de `../zonas.md` (formato de `../../valdemar/contrato.md`).
Bioma **nieve**: `.` nieve, `T` pino nevado, `~` agua del fiordo (oscura, con témpanos), `=` tablones / losas
heladas, `#` calle de tierra apisonada con nieve sucia, `^` montes, `R` rocas de la orilla.

## Mapa

Columnas 0-47, filas 0-35. Las letras mayúsculas `A`-`H` son **huellas de edificio** (en el código, debajo va `.`:
los edificios se colocan aparte, como en `Town.swift`); `|` marca la(s) columna(s) de la puerta, en la última fila.

```
   000000000011111111112222222222333333333344444444
   012345678901234567890123456789012345678901234567
00 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
01 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
02 TT.^..R..^.R^..^R.^..R..^.R^..^R.^..R..^.R^..^TT
03 TT.wwwwwwwwwwwwwAAAAAAAAAAAAAAAAwwwwwwwwwwwww.TT
04 TT.w........T...AAAAAAAAAAAAAAAA....n=====n.w.TT
05 TT.w.T..........AAAAAAAAAAAAAAAA....=======.w.TT
06 TT.w............AAAAAAAAAAAAAAAA....=======.w.TT
07 TT.w.BBBBB.CCCCCAAAAAAA||AAAAAAA....=======.w.TT
08 TT.w.BBBBB.CCCCC================x=..=======.w.TT
09 TT.w.BBBBB.CCCCC.....SSSSSS.........c=====c.w.TT
10 TT.w.BBBBB.CCCCC.....SSSSSS...GGGGG..dd.....w.TT
11 TT.w.BB|BB.CC|CC..============GGGGGT.dd...T.w.TT
12 TT.w...d.....d....=x========x=GGGGG..dd.....w.TT
13 TT.w...dl....dl...============GG|GG..dd.l...w.TT
14 >ddd##############=====++=====##############w.TT
15 >ddd##############=====++=====##############w.TT
16 >ddd##############============##############w.TT
17 TT.w.FFFFFF.HHHHH.============DDDDDDDD.EEEEEw.TT
18 TT.w.FFFFFF.HHHHH.=x========x=DDDDDDDD.EEEEEw.TT
19 TT.w.FFFFFF.HHHHH.============DDDDDDDD.EEEEEw.TT
20 TT.w.FFFFFF.HH|HH.....####....DDDDDDDD.EEEEEw.TT
21 TT.w.FFF|FF...d.T.....####....DDD|DDDD.EE|EEw.TT
22 TT.w.fffdffff........l####l......d.......d..w.TT
23 TT.w....d.............####.......d.......d..w.TT
24 TT.w...........c......####.......c..........w.TT
25 TT.w..m.....m.........####....m.....m....m..w.TT
26 RRRw=c====================================c=wRRR
27 RRRw==============c==========c==============wRRR
28 ~~~~~~~~ppp~~~~~~~~~~~pppp~~~~~~~~~~~ppp~~~~~~~~
29 ~~~~~~~~ppp~~~~~~~~~~~pppp~~~~~~~~~~~ppp~~~~~~~~
30 ~~~~~~~~ppp~~~~~~~~~~~pppp~~~~~~~~~~~ppp~~~~~~~~
31 ~~~~~~~~ppp~~~~~~~~~~~pppp~~~~~~~~~~~ppp~~~~~~~~
32 ~~~~~~~~ppp~~~~~~~~~~~pppp~~~~~~~~~~~ppp~~~~~~~~
33 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
34 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
35 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

(la regla de arriba son las decenas y unidades de la columna; a la izquierda, la fila)

## Leyenda usada

| Carácter | Casilla | ¿Se pisa? | Nota |
|---|---|---|---|
| `.` | Nieve | Sí | `Tile.grass` dibujado con bioma nieve |
| `#` | Calle | Sí | `Tile.street` |
| `=` | Losas / tablones del muelle y la plaza | Sí | `Tile.plaza` |
| `S` | Escalinata al Gran Salón | Sí | `Tile.stairs` |
| `d` | Sendero | Sí | nuevo (M5) |
| `p` | Embarcadero (puente sobre el agua) | Sí | nuevo (M5) |
| `>` | Salida a `escarcha.balleneros` (llegada en su borde este) | Sí | nuevo (M5) |
| `w` | Empalizada de troncos | No | `Tile.wall` |
| `T` | Pino nevado | No | `Tile.tree` |
| `~` | Agua del fiordo | No | `Tile.water` |
| `^` | Montes | No | nuevo (M5) |
| `R` | Roca de la orilla | No | nuevo (M5) |
| `x` | Brasero grande (luz cálida) | No | nuevo (M5) |
| `l` | Brasero de calle (farola) | No | `Tile.lamp` |
| `+` | Tótem del Primer Ballenero (2×2) | No | nuevo (M5); como la fuente de Valdehierro |
| `n` | Tienda (pista del dirigible) | No | nuevo (M5) |
| `m` | Puesto de pescado | No | `Tile.stall` |
| `c` | Cajas / barriles | No | `Tile.crates` |
| `b` | Arbusto nevado | No | `Tile.bush` |
| `f` | Valla del huerto helado | No | `Tile.fence` |

## Edificios

| Letra | Id | Nombre | Estilo (`BuildingStyle`) | x, y, ancho, alto | Puerta (x, ancho) | Interior |
|---|---|---|---|---|---|---|
| `A` | `salon` | Gran Salón de la Jarla | `longhouse` (nuevo; `placeholder` `castle`) | 16, 3, 16, 5 | 23, 2 | `escarcha.hielomar.salon` |
| `B` | `forja` | Forja de Hielomar | `smithy` | 5, 7, 5, 5 | 7, 1 | `escarcha.hielomar.forja` |
| `C` | `templo` | Templo de las Luces | `chapel` | 11, 7, 5, 5 | 13, 1 | `escarcha.hielomar.templo` |
| `D` | `taberna` | Taberna del Arpón | `inn` | 30, 17, 8, 5 | 33, 1 | `escarcha.hielomar.taberna` |
| `E` | `vidente` | Cabaña de Ingrid | `alchemist` | 39, 17, 5, 5 | 41, 1 | `escarcha.hielomar.vidente` |
| `F` | `lonja` | Lonja ballenera | `mill` | 5, 17, 6, 5 | 8, 1 | — (cerrada, decorado) |
| `G` | `casa1` | Casa de balleneros | `longhouse` (`placeholder` `house`) | 30, 10, 5, 4 | 32, 1 | — (cerrada) |
| `H` | `casa2` | Casa de balleneros | `longhouse` (`placeholder` `house`) | 12, 17, 5, 4 | 14, 1 | — (cerrada) |

Los ids de edificio son locales al área; los ids de área de los interiores siguen `continentes.md`.

## Puntos importantes

| Qué | Casilla | Nota |
|---|---|---|
| Llegada en barco (1.ª vez con Marga; luego, viajes de Ulf) | (23, 27) | Muelle central |
| `ulfTresdedos` (maestro de viajes) | (24, 27) | Al pie del embarcadero central |
| `margaCapitana` | (21, 27) | Solo en la llegada (`appearsWhen` hasta `escarcha.llegada`); luego vuelve a Cenizas |
| `princess` | (22, 26) | Hasta `escarcha.llegada`; después, en `escarcha.hielomar.salon` |
| `torvaldTrampero` | (5, 13) | Junto a la puerta oeste |
| `zigoMercader` | (12, 24) | Delante del puesto del muelle (`appearsWhen: .questDone("escarcha.llegada")`) |
| `halvar` | (20, 16) | En la plaza tras `escarcha.sima` (antes, en la cama del templo) |
| Llegada desde la Costa (`balleneros.este`) | (2, 15) | Salida `hielomar.oeste` en (0, 14-16) |
| `safePoint` | (33, 23) | Delante de la taberna |
| Pista del dirigible | (36-42, 4-9) | Cerrada (valla con guardia en (37, 10)) hasta `escarcha.reina`; `brokk` en (39, 6) y Borin con el dirigible *Testaruda* |
| Tótem del Primer Ballenero | (23-24, 14-15) | Centro de la plaza; decorado (ambiente: aurora encima) |

## Ruta

Muelle (llegada) → calle sur → plaza → escalinata → Gran Salón (Jarla). Desde la plaza: forja y templo al noroeste,
taberna y cabaña de Ingrid al sureste, puerta oeste → Costa. La calle este termina en la empalizada (sin salida;
deja sitio a una futura puerta este si se quiere un atajo a la Tundra).

## Interiores (bocetos)

Interiores pequeños como los de Valdehierro (`X` pared, `_` madera, `:` piedra, `r` alfombra, `k` horno/hogar,
`t` mesa, `z` cama, `o` barril, `s` estantería, `I` columna, `Y` trono, `D` salida).

**Gran Salón de la Jarla** (`escarcha.hielomar.salon`, 18×10): hogar largo en el centro, trono de la Jarla al fondo.
```
XXXXXXXXXXXXXXXXXX
X_I____YY_____I__X
X________________X
X__t____kkkk___t_X
X__t____kkkk___t_X
X________________X
X_I____rrrr___I__X
X______rrrr______X
X______rrrr______X
XXXXXXXXDDXXXXXXXX
```

**Forja de Hielomar** (`escarcha.hielomar.forja`, 10×7): como la forja del enano (tienda y ritual), con hogar `k`.
**Templo de las Luces** (10×8): bancos `t`, cama `z` de Hálvar junto al altar. **Taberna del Arpón** (14×8):
mesas, barriles `o`, barra. **Cabaña de Ingrid** (8×6): estanterías `s`, hogar `k`, alfombra `r`.
El `map-designer` los dibuja con estas medidas.
