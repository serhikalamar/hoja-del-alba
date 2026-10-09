# Brief · Continente 1 · `valdemar` — Reino de Valdemar (niveles 1-10)

> **Encargo original (2026-10-07).** Tras el diseño de los leads, lo vigente está en `assets/world/mundo.md` (§5, §13 y §14),
> `continentes.md` (registros comunes y renombres), `progresion.md` (XP de misiones y Hoja del Alba) y `motor_comun.md`.

Para: `continent-lead` de `valdemar`. De: `world-designer`. Lee antes `CLAUDE.md`, `assets/world/mundo.md`,
`assets/world/continentes.md`, `assets/world/progresion.md`, `assets/maps/valdehierro.md`, `assets/maps/mazmorra.md`,
`assets/story/historia.md` y `assets/characters/enemigos.md`.

> **Este continente se implementa ya, entero, después de tu trabajo.** Tu diseño tiene que poder pasarse a código
> sin más preguntas: ids, niveles, qué enemigo va en cada zona, qué dice cada misión y qué hace falta en el motor.
> Prioridad: **reutilizar** lo que existe. Valdemar debe poder construirse casi sin monstruos nuevos.

## 1. Qué es Valdemar

El reino humano: praderas, robledales, granjas, una abadía abandonada y colinas pedregosas. Verdes y ocres
cálidos. Es el **tutorial del MMO**: aprender a moverse, forjar, aceptar misiones y viajar entre zonas.
Emoción: *hogar*. Capital: **Valdehierro** (ya existe, 44×36). Tier de material 1. Minerales: cobre, hierro, plata,
oro, esmeralda. Jefe final: el **Rey Goblin**. Heraldo del Eclipse: el **Abad Morcar** (`abbot`).

## 2. Lo que ya existe y se queda (canon)

| Qué | Dónde | Cómo se usa ahora |
|---|---|---|
| Valdehierro: 6 zonas (`south` 1, `market` 2, `west` 3, `east` 4, `plaza` 5, `courtyard` 7) | `Town.swift` | Zona inicial 1-5. **El patio sube a nivel 9** (es la antesala del final). |
| 9 edificios, 7 interiores (`bakery` 2, `weaver` 3, `mill` 3, `chapel` 5, `inn` 4, `alchemist` 6, `castle` 10) | `Town.swift` | Igual. La **casa del alcalde** (`mayor`, cerrada) se abre con una misión (sección 5). |
| 6 aldeanos rescatables + princesa Aurora | `Town.swift` | Tras rescatarlos se vuelven **dadores de misiones**. |
| 50 enemigos (40 normales + 10 jefes) | `Enemy.swift` | 12 normales y 4 jefes **solo salen hoy en la arena**: pasan a las zonas exteriores (tabla de la sección 4). |
| 11 piezas únicas + Hoja del Alba | `Parts.swift` | Se quedan; el `balance-designer` las baja a la escala de Valdemar (`progresion.md` §6). |
| Pisos de mazmorra `crypt` y `prison` | `Dungeon.swift` | `crypt` = Cripta de la abadía (mazmorra de historia). `prison` = Calabozos del castillo (opcional). |
| Forja del enano, ritual, armería | `ShopModel`, `Crafting`, `Armor` | Vende **tier 1** (cobre/roble/piel curtida/lino); tier 2 tras vencer al Rey Goblin. |
| Ids guardados en partidas | — | **No se renombra nada** de lo anterior. |

Enemigos que hoy son solo de la arena y que tienes que colocar: `mudGolem`, `goblinBomber`, `plagueRat`, `wraith`,
`troll`, `blackKnight`, `gargoyle`, `necromancer`, `berserker`, `iceSlime`, `assassin`, `armoredBoar` (normales) y
`alphaWolf`, `ogre`, `abbot`, `warlord` (jefes). Los demás pueden repetirse fuera del pueblo.

## 3. Mapa del continente (esquema; tú haces los borradores de cada área)

```
                      [ Paso del Norte ]  valdemar.paso · 10 · cerrado hasta vencer al Rey Goblin → Rocaforja
                              |
                 (franja oeste, junto al castillo)
                              |
 [ Huertos del Molino ] ---- VALDEHIERRO ---- [ Abadía de Valsombra ]
   valdemar.huertos     oeste  (town)   este    valdemar.abadia · 7-8
   5-6 · Molino en             1-5, patio 9,     cementerio, claustro,
   ruinas (Ogro)               trono 10          entrada `e` a la Cripta (mazmorra 8: Abad)
          \                    | sur (camino real)
           \                   |
            `--------- [ Bosque de Robleda ] ---------- [ Colinas del Pedregal ]
                         valdemar.robleda · 6-7           valdemar.pedregal · 8-9
                         campamento bandido,              campamento orco,
                         guarida del Lobo alfa            Señor de la guerra orco
