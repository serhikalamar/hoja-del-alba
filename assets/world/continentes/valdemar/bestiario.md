# Valdemar · bestiario

Responsable: `continent-lead` de `valdemar`. Valdemar se construye **con los 50 enemigos que ya existen** + **1 nuevo**
(`eclipseAcolyte`). Fichas y estadísticas base de los existentes: `assets/characters/enemigos.md` (generado).
Posición exacta de cada spawn: tablas de `mapas/<zona>.md`.

## 1. Qué enemigo va en cada área (y cuántos)

Cifras = spawns colocados en el mapa (los de campo reaparecen). Entre paréntesis, el nivel de zona.

| Enemigo | Huertos | Robleda | Abadía | Cripta | Pedregal | Paso | Pueblo / castillo (ya) | Total nuevo |
|---|---|---|---|---|---|---|---|---|
| `zombieFarmer` Granjero zombi | 4 (5) | | | | | | sí | 4 |
| `boar` Jabalí | 2 (5) | 2 (6) | | | | | sí | 4 |
| `crow` Cuervo carroñero | 2 (5) | | | | | | sí | 2 |
| `skeleton` Esqueleto | 4 (5-6) | | 3 (7) | oleadas + escolta | | | sí | 7 |
| `mudGolem` Gólem de barro ★ | 2 (5-6) | | | | | | — | 2 |
| `goblinBomber` Goblin bombardero ★ | 1 (5) | | | | 2 (8) | | — | 3 |
| `plagueRat` Rata de la peste ★ | 3 (5-6) | | | | | | — | 3 |
| `slime` Limo verde | 2 (5) | | | | | | sí | 2 |
| `wolf` Lobo gris | | 5 (6-7) | | | | | sí | 5 |
| `bandit` Bandido | | 4 (6) | | | | | sí | 4 |
| `mercenary` Mercenario | | 3 (6) | | | | | sí | 3 |
| `goblinSpearman` Goblin lancero | | 2 (6) | | | | | sí | 2 |
| `goblinShaman` Chamán goblin | | 2 (6) | | | | | sí | 2 |
| `hobgoblin` Hobgoblin | | 2 (6) | | | | | sí | 2 |
| `skeletonArcher` Esqueleto arquero | | | 1 (7) | oleadas | | | sí | 1 |
| `ghoul` Necrófago | | | 2 (7) | oleadas | | | sí | 2 |
| `wraith` Espectro ★ | | | 3 (7-8) | oleada 2 | | | — | 3 |
| `gargoyle` Gárgola ★ | | | 2 (8) | oleada 2 | | | — | 2 |
| `necromancer` Nigromante ★ | | | 1 (8) | oleada 3 | | | — | 1 |
| `blackKnight` Caballero negro ★ | | | 2 (8) | oleada 3 | | | — | 2 |
| `cultist` Cultista | | | 2 (7) | oleada 2 | | | sí | 2 |
| `eclipseAcolyte` **NUEVO** | | | 2 (7-8) | oleada 2 | | | casa del alcalde ×2 | 4 |
| `fireSlime` Limo de fuego | | | 2 (7) | oleada 2 | | | sí | 2 |
| `iceSlime` Limo helado ★ | | | | oleada 3 | 3 (8) | | — | 3 |
| `troll` Troll ★ | | | | | 3 (8) | | — | 3 |
| `wolfRider` Jinete de lobo | | | | | 2 (8) | 2 (10) | sí | 4 |
| `assassin` Asesino sombrío ★ | | | | | 2 (8) | | — | 2 |
| `orc` Orco | | | | | 3 (9) | | sí | 3 |
| `berserker` Orco berserker ★ | | | | | 2 (9) | | — | 2 |
| `armoredBoar` Jabalí acorazado ★ (élite) | | | | | 1 (9) | 1 (10) | — | 2 |
| `goblinElite` Goblin de élite | | | | | | 2 (10) | sí | 2 |
| `goblinMage` Mago goblin | | | | | | 1 (10) | sí | 1 |
| **Campo por área** | **20** | **20** | **20** | 30 + jefe | **18** | **6** | | |

★ = de los 12 que hoy solo salían en la arena: **los 12 quedan colocados** (`mudGolem`, `goblinBomber`, `plagueRat`,
`wraith`, `troll`, `blackKnight`, `gargoyle`, `necromancer`, `berserker`, `iceSlime`, `assassin`, `armoredBoar`).

## 2. Jefes del continente

