# Conceptos de personajes

Fichas de personajes **antes** de implementarlos. Plantilla:

```markdown
## Nombre
- Tipo: enemigo / jefe / aldeano / raza
- Papel en el juego: qué aporta (amenaza nueva, pista, recompensa…)
- Comportamiento: cuerpo a cuerpo / a distancia / embestida (+ ataque especial si lo hay)
- Dónde aparece: zona, interior u oleada
- Aspecto: silueta, colores, accesorios (referencia en art/referencias/ si la hay)
- Números orientativos: vida, daño, velocidad (relativos a otro enemigo existente)
- Recompensa: minerales, pieza única…
- Estado: idea / aprobado / implementado
```

## Continente 1 · Valdemar

Diseño aprobado en `assets/world/continentes/valdemar/bestiario.md` (§1 reparto por áreas, §3 acólito, §4 NPC) e
`historia.md`. Aquí, lo que importa para el aspecto y el estado de cada uno.

### Acólito del Eclipse (`eclipseAcolyte`)
- Tipo: enemigo (monstruo de continente: **no sale en la arena**, que solo usa `Arena.originalEnemyIDs`)
- Papel en el juego: fija la estética base de la **Orden del Eclipse** (luna negra + violeta) que los demás
  continentes variarán; es "la Orden de verdad", frente al cultista (marrón, antorcha).
- Comportamiento: a distancia (`ranged`); lanza una esfera de sombra violeta, lenta, algo más dañina que la del cultista.
- Dónde aparece: casa del alcalde (`mayor.2`, `mayor.4`), abadía: claustro y huerto (`valdemar.abadia.13`/`.15`),
  cripta oleada 2 (×2). Nivel de aparición 7.
- Aspecto: humano (`human`) con túnica larga gris ceniza `#6B6670`, capucha que deja la cara en sombra (solo brillan
  dos ojos violeta `#C9A6FF`), luna negra con borde violeta `#8E5CC2` en el pecho, faja morada, libro oscuro con broche
  violeta y cadena colgado del cinto (rasgo `tomeAtHip`), ataque `.orb` (rasgo `orbCaster`). Esfera violeta en `ProjectileNode`. Implementado con detalle (PA).
- Números orientativos: vida 45 · daño 13 · velocidad 50 · cadencia 2,4 s · alcance 180 · radio 15 · escala 1,05 ·
  botín 0,7 (≈ cultista ×1,5 de vida; los cierra el balance-designer en B1).
- Recompensa: minerales normales (sin pieza).
- Estado: implementado (aspecto básico)

### Capitán Rodrigo Vela (`capitanGuardia`, look `guardCaptain`)
- Tipo: aldeano (da misiones, `questGiver`)
- Papel en el juego: capitán de la guardia que sobrevivió escondido; aparece al liberar el pueblo, organiza el asalto
  al castillo y lo abre al caer el Abad y el Señor de la guerra. Serio, cansado, leal.
- Dónde aparece: pueblo (18,12).
- Aspecto: humano adulto, pelo y barba corta grises, coraza de cobre abollada con tabardo azul de Valdemar, capa raída,
  casco bajo el brazo. Básico hecho: chibi en `NPCLooks` (pelo plateado, coraza de cobre con tinte azul; sin barba ni
  casco) y respaldo en `EnemyArt.spec("npc.guardCaptain")` (coraza, barba, capa). Detalle → pixel-artist (PA).
- Estado: implementado (aspecto básico)

### Carta del alcalde (`cartaAlcalde`, look `letter`) y cartel del camino (`cartelPaso`, look `signpost`)
- Tipo: objetos con los que se habla (rol `clue`), no personajes.
- Aspecto: dibujo fijo en `EnemyArt.objectRows` (sin animación). Carta: pergamino con renglones y lacre negro de luna
  con borde violeta. Cartel: poste de madera con dos tablas en direcciones opuestas (Valdehierro / Rocaforja).
- Estado: implementado (aspecto básico; el pixel-artist puede pulirlos)

### Alcalde Fausto Ledesma (no aparece)
- Tipo: personaje de historia, sin sprite.
- Papel en el juego: el traidor que abrió la puerta sur por oro y promesas del Eclipse; huye antes de que el héroe
  entre en su casa y deja la carta firmada "F.". Es el encapuchado que escapa al norte en el epílogo (gancho a
  Rocaforja). Si un día aparece, con túnica del Eclipse sobre ropa de burgués (no como mini-jefe: descartado).
- Estado: idea (solo se nombra)

### Qué enemigo va en cada área
La tabla completa es `bestiario.md` §1 (fuente de verdad del reparto; los spawns reales están en `Valdemar.swift` y la
ficha generada de cada enemigo en `enemigos.md`). Resumen: Huertos (nivel 5-6: zombis, jabalíes, gólems, ratas de la
peste…), Robleda (6-7: lobos, bandidos, mercenarios, goblins), Abadía (7-8: no-muertos, cultistas, **acólitos**),
Cripta (oleadas, la 2 con acólitos), Pedregal (8-9: orcos, trolls, limos helados, asesinos), Paso (10: élite goblin).

## Ideas pendientes

- Diseño propio para cada jefe (ahora la mayoría son un cuerpo base más grande con otra paleta).
- Aspecto distinto por raza en las armaduras (enano con placas gruesas, elfo con hojas…).
