# Escarcha · bestiario

Responsable: `continent-lead` de `escarcha` (diseño) → `character-designer` (datos) → `pixel-artist` (arte) →
`balance-designer` (números). **Fase futura.**

Familias de Escarcha (`continentes.md`): **yetis, gigantes de escarcha, bestias de hielo, no-muertos helados,
Caballeros de la Luna Rota**, más el Eclipse con estética local (lunáticos y cultistas de la escarcha).
Ids en camelCase, únicos en todo el juego; ninguno choca con los 50 actuales ni con los de Rocaforja, Lunaria,
Cenizas y Umbral (comprobado). `iceSlime` de Valdemar no se usa aquí. **Corvino** (`corvino`) y la **Hermana Brasa**
son NPC de escena, no enemigos.

Las estadísticas **base** son comparables a las de Valdemar (la fórmula `stats(level:)` ya escala por nivel);
son orientativas, las fija el `balance-designer` con simulación (`progresion.md` §7). Columnas como en
`Bestiary.e(...)`: vida, daño, velocidad, enfriamiento, alcance, radio, escala, prob. de soltar mineral.

## Monstruos normales (15)

| Id | Nombre | Nivel | Plantilla | Comport. | Vida | Daño | Vel. | CD | Alc. | Radio | Escala | Drop | Dónde | Aspecto (para el `pixel-artist`) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `frostWolf` | Lobo de escarcha | 40 | `dog` | charger | 34 | 9 | 100 | 2.2 | 6 | 13 | 1.1 | 0.5 | Costa, Tundra, Gigantes | Lobo blanco-azulado, lomo con escarcha en púas, ojos cian, vaho |
| `iceBear` | Oso polar | 40 | `brute` | melee | 70 | 12 | 50 | 1.6 | 8 | 20 | 1.35 | 0.7 | Costa | Oso blanco enorme, garras negras, hocico gris; a cuatro patas o erguido |
| `drownedWhaler` | Ballenero ahogado | 41 | `skeleton` | melee | 40 | 9 | 50 | 1.3 | 14 | 14 | 1 | 0.55 | Costa | Esqueleto con chubasquero amarillo roto, arpón (alcance largo), hielo en las costillas, ojos cian |
| `yeti` | Yeti | 42 | `brute` | melee | 65 | 11 | 60 | 1.4 | 8 | 19 | 1.3 | 0.6 | Tundra, Gigantes, cueva | Pelaje blanco largo, cara y manos azul pizarra, colmillos; brazos enormes |
| `wendigo` | Wendigo | 43 | `skeleton` | melee (rápido) | 32 | 8 | 120 | 0.8 | 6 | 13 | 1.15 | 0.5 | Tundra | Flaco y alto, piel gris tensa, cráneo de ciervo con cornamenta, ojos rojos (único toque cálido) |
| `mammoth` | Mamut | 43 | `boar` | charger (élite) | 150 | 18 | 70 | 3.0 | 8 | 28 | 1.9 | 0.9 (×2) | Tundra, Gigantes, Sima | Jabalí-mamut: lana parda con nieve, colmillos curvos enormes, trompa |
| `iceElemental` | Elemental de hielo | 44 | `slime` | melee (lento, tanque) | 60 | 9 | 40 | 1.5 | 6 | 16 | 1.3 | 0.6 | Cráter, Sima | Bloque de hielo translúcido con un núcleo cian que late; aristas de cristal |
| `shardLunatic` | Lunático de la esquirla | 44 | `human` | ranged | 30 | 9 | 55 | 2.2 | 170 | 15 | 1 | 0.6 | Cráter, Sima | Harapos, piel azulada, una esquirla clavada en la frente que brilla; lanza trozos de luna (proyectil cian) |
| `rimeCultist` | Cultista de la escarcha | 45 | `human` | ranged | 34 | 10 | 50 | 2.4 | 160 | 15 | 1 | 0.6 | Cráter, Sima, Ciudadela | Cultista del Eclipse con capa de piel negra y capucha con escarcha; proyectil helado (ralentiza si M-hielo, ver Necesidades) |
| `frostGiant` | Gigante de escarcha | 46 | `brute` | melee (élite) | 140 | 20 | 40 | 2.0 | 14 | 30 | 1.8 | 0.9 (×2) | Gigantes, Ciudadela | Piel azul hielo, barba de carámbanos, taparrabos de piel de mamut, garrote de hielo |
| `runeGiant` | Gigante rúnico | 47 | `brute` | ranged | 90 | 15 | 38 | 2.8 | 150 | 24 | 1.5 | 0.8 | Gigantes | Gigante más bajo y viejo, runas cian brillando en el pecho; lanza rocas de hielo (proyectil grande y lento) |
| `frozenDead` | Muerto helado | 47 | `skeleton` | melee | 44 | 10 | 45 | 1.3 | 6 | 14 | 1 | 0.55 | Murallas, Sima, Ciudadela | Esqueleto envuelto en hielo, restos de tabardo azul con la luna partida |
| `frostWraith` | Espectro gélido | 47 | `ghost` | melee (rápido) | 30 | 11 | 85 | 1.1 | 6 | 13 | 1.1 | 0.5 | Murallas, Ciudadela | Fantasma blanco-cian con jirones de niebla, corona de carámbanos |
| `brokenKnight` | Caballero de la Luna Rota | 48 | `human` | melee | 70 | 13 | 55 | 1.3 | 12 | 16 | 1.15 | 0.7 | Murallas, Ciudadela | Armadura de plata con escarcha, tabardo azul noche con luna partida, yelmo cerrado con ojos cian, alabarda |
| `moonPriestess` | Sacerdotisa de la Luna Rota | 48 | `human` | ranged | 36 | 12 | 50 | 2.3 | 170 | 15 | 1 | 0.7 | Murallas, Ciudadela | Túnica blanca y plata, velo, báculo con media luna; dispara rayos de luz cian |

