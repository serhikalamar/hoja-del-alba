# Biblia de la historia

La mantiene el agente `story-writer`. Resume lo que **ya está en el juego** y lo que está **decidido para
implementar**; lo que falta por decidir está en «Misterios abiertos» y «A confirmar».
Fuente del mundo: `assets/world/mundo.md` (Ardenia, 6 continentes, niveles 1-60). Guion completo del capítulo 1, con
todos los textos e ids: **`assets/story/valdemar.md`**.

Última actualización: 2026-10-08 (capítulo 1 de Ardenia: Valdemar; textos pasados al código en SW2).

## 1. El mundo en breve: Ardenia

- Seis **Herreros Primeros** forjaron Ardenia en el **Yunque del Alba** y dejaron en cada continente un **Ascua del
  Alba**, una brasa viva que mantiene la tierra fértil y la **Luna de Plata** encendida.
- Un séptimo herrero, **Morvath**, quiso fundir las seis Ascuas en la **Hoja del Ocaso**; lo sellaron dentro de la
  Luna. Lo llaman **el Herrero Hueco**. **[AC]**
- La **Hoja del Alba**, forjada con una chispa de las seis Ascuas para vigilar el sello, la guarda el linaje de la
  **princesa Aurora**.
- La Luna se apaga: cada año hay más **noches sin luna** (la *Larga Noche*). Morvath susurra a los ambiciosos y nace
  la **Orden del Eclipse**, que busca las Ascuas y la Hoja del Alba. En cada continente, un **Heraldo** corrompe a un
  poder local.
- Los minerales son «virutas» de aquella forja: por eso el ritual del enano despierta habilidades secretas.

Términos fijos: *Ascua del Alba*, *Hoja del Alba*, *Hoja del Ocaso*, *Orden del Eclipse*, *Heraldo*, *Alianza del
Alba*, *Larga Noche*, *Herrero Hueco*, *Luna de Plata*, *fuego negro* (o *fuego Hollín*, para los enanos).

## 2. Capítulo 1 · Valdemar (niveles 1-10) — decidido

**Premisa.** Una **noche sin luna**, los goblins del **Rey Goblin** entran en **Valdehierro** por la puerta sur y toman
el castillo con la princesa Aurora dentro. El héroe llega esa misma noche, libera las calles y rescata a los seis
aldeanos. El Rey Goblin no estaba solo: los orcos del Pedregal le daban músculo, los muertos de la abadía de Valsombra
se habían levantado y **alguien abrió la puerta sur desde dentro**: el alcalde **Fausto Ledesma**, pagado por el
**Abad Morcar**, Heraldo del Eclipse. Vencidos el Abad y el Señor de la guerra, el Capitán de la guardia abre el
castillo; el héroe derrota al Rey Goblin y Aurora le entrega la **Hoja del Alba (I)**. En el epílogo, el herrero
**Brokk** reconoce en las hachas orcas el **fuego Hollín** de su viejo clan y cuenta que Fausto huyó por el **Paso del
Norte**, hacia Rocaforja.

Emoción: **hogar**. Tono: humor de taberna y vecinos entrañables; la amenaza se intuye y crece.

### Por qué está el héroe en Valdehierro (una línea en la intro, por raza) **[AC]**

| Raza | Patria (su capítulo) | Motivo |
|---|---|---|
| Humano | Valdemar (1) | Vuelve a casa tras años fuera, justo la noche del ataque. |
| Enano | Rocaforja (2) | Busca a un herrero enano que se fue de Rocaforja hace veinte años (Brokk). |
| Elfo | Lunaria (3) | Trae para la princesa un aviso de Velaluna: la Luna se apaga. Llega una noche tarde. |
| Hombre lobo | Lunaria (3) | Sigue un olor a ceniza (el Eclipse) desde el bosque; la luna apagada le duele. |

Sin pasado fijo: el jugador lo hace suyo. El héroe no habla; los demás reaccionan a lo que hace.

### Cómo se descubre la trama (pistas, en orden libre)

