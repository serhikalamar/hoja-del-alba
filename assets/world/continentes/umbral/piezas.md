# Umbral · piezas, formas, armadura y la Hoja del Alba (VI)

Responsable: `continent-lead` de `umbral` (diseño) → `character-designer`/`game-programmer` (datos), `pixel-artist`
(dibujo), `balance-designer` (números). **Fase futura.**
Ids y elementos **fijados** en `continentes.md`; aquí, forma, estadísticas orientativas y aspecto.
Tier de Umbral: **6**, el máximo (mithril · escama de dragón · piel de dragón · tela de estrellas; `power` 5,6).
La forja del Bastión (Brokk) vende tier 6 con todas las formas, nuevas y antiguas.

## 1. Formas nuevas

Se añaden **al final** de `WeaponShape`, `GuardShape` y `GripShape` (no se reordena nada). Estadísticas base "por
tier 1": las multiplica el `power` del material, como las actuales.

| Ranura | Id | Nombre de la pieza | Elemento | `baseStats` orientativo | Por qué | Aspecto |
|---|---|---|---|---|---|---|
| Hoja / cabeza | `staff` | Orbe de báculo | Arcano | `Stats(attack: 11, attackSpeed: -0.05, range: 22, critChance: 0.04)` | El arma de más alcance del juego: golpea desde lejos pero suave. Completa Arcano, que no tenía hoja | Asta larga de madera clara (la empuñadura sigue siendo la empuñadura) rematada en un aro de metal que sujeta un orbe que brilla; al golpear, un arco de luz |
| Guarda | `dragon` | Guarda de dragón | Fuego | `Stats(attack: 2, critMultiplier: 0.1)` | Dos cabezas de dragón que muerden: golpes críticos que queman | Cruceta con dos cabezas de dragón hacia fuera, fauces abiertas, gema roja en el centro |
| Empuñadura | `star` | Empuñadura estelar | Sagrado | `Stats(attackSpeed: 0.05, regen: 0.3)` | Ligera y bendita: algo de ritmo y de cura | Mango envuelto en tela de estrellas, pomo en forma de estrella de cinco puntas que brilla |

- **Proyectil mágico del Báculo** (opcional, `encargos.md` M-U6): cada 3 ataques con una hoja `staff`, sale un orbe hacia
  el enemigo más cercano (≤ 180 px) que hace el 60 % del golpe. Sin esto, el Báculo es un golpe en arco de mucho alcance
  (ya funciona).
- Nombres en la tienda: "Orbe de báculo de mithril", "Guarda de dragón de mithril", "Empuñadura estelar de escama de
  dragón".
- Combinaciones: Arcano + Fuego = `meteor` (existe); Fuego + Sagrado = `sunfire` (propuesta de Cenizas); **Arcano +
  Sagrado no existe**: propuesta `constellation` (§5).

## 2. Piezas únicas de jefe (`boss.<id>`)

≈1,5× una pieza normal de tier 6 del mismo hueco (`progresion.md` §6), más una habilidad única. Estadísticas en el
estilo de `PartCatalog.specialParts` (las de Valdemar), a recalibrar por el `balance-designer`. Paletas (claro ·
medio · oscuro) para el `pixel-artist`. Ids de habilidad nuevos (no chocan con los existentes ni con los de otros
continentes).

| Id | Nombre | Ranura · forma | Elementos | Estadísticas (idea) | Paleta | Habilidad |
|---|---|---|---|---|---|---|
| `boss.dragonMatriarch` | Ala de Nixara | Guarda · `dragon` | Fuego, Viento | `Stats(attack: 9, attackSpeed: 0.1, critMultiplier: 0.3)` | `#FFE8A0` · `#E0A030` · `#6A3A10` | `dragon_breath` **Aliento de dragón**: cada 5 ataques, un cono de fuego delante (×1,5) que quema. |
| `boss.voidWarden` | Báculo de la Grieta | Cabeza · `staff` | Arcano, Sombra | `Stats(attack: 70, range: 26, critChance: 0.05, lifesteal: 0.04)` | `#D8C8FF` · `#7A4AE0` · `#1A0A30` | `void_siphon` **Sifón del vacío**: los críticos abren una grieta que roba vida a los enemigos cercanos (3 s). |
| `boss.starHerald` | Astrolabio de Corvino | Empuñadura · `star` | Sagrado, Hielo | `Stats(attackSpeed: 0.15, critChance: 0.06, regen: 1.2)` | `#F0FFFF` · `#A0B8F0` · `#2A3A6A` | `astral_lens` **Lente astral**: cada 6 ataques, 3 esquirlas de luna caen sobre enemigos al azar y los ralentizan. |
| `boss.grandHerald` | Velo del Eclipse | Guarda · `crown` | Sombra, Arcano, Sagrado | `Stats(attack: 14, critChance: 0.1, critMultiplier: 0.25, lifesteal: 0.03)` | `#FFF0C0` · `#C09030` · `#0A0614` | `eclipse_veil` **Velo del eclipse**: al bajar del 30 % de vida, 3 s de invisibilidad (los enemigos pierden el blanco) cada 30 s; +10 % crítico. |
| `boss.morvath` | Martillo del Herrero Hueco | Cabeza · `hammer` | Fuego, Sombra, Tierra | `Stats(maxHP: 60, attack: 125, defense: 10, attackSpeed: -0.25, critMultiplier: 0.5)` | `#FFB060` · `#3A3040` · `#0A0610` | `hollow_hammer` **Martillo hueco**: cada enemigo abatido carga el martillo; con 10 cargas, el siguiente golpe hace temblar la isla (×3 en área grande). |

