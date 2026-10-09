# Umbral · zonas (niveles 50-60)

Responsable: `continent-lead` de `umbral`. Estado: **borrador 2** (2026-10-08), fase futura. Plantilla de
`progresion.md` §3; datos en el formato del contrato de Valdemar (`../valdemar/contrato.md`). Mapas en `mapas/`
(todos a escala **1:1**: el Bastión detallado, el resto bocetos ligeros con coordenadas reales).

## 1. Resumen

| # | Área | Id | `kind` | Niveles | `Biome` (nuevo) | Qué hay | Jefe |
|---|---|---|---|---|---|---|---|
| Capital | **Bastión del Alba** | `umbral.bastion` | `.town` | — (segura) | `umbralBastion` | Ciudadela (Aurora), Forja del Último Yunque (Brokk, tier 6), Posada del Dirigible Varado (Nora, reaparición), Cuartel (Hálvar), Torre de los Astros (Fíbula), puesto de Zigo, Borin (maestro de viajes), Nido de Albor | — |
| 1 | **Muelles del Cielo** | `umbral.muelles` | `.field` | 50-52 | `umbralSky` | Pantalán del dirigible, almacenes celestes, faro roto | — |
| 2 | **Nidos del Vuelo del Alba** | `umbral.nidos` | `.field` | 52-54 | `umbralSky` | Laderas doradas, campo de cascarones, meseta de la Matriarca | **Nixara** (`dragonMatriarch`, 54) |
| 3 | **Islas Rotas** | `umbral.rotas` | `.field` | 54-56 | `umbralVoid` | Fragmentos de isla, puentes estrechos, Boca de la Grieta (`e`) | — (el de la mazmorra) |
| Mazmorra | **Grieta del vacío** | `StoryDungeon` `umbral.grieta` (piso `void`) | — | 55-57 (nivel fijo 57) | — | 4 oleadas + jefe | **El Guardián de la Grieta** (`voidWarden`, 57) |
| 4 | **Observatorio de los Herreros** | `umbral.observatorio` | `.field` | 56-58 | `umbralStar` | Jardines de cristal, patio de los astrolabios, **cúpula** (interior) | **Corvino** (`starHerald`, 58) |
| 5 | **Puente del Yunque** | `umbral.puente` | `.field` | 58-59 | `umbralStar` | Calzada sobre el vacío, dos bastiones, puerta del Yunque (`e`) | **Vesper** (`grandHerald`, 59) |
| Final | **Yunque del Alba** | `StoryDungeon` `umbral.yunque` (piso `skyforge`) | — | 60 | — | Banda: 4 oleadas (punto de control tras la 2.ª) + Morvath en 3 fases | **Morvath** (`morvath`, 60) |

**Biomas** (environment-artist; paleta índigo, dorado y negro del vacío):
- `umbralBastion` (Bastión): `.` piedra clara con vetas de cristal · `#` losas blancas con juntas doradas · `=` mosaico
  de la Forja (anillos dorados) · `~` **vacío** (cielo índigo con estrellas; borde de isla con raíces de piedra) ·
  `p` puente de luz dorada · `T` árbol de cristal azul · `w` muralla blanca con almenas doradas · `F` **Pozo de luz**
  (columna de luz hacia la Luna) · `l` farol estelar · `x` brasero dorado · `+` estela rúnica.
- `umbralSky` (Muelles, Nidos): `.` roca dorada y nube · `,` flores estelares · `d` sendero de piedra dorada · `~` vacío
  · `p` puente de luz · `R` peñasco dorado · `^` pináculo de roca / torre del faro · `+` **cascarón gigante** (Nidos) o
  estela · `T` árbol de cristal · `c` cajas celestes · `m` puesto · `x` nido en llamas / brasero.
- `umbralVoid` (Islas Rotas): `.` roca agrietada con vetas violetas · `d` sendero roto · `~` vacío con jirones
  violetas · `R` fragmento flotante · `^` pared de la Grieta · `T` sauce del vacío (negro, hojas violetas) · `x` brasero
  de luz (de la Alianza).
