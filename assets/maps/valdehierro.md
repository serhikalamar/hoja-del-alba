# Valdehierro (capital de Valdemar)

Pueblo de 44×36 casillas (`town`). Render: `make maps` → `tools/Harness/output/map_town.png`.
Código: `enum Valdehierro` en `src/GameCore/Sources/GameCore/Town.swift`. Borrador del continente:
`assets/world/continentes/valdemar/mapas/valdehierro.md`. Áreas de alrededor: `valdemar.md`.

## Ruta prevista

Entrada por el camino real (sur, (21,33)) → Puerta sur (1) → Mercado (2) → Barrio oeste (3) / Barrio este (4) /
Plaza mayor (5) → rescatar a los 6 aldeanos (aparece el Capitán Vela al pie de la escalinata) → **fuera del pueblo**
(Huertos, Robleda, casa del alcalde, Abadía + Cripta, Pedregal: niveles 5-9, ver `valdemar.md`) → con el Abad y el
Señor de la guerra vencidos se abre la escalinata → Patio del castillo (9) → Salón del trono (10) → epílogo en la
forja → Paso del Norte (10).

## Salidas (`AreaExit`)

| Id | Casillas | Lleva a | Llega a | Bloqueo (aviso) |
|---|---|---|---|---|
| `town.oeste` | (0,17) (0,18) | `valdemar.huertos` | (53,17) | Zona `west` liberada ("Los goblins del barrio oeste cortan el camino de los huertos.") |
| `town.este` | (43,17) (43,18) | `valdemar.abadia` | (2,17) | Zona `east` liberada ("Los cultistas del barrio este vigilan el camino de la abadía.") |
| `town.sur` | (18..25,35) | `valdemar.robleda` | (43,2) | — |
| `town.norte` | (3..5,0) | `valdemar.paso` | (23,29) | Misión `valdemar.paso_norte` ("El Paso del Norte está cerrado. El herrero sabe por qué.") |
| bajada `e` | (34,7) | mazmorra `valdemar.calabozos` (piso `prison`) | — | Castillo abierto |

Llegadas al pueblo: desde Huertos (2,17) · Abadía (41,17) · Robleda (21,33) · Paso (4,2).

**Poternas del patio** (cambio del map-designer sobre el borrador): las franjas de hierba a los lados del castillo
(columnas 2-6 y 37-41, filas 1-11) estaban cerradas por la muralla y por las casas de abajo, así que la salida norte
(3-5,0) y la llegada desde el Paso (4,2) quedaban aisladas. Se abren dos huecos de 2 casillas en la muralla del
patio, (7,4-5) y (36,4-5): a la salida norte se llega por el patio, que ya estará abierto cuando el Paso se abra
(pide `valdemar.rey_goblin`).

## Zonas

| Zona | Dificultad | Enemigos | Notas |
|---|---|---|---|
| Puerta sur | 1 | ratas, goblins, hondero, perro | Entrada y punto de reaparición |
| Mercado | 2 | bandidos, ladrones, cuervos, lancero | Dos plazas de puestos |
| Barrio oeste | 3 | esqueletos, granjero zombi, chamán, jabalí | Panadería, tejedora, molinero, capilla · salida oeste |
| Barrio este | 4 | cultistas, limo, murciélago, goblin bruto | Posada, **forja del enano**, alquimista, alcalde · salida este |
| Plaza mayor | 5 | hobgoblin, arquero, lobo, mercenario, **Capitán bandido** | Fuente central |
| Patio del castillo | **9** (antes 7) | guardias reales, magos, élite, orco, jinete de lobo | Escalinata cerrada hasta abrir el castillo · bajada a los calabozos |

## Interiores

| Edificio | Dificultad | Aldeano / NPC | Jefe |
|---|---|---|---|
| Panadería | 2 | Marta, la panadera | Rey de las ratas |
| Casa de la tejedora | 3 | Elena | — |
| Casa del molinero | 3 | Tomás | Espantapájaros maldito |
| Capilla | 5 | Fray Anselmo | — |
| Posada del Jabalí | 4 | Bruno | Herrero poseído |
| Casa de la alquimista | 6 | Iris | Bruja del pozo |
| **Casa del alcalde** (`mayor`, 14×9) | 7 | Carta del alcalde (`cartaAlcalde`, pista) | — (2 cultistas + 2 acólitos del Eclipse) |
| Castillo (salón del trono) | 10 | Princesa Aurora | Rey Goblin |
| Forja del enano | — | — | Abre tienda y ritual |

La casa del alcalde se abre con `valdemar.hilos` (el bloqueo lo pone el motor, M4). Mapa:

```
XXXXXXXXXXXXXX
XsssssXXsssssX
X________@__!X     @ monstruo · ! carta (12,2)
X_rrrrrr__tt_X
X_r@rr@r_____X
X_rrrrrr__zz_X
X_o_@_____zz_X
X____________X
XXXXXXDXXXXXXX
```

## NPC de la calle (`Valdehierro.streetNPCs`)

| Id | Quién | Casilla | Aparece |
|---|---|---|---|
| `capitanGuardia` | Capitán Rodrigo Vela (`questGiver`, look `guardCaptain`) | (18,12), al pie de la escalinata | `valdemar.liberar` hecha |
| `marta` | Marta | (6,17) | Rescatada |
| `elena` | Elena | (12,17) | Rescatada |
| `tomas` | Tomás | (6,24) | Rescatado |
| `anselmo` | Fray Anselmo | (12,24) | Rescatado |
| `bruno` | Bruno | (35,17) | Rescatado |
| `iris` | Iris | (34,24) | Rescatada |

Mismo id que dentro de su casa (una misión = un `giverID`). Textos provisionales: los cambia el story-writer (SW2).
Ojo: Tomás (6,24) está en la casilla del jabalí `west.4`; en la práctica el jabalí ya ha muerto (está delante de la
puerta del molino), pero si se ve raro se puede mover a (8,24).
