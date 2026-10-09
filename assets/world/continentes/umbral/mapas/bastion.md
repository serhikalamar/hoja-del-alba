# Bastión del Alba (`umbral.bastion`) — capital · borrador detallado

Responsable del borrador: `continent-lead` de `umbral`. Lo pasa al juego el `map-designer` (fichero nuevo, p. ej.
`src/GameCore/Sources/GameCore/Umbral.swift`, sin tocar `Town.swift`). Tamaño **52×34** casillas. Zona **segura**
(sin monstruos). Bioma `umbral`.

## Leyenda

Formato de `assets/maps/README.md` + caracteres de exterior de `continentes.md` (M5). En el bioma de Umbral:

| Carácter | Casilla | ¿Se pisa? | Cómo se ve en Umbral |
|---|---|---|---|
| `~` | Vacío | No | Cielo nocturno índigo con estrellas, sin fondo (borde de isla con raíces de piedra colgando) |
| `.` | Suelo | Sí | Piedra clara con vetas de cristal y jirones de nube |
| `,` | Flores | Sí | Flores estelares (pétalos dorados que brillan) |
| `#` | Calle | Sí | Losas blancas con juntas doradas |
| `=` | Plaza | Sí | Mosaico de la Forja (anillos dorados) |
| `p` | Puente de luz | Sí | Tablero de luz dorada entre dos cadenas |
| `T` | Árbol | No | Árbol de cristal azul |
| `b` | Arbusto | No | Arbusto de cristal |
| `w` | Muralla | No | Muralla blanca con almenas doradas |
| `l` | Farola | No | Farol de luz estelar |
| `m` / `c` | Puesto / cajas | No | Puestos con toldo índigo / cajas de la Alianza |
| `F` | Fuente (2×2) | No | **Pozo de luz**: columna de luz que sube hacia la Luna |
| `x` | Brasero | No | Brasero de fuego dorado |
| `R` / `+` | Roca / estela | No | Peñasco dorado / estela con runas de los Herreros |
| `>` | Salida a otra área | Sí | Final del puente de luz |
| `1`…`5` | **Solo borrador**: huella de un edificio (en el código es suelo `.` bajo el `Building`) | — | — |

## Mapa

Coordenadas (columna, fila) desde (0, 0) arriba a la izquierda; las dos primeras líneas son la regla de columnas.

```
    0000000000111111111122222222223333333333444444444455
    0123456789012345678901234567890123456789012345678901
 0  ~~~~~~~~~~~~~~~~~~~~~~~~>>>>~~~~~~~~~~~~~~~~~~~~~~~~
 1  ~~~~~~~~~~~~~~~~~~~~~~~~pppp~~~~~~~~~~~~~~~~~~~~~~~~
 2  ~~~~~~~.......~~........####........~~.......~~~~~~~
 3  ~~~~~...................####...................~~~~~
 4  ~~~~..wwwwwwwwwwwwwwwwww####wwwwwwwwwwwwwwwwww..~~~~
 5  ~~~~..w.................####.................w..~~~~
 6  ~~~...w.TT.......T.11111111111111.T.......TT.w...~~~
 7  ~~~...w.T..........11111111111111..........T.w...~~~
 8  ~~~...w....,.......11111111111111.........,..w...~~~
 9  ~~~...w..,.........11111111111111.......,....w...~~~
10  ~~~...w.T..........11111111111111..........T.w...~~~
11  ~~~...w............11111111111111............w...~~~
12  ~~~~..w...3333333......l####l.......222222...w..~~~~
13  ~~~...w...3333333.bl============lb..222222...w...~~~
14  ~~~...w...3333333..==============...222222...w...~~~
15  ~~~..lw...3333333..==============.x.222222...wl..~~~
16  >pp#######3333333##==============###222222#######pp>
17  >pp################==============################pp>
18  >pp################======FF======################pp>
19  ~~~..lw..,.........======FF======.........,..wl..~~~
20  ~~~...w...444444.b.==============.b.55555....w...~~~
21  ~~~...w...444444.x.==============...55555....w...~~~
22  ~~~~..w...444444...=m=m======m=m=...55555....w..~~~~
23  ~~~...w...444444.,.==c========c==.,.55555....w...~~~
24  ~~~...w...444444..bl============lb..55555....w...~~~
25  ~~~...w.....#...........####..........#......w...~~~
26  ~~~...w.....########,##################......w...~~~
27  ~~~...w.T...............####...,...........T.w...~~~
28  ~~~...wwwwwwwwwwwwwwwwww####wwwwwwwwwwwwwwwwww...~~~
29  ~~~~.................+..####..+.................~~~~
30  ~~~~...............R...x#..#x..R................~~~~
31  ~~~~~.......R...R...R.........R....R...R.......~~~~~
32  ~~~~~~~..~~..............................~~..~~~~~~~
33  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~```

