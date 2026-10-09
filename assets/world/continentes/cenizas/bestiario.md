# Cenizas · Bestiario (14 monstruos + 1 élite de historia + 4 jefes)

Familias de Cenizas (`continentes.md`): Solarum no-muerto (momias, legionarios, sacerdotes), elementales de fuego,
trolls de ceniza, escorpiones y salamandras; bestias comunes con variante de bioma (cangrejo, buitre, escarabajos) y
el Eclipse con estética local. Ids camelCase en inglés, **nuevos y únicos** (comprobado contra los 50 de Valdemar y
los bestiarios de Rocaforja y Lunaria). Estadísticas **base** comparables a las de Valdemar/Rocaforja (la fórmula de
nivel ya multiplica), con el formato de `Enemy.swift` (`hp`, `dmg`, `speed`, `cd`, `range`, `radius`, `scale`,
`drop`, `rolls`): propuesta que afina el `balance-designer` contra `progresion.md` §7.

Dónde van en el código: **al final de `Bestiary.all`** (`Enemy.swift`), en la sección "Monstruos de continente", con
un subcomentario `// Cenizas`, detrás de Lunaria. La arena no los ve (usa `Arena.originalEnemyIDs` y sus 10 jefes).
`ashAcolyte` es la versión local del `eclipseAcolyte` de Valdemar y del `emberAcolyte` de Rocaforja.
★ = accesorio nuevo de `EnemyArt` (o plantilla nueva) para el pixel-artist.

## Monstruos normales

