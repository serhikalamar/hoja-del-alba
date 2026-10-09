# Rocaforja · Bestiario (15 monstruos + 4 jefes)

Familias de Rocaforja (`continentes.md`): kóbolds, trogloditas, gólems y elementales de piedra, bestias de montaña,
Clan Hollín; más el Eclipse con estética local. Ids camelCase en inglés, **nuevos y únicos** (ninguno de los 50 de
Valdemar). Estadísticas **base** comparables a las de Valdemar (la fórmula de nivel ya multiplica): son una propuesta
con el formato de `Enemy.swift` (`hp`, `dmg`, `speed`, `cd`, `range`, `radius`, `scale`, `drop`, `rolls`); las
afina el `balance-designer` contra los objetivos de `progresion.md` §7.

Dónde van en el código: **al final de `Bestiary.all`** (`Enemy.swift`), bajo el comentario "Monstruos de continente", detrás
de `eclipseAcolyte` (Valdemar), con un subcomentario `// Rocaforja`. La arena no los ve: usa solo
`Arena.originalEnemyIDs` (los 50 originales) y sus 10 jefes. `emberAcolyte` es la versión local del
`eclipseAcolyte` de Valdemar (mismo papel, estética de ceniza y fuego negro).

Plantillas de dibujo actuales (`EnemyArt.Body`): `goblin, human, skeleton, brute, rat, dog, boar, bird, bat, slime,
ghost`. **Ningún bicho necesita cuerpo nuevo**; sí accesorios nuevos (marcados ★).

## Monstruos normales

| Id | Nombre | Nivel | Comport. | Plantilla | Stats propuestas | Dónde | Aspecto (para el pixel-artist) |
|---|---|---|---|---|---|---|---|
| `kobold` | Kóbold minero | 10 | melee | `goblin` | hp 40, dmg 10, speed 60, cd 1.2, radius 13, drop 0.5 | Pastos, Canteras, Minas | Pequeño, piel gris parda (0x8A7A6A), hocico de rata ★`snout`, orejas redondas, casco de minero con vela ★`candle` apagada, pico ★`pickaxe`. |
| `koboldCandle` | Kóbold de la vela | 10 | melee (rápido) | `goblin` | hp 30, dmg 8, speed 80, cd 1.0, radius 12, drop 1.0, rolls 2 | Pastos, Canteras, Minas | Igual que el kóbold pero con **una vela enorme encendida** en el casco (llama amarilla, luz). Lleva un saquito de topacios: es la "piñata" del continente. Frase de ambiente: "¡No toques mi vela!". |
| `mountainGoat` | Cabra montesa | 10 | charger | `boar` | hp 45, dmg 12, speed 80, cd 2.4, radius 15, drop 0.5 | Pastos, Cumbres | Pelaje blanco sucio (0xE8E0D0), barba, ★`horns` curvos grandes. Embiste. |
| `cliffBear` | Oso de las cumbres | 12 | melee | `brute` | hp 110, dmg 16, speed 50, cd 1.6, radius 20, scale 1.3, drop 0.9, rolls 2 | Pastos (pinar) | Oso pardo de pie (0x6A4A30), hocico ★`snout`, ★`fur` en hombros, zarpas claras. Élite ligera. |
| `koboldGeomancer` | Geomante kóbold | 12 | ranged | `goblin` | hp 30, dmg 12, speed 45, cd 2.4, range 180, drop 0.6 | Canteras, Minas | Kóbold con túnica parda, collar de piedras ★`beads` existe, báculo con un cristal de cobalto; lanza piedras (proyectil marrón). |
| `trogg` | Troglodita | 13 | melee | `brute` | hp 70, dmg 13, speed 55, cd 1.3, radius 17, scale 0.95, drop 0.6 | Canteras, Minas | Piel gris azulada (0x6A7A8A) con costras de piedra, encorvado, garrote de estalactita; ojos amarillos sin pupila. |
| `troggBrute` | Troglodita bruto | 14 | melee (élite) | `brute` | hp 150, dmg 20, speed 45, cd 1.8, range 14, radius 22, scale 1.4, drop 1, rolls 2 | Canteras, Minas | Trogg enorme con placas de roca en la espalda y una roca atada a un palo como maza. |
| `cliffEagle` | Águila de las cumbres | 14 | charger (en picado) | `bird` | hp 45, dmg 14, speed 110, cd 2.0, radius 14, scale 1.2, drop 0.5 | Cumbres | Águila parda con cabeza blanca (0x5A3A20 / 0xF0F0F0), pico amarillo. |
| `rockGolem` | Gólem de piedra | 15 | melee (lento, aguanta) | `brute` | hp 140, dmg 16, speed 35, cd 1.8, radius 20, scale 1.3, drop 0.9 | Cumbres, Minas | Cuerpo de bloques grises (0x8A8A86) con runas cian que brillan (0x6FE0E0) ★`runes`. |
| `earthElemental` | Elemental de tierra | 15 | melee | `slime` | hp 80, dmg 13, speed 50, cd 1.2, radius 16, scale 1.2, drop 0.7 | Cumbres, Escoriales, Minas, Forja | Montículo de tierra y piedras que rueda, con dos ojos de brasa. En los Escoriales, variante de paleta "escoria" (negro y naranja) con el mismo id. |
| `emberAcolyte` | Acólito de la brasa | 15 | ranged | `human` | hp 45, dmg 14, speed 50, cd 2.2, range 190, radius 15, drop 0.6 | Cumbres (ermita), Escoriales, Minas, Forja | **El Eclipse local**: capucha gris ceniza (0x5A5A5A) con ribete naranja, farol con llama negra ★`lantern`; dispara chispas negras. |
| `hollinWarrior` | Guerrero Hollín | 16 | melee | `human` (scale 0.9) | hp 95, dmg 15, speed 55, cd 1.2, radius 15, scale 0.9, drop 0.7 | Escoriales, Fortaleza, Forja | Enano ★`beard` negra trenzada, armadura de hierro negro (0x3A3A40) con ribetes rojos (0xA02A2A), hacha. Ojos naranjas. |
| `hollinRifleman` | Arcabucero Hollín | 17 | ranged | `human` (scale 0.9) | hp 55, dmg 18, speed 40, cd 2.8, range 230, radius 15, scale 0.9, drop 0.7 | Escoriales, Fortaleza, Forja | Enano con barba ★`beard`, gafas ★`goggles` (existe), arcabuz ★`rifle`; disparo lento y fuerte (bala con humo). |
| `hollinPyromancer` | Piromante Hollín | 18 | ranged | `human` (scale 0.9) | hp 60, dmg 16, speed 45, cd 2.4, range 190, radius 15, scale 0.9, drop 0.8 | Fortaleza, Forja | Enana con barba corta, delantal de forja de cuero, guantes y un **fuelle** que escupe fuego negro ★`bellows`. |
| `ironConstruct` | Autómata de hierro fundido | 18 | melee (élite) | `brute` | hp 180, dmg 22, speed 45, cd 1.8, range 14, radius 22, scale 1.45, drop 1, rolls 2 | Escoriales, Fortaleza, Forja | Gigante de hierro remachado ★`rivets` (0x6A6A70), horno en el pecho con fuego negro, chimenea en la cabeza que echa humo. |

