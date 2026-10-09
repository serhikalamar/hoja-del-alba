# Rocaforja · piezas y equipo

Tier de material: **2** (hierro · cuero · cuero de jabalí · lana). Ids y elementos de las formas nuevas **fijados**
por el `world-designer` (`continentes.md`); aquí, estadísticas (propuesta, mismo formato que `Parts.swift`), aspecto,
piezas de jefe, la Hoja del Alba (II) y el conjunto `*.rocaforja`. Números finales: `balance-designer`.

## 1. Forja de Hondoyunque (La Gran Forja)

| Momento | Qué vende |
|---|---|
| Tras `rocaforja.prueba_del_thane` (antes, Hilda no deja forjar a Brokk) | Piezas y armaduras de **tier 2** + poción; las 3 formas nuevas entran en las ofertas |
| Tras `rocaforja.despertar` (`Continent.finalQuestID`) | También **tier 3** (plata, fresno, piel de lobo, seda), para llegar a Lunaria |

Antes de la misión 2 el héroe puede volver a forjar en Valdehierro (tier 2 tras `valdemar.paso_norte`): no se queda sin forja.

## 2. Formas nuevas (`WeaponShape.warpick`, `GuardShape.anvil`, `GripShape.chain`)

Se añaden **al final** de cada enum (los `rawValue` se guardan). Ninguna pide mecánica nueva (golpe en arco).
Deben salir en la forja de la historia de Rocaforja en adelante; **la arena no las ofrece** (sigue con las suyas,
para no cambiar su balance; propuesta: decidirlo el balance-designer).

| Id | Nombre de pieza | Hueco | Elemento | `baseStats` propuestas | Idea de juego | Aspecto (pixel-artist, `WeaponArt`) |
|---|---|---|---|---|---|---|
| `warpick` | "Pico de guerra" | hoja/cabeza | Tierra | `Stats(attack: 15, attackSpeed: -0.2, critChance: 0.04, critMultiplier: 0.25)` | Entre hacha y martillo: lento, perfora (crítico). Combina con el diamante (MULT. CRÍTICO). | Cabeza de pico enana: punta larga curva hacia abajo y martillo corto detrás; remaches. |
| `anvil` | "Guarda de yunque" | guarda | Fuego | `Stats(attack: 1, defense: 3, critMultiplier: 0.05)` | La guarda "tanque" del continente. | Guarda maciza con forma de yunque pequeño (cuerno a un lado), color del metal, una brasa en el centro. |
| `chain` | "Empuñadura de cadena" | empuñadura | Sangre | `Stats(range: 8, attackSpeed: -0.05, lifesteal: 0.01)` | Alcance con un poco de robo de vida: el arma "se lanza" un poco más lejos. | Mango envuelto en eslabones; dos eslabones cuelgan del pomo. |

Combinaciones de elementos que salen con lo nuevo (ya existen en `Ability.swift`, no hace falta crear):
Tierra + Fuego = `magma`; Sangre + Fuego = `fury`; Sangre + Tierra = `titan`. Rocaforja empuja hacia esas tres.

## 3. Piezas únicas de jefe (`specialParts`, ≈1,5× una pieza de tier 2 del mismo hueco, más su habilidad)

Ids `boss.<idDelJefe>`. Habilidades **nuevas** (añadir al final de las de jefe en `Ability.swift`), hechas con los
efectos que ya existen (quemar, ralentizar, rayo en cadena, veneno, cura al matar, rematar, bonos, "cada N ataques…",
críticos que estallan).