| Pista | Quién / dónde |
|---|---|
| La puerta sur estaba abierta y el cerrojo sin forzar | Marta (rescate) |
| Los bandidos cobraban de alguien (botas nuevas) | Elena (rescate) |
| La bruja recibía a un encapuchado de túnica gris | Iris (rescate) |
| En Valsombra pasa algo peor desde que murió el abad | Fray Anselmo (rescate y calle) |
| Los orcos del Pedregal llevan hachas nuevas, negras | Bruno → Señor de la guerra → Capitán → Brokk |
| Monedas del concejo en el campamento bandido | Elena (`valdemar.hilos`) |
| Carta a Fausto firmada «M.»: la puerta sur, el oro, la Orden | Casa del alcalde (`valdemar.alcalde`) |
| El Abad buscaba «lo que tu princesa esconde» y «Él despierta» | Abad Morcar en la cripta |
| Al fondo de la cripta brilla un Ascua del Alba | Tras vencer al Abad |
| Fuego Hollín en las hachas; un encapuchado huye al norte | Brokk (epílogo) |
| Jirón de capa gris tejida por Elena junto al cartel de Rocaforja | Paso del Norte |

### Misiones (ids estables; textos en `valdemar.md` §5)

| Id | Título | Da |
|---|---|---|
| `valdemar.liberar` | La noche sin luna | automática |
| `valdemar.molino` | El molino de mi padre | Tomás |
| `valdemar.caza_mayor` | Caza mayor | Bruno |
| `valdemar.hilos` | Tirar del hilo | Elena |
| `valdemar.alcalde` | La casa del alcalde | Elena |
| `valdemar.pociones` | Limo fresco | Iris |
| `valdemar.abadia` | Los muertos de Valsombra | Fray Anselmo |
| `valdemar.pedregal` | Hachas en el Pedregal | Capitán Vela |
| `valdemar.rey_goblin` | El trono de Valdehierro | Capitán Vela |
| `valdemar.paso_norte` | Fuego Hollín | el herrero (`smithy`) |
| `valdemar.calabozos` | Ronda por los calabozos (opcional) | Capitán Vela |

El castillo se abre con `liberar` + `abadia` + `pedregal` (ya **no** al rescatar al sexto aldeano).

## 3. Lugares

### Valdehierro (`town`, capital de Valdemar)

| Lugar (id de zona) | Nivel | Qué hay |
|---|---|---|
| Puerta sur (`south`) | 1 | Entrada; ratas, goblins y perros. Salida sur al camino real (Robleda) |
| Mercado (`market`) | 2 | Bandidos y ladrones goblin entre los puestos |
| Barrio oeste (`west`) | 3 | Panadería, casa de la tejedora, casa del molinero, capilla. Salida oeste (Huertos) |
| Barrio este (`east`) | 4 | Posada del Jabalí, forja del enano, casa de la alquimista, casa del alcalde. Salida este (Abadía) |
| Plaza mayor (`plaza`) | 5 | Fuente; el Capitán bandido la controla |
| Patio del castillo (`courtyard`) | 9 | Guardia real goblin, magos, jinete de lobo; reja de los calabozos |
| Salón del trono (`castle`) | 10 | El Rey Goblin y la princesa |
| Casa del alcalde (`mayor`) | 7 | Cerrada hasta `valdemar.hilos`; acólitos quemando papeles; la carta |
| Franja norte, junto a la muralla | — | Salida al Paso del Norte (cerrada hasta el epílogo) |

### Fuera del pueblo

| Área (id) | Niveles | Zonas | Qué hay |
|---|---|---|---|
| Huertos del Molino (`valdemar.huertos`), oeste | 5-6 | Trigales quemados, Ribera del Plata, Molino en ruinas | Granjas quemadas, el río Plata, el molino del padre de Tomás con el **Ogro** |
| Bosque de Robleda (`valdemar.robleda`), sur | 6-7 | Robledal, Campamento bandido, Camino real, Guarida del lobo | Puesto del guardabosques (abandonado), campamento bandido, **Lobo alfa** |
| Abadía de Valsombra (`valdemar.abadia`), este | 7-8 | Cementerio de Valsombra, Huerto de los monjes, Claustro en ruinas | Iglesia tapiada, campamento del Eclipse, bajada a la **Cripta** |
| Cripta de la abadía (`valdemar.cripta`, mazmorra) | 8 | — | El **Abad Morcar**; debajo, el **Ascua de Valdemar** |
| Colinas del Pedregal (`valdemar.pedregal`), sureste | 8-9 | Laderas, Pozas heladas, Campamento orco | Tótems, braseros, **Señor de la guerra orco** |
| Calabozos del castillo (`valdemar.calabozos`, mazmorra opcional) | 9 | — | Goblins de élite atrincherados |
| Paso del Norte (`valdemar.paso`), norte | 10 | Paso del Norte | Atalaya derruida, goblins rezagados, cartel «Montes de Rocaforja» |

