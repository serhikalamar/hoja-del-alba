# Valdemar · guion del capítulo 1 (niveles 1-10)

Responsable: `story-writer`. Estado: **SW1 entregado, pendiente de visto bueno** del `continent-lead` y del usuario
(2026-10-07). Base: `assets/world/continentes/valdemar/historia.md` (arco y misiones), `zonas.md`, `bestiario.md`,
`mapas/*.md` y `assets/world/mundo.md`. Biblia actualizada en `assets/story/historia.md`.

> **SW2 (2026-10-08): textos pasados al código.** Dónde está cada cosa y qué falta: §15.

> Lo que aquí depende de decisiones *a confirmar por el usuario* (`mundo.md`, última sección) va marcado con **[AC]**.
> Funciona tal cual si el usuario acepta las propuestas; si no, la §14 dice qué líneas habría que tocar.

## 0. Cómo usar este guion (para SW2 y el programador)

- Cada texto tiene un **id de texto** (`npc.marta.thanks`, `quest.valdemar.molino.oferta`…). No se guardan en partidas:
  solo sirven para encontrarlos. Los ids de **NPC, misiones, áreas, salidas y enemigos** son los de los datos y no cambian.
- Cada línea numerada = **un cuadro de diálogo** (`Dialog.lines`). Máximo 120 caracteres; casi todas por debajo de 90.
  Máximo 4 líneas por intervención.
- `{n}`, `{zona}`, `{área}`, `{oro}`, `{xp}`, `{título}`, `{nombre}` = huecos que rellena el código.
- **[P]** = el texto necesita un campo o un momento que el contrato de datos aún no tiene: es una **propuesta**
  (ver §13). Sin ese campo se puede omitir sin romper nada.

| Tipo de texto | Va a (código) |
|---|---|
| `npc.<id>.plea` / `.thanks` | `NPC.plea` / `NPC.thanks` (`Town.swift`, interiores de `Valdehierro`) |
| `npc.<id>.casa`, `npc.<id>.calle.*` | Diálogo al volver a hablar (hoy: línea fija en `ExploreSession.npcReached`) **[P]** |
| `quest.<id>.titulo` / `.diario` | `Quest.title` / `Quest.summary` (`ValdemarQuests.swift`) |
| `quest.<id>.hud.<n>` | Objetivo corto del HUD, uno por objetivo en el orden de `Quest.objectives` **[P]** |
| `quest.<id>.oferta` / `.recordatorio` / `.entrega` | Diálogo del dador al ofrecer ("!"), con la misión activa y al entregar ("?") **[P]** |
| `exit.<id>` | `AreaExit.lockedMessage` (`Town.swift` / `Valdemar.swift`) |
| `dungeon.<id>.bossIntro` | `StoryDungeon.bossIntro` (`Valdemar.swift`) |
| `escena.*`, `aviso.*`, `toast.*` | `ExploreSession` (intro, avisos, toasts) |
| `boss.<enemyID>.intro` | Presentación del jefe al verlo por primera vez **[P]** |
| `smithy.*` | Forja: epílogo antes de abrir la tienda; frases del bocadillo (`ForgeShopView`) |

---

## 1. El guion en ocho pasos

1. **La noche sin luna.** Los goblins entran en Valdehierro por la puerta sur. El héroe llega esa noche (un motivo
   por raza). Misión automática `valdemar.liberar`.
2. **El pueblo (1-5).** Cada aldeano rescatado deja una pista: la puerta estaba **abierta sin forzar** (Marta), los
   bandidos **cobraban de alguien** (Elena), la bruja recibía a un **encapuchado gris** (Iris), en **Valsombra** pasa
   algo peor desde que murió el abad (Anselmo). Al rescatar al sexto, aparece el **Capitán Rodrigo Vela**.
3. **Fuera (5-9).** Los aldeanos se vuelven dadores de misiones: Tomás (Huertos y el Ogro), Bruno (lobos de Robleda),
   Iris (limos), Elena (el campamento bandido). Bruno y el Señor de la guerra plantan las **hachas negras**.
4. **Tirar del hilo.** Los bandidos pagaban con **monedas del concejo**: Elena manda al héroe a la casa del alcalde.
   Allí, acólitos del Eclipse queman papeles y queda **media carta**: «Fausto: deja abierta la puerta sur… — M.».
   El alcalde **Fausto Ledesma** ha huido.
5. **Valsombra.** «M.» es **Morcar**, el abad que Fray Anselmo enterró hace un año. En la cripta, el **Abad no-muerto**
   confiesa a medias: no quería el castillo, quería lo que esconde la princesa. Al caer, al fondo brilla el **Ascua**.
6. **El Pedregal.** El Señor de la guerra presume de hachas «del norte, de fuego negro». Con el Abad y el Señor de la
   guerra vencidos, el Capitán abre la escalinata.
7. **El trono.** El Rey Goblin, vanidoso, cree que el castillo es su premio. Aurora, libre, entrega la **Hoja del
   Alba (I)**: el Eclipse la quería porque es lo único que refuerza el sello de la Luna.
8. **Epílogo.** En la forja, el herrero se presenta como **Brokk Martillohondo**, reconoce el **fuego Hollín** de su
   viejo clan y cuenta que vio a un encapuchado (Fausto) huir por el **Paso del Norte**. La forja vende tier 2 y se
   abre el Paso. En el Paso, el cartel de «Montes de Rocaforja» y un jirón de capa gris tejida por Elena.

---

## 2. Introducción

### `escena.intro` — `showIntroDialog` (speaker: "Valdehierro", sin retrato)

Sustituye a las 3 líneas actuales. La línea 2 depende de la raza del héroe (`Race`).

1. Noche sin luna. Los goblins han entrado en Valdehierro por la puerta sur.
2. *(línea de raza, abajo)*
3. El Rey Goblin se ha hecho con el castillo. Tiene encerrada a la princesa Aurora.
4. Libera las calles, entra en las casas y rescata a los aldeanos.

