# Rocaforja · Historia del capítulo 2 (niveles 10-20)

Responsable: `continent-lead` de `rocaforja`. Estado: **diseño, fase futura** (se implementa después de Valdemar).
Fuentes: `assets/world/mundo.md`, `continentes.md`, `progresion.md`, `brief.md`. Lo marcado *propuesta* está
también en "Propuestas al world-designer" (`encargos.md`).

> Emoción del capítulo: **orgullo y deuda**. El orgullo de un clan que no acepta su exilio y la deuda de un herrero
> que dejó que su hermano cargara con su culpa.

---

## 1. El capítulo en cuatro frases

El enano herrero de Valdehierro, **Brokk**, acompaña al héroe por el Paso del Norte hasta su patria.
En la montaña, el **Clan Hollín** —los enanos exiliados hace 20 años— ha reabierto la **Forja Profunda** con el
**fuego negro** del Eclipse y cava hacia el **Ascua de Rocaforja**, que late bajo Hondoyunque.
Su Thane, **Durgan Hollín**, hermano de Brokk, forja armas para un ejército (las hachas de los orcos del Pedregal
salieron de sus yunques) y, para la **Hermana Brasa**, el Heraldo del Eclipse, un molde para la Hoja del Ocaso.
El héroe se gana la confianza de Hondoyunque, desmonta el poder del Hollín zona a zona, vence a Durgan en la Forja
Profunda y, con el Ascua salvada, Brokk despierta la **Hoja del Alba (II)**.

## 2. Trasfondo

- **Hondoyunque** es la ciudad enana excavada en el corazón de los Montes de Rocaforja hace ~300 años, alrededor de
  la **Gran Forja**, que se alimenta del calor que sube del Ascua. La gobierna un **Thane** elegido por los clanes
  en el **Salón de los Thanes**. Bajo la ciudad, sellada, está la **Cámara del Ascua**, que cuida una guardiana.
- **El fuego negro** (o *fuego hueco*): una llama que no da luz y no se apaga. Lo que se forja con él no se mella y
  obedece a quien lo forjó. Es una astilla de la forja vacía de Morvath: quien lo usa oye sus susurros.
- **Hace 20 años**, los hermanos **Brokk** y **Durgan**, hijos del viejo Thane Hollín, encontraron en la galería más
  honda una **tablilla grabada** con la receta del fuego negro. Brokk, el mejor herrero de su generación, lo encendió
  primero por curiosidad: el hacha que salió de aquel fuego mató a un aprendiz que no la obedeció. Brokk calló y se
  fue. Durgan, orgulloso, siguió forjando con él y defendió el fuego ante los clanes. La **Thane Hilda Piedrafirme**
  expulsó al Clan Hollín entero. Nadie supo que el primer fuego lo encendió Brokk (*esta es la deuda del capítulo*).
- **Brokk** se instaló en Valdehierro bajo el nombre de **Brokk Martillohondo** y juró no volver a forjar un arma
  para un ejército. Por eso es gruñón; por eso forja como nadie.
- **El Clan Hollín** malvivió en los Escoriales, una tierra de escoria al este de las cumbres, hasta que hace un año
  llegó la **Hermana Brasa** con fuego negro "de verdad" (vivo, del Eclipse) y un trato: el Ascua de Rocaforja a
  cambio de devolver al Hollín a Hondoyunque como amos. Durgan aceptó.
- Desde entonces el Hollín ha reabierto la **Forja Profunda** (una forja de los Herreros Primeros, bajo su fortaleza),
  ha sometido a kóbolds y trogloditas con promesas de cobalto, ha despertado gólems con el fuego negro y vende armas
  a los orcos del Pedregal (Valdemar). El encapuchado que Brokk vio subir por el Paso del Norte al final del
  capítulo 1 es **Fausto**, el alcalde traidor de Valdehierro: iba a la Fortaleza Hollín a contarle a la Hermana Brasa
  que la Hoja del Alba ya está en manos del héroe. Brasa lo usa y luego lo deja encadenado en su tienda.

## 3. Personajes con nombre

