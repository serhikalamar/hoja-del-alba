# Lunaria · piezas, formas y armadura

Responsable: `continent-lead` de `lunaria`. **Fase futura.** Formas fijadas por el `world-designer` (`continentes.md`).
Tier de material **3**: plata (metal) · fresno (madera) · piel de lobo (cuero) · seda (tela). No hay materiales
nuevos.

## 1. Formas nuevas (se añaden al final de cada enum en `Parts.swift`)

| Enum | Id | Nombre de la pieza | Elemento | Forma (para `pixel-artist`, `WeaponArt`) | Dónde se consigue |
|---|---|---|---|---|---|
| `WeaponShape` | `glaive` | Guja | Viento | Hoja larga y curva en lo alto de un asta corta, como una media luna alargada; filo con grabado de hojas | Forja de Velaluna (Fendril), botín de `witheredBlade`, `savia_negra` |
| `GuardShape` | `leaf` | Guarda de hojas | Veneno | Dos hojas de plata abiertas hacia los lados, con nervios marcados | Forja de Velaluna, botín de `thornling`/`treant` |
| `GripShape` | `moon` | Empuñadura lunar | Arcano | Mango de fresno envuelto en seda azul, con un pomo en forma de luna creciente | Forja de Velaluna, botín de `wisp`/`forestSpirit` |

Ninguna pide mecánicas nuevas: la guja es un golpe en arco como las demás (alcance algo mayor, como la lanza; lo
decide el `balance-designer`).

## 2. Tiendas de las capitales

| Capital | Quién | Qué vende |
|---|---|---|
| Velaluna (forja élfica) | **Maese Fendril** (y Brokk hace el ritual) | Piezas de metal y madera tier 3 (plata, fresno), con las formas élficas `glaive`, `leaf`, `moon` además de las de siempre. Tras `lunaria.pacto_de_la_luna`, también tier 4 (`progresion.md` §4). |
| Colmillo Gris (curtiduría) | **Hirsa** | Armadura de cuero y tela tier 3 (piel de lobo, seda) y empuñaduras forradas. *Necesidad de motor* N2: segunda tienda por continente (sin ritual). |

## 3. Piezas únicas de jefe (`boss.<id>`, ≈1,5× una pieza tier 3 + su habilidad; números: `balance-designer`)

| Pieza | Jefe | Tipo y forma | Elemento | Habilidad nueva (id fijado por el world-designer; efectos que ya existen; números: B) |
|---|---|---|---|---|
| `boss.rottenElder` · **Corteza del Abuelo Fresno** | `rottenElder` | Guarda `leaf` | Veneno | `elder_bark` **Corteza vieja**: +2 vida/s y +8 DEF; los golpes envenenan (0,3). ("Espinas que devuelven daño" no existe en el motor: no usarlo.) |
| `boss.blackClaw` · **Garra de la Mala Luna** | `blackClaw` | Guarda `claw` | Sangre | `bad_moon` **Mala Luna**: +6 % robo de vida y +15 % velocidad de ataque. |
| `boss.broodMother` · **Huso de la Madre Tejedora** | `broodMother` | Empuñadura `moon` | Veneno (excepción al Arcano de la forma: es "seda envenenada") | `silk_snare` **Lazo de seda**: los golpes ralentizan un 30 % y envenenan (0,4). |
| `boss.ysolde` · **Guja Lunamarchita** | `ysolde` | Hoja `glaive` | Arcano | `withered_moon` **Luna marchita**: los críticos estallan (×1,0) y +8 % crítico. |

## 4. Hoja del Alba (III)

Se despierta con la **brasa del Ascua de Lunaria** (el Ascua se queda en el Árbol Madre; la brasa es la recompensa de `lunaria.arbol_madre`) en la forja de Velaluna, hablando con
Brokk (`lunaria.pacto_de_la_luna`). Sube la Hoja al nivel del tier 3-4 (`progresion.md` §6). Visual: la hoja gana un
filo de luz azul-plata.

## 5. Conjunto de armadura `*.lunaria` (opcional; ids fijados)

`ArmorStyle(id, name, slot, materialKind, base: Stats)`. Se consiguen por **misiones** (`QuestReward.gearID`), no en la
tienda. Estadísticas base orientativas, en la escala de las actuales; B las ajusta.

| Id | Nombre | Hueco | Material | Base orientativa | Misión |
|---|---|---|---|---|---|
| `helm.lunaria` | Yelmo de la Guardia de las Copas | casco | metal | VIDA +8, DEF +2, VEL. ATAQUE +3 % | `lunaria.telaranas` (Sylra) |
| `gloves.lunaria` | Guantes de piel de luna | guantes | cuero | ATQ +2, ROBO DE VIDA +2 % | `lunaria.osolechuzas` (Hirsa) |
| `boots.lunaria` | Botas de paso silencioso | botas | cuero | DEF +2, VEL. MOVIMIENTO +6 | `lunaria.ruinas_de_selenar` (Thessa) |
| `chest.lunaria` | Coraza del Pacto | peto | metal | VIDA +20, DEF +6, REGEN. +1 | `lunaria.pacto_de_la_luna` (Elarith y Ulma) |

Aspecto: plata con grabado de hojas y una luna creciente; el peto mezcla la plata élfica con una piel de lobo al
hombro (el Pacto).