| Id | Raza (`Race`) | Línea 2 | Motivo (`mundo.md` §7) **[AC]** |
|---|---|---|---|
| `intro.raza.human` | `human` | Volvías a casa tras años fuera. No esperabas esta bienvenida. | Es de aquí |
| `intro.raza.dwarf` | `dwarf` | Vienes de Rocaforja buscando a un herrero enano. Dicen que forja aquí… si sigue vivo. | Busca a Brokk |
| `intro.raza.elf` | `elf` | Traes un aviso de Velaluna para la princesa: la Luna se apaga. Llegas una noche tarde. | Mensajero |
| `intro.raza.werewolf` | `werewolf` | Seguiste un olor a ceniza desde el bosque. Sin luna, la sangre te arde. Aquí huele más. | Rastro del Eclipse |

Toast al cerrar la intro: `toast.mision.nueva` → «Nueva misión: La noche sin luna».

---

## 3. Los seis aldeanos

Orden de rescate libre: ninguna línea de rescate depende de otra. Tras el rescate, cada uno sale a la calle (mismo id,
casilla en `mapas/valdehierro.md`) y sigue también dentro de su casa.

Qué dice un aldeano al hablarle (propuesta de prioridad **[P]**): 1) entrega pendiente → `entrega`; 2) misión que
ofrecer → `oferta`; 3) misión activa → `recordatorio`; 4) si no, `casa` (dentro) o `calle.<etapa>` (fuera).
Etapas: **`pueblo`** = `valdemar.liberar` sin completar · **`fuera`** = `liberar` hecha y `rey_goblin` no ·
**`libre`** = `valdemar.rey_goblin` hecha. Si un aldeano tiene una línea especial tras una misión, va indicada.

### Marta, la panadera · `marta` (sin misión)

- `npc.marta.plea`: ¡Ratas! ¡Ratas por todas partes! *(sin cambios)*
- `npc.marta.thanks` (rescate):
  1. ¡Gracias, gracias! Creí que me comerían junto con el pan.
  2. La puerta sur estaba abierta. ¡Abierta! Y el cerrojo, sin forzar.
  3. Toma, es todo lo que he podido ahorrar.
- `npc.marta.casa`: Si ves otra rata, no me lo cuentes. Mátala y ya.
- `npc.marta.calle.pueblo`: ¿Pan? Recién hecho. Bueno, recién rescatado del horno. ¡Quedan vecinos encerrados!
- `npc.marta.calle.fuera`:
  1. El Capitán Vela me compra pan para sus hombres. Paga tarde, pero paga.
  2. Los zombis de los huertos huelen peor que mi masa madre. Y mira que es vieja.
- `npc.marta.calle.libre`: ¡Pan de fiesta para el héroe! Con pasas. No te acostumbres.

### Elena, la tejedora · `elena` (da `valdemar.hilos` y `valdemar.alcalde`)

- `npc.elena.plea`: ¡Se están llevando mis telas! *(sin cambios)*
- `npc.elena.thanks`:
  1. Esos bandidos trabajan para el Rey Goblin, estoy segura.
  2. Y alguien les paga bien: llevaban botas nuevas. ¡Botas nuevas, unos bandidos!
  3. Dicen que el Rey tiene a la princesa encerrada en el salón del trono.
- `npc.elena.casa`: Aquí sigo, cosiendo. Con las telas que me dejaron, al menos.
- `npc.elena.calle.tras_alcalde` (tras `valdemar.alcalde`, etapa `fuera`):
  1. ¿Fausto? Fue padrino de mi hija. Le tejí yo la capa con la que ha huido.
  2. Fray Anselmo conocía al abad de Valsombra. Habla con él.
- `npc.elena.calle.libre`: Voy a tejer un tapiz de tu hazaña. Te he puesto un poco más alto.

### Tomás, el molinero · `tomas` (da `valdemar.molino`)

- `npc.tomas.plea`: ¡El espantapájaros ha cobrado vida! *(sin cambios)*
- `npc.tomas.thanks`:
  1. La bruja del pozo hechizó a mi espantapájaros. ¡Con lo majo que era! Hasta le puse sombrero.
  2. Llévate esto. A mí ya no me sirve de nada.
- `npc.tomas.casa`: Si un espantapájaros te mira raro, esta vez no es cosa mía.
- `npc.tomas.calle.fuera` (tras `valdemar.molino`): En primavera vuelvo a sembrar. Si los muertos me dejan.
- `npc.tomas.calle.libre`: He puesto tu nombre a una espiga. Es una espiga preciosa.

### Fray Anselmo · `anselmo` (da `valdemar.abadia`)

- `npc.anselmo.plea`: ¡Que la luz te guíe, joven! ¡Los muertos se levantan! *(sin cambios)*
- `npc.anselmo.thanks`:
  1. Bendito seas. Sin luna, los muertos no descansan: mira mi pobre cementerio.
  2. En la abadía de Valsombra, al este, pasa algo peor. Desde que murió el abad, nadie va.
  3. Esta reliquia te protegerá. Que la Luna de Plata guíe tu acero.
- `npc.anselmo.casa`: Rezo por los vivos y vigilo a los muertos. Últimamente, más lo segundo.
- `npc.anselmo.calle.antes_carta` (antes de `valdemar.alcalde`): El abad Morcar murió hace un año. Lo enterré yo
  mismo. Que en paz descanse… espero.
- `npc.anselmo.calle.tras_abadia` (tras `valdemar.abadia`): Cada noche bajo a rezar junto al Ascua. Nadie más le
  pondrá la mano encima.

### Bruno, el posadero · `bruno` (da `valdemar.caza_mayor`)

- `npc.bruno.plea`: ¡Mi posada! ¡Se están bebiendo toda la cerveza! *(sin cambios)*
- `npc.bruno.thanks` *(sin cambios: es canon y funciona)*:
  1. ¡Ja! ¡Buen golpe, forastero!
  2. El herrero de al lado es un enano gruñón, pero forja como nadie.
  3. Invita la casa.
- `npc.bruno.casa`: ¡Siéntate, forastero! La primera jarra corre de mi cuenta. La segunda, también.
- `npc.bruno.calle.fuera`: En el Pedregal hay orcos que no beben. ¡Desconfía siempre de quien no bebe!
- `npc.bruno.calle.libre`: ¡La Posada del Jabalí invita a todo el pueblo! A la primera ronda, ¿eh?

