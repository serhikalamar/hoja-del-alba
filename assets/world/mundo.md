# Ardenia — biblia del mundo

Responsable: `world-designer`. Estado: **revisión de coherencia 1** (2026-10-09), tras el diseño de los 6 continentes.
Lo marcado **PENDIENTE DEL USUARIO** espera su decisión (lista al final, con recomendación); mientras tanto, los
documentos siguen la recomendación. Documentos hermanos: `continentes.md` (tabla de los 6, ids y registro de nombres),
`progresion.md` (niveles 1-60, tiers, ritmo, XP), `motor_comun.md` (lo que el motor necesita, una sola vez) y
`continentes/<id>/` (diseño de cada `continent-lead`).

> Regla de oro: lo que ya está en el juego (Valdehierro, sus aldeanos, sus enemigos, la Hoja del Alba, Brokk) **es
> canon**. Este documento lo explica y lo extiende; no lo contradice.

---

## 1. La idea en tres frases

Un MMO de fantasía clásico (World of Warcraft) en pixel-art chibi: **seis continentes**, cada uno con su pueblo,
su historia, sus monstruos y sus minerales, que el jugador recorre del **nivel 1 al 60**.
Lo que une todo es la **forja**: el mundo fue forjado, un herrero traidor quiere volver a forjarlo, y el héroe
lo detiene con un arma que va despertando continente a continente.
Cada continente es un "capítulo" de 10 niveles que se puede diseñar y construir por separado.

## 2. Tono

- **Aventura luminosa con sombras**: humor de taberna y aldeanos entrañables (como Valdehierro), pero una amenaza
  seria y creciente. Más *Warcraft III / WoW Classic* que *Dark Souls*.
- Cada continente tiene **un color y una emoción** propios (ver `continentes.md`): hogar, orgullo, misterio, ruina,
  soledad, desafío final.
- **Los villanos tienen motivos** (cada Heraldo creyó una mentira distinta de Morvath) y **el Eclipse gana algo en
  cada capítulo** (el Molde, una colada, un Ascua): las victorias del héroe cuestan. Pero el final es luminoso.
- Frases cortas en los diálogos (se leen en el móvil). Nombres en español o castellanizados; nada impronunciable;
  **dos personajes no comparten las primeras letras y el final** (registro de nombres en `continentes.md`).

## 3. Cosmología: la Forja del Alba

- Al principio, **siete Herreros Primeros** (titanes) forjaron Ardenia sobre el **Yunque del Alba**, una isla de
  piedra que flota en el cielo. Al terminar dejaron en cada tierra un **Ascua del Alba**: una brasa viva de la forja
  original, oculta en lo hondo de cada continente. **Las Ascuas sostienen su tierra** (fertilidad, metales en la
  roca): arrancar una hace daño a la tierra (Solarum ardió por eso; Escarcha se hiela más cuando Corvino se lleva la
  suya; la Luna se apaga cuando Vesper arranca la de Umbral).
- El séptimo, **Morvath**, forjaba los metales del fondo del mundo; su forja era su propio pecho. Quiso fundir las
  seis Ascuas en una sola arma —la **Hoja del Ocaso**— para rehacer a su gusto un mundo que le parecía mal hecho.
  Los otros seis lo vencieron y lo **sellaron en la Luna**; después lo borraron a propósito de las crónicas (solo los
  murales de Solarum recuerdan que eran siete). Lo llaman **el Herrero Hueco**.
- **La luz de la Luna es el sello.** La **Gran Lente** del Observatorio de los Herreros, en Umbral, enfoca hacia la
  Luna el fuego del Yunque; el corazón de la Lente es el **Ascua de Umbral**. Cada noche sin luna, el sello se afloja.
  *Versión recomendada (PENDIENTE DEL USUARIO, decisión 6)*: esa luz es **la llama que los Seis arrancaron del pecho
  de Morvath** y colgaron en el cielo: la Luna es a la vez su cárcel y su corazón robado; por eso es "Hueco" y por
  eso quiere un molde con seis brasas que le llene el pecho.
- De aquella guerra quedó la **Hoja del Alba**, forjada con una chispa de cada Ascua para cerrar el sello. Las chispas
  se durmieron con los siglos; solo la de Valdemar siguió viva, guardada por el linaje de la **princesa Aurora**.
  **La Hoja es una llave**: "la hoja que arda con seis brasas podrá cerrarle la puerta… o abrírsela" (profecía de
  Solarum). El **Molde del Ocaso** del Eclipse es "la otra hoja".
- **Brasa** (término fijo): lo que la Hoja toma de un Ascua al despertar. **El Ascua no sale de su tierra**: el héroe
  vence al que la amenaza, la Hoja toma su brasa en el ritual de Brokk y el Ascua sigue en su sitio. En el código no
  hay objeto: la brasa es la misión final del continente hecha (`motor_comun.md` B6).