Escenarios de la arena (mismo pueblo y alrededores): Calle del mercado, Huertos del molino, Plaza de la herrería,
Cementerio de la capilla, Pozo de la bruja, Molino en ruinas, Abadía abandonada, Murallas del castillo, Salón del
trono goblin.

## 4. Personajes

### Valdehierro

| Personaje (id) | Dónde | Notas |
|---|---|---|
| El héroe | — | Humano, enano, elfo u hombre lobo; forastero (salvo el humano, que vuelve a casa). No habla. |
| Princesa Aurora (`princess`) | Salón del trono | Última del linaje guardián de la Hoja del Alba. Entrega la Hoja (I). Desde el cap. 2 lidera la Alianza del Alba y da misiones por carta. |
| Capitán Rodrigo Vela (`capitanGuardia`) | Pie de la escalinata | Capitán de la guardia; sobrevivió escondido. Aparece al liberar el pueblo. Serio, cansado, leal. Da `pedregal`, `rey_goblin`, `calabozos`. |
| Brokk Martillohondo, el herrero (`smithy`) **[AC]** | Forja (barrio este) | Enano gruñón, exiliado de Rocaforja; nacido Brokk Hollín (no lo dice en el cap. 1). Lleva la forja y el ritual. Se presenta en el epílogo y acompaña al héroe al norte. |
| Marta, la panadera (`marta`) | Panadería | Vio la puerta sur abierta sin forzar. Sin misión; pan y chistes. |
| Elena, la tejedora (`elena`) | Su casa | Lista y desconfiada. Tira del hilo de los bandidos hasta el alcalde. Tejió la capa gris de Fausto; Fausto fue padrino de su hija. |
| Tomás, el molinero (`tomas`) | Casa del molinero | La bruja hechizó su espantapájaros. El molino viejo de su padre está en los Huertos (el Ogro). |
| Fray Anselmo (`anselmo`) | Capilla | Enterró al abad Morcar hace un año. Tras la cripta, jura vigilar el Ascua. |
| Bruno, el posadero (`bruno`) | Posada del Jabalí | Campechano; recomienda al herrero; oye los rumores de los arrieros (hachas negras). |
| Iris, la alquimista (`iris`) | Su casa | Sabe que la bruja recibía a un encapuchado gris y que el Capitán sigue vivo. |
| Alcalde Fausto Ledesma | — (huido) | El traidor: abrió la puerta sur por oro y un sitio en la Orden. Es el encapuchado que huye por el Paso. No combate. **[AC]** |

### Enemigos con nombre

| Jefe (id) | Dónde | Papel en la historia |
|---|---|---|
| Rey de las ratas (`ratKing`) | Panadería | Amenaza local |
| Capitán bandido (`banditChief`) | Plaza mayor | Cobra por la plaza (de quien paga a los bandidos) |
| Espantapájaros maldito (`scarecrow`) | Casa del molinero | Hechizado por la bruja |
| Herrero poseído (`possessedSmith`) | Posada | Oye «la voz» que pide fuego |
| Bruja del pozo (`witch`) | Casa de la alquimista | Aliada local del Abad **[AC]** |
| Ogro del molino (`ogre`) | Huertos | Amenaza que el caos ha soltado (`molino`) |
| Lobo alfa (`alphaWolf`) | Robleda | Amenaza local (`caza_mayor`) |
| Abad no-muerto (`abbot`) = **Abad Morcar** | Cripta | **Heraldo del Eclipse** de Valdemar: halló el Ascua hace un año, oyó a Morvath, se dejó morir y volvió. Armó al Rey Goblin a cambio del castillo y de la Hoja. **[AC]** |
| Señor de la guerra orco (`warlord`) | Pedregal | Vende orcos al Rey Goblin; hachas de fuego negro del Clan Hollín |
| Rey Goblin (`goblinKing`) | Salón del trono | Jefe final del capítulo. Bruto y vanidoso: cree que el castillo es su premio; es la herramienta del Eclipse |

