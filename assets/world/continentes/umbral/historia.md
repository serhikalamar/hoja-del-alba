# Umbral · historia del capítulo 6 — *Desafío final* (niveles 50-60)

Responsable: `continent-lead` de `umbral`. Estado: **borrador 2** (2026-10-08), **fase futura** (se implementa el
último). Hermanos: `zonas.md` (áreas, salidas, zonas, mazmorras y misiones en formato de datos), `mapas/`,
`bestiario.md`, `minerales.md`, `piezas.md`, `encargos.md`. Formato de datos: el de Valdemar (`../valdemar/contrato.md`).
Hilo recogido de los otros cinco capítulos (`../<id>/historia.md`); lo que depende del usuario, *a confirmar*.

## 1. En pocas líneas

Las **Islas de Umbral** flotan sobre el Mar Quieto alrededor del **Yunque del Alba**. Corvino subió por la Escala de
Esquirlas con el **Molde del Ocaso** (dos coladas: fuego de Cenizas y el **Ascua de Escarcha**) hasta la **Gran
Lente** del Observatorio, donde lo esperaba la **Gran Heraldo Vesper**. Esa misma noche Vesper arrancó de la Lente el
**Ascua de Umbral**: la Luna de Plata se apagó del todo y **Morvath, el Herrero Hueco**, bajó a medias hasta su
Yunque. La Alianza resiste en el **Bastión del Alba**. El héroe llega en el dirigible *Testaruda*, vence a la Matriarca
del Vuelo, cierra la Grieta del vacío, derrota a Corvino en la cúpula y a Vesper en el Puente del Yunque, recupera
las dos Ascuas robadas, despierta la **Hoja del Alba (VI)** —la llave con seis brasas— y en el Yunque **cierra la
puerta** a Morvath.

## 2. El lugar y quién manda

- **Islas de piedra flotantes** unidas por **puentes de luz** (los tendieron los Herreros) y cadenas de mithril.
  Debajo, el **vacío**. Arriba, la Luna de Plata, partida (desde Escarcha) y ahora apagada.
- **Ruinas celestes**: muelles y faros de cuando los Herreros traían metal del cielo; el **Observatorio de los
  Herreros**, cuya **Gran Lente** enfocaba el fuego del Yunque hacia la Luna. Esa luz **es el sello** (murales de
  Cenizas): el corazón de la Lente era el **Ascua de Umbral**.
- **Nidos del Vuelo del Alba**: los dragones guardianes del Yunque, casi todos corrompidos por el vacío.
- **Grietas del vacío**: por donde "gotea" la prisión de Morvath desde que la Luna se apagó.

| Facción | Dónde | Quién manda | Qué quiere |
|---|---|---|---|
| Alianza del Alba | Bastión, Muelles | **Aurora**, con el **Mariscal Hálvar** | Recuperar las dos Ascuas, despertar la Hoja (VI) y cerrar la puerta del Yunque. |
| Vuelo del Alba | Nidos | **Nixara** (corrompida) · **Albor** (leal) | Albor: salvar lo que quede del Vuelo. |
| Criaturas del vacío | Islas Rotas, Grieta | El **Guardián de la Grieta** (vaciado) | Nada: hambre. Abren paso a Morvath. |
| Orden del Eclipse | Observatorio, Puente | **Vesper** (Gran Heraldo), con **Corvino** | Llenar el Molde con seis brasas y entregárselo a Morvath. |
| Siervos de Morvath | Puente, Yunque | **Morvath** | Recuperar su fuego (ver §6). |

## 3. Personajes

Ids de NPC únicos en todo el juego (comprobado con los otros cinco continentes). Los que viajan reutilizan su id con
`appearsWhen` (propuesta 7 de Cenizas).

