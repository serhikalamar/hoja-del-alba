# Lunaria — zonas (niveles 20-30)

Responsable: `continent-lead` de `lunaria`. **Fase futura.** Plantilla: `assets/world/progresion.md` §3.
Áreas con id `lunaria.<zona>`; interiores `lunaria.<zona>.<sitio>`; spawns `<id del área>.<n>`.
Bioma de todas las áreas de suelo: `lunaria` (`.` musgo, `,` setas brillantes, `T` árbol de plata, `b` helecho,
`%` maleza/hierba alta azulada, `~` agua del río, `R` raíz gigante o peña musgosa, `+` estela élfica o tótem lobo).
Velaluna usa el bioma `lunariaCanopy` (ver `mapas/velaluna.md`).

## Resumen

| # | Área (id) | Nombre | Niveles | Bioma / ambiente | Qué hay | Jefe | Conecta con |
|---|---|---|---|---|---|---|---|
| C1 | `lunaria.velaluna` | **Velaluna** | — (segura) | Ciudad élfica en las copas: plataformas de madera de plata, puentes colgantes, farolillos de luna | Palacio de la Reina, forja élfica (Fendril + Brokk), posada (reaparición), torre de Ysolde, santuario, hierbera, maestra de vuelos | — | Raíces (S, Gran Ascensor) · Claros (E, Pasarela del Este) |
| C2 | `lunaria.colmillo` | **Colmillo Gris** | — (segura) | Aldea de los clanes en un claro profundo: tiendas de piel, tótems, gran hoguera | Gran Cubil (Ulma), curtiduría (Hirsa, tienda de cueros/telas), Hoguera del Clan (reaparición), maestro de viajes (un lobo mensajero: mismo NPC de viajes) | — | Raíces (N) · Espesura (E) |
| 1 | `lunaria.raices` | **Raíces de Plata** | 20-22 | Raíces gigantes, setas que brillan, arroyos, ciervos | Boca del Túnel de los Thanes, campamento de Trapisonda (hoguera segura), Hongal Brillante, Sendero de los Ciervos | — | Túnel de los Thanes (O) · Velaluna (N) · Claros (E) · Colmillo Gris (S) |
| 2 | `lunaria.claros` | **Claros de la Luna** | 22-24 | Claros abiertos con estanques de luz, telarañas plateadas, ruinas élficas menores | Ara de los Claros (Thessa, segura), Claro de las Luciérnagas, los Telares, Claro del Abuelo | **Abuelo Fresno Podrido** (`rottenElder`, 23) | Raíces (O) · Velaluna (NO, pasarela) · Espesura (S) · Marchito (E) |
| 3 | `lunaria.espesura` | **Espesura del Aullido** | 24-26 | Bosque cerrado y oscuro, peñas, huesos, niebla, aullidos | Lindero del Clan (tótems), Hondonada del Aullido, Cueva de seda (entrada al Nido), Cubil de la Mala Luna | **Garra Negra** (`blackClaw`, 26) | Colmillo Gris (O) · Claros (N) · Marchito (E) · `e` Nido |
| M | (mazmorra) | **Nido de las Tejedoras** | 25-27 | Piso `webs`: cueva de raíces cubierta de seda, capullos, charcos de savia negra | 4 oleadas + jefe | **Madre Tejedora** (`broodMother`, 27) | Entrada `e` en la Espesura (Cueva de seda) |
| 4 | `lunaria.marchito` | **Bosque Marchito** | 26-28 | Árboles grises y secos, hojas negras, niebla violeta, campamento del Eclipse | Linde Gris, Arboleda Muerta, Campamento Marchito (tiendas, braseros violetas, estandartes del Eclipse) | — (élites: árboles corruptos, osolechuzas) | Espesura (O) · Claros (NO) · Lago (N) |
| 5 | `lunaria.lago` | **Lago de la Luna Caída** | 28-29 | Lago enorme que refleja una luna que ya no está; ruinas élficas antiguas (Selenar); isla del Árbol Madre | Orilla de los Sauces, Ruinas de Selenar (3 aras lunares), Isla del Árbol Madre (entrada al Hueco) | — (guardianes de las aras: élites) | Marchito (S) · `e` Hueco del Árbol Madre |
| F | (mazmorra final) | **Hueco del Árbol Madre** | 29-30 | Piso `hollow`: el interior del tronco, raíces vivas, savia de luz, el Ascua al fondo | 5 oleadas + jefe final | **Ysolde, la Archimaga Marchita** (`ysolde`, 30) | Entrada `e` en la Isla del Árbol Madre |