### Iris, la alquimista · `iris` (da `valdemar.pociones`)

- `npc.iris.plea`: ¡La bruja quiere mis pociones! *(sin cambios)*
- `npc.iris.thanks` (cambia: el castillo ya no se abre solo con los aldeanos):
  1. La bruja del pozo no trabajaba sola. La visitaba un encapuchado de túnica gris.
  2. El Capitán de la guardia sigue vivo, escondido. Saldrá cuando el pueblo esté libre.
  3. Toma estos cristales: tienen magia dentro.
- `npc.iris.casa`: No toques nada de esa mesa. Ni de esa. Bueno, de ninguna.
- `npc.iris.calle.fuera`: ¿Te ha rozado una esfera violeta? Magia del Eclipse. No la lamas.
- `npc.iris.calle.libre`: Por fin hay paz. Ya puedo hacer explotar cosas a propósito.

---

## 4. Capitán Rodrigo Vela · `capitanGuardia`

Aparece en (18,12), al pie de la escalinata, al completar `valdemar.liberar` (`appearsWhen`). Serio, cansado, leal.
Da `valdemar.pedregal`, `valdemar.rey_goblin` y `valdemar.calabozos`.

- `escena.liberar` (al rescatar al sexto aldeano; sustituye a «la gran puerta del castillo cruje y se abre…»;
  speaker "Valdehierro"):
  1. ¡Todos los aldeanos están a salvo! Valdehierro vuelve a respirar.
  2. Al pie de la escalinata del castillo, un soldado con la coraza abollada te hace señas.
- `npc.capitanGuardia.aparicion` (primera vez que se le habla; justo después, su oferta de `valdemar.pedregal`):
  1. Capitán Rodrigo Vela, de la guardia. De lo que queda de ella. Buen trabajo ahí abajo.
  2. El Rey Goblin ha atrancado el castillo… y no está solo.
  3. Orcos en el Pedregal, muertos en la abadía. Y alguien les abrió la puerta sur desde dentro.
  4. Hay que cortarle los apoyos antes de subir. Para eso te necesito.
- `npc.capitanGuardia.falta_abadia` (tras `pedregal`, sin `abadia`): El Pedregal ya es nuestro. Falta la abadía:
  Fray Anselmo sabe de muertos más que yo.
- `npc.capitanGuardia.falta_pedregal` (tras `abadia`, sin `pedregal`): La abadía ya descansa. Faltan los orcos del
  Pedregal. Sin eso, nadie sube.
- `escena.castillo_abierto` (en cuanto se cumple `castleOpen`, esté donde esté el héroe; speaker "Valdehierro"):
  1. Suena un cuerno en la plaza: ¡el Capitán Vela abre la escalinata del castillo!
- `npc.capitanGuardia.calle.libre` (tras `rey_goblin`, antes de `paso_norte`): El castillo vuelve a ser nuestro.
  Ve a la forja: el herrero lleva toda la mañana mirando al norte.
- `npc.capitanGuardia.calle.epilogo` (tras `paso_norte`): Si subes al norte, vigila tu espalda. Lo que huyó por el
  Paso no iba de paseo.

### Escalinata cerrada (`aviso.escalinata.*`)

Se muestra al pisar la escalinata `S` mientras `castleOpen` sea falso (también vale para la puerta del castillo).

| Id | Cuándo | Speaker | Texto |
|---|---|---|---|
| `aviso.escalinata.pueblo` | `liberar` sin hacer (el Capitán aún no está) | — (toast) | La escalinata está atrancada desde arriba. Primero, libera el pueblo. |
| `aviso.escalinata.ambas` | faltan `abadia` y `pedregal` | Capitán Vela | Nadie sube hasta que limpiemos la abadía y el Pedregal. Órdenes mías. |
| `aviso.escalinata.abadia` | falta `abadia` | Capitán Vela | Falta la abadía. Hasta que los muertos de Valsombra caigan, nadie sube. |
| `aviso.escalinata.pedregal` | falta `pedregal` | Capitán Vela | Falta el Pedregal. Hasta que caiga el Señor de la guerra, nadie sube. |

Si solo cabe un texto fijo: `aviso.escalinata.ambas`.

---

## 5. Las 11 misiones

Formato: título (`Quest.title`) · diario (`Quest.summary`, una línea) · HUD (uno por objetivo, en orden) · oferta ·
recordatorio · entrega. Speaker de oferta/recordatorio/entrega = quien da la misión.

### 1 · `valdemar.liberar` — automática

- `titulo`: La noche sin luna
- `diario`: Libera las calles de Valdehierro y rescata a sus seis aldeanos.
- `hud.1` (`rescue`): Rescata a los aldeanos: {n}/6
- `oferta`: = `escena.intro` (se acepta sola).
- `entrega`: = `escena.liberar` (§4). Después, HUD: **Habla con el Capitán Vela, al pie de la escalinata.**

### 2 · `valdemar.molino` — Tomás

- `titulo`: El molino de mi padre
- `diario`: Tomás: limpia de zombis los Huertos del Molino y echa al Ogro del molino viejo.
- `hud.1`: Granjeros zombi en los Huertos: {n}/6 · `hud.2`: Derrota al Ogro del molino
- `oferta`:
  1. Mis trigales, al oeste del pueblo… quemados. Y ahora los pisan granjeros muertos.
  2. En el molino viejo de mi padre se ha metido un ogro. ¡Un ogro! Duerme encima de mi harina.
  3. Limpia los trigales y echa a ese bicho. Mi padre te lo agradecería. Y yo, más.
- `recordatorio`: Los huertos, por la salida oeste. El molino viejo queda al noroeste, pasado el trigal.
- `entrega`:
  1. ¿El ogro, fuera? ¡Ja! Mi padre estaría orgulloso. Y muy sorprendido.
  2. Esos muertos venían del este, de Valsombra. Allí los muertos no descansan.
  3. Toma, plata de la buena. Era para un molino nuevo, pero te la has ganado.

