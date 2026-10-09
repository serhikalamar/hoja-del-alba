# Valdemar · historia del capítulo 1 (niveles 1-10)

Responsable: `continent-lead` de `valdemar`. Estado: **listo para implementar** (2026-10-07).
Base: `assets/world/mundo.md` (canon del mundo) y `brief.md`. Los textos definitivos de diálogo los escribe el
`story-writer` a partir de este documento; aquí están el arco, los personajes, las misiones con sus datos y las
escenas clave en una o dos frases.

## 1. El capítulo en un párrafo

Una noche sin luna los goblins del **Rey Goblin** entran en **Valdehierro** por la puerta sur y toman el castillo con
la **princesa Aurora** dentro. El héroe llega esa misma noche, libera las calles y rescata a los seis aldeanos.
Pero un rey goblin no toma un castillo él solo: los orcos del **Pedregal** le dan músculo, los muertos de la **Abadía
de Valsombra** se han levantado y alguien **abrió la puerta sur desde dentro**. Siguiendo los hilos (los bandidos de
Robleda, la casa cerrada del alcalde) el héroe descubre a la **Orden del Eclipse** y a su primer Heraldo, el **Abad
Morcar**, que armó al Rey Goblin a cambio del castillo… y de la **Hoja del Alba**. Con el Abad y el Señor de la guerra
vencidos, el Capitán de la guardia abre el castillo; el héroe derrota al Rey Goblin y Aurora le entrega la Hoja del
Alba (I). En el epílogo el herrero enano reconoce en las armas orcas el fuego del **Clan Hollín** y un encapuchado
—el alcalde— huye hacia el norte: se abre el **Paso del Norte** hacia Rocaforja.

Emoción: **hogar**. Tono: aldeanos entrañables y con humor de taberna; la amenaza se intuye y crece.

## 2. Quién manda, quién amenaza

| Quién | Papel |
|---|---|
| **Princesa Aurora** | Última del linaje que guarda la Hoja del Alba. Prisionera en el salón del trono. Al final entrega la Hoja y, desde el cap. 2, lidera la Alianza del Alba. |
| **Capitán Rodrigo Vela** (`capitanGuardia`, NUEVO) | Capitán de la guardia de Valdehierro. Sobrevivió escondido con sus últimos hombres. Aparece al liberar el pueblo; organiza el asalto al castillo. Serio, cansado, leal. |
| **El enano herrero** (*nombre a confirmar*: **Brokk Martillohondo**) | Herrero de la forja del barrio este. Exiliado de Rocaforja. Gruñón. Cierra el capítulo: reconoce el fuego Hollín y abre el camino del norte. |
| **Rey Goblin** (`goblinKing`) | Jefe final. Bruto y vanidoso; cree que el castillo es su premio, pero solo es la herramienta del Eclipse. |
| **Abad Morcar** (`abbot`, el *Abad no-muerto*) | **Heraldo del Eclipse** de Valdemar. Encontró hace un año el Ascua bajo la abadía y oyó a Morvath; se dejó morir y volvió. Armó al Rey Goblin. Quiere la Hoja del Alba para el Eclipse. |
| **Alcalde Fausto Ledesma** (no combate) | El traidor: abrió la puerta sur a cambio de oro y promesas del Eclipse. Huye antes de que el héroe entre en su casa. Es **el encapuchado del epílogo** que escapa al norte. |
| **La Bruja del pozo** (`witch`) | Aliada local del Abad: hechizó al espantapájaros de Tomás. Ya existe (jefe de la casa de la alquimista). |
| **Señor de la guerra orco** (`warlord`) | Jefe del campamento orco del Pedregal. Vende sus orcos al Rey Goblin; sus armas llevan la marca del Clan Hollín. |
| **Ogro del molino** (`ogre`) y **Lobo alfa** (`alphaWolf`) | Amenazas locales que el caos ha soltado: misiones de los aldeanos. |

Aldeanos (ya existen, ids estables): `marta`, `elena`, `tomas`, `anselmo`, `bruno`, `iris`. Tras su rescate salen a la
calle (posiciones en `mapas/valdehierro.md`) y dan misiones.

## 3. Cómo conecta con la historia principal

