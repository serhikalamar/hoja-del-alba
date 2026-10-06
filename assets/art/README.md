# Guía de estilo de pixel-art

Responsable: `pixel-artist`. Referencias del usuario en `referencias/`:
`caballero-chibi.png` (estilo de personaje) y `pueblo-castillo.webp` (estilo de mundo).

## Reglas

- Chibi tipo JRPG de 16 bits: cabeza grande, ojos grandes con brillo, vista 3/4.
- Mucho detalle: al menos tres tonos por material (claro, medio, oscuro) y brillos blancos puntuales.
  Luz desde arriba a la izquierda.
- Contorno exterior oscuro `#1A1C2C` (automático con `.outlined()`); detalles interiores dibujados a mano.
- **Un único tamaño de pixel** para todo el mundo (`PX` = 2 puntos): personajes, armas, enemigos y escenario.
- Casillas de 24×24 pixeles en el pueblo; héroe de 34×40; enemigos de ~16-22 pixeles de alto.
- Paleta base Sweetie 16 (`Pal` en `Sprites.swift`), ampliable con tonos por material.
- Cada raza y cada jefe deben distinguirse por la silueta, no solo por el color.

## Cómo se hace

Todo el arte se dibuja en código (`src/GameTest1/Art/`): sprites como filas de caracteres + paleta,
compuestos por capas. Para verlo: `make sprites`, `make maps`, `make shots` → `tools/Harness/output/`.
