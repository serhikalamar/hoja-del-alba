# Escarcha · historia del capítulo 5 — *Soledad y presagio*

Responsable: `continent-lead` de `escarcha`. Estado: **borrador 2** (2026-10-08), **fase futura** (se implementa después
de Valdemar, Rocaforja, Lunaria y Cenizas). Niveles **40-50**. Hermanos: `zonas.md` (áreas, salidas, zonas,
mazmorras y misiones en formato de datos), `mapas/`, `bestiario.md`, `minerales.md`, `piezas.md`, `encargos.md`.
Formato de datos: el de Valdemar (`../valdemar/contrato.md`).

## 1. En pocas líneas

La Luna se rompe y sus trozos caen sobre el norte helado: congelan la tierra y enloquecen a quien los toca. La
**Hermana Brasa** llega antes que el héroe con el **Molde del Ocaso** (ya con la primera colada de fuego de Cenizas) y
se lo entrega a **Corvino el Astrólogo**, el Heraldo del Eclipse de Escarcha. Corvino ha convencido a la **Reina Astrid
de la Luna Rota**, que juró vigilar el sello, de que solo "abriendo el cielo" podrá repararlo. El héroe atraviesa la
costa, la tundra, el cráter y el trono de los gigantes hasta la Ciudadela… y llega tarde: Corvino vierte el **Ascua de
Escarcha** en el Molde y sube con ambos por la **Escala de Esquirlas**. La Reina, al morir, le da al héroe su **Corona
de Esquirlas**, y con ella la Hoja del Alba despierta (V). *El Eclipse gana su golpe más grande.*

## 2. El lugar y quién manda

- **Tierras de Escarcha**: tundra blanca, glaciares azules, auroras violetas, fiordos negros. Ya casi no hay noches
  con luna; cuando la hay, está partida y gotea luz. Cada pocos días cae una **esquirla de luna** y deja un cráter cian.
- **Hielomar**: puerto de los hombres del norte, balleneros. Casas largas de madera oscura, braseros en cada esquina,
  empalizada de troncos. Desconfían de los forasteros; quien comparte su fuego es de la familia.
- **La Ciudadela de la Luna Rota**: fortaleza de plata y hielo sobre un glaciar, al norte. Allí vivían los
  **Caballeros de la Luna Rota**, que desde hace ~100 años vigilan el sello de Morvath mirando el cielo.

| Facción | Dónde | Quién manda | Qué quiere |
|---|---|---|---|
| Hombres del norte (Hielomar) | Hielomar, Costa, Tundra | **Jarla Sigrun Mano de Hielo** | Sobrevivir al invierno. No meterse en guerras de sureños… hasta que el invierno se las trae a casa. |
| Alianza del Alba | Hielomar (de visita) | **Aurora** | Alcanzar el Ascua de Escarcha antes que el Eclipse. |
| Gigantes de escarcha | Trono de los Gigantes | **Jarl Hrimgar** | Que vuelva el frío de antes; Corvino le prometió la costa. |
| Caballeros de la Luna Rota (caídos) | Murallas, Ciudadela | **Reina Astrid** | "Abrir el cielo" para reparar el sello (engañada). |
| Orden del Eclipse | Cráter, Ciudadela | **Corvino el Astrólogo** (Heraldo) con la **Hermana Brasa** | Llenar el Molde del Ocaso con el fuego del Ascua de Escarcha y subirlo al Yunque. |

## 3. Personajes clave

Ids de NPC únicos en todo el juego (comprobado con Rocaforja, Lunaria, Cenizas y Umbral); los que viajan entre
continentes reutilizan el id (como propone Cenizas §9.7).