Ruta principal: Túnel → Raíces → Velaluna → Claros → (Raíces) → Colmillo Gris → Espesura → Nido → Velaluna →
Marchito → Lago → Hueco. Hay **dos anillos** para no volver siempre por el mismo camino:
Raíces ↔ Velaluna ↔ Claros ↔ Raíces y Raíces ↔ Colmillo ↔ Espesura ↔ Claros. El nivel en el nombre de la zona es la
única "puerta" (`progresion.md` §1.4): nada se bloquea salvo las dos mazmorras (por misión).

```
                [ Velaluna ]======(pasarela)=====+
                     | ascensor                  |
 Túnel de los   [ Raíces 20-22 ]---------[ Claros 22-24 ]------+
 Thanes ======>      |                           |              |
                [ Colmillo Gris ]------[ Espesura 24-26 ]---[ Marchito 26-28 ]
                                            e Nido 25-27            |
                                                              [ Lago 28-29 ]
                                                                e Hueco 29-30
```

## Detalle por área

### C1 · Velaluna (`lunaria.velaluna`) — capital élfica

Mapa detallado: `mapas/velaluna.md`. Zona segura: sin monstruos. Llegadas: desde Raíces (Gran Ascensor, sur) y desde
Claros (Pasarela del Este). Reaparición en la posada. NPC: Aurora, Sylra, Ysolde (hasta la misión 8), Ilmar, Nimra,
Mirla; dentro: Elarith (palacio), Fendril y Brokk (forja), Ennis (posada), Liria (santuario).
Tras la misión 8 la torre de Ysolde queda marchita (casillas `T` grises alrededor; cambio de diálogo, no de mapa).

### C2 · Colmillo Gris (`lunaria.colmillo`) — aldea de los clanes

Boceto: `mapas/colmillo.md`. Zona segura. Llegadas: desde Raíces (norte) y desde la Espesura (este). Reaparición en
la Hoguera del Clan. NPC: Ulma (Gran Cubil), Rhovan (hoguera), Hirsa (curtiduría), lobo mensajero `mensajeroColmillo` (viajes), Pico (tras
rescatarlo), cachorros y ancianos de ambiente.

### 1 · Raíces de Plata (`lunaria.raices`) — 20-22

| Zona (`Zone`) | Nivel | Monstruos (cantidad) |
|---|---|---|
| Boca del Túnel (oeste) | 20 | `pixie` ×4, `thornling` ×3 |
| Hongal Brillante (centro y sur) | 21 | `glowcap` ×4, `thornling` ×2, `wisp` ×2 |
| Sendero de los Ciervos (este) | 22 | `corruptStag` ×3, `pixie` ×2 |

Total 20 spawns. Campamento de Trapisonda (hoguera `x`, tienda `n`) junto a la boca del Túnel: punto seguro y de
reaparición del área (M9).

### 2 · Claros de la Luna (`lunaria.claros`) — 22-24

| Zona | Nivel | Monstruos |
|---|---|---|
| Claro de las Luciérnagas (oeste) | 22 | `wisp` ×3, `forestSpirit` ×3, `pixie` ×2 |
| Los Telares (centro-sur) | 23 | `moonSpider` ×3, `spiderling` ×4 (en dos grupos), `webSpitter` ×2 |
| Claro del Abuelo (noreste) | 24 | `forestSpirit` ×2, `owlbear` ×1 (élite), jefe `rottenElder` |

Total 20 spawns + jefe. Ara de los Claros (Thessa; estela `+` y estanque): punto seguro.

### 3 · Espesura del Aullido (`lunaria.espesura`) — 24-26

| Zona | Nivel | Monstruos |
|---|---|---|
| Lindero del Clan (oeste) | 24 | `feralWerewolf` ×4, `corruptStag` ×2 |
| Hondonada del Aullido (centro) | 25 | `moonHowler` ×3, `feralWerewolf` ×3, `owlbear` ×1 |
| Cubil de la Mala Luna (este) | 26 | `feralWerewolf` ×3, `moonHowler` ×2, jefe `blackClaw` |

