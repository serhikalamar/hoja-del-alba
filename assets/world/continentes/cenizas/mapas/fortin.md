# Mapa · `cenizas.fortin` — Fortín del Oasis (capital)

Borrador detallado del `continent-lead` de `cenizas` para el `map-designer`. **48 × 34** casillas. Zona segura
(sin monstruos). `kind: .town`, `biome: .cenizasOasis`, `continentID: "cenizas"`. Bioma oasis: `~` = agua humeante del oasis, `T` = palmera, `.` = arena clara, `,` = hierba del
oasis, `%` = matojo seco; fuera de la muralla la arena se va volviendo ceniza.

## Plano anotado (las cifras son edificios)

Coordenadas (columna, fila) desde (0, 0) arriba a la izquierda; las dos filas de arriba son las decenas y unidades
de la columna.

```
     000000000011111111112222222222333333333344444444
     012345678901234567890123456789012345678901234567
  0  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  1  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  2  ^..............................................^
  3  ^..wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww..^
  4  ^R.w...............1111111111...............w..^
  5  ^..w.222222..n.n...1111111111..n...3333333..wR.^
  6  ^.Tw.222222........1111111111...x..3333333..w..^
  7  ^..w.222222...x....1111111111......3333333..w..^
  8  ^..w.222222..n.n...1111111111..n.n.3333333..w.T^
  9  ^.Rw.222222........1111111111......3333333..w..^
 10  ^..w...##...........%.####.%..........#.....w..^
 11  ^..w...##......=l==============l=.....#.....w..^
 12  ^%.w...##%.....===T,,,,,,,,,,T===.....#..b..w.R^
 13  ^..w.+.##...b..===,,~~~~~~~~,,===.....#.....w..^
 14  ^.xw...##......===,~~~~~~~~~~,===.....#.....w..^
 15  >ddd###########=T=,~~~~~~~~~~,=T=###########w..^
 16  >ddd###########===,~~~~~~~~~~,===###########w..^
 17  >ddd###########===,~~~~~~~~~~,===###########w.%^
 18  ^.xw...........===,,~~~~~~~~,,===..444444...w..^
 19  ^..w.x......b..===T,,,,,,,,,,T===..444444.b.w..^
 20  ^T.w.5555555...==================..444444...w..^
 21  ^..w.5555555.+.==================..444444...w..^
 22  ^..w.5555555...=l==============l=..444444...wR.^
 23  ^..w.5555555..........####...........#......w..^
 24  ^R.w.5555555.+....m...####..m........#......w..^
 25  ^.Tw....#........c....####...c..ffff...ffff.w..^
 26  ^..w....#.....%...m...####..m...f.......+.f.wT.^
 27  ^..w..b...b...........####....%.f.c..e....f.w.R^
 28  ^.Rw..........b....c..####......f..R....c.f.w..^
 29  ^..w..................####......fffffffffff.w..^
 30  ^.%wwwwwwwwwwwwwwwwwwwddddwwwwwwwwwwwwwwwwwww%.^
 31  ^R...................xddddx.................%.R^
 32  ^.....................dddd.....................^
 33  ^^^^^^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^^^^^^^^^
```

## Leyenda usada

