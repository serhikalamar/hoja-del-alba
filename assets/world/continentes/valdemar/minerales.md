# Valdemar · minerales

Familia fijada por el `world-designer` (`continentes.md`, `progresion.md` §5). Ids y bonificaciones **no cambian**
(son los de `Mineral.swift`). El lead decide color, frase y dónde sale más cada uno.

| Rareza | Id | Nombre | % al soltar | Bonificación (actual, por unidad) | Color (icono) | Frase | Dónde sale más |
|---|---|---|---|---|---|---|---|
| Común A | `copper` | Cobre | 35 % | +2 ATQ | naranja cobrizo #C8763A | "Cobre de las vetas del Plata: el primer filo de todo herrero." | Todo el continente; pueblo y Huertos |
| Común B | `iron` | Hierro | 27 % | +2 DEF | gris acero #8A8F96 | "Hierro de las colinas: pesa, pero aguanta." | Pedregal y Robleda (campamento bandido) |
| Poco común | `silver` | Plata | 20 % | +5 % VEL. ATAQUE | plata azulada #C9D3DC | "Plata bendecida: los muertos le temen." | Abadía y Cripta (no-muertos) |
| Rara | `gold` | Oro | 12 % | +4 % ORO | oro cálido #E2B33C | "Oro del reino. Llama a más oro." | Campamento bandido, Campamento orco, cofres de misiones |
| Muy rara | `emerald` | Esmeralda | 6 % | +0,4 REGEN. | verde hoja #3FA65A | "La joya de Valdemar: guarda el verde de los prados." | Jefes, Cripta (premio al ganar), Huerto de los monjes |

## Reglas para el código (M6)

- En las áreas de `valdemar` (y en sus interiores y mazmorras de historia) `Mineral.roll` usa **solo estos 5** con los
  pesos 35/27/20/12/6. Diamante, amatista, rubí, zafiro y mithril **dejan de salir** en la historia.
- "Dónde sale más" se implementa, si se quiere, con un **sesgo por área** pequeño (×1,5 al peso del mineral marcado
  en esa área). Es opcional (P2); sin él vale con la tabla plana.
- La **arena** sigue con sus 10 minerales y su tabla de siempre.
- Escasez: se mantiene `Mineral.dropRateMultiplier = 0,3`; los jefes siempre sueltan algo.
- Los jefes finales y mazmorras sueltan "adelanto" del continente siguiente: **solo cuando exista Rocaforja**
  (el Rey Goblin y la Cripta, 10 % de `cobalt`/`tin`). Hasta entonces, nada.

## Recompensas de NPC que hay que cambiar (fuera de la familia)

| NPC (`Town.swift`) | Hoy | Propuesta |
|---|---|---|
| Fray Anselmo (`anselmo`) | `silver` ×4, `sapphire` ×2 + `head.mace.silver` | `silver` ×5, `emerald` ×1 + la misma pieza |
| Bruno (`bruno`) | `gold` ×3, `ruby` ×1 | `gold` ×3, `iron` ×3 |
| Iris (`iris`) | `amethyst` ×3, `diamond` ×1 | `emerald` ×2, `silver` ×2 |
| Princesa Aurora (`princess`) | `mithril` ×2, `diamond` ×2 + `legend.dawn` | `gold` ×4, `emerald` ×3 + `legend.dawn` (lo fija el brief) |

Las cantidades las cierra el `balance-designer`; lo importante es que no salga nada de fuera de la familia.