## Jefes (no reaparecen; cada uno suelta su pieza `boss.<id>`, ver `piezas.md`)

| Id | Nombre | Nivel | Comport. | Plantilla | Stats propuestas | Dónde | Pieza | Aspecto |
|---|---|---|---|---|---|---|---|---|
| `koboldChief` | Jefe Mechacorta | 13 | melee | `goblin` | hp 1500, dmg 26, speed 60, cd 1.4, range 14, radius 28, scale 2.2 | Canteras (campamento NE) | `boss.koboldChief` Cadena de la vagoneta | Kóbold gordo con un casco hecho de vagoneta y **una vela gigante** ★`candle` encendida; arrastra una cadena con un ancla de mina. |
| `peakRoc` | Roc de las Cumbres | 16 | charger | `bird` | hp 1700, dmg 30, speed 105, cd 2.0, radius 30, scale 2.4 | Cumbres (Nido) | `boss.peakRoc` Pluma del Roc | Águila gigante gris tormenta (0x6A7080) con una **brasa negra** clavada en el ala (brilla). |
| `cobaltColossus` | Coloso de cobalto | 17 | melee | `brute` | hp 2400, dmg 32, speed 40, cd 2.0, range 18, radius 36, scale 2.5 | Minas profundas (piso `mine`) | `boss.cobaltColossus` Pico de cobalto vivo | Gólem enorme de roca con **cristales de cobalto** ★`crystals` (0x2F5BD0) saliendo de hombros y espalda; corazón de fuego negro. |
| `thaneDurgan` | Thane Durgan Hollín | 20 | melee | `human` | hp 3200, dmg 36, speed 55, cd 1.4, range 16, radius 30, scale 2.0 | Forja Profunda (piso `forge`) | `boss.thaneDurgan` Yunque Negro | Enano corpulento ★`beard` gris y negra trenzada con anillas, armadura de Thane negra y roja, corona de hierro, **martillo-yunque** enorme ★`anvilHammer`; una grieta en el peto deja ver el fuego negro del pecho. |

## Resumen para el pixel-artist

- **Reutilizan cuerpo**: `goblin` (4 kóbolds), `brute` (trogg ×2, oso, gólem, autómata, coloso), `human` (acólito,
  3 Hollín, Durgan), `boar` (cabra), `bird` (águila, Roc), `slime` (elemental).
- **Accesorios nuevos ★**: `snout`, `candle` (apagada/encendida/gigante), `pickaxe`, `horns`, `fur`, `runes`,
  `lantern`, `beard` (puede salir del arte de la raza enana del héroe), `rifle`, `bellows`, `rivets`, `crystals`,
  `anvilHammer`.
- **Proyectiles nuevos**: piedra (geomante), chispa negra (acólito), bala con humo (arcabucero), llamarada negra (piromante).
- El "fuego negro" de todo el continente: negro/violeta muy oscuro (0x1A1020) con borde naranja (0xE07020).