| Id (NPC / enemigo) | Nombre | Dónde | Papel | Aspecto (para `pixel-artist`) |
|---|---|---|---|---|
| `princess` | Princesa Aurora | Muelle (llegada), Gran Salón | Misión principal. Tras los murales de Cenizas sabe que su Hoja es una **llave**; aquí ve qué abre la otra. | Capa de viaje con cuello de piel blanca. |
| `brokk` | Brokk Martillohondo | Forja de Hielomar (solo al final) | Llega en el dirigible *Testaruda* y despierta la **Hoja del Alba (V)** con la Corona. | El enano herrero de siempre, con orejeras de piel. |
| `margaCapitana` | Capitana Marga Velasalada | Muelle (solo la llegada) | La maestra de viajes de Cenizas trae al héroe en *La Gaviota Tuerta* y añade Hielomar a su ruta. | La de Cenizas, con capote. |
| `zigoMercader` | Zigo | Muelle, puesto | El goblin mercader sigue a la Alianza ("¡el frío vende mantas!"). Misión secundaria. | Goblin con mochila enorme y gorro de lana. |
| `jarlaSigrun` | Jarla Sigrun Mano de Hielo | Gran Salón | Señora de Hielomar. Perdió la mano izquierda contra un oso (ahora es de plata). Seca, justa. No se fía del héroe hasta que limpia la costa. | Humana alta, trenzas rubias canosas, capa de oso, mano de plata. |
| `ulfTresdedos` | Ulf Tresdedos | Muelle | **Maestro de viajes** de Escarcha (barco ballenero, misma mecánica que Frida y Marga). Misión de la esquirla. | Viejo ballenero, barba blanca, chubasquero amarillo, mano con tres dedos. |
| `solveigTabernera` | Solveig | Taberna del Arpón | Posadera (reaparición). Ríe fuerte y pega más fuerte. Misiones de pieles y caravana. | Humana robusta, delantal, jarra de hidromiel. |
| `ragnaHerrera` | Ragna Yunquefrío | Forja de Hielomar | Herrera norteña, aprendió con los enanos de Hondoyunque de joven. Forja tier 5 (glacita, ébano) y las formas de Escarcha. | Humana fuerte, pelo rapado a un lado, delantal de cuero sombrío, martillo. |
| `ingridVidente` | Ingrid la Vidente | Cabaña de Ingrid | Anciana ciega que "lee" las auroras. Explica las esquirlas y la Escala. Guía mística. | Anciana con velo y ojos blancos, bastón con plumas, collar de esquirlas. |
| `torvaldTrampero` | Torvald el Trampero | Puerta oeste | Cazador solitario de la tundra. Misiones de yetis y mamuts. | Humano barbudo, pieles, raquetas a la espalda, arco corto. |
| `halvar` | Ser Hálvar | Templo de las Luces → plaza → campamento de las Murallas | Último Caballero de la Luna Rota leal, natural de Hielomar. Llega herido; cuenta la caída de la orden. Viaja a Umbral (allí, **Mariscal Hálvar**). | Armadura de plata abollada, tabardo azul noche con luna partida, vendas, barba corta. |
| `thessa` *(opcional)* | Thessa | Gran Salón (tras `escarcha.reina`) | La erudita de Lunaria/Cenizas llega con Brokk y lee las cartas astrales de Corvino: la Escala lleva a la **Gran Lente** de Umbral. | La de Cenizas, con bufanda. |
| `hermanaBrasa` | Hermana Brasa | Escena del Cráter (y `cartaBrasa`) | Heraldo de Rocaforja. Entrega el Molde a Corvino y se va hacia el cielo antes que él. **No pelea.** | La de siempre, con el Molde a la espalda y escarcha en la capucha. |
| `corvino` | Corvino el Astrólogo | Escenas del Cráter y de la Ciudadela | **Heraldo del Eclipse de Escarcha.** Fue el astrólogo real de la Ciudadela: el primero en ver las grietas de la Luna y en oír a Morvath. **No pelea** aquí. | Humano delgado y alto, túnica azul noche bordada de estrellas, astrolabio de plata, ojos con brillo violeta. |
| enemigo `yetiPatriarch` | **Abuelo Ventisca** | Cueva de la Tundra | Patriarca yeti, sabio hasta que una esquirla se le clavó en el lomo. Jefe de zona. Víctima. | Ver `bestiario.md`. |
| enemigo `shardHorror` | **Engendro de la Esquirla** | Mazmorra `escarcha.sima` | Elemental nacido de la esquirla más grande. Jefe de la mazmorra. | Ver `bestiario.md`. |
| enemigo `giantJarl` | **Jarl Hrimgar** | Salón del Trono | Señor de los gigantes a sueldo del Eclipse. Jefe de zona. | Ver `bestiario.md`. |
| enemigo `wallCommander` | **Comendador Eirik, el Primero en Caer** | Puerta de Plata | Hermano de armas de Hálvar, el primero en tocar una esquirla. Jefe de zona. | Ver `bestiario.md`. |
| enemigo `brokenQueen` | **Reina Astrid de la Luna Rota** | Mazmorra `escarcha.ciudadela` | Reina-comendadora de la orden, con el corazón helado por las esquirlas. **Jefa final.** | Ver `bestiario.md`. |

