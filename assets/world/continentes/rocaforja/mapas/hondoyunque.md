# Hondoyunque (`rocaforja.hondoyunque`) — capital, borrador detallado

Ciudad enana excavada en la montaña. **Zona segura** (sin monstruos). 56×34 casillas, 1 239 pisables, todo conectado
(comprobado con un relleno desde la puerta sur). Lo pasa al juego el `map-designer` (fichero nuevo, p. ej.
`Rocaforja.swift`; no tocar `Town.swift`).

**Bioma `rocaforjaHall`** (cómo se dibuja cada carácter aquí): `.` suelo de roca tallada · `#` losas de la calle ·
`=` plaza de losas grandes con mosaico de yunque · `^` pared de la caverna (tapa + cara, con vetas) · `~` **lava**
(canal de la Gran Forja, ilumina) · `p` puente de piedra · `d` **vía de vagoneta** (raíles, se pisa) · `F` gran crisol
de lava (2×2, fuente de la plaza) · `I` columna colosal tallada · `+` estatua de un Thane · `S` escalinata ·
`l` lámpara de aceite en poste · `x` brasero · `c` cajas / vagoneta cargada · `m` puesto del mercado · `f` valla de
madera · `R` peñasco · `>` salida. **Dígitos** = huella de un edificio (no son casillas: el edificio se coloca encima,
como en `Town.swift`, con la puerta en su fila de abajo).

Techo: oscuro, sin cielo. Luz de braseros, lámparas y lava; el `environment-artist` puede añadir haces de luz de
lumbreras en la plaza.

