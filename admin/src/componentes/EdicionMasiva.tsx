// Edición masiva sobre las filas que se ven (con los filtros puestos): "+10 % de vida", "precio × 0,8"…

import { useMemo, useState } from 'react'
import { usePanel } from '../estado/panel'
import type { Fila, Tabla } from '../logica/catalogo'
import { valorEfectivo } from '../logica/documento'
import { aplicarMasivo, describirOperacion, type Operacion } from '../logica/masivo'
import { fmt, leerNumero } from '../logica/numeros'
import { Modal } from './Modal'

type Tipo = Operacion['tipo']

const TIPOS: { id: Tipo; texto: string; ayuda: string }[] = [
  { id: 'porcentaje', texto: '+/− %', ayuda: '10 = +10 %, −20 = −20 %' },
  { id: 'multiplicar', texto: '× multiplicar', ayuda: '0,8 = 80 %' },
  { id: 'sumar', texto: '+ sumar', ayuda: 'negativo para restar' },
  { id: 'fijar', texto: '= fijar', ayuda: 'el mismo valor para todos' },
  { id: 'restaurar', texto: '↺ volver al base', ayuda: 'quita los ajustes de ese campo' },
]

export function EdicionMasiva({ tabla, filas, onCerrar }: { tabla: Tabla; filas: Fila[]; onCerrar: () => void }) {
  const { datos, borrador, reemplazar, notificar } = usePanel()
  const columnas = tabla.columnas.filter((c) => filas.some((f) => f.celdas[c.id] && !f.celdas[c.id]!.ausente))
  const [col, setCol] = useState(columnas[0]?.id ?? '')
  const [tipo, setTipo] = useState<Tipo>('porcentaje')
  const [texto, setTexto] = useState('10')
  const [desde, setDesde] = useState<'actual' | 'base'>('actual')
  const [incluirAusentes, setIncluirAusentes] = useState(false)

  const objetivos = useMemo(() => filas
    .map((f) => ({ f, c: f.celdas[col] }))
    .filter((x) => x.c && (incluirAusentes || !x.c.ausente))
    .map((x) => ({ fila: x.f, ruta: x.c!.ruta, campo: x.c!.campo })), [filas, col, incluirAusentes])

  const n = leerNumero(texto)
  const op: Operacion | null = tipo === 'restaurar' ? { tipo } : n === null ? null : { tipo, valor: n }
  const resultado = useMemo(
    () => (datos && op ? aplicarMasivo(borrador.doc, datos, objetivos, op, desde) : null),
    [datos, borrador.doc, objetivos, tipo, n, desde],
  )
  if (!datos) return null
  const columna = tabla.columnas.find((c) => c.id === col)
  const hayAusentes = filas.some((f) => f.celdas[col]?.ausente)

  const aplicar = () => {
    if (!resultado || !op) return
    reemplazar(resultado.doc)
    notificar(
      `${columna?.etiqueta ?? col} ${describirOperacion(op)}: ${resultado.cambiados} valores cambiados` +
        (resultado.recortados ? `, ${resultado.recortados} recortados al rango` : '') + '. Puedes deshacerlo.',
      'ok',
    )
    onCerrar()
  }

  return (
    <Modal
      titulo="Edición masiva"
      onCerrar={onCerrar}
      pie={
        <>
          <button onClick={onCerrar}>Cancelar</button>
          <button className="primario" disabled={!resultado || objetivos.length === 0} onClick={aplicar}>
            Aplicar a {objetivos.length} {objetivos.length === 1 ? 'fila' : 'filas'}
          </button>
        </>
      }
    >
      <p className="texto-2">
        Se aplica a las <strong>{filas.length}</strong> filas que se ven ahora en «{tabla.titulo}» (con la búsqueda y los filtros puestos).
        Los enteros se redondean y todo se recorta al rango del esquema.
      </p>
      <div className="rejilla" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 12 }}>
        <div className="campo">
          <label htmlFor="m-col">Campo</label>
          <select id="m-col" value={col} onChange={(e) => setCol(e.target.value)}>
            {columnas.map((c) => <option key={c.id} value={c.id}>{c.etiqueta}</option>)}
          </select>
        </div>
        <div className="campo">
          <label htmlFor="m-op">Operación</label>
          <select id="m-op" value={tipo} onChange={(e) => {
            const t = e.target.value as Tipo
            setTipo(t)
            setTexto(t === 'porcentaje' ? '10' : t === 'multiplicar' ? '1' : t === 'sumar' ? '1' : '')
          }}>
            {TIPOS.map((t) => <option key={t.id} value={t.id}>{t.texto}</option>)}
          </select>
        </div>
        {tipo !== 'restaurar' && (
          <div className="campo">
            <label htmlFor="m-val">Valor <span className="tenue">({TIPOS.find((t) => t.id === tipo)?.ayuda})</span></label>
            <input id="m-val" inputMode="decimal" value={texto} onChange={(e) => setTexto(e.target.value)} className={n === null ? 'mal' : ''} />
          </div>
        )}
        {(tipo === 'porcentaje' || tipo === 'multiplicar' || tipo === 'sumar') && (
          <div className="campo">
            <label htmlFor="m-desde">Partiendo de</label>
            <select id="m-desde" value={desde} onChange={(e) => setDesde(e.target.value as 'actual' | 'base')}>
              <option value="actual">el valor ajustado (se acumula)</option>
              <option value="base">el valor base del juego</option>
            </select>
          </div>
        )}
      </div>
      {hayAusentes && (
        <label className="fila-flex" style={{ marginTop: 10 }}>
          <input type="checkbox" checked={incluirAusentes} onChange={(e) => setIncluirAusentes(e.target.checked)} />
          Incluir las filas que no tienen esta estadística (valen 0)
        </label>
      )}
      {columna?.ayuda && <p className="tenue peque" style={{ marginTop: 8 }}>{columna.ayuda}</p>}

      <h3 style={{ marginTop: 16 }}>Vista previa</h3>
      {resultado ? (
        <>
          <p>
            <strong>{resultado.cambiados}</strong> valores cambian
            {resultado.recortados > 0 && <> · <span style={{ color: 'var(--sube)' }}>{resultado.recortados} se recortan al rango</span></>}
          </p>
          <table className="tabla-simple">
            <thead><tr><th>Fila</th><th className="num">Ahora</th><th className="num">Después</th></tr></thead>
            <tbody>
              {objetivos.slice(0, 10).map((o) => (
                <tr key={o.ruta.join('.')}>
                  <td>{o.fila.nombre}</td>
                  <td className="num">{fmt(valorEfectivo(borrador.doc, datos, o.ruta) as number)}</td>
                  <td className="num" style={{ color: 'var(--oro-claro)' }}>{fmt(valorEfectivo(resultado.doc, datos, o.ruta) as number)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {objetivos.length > 10 && <p className="tenue peque">… y {objetivos.length - 10} filas más.</p>}
        </>
      ) : (
        <p className="tenue">Escribe un número válido.</p>
      )}
    </Modal>
  )
}
