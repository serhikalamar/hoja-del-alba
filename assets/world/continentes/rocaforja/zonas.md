# Rocaforja · Zonas (niveles 10-20)

Plantilla de `progresion.md` §3 (B = 10). Formato de datos: el de Valdemar (`assets/world/continentes/valdemar/contrato.md`,
`Valdemar.swift`, `ValdemarQuests.swift`). Ids: áreas `rocaforja.<área>`, zonas `rocaforja.<área>.<zona>`, spawns
`rocaforja.<área>.<n>`, salidas `<área corta>.<punto cardinal>`, misiones `rocaforja.<nombre>`, mazmorras de historia
`rocaforja.minas` y `rocaforja.forja`. Mapas en `mapas/` (la capital detallada; el resto, bocetos con salidas, zonas
y spawns; todos comprobados: filas iguales, borde cerrado salvo `>`, suelo conectado).

## 1. Resumen

| # | Área | Id | `kind` | Niveles | `Biome` (nuevo) | Qué hay | Jefe |
|---|---|---|---|---|---|---|---|
| Capital | **Hondoyunque** | `rocaforja.hondoyunque` | `.town` | — (segura) | `rocaforjaHall` | Gran Forja (forja + ritual, tier 2; tier 3 tras Durgan), Salón de los Thanes, posada El Barril sin Fondo, maestra de viajes (Frida), cuartel, mercado (Zigo), Cámara del Ascua (sellada) | — |
| 1 | **Pastos Altos** | `rocaforja.pastos` | `.field` | 10-12 | `rocaforjaMeadow` | Llegada desde el Paso del Norte; corrales de Greta; campamento kóbold; pinar de los osos | — |
| 2 | **Canteras de Cobalto** | `rocaforja.canteras` | `.field` | 12-14 | `rocaforjaQuarry` | Cobertizo de Odila; gradas de cobalto; madriguera troglodita; campamento de Mechacorta; bajada `e` a las Minas | **Jefe Mechacorta** (`koboldChief`, 13) |
| 3 | **Cumbres del Águila** | `rocaforja.cumbres` | `.field` | 14-16 | `rocaforjaSnow` | Atalaya de Thrain; círculo de estelas (gólems); ermita del Eclipse; Nido del Roc | **Roc de las Cumbres** (`peakRoc`, 16) |
| Mazmorra | **Minas profundas** | `StoryDungeon` `rocaforja.minas` (piso `mine`) | — | 15-17 (nivel fijo 16) | — | 4 oleadas + jefe; botín raro | **Coloso de cobalto** (`cobaltColossus`, 17) |
| 4 | **Escoriales del Hollín** | `rocaforja.escoriales` | `.field` | 16-18 | `rocaforjaSlag` | 3 crisoles negros; barracón de prisioneros (interior); fundición vieja; la muralla Hollín al norte | — (élites `ironConstruct`) |
| 5 | **Fortaleza Hollín** | `rocaforja.fortaleza` | `.field` | 18-19 | `rocaforjaSlag` | Patio de armas, barracones, fundición, tienda de Brasa, bajada `e` a la Forja Profunda | — |
| Final | **Forja Profunda** | `StoryDungeon` `rocaforja.forja` (piso `forge`) | — | 19-20 (nivel fijo 20) | — | Banda: 4 oleadas + jefe final | **Thane Durgan Hollín** (`thaneDurgan`, 20) |

Interiores (`kind: .interior`, se construyen con `interior(...)` como en Valdehierro):
`rocaforja.hondoyunque.salon` (Hilda), `.forja` (tienda y ritual de Hondoyunque, ver Necesidades de motor),
`.posada` (Gorm), `.cuartel` (Runa), `.establo` (Frida), `.ascua` (Edda; cerrado hasta `rocaforja.forja_profunda`),
`rocaforja.escoriales.barracon` (3 mineros + guardias, nivel 18). Primera versión: si cuesta, los NPC de la capital
pueden estar fuera y los edificios sin interior con `lockedMessage` (salvo la forja y el barracón).

## 2. Salidas (`AreaExit`) y bajadas (`DungeonEntrance`)

