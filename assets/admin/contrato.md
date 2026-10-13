# Contrato de ajustes en vivo (`GameTuning`)

Lo leen el backend (tabla `game_config`, descarga en la app) y el panel web (`admin/`). Responsable del lado del
juego: `game-programmer`. Código: `src/GameCore/Sources/GameCore/GameTuning.swift` (tipos), `TuningSchema.swift`
(rangos y descripciones), `TunedData.swift` (validar y aplicar). Tests: `TuningTests.swift`.

## Cómo funciona

1. El panel guarda un **documento JSON de ajustes** con solo lo que cambia (todo es opcional).
2. El juego lo descarga al abrirse y llama a:
   ```swift
   let tuning = try JSONDecoder().decode(GameTuning.self, from: data)
   let avisos: [String] = GameTuning.apply(tuning)   // ids desconocidos, valores recortados…
   GameTuning.current                                // el documento aplicado (vacío por defecto)
   GameTuning.lastWarnings                           // los avisos del último apply
   ```
3. `apply` parte **siempre de los valores del código** (no acumula): `apply(GameTuning())` vuelve a los de serie.
4. Se precalculan todas las tablas al aplicar; el juego no busca ajustes en cada frame.

Reglas que garantiza el juego:

- **Ids desconocidos** (monstruo, pieza, zona…) y **campos desconocidos** (erratas como `"hpp"`) se ignoran con un aviso.
- **Números fuera de rango** se recortan al rango y los **enteros** se redondean, con aviso.
- **Lo guardado no cambia**: un arma o armadura ya forjada conserva sus números (van en el `Item` del perfil).
  Los ajustes valen para lo que se forje, compre o aparezca después.
- Con el documento **vacío** el juego es idéntico al del código (comprobado: mismas oleadas de la arena, mismas
  tablas, mismas ofertas de la forja con la misma semilla).
- Llamar a `apply` en el hilo principal, idealmente antes de empezar una partida: los monstruos que ya están en
  pantalla no cambian; los siguientes, sí. (Es seguro aunque otro hilo esté leyendo: las tablas viejas no se liberan.)
- `schemaVersion` mayor que la del juego (`GameTuning.currentSchemaVersion`, hoy **1**): se aplica lo que se
  entiende y se avisa.

## Valores base para el panel

`make datos` (o `cd tools/Harness && swift run -c release Harness exportar-datos [carpeta]`) escribe en
`admin/public/data/` (por defecto):

| Fichero | Contenido |
|---|---|
| `enemigos.json` | Cada monstruo: nombre, familia (plantilla de dibujo), comportamiento, jefe, `base` (las claves de `enemies`), áreas y zonas donde sale (con ids de spawn y nivel), mazmorras y oleadas, misiones que lo piden, primera oleada de la arena, oleadas de jefe, pieza que suelta en la arena (`pieza`) y en la historia (`piezaHistoria`) |
| `piezas.json` | `piezas` (normales, únicas y copias de jefe de la historia: hueco, forma, material, elementos, habilidad, origen = forja / jefe / rescate, `base` = `stats`, `price`, `tier`), `armaduras` (`base` = `stats`, `price`), `materiales` (tier y poder; no ajustables) |
| `minerales.json` | Cada mineral (`base` = `value`, `dropWeight`, `stats`), rareza, continentes; familias por continente con su peso |
| `zonas.json` | Continentes, áreas (tipo, `base.level`, zonas con `base.level` y sus spawns, spawns fuera de zona, rescates, mazmorras), mazmorras de historia (`base` = `level`, `waves`, `bossEscort`), las 30 primeras oleadas de la arena |
| `misiones.json` | Misiones (título, quién la da, objetivos, `base` = `xp`, `gold`, `minerals`) y rescates (`base` = `gold`, `minerals`, pieza) |
| `economia.json` | `base` (todas las claves de `economy`), `ruleta` (`base` = `weight`, `multiplier`) y tablas de referencia (XP por nivel, oro y nivel de la arena por oleada) |
| `esquema.json` | Cada apartado y campo ajustable: clave, tipo, mínimo, máximo, descripción en español y a qué valor del código corresponde; las estadísticas válidas |

Los valores ajustables van siempre en un objeto `base` con **las mismas claves que este contrato**, para que el
panel muestre "base → ajustado". Si cambia el código, se vuelve a ejecutar `make datos`.

Para probar un documento sin publicarlo: `cd tools/Harness && swift run -c release Harness balance --ajustes <fichero.json>`
(vale con cualquier comando del banco de pruebas: `historia`, `valdemar`…). Imprime los avisos.