- El **Martillo del Herrero Hueco** es la pieza del endgame (se repite la banda para conseguirla): hecho con los pedazos
  del Molde del Ocaso que Morvath se soldó al brazo. Es la alternativa a la Hoja del Alba (VI): más golpe, menos ritmo.
- `void_siphon` reutiliza `critExplosion` + `lifesteal`; `astral_lens` = rayos/pulso + `slow`; `dragon_breath` = pulso
  frontal + `burn`; `eclipse_veil` y `hollow_hammer` piden un efecto nuevo pequeño (`encargos.md` M-U7). Si no se hace,
  `eclipse_veil` queda en "+10 % crítico y +3 % robo de vida" y `hollow_hammer` en "cada 6 ataques, terremoto ×2".

## 3. Hoja del Alba (VI) — `umbral.sexta_brasa`

- Viene de la (V) de Escarcha (despertada con la **Corona de Esquirlas**). Se despierta en la Forja del Último Yunque
  (Brokk) con **dos objetos de historia**: el **Ascua de Escarcha** y el **Ascua de Umbral**, recuperados de Vesper en
  `umbral.gran_heraldo`. Con ellas la Hoja arde con **seis brasas** (Valdemar, Rocaforja, Lunaria, Cenizas, Escarcha,
  Umbral): es la **llave** completa (Cenizas).
- Estadísticas: a la altura de una pieza de jefe de **tier 6** (×1,5), como cada despertar (`mundo.md` §5); propuesta
  ×1,6 por ser la última: queda **un poco por encima** del Martillo de Morvath en ATQ por segundo y por debajo en golpe.
- Habilidad: `dawn` gana **"Alba plena"**: cada 6 ataques, seis rayos de luz (uno por brasa) caen alrededor (×0,8 cada
  uno). *Opcional* (M-U2): +25 % de daño contra `morvath` y los Heraldos (`starHerald`, `grandHerald`) y es la que
  reenciende los braseros en la fase 3 de la banda.
- Aspecto: el filo se vuelve blanco-dorado con **seis vetas** de colores (verde esmeralda, cobalto, plata lunar, rojo
  ceniza, cian, dorado), la guarda se abre en forma de sol y la luz palpita despacio.
- Cómo guardarlo: lo que decida el `game-programmer` en Rocaforja (`dawnAwakening` o piezas `legend.dawnN`): aquí, nivel 6.

## 4. Conjunto de armadura del Alba (opcional) — "Panoplia del Alba"

Ids fijados: `helm.umbral`, `chest.umbral`, `gloves.umbral`, `boots.umbral`. El conjunto de la última guardia de la
Alianza: mithril, piel de dragón y tela de estrellas, blanco y dorado con el sol del Alba. Se venden en la forja del
Bastión (tier 6) y salen de las secundarias (`zonas.md` §6).

| Id | Nombre | Ranura | Material | `base` orientativo | Cómo se consigue | Aspecto |
|---|---|---|---|---|---|---|
| `helm.umbral` | Yelmo del Alba | Casco | metal | `Stats(maxHP: 10, defense: 4, critChance: 0.02)` | `umbral.enmascarados` | Yelmo abierto de mithril con un sol dorado en la frente y dos alas pequeñas |
| `chest.umbral` | Coraza de escamas de dragón | Peto | cuero | `Stats(maxHP: 26, defense: 7, lifesteal: 0.01)` | `umbral.herreros_huecos` | Escamas doradas superpuestas, cinturón ancho, capa corta índigo |
| `gloves.umbral` | Guanteletes estelares | Guantes | metal | `Stats(attack: 2, attackSpeed: 0.05)` | `umbral.chatarra_celeste` | Guanteletes de mithril con constelaciones grabadas que brillan |
| `boots.umbral` | Botas de tela de estrellas | Botas | tela | `Stats(moveSpeed: 10, regen: 0.2)` | `umbral.cielo_en_calma` | Botas altas de tela índigo con estrellas bordadas, punteras doradas |

Tema: equilibrado (un poco de todo), como la Alianza. Bono de conjunto si existe el sistema que propone Rocaforja
(propuesta: 2 piezas +5 DEF; 4 piezas +5 % de daño). Si no, sin bono.

## 5. Propuestas

- Combinación nueva **Arcano + Sagrado** (no existe en `AbilityBook`): `constellation` "Constelación": cada 5 ataques,
  una estrella cae sobre el enemigo más fuerte cerca (×1,6) y cura un 2 % al héroe. Sale al combinar `staff` con `star`.
- **Mithril escalado por continente** en la historia (`minerales.md`).
- La forja del Bastión vende el tier 6 desde el principio (es el último tier); tras el final no hay tier 7: el
  progreso del endgame son la calidad del ritual, el mithril y el Martillo de Morvath.