Reparto por familia: bestias de hielo (lobo, oso, mamut, elemental) · yetis (yeti, wendigo) · gigantes (gigante,
gigante rúnico) · no-muertos helados (ballenero ahogado, muerto helado, espectro) · Caballeros de la Luna Rota
(caballero, sacerdotisa) · Eclipse local (lunático, cultista).

Mezcla de comportamientos por área (para que cada zona juegue distinto): Costa = embestidas + melee; Tundra = melee
rápido + élite que embiste; Cráter = mucho a distancia + tanques lentos; Gigantes = élites grandes + artillería;
Murallas = el mix más completo (melee duro + distancia + rápidos).

## Jefes (5)

Se definen con `Bestiary.boss(...)` (siempre sueltan; pieza `boss.<id>` automática). Permanentes (no reaparecen).

| Id | Nombre | Nivel | Plantilla | Comport. | Vida | Daño | Vel. | CD | Alc. | Radio | Escala | Dónde | Pieza que suelta |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `yetiPatriarch` | Abuelo Ventisca | 43 | `brute` | melee | 950 | 24 | 55 | 1.6 | 12 | 34 | 2.5 | `escarcha.tundra.cueva` | `boss.yetiPatriarch` · Zarpa del Abuelo Ventisca (empuñadura `fur`) |
| `shardHorror` | Engendro de la Esquirla | 46 | `slime` | melee | 1300 | 26 | 40 | 1.8 | 14 | 36 | 2.6 | Mazmorra `glacier` | `boss.shardHorror` · Témpano de la Sima (cabeza `spear`) |
| `giantJarl` | Jarl Hrimgar | 48 | `brute` | melee | 1700 | 32 | 45 | 2.0 | 16 | 38 | 2.6 | `escarcha.gigantes.trono` | `boss.giantJarl` · Mazo de Hrimgar (cabeza `hammer`) |
| `wallCommander` | Comendador Eirik | 49 | `human` | melee | 1500 | 30 | 65 | 1.2 | 14 | 26 | 1.8 | `escarcha.murallas` (Puerta de Plata) | `boss.wallCommander` · Guarda del Juramento Roto (guarda `frost`) |
| `brokenQueen` | Reina Astrid de la Luna Rota | 50 | `human` | melee (+ fase a distancia) | 2400 | 34 | 60 | 1.3 | 16 | 28 | 2.0 | Banda `citadel` | `boss.brokenQueen` · Alabarda de la Luna Rota (cabeza `halberd`) |

Aspecto de los jefes:
- **Abuelo Ventisca**: yeti gigante y canoso, pelo gris-azulado, barba trenzada, una **esquirla cian clavada en el
  lomo** que ilumina; ojos tristes (es víctima). Golpe con aviso: salta y aplasta (onda de nieve).
- **Engendro de la Esquirla**: masa de hielo y cristal de luna con la esquirla madre como corazón (brilla más al
  atacar). Invoca 2 `iceElemental` cada 30 s.
- **Jarl Hrimgar**: el gigante más grande, corona de cuernos de mamut, capa de piel de oso polar, mazo de hielo
  con runas. Golpe en área con aviso (pisotón).
- **Comendador Eirik**: caballero de la Luna Rota con armadura más ornamentada, capa rota, mitad de la cara
  congelada (la esquirla en el pecho). Rápido: embestida corta con aviso.
- **Reina Astrid**: armadura-vestido de plata y azul noche, **corona de esquirlas** (5 puntas de cristal cian), pelo
  blanco, alabarda. Fase 2 (≤50 %): flota y lanza esquirlas desde lejos; invoca 2 `brokenKnight`.

Escala de los jefes respecto a Valdemar: mismo patrón (jefe ≈ 10-15× la vida de un normal de su nivel, daño
2,5-3×); los números exactos según los objetivos de `progresion.md` §7 (jefe de zona 40-60 s, final 60-120 s).

## Plantillas y arte

Ninguna plantilla nueva imprescindible: `dog`, `brute`, `skeleton`, `human`, `ghost`, `slime`, `boar` cubren todo.
Opcionales (mejoran mucho el resultado; ver `encargos.md`): plantilla `giant` (cuerpo más alto que `brute`, para
gigantes y Jarl) y accesorios de `human` nuevos (alabarda, velo, corona de esquirlas, chubasquero).

Paleta del continente: blanco `#F4FAFF`, cian `#8FD8F0`, azul hielo `#3C8CB0`, azul noche `#1E2A4A`, violeta de
aurora `#A070E0`, plata `#C0C8DC`, y un único cálido por bicho como máximo (ojos del wendigo, brasas).

## Necesidades de motor (opcionales)

- **Proyectil que ralentiza** (cultista, sacerdotisa, Reina): reutilizar el `slow` de las habilidades de hielo en
  proyectiles enemigos. Si no, son proyectiles normales.
- **Invocar esbirros** (Engendro, Reina): el jefe añade 2 enemigos cada N s. Si no está, se quita (las oleadas ya
  ponen esbirros).
- **Fase 2 de jefe** (Reina pasa a `ranged` al 50 %). Si no está, la Reina es `melee` y basta.
