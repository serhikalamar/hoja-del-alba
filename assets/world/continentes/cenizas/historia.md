# Cenizas · historia del capítulo 4 — *Ruina y verdad*

Responsable: `continent-lead` de `cenizas`. Estado: **borrador 2** (2026-10-08), **fase futura** (se implementa después
de Valdemar, Rocaforja y Lunaria). Niveles **30-40**. Hermanos: `zonas.md`, `mapas/`, `bestiario.md`,
`minerales.md`, `piezas.md`, `encargos.md`. Formato de datos: el de Valdemar (`../valdemar/contrato.md`).

## 1. En pocas líneas

El barco de Aurora llega al Yermo de Cenizas siguiendo a la **Hermana Brasa**, que huyó de Lunaria con el **Molde del
Ocaso** ya templado. Aquí la espera **Ozrán el Desenterrador**, el arqueólogo de la Alianza que fundó la excavación
del Fortín del Oasis y que, tras oír a Morvath en una noche sin luna, se ha convertido en el **Heraldo del Eclipse**
de Cenizas. El Molde necesita el fuego de un Ascua, y el Ascua de Cenizas solo obedece a quien ya ardió con ella:
el **Emperador Ceniciento**, que hace mil años intentó robarla. Ozrán lo despierta. En la **Tumba de Solarum**, los
murales cuentan la Guerra del Ocaso, quién es Morvath y qué es de verdad la Hoja del Alba: la historia cambia de
marcha. En la Caldera del volcán Brasamadre el héroe vence al Emperador y gana la **brasa del Ascua de Cenizas**… pero la
Hermana Brasa recoge en el Molde la primera colada de fuego y huye al norte.

## 2. El lugar y quién manda

- Desierto de **ceniza y arena negra** al sur del mar: costas de escoria, dunas negras, oasis de vapor, el volcán
  **Brasamadre** y, enterrado, el **Imperio de Solarum** (templos dorados, legiones de bronce, un emperador que se
  llamaba a sí mismo *Sol Invicto*). Negro, gris ceniza, rojo lava y oro viejo; el oasis pone el único verde y azul.
- **Nadie manda.** La Alianza tiene una avanzada, el **Fortín del Oasis**, que creció alrededor de la excavación de
  Ozrán (*la Cata*). En las dunas viven los nómadas del **Clan Duna**, descendientes de los esclavos que huyeron del
  incendio; los **trolls de ceniza** del rey Gorrak les disputan los pozos.

| Facción | Dónde | Quién manda | Qué quiere |
|---|---|---|---|
| Alianza del Alba | Fortín del Oasis | **Comandante Dorna Yelmorrojo** (con Aurora de visita) | Encontrar a la expedición perdida y que el Eclipse no saque nada del desierto. |
| Clan Duna (nómadas) | Pozos de las Dunas Negras | **Yalia, la Guía de las Dunas** | Conservar sus pozos. Desconfía de todos los que cavan. |
| Trolls de ceniza | Trono de Hueso | **Gorrak, Rey de las Dunas** | Los pozos y el oro que le paga Ozrán. |
| Solarum no-muerto | Necrópolis, Ciudad Sepultada | **El Emperador Ceniciento** (dormido, luego despierto) | Terminar el robo de hace mil años. |
| Orden del Eclipse | Necrópolis, Laderas, Sepultada | **Ozrán el Desenterrador** (Heraldo) y la **Hermana Brasa** | Llenar el Molde del Ocaso con el fuego del Ascua de Cenizas. |

## 3. Personajes clave