- **Los minerales** (cobre, esmeralda, mithril…) son "virutas" de aquella forja: por eso el ritual de la forja puede
  despertar habilidades secretas. Cuanto más cerca de un Ascua, más raros y poderosos.

## 4. La amenaza: la Larga Noche

- La Luna de Plata se apaga: desde hace 20 años, cada año hay más **noches sin luna**. El sello se agrieta.
- Desde la Luna, Morvath susurra a los ambiciosos y desesperados. Así nace la **Orden del Eclipse** (los cultistas y
  acólitos de cada continente). No es nueva: hace mil años, en la primera noche sin luna de la que hay memoria,
  Morvath habló al emperador de Solarum, **el primer Heraldo**.
- Hoy el Eclipse tiene **seis Heraldos**, uno por continente, dirigidos desde la Gran Lente por la Gran Heraldo
  **Vesper**. Cada uno corrompe a un poder local (un rey goblin, un thane, una archimaga…) y busca el Ascua de su
  tierra, la Hoja del Alba o ambas.
- **El Molde del Ocaso** es el plan: un molde para la Hoja del Ocaso que, lleno con el fuego de las seis Ascuas,
  devolvería a Morvath todo su poder. El Eclipse lo lleva de continente en continente (§5b).
- **La noche sin luna en que los goblins entraron en Valdehierro** fue la primera señal: el Eclipse quería la
  Hoja del Alba, la única llave capaz de cerrar el sello.

## 5. La historia principal (los 6 capítulos)

| Cap. | Continente (niveles) | Qué pasa | Heraldo | Qué gana el héroe | Qué gana el Eclipse |
|---|---|---|---|---|---|
| 1 | **Valdemar** (1-10) | Los goblins toman Valdehierro. El héroe libera el pueblo, descubre al alcalde traidor (Fausto) y al **Abad Morcar**, que armó al Rey Goblin a cambio de la Hoja del Alba. Vence al Rey Goblin; Aurora le entrega la Hoja. Fausto huye al norte. | Abad Morcar (`abbot`) | **Hoja del Alba (I)**. El Ascua de Valdemar queda bajo la abadía (la vigila Fray Anselmo). | Nada (pierde a Morcar) |
| 2 | **Rocaforja** (10-20) | Brokk vuelve a su patria con el héroe. El **Clan Hollín** forja con fuego negro; su Thane Durgan, hermano de Brokk, ha forjado para el Eclipse el **Molde del Ocaso**. Brokk confiesa que él encendió el primer fuego negro. Durgan cae y sobrevive. | Hermana Brasa (NPC, no pelea) | Brasa de Rocaforja → **Hoja (II)** | **El Molde del Ocaso** (Brasa huye con él) |
| 3 | **Lunaria** (20-30) | Elfos y clanes lobo al borde de la guerra: la archimaga **Ysolde** envenena la luz de los claros. El héroe la desenmascara y sella el **Pacto de la Luna**. Garra Negra se cura. | Ysolde (`ysolde`) | Brasa de Lunaria → **Hoja (III)** · Pacto de la Luna | **El Molde, templado** con savia negra (Brasa lo recoge) |
| 4 | **Cenizas** (30-40) | La Alianza persigue a Brasa al desierto. El arqueólogo **Ozrán** despierta a **Severián, el Emperador Ceniciento**, el primer Heraldo. Los **murales de Solarum** cuentan la verdad: eran siete Herreros, la luz de la Luna es el sello, la Hoja es una llave. | Ozrán (`ashHerald`) | Brasa de Cenizas → **Hoja (IV)** · la profecía | **La primera colada** de fuego del Ascua de Cenizas en el Molde |
| 5 | **Escarcha** (40-50) | Caen esquirlas de la Luna. **Corvino** convence a la Reina Astrid de "abrir el cielo". El héroe llega tarde: Corvino vierte el **Ascua de Escarcha** en el Molde y sube por la Escala de Esquirlas. La Reina, al morir, le da la **Corona de Esquirlas**. | Corvino (NPC aquí; enemigo `starHerald` en Umbral) | Corona de Esquirlas → **Hoja (V)** · Hielomar y Ser Hálvar | **El Ascua de Escarcha** (segunda colada): su golpe más grande |
| 6 | **Umbral** (50-60) | Vesper arranca el **Ascua de Umbral** de la Gran Lente: la Luna se apaga y Morvath baja a medias a su Yunque. El héroe vence a Nixara, al Guardián, a Corvino y a **Vesper**; el Molde se raja y recupera las dos Ascuas. Brokk despierta la **Hoja (VI)**. Banda final contra **Morvath** en el Yunque. | Vesper (`grandHerald`), la Gran Heraldo | Brasas de Escarcha y Umbral → **Hoja (VI)**; las dos Ascuas vuelven a su sitio | Morvath se lleva los pedazos del Molde (su "Hoja del Ocaso a medias") |