| Personaje | Id propuesto (NPC) | Dónde | Papel |
|---|---|---|---|
| **Brokk Martillohondo** (nacido Brokk Hollín) | `brokk` (NPC de mapa nuevo, rol `.questGiver`; en Valdemar es `smithy`, que no es NPC) | Viaja con el héroe; Gran Forja de Hondoyunque | Guía del capítulo. Lleva la forja y el ritual. Confiesa su deuda en la Fortaleza. Despierta la Hoja del Alba (II). |
| **Thane Hilda Piedrafirme** | `thaneHilda` | Salón de los Thanes | Señora de Hondoyunque. Dura y justa. Desconfía de Brokk ("un Hollín") y del héroe hasta la prueba. Da las misiones principales junto a Aurora (por carta). |
| **Capitana Runa Escudohondo** | `runaEscudohondo` | Cuartel de la guardia | Jefa de la guardia; misiones de combate contra el Hollín y el Eclipse. Prima lejana de Brokk. |
| **Gorm Barrilhondo** | `gormPosadero` | Posada "El Barril sin Fondo" | Posadero; humor de taberna, rumores, misiones ligeras. Punto de reaparición de la capital. |
| **Frida la Arriera** | `fridaArriera` | Establo de cabras de Hondoyunque | **Maestra de viajes**: lleva en cabra de carga a las capitales visitadas. |
| **Edda, Guardiana del Ascua** | `eddaGuardiana` | Cámara del Ascua (sellada) / Salón | Anciana sacerdotisa de la forja. Sabe lo que es el fuego negro. Encarga apagarlo. |
| **Zigo** | `zigoMercader` | Plaza de Hondoyunque (puesto) | Goblin mercader neutral (guiño a la Horda Goblin). Vende y compra. Huyó del Rey Goblin. |
| **Greta Cabrera** | `gretaCabrera` | Corrales de los Pastos Altos | Pastora. Primera misión del continente. |
| **Capataz Odila Vetazul** | `odilaCapataz` | Cobertizo de las Canteras | Jefa de los canteros; los kóbolds le roban vagonetas. |
| **Viejo Thrain** | `thrainVigia` | Atalaya de las Cumbres | Vigía; vio humo negro en el Nido del Roc. |
| **Hermana Brasa** | `hermanaBrasa` | Escoriales, Fortaleza Hollín | **Heraldo del Eclipse en Rocaforja.** Encapuchada de ceniza con un farol de fuego negro. Nunca pelea: habla, enciende y huye. |
| **Thane Durgan Hollín** | `thaneDurgan` (jefe) | Forja Profunda | **Jefe final.** Hermano de Brokk. No es malvado: es orgulloso y está consumido por el fuego negro, que le arde en el pecho. |
| Mineros cautivos (3) | `mineroCautivo1..3` | Barracón de prisioneros de los Escoriales (interior) | Rescate (como los aldeanos de Valdehierro). Tras liberarlos, abren la brecha de la Fortaleza. |
| **Fausto** (el alcalde traidor de Valdehierro) | `faustoCautivo` (`.clue`) | Tienda de la Hermana Brasa, Fortaleza Hollín | Aparece tras `rocaforja.forja_profunda`, encadenado. Confiesa qué le contó al Eclipse (la Hoja del Alba, el héroe) y que Brasa va "al bosque de la luna". Gancho de Lunaria y cierre del hilo del alcalde. |

## 4. Misiones principales (en orden)

Ids `rocaforja.<nombre>`. Niveles = nivel de la misión. Detalle de recompensas en `zonas.md` §4.

1. **`rocaforja.paso_del_norte`** — *Volver a casa* (10). Brokk y el héroe cruzan los Pastos Altos hasta la Gran Puerta.
   La guardia deja pasar al héroe, pero no a "un Hollín". Brokk se queda fuera, en los corrales de Greta.
2. **`rocaforja.prueba_del_thane`** — *La prueba* (13). La Thane Hilda: "Los kóbolds roban mi cobalto. Tráeme la
   mecha de su jefe y hablaremos". Vencer al **Jefe Mechacorta** en las Canteras. Las vagonetas robadas llevan la
   marca del Hollín. Hilda abre la Gran Forja a Brokk ("solo para forjar, no para quedarte").
3. **`rocaforja.humo_en_las_cumbres`** — *El nido negro* (16). Thrain vio humo sin luz sobre el Nido del Roc. En la
   cima, el Roc tiene una brasa de fuego negro clavada en el ala. Al vencerlo, el héroe encuentra un farol apagado con
   el sello del Eclipse: primera huella de la Hermana Brasa.
4. **`rocaforja.minas_profundas`** — *Lo que excavan* (17, mazmorra `mine`). Las Minas profundas bajo las Canteras: el
   Hollín ha despertado al **Coloso de cobalto** para abrir túneles hacia el Ascua. Al vencerlo, el héroe recupera
   los **planos de los túneles Hollín**: van directos a la Cámara del Ascua, bajo Hondoyunque.
