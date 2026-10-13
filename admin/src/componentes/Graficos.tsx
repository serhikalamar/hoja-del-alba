// Gráficos sencillos en SVG propio (sin librerías): barras, columnas, barras dobles y líneas.
// Cada uno trae su tabla ("Ver como tabla") y un title por marca para el hover.

import { fmt } from '../logica/numeros'

export interface Dato { etiqueta: string; valor: number; detalle?: string }

function TablaDatos({ columnas, filas }: { columnas: string[]; filas: (string | number)[][] }) {
  return (
    <details className="ver-tabla">
      <summary>Ver como tabla</summary>
      <table className="tabla-simple">
        <thead><tr>{columnas.map((c, i) => <th key={c} className={i > 0 ? 'num' : ''}>{c}</th>)}</tr></thead>
        <tbody>
          {filas.map((f, i) => (
            <tr key={i}>{f.map((x, j) => <td key={j} className={j > 0 ? 'num' : ''}>{typeof x === 'number' ? fmt(x) : x}</td>)}</tr>
          ))}
        </tbody>
      </table>
    </details>
  )
}

/** Barras horizontales: una por categoría, con el valor al final. */
export function Barras({ datos, unidad = '', vacio = 'Sin datos todavía.' }: { datos: Dato[]; unidad?: string; vacio?: string }) {
  if (datos.length === 0) return <p className="tenue">{vacio}</p>
  const ancho = 420
  const izq = 130
  const der = 46
  const fila = 24
  const alto = datos.length * fila + 4
  const max = Math.max(1, ...datos.map((d) => d.valor))
  const escala = (ancho - izq - der) / max
  return (
    <>
      <svg className="grafico" viewBox={`0 0 ${ancho} ${alto}`} role="img" aria-label={datos.map((d) => `${d.etiqueta}: ${d.valor}`).join(', ')}>
        <line className="eje" x1={izq} x2={izq} y1={0} y2={alto} />
        {datos.map((d, i) => {
          const y = i * fila + 4
          const w = Math.max(d.valor > 0 ? 2 : 0, d.valor * escala)
          return (
            <g key={d.etiqueta + i}>
              <text x={izq - 6} y={y + 13} textAnchor="end">{d.etiqueta.length > 20 ? `${d.etiqueta.slice(0, 19)}…` : d.etiqueta}</text>
              <rect className="barra" x={izq + 1} y={y + 2} width={w} height={fila - 8} rx={2}>
                <title>{`${d.etiqueta}: ${fmt(d.valor)}${unidad}${d.detalle ? ` · ${d.detalle}` : ''}`}</title>
              </rect>
              <text className="valor-barra" x={izq + w + 6} y={y + 13}>{fmt(d.valor)}</text>
            </g>
          )
        })}
      </svg>
      <TablaDatos columnas={['', `Valor${unidad}`]} filas={datos.map((d) => [d.etiqueta, d.valor])} />
    </>
  )
}

/** Columnas verticales sobre un eje numérico (p. ej. personajes por nivel). */
export function Columnas({ datos, etiquetaX, etiquetaY, vacio = 'Sin datos todavía.' }: {
  datos: { x: number; y: number }[]; etiquetaX: string; etiquetaY: string; vacio?: string
}) {
  if (datos.length === 0) return <p className="tenue">{vacio}</p>
  const ancho = 420
  const alto = 170
  const izq = 34
  const abajo = 22
  const arriba = 8
  const minX = Math.min(...datos.map((d) => d.x))
  const maxX = Math.max(...datos.map((d) => d.x))
  const n = maxX - minX + 1
  const maxY = Math.max(1, ...datos.map((d) => d.y))
  const paso = (ancho - izq - 4) / n
  const h = alto - abajo - arriba
  const marcasY = [0, Math.round(maxY / 2), maxY].filter((v, i, a) => a.indexOf(v) === i)
  const cadaX = Math.max(1, Math.ceil(n / 12))
  return (
    <>
      <svg className="grafico" viewBox={`0 0 ${ancho} ${alto}`} role="img" aria-label={`${etiquetaY} por ${etiquetaX}`}>
        {marcasY.map((v) => {
          const y = arriba + h - (v / maxY) * h
          return (
            <g key={v}>
              <line className="rejilla-linea" x1={izq} x2={ancho} y1={y} y2={y} />
              <text x={izq - 5} y={y + 4} textAnchor="end">{fmt(v)}</text>
            </g>
          )
        })}
        <line className="eje" x1={izq} x2={ancho} y1={arriba + h} y2={arriba + h} />
        {datos.map((d) => {
          const bh = (d.y / maxY) * h
          const x = izq + (d.x - minX) * paso
          return (
            <rect key={d.x} className="barra" x={x + 1} y={arriba + h - bh} width={Math.max(2, paso - 2)} height={bh} rx={2}>
              <title>{`${etiquetaX} ${d.x}: ${fmt(d.y)} ${etiquetaY.toLowerCase()}`}</title>
            </rect>
          )
        })}
        {Array.from({ length: n }, (_, i) => minX + i).filter((x) => (x - minX) % cadaX === 0).map((x) => (
          <text key={x} x={izq + (x - minX) * paso + paso / 2} y={alto - 6} textAnchor="middle">{x}</text>
        ))}
      </svg>
      <TablaDatos columnas={[etiquetaX, etiquetaY]} filas={datos.map((d) => [String(d.x), d.y])} />
    </>
  )
}

