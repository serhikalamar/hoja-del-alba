# Lunaria · bestiario (niveles 20-30)

Responsable: `continent-lead` de `lunaria`. **Fase futura.** 15 monstruos nuevos + 4 jefes, todos en `Bestiary.all`
(**no** en la arena: `Arena.originalEnemyIDs` deja fuera todo lo que no sea de los 50 originales, y los jefes de la
arena siguen siendo los 10 originales). Familias del continente: arañas tejedoras, árboles corruptos, duendes,
Mala Luna, elfos marchitos, espíritus.

Estadísticas **base** comparables a las de Valdemar (`progresion.md` §1.3: la fórmula `stats(level:)` ya escala por
nivel). Son provisionales: las cierra el `balance-designer` con los objetivos de `progresion.md` §7. Formato de
`Enemy.swift`: `e(id, nombre, nivel, plantilla, comportamiento, hp, dmg, speed, cd, range, radius, scale, drop)`.

## 1. Plantillas (`template`)

| Plantilla | ¿Existe? | Quién la usa |
|---|---|---|
| `spider` | **nueva** (8 patas, cuerpo bajo y ancho, abdomen grande) | `moonSpider`, `spiderling`, `webSpitter`, `broodMother` |
| `treant` | **nueva** (tronco con cara, brazos-rama, raíces de pies) | `thornling` (pequeño), `treant`, `rottenElder` |
| `bat` | sí | `pixie` (alas de libélula en lugar de murciélago) |
| `slime` | sí | `glowcap` (sombrero de seta encima) |
| `boar` | sí | `corruptStag` (con astas) |
| `ghost` | sí | `wisp`, `forestSpirit` |
| `brute` | sí | `owlbear` |
| `dog` | sí | `feralWerewolf`, `moonHowler`, `blackClaw` (*propuesta*: si se ve poco "hombre lobo", reutilizar el cuerpo del héroe hombre lobo como plantilla `werewolf`) |
| `human` | sí | `witheredArcher`, `witheredBlade`, `ysolde` |

## 2. Monstruos normales