| Jefe | Dónde | Nivel de zona | Spawn | Pieza (ya existe) | Misión |
|---|---|---|---|---|---|
| `ratKing` Rey de las ratas | Panadería | 2 | `bakery.4` | `boss.ratKing` Diente del Rey Rata | `liberar` |
| `banditChief` Capitán bandido | Plaza mayor | 5 | `plaza.5` | `boss.banditChief` Guarda del Capitán | `liberar` |
| `scarecrow` Espantapájaros maldito | Casa del molinero | 3 | `mill.3` | `boss.scarecrow` Mango del Espantapájaros | `liberar` |
| `possessedSmith` Herrero poseído | Posada | 4 | `inn.5` | `boss.possessedSmith` Martillo del Herrero | `liberar` |
| `witch` Bruja del pozo | Casa de la alquimista | 6 | `alchemist.4` | `boss.witch` Escoba de la Bruja | `liberar` |
| **`ogre` Ogro del molino** | Huertos · Molino en ruinas | 6 | `valdemar.huertos.1` (9,11) + escolta `mudGolem` | `boss.ogre` Piedra de molino | `molino` |
| **`alphaWolf` Lobo alfa** | Robleda · Guarida | 7 | `valdemar.robleda.18` (55,30) | `boss.alphaWolf` Colmillo Alfa | `caza_mayor` |
| **`abbot` Abad no-muerto** (Heraldo) | Cripta (mazmorra) | 8 | oleada final de `valdemar.cripta` | `boss.abbot` Rosario del Abad | `abadia` |
| **`warlord` Señor de la guerra orco** | Pedregal · Campamento orco | 9 | `valdemar.pedregal.19` (51,31) | `boss.warlord` Hoja del Señor de la Guerra | `pedregal` |
| **`goblinKing` Rey Goblin** (final) | Salón del trono | 10 | `castle.6` | `boss.goblinKing` Corona del Rey Goblin | `rey_goblin` |

Los jefes de campo **no reaparecen** (spawn permanente en `killedSpawns`). Todos sueltan su pieza la primera vez.

## 3. Monstruo nuevo (1 de los 3 permitidos)

### `eclipseAcolyte` — Acólito del Eclipse

| Campo | Valor |
|---|---|
| Id | `eclipseAcolyte` (camelCase, único) |
| Nombre | Acólito del Eclipse |
| Nivel de aparición | **7** |
| Plantilla | `human` |
| Comportamiento | `ranged` (lanza una esfera de sombra violeta, lenta, que hace algo más de daño que el cultista) |
| Base propuesta | vida 45 · daño 13 · velocidad 50 · cadencia 2,4 s · alcance 180 · radio 15 · escala 1,05 · `drop` 0,7 (el `balance-designer` los cierra) |
| Dónde | Casa del alcalde (2), Abadía: claustro (1) y huerto (1), Cripta oleada 2 (2) |
| Aspecto (para el pixel-artist) | Túnica **gris ceniza** larga con capucha que tapa los ojos (solo brillan dos puntos violeta), **emblema de luna negra con borde violeta** en el pecho, faja morada, manos vendadas, un libro cerrado con cadena colgando del cinto. Distinto del cultista (que es marrón y con antorcha): el acólito es "la Orden de verdad". Paleta: ceniza #6B6670, sombra #3A3540, violeta #8E5CC2, brillo #C9A6FF. |
| Por qué | El Eclipse aparece en los 6 continentes "con estética local": este acólito fija **la estética base de la Orden** (luna negra + violeta) que los demás leads pueden variar. |

Monstruos nuevos que **no** hacen falta (descartados para no gastar arte): el alcalde como mini-jefe (huye; mejor como
gancho), un guardabosques hostil, un orco chamán.

## 4. NPC nuevos (no son monstruos)

| Id | Nombre | Look | Dónde |
|---|---|---|---|
| `capitanGuardia` | Capitán Rodrigo Vela | `guardCaptain`: humano adulto, barba corta gris, coraza abollada de cobre con tabardo azul y blanco de Valdemar, capa raída, casco bajo el brazo | `town` (18,12) |
| `cartaAlcalde` | Carta del alcalde | `letter`: pergamino enrollado con lacre negro (luna) sobre el escritorio | `mayor` (12,2) |
| `cartelPaso` | Cartel del camino | `signpost`: poste de madera con dos tablas (una dice "Valdehierro", la otra "Rocaforja") | `valdemar.paso` (26,2) |
