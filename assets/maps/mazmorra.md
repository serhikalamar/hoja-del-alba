# Mazmorra de la arena

Responsable: `map-designer` (mapas) y `environment-artist` (arte).
Código: `src/GameCore/Sources/GameCore/Dungeon.swift` (pisos) y `src/GameTest1/Art/DungeonArt.swift` (arte).
Para verla: `make dungeon` → `tools/Harness/output/dungeon_<piso>.png`.

## Cómo funciona

- La arena es una mazmorra **más grande que la pantalla** (unas 2×2 pantallas); la cámara sigue al héroe.
- Los monstruos salen por las **puertas `G`** de las paredes y las **rejillas `h`** del suelo. El juego elige
  entradas que no se ven en pantalla y que no estén lejísimos, así que te rodean desde la oscuridad.
- Los enemigos **rodean los obstáculos** (camino más corto por casillas) y no disparan a través de paredes.
- El jefe entra por la **gran puerta `BBB`** cada 5 oleadas.
- Cada 5 oleadas se **baja un piso**; después del quinto se vuelve al primero (la profundidad sigue contando).

| Piso | Id | Tema | Idea |
|---|---|---|---|
| 1 | `prison` | Calabozos del castillo | Piedra gris, celdas con rejas, cadenas, agua sucia |
| 2 | `crypt` | Cripta de los reyes | Losas, sarcófagos, velas, abismo, luz fría |
| 3 | `sewer` | Cloacas inundadas | Ladrillo con musgo, canales de agua verde, puentes |
| 4 | `mine` | Mina de cristal | Roca, vías y vagonetas, cristales que brillan, abismo |
| 5 | `forge` | Forja de lava | Roca volcánica, ríos de lava, yunques, braseros |

## Los pisos

Coordenadas en casillas (columna, fila), con (0, 0) arriba a la izquierda. Los mapas están en `Dungeon.swift`
(`prisonRows`, `cryptRows`, …). Todos tienen la pared de arriba de 2 filas (tapa + cara con antorchas cada 5-7
casillas), muros interiores horizontales de 2 filas, pasillos y puentes de 3+ casillas y obstáculos separados
por 2+ casillas libres (o pegados a la pared). Varias rutas entre zonas: nunca hay una sola salida.

### 1. Calabozos del castillo (`prison`) — 44×22, 673 casillas pisables

- **Galería de celdas** (filas 2-8): sala larga bajo una pared llena de rejas `k`; cuatro pilares, dos braseros
  a los lados de la gran puerta del jefe (`BBB` en el centro de la pared norte), cadenas y huesos.
- **Muro de las celdas** (filas 9-10) con más rejas, antorchas y 2 puertas; tres pasos (4, 6 y 4 casillas).
- **Sala de guardia** (abajo a la izquierda): mesa de cajas, brasero, cofre, cajas en la esquina y una rejilla.
- **Sala de tortura** (abajo en el centro): cuatro braseros en cuadro y cadenas en el suelo. Aquí empieza el héroe (21, 15).
- **Aljibe** (abajo a la derecha): charca de agua sucia `~` con orillas de musgo y cajas.
- Entradas: 6 puertas `G` (4 arriba, 2 en el muro de las celdas) + 4 rejillas `h` = 10.

### 2. Cripta de los reyes (`crypt`) — 44×24, 769 casillas pisables

- **Santuario** (arriba): altar `AA` entre dos estatuas de reyes; la gran puerta `BBB` está justo detrás del altar
  (el jefe aparece en el santuario y tiene que rodearlo). Braseros a los lados.
- **Nave**: alfombra `r` desde el fondo sur hasta el altar, entre dos filas de tres pilares. Dos braseros al pie.
  El héroe empieza en la alfombra (22, 18).
- **Ala oeste**: abismo `~` en tres trozos cruzado por dos puentes `=` de 3×7; por el oeste y por arriba/abajo
  también se rodea (pasillo de 3).
- **Capillas del este**: tres capillas (cofre real, estatuas yacentes, urnas) separadas por muros de 2 filas con
  osarios `k`; cada una se abre a la nave y a la siguiente por el lado del muro exterior, así que forman un circuito.
- Entradas: 5 puertas `G` (3 arriba, 2 en las caras de las capillas) + 5 rejillas = 10.

### 3. Cloacas inundadas (`sewer`) — 46×22, 676 casillas pisables

