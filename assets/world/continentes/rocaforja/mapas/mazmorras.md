# Rocaforja · Mazmorra y banda (pisos que ya existen)

Formato: `StoryDungeon` de `StoryDungeon.swift` (como `Valdemar.cripta`). No hacen falta mapas nuevos: se usan los pisos `mine` y `forge` de `Dungeon.swift` tal cual (ver
`assets/maps/mazmorra.md`). Lo nuevo es la **lista fija de oleadas** de cada uno (motor M8: "mazmorra de historia").
Se entra por una `e` del mapa exterior; al ganar se vuelve a esa `e` y cuenta para la misión. Al morir, se sale y se
puede reintentar (sin reinicio roguelike).

Cantidades orientativas para un héroe solo de nivel = nivel de la mazmorra con equipo de tier 2; el
`balance-designer` las ajusta (objetivo: 4-6 min la mazmorra, 6-8 min la banda).

## Minas profundas — `StoryDungeon` `rocaforja.minas`, piso `mine`, nivel fijo 16 (misión `rocaforja.minas_profundas`)

`entranceAreaID: "rocaforja.canteras"`, `repeatable: true`, `bossID: "cobaltColossus"`, `bossEscort: ["kobold": 4]`,
`bossIntro`/`bossDefeat`: story-writer (el Coloso no habla: el texto es de Brokk o de un kóbold que huye).

Ambiente: el Hollín ha clavado braseros de fuego negro en los puntales; los cristales del piso se tiñen de azul cobalto.

| Oleada | Nivel (orientativo: la mazmorra usa su nivel fijo) | Monstruos |
|---|---|---|
| 1 | 15 | 6 `kobold`, 3 `koboldCandle`, 3 `trogg` |
| 2 | 16 | 5 `trogg`, 3 `koboldGeomancer`, 1 `troggBrute` |
| 3 | 16 | 3 `rockGolem`, 4 `earthElemental`, 2 `koboldGeomancer` |
| 4 | 17 | 2 `troggBrute`, 2 `rockGolem`, 3 `emberAcolyte`, 4 `kobold` |
| Jefe | 17 | **`cobaltColossus`** por la gran puerta `BBB` + 4 `kobold` |

Botín extra al ganar: 1 `runestone` seguro y 25 % de `diamond`; con poca probabilidad, un común de Lunaria
(`quicksilver`/`amber`, "adelanto" de `progresion.md` §5).

## Forja Profunda — `StoryDungeon` `rocaforja.forja`, piso `forge`, nivel fijo 20 (misión `rocaforja.forja_profunda`, banda final)

`entranceAreaID: "rocaforja.fortaleza"`, `repeatable: true`, `bossID: "thaneDurgan"`, `bossEscort: ["hollinWarrior": 4]`,
`bossIntro` (Durgan a Brokk: "¿Vienes a apagarme, hermano?"), `bossIntroRepeat`, `bossDefeat` (cae, el fuego negro se
apaga, Brasa huye con el Molde del Ocaso): story-writer.

Ambiente: el fuego de los ríos de lava es negro con bordes naranjas hasta que cae Durgan; entonces vuelve a ser naranja
(si el motor lo permite: cambio de paleta al ganar; si no, se queda naranja).

| Oleada | Nivel (orientativo: la mazmorra usa su nivel fijo) | Monstruos |
|---|---|---|
| 1 | 19 | 6 `hollinWarrior`, 3 `hollinRifleman` |
| 2 | 19 | 4 `hollinWarrior`, 3 `hollinPyromancer`, 3 `earthElemental` |
| 3 | 20 | 2 `ironConstruct`, 4 `hollinRifleman`, 4 `emberAcolyte` |
| 4 | 20 | 3 `ironConstruct`, 4 `hollinWarrior`, 2 `hollinPyromancer` |
| Jefe | 20 | **`thaneDurgan`** por la gran puerta + 4 `hollinWarrior`. Al 50 % de vida, 2 `ironConstruct` por las puertas `G` (necesita N10 de `encargos.md`, opcional) |

Botín: `boss.thaneDurgan` seguro, 2 `diamond`, y 1-2 comunes de Lunaria.
