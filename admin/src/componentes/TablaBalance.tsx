// Tabla genérica de balance: búsqueda, filtros, "solo cambiados", celdas base → ajustado, detalle por fila,
// restaurar fila y edición masiva. En el móvil cada fila se ve como una tarjeta.

import { Fragment, useEffect, useMemo, useState, type ReactNode } from 'react'
import { usePanel } from '../estado/panel'
import { filtrarFilas, rutasDeFila, type Fila, type Tabla } from '../logica/catalogo'
import { estaAjustado } from '../logica/documento'
import { Celda } from './Celda'
import { EdicionMasiva } from './EdicionMasiva'

interface Memoria { busqueda: string; filtros: Record<string, string>; soloCambiados: boolean }
const memoria = new Map<string, Memoria>()

interface Props {
  tabla: Tabla
  detalle?: (fila: Fila) => ReactNode
  /** Texto del botón para abrir el detalle. */
  textoDetalle?: string
  /** Fila a abrir y enseñar (de la ruta #/balance/<pestaña>/<fila>). */
  abrir?: string
}

export function TablaBalance({ tabla, detalle, textoDetalle = 'Detalle', abrir }: Props) {
  const { datos, borrador, restaurar } = usePanel()
  const inicial = memoria.get(tabla.id) ?? { busqueda: '', filtros: {}, soloCambiados: false }
  const [busqueda, setBusquedaS] = useState(inicial.busqueda)
  const [filtros, setFiltrosS] = useState<Record<string, string>>(inicial.filtros)
  const [soloCambiados, setSoloCambiadosS] = useState(inicial.soloCambiados)
  const [abiertas, setAbiertas] = useState<Set<string>>(() => new Set(abrir ? [abrir] : []))

  // Abrir y enseñar la fila pedida en la ruta (p. ej. desde la lista de cambios).
  useEffect(() => {
    if (!abrir || !tabla.filas.some((f) => f.id === abrir)) return
    setAbiertas((s) => new Set([...s, abrir]))
    const t = window.setTimeout(() => document.getElementById(`fila-${tabla.id}-${abrir}`)?.scrollIntoView({ block: 'center' }), 50)
    return () => window.clearTimeout(t)
  }, [abrir, tabla])
  const [masiva, setMasiva] = useState(false)
  const [verFiltros, setVerFiltros] = useState(false)

  const recordar = (m: Partial<Memoria>) => memoria.set(tabla.id, { busqueda, filtros, soloCambiados, ...m })
  const setBusqueda = (v: string) => { setBusquedaS(v); recordar({ busqueda: v }) }
  const setFiltro = (id: string, v: string) => { const f = { ...filtros, [id]: v }; setFiltrosS(f); recordar({ filtros: f }) }
  const setSoloCambiados = (v: boolean) => { setSoloCambiadosS(v); recordar({ soloCambiados: v }) }

  const cambiadas = useMemo(() => {
    const s = new Set<string>()
    if (!datos) return s
    for (const f of tabla.filas) if (rutasDeFila(f).some((r) => estaAjustado(borrador.doc, datos, r))) s.add(f.id)
    return s
  }, [tabla, datos, borrador.doc])

  const filas = useMemo(() => {
    const r = filtrarFilas(tabla.filas, busqueda, filtros)
    const visibles = soloCambiados ? r.filter((f) => cambiadas.has(f.id)) : r
    const pedida = abrir ? tabla.filas.find((f) => f.id === abrir) : undefined
    return pedida && !visibles.includes(pedida) ? [pedida, ...visibles] : visibles
  }, [tabla, busqueda, filtros, soloCambiados, cambiadas, abrir])

  const columnas = tabla.columnas.filter((c) => filas.some((f) => f.celdas[c.id]))
  const hayFiltros = busqueda !== '' || Object.values(filtros).some(Boolean) || soloCambiados
  const conmutar = (id: string) => setAbiertas((s) => {
    const n = new Set(s)
    if (n.has(id)) n.delete(id)
    else n.add(id)
    return n
  })

  return (
    <section className="panel" aria-labelledby={`t-${tabla.id}`}>
      <div className="fila-flex entre">
        <h2 id={`t-${tabla.id}`} style={{ margin: 0 }}>{tabla.titulo}</h2>
        <span className="tenue peque">
          {filas.length} de {tabla.filas.length} · {cambiadas.size} con cambios
        </span>
      </div>
      {tabla.descripcion && <p className="texto-2 peque" style={{ marginTop: 6 }}>{tabla.descripcion}</p>}

      <div className="filtros" role="search">
        {tabla.filas.length > 6 && (
          <div className="campo buscar">
            <label htmlFor={`b-${tabla.id}`}>Buscar</label>
            <input id={`b-${tabla.id}`} type="search" placeholder="Nombre, id, zona…" value={busqueda} onChange={(e) => setBusqueda(e.target.value)} />
          </div>
        )}
        {tabla.filtros.length > 0 && (
          <button className="solo-movil" aria-expanded={verFiltros} onClick={() => setVerFiltros((v) => !v)}>
            {verFiltros ? '▾' : '▸'} Filtros{Object.values(filtros).filter(Boolean).length > 0 && ` (${Object.values(filtros).filter(Boolean).length})`}
          </button>
        )}
        <div className={`filtros-extra${verFiltros ? '' : ' cerrado'}`}>
          {tabla.filtros.map((f) => (
            <div className="campo" key={f.id}>
              <label htmlFor={`f-${tabla.id}-${f.id}`}>{f.etiqueta}</label>
              <select id={`f-${tabla.id}-${f.id}`} value={filtros[f.id] ?? ''} onChange={(e) => setFiltro(f.id, e.target.value)}>
                <option value="">Todos</option>
                {f.opciones.map((o) => <option key={o.valor} value={o.valor}>{o.etiqueta}</option>)}
              </select>
            </div>
          ))}
          <label className="fila-flex" style={{ paddingBottom: 6 }}>
            <input type="checkbox" checked={soloCambiados} onChange={(e) => setSoloCambiados(e.target.checked)} />
            Solo cambiados
          </label>
        </div>
        {hayFiltros && (
          <button className="plano" onClick={() => { setBusquedaS(''); setFiltrosS({}); setSoloCambiadosS(false); memoria.delete(tabla.id) }}>
            Quitar filtros
          </button>
        )}
        {columnas.length > 0 && (
          <button onClick={() => setMasiva(true)} disabled={filas.length === 0} title="Aplicar una operación a todas las filas que se ven">
            ⚒ Edición masiva
          </button>
        )}
      </div>

      {filas.length === 0 ? (
        <p className="tenue">Nada coincide con la búsqueda y los filtros.</p>
      ) : (
        <div className="tabla-envoltorio">
          <table className="tabla tarjetas">
            <thead>
              <tr>
                <th className="col-nombre">Nombre</th>
                {columnas.map((c) => <th key={c.id} className="num" title={c.ayuda}>{c.etiqueta}</th>)}
              </tr>
            </thead>
            <tbody>
              {filas.map((f) => {
                const cambiada = cambiadas.has(f.id)
                const abierta = abiertas.has(f.id)
                return (
                  <Fragment key={f.id}>
                    <tr id={`fila-${tabla.id}-${f.id}`} className={`fila${cambiada ? ' fila-cambiada' : ''}${f.id === abrir ? ' fila-pedida' : ''}`}>
                      <td className="col-nombre">
                        <div className="nombre-fila">{f.nombre}</div>
                        {f.sub && <div className="sub-fila">{f.sub}</div>}
                        {f.etiquetas && f.etiquetas.length > 0 && (
                          <div style={{ marginTop: 3 }}>
                            {f.etiquetas.map((e) => <span key={e} className={`chip${e === 'jefe' ? ' chip-jefe' : ''}`}>{e}</span>)}
                          </div>
                        )}
                        <div className="acciones-fila">
                          {detalle && (
                            <button className="plano mini" aria-expanded={abierta} onClick={() => conmutar(f.id)}>
                              {abierta ? '▾' : '▸'} {textoDetalle}
                            </button>
                          )}
                          {cambiada && (
                            <button className="plano mini" onClick={() => restaurar(rutasDeFila(f))} title="Volver toda la fila a los valores base">
                              ↺ Restaurar fila
                            </button>
                          )}
                        </div>
                      </td>
                      {columnas.map((c) => <Celda key={c.id} def={f.celdas[c.id]} etiqueta={c.etiqueta} />)}
                    </tr>
                    {detalle && abierta && (
                      <tr className="fila-detalle">
                        <td className="detalle" colSpan={columnas.length + 1}>{detalle(f)}</td>
                      </tr>
                    )}
                  </Fragment>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
      {masiva && <EdicionMasiva tabla={tabla} filas={filas} onCerrar={() => setMasiva(false)} />}
    </section>
  )
}
