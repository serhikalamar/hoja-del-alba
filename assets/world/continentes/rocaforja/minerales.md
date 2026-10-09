# Rocaforja · Minerales

Ids, rareza, % y estadística principal **fijados** por el `world-designer` (`continentes.md`, `progresion.md` §5).
Aquí: color, descripción, dónde salen más y una propuesta de número (×1,6 de Valdemar en las planas; las de
porcentaje apenas suben). Los números finales, `balance-designer`. Escasos: los monstruos sueltan con probabilidad
×0,3 (`Mineral.dropRateMultiplier`); los jefes, siempre.

| Rareza | Id | Nombre | % (al soltar mineral) | Bonificación por unidad (propuesta) | Valor (oro) | Color (claro / medio / oscuro) | Descripción (texto del juego) |
|---|---|---|---|---|---|---|---|
| Común A | `cobalt` | Cobalto | 35 % | ATQ +3 (cobre: +2) | 4 | 0x6A9AF0 / 0x2F5BD0 / 0x1A2A6A | "Veta azul de las canteras. Endurece el filo." |
| Común B | `tin` | Estaño | 27 % | DEF +3 (hierro: +2) | 5 | 0xE0E4E8 / 0xB8BCC0 / 0x6A6E74 | "Metal blando que, aleado, aguanta cualquier golpe." |
| Poco común | `topaz` | Topacio | 20 % | ORO +5 % (oro: +4 %) | 10 | 0xFFE08A / 0xF0B030 / 0x9A6A10 | "Piedra color miel. Los kóbolds la guardan como un tesoro." |
| Rara | `runestone` | Piedra rúnica | 12 % | VEL. ATAQUE +6 % (plata: +5 %) | 18 | 0x9AF0F0 / 0x6FE0E0 runas sobre 0x5A6470 / 0x2A3038 | "Pizarra con runas de los Herreros Primeros. Aún zumba." |
| Muy rara | `diamond` | Diamante | 6 % | MULT. CRÍTICO +0,12 (**ya existe, no cambia**) | 50 (ya existe) | el actual del arte (blanco azulado) | La actual. |

## Dónde sale más

La tabla de botín es la del continente (M6). Para dar personalidad, **sesgos por monstruo** (opcional, si el motor
lo permite; si no, todos tiran la tabla del continente):

| Mineral | Sale más de… | Zonas |
|---|---|---|
| `cobalt` | `kobold`, `trogg`, `troggBrute`, `cobaltColossus` (3-5 seguros) | Canteras, Minas profundas |
| `tin` | `mountainGoat`, `cliffBear`, `hollinWarrior`, `ironConstruct` | Pastos, Escoriales, Fortaleza |
| `topaz` | `koboldCandle` (sesgo fuerte: es su "saquito"), `koboldChief` (2-3 seguros), botín Hollín | Pastos, Canteras, Escoriales |
| `runestone` | `rockGolem`, `earthElemental`, `koboldGeomancer`, `peakRoc` (1 seguro) | Cumbres, Minas profundas |
| `diamond` | jefes (`cobaltColossus` 25 %, `thaneDurgan` 2 seguros), recompensas de misión, `ironConstruct` (rarísimo) | Minas profundas, Forja Profunda |

Propuesta de recetas de la forja de Hondoyunque: las piezas de tier 2 piden `cobalt` + `tin` (como las de Valdemar
piden cobre + hierro); el ritual acepta cualquier mineral (como ahora).

**Ritmo de escasez** (orientativo): con ~250 monstruos en el continente, drop medio ~0,7 × 0,3 ≈ 52 minerales:
~18 cobalto, ~14 estaño, ~10 topacio, ~6 piedra rúnica, ~3 diamantes + los de jefes y misiones (~6 más).
Suficiente para 4-6 forjas buenas en el continente, como pide el GDD.

## En el código (para los encargos)

- `Mineral`: añadir **al final** `cobalt`, `tin`, `topaz`, `runestone` (el `diamond` ya existe). Con datos explícitos
  por mineral (`dropPercent`, `buffPerUnit`, `value`, rareza dentro de la familia), no por posición (`progresion.md` §8).
- `Continent` de Rocaforja: `minerals: [.cobalt, .tin, .topaz, .runestone, .diamond]` (orden = Común A … Muy rara;
  `ContinentLoot.familyWeights` ya reparte 35/27/20/12/6).
- **La arena no cambia**: `Mineral.roll` y la tienda de la arena deben seguir con los 10 originales (hoy usan
  `allCases`: filtrar a una lista `Mineral.arenaMinerals` como se hizo con `Arena.originalEnemyIDs`).
- Los sesgos por monstruo de la tabla de arriba son **opcionales** (necesitan un campo nuevo en `EnemyDefinition`, p.
  ej. `mineralBias: [Mineral: Double]`); sin él, todos tiran la tabla del continente y el juego funciona igual.
- Color e icono: `pixel-artist` (`Art/` iconos de mineral).
