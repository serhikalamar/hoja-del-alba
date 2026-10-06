# game_test_1 (nombre provisional) · v0.2

Juego incremental pixel-art para iPhone/iPad en **horizontal** (y Mac para probar), hecho con **SwiftUI + SpriteKit**.

Defiendes el pueblo medieval de **Valdehierro** de oleadas de monstruos. Solo mueves al héroe: cuando un enemigo
entra en tu alcance, atacas automáticamente. Los enemigos sueltan minerales y los jefes, piezas únicas. Entre
rondas, el **enano herrero** te vende piezas de arma, y en el **ritual de forja** combinas tres piezas y minerales
para crear tu propia arma, que despierta una **habilidad secreta** según los elementos de sus piezas.

## Requisitos y comandos

| Herramienta | Para qué |
|---|---|
| Xcode 27 | Compilar y ejecutar en simulador, iPhone o Mac |
| XcodeGen (`brew install xcodegen`) | Generar `GameTest1.xcodeproj` desde `project.yml` |

```bash
make test      # 23 tests de la lógica (GameCore)
make open      # genera el proyecto y lo abre en Xcode
make mac       # compila y abre la versión de Mac (WASD/flechas + ratón, Esc = pausa)
```

Para usar el panel del simulador desde Claude Code hace falta seleccionar Xcode una vez:
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

## Novedades de la v0.2

- **Mundo 1: Pueblo de Valdehierro.** 10 niveles (Puerta del pueblo → Salón del trono goblin) con suelos
  distintos (adoquines, huertos, cementerio, castillo), casas de entramado de madera y ambiente de día,
  atardecer y noche con farolas.
- **Héroe chibi** (34×40, estilo caballero anime) con un diseño propio por raza: caballero de pelo negro,
  enano con casco de cuernos y barba, elfa rubia de orejas puntiagudas y hombre lobo con arnés y garras.
  La tela (tabardo/túnica) cambia de color con la armadura equipada.
- **Animaciones del héroe**: respiración con parpadeo, paso de 4 frames con rebote y polvo, golpe en tres fases
  (preparación, tajo y recuperación) con el arma siguiendo la mano, daño y muerte.
- **4 razas** con estadísticas distintas: Humano, Enano, Elfo, Hombre lobo.
- **50 enemigos nuevos**: 4 por nivel + 1 jefe por nivel. Tres comportamientos: cuerpo a cuerpo,
  a distancia (honderos, arqueros, magos…) y embestida (jabalíes, lobos, berserkers).
  Se construyen con 11 cuerpos detallados y accesorios (cascos, capuchas, coronas, armas).
  Ataques animados: se echan atrás con el arma en alto (aviso), golpean hacia delante y el daño llega en
  ese momento, así que se pueden esquivar. Al recibir golpes se aplastan y al morir salen despedidos.
- **Forja del enano** (tienda): el herrero vigila desde un lado mientras vende piezas, una armadura y pociones.
- **130 piezas de arma**: 54 hojas/cabezas (9 tipos × 6 metales), 36 guardas, 30 empuñaduras y
  10 piezas únicas de jefe (el Rey Goblin suelta la *Corona del Rey Goblin*).
- **Ritual de forja**: círculo rúnico con tres altares (hoja, guarda, empuñadura), minerales orbitando y ruleta.
- **Habilidades secretas** (38): 10 de un elemento, 18 combinaciones y 10 de jefe. Funcionan en combate:
  quemadura, veneno, ralentización, rayos en cadena, ondas, rayos del cielo, ejecuciones, explosiones…
- **Crea tu arma**: editor de pixel-art (lápiz, goma, cubo, cuentagotas, simetría, deshacer) para dibujar
  tu propia arma; si no, se usa el diseño generado a partir de las piezas.
- **Inventario**: armas, armaduras, piezas, minerales y códice de habilidades.

## Cómo funciona la habilidad secreta

Cada pieza tiene 1-2 elementos (del material y de la forma). Con las tres piezas del arma:
1. Si hay una **pieza de jefe**, el arma toma su habilidad única.
2. Si hay dos elementos de una **combinación** que sumen 3 o más piezas → esa combinación
   (p. ej. Fuego + Tierra = *Magma*).
3. Si un elemento se repite 2+ veces → su habilidad simple (p. ej. Fuego ×2 = *Llamarada*).

En el ritual se ven los elementos que llevas, pero la habilidad aparece como **???** hasta que la descubres.

| Metal (hoja/guarda) | Elemento | | Madera (empuñadura) | Elemento |
|---|---|---|---|---|
| Cobre | Tormenta | | Roble | Tierra |
| Hierro | Tierra | | Cuero | Sangre |
| Plata | Sagrado | | Fresno | Viento |
| Obsidiana | Fuego | | Hueso | Sombra |
| Glacita | Hielo | | Ébano | Arcano |
| Mithril | Viento | | Escama de dragón | Fuego |

## Estructura

```
Packages/GameCore/      Lógica pura + tests: razas, piezas, habilidades, bestiario, niveles, tienda, ritual, perfil
GameTest1/App/          Entrada y estado global (GameStore)
GameTest1/Game/         SpriteKit: escena, nodos (héroe, enemigos, proyectiles, botín), teclado de Mac
GameTest1/Views/        Menú, razas, mapa, HUD, forja del enano, ritual, revelación, editor, inventario
GameTest1/Art/          Pixel-art en código: héroe, enemigos, piezas de arma, pueblo procedural
```

## Balance

Ajustado simulando partidas completas sin pantalla con un bot que persigue enemigos y nunca compra.
Arma forjada con el mejor material disponible y unos cuantos minerales comunes:

| Calidad de la ruleta | Niveles que gana el bot |
|---|---|
| Normal ×1.0 | 1-3 (a veces 4) |
| Fina ×1.2 | 1-4, 9 |
| Excelente ×1.5 | 1-7, 9-10 |

El nivel 8 (Abadía abandonada) es el muro: pide buenas piezas, piezas de jefe o una buena habilidad.
Los valores están en `Enemy.swift`, `Level.swift` y `Parts.swift`.
