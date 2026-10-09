# Yunque del Alba (`StoryDungeon` `umbral.yunque`, piso `skyforge`) — banda final, nivel 60 · boceto

48×26, formato `DungeonTile`. El Yunque de los Seis (`AAAA`, 4×3) en el centro, rodeado por un **anillo de fuego
estelar** (`~`) con 4 puentes (`=`). Alrededor, las **seis estatuas de los Herreros** (`s`) con su brasero (`x`): las
seis Ascuas. Por los lados, el borde de la isla al vacío (`~`). Morvath entra por la gran puerta norte (`BBB`) y baja
por la alfombra `r` hasta el Yunque. `@` = inicio del héroe (solo borrador).

## Mapa

```
    000000000011111111112222222222333333333344444444
    012345678901234567890123456789012345678901234567
 0  ################################################
 1  ####t#G###t#G###t#####tBBB##t#####tG####tG######
 2  #~~~...................rr...................~~~#
 3  #~~~...................rr...................~~~#
 4  #~~~...................rr...................~~~#
 5  #~~~....sx.............rr.............xs....~~~#
 6  #~~~...................rr...................~~~#
 7  #~~~...................rr...................~~~#
 8  #~~~...........~~~~~~~====~~~~~~~...........~~~#
 9  #~~~.......h...~~~~~~~====~~~~~~~...h.......~~~#
10  #~~~...........~~~............~~~...........~~~#
11  #..............~~~.I........I.~~~..............#
12  #..............===....AAAA....===..............#
13  #.....sx.......===....AAAA....===.......xs.....#
14  #..............===....AAAA....===..............#
15  #~~~...........~~~.I........I.~~~...........~~~#
16  #~~~...........~~~............~~~...........~~~#
17  #~~~.......h...~~~~~~~====~~~~~~~...h.......~~~#
18  #~~~...........~~~~~~~====~~~~~~~...........~~~#
19  #~~~........................................~~~#
20  #~~~........................................~~~#
21  #~~~....sx.............@..............xs....~~~#
22  #~~~..........c.....h......h.....c..........~~~#
23  #~~~.C......................................~~~#
24  #~~~........................................~~~#
25  ################################################
```

## Notas

- **El séptimo pedestal**: junto a la gran puerta `BBB` (centro de la pared norte) va un pedestal roto sin estatua
  (decorado del `environment-artist`): el sitio de Morvath entre los Siete.
- Entradas: 4 `G` + 4 `h` = 8 (la banda tiene menos oleadas que la arena pero más gordas).
- **Los seis braseros** son la mecánica de la fase 3 (ver `bestiario.md` → Morvath): Morvath "apaga" uno cada 15 s
  (el brasero se oscurece); con la Hoja del Alba (VI) equipada, golpear junto a un brasero apagado lo vuelve a
  encender. *Opcional* (motor): si no se implementa, los braseros son decorado y la fase 3 es solo más rápida.
- Pasos laterales (filas 11-14) al borde del vacío: para esquivar las ondas de Morvath sin quedar encerrado.
- Arte (`environment-artist`): suelo de mithril con runas doradas, anillo de fuego blanco-dorado, estatuas de los Seis
  (cada una con el símbolo de un continente), Luna rota enorme de fondo.
- Comprobación: `make dungeon` → `tools/Harness/output/dungeon_skyforge.png`.