| Id (NPC / enemigo) | Nombre | Dónde | Papel | Aspecto (para `pixel-artist`) |
|---|---|---|---|---|
| `princess` | Princesa Aurora | Ciudadela del Bastión | Misión principal. Sabe desde Cenizas que su Hoja es una **llave**. Al final, **guardiana del Yunque** (*a confirmar*, decisión 5). | Armadura ligera blanca y dorada, capa índigo, corona fina. |
| `brokk` | Brokk Martillohondo | Forja del Último Yunque | Forja tier 6, ritual, despierta la Hoja (VI) y **funde el Molde del Ocaso**. | El de siempre, con gafas de piloto en la frente. |
| `halvar` | Mariscal Hálvar (Ser Hálvar de Escarcha) | Cuartel → Puente del Yunque | Último Caballero de la Luna Rota; manda la guarnición. Misiones de caza. Al final lleva el Ascua de Escarcha a casa. | Armadura de plata reparada, tabardo azul noche con luna partida, capa de mariscal dorada. |
| `borin` | Capitán Borin Nubehierro | Pantalán de los Muelles; plaza del Bastión | Piloto del *Testaruda* y **maestro de viajes** de Umbral. | Enano de barba pelirroja con trenzas, casco de aviador, chaqueta de cuero con borreguito. |
| `albor` | Albor, el Viejo Dorado | Nido de Albor (sur del Bastión) | El último dragón leal del Vuelo, con un ala rota. Tras `umbral.matriarca`, vuela entre áreas ya visitadas de Umbral. | Dragón dorado viejo (sprite 2×2), escamas desvaídas, ala izquierda vendada con cadenas. |
| `fibulaEngranaje` | Fíbula Engranaje | Torre de los Astros → cúpula del Observatorio | Gnoma astrónoma, última cuidadora de la Lente; maestra de Vesper. Habla deprisa y en números. Guiño a los "gnomos del Umbral". | Gnoma diminuta, gafas de muchas lentes, bata índigo con estrellas, llave inglesa enorme. |
| `zigoMercader` | Zigo | Mercado del Bastión | El goblin mercader de siempre ("¡en el cielo, todo es *altamente* caro!"). Misión secundaria. | Goblin con mochila enorme y gafas de aviador. |
| `noraPosadera` | Nora | Posada del Dirigible Varado | Posadera (reaparición). Antigua grumete de Borin. | Humana pelirroja, pañuelo, delantal con hollín. |
| `thessa` *(opcional)* | Thessa | Torre de los Astros | La erudita de Lunaria/Cenizas ayuda a Fíbula a leer las notas de Vesper. | La de Cenizas, con bufanda índigo. |
| `hermanaBrasa` | Hermana Brasa | 2.º bastión del Puente (escena y `.clue`) | Heraldo de Rocaforja, **descartada por Vesper** y medio vaciada. Cuenta qué quiere Morvath. **No pelea.** | La de siempre, sin farol, con grietas negras de "hueco" en las manos. |
| enemigo `dragonMatriarch` | **Nixara, Matriarca del Vuelo** | Cumbre de los Nidos | Compañera de Albor. Jefe de zona. Víctima. | Ver `bestiario.md`. |
| enemigo `voidWarden` | **El Guardián de la Grieta** | Mazmorra `umbral.grieta` | Centinela forjado por los Herreros para vigilar la mayor grieta; el vacío lo vació. Jefe de la mazmorra. | Ver `bestiario.md`. |
| enemigo `starHerald` | **Corvino el Astrólogo** | Cúpula del Observatorio | **Heraldo de Escarcha**; aquí sí pelea. Jefe de zona. | El de Escarcha (`corvino`), con la túnica rasgada y el astrolabio encendido. |
| enemigo `grandHerald` | **Vesper, la Gran Heraldo** | Puerta del Yunque (Puente) | **Sexto Heraldo y la que los dirige a todos** desde la Lente. Jefa de zona. | Ver `bestiario.md`. |
| enemigo `morvath` | **Morvath, el Herrero Hueco** | Banda `umbral.yunque` | El séptimo Herrero. **Jefe final del juego.** | Ver `bestiario.md`. |

Pistas (`.clue`): `notaVesper` (cúpula: "Maestra: la Luna no os protegía. Os encerraba fuera."), `cartaBrasa2`
(2.º bastión: lo que la Brasa no llegó a decir), `estelaFarero` (Muelles, ambiente).

Frases de muestra (cortas, para el `story-writer`):
- Aurora: "Seis brasas. Una llave. Ningún paso atrás."
- Albor: "Los dragones no lloran, pequeño. Solo arden más despacio."
- Fíbula: "La Lente está vacía. Vacía. ¡Cero de cero!"
- Corvino (al caer): "Yo solo quería verla entera… una vez."
- Hermana Brasa: "Ya no le sirvo. Lo dije yo misma, ¿sabes? Muchas veces."
- Morvath: "Me arrancaron el fuego del pecho y lo colgaron en el cielo. Vengo a por él."

