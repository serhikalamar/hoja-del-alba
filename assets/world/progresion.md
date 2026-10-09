# Progresión 1-60

Estado: **revisión de coherencia 1** (2026-10-09). Responsable: `world-designer` (escala y reglas) con `balance-designer` (números finos, medidos con simulación).
Fuente de verdad del código: `src/GameCore/Sources/GameCore/Leveling.swift` (XP, estadísticas por nivel,
diferencia de nivel), `Enemy.swift` (escalado de monstruos), `Mineral.swift`, `Parts.swift`, `Armor.swift`.

## 1. Reglas de la escala

1. **La escala del juego es el nivel del personaje (1-60).** Cada continente cubre 10 niveles: 1-10, 10-20, 20-30,
   30-40, 40-50, 50-60. Los rangos se tocan en el borde (se llega a un continente con el nivel con que se acaba el anterior).
2. **El nivel de una zona es el nivel de sus monstruos.** En el código, `Zone.level` (o `AreaMap.level` en un interior)
   decide sus estadísticas (`EnemyDefinition.stats(level:)`), la XP (`Leveling.xpForKill`) y el oro. Hoy está
   documentado como 1…10: pasa a ser **1…60** (los datos de Valdemar no cambian).
3. **El nivel de un enemigo** (`EnemyDefinition.level`) es el nivel en que aparece por primera vez: los de Rocaforja
   empiezan en 10-20, etc. Sus estadísticas **base** se dan comparables a las de Valdemar (un "goblin" de Rocaforja
   tiene vida base de su tamaño, no ×10): la fórmula de escalado ya multiplica por nivel.
4. **La diferencia de nivel manda** (ya está en el juego): pegar a alguien de más nivel hace ×0,4-1,5 de daño
   (±7 % por nivel). Una zona 3 niveles por encima es "muy difícil"; 5+ niveles, un muro. Es la puerta natural
   entre zonas: no hace falta bloquear caminos, basta con poner el nivel en el nombre de la zona.
5. **Un tier de material por continente** y una **familia de minerales por continente** (secciones 4 y 5).

## 2. Ritmo de subida

`Leveling.xpToNext(n) = 50·n^1,6 + 30`; matar a un monstruo de tu nivel da `8 + 4·n` (jefe de historia ×6,
`Leveling.storyBossMultiplier`; jefe de la arena ×12).

| Nivel | XP para subir | XP por monstruo de tu nivel | Monstruos (si solo matas) | XP acumulada al llegar |
|---|---|---|---|---|
| 1 | 80 | 12 | 7 | 0 |
| 2 | 182 | 16 | 11 | 80 |
| 3 | 320 | 20 | 16 | 262 |
| 4 | 489 | 24 | 20 | 582 |
| 5 | 687 | 28 | 25 | 1 071 |
| 6 | 909 | 32 | 28 | 1 758 |
| 7 | 1 155 | 36 | 32 | 2 667 |
| 8 | 1 423 | 40 | 36 | 3 822 |
| 9 | 1 712 | 44 | 39 | 5 245 |
| 10 | 2 021 | 48 | 42 | 6 957 |
| 15 | 3 838 | 68 | 56 | 20 520 |
| 20 | 6 064 | 88 | 69 | 44 010 |
| 25 | 8 653 | 108 | 80 | 79 370 |
| 30 | 11 574 | 128 | 90 | 128 351 |
| 35 | 14 803 | 148 | 100 | 192 561 |
| 40 | 18 322 | 168 | 109 | 273 502 |
| 45 | 22 116 | 188 | 118 | 372 592 |
| 50 | 26 171 | 208 | 126 | 491 179 |
| 55 | 30 477 | 228 | 134 | 630 549 |
| 60 | — | 248 | — | 791 937 |

### Presupuesto de XP por continente

De dónde sale la XP (orientativo, para que cada lead sepa cuánto contenido poner):
**monstruos 50 % · misiones 40 % · jefes 10 %** (en Valdemar los jefes pesan más: ver su brief).

