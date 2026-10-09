# Cenizas · zonas (niveles 30-40)

Plantilla de `progresion.md` §3 (B = 30). Formato de datos: el de Valdemar (`../valdemar/contrato.md`, `Valdemar.swift`,
`ValdemarQuests.swift`). Ids: áreas `cenizas.<área>`, interiores `cenizas.<área>.<sitio>`, zonas
`cenizas.<área>.<zona>`, spawns `cenizas.<área>.<n>`, salidas `<área corta>.<punto cardinal>`, misiones
`cenizas.<nombre>`, mazmorras de historia `cenizas.tumba` (piso `tomb`) y `cenizas.caldera` (piso `caldera`).
Mapas en `mapas/`: la capital detallada y comprobada (filas iguales, borde cerrado salvo `>`, suelo conectado); el
resto, bocetos a escala 1:2.

## 1. Resumen

| # | Área | Id | `kind` | Niveles | `Biome` (nuevo) | Qué hay | Jefe |
|---|---|---|---|---|---|---|---|
| Capital | **Fortín del Oasis** | `cenizas.fortin` | `.town` | — (segura) | `cenizasOasis` | Puesto de mando (Aurora), forja de Tova (tier 4; tier 5 tras el final), posada *La Cantimplora*, archivo (Thessa), barracón, mercadillo (Zigo), maestra de viajes (Marga), **la Cata** (primer mural) | — |
| 1 | **Costa de Escoria** | `cenizas.costa` | `.field` | 30-32 | `cenizasAsh` | Embarcadero (llegada en barco), barco naufragado, charcas de azufre, barco negro del Eclipse varado, **faro roto** (interior) | — |
| 2 | **Dunas Negras** | `cenizas.dunas` | `.field` | 32-34 | `cenizasAsh` | Pozos del Clan Duna (campamento seguro, jaima de Yalia), mar de dunas con costillares, **Trono de Hueso** | **Gorrak** (`ashTrollKing`, 34) |
| 3 | **Necrópolis de Solarum** | `cenizas.necropolis` | `.field` | 34-36 | `cenizasAsh` | Avenida de estatuas, campo de tumbas (primer Eclipse), Mausoleo, **Puerta del Sol** (`e` → Tumba), **Sala de los Murales** | **Aguijón Negro** (`colossalScorpion`, 36) |
| Mazmorra | **Tumba de Solarum** | `StoryDungeon` `cenizas.tumba` (piso `tomb`) | — | 35-37 (nivel fijo 36) | — | 4 oleadas + jefe; botín raro | **Gran Sacerdote Solano** (`sunHighPriest`, 37) |
| 4 | **Laderas de Brasamadre** | `cenizas.laderas` | `.field` | 36-38 | `cenizasVolcano` | Ríos de lava con puentes, **3 braseros violeta**, Boca del Cráter (`e` → Caldera). Élites | — (élites `magmaGolem`) |
| 5 | **Ciudad Sepultada** | `cenizas.sepultada` | `.field` | 38-39 | `cenizasVolcano` | Barrio de artesanos, Foro Hundido, escalinata y **palacio imperial** (interior: Ozrán) | — (élite de historia `ashHerald`) |
| Final | **Caldera de Brasamadre** | `StoryDungeon` `cenizas.caldera` (piso `caldera`) | — | 39-40 (nivel fijo 40) | — | Banda corta: 5 oleadas + jefe final | **Severián, el Emperador Ceniciento** (`ashEmperor`, 40) |

**Biomas** (cómo se dibujan las casillas, environment-artist):
- `cenizasOasis` (Fortín): `.` arena clara · `,` hierba del oasis · `~` agua humeante · `T` palmera · `%` matojo.
- `cenizasAsh` (Costa, Dunas, Necrópolis): `.` ceniza / arena negra · `,` arena amarilla de azufre · `~` agua
  oscura (mar de escoria, pozos) · `T` árbol muerto calcinado · `%` matojo seco · `R` costillar / estatua caída ·
  `+` estela o lápida de Solarum.
- `cenizasVolcano` (Laderas, Sepultada): `.` roca volcánica · `,` escoria con brasas · `~` **lava** (ilumina) ·
  `T` tocón carbonizado · `p` puente de basalto · `w` muro de bronce y adobe.

