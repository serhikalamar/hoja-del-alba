# Cenizas · piezas y equipo

Tier de material: **4** (obsidiana · hueso · cuero de troll · terciopelo). Ids y elementos de las formas nuevas
**fijados** por el `world-designer` (`continentes.md`); aquí, estadísticas (propuesta, formato de `Parts.swift`),
aspecto, piezas de jefe, la Hoja del Alba (IV) y el conjunto `*.cenizas`. Números finales: `balance-designer`.

## 1. Forja del Fortín (Tova Fundehierro)

| Momento | Qué vende |
|---|---|
| Desde `cenizas.desembarco` | Piezas y armaduras de **tier 4** + poción; las 3 formas nuevas entran en las ofertas |
| Tras `cenizas.cuarta_brasa` (`Continent.finalQuestID`) | También **tier 5** (glacita, ébano, cuero sombrío, seda lunar), para llegar a Escarcha |

Lunaria ya vende tier 4 al terminar (adelanto), así que se llega con algo. `storyForgeTier` de Cenizas: 4 → 5.

## 2. Formas nuevas (`WeaponShape.khopesh`, `GuardShape.sun`, `GripShape.scarab`)

Se añaden **al final** de cada enum (los `rawValue` se guardan). Golpe en arco: ninguna pide mecánica nueva. Salen en
las forjas de la historia desde Cenizas; la arena no las ofrece (como las de Rocaforja y Lunaria).

| Id | Nombre de pieza | Hueco | Elemento | `baseStats` propuestas | Idea de juego | Aspecto (pixel-artist, `WeaponArt`) |
|---|---|---|---|---|---|---|
| `khopesh` | "Hoja de jopesh" | hoja | Fuego | `Stats(attack: 12, attackSpeed: 0.05, critChance: 0.03, critMultiplier: 0.15)` | Espada curva equilibrada: entre la espada y el hacha, con algo de crítico. Combina con el ópalo de fuego (MULT. CRÍTICO). | Hoja en forma de hoz abierta (recta junto a la guarda y luego curvada hacia fuera), filo exterior; vetas naranja en la obsidiana. |
| `sun` | "Guarda solar" | guarda | Sagrado | `Stats(defense: 1, regen: 0.4, goldBonus: 0.03)` | Guarda de "aguante": regenera un poco y da algo de oro (tema de la piedra solar). | Disco con rayos cortos alrededor del arranque de la hoja; un granate en el centro. |
| `scarab` | "Empuñadura de escarabajo" | empuñadura | Veneno | `Stats(attackSpeed: 0.06, critChance: 0.015)` | Rápida y ligera: velocidad con un poco de crítico. | Mango vendado y pomo con un escarabajo de metal con las alas cerradas (verde-oro). |

Combinaciones de elementos: con lo nuevo salen sobre todo **Fuego + Sagrado**, **Fuego + Veneno** y **Sagrado +
Veneno**, que hoy **no tienen combo** en `Ability.swift` (se quedan en la habilidad de un solo elemento). Propuesta
(balance-designer, opcional) de tres combos nuevos hechos con efectos que ya existen:
- `sunfire` "Fuego solar" [Fuego, Sagrado]: quema (0,4) y cada enemigo abatido cura un 3 %.
- `pitch` "Brea ardiente" [Fuego, Veneno]: quema (0,3) y envenena (0,3); el veneno se acumula.
- `embalm` "Embalsamar" [Sagrado, Veneno]: envenena (0,4) y +1,5 vida/s.

## 3. Piezas únicas de jefe (`specialParts`, ≈1,5× una pieza de tier 4 del mismo hueco, más su habilidad)

Habilidades **nuevas** (al final de las de jefe en `Ability.swift`), hechas con efectos que ya existen.

