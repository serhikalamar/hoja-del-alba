# Observatorio de los Herreros (`umbral.observatorio`) — 56-58 · boceto

56×36. Gran isla con jardines de cristal; en el centro, el **patio de los astrolabios** amurallado (`w`, plaza `=`,
astrolabios `R` y estelas `+`) y al norte la **cúpula** (`1`, edificio con interior). Territorio de la élite del Eclipse.

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
 2  ~~~~~~~~~~~~~~~~~~~~~~.........111111111.........~~~~~~~
 3  ~~~~~~~~~~~~~~~~~~~~...........111111111...........~~~~~
 4  ~~~~~~~~~~~~~~~~~~.............111111111.............~~~
 5  ~~~~~~~~~~~~~~~~~~.............111111111.............~~~
 6  ~~~~~~~~~~~~~~~~~...TT....wwwww111111111wwwww.........~~
 7  ~~~~~~~~~~~~~~~~~.........wwwwwwww###wwwwwwww.........~~
 8  ~~~~~~~~~~~~~~~~..........wwwwwwww###wwwwwwww..........~
 9  ~~~~~~~~~~~~~~~~..........w=================w..........~
10  ~~~~~~~~~~~~~~~~..........w========x========w..........~
11  ~~~~~~~~~~~~~~~~..........w===R=========R===w..........~
12  ~~~.........~~~~..........w======+===+======w...*......~
13  ~~...........~~~..........w=====*==!========w..........~
14  ~.............~~........*.w=================w..........~
15  ...............~..........w===R=======*=R===w..........~
16  ...............~..........w=================w..........~
17  >ddddddddddddddpddddddddddddddddd===========w..........~
18  >ddd@ddddddddddpdddddddddddddddddw###wwwwwwww.....*....~
19  >ddddddddddddddpdddddddddddddd########.................~
20  ...............~...*...............###.................~
21  ...............~...................###.................~
22  ~.............~~...................###..........TT.....~
23  ~~...........~~~...................###.................~
24  ~~~.........~~~~......*............###....*............~
25  ~~~~~~~~~~~~~~~~............*......###.................~
26  ~~~~~~~~~~~~~~~~...................###.............*...~
27  ~~~~~~~~~~~~~~~~....T..............###.................~
28  ~~~~~~~~~~~~~~~~~..................dddddddddddddddddddp>
29  ~~~~~~~~~~~~~~~~~.....T............dddddddddddddddddddp>
30  ~~~~~~~~~~~~~~~~~~.....*...........ddddddddddd*ddddddpp>
31  ~~~~~~~~~~~~~~~~~~.................###...............~~~
32  ~~~~~~~~~~~~~~~~~~~~...............###.............~~~~~
33  ~~~~~~~~~~~~~~~~~~~~~~...........................~~~~~~~
34  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
35  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

## Zonas de nivel

| Id | Nombre | Nivel | Rectángulo aprox. |
|---|---|---|---|
| `rellano` | Rellano de llegada | 56 | 0, 10, 16, 16 |
| `jardines` | Jardines de cristal | 57 | 16, 0, 40, 36 (menos el patio) |
| `patio` | Patio de los astrolabios | 58 | 26, 6, 19, 13 |

## Edificio

| Id | Nombre | Estilo | x, y | Ancho × alto | Puerta | Interior |
|---|---|---|---|---|---|---|
| `cupula` | Cúpula de la Gran Lente | `skyDome` (nuevo; `placeholder` `castle`) | 31, 2 | 9 × 5 | 35, 1 (da al patio por (34-36, 7-8)) | `umbral.observatorio.cupula` (nivel 58) |

Interior `umbral.observatorio.cupula` (≈18×12, `level` 58): suelo de piedra `:`, alfombra `r` hasta la Gran Lente (un
`Y` en el centro, vacía y apagada), columnas `I`, estanterías `s`. Dentro: 2 `eclipseProphet` y **Corvino**
(`starHerald`, jefe). Tras vencerlo: la `notaVesper` (`.clue`) junto a la Lente, **Fíbula** (`appearsWhen`
`.questDone("umbral.observatorio")`) y la estatua de cristal de Corvino (decorado).

## Marcas

- `!` (35, 13): **Campeón del Eclipse** (élite fija que guarda el paso a la cúpula: spawn permanente de
  `eclipseKnight`; si el motor permite variar la escala por spawn, ×1,5). No reaparece.
- 12 grupos `*` ≈ 34 monstruos.
- El patio tiene dos accesos: el sendero del oeste (fila 17) y la puerta sur (34-36, 18).

## Salidas

| Salida | Casillas | Lleva a | Llegada |
|---|---|---|---|
| Oeste | (0, 17-19) | `umbral.rotas` | (57, 11) de las Islas Rotas |
| Este | (55, 28-30) | `umbral.puente` | (2, 12) del Puente del Yunque |

Llegada desde las Islas Rotas: `@` (4, 18). Desde el Puente: (53, 29).
