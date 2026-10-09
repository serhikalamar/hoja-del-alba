# Escarcha · piezas, formas y armadura

Responsable: `continent-lead` de `escarcha` (diseño) → `character-designer`/`game-programmer` (datos),
`pixel-artist` (dibujo), `balance-designer` (números). **Fase futura.**
Ids y elementos **fijados** en `continentes.md`; aquí, forma, estadísticas orientativas y aspecto.
Tier de Escarcha: **5** (glacita · ébano · cuero sombrío · seda lunar; `power` 4,4).

## 1. Formas nuevas

Ninguna necesita mecánica nueva (golpe en arco). Se añaden **al final** de `WeaponShape`, `GuardShape` y
`GripShape` (no se reordena nada). Las estadísticas base son "por tier 1": las multiplica el `power` del material,
como las actuales.

| Ranura | Id | Nombre de la pieza | Elemento | `baseStats` orientativo | Por qué | Aspecto |
|---|---|---|---|---|---|---|
| Hoja / cabeza | `halberd` | Hoja de alabarda | Hielo | `Stats(attack: 15, attackSpeed: -0.15, range: 14, critMultiplier: 0.1)` | Entre la lanza (alcance) y el mandoble (golpe): el arma de los caballeros del norte | Asta larga, hoja de hacha curva + punta de lanza + gancho trasero; filo con escarcha |
| Guarda | `frost` | Guarda escarchada | Hielo | `Stats(defense: 1, critMultiplier: 0.08)` | El frío vuelve quebradizo al enemigo: críticos más fuertes | Cruceta recta con carámbanos colgando de los extremos, cristal en el centro |
| Empuñadura | `fur` | Empuñadura forrada | Viento | `Stats(maxHP: 5, attackSpeed: 0.05)` | Agarre caliente: aguantas más y no se te escurre | Mango envuelto en piel blanca con cordones de cuero y un colmillo de pomo |

Con esto **Hielo** tiene hoja y guarda propias (antes solo la glacita y el `iceSlime` daban Hielo). Combinan con
las habilidades ya existentes: Hielo + Viento no tiene combinación hoy (propuesta abajo).

Nombres en la tienda: "Hoja de alabarda de glacita", "Guarda escarchada de glacita", "Empuñadura forrada de ébano".
La forja de Hielomar (Ragna) vende tier 5 con las formas nuevas y las antiguas.

## 2. Piezas únicas de jefe (`boss.<id>`)

≈1,5× una pieza normal de tier 5 del mismo hueco (`progresion.md` §6), más una habilidad única. Paletas
(claro · medio · oscuro) para el `pixel-artist`. Habilidades nuevas: ids propuestos (el `game-programmer` las añade a
`AbilityBook` como las de los jefes de Valdemar).

| Id | Nombre | Ranura · forma | Elementos | Estadísticas (idea) | Paleta | Habilidad |
|---|---|---|---|---|---|---|
| `boss.yetiPatriarch` | Zarpa del Abuelo Ventisca | Empuñadura · `fur` | Hielo, Viento | vida, vel. ataque, regen. | `#F4FAFF` · `#B8C8D8` · `#5A6A80` | `blizzard` **Ventisca**: cada 4 ataques, torbellino helado alrededor que ralentiza un 40 %. |
| `boss.shardHorror` | Témpano de la Sima | Cabeza · `spear` | Hielo, Arcano | ATQ, alcance, crítico | `#F0FFFF` · `#8FD8F0` · `#3C6CB0` | `shatter` **Fractura**: los golpes ralentizan; los críticos estallan en esquirlas alrededor. |
| `boss.giantJarl` | Mazo de Hrimgar | Cabeza · `hammer` | Hielo, Tierra | mucho ATQ, DEF, vel. ataque baja | `#D8F0FF` · `#6A9AC8` · `#2A3E5A` | `avalanche` **Alud**: cada 4 ataques, onda de choque helada que ralentiza; +40 vida. |
| `boss.wallCommander` | Guarda del Juramento Roto | Guarda · `frost` | Hielo, Sagrado | DEF, crítico, regen. | `#FFFFFF` · `#C0C8DC` · `#4A5A8A` | `broken_oath` **Juramento roto**: cada enemigo abatido te cura un 3 % y ralentiza a los cercanos. |
| `boss.brokenQueen` | Alabarda de la Luna Rota | Cabeza · `halberd` | Hielo, Arcano, Sagrado | ATQ, alcance, robo de vida, crítico | `#F0FFFF` · `#A0B8F0` · `#5A3A9A` | `moonfall` **Caída lunar**: cada 3 ataques, lluvia de esquirlas (×3) que ralentiza; +6 % robo de vida. |

La **Alabarda de la Luna Rota** es la pieza más buscada del continente (como la Corona del Rey Goblin en Valdemar).

## 3. Hoja del Alba (V)

- Viene de la (IV) de Cenizas. Se despierta en la forja de Hielomar (Brokk, misión `escarcha.quinta_luz`) con la
  **Corona de Esquirlas** (objeto de historia, no es una pieza: no se equipa ni se vende), no con el Ascua de
  Escarcha, que Corvino vierte en el Molde del Ocaso y se lleva al cielo (ver `historia.md` §7.1).
- Estadísticas al nivel del tier 5 × 1,5, como cada despertar (`mundo.md` §5). Propuesta: al despertar en Escarcha,
  la Hoja gana el elemento **Hielo** (luz fría de la Luna), que se suma a Sagrado/Tormenta/Fuego.
  A confirmar con el `world-designer` y el lead de Rocaforja (que implementa el sistema de despertar). Con la idea de
  Cenizas (la Hoja es una **llave**), la Corona es lo que "talla" la llave para la puerta del Yunque.

## 4. Conjunto de armadura de Hielomar (opcional)

Ids fijados: `helm.escarcha`, `chest.escarcha`, `gloves.escarcha`, `boots.escarcha`. Estilo de los balleneros
del norte: pieles, cuernos y remaches. Se venden en la forja de Hielomar con materiales de tier 5.

| Id | Nombre | Ranura | Material | `base` orientativo | Aspecto |
|---|---|---|---|---|---|
| `helm.escarcha` | Yelmo astado de Hielomar | Casco | metal | `Stats(maxHP: 8, defense: 3, regen: 0.1)` | Yelmo redondo con dos cuernos cortos y borde de piel blanca |
| `chest.escarcha` | Pelliza de oso polar | Peto | cuero | `Stats(maxHP: 20, defense: 5, regen: 0.3)` | Jubón de cuero oscuro con capa corta de piel de oso (cabeza en el hombro) |
| `gloves.escarcha` | Manoplas de ballenero | Guantes | cuero | `Stats(defense: 2, attackSpeed: 0.04)` | Manoplas gruesas con cordel de arpón |
| `boots.escarcha` | Botas de raqueta | Botas | cuero | `Stats(maxHP: 8, defense: 1, moveSpeed: 6)` | Botas altas de piel con raquetas de nieve trenzadas |

Tema del conjunto: aguantar (vida + regeneración), coherente con la *soledad* del continente: el que viaja solo
por el hielo tiene que curarse solo. Sin bonificación de conjunto (el motor no la tiene).

## 5. Propuestas

- Combinación de habilidades nueva **Hielo + Viento** (no existe en `AbilityBook`): `north_wind` "Viento del
  norte" (no "Tormenta de nieve": se confundiría con `frozen_storm` "Tormenta helada"): cada 4 ataques, ventisca alrededor que ralentiza. Aparece al combinar `halberd`/`frost` con `fur`/viento.
  Es opcional; decide el `game-programmer` con el `balance-designer`.
