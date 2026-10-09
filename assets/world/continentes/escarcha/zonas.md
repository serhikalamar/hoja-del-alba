# Escarcha · zonas (niveles 40-50)

Responsable: `continent-lead` de `escarcha`. Estado: **borrador 2** (2026-10-08), **fase futura**. Plantilla de
`progresion.md` §3. Formato de datos: el de Valdemar (`../valdemar/contrato.md`: `AreaMap`, `AreaExit`,
`DungeonEntrance`, `Zone`, `StoryDungeon`, `Quest`). Borradores de mapas en `mapas/`. Historia en `historia.md`.

## 1. Resumen

| # | Área | Id | `kind` | Niveles | `Biome` (nuevo) | Qué hay | Jefe |
|---|---|---|---|---|---|---|---|
| Capital | **Hielomar** | `escarcha.hielomar` | `.town` | — (segura) | `escarchaPort` | Gran Salón (Jarla Sigrun, Aurora), forja de Ragna (tier 5; tier 6 tras el final), Taberna del Arpón (posada), Templo de las Luces (Hálvar), cabaña de Ingrid, muelle (Ulf, maestro de viajes), puesto de Zigo, pista del dirigible | — |
| 1 | **Costa de los Balleneros** | `escarcha.balleneros` | `.field` | 40-42 | `escarchaSnow` | Playa de huesos de ballena, pecios atrapados en el hielo, acantilados, cráter pequeño con la primera esquirla | — |
| 2 | **Tundra Aullante** | `escarcha.tundra` | `.field` | 42-44 | `escarchaSnow` | Llanura con ventisca, campamento de tramperos, Paso de los Mamuts, **cueva del Abuelo Ventisca** (interior) | **Abuelo Ventisca** (`yetiPatriarch`, 43) |
| 3 | **Cráter de la Esquirla** | `escarcha.crater` | `.field` | 44-46 | `escarchaShard` | Anillo de hielo vitrificado, campamento del Eclipse, 3 tótems de la aurora, lago helado con la **Sima** (`e`) | — (escena: Corvino y la Hermana Brasa) |
| Mazmorra | **Sima del Glaciar** | `StoryDungeon` `escarcha.sima` (piso `glacier`) | — | 45-47 (nivel fijo 46) | — | 4 oleadas + jefe; botín raro | **Engendro de la Esquirla** (`shardHorror`, 46) |
| 4 | **Trono de los Gigantes** | `escarcha.gigantes` | `.field` | 46-48 | `escarchaSnow` | Tres terrazas con escalinatas gigantes, menhires rúnicos, campamento de Hrimgar, **salón del trono** (interior) | **Jarl Hrimgar** (`giantJarl`, 48) |
| 5 | **Murallas de la Luna Rota** | `escarcha.murallas` | `.field` | 48-49 | `escarchaSilver` | Foso helado, adarve, estatuas de caballeros, **Puerta de Plata** (`e` → Ciudadela) | **Comendador Eirik** (`wallCommander`, 49) |
| Final | **Ciudadela de la Luna Rota** | `StoryDungeon` `escarcha.ciudadela` (piso `citadel`) | — | 49-50 (nivel fijo 50) | — | Banda corta: 5 oleadas + jefa | **Reina Astrid** (`brokenQueen`, 50) |

**Biomas** (environment-artist):
- `escarchaPort` (Hielomar): `.` nieve pisada · `#` tierra con nieve sucia · `=` tablones y losas heladas · `~` agua
  negra del fiordo con témpanos · `T` pino nevado · `w` empalizada de troncos · `x` brasero grande · `+` tótem tallado.
- `escarchaSnow` (Costa, Tundra, Gigantes): `.` nieve · `,` hielo / nieve pisada · `~` agua helada (costa) o grieta
  (tundra) · `T` pino nevado · `%` matorral helado · `R` bloque de hielo, roca o pecio · `^` pared de glaciar ·
  `+` costillar de ballena, menhir rúnico, colmillo de mamut · `n` tienda de pieles · `x` hoguera.
- `escarchaShard` (Cráter): `.` nieve · `,` **hielo vitrificado** (brillo cian tenue) · `~` lago helado (no se pisa)
  · `R` bloque de hielo · `+` **esquirla de luna** (brilla, ilumina) · `n` tienda negra del Eclipse.
