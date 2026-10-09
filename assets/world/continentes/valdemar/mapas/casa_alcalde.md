# Casa del alcalde · `mayor`

Interior de la casa del alcalde (edificio `mayor` de Valdehierro, hoy cerrado). Se abre al completar `valdemar.hilos`. Cultistas y acólitos del Eclipse quemando papeles; la carta del alcalde está en el escritorio.

- Tamaño: **14×9** casillas · tipo: **interior** · bioma: `valdemar`
- `AreaMap.level` (fuera de zonas): **7** · entrada por defecto (`entry`): **(6, 7)**
- Generado y validado (filas iguales, borde cerrado salvo salidas, todo conectado desde la entrada, spawns pisables y dentro de su zona, ningún monstruo a menos de 7 casillas de una llegada).

Llegadas a esta área: desde `town` → (6, 7)

## Zonas (`Zone`)

| Id | Nombre | x, y, ancho, alto | Nivel |
|---|---|---|---|
| `mayor` | Casa del alcalde | 0, 0, 14, 9 | **7** |

## Monstruos (`Spawn`)

Grupos: los que están a menos de 3,5 casillas se avisan entre sí (alerta de manada de 170 pt). **Reaparece** = monstruo de campo (M2); **permanente** = se guarda en `killedSpawns`.

| Id | Enemigo | Casilla | Zona (nivel) | Tipo | Nota |
|---|---|---|---|---|---|
| `mayor.1` | `cultist` Cultista | (3,4) | Casa del alcalde (7) | permanente |  |
| `mayor.2` | `eclipseAcolyte` Acólito del Eclipse (NUEVO) | (9,2) | Casa del alcalde (7) | permanente |  |
| `mayor.3` | `cultist` Cultista | (4,6) | Casa del alcalde (7) | permanente |  |
| `mayor.4` | `eclipseAcolyte` Acólito del Eclipse (NUEVO) | (6,4) | Casa del alcalde (7) | permanente |  |

## NPC y objetos

| Id | Nombre | Casilla | Nota |
|---|---|---|---|
| `cartaAlcalde` | Carta del alcalde | (12,2) | objeto: se lee al despejar la sala |

## Mapa (filas listas para `rows:` del código)

```
XXXXXXXXXXXXXX
XsssssXXsssssX
X____________X
X_rrrrrr__tt_X
X_rrrrrr_____X
X_rrrrrr__zz_X
X_o_______zz_X
X____________X
XXXXXXDXXXXXXX
```

## Mapa anotado (solo para leer: `H` edificio, `u` su puerta, `@` monstruo, `&` jefe, `!` NPC/objeto, `*` punto seguro)

```
XXXXXXXXXXXXXX
XsssssXXsssssX
X________@__!X
X_rrrrrr__tt_X
X_r@rr@r_____X
X_rrrrrr__zz_X
X_o_@_____zz_X
X____________X
XXXXXXDXXXXXXX
```

Caracteres usados: `D` puerta de salida · `X` pared · `_` madera · `o` barril · `r` alfombra · `s` estantería · `t` mesa · `z` cama

## Notas

- Es un **interior** como los demás de `Valdehierro.interiors`: sin zonas (la tabla de zona de arriba es solo para
  el validador; en código `zones: []`), nivel **7** en `AreaMap.level`, ids de spawn `mayor.1…mayor.4` (los genera el
  helper `interior(...)`), salida por `D` a la puerta del edificio `mayor` (38,23) → se sale a (38,24).
- `cartaAlcalde` no es un aldeano: es un **objeto que se lee** (rol nuevo de NPC, p. ej. `.clue`). Solo se puede leer
  con la sala despejada. Al leerlo se completa `valdemar.alcalde`. Look: `letter` (pergamino con sello de luna negra).
- El alcalde **no está**: huyó. Es el encapuchado del epílogo (ver `../historia.md`).
- Spawns permanentes (como en todas las casas).