| Id (NPC / enemigo) | Nombre | Dónde | Papel | Aspecto (para `pixel-artist`) |
|---|---|---|---|---|
| `princess` | Princesa Aurora | Fortín, puesto de mando | Misión principal. En los murales entiende qué es su linaje. | La de siempre, capa de viaje clara con capucha contra la arena. |
| `thessa` | Thessa | Fortín, archivo; Necrópolis; Sala de los Murales | **Viene de Lunaria** con Aurora (antigua aprendiz de Ysolde). Erudita: traduce los murales. Línea de "la verdad". | Elfa joven, túnica azul, gafas redondas, libro; aquí con pañuelo de arena. |
| `brokk` | Brokk Martillohondo (*nombre a confirmar*) | Fortín, forja (solo al final) | Llega en el último barco para despertar la Hoja del Alba (IV). | El enano herrero de siempre. |
| `dornaComandante` | Comandante Dorna Yelmorrojo | Fortín, delante del puesto de mando | Jefa del Fortín. Seca, práctica, odia la arena en la barba. Desconfió siempre de Ozrán. Misiones militares. | Enana, armadura de bronce con capa roja descolorida, yelmo con penacho rojo, barba trenzada. |
| `tovaHerrera` | Tova Fundehierro | Fortín, forja | Herrera enana: forja tier 4 (obsidiana, hueso) y las formas de Cenizas. Misiones de materiales. | Enana, delantal de cuero de troll, gafas de herrera, brazos tiznados. |
| `sedraPosadera` | Sedra | Fortín, posada *La Cantimplora* | Posadera (reaparición). Rumores. | Humana morena, turbante naranja, jarra de agua fresca. |
| `zigoMercader` | Zigo | Fortín, mercadillo | **El mismo goblin de Hondoyunque**: sigue a la Alianza "porque donde hay soldados hay clientes". | Goblin con mochila enorme; aquí con sombrero de paja. |
| `margaCapitana` | Capitana Marga Velasalada | Fortín, poste de viajes; Costa, embarcadero | **Maestra de viajes** (barco *La Gaviota Tuerta*; misma mecánica que Frida). Al final añade Hielomar. | Humana curtida, tricornio, pata de palo, loro gris. |
| `yaliaGuia` | Yalia, la Guía de las Dunas | Dunas, jaima | Jefa del Clan Duna. Lleva la cara tapada; conoce las canciones antiguas de Solarum. | Humana alta, velo negro y túnica índigo, bastón con campanillas. |
| `solanoEspiritu` | Espíritu de Solano | Necrópolis, Sala de los Murales | El Gran Sacerdote vencido, ya en su sano juicio. Cuenta la verdad. | Fantasma dorado pálido de sacerdote, disco solar en la espalda. |
| `hermanaBrasa` | Hermana Brasa | Escenas (Costa, Laderas, Caldera) | **Heraldo de Rocaforja** que trae el Molde. Nunca pelea (como en Rocaforja y Lunaria): habla, enciende y huye. | La de Rocaforja: encapuchada de ceniza con farol de fuego negro; ahora lleva el Molde a la espalda. |
| enemigo `ashHerald` | **Ozrán el Desenterrador** | Ciudad Sepultada, palacio | **Heraldo del Eclipse de Cenizas.** Maestre arqueólogo de Valdemar. Cree que despertar al Emperador "terminará la historia". Élite de historia. | Humano flaco, gafas de latón agrietadas, túnica de explorador gris quemada, pala de bronce que arde violeta. |
| enemigo `ashTrollKing` | **Gorrak, Rey de las Dunas** | Dunas, Trono de Hueso | Rey troll pagado con oro de Solarum para echar a los nómadas. Jefe de zona. | Troll enorme gris ceniza, corona de costillas, hacha de bronce imperial. |
| enemigo `colossalScorpion` | **Aguijón Negro** | Necrópolis, Puerta del Sol | Escorpión colosal que los sacerdotes criaron para guardar la Tumba. Jefe de zona. | Escorpión negro brillante, aguijón dorado, inscripciones solares en el caparazón. |
| enemigo `sunHighPriest` | **Gran Sacerdote Solano** | Mazmorra `cenizas.tumba` | Hace mil años se negó a abrir el santuario y el Emperador lo emparedó vivo. Mil años de rabia. | Esqueleto alto con máscara solar de oro y túnica blanca podrida, báculo con disco. |
| enemigo `ashEmperor` | **Severián, el Emperador Ceniciento** | Mazmorra `cenizas.caldera` | Último emperador de Solarum y **primer Heraldo** de la historia. Jefe final. | Gigante de ceniza con grietas de lava, corona de oro fundida a la cabeza, capa de brasas, jopesh. |