- `escarchaSilver` (Murallas): `.` nieve sobre losas de plata · `,` losas rotas · `~` foso helado · `w` muralla de
  plata y hielo · `r` camino ceremonial · `+` estatua de caballero · `T` pino muerto blanco.

**Edificios nuevos** (`BuildingStyle`, con `placeholder` mientras no tengan arte, como en Valdemar):
`longhouse` (casa larga nórdica → `house`; Gran Salón, casas de balleneros), `iceCave` (boca de cueva de hielo →
`house`; cueva del Abuelo Ventisca), `giantHall` (salón de piedra gigante → `castle`; trono de Hrimgar).

**Interiores** (`kind: .interior`, con `interior(...)`):

| Id | Nombre | Nivel | Qué hay |
|---|---|---|---|
| `escarcha.hielomar.salon` | Gran Salón de la Jarla | — | `jarlaSigrun`, `princess` (tras `escarcha.llegada`); mapa del continente |
| `escarcha.hielomar.forja` | Forja de Hielomar | — | `ragnaHerrera`: tienda y ritual (tier del continente); `brokk` tras `escarcha.reina` |
| `escarcha.hielomar.templo` | Templo de las Luces | — | `halvar` (herido en una cama hasta `escarcha.sima`) |
| `escarcha.hielomar.taberna` | Taberna del Arpón | — | `solveigTabernera` (posada) |
| `escarcha.hielomar.vidente` | Cabaña de Ingrid | — | `ingridVidente` |
| `escarcha.tundra.cueva` | Cueva del Abuelo Ventisca | 43 | `yeti` ×4 + **`yetiPatriarch`** |
| `escarcha.gigantes.trono` | Salón del Trono de Hrimgar | 48 | `frostGiant` ×2 + **`giantJarl`** |

Primera versión: si cuesta, `templo`, `taberna` y `vidente` pueden ser edificios sin interior con `lockedMessage` y
el NPC en la puerta; `salon`, `forja`, `cueva` y `trono` sí hacen falta.

## 2. Mapa de conexiones

```
                                        ▣ escarcha.ciudadela (piso citadel, 50)
                                        ^ e (Puerta de Plata · tras escarcha.murallas)
                               [ MURALLAS 48-49 ]
                                        ^ gigantes.norte / murallas.suroeste + murallas.sureste
                               [ GIGANTES 46-48 ] · trono (interior)
                    tundra.norte ^          ^ gigantes.oeste / crater.norte
   [ TUNDRA 42-44 ] ─────────────┘          │
     · cueva (interior)  ──tundra.este / crater.oeste──> [ CRÁTER 44-46 ] ──e──> ▣ escarcha.sima (piso glacier, 46)
          ^ balleneros.norte / tundra.sur
   [ COSTA 40-42 ] ──balleneros.este / hielomar.oeste──> [ HIELOMAR ] (capital) <── barco (Marga, 1.ª vez; luego Ulf)
                                                         · pista del dirigible ──> Umbral (tras escarcha.quinta_luz)
```

## 3. Salidas (`AreaExit`) y bajadas (`DungeonEntrance`)

Coordenadas reales: Hielomar es 1:1 (`mapas/hielomar.md`); el resto, las de los bocetos ×2 (el `map-designer` las
ajusta al pasarlos a tamaño real; `WorldTests` comprueba que cada `>` pertenece a una salida y que las llegadas son
pisables). Los avisos (`lockedMessage`) son borradores para el story-writer.

