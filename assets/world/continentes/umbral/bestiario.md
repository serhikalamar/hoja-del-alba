# Umbral · bestiario

Responsable: `continent-lead` de `umbral` (diseño) → `character-designer` (datos) → `pixel-artist` (arte) →
`balance-designer` (números). **Fase futura.**

Familias de Umbral (`continentes.md`): **dragones y dragonantes, criaturas del vacío, constructos celestes, élite del
Eclipse**, más los **siervos de Morvath** (herreros huecos). Ids en camelCase, únicos en todo el juego: ninguno choca
con los 50 actuales ni con los de Rocaforja, Lunaria, Cenizas y Escarcha (comprobado). `gargoyle` de Valdemar no se
usa (la gárgola estelar es otra). `starHerald` es el id de enemigo que Escarcha dejó para **Corvino** (allí es el NPC
`corvino`). La Hermana Brasa sigue siendo NPC de escena.

Estadísticas **base** comparables a las de Valdemar (la fórmula `stats(level:)` ya escala por nivel); orientativas, las
fija el `balance-designer` con simulación (`progresion.md` §7). Columnas como en `Bestiary.e(...)`: vida, daño,
velocidad, enfriamiento, alcance, radio, escala, prob. de soltar mineral.

## Monstruos normales (14)

| Id | Nombre | Nivel | Plantilla | Comport. | Vida | Daño | Vel. | CD | Alc. | Radio | Escala | Drop | Dónde | Aspecto (para el `pixel-artist`) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `skyConstruct` | Constructo celeste | 50 | `brute` | melee (lento) | 75 | 12 | 45 | 1.6 | 10 | 19 | 1.3 | 0.65 | Muelles | Gólem de mithril blanco y dorado, sin cara: una ranura con luz azul; runas que parpadean; un brazo-grúa |
| `starGargoyle` | Gárgola estelar | 50 | `bat` | melee (rápido) | 38 | 10 | 110 | 1.0 | 6 | 14 | 1.2 | 0.55 | Muelles | Gárgola de piedra índigo con constelaciones doradas en las alas; ojos de estrella |
| `cloudRay` | Raya de las nubes | 51 | `bird` | charger | 42 | 12 | 105 | 2.2 | 6 | 16 | 1.4 | 0.55 | Muelles, Nidos | Manta raya blanca y translúcida que "nada" en el aire; cola larga con chispa eléctrica |
| `dragonWhelp` | Cría de dragón | 52 | `bird` (→ `dragon`) | melee (muy rápido) | 32 | 9 | 125 | 0.8 | 6 | 12 | 0.9 | 0.5 | Nidos | Dragoncito dorado con manchas violetas (corrupción), alas pequeñas, cabezón; muerde |
| `drake` | Dragonante | 52 | `dragon` (provisional `boar`) | charger | 80 | 15 | 80 | 2.4 | 8 | 20 | 1.4 | 0.7 | Nidos | Dragón sin alas a cuatro patas, escamas cobrizas con grietas violetas; embiste con la cabeza acorazada |
| `stormDrake` | Dragonante de tormenta | 53 | `dragon` (provisional `bird`) | ranged | 50 | 13 | 60 | 2.4 | 180 | 17 | 1.3 | 0.65 | Nidos | Dragonante azul pizarra con alas membranosas rotas; escupe rayos (proyectil azul-blanco) |
| `fallenDragon` | Dragón caído | 54 | `dragon` (provisional `brute`) | melee (élite) | 170 | 22 | 50 | 2.0 | 16 | 32 | 1.9 | 0.9 (×2) | Nidos (cumbre), Islas Rotas, Grieta, Puente | Dragón del Vuelo adulto, oro ennegrecido, alas desgarradas que dejan ver el vacío; ojos violetas |
| `voidWalker` | Caminante del vacío | 54 | `ghost` | melee | 60 | 12 | 55 | 1.3 | 8 | 15 | 1.15 | 0.6 | Islas Rotas, Grieta | Silueta humanoide negra con estrellas violetas dentro (un "agujero" con forma de persona); bordes que se deshacen |
| `voidLurker` | Acechador del vacío | 54 | `ghost` | charger (rápido) | 40 | 13 | 130 | 1.8 | 6 | 13 | 1.0 | 0.55 | Islas Rotas, Grieta, banda | Bicho de cuatro patas larguísimas, negro, sin cara; una boca violeta vertical; se mueve a saltos |
| `voidEye` | Ojo del vacío | 55 | `ghost` (opcional `eye`) | ranged | 36 | 12 | 40 | 2.2 | 190 | 14 | 1.1 | 0.6 | Islas Rotas, Observatorio, Grieta, banda | Ojo enorme flotante, iris violeta, párpados de piedra rota; dispara "lágrimas" de vacío (proyectil violeta) |
| `voidZealot` | Enmascarado del vacío | 56 | `human` | melee (rápido) | 42 | 11 | 95 | 0.9 | 8 | 14 | 1.0 | 0.55 | Observatorio | Cultista del Eclipse de túnica índigo con estrellas negras, máscara de cristal, dos dagas violetas |
| `eclipseKnight` | Caballero del Eclipse | 56 | `human` | melee (tanque) | 95 | 15 | 55 | 1.3 | 12 | 17 | 1.2 | 0.75 | Observatorio, Puente, banda | Armadura negra con filos dorados, yelmo cerrado con un eclipse grabado (círculo negro con halo), espada larga y escudo |
| `eclipseProphet` | Profeta del Eclipse | 57 | `human` | ranged (élite) | 120 | 18 | 50 | 2.0 | 200 | 18 | 1.35 | 0.85 (×2) | Observatorio (patio, cúpula), Puente, banda | Túnica negra y dorada larga, capucha con corona de rayos, báculo con un eclipse; orbes de sombra lentos y grandes |
| `hollowSmith` | Herrero hueco | 58 | `brute` | melee (golpe fuerte) | 85 | 18 | 45 | 1.8 | 12 | 19 | 1.25 | 0.7 | Puente, banda | Herrero de la Alianza (humano o enano) con el pecho abierto y vacío, oscuro; delantal quemado, martillo de forja; brasas negras en los ojos |

