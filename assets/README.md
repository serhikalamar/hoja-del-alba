# assets/ — diseño del juego por áreas

Aquí viven los documentos de diseño, las fichas y las referencias. Cada carpeta tiene un **agente responsable**
que la mantiene al día. El código del juego está en `src/`; estas carpetas dicen **qué** queremos y por qué,
y el código dice **cómo** está hecho.

| Carpeta | Responsable | Contenido |
|---|---|---|
| `design/` | `game-designer` | Documento de diseño (GDD), tablero de tareas, decisiones y catálogo de piezas/habilidades |
| `maps/` | `map-designer` | Mapas del mundo, zonas y rutas. `borradores/` para los mapas que prepares tú |
| `characters/` | `character-designer` | Razas, bestiario, aldeanos y jefes (fichas) |
| `art/` | `pixel-artist` | Guía de estilo y `referencias/` (imágenes de ejemplo) |
| `story/` | `story-writer` | Biblia del mundo e historia |
| `balance/` | `balance-designer` | Objetivos de dificultad y resultados de las simulaciones |

Los ficheros que empiezan con `<!-- Generado con make fichas -->` se crean desde el código: no se editan a mano,
se cambian los datos en `src/` y se ejecuta `make fichas`.