/** Dos barras por categoría (p. ej. misiones aceptadas y hechas), con leyenda. */
export function BarrasDobles({ datos, nombres, vacio = 'Sin datos todavía.' }: {
  datos: { etiqueta: string; a: number; b: number }[]; nombres: [string, string]; vacio?: string
}) {
  if (datos.length === 0) return <p className="tenue">{vacio}</p>
  const ancho = 420
  const izq = 150
  const der = 40
  const fila = 30
  const alto = datos.length * fila + 4
  const max = Math.max(1, ...datos.flatMap((d) => [d.a, d.b]))
  const escala = (ancho - izq - der) / max
  return (
    <>
      <div className="leyenda">
        <span><i style={{ background: 'var(--serie-2)' }} />{nombres[0]}</span>
        <span><i style={{ background: 'var(--serie-1)' }} />{nombres[1]}</span>
      </div>
      <svg className="grafico" viewBox={`0 0 ${ancho} ${alto}`} role="img" aria-label={`${nombres[0]} y ${nombres[1]}`}>
        <line className="eje" x1={izq} x2={izq} y1={0} y2={alto} />
        {datos.map((d, i) => {
          const y = i * fila + 4
          const wa = d.a * escala
          const wb = d.b * escala
          return (
            <g key={d.etiqueta}>
              <text x={izq - 6} y={y + 15} textAnchor="end">{d.etiqueta.length > 23 ? `${d.etiqueta.slice(0, 22)}…` : d.etiqueta}</text>
              <rect className="barra-2" x={izq + 1} y={y + 2} width={Math.max(d.a > 0 ? 2 : 0, wa)} height={11} rx={2}>
                <title>{`${d.etiqueta} · ${nombres[0]}: ${fmt(d.a)}`}</title>
              </rect>
              <rect className="barra" x={izq + 1} y={y + 15} width={Math.max(d.b > 0 ? 2 : 0, wb)} height={11} rx={2}>
                <title>{`${d.etiqueta} · ${nombres[1]}: ${fmt(d.b)}`}</title>
              </rect>
              <text className="valor-barra" x={izq + Math.max(wa, wb) + 6} y={y + 18}>{fmt(d.b)}/{fmt(d.a)}</text>
            </g>
          )
        })}
      </svg>
      <TablaDatos columnas={['', nombres[0], nombres[1]]} filas={datos.map((d) => [d.etiqueta, d.a, d.b])} />
    </>
  )
}

/** Líneas (base discontinua y ajustada continua) sobre el mismo eje. */
export function Lineas({ base, ajustada, etiquetaX, etiquetaY }: {
  base: { x: number; y: number }[]; ajustada: { x: number; y: number }[]; etiquetaX: string; etiquetaY: string
}) {
  const todos = [...base, ...ajustada]
  if (todos.length === 0) return null
  const ancho = 420
  const alto = 170
  const izq = 44
  const abajo = 22
  const arriba = 8
  const minX = Math.min(...todos.map((d) => d.x))
  const maxX = Math.max(...todos.map((d) => d.x))
  const maxY = Math.max(1, ...todos.map((d) => d.y))
  const h = alto - abajo - arriba
  const px = (x: number) => izq + ((x - minX) / Math.max(1, maxX - minX)) * (ancho - izq - 6)
  const py = (y: number) => arriba + h - (y / maxY) * h
  const camino = (ps: { x: number; y: number }[]) => ps.map((p, i) => `${i ? 'L' : 'M'}${px(p.x).toFixed(1)},${py(p.y).toFixed(1)}`).join(' ')
  const distinta = ajustada.some((p, i) => base[i] && Math.abs(base[i].y - p.y) > 1e-9)
  const marcasX = [minX, Math.round((minX + maxX) / 2), maxX]
  return (
    <>
      <div className="leyenda">
        <span><i style={{ background: 'var(--tenue)' }} />Base</span>
        <span><i style={{ background: 'var(--serie-1)' }} />Ajustada{distinta ? '' : ' (igual que la base)'}</span>
      </div>
      <svg className="grafico" viewBox={`0 0 ${ancho} ${alto}`} role="img" aria-label={`${etiquetaY} por ${etiquetaX}`}>
        {[0, maxY / 2, maxY].map((v) => (
          <g key={v}>
            <line className="rejilla-linea" x1={izq} x2={ancho} y1={py(v)} y2={py(v)} />
            <text x={izq - 5} y={py(v) + 4} textAnchor="end">{fmt(Math.round(v))}</text>
          </g>
        ))}
        <line className="eje" x1={izq} x2={ancho} y1={arriba + h} y2={arriba + h} />
        <path className="linea-1" d={camino(base)} />
        <path className="linea-2" d={camino(ajustada)} />
        {ajustada.map((p) => (
          <circle key={p.x} cx={px(p.x)} cy={py(p.y)} r={6} fill="transparent">
            <title>{`${etiquetaX} ${p.x}: ${fmt(p.y)} (base ${fmt(base.find((b) => b.x === p.x)?.y)})`}</title>
          </circle>
        ))}
        {marcasX.map((x) => <text key={x} x={px(x)} y={alto - 6} textAnchor="middle">{x}</text>)}
      </svg>
      <TablaDatos columnas={[etiquetaX, 'Base', 'Ajustada']} filas={ajustada.map((p, i) => [String(p.x), base[i]?.y ?? 0, p.y])} />
    </>
  )
}