| Id | Área | Casillas `>` | Hacia | Llegada | `lock` / aviso |
|---|---|---|---|---|---|
| `hielomar.oeste` | `escarcha.hielomar` | (0, 14-16) | `escarcha.balleneros` | (53, 21) | — |
| `balleneros.este` | `escarcha.balleneros` | (55, 20-23) | `escarcha.hielomar` | (2, 15) | — |
| `balleneros.norte` | `escarcha.balleneros` | (24-31, 0) | `escarcha.tundra` | (37, 37) | `.questDone("escarcha.balleneros_helada")` — "Ulf: «Con la costa llena de lobos, nadie sube a la tundra.»" |
| `tundra.sur` | `escarcha.tundra` | (34-41, 39) | `escarcha.balleneros` | (27, 2) | — |
| `tundra.este` | `escarcha.tundra` | (63, 18-23) | `escarcha.crater` | (2, 16) | `.questDone("escarcha.abuelo_ventisca")` — "La ventisca no deja ver el camino al este. Torvald sabrá cruzarla." |
| `tundra.norte` | `escarcha.tundra` | (28-35, 0) | `escarcha.gigantes` | (29, 37) | `.questDone("escarcha.juramento")` — "Un gigante duerme atravesado en el paso. Mejor no despertarlo sin un plan." |
| `crater.oeste` | `escarcha.crater` | (0, 14-19) | `escarcha.tundra` | (61, 20) | — |
| `crater.norte` | `escarcha.crater` | (38-45, 0) | `escarcha.gigantes` | (2, 31) | `.questDone("escarcha.juramento")` — mismo aviso |
| `gigantes.sur` | `escarcha.gigantes` | (26-33, 39) | `escarcha.tundra` | (31, 2) | — |
| `gigantes.oeste` | `escarcha.gigantes` | (0, 30-33) | `escarcha.crater` | (41, 2) | — |
| `gigantes.norte` | `escarcha.gigantes` | (26-33, 0) | `escarcha.murallas` | (22, 33) | `.questDone("escarcha.trono_gigantes")` — "Los gigantes de Hrimgar cierran la subida a las murallas." |
| `murallas.suroeste` | `escarcha.murallas` | (20-25, 35) | `escarcha.gigantes` | (29, 2) | — |
| `murallas.sureste` | `escarcha.murallas` | (34-39, 35) | `escarcha.gigantes` | (31, 2) | — |

**Llegada por mar** (maestro de viajes, mecánica de Frida/Marga): el primer viaje (tras `cenizas.cuarta_brasa`) lo
hace **Marga** en *La Gaviota Tuerta* y deja en el **muelle de Hielomar** (23, 27). Desde entonces el maestro de
viajes de Escarcha es **Ulf Tresdedos** (`ulfTresdedos`, junto al barco), que lleva a las capitales visitadas.
**Salida final**: el dirigible *Testaruda* (piloto **Borin Nubehierro**, enano de Hondoyunque que ya había volado a Umbral) atraca en la pista tras
`escarcha.reina`; tras `escarcha.quinta_luz`, Ulf (y Borin) añaden **Bastión del Alba**. Hasta que Umbral exista:
`.comingSoon("umbral")` — "El dirigible aún no está listo para subir al cielo."

| Mazmorra | Área | Casillas `e` | `lock` / aviso |
|---|---|---|---|
| `escarcha.sima` | `escarcha.crater` | (24, 18), (25, 18) | `.questDone("escarcha.crater")` — "El hielo cruje bajo tus pies. Ingrid sabrá qué hay ahí abajo." |
| `escarcha.ciudadela` | `escarcha.murallas` | (27, 3), (28, 3) | `.questDone("escarcha.murallas")` — "La Puerta de Plata no se abre mientras su guardián siga en pie." |

**Puertas de edificio** (como los `doorLocks` de Valdemar): `cueva` en la Tundra (puerta en (56, 6), estilo
`iceCave`), abierta con `escarcha.ventisca` ("Algo enorme ronca dentro. Torvald quiere que vayas preparado.");
`trono` en los Gigantes (puerta en (42, 6), estilo `giantHall`), abierto con `escarcha.juramento`; `pista` del
dirigible en Hielomar (valla o guardia en (37, 10)), abierta con `escarcha.reina`.

**Puntos seguros** (`safePoint`): Hielomar (33, 23) delante de la taberna · Costa (21, 23) hoguera de los balleneros
· Tundra (5, 15) hoguera de los tramperos · Cráter (9, 33) hoguera fuera del anillo · Gigantes (17, 13) hoguera azul
de la terraza media · Murallas (43, 29) campamento de Hálvar.

## 4. Zonas de nivel (`Zone`) y monstruos de campo

Los monstruos de campo **reaparecen**; los de interiores y los jefes, no. Spawns `escarcha.<área>.<n>`.