**Hilo que se juega**: la **Hoja del Alba** despierta un nivel al final de cada continente, en la forja, con Brokk.
Niveles, números y matices de la habilidad: `progresion.md` §6. "Cinco luces abren la puerta del Yunque" (Ingrid):
las cuatro brasas de la Alianza (Valdemar, Rocaforja, Lunaria, Cenizas) + la Corona; "seis brasas la cierran".

### 5b. El hilo del Molde del Ocaso y las Ascuas (quién tiene qué al final de cada capítulo)

| Al final de | Molde del Ocaso | Ascuas que tiene el Eclipse | Dónde están las demás Ascuas |
|---|---|---|---|
| Valdemar | No existe aún (Durgan lo está forjando) | — | Todas en su tierra |
| Rocaforja | Hermana Brasa, vacío (huye por las galerías Hollín al Túnel de los Thanes) | — | Todas en su tierra |
| Lunaria | Hermana Brasa, **templado** con savia negra por Ysolde (huye al sur) | — | Todas en su tierra |
| Cenizas | Hermana Brasa, con **la primera colada** (fuego del Ascua de Cenizas; el Ascua sigue en el volcán) | — | Todas en su tierra |
| Escarcha | Corvino (se lo dio Brasa en el Cráter), con la **segunda colada**: el **Ascua de Escarcha** entera | Escarcha | Las otras cinco en su tierra |
| (esa misma noche) | Vesper (Corvino se lo entrega en la Gran Lente) | Escarcha y **Umbral** (Vesper la arranca de la Lente: la Luna se apaga) | Cuatro en su tierra |
| Umbral | Vesper vierte el Ascua de Umbral (tercera colada); al caer ella, **el Molde se raja**: las dos Ascuas caen ante el héroe y Morvath arrastra los pedazos al Yunque. Tras la banda, **Brokk funde los pedazos**. | — | Hálvar devuelve el de Escarcha a Hielomar; Fíbula, el de Umbral a la Lente |

### 5c. Personajes que viajan con la historia

| Personaje (id) | Dónde aparece | Papel y destino |
|---|---|---|
| **Princesa Aurora** (`princess`, el id del código) | Valdemar → todas las capitales | Última del linaje guardián. Lidera la Alianza del Alba y da la misión principal en cada capital. En Cenizas entiende que su Hoja es una llave. Final: **guardiana del Yunque** (PENDIENTE, decisión 5). |
| **Brokk Martillohondo**, nacido Brokk Hollín (`brokk`; en Valdemar es el herrero de `smithy`) | Valdemar → Rocaforja → Lunaria (forja élfica) → llega en el último barco a Cenizas → llega en el *Testaruda* a Hielomar → Umbral | Despierta la Hoja en cada capítulo. Paga su deuda en Rocaforja. Funde el Molde al final. Nombre ya canon en el código. |
| **Hermana Brasa** (`hermanaBrasa`) | Rocaforja, Lunaria, Cenizas, Escarcha (escenas), Umbral | Heraldo de Rocaforja. **Nunca pelea**. Lleva el Molde de Rocaforja a Escarcha; Vesper la descarta y queda medio hueca. Final: vuelve a Hondoyunque a que la juzguen los Thanes. Enana de Hondoyunque (por eso "vuelvo a casa"); su motivo, la venganza contra Hondoyunque (el story-writer puede atarla al aprendiz que mató el primer fuego negro: su hermano). |
| **Thessa** (`thessa`) | Lunaria → Cenizas (traduce los murales) → Escarcha y Umbral (opcional) | Aprendiz de Ysolde que la delata; erudita de la Alianza. |
| **Zigo** (`zigoMercader`) | Rocaforja, Cenizas, Escarcha, Umbral | Goblin mercader neutral que huyó del Rey Goblin y sigue a la Alianza. |
| **Marga Velasalada** (`margaCapitana`) | Cenizas (maestra de viajes), Escarcha (la llegada) | Capitana de *La Gaviota Tuerta*: Puerto de Valdemar → Cenizas → Hielomar. |
| **Ser / Mariscal Hálvar** (`halvar`) | Escarcha → Umbral | Último Caballero de la Luna Rota leal. Sobrevive; devuelve el Ascua de Escarcha a Hielomar. |
| **Corvino** (NPC `corvino`; enemigo `starHerald`) | Escarcha (escenas) → Umbral (jefe) | Heraldo de Escarcha. Queda convertido en estatua de cristal. |
| **Borin Nubehierro** (`borin`) | Hielomar (epílogo) → Umbral | Enano de Hondoyunque, piloto del dirigible *Testaruda* (ya había volado a Umbral). Maestro de viajes de Umbral. |
| **Morvath** (`morvath`) | Visiones (caps. 1-5), banda final | El séptimo Herrero. Solo se ve en sueños hasta el capítulo 6. |