Pistas (`.clue`): `esquirlaCaida` (la primera esquirla, Costa), `diarioTrampero` (Tundra), `cartaBrasa` (Cráter: carta
de la Brasa a Corvino), `totemAurora1-3` (Cráter). Ids en `zonas.md` §4.

### Líneas por raza (solo diálogo)

| Momento | Humano | Enano | Elfo | Hombre lobo |
|---|---|---|---|---|
| Llegada | "Ni en Valdemar hace este frío… y allí lo llamamos invierno." | "Hielo y roca. Casi me siento en casa." | "La Luna llora. Nunca la había oído llorar." | "Me duele el pecho. Huele a luna rota." |
| Corona de Esquirlas | "Pesa más que una espada." | "Ningún enano forjó esto. Y aun así, quema." | "Es un trozo de cielo. Lo siento." | "Aúlla por dentro. Igual que yo." |

## 4. Lo que pasa (por actos)

**Acto I · El puerto (40-42).** *La Gaviota Tuerta* entra de noche en el fiordo; una esquirla cruza el cielo y cae en
la costa. Marga deja al héroe y a Aurora en el muelle; Ulf toma el relevo como maestro de viajes. La Jarla Sigrun no
quiere "sureños con espadas bonitas": primero, la costa. Lobos de escarcha y osos bajan al puerto; los balleneros
ahogados este invierno se levantan del hielo. Ulf pide traer la esquirla caída (`esquirlaCaida`); **Ingrid** la "lee":
lleva dentro un eco del fuego del Yunque, el mismo que la Luna refleja. "La Luna no se apaga, sureño: se rompe."

