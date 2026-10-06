# game_test_1 (nombre provisional)

Juego incremental pixel-art para iPhone/iPad en **horizontal**, hecho con **SwiftUI + SpriteKit**.

Eres un caballero que se enfrenta a oleadas de goblins. Solo mueves al personaje: cuando un monstruo
entra en tu alcance, atacas automáticamente con el arma equipada. Los monstruos sueltan minerales,
cada ronda te da oro y entre rondas aparece la tienda. En la forja combinas minerales para fabricar
armas y armaduras, y una ruleta decide la potencia final.

## Requisitos

| Herramienta | Para qué | Instalación |
|---|---|---|
| **Xcode 15+** (recomendado 16) | Compilar y ejecutar la app en el simulador o en el iPhone | App Store → Xcode, después `sudo xcode-select -s /Applications/Xcode.app` |
| **XcodeGen** | Generar `GameTest1.xcodeproj` desde `project.yml` | `brew install xcodegen` (ya instalado) |
| Command Line Tools | Ejecutar los tests de la lógica (`make test`) | ya instaladas |

## Primeros pasos

```bash
make test      # 16 tests de la lógica del juego (no necesita Xcode)
make open      # genera el .xcodeproj y lo abre en Xcode
```

En Xcode: elige un simulador de iPhone y pulsa ▶.

### Probar en el Mac

```bash
make mac       # compila y abre la versión de escritorio
```

O en Xcode: esquema **GameTest1Mac** → destino **My Mac** → ▶.
Controles: **WASD** o flechas para moverse, **Esc** para pausar y el ratón para todo lo demás. Para probar en tu iPhone, selecciona tu equipo en
*Signing & Capabilities* (con un Apple ID gratuito basta).

> El `.xcodeproj` no se versiona: si añades o renombras ficheros, ejecuta `make project` otra vez.

## Estructura

```
game_test_1/
├── project.yml                 # Definición del proyecto Xcode (XcodeGen)
├── Makefile
├── Packages/GameCore/          # Lógica pura en Swift, sin UI, con tests
│   ├── Sources/GameCore/
│   │   ├── Stats.swift         # Estadísticas del caballero (ATQ, DEF, crítico, robo de vida…)
│   │   ├── Mineral.swift       # 10 minerales: % de aparición y bonificación al forjar
│   │   ├── Item.swift          # Equipo, rarezas y catálogo de armas/armaduras (4 tiers)
│   │   ├── Monster.swift       # Tipos de goblin y escalado por nivel
│   │   ├── Level.swift         # Mundo 1: 10 niveles y sus oleadas
│   │   ├── Combat.swift        # Fórmulas de daño y defensa
│   │   ├── Shop.swift          # Ofertas de la tienda entre rondas
│   │   ├── Crafting.swift      # Recetas de forja y ruleta de calidad
│   │   ├── PlayerProfile.swift # Progreso persistente (oro, minerales, inventario, niveles)
│   │   └── SaveStore.swift     # Guardado en JSON
│   └── Tests/GameCoreTests/
└── GameTest1/                  # App iOS
    ├── App/                    # Punto de entrada y estado global (GameStore)
    ├── Game/                   # SpriteKit: escena de batalla, nodos y puente con SwiftUI
    ├── Views/                  # SwiftUI: menú, mapa, HUD, tienda, forja, ruleta, equipo
    ├── Art/                    # Pixel-art definido en código (sprites como mapas de caracteres)
    └── Resources/              # Assets (icono)
```

El pixel-art está definido en `GameTest1/Art/Sprites.swift` como filas de caracteres con una paleta.
Así se pueden crear variantes por color (los tipos de goblin o el color de la armadura del caballero)
sin depender de ficheros de imagen. Más adelante se pueden sustituir por sprites dibujados a mano.

## Mecánicas

### Combate
- Joystick flotante: tocas en cualquier punto de la pantalla y arrastras.
- El caballero ataca solo al goblin más cercano que esté a su alcance. El golpe barre un arco de unos
  145°: los demás goblins dentro del arco reciben el 75% del daño.
- Defensa: daño recibido × (1 − DEF / (DEF + 60)).
- Entre rondas recuperas un 25% de la vida. La poción de la tienda cura un 50%.
- Si caes, conservas el oro y los minerales conseguidos (es un juego incremental).

### Minerales (% de aparición cuando un monstruo suelta uno)

| Mineral | % | Bonificación por unidad |
|---|---|---|
| Cobre | 30 | +2 ATQ |
| Hierro | 22 | +2 DEF |
| Plata | 15 | +0.05 velocidad de ataque |
| Oro | 10 | +4% oro |
| Esmeralda | 8 | +0.4 vida/s |
| Zafiro | 6 | +3 alcance |
| Rubí | 4 | +3% crítico |
| Amatista | 3 | +2% robo de vida |
| Diamante | 1.5 | +12% daño crítico |
| Mithril | 0.5 | +12 vida, +2 ATQ, +2 DEF |

### Forja y ruleta
1. Eliges el tipo de objeto (los tiers se desbloquean en los niveles 1, 3, 6 y 9).
2. Añades entre 3 y 12 minerales.
3. La ruleta decide la calidad, que multiplica todas las estadísticas:
   Rota ×0.6 · Tosca ×0.8 · Normal ×1.0 · Fina ×1.2 · Excelente ×1.5 · Obra maestra ×2.0.
   Los minerales raros dan **suerte**, que aumenta la probabilidad de las casillas buenas.

### Mundo 1: Bosque Goblin
10 niveles de 3 a 6 rondas, con cada vez más goblins. Tipos: goblin, goblin veloz (desde el nivel 2),
goblin bruto (desde el 4, con mini-jefe en el 5) y el **Rey Goblin** como jefe final del nivel 10.

## Balance

El balance se ha ajustado simulando partidas completas sin interfaz con un bot que persigue a los
goblins y nunca compra nada. Para que el equipo de tienda sirva de referencia:

| Equipo (tier del nivel) | Niveles que gana el bot |
|---|---|
| Común | 1-3, 6, 9 |
| Raro | 1-4, 6-7, 9-10 |
| Épico | 1-7, 9-10 |

Los niveles 5 y 8 son picos de dificultad pensados para obligar a forjar o a repetir niveles.
Los valores están en `Monster.swift`, `Level.swift` e `Item.swift`.