| Área | Zona (id) | Nombre | Nivel | Monstruos de campo |
|---|---|---|---|---|
| costa | `escarcha.balleneros.playa` | Playa de los Huesos | 40 | `frostWolf` ×5, `drownedWhaler` ×3 |
| costa | `escarcha.balleneros.pecios` | Pecios Helados | 41 | `drownedWhaler` ×3, `iceBear` ×2, `frostWolf` ×1 |
| costa | `escarcha.balleneros.acantilados` | Acantilados del Arpón | 42 | `iceBear` ×2, `frostWolf` ×3 (manada) |
| tundra | `escarcha.tundra.llanura` | Llanura Aullante | 42 | `yeti` ×4, `frostWolf` ×3 |
| tundra | `escarcha.tundra.campamento` | Campamento de Tramperos | 43 | `wendigo` ×4, `yeti` ×2 |
| tundra | `escarcha.tundra.paso` | Paso de los Mamuts | 44 | `mammoth` ×3, `yeti` ×2, `wendigo` ×2 |
| tundra.cueva | (interior, `level` 43) | Cueva del Abuelo Ventisca | 43 | `yeti` ×4 · **jefe `yetiPatriarch`** |
| crater | `escarcha.crater.borde` | Borde del Cráter | 44 | `iceElemental` ×3, `shardLunatic` ×3 |
| crater | `escarcha.crater.campo` | Campo de Esquirlas | 45 | `shardLunatic` ×3, `rimeCultist` ×3, `iceElemental` ×2 |
| crater | `escarcha.crater.corazon` | Corazón del Cráter | 46 | `rimeCultist` ×2, `iceElemental` ×2 |
| gigantes | `escarcha.gigantes.escalones` | Escalones de los Gigantes | 46 | `frostGiant` ×2, `yeti` ×2, `frostWolf` ×2 |
| gigantes | `escarcha.gigantes.campamento` | Campamento de Hrimgar | 47 | `frostGiant` ×2, `runeGiant` ×3 |
| gigantes | `escarcha.gigantes.puerta` | Puerta del Trono | 48 | `runeGiant` ×2, `frostGiant` ×1, `mammoth` ×2 |
| gigantes.trono | (interior, `level` 48) | Salón del Trono | 48 | `frostGiant` ×2 · **jefe `giantJarl`** |
| murallas | `escarcha.murallas.foso` | Foso Helado | 48 | `frozenDead` ×4, `frostWraith` ×2 |
| murallas | `escarcha.murallas.adarve` | Adarve | 49 | `brokenKnight` ×3, `moonPriestess` ×2, `frostWraith` ×2 |
| murallas | `escarcha.murallas.puerta` | Puerta de Plata | 49 | `brokenKnight` ×2, `moonPriestess` ×2 · **jefe `wallCommander`** |

Totales de campo: costa 19, tundra 20, cráter 18, gigantes 16 (élites grandes), murallas 17 (+jefe) (objetivo 12-20).
`wallCommander` es spawn permanente de su zona, como los jefes de zona de Valdemar.

**NPC de pista** (`.clue`, se leen al acercarse): `esquirlaCaida` (cráter pequeño de la Costa, (50, 6)),
`diarioTrampero` (campamento de la Tundra, (8, 16)), `cartaBrasa` (tienda negra del Campo de Esquirlas, (24, 10)),
`totemAurora1`/`2`/`3` (Cráter: (14, 8), (38, 12), (38, 24)).

## 5. Mazmorras de historia (`StoryDungeon`)

| Id | Nombre | `floorID` | `level` | `waves` | `bossID` / `bossEscort` | `entranceAreaID` | `reward` (orientativa) |
|---|---|---|---|---|---|---|---|
| `escarcha.sima` | Sima del Glaciar | `glacier` (nuevo) | 46 | 1: `iceElemental` 6 · 2: `shardLunatic` 5, `frostWolf` 3 · 3: `rimeCultist` 4, `iceElemental` 4, `frozenDead` 2 · 4: `mammoth` 2, `shardLunatic` 5 | `shardHorror` / `iceElemental` 2 | `escarcha.crater` | 500 oro, `moonshard: 1` (+30 % `sapphire: 1`, balance) |
| `escarcha.ciudadela` | Ciudadela de la Luna Rota | `citadel` (nuevo) | 50 | 1: `brokenKnight` 6 · 2: `moonPriestess` 4, `frostWraith` 4 · 3: `brokenKnight` 4, `moonPriestess` 3, `frozenDead` 3 · 4: `frostGiant` 2, `frostWraith` 4, `rimeCultist` 2 · 5: `brokenKnight` 6, `moonPriestess` 4 | `brokenQueen` / `brokenKnight` 2 | `escarcha.murallas` | 800 oro, `moonshard: 2`, `sapphire: 1`; adelanto: `starmetal: 2`, `adamantite: 1` (Umbral) |