### 3 · `valdemar.caza_mayor` — Bruno

- `titulo`: Caza mayor
- `diario`: Bruno: caza lobos en el Bosque de Robleda y acaba con el Lobo alfa.
- `hud.1`: Lobos grises en Robleda: {n}/6 · `hud.2`: Derrota al Lobo alfa
- `oferta`:
  1. Una posada sin venado ni jabalí es una casa con sillas, forastero.
  2. Los lobos de Robleda no dejan pasar a un cazador. Y su jefe es grande como un carro.
  3. Caza seis lobos y trae la cabeza del alfa. Bueno, la cabeza no, que luego huele.
- `recordatorio`: Robleda, por la puerta sur. La guarida del alfa está al sureste, entre las rocas.
- `entrega`:
  1. ¡Ese colmillo va encima de la barra! «Lo cazó un cliente». Precioso.
  2. Los arrieros dicen que los orcos del Pedregal llevan hachas nuevas. Negras.
  3. Ten, hierro del bueno. Y vuelve a cenar: hay estofado. De lobo no, tranquilo.

### 4 · `valdemar.hilos` — Elena (columna principal)

- `titulo`: Tirar del hilo
- `diario`: Elena: desmonta el campamento bandido de Robleda y vuelve con lo que encuentres.
- `hud.1`: Bandidos o mercenarios en Robleda: {n}/8 · `hud.2`: Vuelve con Elena
- `oferta`:
  1. Esos bandidos no robaban por hambre: alguien les pagaba.
  2. Se llevaron mis telas a su campamento, en el bosque de Robleda. Al sur, por el camino real.
  3. Desmonta ese campamento y tráeme lo que encuentres. Quiero saber de quién es el oro.
- `recordatorio`: El campamento bandido está al suroeste de Robleda, tras la empalizada.
- `entrega` (al hablar con ella = objetivo `talk(elena)`):
  1. ¿Esto llevaban? Monedas nuevas… con el sello del concejo de Valdehierro.
  2. Solo el alcalde tiene la llave del arca. Y desde la noche del ataque no ha salido de casa.
  3. Su puerta no aguantará mucho. Yo tampoco pienso esperar.
- Toast al entregar: `toast.mayor.abierta` → «La casa del alcalde ya no está atrancada.»

### 5 · `valdemar.alcalde` — Elena (columna principal, se completa al leer la carta)

- `titulo`: La casa del alcalde
- `diario`: Elena: entra en la casa del alcalde Fausto y averigua qué esconde.
- `hud.1` (`clear(mayor)`): Despeja la casa del alcalde (barrio este) · `hud.2` (`read`): Lee la carta del escritorio
- `oferta` (justo después de la entrega de `hilos`):
  1. Entra en casa del alcalde. Si es inocente, que me lo diga a la cara.
  2. Y si no lo es, busca papeles. Los tramposos siempre lo apuntan todo.
- `recordatorio`: La casa del alcalde está en el barrio este, al lado de la de Iris.
- `aviso.mayor.entrar` (toast al entrar la primera vez): Papeles ardiendo en la chimenea. Del alcalde, ni rastro.
- `aviso.mayor.despejada` (en vez de «¡Sala despejada! Habla con quien estaba atrapado.»):
  ¡Sala despejada! Hay una carta sobre el escritorio.
- `entrega`: = `npc.cartaAlcalde.leer` (§6). Después, HUD: **Habla con Fray Anselmo.**

### 6 · `valdemar.pociones` — Iris

- `titulo`: Limo fresco
- `diario`: Iris: aplasta seis limos de cualquier color en Valdemar.
- `hud.1`: Limos de cualquier color: {n}/6
- `oferta`:
  1. Necesito limo para mis pociones. Fresco, a poder ser.
  2. Verdes en los huertos, de fuego en la abadía, helados en las pozas del Pedregal.
  3. Seis limos, del color que sea. No soy tiquismiquis.
- `recordatorio`: Limos verdes en los huertos, de fuego en la abadía y helados en el Pedregal.
- `entrega`:
  1. ¡Qué textura! Este limo de fuego aún burbujea.
  2. Ojo con los encapuchados grises de la abadía: sus esferas violetas queman por dentro.
  3. Toma esta esmeralda. Tiene más magia que todo mi estante.

### 7 · `valdemar.abadia` — Fray Anselmo (columna principal)

Requisitos: Anselmo rescatado **y** `valdemar.alcalde` hecha.

- `titulo`: Los muertos de Valsombra
- `diario`: Fray Anselmo: limpia el cementerio de Valsombra y baja a la cripta de la abadía.
- `hud.1`: No-muertos en la abadía: {n}/10 · `hud.2`: Supera la Cripta de la abadía
- `oferta`:
  1. ¿«M.»? ¿Morcar? Imposible: yo mismo lo enterré hace un año.
  2. Aunque… dicen que en Valsombra las lápidas amanecen abiertas.
  3. Limpia el cementerio y baja a la cripta. Si Morcar sigue allí, no es por gracia de la Luna.
- `recordatorio`: Valsombra, por la salida este. La bajada a la cripta está en el claustro, junto a la iglesia.
- `entrega`:
  1. Así que Morcar volvió de la tumba para servir al Eclipse. Que la Luna lo perdone. Yo no.
  2. ¿Y dices que al fondo de la cripta brillaba una brasa dorada? Un Ascua del Alba…
  3. Juro guardarla mientras viva. El Eclipse no volverá a tocarla.
- Tras entregar, si se cumple `castleOpen`: `escena.castillo_abierto`; si no: toast `toast.falta.pedregal` →
  «El Capitán Vela espera noticias del Pedregal.»

### 8 · `valdemar.pedregal` — Capitán Vela (columna principal)