| Continente | Niveles | XP del continente | Monstruos de tu nivel si solo matas | Monstruos con misiones (50 %) | Misiones (presupuesto ≈400-450 %) | Tiempo orientativo |
|---|---|---|---|---|---|---|
| `valdemar` | 1→10 | 6 957 | 214 | ~60-100 | 10-11 (+ jefes que dan mucho) | ~1-1,5 h |
| `rocaforja` | 10→20 | 37 053 | 548 | ~250 | 18-22 | ~2 h |
| `lunaria` | 20→30 | 84 341 | 789 | ~350 | 18-23 | ~2,5-3 h |
| `cenizas` | 30→40 | 145 151 | 990 | ~450 | 18-21 | ~3-3,5 h |
| `escarcha` | 40→50 | 217 677 | 1 167 | ~525 | 18-21 | ~3,5-4 h |
| `umbral` | 50→60 | 300 758 | 1 329 | ~600 | 16-19 | ~4-4,5 h (+ banda) |

Total orientativo: **~18-20 horas** del 1 al 60, contando ~12 s por monstruo (andar + pelear). Si se queda corto, se
alarga con misiones, no con más vida de los monstruos.

**Misiones (corregido en la revisión de coherencia, 2026-10-09)**. La XP de una misión se da como % de
`xpToNext(nivel de la misión)`. Un continente tiene 10 niveles, o sea ~1 000 % en total; el 40 % de misiones es un
**presupuesto de ≈400-450 %** (suma de los % de todas las misiones del continente). La versión anterior de esta tabla
("14-16 misiones a ~25 %" más las de historia a 50-100 %) invitaba a pasarse del doble: es la causa del exceso que
avisó Cenizas. Reparto orientativo:

| Tipo de misión | % de `xpToNext` |
|---|---|
| Llegada, hablar con alguien, escena | 5-10 % |
| Secundaria de matar / recoger | 10-15 % |
| Secundaria que da pieza de armadura | 15-20 % |
| Historia normal | 15-20 % |
| Historia con jefe de zona | 25-30 % |
| Mazmorra de historia | 30-40 % |
| Jefe final del continente (banda) | 50-60 % |
| Despertar de la Hoja (cierre) | 10 % |

Cuentas actuales de los diseños (las corrige el `balance-designer`, ver su encargo en cada `encargos.md`):
Rocaforja ~925 % · Lunaria ~625 % · Cenizas ~610 % · Escarcha ~720 % · Umbral ~480 %. Ninguna misión se quita por
esto: se bajan los porcentajes. Además dan oro y, a veces, minerales o una pieza.

**Monstruos que reaparecen**: para que salgan esas cuentas, los monstruos de campo **reaparecen** (al volver al área
o ~90 s después, fuera de la vista). Los de la historia (casas con aldeanos, jefes) no.
Cada área exterior necesita ~12-20 monstruos de campo para no hacerse pesada.

## 3. Zonas por nivel (plantilla de cada continente)

`B` = primer nivel del continente (1, 10, 20, 30, 40, 50). Cada continente tiene **5-8 zonas**; esta es la plantilla
que siguen los leads (pueden mover un nivel arriba o abajo, nunca salirse del rango):

| Hueco | Niveles | Qué es |
|---|---|---|
| Capital | — (segura) | Forja, posada (reaparición), maestro de viajes, misiones. Llega aquí desde el continente anterior. |
| Zona 1 | B … B+2 | Bienvenida: monstruos sencillos de la familia más típica del continente. |
| Zona 2 | B+2 … B+4 | Primera trama local; un jefe de zona. |
| Zona 3 | B+4 … B+6 | Aparece el Eclipse; segundo jefe. |
| **Mazmorra** | B+5 … B+7 | Partida de supervivencia en un piso de mazmorra (3-4 oleadas + jefe). Botín de minerales raros. |
| Zona 4 | B+6 … B+8 | El conflicto se vuelve abierto; élites. |
| Zona 5 | B+8 … B+9 | Fortaleza / territorio del enemigo. |
| **Banda / jefe final** | B+9 … B+10 | El jefe final del continente (a veces en su propio piso de mazmorra, más largo). Abre el viaje al siguiente continente. |