## Documento

```json
{
  "schemaVersion": 1,
  "version": 7,
  "note": "Ratas más duras y más oro en la arena",
  "enemies":  { "<id de monstruo>": { … } },
  "parts":    { "<id de pieza>": { … } },
  "armor":    { "<id de diseño>": { … } },
  "minerals": { "<id de mineral>": { … } },
  "areas":    { "<id de área>": { "level": 6 } },
  "zones":    { "<id de zona>": { "level": 7 } },
  "spawns":   { "<id de spawn>": "<id de monstruo>" },
  "dungeons": { "<id de mazmorra>": { … } },
  "quests":   { "<id de misión>": { "xp": 120, "gold": 60, "minerals": { "silver": 2 } } },
  "rescues":  { "<id de aldeano>": { "gold": 40, "minerals": { "iron": 1 } } },
  "roulette": { "<id de casilla>": { "weight": 6, "multiplier": 2 } },
  "economy":  { … }
}
```

| Campo | Tipo | Qué es |
|---|---|---|
| `schemaVersion` | entero | Versión del formato (1). Si falta, 1. |
| `version` | entero, opcional | Versión publicada en el panel (para saber qué ajustes tiene el jugador). |
| `note` | texto, opcional | Nota de quien publica. |

Todos los apartados son mapas `id → ajuste` salvo `economy` (un objeto) y `spawns` (`id → id de monstruo`).

### `enemies` — monstruos y jefes (`EnemyDefinition`, `Enemy.swift`)

Los números son los del **nivel de aparición**; luego escalan con el nivel de la zona u oleada (ver `economy.enemy*`).

| Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|
| `hp` | número | 1 – 1 000 000 | `EnemyDefinition.hp` | Vida |
| `damage` | número | 0 – 100 000 | `.damage` | Daño por golpe o proyectil |
| `speed` | número | 10 – 250 | `.speed` | Velocidad (el héroe va a 125) |
| `attackCooldown` | número | 0,8 – 10 | `.attackCooldown` | Segundos entre ataques (0,8 = el más rápido de hoy) |
| `attackRange` | número | 4 – 40 cuerpo a cuerpo / embestida; 60 – 300 a distancia | `.attackRange` | Alcance |
| `level` | entero | 1 – 60 | `.level` | Nivel de aparición: oleadas de la arena en las que sale y desde dónde escala |
| `dropChance` | número | 0 – 1 | `.dropChance` | Probabilidad de mineral por tirada (1 = siempre, como los jefes) |
| `dropRolls` | entero | 0 – 10 | `.dropRolls` | Tiradas de mineral |
| `xpMultiplier` | número | 0 – 10 | `.xpMultiplier` (nuevo, 1) | Multiplica la XP que da (arena e historia) |
| `goldMultiplier` | número | 0 – 10 | `.goldMultiplier` (nuevo, 1) | Multiplica el oro que da en la historia (en la arena se cobra por oleada) |
| `storyHPMultiplier` | número | 0,1 – 10 | `EnemyDefinition.storyBossTuning[id].hp` | **Solo jefes**: vida en la historia (la arena usa la base) |
| `storyDamageMultiplier` | número | 0,1 – 10 | `storyBossTuning[id].damage` | **Solo jefes**: daño en la historia |

Ejemplo: `"enemies": { "rat": { "hp": 15 }, "ogre": { "storyHPMultiplier": 1.6 } }`

### `parts` — piezas de arma (`WeaponPart`, `Parts.swift`)

Ids: `head.<forma>.<metal>`, `guard.<forma>.<metal>`, `grip.<forma>.<madera>`, `boss.<jefe>` (arena),
`boss.<jefe>.valdemar` (copia de la historia, se ajusta aparte) y `legend.dawn`.

| Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|
| `stats` | mapa estadística → número | ver Estadísticas | `WeaponPart.stats` | Valor final de las que vienen; las demás no cambian |
| `price` | entero | 0 – 1 000 000 | `.price` | Precio en la forja (las únicas no se venden: 0) |
| `tier` | entero | 1 – 6 | `.tier` | Desde qué nivel de forja se vende y precio del ritual |

Ejemplo: `"parts": { "head.sword.copper": { "stats": { "attack": 10 }, "price": 28 } }`

### `armor` — diseños de armadura (`ArmorStyle`, `Armor.swift`)

| Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|
| `stats` | mapa estadística → número | ver Estadísticas | `ArmorStyle.base` | Estadísticas con material de tier 1 (el material las multiplica) |
| `price` | número | 0 – 10 000 | `ArmorStyle.forgePrice` | Oro base a tier 1; coste = precio × poder^1,3 + 5 (de serie: peto 30, casco 22, botas 20, guantes 16) |

### `minerals` — minerales (`Mineral`, `Mineral.swift`)

Ids: `copper`, `iron`, `silver`, `gold`, `emerald`, `sapphire`, `ruby`, `amethyst`, `diamond`, `mithril`.

| Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|
| `value` | entero | 0 – 100 000 | `Mineral.value` | Valor en oro por unidad (precio de venta de lo forjado) |
| `dropWeight` | número | 0 – 100 | `Mineral.dropPercent` | Peso en el botín de la **arena** (los 10 suman 100 de serie; si todos quedan a 0, se usan los de serie) |
| `stats` | mapa estadística → número | ver Estadísticas | `Mineral.buffPerUnit` | Bonificación por unidad al forjar (la armadura usa la mitad) |

### `areas`, `zones`, `spawns` — el mundo (`Town.swift`, `Valdemar.swift`)

| Apartado | Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|---|
| `areas.<id>` | `level` | entero | 1 – 60 | `AreaMap.level` | Nivel de los monstruos fuera de zonas (interiores y campo) |
| `zones.<id>` | `level` | entero | 1 – 60 | `Zone.level` | Nivel de los monstruos de la zona (y oro al liberarla) |
| `spawns.<id>` | — | id de monstruo | — | `Spawn.enemyID` | Qué monstruo sale en ese punto |

Reglas de `spawns`: los **jefes no se cambian ni se ponen** en otro sitio (misiones `defeat`, piezas de jefe, monstruos
que no reaparecen); si una misión de "mata N de X en tal área" se queda sin X en esa área, se **deshacen** los
cambios de spawns de esa área (con aviso). Ids de áreas, zonas y spawns: `zonas.json`.

Ejemplo: `"zones": { "valdemar.huertos.molino": { "level": 7 } }, "spawns": { "south.1": "goblin" }`

### `dungeons` — mazmorras de historia (`StoryDungeon`, `Valdemar.swift`)

| Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|
| `level` | entero | 1 – 60 | `StoryDungeon.level` | Nivel fijo de los monstruos |
| `waves` | lista de mapas id → cuántos | 1 – 10 oleadas; 0 – 40 por tipo | `.waves` | Sustituye a **todas** las oleadas; sin jefes; cada oleada con al menos un monstruo (si no, se ignora entera) |
| `bossEscort` | mapa id → cuántos | 0 – 40, sin jefes | `.bossEscort` | Escolta del jefe (el jefe no se cambia) |

Ejemplo: `"dungeons": { "valdemar.calabozos": { "level": 10, "waves": [ { "goblinElite": 5 }, { "troll": 3, "orc": 2 } ] } }`

### `quests` y `rescues` — recompensas (`ValdemarQuests.swift`, `Town.swift`)

| Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|
| `xp` | entero | 0 – 1 000 000 | `QuestReward.xp` | Experiencia (**solo misiones**; en rescates se ignora con aviso) |
| `gold` | entero | 0 – 1 000 000 | `QuestReward.gold`, `NPC.reward.gold` | Oro |
| `minerals` | mapa id de mineral → unidades | 0 – 99 | `.minerals` | Si viene, **sustituye** a todos los de la recompensa (`{}` = ninguno) |

Los rescates se ajustan por id del aldeano o la princesa (`marta`, `princess`…); vale para el que está en su casa
(o en el salón del trono). La pieza que dan no se cambia.

### `roulette` — ruleta de la forja (`Roulette`, `Crafting.swift`)

Ids: `broken`, `crude`, `normal`, `fine`, `excellent`, `masterwork`.

| Clave | Tipo | Rango | Código | Descripción |
|---|---|---|---|---|
| `weight` | número | 0 – 100 | `CraftQuality.weight` | Peso base de la casilla (si todas quedan a 0, se usan las de serie) |
| `multiplier` | número | 0,1 – 5 | `CraftQuality.multiplier` | Multiplica estadísticas y valor del objeto forjado |

### `economy` — números globales (`EconomyValues` en `TunedData.swift`)