5. **`rocaforja.crisoles_negros`** — *Apagar el fuego* (17-18). Edda enseña a apagar el fuego negro con agua del
   Ascua. Apagar los **3 crisoles** de los Escoriales y liberar a los **3 mineros cautivos**. La Hermana Brasa aparece
   un momento en el último crisol, se ríe y desaparece en el humo.
6. **`rocaforja.asalto_a_la_fortaleza`** — *La deuda* (19). Asalto con la guardia de Runa. Los mineros abren la
   brecha y la Puerta Hollín cede; hay que barrer el patio (12 guerreros). En el patio, Durgan habla desde la muralla y cuenta la
   verdad a medias: "Pregúntale a mi hermano quién encendió el primer fuego". **Brokk confiesa** ante Hilda y Runa.
7. **`rocaforja.forja_profunda`** — *Hermano contra hermano* (20, banda en el piso `forge`). Oleadas del Hollín y
   **Thane Durgan Hollín**. Al caer, el fuego negro de su pecho se apaga. Detrás, la Hermana Brasa saca del gran crisol
   el **Molde del Ocaso** (el molde de la hoja de Morvath) y huye por las galerías Hollín, que salen al **Túnel de los Thanes** por detrás del rastrillo sellado, hacia el este.
8. **`rocaforja.despertar`** — *La Hoja del Alba (II)* (20). Edda abre la Cámara del Ascua: está a salvo. Brokk forja
   con el héroe en la Gran Forja (ritual) y despierta la **Hoja del Alba (II)**. Hilda abre el Túnel de los Thanes y
   devuelve a Brokk su nombre ("Brokk Hollín, herrero de Hondoyunque"). Carta de Aurora: la Alianza sigue a la Hermana
   Brasa hacia Lunaria.

## 5. El final del continente

- **Durgan no muere**: vencido y libre del fuego negro, se rinde. Hilda lo encierra en el Salón de los Thanes
  (puede reaparecer en capítulos posteriores como forjador arrepentido: *propuesta*).
- **Brokk paga su deuda**: confiesa, se queda a reconstruir la Gran Forja… y vuelve a viajar con el héroe (sigue
  siendo quien despierta la Hoja en cada capital).
- **El Eclipse gana algo**: la Hermana Brasa se lleva el **Molde del Ocaso** hacia Lunaria (gancho del capítulo 3).
- **Fausto**, abandonado en la tienda de Brasa, confiesa y lo mandan preso a Valdehierro (misión `rocaforja.fausto`).
  El Ascua de Rocaforja queda a salvo.
- **Se abre**: el Túnel de los Thanes (→ Lunaria), la forja de tier 3 en Hondoyunque, y Frida añade Hondoyunque a los
  viajes.

## 6. Si el héroe es enano

Su capítulo-patria. Líneas propias (una por momento clave, frases cortas):
- Gran Puerta (guardia): "¿Un enano de fuera? … Bienvenido a casa, primo. Tu amigo el Hollín se queda fuera."
- Hilda, al conocerlo: "Tienes la barba de los Piedrafirme. Demuéstrame que tienes también su palabra."
- Brokk, en los Pastos: "Mira bien estas montañas. Yo tardé veinte años en volver a verlas."
- Durgan, en la Forja Profunda: "¡Tú también nos echaste, enano! Todos lo hicisteis."
- Hilda, al final: "Hondoyunque te debe una Ascua. Tu nombre irá en el Salón."

Otras razas, una línea al llegar: **humano** ("Ni un árbol. ¿Cómo viven aquí?"), **elfo** ("La piedra no canta… pero
recuerda"), **hombre lobo** ("Huele a hierro y a cabra. Y a ceniza").

## 7. Conexión con la historia principal

| Hilo | En Rocaforja |
|---|---|
| Orden del Eclipse | Heraldo: **Hermana Brasa**. Acólitos locales: `emberAcolyte` (Acólito de la brasa). |
| Poder corrompido (jefe final) | **Thane Durgan Hollín** y el Clan Hollín. |
| Valdemar | Las hachas de fuego Hollín del Pedregal (`valdemar.paso_norte`) y Fausto, el alcalde huido por el Paso, llevan a la Fortaleza Hollín. |
| Hoja del Alba | Se despierta a la **(II)** con el Ascua de Rocaforja (forja de Hondoyunque, con Brokk). |
| Lunaria | La Hermana Brasa huye por el Túnel de los Thanes con el Molde del Ocaso hacia Ysolde. |
| Morvath | El fuego negro y la tablilla de los Hollín son sus susurros; Durgan lo oyó en sueños ("una forja vacía en la luna"). |