Niveles por continente con esa plantilla:

| Continente | Capital | Zona 1 | Zona 2 | Zona 3 | Mazmorra | Zona 4 | Zona 5 | Final |
|---|---|---|---|---|---|---|---|---|
| `valdemar` | Valdehierro | 1-5 (el pueblo) | 5-6 | 6-7 | 8 (cripta) | 7-8 | 8-9 | 9-10 (patio + trono) |
| `rocaforja` | Hondoyunque | 10-12 | 12-14 | 14-16 | 15-17 | 16-18 | 18-19 | 19-20 |
| `lunaria` | Velaluna / Colmillo Gris | 20-22 | 22-24 | 24-26 | 25-27 | 26-28 | 28-29 | 29-30 |
| `cenizas` | Fortín del Oasis | 30-32 | 32-34 | 34-36 | 35-37 | 36-38 | 38-39 | 39-40 |
| `escarcha` | Hielomar | 40-42 | 42-44 | 44-46 | 45-47 | 46-48 | 48-49 | 49-50 |
| `umbral` | Bastión del Alba | 50-52 | 52-54 | 54-56 | 55-57 | 56-58 | 58-59 | 60 (banda: Morvath) |

## 4. Tiers de material por rango

Los 24 materiales actuales (`PartMaterial.metals`, `woods`, `leathers`, `cloths`) tienen tiers 1-6 y
`power` = 1,0 · 1,6 · 2,4 · 3,3 · 4,4 · 5,6. Se reparten **un tier por continente**:

| Tier | Niveles | Continente | Metal (hojas, guardas, armadura) | Madera (empuñaduras) | Cuero | Tela |
|---|---|---|---|---|---|---|
| 1 | 1-10 | `valdemar` | Cobre | Roble | Piel curtida | Lino |
| 2 | 10-20 | `rocaforja` | Hierro | Cuero | Cuero de jabalí | Lana |
| 3 | 20-30 | `lunaria` | Plata | Fresno | Piel de lobo | Seda |
| 4 | 30-40 | `cenizas` | Obsidiana | Hueso | Cuero de troll | Terciopelo |
| 5 | 40-50 | `escarcha` | Glacita | Ébano | Cuero sombrío | Seda lunar |
| 6 | 50-60 | `umbral` | Mithril | Escama de dragón | Piel de dragón | Tela de estrellas |

Encajan solos: plata contra hombres lobo, obsidiana y hueso en el desierto de ceniza, glacita y seda lunar en el
norte de la luna caída, mithril y dragón en las islas del cielo.

- **La forja de cada capital vende el tier de su continente.** Al vencer al jefe final del continente, también el
  siguiente (para llegar al nuevo continente con algo de equipo).
- Dentro de un continente el poder crece por: nivel del personaje (+8,5 % de ataque por nivel), **calidad del ritual**
  (ruleta ×0,6-×2), **minerales** del continente y **piezas únicas de jefe** (las más buscadas).
- **La arena no cambia**: sigue con su propia escalera de tiers por oleada (`Arena.shopLevel`).

## 5. Minerales por rango

Familia de 5 por continente (ids en `continentes.md`). Misma forma en todas:

| Rareza | % cuando un monstruo suelta mineral | Para qué |
|---|---|---|
| Común A | 35 % | Ataque (la base de cualquier receta) |
| Común B | 27 % | Defensa o vida |
| Poco común | 20 % | Estadística secundaria temática |
| Rara | 12 % | Estadística secundaria fuerte |
| Muy rara | 6 % | La joya del continente (las 5 joyas actuales: esmeralda en Valdemar → diamante, amatista, rubí, zafiro, mithril) |

