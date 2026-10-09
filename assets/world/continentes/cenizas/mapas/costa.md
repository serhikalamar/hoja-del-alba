# Mapa · `cenizas.costa` — Costa de Escoria (30-32)

Tamaño real: **56 × 36**. Bioma `cenizasAsh` con mar: aquí `~` = **mar de escoria** (agua negra con espuma gris) y las
charcas de azufre son `~` rodeadas de `,` (arena amarilla; el `environment-artist` puede teñir el agua de las
charcas si el bioma lo permite, si no se quedan como agua oscura).

**Boceto ligero a escala 1:2**: cada carácter ≈ 2×2 casillas (el mapa real mide el doble en ancho y alto).
El `map-designer` lo pasa a tamaño real siguiendo `assets/maps/README.md` y la leyenda común de exteriores de
`assets/world/continentes.md` (`d % p R ^ + n x e >`). Marcas solo de boceto: `*` = grupo de monstruos de campo
(2-3), cifras = lugares clave (tabla), `>` = salida.

```
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
~~~~^11^^^^RR^^^^^^^^^^^^^^^
~~~~.11.....*.....%....R...^
~~~~..e............T.......^
~~~~~..x.....R........*....^
~~~~~......%...............^
~~~~~~...*.........dddddddd>
~~~~~~~.......dddddd..R....>
~~~~ppppddddddd.....%......^
~~~~pppp..x.....,,,,.......^
~~~~~~~..*.....,~~~~,..*...^
~~~~~~.........,~~~~,......^
~~~~~...R...*...,,,,...R...^
~~~~~..222.........*.......^
~~~~~..222.....%.......T...^
~~~~~~.....*......R........^
~~~~~~~~...................^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

| Marca | Qué es |
|---|---|
| `1` | **Faro roto** (edificio, 4×4 reales) con puerta `e` debajo → interior `cenizas.costa.faro` |
| `2` | **Barco naufragado** (obstáculo grande, 6×4 reales; arte del `environment-artist`) |
| `pppp` (oeste) | **Embarcadero** de madera sobre el mar: llegada en barco (*La Gaviota Tuerta* atracada al lado) |
| `>` (este) | Salida → `cenizas.fortin` (llega a (1, 16) del Fortín) |

**Zonas** (`Zone`, coordenadas reales aproximadas):
- `naufragio` · Playa del Naufragio · nivel 30 · sur y suroeste (x 8-30, y 16-34): `cinderCrab` ×4, `ashScorpion` ×3.
- `azufre` · Charcas de Azufre · nivel 31 · centro y este (x 24-54, y 10-30): `salamander` ×4, `ashScorpion` ×2, `cinderCrab` ×2.
- `cabo` · Cabo del Faro · nivel 32 · norte (x 8-54, y 2-10): `salamander` ×2, `ashScorpion` ×2, `ashVulture` ×2.

**Llegada** desde el barco: (10, 17) en el embarcadero. **Desde el Fortín**: (54, 13). Reaparición (M9): hoguera `x`
junto al embarcadero (20, 18).
**NPC**: `princess` y `margaCapitana` en el embarcadero al llegar; un marinero de ambiente. Más allá del cabo, el
**barco negro** del Eclipse varado (decorado; la `hermanaBrasa` aparece un instante en su cubierta la primera vez).
**Salida**: `costa.este` (55, 12-15) → Fortín (2, 16).

**Interior `cenizas.costa.faro`** (≈ 12×10): planta baja redonda de piedra (`:`), cajas y barriles de la expedición,
mesa con el **diario del ayudante** (casilla legible o NPC-objeto), escalera rota. Nivel 31: `salamander` ×2,
`cinderCrab` ×1.
