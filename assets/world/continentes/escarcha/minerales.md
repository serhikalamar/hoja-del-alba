# Escarcha · minerales

Responsable: `continent-lead` de `escarcha` (color, descripción, dónde salen). Ids, rareza, % y estadística
principal **fijados** por el `world-designer` (`continentes.md`, `progresion.md` §5). Números exactos:
`balance-designer`. **Fase futura.**

Idea de la familia: el hielo del norte y los **trozos de la Luna**. Los dos comunes son "de la tierra" (cuarzo y
hierro helado); los tres raros vienen del cielo o de su reflejo (agua del fiordo, esquirlas, zafiro). Cuanto más
cerca de un cráter, más raros.

| Rareza | Id | Nombre | % (cuando sale mineral) | Estadística | Bonificación orientativa (×4,4 en planas) | Color (claro · medio · oscuro) | Frase |
|---|---|---|---|---|---|---|---|
| Común A | `quartz` | Cuarzo | 35 % | ATQ | `Stats(attack: 9)` | `#FFFFFF` · `#E4ECF4` · `#9AA8BC` | "Cristal de roca helada. Afila cualquier filo." |
| Común B | `rimeiron` | Hierro gélido | 27 % | DEF | `Stats(defense: 9)` | `#D8E8F4` · `#7A9AB8` · `#3A4E66` | "Hierro que nunca se calienta. Ni con golpes." |
| Poco común | `aquamarine` | Aguamarina | 20 % | REGEN. | `Stats(regen: 1.8)` | `#C8FFF4` · `#6FD8C8` · `#2A8A84` | "Agua del fiordo hecha piedra. Cura despacio." |
| Rara | `moonshard` | Esquirla de luna | 12 % | ROBO DE VIDA | `Stats(lifesteal: 0.025)` | `#F0FFFF` · `#8FD8F0` · `#A070E0` (núcleo violeta) | "Un trozo de cielo. Bebe el calor de lo que toca." |
| Muy rara | `sapphire` | Zafiro | 6 % | ALCANCE | `Stats(range: 3)` (ya existe; % de las estadísticas apenas sube) | ya existe en `Mineral.swift` | "La joya del norte. Alarga el brazo del que la lleva." |

Notas:
- `sapphire` **ya existe** (id, bonificación y color se mantienen; en la arena sigue con su tabla de siempre).
  En Escarcha solo cambia su probabilidad (6 % dentro de la familia).
- `moonshard`: el dibujo del icono es una esquirla cian alargada con un brillo violeta en el centro (como las
  esquirlas del decorado del Cráter). Es el mineral "de la historia": la misión 4 regala una.
- El robo de vida apenas escala con el continente (es porcentaje): 2-2,5 % por mineral, como la amatista.

## Dónde sale más

La tabla de botín es la del continente (M6). Para dar sabor por zona (opcional, si el motor permite pesos por área):

| Dónde | Más probable | Motivo |
|---|---|---|
| Costa | `rimeiron`, `aquamarine` | Hierro de los pecios, agua del fiordo |
| Tundra | `quartz`, `rimeiron` | Roca y hielo |
| Cráter, Sima del Glaciar | `moonshard`, `sapphire` | Donde caen las esquirlas |
| Gigantes | `quartz`, `sapphire` | Los gigantes guardan zafiros en sus coronas |
| Murallas, Ciudadela | `moonshard`, `aquamarine` | Las armas de la orden llevan esquirlas |
| Jefes | 4 + nivel/2 tiradas, siempre algo; la Reina y el Engendro, con más peso en `moonshard`/`sapphire` | |
| Adelanto (jefa final y mazmorra) | `starmetal`, `adamantite` (Umbral) con poca probabilidad | `progresion.md` §5 |

Escasez: como en todo el juego, los monstruos sueltan con ×0,3 (`Mineral.dropRateMultiplier`).