**Interiores** (`kind: .interior`, con `interior(...)`): `cenizas.fortin.mando` (Aurora, Dorna; mapa del continente),
`.forja` (Tova: tienda y ritual, tier del continente), `.posada` (Sedra), `.archivo` (Thessa), `.barracon`
(soldados, cofre de bienvenida), `.cata` (mural `muralCata`, sin enemigos); `cenizas.costa.faro` (diario
`diarioFaro`, 3 monstruos, nivel 31); `cenizas.dunas.jaima` (Yalia, segura); `cenizas.necropolis.mausoleo`
(3 momias + cofre, nivel 35); `cenizas.necropolis.murales` (4 murales `.clue` + `solanoEspiritu`, segura; cerrada
hasta `cenizas.tumba_de_solarum`); `cenizas.sepultada.palacio` (Ozrán + escolta, nivel 39).
Primera versión: si cuesta, `mando`, `posada`, `barracon` y `archivo` pueden ser edificios sin interior con
`lockedMessage` y los NPC fuera; `forja`, `cata`, `faro`, `murales` y `palacio` sí hacen falta.

## 2. Mapa de conexiones

```
   barco (Marga) ─────> [ COSTA 30-32 ] ──costa.este / fortin.oeste──> [ FORTÍN ] (capital)
   (1.ª vez: embarcadero)    · faro                                         │ fortin.sur / dunas.norte
                                                                            v
                         [ DUNAS 32-34 ] ──dunas.este / necropolis.oeste──> [ NECRÓPOLIS 34-36 ] ──e──> ▣ cenizas.tumba
                            · jaima · Trono de Hueso                           · mausoleo · murales
                                 │ dunas.sur / sepultada.norte                  │ necropolis.sur / laderas.norte
                                 │ (atajo: tras cenizas.el_heraldo)             v
                         [ SEPULTADA 38-39 ] <──laderas.oeste / sepultada.este── [ LADERAS 36-38 ] ──e──> ▣ cenizas.caldera
                            · palacio
```

## 3. Salidas (`AreaExit`) y bajadas (`DungeonEntrance`)

Coordenadas reales (las de los bocetos ×2). El `map-designer` las ajusta al pasar los bocetos a tamaño real; los
tests de `WorldTests` comprueban que cada `>` pertenece a una salida y que las llegadas son pisables.

| Id | Área | Casillas `>` | Hacia | Llegada | `lock` / aviso |
|---|---|---|---|---|---|
| `fortin.oeste` | `cenizas.fortin` | (0, 15-17) | `cenizas.costa` | (53, 13) | — |
| `fortin.sur` | `cenizas.fortin` | (22-25, 33) | `cenizas.dunas` | (27, 2) | `.questDone("cenizas.rastro_de_ozran")` — "Dorna: «Nadie sale al desierto sin saber adónde va.»" |
| `costa.este` | `cenizas.costa` | (55, 12-15) | `cenizas.fortin` | (2, 16) | — |
| `dunas.norte` | `cenizas.dunas` | (26-29, 0) | `cenizas.fortin` | (23, 31) | — |
| `dunas.este` | `cenizas.dunas` | (59, 10-13) | `cenizas.necropolis` | (2, 7) | `.questDone("cenizas.rey_de_las_dunas")` — "Las dunas se mueven. Sin la canción de Yalia te perderías." |
| `dunas.sur` | `cenizas.dunas` | (36-39, 37) | `cenizas.sepultada` | (25, 2) | `.questDone("cenizas.el_heraldo")` — "Un derrumbe de ceniza tapa la bajada." |
| `necropolis.oeste` | `cenizas.necropolis` | (0, 6-9) | `cenizas.dunas` | (57, 11) | — |
| `necropolis.sur` | `cenizas.necropolis` | (28-31, 39) | `cenizas.laderas` | (29, 2) | `.questDone("cenizas.los_murales")` — "Thessa: «Antes de subir al volcán, tenemos que leer esos muros.»" |
| `laderas.norte` | `cenizas.laderas` | (28-31, 0) | `cenizas.necropolis` | (29, 37) | — |
| `laderas.oeste` | `cenizas.laderas` | (0, 22-25) | `cenizas.sepultada` | (53, 17) | `.questDone("cenizas.braseros_violeta")` — "Un muro de fuego violeta corta el paso." |
| `sepultada.este` | `cenizas.sepultada` | (55, 16-19) | `cenizas.laderas` | (2, 23) | — |
| `sepultada.norte` | `cenizas.sepultada` | (24-27, 0) | `cenizas.dunas` | (37, 35) | `.questDone("cenizas.el_heraldo")` — mismo derrumbe |

**Llegada por mar** (maestra de viajes, ver `encargos.md` → Necesidades de motor C1.2): el primer viaje a Cenizas
(tras `lunaria.pacto_de_la_luna`) deja en el **embarcadero de la Costa** (12, 17); después, Marga lleva al Fortín
como a cualquier capital. Salida final: Marga añade **Hielomar** tras `cenizas.cuarta_brasa` (hasta que Escarcha
exista, `.comingSoon("escarcha")`).

