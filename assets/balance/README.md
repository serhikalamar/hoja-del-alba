# Balance

Responsable: `balance-designer`. Se mide con `make balance` (bot que persigue enemigos y nunca compra).

## Objetivos de la arena

| Equipo del bot | Objetivo (oleada en la que cae) | Última medición (v0.3) |
|---|---|---|
| Inicial | ~5 (primer jefe) | 5, 5, 5 |
| Arma T2 Normal | ~9 | 9, 9, 8 |
| Arma T3 Fina | ~12 | 12, 13, 12 |
| Arma T4 Fina | ~13-14 | 13, 14, 14 |
| Arma T5 Excelente | ~19 | 19, 19, 19 |
| Arma T6 Excelente | ~22 | 23, 23, 22 |
| Arma T6 Obra maestra | ~25 | 25, 25, 25 |

## Pueblo

Dificultad por zona en `maps/valdehierro.md`. `make check-town` comprueba el flujo, no la dificultad:
para medirla, ampliar el comando `town` del banco de pruebas.

## Historial de cambios

| Fecha | Cambio | Motivo | Resultado |
|---|---|---|---|
| 2026-10-06 | Golpes enemigos con aviso (esquivables) y +dificultad en niveles altos | El aviso hacía el juego más fácil | Curva recuperada |