| Id | Área | Casillas `>` | Hacia | Llegada | `lock` / aviso |
|---|---|---|---|---|---|
| `paso.norte` (**ya existe**) | `valdemar.paso` | (22-24, 0) | `rocaforja.pastos` | (25, 32) | Hoy `.comingSoon("rocaforja")`: pasa a `.questDone("valdemar.paso_norte")` |
| `pastos.sur` | `rocaforja.pastos` | (24-27, 33) | `valdemar.paso` | (23, 1) | — |
| `pastos.norte` | `rocaforja.pastos` | (24-27, 0) | `rocaforja.hondoyunque` | (27, 31) | — |
| `pastos.este` | `rocaforja.pastos` | (51, 16-18) | `rocaforja.canteras` | (1, 16) | — |
| `hondoyunque.sur` | `rocaforja.hondoyunque` | (26-29, 33) | `rocaforja.pastos` | (25, 5) | — |
| `hondoyunque.oeste` | `rocaforja.hondoyunque` | (0, 20-22) | `rocaforja.canteras` | (2, 6) | `.questDone("rocaforja.prueba_del_thane")` — "El rastrillo de la galería está bajado. Orden de la Thane." |
| `hondoyunque.este` | `rocaforja.hondoyunque` | (55, 10-12) | `lunaria.raices` | (2, 10) | `.questDone("rocaforja.despertar")` — "El Túnel de los Thanes está sellado. Solo la Thane puede abrirlo." Mientras Lunaria no esté construida: `toArea: "lunaria"`, `arrival: nil`, `.comingSoon("lunaria")`. La vuelta (`raices.oeste`, de Lunaria) llega a **(53, 11)** |
| `canteras.oeste` | `rocaforja.canteras` | (0, 15-17) | `rocaforja.pastos` | (49, 17) | — |
| `canteras.noroeste` | `rocaforja.canteras` | (0, 5-7) | `rocaforja.hondoyunque` | (2, 21) | `.questDone("rocaforja.prueba_del_thane")` |
| `canteras.norte` | `rocaforja.canteras` | (24-27, 0) | `rocaforja.cumbres` | (23, 34) | — (el nivel avisa) |
| `canteras.este` | `rocaforja.canteras` | (51, 26-28) | `rocaforja.escoriales` | (1, 27) | `.questDone("rocaforja.minas_profundas")` — "Un derrumbe tapa el camino. Los kóbolds lo hicieron a propósito." |
| `cumbres.sur` | `rocaforja.cumbres` | (22-25, 35) | `rocaforja.canteras` | (25, 2) | — |
| `cumbres.este` | `rocaforja.cumbres` | (47, 8-10) | `rocaforja.escoriales` | (1, 9) | — |
| `escoriales.oeste` | `rocaforja.escoriales` | (0, 8-10) | `rocaforja.cumbres` | (45, 9) | — |
| `escoriales.suroeste` | `rocaforja.escoriales` | (0, 26-28) | `rocaforja.canteras` | (49, 27) | — |
| `escoriales.puerta` | `rocaforja.escoriales` | (24-27, 0) | `rocaforja.fortaleza` | (23, 23) | `.questDone("rocaforja.crisoles_negros")` |
| `escoriales.brecha` | `rocaforja.escoriales` | (37-39, 0) | `rocaforja.fortaleza` | (36, 23) | `.questDone("rocaforja.crisoles_negros")` |
| `fortaleza.puerta` | `rocaforja.fortaleza` | (22-25, 25) | `rocaforja.escoriales` | (25, 2) | — |
| `fortaleza.brecha` | `rocaforja.fortaleza` | (35-37, 25) | `rocaforja.escoriales` | (38, 2) | — |
| `e` → `rocaforja.minas` | `rocaforja.canteras` | (40-41, 29) | piso `mine` | vuelve a (40, 29) | `.questDone("rocaforja.humo_en_las_cumbres")` |
| `e` → `rocaforja.forja` | `rocaforja.fortaleza` | (22-25, 7) | piso `forge` | vuelve a (22, 7) | `.questDone("rocaforja.asalto_a_la_fortaleza")` |

Puertas de edificios con historia (hoy `ValdemarQuests.doorLocks` solo mira Valdehierro: ver Necesidades de motor):
`salon` abierta; `forja` `.questDone("rocaforja.prueba_del_thane")` ("Hilda no deja forjar a un Hollín… todavía");
`ascua` `.questDone("rocaforja.forja_profunda")`.

**Puntos seguros** (`safePoint`): Pastos (22, 30) junto a la hoguera; Canteras (15, 14) entre las farolas;
Cumbres (20, 31) junto a la hoguera; Escoriales (2, 9) entrada oeste; Fortaleza (23, 22). La capital: su entrada
(27, 31) (como la Puerta sur de Valdehierro).

Mapa del continente (`Continent.mapLayout`, columna-fila): `rocaforja.hondoyunque` (0,1) · `rocaforja.canteras` (1,1) ·
`rocaforja.pastos` (1,2) · `rocaforja.cumbres` (1,0) · `rocaforja.escoriales` (2,0) · `rocaforja.fortaleza` (3,0).
```
          Cumbres ── Escoriales ── Fortaleza
             │            │
Hondoyunque ─ Canteras ───┘
     │          │
     └─ Pastos ─┘── (sur: Paso del Norte, Valdemar)
```