```
     0         1         2         3         4         5     
     01234567890123456789012345678901234567890123456789012345
  0  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  1  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  2  ^......................................................^
  3  ^...2222222..........11111111111111.....66666666.......^
  4  ^...2222222..RR....I.11111111111111.I...66666666.......^
  5  ^...2222222..RR......11111111111111.....66666666.......^
  6  ^...2222222..........11111111111111.....66666666.......^
  7  ^...2222222..........11111111111111.....66666666.......^
  8  ^..x.......x.......I.11111111111111.I...66666666.......^
  9  ^..............~~....11111111111111.......##.........x.^
 10  ^..............~~.......+.SSSS.+......#################>
 11  ^..............~~.........SSSS........#################>
 12  ^...333333333x.pp.........####........#################>
 13  ^...333333333..pp.=====l========l=====..44444444.5555x.^
 14  ^...333333333..pp.=I================I=..44444444.55555.^
 15  ^...333333333..~~.====================..44444444.55555.^
 16  ^...333333333..~~.====================..44444444.55555.^
 17  ^...333333333..~~.=========FF=========..44444444.55555.^
 18  ^..x.........x.~~.=========FF=========..44444444.......^
 19  ^...cc.........~~.====================##########.......^
 20  >##############pp.====================##########.......^
 21  >ddddddddddddddddd=I================I=......l...ffffff.^
 22  >###########l##pp.=====l========l=====..........f....f.^
 23  ^..............~~.........####.......................f.^
 24  ^..777777.cc...~~...m.m...####...m.m.................f.^
 25  ^..777777................l####l.................f....f.^
 26  ^..777777...........c.....####.....c............ffffff.^
 27  ^..777777.................####.........RR..............^
 28  ^.........................####.........RR..............^
 29  ^..888888........RR......l####l.................RR.....^
 30  ^..888888.c......RR.......####..................RR.....^
 31  ^..888888.................####.........................^
 32  ^.........................####.........................^
 33  ^^^^^^^^^^^^^^^^^^^^^^^^^^>>>>^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## Edificios

| Nº | Id del interior | Nombre | Estilo | Rect (x, y, ancho, alto) | Puerta (columnas, fila) | Notas |
|---|---|---|---|---|---|---|
| 1 | `rocaforja.hondoyunque.salon` | Salón de los Thanes | `castle` (variante enana) | 21, 3, 14, 7 | 27-28, fila 9 | Thane Hilda. Al final, Durgan encerrado. Escalinata 26-29 × 10-11. |
| 2 | `rocaforja.hondoyunque.ascua` | Cámara del Ascua | `chapel` (variante, puerta de piedra rúnica) | 4, 3, 7, 5 | 7, fila 7 | **Sellada** hasta `rocaforja.forja_profunda`. Edda dentro al final. |
| 3 | `rocaforja.hondoyunque.forja` | La Gran Forja | `smithy` (grande) | 4, 12, 9, 6 | 8-9, fila 17 | Forja y ritual (tienda tier 2 → tier 3). Brokk tras la misión 2. |
| 4 | `rocaforja.hondoyunque.posada` | El Barril sin Fondo | `inn` | 40, 13, 8, 6 | 43, fila 18 | Gorm. **Punto de reaparición** de la capital. |
| 5 | `rocaforja.hondoyunque.establo` | Establo de las cabras | `house` (puerta ancha) | 49, 13, 5, 5 | 51, fila 17 | Frida, maestra de viajes; corral delante (48-53 × 21-26). |
| 6 | `rocaforja.hondoyunque.cuartel` | Cuartel de la guardia | `house` (variante con escudos) | 40, 3, 8, 6 | 43, fila 8 | Capitana Runa. |
| 7 | — | Casa minera | `house` | 3, 24, 6, 4 | 5, fila 27 | Cerrada (decoración). |
| 8 | — | Casa minera | `house` | 3, 29, 6, 3 | 5, fila 31 | Cerrada (decoración). |

## Salidas y llegada

| Salida | Casillas | Lleva a | Llegada en este mapa |
|---|---|---|---|
| Gran Puerta (sur) | (26-29, 33) | `rocaforja.pastos` (25, 5) | (27, 31) — aquí aparece el héroe al entrar |
| Galería de vagonetas (oeste) | (0, 20-22) | `rocaforja.canteras` (2, 6) | (2, 21). Cerrada (rastrillo) hasta `rocaforja.prueba_del_thane` |
| Túnel de los Thanes (este) | (55, 10-12) | `lunaria.raices` (2, 10) | (53, 11) (llegada desde `raices.oeste`). Cerrada hasta `rocaforja.despertar` |

## NPC (posición en casillas)

| NPC | Posición | Rol |
|---|---|---|
| Guardia de la puerta (`guardaHondoyunque`) | (25, 30) y (30, 30) | Diálogo de llegada (línea propia si el héroe es enano) |
| Thane Hilda (`thaneHilda`) | dentro del Salón; antes de abrirlo, (28, 12) en lo alto de la escalinata | Misiones de historia |
| Brokk (`brokk`) | Pastos (corrales) hasta la misión 2; luego (9, 19) delante de la Gran Forja | Forja, ritual, misiones |
| Capitana Runa (`runaEscudohondo`) | (43, 10) delante del cuartel | Misiones de combate |
| Gorm (`gormPosadero`) | dentro de la posada; fuera, (44, 20) | Misiones ligeras, reaparición |
| Frida (`fridaArriera`) | (51, 19) | Maestra de viajes |
| Edda (`eddaGuardiana`) | (7, 9) delante de la Cámara del Ascua | Misiones del fuego negro |
| Zigo (`zigoMercader`) | (21, 25) junto a los puestos | Comerciante |
| Aldeanos enanos (3-4, decorativos) | plaza, mercado, barrio minero | Frases de ambiente |

## Notas para el map-designer / environment-artist

- Tres rutas de la puerta sur a la plaza (avenida central y los dos lados del mercado); el canal de lava se cruza por
  dos puentes o rodeándolo por arriba (fila 2-8) y por abajo (fila 25-32).
- La vía de vagoneta (`d`) entra por la galería oeste, cruza el puente sur del canal y muere en la plaza: poner 2-3
  vagonetas (`c` o decoración) sobre ella.
- El canal de lava ilumina y "late"; el gran crisol `F` de la plaza echa chispas (animación).
- Pedido nuevo de bioma: `d` = vía de vagoneta solo en este bioma (en los demás, sendero). Ver "Propuestas" en
  `encargos.md`.

> Ids de salida, bloqueos (`ExitLock`) y avisos definitivos: `../zonas.md` §2. Ids de zona: `rocaforja.<área>.<zona>` (§3).