- **Canal principal** de 3 filas de este a oeste, cruzado por tres puentes de 4 de ancho (columnas 6-9, 21-24, 36-39).
- **Canal norte**: nace bajo el desagüe enrejado `kkk` de la pared norte y tiene un puente de 3.
- **Canal sur**: baja hasta el sumidero y tiene otro puente de 3.
- Los canales parten el mapa en cuatro andenes conectados en anillo por los cinco puentes.
- Andenes con musgo `,` a lo largo del agua, barriles en las esquinas, pilares que sostienen la bóveda, braseros
  y un cofre. Gran puerta del jefe en el andén norte. El héroe empieza en el andén suroeste (22, 16).
- Entradas: 5 puertas `G` en la pared norte + 5 rejillas en los andenes = 10.

### 4. Mina de cristal (`mine`) — 44×24, 705 casillas pisables

- Formas orgánicas: salientes de roca en las paredes (con puerta y antorcha en el saliente norte), dos peñascos
  sueltos y un derrumbe al sur, todos de 2+ filas para que se vean con tapa y cara.
- **Túnel norte** (filas 2-8): ancho, con puntales `I`, braseros y cajas a los lados de la gran puerta del jefe.
- **Gran grieta** central (abismo irregular) con dos puentes de madera de 3 de ancho; se rodea por ambos extremos.
- **Pozo sin fondo** al suroeste y **caverna sur** con vagonetas/cajas, cofre y braseros. El héroe empieza en (22, 19).
- Entradas: 5 puertas `G` (4 arriba + 1 en el saliente) + 5 rejillas = 10.

### 5. Forja de lava (`forge`) — 46×24, 763 casillas pisables

- **Dos ríos de lava** de norte a sur (columnas 11-13 y 32-34) que bajan por rejas `kkk` de la pared norte; cada uno
  con tres puentes de 3 (a distintas alturas en cada río).
- **Sala del trono** (arriba, centro): gran puerta `BBB`, estatuas de reyes enanos, pilares y un brasero delante.
- Muro de 2 filas con antorchas y 4 puertas separa la sala del trono de las forjas (dos pasos de 4 en el centro).
- **Forja central**: cuatro yunques (`AA`) y el gran crisol (pozo de lava 4×2 con dos braseros). El héroe empieza en (23, 20).
- **Fundición** (oeste): cajas de mineral, braseros, cofre. **Armería** (este): tres yunques, brasero, cajas.
- Entradas: 6 puertas `G` + 5 rejillas = 11.

## Leyenda (`DungeonTile`)

| Carácter | Casilla | ¿Se pisa? |
|---|---|---|
| `#` | Pared (de frente si hay suelo debajo) | No |
| `t` | Pared con antorcha (luz) | No |
| `G` | Puerta de monstruos (salen por la casilla pisable de al lado) | No |
| `B` | Gran puerta del jefe (2-3 seguidas) | No |
| `k` | Rejas de celda en la pared | No |
| `.` | Suelo | Sí |
| `,` | Suelo agrietado, escombros, musgo | Sí |
| `b` | Huesos, cadenas, restos | Sí |
| `r` | Alfombra / camino ceremonial | Sí |
| `=` | Puente | Sí |
| `h` | Rejilla (también salen monstruos) | Sí |
| `~` | Líquido del tema (agua, lava, abismo) | No |
| `I` | Pilar | No |
| `s` | Estatua | No |
| `x` | Brasero (luz) | No |
| `c` | Cajas y barriles | No |
| `C` | Cofre | No |
| `A` | Altar (2 casillas: `AA`); en la forja se usa como yunque | No |

## Reglas

- Todas las filas igual de largas; el borde, cerrado (los tests lo comprueban).
- Todo el suelo conectado con la salida del héroe; al menos 6 entradas de monstruos y espacio de sobra
  (300+ casillas pisables).
- Entre 8 y 12 entradas (`G` + `h`) repartidas por todo el mapa; el `start` en una zona abierta, a 10+ casillas
  de la entrada más cercana.
- Obstáculos sueltos (pilares, estatuas, braseros, cajas) pegados a la pared o con 2+ casillas libres alrededor:
  nada de huecos de 1 casilla. Bloques de roca o muro interiores, de 2+ filas (tapa + cara).
- Pasillos de 3+ casillas y sin callejones estrechos: es un modo de supervivencia, hay que poder esquivar.
- Pared de arriba de 2 filas (tapa + cara). Antorchas cada 5-7 casillas para que no quede nada a oscuras.
- Tras cambiar un piso: `make test`, `make dungeon` (mirar el PNG) y `make balance` (sin "⚠︎ atasco").
