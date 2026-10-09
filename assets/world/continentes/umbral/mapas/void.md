# Grieta del vacío (`StoryDungeon` `umbral.grieta`, piso `void`) — mazmorra 55-57 · boceto

44×24, formato de `assets/maps/mazmorra.md` (`DungeonTile` de `Dungeon.swift`): `#` pared (la de arriba de 2 filas con
antorchas `t`), `G` puerta de monstruos, `BBB` gran puerta del jefe, `h` rejilla (aquí: **grieta en el suelo** por
donde salen criaturas), `~` líquido (aquí: **vacío**), `=` puente (aquí: puente de luz), `I` pilar, `A` altar
(sello roto), `x` brasero, `k` reja, `C` cofre, `,` escombros. `@` = inicio del héroe (solo borrador).

Plataformas que flotan sobre la nada, unidas por puentes de 3. El **santuario norte** (gran puerta del jefe) y la
**plataforma central** con el altar del sello roto, donde empieza el héroe.

## Mapa

```
    00000000001111111111222222222233333333334444
    01234567890123456789012345678901234567890123
 0  ############################################
 1  ###G#t##G##t########BBB#########t##G##t#G###
 2  #~~...........~..............~...........~~#
 3  #~................x......x................~#
 4  #~........h......................h........~#
 5  #~...........===............===...........~#
 6  #~...........===............===...........~#
 7  #~...........===....===.....===...........~#
 8  #~.......,.....~~~~~===~~~~~~....,,.......~#
 9  #~..................===...................~#
10  #~~...===..........................===...~~#
11  #~~~~~===~~~~~...I........I...~~~~~===~~~~~#
12  #~~~~~===~~~~~.......AA.......~~~~~===~~~~~#
13  #~~~~~===~~~~~................~~~~~===~~~~~#
14  #~~...===....~...I...@....I...~....===...~~#
15  #~........................................~#
16  #~.k..........~.....===......~..........k.~#
17  #~...........====~~~===~~~~====...........~#
18  #~...........====...===....====...........~#
19  #~...........====..........====...........~#
20  #~..h.........~~...h....h...~~.........h..~#
21  #~.........C..~~............~~............~#
22  #~~..........~~~............~~~..........~~#
23  ############################################
```

## Notas

- Entradas: 4 `G` (pared norte) + 6 `h` (grietas) = 10, como los pisos de la arena.
- Circuito: se puede rodear la plataforma central por el norte (puentes de 3) y por el sur (puentes de 4); los
  puentes laterales de las columnas 6-8 y 35-37 unen las esquinas.
- El vacío pide un arte nuevo (`environment-artist`): negro con estrellas violetas que se mueven despacio; bordes con
  raíces de piedra; las `h` como grietas violetas que laten.
- Oleadas y jefe en `bestiario.md` → "Oleadas de la Grieta".
- Comprobación: `make dungeon` → `tools/Harness/output/dungeon_void.png`; todas las casillas pisables conectadas.