Reparto por familia: constructos celestes (constructo, gárgola, raya) · dragones (cría, dragonante, de tormenta,
caído) · vacío (caminante, acechador, ojo) · élite del Eclipse (fanático, caballero, heraldo menor) · siervos de
Morvath (herrero hueco).

Mezcla por área: Muelles = melee lento + rápido + embestida (bienvenida) · Nidos = embestidas y disparos (dragones) ·
Islas Rotas = rápidos y a distancia sobre puentes estrechos (vértigo) · Observatorio = élites del Eclipse (tanque +
distancia) · Puente = golpes fuertes y lentos en pasillo (aguantar).

## Jefes (5)

Se definen con `Bestiary.boss(...)` (siempre sueltan; pieza `boss.<id>` automática). Permanentes (no reaparecen).

| Id | Nombre | Nivel | Plantilla | Comport. | Vida | Daño | Vel. | CD | Alc. | Radio | Escala | Dónde | Pieza que suelta |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `dragonMatriarch` | Nixara, Matriarca del Vuelo | 54 | `dragon` (provisional `boar`) | charger (+ aliento) | 2000 | 32 | 85 | 2.0 | 14 | 38 | 2.6 | `umbral.nidos.cumbre` | `boss.dragonMatriarch` · Ala de Nixara (guarda `dragon`) |
| `voidWarden` | El Guardián de la Grieta | 57 | `brute` (opcional `hollowTitan`) | melee (+ pulsos) | 2400 | 34 | 40 | 1.8 | 18 | 38 | 2.6 | Mazmorra `umbral.grieta` | `boss.voidWarden` · Báculo de la Grieta (cabeza `staff`) |
| `starHerald` | Corvino el Astrólogo | 58 | `human` | ranged | 2100 | 32 | 55 | 1.5 | 200 | 22 | 1.6 | `umbral.observatorio.cupula` | `boss.starHerald` · Astrolabio de Corvino (empuñadura `star`) |
| `grandHerald` | Vesper, la Gran Heraldo | 59 | `human` | ranged → melee (fase 2) | 2700 | 36 | 60 | 1.4 | 200 | 24 | 1.8 | `umbral.puente.puerta` | `boss.grandHerald` · Velo del Eclipse (guarda `crown`) |
| `morvath` | Morvath, el Herrero Hueco | 60 | `hollowTitan` (nueva) | melee → ranged → charger (3 fases) | 6000 | 42 | 45 | 1.8 | 20 | 44 | 3.2 | Banda `umbral.yunque` | `boss.morvath` · Martillo del Herrero Hueco (cabeza `hammer`) |

Aspecto y combate de los jefes:
- **Nixara**: dragona dorada enorme (la más grande antes de Morvath), cuello largo, corona de cuernos, vetas violetas
  que le suben desde el pecho. Embestida con aviso (raya en el suelo) y, cada 3 embestidas, **aliento de fuego** en
  cono (con aviso). Al 30 % invoca 2 `dragonWhelp`. Al caer: animación corta, deja de brillar violeta.