- El Eclipse quería **la Hoja del Alba**: era la única arma capaz de reforzar el sello de la Luna.
- El **Ascua de Valdemar** está bajo la Cripta de la abadía. El Abad la custodiaba para la Orden; al vencerlo, queda a
  salvo (en el cap. 1 no se recoge: solo se ve su brillo al fondo de la cripta y Fray Anselmo jura vigilarla).
- Primer **gancho a Rocaforja**: las armas orcas con fuego Hollín y el alcalde huyendo al norte (si el lead de
  Rocaforja quiere usarlo: ver "Propuestas al world-designer").

## 4. Misiones (ids estables `valdemar.<nombre>`)

Columna principal (historia) en **negrita**. XP calculada como % de `Leveling.xpToNext(nivel de la misión)`
(simulación en `zonas.md` §4). Oro y minerales orientativos: los ajusta el `balance-designer`.

| # | Id | Da | Requisitos | Objetivos (en datos) | Recompensa | Desbloquea |
|---|---|---|---|---|---|---|
| 1 | **`valdemar.liberar`** | (automática al empezar) | — | `rescue([marta, elena, tomas, anselmo, bruno, iris])` | 172 XP · 100 oro | Aparece `capitanGuardia`; misiones 2-5 según quién esté rescatado |
| 2 | `valdemar.molino` | `tomas` | Tomás rescatado | `kill(zombieFarmer ×6, área valdemar.huertos)` + `defeat(ogre)` | 182 XP · 120 oro · `silver` ×2 | — |
| 3 | `valdemar.caza_mayor` | `bruno` | Bruno rescatado | `kill(wolf ×6, área valdemar.robleda)` + `defeat(alphaWolf)` | 182 XP · 120 oro · `iron` ×3 | — |
| 4 | **`valdemar.hilos`** | `elena` | Elena rescatada | `kill([bandit, mercenary] ×8, área valdemar.robleda)` + `talk(elena)` | 136 XP · 100 oro | Abre la casa del alcalde (`mayor`) · misión 5 |
| 5 | **`valdemar.alcalde`** | `elena` | 4 completada | `clear(área mayor)` + `read(cartaAlcalde)` | 173 XP · 80 oro · `gold` ×1 | Misión 7 (la carta nombra al Abad Morcar) |
| 6 | `valdemar.pociones` | `iris` | Iris rescatada | `kill([slime, fireSlime, iceSlime] ×6, cualquier área de Valdemar)` | 116 XP · 80 oro · `emerald` ×1 | — |
| 7 | **`valdemar.abadia`** | `anselmo` | Anselmo rescatado **y** 5 completada | `kill([skeleton, skeletonArcher, ghoul, wraith] ×10, área valdemar.abadia)` + `dungeon(valdemar.cripta)` | 285 XP · 200 oro · `emerald` ×2 | Parte de la condición del castillo |
| 8 | **`valdemar.pedregal`** | `capitanGuardia` | 1 completada | `kill([orc, berserker] ×6, área valdemar.pedregal)` + `defeat(warlord)` | 213 XP · 200 oro · `gold` ×2 | Parte de la condición del castillo |
| 9 | **`valdemar.rey_goblin`** | `capitanGuardia` | 1, 7 y 8 completadas (castillo abierto) | `defeat(goblinKing)` + `talk(princess)` | 505 XP · la recompensa de Aurora (oro + `emerald` + **Hoja del Alba**) | Misión 10 · forja tier 2 |
| 10 | **`valdemar.paso_norte`** | enano herrero (al entrar en la forja) | 9 completada | `talk(herrero)` | 202 XP · la forja vende tier 2 | Abre la salida norte del pueblo (`valdemar.paso`) |
| 11 | `valdemar.calabozos` (opcional, P3) | `capitanGuardia` | castillo abierto | `dungeon(valdemar.calabozos)` | 150 XP · 150 oro · `silver` ×2 | Repetible para farmear |

Reglas:
- `kill(...)` cuenta **las muertes después de aceptar la misión** y solo en el área indicada (los monstruos de campo
  reaparecen, así que siempre se puede terminar). `defeat(jefe)` cuenta aunque se haya matado antes de aceptarla
  (los jefes de campo no reaparecen; si no, la misión quedaría imposible).
- Una misión se **acepta** hablando con quien la da ("!" amarillo sobre su cabeza), se **entrega** hablando con él
  otra vez ("?" amarillo). Excepciones: `liberar` (automática) y `alcalde` (se completa al leer la carta),
  `rey_goblin` (se completa al hablar con Aurora), `paso_norte` (al hablar con el herrero).
