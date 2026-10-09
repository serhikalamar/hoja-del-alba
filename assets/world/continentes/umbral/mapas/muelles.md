# Muelles del Cielo (`umbral.muelles`) — 50-52 · boceto

56×32. Cuatro islas: **amarre** (oeste, pantalán del dirigible), **almacenes** (centro), **faro** (noreste) y
**terraza** (sureste, hacia el Bastión). Zona 1: bienvenida con constructos y gárgolas.

Leyenda: la de `bastion.md` (bioma `umbral`; `~` = vacío, `p` = puente de luz, `d` = sendero de piedra dorada,
`^` = pared de roca o torre, `R` = peñasco, `+` = estela / cascarón gigante, `x` = brasero, `e` = entrada a mazmorra,
`>` = salida). **Marcas solo de borrador** (en el código son suelo `.`): `@` = llegada y punto de reaparición,
`*` = grupo de monstruos de campo (2-4), `!` = NPC o élite fija, `J` = jefe, `1` = huella de un edificio.
Boceto ligero: el `map-designer` puede mover islas, puentes y grupos mientras respete tamaños, salidas y zonas.

## Mapa

```
    00000000001111111111222222222233333333334444444444555555
    01234567890123456789012345678901234567890123456789012345
 0  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 2  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.........~~~~
 3  ~~~~~~~~~~~~~~~~~~~~~~~~...........~~~~~~~.....^^....~~~
 4  ~~~~~~~~~~~~~~~~~~~~~~......RRRR.....~~~~....l.^^!....~~
 5  ~~~~~~~~~~~~~~~~~~~~~.................~~.......^^......~
 6  ~~~~~~~~~~~~~~~~~~~~~..ccc.......cc...~~..*..x....x....~
 7  ~~~~~~~~~~~~~~~~~~~~...................~...............~
 8  ~~~~............~~~~..........dddddddddpddddddddd......~
 9  ~~~..............~~~..........dddddddddpddddddddd......~
10  ~~..........c.....~~..l.......dddddddldpddddddddd......~
11  ~.....c.c..........~......mmm..........~......ddd..*...~
12  ~fff..........*....~....*..............~~.....dd*.....~~
13  f====..*...........~...............*...~~~....ddd....~~~
14  f====.....@........~...................~~~~...ddd...~~~~
15  f====#############dpdddddddddddddddddddpppp~~~ppp~~~~~~~
16  f====!###l########dpddddd!dddddddddddddpppp~~~ppp~~~~~~~
17  f====#############dpdddddddddddddddddddpppp~~~ppp~~~~~~~
18  f====.......*......~..........*........~~~~~..ddd...~~~~
19  f====..............~............mm.....~~~~...ddd....~~~
20  ~fff...............~..l...m..........l.~~~..T.ddd.....~~
21  ~.....c..c.........~...................~~.....ddd......~
22  ~.............c....~.......*...........~~.....#########>
23  ~..................~...................~~.....#########>
24  ~~................~~...cc.........cc...~~.....#########>
25  ~~~..............~~~~.................~~~..T........T..~
26  ~~~~............~~~~~.................~~~..............~
27  ~~~~~~~~~~~~~~~~~~~~~~...............~~~~~............~~
28  ~~~~~~~~~~~~~~~~~~~~~~~~...........~~~~~~~~..........~~~
29  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~........~~~~
30  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
31  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

## Zonas de nivel (`Zone`)

| Id | Nombre | Nivel | Rectángulo aprox. (x, y, ancho, alto) |
|---|---|---|---|
| `amarre` | Amarre del dirigible | 50 | 0, 0, 20, 32 |
| `almacenes` | Almacenes celestes | 51 | 20, 0, 20, 32 |
| `faro` | Faro roto y terraza | 52 | 40, 0, 16, 32 |

## NPC y marcas

- `!` (5, 16): **Capitán Borin** (`borin`) junto al dirigible *Testaruda* (el pantalán `=` de la izquierda, cerrado
  con barandilla `f`; el dirigible se dibuja como decorado sobre el vacío). Da `umbral.llegada`. Es el **maestro de
  viajes**: no hay salida a pie por el oeste.
- `!` (25, 16): soldado herido de Hielomar (relleno: "Los constructos no paran. Nunca paran.").
- `!` (49, 4): `estelaFarero` (`.clue`), el último aviso del farero (ambiente).
- 10 grupos `*` ≈ 30 monstruos de campo (ver `zonas.md`).

## Salidas

| Salida | Casillas | Lleva a | Llegada |
|---|---|---|---|
| Este | (55, 22-24) | `umbral.bastion` | (2, 17) del Bastión |

Llegada en el dirigible (primer viaje desde Hielomar): `@` (10, 14), también `safePoint`. Desde el Bastión: (53, 23).
