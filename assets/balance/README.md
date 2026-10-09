# Balance

Responsable: `balance-designer`. Se mide con el banco de pruebas (`tools/Harness`):

- `make balance` — arena roguelike: un bot juega partidas desde cero y para en la forja cada 2 oleadas.
  Opciones directas: `cd tools/Harness && swift run -c release Harness balance [n] [-v] [-t] [perfil]`
  (`n` partidas por perfil, 5 por defecto; `-v` lo que forja cada partida; `-t` el héroe al empezar cada oleada;
  `-d` por qué no compra en una parada; perfiles: `nada`, `medias`, `solo-arma`, `bien`, `sin-nivel`).
- `make historia` — modo historia de Valdemar jugado por un bot con el combate real (nivel al llegar a cada zona,
  muertes, oro, minerales, duración de los jefes). Opciones: `cd tools/Harness && swift run -c release Harness historia
  [n] [-v] [-d] [--sin-esquivar] [--fijo]` (`n` partidas, 3 por defecto; `-v` lo que forja y cada muerte; `-d` cada
  pelea; `--fijo` equipo T1 fijo sin minerales y sin comprar).
- `Harness niveles` — estimación rápida del mismo ritmo sin combate (cada monstruo una vez + misiones).
- `make check-town` — flujo del pueblo (no mide dificultad).

## Arena roguelike: cómo juega el bot

Cada partida empieza de cero (`PlayerProfile.arenaRun`: nivel 1, espada de entrenamiento, túnica, 50 de oro). El bot
persigue al enemigo más cercano y **no esquiva** (un jugador real sí: los golpes avisan), así que un jugador llega más
lejos. En la forja:

- **Pociones**: todos los perfiles compran la poción si les falta más del 40 % de la vida.
- **Ritual**: busca la mejor arma posible con sus piezas + las de la tienda (+ minerales, según perfil). Si no le llega
  el oro, **ahorra**: compra ahora la hoja (y lo que pueda) y la forja en otra parada. Equipa lo mejor y vende lo viejo.
- **Armería y armadura de la tienda**: forja la pieza que más mejora.
- Elige por *mejora / √coste*, donde mejora = daño por segundo × vida efectiva (`botScore` en el banco de pruebas).

| Perfil | Qué hace |
|---|---|
| No mejora | Solo pociones. |
| A medias | Mejora una parada sí y otra no; sin minerales, sin vender, sin renovar ofertas. |
| Solo el arma | Todas las paradas, pero ignora la armería y los minerales. |
| Mejora bien | Todo: arma, armadura, minerales, vende lo viejo, renueva la tienda (2 veces) si no hay nada útil. |
| Bien, sin nivel | Igual que "bien" pero el héroe se queda en nivel 1 (diagnóstico: cuánto pesa el nivel). |

## Objetivos de la arena (curva "cuesta arriba")

| Perfil | Objetivo (oleada en la que cae, mediana) | Por qué |
|---|---|---|
| No mejora | **6-8** | Pasa el primer jefe con los niveles y las pociones, pero el piso 2 ya pide equipo. |
| Solo el arma | ~10-12 | La armería importa: sin armadura, el jefe de la 10 es un muro. |
| A medias | **12-16** | Va siempre una parada por detrás: aguanta la mitad del camino. |
| Mejora bien | **20-25** y luego muro | El tier 6 llega en la 18; desde la 20 los enemigos suben 2 niveles por oleada y nadie pasa de ~25. |
| Bien, sin nivel | Más que "no mejora", bastante menos que "bien" (~10-15) | El nivel importa (≈ la mitad del recorrido) pero no sustituye al equipo. |

Un jugador que esquiva y compra con cabeza debería quedar 2-5 oleadas por encima de su perfil.

## Mediciones

### 2026-10-07 · arena roguelike (tras los cambios del historial)

| Perfil | Antes (números viejos, bot nuevo, 10 partidas) | Después (16 partidas) | Después (`make balance`, 5) |
|---|---|---|---|
| No mejora | 5 (todas 5) | **6** (6-8) | 6 (6-8) |
| A medias | 5 (5-6) | **15** (8-16) | 16 (12-22) |
| Solo el arma | 5 (5-8) | **12** (10-14) | 10 (10-14) |
| Mejora bien | 5 (5-6) | **22** (10-25; 13 de 16 entre 21 y 25) | 22 (16-23) |
| Bien, sin nivel | 5 | **10** (6-18) | 11 (6-14) |

