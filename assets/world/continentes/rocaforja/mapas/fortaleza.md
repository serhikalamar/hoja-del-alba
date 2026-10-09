# Fortaleza Hollín (`rocaforja.fortaleza`) — zona 5, niveles 18-19 (boceto)

48×26, 877 pisables, todo conectado. Dentro de la muralla: el patio de armas, barracones, fundición y la puerta de la
Forja Profunda. **Se entra desde los Escoriales** por la Puerta Hollín o por la brecha (las dos salidas del borde sur,
cerradas hasta `rocaforja.crisoles_negros`; así no hace falta una casilla bloqueada dentro del área).
**Bioma `rocaforjaSlag`** + piedra Hollín: `,` escoria · `#` losas del patio · `d` rampa de la brecha ·
`w` muralla (las torres son bloques 4×2) · `^` roca de la montaña · `I` columna con estandarte Hollín (yunque negro
sobre rojo) · `+` estatua de Durgan · `x` brasero de fuego negro · `c` armas apiladas · `n` tienda de la Hermana Brasa ·
`e` puerta de la Forja Profunda · `1` barracones, `2` fundición (sin interior: `lockedMessage`).

```
     0         1         2         3         4       
     012345678901234567890123456789012345678901234567
  0  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  1  ^,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^
  2  ^,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^
  3  ^,,,,,,,,,,,,,^^^^^^^^^^^^^^^^^^^^,,,,,,,,,,,,,^
  4  ^,,,111111111,^^^^^^^^^^^^^^^^^^^^,222222222,,,^
  5  ^,,,111111111,^^^^^^^^^^^^^^^^^^^^,222222222,,,^
  6  ^,,,111111111,^^^^^^^^^^^^^^^^^^^^,222222222,,,^
  7  ^,,,111111111,^^^^^^+^eeee^+^^^^^^,222222222,,,^
  8  ^,,,111111111,,,,,,x,,####,,x,,,,,,222222222,,,^
  9  ^,,,111111111,,,,,,,,,####,,,,,,,,,222222222,,,^
 10  ^,,,,,,,#,,,,,,,,,,,,,####,,,,,,,,,,,,,#,,,,,,,^
 11  ^,,,,,,,#,,,,,,,,,,,,,####,,,,n,,,,,,,,#,,,,,,,^
 12  ^,,,,,,,#,,,,,,,,,,,,,####,,,,,x,,,,,,,#,,,,,,,^
 13  ^,,,,,,,#####cc##################cc#####,,,,,,,^
 14  ^,,,,,,,##I##########################I##,,,,,,,^
 15  ^,,,,,,,################################,,,,,,,^
 16  ^,,,,,,,################################,,,,,,,^
 17  ^,,,,,,,################################,,,,,,,^
 18  ^,,,,,,,################################,,,,,,,^
 19  ^,,,,,,,##I##########################I##,,,,,,,^
 20  ^,,,,,,,################################,,,,,,,^
 21  ^,,,,,,,,,,,,,,,,,,,,,####,,,,,,,,,,,,,,,,,,,,,^
 22  ^,,,,,,,,,,,,,,,,,,,,,####,,,,,,,,,ddd,,,,,,,,,^
 23  ^wwww,,,,,,,,,,,,,,,,x####x,,,,,,,,ddd,,,,,wwww^
 24  ^wwww,,,,,,,,,,,,,,,,,####,,,,,,,,,ddd,,,,,wwww^
 25  wwwwwwwwwwwwwwwwwwwwww>>>>wwwwwwwww>>>wwwwwwwwww
```

## Salidas

| Salida (id) | Casillas | Lleva a | Llegada aquí | Bloqueo |
|---|---|---|---|---|
| `fortaleza.puerta` | (22-25, 25) | `rocaforja.escoriales` (25, 2) | (23, 23) | — (para volver) |
| `fortaleza.brecha` | (35-37, 25) | `rocaforja.escoriales` (38, 2) | (36, 23) | — |
| `e` Forja Profunda | (22-25, 7) | `StoryDungeon` `rocaforja.forja_profunda` (piso `forge`) | (23, 9) al salir | `.questDone("rocaforja.asalto_a_la_fortaleza")` |

## Zonas y spawns

| Zona (id) | Nivel | Rect aprox. | Monstruos (reaparecen) |
|---|---|---|---|
| `rocaforja.fortaleza.patio` Patio de armas | 18 | 1, 13, 46, 12 | `rocaforja.fortaleza.1-6` 6 `hollinWarrior` · `.7-8` 2 `hollinRifleman` (junto a las torres) |
| `rocaforja.fortaleza.barracones` Barracones | 19 | 1, 1, 13, 12 | `.9-10` 2 `hollinRifleman` · `.11-12` 2 `hollinPyromancer` |
| `rocaforja.fortaleza.fundicion` Fundición | 19 | 34, 1, 13, 12 | `.13-14` 2 `hollinPyromancer` · `.15` 1 `ironConstruct` |
| `rocaforja.fortaleza.forja` Puerta de la Forja | 19 | 14, 8, 20, 5 | `.16-17` 2 `ironConstruct` (élite) |

La misión `rocaforja.asalto_a_la_fortaleza` es `kill(["hollinWarrior"], 12, areaID: "rocaforja.fortaleza")` +
`talk(brokk)` (Brokk aparece en (24, 21) con `appearsWhen: .questDone("rocaforja.crisoles_negros")`).

NPC: **Brokk** (24, 21) para la confesión; **Capitana Runa** (20, 21) con la misma condición. En la tienda de la Hermana
Brasa, tras `rocaforja.forja_profunda`, aparece **Fausto** (29, 11) (`faustoCautivo`, rol `.clue`), el alcalde traidor
de Valdehierro, encadenado y abandonado por el Eclipse (misión `rocaforja.fausto`). Punto seguro: braseros de la
puerta (23, 22).

> Ids de salida, bloqueos (`ExitLock`) y avisos definitivos: `../zonas.md` §2. Ids de zona: `rocaforja.<área>.<zona>` (§3).