- **Escasos** (como ya decide el GDD): los monstruos sueltan con probabilidad ×0,15 (`Mineral.dropRateMultiplier`,
  valor actual del código; algunos diseños de continente cuentan con ×0,3: el `balance-designer` rehace sus cuentas de
  escasez con 0,15); los jefes siempre algo.
- **Bonificación escalada por continente**: las estadísticas planas (ATQ, DEF, VIDA, REGEN.) crecen con el continente
  (orientativo: ×1, ×1,6, ×2,4, ×3,3, ×4,4, ×5,6, como el `power` del tier); las de porcentaje (crítico, robo de vida,
  velocidad de ataque) apenas suben. Los números exactos, `balance-designer`.
  **Regla fijada en la revisión**: el factor es el del **continente de la familia del mineral** (no el del sitio donde
  se forja) y solo vale en la historia; la arena usa los valores de siempre. Así el mithril (Umbral, ×5,6) da
  VIDA ~67, ATQ ~11 y DEF ~11 por unidad y supera al metal estelar común (ATQ ~11), como debe la joya del final
  (propuesta 6 de Umbral, aceptada). Motor: `motor_comun.md` B2.
- **Sale lo del continente donde estás**: la tabla de botín depende del continente del área. Los jefes finales y las
  mazmorras sueltan además, con poca probabilidad, comunes del continente siguiente (un "adelanto").
- **La suerte del ritual** se calcula hoy con `rarityTier` (posición en la lista). Con 30 minerales debe pasar a ser
  la **rareza dentro de su familia (1-5)** más un pequeño extra por continente; si no, el mithril (tier 10) quedaría
  por debajo del cobalto (tier 12).

### Por qué se redistribuyen así los 10 minerales actuales

- **Los ids no cambian** (`copper` … `mithril`), ni su bonificación: las partidas guardadas siguen valiendo y lo
  que el jugador ya tenga se puede usar.
- Los cinco primeros (cobre, hierro, plata, oro, esmeralda) son ya una familia completa de 5 con las estadísticas
  básicas: son **Valdemar**. Para implementar el continente 1 solo hay que dejar de soltar los cinco raros allí.
- Los cinco raros (diamante, amatista, rubí, zafiro, mithril) son "joyas": cada una pasa a ser la **muy rara** del
  continente al que mejor le va (diamante de las minas enanas, amatista lunar para el robo de vida de los lobos,
  rubí del desierto de fuego, zafiro del hielo, mithril del final). Así cada continente posterior solo añade 4.
- **La arena sigue con los 10 originales** y su tabla de siempre (es un modo aparte y roguelike).
- Lo que cambia en Valdemar: la princesa ya no puede regalar mithril y diamante (hoy da 2 de cada); pasa a dar oro
  y esmeralda (y la Hoja del Alba, que es lo importante).

## 6. Piezas únicas de jefe y la Hoja del Alba

- Las 11 piezas únicas actuales son de Valdemar. Hoy tienen tier 3-6 (pensadas para un mundo de 10 niveles);
  el `balance-designer` las recalibra a la escala de Valdemar: una pieza de jefe ≈ 1,5× una pieza normal de tier 1
  del mismo hueco, más su habilidad. Las ya forjadas en partidas guardadas conservan sus números (se guardan en el
  objeto), así que no se rompe nada.
- Cada continente: **2-5** jefes con pieza única (`boss.<idDelJefe>`) a ≈1,5× su tier (Escarcha y Umbral tienen 5:
  propuesta aceptada en la revisión; Cenizas tiene además una élite de historia sin pieza, Ozrán).