- `umbralStar` (Observatorio, Puente): `.` losas de mithril · `#` calzada dorada · `=` mosaico estelar del patio ·
  `w` muro de mithril · `R` **astrolabio** gigante · `+` estela de los Herreros · `^` pináculo · `x` brasero estelar ·
  `T` árbol de cristal.

**Edificios nuevos** (`BuildingStyle`, con `placeholder` mientras no tengan arte, como en Valdemar):
`starTower` (Torre de los Astros → `alchemist`), `skyDome` (Cúpula de la Gran Lente → `castle`). El resto del
Bastión usa estilos que ya existen (`castle`, `smithy`, `inn`, `house`).

**Interiores** (`kind: .interior`, con `interior(...)`):

| Id | Nombre | Tamaño aprox. | `level` | Quién / qué |
|---|---|---|---|---|
| `umbral.bastion.ciudadela` | Sala de mando | 18×12 | — | `princess`; mesa de mapas `t`, estandartes de las seis capitales, trono vacío `Y` |
| `umbral.bastion.forja` | Forja del Último Yunque | 14×10 | — | `brokk`; tienda tier 6, ritual, despertar (VI) |
| `umbral.bastion.posada` | Posada del Dirigible Varado | 16×10 | — | `noraPosadera`; NPC de relleno de las capitales |
| `umbral.bastion.cuartel` | Cuartel de la Alianza | 14×10 | — | `halvar` |
| `umbral.bastion.torre` | Torre de los Astros | 12×12 | — | `fibulaEngranaje` (telescopio `I`), `thessa` opcional |
| `umbral.observatorio.cupula` | Cúpula de la Gran Lente | 18×12 | 58 | 2 `eclipseProphet` + **jefe `starHerald`**; `notaVesper`; después `fibulaEngranaje` |

## 2. Mapa de conexiones

```
                                [ Yunque del Alba ] (banda umbral.yunque, piso skyforge)
                                        ^ e (puerta del Yunque; tras umbral.sexta_brasa)
  [ Observatorio 56-58 ] ---> [ Puente del Yunque 58-59 ]
          ^ (este; tras umbral.la_grieta)
  [ Islas Rotas 54-56 ] --e--> [ Grieta del vacío ] (mazmorra umbral.grieta, piso void)
     ^ (sur)        ^ (oeste: puente de luz, tras umbral.puente_de_luz)
  [ Nidos 52-54 ]   |
     ^ (oeste)      |
  [ BASTIÓN DEL ALBA ]  (oeste → Muelles · este → Nidos · norte → Islas Rotas)
     ^ (oeste)
  [ Muelles del Cielo 50-52 ] <== dirigible *Testaruda* (Borin) desde Hielomar
```

## 3. Salidas (`AreaExit`) y bajadas (`DungeonEntrance`)

Coordenadas reales (los mapas están a 1:1). Avisos (`lockedMessage`): borradores para el story-writer.