Heraldos (uno por capítulo): **Abad Morcar** (muere), **Hermana Brasa** (sobrevive), **Ysolde** (cae), **Ozrán** (lo
arrastra el Emperador), **Corvino** (estatua), **Vesper** (cae al vacío). Lo que cada uno creyó: Morcar el poder, Brasa
la venganza, Ysolde que la Luna no muriera, Ozrán el saber, Corvino ver la Luna entera, Vesper "la libertad del cielo".
**Severián** fue el primer Heraldo, hace mil años (no cuenta entre los seis de hoy). Supervivientes no Heraldos:
**Durgan** (preso en Hondoyunque; puede volver arrepentido), **Fausto** (preso en Valdehierro), **Garra Negra/Varg**
(curado). Mueren: la **Reina Astrid** (de hielo) y el **Comendador Eirik**.

## 6. Cronología

| Época | Hecho |
|---|---|
| Hace eras | Los Siete Herreros forjan Ardenia en el Yunque del Alba y dejan las seis Ascuas. |
| Hace eras | Guerra del Ocaso: Morvath intenta fundir las Ascuas; los Seis lo sellan en la Luna (y lo borran de las crónicas). Se forja la Hoja del Alba. La Gran Lente apunta el fuego del Yunque a la Luna. |
| Hace ~1000 años | Primera noche sin luna de la que hay memoria: Morvath habla al emperador **Severián** de Solarum, el primer Heraldo. Intenta robar el Ascua de Cenizas; el Ascua no se deja y el imperio arde: nace el desierto de ceniza. |
| Hace ~300 años | Los enanos fundan Hondoyunque; los humanos, el reino de Valdemar. Primera Alianza del Alba. |
| Hace ~100 años | Los Caballeros de la Luna Rota se retiran a Escarcha a vigilar el cielo. |
| Hace 20 años | Vuelven las noches sin luna, cada año más. Brokk enciende el primer fuego negro y calla; el Clan Hollín es expulsado de Hondoyunque. |
| Hace 1 año | El Abad Morcar oye a Morvath. La Hermana Brasa lleva fuego negro "vivo" al Clan Hollín. Ozrán oye a la Luna en la excavación de la Cata. |
| **Comienzo del juego** | Noche sin luna: los goblins del Rey Goblin entran en Valdehierro por la puerta sur, que abrió el alcalde Fausto. Llega el héroe. |
| Fin del capítulo 5 | Corvino sube con el Molde y el Ascua de Escarcha; esa misma noche Vesper arranca el Ascua de Umbral de la Lente: la Luna se apaga del todo. |
| Final (cap. 6) | Morvath, sellado en el Yunque; la Luna vuelve entera: primera luna llena en veinte años (PENDIENTE, decisión 5). |

## 7. Razas jugables y su lugar en el mundo

Las cuatro razas empiezan en **Valdehierro** (no hay una zona inicial por raza: es más barato de construir y la
historia lo justifica). Cada raza tiene su patria en un continente, que se convierte en "su capítulo".

| Raza | Patria | Por qué está en Valdehierro |
|---|---|---|
| **Humano** | Valdemar (cap. 1) | Es de aquí: vuelve a su pueblo la noche del ataque. |
| **Enano** | Rocaforja (cap. 2) | Busca al herrero de Valdehierro, el enano que dejó el Clan Hollín. |
| **Elfo** | Lunaria (cap. 3) | Mensajero de Velaluna: trae un aviso sobre la Luna para la princesa. |
| **Hombre lobo** | Lunaria (cap. 3) | Siguió el olor del Eclipse desde el bosque; la luna apagada le duele. |

Una línea de diálogo distinta por raza al llegar a cada continente (todos los leads las tienen). Razas futuras
posibles (no ahora): **gnomos de Umbral** (Fíbula) y **hombres del norte** de Hielomar.

## 8. Facciones

