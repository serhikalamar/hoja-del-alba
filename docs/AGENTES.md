# Agentes del proyecto

El videojuego está organizado por **áreas**, y cada área tiene un agente de Claude Code responsable
(`.claude/agents/`) y una carpeta de diseño en `assets/`. Un agente director, `game-designer`, coordina:
convierte las ideas en diseño y reparte el trabajo entre los especialistas.

```
.claude/agents/
├── game-designer.md        Director: GDD, plan y reparto de tareas       → assets/design/
├── map-designer.md         Mapas, zonas, edificios, interiores           → assets/maps/
├── character-designer.md   Razas, enemigos, aldeanos, jefes              → assets/characters/
├── pixel-artist.md         Pixel-art y animaciones                       → assets/art/
├── story-writer.md         Historia, lore y diálogos                     → assets/story/
├── balance-designer.md     Números, dificultad y economía                → assets/balance/
├── game-programmer.md      Mecánicas, pantallas, sistemas, bugs          → src/
└── qa-tester.md            Pruebas y bugs (informa, no arregla)
```

## Cómo trabajan juntos

```
Tu idea ──► game-designer ──► plan en assets/design/tareas.md
                                  │
          ┌───────────────┬───────┴───────┬────────────────┐
     map-designer   character-designer  story-writer   game-programmer    (en paralelo si no se pisan)
          └───────────────┴───────┬───────┴────────────────┘
                            pixel-artist ──► balance-designer ──► qa-tester
```

1. **Peticiones grandes o ambiguas** («quiero un segundo mundo», «prepara la v0.4»): pide primero al
   `game-designer`. Actualiza el GDD y el tablero, y devuelve un plan con un encargo listo para cada agente,
   indicando qué puede ir en paralelo. Si hay decisiones que son tuyas, te las pregunta.
2. Claude lanza a los especialistas con esos encargos (los agentes no pueden lanzarse entre sí: coordina el
   hilo principal).
3. Cada especialista trabaja en su área, comprueba su trabajo (tests, renders, simulaciones) y marca su tarea
   en `assets/design/tareas.md`.
4. `qa-tester` cierra probándolo todo.

**Cambios pequeños y claros** pueden ir directos al especialista, sin pasar por el director.

## Ejemplos de peticiones

- «**game-designer**: quiero que el castillo tenga sótanos con mazmorras. Organízalo.»
- «Usa el **map-designer** para pasar al juego el mapa que he dejado en `assets/maps/borradores/`.»
- «**character-designer**: diseña un jefe nuevo para el molino, una araña gigante que lanza telarañas.»
- «Que el **pixel-artist** dé a cada jefe una silueta propia, siguiendo `assets/art/referencias/`.»
- «**story-writer**: el héroe es un caballero exiliado que vuelve a su pueblo natal. Escribe la historia.»
- «**balance-designer**: la arena se hace aburrida entre las oleadas 10 y 15.»
- «Pasa el **qa-tester** antes de cerrar la versión.»

## Documentos de cada área

| Carpeta | Documentos |
|---|---|
| `assets/design/` | `GDD.md` (visión, pilares, sistemas, decisiones), `tareas.md` (tablero), `catalogo.md` (piezas y habilidades, generado) |
| `assets/maps/` | `README.md` (formato y cómo preparar borradores), `valdehierro.md` (zonas y ruta), `borradores/` |
| `assets/characters/` | `razas.md`, `enemigos.md`, `aldeanos.md` (generados), `conceptos.md` (ideas) |
| `assets/art/` | `README.md` (guía de estilo), `referencias/` (tus imágenes de ejemplo) |
| `assets/story/` | `historia.md` (biblia del mundo) |
| `assets/balance/` | `README.md` (objetivos, mediciones e historial) |

## Herramientas compartidas

`tools/Harness/` compila el juego para macOS sin pantalla, para que los agentes **vean** el arte,
**simulen** partidas y **midan** el balance:

```bash
make check-town   # flujo del pueblo
make balance      # oleada de la arena en la que cae un bot con cada equipo
make sprites      # hojas de sprites            ┐
make maps         # mapas completos             ├→ tools/Harness/output/
make shots        # capturas en juego           ┘
make fichas       # regenera las fichas de assets/ desde el código
make verify       # tests + flujo del pueblo + compilar Mac e iOS
```

## Añadir un agente

Copia uno parecido de `.claude/agents/`, cambia `name` y `description` (es lo que Claude usa para elegirlo:
que sea concreta), qué ficheros y carpeta de `assets/` le tocan, y cómo comprueba su trabajo. Añádelo a la
tabla de `CLAUDE.md` y a la lista de especialistas de `game-designer.md`.
