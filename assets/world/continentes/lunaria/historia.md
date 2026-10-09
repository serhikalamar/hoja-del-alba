# Lunaria — historia del capítulo 3 (niveles 20-30)

Responsable: `continent-lead` de `lunaria`. Estado: **borrador 1** (2026-10-07), **fase futura** (se implementa
después de Valdemar y Rocaforja). Brief: `brief.md`. Emoción: *misterio y reconciliación*. Paleta: azul noche,
plata, verde musgo (luces frías de luna; ámbar cálido solo en las casas y hogueras).

## 1. En pocas líneas

El héroe sale del **Túnel de los Thanes** a un bosque de árboles de plata donde la luz de la luna se bebe en los
claros. Pero la Luna se apaga y algo envenena esa luz: los árboles se marchitan y algunos hombres lobo enloquecen
(la **Mala Luna**). Los **elfos de Velaluna** culpan a los **clanes de Colmillo Gris**; los lobos culpan a la magia
élfica. La culpable es **Ysolde, la Archimaga Marchita**, consejera de la reina y Heraldo del Eclipse: echa
*savia negra* (luz de luna envenenada con fuego del Eclipse) en los claros para que el Árbol Madre se pudra y
deje al descubierto el **Ascua de Lunaria** que guarda en su corazón.
El héroe trabaja para los dos bandos, desenmascara a Ysolde, la vence en el **Hueco del Árbol Madre** y sella el
**Pacto de la Luna**: elfos y lobos entran en la Alianza del Alba. Brokk despierta la **Hoja del Alba (III)**.

## 2. Quién manda y qué amenaza

| Facción | Dónde | Quién manda | Qué quiere |
|---|---|---|---|
| Elfos de Velaluna | Ciudad en las copas (Velaluna), Claros de la Luna | **Reina Elarith** (anciana, cansada, confía en Ysolde) | Proteger los claros. Cree que los lobos los envenenan. |
| Clanes lobo | Aldea de Colmillo Gris, Espesura del Aullido | **Matriarca Ulma** (alfa de los clanes) | Curar a sus hijos enloquecidos. Cree que es una maldición élfica. |
| Mala Luna | Espesura del Aullido | **Garra Negra** (Varg, hijo de Ulma) | Nada: son lobos enfermos de savia negra, salvajes. |
| Orden del Eclipse | Torre de Ysolde, Bosque Marchito, Lago de la Luna Caída | **Ysolde, la Archimaga Marchita** (Heraldo) | El Ascua de Lunaria para la Hoja del Ocaso. |

**Cómo conecta con la historia principal**: tras Rocaforja, Aurora sabe que el Eclipse busca la siguiente Ascua. El
mensajero élfico (el héroe, si es elfo) ya avisó de que la Luna enfermaba. El enano Brokk acompaña al héroe por el
Túnel: en Velaluna le prestan la forja élfica para despertar la Hoja del Alba cuando llegue el Ascua. Al terminar,
Aurora fleta un barco en el Puerto de Valdemar hacia Cenizas (lo hace el maestro de viajes).

## 3. Personajes clave

