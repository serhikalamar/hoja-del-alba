// Editor de un mapa "id → cuántos" (minerales de una recompensa, monstruos de una oleada o escolta).

import { useState } from 'react'
import type { CampoEsquema } from '../tipos/datos'
import { validarValor } from '../logica/esquema'
import { fmt, leerNumero } from '../logica/numeros'

interface Props {
  valor: Record<string, number>
  base?: Record<string, number>
  opciones: { id: string; nombre: string }[]
  campo: CampoEsquema
  onCambiar: (nuevo: Record<string, number>) => void
  textoAnadir?: string
}

function Cantidad({ valor, campo, onCambiar, etiqueta }: { valor: number; campo: CampoEsquema; onCambiar: (n: number) => void; etiqueta: string }) {
  const [texto, setTexto] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const aceptar = () => {
    if (texto === null) return
    const n = leerNumero(texto)
    const err = n === null ? 'Escribe un número' : validarValor(campo, n)
    if (err || n === null) { setError(err); return }
    setTexto(null)
    setError(null)
    if (n !== valor) onCambiar(n)
  }
  return (
    <>
      <input
        inputMode="numeric"
        aria-label={etiqueta}
        className={error ? 'mal' : ''}
        value={texto ?? String(valor)}
        title={error ?? `${fmt(campo.min)}–${fmt(campo.max)}`}
        onChange={(e) => { setTexto(e.target.value); setError(null) }}
        onBlur={aceptar}
        onKeyDown={(e) => { if (e.key === 'Enter') aceptar(); if (e.key === 'Escape') { setTexto(null); setError(null) } }}
      />
      {error && <small style={{ color: 'var(--error)' }}>{error}</small>}
    </>
  )
}

export function EditorCuentas({ valor, base, opciones, campo, onCambiar, textoAnadir = 'Añadir' }: Props) {
  const [nuevo, setNuevo] = useState('')
  const nombre = (id: string) => opciones.find((o) => o.id === id)?.nombre ?? id
  const ids = Object.keys(valor)
  const libres = opciones.filter((o) => !(o.id in valor))
  return (
    <div>
      {ids.length === 0 && <p className="tenue peque">Ninguno.</p>}
      {ids.map((id) => {
        const cambiado = base !== undefined && (base[id] ?? 0) !== valor[id]
        return (
          <div key={id} className={`cuenta-fila${cambiado ? ' cambiado' : ''}`}>
            <span title={id}>{nombre(id)}{cambiado && <small className="tenue"> (base {fmt(base?.[id] ?? 0)})</small>}</span>
            <Cantidad valor={valor[id]} campo={campo} etiqueta={`Cantidad de ${nombre(id)}`} onCambiar={(n) => onCambiar({ ...valor, [id]: n })} />
            <button className="plano mini" title="Quitar" aria-label={`Quitar ${nombre(id)}`} onClick={() => {
              const r = { ...valor }
              delete r[id]
              onCambiar(r)
            }}>✕</button>
          </div>
        )
      })}
      {base && Object.keys(base).filter((id) => !(id in valor) && base[id] > 0).length > 0 && (
        <p className="peque" style={{ color: 'var(--sube)', margin: '2px 0 6px' }}>
          Quitados: {Object.keys(base).filter((id) => !(id in valor) && base[id] > 0).map((id) => `${nombre(id)} (${fmt(base[id])})`).join(', ')}
        </p>
      )}
      {libres.length > 0 && (
        <div className="cuenta-fila">
          <select value={nuevo} onChange={(e) => setNuevo(e.target.value)} aria-label={textoAnadir} style={{ flex: '1 1 auto', minWidth: 0 }}>
            <option value="">{textoAnadir}…</option>
            {libres.map((o) => <option key={o.id} value={o.id}>{o.nombre}</option>)}
          </select>
          <button className="mini" disabled={!nuevo} onClick={() => { onCambiar({ ...valor, [nuevo]: 1 }); setNuevo('') }}>+</button>
        </div>
      )}
    </div>
  )
}