```

- Salidas del pueblo: **oeste** y **este** al final de las calles de las filas 17-18 (hoy acaban en árboles),
  **sur** por el camino de las filas 32-35 y **norte** por la franja de hierba al oeste de la muralla del castillo.
- Huertos ↔ Robleda también se conectan (dos rutas, nunca un callejón sin salida).
- Tamaño orientativo de cada área: 48-64 × 32-40 casillas, 2-3 zonas de nivel por área, 12-20 monstruos de campo.
- Leyenda: la de `assets/maps/README.md` + la común de exteriores de `continentes.md` (`d % p R ^ + n x e >`).

## 4. Zonas, niveles y monstruos (propuesta: ajústala, pero respeta niveles e ids)

| Área / zona | Id | Nivel | Monstruos (ids existentes) | Jefe | Qué hay |
|---|---|---|---|---|---|
| Valdehierro (pueblo) | `town` | 1-5 | Los de ahora | Rey de las ratas, Capitán bandido, Espantapájaros, Herrero poseído, Bruja del pozo (en sus casas) | Capital: forja, posada (reaparición), misiones. Segura al liberarla. |
| Huertos del Molino | `valdemar.huertos` | 5 / 6 | `zombieFarmer`, `boar`, `crow`, `skeleton`, `mudGolem`, `goblinBomber`, `plagueRat` | **Ogro del molino** (`ogre`) en el Molino en ruinas (zona 6) | Trigales `%`, granjas quemadas, molino, río con puente. |
| Bosque de Robleda | `valdemar.robleda` | 6 / 7 | `wolf`, `boar`, `bandit`, `mercenary`, `goblinSpearman`, `hobgoblin`, `goblinShaman`, `crow` | **Lobo alfa** (`alphaWolf`) en su guarida (zona 7) | Camino real `d`, robledal `T`, campamento bandido `n x`, puesto del guardabosques. |
| Abadía de Valsombra | `valdemar.abadia` | 7 / 8 | `skeleton`, `skeletonArcher`, `ghoul`, `wraith`, `gargoyle`, `necromancer`, `cultist`, `blackKnight` | — (el Abad está en la cripta) | Cementerio `+`, claustro en ruinas, entrada `e` a la cripta. |
| Cripta de la abadía (mazmorra) | piso `crypt` | 8 | Oleadas de no-muertos y cultistas | **Abad no-muerto** (`abbot`) | 3 oleadas + jefe. Bajo ella, el Ascua de Valdemar. |
| Colinas del Pedregal | `valdemar.pedregal` | 8 / 9 | `orc`, `troll`, `berserker`, `wolfRider`, `goblinBomber`, `assassin`, `armoredBoar` (élite) | **Señor de la guerra orco** (`warlord`) en su campamento (zona 9) | Rocas `R`, acantilados `^`, campamento orco, tótems `+`. |
| Patio del castillo | `courtyard` | **9** (antes 7) | Los de ahora | — | Se abre con la condición nueva (sección 5). |
| Salón del trono | `castle` | 10 | Los de ahora | **Rey Goblin** (`goblinKing`) | Princesa → Hoja del Alba (I). |
| Calabozos del castillo (opcional) | piso `prison` | 9-10 | Goblins de élite, orcos | — | Mazmorra opcional para farmear antes del trono. |
| Paso del Norte | `valdemar.paso` | 10 | — (o pocos) | — | Transición a Rocaforja: al principio, cerrado con un cartel "Próximamente". |

`iceSlime` y `fireSlime` pueden ir en la cripta o en el Pedregal; `armoredBoar` es el élite del Pedregal.
Monstruos nuevos: **máximo 3**, opcionales (p. ej. el **alcalde traidor** como mini-jefe humano, un **acólito del
Eclipse** con estética propia). Todo lo demás, reutilizado.

## 5. Historia del capítulo y misiones

**Arco**: los goblins toman Valdehierro → el héroe libera el pueblo y rescata a los aldeanos → los aldeanos lo mandan
fuera: el Rey Goblin recibe ayuda del exterior (orcos del Pedregal, no-muertos de la abadía) → la carta del alcalde
revela a la **Orden del Eclipse** → en la cripta, el **Abad Morcar** confiesa (a medias) que busca el Ascua y la Hoja
del Alba → con el Pedregal y la abadía caídos, los guardias abren el castillo → **Rey Goblin** → Aurora entrega la
**Hoja del Alba (I)** → epílogo: un encapuchado huye hacia el norte; el enano herrero reconoce el fuego del Clan
Hollín en las armas orcas → se abre el **Paso del Norte** (Rocaforja).

**Condición nueva del castillo**: los 6 aldeanos rescatados **y** el Abad (cripta) **y** el Señor de la guerra orco
vencidos. (Hoy basta con los aldeanos: `TownProgress.castleOpen`.)

Misiones propuestas (8-12; el lead las fija con ids `valdemar.<nombre>` y el `story-writer` escribe los textos):

| Id | Da | Zona | Objetivo | Recompensa orientativa |
|---|---|---|---|---|
| `valdemar.liberar` | (inicio) | Valdehierro | Liberar las calles y rescatar a los 6 aldeanos (lo que ya hay, ahora en el diario) | XP de historia |
| `valdemar.molino` | Tomás | Huertos | 6 granjeros zombi + Ogro del molino | XP, oro, plata |
| `valdemar.caza_mayor` | Bruno | Robleda | 6 lobos grises + Lobo alfa | XP, oro, poción |
| `valdemar.hilos` | Elena | Robleda | Limpiar el campamento bandido (8 bandidos/mercenarios) → volver con la carta | XP; abre la casa del alcalde |
| `valdemar.alcalde` | Elena | Casa del alcalde | Entrar en la casa (interior nuevo, nivel 7, cultistas) y leer la carta: él abrió la puerta sur | XP |
| `valdemar.abadia` | Fray Anselmo | Abadía + cripta | 10 no-muertos + la Cripta (Abad no-muerto) | XP grande, esmeralda |
| `valdemar.pociones` | Iris | Abadía / Pedregal | 6 limos (`slime`/`fireSlime`/`iceSlime`) | Pociones, oro |
| `valdemar.pedregal` | **Capitán de la guardia** (NPC nuevo, junto a la escalinata) | Pedregal | 6 orcos + Señor de la guerra orco | XP grande, oro |
| `valdemar.rey_goblin` | Capitán / Aurora | Patio + trono | Rey Goblin | Hoja del Alba (I) |
| `valdemar.paso_norte` | Enano herrero | Pueblo | Hablar con él tras el trono → se abre el Paso del Norte | Tier 2 en la forja |

**Ritmo objetivo**: nivel ~6 al terminar el pueblo (hoy da ~2 450 XP), ~9 al entrar al patio, **10 al vencer al Rey
Goblin**. Los jefes pesan mucho aquí (~1 800 XP los cuatro de fuera): úsalos como hitos de misión.

## 6. Minerales y piezas

- Minerales de Valdemar: `copper` 35 %, `iron` 27 %, `silver` 20 %, `gold` 12 %, `emerald` 6 % (mismas bonificaciones
  que ahora). Diamante, amatista, rubí, zafiro y mithril **dejan de salir** en la historia (siguen en la arena).
- La princesa da oro + esmeralda en vez de mithril + diamante (y la Hoja del Alba).
- Forja: tier 1; tier 2 tras el Rey Goblin. Piezas únicas de los 10 jefes: se quedan, recalibradas a Valdemar.
- Sin formas de arma nuevas (Valdemar usa las 9 + 7 + 5 actuales). Conjunto de armadura `*.valdemar` opcional.

## 7. Qué hace falta en el motor (para tus encargos al `game-programmer`)

| # | Prioridad | Qué | Por qué |
|---|---|---|---|
| M1 | P1 | **Áreas exteriores enlazadas**: salidas `>` en el borde de un mapa que llevan a otra área y a un punto de llegada (como las puertas de los interiores, pero entre exteriores). El pueblo gana salidas oeste, este, sur y norte. Guardar el área actual (campo opcional). | Viajar entre zonas. |
| M2 | P1 | **Monstruos de campo que reaparecen** (al volver al área o ~90 s después, fuera de la vista). Los de la historia (casas, jefes, el pueblo) siguen siendo permanentes. | La XP de `progresion.md` no sale sin esto. |
| M3 | P1 | **Misiones**: datos en GameCore (id, quién la da, objetivos: matar N de X / vencer a un jefe / hablar / llegar a un área; recompensa XP, oro, minerales, pieza; requisitos), progreso en el perfil (opcional), "!" y "?" sobre el NPC, diario en la pausa. Los aldeanos rescatados dan misiones. | Columna del modo historia. |
| M4 | P1 | **Condición del castillo ampliada** (aldeanos + Abad + Señor de la guerra) y **casa del alcalde** que se abre con una misión. | Historia. |
| M5 | P1 | **Casillas de exterior nuevas** (`d % p R ^ + n x e >`) y **bioma por área** (el mismo carácter se dibuja según el bioma). | Mapas de fuera del pueblo. |
| M6 | P1 | **Botín y forja por continente**: tabla de minerales de la familia del continente del área; forja de la historia con el tier del continente; la arena intacta (sus 10 minerales, sus 10 jefes). | `progresion.md` §4-5 y §8. |
| M7 | P1 | **Datos de continente** en GameCore (`Continent`: id, nombre, niveles, capital, áreas, familia de minerales, tier), para que los continentes 2-6 se añadan como datos. | Escalar a 6. |
| M8 | P2 | **Mazmorra de historia**: una partida de la arena corta y fija (3-4 oleadas de una lista + jefe) en un piso concreto, con tu personaje y sin reinicio roguelike; se entra por una `e` y al ganar cuenta para la misión. | Cripta de la abadía (y todas las mazmorras/bandas futuras). |
| M9 | P2 | **Reaparecer en el punto seguro del área** (entrada / hoguera), no siempre en la Puerta sur. | Áreas grandes. |
| M10 | P3 | Nombre y nivel de la zona al entrar ("Bosque de Robleda · 6-7") y **mapa del continente** en la pausa. | Orientarse como en un MMO. |

## 8. El equipo de Valdemar (cómo repartir para que sea óptimo)

En tu `encargos.md`, un encargo por especialista, con ficheros y comprobación, en este orden:

1. **En paralelo** (no se pisan si respetan los ficheros):
   - `game-programmer`: M1-M7 (luego M8-M10) en ficheros nuevos de GameCore (p. ej. `World.swift`, `Quest.swift`) y
     sus tests; un área de prueba mínima para comprobar los viajes. Toca `Town.swift` solo para salidas/castillo.
   - `map-designer`: borradores de las 5 áreas nuevas (`mapas/<zona>.md` tuyos → código en un fichero nuevo, p. ej.
     `Valdemar.swift`, para no pisar `Town.swift`), las 4 salidas del pueblo y la casa del alcalde.
   - `story-writer`: textos de las misiones, diálogos nuevos de aldeanos tras el rescate, Capitán de la guardia,
     carta del alcalde, confesión del Abad, epílogo; actualiza `assets/story/historia.md`.
   - `character-designer`: colocar los enemigos reutilizados, el Capitán de la guardia, el alcalde y los (≤3)
     monstruos nuevos.
2. **Después** (necesitan M5 y los mapas): `environment-artist` (bioma de Valdemar: trigales, robledal, cementerio,
   campamentos, rocas, acantilados, puente, hoguera, cueva) y `pixel-artist` (NPC y monstruos nuevos).
3. **Después** (con todo jugable): `balance-designer` — niveles de zona, piezas de jefe, tabla de minerales, tier de la
   forja, ritmo 1→10 medido con una simulación nueva del modo historia; y la fórmula de `stats(level:)` mirando ya a 60.
4. **Al final**: `qa-tester` (`make verify`, `make check-town` ampliado con salidas, misiones y castillo nuevo).

## 9. Lo que entregas (en `assets/world/continentes/valdemar/`)

Lo de tu fichero de agente (`historia.md`, `zonas.md`, `mapas/<zona>.md`, `bestiario.md`, `minerales.md`,
`piezas.md`, `encargos.md`), con estas precisiones:
- `bestiario.md`: qué enemigo existente va en cada zona y cuántos; los ≤3 nuevos con ficha completa.
- `mapas/`: un borrador por área nueva (huertos, robleda, abadia, pedregal, paso) + la casa del alcalde + los cambios
  del pueblo (dónde se abren las 4 salidas). Marca entradas/salidas y la posición de cada spawn y NPC.
- `encargos.md`: los 7 encargos de la sección 8 listos para lanzar, con criterios de "hecho".

**No**: no cambies ids existentes, no toques `src/`, no diseñes Rocaforja (su lead está en ello; el Paso del Norte
solo llega hasta su puerta).
