# Cenizas · Minerales

Ids, rareza, % y estadística principal **fijados** por el `world-designer` (`continentes.md`, `progresion.md` §5).
Aquí: color, descripción, dónde salen más y una propuesta de número (×3,3 de Valdemar en las planas, como el `power`
del tier 4; las de porcentaje apenas suben). Números finales: `balance-designer`. Escasos: los monstruos sueltan con
probabilidad ×0,3; los jefes, siempre.

| Rareza | Id | Nombre | % (al soltar mineral) | Bonificación por unidad (propuesta) | Valor (oro) | Color (claro / medio / oscuro) | Descripción (texto del juego) |
|---|---|---|---|---|---|---|---|
| Común A | `sulfur` | Azufre | 35 % | ATQ +7 (cobre: +2) | 8 | 0xFFF080 / 0xE8D040 / 0x9A8420 | "Piedra amarilla que apesta y arde con llama azul. Muerde el filo." |
| Común B | `garnet` | Granate | 27 % | VIDA +26 | 10 | 0xE05A6A / 0x8A1A2A / 0x4A0A14 | "Gotas de sangre de la tierra, endurecidas por el fuego del volcán." |
| Poco común | `sunstone` | Piedra solar | 20 % | ORO +5 % (oro: +4 %) | 20 | 0xFFE0A0 / 0xF0A030 / 0x9A5A10, con destello blanco | "Con ella pagaba Solarum. Aún guarda la luz de un sol que ya no existe." |
| Rara | `fireopal` | Ópalo de fuego | 12 % | MULT. CRÍTICO +0,09 (diamante: +0,12) | 35 | 0xFFB060 / 0xFF6A20 / 0x8A2A0A, con motas verdes 0x60E0A0 | "Dentro baila una llama que nunca se apaga." |
| Muy rara | `ruby` | Rubí | 6 % | CRÍTICO +3 % (**ya existe, no cambia**) | el actual | el actual del arte | La actual; nueva descripción propuesta: "Una gota del Ascua de Cenizas. Los emperadores la llevaban en la corona." |

## Dónde sale más

La tabla de botín es la del continente (`ContinentLoot`). Sesgos por monstruo **opcionales** (mismo campo que
proponga Rocaforja, p. ej. `mineralBias`); sin él, todos tiran la tabla del continente.

| Mineral | Sale más de… | Zonas |
|---|---|---|
| `sulfur` | `salamander`, `cinderCrab`, `fireElemental` | Costa (charcas), Laderas |
| `garnet` | `ashTroll`, `trollHexer`, `mummy`, `ashTrollKing` (2 seguros) | Dunas, Necrópolis |
| `sunstone` | `solarLegionary`, `sunPriest`, cofres del mausoleo y del palacio | Necrópolis, Sepultada |
| `fireopal` | `magmaGolem`, `fireElemental`, `sunHighPriest` (1 seguro), `ashHerald` (1 seguro) | Laderas, Tumba, Caldera |
| `ruby` | `ashEmperor` (1 seguro), `colossalScorpion` (25 %), `cenizas.los_murales`, `cenizas.emperador_ceniciento` | Caldera, Necrópolis |

Adelanto (`progresion.md` §5): la Caldera suelta además, con poca probabilidad, `quartz` y `rimeiron` (Escarcha).

**Recetas** de la forja del Fortín: las piezas de tier 4 piden `sulfur` + `garnet`; el ritual acepta cualquier
mineral (como ahora).

**Ritmo de escasez** (orientativo): ~450 monstruos con misiones × drop medio ~0,65 × 0,3 ≈ 88 minerales: ~31 azufre,
~24 granate, ~18 piedra solar, ~10 ópalo, ~5 rubíes + los de jefes, mazmorras y misiones (~12 más). Da para 5-7
forjas buenas en el continente (algo más que Rocaforja porque el continente es más largo).

## En el código (para los encargos)

- `Mineral`: añadir **al final** `sulfur`, `garnet`, `sunstone`, `fireopal` (el `ruby` ya existe) con datos
  explícitos (`dropPercent`, `rarityTier` dentro de la familia + extra por continente, `buffPerUnit`, `value`).
- `Continent` de Cenizas: `minerals: [.sulfur, .garnet, .sunstone, .fireopal, .ruby]` (orden = Común A … Muy rara).
- **La arena no cambia**: sigue con los 10 originales (`Mineral.arenaMinerals`, si Rocaforja/Lunaria ya lo crearon).
- Iconos y color: `pixel-artist`.