| Pieza | Jefe (nivel) | Hueco / forma | Tier | Elementos | Stats propuestas | Habilidad nueva |
|---|---|---|---|---|---|---|
| `boss.ashTrollKing` "Fémur de Gorrak" | Gorrak (34) | empuñadura `pommel` | 4 | Sangre, Tierra | `Stats(maxHP: 40, attack: 6, regen: 1.5)` | `troll_blood` "Sangre de troll": +3 vida/s y cada enemigo abatido cura un 3 %. |
| `boss.colossalScorpion` "Aguijón Negro" | Aguijón Negro (36) | hoja `dagger` | 4 | Veneno, Sombra | `Stats(attack: 40, attackSpeed: 0.35, critChance: 0.08)` | `black_sting` "Aguijón negro": veneno muy potente que se acumula (0,7) y remata por debajo del 15 %. |
| `boss.sunHighPriest` "Disco del Sol Muerto" | Gran Sacerdote Solano (37) | guarda `sun` | 4 | Sagrado, Fuego | `Stats(attack: 10, defense: 4, regen: 1.0, critChance: 0.05)` | `solar_flare` "Llamarada solar": cada 4 ataques, onda de luz alrededor (×1,2) que quema; matar cura un 3 %. |
| `boss.ashEmperor` "Jopesh del Sol Invicto" | Severián (40) | hoja `khopesh` | 5 | Fuego, Sagrado, Sombra | `Stats(attack: 110, attackSpeed: 0.05, critChance: 0.08, critMultiplier: 0.4)` | `ashen_crown` "Corona de ceniza": los golpes queman (0,5), los críticos estallan (×1,0) y remata por debajo del 12 %. |

Paletas (claro / medio / oscuro): Gorrak 0xE8E0D0 / 0xA09880 / 0x4A4438 (hueso viejo con cuero rojo); Aguijón
0xFFE080 / 0x16141A / 0x0A080C (negro brillante con punta de oro); Solano 0xFFF4C0 / 0xE0B040 / 0x7A5010; Severián
0xFFC060 / 0xE04020 / 0x2A1A18 (obsidiana con filo de lava).

## 4. La Hoja del Alba (IV) — `cenizas.cuarta_brasa`

- Se despierta con la **brasa del Ascua de Cenizas** (el Ascua no sale del volcán: `mundo.md` §5) con el mismo sistema que hagan Rocaforja (II) y Lunaria (III).
- Propuesta: la (IV) queda a la altura de una pieza de jefe de **tier 5** (para llegar a Escarcha); la habilidad
  `dawn` gana "solar": los rayos de luz también **queman** (0,3). Aspecto: el filo se oscurece en la base como
  obsidiana y una veta roja de rubí sube por el centro.

## 5. Conjunto de armadura `*.cenizas` — "Legión del Oasis" (opcional)

Ids fijados: `helm.cenizas`, `chest.cenizas`, `gloves.cenizas`, `boots.cenizas`. Tier 4 (obsidiana y cuero de troll)
con calidad alta. Idea: los soldados del Fortín se han hecho armaduras con lo que sacan de las ruinas (estética de
legionario de Solarum, colores de la Alianza). Paleta: bronce 0xC08A3A / 0x7A5020, obsidiana 0x2A2228, tela
blanca 0xE8E0D0, ribete azul de la Alianza 0x3A6AC0.

| Pieza | Cómo se consigue | Idea |
|---|---|---|
| `boots.cenizas` | `cenizas.legion_perdida` (Dorna) | sandalias-bota de cuero de troll con grebas de bronce |
| `helm.cenizas` | `cenizas.tumba_de_solarum` (Thessa) | casco de legionario con cresta (azul en vez de roja) y velo de tela contra la arena |
| `gloves.cenizas` | `cenizas.corazones_de_magma` (Tova) | guanteletes de obsidiana que no se queman |
| `chest.cenizas` | `cenizas.el_heraldo` (Aurora) | coraza de escamas de bronce y obsidiana con un sol partido grabado |

Bono de conjunto (si existe el sistema): 2 piezas +8 DEF; 4 piezas +6 % VIDA y +1 vida/s.
Si no da tiempo, las misiones dan oro y minerales y el conjunto queda para más adelante.