| Id | Nombre | Nivel | Comport. | Plantilla | Stats propuestas | Dónde | Aspecto (para el pixel-artist) |
|---|---|---|---|---|---|---|---|
| `ashScorpion` | Escorpión de ceniza | 30 | melee | ★`scorpion` (nueva) | hp 34, dmg 9, speed 80, cd 1.0, radius 14, drop 0.5 | Costa, Dunas | Escorpión gris ceniza (0x5A5A60) con pinzas grandes y cola curvada sobre el lomo, aguijón rojo brasa (0xE04020). Corre de lado. |
| `cinderCrab` | Cangrejo de escoria | 30 | melee (lento, aguanta) | ★`crab` (nueva) | hp 55, dmg 8, speed 45, cd 1.3, radius 15, drop 0.55 | Costa, faro | Cangrejo negro con costras de escoria naranja (0x2A2626 / 0xC06020) en el caparazón, ojos en palito. Anda de lado. |
| `salamander` | Salamandra | 31 | ranged (escupe fuego) | `rat` (o ★`lizard`) | hp 28, dmg 10, speed 60, cd 2.0, range 160, radius 12, drop 0.5 | Costa, Laderas, Caldera | Lagarto bajo y largo, rojo (0xC03018) con lomo de brasas amarillas (0xFFC040), cola larga ★`tail`; escupe una bola de fuego. |
| `ashVulture` | Buitre de ceniza | 32 | charger (en picado) | `bird` | hp 26, dmg 10, speed 125, cd 1.8, radius 12, drop 0.4 | Costa (cabo), Dunas | Buitre gris oscuro (0x3A3638) de cuello pelado rosado (0xC08080) ★`bareNeck`, alas raídas. |
| `ashTroll` | Troll de ceniza | 33 | melee (élite) | `brute` | hp 140, dmg 19, speed 45, cd 1.6, range 12, radius 22, scale 1.4, drop 0.9, rolls 2 | Dunas | Troll alto gris ceniza (0x7A7A78) con colmillos ★`tusks`, pelo blanco en cresta, taparrabos de piel, **hacha de bronce de Solarum** (0xC08A3A). |
| `trollHexer` | Brujo troll | 33 | ranged | `brute` (scale 1.0) | hp 48, dmg 13, speed 50, cd 2.2, range 180, radius 16, drop 0.6 | Dunas | Troll más flaco con máscara de hueso ★`boneMask`, collar de dientes, bastón con un cráneo de buitre; lanza maldiciones verdes. |
| `scarabSwarm` | Enjambre de escarabajos | 34 | melee (rápido) | `bat` | hp 18, dmg 6, speed 135, cd 0.7, radius 11, drop 0.35 | Necrópolis, Sepultada, Tumba | Nube de 5-6 escarabajos negros con reflejos verde-oro (0x1A2A20 / 0x8ACA40); el "cuerpo" del murciélago son los bichos agrupados. |
| `mummy` | Momia | 34 | melee (lenta) | `skeleton` | hp 50, dmg 11, speed 45, cd 1.3, drop 0.55 | Necrópolis, mausoleo, Tumba | Cuerpo envuelto en vendas amarillentas (0xD8C8A0) ★`bandages` con jirones sueltos, ojos ámbar; brazos por delante al andar. |
| `solarLegionary` | Legionario de Solarum | 35 | melee (aguanta) | `skeleton` | hp 60, dmg 12, speed 55, cd 1.2, drop 0.6 | Necrópolis, Sepultada, Tumba, Caldera | Esqueleto con casco de cresta roja ★`crest`, coraza y escudo redondo de bronce (0xB07A30) con un sol grabado, lanza corta. |
| `sunPriest` | Sacerdote del Sol | 35 | ranged (rayo solar) | `skeleton` | hp 36, dmg 13, speed 45, cd 2.2, range 190, drop 0.6 | Tumba, Sepultada, Caldera | Esqueleto con túnica blanca podrida y tocado dorado ★`sunHalo` (disco detrás de la cabeza); dispara un rayo amarillo. |
| `fireElemental` | Elemental de fuego | 36 | melee (rápido) | `slime` | hp 52, dmg 13, speed 70, cd 1.0, radius 15, drop 0.6 | Laderas, Caldera | Llama viva naranja-amarilla (0xFF8020 / 0xFFE060) con núcleo blanco y dos ojos negros; deja chispas al moverse. Distinto del `fireSlime` de Valdemar: más alto, sin "gelatina". |
| `eclipseZealot` | Fanático del Eclipse | 36 | charger | `human` | hp 65, dmg 17, speed 75, cd 2.0, radius 16, scale 1.1, drop 0.7 | Necrópolis, Laderas, Sepultada, Caldera | Humano con túnica gris ceniza y **vendas en la cara** (solo ojos violeta), cimitarra con fuego violeta (0x9A50E0). Embiste gritando. |
| `ashAcolyte` | Acólito de la ceniza | 36 | ranged | `human` | hp 40, dmg 13, speed 50, cd 2.2, range 175, radius 15, drop 0.6 | Necrópolis, Laderas, Sepultada, Caldera | **El Eclipse local**: capucha gris con ribete violeta, pañuelo de arena, farol de llama violeta ★`lantern` (el de Rocaforja con otra paleta). |
| `magmaGolem` | Gólem de magma | 37 | melee (élite, lento) | `brute` | hp 170, dmg 23, speed 38, cd 1.8, range 14, radius 24, scale 1.5, drop 1.0, rolls 2 | Laderas, Sepultada, Caldera | Bloques de basalto negro (0x2A2228) unidos por grietas de lava (0xFF6A10) ★`lavaCracks`; los puños gotean fuego. |

## Élite de historia (no reaparece, sin pieza única)

| Id | Nombre | Nivel | Comport. | Plantilla | Stats propuestas | Dónde | Aspecto |
|---|---|---|---|---|---|---|---|
| `ashHerald` | Ozrán el Desenterrador | 39 | ranged | `human` | hp 480, dmg 22, speed 55, cd 1.8, range 200, radius 18, scale 1.3, drop 1.0, rolls 3 (`isBoss: false`) | Interior `cenizas.sepultada.palacio` | Humano flaco con gafas de latón agrietadas ★`goggles`, túnica de explorador gris quemada, mochila de pergaminos, pala de bronce que arde violeta. Lanza bolas de fuego violeta. |

Es el Heraldo de Cenizas pero no es un "jefe" con pieza: el premio es la misión `cenizas.el_heraldo`
(`gearID: chest.cenizas`). Combate objetivo: como un jefe de zona corto (≈30-40 s). Si el balance lo pide, se le
pone `isBoss: true` sin `specialPartID` (y se filtra de la arena como los demás).