## 3. Monstruos por zona (detalle en `bestiario.md`)

En el campo **solo los jefes son permanentes** (`AreaMap.isPermanent`); el resto reaparece. Los "guardias" fijos de
la historia van en interiores (barracón).

| Área (zonas) | Monstruos de campo | Total | Jefe |
|---|---|---|---|
| Pastos: `paso` 10, `corrales` 10, `prado` 11, `campamento` 11, `pinar` 12 | 6 `kobold`, 5 `mountainGoat`, 3 `koboldCandle`, 3 `cliffBear` | 17 | — |
| Canteras: `patio` 12, `gradas` 13, `madriguera` 14, `campamento` 13 | 4 `kobold`, 5 `koboldCandle` (2 escoltan al jefe), 4 `koboldGeomancer`, 5 `trogg`, 2 `troggBrute` | 20 | `koboldChief` |
| Cumbres: `ladera` 14, `estelas` 15, `ermita` 15, `paso` 15, `nido` 16 | 5 `cliffEagle`, 3 `mountainGoat`, 4 `rockGolem`, 4 `earthElemental`, 3 `emberAcolyte` | 19 | `peakRoc` |
| Minas profundas (16) | oleadas (`mapas/mazmorras.md`) | — | `cobaltColossus` |
| Escoriales: `camino` 16, `fundicion` 16, `lava` 17, `alto` 18 | 6 `hollinWarrior`, 4 `hollinRifleman`, 3 `emberAcolyte`, 3 `earthElemental`, 2 `ironConstruct` | 18 | — (+ 6 guardias en el barracón) |
| Fortaleza: `patio` 18, `barracones` 19, `fundicion` 19, `forja` 19 | 6 `hollinWarrior`, 4 `hollinRifleman`, 4 `hollinPyromancer`, 3 `ironConstruct` | 17 | — |
| Forja Profunda (20) | oleadas | — | `thaneDurgan` |

Zonas por área con su rectángulo aproximado: en cada `mapas/<área>.md` (el map-designer las cierra; deben cubrir el
área sin solaparse, como en `Valdemar.swift`).

## 4. Misiones (`RocaforjaQuests.all`, 22: 8 de historia + 14 secundarias)

Formato `Quest` de `ValdemarQuests.swift`. XP según `progresion.md` (normal ≈ 25 % de `xpToNext(nivel)`, historia
50-100 %): a nivel 10 un 25 % son ~505 XP, a nivel 15 ~960, a nivel 19 ~1 400. Las cifras exactas, el
balance-designer (B). `kill` con `areaID: nil` cuenta en todo el continente.