### Líneas por raza (solo diálogo)

| Momento | Humano | Enano | Elfo | Hombre lobo |
|---|---|---|---|---|
| Llegada | "El suelo… no está. Abajo no hay nada." | "Una forja en el cielo. Mi abuelo no me creería." | "Aquí la Luna ni siquiera calla. No está." | "No huele a nada. El vacío no huele." |
| Hoja del Alba (VI) | "Pesa como mi pueblo entero." | "Seis fuegos y ni una grieta. Buen trabajo, viejo." | "Canta con seis voces." | "Por fin no me duele la Luna." |

## 4. Lo que pasa (por actos)

**Acto I · Muelles y Nidos (50-54).** El *Testaruda* de Borin atraca en los **Muelles del Cielo** con el héroe, Brokk
y lo que queda de la guarnición de Hielomar. Los **constructos celestes** ya no distinguen amigos de enemigos y las
**gárgolas estelares** anidan en el faro roto. El héroe se abre paso hasta el **Bastión**, donde Aurora y el Mariscal
Hálvar lo esperan: Morvath ya está en el Yunque y el Eclipse tiene el Molde con dos Ascuas. Aurora lo manda con
**Albor**: los dragonantes corrompidos derriban dirigibles y su compañera **Nixara** los guía. En la Cumbre, al caer,
Nixara vuelve en sí y empuja hacia el héroe su último **huevo dorado**: "Que no nazca a oscuras". Albor, desde
entonces, lleva al héroe volando entre las islas.

**Acto II · Islas Rotas, Grieta y Observatorio (54-58).** Fíbula necesita "lágrimas" de los ojos del vacío para
encender el puente norte del Bastión. Las Islas Rotas se desmoronan; la Grieta crece porque algo la abre desde
abajo: el **Guardián de la Grieta**. En la mazmorra, sobre plataformas que flotan en la nada, el héroe lo vence y la
grieta se cierra a medias. En el **Observatorio**, tomado por la élite del Eclipse, la cúpula está ocupada por
**Corvino**, que intenta volver a encender la Lente para ver la Luna "entera". Vencido, comprende el engaño: Vesper
se llevó el Molde y las dos Ascuas al Yunque y lo dejó allí "mirando el cielo". Se apaga convertido en una estatua de
cristal de luna. Fíbula encuentra la `notaVesper`: su aprendiz fue la Heraldo que dirigía a los otros cinco; desde la
Lente lo veía todo, por eso el Eclipse sabía siempre dónde estaban las Ascuas.

**Acto III · El Puente y la llave (58-59).** En el **Puente del Yunque** guardan el paso los **herreros huecos**:
herreros de la Alianza que Morvath vació. En el segundo bastión, encadenada, está la **Hermana Brasa**: Vesper la
descartó con sus mismas palabras ("ya no nos sirves") y la dejó vaciarse (el Molde se lo había dado Corvino). Antes de que se le apague la voz, la
Brasa cuenta la verdad (§6). Ante la puerta del Yunque, **Vesper** vierte el Ascua de Umbral en el Molde (tercera
colada). El héroe la vence: el Molde se **raja**, las dos Ascuas caen a los pies del héroe… y Morvath, desde el Yunque,
**arrastra hacia sí los pedazos del Molde** y su fuego a medias. Vesper muere mirando la Luna apagada.
En el Bastión, ante el último yunque, Brokk despierta la **Hoja del Alba (VI)** con el **Ascua de Escarcha** y el
**Ascua de Umbral**: seis brasas (Valdemar, Rocaforja, Lunaria, Cenizas, Escarcha, Umbral). Toda la Alianza en la
plaza; Albor sobre la muralla.

**Acto IV · El Yunque del Alba (60, banda).** Oleadas de la guardia de Morvath y, sobre el Yunque, **Morvath** con la
**Hoja del Ocaso a medias** soldada al brazo. Tres fases (`bestiario.md`). En la última intenta **arrancar las seis
brasas** de la Hoja del Alba apagando las estatuas de los Herreros; la Hoja responde y las enciende. Morvath cae de
rodillas sobre el Yunque.