| Id (NPC) | Nombre | Dónde | Papel | Aspecto (para `pixel-artist`) |
|---|---|---|---|---|
| `princess` | Princesa Aurora | Velaluna, plaza | Da la misión principal y la cierra (como en cada capital). | La de siempre, capa de viaje azul. |
| `brokk` | Brokk Martillohondo (*nombre a confirmar en `mundo.md`*) | Velaluna, forja élfica | Despierta la Hoja del Alba (III). Gruñe por los árboles ("¿dónde está la roca?"). | El enano herrero de siempre. |
| `elarith` | Reina Elarith | Velaluna, palacio | Reina élfica. Primero culpa a los lobos; al final firma el Pacto. | Elfa anciana, pelo plata hasta el suelo, corona de ramas, túnica blanca. |
| `sylra` | Capitana Sylra | Velaluna, plaza / Claros | Capitana de la Guardia de las Copas. Desconfiada, honrada: la primera en creer al héroe. | Elfa, armadura de plata ligera, capa verde musgo, arco largo. |
| `ysolde` | Ysolde, la Archimaga | Velaluna, torre (antes de la revelación) | Consejera de la reina y Heraldo del Eclipse. Amable, persuasiva. Jefe final. | Elfa alta, túnica violeta oscuro con bordado de plata, báculo con una luna negra. Tras la revelación: piel gris, hojas secas en el pelo, ojos ámbar. |
| `thessa` | Thessa | Claros de la Luna (Ara de los Claros) | Aprendiz de Ysolde. Sospecha de su maestra; da las pistas. | Elfa joven, túnica azul, libro bajo el brazo, gafas redondas. |
| `fendril` | Maese Fendril | Velaluna, forja | Herrero élfico: vende plata y fresno (tier 3) y las formas élficas. | Elfo, delantal de cuero, brazos finos, martillo de plata. |
| `mirla` | Mirla la hierbera | Velaluna, casa de la hierbera | Misiones de setas y espinos. Cotilla. | Elfa mayor, cesta de setas brillantes. |
| `ilmar` | Guardabosques Ilmar | Velaluna, plataforma del ascensor | Recibe al héroe; misiones de Raíces. | Elfo, capucha verde, lanza. |
| `nimra` | Nimra, maestra de vuelos | Velaluna, plataforma este | **Maestro de viajes**: búhos mensajeros gigantes a las capitales visitadas. | Elfa con guante de cetrería y un búho blanco. |
| `ulma` | Matriarca Ulma | Colmillo Gris, Gran Cubil | Alfa de los clanes. Sabia y dura; su hijo es Garra Negra. Firma el Pacto. | Mujer lobo vieja, pelaje gris casi blanco, collar de colmillos, bastón de fresno. |
| `rhovan` | Rhovan | Colmillo Gris, hoguera | Guerrero lobo exaltado: quiere la guerra con los elfos. Al final, amigo de Sylra. | Hombre lobo joven, pelaje pardo, cicatriz en el hocico, hacha. |
| `hirsa` | Hirsa la curtidora | Colmillo Gris, curtiduría | Vende piel de lobo y seda (tier 3) y los cueros del conjunto lunar. | Mujer lobo fornida, delantal, pieles colgadas. |
| `pico` | Pico | Espesura (perdido) → Colmillo Gris | Cachorro de lobo perdido (misión de rescate). | Lobezno chibi, bufanda roja. |
| `trapisonda` | Trapisonda | Raíces de Plata, campamento | Goblin buhonero neutral (guiño a Valdemar). Vende pociones/minerales comunes. | Goblin con mochila enorme y farolillo. |
| `varg` | Varg (Garra Negra curado) | Lago, al final | Aparece curado en el epílogo. | Hombre lobo negro, ya sin ojos rojos. |
| `liria` | Hermana Liria | Velaluna, santuario | Sacerdotisa de la Luna (bendice; diálogo de ambiente). | Elfa con velo plateado. |
| `tabernera` (*id: `posaderaVelaluna`*) | Ennis | Velaluna, posada | Posadera (reaparición). | Elfa sonriente con jarra de hidromiel. |

### Líneas por raza (solo diálogo, nunca bloquean nada)

- **Elfo** (su capítulo): Ilmar le reconoce ("¡El mensajero ha vuelto!"); en Colmillo Gris, Rhovan le gruñe
  ("Huele a copa de árbol. Fuera."); Ulma le pone a prueba con más dureza. Ysolde le llama "hijo de las copas"
  y le pide que vigile a los lobos (lo que hace la traición más dolorosa).