Monstruo nuevo: **Acólito del Eclipse** (`eclipseAcolyte`): túnica gris ceniza, luna negra con borde violeta, esferas de
sombra violeta. Es «la Orden de verdad»; los cultistas marrones con antorcha son sus seguidores de a pie.

Cada jefe guarda una pieza única.

## 5. Objetos de leyenda

- **Hoja del Alba**: hoja de mandoble que entrega Aurora; habilidad *Amanecer* (rayos de luz y ondas sagradas).
  El Eclipse la quiere porque es lo único que puede reforzar el sello de la Luna. Se despierta un grado (I → VI) con
  el Ascua de cada continente en el ritual de Brokk.
- **Ascua de Valdemar**: bajo la cripta de la abadía. En el cap. 1 solo se ve su brillo; Fray Anselmo la vigila.
- **Fuego negro / fuego Hollín**: llama que no da luz ni se apaga; lo forjado con él no se mella. Astilla de la forja
  vacía de Morvath. Lo usa el Clan Hollín (cap. 2).
- El **ritual de forja** combina tres piezas y minerales; los elementos despiertan habilidades secretas.

## 6. Facciones (detalle en `mundo.md` §8)

Alianza del Alba (el jugador) · Orden del Eclipse (enemigo en los 6 continentes) · Horda Goblin (enemigo en Valdemar;
después, algún goblin mercader neutral) · Clan Hollín (enanos renegados, cap. 2) · Mala Luna (cap. 3) · Vuelo del Alba (cap. 6).

## 7. Cronología

| Época | Hecho |
|---|---|
| Hace eras | Los Seis Herreros forjan Ardenia y dejan las seis Ascuas. Guerra del Ocaso: Morvath, sellado en la Luna. Se forja la Hoja del Alba. |
| Hace ~300 años | Fundación del reino de Valdemar y de Hondoyunque; primera Alianza del Alba. |
| Hace 20 años | Primeras noches sin luna. El Clan Hollín, expulsado de Hondoyunque; Brokk se instala en Valdehierro. |
| Hace 1 año | Morcar halla el Ascua bajo la abadía y oye a Morvath; «muere» y Fray Anselmo lo entierra. Valsombra queda vacía. |
| Meses antes | Morcar compra al alcalde Fausto, pacta con el Rey Goblin y con el Señor de la guerra; la Bruja del pozo, su aliada. |
| **Comienzo del juego** | Noche sin luna: Fausto deja abierta la puerta sur; los goblins toman Valdehierro. Llega el héroe. |
| Capítulo 1 | Liberación del pueblo, cripta, Pedregal, Rey Goblin, Hoja del Alba (I). Fausto huye al norte. |

## 8. Misterios abiertos (cabos para capítulos siguientes)

- ¿Qué sabe Fausto de la Hoja y a quién se la cuenta en Rocaforja? (El lead de Rocaforja: iba a la Fortaleza Hollín.)
- ¿Por qué Brokk reconoce tan bien el fuego Hollín? (Su deuda: cap. 2.)
- «Quedan cinco brasas»: el Abad sabe que hay seis Ascuas.
- ¿Quién es «Él»? (Morvath; no se nombra hasta más adelante.)
- El nombre definitivo del juego (propuesta: «Hoja del Alba» o «Crónicas del Alba»). **[AC]**

## 9. A confirmar por el usuario [AC]

Se usan como propuesta en todo el guion (`mundo.md`, última sección): el villano final Morvath; el Abad Morcar como
Heraldo con la Bruja de aliada y el alcalde como traidor; el héroe forastero con un motivo por raza; elfos y lobos en
Lunaria; el final y el nombre del mundo (Ardenia). Además, el nombre del enano (Brokk Martillohondo). Qué líneas
cambiarían si se elige otra opción: `valdemar.md` §14.