## Jefes (no reaparecen; cada uno suelta su pieza `boss.<id>`, ver `piezas.md`)

| Id | Nombre | Nivel | Comport. | Plantilla | Stats propuestas | Dónde | Pieza | Aspecto |
|---|---|---|---|---|---|---|---|---|
| `ashTrollKing` | Gorrak, Rey de las Dunas | 34 | melee | `brute` | hp 1700, dmg 30, speed 48, cd 1.7, range 16, radius 34, scale 2.2 | Dunas, Trono de Hueso | `boss.ashTrollKing` Fémur de Gorrak | Troll enorme gris ceniza, **corona de costillas** ★`ribCrown`, capa de piel de buitre, hacha de bronce imperial a dos manos. |
| `colossalScorpion` | Aguijón Negro | 36 | charger | ★`scorpion` | hp 1900, dmg 32, speed 75, cd 2.2, radius 34, scale 2.3 | Necrópolis, Puerta del Sol | `boss.colossalScorpion` Aguijón Negro | Escorpión colosal negro brillante (0x16141A) con **aguijón de oro** (0xE0B040) e inscripciones solares grabadas en el caparazón. |
| `sunHighPriest` | Gran Sacerdote Solano | 37 | ranged | `skeleton` | hp 1700, dmg 31, speed 50, cd 1.4, range 210, radius 24, scale 1.8 | Mazmorra `cenizas.tumba` | `boss.sunHighPriest` Disco del Sol Muerto | Esqueleto alto con **máscara solar de oro** ★`sunMask`, túnica blanca hecha jirones, báculo con disco; el disco ★`sunHalo` a la espalda brilla al disparar. |
| `ashEmperor` | Severián, el Emperador Ceniciento | 40 | melee | `skeleton` (o `brute`) | hp 3600, dmg 38, speed 52, cd 1.4, range 16, radius 34, scale 2.4 | Mazmorra `cenizas.caldera` | `boss.ashEmperor` Jopesh del Sol Invicto | Gigante de **ceniza gris con grietas de lava**, **corona de oro fundida** a la cabeza ★`moltenCrown` (gotea), capa de brasas, jopesh enorme. Al moverse suelta copos de ceniza. |

Combate objetivo (`progresion.md` §7): Gorrak y Aguijón Negro 40-60 s; Solano 40-60 s; Severián 60-120 s (jefe
final), daño por golpe 25-30 % de la vida con aviso.

## Resumen para el pixel-artist

- **Plantillas nuevas**: `scorpion` (cuerpo bajo segmentado, pinzas, cola arqueada; la usan `ashScorpion` y el jefe
  `colossalScorpion` a escala 2,3) y `crab` (caparazón ancho, pinzas, andar de lado). `lizard` es opcional: si la
  `rat` con cola larga y paleta roja queda bien, `salamander` la usa.
- **Accesorios nuevos**: `tail`, `bareNeck`, `tusks`, `boneMask`, `bandages`, `crest`, `sunHalo`, `lavaCracks`,
  `ribCrown`, `sunMask`, `moltenCrown`. Reutiliza `lantern` (Rocaforja) y `goggles` (existe).
- **Paleta del continente**: negro 0x16141A, gris ceniza 0x6A6A6E, rojo lava 0xE04020, naranja brasa 0xFF8020,
  oro viejo 0xC08A3A, violeta del Eclipse 0x9A50E0. Un solo color "vivo" por bicho.
- **NPC nuevos** (looks en `NPCLooks.swift`): `dornaComandante`, `tovaHerrera`, `sedraPosadera`, `margaCapitana`,
  `yaliaGuia`, `solanoEspiritu` (fantasma dorado), `guardiaFortin`; looks de pista `mural` y `violetBrazier`.
  Reutiliza `princess`, `brokk`, `thessa` (Lunaria), `zigoMercader` (Rocaforja, con sombrero de paja si se puede),
  `hermanaBrasa` (Rocaforja, con el Molde a la espalda).
