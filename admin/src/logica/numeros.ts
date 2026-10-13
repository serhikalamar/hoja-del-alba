// Números: leer lo que escribe el usuario (coma o punto) y mostrarlos en formato español.

const formato = new Intl.NumberFormat('es-ES', { maximumFractionDigits: 4 })
const formatoCorto = new Intl.NumberFormat('es-ES', { maximumFractionDigits: 2 })

/** "1,5" → 1.5; "1.234,5" → 1234.5; "" o texto → null. */
export function leerNumero(texto: string): number | null {
  let t = texto.trim().replace(/\s/g, '').replace(/[×x%]$/i, '')
  if (t === '' || t === '-' || t === '+') return null
  if (t.includes(',') && t.includes('.')) {
    // El último separador es el decimal.
    if (t.lastIndexOf(',') > t.lastIndexOf('.')) t = t.replace(/\./g, '').replace(',', '.')
    else t = t.replace(/,/g, '')
  } else {
    t = t.replace(',', '.')
  }
  if (!/^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$/i.test(t)) return null
  const n = Number(t)
  return Number.isFinite(n) ? n : null
}

export function fmt(n: number | null | undefined): string {
  if (n === null || n === undefined || !Number.isFinite(n)) return '—'
  return formato.format(n)
}

export function fmtCorto(n: number | null | undefined): string {
  if (n === null || n === undefined || !Number.isFinite(n)) return '—'
  return formatoCorto.format(n)
}

/** Cambio en % de base a nuevo (null si la base es 0). */
export function cambioPorcentual(base: number, nuevo: number): number | null {
  if (base === 0) return null
  return ((nuevo - base) / Math.abs(base)) * 100
}

export function fmtPorcentaje(p: number | null): string {
  if (p === null) return ''
  const r = Math.round(p * 10) / 10
  if (r === 0) return '±0 %'
  return `${r > 0 ? '+' : '−'}${formatoCorto.format(Math.abs(r))} %`
}

/** Redondea para quitar el ruido de coma flotante (0.1 * 3 → 0.3). */
export function limpio(n: number): number {
  return Math.round(n * 1e6) / 1e6
}

export function casiIgual(a: number, b: number): boolean {
  return Math.abs(a - b) <= 1e-9 * Math.max(1, Math.abs(a), Math.abs(b))
}
