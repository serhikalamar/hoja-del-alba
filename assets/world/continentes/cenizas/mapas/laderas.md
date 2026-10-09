# Mapa · `cenizas.laderas` — Laderas de Brasamadre (36-38)

Tamaño real: **60 × 40**. Bioma `cenizasVolcano`: `~` = **lava** (no se pisa, ilumina), `p` = puente de basalto,
`^` = paredes del cráter, `.` = roca volcánica, `x` = fumarola/brasero. Dos ríos de lava bajan en diagonal; el camino
central los cruza por un puente ancho.

**Boceto ligero a escala 1:2**: cada carácter ≈ 2×2 casillas (el mapa real mide el doble en ancho y alto).
El `map-designer` lo pasa a tamaño real siguiendo `assets/maps/README.md` y la leyenda común de exteriores de
`assets/world/continentes.md` (`d % p R ^ + n x e >`). Marcas solo de boceto: `*` = grupo de monstruos de campo
(2-3), cifras = lugares clave (tabla), `>` = salida.

```
^^^^^^^^^^^^^^>>^^^^^^^^^^^^^^
^..R....~~...dddd..~~....R...^
^......~~....d..d...~~...*...^
^..*..~~...*.d..d....~~......^
^....~~......d..d.....~~..*..^
^...~~...R..~pppp~.....~~....^
^..~~..*....~pppp~..R...~~...^
^.~~.........d..d....*...~~..^
^~~....x..n..d..d.........~~.^
^~.....*n1n*.d..ddddd......~~^
^.......n.n..d......d.x.n.x..^
>dddddddddddd...*...d..n2n...^
>dd....R.....x......d.*.n.*..^
^.....*......n3n....d........^
^.....~~~....*.n....d....R...^
^....~~~~~.........^^^^^.....^
^...~~~~~~~...*...^^.e.^^.*..^
^....~~~~~.......^^.....^^...^
^.....~~~...R.....^^^^^^^....^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

| Marca | Qué es |
|---|---|
| `1` `2` `3` | **Braseros violeta del Eclipse** (objetivo de `cenizas.braseros_violeta`), cada uno en un círculo de tiendas `n` con su grupo de guardia. En el código: casilla `x` + NPC `.clue` `braseroVioleta1-3` (look `violetBrazier`) delante; se "lee" (se apaga) con el grupo muerto |
| `pppp` | Puente de basalto (4 de ancho real) |
| `^^.e.^^` | **Boca del Cráter**: entrada `e` a la mazmorra final (piso `caldera`). Cerrada hasta terminar `cenizas.el_heraldo` |
| `>>` (norte) | Salida → `cenizas.necropolis` |
| `>` (oeste) | Salida → `cenizas.sepultada` |

**Zonas**:
- `lava` · Ríos de Lava · nivel 36 · norte (x 0-60, y 0-16): `fireElemental` ×3, `salamander` ×3.
- `campamento` · Campamento del Eclipse · nivel 37 · centro (x 0-60, y 16-28): `eclipseZealot` ×3, `ashAcolyte` ×3,
  repartidos 1+1 por brasero.
- `crater` · Boca del Cráter · nivel 38 · sur (x 0-60, y 28-40): `magmaGolem` ×2, `fireElemental` ×2.

**Llegadas**: desde la Necrópolis (29, 1); desde la Sepultada (1, 23); al salir de la Caldera (42, 34).
Reaparición: campamento de la Alianza junto al puente (30, 6).