- `titulo`: Hachas en el Pedregal
- `diario`: Capitán Vela: deja al Rey Goblin sin orcos en las Colinas del Pedregal.
- `hud.1`: Orcos en el Pedregal: {n}/6 · `hud.2`: Derrota al Señor de la guerra orco
- `oferta` (tras `npc.capitanGuardia.aparicion`):
  1. Los orcos del Pedregal le venden brazos al Rey Goblin. Los manda un Señor de la guerra.
  2. Están al sureste, pasado el bosque de Robleda. Mata orcos y tumba a su jefe.
  3. Es mal sitio para novatos. Si aún no estás listo, ayuda antes a los vecinos: ellos también te necesitan.
- `recordatorio`: Pasado Robleda, hacia el este. El campamento orco está al fondo, tras la empalizada.
- `entrega`:
  1. ¿El Señor de la guerra, muerto? Mis hombres brindarán por ti hasta el invierno.
  2. ¿Has visto sus hachas? Negras y sin una mella. Eso no lo forja un orco.
  3. Enséñaselas al herrero algún día. Yo no sé de fuegos, pero ese huele mal.
- Tras entregar: si se cumple `castleOpen` → `escena.castillo_abierto` y oferta de `rey_goblin`; si no →
  `npc.capitanGuardia.falta_abadia`.

### 9 · `valdemar.rey_goblin` — Capitán Vela (columna principal, se completa al hablar con Aurora)

- `titulo`: El trono de Valdehierro
- `diario`: Sube al castillo, derrota al Rey Goblin y libera a la princesa Aurora.
- `hud.1`: Derrota al Rey Goblin · `hud.2`: Habla con la princesa Aurora
- `oferta`:
  1. Sin orcos ni muertos, el Rey Goblin está solo. La escalinata es tuya.
  2. El patio está lleno de su guardia. Mis hombres no pasarán de la puerta: tú sí.
  3. Trae a la princesa a casa.
- `recordatorio`: El salón del trono está al fondo del patio. Aurora lleva demasiado tiempo esperando.
- `entrega`: = `npc.princess.thanks` (§9). Después, HUD: **Ve a la forja: el herrero quiere verte.**

### 10 · `valdemar.paso_norte` — el herrero (`smithy`), se ofrece y se completa al entrar en la forja

- `titulo`: Fuego Hollín
- `diario`: El herrero de la forja quiere hablar contigo.
- `hud.1`: Ve a la forja: el herrero quiere verte.
- `oferta` + `entrega`: = `escena.epilogo` (§10).
- Toasts al completar: «¡El Paso del Norte está abierto!» · «Nuevas piezas en la forja (T2)».
- Después, HUD: **El Paso del Norte está abierto. Rocaforja espera… pronto.**

### 11 · `valdemar.calabozos` — Capitán Vela (opcional, P3)

- `titulo`: Ronda por los calabozos
- `diario`: Capitán Vela: limpia los calabozos del castillo. Si se vuelven a llenar, vuelve.
- `hud.1`: Supera los Calabozos del castillo
- `oferta`:
  1. Bajo el patio están los calabozos. Hay goblins de élite atrincherados ahí abajo.
  2. Límpialos y te pago de la caja de la guardia. Si vuelven a colarse… vuelve tú también.
- `recordatorio`: La reja de los calabozos está en el patio, a mano derecha.
- `entrega`:
  1. Ni un goblin en los calabozos. Así da gusto hacer la ronda.
  2. Si vuelven a colarse, ya sabes dónde están.

### Toasts y textos comunes de misiones

| Id | Texto |
|---|---|
| `toast.mision.nueva` | Nueva misión: {título} |
| `toast.mision.objetivo` | ¡Objetivo cumplido! Vuelve con {nombre}. |
| `toast.mision.cumplida` | Misión cumplida: {título} · +{xp} XP · +{oro} oro |
| `ui.diario.titulo` | Diario |
| `ui.diario.activas` / `ui.diario.hechas` | En curso / Cumplidas |

---

## 6. Objetos que se leen (`role: .clue`)

### `npc.cartaAlcalde.leer` — Carta del alcalde (casa `mayor`, se lee con la sala despejada)

Speaker: "Carta del alcalde". Completa `valdemar.alcalde`.

1. Media carta chamuscada. Lacre negro con una luna apagada.
2. «Fausto: la noche sin luna, deja abierta la puerta sur. Los goblins harán el resto.»
3. «Tu oro y tu sitio en la Orden te esperan. El Abad cumple lo que promete. — M.»
4. ¿M.? El único abad de la comarca era Morcar, el de Valsombra. Y murió hace un año.

- `npc.cartaAlcalde.otra_vez` (si se vuelve a leer): «…El Abad cumple lo que promete. — M.»

### `npc.cartelPaso.leer` — Cartel del camino (`valdemar.paso`, (26,2))

Speaker: "Cartel del camino".

1. Un poste con dos tablas. Al sur: «Valdehierro». Al norte: «Montes de Rocaforja».
2. En el barro, huellas de botas recientes y un jirón de capa gris. Buen paño.
3. Elena reconocería ese punto en cualquier parte.

---

## 7. Presentaciones de jefes

**[P]** Hoy no hay un momento para que hable un jefe de campo o del trono. Propuesta: al entrar el héroe en el radio
de alerta de un spawn de jefe por **primera vez** (no en reapariciones), se pausa y sale este diálogo con el nombre
del jefe como speaker. El Abad usa el campo que ya existe (`StoryDungeon.bossIntro`).

### `boss.ogre.intro` — Ogro del molino (Huertos, `valdemar.huertos.1`)

1. ¡GRRR! ¡Molino mío! ¡Harina mía!
2. Tú… pequeño. Tú cabe en un pan.

### `boss.alphaWolf.intro` — Lobo alfa (Robleda, `valdemar.robleda.18`; speaker "Valdehierro", narra)

1. Un aullido hace callar el bosque entero.
2. El Lobo alfa sale de entre las rocas. Bruno no exageraba: es grande como un carro.

### `dungeon.valdemar.cripta.bossIntro` — Abad no-muerto (Cripta, antes de abrir la `BBB`)

Speaker: "Abad Morcar". Es la confesión a medias: nombra a la princesa y a «Él», nunca al Ascua.

1. Bienvenido a mi abadía, forastero. Perdona el polvo: llevo un año muerto.
2. ¿El castillo? No buscaba el castillo, necio. Buscaba lo que tu princesa esconde.
3. La Luna se apaga… y Él despierta.
4. Arrodíllate. Quizá te deje ver el último amanecer.