| Mazmorra | Área | Casillas `e` | `lock` / aviso |
|---|---|---|---|
| `cenizas.tumba` | `cenizas.necropolis` | (28, 26), (29, 26) | `.questDone("cenizas.puerta_sellada")` — "La Puerta del Sol está sellada. Algo enorme se mueve delante." |
| `cenizas.caldera` | `cenizas.laderas` | (42, 32), (43, 32) | `.questDone("cenizas.el_heraldo")` — "El cráter escupe fuego. Aún no." |

**Puertas de edificio cerradas** (como `doorLocks` de Valdemar): `murales` en la Necrópolis, abierta con
`cenizas.tumba_de_solarum` ("La Sala de los Murales sigue en penumbra."); `palacio` en la Sepultada, abierto con
`cenizas.braseros_violeta`.

**Puntos seguros** (`safePoint`): Fortín (38, 10) delante de la posada · Costa (20, 18) hoguera del embarcadero ·
Dunas (8, 8) hoguera del Clan Duna · Necrópolis (6, 6) brasero de la Alianza · Laderas (30, 6) campamento junto al
puente · Sepultada (10, 16) brasero de la Alianza.

## 4. Zonas de nivel (`Zone`) y monstruos de campo

Los monstruos de campo **reaparecen**; los de interiores, jefes y élites de historia, no. Spawns
`cenizas.<área>.<n>`: el `map-designer` los coloca dentro de cada zona (2-3 por grupo `*` del boceto).

| Área | Zona (id) | Nombre | Nivel | Monstruos de campo |
|---|---|---|---|---|
| costa | `cenizas.costa.naufragio` | Playa del Naufragio | 30 | `cinderCrab` ×4, `ashScorpion` ×3 |
| costa | `cenizas.costa.azufre` | Charcas de Azufre | 31 | `salamander` ×4, `ashScorpion` ×2, `cinderCrab` ×2 |
| costa | `cenizas.costa.cabo` | Cabo del Faro | 32 | `salamander` ×2, `ashScorpion` ×2, `ashVulture` ×2 |
| costa.faro | (interior, `level` 31) | Faro roto | 31 | `salamander` ×2, `cinderCrab` ×1 |
| dunas | `cenizas.dunas.pozos` | Pozos del Clan Duna | 32 | `ashVulture` ×3, `ashScorpion` ×3 (fuera del campamento) |
| dunas | `cenizas.dunas.mar` | Mar de Dunas | 33 | `ashTroll` ×2, `trollHexer` ×3, `ashVulture` ×2 |
| dunas | `cenizas.dunas.trono` | Trono de Hueso | 34 | `ashTroll` ×2, `trollHexer` ×2 · **jefe `ashTrollKing`** |
| necropolis | `cenizas.necropolis.avenida` | Avenida de las Estatuas | 34 | `mummy` ×3, `scarabSwarm` ×3 |
| necropolis | `cenizas.necropolis.tumbas` | Campo de Tumbas | 35 | `mummy` ×3, `solarLegionary` ×3, `eclipseZealot` ×2, `ashAcolyte` ×1 |
| necropolis | `cenizas.necropolis.puerta` | Puerta del Sol | 36 | `solarLegionary` ×2, `scarabSwarm` ×2 · **jefe `colossalScorpion`** |
| necropolis.mausoleo | (interior, `level` 35) | Mausoleo de los Tribunos | 35 | `mummy` ×3 + cofre |
| laderas | `cenizas.laderas.lava` | Ríos de Lava | 36 | `fireElemental` ×3, `salamander` ×3 |
| laderas | `cenizas.laderas.campamento` | Campamento del Eclipse | 37 | `eclipseZealot` ×3, `ashAcolyte` ×3 (1+1 por brasero) |
| laderas | `cenizas.laderas.crater` | Boca del Cráter | 38 | `magmaGolem` ×2, `fireElemental` ×2 |
| sepultada | `cenizas.sepultada.artesanos` | Barrio de los Artesanos | 38 | `solarLegionary` ×3, `sunPriest` ×2, `scarabSwarm` ×2 |
| sepultada | `cenizas.sepultada.foro` | Foro Hundido | 38 | `sunPriest` ×2, `eclipseZealot` ×2, `ashAcolyte` ×2 |
| sepultada | `cenizas.sepultada.escalinata` | Escalinata del Palacio | 39 | `solarLegionary` ×2, `magmaGolem` ×1 |
| sepultada.palacio | (interior, `level` 39) | Salón del Trono Enterrado | 39 | **`ashHerald`** + `ashAcolyte` ×2 + `solarLegionary` ×2 |