Total 18 spawns + jefe. La Cueva de seda (`e`, entrada al Nido) está en el norte de la Hondonada, rodeada de
telarañas (`moonSpider` ×2 de guardia, cuentan en el total si se quiere llegar a 20). Pico, el cachorro perdido, está
en un tronco hueco del Cubil.

### M · Nido de las Tejedoras (piso `webs`) — 25-27

Mazmorra de historia (M8). 4 oleadas + jefe:
1. `spiderling` ×8 · 2. `moonSpider` ×4 + `webSpitter` ×2 · 3. `spiderling` ×6 + `webSpitter` ×3 + `moonSpider` ×2 ·
4. `moonSpider` ×4 + `webSpitter` ×4 + `spiderling` ×6 · **Jefe**: `broodMother` (con `spiderling` ×4 a la vez).
Botín: minerales raros de Lunaria (piedra lunar, amatista) + adelanto: algún común de Cenizas con poca probabilidad.

### 4 · Bosque Marchito (`lunaria.marchito`) — 26-28

| Zona | Nivel | Monstruos |
|---|---|---|
| Linde Gris (oeste) | 26 | `witheredArcher` ×3, `thornling` ×3 (variante gris: mismo id), `wisp` ×2 |
| Arboleda Muerta (centro) | 27 | `treant` ×3 (élite), `witheredBlade` ×3 |
| Campamento Marchito (noreste) | 28 | `witheredArcher` ×3, `witheredBlade` ×3, `owlbear` ×1 |

Total 21 spawns. Sin jefe: es la zona de **élites** (los árboles corruptos). NPC de ambiente: dos guardias élficos y
dos lobos del clan que patrullan juntos tras la misión 8.

### 5 · Lago de la Luna Caída (`lunaria.lago`) — 28-29

| Zona | Nivel | Monstruos |
|---|---|---|
| Orilla de los Sauces (sur) | 28 | `witheredBlade` ×3, `wisp` ×3, `forestSpirit` ×2 |
| Ruinas de Selenar (este y oeste) | 29 | `witheredArcher` ×4, `treant` ×2, guardianes de las 3 aras (1 `treant` o `owlbear` élite en cada ara, `scale` 1,5) |
| Isla del Árbol Madre (norte) | 29 | `witheredBlade` ×2, `witheredArcher` ×2 |

Total ~21 spawns. La bajada `e` al Hueco está sellada por raíces negras hasta purificar las 3 aras (misión 10): `DungeonEntrance` con
`lock: .questDone("lunaria.aras_lunares")`. Las aras son NPC con rol `clue` (se "leen" al acercarse con la zona limpia).

### F · Hueco del Árbol Madre (piso `hollow`) — 29-30

Mazmorra final (más larga, como una banda pequeña). 5 oleadas + jefe:
1. `witheredBlade` ×4 + `witheredArcher` ×4 · 2. `treant` ×2 + `wisp` ×6 · 3. `feralWerewolf` ×6 + `moonHowler` ×2 ·
4. `moonSpider` ×4 + `webSpitter` ×3 + `spiderling` ×6 · 5. `witheredBlade` ×4 + `witheredArcher` ×3 + `treant` ×1 ·
**Jefe**: `ysolde`. Botín: Ascua de Lunaria (objeto de historia), pieza `boss.ysolde`, minerales raros, adelanto de
Cenizas.

## Misiones secundarias

Ids `lunaria.<nombre>`. Orientativo: misión de matar corta ≈ 15 % de `xpToNext`; de llegar/rescatar ≈ 20 %; las
que dan pieza de armadura ≈ 25 %. Con las 12 principales (`historia.md`) suman lo que pide `progresion.md`.