## 5. Misiones (resumen)

Tabla completa en formato `Quest` en `zonas.md` §6.

| # | Id | Nv. | Da | Qué pasa |
|---|---|---|---|---|
| 1 | `umbral.llegada` | 50 | `borin` | Cruzar los Muelles y llegar al Bastión. |
| 2 | `umbral.el_viejo_albor` | 52 | `princess` | Conocer a Albor y llegar a los Nidos. |
| 3 | `umbral.matriarca` | 54 | `albor` | Vencer a Nixara; el huevo dorado; el vuelo de Albor. |
| 4 | `umbral.puente_de_luz` | 54 | `fibulaEngranaje` | Lágrimas de los ojos del vacío; se enciende el puente norte. |
| 5 | `umbral.la_grieta` | 57 | `princess` | Mazmorra: el Guardián de la Grieta. |
| 6 | `umbral.observatorio` | 58 | `fibulaEngranaje` | Vencer a Corvino en la cúpula; la nota de Vesper. |
| 7 | `umbral.la_brasa` | 58 | `halvar` | Llegar al 2.º bastión y leer a la Hermana Brasa. |
| 8 | `umbral.gran_heraldo` | 59 | `princess` | Vencer a Vesper; recuperar las Ascuas de Escarcha y de Umbral. |
| 9 | `umbral.sexta_brasa` | 59 | `brokk` | **Hoja del Alba (VI)**. |
| 10 | `umbral.herrero_hueco` | 60 | `princess` | **Banda**: Morvath. Final del juego. |

Secundarias (8): `chatarra_celeste`, `rayas_de_zigo`, `cazadragones`, `cielo_en_calma`, `descanso`, `paso_en_vacio`,
`enmascarados`, `herreros_huecos`. Repetible tras el final: `umbral.eco_de_morvath`.

## 6. Morvath: la verdad (cierre del hilo)

Lo que cuenta la Hermana Brasa en el Puente y confirma Morvath en la banda, juntando los murales de Cenizas:

- Los **Herreros eran siete** (Cenizas). Morvath, el séptimo, forjaba los metales del mundo y quiso fundir las Ascuas
  en la Hoja del Ocaso para rehacerlo "bien hecho".
- Para vencerlo, los otros seis **le arrancaron el fuego del pecho** y lo colgaron en el cielo: **la luz de la Luna
  es su propia llama**, enfocada por la Gran Lente con el Ascua de Umbral. Por eso lo llaman **Hueco**, y por eso la
  Luna es a la vez su cárcel y su corazón (propuesta 6 de Cenizas, que adopto).
- El **Molde del Ocaso** no era para rehacer el mundo, como creían los Heraldos: era para **llenar de nuevo el pecho
  vacío de Morvath** con seis brasas. Cada Heraldo creyó una mentira distinta (Morcar el poder, la Brasa la venganza,
  Ysolde que la Luna no muriera, Ozrán el saber, Corvino la Luna entera, Vesper "la libertad del cielo").
- La **Hoja del Alba es la llave** (Cenizas): la que arda con seis brasas "cierra la puerta… o la abre". Si Morvath
  la toma, se llena; si la gira el héroe, lo cierra.

## 7. El final (propuesta, decisión 5 de `mundo.md`, *a confirmar*)

- **La llave gira.** Con Morvath de rodillas, el héroe hunde la Hoja del Alba (VI) en el Yunque. Las seis brasas no
  se apagan: **cierran**. Morvath queda sellado **en el Yunque**, no en la Luna, bajo la guardia de los vivos.
  Sus últimas palabras: "Al menos… dejadme oír el martillo."
- **La Luna se enciende.** Fíbula devuelve el Ascua de Umbral a la Gran Lente: la luz vuelve, pero ya no es la llama
  robada de Morvath sino el fuego del Yunque cerrado. Primera **luna llena** en veinte años en toda Ardenia.
- **El Molde del Ocaso**: Brokk funde sus pedazos en el Yunque. "Ni una hoja más." (La pieza `boss.morvath` sale de
  ese metal: ver `piezas.md`.)
