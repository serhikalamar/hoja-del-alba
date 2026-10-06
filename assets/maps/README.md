# Mapas

Responsable: `map-designer`.

- **Fuente de verdad**: `src/GameCore/Sources/GameCore/Town.swift` (lo que se juega).
- **Este directorio**: diseño, rutas y notas de cada mapa (`valdehierro.md`) y `borradores/`, donde dejas
  tus mapas (imagen, dibujo, texto… cualquier formato). El `map-designer` los pasa al juego.
- Para ver el mapa actual tal y como se dibuja: `make maps` → `tools/Harness/output/map_town.png`.

## Formato del mapa en el juego

Un carácter por casilla de 24×24 pixeles. Exterior: `.` `,` hierba, `#` calle, `=` plaza, `T` árbol,
`w` muralla, `S` escalinata, `l` farola, `b` arbusto, `m` puesto, `c` cajas, `F` fuente (2×2), `~` agua,
`f` valla. Interior: `X` pared, `_` madera, `:` piedra, `r` alfombra, `s` estantería, `k` horno, `t` mesa,
`z` cama, `o` barril, `I` columna, `Y` trono, `D` salida.

Edificios, zonas, enemigos y aldeanos se colocan por (columna, fila), contando desde 0 arriba a la izquierda.

## Cómo preparar un borrador

Lo más cómodo para pasarlo al juego:
1. Una cuadrícula (papel, hoja de cálculo o texto) con un símbolo por casilla, usando la leyenda de arriba.
2. Edificios marcados como rectángulos con su nombre y dónde está la puerta.
3. Zonas con nombre y dificultad aproximada (fácil → difícil).
4. Qué hay dentro de cada casa: quién está atrapado y qué enemigos.

Cualquier dibujo vale: el `map-designer` lo traduce y te devuelve el render para revisarlo.