| Id | Área | Casillas `>` | Hacia | Llegada | `lock` / aviso |
|---|---|---|---|---|---|
| `bastion.oeste` | `umbral.bastion` | (0, 16-18) | `umbral.muelles` | (53, 23) | — |
| `bastion.este` | `umbral.bastion` | (51, 16-18) | `umbral.nidos` | (2, 27) | `.questDone("umbral.llegada")` — "Hálvar: «Primero preséntate a la princesa.»" |
| `bastion.norte` | `umbral.bastion` | (24-27, 0) | `umbral.rotas` | (3, 7) | `.questDone("umbral.puente_de_luz")` — "El puente de luz está apagado. Fíbula sabrá encenderlo." |
| `muelles.este` | `umbral.muelles` | (55, 22-24) | `umbral.bastion` | (2, 17) | — |
| `nidos.oeste` | `umbral.nidos` | (0, 26-28) | `umbral.bastion` | (49, 17) | — |
| `nidos.norte` | `umbral.nidos` | (26-28, 0) | `umbral.rotas` | (6, 33) | `.questDone("umbral.matriarca")` — "Los dragonantes cortan el puente. Mientras la Matriarca vuele, nadie cruza." |
| `rotas.sur` | `umbral.rotas` | (5-7, 35) | `umbral.nidos` | (27, 2) | — |
| `rotas.oeste` | `umbral.rotas` | (0, 6-8) | `umbral.bastion` | (25, 2) | `.questDone("umbral.puente_de_luz")` — mismo aviso |
| `rotas.este` | `umbral.rotas` | (59, 10-12) | `umbral.observatorio` | (2, 18) | `.questDone("umbral.la_grieta")` — "El vacío se traga el puente al Observatorio. Algo lo abre desde la Grieta." |
| `observatorio.oeste` | `umbral.observatorio` | (0, 17-19) | `umbral.rotas` | (57, 11) | — |
| `observatorio.este` | `umbral.observatorio` | (55, 28-30) | `umbral.puente` | (2, 12) | `.questDone("umbral.observatorio")` — "Un sello del Eclipse cierra el camino. Lo mantiene alguien desde la cúpula." |
| `puente.oeste` | `umbral.puente` | (0, 11-13) | `umbral.observatorio` | (53, 29) | — |

**Llegada por aire** (maestro de viajes, mecánica de Frida/Marga/Ulf): el primer viaje (tras `escarcha.quinta_luz`)
lo hace **Borin** en el *Testaruda* y deja en el **pantalán de los Muelles** (10, 14). Desde entonces Borin
(`borin`) está también en la plaza del Bastión (`appearsWhen` `.questDone("umbral.llegada")`) y lleva a las capitales
visitadas; Ulf y Marga añaden el Bastión a su ruta. Hasta que Umbral exista, Escarcha usa `.comingSoon("umbral")`.

| Mazmorra | Área | Casillas `e` | `lock` / aviso |
|---|---|---|---|
| `umbral.grieta` | `umbral.rotas` | (46, 25), (47, 25) | `.questDone("umbral.puente_de_luz")` — "La Grieta late. Fíbula quiere medirla antes de que bajes." |
| `umbral.yunque` | `umbral.puente` | (59, 11), (59, 12), (59, 13) | `.questDone("umbral.sexta_brasa")` — "La puerta del Yunque no reconoce tu Hoja. Aún le faltan brasas." |

**Puertas de edificio**: la cúpula (`skyDome`, puerta en (35, 6) del Observatorio) está abierta; el patio que lleva a
ella lo guarda el Campeón del Eclipse.

**Puntos seguros** (`safePoint`): Bastión (25, 21) plaza · Muelles (10, 14) pantalán · Nidos (3, 27) entrada oeste ·
Islas Rotas (5, 32) embarcadero · Observatorio (4, 18) rellano · Puente (3, 12) campamento de Hálvar.

**Vuelo de Albor** (opcional, M-U5 en `encargos.md`): tras `umbral.matriarca`, hablar con `albor` lleva a la
`safePoint` de cualquier área de Umbral visitada.

## 4. Zonas de nivel (`Zone`) y monstruos de campo

Los monstruos de campo **reaparecen**; los de interiores y los jefes, no. Spawns `umbral.<área>.<n>`.
Rectángulos aproximados (x, y, ancho, alto) sobre los mapas de `mapas/`.

