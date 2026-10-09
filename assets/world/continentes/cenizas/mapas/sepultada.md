# Mapa · `cenizas.sepultada` — Ciudad Sepultada de Solarum (38-39)

Tamaño real: **56 × 34**. Bioma `cenizasVolcano` sin lava: calles de losas hundidas bajo la ceniza. `w` = muros de bronce
y adobe de las casas (bloques de 2+ filas), `I` = **columnas** (en el código, `R` con arte de columna en este bioma; si el motor permite `I` en exterior, mejor), `S` = escalinata del palacio, `+` = estela legible.

**Boceto ligero a escala 1:2**: cada carácter ≈ 2×2 casillas (el mapa real mide el doble en ancho y alto).
El `map-designer` lo pasa a tamaño real siguiendo `assets/maps/README.md` y la leyenda común de exteriores de
`assets/world/continentes.md` (`d % p R ^ + n x e >`). Marcas solo de boceto: `*` = grupo de monstruos de campo
(2-3), cifras = lugares clave (tabla), `>` = salida.

```
^^^^^^^^^^^^RR^^^^^^^^^^^^^^
^...........dd.......^^^^^^^
^..wwww..wwwddwww....^11111^
^..w..w..w.....+w....^11111^
^..w*.w..w..*...w....^11111^
^..wwdw..wwwdwwww....^11e11^
^....d......d.........SSSS.^
^.I..d..I...d..I..*...SSSS.^
^....dddddddddddddddddSSSS.>
^.I.....*...d..I......SSSS.>
^.......wwwwdwwww......*...^
^..*....w.......w....I.....^
^.......w..*.*..w..........^
^...I...w...x...w....*.....^
^.......wwwwwwwww.......I..^
^..R.......*.........R.....^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

| Marca | Qué es |
|---|---|
| `1` | **Palacio imperial** (edificio `palacio` 10×8 reales sobre la peña, estilo `solarPalace` nuevo con `placeholder` = `castle`; la `e` del boceto es su puerta) → `cenizas.sepultada.palacio`, cerrado hasta `cenizas.braseros_violeta` |
| `SSSS` | Gran escalinata del palacio (8 de ancho real) |
| bloques `w` | Casas de artesanos (noroeste) y el **Foro Hundido** (centro sur: patio cerrado con brasero y dos entradas) |
| `RR` (norte) | **Atajo** `sepultada.norte` → `cenizas.dunas` (`>` con `lock: .questDone("cenizas.el_heraldo")`) |
| `>` (este) | Salida → `cenizas.laderas` |

**Zonas**:
- `artesanos` · Barrio de los Artesanos · nivel 38 · oeste (x 0-24, y 0-34): `solarLegionary` ×3, `sunPriest` ×2,
  `scarabSwarm` ×2.
- `foro` · Foro Hundido · nivel 38 · centro (x 14-34, y 18-34): `sunPriest` ×2, `eclipseZealot` ×2, `ashAcolyte` ×2.
- `escalinata` · Escalinata del Palacio · nivel 39 · este (x 34-56, y 0-34): `solarLegionary` ×2, `magmaGolem` ×1.

**Llegadas**: desde las Laderas (54, 17); desde las Dunas (25, 1). Reaparición: brasero de la Alianza (10, 16).

**Interior `cenizas.sepultada.palacio`** (≈ 22×14, nivel 39): salón con alfombra `r` hasta el trono vacío `Y`,
dos filas de pilares `I`, estatuas de emperadores (`s`), grieta al fondo. **Ozrán** (`ashHerald`) junto al trono,
`ashAcolyte` ×2 y `solarLegionary` ×2 a los lados. Al vencerlo, escena: la mano de ceniza lo arrastra a la grieta.
