# game_test_1 — guía para Claude

Juego pixel-art incremental para iPhone/iPad (horizontal) y Mac, en **SwiftUI + SpriteKit**.
Nombre provisional. Todo el texto que ve el jugador, los comentarios del código y la documentación
van **en español**.

## El juego en una frase

Un héroe chibi (4 razas) defiende el pueblo de Valdehierro: explora zonas, entra en casas, rescata
aldeanos y a la princesa; ataca solo al acercarse; los enemigos sueltan minerales y piezas; en la forja
del enano combina 3 piezas + minerales en un ritual con ruleta y despierta habilidades secretas.
Además hay una arena de oleadas infinitas. Diseño completo: `assets/design/GDD.md`.

## Estructura

```
.claude/agents/   Agentes especializados (ver "Organización")
src/
  GameTest1/      App iOS/Mac: App/ (GameStore), Game/ (SpriteKit), Views/ (SwiftUI), Art/ (pixel-art en código)
  GameCore/       Paquete Swift con la lógica pura + tests (razas, piezas, habilidades, bestiario, arena, pueblo, guardado)
assets/           Diseño por áreas: design/, maps/, characters/, art/, story/, balance/ (cada una con su responsable)
tools/Harness/    Banco de pruebas sin pantalla: simulación, balance, sprites, mapas, capturas, fichas
docs/AGENTES.md   Cómo usar los agentes
project.yml       Proyecto Xcode (XcodeGen) — el .xcodeproj se regenera, no se versiona
```

- `src/` dice **cómo** está hecho el juego (fuente de verdad de lo que se juega).
- `assets/` dice **qué** queremos y por qué. Las fichas marcadas como generadas salen de `src/` con `make fichas`.
- Piezas clave del código: `CombatScene` (combate compartido) → `BattleScene` (arena) y `ExploreScene` (pueblo);
  `BattleSession` / `ExploreSession` hacen de puente con SwiftUI; `ShopModel` = forja del enano;
  mapas como texto en `src/GameCore/Sources/GameCore/Town.swift`.

## Organización: quién se ocupa de qué

| Área | Agente | Diseño en `assets/` | Código que toca |
|---|---|---|---|
| Dirección, GDD, tareas | `game-designer` | `design/` | — (no implementa) |
| Mapas, zonas, interiores | `map-designer` | `maps/` | `Town.swift` |
| Razas, enemigos, aldeanos, jefes | `character-designer` | `characters/` | `Race`, `Enemy`, `Parts` (jefes), `EnemyArt.spec` |
| Pixel-art y animación | `pixel-artist` | `art/` | `src/GameTest1/Art/` |
| Historia y diálogos | `story-writer` | `story/` | textos en `Town.swift`, `ExploreSession`, nombres |
| Números y economía | `balance-designer` | `balance/` | `Enemy`, `Arena`, `Parts`, `Item`, `Ability` |
| Mecánicas, pantallas, sistemas | `game-programmer` | (GDD) | `src/` |
| Pruebas | `qa-tester` | — | — (informa) |

Para una petición grande o ambigua, empieza por `game-designer`: devuelve un plan con encargos para cada
especialista (marcando qué puede ir en paralelo) y actualiza `assets/design/tareas.md`. Después se lanzan
los especialistas con esos encargos y, al final, `qa-tester`. Cambios pequeños y claros pueden ir directos
al especialista.

## Comandos

```bash
make test          # tests de GameCore (rápido)
make check-town    # flujo del pueblo: diálogos, rescates, castillo, muerte
make balance       # arena: oleada en la que cae un bot con distintos equipos
make sprites       # hojas de sprites → tools/Harness/output/
make maps          # mapas del pueblo e interiores → tools/Harness/output/
make shots         # capturas de la escena (pueblo, interiores, arena) → tools/Harness/output/
make fichas        # regenera las fichas de assets/ desde el código
make verify        # test + check-town + compilar Mac e iOS (hacerlo antes de dar algo por terminado)
make project       # regenerar GameTest1.xcodeproj (OBLIGATORIO tras añadir/quitar/renombrar ficheros)
make mac           # compilar y abrir la versión de Mac
```

- Xcode 27 está en `/Applications/Xcode.app`, pero `xcode-select` puede seguir apuntando a las
  Command Line Tools: si `xcodebuild` falla, antepón `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- Simulador: iPhone 18 Pro `2DAD959D-AB6D-453E-9716-D90DE50F72FA`, bundle `com.sergimartinez.gametest1`.
  `xcrun simctl install/launch` y `xcrun simctl io <id> screenshot` funcionan sin el panel.
- Para **ver** un cambio visual: `make sprites|maps|shots` y abre el PNG con la herramienta Read.

## Convenciones

- Swift 5 (no modo 6), iOS 17 / macOS 14, `@Observable`. El código de la app compila también en macOS:
  lo específico de iOS va con `#if os(iOS)` (joystick, hápticos) y lo de Mac con `#if os(macOS)` (teclado).
- **La lógica va en GameCore con tests**; la app solo dibuja y conecta. Si añades reglas, añade tests.
- **Partidas guardadas**: `PlayerProfile` es Codable. Los campos nuevos deben ser **opcionales**
  (como `townProgress` o `arenaBestWave`). Los `id` de enemigos, NPC, zonas y spawns no se renombran.
- **Pixel-art**: sprites como filas de caracteres + paleta (`PixelSprite`), compuestos por capas en
  `PixelGrid` con `.outlined()` para el contorno. Un único tamaño de pixel `PX` para todo el mundo.
  Guía de estilo y referencias en `assets/art/`.
- **Mapas como texto** (`Town.swift`): un carácter por casilla de 24 px; leyenda en `assets/maps/README.md`.
- Cualquier cambio de números → `make balance` y comparar con `assets/balance/README.md`.
- Commits solo cuando el usuario lo pida. Versiones etiquetadas: `v0.1`, `v0.2`.