- **El Guardián de la Grieta**: coloso de mithril de los Herreros, con el pecho abierto y un **ojo del vacío** dentro
  (la luz violeta sale por las juntas). Golpes lentos; cada 5 golpes, **pulso del vacío** en anillo (aviso: el ojo se
  ilumina). Invoca 2 `voidEye` cada 30 s.
- **Corvino**: el de Escarcha (alto, túnica azul noche con estrellas, astrolabio de plata), ahora con la túnica
  rasgada y el astrolabio ardiendo. Se aleja y dispara **esquirlas de luna** en abanico de 3; cada 20 s se teletransporta
  junto a la Lente (fase opcional). Al caer, se vuelve estatua de cristal.
- **Vesper**: mujer alta, piel pálida, pelo negro con estrellas, vestido-armadura negro y dorado con un **velo** que
  le tapa los ojos, el **Molde del Ocaso** flotando a su espalda (piedra negra con dos vetas encendidas: naranja y
  cian). Fase 1 (100-50 %): `ranged`, orbes de sombra y lluvia de estrellas con aviso; invoca 2 `eclipseKnight`. Fase 2
  (≤50 %): vierte el Ascua de Umbral en el Molde (tercera veta, dorada), se quita el velo y pasa a `melee` con una hoja
  de luz negra, más rápida.
- **Morvath**: titán de metal negro, el triple de alto que el héroe, con una **forja apagada en el pecho** (un hueco
  con brasas grises), barba de cadenas, martillo de forja enorme en una mano y la **Hoja del Ocaso a medias** (pedazos
  del Molde soldados) en la otra. Sprite grande (ver "Plantillas").
  - **Fase 1 · El martillo** (100-66 %): `melee`, golpes lentos con aviso (círculo dorado de 0,8 s); cada 4 golpes,
    onda de choque alrededor del Yunque.
  - **Fase 2 · La escoria** (66-33 %): se queda sobre el Yunque y pasa a `ranged`: lanza bolas de escoria (proyectil
    grande, lento); invoca 2 `hollowSmith` cada 20 s.
  - **Fase 3 · La Hoja del Ocaso** (33-0 %): `charger`, +30 % de velocidad, embestidas con aviso. Cada 15 s apaga uno de
    los seis braseros de los Herreros (+5 % de daño por brasero apagado). *Opcional*: con la Hoja del Alba (VI)
    equipada, golpear cerca de un brasero apagado lo vuelve a encender.
  - Objetivo de duración: **3-4 min** (`progresion.md` §7), con daño de 25-30 % de la vida del héroe por golpe y aviso.

Escala respecto a Valdemar: mismo patrón (jefe ≈ 12-15× la vida de un normal de su nivel; Morvath ≈ 2,5× un jefe
final). Números exactos: `balance-designer` (jefe de zona 40-60 s, Guardián 60-90 s, Morvath 3-4 min).

## Plantillas y arte

- **`dragon`** (nueva, **P1** para Umbral): cuadrúpedo con alas, cuello y cola largos; sirve para `drake`,
  `stormDrake`, `fallenDragon`, `dragonWhelp` (pequeña) y `dragonMatriarch` (grande). Mientras no exista, las
  provisionales de la tabla (`boar`, `bird`, `brute`) para que se pueda jugar.
- **`hollowTitan`** (nueva, **P1** solo para Morvath; opcional para el Guardián): humanoide muy grande (sprite de 2×3
  casillas de 24 px aprox.), con pecho hueco animado. Albor (NPC, dragón 2×2) puede reutilizar `dragon` a escala.
- **`eye`** (opcional): ojo flotante; si no, `ghost` con un ojo pintado.
- Accesorios de `human` nuevos (opcionales): velo de Vesper, astrolabio de Corvino, yelmo del eclipse, delantal y
  martillo del herrero hueco, máscara de cristal del fanático.

Paleta del continente: índigo `#2A2A6A`, índigo claro `#5A5AC0`, dorado `#FFD870`, oro viejo `#C09030`, negro del
vacío `#0A0614`, violeta del vacío `#A070FF`, blanco estelar `#F4F4FF`. La corrupción siempre en violeta.

## Necesidades de motor (resumen; detalle en `encargos.md`)

- **Fases de jefe** (Vesper, Morvath): cambiar comportamiento/velocidad a un % de vida. Sin esto, Vesper es `ranged` y
  Morvath `melee` con más vida (jugable, menos épico).
- **Invocar esbirros** (Nixara, Guardián, Vesper, Morvath): el patrón que piden Escarcha y Cenizas.
- **Ataque en área con aviso** (aliento, pulso, onda): ya lo piden otros jefes; si no, son golpes normales.
- **Sprites grandes** (`dragon` grande, `hollowTitan`).
- **Braseros de la banda** (fase 3 de Morvath): opcional.