### Líneas por raza (solo diálogo)

- **Enano**: reconoce la obsidiana de los cuentos de Hondoyunque; Dorna le habla como a un recluta ("¿de qué clan?").
- **Elfo**: lee a medias la escritura de los murales antes que Thessa ("…*siete*. Pone siete.").
- **Hombre lobo**: en las noches sin luna del desierto "la Luna sangra"; Yalia lo respeta más que a nadie.
- **Humano**: Aurora le confía su miedo tras los murales ("¿y si mi linaje no guarda una espada… sino una llave?").

## 4. Lo que pasa (por actos)

**Acto I · La avanzada (30-34).** *La Gaviota Tuerta* atraca en la **Costa de Escoria**. Hay un barco de velas negras
varado más allá del faro: la Hermana Brasa llegó antes. En el Fortín, Dorna cuenta que Ozrán bajó a la Cata una
noche sin luna y desapareció con media expedición. Thessa lee el primer mural roto (un sol negro sobre una ciudad en
llamas) y recuerda las palabras de Ysolde. En el **faro roto**, el diario del ayudante de Ozrán: "el maestre habla
solo de noche… dice que la Luna le contesta" y "vino una mujer con un farol negro; traía un molde de piedra". Las
huellas llevan a las **Dunas Negras**, donde los trolls de Gorrak acosan al Clan Duna con armas de bronce de Solarum.
Al vencer a Gorrak, Yalia entrega el camino a la Necrópolis ("la canción dice: la puerta duerme bajo el aguijón").

**Acto II · La verdad (34-37).** En la **Necrópolis** el Eclipse ya excava y las momias se levantan solas. El
**Aguijón Negro** guarda la Puerta del Sol. Dentro de la **Tumba de Solarum**, el héroe vence al **Gran Sacerdote
Solano**, que al caer recupera la razón. En la **Sala de los Murales**, con Thessa y el espíritu de Solano, se leen
los cuatro murales (§5). Ahora se sabe qué quiere el Eclipse: no basta con robar el Ascua, quiere **verterla en el
Molde**, y para eso necesita al Emperador.