Antes todo caía en la 5: con 20 de oro y 12+7·oleada no había forma de pagar un arma (las ofertas de la forja ya eran de
tier 3 en la 4.ª oleada) y las armaduras de la armería costaban casi nada.
Nivel del héroe al caer (mediana): no mejora 4 · a medias 9 · bien 13 · Minerales en una partida "bien" hasta la 22: ~60-85.

### v0.3 (antes del roguelike, bot con equipo fijo y sin forja)

| Equipo del bot | Objetivo | Medición |
|---|---|---|
| Inicial | ~5 | 5, 5, 5 |
| Arma T2 Normal | ~9 | 9, 9, 8 |
| Arma T3 Fina | ~12 | 12, 13, 12 |
| Arma T4 Fina | ~13-14 | 13, 14, 14 |
| Arma T5 Excelente | ~19 | 19, 19, 19 |
| Arma T6 Excelente | ~22 | 23, 23, 22 |
| Arma T6 Obra maestra | ~25 | 25, 25, 25 |

## Historia: ritmo de Valdemar (`make historia`, B1)

Objetivo (brief de Valdemar): **~6 al liberar el pueblo, ~9 al entrar al patio, 10 al vencer al Rey Goblin** y el
continente acaba en 10-11.

### Cómo juega el bot de la historia (`tools/Harness/Sources/Harness/Historia.swift`)

- Empieza como una partida nueva (espada de entrenamiento, túnica, 30 de oro y las 3 piezas de cobre) y sigue el orden
  de `valdemar/historia.md` §5: pueblo (zonas y casas por nivel) → Huertos → Robleda → casa del alcalde → Abadía +
  Cripta → Pedregal → patio y trono → epílogo en la forja → Paso del Norte → Calabozos (opcional).
- Combate real de `ExploreScene`/`BattleScene`. Se pone junto a cada monstruo (no anda por el mapa) y pelea hasta que no
  queda nadie en guardia (lo que reaparece y le ve, también). **Esquiva** el 70 % de los golpes avisados (85 % los de
  jefe): golpes cuerpo a cuerpo, embestidas y disparos. Sin esquivar (`--sin-esquivar`) es el bot de la arena.
- Habla con todos los "!"/"?" del pueblo entre área y área. Si a una misión de matar le faltan monstruos, vuelve a
  entrar en el área (reaparecen) y mata los que cuentan.
- **Forja** en cada vuelta al pueblo: la mejor arma que puede hacer (hoja, guarda y empuñadura del tier de la forja o
  piezas de jefe que tenga, con sus 12 mejores minerales, calidad Normal) si mejora al héroe, y las 4 armaduras de la
  tienda. Pelea como un jugador: primero la escolta (magos, abanderados) y luego el jefe.
- Ante un muro (3 muertes con el mismo enemigo): tira la ruleta con sus minerales mientras le llegue el oro (hasta 4
  veces, se queda la mejor) y lo intenta otra vez; si sigue sin poder, sube un nivel en el campo (minutos de juego que
  se apuntan) y vuelve. Si aun así no puede, lo deja y lo dice ("No llega").

### Mediciones (2026-10-09, mediana)

| Momento | Objetivo | Antes de B1 (estimador) | Antes de B1 (bot) | B1 ronda 1 (bot, 5) | **B1 final (bot, 8 partidas)** | Final (estimador) |
|---|---|---|---|---|---|---|
| Pueblo liberado | ~6 | 6,2 | 6,2 | 6,2 | **6,2** | 6,2 |
| Tras los Huertos | — | — | 7,2 | 6,8 | 6,7 | — |
| Tras Robleda + casa del alcalde | — | — | 8,3 | 7,7 | 7,6 | — |
| Tras la Abadía y la Cripta | — | — | 10,0 | 9,1 | 8,5 | — |
| Antes del patio | ~9 | 11,4 | 10,6 | 9,8 | **9,0** (9,0-9,6) | 8,9 |
| Tras el Rey Goblin | 10 | 11,9 | 10,9 (sin vencerlo) | 10,7 (4 de 5 no lo vencen) | **9,8** (los 8 lo vencen) | 9,7 |
| Fin (Paso del Norte) | 10-11 | — | 10,9 | 10,7 | **10,0** | 9,9 |
| + Calabozos (opcional) | — | — | 11,4 | 11,0 | 10,2 | 10,1 |
| Muertes en toda la historia | — | — | 9-14 y muros | ~13 y muros | **~2** (15 en 8 partidas, ningún muro) | — |
| Oro al llegar al patio | — | — | 11 120 | ~2 000 | **~1 900** | — |