Totales de campo: costa 21, dunas 17 (+jefe), necrópolis 19 (+jefe), laderas 16, sepultada 16 (objetivo 12-20).
Los jefes de zona (`ashTrollKing`, `colossalScorpion`) son spawns permanentes de su zona, como los de Valdemar.

## 5. Mazmorras de historia (`StoryDungeon`)

| Id | Nombre | `floorID` | `level` | `waves` | `bossID` / `bossEscort` | `entranceAreaID` | `reward` (orientativa) |
|---|---|---|---|---|---|---|---|
| `cenizas.tumba` | Tumba de Solarum | `tomb` (nuevo) | 36 | 1: `mummy` 4, `scarabSwarm` 3 · 2: `mummy` 3, `solarLegionary` 3 · 3: `solarLegionary` 3, `sunPriest` 2, `scarabSwarm` 3 · 4: `sunPriest` 3, `mummy` 3, `eclipseZealot` 2 | `sunHighPriest` / `sunPriest` 2 | `cenizas.necropolis` | 300 oro, `fireopal: 1` (+30 % `ruby: 1`, balance) |
| `cenizas.caldera` | Caldera de Brasamadre | `caldera` (nuevo) | 40 | 1: `fireElemental` 4, `salamander` 3 · 2: `eclipseZealot` 3, `ashAcolyte` 3 · 3: `solarLegionary` 4, `sunPriest` 2 · 4: `magmaGolem` 2, `fireElemental` 3 · 5: `magmaGolem` 2, `solarLegionary` 2, `eclipseZealot` 2, `ashAcolyte` 2 | `ashEmperor` / `solarLegionary` 2 | `cenizas.laderas` | 500 oro, `fireopal: 2`, `ruby: 1`; adelanto: `quartz: 2`, `rimeiron: 1` (Escarcha) |

Ambas `repeatable: true` (para farmear raros; la primera vez cuentan para la misión). Textos `bossIntro`,
`bossIntroRepeat`, `bossDefeat` (story-writer): Solano ("¿Otro ladrón del Sol?") y Severián; en el `bossDefeat`
de la Caldera va la escena de la Hermana Brasa recogiendo la colada en el Molde y huyendo (no pelea).

## 6. Misiones (`CenizasQuests.all`, 21: 12 de historia + 9 secundarias)

Formato `Quest` de `ValdemarQuests.swift`. XP como fracción de `xpToNext(nivel)` (`progresion.md` §2: a nivel 30 un
25 % son ~2 900 XP, a 35 ~3 700, a 39 ~4 400). Oro y minerales orientativos: los fija el balance-designer.
`requires` se escribe abreviado (`rastro_de_ozran` = `.questDone("cenizas.rastro_de_ozran")`).

