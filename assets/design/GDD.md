# Documento de diseño (GDD)

Responsable: `game-designer`. Estado: versión 0.3 (prototipo jugable, publicada). Nombre del juego: *pendiente*.

## Visión

Juego de acción incremental en pixel-art chibi (estilo JRPG de 16 bits, vista 3/4) para móvil en horizontal
y Mac. El jugador solo mueve al héroe: el ataque es automático. La profundidad está en **forjar armas propias**
combinando piezas, minerales y elementos, y en descubrir habilidades secretas.

## Pilares

1. **Moverse es jugar**: esquivar golpes avisados, elegir a quién acercarse, explorar.
2. **Forjar es progresar**: cada arma es única (piezas + minerales + ruleta + habilidad + dibujo propio).
3. **Descubrir**: habilidades secretas, piezas de jefe, casas por explorar, historia por desvelar.
4. **Siempre un paso más**: progresión incremental sin techo (arena infinita) y muros que piden mejorar el equipo.

## Bucle principal

Explorar / pelear → conseguir oro, minerales y piezas → forja del enano (comprar piezas, ritual) →
arma más fuerte → zonas más difíciles, rescates, jefes → piezas únicas → …

## Modos

| Modo | Descripción | Estado |
|---|---|---|
| Pueblo (historia) | Valdehierro explorable: 6 zonas, 6 casas con aldeanos, castillo con el Rey Goblin y la princesa | Hecho (prototipo) |
| Arena | Oleadas infinitas; forja cada 2 oleadas; jefe y escenario nuevo cada 5; récord | Hecho |

## Sistemas

| Sistema | Resumen | Código | Ficha |
|---|---|---|---|
| Héroe y razas | 4 razas con estadísticas propias y diseño chibi propio | `Race.swift`, `HeroArt.swift` | `characters/razas.md` |
| Combate | Ataque automático en arco; enemigos cuerpo a cuerpo, a distancia y de embestida con aviso | `CombatScene.swift`, `Nodes.swift` | — |
| Enemigos | 50 (4 por nivel + 10 jefes), cada jefe suelta una pieza única | `Enemy.swift`, `EnemyArt.swift` | `characters/enemigos.md` |
| Minerales | 10, con probabilidad de aparición y bonificación al forjar | `Mineral.swift` | — |
| Piezas | 120 normales (hoja, guarda, empuñadura × materiales) + 11 únicas | `Parts.swift`, `WeaponArt.swift` | `design/catalogo.md` |
| Ritual y ruleta | 3 piezas + minerales; la ruleta multiplica ×0,6 a ×2; la suerte la inclina | `Crafting.swift` | — |
| Habilidades | 39 secretas según los elementos de las piezas | `Ability.swift` | `design/catalogo.md` |
| Forja del enano | Tienda de piezas, armadura y pociones; mejora con el progreso | `Shop.swift`, `ShopModel.swift` | — |
| Pueblo | Mapas en texto, zonas, puertas, interiores, aldeanos, castillo | `Town.swift`, `ExploreScene.swift` | `maps/` |
| Editor de armas | El jugador dibuja su arma en pixel-art | `PixelEditorView.swift` | — |
| Guardado | Perfil en JSON; campos nuevos opcionales | `PlayerProfile.swift`, `SaveStore.swift` | — |

## Decisiones tomadas

| Fecha | Decisión | Motivo |
|---|---|---|
| 2026-10-06 | Ataque automático, el jugador solo se mueve | Juego de móvil, una mano, foco en la forja |
| 2026-10-06 | Todo el pixel-art se dibuja en código | Variantes por paleta, sin depender de ficheros de imagen |
| 2026-10-06 | Mismo tamaño de pixel para todo | El arma no cuadraba con el cuerpo |
| 2026-10-06 | El modo principal es un pueblo explorable, no niveles | Petición del usuario: zonas, casas, aldeanos, castillo |
| 2026-10-06 | La arena son oleadas infinitas | Progresión incremental sin final y para conseguir botín |

## Preguntas abiertas

- Nombre del juego.
- Historia completa (ver `story/historia.md`) y qué hay después de Valdehierro (Mundo 2).
- ¿Las razas tendrán habilidades propias además de estadísticas?
- ¿Misiones secundarias? ¿Sonido y música?
- Mapa definitivo del Mundo 1 (lo prepara el usuario → `maps/borradores/`).
