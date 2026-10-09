# Valdemar · zonas (niveles 1-10)

Responsable: `continent-lead` de `valdemar`. Borradores de cada mapa en `mapas/` (filas listas para el código,
validadas: borde cerrado, todo conectado, spawns en su zona). Bioma de todas las áreas: `valdemar` (verdes y ocres).

## 1. Mapa del continente

```
                         [ Paso del Norte ]  valdemar.paso · 10 · 48×32
                           |  (sur 22-24,31) ↔ (norte 3-5,0)  · cerrado hasta valdemar.paso_norte
                           |  norte (22-24,0) → Rocaforja ("Próximamente")
                           |
 [ Huertos del Molino ] ── VALDEHIERRO (town) ── [ Abadía de Valsombra ]
   valdemar.huertos   oeste    44×36       este    valdemar.abadia · 7/8 · 56×38
   5/6 · 56×36       (0,17-18) 1-5 · patio 9 (43,17-18)  ee → Cripta (mazmorra 8)
        |                      trono 10                 |
        | sur (11-14,35)        | sur (18-25,35)        | sur (31-33,37)
        |                       |                       |
        └──(8-11,0)──[ Bosque de Robleda ]──(63,22-24)──[ Colinas del Pedregal ]
                       valdemar.robleda (42-45,0)   (0,16-18) valdemar.pedregal · 8/9 · 60×38
                       6/7 · 64×36                           (norte 30-32,0) ↔ abadía
```

Dos anillos, ningún callejón sin salida: pueblo → Huertos → Robleda → pueblo, y pueblo → Abadía → Pedregal → Robleda →
pueblo. El nivel de cada zona hace de puerta (no hay muros salvo el Paso y el patio).

## 2. Zonas

| # | Área (id) | Zona (id) | Nombre | Nivel | Bioma / qué hay | Jefe | Monstruos de campo |
|---|---|---|---|---|---|---|---|
| Capital | `town` | `south`, `market`, `west`, `east`, `plaza` | Valdehierro | 1-5 | Pueblo (ya existe). Forja, posada, aldeanos con misiones, Capitán de la guardia | Rey de las ratas, Capitán bandido, Espantapájaros, Herrero poseído, Bruja (en casas) | No reaparecen (pueblo) |
| 1 | `valdemar.huertos` | `valdemar.huertos.trigales` | Trigales quemados | 5 | Trigales `%`, 2 granjas quemadas, hoguera de la entrada | — | 9 |
| 1 | | `valdemar.huertos.ribera` | Ribera del Plata | 5 | Río con 2 puentes, estanque, tumbas viejas | — | 6 |
| 2 | | `valdemar.huertos.molino` | Molino en ruinas | 6 | Molino derruido, cajas, rocas | **Ogro del molino** (`ogre`) | 5 |
| 2 | `valdemar.robleda` | `valdemar.robleda.robledal` | Robledal | 6 | Robles densos con claros | — | 4 |
| 2 | | `valdemar.robleda.campamento` | Campamento bandido | 6 | Empalizada, tiendas, hoguera | — | 7 |
| 2 | | `valdemar.robleda.camino` | Camino real | 6 | Camino ancho, puesto del guardabosques | — | 6 |
| 3 | | `valdemar.robleda.guarida` | Guarida del lobo | 7 | Claro rocoso | **Lobo alfa** (`alphaWolf`) | 3 |
| — | `mayor` (interior) | — | Casa del alcalde | 7 | Despacho, carta del alcalde | — | 4 (permanentes) |
| 3 | `valdemar.abadia` | `valdemar.abadia.cementerio` | Cementerio de Valsombra | 7 | Lápidas `+` en filas, valla | — | 6 |
| 3 | | `valdemar.abadia.huerto` | Huerto de los monjes | 7 | Maleza, pozo, campamento del Eclipse | — | 7 |
| 4 | | `valdemar.abadia.claustro` | Claustro en ruinas | 8 | Muros `w`, columnas `I`, losas `=`, iglesia, bajada `ee` | — | 7 |
| Mazmorra | piso `crypt` | `valdemar.cripta` | Cripta de la abadía | 8 | Mazmorra de historia (M8) | **Abad no-muerto** (`abbot`) | 3 oleadas |
| 4 | `valdemar.pedregal` | `valdemar.pedregal.laderas` | Laderas del Pedregal | 8 | Rocas, crestas `^`, hierba seca | — | 7 |
| 4 | | `valdemar.pedregal.pozas` | Pozas heladas | 8 | Pozas `~` frías, rocas | — | 5 |
| 5 | | `valdemar.pedregal.campamento` | Campamento orco | 9 | Empalizada, tiendas, tótems, braseros | **Señor de la guerra orco** (`warlord`) | 6 |
| 5 | `town` | `courtyard` | Patio del castillo | **9** (antes 7) | Ya existe; se abre con la condición nueva | — | 7 (permanentes) |
| Final | `castle` (interior) | — | Salón del trono | 10 | Ya existe | **Rey Goblin** (`goblinKing`) | 5 (permanentes) |
| Opcional | piso `prison` | `valdemar.calabozos` | Calabozos del castillo | 9 | Mazmorra de historia repetible (P3) | — | 4 oleadas |
| Salida | `valdemar.paso` | `valdemar.paso.sendero` | Paso del Norte | 10 | Sendero en zigzag, crestas, atalaya derruida | — | 6 |