| Área | Zona (id) | Nombre | Nivel | Rectángulo | Monstruos de campo |
|---|---|---|---|---|---|
| muelles | `umbral.muelles.amarre` | Amarre del dirigible | 50 | 0, 0, 20, 32 | `skyConstruct` ×5, `starGargoyle` ×3 |
| muelles | `umbral.muelles.almacenes` | Almacenes celestes | 51 | 20, 0, 20, 32 | `skyConstruct` ×4, `starGargoyle` ×3, `cloudRay` ×3 |
| muelles | `umbral.muelles.faro` | Faro roto y terraza | 52 | 40, 0, 16, 32 | `cloudRay` ×3, `starGargoyle` ×2, `skyConstruct` ×2 |
| nidos | `umbral.nidos.laderas` | Laderas de los nidos | 52 | 0, 0, 18, 36 | `dragonWhelp` ×5, `cloudRay` ×3 |
| nidos | `umbral.nidos.cascarones` | Campo de cascarones | 53 | 18, 10, 18, 26 | `drake` ×4, `dragonWhelp` ×4, `stormDrake` ×3 |
| nidos | `umbral.nidos.cumbre` | Cumbre de la Matriarca | 54 | 36, 0, 20, 19 | `stormDrake` ×3, `fallenDragon` ×2 · **jefe `dragonMatriarch`** (45, 6) |
| rotas | `umbral.rotas.embarcadero` | Embarcadero roto | 54 | 0, 0, 17, 36 | `voidWalker` ×5, `fallenDragon` ×2 |
| rotas | `umbral.rotas.fragmentos` | Fragmentos | 55 | 17, 0, 19, 36 | `voidWalker` ×4, `voidLurker` ×4, `voidEye` ×3 |
| rotas | `umbral.rotas.boca` | Boca de la Grieta | 56 | 36, 0, 24, 36 | `voidLurker` ×4, `voidEye` ×4 |
| observatorio | `umbral.observatorio.rellano` | Rellano | 56 | 0, 10, 16, 16 | `voidZealot` ×4, `voidEye` ×2 |
| observatorio | `umbral.observatorio.jardines` | Jardines de cristal | 57 | 16, 0, 40, 36 | `voidZealot` ×4, `eclipseKnight` ×4 |
| observatorio | `umbral.observatorio.patio` | Patio de los astrolabios | 58 | 26, 6, 19, 13 | `eclipseKnight` ×3, `eclipseProphet` ×3 · Campeón del Eclipse (`eclipseKnight` permanente) (35, 13) |
| observatorio.cupula | (interior, `level` 58) | Cúpula de la Gran Lente | 58 | — | `eclipseProphet` ×2 · **jefe `starHerald`** |
| puente | `umbral.puente.cabeza` | Cabeza de puente | 58 | 0, 0, 18, 24 | `hollowSmith` ×4, `eclipseKnight` ×2 |
| puente | `umbral.puente.bastiones` | Bastiones del puente | 59 | 18, 0, 33, 24 | `hollowSmith` ×5, `eclipseProphet` ×3, `fallenDragon` ×1 |
| puente | `umbral.puente.puerta` | Puerta del Yunque | 59 | 51, 0, 13, 24 | `eclipseProphet` ×2 · **jefe `grandHerald`** (55, 12) |

Totales de campo: muelles 25, nidos 24 (+jefe), rotas 26, observatorio 24 (+campeón, +cúpula), puente 17 (+jefe;
élites y herreros huecos). Algo por encima de 12-20 en las tres primeras: son áreas grandes y de paso (balance).
Los jefes de zona son spawns permanentes de su zona, como en Valdemar.

**NPC de pista** (`.clue`): `estelaFarero` (Muelles, (49, 4)), `notaVesper` (cúpula, junto a la Lente),
`cartaBrasa2` (Puente, (38, 13), junto a la Hermana Brasa).

## 5. Mazmorras de historia (`StoryDungeon`)

| Id | Nombre | `floorID` | `level` | `waves` | `bossID` / `bossEscort` | `entranceAreaID` | `reward` (orientativa) |
|---|---|---|---|---|---|---|---|
| `umbral.grieta` | Grieta del vacío | `void` (nuevo) | 57 | 1: `voidWalker` 6 · 2: `voidLurker` 5, `voidEye` 3 · 3: `voidWalker` 4, `voidEye` 4, `voidLurker` 3 · 4: `fallenDragon` 2, `voidLurker` 4 | `voidWarden` / `voidEye` 2 | `umbral.rotas` | 700 oro, `voidstone: 2` (+20 % `dragonite: 1`, +5 % `mithril: 1`) |
| `umbral.yunque` | Yunque del Alba | `skyforge` (nuevo) | 60 | 1: `hollowSmith` 6, `eclipseKnight` 2 · 2: `eclipseKnight` 4, `eclipseProphet` 3 · *(punto de control)* · 3: `voidEye` 4, `voidLurker` 4, `hollowSmith` 3 · 4: `fallenDragon` 2, `eclipseKnight` 3, `eclipseProphet` 2 | `morvath` / `hollowSmith` 2 | `umbral.puente` | 1ª vez: 2 000 oro, `mithril: 3`, `dragonite: 2`; repetición: 800 oro, `mithril: 1` + tirada de la familia |