| Id | Da | Objetivo | Zona (niv.) | Recompensa extra |
|---|---|---|---|---|
| `lunaria.duendes_ladrones` | Trapisonda | Vencer 8 `pixie` | Raíces (20) | Oro, azogue |
| `lunaria.setas_y_espinos` | Mirla | Vencer 6 `glowcap` y 6 `thornling` | Raíces (21) | Ámbar ×2 |
| `lunaria.ciervos_corruptos` | Ilmar | Vencer 5 `corruptStag` | Raíces (22) | Jade |
| `lunaria.fuegos_fatuos` | Thessa | Vencer 8 `wisp` | Claros (22) | Jade ×2 |
| `lunaria.telaranas` | Sylra | Vencer 6 `moonSpider` y 3 `webSpitter` | Claros (23) | **`helm.lunaria`** |
| `lunaria.osolechuzas` | Hirsa | Vencer 3 `owlbear` | Claros / Espesura (24-25) | **`gloves.lunaria`** |
| `lunaria.aullidos` | Rhovan | Vencer 6 `moonHowler` | Espesura (25) | Piedra lunar |
| `lunaria.cachorro_perdido` | Ulma | Llegar al Cubil y hablar con Pico | Espesura (26) | Amatista (Pico la había "encontrado") |
| `lunaria.savia_negra` | Fendril | Vencer 4 `treant` | Marchito (27) | Pieza: hoja `glaive` de plata de buena calidad |
| `lunaria.arqueros_y_danzantes` | Sylra | Vencer 6 `witheredArcher` y 6 `witheredBlade` | Marchito (27-28) | Piedra lunar ×2 |
| `lunaria.ruinas_de_selenar` | Thessa | Llegar a las 3 ruinas de Selenar | Lago (28) | **`boots.lunaria`** |

11 secundarias + 12 principales. El peto `chest.lunaria` lo da `lunaria.pacto_de_la_luna`.

## Ids para el código (según el contrato de Valdemar: `valdemar/contrato.md`)

Formato igual que `Valdemar.swift`: áreas `lunaria.<área>`, zonas `lunaria.<área>.<zona>`, spawns
`lunaria.<área>.<n>` (en el orden en que el map-designer los coloque, de oeste a este y de norte a sur), salidas
`<área corta>.<punto cardinal>`, mazmorras de historia `lunaria.<mazmorra>`. Coordenadas reales = boceto ×2.

| Área | `kind` | `biome` | Zonas (`Zone.id` · nivel) | `safePoint` (real) |
|---|---|---|---|---|
| `lunaria.velaluna` | `.town` (capital: `Continent.capitalID`) | `.lunariaCanopy` (nuevo) | — | (6, 12) |
| `lunaria.colmillo` | `.town` | `.lunaria` (nuevo) | — | (24, 14) junto a la hoguera |
| `lunaria.raices` | `.field` | `.lunaria` | `lunaria.raices.boca` 20 · `lunaria.raices.hongal` 21 · `lunaria.raices.ciervos` 22 | (10, 8) junto al campamento de Trapisonda |
| `lunaria.claros` | `.field` | `.lunaria` | `lunaria.claros.luciernagas` 22 · `lunaria.claros.telares` 23 · `lunaria.claros.abuelo` 24 | (16, 7) Ara de los Claros |
| `lunaria.espesura` | `.field` | `.lunaria` | `lunaria.espesura.lindero` 24 · `lunaria.espesura.hondonada` 25 · `lunaria.espesura.cubil` 26 | (4, 16) junto a los tótems |
| `lunaria.marchito` | `.field` | `.lunariaWithered` (nuevo) | `lunaria.marchito.linde` 26 · `lunaria.marchito.arboleda` 27 · `lunaria.marchito.campamento` 28 | (4, 11) |
| `lunaria.lago` | `.field` | `.lunaria` | `lunaria.lago.orilla` 28 · `lunaria.lago.selenar` 29 · `lunaria.lago.isla` 29 | (32, 32) orilla sur |

Interiores: `lunaria.velaluna.palacio`, `.posada`, `.hierbera`, `.santuario`, `.forja`, `.torre`;
`lunaria.colmillo.cubil`, `.curtiduria`, `.casalarga`, `.cachorros` (`kind: .interior`, sin monstruos).

