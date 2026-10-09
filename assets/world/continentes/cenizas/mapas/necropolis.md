# Mapa · `cenizas.necropolis` — Necrópolis de Solarum (34-36)

Tamaño real: **60 × 40**. Bioma `cenizasAsh`: `+` = **lápidas y estelas**, `^` = muro de la Puerta del Sol y peñas,
`R` = estatuas caídas. La avenida norte la flanquean estatuas sin cara (`+` en fila).

**Boceto ligero a escala 1:2**: cada carácter ≈ 2×2 casillas (el mapa real mide el doble en ancho y alto).
El `map-designer` lo pasa a tamaño real siguiendo `assets/maps/README.md` y la leyenda común de exteriores de
`assets/world/continentes.md` (`d % p R ^ + n x e >`). Marcas solo de boceto: `*` = grupo de monstruos de campo
(2-3), cifras = lugares clave (tabla), `>` = salida.

```
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^..+..+..+..+...R....+..+..+.^
^.........*.......*..........^
>dddddddddddddddddddddddddd..^
>dd.+..+..+..+..+..+..+..dd..^
^.....*...........*.......d..^
^..+.+.+.....R.......+.+.+d..^
^..+.*.+...1111......+.*.+d..^
^..+.+.+...1111......+.+.+d..^
^............dd...........d..^
^...*..R.....dd....*....dddd.^
^.+.+.+.+....dd.....+.+.+.+..^
^.....*..........*...........^
^..........^^^e^^^...........^
^....x.....^.....^.....x.....^
^.......*..^..*..^.....*.....^
^..........^.....^...........^
^...R......d..2..d.......R...^
^..........d.....d...........^
^^^^^^^^^^^^^^>>^^^^^^^^^^^^^^
```

| Marca | Qué es |
|---|---|
| `1` | **Mausoleo de los Tribunos** (edificio 8×4 reales, puerta abajo) → `cenizas.necropolis.mausoleo` |
| `^^^e^^^` | **Puerta del Sol**: muro con la entrada `e` a la mazmorra (piso `tomb`). Cerrada hasta vencer al Aguijón Negro |
| `2` | **Aguijón Negro** (`colossalScorpion`), delante de la puerta, en un patio de 12×8 reales |
| `x` | Braseros con llama violeta (el Eclipse ya está aquí) |
| `>` (oeste) | Salida → `cenizas.dunas` |
| `>>` (sur) | Salida → `cenizas.laderas` (camino que pasa junto al patio de la puerta) |

**Zonas**:
- `avenida` · Avenida de las Estatuas · nivel 34 · norte (x 0-60, y 0-12): `mummy` ×3, `scarabSwarm` ×3.
- `tumbas` · Campo de Tumbas · nivel 35 · centro (x 0-60, y 12-26): `mummy` ×3, `solarLegionary` ×3,
  `eclipseZealot` ×2, `ashAcolyte` ×1.
- `puerta` · Puerta del Sol · nivel 36 · sur (x 0-60, y 26-40): `solarLegionary` ×2, `scarabSwarm` ×2, **jefe
  `colossalScorpion`** en (28, 34).

**Llegadas**: desde las Dunas (1, 7); desde las Laderas (29, 38); al salir de la Tumba (28, 30).
Reaparición: brasero apagado de la Alianza (6, 6). **NPC**: `thessa` aparece junto a la Puerta del Sol durante
`cenizas.puerta_sellada` (fuera del alcance del jefe).

**Sala de los Murales**: edificio `murales` (6×4 reales, estilo `solarTemple` nuevo, `placeholder` = `chapel`) a la
derecha de la Puerta del Sol, hacia (36, 22), puerta abajo, cerrada hasta `cenizas.tumba_de_solarum` → interior
`cenizas.necropolis.murales` (≈ 18×10, piedra `:`, alfombra `r`, columnas `I`): cuatro NPC `.clue` delante de la
pared norte (`muralSiete`, `muralOcaso`, `muralSolNegro`, `muralProfecia`, look `mural`), `solanoEspiritu`
(`.questGiver`) en el centro y `thessa` junto a la puerta. Sin enemigos.