| Id | Tipo | Nv. | `giverID` | `requires` | `objectives` | `reward` (orientativa) |
|---|---|---|---|---|---|---|
| `rocaforja.paso_del_norte` | Historia, `autoAccept`, `completesOnLastObjective` | 10 | `brokk` | `.questDone("valdemar.paso_norte")` | `reach("rocaforja.hondoyunque")` | 50 % XP, 40 oro |
| `rocaforja.cabras_perdidas` | Secundaria | 10 | `gretaCabrera` | — | `kill(["kobold"], 8, "rocaforja.pastos")` | 25 % XP, 30 oro, `tin: 2` |
| `rocaforja.velas_robadas` | Secundaria | 11 | `gormPosadero` | `paso_del_norte` | `kill(["koboldCandle"], 6, nil)` | 25 % XP, 30 oro, `topaz: 1` |
| `rocaforja.osos_hambrientos` | Secundaria | 12 | `gretaCabrera` | `cabras_perdidas` | `kill(["cliffBear"], 4, "rocaforja.pastos")` | 25 % XP, 40 oro, `gearID: boots.rocaforja` |
| `rocaforja.vetas_de_cobalto` | Secundaria | 12 | `odilaCapataz` | `paso_del_norte` | `kill(["trogg"], 8, "rocaforja.canteras")` | 25 % XP, 40 oro, `cobalt: 3` |
| `rocaforja.geomantes` | Secundaria | 13 | `odilaCapataz` | `vetas_de_cobalto` | `kill(["koboldGeomancer"], 6, nil)` | 25 % XP, 45 oro, `runestone: 1` |
| `rocaforja.prueba_del_thane` | Historia | 13 | `thaneHilda` | `paso_del_norte` | `defeat("koboldChief")` | 75 % XP, 80 oro, `gearID: helm.rocaforja`; abre galería y Gran Forja |
| `rocaforja.brutos_de_la_madriguera` | Secundaria | 14 | `runaEscudohondo` | `prueba_del_thane` | `kill(["troggBrute"], 4, nil)` | 25 % XP, 50 oro, `cobalt: 2` |
| `rocaforja.plumas_de_aguila` | Secundaria | 14 | `fridaArriera` | `prueba_del_thane` | `kill(["cliffEagle"], 8, "rocaforja.cumbres")` | 25 % XP, 50 oro, `topaz: 1` |
| `rocaforja.estelas_rotas` | Secundaria | 15 | `eddaGuardiana` | `prueba_del_thane` | `kill(["rockGolem"], 5, nil)`, `kill(["earthElemental"], 5, nil)` | 25 % XP, 60 oro, `runestone: 1` |
| `rocaforja.ermita_del_eclipse` | Secundaria | 15 | `runaEscudohondo` | `prueba_del_thane` | `kill(["emberAcolyte"], 8, nil)` | 25 % XP, 60 oro, `tin: 2` |
| `rocaforja.humo_en_las_cumbres` | Historia | 16 | `thrainVigia` | `prueba_del_thane` | `defeat("peakRoc")` | 75 % XP, 100 oro, `runestone: 1` |
| `rocaforja.minas_profundas` | Historia | 17 | `thaneHilda` | `humo_en_las_cumbres` | `dungeon("rocaforja.minas")` | 75 % XP, 120 oro, `diamond: 1`; abre `canteras.este` |
| `rocaforja.arcabuces` | Secundaria | 17 | `runaEscudohondo` | `minas_profundas` | `kill(["hollinRifleman"], 8, nil)` | 25 % XP, 70 oro, `cobalt: 2` |
| `rocaforja.crisoles_negros` | Historia | 18 | `eddaGuardiana` | `minas_profundas` | `read("crisolNegro1")`, `read("crisolNegro2")`, `read("crisolNegro3")`, `rescue(["mineroCautivo1","mineroCautivo2","mineroCautivo3"])` | 75 % XP, 120 oro, `gearID: gloves.rocaforja`; abre la Fortaleza |
| `rocaforja.automatas` | Secundaria | 18 | `brokk` | `crisoles_negros` | `kill(["ironConstruct"], 4, nil)` | 25 % XP, 80 oro, `runestone: 1` |
| `rocaforja.piromantes` | Secundaria | 18 | `eddaGuardiana` | `crisoles_negros` | `kill(["hollinPyromancer"], 6, nil)` | 25 % XP, 80 oro, `topaz: 2` |
| `rocaforja.asalto_a_la_fortaleza` | Historia | 19 | `runaEscudohondo` | `crisoles_negros` | `kill(["hollinWarrior"], 12, "rocaforja.fortaleza")`, `talk("brokk")` | 75 % XP, 150 oro, `gearID: chest.rocaforja` |
| `rocaforja.cerveza_de_la_victoria` | Secundaria | 19 | `gormPosadero` | `asalto_a_la_fortaleza` | `kill(["hollinWarrior"], 10, nil)` | 25 % XP, 90 oro, `topaz: 3` |
| `rocaforja.forja_profunda` | Historia | 20 | `thaneHilda` | `asalto_a_la_fortaleza` | `dungeon("rocaforja.forja")` | 100 % XP, 250 oro, `diamond: 2` (`boss.thaneDurgan` lo suelta el jefe) |
| `rocaforja.fausto` | Secundaria (historia de Valdemar) | 20 | `faustoCautivo` | `forja_profunda` | `read("faustoCautivo")`, `talk("thaneHilda")` | 25 % XP, 100 oro |
| `rocaforja.despertar` | Historia, final del continente, `completesOnLastObjective` | 20 | `eddaGuardiana` | `forja_profunda` | `talk("brokk")` (en la Gran Forja: ritual de despertar) | 50 % XP, **Hoja del Alba (II)**; `Continent.finalQuestID` (tier 3 en la forja) |

Cuentas: 14 secundarias (~3,5 niveles) + 8 de historia (~5,5 niveles) ≈ 9 niveles; el resto, monstruos (~250 con
misiones, `progresion.md`). Si sobra XP, se quitan `cerveza_de_la_victoria` y `plumas_de_aguila`.

## 5. Ruta prevista

Pastos (10-12) → Hondoyunque → Pastos/Canteras (12-14, Mechacorta) → Cumbres (14-16, Roc) → Minas profundas (16-17)
→ Escoriales (16-18, crisoles y barracón) → Fortaleza (18-19) → Forja Profunda (20) → Hondoyunque (despertar).
Rutas en anillo: Pastos-Hondoyunque-Canteras (por la galería) y Canteras-Cumbres-Escoriales-Canteras.