| Carácter | Casilla | ¿Se pisa? | Notas |
|---|---|---|---|
| `.` | Arena clara (bioma oasis) | Sí | |
| `,` | Hierba del oasis | Sí | Anillo verde alrededor del agua |
| `#` | Calle de losas de basalto | Sí | |
| `=` | Plaza de losas | Sí | Plaza del Oasis |
| `d` | Camino de tierra | Sí | Nuevo (M5) |
| `%` | Matojo seco (decorativo) | Sí | Nuevo (M5) |
| `e` | Bajada (`cave`) | Sí | Solo decorativa aquí: la Cata se hace como **edificio** sin muros (ver abajo) para que lleve a un interior; si el motor permite `e` → interior, se deja la `e` |
| `>` | Salida a otra área (`areaExit`) | Sí | `fortin.oeste` → Costa · `fortin.sur` → Dunas |
| `~` | Agua humeante (oasis) | No | Vapor animado (environment-artist) |
| `T` | Palmera | No | |
| `w` | Muralla de adobe y piedra negra | No | |
| `^` | Peña / acantilado de basalto | No | Nuevo (M5) |
| `R` | Roca | No | Nuevo (M5) |
| `n` | Tienda de campaña (lona) | No | Nuevo (M5) |
| `x` | Brasero (luz) | No | Nuevo (M5) |
| `+` | Estela / poste / muñeco de prácticas | No | Nuevo (M5). (5,13) = poste del maestro de viajes; (40,26) = estaca de la excavación; (13,21) y (13,24) = muñecos |
| `l` | Farol | No | |
| `b` | Arbusto | No | |
| `m` | Puesto de mercado | No | Mercadillo de Zigo |
| `c` | Cajas | No | |
| `f` | Valla (andamios de la Cata) | No | |
| `1`-`5` | Edificios (en el código: `.` debajo + `Building`) | No | Ver tabla |

## Edificios (`Building`)

| # | Id | Nombre | Estilo | x, y, ancho, alto | Puerta (x, ancho) | Interior |
|---|---|---|---|---|---|---|
| 1 | `mando` | Puesto de mando | `fortTent` (*nuevo*; `placeholder` = `castle`) | 19, 4, 10, 6 | 23, 2 | `cenizas.fortin.mando` |
| 2 | `forja` | Forja de Tova | `smithy` | 5, 5, 6, 5 | 7, 2 | `cenizas.fortin.forja` |
| 3 | `posada` | Posada *La Cantimplora* | `inn` | 35, 5, 7, 5 | 38, 1 | `cenizas.fortin.posada` |
| 4 | `archivo` | Archivo de la expedición | `alchemist` (o `adobeHouse`) | 35, 18, 6, 5 | 37, 1 | `cenizas.fortin.archivo` |
| 5 | `barracon` | Barracón de la guardia | `adobeHouse` (*nuevo*; `placeholder` = `house`) | 5, 20, 7, 5 | 8, 1 | `cenizas.fortin.barracon` |

La **Cata** es el recinto vallado (32-42, 25-29). Para el motor actual va como edificio `cata` de 1×1 sobre la `e`
(37, 27), estilo `digSite` (*nuevo*; `placeholder` = `house`), puerta en (37, 1) → `cenizas.fortin.cata`.
Estilos con aspecto propio de Cenizas (adobe, toldos, cúpula) los pide `encargos.md` al `environment-artist`.

## Salidas y llegadas

| Salida | Casillas | Lleva a | Llegada en el destino |
|---|---|---|---|
| `fortin.oeste` | (0, 15-17) | `cenizas.costa` | (53, 13) |
| `fortin.sur` | (22-25, 33) | `cenizas.dunas` | (27, 2) · `lock: .questDone("cenizas.rastro_de_ozran")` |
| Viaje en barco | poste (5, 13), NPC `margaCapitana` | Capitales visitadas · (tras el final) Hielomar | — |
| `safePoint` | (38, 10), delante de la posada | — | Reaparición (M9) |

Llegadas a este mapa: desde la Costa en (2, 16); desde las Dunas en (23, 31). `entry` del pueblo (viajes): (23, 25).

## NPC