- **Hombre lobo** (su capítulo): en Velaluna la guardia le sigue con la mirada ("Mantén las garras quietas,
  bestia."); Elarith tarda en dirigirle la palabra. En Colmillo Gris le reciben como hermano y la Mala Luna "le
  llama" (frase en la Espesura: "Oyes un aullido que te pide que te rindas. No lo haces.").
- **Humano / enano**: forastero neutral; ambos bandos le usan de mensajero. Brokk comenta con los enanos.

## 4. Misiones principales (en orden)

Ids `lunaria.<nombre>`. Las secundarias están en `zonas.md` y en `encargos.md` (story-writer).

| # | Id | Da | Objetivo | Zona (niv.) | Qué pasa |
|---|---|---|---|---|---|
| 1 | `lunaria.bajo_las_raices` | Brokk (salida del Túnel) | Llegar a Velaluna | Raíces (20) | El héroe y Brokk salen del Túnel. Ilmar los sube en el Gran Ascensor. |
| 2 | `lunaria.luz_enferma` | Reina Elarith | Llegar al Claro del Abuelo y vencer 6 espíritus del bosque | Claros (22-23) | La luz de los claros está enferma. Ysolde, a su lado, sugiere "mirad si hay huellas de lobo". |
| 3 | `lunaria.abuelo_fresno` | Capitana Sylra | Vencer al **Abuelo Fresno Podrido** (`rottenElder`) | Claros (23) | Junto al árbol caído, huellas de garra (falsas). La reina declara a los lobos culpables. |
| 4 | `lunaria.embajada` | Aurora | Hablar con la Matriarca Ulma en Colmillo Gris | Colmillo Gris | Aurora pide una última embajada antes de la guerra. Los lobos reciben mal al héroe. |
| 5 | `lunaria.mala_luna` | Ulma | Vencer 10 lobos de la Mala Luna | Espesura (24-25) | Ulma cuenta que su hijo Varg lidera a los enloquecidos. Rhovan quiere atacar Velaluna. |
| 6 | `lunaria.garra_negra` | Ulma | Vencer a **Garra Negra** (`blackClaw`) en su cubil | Espesura (26) | Varg cae (no muere: queda inconsciente). Lleva al cuello un frasco de *savia negra* con seda de araña. |
| 7 | `lunaria.nido_tejedoras` | Thessa | Superar la mazmorra **Nido de las Tejedoras** (piso `webs`) y vencer a la **Madre Tejedora** (`broodMother`) | Mazmorra (25-27) | La seda del frasco sale del Nido. Dentro: cartas de Ysolde que "alimenta" a las arañas con savia negra para tejer los frascos. |
| 8 | `lunaria.la_verdad` | Thessa | Llevar las cartas a la Reina Elarith | Velaluna | Revelación: Ysolde se quita la máscara, marchita la plataforma de su torre y huye al Bosque Marchito. Sylra y Rhovan, juntos por primera vez. |
| 9 | `lunaria.bosque_marchito` | Sylra y Rhovan | Vencer 10 elfos marchitos y 3 árboles corruptos | Marchito (26-28) | Patrulla conjunta de elfos y lobos (NPC de ambiente). Primer gesto de confianza. |
| 10 | `lunaria.aras_lunares` | Thessa | Llegar a las 3 aras del Lago y vencer a sus guardianes | Lago (28-29) | Purificar las aras abre el puente al Árbol Madre. |
| 11 | `lunaria.arbol_madre` | Reina Elarith y Matriarca Ulma | Superar el **Hueco del Árbol Madre** (piso `hollow`) y vencer a **Ysolde** (`ysolde`) | Final (29-30) | Ysolde intenta arrancar el Ascua. Al caer, la luz vuelve al árbol. El héroe toma una **brasa del Ascua de Lunaria** (el Ascua se queda en el Árbol). |
| 12 | `lunaria.pacto_de_la_luna` | Aurora | Hablar con Elarith y Ulma en la orilla del Lago; después, con Brokk | Lago → Velaluna | Firman el Pacto de la Luna (Varg aparece curado). Brokk despierta la **Hoja del Alba (III)**. Aurora: "Al sur, el desierto. Fletaré un barco." Se abre el viaje a Cenizas. |

Recompensas grandes: la 3, 6, 7 y 11 dan además la pieza del jefe (`boss.<id>`); la 11 da 100 % de un nivel, la 8 y
la 12 un 50 %. El conjunto `*.lunaria` sale de misiones (ver `piezas.md`).

## 5. El final del continente

En el Hueco del Árbol Madre, Ysolde confiesa que lo hizo "para que la Luna no muera sola": Morvath le prometió que
con la Hoja del Ocaso volvería a encender la Luna para siempre. Cae, y su báculo se rompe con un eco que dice
*"…quedan tres"*. El Árbol Madre vuelve a brillar, la Mala Luna se apaga en los ojos de los lobos y Varg despierta.
En la orilla del Lago, la Reina Elarith y la Matriarca Ulma cruzan una rama de fresno y un colmillo: el **Pacto de
la Luna**. Elfos y lobos se suman a la Alianza del Alba. Aurora fleta el barco a Cenizas; Thessa se une a la
Alianza como erudita (gancho: "Lo que dijo Ysolde de la Luna… está escrito en las ruinas de Solarum").

## 5b. Hilo con Rocaforja y Cenizas (Hermana Brasa y el Molde del Ocaso)

Rocaforja termina con la **Hermana Brasa** (Heraldo de Rocaforja, `hermanaBrasa`) huyendo por el Túnel de los Thanes
con el **Molde del Ocaso** (`rocaforja/historia.md`). En Lunaria:
- **Misión 1**: al salir del Túnel, Trapisonda cuenta que "una encapuchada con un farol negro" pasó corriendo hacia
  los Claros. (Solo diálogo.)
- **Misión 7** (cartas del Nido): Ysolde recibió el Molde y lo está **templando con savia negra** para que aguante el
  fuego de las Ascuas. Por eso necesita el Ascua de Lunaria.
- **Misión 11**: al caer Ysolde, la Hermana Brasa aparece un instante en el Hueco, recoge el Molde (ya templado) y
  huye "hacia el sur, donde el sol quema". *El Eclipse gana algo* (como en Rocaforja) y queda el gancho de Cenizas.
  La Brasa no pelea (igual que en Rocaforja): es un NPC de escena en `StoryDungeon.bossDefeat`.

## 6. Propuestas al world-designer

> **Respuesta del world-designer (revisión de coherencia 1, 2026-10-09)**: cada propuesta está aceptada, ajustada,
> rechazada o marcada PENDIENTE DEL USUARIO, con su razón, en `assets/world/mundo.md` §13; las contradicciones
> corregidas en este continente, en `mundo.md` §14; los renombres, en `assets/world/continentes.md` (registros comunes).

1. **Garra Negra se cura, no muere** (Varg vuelve en el epílogo). El combate es igual; solo cambia el diálogo.
2. **Viajes**: el maestro de viajes de Lunaria es una maestra de vuelos con **búhos gigantes** (solo estética; misma
   mecánica del maestro de viajes).
3. **Thessa** como personaje que viaja a Cenizas (puente narrativo con "la verdad sobre Morvath").
4. **Bioma `lunariaCanopy`** para Velaluna, distinto del bioma `lunaria` del suelo del bosque (ver `mapas/velaluna.md`).