| Pieza | Jefe (nivel) | Hueco / forma | Tier | Elementos | Stats propuestas | Habilidad nueva |
|---|---|---|---|---|---|---|
| `boss.koboldChief` "Cadena de la vagoneta" | Jefe Mechacorta (13) | empuñadura `chain` | 2 | Sangre, Fuego | `Stats(attack: 4, range: 12, lifesteal: 0.02)` | `runaway_cart` "Vagoneta desbocada": cada 4 ataques, onda de fuego alrededor (×1,2) que quema; +4 % robo de vida. |
| `boss.peakRoc` "Pluma del Roc" | Roc de las Cumbres (16) | guarda `winged` | 2 | Viento, Tormenta | `Stats(attack: 3, attackSpeed: 0.15, critChance: 0.03)` | `skyfall` "Picado": cada 3 ataques, un rayo cae del cielo (×2) y salta a 2 enemigos. |
| `boss.cobaltColossus` "Pico de cobalto vivo" | Coloso de cobalto (17) | hoja `warpick` | 3 | Tierra, Arcano | `Stats(attack: 34, attackSpeed: -0.2, critChance: 0.06, critMultiplier: 0.4)` | `resonance` "Resonancia": los críticos estallan; cada 5 ataques, temblor alrededor. |
| `boss.thaneDurgan` "Yunque Negro" | Thane Durgan Hollín (20) | guarda `anvil` | 3 | Fuego, Sombra, Tierra | `Stats(attack: 6, defense: 8, critMultiplier: 0.15, lifesteal: 0.02)` | `black_fire` "Fuego negro": cada 3 ataques, explosión de fuego negro (×1,6) que quema; +10 DEF. |

Paletas (claro / medio / oscuro): Mechacorta 0xFFD070 / 0x8A6A4A / 0x3A2A1A (hierro oxidado con mecha);
Roc 0xF0F0F8 / 0x6A7080 / 0x2A2E3A; Coloso 0x9AC0FF / 0x2F5BD0 / 0x1A2A6A; Durgan 0xE07020 / 0x2A2030 / 0x0E0A12.

## 4. La Hoja del Alba (II) — `rocaforja.despertar`

- La `legend.dawn` (I) se **despierta** en la forja con la **brasa del Ascua de Rocaforja** (objeto de historia, no mineral; el Ascua se queda en su Cámara: `mundo.md` §5).
  Es el primer despertar: el motor hay que hacerlo aquí (`progresion.md` §6, "Necesidades de motor" en `encargos.md`).
- Propuesta: la (II) queda a la altura de una pieza de jefe de **tier 3** (para llegar a Lunaria) y la habilidad `dawn`
  gana "tiembla": las ondas sagradas también hacen un pequeño temblor (Tierra) cada 6 ataques. Aspecto: el filo
  gana una veta de cobalto y una runa naranja en la base.
- Cómo guardarlo sin romper partidas: un campo opcional en el perfil (p. ej. `dawnAwakening: Int?`, nil = I) y la
  pieza recalcula sus números desde ese nivel; o crear la pieza nueva `legend.dawn2` y cambiarla en el inventario.
  Lo decide el `game-programmer`.

## 5. Conjunto de armadura `*.rocaforja` — "Guardia de Hondoyunque" (opcional)

Ids fijados: `helm.rocaforja`, `chest.rocaforja`, `gloves.rocaforja`, `boots.rocaforja`. Tier 2 (hierro y cuero de
jabalí) con calidad alta. Paleta: hierro 0xB8BCC4 / 0x6A6E78, cuero 0x7A4A2A, ribetes de cobalto 0x2F5BD0.

| Pieza | Cómo se consigue | Idea |
|---|---|---|
| `helm.rocaforja` | `rocaforja.prueba_del_thane` (Hilda) | yelmo enano cerrado con nasal y cuernos cortos |
| `boots.rocaforja` | `rocaforja.osos_hambrientos` (Greta) | botas de cuero de jabalí con punteras de hierro |
| `gloves.rocaforja` | `rocaforja.crisoles_negros` (Edda) | guanteletes de forja (no se queman) |
| `chest.rocaforja` | `rocaforja.asalto_a_la_fortaleza` (Runa) | coraza de placas con el yunque de Hondoyunque grabado |

Bono de conjunto (si existe el de Valdemar, el mismo sistema): 2 piezas +4 DEF; 4 piezas +6 % VIDA.
Si no da tiempo, las misiones dan oro y minerales y el conjunto queda para más adelante.