| Id | Nombre | Niv. | Plantilla | Comport. | hp | dmg | speed | cd | range | scale | drop | Aspecto (para `pixel-artist`) | Dónde |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pixie` | Duende travieso | 20 | bat | melee | 16 | 5 | 130 | 0,9 | 6 | 0,8 | 0,5 | Hadita verde musgo con alas de libélula y risa; deja chispas | Raíces, Claros |
| `thornling` | Espinoso | 20 | treant | melee | 30 | 7 | 55 | 1,1 | 6 | 0,7 | 0,5 | Matojo de zarzas con dos ojos ámbar; en el Marchito, gris | Raíces, Marchito |
| `glowcap` | Seta luminosa | 20 | slime | melee | 45 | 7 | 40 | 1,2 | 6 | 1 | 0,5 | Seta azul brillante que da saltitos; esporas de luz al morir | Raíces |
| `corruptStag` | Ciervo corrupto | 21 | boar | charger | 42 | 10 | 75 | 2,2 | 6 | 1,1 | 0,6 | Ciervo plateado con astas ennegrecidas y ojos violetas | Raíces, Espesura |
| `wisp` | Fuego fatuo | 21 | ghost | ranged | 18 | 7 | 60 | 2,0 | 160 | 0,8 | 0,5 | Llama azul pálida que flota; dispara chispas frías | Raíces, Claros, Marchito, Lago |
| `forestSpirit` | Espíritu del bosque | 22 | ghost | melee | 40 | 9 | 60 | 1,2 | 6 | 1 | 0,6 | Ciervo-niño translúcido verde; enfermo: manchas violetas | Claros, Lago |
| `moonSpider` | Tejedora lunar | 22 | spider | melee | 40 | 9 | 70 | 1,1 | 8 | 1 | 0,6 | Araña plateada con una luna creciente en el abdomen | Claros, Espesura, Nido, Hueco |
| `spiderling` | Arañita | 22 | spider | melee | 12 | 4 | 120 | 0,8 | 6 | 0,55 | 0,3 | Cría plateada; siempre en grupos de 3-4 | Claros, Nido, Hueco |
| `webSpitter` | Escupetelas | 23 | spider | ranged | 26 | 8 | 50 | 2,2 | 170 | 0,9 | 0,6 | Araña violeta con abdomen hinchado; escupe bolas de seda | Claros, Nido, Hueco |
| `owlbear` | Osolechuza | 23 | brute | melee | 120 | 16 | 55 | 1,6 | 10 | 1,35 | 1 (×2 tiradas) | **Élite.** Oso pardo con cabeza y plumas de búho blanco | Claros, Espesura, Marchito, Lago (ara) |
| `feralWerewolf` | Lobo de la Mala Luna | 24 | dog | charger | 48 | 11 | 90 | 1,8 | 6 | 1,1 | 0,6 | Hombre lobo encorvado, pelaje erizado gris oscuro, ojos rojos, babas violetas | Espesura, Hueco |
| `moonHowler` | Aullador | 25 | dog | ranged | 34 | 10 | 70 | 2,4 | 180 | 1 | 0,6 | Lobo flaco con el hocico al cielo; el aullido es una onda violeta (proyectil) | Espesura, Hueco |
| `treant` | Árbol corrupto | 26 | treant | melee | 170 | 18 | 30 | 1,8 | 14 | 1,6 | 1 (×2 tiradas) | **Élite.** Árbol de plata podrido: corteza gris, savia negra, hojas negras | Marchito, Lago, Hueco |
| `witheredArcher` | Arquero marchito | 26 | human | ranged | 30 | 11 | 55 | 1,8 | 190 | 1 | 0,6 | Elfo de piel gris, capucha violeta con el sello del Eclipse, arco de rama seca | Marchito, Lago, Hueco |
| `witheredBlade` | Danzante marchito | 27 | human | melee | 50 | 14 | 110 | 1,0 | 6 | 1 | 0,7 | Elfa gris con dos hojas curvas y cintas violetas; muy rápida | Marchito, Lago, Hueco |

Los elfos marchitos **son** el Eclipse en Lunaria (seguidores de Ysolde): no hace falta un acólito local.

## 3. Jefes (pieza única `boss.<id>`; ver `piezas.md`)

| Id | Nombre | Niv. | Plantilla | Comport. | hp | dmg | speed | cd | range | radius | scale | Dónde | Idea de combate | Pieza |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `rottenElder` | Abuelo Fresno Podrido | 23 | treant | melee | 1800 | 26 | 25 | 1,8 | 22 | 30 | 2,2 | Claros, Claro del Abuelo | Lentísimo pero con mucho alcance (barridos de rama). Se le esquiva rodeándolo. | `boss.rottenElder` |
| `blackClaw` | Garra Negra | 26 | dog | charger | 2000 | 32 | 85 | 2,0 | 14 | 26 | 2,0 | Espesura, Cubil | Embestidas con aviso; entre una y otra, ventana para pegar. Escolta: 2 `feralWerewolf`. | `boss.blackClaw` |
| `broodMother` | Madre Tejedora | 27 | spider | ranged | 2300 | 30 | 45 | 1,8 | 200 | 30 | 2,4 | Nido (jefe de `lunaria.nido`) | Escupe seda a distancia; llega con 4 `spiderling` de escolta (`bossEscort`). | `boss.broodMother` |
| `ysolde` | Ysolde, la Archimaga Marchita | 30 | human | ranged | 3400 | 38 | 60 | 1,4 | 220 | 24 | 1,8 | Hueco (jefe de `lunaria.hueco`) | Proyectiles de luna negra; escolta: 2 `witheredBlade` + 1 `treant`. | `boss.ysolde` |

Aspecto de los jefes: **Abuelo Fresno** = fresno de plata gigante, medio podrido, cara triste, musgo y setas;
**Garra Negra** = hombre lobo negro enorme con una cicatriz blanca en el pecho y un frasco al cuello; **Madre
Tejedora** = araña blanca nacarada, abdomen con una luna llena tatuada, corona de seda; **Ysolde** = ver `historia.md` §3
(forma marchita).

## 4. Qué enemigo va en cada área (y cuántos)

| Enemigo | Raíces | Claros | Espesura | Nido | Marchito | Lago | Hueco | Total campo |
|---|---|---|---|---|---|---|---|---|
| `pixie` | 6 (20-22) | 2 (22) | | | | | | 8 |
| `thornling` | 5 (20-21) | | | | 3 (26) | | | 8 |
| `glowcap` | 4 (21) | | | | | | | 4 |
| `corruptStag` | 3 (22) | | 2 (24) | | | | | 5 |
| `wisp` | 2 (21) | 3 (22) | | | 2 (26) | 3 (28) | oleada 2 | 10 |
| `forestSpirit` | | 5 (22-24) | | | | 2 (28) | | 7 |
| `moonSpider` | | 3 (23) | 2 (25) | oleadas 2-4 | | | oleada 4 | 5 |
| `spiderling` | | 4 (23) | | oleadas + escolta | | | oleada 4 | 4 |
| `webSpitter` | | 2 (23) | | oleadas 2-4 | | | oleada 4 | 2 |
| `owlbear` | | 1 (24) | 1 (25) | | 1 (28) | 1-2 (ara) | | 4-5 |
| `feralWerewolf` | | | 10 (24-26) | | | | oleada 3 + escolta | 10 |
| `moonHowler` | | | 5 (25-26) | | | | oleada 3 | 5 |
| `treant` | | | | | 3 (27) | 2 + 1-2 (ara) | oleadas 2, 5 + escolta | 6-7 |
| `witheredArcher` | | | | | 6 (26-28) | 6 (29) | oleadas 1, 5 | 12 |
| `witheredBlade` | | | | | 6 (27-28) | 5 (28-29) | oleadas 1, 5 + escolta | 11 |
| Jefes | | `rottenElder` | `blackClaw` | `broodMother` | | | `ysolde` | |

Las oleadas exactas de las dos mazmorras están en `zonas.md` (Nido y Hueco).

## 5. Propuestas al world-designer

- `owlbear` y `corruptStag` son "bestias del bosque": no están en la lista de familias de Lunaria, pero encajan
  (variante de bestias comunes con calificativo de bioma). Si se prefiere, renombrar a `moonOwlbear`/`silverStag`.
- `blackClaw` podría usar una plantilla `werewolf` nueva (cuerpo del héroe hombre lobo) para que la Mala Luna se lea
  como hombres lobo y no como perros. Lo mismo para `feralWerewolf` y `moonHowler`.
