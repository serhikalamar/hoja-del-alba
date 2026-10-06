# Tablero de tareas

Lo mantiene `game-designer`. Cada tarea tiene un **agente responsable**, un estado y, si hace falta, de qué depende.
Los especialistas marcan su tarea como hecha y anotan el resultado en una línea.

Estados: `pendiente` · `en curso` · `bloqueada` · `hecha`

## En curso / próximas

| # | Tarea | Responsable | Estado | Depende de | Notas |
|---|---|---|---|---|---|
| 1 | Pasar al juego el mapa definitivo del Mundo 1 | `map-designer` | bloqueada | Mapa del usuario en `maps/borradores/` | |
| 2 | Escribir la historia del Mundo 1 a partir de la biblia | `story-writer` | pendiente | Decisiones del usuario (origen del héroe, villano) | |
| 3 | Diálogos nuevos de aldeanos según la historia | `story-writer` | pendiente | 2 | |
| 4 | Diseño propio para cada jefe (no solo paleta) | `character-designer` → `pixel-artist` | pendiente | | |

## Hechas

| # | Tarea | Responsable | Resultado |
|---|---|---|---|
| — | Pueblo explorable con casas, aldeanos y castillo | `game-programmer` | v0.3 |
| — | Arena de oleadas infinitas | `game-programmer` + `balance-designer` | v0.3 |
| — | Héroe chibi con diseño por raza y animaciones | `pixel-artist` | v0.3 |
| — | Organización por agentes: src/, assets/, tools/ y 8 agentes | `game-designer` | v0.3 |