- `dungeon.valdemar.cripta.bossIntro.repeticion` **[P]** (si se repite la cripta): ¿Otra vez tú? La muerte me sienta
  mejor que a ti.
- `boss.abbot.derrota` **[P]** (al caer, solo la primera vez):
  1. *(Abad Morcar)* La Orden… no muere conmigo. Quedan cinco brasas…
  2. *(Valdehierro)* Al fondo de la cripta algo brilla, dorado y caliente como una brasa viva.

### `boss.warlord.intro` — Señor de la guerra orco (Pedregal, `valdemar.pedregal.19`)

1. ¿Un enviado del Rey Goblin? No… tú hueles a pueblo libre.
2. Mis hachas vienen del norte, templadas en fuego negro. No se mellan. ¡Pruébalas!

### `boss.goblinKing.intro` — Rey Goblin (Salón del trono, `castle.6`)

1. ¡Mi castillo! ¡Mi trono! ¡Mi princesa! ¡Todo mío!
2. El encapuchado me lo prometió. ¡Y un rey goblin siempre cobra!
3. ¡Guardias! ¡Aplastad a ese… a ese… lo que sea!

### Jefes del pueblo (opcional, misma propuesta, una línea)

| Id | Jefe | Línea |
|---|---|---|
| `boss.ratKing.intro` | Rey de las ratas | ¡Iiiik! ¡Este pan es del rey! ¡Todo el pan es del rey! |
| `boss.scarecrow.intro` | Espantapájaros maldito | *(crujido de paja)* … sombrero… nuevo… |
| `boss.possessedSmith.intro` | Herrero poseído | ¡Más fuego! ¡La voz quiere más fuego! |
| `boss.witch.intro` | Bruja del pozo | ¿Pociones gratis? Ji, ji. El encapuchado me prometió todas. |
| `boss.banditChief.intro` | Capitán bandido | Me han pagado por esta plaza. Y yo cumplo lo que cobro. |

---

## 8. Mazmorras de historia

| Id | Texto |
|---|---|
| `dungeon.valdemar.cripta.nombre` | Cripta de la abadía *(= `StoryDungeon.name`)* |
| `dungeon.valdemar.cripta.entrar` | Cripta de la abadía · 8 |
| `dungeon.valdemar.cripta.ganar` | ¡Cripta despejada! El Abad Morcar ha caído. *(repeticiones: «¡Cripta despejada!»)* |
| `dungeon.valdemar.cripta.perder` | La oscuridad de la cripta te vence. Despiertas junto a la hoguera de Valsombra. |
| `dungeon.valdemar.calabozos.nombre` | Calabozos del castillo |
| `dungeon.valdemar.calabozos.entrar` | Calabozos del castillo · 9 |
| `dungeon.valdemar.calabozos.ganar` | ¡Calabozos despejados! |
| `dungeon.valdemar.calabozos.perder` | Te sacan a rastras de los calabozos. Despiertas en la Puerta sur. |
| `dungeon.valdemar.calabozos.cerrada` | Una reja oxidada cierra los calabozos. Primero, el castillo. *(= `DungeonEntrance.lockedMessage`)* |

---

## 9. Princesa Aurora · `princess`

Cambio menor: ahora nombra al Eclipse y explica por qué quieren la Hoja.

- `npc.princess.plea`: ¡Cuidado, héroe! El Rey Goblin no es más que el perro del Eclipse… pero muerde.
- `npc.princess.thanks` (completa `valdemar.rey_goblin`):
  1. ¡Has vencido al Rey Goblin! Valdehierro vuelve a ser libre.
  2. No querían mi castillo. Querían esto: la Hoja del Alba. Mi familia la ha guardado siglos.
  3. La Luna se apaga y el Eclipse quiere apagarla del todo. Esta hoja es lo único que lo frena.
  4. Llévala al ritual de forja. Solo un héroe puede despertarla.
- `npc.princess.casa` (después): Valdehierro te debe todo, héroe. *(la línea actual)*
- `npc.princess.casa.epilogo` (tras `paso_norte`): La Alianza del Alba debe renacer. Empezaré escribiendo a
  Hondoyunque.

---

## 10. El herrero enano · `smithy` — epílogo y bocadillos

Nombre **[AC]**: **Brokk Martillohondo** (propuesta de `mundo.md`). Hasta el epílogo el speaker es «El herrero»;
desde él, «Brokk, el herrero». Coherente con Rocaforja: Brokk es un Hollín de nacimiento y **no** confiesa aquí que
encendió el primer fuego negro (eso es la deuda del capítulo 2); solo lo reconoce.

### `escena.epilogo` — al entrar en la forja tras `valdemar.rey_goblin`, antes de abrir la tienda

Parte 1 (speaker «El herrero»):
1. Así que la princesa te ha dado la Hoja del Alba. Bah. Tráela al ritual cuando quieras.
2. Pero antes mira esto: un hacha de los orcos del Pedregal.
3. Este temple negro no se mella ni se enfría. Es fuego Hollín. Mi viejo clan.
4. Me llamo Brokk. Brokk Martillohondo. Ya iba siendo hora de que lo supieras.

Parte 2 (speaker «Brokk, el herrero»):
1. Esta mañana, desde la muralla, vi a un encapuchado subir por el Paso del Norte.
2. Andaba como un alcalde gordo con prisa. Fausto, me apuesto el yunque.
3. Va hacia Rocaforja. Hacia mi tierra. Si vas tras él, voy contigo.
4. Y desde hoy vendo acero de verdad. Se acabó el cobre para críos.

### Bocadillos de la tienda (opcional, se suman a `ForgeShopView`)