| Clave | Tipo | Rango | Base | Código | Descripción |
|---|---|---|---|---|---|
| `mineralDropRate` | número | 0 – 5 | 0,15 | `Mineral.dropRateMultiplier` | Multiplica la probabilidad de mineral de los monstruos normales |
| `continentLootWeights` | lista de 5 números | 0 – 100 c/u | [35, 27, 20, 12, 6] | `Continent.familyWeights` | Pesos de la familia de minerales del continente (de común a muy rara) |
| `arenaStartingGold` | entero | 0 – 100 000 | 50 | `PlayerProfile.arenaRun` | Oro al empezar la arena |
| `arenaRewardBase` | entero | 0 – 10 000 | 16 | `Arena.reward(wave:)` | Oro fijo por oleada superada |
| `arenaRewardPerWave` | entero | 0 – 1 000 | 7 | `Arena.reward(wave:)` | Oro extra × número de oleada |
| `arenaWavesPerShopLevel` | entero | 1 – 10 | 2 | `Arena.shopLevel(wave:)` | Nivel de forja de la arena = oleada ÷ esto |
| `wallWave` | entero | 5 – 200 | 20 | `Arena.wallWave` | Desde esta oleada los monstruos suben 2 niveles por oleada |
| `arenaBossXPMultiplier` | número | 0 – 50 | 12 | `Leveling.arenaBossMultiplier` | XP de los jefes en la arena |
| `storyBossXPMultiplier` | número | 0 – 50 | 6 | `Leveling.storyBossMultiplier` | XP de los jefes en la historia |
| `respawningXPMultiplier` | número | 0 – 10 | 0,3 | `Leveling.respawningMultiplier` | XP de los monstruos que reaparecen |
| `xpCurveBase` | número | 1 – 1 000 | 50 | `Leveling.xpToNext` | XP por nivel = base × nivel^exponente + fija |
| `xpCurveExponent` | número | 1 – 3 | 1,6 | `Leveling.xpToNext` | |
| `xpCurveFlat` | entero | 0 – 1 000 | 30 | `Leveling.xpToNext` | |
| `levelHPGrowth` | número | 0 – 1 | 0,08 | `Leveling.levelBonus` | Vida extra por nivel (fracción de la de la raza) |
| `levelAttackGrowth` | número | 0 – 1 | 0,085 | `Leveling.levelBonus` | Ataque extra por nivel (fracción del de la raza) |
| `levelDefensePerLevel` | número | 0 – 10 | 0,6 | `Leveling.levelBonus` | Defensa extra por nivel |
| `enemyHPPerLevel` | número | 0 – 1 | 0,13 | `EnemyDefinition.stats(level:)` | Vida extra por nivel sobre el suyo |
| `enemyHPDifficulty` | número | 0 – 1 | 0,11 | `stats(level:)` | Vida extra por nivel de juego |
| `enemyDamagePerLevel` | número | 0 – 1 | 0,10 | `stats(level:)` | Daño extra por nivel sobre el suyo |
| `enemyDamageDifficulty` | número | 0 – 1 | 0,09 | `stats(level:)` | Daño extra por nivel de juego |
| `enemySpeedPerLevel` | número | 0 – 0,2 | 0,02 | `stats(level:)` | Velocidad extra por nivel sobre el suyo |
| `storyKillGoldBase` | entero | 0 – 1 000 | 1 | `StoryEconomy.killGold` | Oro por monstruo = base + nivel ÷ nivelesPorMoneda (+ jefe) |
| `storyKillGoldLevelsPerCoin` | entero | 1 – 60 | 3 | `StoryEconomy.killGold` | |
| `storyBossGoldPerLevel` | entero | 0 – 1 000 | 10 | `StoryEconomy.bossGoldPerLevel` | Oro extra de un jefe × nivel |
| `storyZoneGoldPerLevel` | entero | 0 – 1 000 | 3 | `StoryEconomy.zoneGold` | Oro × nivel al liberar una zona |
| `storyDungeonRepeatPartChance` | número | 0 – 1 | 0,25 | `StoryDungeon.repeatPartChance` | Pieza del jefe al repetir una mazmorra |
| `forgeGoldBase` | entero | 0 – 10 000 | 5 | `WeaponRecipe.goldCost` | Oro del ritual = base + porTier × tier |
| `forgeGoldPerTier` | entero | 0 – 10 000 | 10 | `WeaponRecipe.goldCost` | |
| `rerollBaseCost` | entero | 0 – 10 000 | 10 | `ShopGenerator.rerollCost` | Primera renovación de la forja |
| `rerollCostStep` | entero | 0 – 10 000 | 10 | `ShopGenerator.rerollCost` | Lo que sube cada renovación |
| `potionBasePrice` | entero | 0 – 10 000 | 15 | `ShopGenerator.offers` | Poción = base + porNivel × nivel de forja |
| `potionPricePerLevel` | entero | 0 – 1 000 | 5 | `ShopGenerator.offers` | |
| `potionHeal` | número | 0,05 – 1 | 0,5 | `ShopGenerator.offers` | Fracción de vida que cura |