| Id | Dónde | Casilla | Notas |
|---|---|---|---|
| `princess` | Interior `mando` | — | Misión principal. Fuera de él, en la plaza (24, 11) mientras no haya interior |
| `dornaComandante` | Delante del puesto de mando | (26, 10) | `.questGiver` |
| `thessa` | Junto a la Cata | (36, 24) | `.questGiver`; `appearsWhen: nil` (llega con Aurora) |
| `tovaHerrera` | Interior `forja` | — | Forja tier 4 (`.questGiver` además) |
| `sedraPosadera` | Interior `posada` | — | Posadera |
| `zigoMercader` | Mercadillo | (20, 25) | Tienda de baratijas; `.questGiver` |
| `margaCapitana` | Poste del maestro de viajes | (6, 13) | Maestra de viajes (mecánica de Frida) |
| `guardiaFortin1`, `guardiaFortin2` | Puertas | (4, 14) y (21, 29) | Diálogo de ambiente |
| `yaliaGuia` | Plaza (solo tras el final) | (30, 20) | `appearsWhen: .questDone("cenizas.cuarta_brasa")` |
| `brokk` | Interior `forja` | — | `appearsWhen: .questDone("cenizas.emperador_ceniciento")`; despierta la Hoja del Alba (IV) |

## Interior · `cenizas.fortin.cata` (16 × 9) — borrador

`M` = sitio del mural: en el código es pared `X` y delante, en (7, 2), un NPC `.clue` **`muralCata`** (look `mural`) que se lee al acercarse.

```
XXXXXXXXXXXXXXXX
XXXXXXXMMXXXXXXX
X::::::::::::::X
X:I::::::::::I:X
X::::o::::t::::X
X:::::::::::::oX
X:I::::::::::I:X
X::::::::::::::X
XXXXXXXDDXXXXXXX
```

Andamios (`I`), un barril y la mesa de dibujo de Ozrán (con su lápiz roto). Sin enemigos. El mural (7-8, 1) muestra
un sol negro sobre una ciudad en llamas. Entrada/salida `D` en (7-8, 8).

## Filas para el código (`AreaMap.rows`, edificios ya como `.`)

```swift
"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
"^..............................................^",
"^..wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww..^",
"^R.w........................................w..^",
"^..w.........n.n...............n............wR.^",
"^.Tw............................x...........w..^",
"^..w..........x.............................w..^",
"^..w.........n.n...............n.n..........w.T^",
"^.Rw........................................w..^",
"^..w...##...........%.####.%..........#.....w..^",
"^..w...##......=l==============l=.....#.....w..^",
"^%.w...##%.....===T,,,,,,,,,,T===.....#..b..w.R^",
"^..w.+.##...b..===,,~~~~~~~~,,===.....#.....w..^",
"^.xw...##......===,~~~~~~~~~~,===.....#.....w..^",
">ddd###########=T=,~~~~~~~~~~,=T=###########w..^",
">ddd###########===,~~~~~~~~~~,===###########w..^",
">ddd###########===,~~~~~~~~~~,===###########w.%^",
"^.xw...........===,,~~~~~~~~,,===...........w..^",
"^..w.x......b..===T,,,,,,,,,,T===.........b.w..^",
"^T.w...........==================...........w..^",
"^..w.........+.==================...........w..^",
"^..w...........=l==============l=...........wR.^",
"^..w..................####...........#......w..^",
"^R.w.........+....m...####..m........#......w..^",
"^.Tw....#........c....####...c..ffff...ffff.w..^",
"^..w....#.....%...m...####..m...f.......+.f.wT.^",
"^..w..b...b...........####....%.f.c..e....f.w.R^",
"^.Rw..........b....c..####......f..R....c.f.w..^",
"^..w..................####......fffffffffff.w..^",
"^.%wwwwwwwwwwwwwwwwwwwddddwwwwwwwwwwwwwwwwwww%.^",
"^R...................xddddx.................%.R^",
"^.....................dddd.....................^",
"^^^^^^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^^^^^^^^^"
```

## Comprobación

- Todas las filas de 48; el borde es `^` salvo las salidas `>`.
- 973 casillas pisables, **todas conectadas** (comprobado con un relleno desde (23, 25)).
- Caminos de 3+ casillas en las dos calles principales; la plaza rodea el oasis por los cuatro lados.