| Id | Cuándo | Línea |
|---|---|---|
| `smithy.bocadillo.fuera.1` | etapa `fuera` | ¿Plata de los huertos? ¿Oro del Pedregal? Tráemelo todo. |
| `smithy.bocadillo.fuera.2` | tras `pedregal` | ¿Hachas orcas negras? Ni me las nombres. Ni me las enseñes. |
| `smithy.bocadillo.libre.1` | tras `paso_norte` | Acero de verdad, como en Rocaforja. Bueno, casi. |
| `smithy.bocadillo.libre.2` | tras `paso_norte` | Cuando quieras, subimos. Yo llevo el martillo; tú, las piernas. |

---

## 11. Avisos: salidas, edificios cerrados, zonas y muerte

### Salidas cerradas (`AreaExit.lockedMessage`)

| Id de salida | Bloqueo | Texto |
|---|---|---|
| `town.oeste` | zona `west` liberada | Los goblins del barrio oeste cortan el camino de los huertos. *(sin cambios)* |
| `town.este` | zona `east` liberada | Los cultistas del barrio este vigilan el camino de la abadía. *(sin cambios)* |
| `town.norte` | `valdemar.paso_norte` | El Paso del Norte está cerrado. Primero, el castillo; luego, habla con el herrero. |
| `paso.norte` | `comingSoon("rocaforja")` | Montes de Rocaforja: próximamente. El camino sigue en el capítulo 2. |
| (`e`) `valdemar.calabozos` | `castleOpen` | = `dungeon.valdemar.calabozos.cerrada` |

Cambio en `town.norte`: el texto del borrador («El herrero sabe por qué») no tiene sentido antes del trono, cuando el
herrero aún no sabe nada; el nuevo sirve para todo el capítulo.

### Edificios sin interior **[P]**

Hoy el código dice «{nombre}: está cerrada.» (y queda raro con «Molino en ruinas» o «Puesto del guardabosques»).
Propuesta: un `lockedMessage` opcional por edificio; si no lo hay, «{nombre}: no se puede entrar.».

| Edificio (id) | Área | Texto |
|---|---|---|
| `mayor` (hasta `hilos`) | `town` | La casa del alcalde está atrancada por dentro. Elena, la tejedora, sospecha algo. |
| `castle` (hasta `castleOpen`) | `town` | La puerta del castillo está atrancada. El Capitán Vela aún no la abrirá. |
| `molino` | `valdemar.huertos` | El molino está medio derruido. Dentro, harina podrida y olor a ogro. |
| `granja1`, `granja2` | `valdemar.huertos` | Solo quedan vigas quemadas. Aquí ya no vive nadie. |
| `cabana` | `valdemar.robleda` | El puesto del guardabosques está cerrado. Huyó cuando llegaron los lobos. |
| `iglesia` | `valdemar.abadia` | La iglesia está tapiada. La bajada a la cripta está en el claustro. |
| `atalaya` | `valdemar.paso` | La atalaya está derruida. Desde aquí se ve el castillo… y el camino al norte. |

### Áreas y zonas

- Cartel al entrar (M10): `{área} · {niveles}` con los nombres de `zonas.md`: «Valdehierro · 1-5», «Huertos del
  Molino · 5-6», «Bosque de Robleda · 6-7», «Abadía de Valsombra · 7-8», «Colinas del Pedregal · 8-9», «Paso del
  Norte · 10», «Casa del alcalde · 7». Nombres de zonas: los de `zonas.md` §2, sin cambios.
- `toast.zona.liberada` **[P]**: hoy es «¡{zona} liberado!», que falla con nombres femeninos o en plural («¡Trigales
  quemados liberado!»). Propuesta: **«¡Zona liberada: {zona}! +{oro} oro»**.
- `escena.paso.entrar` (opcional, primera vez en `valdemar.paso`): Goblins rezagados huyen del castillo… hacia las
  montañas.

### Muerte

- `aviso.muerte.campo` (M9): Caes rendido… Despiertas junto a la hoguera de {área}.
- `aviso.muerte.pueblo` (como ahora): reaparición en la Puerta sur.

### Objetivo del HUD cuando no hay misión activa (`ExploreSession.objective`) **[P]**

| Momento | Texto |
|---|---|
| `liberar` en curso | Rescata a los aldeanos: {n}/6 |
| `liberar` hecha, Capitán sin hablar | Habla con el Capitán Vela, al pie de la escalinata. |
| Hay "?" pendiente | Vuelve con {nombre}: {título} |
| Fuera, nada activo | Los vecinos te necesitan: busca el «!» en la calle. |
| `castleOpen` | ¡El castillo está abierto! Derrota al Rey Goblin. |
| `rey_goblin` hecha | Ve a la forja: el herrero quiere verte. |
| `paso_norte` hecha | El Paso del Norte está abierto. Rocaforja espera… pronto. |

---

## 12. Variantes por raza (opcional)

Una línea extra en un momento clave para que cada raza sienta que el mundo la reconoce. Se inserta **después** de la
línea indicada; si ocupa una 5.ª línea, el diálogo pasa a dos cuadros seguidos.

| Id | Raza | Dónde | Línea |
|---|---|---|---|
| `raza.human.aurora` | `human` | tras `npc.princess.thanks` 1 | Eres de aquí, ¿verdad? Valdehierro siempre cuida de los suyos. |
| `raza.elf.aurora` | `elf` | tras `npc.princess.thanks` 1 | ¿Un aviso de Velaluna? Llega tarde… pero llega. Gracias. |
| `raza.werewolf.aurora` | `werewolf` | tras `npc.princess.thanks` 1 | Tus ojos brillan como los de un lobo. Esta noche, me alegro de tenerlos de mi lado. |
| `raza.dwarf.brokk` | `dwarf` | tras `escena.epilogo` parte 1, línea 4 | Hondoyunque te mandó a buscarme, ¿eh? Pues mira: volvemos juntos. |

---

## 13. Propuestas de mecánica o datos (no implementadas; decide el `game-programmer` / lead)

1. **Diálogos de misión**: `Quest` solo tiene `title` y `summary`. Para `oferta`, `recordatorio`, `entrega` y los
   `hud.n` hacen falta campos (p. ej. `offer: [String]`, `reminder: String`, `turnIn: [String]`,
   `objectiveLabels: [String]`) o una tabla aparte en `ValdemarQuests.swift` por id de misión.