- **Hoja del Alba (I-VI)**: llega en el capítulo 1 a la altura del tier 2 y se **despierta** en la forja (con Brokk) al
  final de cada continente, con la **brasa** de su Ascua (`mundo.md` §3: el Ascua se queda en su tierra). Es un
  objetivo para todo el juego. El despertar se implementa con el continente 2 (`motor_comun.md` B6).
  **Regla única** (antes cada lead usaba una distinta): el despertar N, al final del continente N, pone la Hoja a la
  altura de una **pieza de jefe del tier del continente siguiente** (para llegar a él con ella); la VI, a la de una
  pieza de jefe de tier 6 ×1,1 (la mejor arma del juego por ritmo; el Martillo de Morvath la supera en golpe).
  **Los elementos no cambian** (Sagrado, Tormenta, Fuego): cada despertar añade un matiz a la habilidad `dawn`
  (se rechaza que la (V) gane el elemento Hielo, que cambiaría sus combos).

| Hoja | Se despierta en | Con | A la altura de | Matiz de `dawn` (propuesta de cada lead) |
|---|---|---|---|---|
| I | `valdemar.rey_goblin` (Aurora la entrega) | la brasa de Valdemar, que su linaje mantuvo viva | jefe tier 2 | — (la de hoy) |
| II | `rocaforja.despertar` (Hondoyunque) | brasa del Ascua de Rocaforja | jefe tier 3 | las ondas sagradas hacen temblar (Tierra) cada 6 ataques |
| III | `lunaria.pacto_de_la_luna` (Velaluna) | brasa del Ascua de Lunaria | jefe tier 4 | filo de luz lunar: +regeneración |
| IV | `cenizas.cuarta_brasa` (Fortín) | brasa del Ascua de Cenizas | jefe tier 5 | los rayos de luz queman (0,3) |
| V | `escarcha.quinta_luz` (Hielomar) | la **Corona de Esquirlas** (el Ascua de Escarcha la robó Corvino) | jefe tier 6 | luz fría: los rayos ralentizan |
| VI | `umbral.sexta_brasa` (Bastión) | brasas del Ascua de Escarcha y del Ascua de Umbral (recuperadas de Vesper) | jefe tier 6 ×1,1 | "Alba plena": seis rayos cada 6 ataques |

## 7. Objetivos de combate (para el balance-designer)

Con el equipo del continente (tier + calidad media, sin minerales) y a igual nivel:

| Enemigo | Golpes para matarlo | Daño que hace por golpe | Tiempo |
|---|---|---|---|
| Monstruo normal | 3-5 | 8-12 % de tu vida | — |
| Élite (grande, `scale` ≥1,3) | 10-15 | 15-20 % | — |
| Jefe de zona | — | 20-25 %, con aviso | 40-60 s |
| Jefe final de continente | — | 25-30 %, con aviso | 60-120 s |
| Banda final (Morvath) | — | — | 3-4 min |

La fórmula actual de `EnemyDefinition.stats(level:)` (+11 % por nivel de dificultad global) se hizo para 10 niveles:
hay que **medirla de 1 a 60** (héroe bot con equipo del tier del continente y nivel = zona) y ajustarla para que estas
cifras se cumplan en los 6 continentes. Tarea del `balance-designer` (ver el brief de Valdemar).

## 8. Notas para el game-programmer (cuando llegue cada continente)

- `Zone.level`, `AreaMap.level`, `EnemyDefinition.level`: documentar 1…60 (hoy dicen 1…10).
- `Mineral.roll` usa `allCases`: al añadir minerales nuevos, la arena debe seguir con los 10 originales y la historia
  con la familia del continente.
- `Mineral.rarityTier` y `value` se calculan por posición en la lista: pasar a datos explícitos por mineral.
- `Arena.wave` ya elige el jefe solo entre los de la arena (`Arena.originalEnemyIDs`): hecho con Valdemar.
- Todo lo que el motor necesita para los continentes 2-6, sin duplicados y con quién lo estrena: `motor_comun.md`.
- `PartCatalog.maxShopTier(forLevel:)` sirve para la arena; la historia necesita "tier del continente".
- Todo lo nuevo en `PlayerProfile` como **opcional** (área actual, continentes abiertos, misiones, Ascuas).