"Antes (bot)" = el mismo bot con los números viejos (3 partidas). "Ronda 1" = con la XP y el oro nuevos, pero piezas de
jefe de la arena sin usar y jefes sin ajustar. "Final" = además piezas de jefe de Valdemar (el bot las usa), jefes de
historia ajustados y el bot que mata primero a la escolta.
Nivel al llegar (final): Huertos 6,2 (zonas 5/6) · Robleda 6,7 (6/7) · guarida del lobo 6,9 (7) · casa del alcalde 7,4
(7) · Abadía 7,6 (7/8) · Cripta 7,9 (8) · Pedregal 9,1 (8/9) · patio 9,4 (9) · trono 9,6 (10) · Paso 10,3 (10).
**Cada zona se pisa con su nivel o medio nivel por debajo**: el nivel hace de puerta, como pide `progresion.md`.

Jefes (segundos desde que te ven hasta que caen, mediana final): Rey de las ratas 6 · Espantapájaros 11 · Herrero
poseído 15 · Capitán bandido 14 · Bruja 21 · **Ogro 42 · Lobo alfa 43 · Abad 58 · Señor de la guerra 61 · Rey Goblin 61**
(objetivo `progresion.md` §7: jefe de zona 40-60 s, jefe final 60-120 s). Antes: Ogro 25, Lobo 23, Abad 23, Rey 80 y muro.
Los jefes del pueblo (4-22 s) son el tutorial y no se han tocado.

Con las piezas de jefe de la arena (`--piezas-arena`, diagnóstico): 0 muertes y el Rey Goblin en 29 s. Por eso las
piezas de la historia tienen que ser propias.

### Jefes y piezas de jefe de la historia (la arena no cambia)

- **Ajuste de jefes solo en la historia** (`EnemyDefinition.storyBossTuning` / `forStory`, que usan `ExploreScene` y
  las mazmorras de historia de `BattleScene`; la arena usa la definición base):

| Jefe | Vida | Daño | Por qué |
|---|---|---|---|
| Ogro del molino | ×1,8 | ×0,8 | Caía en 25 s |
| Lobo alfa | ×1,5 | ×0,45 | Caía en 23 s, pero sus cargas y la manada eran muro (34 muertes en 5 partidas con ×0,75) |
| Abad no-muerto | ×2,0 | ×0,6 | Caía en 23 s; sus esferas a distancia mataban en la oleada final de la Cripta |
| Señor de la guerra orco | ×1,0 | ×0,8 | Duración bien (55 s), demasiadas muertes |
| Rey Goblin | ×0,95 | ×0,5 | Muro en 4 de 5 partidas; ahora 61 s y lo vencen los 8 |

- **Piezas de jefe de Valdemar** (`PartCatalog.storyBossParts`, ids `boss.<jefe>.valdemar`): en un área de Valdemar los
  jefes sueltan una copia con la misma forma, dibujo y habilidad, de **tier 1** y ≈1,5× una pieza de tier 1 del mismo
  hueco (1,6× los jefes de nivel 7-8, 1,75× los de 9-10; estadísticas planas × objetivo/poder del tier original, las de
  porcentaje con la curva suave del material). La arena sigue soltando `boss.<jefe>` (tier 3-6).
  ATQ: Diente del Rey Rata 8,8 (antes 14) · Martillo del Herrero 18,2 (40) · Piedra de molino 20 (55) · Hoja del Señor
  de la Guerra 23,4 (75) · Corona del Rey Goblin 5,6 (18). Una espada T1 Normal con 12 cobres: ~33.
- **Hoja del Alba (I)** (`legend.dawn`, solo la da la princesa): tier 6 → **tier 2**, ATQ 95 → 36 (≈1,3× un mandoble de
  hierro), +6 % velocidad, alcance 10, crítico 6 % ×1,25. Las ya forjadas conservan sus números.

### Mazmorras de historia

- Premio de la Cripta (`StoryDungeon.rewards`, en `StoryEconomy.swift`): la esmeralda solo **la primera vez** (antes
  se daba en cada victoria: repetir era una mina de esmeraldas) y **50 % de oro ×1 en cada victoria**, también al repetir
  (`zonas.md` §3). Test en `StoryBalanceTests`.
- Oleadas de la Cripta y los Calabozos y el acólito: **sin cambios**. Con el Abad ajustado, la Cripta cuesta ~0,5 muertes
  por partida (en la oleada del jefe) y los Calabozos ninguna; el acólito (nivel 7, vida 45, daño 13, a distancia)
  queda entre el cultista y el nigromante, en la curva del bestiario.