| Id | Tipo | Nv. | `giverID` | `requires` | `objectives` | `reward` (orientativa) |
|---|---|---|---|---|---|---|
| `cenizas.desembarco` | Historia, `autoAccept`, `completesOnLastObjective` | 30 | `princess` | `.questDone("lunaria.pacto_de_la_luna")` | `reach("cenizas.fortin")`, `talk("dornaComandante")` | 10 % XP, 100 oro |
| `cenizas.pinzas_de_escoria` | Secundaria | 30 | `tovaHerrera` | `desembarco` | `kill(["cinderCrab"], 8, "cenizas.costa")` | 20 % XP, 120 oro, `sulfur: 2` |
| `cenizas.la_cata` | Historia | 30 | `thessa` | `desembarco` | `read("muralCata")` | 20 % XP, 120 oro, `garnet: 1` |
| `cenizas.cola_de_salamandra` | Secundaria | 31 | `zigoMercader` | `desembarco` | `kill(["salamander"], 8, nil)` | 20 % XP, 140 oro, `sunstone: 1` |
| `cenizas.rastro_de_ozran` | Historia | 31 | `dornaComandante` | `la_cata` | `reach("cenizas.costa.faro")`, `read("diarioFaro")` | 20 % XP, 150 oro, `sunstone: 1`; abre `fortin.sur` |
| `cenizas.clan_duna` | Historia | 32 | `dornaComandante` | `rastro_de_ozran` | `talk("yaliaGuia")` | 10 % XP, 120 oro |
| `cenizas.alas_negras` | Secundaria | 32 | `yaliaGuia` | `clan_duna` | `kill(["ashVulture"], 8, "cenizas.dunas")` | 20 % XP, 160 oro, `garnet: 2` |
| `cenizas.tambores_troll` | Secundaria | 33 | `yaliaGuia` | `clan_duna` | `kill(["trollHexer"], 6, nil)` | 20 % XP, 170 oro, `sunstone: 1` |
| `cenizas.rey_de_las_dunas` | Historia | 34 | `yaliaGuia` | `clan_duna` | `defeat("ashTrollKing")` | 40 % XP, 250 oro, `garnet: 2`; abre `dunas.este` |
| `cenizas.vendas_y_polvo` | Secundaria | 35 | `thessa` | `rey_de_las_dunas` | `kill(["mummy"], 10, "cenizas.necropolis")` | 20 % XP, 190 oro, `sulfur: 2`, `garnet: 1` |
| `cenizas.legion_perdida` | Secundaria | 35 | `dornaComandante` | `rey_de_las_dunas` | `kill(["solarLegionary"], 8, nil)` | 20 % XP, 200 oro, `gearID: boots.cenizas` |
| `cenizas.puerta_sellada` | Historia | 36 | `thessa` | `rey_de_las_dunas` | `defeat("colossalScorpion")` | 40 % XP, 280 oro, `sunstone: 2`; abre la Tumba |
| `cenizas.tumba_de_solarum` | Historia | 37 | `thessa` | `puerta_sellada` | `dungeon("cenizas.tumba")` | 50 % XP, 320 oro, `gearID: helm.cenizas` (`boss.sunHighPriest` lo suelta el jefe) |
| `cenizas.los_murales` | Historia | 37 | `solanoEspiritu` | `tumba_de_solarum` | `read("muralSiete")`, `read("muralOcaso")`, `read("muralSolNegro")`, `read("muralProfecia")`, `talk("thessa")` | 30 % XP, 200 oro, `ruby: 1`; abre `necropolis.sur` |
| `cenizas.corazones_de_magma` | Secundaria | 37 | `tovaHerrera` | `los_murales` | `kill(["magmaGolem"], 3, nil)` | 25 % XP, 220 oro, `fireopal: 1`, `gearID: gloves.cenizas` |
| `cenizas.braseros_violeta` | Historia | 38 | `princess` | `los_murales` | `read("braseroVioleta1")`, `read("braseroVioleta2")`, `read("braseroVioleta3")` | 40 % XP, 300 oro, `sunstone: 2`; abre `laderas.oeste` y el palacio |
| `cenizas.fanaticos` | Secundaria | 38 | `dornaComandante` | `los_murales` | `kill(["eclipseZealot"], 10, nil)` | 20 % XP, 230 oro, `sulfur: 3` |
| `cenizas.oraculos_muertos` | Secundaria | 38 | `thessa` | `braseros_violeta` | `kill(["sunPriest"], 8, "cenizas.sepultada")` | 20 % XP, 240 oro, `fireopal: 1` |
| `cenizas.el_heraldo` | Historia | 39 | `princess` | `braseros_violeta` | `defeat("ashHerald")` | 40 % XP, 350 oro, `gearID: chest.cenizas`; abre la Caldera y el atajo |
| `cenizas.emperador_ceniciento` | Historia | 40 | `princess` | `el_heraldo` | `dungeon("cenizas.caldera")` | 100 % XP, 500 oro, `ruby: 2` (`boss.ashEmperor` lo suelta el jefe) |
| `cenizas.cuarta_brasa` | Historia, final del continente, `completesOnLastObjective` | 40 | `princess` | `emperador_ceniciento` | `talk("brokk")` (en la forja del Fortín: ritual de despertar) | 20 % XP, **Hoja del Alba (IV)**; `Continent.finalQuestID` (tier 5 en la forja, Hielomar en los viajes) |

Los braseros violeta (`braseroVioleta1-3`) son NPC `.clue` en las Laderas: "se leen" (se apagan) al acercarse con
su grupo de guardia muerto, como los crisoles de Rocaforja.

**Cuentas de XP**: historia ≈ 4,2 niveles + secundarias ≈ 1,9 = ~6 niveles de "barra" en misiones. `progresion.md`
pide ~40 % de la XP del continente en misiones (~3,9 niveles a esta altura): el balance-designer recorta
porcentajes o quita secundarias (candidatas: `cola_de_salamandra`, `oraculos_muertos`).

## 7. Ruta prevista (orientativa)

30 Costa (desembarco, cata, pinzas, salamandras) → 31 faro → 32-34 Dunas (vuelve al Fortín a forjar con Tova) →
34-36 Necrópolis → 36-37 Tumba + murales → 36-38 Laderas → 38-39 Sepultada (Ozrán) → 39-40 Caldera → Fortín (Hoja IV).
Para farmear raros: repetir `cenizas.tumba` y `cenizas.caldera`.