Ejemplo: `"economy": { "arenaRewardBase": 20, "mineralDropRate": 0.2, "continentLootWeights": [30, 28, 22, 13, 7] }`

### Estadísticas (`stats` de piezas, armaduras y minerales; `StatKind`)

| Clave | Rango | Descripción |
|---|---|---|
| `maxHP` | −200 – 2000 | Vida máxima |
| `attack` | −50 – 500 | Ataque |
| `defense` | −50 – 200 | Defensa |
| `attackSpeed` | −1 – 2 | Ataques por segundo (suma) |
| `range` | −30 – 80 | Alcance |
| `moveSpeed` | −60 – 60 | Velocidad de movimiento |
| `critChance` | −0,5 – 0,5 | Probabilidad de crítico (0,05 = 5 %) |
| `critMultiplier` | −1 – 3 | Daño crítico extra (0,2 = +20 %) |
| `lifesteal` | 0 – 0,2 | Robo de vida |
| `goldBonus` | −0,5 – 2 | Oro extra |
| `regen` | 0 – 20 | Vida por segundo |

(Al jugar, el total del héroe se sigue limitando con `Stats.clampedForPlay`.)

## Avisos

`apply` devuelve textos en español con la ruta del campo, p. ej.:

```
enemies.dragon: monstruo desconocido; se ignora
enemies.goblin.dmg: campo desconocido; se ignora
enemies.rat.attackCooldown: 0.2 fuera de rango [0.8, 10]; se usa 0.8
economy.wallWave: 22.5 no es entero; se usa 23
spawns.valdemar.huertos.1: los jefes no se cambian ni se ponen en otro sitio (misiones y piezas); se ignora
spawns: «valdemar.molino» necesita zombieFarmer en valdemar.huertos; se deshacen los cambios de spawns de esa área
```

## Ejemplo completo

```json
{
  "schemaVersion": 1,
  "version": 3,
  "note": "Arena: más oro al principio; Ogro más blando en la historia",
  "enemies": {
    "goblin": { "hp": 25, "damage": 5 },
    "ogre": { "storyHPMultiplier": 1.5 }
  },
  "parts": { "head.dagger.copper": { "stats": { "attack": 7 }, "price": 26 } },
  "minerals": { "ruby": { "value": 30, "stats": { "critChance": 0.035 } } },
  "zones": { "valdemar.robleda.guarida": { "level": 8 } },
  "quests": { "valdemar.caza_mayor": { "gold": 70, "minerals": { "iron": 3, "silver": 1 } } },
  "economy": { "arenaStartingGold": 70, "arenaRewardBase": 20 }
}
```

## Qué no se puede ajustar todavía (y por qué)

- **Número de monstruos por zona y su posición**: los spawns son casillas del mapa (texto) con ids guardados en las
  partidas; solo se cambia *qué* monstruo sale en cada punto. Para "más monstruos" hay que tocar el mapa.
- **Composición de las oleadas de la arena** (cuántos, qué tiers, cada cuánto el jefe): salen de una semilla y de
  fórmulas (`Arena.wave`); sí se puede mover el `level` de un monstruo (cambia en qué oleadas sale) y el muro.
- **Jefes**: no se cambian de sitio ni de pieza (misiones `defeat`, piezas únicas, monstruos permanentes).
- **Materiales** (poder por tier ×1, ×1,6, ×2,4…): multiplican todas las piezas y armaduras a la vez y las piezas
  normales se generan a partir de ellos; se ajustan pieza a pieza.
- **Habilidades** (`Ability.swift`): son reglas de combate con código propio, no solo números.
- **Razas** (estadísticas base del héroe) y límites `Stats.clampedForPlay`: fuera de este primer contrato.
- **Textos** (nombres, diálogos): el contrato es solo de números; los textos van con la app.
- **Premio extra de las mazmorras** (`StoryDungeon.winBonus`) y la pieza de los rescates: pendientes.
- Lo ya forjado o guardado en el perfil: a propósito, para no cambiar las partidas.