- **Destinos**: Aurora, **guardiana del Yunque**. Hálvar devuelve el Ascua de Escarcha a Hielomar y la Jarla le da
  sitio junto al fuego. Albor reúne lo que queda del Vuelo; el **huevo de Nixara** eclosiona (cría dorada: gancho de
  mascota futura). La **Hermana Brasa** sobrevive, hueca a medias, y pide volver a Hondoyunque a que la juzguen los
  Thanes ("vuelvo a casa"). **Corvino** queda como estatua de cristal en la cúpula, mirando la Luna encendida.
  **Vesper** cae al vacío desde el Puente. El héroe conserva la Hoja: es la única llave, y nadie más puede girarla.
- Epílogo: una línea por capital (aldeanos importantes de los seis capítulos) y créditos.
- **Endgame**: Umbral sigue siendo zona de nivel 60. Monstruos de campo y la banda repetible `umbral.eco_de_morvath`
  ("el eco de Morvath sigue golpeando el yunque desde dentro").

*Alternativa agridulce* (si se elige en la decisión 5): Morvath es destruido, no sellado; la Luna se apaga para
siempre y Ardenia aprende a vivir con noches oscuras. Solo cambian el epílogo y las últimas frases; la banda es igual.

## 8. Hilo con los otros continentes

| Continente | Enlace |
|---|---|
| Valdemar | El Eclipse siempre quiso la **Hoja del Alba**: ahora se sabe por qué (es la llave y lleva las brasas). Aurora cierra su arco como guardiana. |
| Rocaforja | La **Hermana Brasa** termina aquí (descartada, vuelve a casa a ser juzgada). Brokk funde el Molde que salió de la Forja Profunda. |
| Lunaria | Thessa (opcional) ayuda a Fíbula. Ysolde entre las "mentiras de los Heraldos". |
| Cenizas | Siete Herreros, Severián **primer Heraldo**, la Hoja-llave, la luz de la Luna como llama de Morvath: todo se confirma. |
| Escarcha | Llegada en el *Testaruda*; requisito `escarcha.quinta_luz`. Corvino (`starHerald`) pelea aquí. **Ser Hálvar** = Mariscal Hálvar (`halvar`). Se recupera el **Ascua de Escarcha**. La Hoja (V, Corona) pasa a (VI). |

---

## Propuestas al world-designer

> **Respuesta del world-designer (revisión de coherencia 1, 2026-10-09)**: cada propuesta está aceptada, ajustada,
> rechazada o marcada PENDIENTE DEL USUARIO, con su razón, en `assets/world/mundo.md` §13; las contradicciones
> corregidas en este continente, en `mundo.md` §14; los renombres, en `assets/world/continentes.md` (registros comunes).

1. **Cambiar `mundo.md` §5, fila de Umbral**: "Recuperar el Ascua de Escarcha y el Ascua de Umbral de manos de Vesper;
   Hoja del Alba (VI) con seis brasas; cerrar la puerta del Yunque a Morvath." Cronología: "Hace un mes: Vesper
   arranca el Ascua de Umbral de la Gran Lente; la Luna se apaga del todo."
2. **Vesper es el sexto Heraldo y el que los dirige** (no el primero: ese es Severián, de Cenizas). Lo veía todo
   desde la Lente.
3. **Adopto la propuesta 6 de Cenizas** (la luz de la Luna es la llama arrancada a Morvath). Es lo que hace que
   "Hueco", la Luna, el Molde y la Hoja-llave encajen en una sola explicación.
4. **Final**: sigo la propuesta 5 con un matiz: Morvath queda sellado **en el Yunque** (no en la Luna) y la Luna se
   reenciende con el fuego del Yunque cerrado. *Alternativa agridulce* lista en §7.
5. **Cinco jefes** (Nixara, Guardián, Corvino, Vesper, Morvath) en vez de 2-4, como Escarcha: Corvino tiene que
   pelear en algún sitio y la zona 4 no tenía jefe. Si se quieren 4, Corvino vuelve a ser escena y el Observatorio
   se cierra con el Campeón del Eclipse (élite).
6. **Mithril (muy rara de Umbral) escalado por continente** en la historia (`minerales.md`).
7. **Albor como vuelo dentro del continente** (no entre continentes: eso es Borin). Si el motor no lo permite fácil,
   Albor es solo NPC.
