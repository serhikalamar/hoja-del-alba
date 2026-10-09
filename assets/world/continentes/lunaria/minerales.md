# Lunaria · minerales

Responsable: `continent-lead` de `lunaria`. **Fase futura.** Ids, estadística y porcentaje **fijados** por el
`world-designer` (`continentes.md`, `progresion.md` §5). Aquí: color, descripción y dónde sale más. Números finos:
`balance-designer` (orientativo: estadísticas planas ×2,4 respecto a Valdemar; porcentajes casi igual).

Escasos: los monstruos sueltan mineral con probabilidad ×0,3; los jefes siempre. En las áreas de Lunaria
(`continentID = "lunaria"`) solo sale esta familia (`ContinentLoot`); la arena sigue con sus 10 originales.

| Id | Nombre | Rareza | % (al soltar mineral) | Bonificación al forjar | Color (paleta) | Frase (tienda / inventario) |
|---|---|---|---|---|---|---|
| `quicksilver` | Azogue | Común A | 35 % | ATQ | Plata líquida `#C9D1DC` con brillo blanco `#F4F7FA` | "Metal que corre como el agua. Las hojas que lo beben cortan más hondo." |
| `amber` | Ámbar | Común B | 27 % | VIDA | Miel `#E3A035` con corazón naranja `#B8661C` | "Savia de los árboles de plata, dura como piedra. Guarda el calor de la vida." |
| `jade` | Jade | Poco común | 20 % | REGEN. | Verde musgo pálido `#6DB58E`, vetas `#3F7D5C` | "Piedra de los claros. Quien la lleva cerca se cura como el bosque." |
| `moonstone` | Piedra lunar | Rara | 12 % | VEL. ATAQUE | Blanco azulado nacarado `#C4DDF2`, reflejo `#8FB4E0` | "Un pedazo de luz de luna que se quedó dormido. Rápida como un reflejo." |
| `amethyst` | Amatista | Muy rara | 6 % | ROBO DE VIDA | Violeta (la de siempre) | Ya existe. En Lunaria: "La piedra de la Mala Luna: bebe de la sangre que derrama." |

## Dónde sale más (sesgo de botín, si el motor lo permite; si no, la tabla de arriba vale para todo el continente)

| Mineral | Monstruos / sitios con más probabilidad | Por qué |
|---|---|---|
| Azogue | `moonSpider`, `webSpitter`, `witheredBlade`; Nido de las Tejedoras | Las arañas tejen hilo con azogue; armas élficas |
| Ámbar | `thornling`, `treant`, `glowcap`, `rottenElder` | Savia de los árboles |
| Jade | `forestSpirit`, `wisp`; Claros de la Luna | Piedra de los claros sagrados |
| Piedra lunar | `moonHowler`, `witheredArcher`; Lago; `broodMother` | Lo que queda de la luz de la luna |
| Amatista | `feralWerewolf`, `blackClaw`, `ysolde` | La Mala Luna y el robo de vida de los lobos |

Recompensas fijas (misiones y mazmorras): ver `zonas.md` (secundarias) y `encargos.md` (B). Jefes finales y
mazmorras sueltan además, con poca probabilidad, un común de Cenizas (`sulfur`, `garnet`) como adelanto.

Nota para el `game-programmer`: `quicksilver`, `amber`, `jade` y `moonstone` son **nuevos** en `Mineral` (se añaden
al final de la lista, con `rarityTier`/`value` explícitos por familia, `progresion.md` §8). `amethyst` ya existe y no
cambia de id ni de bonificación.
