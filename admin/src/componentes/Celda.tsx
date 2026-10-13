// Una celda numérica "base → ajustado": clic para editar, Enter para aceptar, Esc para cancelar, ↺ para volver al base.

import { useState, type KeyboardEvent } from 'react'
import { usePanel } from '../estado/panel'
import type { Celda as DefCelda } from '../logica/catalogo'
import { valorBase, valorEfectivo } from '../logica/documento'
import { avisoAlcance, validarValor } from '../logica/esquema'
import { cambioPorcentual, casiIgual, fmt, fmtPorcentaje, leerNumero } from '../logica/numeros'

export function Celda({ def, etiqueta }: { def: DefCelda | undefined; etiqueta: string }) {
  const { datos, borrador, cambiar, restaurar } = usePanel()
  const [editando, setEditando] = useState(false)
  const [texto, setTexto] = useState('')
  const [error, setError] = useState<string | null>(null)
  if (!def || !datos) return <td className="celda vacia" data-etiqueta={etiqueta}>·</td>

  const base = valorBase(datos, def.ruta)
  const actual = valorEfectivo(borrador.doc, datos, def.ruta)
  const b = typeof base === 'number' ? base : 0
  const v = typeof actual === 'number' ? actual : b
  const cambiada = !casiIgual(v, b)
  const pct = cambiada ? cambioPorcentual(b, v) : null
  const aviso = def.ruta[0] === 'enemies' && def.ruta[2] === 'attackRange' ? avisoAlcance(datos, def.ruta[1], v) : null
  const ayuda = `${def.campo.descripcion}\n${def.ruta.join('.')} · ${def.campo.tipo} ${fmt(def.campo.min)}–${fmt(def.campo.max)} · base ${fmt(b)}${def.campo.codigo ? `\n${def.campo.codigo}` : ''}`

  const empezar = () => {
    setTexto(String(v).replace('.', ','))
    setError(null)
    setEditando(true)
  }
  const aceptar = () => {
    const n = leerNumero(texto)
    if (n === null) { setError('Escribe un número'); return }
    const err = validarValor(def.campo, n)
    if (err) { setError(err); return }
    cambiar(def.ruta, n)
    setEditando(false)
    setError(null)
  }
  const tecla = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') { e.preventDefault(); aceptar() }
    if (e.key === 'Escape') { e.preventDefault(); setEditando(false); setError(null) }
  }

  const clases = ['celda', cambiada ? 'celda-cambiada' : '', def.ausente && !cambiada ? 'celda-ausente' : ''].filter(Boolean).join(' ')
  if (editando) {
    return (
      <td className={clases} data-etiqueta={etiqueta}>
        <input
          autoFocus
          inputMode="decimal"
          className={error ? 'mal' : ''}
          value={texto}
          aria-label={`${etiqueta}: nuevo valor`}
          onChange={(e) => { setTexto(e.target.value); setError(null) }}
          onKeyDown={tecla}
          onBlur={() => { if (!error) aceptar() }}
        />
        {error && <span className="celda-error" role="alert">{error}</span>}
        <span className="celda-base" style={{ textDecoration: 'none' }}>base {fmt(b)} · {fmt(def.campo.min)}–{fmt(def.campo.max)}</span>
      </td>
    )
  }
  return (
    <td className={clases} data-etiqueta={etiqueta}>
      <button className="celda-boton" onClick={empezar} title={ayuda} aria-label={`${etiqueta}: ${fmt(v)}${cambiada ? ` (base ${fmt(b)})` : ''}. Editar`}>
        {cambiada && <span className="celda-base">{fmt(b)}</span>}
        <span className="celda-valor">{def.ausente && !cambiada ? '—' : fmt(v)}</span>
        {cambiada && pct !== null && <span className={`pct ${pct >= 0 ? 'pct-sube' : 'pct-baja'}`}>{fmtPorcentaje(pct)}</span>}
        {cambiada && pct === null && <span className="pct pct-sube">nuevo</span>}
      </button>
      {cambiada && (
        <button className="restaurar" onClick={() => restaurar([def.ruta])} title={`Volver al valor base (${fmt(b)})`} aria-label={`Volver ${etiqueta} al valor base`}>
          ↺ base
        </button>
      )}
      {aviso && <span className="celda-aviso">{aviso}</span>}
    </td>
  )
}