## Edificios

| # | Id | Nombre | Estilo (`BuildingStyle`) | x, y | Ancho × alto | Puerta (x, ancho) | Interior | Quién está |
|---|---|---|---|---|---|---|---|---|
| 1 | `ciudadela` | Ciudadela del Alba | `castle` | 19, 6 | 14 × 6 | 25, 2 | `umbral.bastion.ciudadela` | `princess` (sala de mando, mesa de mapas, trono vacío `Y`) |
| 2 | `forja` | Forja del Último Yunque | `smithy` | 36, 12 | 6 × 5 | 38, 1 | `umbral.bastion.forja` | `brokk`: tienda tier 6, ritual, despertar de la Hoja del Alba (VI) |
| 3 | `posada` | Posada del Dirigible Varado | `inn` | 10, 12 | 7 × 5 | 13, 1 | `umbral.bastion.posada` | Nora (`noraPosadera`); reaparición; un NPC de cada capital |
| 4 | `cuartel` | Cuartel de la Alianza | `house` | 10, 20 | 6 × 5 | 12, 1 | `umbral.bastion.cuartel` | `halvar` (Mariscal Hálvar) |
| 5 | `torre` | Torre de los Astros | `starTower` (nuevo; `placeholder` `alchemist`) | 36, 20 | 5 × 5 | 38, 1 | `umbral.bastion.torre` | `fibulaEngranaje` (telescopio); `thessa` opcional |

Los interiores siguen el formato de interior (`X _ : r s k t z o I Y D`), 14-18 × 10-12, puerta `D` abajo.
Ideas: ciudadela con alfombra `r` hasta la mesa de mapas `t` y estandartes de las seis capitales; forja con dos
hornos `k`, yunque (mesa `t`) y barriles `o`; torre con estanterías `s` y una columna `I` (el telescopio).

## NPC del exterior

| NPC (id) | Posición | Qué hace |
|---|---|---|
| Capitán Borin Nubehierro (`borin`) | (8, 15) | Maestro de viajes (capitales visitadas); `appearsWhen` `.questDone("umbral.llegada")` |
| Zigo (`zigoMercader`) | (21, 21) | Puesto de consumibles; misión `umbral.rayas_de_zigo` |
| Albor (`albor`) | (25, 30), sprite 2×2 | Misiones del Vuelo; vuelo entre áreas de Umbral (tras `umbral.matriarca`) |
| Enano de Hondoyunque (`enanoBastion`) | (22, 14) | Relleno de la Alianza (una frase) |
| Elfa de Velaluna (`elfaBastion`) | (29, 14) | Relleno |
| Loba de Colmillo Gris (`lobaBastion`) | (22, 20) | Relleno |
| Legionaria del Oasis (`oasisBastion`) | (29, 20) | Relleno |
| Guardias de Hielomar (`guardiaBastion1`, `2`) | (4, 15) y (47, 15), junto a las puertas | Relleno; "el vacío no duerme" |

## Salidas (`AreaExit`)

| Id | Casillas `>` | Hacia | Llegada | `lock` / aviso |
|---|---|---|---|---|
| `bastion.oeste` | (0, 16-18) | `umbral.muelles` | (53, 23) | — |
| `bastion.este` | (51, 16-18) | `umbral.nidos` | (2, 27) | `.questDone("umbral.llegada")` — "Hálvar: «Primero preséntate a la princesa.»" |
| `bastion.norte` | (24-27, 0) | `umbral.rotas` | (3, 7) | `.questDone("umbral.puente_de_luz")` — "El puente de luz está apagado. Fíbula sabrá encenderlo." |

- Mientras `bastion.norte` está cerrada, el `environment-artist` dibuja el puente apagado (gris, sin brillo).
- Llegadas al Bastión: desde los Muelles (2, 17); desde los Nidos (49, 17); desde las Islas Rotas (25, 2); por el
  maestro de viajes y la posada, en la plaza (25, 21).
- `safePoint`: plaza (25, 21).

## Ruta prevista

Puerta oeste (llegada desde los Muelles) → calle mayor → plaza (Pozo de luz) → Ciudadela (Aurora) → forja (Brokk) →
salir por el este a los Nidos, o bajar por la puerta sur al **Nido de Albor**. Más tarde, la puerta norte a las
Islas Rotas.

## Comprobación

`make maps` con el área nueva: todas las filas de 52 caracteres, salidas en el borde, puertas de edificio con
calle delante, ninguna casilla pisable aislada (el Nido de Albor se alcanza por la calle sur).
