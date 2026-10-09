# Velaluna (`lunaria.velaluna`) — mapa detallado (borrador)

Capital élfica en las copas. **56 × 36** casillas. Zona segura (sin monstruos). Formato: `assets/maps/README.md`
más los caracteres de exterior de `assets/world/continentes.md` (`d p R ^ + n x e >`).

## Bioma `lunariaCanopy` (propuesta; *necesidad de motor* N1)

Velaluna está a 30 m del suelo. Los caracteres de siempre se dibujan así en este bioma:

| Carácter | En Velaluna | ¿Se pisa? |
|---|---|---|
| `.` | Plataforma de tablas de plata con musgo | Sí |
| `=` | Plaza de la Luna: tablas claras en círculos, con runas | Sí |
| `#` | Pasarela principal (tablas anchas con barandilla a los lados) | Sí |
| `d` | Senda de hojas (tablas más estrechas, hojas caídas) | Sí |
| `S` | Escalinata de raíz labrada (sube al palacio) | Sí |
| `p` | Puente colgante de cuerda y tablas (cruje y se balancea un poco) | Sí |
| `~` | **Vacío entre copas**: se ve el suelo del bosque muy abajo, entre hojas y niebla azul | No |
| `T` | Tronco de árbol de plata gigante con su copa (el borde del mapa es un muro de copas) | No |
| `b` | Maceta de helechos plateados | No |
| `,` | Setas luminosas en la tabla (decorativo, emite luz azul suave) | Sí |
| `l` | Farolillo de luna (luz fría) | No |
| `F` | Pila de luz lunar 2×2 (fuente: agua que brilla; se apaga en las misiones 2-10 y vuelve en la 12) | No |
| `m` | Percha de búho / puesto de la maestra de vuelos | No |
| `x` | Brasero de luna (luz) | No |
| `c` | Cajas y fardos de seda | No |
| `>` | Salida a otra área | Sí |
| `1`-`6` | **Solo en el borrador**: huella de un edificio (el `map-designer` lo pone como `.` y crea el `Building`) | — |

## Mapa

```
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TT~~~~~~~~~~~~~~....1111111111111111....~~~~~~~~~~~~~~TT
TT~~~~~~~~~~~~~~.T..1111111111111111..T.~~~~~~~~~~~~~~TT
TT..........pppp....1111111111111111....pppp..........TT
TT.,........pppp....1111111111111111....pppp........,.TT
TT........T.pppp....1111111111111111....pppp.T........TT
TT.2222222..~~~~....1111111111111111....~~~~.555555...TT
TT.2222222..~~~~....1111111111111111....~~~~.555555...TT
TT.2222222..~~~~########################~~~~.555555...TT
TT.2222222..~~~~##l##################l##~~~~.555555..TTT
TT.2222222..~~~~~~~~~~~~~SSSSSS~~~~~~~~~~~~~.555555...TT
TT..........~~~~~~~~~~~~~SSSSSS~~~~~~~~~~~~~..........TT
TT...dd.....~~l=========l======l=========l~~....dd....>>
TT.T.dd.....~~=b========================b=~~dddddddddd>>
TT...dddddddpp======b==============b======ppdddddddddd>>
TT...dddddddpp============================ppdddddd....TT
TT.333333dddpp============================pp....dd....TT
TT.333333...~~=============FF=============~~..666666..TT
TT.333333...~~=============FF=============~~..666666..TT
TT.333333...~~============================~~..666666..TT
TT.333333.T.~~============================~~..666666.TTT
TT...dd.....~~======b==============b======~~..666666..TT
TT.4444444..~~=b========================b=~~....dd....TT
TT.4444444..~~==T========================T~~....dd....TT
TT.4444444..~~~~~~~~~~~~~######~~~~~~~~~~~~~..x.dd.x..TT
TT.4444444..~~~~~~~~~~~~~######~~~~~~~~~~~~~....dd....TT
TT.4444444..~~~~~~~~..l..........l..~~~~~~~~.m.mddm.m.TT
TT...dd.....~~~~~~~~......####......~~~~~~~~....dd....TT
TT...dd.....~~~~~~~~......####......~~~~~~~~.c..dd..c.TT
TT..........pppppppp......####......pppppppp..........TT
TT.,......,.pppppppp......####......pppppppp.,......,.TT
TT..........pppppppp.,....####....,.pppppppp..........TT
TT~~~~~~~~~~~~~~~~~~.....l####l.....~~~~~~~~~~~~~~~~~~TT
TTTTTTTTTTTTTTTTTTTTTTTTTT>>>>TTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTT>>>>TTTTTTTTTTTTTTTTTTTTTTTTTT
```

Filas 0-35, columnas 0-55 (contando desde 0 arriba a la izquierda). Todas las filas miden 56.

## Partes de la ciudad

- **Plataforma del Palacio** (norte, filas 2-10): el palacio ocupa casi todo; pasarela `#` delante con dos farolillos.
  Puentes colgantes de 4×3 al oeste (12-15, 4-6) y al este (40-43, 4-6) hacia los barrios.
- **Escalinata de raíz** (25-30, 11-12): baja del palacio a la plaza.
- **Plaza de la Luna** (14-41, 13-24): plaza central con la Pila de luz lunar `FF` (27-28, 18-19), farolillos en las
  esquinas, macetas. Aquí están Aurora, Sylra e Ysolde.
