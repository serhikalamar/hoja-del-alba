# Escoriales del Hollín (`rocaforja.escoriales`) — zona 4, niveles 16-18 (boceto)

52×34, 1 434 pisables, todo conectado. Tierra de escoria donde malvivió el Clan Hollín: ríos de lava, crisoles de
fuego negro y un barracón de prisioneros. El borde norte es **la muralla de la Fortaleza Hollín** (`w`), con la
puerta y la brecha como salidas. **Bioma `rocaforjaSlag`**: `,` escoria negra y ceniza (suelo base aquí) ·
`d` camino de escoria apisonada · `~` **lava** · `p` puente de hierro · `R` montón de escoria · `w` muralla Hollín
(piedra negra con almenas) · `x` **crisol de fuego negro** (llama oscura) o brasero · `c` sacos y cajas de mineral ·
`f` empalizada · `+` poste con calavera de cabra · `1` ruinas de la fundición vieja (sin interior, `lockedMessage`) ·
`2` **barracón de prisioneros** (interior `rocaforja.escoriales.barracon`, puerta en (44, 18)).

```
     0         1         2         3         4         5 
     0123456789012345678901234567890123456789012345678901
  0  ^^^^^^^^^^^^^^wwwwwwwwww>>>>wwwwwwwww>>>wwwwww^^^^^^
  1  ^,,,,,,,,,,,,,,,,,,,,,,,dddd,,,,,~~,,ddd,,,,,,,,,,,^
  2  ^,,,,,,,,,,,,,,,,,,,,,,,dddd,,,,,~~,,ddd,,,,,,,,,,,^
  3  ^,,,,,,,,,,,,,,,,,,,,,,,dddd,,,,,~~,,ddd,,,,,,,,,,,^
  4  ^,,,,,,cxc,,,,,,,,,,,,,,dddd,,,,,~~,,ddd,,,,,,,,,,,^
  5  ^,,,,,,,,,,,,,,,,,,,,,,,dddd,,,,,~~,,ddd,,,cxc,,,,,^
  6  ^,,,,,,,,,,,,,,,,,,,,,,,dddd,,,,,~~,,ddd,,,,,,,,,,,^
  7  ^,,,,,,,,,,,,,,,,,,,,,,,dddd,,,,,~~,,,,,,,,,,,,,,,,^
  8  >ddddddddddddddddddddddddddddd,,,pp,,,,,,,,,,,,,,,,^
  9  >ddddddddddddddddddddddddddddd,,,pp,,,,,,,,,,,,,,,,^
 10  >ddddddddddddddddddddddddddddd,,,pp,,,,,,,,,,,RR,,,^
 11  ^,,,,,,,,,,,ddd,,,,,,,,,,,,ddd,,,~~,,,,,,,,,,,RR,,,^
 12  ^,,,,,,,,,,,ddd,,,~~,,,,,,,ddd,,,~~,,,,,,,,,,,,,,,,^
 13  ^,,,,,,,,,,,ddd,,,~~,,,,,,,ddd,,,~~,,,,,,,,,,,,,,,,^
 14  ^,,,,,,,,,,,ddd,,,~~,,,,,,,ddd,,,,,,,,,,,,,,,,,,,,,^
 15  ^,,,,RR,,,,,ddd,,,~~,,,,,,,dddddddddddddfffffffff,,^
 16  ^,,,,RR,,,,,ddd,,,~~,,,,,,,dddddddddddddfd22222,f,,^
 17  ^,,,,,,,,,,,ddd,,,~~,,,,,,,dddddddddddddfd22222,f,,^
 18  ^,,,,,,,,,,,ddd,,,~~,,,,,,,,,,,,,,,,,,,,f,22222,f,,^
 19  ^,,111111,,,ddd,,,~~,,,,,,,,,,,,,,,,,,,,f,,,,,,,f,,^
 20  ^,,111111,,,ddd,,,~~,,,RR,,,,,,,,,,,,,,,fff,,,fff,,^
 21  ^,,111111,,,ddd,,,pp,,,RR,,,,,,,,,,,,,,,,,,,,,,,,,,^
 22  ^,,111111,,,ddd,,,pp,,,,,,,,,,,,,,,,,,,,,,,cxc,,,,,^
 23  ^,,,,,,,,,,,ddd,,,pp,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^
 24  ^,,,,,,,,,,,ddd,,,~~,,,,,,,,,,,,,,,,RR,,,,,,,,,,,,,^
 25  ^,,,,,,,,,,,ddd,,,~~,,,,,,,,,,,,,,,,RR,,,,,,,,,,,,,^
 26  >dddddddddddddd,,,~~,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^
 27  >dddddddddddddd,,,~~,,,,,,~~~~~~~~~~,,,,,,,,,,,,,,,^
 28  >dddddddddddddd,,,~~,,,,,,~~~~~~~~~~,,,,,,,,,,,,,,,^
 29  ^,,,,,,,,,,,,,,,,,pp,,,,,,~~~~~~~~~~,,,,,,,,,,,,,,,^
 30  ^,,,,,,,,,+,,,,,,,pp,,,,,,~~~~~~~~~~,,,,,,,,,,,,,,,^
 31  ^,,,,,,,,,,,,,,,,,pp,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^
 32  ^,,,,,,,,,,,,,,+,,~~,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^
 33  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## Salidas

| Salida (id) | Casillas | Lleva a | Llegada aquí | Bloqueo |
|---|---|---|---|---|
| `escoriales.oeste` | (0, 8-10) | `rocaforja.cumbres` (45, 9) | (1, 9) | — |
| `escoriales.suroeste` | (0, 26-28) | `rocaforja.canteras` (49, 27) | (1, 27) | — |
| `escoriales.puerta` (Puerta Hollín) | (24-27, 0) | `rocaforja.fortaleza` (23, 23) | (25, 2) | `.questDone("rocaforja.crisoles_negros")` — "La Puerta Hollín está atrancada. Sin el fuego de los crisoles no aguantarán mucho." |
| `escoriales.brecha` | (37-39, 0) | `rocaforja.fortaleza` (36, 23) | (38, 2) | `.questDone("rocaforja.crisoles_negros")` — la abren los mineros rescatados |

## Crisoles, barracón y spawns

- **Crisoles negros** (misión `rocaforja.crisoles_negros`): 3 NPC de rol `.clue` (`crisolNegro1..3`) sobre los braseros
  (8, 4), (44, 5), (44, 22) — cada uno en su propia zona. Se "leen" (se apagan con el agua del Ascua) al acercarse con
  la zona liberada: objetivo `read(npcID:)`. El tercero tiene la aparición de la Hermana Brasa (texto).
- **Barracón de prisioneros** (interior `rocaforja.escoriales.barracon`, 14×9 como la casa del alcalde, nivel 18):
  3 mineros `mineroCautivo1..3` (rol `.villager`) y guardias permanentes (interior): 3 `hollinWarrior`,
  2 `hollinRifleman`, 1 `ironConstruct`. Objetivo `rescue([...])`, como las casas de Valdehierro.

| Zona (id) | Nivel | Rect aprox. (x, y, ancho, alto) | Monstruos (de campo, reaparecen) |
|---|---|---|---|
| `rocaforja.escoriales.camino` Camino de las cumbres | 16 | 1, 1, 31, 13 | `rocaforja.escoriales.1-3` 3 `hollinWarrior` · `.4-5` 2 `earthElemental` (paleta escoria) · crisol 1 |
| `rocaforja.escoriales.fundicion` Fundición vieja | 16 | 1, 14, 17, 19 | `.6-8` 3 `emberAcolyte` · `.9` 1 `earthElemental` · `.10-11` 2 `hollinRifleman` |
| `rocaforja.escoriales.lava` Campos de lava | 17 | 18, 11, 22, 22 | `.12-14` 3 `hollinWarrior` · `.15-16` 2 `hollinRifleman` |
| `rocaforja.escoriales.alto` Alto del este | 18 | 35, 1, 16, 32 | `.17-18` 2 `ironConstruct` (élite) en (47, 9) y (46, 27) · crisoles 2 y 3 |

Punto seguro: entrada oeste (2, 9).

> Ids de salida, bloqueos (`ExitLock`) y avisos definitivos: `../zonas.md` §2. Ids de zona: `rocaforja.<área>.<zona>` (§3).