2. **Diálogo de calle por etapa**: `NPC` solo tiene `plea` y `thanks`. Para `casa` y `calle.<etapa>`, un campo opcional
   (p. ej. `talk: [StoryStage: [String]]`) o una tabla por id de NPC. Mínimo viable: una sola línea de `calle`.
3. **Presentación de jefe** (`boss.*.intro`) al verlo por primera vez, y **línea al caer** (`boss.abbot.derrota`).
4. **`lockedMessage` por edificio** y el toast de zona liberada con «Zona liberada: {zona}».
5. **Variantes por raza** (§2 y §12): la intro las necesita; el resto es opcional.
6. **Cartel del Paso** (`cartelPaso`) como `clue` que se lee al acercarse, igual que la carta.

## 14. Notas para el lead y el usuario

**Decisiones a confirmar [AC]** (se usan como propuesta; `mundo.md`, final):
- El Abad Morcar es el Heraldo del Eclipse; la Bruja, su aliada; el alcalde Fausto, el traidor (§3, §5-7). Si se
  elige otra opción, cambian: carta (§6), confesión (§7), Anselmo y Elena (§5).
- El héroe es un forastero con un motivo por raza (§2). Si fuera el caballero de Aurora, solo cambian las 4 líneas
  de raza y §12.
- El villano final (Morvath) solo se insinúa como «Él» y «quedan cinco brasas»: no se nombra en el capítulo 1.
- Nombre del enano: Brokk Martillohondo (§10).

**Cambios respecto a `continentes/valdemar/historia.md` del lead** (para que los apruebe):
- **Carta del alcalde**: firmada «— M.» y dirigida a Fausto (no firmada «— F.»). Así una carta que está en casa de
  Fausto tiene sentido (es la que recibió), lo delata y a la vez nombra al Abad, que es lo que abre `valdemar.abadia`.
- **Elena**: «Fue padrino de mi hija» en vez de «bautizó a mi hija» (un alcalde no bautiza).
- **Aviso de `town.norte`**: ver §11.
- **Pistas tempranas** añadidas a los rescates (puerta sin forzar, botas nuevas, encapuchado gris, abad muerto) y el
  hilo de las **hachas negras** (Bruno → Señor de la guerra → Capitán → Brokk) como gancho a Rocaforja.
- Id del herrero: las misiones usan `smithy` (contrato) y Rocaforja propone `brokk`: hay que decidir uno al llegar
  al capítulo 2.

## 15. SW2 · dónde está cada texto en el código (2026-10-08)

| Textos | Fichero (`src/GameCore/Sources/GameCore/`) | Campo |
|---|---|---|
| Misiones §5 (título, diario, HUD, oferta, recordatorio, entrega), escalinata §4, puertas `castle`/`mayor` | `ValdemarQuests.swift` | `Quest.*`, `stairsMessage`, `castleOpensLines`, `doorLocks` |
| Intro y raza §2/§12, jefes §7, mazmorras §8, avisos y HUD §11 | `ValdemarDialogue.swift` | — |
| `plea`/`thanks` de aldeanos, carta, Aurora; `casa` | `Town.swift` (interiores de `Valdehierro`) | `NPC.plea/thanks/talk` |
| `calle.*` de aldeanos, Capitán (`falta_*`, `calle.*`) | `Town.swift` (`streetNPCs`) | `NPC.talk` (+ `thanks` = reserva) |
| Cartel del Paso, salida `paso.norte`, edificios de campo, cripta (`bossIntro`, repetición, derrota) | `Valdemar.swift` | `NPC.thanks`, `AreaExit/Building.lockedMessage`, `StoryDungeon.*` |
| `town.norte`, reja de los calabozos | `Town.swift` | `AreaExit/DungeonEntrance.lockedMessage` |

**Líneas nuevas escritas en SW2** (no estaban en el guion; hacían falta como reserva o bocadillo):

| Id | Texto |
|---|---|
| `npc.capitanGuardia.bocadillo` (`plea`) | Guardia de Valdehierro. Lo que queda de ella. |
| `npc.capitanGuardia.reserva` (`thanks`) | Mis hombres guardan la escalinata. Lo de fuera es cosa tuya. |
| `npc.cartaAlcalde.bocadillo` (`plea`) | Una carta a medio quemar, con lacre negro. |
| `npc.elena.calle.pueblo` | Botas nuevas, unos bandidos… Alguien les paga, y pienso saber quién. |
| `npc.tomas.calle.pueblo` | Mi molino de los huertos… y ahora dicen que duerme un ogro dentro. |
| `npc.bruno.calle.pueblo` | ¡Quedan goblins sueltos! Cuando acabes, la cerveza estará fresquita. |
| `npc.iris.calle.pueblo` | Mientras queden goblins en el pueblo, mis matraces no salen de casa. |
| `npc.anselmo.calle.*` (reserva) | = `npc.anselmo.casa` |

**Colocado por el programador (P2, 2026-10-08):** los cuatro textos de abajo ya están en el código: carta releída →
`NPC.talk` de `cartaAlcalde` (`Town.swift`); bocadillos → `ValdemarDialogue.smithStoryBubbles`; entrada al Paso →
`ValdemarDialogue.firstVisitScenes`; hablante de la cripta → `StoryDungeon.bossSpeaker` = «Abad Morcar» (también en la
derrota, que sale como «Abad Morcar: «La Orden…»» + la línea del narrador). `converse` ya usa el NPC del área actual.

**Sin colocar** (antes de P2; se deja como registro):
- `npc.cartaAlcalde.otra_vez`: una pista (`clue`) siempre repite sus `thanks`.
- `smithy.bocadillo.*`: las frases de la forja (`ForgeShopView`) no dependen de la etapa.
- `escena.paso.entrar`: no hay aviso de "primera vez en un área".
- Hablante de la cripta: sale el nombre del bestiario («Abad no-muerto»), no «Abad Morcar».
- Las líneas `casa` están en los NPC de dentro, pero hoy `ExploreSession.converse` busca el NPC con `World.npc(id)`,
  que devuelve el de la calle: dentro de casa se oyen las de `calle.*` (aviso al programador).
