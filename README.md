# game_test_1 (nombre provisional) · v0.3

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
make test      # tests de la lógica (GameCore)
make verify    # tests + flujo del pueblo + compilar Mac e iOS
make open      # genera el proyecto y lo abre en Xcode
make mac       # compila y abre la versión de Mac (WASD/flechas + ratón, Esc = pausa)
```

Para usar el panel del simulador desde Claude Code hace falta seleccionar Xcode una vez:
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

## Novedades de la v0.3: el pueblo explorable

- **Jugar = explorar Valdehierro**: un pueblo entero en vista 3/4 con cámara que sigue al héroe.
  Castillo con torres y reloj, plaza con fuente, barrios oeste y este, mercado con puestos y muralla sur.
- **Zonas** (Puerta sur, Mercado, Barrio oeste, Barrio este, Plaza mayor, Patio del castillo): cada una con
  sus enemigos y su dificultad. Los enemigos esperan hasta verte (y no ven a través de muros).
  Al limpiar una zona se libera y da oro. Los enemigos muertos no reaparecen.
- **Casas en las que se entra**: panadería, casa de la tejedora, del molinero, capilla, posada y alquimista.
  Dentro hay monstruos (algunos jefes) y un **aldeano atrapado**: despeja la sala y habla con él para rescatarlo.
  Cada aldeano da recompensa y después aparece en la plaza.
- **Forja del enano**: su casa en el barrio este abre la tienda, el ritual y el inventario.
  La forja mejora sus piezas al liberar zonas y rescatar aldeanos.
- **El castillo** se abre al rescatar a los 6 aldeanos. En el salón del trono espera el Rey Goblin;
  al vencerlo, la **princesa Aurora** te entrega la pieza legendaria **Hoja del Alba** (habilidad *Amanecer*).
- Fuera de combate se recupera vida poco a poco. Si caes, vuelves a la puerta sur con todo lo conseguido.
- **Arena de oleadas infinitas** (menú → ARENA): cada oleada es más difícil y no hay final.
  Cada 2 oleadas se abre la forja del enano (tienda, ritual e inventario); entre las demás hay un respiro
  corto y la siguiente empieza sola. Cada 5 oleadas sale un jefe y cambia el escenario
  (calle, huertos, cementerio, murallas, molino, abadía, salón del trono…). Se guarda tu récord.
- Mismo tamaño de pixel para todo (héroe, arma, enemigos y pueblo): el arma ya va a escala del cuerpo.

### Cómo editar el mapa

El pueblo y los interiores están en `src/GameCore/Sources/GameCore/Town.swift` como texto,
un carácter por casilla de 24×24 pixeles:

| Carácter | Casilla | | Carácter | Casilla (interiores) |
|---|---|---|---|---|
| `.` `,` | hierba / hierba con flores | | `X` | pared |
| `#` | calle empedrada | | `_` `:` | suelo de madera / piedra |
| `=` | losas de plaza | | `r` | alfombra |
| `T` | árbol | | `s` `k` | estantería / horno |
| `w` | muralla | | `t` `z` `o` | mesa / cama / barril |
| `S` | escalinata | | `I` `Y` | columna / trono |
| `l` `b` | farola / arbusto | | `D` | salida |
| `m` `c` | puesto de mercado / cajas | | | |
| `F` `~` `f` | fuente / agua / valla | | | |

Los edificios, zonas, enemigos y aldeanos se colocan con coordenadas (columna, fila) en ese mismo fichero.
Los tests comprueban que todo esté en casillas pisables y que las puertas den a algún sitio.

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
src/GameTest1/   App iOS/Mac (SwiftUI + SpriteKit) y todo el pixel-art en código
src/GameCore/    Lógica del juego + tests
assets/          Diseño por áreas (GDD, mapas, personajes, arte, historia, balance)
tools/Harness/   Banco de pruebas: simulación, balance, sprites, capturas
.claude/agents/  Agentes de Claude Code que organizan cada área (ver docs/AGENTES.md)
```

## Balance de la arena

Simulado con un bot que persigue enemigos y nunca compra (oleada en la que cae):

| Equipo | Oleada |
|---|---|
| Inicial (espada de entrenamiento) | 5 (primer jefe) |
| Arma T2 Normal | 9 |
| Arma T3-T4 Fina | 12-13 |
| Arma T5 Excelente | 18-20 |
| Arma T6 Obra maestra | 25 |

Los valores están en `Arena.swift` (oleadas), `Enemy.swift` y `Parts.swift`.
