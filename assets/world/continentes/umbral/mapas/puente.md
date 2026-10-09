# Puente del Yunque (`umbral.puente`) — 58-59 · boceto

64×24. Calzada recta de 3 de ancho sobre el vacío, con dos **bastiones** amurallados (cada uno una sala de pelea con
braseros) y, al final, la explanada ante la **puerta del Yunque** (`e`, entre pináculos `^`). Tramos de puente `p`
entre islas: ahí el jugador no tiene por dónde rodear (los grupos `*` en los puentes son de 2, no más).

Leyenda: la de `bastion.md` (bioma `umbral`; `~` = vacío, `p` = puente de luz, `d` = sendero de piedra dorada,
`^` = pared de roca o torre, `R` = peñasco, `+` = estela / cascarón gigante, `x` = brasero, `e` = entrada a mazmorra,
`>` = salida). **Marcas solo de borrador** (en el código son suelo `.`): `@` = llegada y punto de reaparición,
`*` = grupo de monstruos de campo (2-4), `!` = NPC o élite fija, `J` = jefe, `1` = huella de un edificio.
Boceto ligero: el `map-designer` puede mover islas, puentes y grupos mientras respete tamaños, salidas y zonas.

## Mapa

```
    0000000000111111111122222222223333333333444444444455555555556666
    0123456789012345678901234567890123456789012345678901234567890123
 0  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 2  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~......~~~
 3  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~........~~
 4  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....^^^^.~
 5  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~wwwwwww~~~~~~~......^^^^..
 6  ~~~~~~~~~~~~~~~~~~~~wwwwwww~~~~~~~~~~wwwwwwwww~~~~~~......^^^^..
 7  ~~~~~~~~~~~~~~~~~~~wwwwwwwww~~~~~~~~...........~~~~~...x..^^^^..
 8  ~~.......~~~~~~~~~...........~~~~~~~..x..*..x..~~~~~......^^^^..
 9  ~....!.*..~~~~~~~~..x..*..x..~~~~~~~...........~~~~~......^^^^..
10  ...........~~~~~~~...........~~~~~~~...........~~~~~............
11  >##########ppppppp###########ppppppp###########ppppp#######e####
12  >##@#######ppp*ppp###########ppp*ppp###########pp*pp###J###e####
13  >##########ppppppp###########ppppppp##!########ppppp#######e####
14  ...........~~~~~~~...........~~~~~~~...........~~~~~............
15  ~.........~~~~~~~~..x..*..x..~~~~~~~...........~~~~~......^^^^..
16  ~~.......~~~~~~~~~...........~~~~~~~..x..*..x..~~~~~......^^^^..
17  ~~~~~~~~~~~~~~~~~~~wwwwwwwww~~~~~~~~...........~~~~~...x..^^^^..
18  ~~~~~~~~~~~~~~~~~~~~wwwwwww~~~~~~~~~~wwwwwwwww~~~~~~......^^^^..
19  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~wwwwwww~~~~~~~......^^^^..
20  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....^^^^.~
21  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~........~~
22  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~......~~~
23  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

## Zonas de nivel

| Id | Nombre | Nivel | Rectángulo aprox. |
|---|---|---|---|
| `cabeza` | Cabeza de puente | 58 | 0, 0, 18, 24 |
| `bastiones` | Bastiones del puente | 58 (1.º) · 59 (2.º) | 18, 0, 33, 24 |
| `puerta` | Puerta del Yunque | 59 | 51, 0, 13, 24 |

## Marcas

- `J` (55, 12): **Vesper** (`grandHerald`). Al vencerla se recupera el Ascua de Umbral (misión `umbral.gran_heraldo`).
- `e` (59, 11-13): **puerta del Yunque del Alba** → banda (piso `skyforge`). Se activa con `umbral.hoja_del_alba` hecha.
- `!` (5, 9): **Mariscal Hálvar** (`halvar`, `appearsWhen` `.questDone("umbral.observatorio")`) y sus hombres;
  la cabeza de puente es el `safePoint`.
- `!` (38, 13): **Hermana Brasa** encadenada en el 2.º bastión (`hermanaBrasa`, escena) y `cartaBrasa2` (`.clue`):
  misión `umbral.la_brasa`.
- 8 grupos `*` ≈ 22 monstruos (menos que en otras áreas, pero élites y herreros huecos).

## Salidas

| Salida | Casillas | Lleva a | Llegada |
|---|---|---|---|
| Oeste | (0, 11-13) | `umbral.observatorio` | (53, 29) del Observatorio |

Llegada: `@` (3, 12).
