# Umbral · minerales

Responsable: `continent-lead` de `umbral` (color, descripción, dónde salen). Ids, rareza, % y estadística principal
**fijados** por el `world-designer` (`continentes.md`, `progresion.md` §5). Números exactos: `balance-designer`.
**Fase futura.**

Idea de la familia: **lo que cae del cielo y lo que forjaron los Herreros**. El metal estelar y la adamantita son el
material de los muelles y los constructos; la piedra del vacío sale de las grietas; la dragonita, de los nidos; el
mithril es la viruta del propio Yunque. Son los más escasos del juego: el jugador llega aquí con su equipo de Escarcha
y cada mineral de Umbral se nota.

| Rareza | Id | Nombre | % (cuando sale mineral) | Estadística | Bonificación orientativa (×5,6 en planas) | Color (claro · medio · oscuro) | Frase |
|---|---|---|---|---|---|---|---|
| Común A | `starmetal` | Metal estelar | 35 % | ATQ | `Stats(attack: 11)` | `#E8F0FF` · `#9DB4FF` · `#3A4A9A` (chispas `#FFD870`) | "Cayó cuando la Luna se partió. Pesa menos que una pluma y corta como el rayo." |
| Común B | `adamantite` | Adamantita | 27 % | DEF + VIDA | `Stats(maxHP: 30, defense: 7)` | `#A8E0C8` · `#3F7A66` · `#16302A` | "La piedra de los muelles del cielo. Ni el vacío la muerde." |
| Poco común | `voidstone` | Piedra del vacío | 20 % | ROBO DE VIDA | `Stats(lifesteal: 0.025)` | `#C8A8FF` · `#6A3AC0` · `#1A0A30` (núcleo que late) | "Un trozo de nada con forma de piedra. Tiene hambre." |
| Rara | `dragonite` | Dragonita | 12 % | CRÍTICO + MULT. | `Stats(critChance: 0.025, critMultiplier: 0.08)` | `#FFD0A0` · `#E04A2A` · `#6A1A10` (vetas `#FFC040`) | "Escama de dragón hecha piedra por los siglos. Aún quema." |
| Muy rara | `mithril` | Mithril | 6 % | VIDA + ATQ + DEF | **ya existe**: `Stats(maxHP: 12, attack: 2, defense: 2)` → en la historia, ×5,6 (propuesta) | ya existe en `Mineral.swift` | "Viruta del Yunque del Alba. Lo mejor que forjaron los Siete." |

Notas:
- `mithril` **ya existe** (id y bonificación base no cambian; en la arena sigue con su tabla). Con su bonificación
  actual sería **peor** que el metal estelar común: propongo que la forja de la historia aplique el factor del
  continente del mineral (`progresion.md` §5: "las planas crecen con el continente") → VIDA 67, ATQ 11, DEF 11 por
  unidad en Umbral; la arena, sin factor. Lo mismo valdría para el resto de joyas antiguas (diamante, amatista, rubí,
  zafiro). Decisión del `world-designer` + `balance-designer` (ver `historia.md`, propuestas).
- Porcentajes (robo de vida, crítico) apenas suben respecto a Escarcha (2,5 % como la esquirla de luna).
- Iconos (`pixel-artist`): `starmetal` lingote azul acero con chispas doradas; `adamantite` piedra verde negruzca
  facetada; `voidstone` piedra negra con un núcleo violeta que late (2 frames); `dragonite` escama roja con vetas de oro.
- Valor en oro (`value`): por encima de Escarcha; números del `balance-designer` (datos explícitos por mineral,
  `progresion.md` §8).

## Dónde sale más

La tabla de botín es la del continente (M6). Para dar sabor por zona (opcional, si el motor permite pesos por área):

| Dónde | Más probable | Motivo |
|---|---|---|
| Muelles (constructos, gárgolas) | `starmetal`, `adamantite` | Material de los Herreros |
| Nidos (dragones) | `dragonite` | Escamas |
| Islas Rotas y Grieta (vacío) | `voidstone` | Las grietas |
| Observatorio y Puente (Eclipse, herreros huecos) | `adamantite`, `mithril` (un poco más) | Cerca del Yunque |
| Jefes | siempre algo; `dragonMatriarch` → `dragonite`; `voidWarden` → `voidstone`; `starHerald`/`grandHerald` → `mithril` (30 %) | |
| Banda `umbral.yunque` | `mithril` garantizado (3 la 1.ª vez, 1 al repetir) | La joya del final |

- Umbral es el último continente: no hay "adelanto" del siguiente. En su lugar, la banda da mithril garantizado.
- **Adelanto que entra desde Escarcha** (ya lo puso su lead): la Ciudadela suelta `starmetal: 2`, `adamantite: 1`.
- Escasez (`Mineral.dropRateMultiplier` ×0,3) igual que en todo el juego.