**Acto III · El volcán (36-40).** En las **Laderas de Brasamadre**, tres **braseros violeta** forman el círculo que
guiará el fuego del Ascua hasta el Molde; la Hermana Brasa los enciende y se esfuma. El héroe los apaga. En la
**Ciudad Sepultada**, en el palacio enterrado, alcanza a **Ozrán**: cae de rodillas ("solo quería saber cómo
terminaba"). La Hermana Brasa aparece, le dice "ya no nos sirves", y una mano de ceniza lo arrastra a la grieta: el
Emperador ha despertado. Se abre la **Caldera de Brasamadre**. Sobre el Ascua, **Severián** pelea con la corona
fundida a la cabeza; mientras, la Brasa sostiene el Molde sobre la lava. Al caer el Emperador, el Ascua lo deja ir
("dile a la Luna… que no fui el último"). El héroe toma una **brasa** del Ascua (el Ascua vuelve a dormir en el volcán); la Brasa, la **primera colada** de fuego en el
Molde, y huye al norte, "donde cae la Luna". *El Eclipse gana algo*, como en Rocaforja y Lunaria.

**Epílogo.** Brokk llega en el último barco y, en la forja de Tova, despierta la **Hoja del Alba (IV)**. Aurora
manda a Marga fletar el barco del norte: si la Luna se rompe, Escarcha lo verá primero. Thessa se queda en el Fortín
copiando los murales (puede volver a aparecer en Escarcha: propuesta).

## 5. La escena de los murales (la "verdad")

Misión `cenizas.los_murales`, en el interior `cenizas.necropolis.murales`. Los cuatro murales son NPC con rol
`.clue` (se leen al acercarse, como la carta del alcalde); los comentan Thessa y el espíritu de Solano.

1. **Los Siete** (`muralSiete`). No eran seis Herreros Primeros: eran siete. El séptimo, Morvath, forjaba los metales
   del fondo; su forja quedó en lo hondo, sin luz. Fue el que más dio y el que menos recibió.
2. **La Guerra del Ocaso** (`muralOcaso`). Morvath quiso fundir las seis Ascuas en la Hoja del Ocaso para rehacer un
   mundo que le parecía mal hecho. Los seis lo vencieron y lo **sellaron en la Luna**; la Luna brilla con el fuego del
   Yunque, y **esa luz es el sello**. Cada noche sin luna, el sello se afloja.
3. **El sol negro** (`muralSolNegro`). Hace mil años, en la primera noche sin luna, el emperador Severián oyó una voz
   que le prometía la eternidad a cambio de un Ascua. Solano se negó a abrir el santuario y fue emparedado. El Ascua
   no se deja robar: ardió, y con ella el imperio. **El Emperador fue el primer Heraldo**: el Eclipse no es nuevo.
4. **La profecía completa** (`muralProfecia`). "Cuando la Luna calle seis veces, el Herrero Hueco volverá a su
   yunque. Solo la hoja que arda con seis brasas podrá cerrarle la puerta… o abrírsela." Thessa lo traduce; Aurora
   entiende que la **Hoja del Alba es la llave** y que el Molde del Ocaso es su contraria: dos hojas, una puerta.

Consecuencia: desde aquí la Alianza sabe que el sello no se arregla desde abajo; hay que llegar al Yunque del Alba
antes que el Eclipse. Encaja con Escarcha (`../escarcha/historia.md` §4: "Morvath está sellado en la Luna y la Luna
refleja el fuego del Yunque").

## 6. Misiones principales (en orden)

Tabla completa (con `requires`, objetivos en formato `Quest` y recompensas) en `zonas.md` §5.

| # | Id | Nv. | Da | Objetivo | Qué pasa |
|---|---|---|---|---|---|
| 1 | `cenizas.desembarco` | 30 | `princess` | Llegar al Fortín y hablar con Dorna | Llegada en barco a la Costa; barco negro varado. |
| 2 | `cenizas.la_cata` | 30 | `thessa` | Leer el mural de la Cata | Sol negro; Thessa recuerda a Ysolde. |
| 3 | `cenizas.rastro_de_ozran` | 31 | `dornaComandante` | Entrar en el faro roto y leer el diario | Ozrán oye a la Luna; la Brasa le trajo el Molde. |
| 4 | `cenizas.clan_duna` | 32 | `dornaComandante` | Hablar con Yalia en los Pozos | El Clan Duna y el oro de Solarum. |
| 5 | `cenizas.rey_de_las_dunas` | 34 | `yaliaGuia` | Vencer a Gorrak | Se abre el camino a la Necrópolis. |
| 6 | `cenizas.puerta_sellada` | 36 | `thessa` | Vencer al Aguijón Negro | Se abre la Tumba. |
| 7 | `cenizas.tumba_de_solarum` | 37 | `thessa` | Superar la mazmorra `cenizas.tumba` | Solano cae y recupera la razón. |
| 8 | `cenizas.los_murales` | 37 | `solanoEspiritu` | Leer los 4 murales | **La verdad.** |
| 9 | `cenizas.braseros_violeta` | 38 | `princess` | Apagar los 3 braseros violeta | El círculo del Molde, roto. |
| 10 | `cenizas.el_heraldo` | 39 | `princess` | Vencer a Ozrán | El Emperador despierta y se lleva a Ozrán. |
| 11 | `cenizas.emperador_ceniciento` | 40 | `princess` | Superar la mazmorra `cenizas.caldera` | Ascua de Cenizas; la Brasa huye con la colada. |
| 12 | `cenizas.cuarta_brasa` | 40 | `princess` | Hablar con Brokk en la forja | **Hoja del Alba (IV)**; barco del norte. |

## 7. El final del continente

- Se gana: **brasa del Ascua de Cenizas** (el Ascua se queda en el volcán), **Hoja del Alba (IV)**, la pieza única del Emperador y la **profecía completa**. La
  forja del Fortín pasa a vender también tier 5 (adelanto de Escarcha).
- Se abre: el barco del norte a **Hielomar** (Marga, maestra de viajes).
- El Clan Duna se suma a la Alianza (Yalia aparece en la plaza del Fortín tras el final).
- El Eclipse se lleva el **Molde del Ocaso con la primera colada**: el hilo Brasa-Molde sigue hacia Escarcha.

## 8. Hilo con los otros continentes

| Continente | Enlace |
|---|---|
| Rocaforja | La **Hermana Brasa** (`hermanaBrasa`) y el **Molde del Ocaso**. Zigo (`zigoMercader`) reaparece. Maestra de viajes con la mecánica de Frida. |
| Lunaria | Aurora fleta el barco a Cenizas al terminar `lunaria.pacto_de_la_luna` (requisito de `cenizas.desembarco`). **Thessa** viaja con ella y traduce los murales ("lo que dijo Ysolde de la Luna está escrito en Solarum"). La Brasa llega con el Molde templado con savia negra. |
| Escarcha | Se sale en el barco del norte. La Brasa huye al norte con el Molde (propuesta: se lo entrega a Corvino). La revelación del §5 es la que Escarcha da por sabida. |

## 9. Propuestas al world-designer

> **Respuesta del world-designer (revisión de coherencia 1, 2026-10-09)**: cada propuesta está aceptada, ajustada,
> rechazada o marcada PENDIENTE DEL USUARIO, con su razón, en `assets/world/mundo.md` §13; las contradicciones
> corregidas en este continente, en `mundo.md` §14; los renombres, en `assets/world/continentes.md` (registros comunes).

1. **Los Herreros eran siete.** Que `mundo.md` diga "seis Herreros Primeros… y un séptimo al que se olvidó a
   propósito" (los murales de Solarum son el único sitio donde aún aparece). No contradice nada de lo jugado.
2. **El Emperador Severián, primer Heraldo** (hace ~1000 años): añadir a la cronología "primera noche sin luna:
   Morvath habla a Severián". Implica que hubo noches sin luna hace mil años, no solo hace 20.
3. **La Hoja del Alba es una llave (abre o cierra)** y el Molde del Ocaso es "la otra hoja". Da tensión a Escarcha y
   Umbral.
4. **El hilo de la Hermana Brasa sigue en Escarcha**: entrega el Molde con la colada a Corvino (o lo usa ella en la
   Escala de Esquirlas). A coordinar con el lead de Escarcha.
5. **Fragmentos de la profecía en los capítulos 1-3**: un verso suelto en cada uno (cripta de la abadía, Forja
   Profunda, canto élfico de Velaluna) para que en Cenizas se "complete". Solo texto (story-writer de cada continente).
6. *(Opcional, más arriesgada)* **La luz de la Luna es la llama arrancada a Morvath** (por eso lo llaman "Hueco"):
   los Seis le sacaron el fuego del pecho y lo usaron de cerradura. Explicaría que las noches sin luna sean Morvath
   recuperando su llama. Si no se acepta, el mural 2 se queda como está arriba (compatible con Escarcha).
7. **NPC que viajan entre continentes** (`princess`, `brokk`, `thessa`, `zigoMercader`, `hermanaBrasa`): mismo id en
   varias áreas con `appearsWhen`. Confirmar que el registro de NPC lo permite (ya lo hacen Rocaforja y Lunaria).