- **Condición nueva del castillo** (`castleOpen`): `liberar` + `abadia` + `pedregal` completadas. **No** usar
  `defeatedBosses` (la arena también lo rellena).

## 5. Orden previsto y escenas clave

1. **Intro** (ya existe) + una línea por raza (texto: `story-writer`; motivos en `mundo.md` §7).
2. **Pueblo 1-5**: lo de hoy. Al rescatar al sexto aldeano ya **no** se abre el castillo: aparece el Capitán Vela al
   pie de la escalinata. Escena: "El Rey Goblin ha atrancado la puerta… y no está solo. Orcos en el Pedregal, muertos
   en la abadía. Y alguien les abrió la puerta sur."
3. **Fuera (5-9)**, en el orden que quiera el jugador, guiado por el nivel de cada área:
   Huertos (Tomás) → Robleda (Bruno, Elena) → Casa del alcalde → Abadía + Cripta (Anselmo) → Pedregal (Capitán).
   Iris (limos) se completa por el camino.
4. **La carta del alcalde** (escena): sello de luna negra; "La puerta sur estará abierta la noche sin luna. El Abad
   cumple lo que promete. — F." Elena: "¿El alcalde? Pero si bautizó a mi hija…".
5. **La Cripta** (mazmorra): antes de la oleada del jefe, el Abad habla (confesión a medias): "No buscaba el castillo,
   necio. Buscaba lo que tu princesa esconde. La Luna se apaga… y Él despierta." Al caer: se ve el brillo del Ascua
   al fondo; Fray Anselmo (de vuelta en el pueblo) jura guardarla.
6. **El Pedregal**: al vencer al Señor de la guerra, el Capitán: "Sin orcos ni muertos, el Rey Goblin está solo. Abro
   la escalinata."
7. **Patio (9) y trono (10)**: Rey Goblin → Aurora entrega la **Hoja del Alba (I)** ("Llévala al ritual. Solo un héroe
   puede despertarla.").
8. **Epílogo** (al entrar en la forja): el enano examina una hoja orca: "Este temple… es fuego Hollín. Mi viejo clan."
   Desde la muralla se ve una figura encapuchada que huye por el Paso del Norte. "Si vas tras él, iré contigo. La
   forja ya vende acero de verdad." → se abre la salida norte.
9. **Paso del Norte (10)**: rezagados goblins; al fondo, el cartel "Montes de Rocaforja" (*Próximamente* hasta el cap. 2).

## 6. Final del continente

- Valdehierro es libre y se convierte en **capital** de la Alianza en Valdemar: forja, posada, aldeanos con diálogo.
- El héroe tiene la **Hoja del Alba (I)**, nivel ~10 y la forja vende **tier 2**.
- El Ascua de Valdemar está a salvo bajo la abadía (Fray Anselmo la vigila).
- Cabo suelto: el alcalde Fausto huye hacia Rocaforja con lo que sabe de la Hoja.

## 7. Propuestas al world-designer

> **Respuesta del world-designer (revisión de coherencia 1, 2026-10-09)**: cada propuesta está aceptada, ajustada,
> rechazada o marcada PENDIENTE DEL USUARIO, con su razón, en `assets/world/mundo.md` §13; las contradicciones
> corregidas en este continente, en `mundo.md` §14; los renombres, en `assets/world/continentes.md` (registros comunes).

1. **El encapuchado que huye = el alcalde Fausto Ledesma.** Cierra el misterio de la puerta sur y deja un villano
   menor que el lead de Rocaforja puede usar o no (por ejemplo, como contacto del Clan Hollín). Si no lo quiere, el
   epílogo funciona igual con "un encapuchado".
2. **Recompensas de aldeanos fuera de la familia de Valdemar**: hoy Fray Anselmo da zafiro, Bruno rubí e Iris
   amatista + diamante. Propongo cambiarlas a plata/oro/esmeralda como la de la princesa (ver `minerales.md`).
3. **Multiplicador de XP de los jefes de historia ×12 → ×6** (ver `zonas.md` §4): con ×12 el héroe llega al Rey
   Goblin con nivel 11-12 aunque las misiones den poco. Lo decide y mide el `balance-designer`.
4. Nombre del enano: uso **Brokk Martillohondo** (propuesta de `mundo.md`) hasta que el usuario lo confirme.