**Acto II · El rastro de la Luna (42-46).** Los yetis, que nunca atacaban, arrasan las trampas de Torvald. El rastro
lleva a la cueva del **Abuelo Ventisca**, con una esquirla en el lomo. Muerto el patriarca, el camino al este se abre.
En el **Cráter de la Esquirla**, lunáticos y cultistas rezan a las esquirlas. En una tienda negra, la `cartaBrasa`:
"Hermano Corvino: el Molde lleva ya un fuego. El segundo lo pones tú." Al entregar la misión, escena: en el corazón del
cráter, **Corvino** recibe el Molde de manos de la **Hermana Brasa**; ella se va hacia la ventisca ("Te espero arriba,
hermano"); él mira al héroe: "La Luna se abre. No para morir: para dar a luz." Ingrid: la esquirla mayor cayó por una
grieta del glaciar. En la **Sima** nace el **Engendro de la Esquirla**; vencido, se ve un caballero congelado con el
blasón de la luna partida: la Ciudadela ha caído.

**Acto III · El juramento (46-50).** En el Templo de las Luces, **Ser Hálvar** (herido) cuenta la verdad: Corvino
convenció a la Reina Astrid de abrir el corazón del glaciar, donde dormía el Ascua; los caballeros que tocaron las
esquirlas son ahora soldados helados. Entre Hielomar y la Ciudadela están los **gigantes** de Hrimgar. La Jarla, por
fin, se suma ("Mis barcos no suben glaciares. Pero mis hachas, sí."). **Hrimgar** cae y confiesa: "El astrólogo me dio
la costa. Ni la quería. Quería el frío de vuelta". En las **Murallas**, Hálvar acampa junto al foso. Ante la Puerta de
Plata, el **Comendador Eirik** recupera la voz al morir: "Corre, hermano. Ella ya sacó el Ascua".
En la **Ciudadela**, la **Reina Astrid** combate bajo un rayo cian que sube al cielo: la **Escala de Esquirlas**. Al
caer, se le descongela el corazón y pide perdón. En ese instante **Corvino** sostiene el Molde sobre el **Ascua de
Escarcha**: la segunda colada se vierte con un grito de luz, y él entra en el rayo con el Molde y el Ascua y sube. La
Reina, muriendo, da al héroe su **Corona de Esquirlas**: "Lleva el fuego que ella refleja. Úsalo". Se queda de hielo.

**Epílogo.** El dirigible *Testaruda* (Borin Nubehierro) atraca en la pista de Hielomar con **Brokk**. En la forja de
Ragna, Brokk despierta la **Hoja del Alba (V)** con la Corona. Ingrid: "Cinco luces abren la puerta del Yunque" (las
cuatro Ascuas de la Alianza + la Corona). Si está Thessa: las cartas de Corvino dicen que la Escala lleva a la **Gran
Lente** del Observatorio de Umbral. Aurora, en la pista: "Nos han ganado una. Solo una." Aurora y Hálvar suben en el primer viaje del *Testaruda* a tomar el Bastión del Alba; Borin vuelve a por el héroe y Brokk. Se abre el viaje a **Umbral**.

## 5. Misiones (resumen)

Tabla completa en formato `Quest` (`requires`, objetivos, recompensas) en `zonas.md` §6.

| # | Id | Nv. | Da | Qué pasa |
|---|---|---|---|---|
| 1 | `escarcha.llegada` | 40 | `princess` | Llegada en barco; la Jarla desconfía. |
| 2 | `escarcha.balleneros_helada` | 40 | `jarlaSigrun` | Limpiar la costa de lobos y balleneros ahogados. |
| 3 | `escarcha.esquirla_perdida` | 41 | `ulfTresdedos` | La primera esquirla; Ingrid explica qué es. |
| 4 | `escarcha.ventisca` | 42 | `torvaldTrampero` | Los yetis enloquecen. |
| 5 | `escarcha.abuelo_ventisca` | 43 | `torvaldTrampero` | Vencer al patriarca yeti con la esquirla en el lomo. |
| 6 | `escarcha.crater` | 44 | `ingridVidente` | Carta de la Brasa; Corvino recibe el Molde. |
| 7 | `escarcha.sima` | 46 | `ingridVidente` | Mazmorra: Engendro de la Esquirla; el caballero congelado. |
| 8 | `escarcha.juramento` | 46 | `halvar` | La caída de la orden; la Jarla se suma. |
| 9 | `escarcha.trono_gigantes` | 48 | `jarlaSigrun` | Vencer a Hrimgar. |
| 10 | `escarcha.murallas` | 49 | `halvar` | Vencer a Eirik ante la Puerta de Plata. |
| 11 | `escarcha.reina` | 50 | `princess` | Banda de la Ciudadela; Corvino sube con el Molde y el Ascua. |
| 12 | `escarcha.quinta_luz` | 50 | `brokk` | **Hoja del Alba (V)**; dirigible a Umbral. |

Secundarias (9): `pieles`, `arpones`, `caravana`, `mamuts`, `tres_auroras`, `nucleos` (Zigo), `runas`,
`huesos_de_gigante`, `caidos`.

## 5b. Hilo con los otros continentes

| Continente | Enlace |
|---|---|
| Rocaforja | La **Hermana Brasa** y el **Molde del Ocaso** (robado de la Forja Profunda) cierran aquí su viaje por el suelo: el Molde sube al cielo. Ragna aprendió con los enanos de Hondoyunque. |
| Lunaria | El Molde, templado con savia negra por Ysolde, aguanta el frío de la Escala. Thessa (opcional) vuelve a aparecer. |
| Cenizas | Requisito: `cenizas.cuarta_brasa`. Marga trae al héroe. La Brasa llegó con la **primera colada** (fuego del Ascua de Cenizas); aquí Corvino vierte la **segunda** (Ascua de Escarcha). Lo que se supo en los murales (siete Herreros, la Luna como sello, la Hoja como **llave** y el Molde como "la otra hoja") se da por sabido: Aurora lo cita. |
| Umbral | Se sale en el dirigible *Testaruda* (Borin). Corvino llega a la Gran Lente con el Molde (dos coladas) y el **Ascua de Escarcha** y se los da a la **Gran Heraldo Vesper**, que esa misma noche arranca el Ascua de Umbral (fuera de pantalla). En Umbral se recuperan ambas en `umbral.gran_heraldo`. Ser Hálvar es allí el **Mariscal Hálvar**. |

## 6. El final del continente

- **Se pierde**: el Ascua de Escarcha (Corvino) y la Reina Astrid. El Molde ya tiene dos coladas. Desde ahora el cielo de
  Escarcha muestra una grieta en la Luna (fondo opcional, `environment-artist`).
- **Se gana**: Hoja del Alba (V), la pieza única de la Reina, la alianza de Hielomar (la Jarla se suma a la Alianza del
  Alba), Ser Hálvar como compañero, el dirigible y la forja de Ragna vendiendo también tier 6 (adelanto de Umbral).
- **Se abre**: el viaje a Umbral (Ulf y Borin añaden el Bastión del Alba).

## 7. Propuestas al world-designer

> **Respuesta del world-designer (revisión de coherencia 1, 2026-10-09)**: cada propuesta está aceptada, ajustada,
> rechazada o marcada PENDIENTE DEL USUARIO, con su razón, en `assets/world/mundo.md` §13; las contradicciones
> corregidas en este continente, en `mundo.md` §14; los renombres, en `assets/world/continentes.md` (registros comunes).

1. **El golpe bajo (pregunta abierta de `mundo.md`).** El Eclipse **roba el Ascua de Escarcha**: Corvino la vierte en el
   Molde del Ocaso (segunda colada) y sube con ambos por la Escala de Esquirlas. La Hoja del Alba despierta (V) con la
   **Corona de Esquirlas** (un trozo de Luna con el eco del fuego del Yunque). Es el golpe más fuerte porque **cambia
   el objetivo** de Umbral y cierra el hilo Brasa-Molde de Rocaforja-Lunaria-Cenizas. Encaja con la propuesta 1 del
   lead de Umbral ("si Escarcha roba otra Ascua, Vesper la lleva también y se recupera en `umbral.gran_heraldo`").
   *Alternativa*: además muere Ser Hálvar en las Murallas (más drama, pero Umbral pierde a su Mariscal).
   Cambio en `mundo.md` §5: fila de Escarcha → "El Eclipse roba el Ascua de Escarcha; la Hoja despierta (V) con la
   Corona de Esquirlas"; fila de Umbral → "recuperar el Ascua de Escarcha y el Molde de manos de Vesper".
2. **La Hermana Brasa entrega el Molde a Corvino** (respuesta a Cenizas §9.4) y sube al cielo antes que él. Su final
   queda para Umbral (propuesta: Vesper la descarta, como la Brasa descartó a Ozrán).
3. **Corvino el Astrólogo**, quinto Heraldo, **no pelea en Escarcha**. Id reservado `corvino` (NPC de escena aquí). Si
   Umbral quiere combatirlo, que use ese id como enemigo o uno nuevo (`starHerald`).
4. **Ser Hálvar = Mariscal Hálvar** de Umbral (mismo personaje; id compartido `halvar`). A coordinar con el lead de
   Umbral (allí aún no tiene id en el registro de NPC).
5. **Cinco jefes en vez de 2-4** (`progresion.md` §6): la plantilla pide jefe en zona 2, zona 3/mazmorra, zona 4,
   zona 5 y final. Si se quieren 4, el Engendro sale y el jefe de la mazmorra es el Abuelo Ventisca.
6. **"Cinco luces"**: Ingrid dice que el portal del Yunque se abre con cinco luces (cuatro Ascuas + la Corona). Encaja
   con la Hoja-llave de Cenizas: la Hoja (V) es la llave y las Ascuas, la fuerza para girarla.
7. **Nombres**: Reina **Astrid** (evita confusión con Ysolde de Lunaria). La vidente es **Ingrid** (en Rocaforja ya
   hay una Edda, `eddaGuardiana`). La herrera local es **Ragna** (Brokk solo llega al final).
8. **Raza futura** (`mundo.md` §7): los hombres del norte de Hielomar serían la raza natural de este capítulo.