Puntos seguros (reaparición al morir en el área, M9 · hoguera `x` al lado): Huertos (50,17) · Robleda (47,8) ·
Abadía (4,17) · Pedregal (5,17) · Paso (23,27). En el pueblo y sus interiores: la Puerta sur, como ahora.
Al morir en una mazmorra de historia: el punto seguro del área desde la que se entró.

## 3. Mazmorras de historia (M8)

Partida corta en un piso de la arena, con el personaje, sin forja entre oleadas ni reinicio roguelike. Se entra por la
`e`; al ganar se vuelve a la casilla de la `e` y cuenta para la misión. Al morir: punto seguro del área, sin premio.
Los monstruos salen por las puertas `G`/`h` del piso como en la arena; el jefe por la `BBB`.

### `valdemar.cripta` — Cripta de la abadía (piso `crypt`, nivel 8)

Entrada: `ee` (40-41,15) del claustro de `valdemar.abadia`. Repetible: sí (el Abad reaparece en las repeticiones;
su pieza `boss.abbot` solo es segura la primera vez — probabilidad después: la decide el `balance-designer`).

| Oleada | Monstruos (ids existentes salvo `eclipseAcolyte`) | Total |
|---|---|---|
| 1 | `skeleton` ×5, `ghoul` ×3, `skeletonArcher` ×2 | 10 |
| 2 | `wraith` ×3, `cultist` ×2, `eclipseAcolyte` ×2, `gargoyle` ×2, `fireSlime` ×1 | 10 |
| 3 | `necromancer` ×2, `blackKnight` ×2, `ghoul` ×3, `skeletonArcher` ×2, `iceSlime` ×1 | 10 |
| Jefe | `abbot` + `skeleton` ×2 de escolta (diálogo del Abad antes de abrir la `BBB`) | 3 |

Botín: el de los monstruos + al ganar `emerald` ×1 y 50 % de `gold` ×1 (adelanto de minerales raros de la plantilla).

### `valdemar.calabozos` — Calabozos del castillo (piso `prison`, nivel 9, opcional · P3)

Entrada: `e` (34,7) del patio del castillo, cuando el castillo está abierto. Repetible, sin jefe.

| Oleada | Monstruos | Total |
|---|---|---|
| 1 | `goblinElite` ×4, `goblinMage` ×2, `goblinGuard` ×2 | 8 |
| 2 | `orc` ×3, `berserker` ×2, `assassin` ×2, `goblinBomber` ×2 | 9 |
| 3 | `goblinGuard` ×3, `iceSlime` ×2, `troll` ×2, `wolfRider` ×2 | 9 |
| 4 | `goblinStandard` ×2 (élite), `goblinElite` ×4, `goblinMage` ×2 | 8 |

## 4. Ritmo 1→10 (simulación del lead)

Simulación de papel (script del lead con las fórmulas reales de `Leveling`): XP por zona (`area.level(at:)`), cada
monstruo de campo matado **una vez**, las misiones de `historia.md` §4, la cripta (30 monstruos + Abad).

| Momento | Con jefes ×12 (hoy) | Con jefes ×6 (propuesta) | Objetivo del brief |
|---|---|---|---|
| Pueblo liberado (+ `liberar`) | 6,9 | 6,2 | ~6 |
| Huertos + Robleda + casa del alcalde | 8,8 | 8,3 | — |
| Abadía + Cripta | 10,3 | 9,8 | — |
| Pedregal (antes del patio) | 10,9 | 10,3 | ~9 |
| Rey Goblin | 11,7 | 10,9 | **10** |

Conclusión para el `balance-designer`: con el multiplicador ×12 de los jefes el jugador se pasa de nivel aunque las
misiones den poco (los 9 jefes del continente aportan ~40 % de la XP). Propuesta: **×6 para los jefes de historia** (la
arena puede seguir con ×12) y las misiones con los valores de `historia.md`; medirlo con la simulación del modo
historia (encargo B1). Si se quiere que el jugador llegue con 9 justo al patio, bajar `valdemar.pedregal` y quitar la
XP de `valdemar.rey_goblin` (que se cobra igualmente con el Rey).
