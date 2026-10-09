# Nidos del Vuelo del Alba (`umbral.nidos`) — 52-54 · boceto

56×36. Ladera de roca dorada que sube de suroeste a noreste. Cascarones gigantes (`+`) como obstáculos. En la meseta
de la cumbre (noreste), rodeada de pináculos `^`, espera **Nixara**.

Leyenda: la de `bastion.md` (bioma `umbral`; `~` = vacío, `p` = puente de luz, `d` = sendero de piedra dorada,
`^` = pared de roca o torre, `R` = peñasco, `+` = estela / cascarón gigante, `x` = brasero, `e` = entrada a mazmorra,
`>` = salida). **Marcas solo de borrador** (en el código son suelo `.`): `@` = llegada y punto de reaparición,
`*` = grupo de monstruos de campo (2-4), `!` = NPC o élite fija, `J` = jefe, `1` = huella de un edificio.
Boceto ligero: el `map-designer` puede mover islas, puentes y grupos mientras respete tamaños, salidas y zonas.

## Mapa

```
    00000000001111111111222222222233333333334444444444555555
    01234567890123456789012345678901234567890123456789012345
 0  ~~~~~~~~~~~~~~~~~~~~~~~~~~>>>~~~~~~~~~~~~~~~~~~~~~~~~~~~
 1  ~~~~~~~~~~~~~~~~~~~~~~~~~~ppp~~~~~~~~~~~............~~~~
 2  ~~~~~.........~~~~~~~~~~~~ppp~~~~~~~~~.......xx.......~~
 3  ~~~~...........~~~~~~~~~~~ppp~~~~~~~~..................~
 4  ~~~.TT..........~~~~~~~~~~ppp~~~~~~~~..^............^..~
 5  ~~..........T....~~~~~~~~~ppp~~~~~~~....................
 6  ~~....*..........~~~~~~~~~ppp~~~~~~~.........J..........
 7  ~~...............~~~~~~~~~ppp~~~~~~~....................
 8  ~~..........*....~~~~~~~~~ppp~~~~~~~....................
 9  ~~...............~~~~~~~~~ppp~~~~~~~...^............^...
10  ~~~.....ddd.....~~~~~~~...ddd...............ddd.........
11  ~~~~....ddT....~~~~~~.....ddd...............ddd.........
12  ~~~~~...ddd...~~~~~~......ddd.........*.....ddd.*.......
13  ~~~~~~~~ppp~~~~~~~~RR.....ddd...............ddd.........
14  ~~~~~~~~ppp~~~~~~~~.......ddddddddddddddddddddd.........
15  ~~~~~~~~ppp~~~~~~~..........ddddddddddddddddddd........~
16  ~~~~~~~~ppp~~~~~~~..........ddddddddddddddddddd........~
17  ~~~~~~~~ppp~~~~~~~..........ddd..+....................~~
18  ~~~~~~~~ppp~~~~~~~....+.....ddd.....................~~~~
19  ~~~~~~~~ppp~~~~~~~..........ddd..........~~~~~~~~~~~~~~~
20  ~~~~....ddd......~......*...ddd*.........~~~~~~~~~~~~~~~
21  ~~......ddd.................ddd..........~~~~~~~~~~~~~~~
22  ~.......ddd.*..R.........+..ddd....+.....~~~~~~~~~~~~~~~
23  ~.......ddd.................ddd..........~~~~~~~~~~~~~~~
24  ...R....ddd.................ddd.....*....~~~~~~~~~~~~~~~
25  ........ddd.................dd+..........~~~~~~~~~~~~~~~
26  >dddddddddddddddddddddddddddddd......R..~~~~~~~~~~~~~~~~
27  >dd@ddddddddddddddddddddddddddd.......R.~~~~~~~~~~~~~~~~
28  >dddd*ddddddddddddddddddddd*ddd........~~~~~~~~~~~~~~~~~
29  ........................R.............~~~~~~~~~~~~~~~~~~
30  .....R...............~~.............~~~~~~~~~~~~~~~~~~~~
31  ~...................~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
32  ~...................~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
33  ~~.................~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
34  ~~~~.............~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
35  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

## Zonas de nivel

| Id | Nombre | Nivel | Rectángulo aprox. |
|---|---|---|---|
| `laderas` | Laderas de los nidos (incluye el nido aislado del noroeste) | 52 | 0, 0, 18, 36 |
| `cascarones` | Campo de cascarones | 53 | 18, 10, 18, 26 |
| `cumbre` | Cumbre de la Matriarca | 54 | 36, 0, 20, 19 |

## Marcas

- `J` (45, 6): **Nixara** (`dragonMatriarch`), sprite grande (ver `bestiario.md`). Su meseta (40-51, 4-9) es
  despejada para que la embestida y el aliento se lean bien. Los braseros `x` (45-46, 2) son su nido en llamas.
- 10 grupos `*` ≈ 32 monstruos.

## Salidas

| Salida | Casillas | Lleva a | Llegada |
|---|---|---|---|
| Oeste | (0, 26-28) | `umbral.bastion` | (49, 17) del Bastión |
| Norte (puente) | (26-28, 0) | `umbral.rotas` | (6, 33) de las Islas Rotas |

Llegada desde el Bastión: `@` (3, 27). Desde las Islas Rotas: (27, 2).