Ambas `repeatable: true` (la primera vez cuentan para la misión). Textos (story-writer): `bossIntro` del Engendro (sin
voz: un crujido y la esquirla que late) y de la Reina ("Has llegado tarde, sureño. El cielo ya está abierto."),
`bossIntroRepeat`, y en el `bossDefeat` de la Ciudadela la escena final: la Reina recupera la razón, **Corvino** entra
en la Escala de Esquirlas con el **Ascua de Escarcha** y el **Molde del Ocaso** y sube al cielo; la Reina da la
**Corona de Esquirlas** y se queda de hielo (`historia.md` §6). Corvino no pelea: NPC de escena, como la Hermana Brasa.

## 6. Misiones (`EscarchaQuests.all`, 21: 12 de historia + 9 secundarias)

Formato `Quest` de `ValdemarQuests.swift`. XP como fracción de `xpToNext(nivel)` (`progresion.md` §2: a nivel 40 un
25 % son ~4 600 XP, a 45 ~5 500, a 49 ~6 300). Oro y minerales orientativos (balance-designer).
`requires` abreviado (`costa_helada` = `.questDone("escarcha.balleneros_helada")`).

| Id | Tipo | Nv. | `giverID` | `requires` | `objectives` | `reward` (orientativa) |
|---|---|---|---|---|---|---|
| `escarcha.llegada` | Historia, `autoAccept`, `completesOnLastObjective` | 40 | `princess` | `.questDone("cenizas.cuarta_brasa")` | `reach("escarcha.hielomar.salon")`, `talk("jarlaSigrun")` | 10 % XP, 150 oro |
| `escarcha.balleneros_helada` | Historia | 40 | `jarlaSigrun` | `llegada` | `kill(["frostWolf"], 10, "escarcha.balleneros")`, `kill(["drownedWhaler"], 6, "escarcha.balleneros")` | 25 % XP, 200 oro, `quartz: 2`; abre `balleneros.norte` |
| `escarcha.pieles` | Secundaria | 41 | `solveigTabernera` | `llegada` | `kill(["iceBear"], 8, "escarcha.balleneros")` | 25 % XP, 200 oro, `gearID: chest.escarcha` |
| `escarcha.arpones` | Secundaria | 41 | `ragnaHerrera` | `llegada` | `kill(["drownedWhaler"], 8, nil)` | 25 % XP, 220 oro, `rimeiron: 2` |
| `escarcha.esquirla_perdida` | Historia | 41 | `ulfTresdedos` | `costa_helada` | `read("esquirlaCaida")`, `talk("ingridVidente")` | 25 % XP, 200 oro, `moonshard: 1` |
| `escarcha.ventisca` | Historia | 42 | `torvaldTrampero` | `esquirla_perdida` | `kill(["yeti"], 10, "escarcha.tundra")` | 25 % XP, 250 oro, `aquamarine: 1`; abre la cueva |
| `escarcha.caravana` | Secundaria | 43 | `solveigTabernera` | `ventisca` | `read("diarioTrampero")`, `kill(["wendigo"], 8, "escarcha.tundra")` | 25 % XP, 250 oro, `quartz: 2` |
| `escarcha.mamuts` | Secundaria | 43 | `torvaldTrampero` | `ventisca` | `kill(["mammoth"], 4, nil)` | 25 % XP, 300 oro, `gearID: boots.escarcha` |
| `escarcha.abuelo_ventisca` | Historia | 43 | `torvaldTrampero` | `ventisca` | `defeat("yetiPatriarch")` | 50 % XP, 400 oro, `aquamarine: 1`; abre `tundra.este` |
| `escarcha.crater` | Historia | 44 | `ingridVidente` | `abuelo_ventisca` | `reach("escarcha.crater")`, `kill(["shardLunatic", "rimeCultist"], 10, "escarcha.crater")`, `read("cartaBrasa")` | 50 % XP, 400 oro, `moonshard: 1`; abre `escarcha.sima` |
| `escarcha.tres_auroras` | Secundaria | 45 | `ingridVidente` | `crater` | `read("totemAurora1")`, `read("totemAurora2")`, `read("totemAurora3")` | 25 % XP, 300 oro, `aquamarine: 2` |
| `escarcha.nucleos` | Secundaria | 45 | `zigoMercader` | `crater` | `kill(["iceElemental"], 10, nil)` | 25 % XP, 450 oro |
| `escarcha.sima` | Historia | 46 | `ingridVidente` | `crater` | `dungeon("escarcha.sima")` | 75 % XP, 500 oro |
| `escarcha.juramento` | Historia | 46 | `halvar` | `sima` | `talk("jarlaSigrun")` | 10 % XP, 200 oro; abre `tundra.norte`, `crater.norte`, el trono |
| `escarcha.runas` | Secundaria | 47 | `halvar` | `juramento` | `kill(["runeGiant"], 6, "escarcha.gigantes")` | 25 % XP, 350 oro, `rimeiron: 2` |
| `escarcha.huesos_de_gigante` | Secundaria | 47 | `ragnaHerrera` | `juramento` | `kill(["frostGiant"], 5, nil)` | 25 % XP, 350 oro, `gearID: helm.escarcha` |
| `escarcha.trono_gigantes` | Historia | 48 | `jarlaSigrun` | `juramento` | `defeat("giantJarl")` | 50 % XP, 600 oro, `sapphire: 1`; abre `gigantes.norte` |
| `escarcha.caidos` | Secundaria | 48 | `halvar` | `trono_gigantes` | `kill(["frozenDead", "frostWraith"], 12, "escarcha.murallas")` | 25 % XP, 400 oro, `gearID: gloves.escarcha` |
| `escarcha.murallas` | Historia | 49 | `halvar` | `trono_gigantes` | `defeat("wallCommander")` | 50 % XP, 600 oro, `moonshard: 1`; abre `escarcha.ciudadela` |
| `escarcha.reina` | Historia, `completesOnLastObjective` | 50 | `princess` | `murallas` | `dungeon("escarcha.ciudadela")` | 100 % XP, 1 000 oro; abre la pista del dirigible |
| `escarcha.quinta_luz` | Historia, `completesOnLastObjective` | 50 | `brokk` | `reina` | `talk("brokk")`, `talk("princess")` | 25 % XP; **Hoja del Alba (V)** (despertar con la Corona de Esquirlas); viaje a Umbral |