### Oro y forja de la historia

Precios de la forja (los mismos que en la arena, no cambian): espada T1 63 de piezas + 15 de ritual · 4 armaduras T1
164 en la tienda (108 forjadas) · espada T2 116 + 25 · armaduras T2 273 en la tienda (182 forjadas). Con los números
viejos el pueblo daba 2 650 de oro y el patio se pisaba con ~11 000: el oro no pesaba. Ahora (`StoryEconomy`):

| Fuente | Antes | Ahora |
|---|---|---|
| Monstruo | 2 + 2·nivel | 1 + nivel/3 |
| Jefe (además) | 40·nivel | 10·nivel |
| Zona liberada | 40·nivel | 3·nivel |
| Aldeanos (6) | 60-180 (680 en total) | 25-50 (225) |
| Princesa | 500 | 200 |
| Misiones | 80-200 (1 150 en total) | 40-80 (470) |

Resultado: ~440 de oro al liberar el pueblo (lo justo para la espada con minerales y las 4 armaduras T1, que el bot
tiene a nivel ~4,5), ~2 000 al llegar al patio y lo del tier 2 (414 en la tienda) de sobra al final. **Lo que manda son
los minerales**: el cobre (ATQ) se gasta entero en las espadas y la ruleta; el bot llega al patio sin cobre.

Minerales: los aldeanos y la princesa ya no dan nada de fuera de la familia (antes: zafiro, rubí, amatista, diamante,
mithril). Pueblo: ~20-25 de la familia (aldeanos 16 + jefes + monstruos), suficiente para una espada de 12; el campo da
otros ~40 hasta el patio (misiones 13, jefes, monstruos y Cripta). Fray Anselmo regala `head.mace.iron` (T2) en vez de
`head.mace.silver` (T3, demasiado para el nivel 5).

### Pendiente

- La fórmula de `EnemyDefinition.stats(level:)` medida de 1 a 60 (`progresion.md` §7): sin tocar; queda para cuando
  haya un segundo continente que medir (en Valdemar, el ritmo y los jefes ya cumplen con la fórmula actual).
- La XP de la historia la reparte `Leveling.respawningMultiplier` (×0,3): si Rocaforja pone más monstruos por área,
  revisarlo allí con `make historia` adaptado.

## Historial de cambios