Las dos `repeatable: true` (la primera vez cuentan para la misión). Textos (story-writer): `bossIntro` del Guardián
(sin voz: el ojo del pecho se abre), de Morvath ("Me arrancaron el fuego del pecho y lo colgaron en el cielo. Vengo a
por él."), `bossIntroRepeat` de Morvath ("El martillo sigue sonando. ¿Lo oyes?") y el `bossDefeat` de Morvath: la
escena final (`historia.md` §7). La banda necesita **punto de control** y **fases de jefe** (`encargos.md`, M-U1/M-U2).

## 6. Misiones (`UmbralQuests.all`, 19: 10 de historia + 8 secundarias + 1 repetible)

Formato `Quest` de `ValdemarQuests.swift`. XP como fracción de `xpToNext(nivel)` (a nivel 50 un 25 % son ~6 500 XP,
a 55 ~7 600, a 59 ~8 500). Oro y minerales orientativos (balance-designer). `requires` abreviado
(`matriarca` = `.questDone("umbral.matriarca")`).

| Id | Tipo | Nv. | `giverID` | `requires` | `objectives` | `reward` (orientativa) |
|---|---|---|---|---|---|---|
| `umbral.llegada` | Historia, `autoAccept`, `completesOnLastObjective` | 50 | `borin` | `.questDone("escarcha.quinta_luz")` | `reach("umbral.bastion")`, `talk("princess")` | 10 % XP, 300 oro, `starmetal: 1` |
| `umbral.chatarra_celeste` | Secundaria | 51 | `halvar` | `llegada` | `kill(["skyConstruct"], 15, "umbral.muelles")` | 25 % XP, 350 oro, `gearID: gloves.umbral` |
| `umbral.rayas_de_zigo` | Secundaria | 51 | `zigoMercader` | `llegada` | `kill(["cloudRay"], 10, nil)` | 25 % XP, 500 oro |
| `umbral.el_viejo_albor` | Historia | 52 | `princess` | `llegada` | `talk("albor")`, `reach("umbral.nidos")` | 10 % XP, 300 oro |
| `umbral.cazadragones` | Secundaria | 53 | `halvar` | `el_viejo_albor` | `kill(["drake"], 12, "umbral.nidos")` | 25 % XP, 400 oro, `adamantite: 2` |
| `umbral.cielo_en_calma` | Secundaria | 53 | `borin` | `el_viejo_albor` | `kill(["stormDrake"], 10, nil)` | 25 % XP, 400 oro, `gearID: boots.umbral` |
| `umbral.matriarca` | Historia | 54 | `albor` | `el_viejo_albor` | `defeat("dragonMatriarch")` | 50 % XP, 700 oro, `dragonite: 2`; abre `nidos.norte` y el vuelo de Albor |
| `umbral.descanso` | Secundaria | 54 | `albor` | `matriarca` | `kill(["fallenDragon"], 3, nil)` | 25 % XP, 450 oro, `dragonite: 1` |
| `umbral.puente_de_luz` | Historia | 54 | `fibulaEngranaje` | `matriarca` | `kill(["voidEye"], 12, "umbral.rotas")`, `talk("fibulaEngranaje")` | 25 % XP, 450 oro, `voidstone: 1`; abre `bastion.norte`, `rotas.oeste` y la Grieta |
| `umbral.paso_en_vacio` | Secundaria | 55 | `princess` | `puente_de_luz` | `kill(["voidWalker", "voidLurker"], 15, "umbral.rotas")` | 25 % XP, 450 oro, `voidstone: 1` |
| `umbral.la_grieta` | Historia | 57 | `princess` | `puente_de_luz` | `dungeon("umbral.grieta")` | 50 % XP, 800 oro; abre `rotas.este` |
| `umbral.enmascarados` | Secundaria | 57 | `halvar` | `la_grieta` | `kill(["voidZealot"], 15, "umbral.observatorio")` | 25 % XP, 500 oro, `gearID: helm.umbral` |
| `umbral.observatorio` | Historia | 58 | `fibulaEngranaje` | `la_grieta` | `defeat("starHerald")`, `read("notaVesper")`, `talk("fibulaEngranaje")` | 50 % XP, 900 oro, `mithril: 1`; abre `observatorio.este` |
| `umbral.la_brasa` | Historia | 58 | `halvar` | `observatorio` | `reach("umbral.puente")`, `read("cartaBrasa2")` | 10 % XP, 400 oro |
| `umbral.herreros_huecos` | Secundaria | 58 | `brokk` | `la_brasa` | `kill(["hollowSmith"], 15, "umbral.puente")` | 25 % XP, 600 oro, `gearID: chest.umbral` |
| `umbral.gran_heraldo` | Historia | 59 | `princess` | `la_brasa` | `defeat("grandHerald")` | 50 % XP, 1 200 oro, `mithril: 1`; **Ascua de Escarcha** y **Ascua de Umbral** (objetos de historia) |
| `umbral.sexta_brasa` | Historia, `completesOnLastObjective` | 59 | `brokk` | `gran_heraldo` | `talk("brokk")`, `talk("princess")` | 25 % XP; **Hoja del Alba (VI)**; abre la puerta del Yunque |
| `umbral.herrero_hueco` | Historia, `completesOnLastObjective` | 60 | `princess` | `sexta_brasa` | `dungeon("umbral.yunque")` | (nivel máximo: sin XP) 3 000 oro, título "Portador del Alba"; epílogo y créditos |
| `umbral.eco_de_morvath` | Repetible (tras el final) | 60 | `princess` | `herrero_hueco` | `dungeon("umbral.yunque")` | 800 oro, `mithril: 1` (la mazmorra suelta lo suyo) |

Las piezas `boss.*` las sueltan los jefes al caer (no van en `reward`). El conjunto `*.umbral` sale de misiones
secundarias (y se vende en la forja). Repetible: el motor de misiones necesita "volver a ofrecer al completar"
(`encargos.md`, M-U4); si no, la repetición se hace solo entrando otra vez por la `e`.

### Presupuesto de XP (comprobación)

Umbral: 50→60 = **300 758 XP** (`progresion.md` §2).

| Fuente | XP aprox. | % |
|---|---|---|
| 9 misiones de historia con XP (la banda no da: nivel máximo) | ~90 000 | 30 % |
| 8 secundarias (25 % cada una) | ~59 000 | 20 % |
| 4 jefes antes de la banda (`(8+4n)·12`, ~2 700-2 900 cada uno) | ~11 000 | 4 % |
| Monstruos de campo y mazmorra (~620 de nivel 50-59) | ~141 000 | 46 % |

Encaja con "monstruos 50 % · misiones 40 % · jefes 10 %" (los jefes dan poca XP directa; sus misiones la compensan).
Ajuste fino: `balance-designer` con la simulación del modo historia.

## 7. Ruta prevista (orientativa)

Muelles (50-52: llegada, chatarra, rayas) → Bastión (Aurora) → Nido de Albor → Nidos (52-54: cazadragones, cielo en
calma, Nixara) → Islas Rotas (54-56: ojos del vacío, paso en vacío) → puente norte encendido (atajo al Bastión) →
Grieta del vacío (57) → Observatorio (56-58: fanáticos, Corvino) → Puente del Yunque (58-59: la Brasa, herreros
huecos, Vesper) → Bastión: Hoja del Alba (VI) → Yunque del Alba (60, banda) → epílogo → endgame (`eco_de_morvath`).