| Facción | Quiénes | Relación con el jugador |
|---|---|---|
| **Alianza del Alba** | Humanos de Valdemar, enanos de Hondoyunque, elfos de Velaluna, clanes lobo de Colmillo Gris (tras el cap. 3), el Fortín del Oasis y el Clan Duna (cap. 4), Hielomar (cap. 5), el Bastión del Alba (cap. 6) | Es la facción del jugador. Capitales = forja, posada, maestro de viajes, misiones. |
| **Orden del Eclipse** | Cultistas, acólitos y fanáticos locales, los seis Heraldos, Vesper | Enemigo principal en los 6 continentes, con estética propia en cada uno. |
| **Horda Goblin** | El Rey Goblin y sus clanes; después, goblins mercaderes neutrales (Zigo, Trapisonda) | Enemigos en Valdemar; guiños neutrales después. |
| **Clan Hollín** | Enanos renegados con fuego negro | Enemigo en Rocaforja. |
| **Mala Luna** | Hombres lobo enfermos de savia negra | Enemigo en Lunaria (no confundir con los clanes de Colmillo Gris, aliados). Se curan al caer Ysolde. |
| **Solarum** | El imperio muerto: momias, legionarios, sacerdotes, el Emperador | Enemigo en Cenizas. |
| **Gigantes de Hrimgar** | Gigantes de escarcha a sueldo del Eclipse | Enemigo en Escarcha. |
| **Caballeros de la Luna Rota** | La orden que vigilaba el sello; caída, salvo Hálvar | Enemigo en Escarcha (víctimas). |
| **Vuelo del Alba** | Los dragones guardianes del Yunque | En Umbral, corrompidos casi todos; **Albor** es aliado. |

*Futuro MMO*: si algún día hay PvP o una segunda facción jugable, sale de la Orden del Eclipse (renegados).

## 9. Familias de monstruos (resumen; detalle en `continentes.md` y en cada `bestiario.md`)

| Continente | Familias principales |
|---|---|
| Valdemar | Goblins, bandidos, no-muertos de la abadía, bestias del campo, orcos del Pedregal (las 50 del juego + `eclipseAcolyte`) |
| Rocaforja | Kóbolds, trogloditas, gólems y elementales de piedra, bestias de montaña, Clan Hollín |
| Lunaria | Arañas tejedoras, árboles corruptos, duendes, Mala Luna, elfos marchitos, espíritus |
| Cenizas | Momias y legionarios de Solarum, elementales de fuego, trolls de ceniza, escorpiones y salamandras |
| Escarcha | Yetis, gigantes de escarcha, bestias de hielo, no-muertos helados, Caballeros de la Luna Rota |
| Umbral | Dragones y dragonantes, criaturas del vacío, constructos celestes, élite del Eclipse, herreros huecos |

## 10. Mapa del mundo y viajes

