# Islas Rotas (`umbral.rotas`) — 54-56 · boceto

60×36. Siete fragmentos de isla unidos por puentes de luz estrechos (2 de ancho: aquí se nota el vértigo). Al este,
la **Boca de la Grieta**: pared de roca `^` con la entrada `e` a la mazmorra (piso `void`) entre dos braseros.

Leyenda: la de `bastion.md` (bioma `umbral`; `~` = vacío, `p` = puente de luz, `d` = sendero de piedra dorada,
`^` = pared de roca o torre, `R` = peñasco, `+` = estela / cascarón gigante, `x` = brasero, `e` = entrada a mazmorra,
`>` = salida). **Marcas solo de borrador** (en el código son suelo `.`): `@` = llegada y punto de reaparición,
`*` = grupo de monstruos de campo (2-4), `!` = NPC o élite fija, `J` = jefe, `1` = huella de un edificio.
Boceto ligero: el `map-designer` puede mover islas, puentes y grupos mientras respete tamaños, salidas y zonas.

## Mapa

```
    000000000011111111112222222222333333333344444444445555555555
    012345678901234567890123456789012345678901234567890123456789
 0  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 2  ~~~~..........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 3  ~~~............~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 4  ~~..............~~~~~~~~~~~~~~~~~~~~~~~.........~~~~~~~~~~~~
 5  ~~..............~~~~~~~~~~~~~~~~~~~~~~...........~~~~~~~~~~~
 6  >pddddddd.......~~~~~........~~~~~~~~...........*.~~~~....~~
 7  >pddddddd.......~~~~..........~~~~~~.....R.........~~......~
 8  >pddddddd.......~~~...*.....R..~~~~~....*..........~........
 9  ~~..............~~..............~~~~...............~........
10  ~~......ddddddddppdddddddd......~~~~............dddpddd*ddd>
11  ~~......ddddddddppdddddddd......~~~~............dddpddddddd>
12  ~~~............~~~......dd...dddppppdddddddd..dddddpddddddd>
13  ~~~~..........~~~~......dd...dddpppppddddddd..dd..~~........
14  ~~~~~~~~~~~~~~~~~~.....Rdd......~~~~~~........dd.~~~~......~
15  ~~~~~~~~~~~~~~~~~~......dd......~~~~~~~.......dd~~~~~~....~~
16  ~~~~~~~~~~~~~~~~~~~.....dd..*..~~~~~~~~~~~~~~~pp~~~~~~~~~~~~
17  ~~~~~~~~~~~~~~~~~~~~....dd....~~~~~~~~~~~~~~~~pp~~~~~~~~~~~~
18  ~~~~~~~~~~~~~~~~~~~~~...dd...~~~~~~~~~~~~~~~~~pp~~~~~~~~~~~~
19  ~~~~~~~~~~~~~~~~~~~~~~~~pp~~~~~~~~~~~~~~~~....dd....~~~~~~~~
20  ~~~~~~~~~~~~~~~~~~~~~~~~pp~~~~~~~~~~~~~~......dd......~~~~~~
21  ~~~~~~~~~~~~~~~~~~~~~~~~pp~~~~~~~~~~~~~......!dd.......~~~~~
22  ~~~~~~~~~~~~~~~~~~~~~~~.dd......~~~~~~~..*....dd....R..~~~~~
23  ~~~~~~~~~~~~~~~~~~~~~~..dd.......~~~~~......^^^^^^......~~~~
24  ~~~...ddddddpppppppppddddd.....*..~~~~......^^^^^^......~~~~
25  ~~....dddddddpppppppdddddd.........~~~.....x..ee..x.....~~~~
26  ~.....ddd.....~~~~~~...............~~~........dd........~~~~
27  ......ddd..*...~~~~~..........dddddpppdddddddddd........~~~~
28  ......dd!......~~~~~......TT..dddddpppdddddddd.......*..~~~~
29  ......ddd.R....~~~~~...............~~~..................~~~~
30  ....*.ddd......~~~~~....*..........~~~~.*....R.........~~~~~
31  ......ddd......~~~~~~.............~~~~~................~~~~~
32  .....@ddd......~~~~~~~...........~~~~~~~..............~~~~~~
33  ~.....ddd.....~~~~~~~~~.........~~~~~~~~~~..........~~~~~~~~
34  ~~....ddd....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
35  ~~~..>>>d...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

## Zonas de nivel

| Id | Nombre | Nivel | Rectángulo aprox. |
|---|---|---|---|
| `embarcadero` | Embarcadero roto e isla del puente | 54 | 0, 0, 17, 36 |
| `fragmentos` | Fragmentos e isla del sauce del vacío | 55 | 17, 0, 19, 36 |
| `boca` | Boca de la Grieta y fragmento alto | 56 | 36, 0, 24, 36 |

## Marcas

- `e` (46-47, 25): entrada a la **Grieta del vacío** (mazmorra, M8). Cuenta para `umbral.la_grieta`.
- `!` (8, 28): explorador de Hálvar (relleno). `!` (45, 21): **Fíbula** (aparece aquí durante `umbral.la_grieta`).
- 12 grupos `*` ≈ 36 monstruos. Los `voidEye` (a distancia) mejor en los fragmentos con puente estrecho delante.
- Los bordes del vacío no matan: son sólidos (`~`). *Idea opcional* (motor): casillas que "se desmoronan" — no hace
  falta para jugarlo.

## Salidas

| Salida | Casillas | Lleva a | Llegada |
|---|---|---|---|
| Sur | (5-7, 35) | `umbral.nidos` | (27, 2) de los Nidos |
| Oeste (puente de luz) | (0, 6-8) | `umbral.bastion` (puerta norte) | (25, 2) del Bastión — solo tras `umbral.puente_de_luz` |
| Este | (59, 10-12) | `umbral.observatorio` | (2, 18) del Observatorio |

Llegada desde los Nidos: `@` (5, 32). Desde el Bastión: (3, 7). Desde el Observatorio: (57, 11).
