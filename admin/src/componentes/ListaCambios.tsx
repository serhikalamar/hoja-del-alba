// Diff legible, campo a campo, agrupado por apartado.

import { usePanel } from '../estado/panel'
import { enlace } from '../estado/ruta'
import { filaDeRuta } from '../logica/catalogo'
import { agrupar, dentroDeValorEntero, describir, expandir, textoValor, type Cambio } from '../logica/diff'
import { cambioPorcentual, fmtPorcentaje } from '../logica/numeros'

interface Props {
  cambios: Cambio[]
  /** Nombres de las columnas "antes" y "después". */
  antes?: string
  despues?: string
  limite?: number
  /** Ocultar la columna "Base del juego" (cuando "antes" ya son los valores de serie). */
  sinBase?: boolean
}

export function ListaCambios({ cambios, antes = 'Publicada', despues = 'Borrador', limite, sinBase = antes === 'Serie' }: Props) {
  const { datos } = usePanel()
  if (!datos) return null
  const todos = expandir(cambios, datos)
  if (todos.length === 0) return <p className="tenue">Sin cambios.</p>
  const lista = limite ? todos.slice(0, limite) : todos
  const grupos = agrupar(lista.map((c) => describir(datos, c)))
  return (
    <div>
      {grupos.map((g) => (
        <div key={g.apartado} className="diff-grupo">
          <h3>{g.nombre} <small className="tenue">({g.cambios.length})</small></h3>
          <div style={{ overflowX: 'auto' }}>
            <table className="diff">
              <thead>
                <tr><th>Qué</th><th>Campo</th>{!sinBase && <th className="ocultar-movil">Base del juego</th>}<th>{antes}</th><th>{despues}</th><th /></tr>
              </thead>
              <tbody>
                {g.cambios.map((c) => {
                  const interior = dentroDeValorEntero(c.path)
                  const a = c.before ?? (interior ? 0 : c.base ?? null)
                  const d = c.after ?? (interior ? 0 : c.base ?? null)
                  const nulo = (v: typeof c.before) => (v === null ? (interior ? <span className="tenue">—</span> : <span className="tenue">base ({textoValor(c.base, datos)})</span>) : textoValor(v, datos))
                  const pct = typeof a === 'number' && typeof d === 'number' ? cambioPorcentual(a, d) : null
                  return (
                    <tr key={c.path}>
                      <td>
                        {(() => {
                          const destino = filaDeRuta(datos, c.path)
                          return destino ? <a href={enlace('balance', destino[0], destino[1])}>{c.objeto}</a> : c.objeto
                        })()}
                        <div className="ruta">{c.path}</div>
                      </td>
                      <td>{c.campo}</td>
                      {!sinBase && <td className="ocultar-movil tenue">{textoValor(c.base, datos)}</td>}
                      <td className="antes">{nulo(c.before)}</td>
                      <td className="despues">{nulo(c.after)}</td>
                      <td className={pct === null ? '' : pct >= 0 ? 'pct-sube' : 'pct-baja'}>{fmtPorcentaje(pct)}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      ))}
      {limite && todos.length > limite && <p className="tenue">… y {todos.length - limite} cambios más.</p>}
    </div>
  )
}