Las piezas `boss.*` las sueltan los jefes al caer (no van en `reward`). El conjunto `*.escarcha` sale de misiones
secundarias (y se vende en la forja). Los `gearID` exactos (material del conjunto) los decide el balance-designer.

## 7. Ruta prevista (orientativa)

Hielomar → Costa (40-42: `costa_helada`, `pieles`, `arpones`, `esquirla_perdida`) → Tundra (42-44: `ventisca`,
`caravana`, `mamuts`, cueva) → Cráter (44-46: `crater`, `tres_auroras`, `nucleos`) → Sima (46) → Hielomar
(`juramento`) → Gigantes por la Tundra o por el Cráter (46-48: `runas`, `huesos_de_gigante`, trono) → Murallas
(48-49: `caidos`, Eirik) → Ciudadela (50) → Hielomar (`quinta_luz`) → dirigible a Umbral.

**Presupuesto de XP**: `progresion.md` pide 217 677 XP de 40 a 50 (~525 monstruos + 16 misiones). Con 90 monstruos de
campo que reaparecen, 21 misiones (9 secundarias al 25 %, 12 de historia al 10-100 %), 5 jefes y 2 mazmorras
repetibles, cuadra con ~3,5-4 h. Lo mide el `balance-designer` con la simulación del modo historia.