| Fecha | Cambio | Motivo | Resultado |
|---|---|---|---|
| 2026-10-06 | Golpes enemigos con aviso (esquivables) y +dificultad en niveles altos | El aviso hacía el juego más fácil | Curva recuperada |
| 2026-10-07 | Bot de arena nuevo (forja, ahorra piezas, armería, pociones; 5 perfiles) | La arena es roguelike: el bot de equipo fijo ya no medía nada (todo caía en la 5) | Tabla nueva |
| 2026-10-07 | Oro inicial de la partida 20 → 50; oro por oleada 12+7·n → 16+7·n | No se podía pagar ni la primera arma antes del primer jefe | Primera arma en la parada 1-2 |
| 2026-10-07 | Forja de la arena: nivel `1+n/2` → `max(1, n/2)` (T2 hasta la 4, T3 en la 6, T4 en la 10, T5 en la 14, T6 en la 18) | Los precios saltaban de tier antes de poder pagar el anterior; el T6 llega justo antes del muro | Progresión de un tier cada 4 oleadas |
| 2026-10-07 | Armería: coste `12·tier+5` → `(30/22/20/16 por peto/casco/botas/guantes)·poder^1,3 + 5`; armadura de la tienda = 1,5 × ese coste | Un peto T6 costaba 77 de oro (la armería salía 3 veces más barata que el arma) | Equipo completo ≈ 1,3 × un arma del mismo tier |
| 2026-10-07 | El material ya no multiplica entero la velocidad de ataque, alcance, velocidad, crítico, robo de vida ni oro: crecen con `1 + 0,2·(poder−1)` (armas y armaduras) | Una daga de mithril daba +2 ataques/s y un martillo de glacita bajaba a 0,4 (las armas lentas no servían) | Todas las formas son viables en tier alto |
| 2026-10-07 | Forja: siempre hay al menos una hoja, una guarda y una empuñadura a la venta | 1 de cada 6 paradas no se podía montar ningún arma | El ritual siempre es posible |
| 2026-10-07 | Nivel de los enemigos de la arena: 1 en las oleadas 1-5, +3 cada 5 oleadas hasta la 20 (nivel 10) y +2 por oleada desde la 20 (`Arena.wallWave`) | El héroe sube ~1 nivel por oleada: sin acelerar, el equipo al máximo + niveles no tenía techo (una partida llegó a la 55) | Muro en 22-25 |
| 2026-10-07 | Oleadas de jefe: la mitad de monstruos normales | Los jefes + 14-30 monstruos mataban a todos los perfiles en la 5/10/15 por desgaste | Caen ante jefe 0-3 de 16 (antes 6-10 de 10) |
| 2026-10-07 | Minerales: `dropRateMultiplier` 0,3 → 0,15 | Con 0,3 el bot llenaba los 12 huecos del ritual en cada parada (~140 minerales por partida) | ~60-85 por partida "bien" (5 de media entre paradas); en el pueblo, ~5 de monstruos normales + los de jefes y aldeanos |
| 2026-10-07 | XP de jefes de historia ×12 → ×6 (`Leveling.storyBossMultiplier`; la arena sigue ×12) | Con ×12 el pueblo liberado daba nivel ~7 | Pueblo ≈ 6,2 |
| 2026-10-09 | Bot nuevo del modo historia (`make historia`): combate real, esquiva, misiones, forja, mazmorras | B1: el estimador `niveles` no medía muertes, oro ni minerales | Tabla "Historia" |
| 2026-10-09 | Rayo de habilidad (`strikeEvery`, p. ej. Juicio de la espada de cobre inicial) solo a enemigos en guardia (`CombatScene`) | Bug: en la exploración pegaba al monstruo con más vida del mapa y despertaba jefes lejanos (el Lobo alfa venía desde 500 px) | Arena igual (allí todos están activos): 12 partidas tras B1, "bien" mediana 22, "a medias" 14 |
| 2026-10-09 | XP de los monstruos que reaparecen (campo y mazmorras de historia) ×0,4 → ×0,3 (`Leveling.respawningMultiplier`) | El campo llevaba al patio con nivel 10,6-11,4 (objetivo ~9); con ×0,4, 9,8 | Patio 9,0 (bot) / 8,9 (estimador) |
| 2026-10-09 | Misiones de fuera del pueblo: XP ×~0,55 (molino 100, caza 100, hilos 75, alcalde 95, limos 65, abadía 160 → 130, Pedregal 120 → 100, epílogo 150, calabozos 100) y oro ×~0,4 | Mismo motivo; `liberar` (172) y `rey_goblin` (505) no cambian | Ver tabla |
| 2026-10-09 | Oro de la historia (`StoryEconomy`): monstruo 1+nivel/3, jefe +10·nivel, zona 3·nivel; aldeanos 25-50, princesa 200 | Se llegaba al patio con ~11 000 de oro y el equipo T1-T2 cuesta ~80-400 | ~440 al liberar el pueblo, ~2 000 en el patio |
| 2026-10-09 | Recompensas de aldeanos y princesa solo con minerales de Valdemar y menos (16 en total); Anselmo da maza de hierro (T2) | `minerales.md`: nada de fuera de la familia; la maza de plata (T3) era demasiado | Test `StoryBalanceTests` |
| 2026-10-09 | Piezas de jefe propias de Valdemar (`boss.<jefe>.valdemar`, tier 1, ≈1,5-1,75× una pieza T1) y Hoja del Alba T6 → T2 (ATQ 95 → 36) | Con las de la arena (tier 3-6) el Martillo del Herrero daba ATQ 40 a nivel 4 y el Rey Goblin caía en 29 s | Ritmo y jefes medidos con ellas |
| 2026-10-09 | Jefes de historia: Ogro ×1,8 vida ×0,8 daño · Lobo alfa ×1,5/×0,45 · Abad ×2/×0,6 · Señor de la guerra ×1/×0,8 · Rey Goblin ×0,95/×0,5 (`storyBossTuning`) | Ogro, Lobo y Abad caían en ~25 s; Lobo, Señor de la guerra y Rey eran muros para el bot | 42-61 s; ~2 muertes por partida y ningún muro (8 partidas) |
| 2026-10-09 | Cripta: esmeralda solo la primera vez; 50 % de oro ×1 en cada victoria | `zonas.md` §3; repetir daba una esmeralda cada vez | Test |
| 2026-10-09 | Arena tras todo B1 (12 partidas): no mejora 6 · a medias 16 · solo el arma 10 · bien 18 (12-23) · sin nivel 10 | Comprobar que la arena no cambia (la arena usa la definición base de los jefes y sus piezas de siempre) | Igual que antes de B1 (5 partidas: 6/16/10/18/10) |