- **Barrio de las Hojas** (oeste, 2-11, 4-32): posada, hierbera y santuario a lo largo de una senda `d`.
  Puente a la plaza (12-13, 15-17) y puente largo al ascensor (12-19, 30-32).
- **Barrio de la Forja** (este, 44-53, 4-32): forja élfica, torre de Ysolde y las perchas de búhos (maestra de vuelos).
  Puente a la plaza (42-43, 15-17), puente largo al ascensor (36-43, 30-32) y **salida este** `>>` (54-55, 13-15).
- **Plataforma del Gran Ascensor** (sur, 20-35, 27-33): llegada desde Raíces. Pasarela `#` a la plaza (25-30, 25-26).
  **Salida sur** `>>>>` (26-29, 34-35) = el ascensor de raíces que baja a `lunaria.raices`.

Rutas: tres anillos (palacio-oeste-plaza, plaza-oeste-ascensor, plaza-este-ascensor); nunca hay un solo camino.

## Edificios

| N.º | Id | Nombre | Estilo | x, y, ancho × alto | Puerta (x, ancho) | Interior |
|---|---|---|---|---|---|---|
| 1 | `velalunaPalace` | Palacio de la Reina | `castle` (variante élfica) | 20, 2, 16×7 | 27, 2 | `lunaria.velaluna.palacio` |
| 2 | `velalunaInn` | Posada La Hoja Dormida | `inn` | 3, 7, 7×5 | 6, 1 | `lunaria.velaluna.posada` |
| 3 | `velalunaHerbalist` | Casa de la hierbera | `house` | 3, 17, 6×5 | 5, 1 | `lunaria.velaluna.hierbera` |
| 4 | `velalunaShrine` | Santuario de la Luna | `chapel` | 3, 23, 7×5 | 6, 1 | `lunaria.velaluna.santuario` |
| 5 | `velalunaForge` | Forja élfica | `smithy` | 45, 7, 6×5 | 47, 1 | `lunaria.velaluna.forja` |
| 6 | `ysoldeTower` | Torre de la Archimaga | `alchemist` (torre alta y estrecha) | 46, 18, 6×5 | 48, 1 | `lunaria.velaluna.torre` |

Estilos élficos (tejados de hoja, paredes de corteza plateada, ventanas redondas con luz azul) = variante de bioma
de los estilos existentes (*necesidad de motor* N1, `environment-artist`).

## Llegadas, salidas y puntos

| Qué | Casillas | Lleva a / notas |
|---|---|---|
| Salida sur (Gran Ascensor) | (26-29, 34-35) | `lunaria.raices`, llegada en la base del ascensor (norte de Raíces) |
| Salida este (Pasarela del Este) | (54-55, 13-15) | `lunaria.claros`, llegada al noroeste de Claros |
| Llegada desde Raíces | (27, 32) | `entry` por defecto del área |
| Llegada desde Claros | (52, 14) | |
| Reaparición | (6, 12) | delante de la posada |

## NPC (exterior)

| Id | Nombre | Posición | Notas |
|---|---|---|---|
| `princess` | Princesa Aurora | (24, 16) | Misiones 4 y 12 |
| `sylra` | Capitana Sylra | (27, 14) | Pie de la escalinata. Misiones 3, `telaranas`, `arqueros_y_danzantes` |
| `ysolde` | Ysolde, la Archimaga | (30, 21) | Junto a la pila. Desaparece tras la misión 8 |
| `ilmar` | Guardabosques Ilmar | (23, 30) | Junto al ascensor. `ciervos_corruptos` |
| `mirla` | Mirla la hierbera | (8, 22) | Delante de su casa. `setas_y_espinos` |
| `nimra` | Nimra, maestra de vuelos | (49, 28) | Maestro de viajes (búhos) |
| — | 2 guardias élficos de ambiente | (25, 25) y (30, 25) | A los lados de la pasarela del ascensor; frases de desconfianza para el hombre lobo |

## Interiores (resumen; el `map-designer` los dibuja con la leyenda de interior)

| Id | Tamaño | Contenido |
|---|---|---|
| `lunaria.velaluna.palacio` | 20×12 | Salón del trono de ramas (`Y`), alfombra `r` hasta la puerta, pilares-tronco `I`. Reina Elarith en el trono. |
| `lunaria.velaluna.posada` | 14×10 | Barra, mesas `t`, barriles `o`, camas `z` arriba. Ennis. Reaparición. |
| `lunaria.velaluna.hierbera` | 8×7 | Estanterías de frascos `s`, mesa con setas. (Mirla está fuera.) |
| `lunaria.velaluna.santuario` | 12×10 | Suelo de piedra `:`, altar de luna, Hermana Liria. |
| `lunaria.velaluna.forja` | 12×9 | Horno `k`, yunque, estantes `s`. Fendril (tienda tier 3) y Brokk (ritual + despertar de la Hoja). |
| `lunaria.velaluna.torre` | 10×10 | Biblioteca de Ysolde: estanterías `s`, mesa de alquimia `t`. Tras la misión 8: libros caídos y un cofre con una carta (diálogo). Sin monstruos. |