| Salida (`AreaExit.id`) | Desde | A | Bloqueo |
|---|---|---|---|
| `velaluna.sur` / `velaluna.este` | Velaluna | `lunaria.raices` / `lunaria.claros` | — |
| `colmillo.norte` / `colmillo.este` | Colmillo Gris | `lunaria.raices` / `lunaria.espesura` | — |
| `raices.oeste` | Raíces | `rocaforja.hondoyunque` (llegada: la que fije Rocaforja junto a su salida `este`) | — (se abre desde Rocaforja con `rocaforja.despertar`) |
| `raices.norte` / `raices.este` / `raices.sur` | Raíces | `lunaria.velaluna` / `lunaria.claros` / `lunaria.colmillo` | — |
| `claros.oeste` / `claros.noroeste` / `claros.sur` / `claros.este` | Claros | `lunaria.raices` / `lunaria.velaluna` / `lunaria.espesura` / `lunaria.marchito` | — |
| `espesura.norte` / `espesura.oeste` / `espesura.este` | Espesura | `lunaria.claros` / `lunaria.colmillo` / `lunaria.marchito` | — |
| `marchito.oeste` / `marchito.noroeste` / `marchito.norte` | Marchito | `lunaria.espesura` / `lunaria.claros` / `lunaria.lago` | — |
| `lago.sur` | Lago | `lunaria.marchito` | — |

Para Rocaforja: su salida `este` de `rocaforja.hondoyunque` debe llevar a `lunaria.raices`, llegada **(2, 10)**.

| Mazmorra (`StoryDungeon.id`) | `floorID` | `level` | Entrada (`DungeonEntrance`) | Bloqueo | `repeatable` |
|---|---|---|---|---|---|
| `lunaria.nido` | `webs` (nuevo) | 26 | `lunaria.espesura`, `e` (40-41, 2) | `.questDone("lunaria.garra_negra")` | sí |
| `lunaria.hueco` | `hollow` (nuevo) | 30 | `lunaria.lago`, `e` (30-31, 8) | `.questDone("lunaria.aras_lunares")` | sí (como la cripta: al repetir, `bossIntroRepeat` = "eco de Ysolde") |

### Misiones → `QuestObjective`

| Misión | Objetivos con los tipos del motor |
|---|---|
| `lunaria.bajo_las_raices` | `.reach(areaID: "lunaria.velaluna")` · `autoAccept`, da `brokk` (al llegar a Raíces) |
| `lunaria.luz_enferma` | `.kill(["forestSpirit"], 6, "lunaria.claros")` |
| `lunaria.abuelo_fresno` | `.defeat("rottenElder")` |
| `lunaria.embajada` | `.talk("ulma")` |
| `lunaria.mala_luna` | `.kill(["feralWerewolf"], 10, "lunaria.espesura")` |
| `lunaria.garra_negra` | `.defeat("blackClaw")` |
| `lunaria.nido_tejedoras` | `.dungeon("lunaria.nido")` |
| `lunaria.la_verdad` | `.talk("elarith")` · `completesOnLastObjective` |
| `lunaria.bosque_marchito` | `.kill(["witheredArcher","witheredBlade"], 10, "lunaria.marchito")` · `.kill(["treant"], 3, "lunaria.marchito")` |
| `lunaria.aras_lunares` | `.read("araOeste")` · `.read("araNoreste")` · `.read("araEste")` (NPC rol `.clue` en el Lago, cada uno junto a su guardián) |
| `lunaria.arbol_madre` | `.dungeon("lunaria.hueco")` · `completesOnLastObjective` |
| `lunaria.pacto_de_la_luna` | `.talk("elarith")` · `.talk("ulma")` · `.talk("brokk")` · **final del continente** (`Continent.finalQuestID`) |
| secundarias | `.kill` con su área; `cachorro_perdido` = `.talk("pico")`; `ruinas_de_selenar` = `.read` de 3 estelas (`estelaSelenar1-3`) |

Requisitos (`requires`): cadena principal en orden (cada una pide la anterior). Secundarias: `duendes_ladrones`,
`setas_y_espinos`, `ciervos_corruptos` tras `bajo_las_raices`; `fuegos_fatuos`, `telaranas` tras `luz_enferma`;
`osolechuzas`, `aullidos`, `cachorro_perdido` tras `embajada`; `savia_negra`, `arqueros_y_danzantes` tras
`la_verdad`; `ruinas_de_selenar` tras `bosque_marchito`. NPC que aparecen/desaparecen con `appearsWhen`: Ysolde
(hasta `la_verdad`, condición inversa: ver N6), Varg (tras `arbol_madre`), patrulla del Marchito (tras `la_verdad`).
