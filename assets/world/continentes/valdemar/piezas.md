# Valdemar · piezas y equipo

Valdemar **no añade formas de arma** (usa las 9 hojas, 7 guardas y 5 empuñaduras actuales: `continentes.md`).
Tier de material: **1** (cobre · roble · piel curtida · lino). Este documento fija qué vende la forja, qué hacer con
las piezas de jefe y el conjunto de armadura opcional.

## 1. Forja de Valdehierro (M6)

| Momento | Qué vende |
|---|---|
| Desde el principio | Piezas y armaduras de **tier 1** (cobre, roble, piel curtida, lino) + poción |
| Tras `valdemar.rey_goblin` / `valdemar.paso_norte` | También **tier 2** (hierro, cuero, cuero de jabalí, lana), para llegar a Rocaforja con algo |

Hoy la forja de la historia sube de nivel con zonas y rescates (`TownProgress.shopLevel`, hasta 10, pensado para el
mundo de 10 niveles). En la historia pasa a mandar el **tier del continente**; `shopLevel` puede seguir decidiendo
cuántas ofertas y su calidad dentro del tier. La arena no cambia (`Arena.shopLevel`).

## 2. Piezas únicas de jefe (ya existen, se recalibran)

Las 10 de `Parts.swift` (`boss.ratKing` … `boss.goblinKing`) + `legend.dawn` se quedan con su id, forma y habilidad.
Hoy tienen tier 3-6; el `balance-designer` las baja a la escala de Valdemar: **≈ 1,5× una pieza de tier 1 del mismo
hueco** (la de los jefes de nivel 9-10, algo más). Las ya forjadas en partidas guardadas conservan sus números.

| Pieza | Jefe (nivel de zona) | Hueco | Momento en que llega |
|---|---|---|---|
| `boss.ratKing` Diente del Rey Rata | Rey de las ratas (2) | hoja | pueblo |
| `boss.banditChief` Guarda del Capitán | Capitán bandido (5) | guarda | pueblo |
| `boss.scarecrow` Mango del Espantapájaros | Espantapájaros (3) | empuñadura | pueblo |
| `boss.possessedSmith` Martillo del Herrero | Herrero poseído (4) | hoja | pueblo |
| `boss.witch` Escoba de la Bruja | Bruja del pozo (6) | empuñadura | pueblo |
| `boss.ogre` Piedra de molino | Ogro (6) | hoja | Huertos |
| `boss.alphaWolf` Colmillo Alfa | Lobo alfa (7) | guarda | Robleda |
| `boss.abbot` Rosario del Abad | Abad (8) | guarda | Cripta |
| `boss.warlord` Hoja del Señor de la Guerra | Señor de la guerra (9) | hoja | Pedregal |
| `boss.goblinKing` Corona del Rey Goblin | Rey Goblin (10) | guarda | trono |
| `legend.dawn` **Hoja del Alba (I)** | la entrega Aurora | hoja (mandoble) | final; **a la altura del tier 2** (`progresion.md` §6) |

El despertar de la Hoja (II…VI) con las Ascuas se implementa con el continente 2; en Valdemar basta con la (I).

## 3. Conjunto de armadura `*.valdemar` (opcional, P3)

"**Guardia de Valdehierro**": casco, peto, guantes y botas de cobre con tabardo azul y blanco (el del Capitán Vela).
Ids fijados por el world-designer: `helm.valdemar`, `chest.valdemar`, `gloves.valdemar`, `boots.valdemar`.

| Pieza | Cómo se consigue | Idea |
|---|---|---|
| `helm.valdemar` | Recompensa de `valdemar.pedregal` (Capitán) | yelmo abierto de cobre con penacho azul |
| `chest.valdemar` | Recompensa de `valdemar.abadia` (Fray Anselmo) | coraza de cobre con tabardo azul/blanco |
| `gloves.valdemar` | Recompensa de `valdemar.caza_mayor` (Bruno) | guanteletes de cobre con puño de cuero |
| `boots.valdemar` | Recompensa de `valdemar.molino` (Tomás) | botas de piel curtida con grebas de cobre |

Tier 1 con calidad alta (≈ ritual bueno). Bono de conjunto opcional (2 piezas: +4 % VIDA; 4 piezas: +1 REGEN.).
Si no da tiempo, las misiones dan oro y minerales y el conjunto queda para más adelante: no bloquea nada.