```
                         *  ( la Luna de Plata, agrietada )  *
                                ~ ~ ~ ~ ~ ~ ~ ~ ~
           ~~~~~~~~~~~~~~~~        [ 6 · UMBRAL ]        ~~~~~~~~~~~~~~~~
           ~  5 · ESCARCHA ~     islas que flotan       ~                ~
           ~  tundra, luna  ~    sobre el Mar Quieto     ~    MAR DEL    ~
           ~  caída, Hielomar~        (Yunque del Alba)   ~    LEVANTE    ~
           ~~~~~~~^~~~~~~~~~~~            ^               ~                ~
                  | barco de Marga        | dirigible Testaruda (Borin) desde la pista de Hielomar
        ^^^^^^^^^^^^^^^^^^^^^^^^^
        ^  2 · ROCAFORJA        ^                    ~~~~~~~~~~~~~~~~~~~~~~
        ^  montes, minas,       ^ ---- túnel de los Thanes ----> 3 · LUNARIA ~
        ^  Hondoyunque          ^                    ~  bosque de plata,    ~
        ^^^^^^^^^|^^^^^^^^^^^^^^^                    ~  Velaluna,          ~
                 | Paso del Norte                     ~  Colmillo Gris      ~
        .........|.................                   ~~~~~~~~~~~~~~~~~~~~~~
        .  1 · VALDEMAR            .  río Plata  ~~~~~~~~/
        .  praderas, robles,       .
        .  VALDEHIERRO (inicio)    .
        .........|.................
                 | Puerto de Valdemar (barco de Marga)
        ~~~~~~~~~v~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~      4 · CENIZAS                 ~
        ~  desierto de ceniza, volcanes,   ~
        ~  ruinas de Solarum, Fortín del Oasis
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

**Viajes** (se abren con la historia; el detalle de motor está en `motor_comun.md` B7 y D1):
- Valdemar → Rocaforja: a pie, por el **Paso del Norte** (`valdemar.paso_norte`).
- Rocaforja → Lunaria: a pie, por el **Túnel de los Thanes** (Hilda lo abre en `rocaforja.despertar`).
- Lunaria → Cenizas: barco de **Marga** (*La Gaviota Tuerta*) desde el Puerto de Valdemar; Aurora lo fleta tras
  `lunaria.pacto_de_la_luna`. Primera llegada: embarcadero de la Costa de Escoria.
- Cenizas → Escarcha: el mismo barco de Marga, desde el Fortín, tras `cenizas.cuarta_brasa`. Llegada: muelle de Hielomar.
- Escarcha → Umbral: dirigible **Testaruda** de Borin, desde la pista de Hielomar, tras `escarcha.quinta_luz`. Aurora
  y Hálvar suben en el primer viaje a tomar el Bastión; Borin vuelve a por el héroe y Brokk. Llegada: Muelles del Cielo.
- Una vez abiertos, los viajes son libres: en cada capital hay un **maestro de viajes** que lleva a cualquier capital
  visitada. Cabra, búho, barco o dirigible es solo estética (lista de maestros en `continentes.md`).

## 11. Cómo se construye todo esto con el motor actual

| Concepto MMO | Cómo se hace aquí |
|---|---|
| Zona exterior | Un mapa de texto (`AreaMap`) con zonas de nivel; enlazado con otros por **salidas** en los bordes. |
| Capital / hub | Un pueblo como Valdehierro: forja, posada (reaparición), maestro de viajes, NPC con misiones. Zona segura. |
| Misiones | Matar N, vencer a un jefe, hablar, leer una pista, llegar a un sitio, superar una mazmorra. Dan XP, oro, minerales, piezas. |
| Monstruos de campo | Esperan en su zona y **reaparecen** (los de la historia, en casas y jefes, no). |
| Mazmorra (grupo en WoW) | Una partida corta en un piso de mazmorra (motor de la arena): 4 oleadas + jefe. |
| Banda (raid) | Igual, más larga, con el jefe final del continente. La de Umbral (Morvath) es el final del juego, con punto de control y fases. |
| Equipo por tiers | Un tier de material por continente (cobre → … → mithril). La forja de cada capital vende el suyo. |
| Grupos, chat, comercio | **No ahora.** Las cuentas en Supabase lo permitirían en el futuro; nada del diseño lo bloquea. |

## 12. Glosario

Términos fijos: *Ascua del Alba* (la de cada tierra, no se mueve salvo robo), *brasa* (lo que la Hoja toma de un
Ascua), *Hoja del Alba* (la llave), *Hoja del Ocaso* (la de Morvath), *Molde del Ocaso*, *colada* (fuego vertido en el
Molde), *Orden del Eclipse*, *Heraldo*, *Gran Heraldo*, *Alianza del Alba*, *Larga Noche*, *Herrero Hueco*, *fuego
negro*, *savia negra*, *esquirla de luna*, *Corona de Esquirlas*, *Escala de Esquirlas*, *Gran Lente*. Ids: `continentes.md`.

---

## 13. Revisión de coherencia 1 (2026-10-09): propuestas de los leads

| Propuesta | De | Decisión | Por qué |
|---|---|---|---|
| Los Herreros eran **siete** | Cenizas 1 | **Aceptada** | No contradice nada jugado y da sentido a "Hueco" y a los murales. |
| El Emperador es el **primer Heraldo** (hace mil años) | Cenizas 2 | **Aceptada** | Explica Solarum. Cronología ajustada: una noche sin luna hace mil años; las de ahora vuelven hace 20. |
| La **Hoja del Alba es una llave** y el Molde "la otra hoja" | Cenizas 3 | **Aceptada** | Da tensión a Escarcha y Umbral. |
| Brasa entrega el Molde a **Corvino** | Cenizas 4, Escarcha 2 | **Aceptada** | Cierra el hilo por el suelo; ver §5b. |
| Versos de la profecía en los caps. 1-3 | Cenizas 5 | **Aceptada** (solo texto; Valdemar, si se retoca, en la cripta) | Siembra lo que Cenizas revela. |
| **La luz de la Luna es la llama de Morvath** | Cenizas 6, Umbral 3 | **PENDIENTE DEL USUARIO** (decisión 6), documentos con la recomendación | Cambia la cosmología y vuelve a Morvath algo trágico: toca el tono. |
| NPC que viajan con el mismo id | Cenizas 7 | **Aceptada** | El código ya lo permite con `appearsWhen`; `motor_comun.md` C4. |
| Garra Negra **se cura** | Lunaria 1 | **Aceptada** | La Mala Luna son enfermos, no villanos; mismo combate. |
| Maestro de viajes con **búhos** | Lunaria 2 | **Aceptada** | Solo estética. El de Colmillo Gris: `mensajeroColmillo`. |
| Thessa viaja a Cenizas | Lunaria 3 | **Aceptada** | Puente de "la verdad". |
| Bioma de las copas | Lunaria 4 | **Aceptada**, renombrada `lunariaCanopy` | Regla de nombres de biomas (`continentes.md`). |
| Plantilla **`werewolf`** para la Mala Luna | Lunaria (bestiario) | **Aceptada como P2 de arte** | Se lee mejor que `dog`; `dog` vale de provisional. |
| `owlbear`, `corruptStag` sin calificativo de bioma | Lunaria (bestiario) | **Aceptada** tal cual | No son variantes de un bicho existente. |
| Brokk Martillohondo, nacido Brokk Hollín | Rocaforja 1, Valdemar 4 | **Aceptada** | Ya es canon en el código (epílogo de Valdemar). |
| Hermana Brasa no pelea; el Molde, hilo del juego | Rocaforja 2 | **Aceptada** | Columna vertebral de los caps. 2-6. |
| Durgan sobrevive | Rocaforja 3 | **Aceptada** | Deja abierto un "forjador arrepentido". |
| Fausto acaba encadenado en Rocaforja | Rocaforja 4, Valdemar 1 | **Aceptada** | Cierra el hilo del alcalde. |
| **Arriero de Valdehierro** como maestro de viajes | Rocaforja 5 | **Aceptada**: `arrieroValdehierro`, *Nicasio el arriero*, en la Puerta sur tras `valdemar.paso_norte` | Valdehierro necesita su maestro. |
| **Forja de Valdehierro sin Brokk**: la lleva su aprendiz | Rocaforja 6 | **Aceptada** con matiz: mismo edificio `smithy`, sin NPC nuevo; la escena de la tienda muestra al aprendiz tras `valdemar.paso_norte` (P3 de arte; mientras, el dibujo de siempre). Solo Brokk despierta la Hoja. | El jugador no se queda sin forja en casa. |
| Formas nuevas fuera de la arena | Rocaforja 7 | **Aceptada** | La arena no cambia (`motor_comun.md` A6). |
| Varios biomas por continente | Rocaforja 8 | **Aceptada** (máx. ~5 por continente), con regla de nombres | Cada área se lee distinta. |
| `d` = vía de vagoneta en Hondoyunque | Rocaforja 9 | **Aceptada** | Regla "el carácter según el bioma". |
| El Eclipse **roba el Ascua de Escarcha** | Escarcha 1 | **Aceptada** (era "a confirmar" en esta biblia; es de estructura, no de tono) | El golpe bajo que cambia el objetivo de Umbral y cierra el hilo del Molde. Se rechaza la alternativa de matar a Hálvar. |
| Corvino no pelea en Escarcha; `starHerald` en Umbral | Escarcha 3 | **Aceptada** | |
| Hálvar = Mariscal Hálvar (`halvar`) | Escarcha 4 | **Aceptada** | |
| **5 jefes** en Escarcha y Umbral | Escarcha 5, Umbral 5 | **Aceptada** (`progresion.md` §6: 2-5) | Son los continentes largos y Corvino tiene que pelear en algún sitio. |
| "Cinco luces" | Escarcha 6 | **Aceptada** | Encaja con la llave. |
| La Hoja (V) gana el elemento Hielo | Escarcha (piezas) | **Rechazada** | Cambiar los elementos de la Hoja cambia sus combos; se da un matiz a `dawn` (ralentiza). |
| Umbral: fila de §5 y cronología | Umbral 1 | **Aceptada** con corrección: no "hace un mes", sino **la misma noche** en que Corvino llega (lo que dicen Escarcha y el §1 de Umbral) | Contradicción interna de Umbral. |
| Vesper, sexto Heraldo y la que dirige | Umbral 2 | **Aceptada** | Explica por qué el Eclipse siempre sabía dónde buscar. |
| **Final**: Morvath sellado en el Yunque, la Luna se reenciende | Umbral 4 | **PENDIENTE DEL USUARIO** (decisión 5) | Es el final del juego. |
| **Mithril escalado** en la historia | Umbral 6 | **Aceptada** como regla general (`progresion.md` §5 y `motor_comun.md` B2) | Sin ella, la joya del final sería peor que un común. |
| Vuelo de Albor dentro de Umbral | Umbral 7 | **Aceptada como P3** | Atajo; si cuesta, Albor es solo NPC. |
| Recompensas de aldeanos con minerales de Valdemar; jefes de historia ×6 | Valdemar 2-3 | **Aceptadas** (ya hechas en el código) | |
| Hombres del norte como raza futura | Escarcha 8 | **Anotada** (§7) | No ahora. |

## 14. Contradicciones encontradas y cómo se resolvieron

1. **El id de la princesa**: el código usa `princess`; Lunaria, Cenizas, Escarcha y Umbral usaban `aurora` → cambiado a `princess` en todos.
2. **¿El héroe se lleva las Ascuas?** Rocaforja, Lunaria y Cenizas decían que el héroe "gana el Ascua"; Valdemar la deja bajo la abadía y Umbral las devuelve a su sitio, y la cosmología dice que sostienen su tierra → regla de la **brasa** (§3): el Ascua se queda; la Hoja toma su brasa. Corregidas las líneas de Lunaria, Cenizas y Rocaforja.
3. **Vesper "le quitó el Molde" a Brasa** (Umbral), pero Brasa se lo había dado a Corvino en el Cráter (Escarcha) → Vesper descarta a Brasa; el Molde se lo entrega Corvino.
4. **Cuándo se apaga la Luna**: Umbral decía "hace un mes" y "esa misma noche" → esa misma noche.
5. **Aurora y Hálvar ya esperan en el Bastión** cuando el héroe llega en el primer vuelo → suben en un viaje anterior del *Testaruda*.
6. **Borin "de Umbral"** (Escarcha) y "enano" en un dirigible enano → enano de Hondoyunque que ya había volado a Umbral.
7. **Brasa huye por el Túnel de los Thanes, que está sellado** hasta el final de Rocaforja → huye por las galerías Hollín, que salen al Túnel por detrás del rastrillo.
8. **"Primera noche con luna en veinte años"**: en esos veinte años sí hubo noches con luna → "primera luna llena".
9. **Motivo de Ysolde** ("la pureza" en Umbral, "que la Luna no muriera" en Lunaria) → el de Lunaria.
10. **Noches sin luna**: "primeras hace 20 años" (biblia) contra "la primera hace mil años" (Cenizas) → cronología §6.
11. **Niveles de la Hoja**: cada lead usaba una vara distinta (tier 3, "3-4", tier 5, "tier 5 ×1,5") → regla única en `progresion.md` §6.
12. **XP de misiones**: los cinco continentes nuevos se pasaban (480-925 % contra ~400 %), porque la tabla de esta biblia lo invitaba → corregida (`progresion.md` §2).
13. **`Mineral.dropRateMultiplier`** es 0,15 en el código; los diseños contaban con 0,3 → aviso al balance-designer.

---

## PENDIENTE DEL USUARIO

Las decisiones que de verdad son suyas. Los documentos siguen la recomendación; cambiarla ahora es barato (solo
textos de los capítulos 4-6), después de construir Cenizas ya no tanto.

1. **El villano final** — *Recomendación: mantener a Morvath, el Herrero Hueco* (ya lo usan los 6 continentes).
2. **Quién está detrás del Rey Goblin** — ya decidido en el juego (Abad Morcar + alcalde Fausto): solo confirmar.
3. **El héroe** — *Recomendación: forastero de cualquier raza, sin pasado fijo* (ya lo usan todos los leads).
4. **Elfos y hombres lobo en Lunaria** — ya construido así en el diseño: solo confirmar.
5. **El final** — *Recomendación (la de Umbral)*: el héroe gira la llave (Hoja VI) y **sella a Morvath en el Yunque**
   (no en la Luna); la Luna vuelve entera con el fuego del Yunque; Aurora queda como guardiana del Yunque; Brokk funde
   el Molde; el endgame es repetir la banda (`umbral.eco_de_morvath`). *Alternativa agridulce*: Morvath destruido y la
   Luna apagada para siempre (solo cambian epílogo y últimas frases). Nombre del mundo: **Ardenia**. Nombre del juego:
   *recomendación* **"Hoja del Alba"** (alternativa "Crónicas del Alba").
6. **La luz de la Luna es la llama arrancada a Morvath** — *Recomendación: sí*. Es lo que hace encajar "Hueco", la
   Luna, el Molde y la llave, y le da al villano un motivo trágico sin quitarle maldad (quiere rehacer el mundo a la
   fuerza). Cambia el tono: los Seis Herreros ya no son del todo "buenos". *Alternativa*: la luz es solo el fuego del
   Yunque reflejado (mural 2 de Cenizas y las líneas de Brasa y Morvath en Umbral se reescriben; nada más cambia).
7. **Renombres por parecido** (hechos en esta revisión; el usuario puede vetarlos): Hulda→**Frida** (choca con la Thane
   Hilda), Bruna→**Hirsa** (con Bruno de Valdehierro), Brena→**Dorna** (con la Hermana Brasa), Gudrun→**Solveig** (con
   la Jarla Sigrun), Ulric→**Eirik** (con Ulf), Maela→**Nora** (con Marga), Aurelián→**Severián** (con Aurora),
   "Coloso de la Esquirla"→**Engendro de la Esquirla** (con el Coloso de cobalto), "Grieta del glaciar"→**Sima del
   Glaciar** (con la Grieta del vacío), "Templo de la Aurora"→**Templo de las Luces** (con la princesa).
