// Edición masiva: aplicar una operación a muchos campos a la vez ("+10 % de vida a los monstruos del Pedregal").

import type { CampoEsquema, DatosBase } from '../tipos/datos'
import type { GameTuning, Ruta } from '../tipos/tuning'
import { ponerValor, restaurar, valorBase, valorEfectivo } from './documento'
import { ajustarAlRango } from './esquema'

export type Operacion =
  | { tipo: 'porcentaje'; valor: number } // +10 → ×1,10 ; −20 → ×0,80
  | { tipo: 'multiplicar'; valor: number }
  | { tipo: 'sumar'; valor: number }
  | { tipo: 'fijar'; valor: number }
  | { tipo: 'restaurar' }

export interface Objetivo {
  ruta: Ruta
  campo: CampoEsquema
}

export interface ResultadoMasivo {
  doc: GameTuning
  cambiados: number
  recortados: number
  /** Rutas cuyo valor se recortó al rango (para avisar). */
  rutasRecortadas: string[]
}

/**
 * Aplica la operación a cada objetivo. `desde`: 'actual' parte del valor ajustado (se acumula);
 * 'base' parte del valor base del juego (repetirla da lo mismo).
 * Los enteros se redondean y todo se recorta al rango del esquema.
 */
export function aplicarMasivo(
  doc: GameTuning,
  datos: DatosBase,
  objetivos: Objetivo[],
  op: Operacion,
  desde: 'actual' | 'base' = 'actual',
): ResultadoMasivo {
  let r = doc
  let cambiados = 0
  let recortados = 0
  const rutasRecortadas: string[] = []
  for (const o of objetivos) {
    const antes = valorEfectivo(r, datos, o.ruta)
    if (op.tipo === 'restaurar') {
      const nuevo = restaurar(r, datos, o.ruta)
      if (JSON.stringify(nuevo) !== JSON.stringify(r)) cambiados++
      r = nuevo
      continue
    }
    const origen = desde === 'base' ? valorBase(datos, o.ruta) : antes
    if (typeof origen !== 'number') continue
    let n: number
    switch (op.tipo) {
      case 'porcentaje': n = origen * (1 + op.valor / 100); break
      case 'multiplicar': n = origen * op.valor; break
      case 'sumar': n = origen + op.valor; break
      case 'fijar': n = op.valor; break
    }
    const { valor, recortado } = ajustarAlRango(o.campo, n)
    if (recortado) { recortados++; rutasRecortadas.push(o.ruta.join('.')) }
    if (typeof antes !== 'number' || antes !== valor) cambiados++
    r = ponerValor(r, datos, o.ruta, valor)
  }
  return { doc: r, cambiados, recortados, rutasRecortadas }
}

/** Texto de la operación ("+10 %", "× 0,8"…). */
export function describirOperacion(op: Operacion): string {
  const f = (n: number) => n.toLocaleString('es-ES', { maximumFractionDigits: 4 })
  switch (op.tipo) {
    case 'porcentaje': return `${op.valor >= 0 ? '+' : '−'}${f(Math.abs(op.valor))} %`
    case 'multiplicar': return `× ${f(op.valor)}`
    case 'sumar': return `${op.valor >= 0 ? '+' : '−'} ${f(Math.abs(op.valor))}`
    case 'fijar': return `= ${f(op.valor)}`
    case 'restaurar': return 'volver al valor base'
  }
}
