# Mapa · `cenizas.dunas` — Dunas Negras (32-34)

Tamaño real: **60 × 38**. Bioma `cenizasAsh`: `.` = arena negra, `%` = matojo, `R` = costillar de bestia / roca,
`~` = **pozo de agua** (en el campamento). Las dunas se sugieren con `^` bajos sueltos si hace falta (sin cerrar caminos).

**Boceto ligero a escala 1:2**: cada carácter ≈ 2×2 casillas (el mapa real mide el doble en ancho y alto).
El `map-designer` lo pasa a tamaño real siguiendo `assets/maps/README.md` y la leyenda común de exteriores de
`assets/world/continentes.md` (`d % p R ^ + n x e >`). Marcas solo de boceto: `*` = grupo de monstruos de campo
(2-3), cifras = lugares clave (tabla), `>` = salida.

```
^^^^^^^^^^^^^>>^^^^^^^^^^^^^^^
^...R....%..dddd.....R.....*.^
^.T....*....d..d.......%.....^
^.....n.n...d..d...R.........^
^...x.n1n...d..dddddd....*...^
^.....n.n.~~d......d.........>
^...*.....~~d....R.d..+......>
^.........dddd.....d....R....^
^..R..%......d..*..ddddd.....^
^.......*....d.........d.*...^
^...+........d...R.....d.....^
^.....R..*...ddddd.....ddd...^
^..%..............d......d...^
^.......*..R..*...dd.ffffdff.^
^..T..............d..f..*..f.^
^.....R.....*.....d..f.x2..f.^
^.%...............d..f..*..f.^
^.........R.......d..fffffff.^
^^^^^^^^^^^^^^^^^^RR^^^^^^^^^^
```

| Marca | Qué es |
|---|---|
| `1` | **Jaima de Yalia** (edificio-tienda 3×3 reales, puerta abajo) → `cenizas.dunas.jaima`. Alrededor, tiendas `n` del Clan Duna y el pozo `~` |
| `2` | **Trono de Hueso** de Gorrak, dentro de la empalizada de huesos (`f`), con una entrada al norte |
| `+` | Estelas de Solarum medio enterradas (decorado; una puede ser legible: "Aquí terminaba el imperio") |
| `>>` (norte) | Salida → `cenizas.fortin` (llega a (23, 32) del Fortín) |
| `>` (este) | Salida → `cenizas.necropolis` |
| `RR` (sur) | **Atajo** `dunas.sur` → `cenizas.sepultada`: en el código son `>` con `lock: .questDone("cenizas.el_heraldo")` y el aviso del derrumbe (el arte puede dibujar rocas mientras esté cerrada) |

**Zonas**:
- `pozos` · Pozos del Clan Duna · nivel 32 · noroeste (x 0-28, y 0-20). El campamento (x 8-20, y 4-14) es **seguro**
  (sin spawns). Fuera: `ashVulture` ×3, `ashScorpion` ×3.
- `mar` · Mar de Dunas · nivel 33 · centro y este (x 28-60, y 0-24) y suroeste (x 0-36, y 20-38): `ashTroll` ×2,
  `trollHexer` ×3, `ashVulture` ×2.
- `trono` · Trono de Hueso · nivel 34 · sureste (x 40-60, y 24-38): `ashTroll` ×2, `trollHexer` ×2, **jefe
  `ashTrollKing`** en (47, 30).

**Llegadas**: desde el Fortín (27, 1); desde la Necrópolis (58, 11); desde la Sepultada (37, 36).
Reaparición: hoguera del campamento (8, 8). **NPC**: `yaliaGuia` (dentro de la jaima), dos nómadas de ambiente.
