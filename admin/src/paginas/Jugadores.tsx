// Jugadores: lista paginada con búsqueda (admin_characters) y ficha de solo lectura (admin_character).

import { useEffect, useState } from 'react'
import { ErrorPanel, type FichaPersonaje, type FilaPersonaje } from '../api'
import { usePanel } from '../estado/panel'
import { enlace, navegar } from '../estado/ruta'
import { NOMBRES_RAZA } from '../logica/catalogo'
import { indices } from '../logica/documento'
import { fmt } from '../logica/numeros'
import { fecha } from './Resumen'

const TAMANO = 25

function useAcceso(): string | null {
  const { modo, sesion, esAdmin } = usePanel()
  if (modo === 'supabase' && !sesion) return 'Entra con tu usuario de admin para ver a los jugadores.'
  if (modo === 'supabase' && !esAdmin) return 'Solo los admins ven a los jugadores (tabla admins; ver backend/README.md).'
  return null
}

export function Jugadores({ id }: { id?: string }) {
  const sinAcceso = useAcceso()
  if (sinAcceso) return <div className="banda banda-info"><div className="crece">{sinAcceso} {sinAcceso.startsWith('Entra') && <a href={enlace('entrar')}>Entrar</a>}</div></div>
  return id ? <Ficha id={id} /> : <Lista />
}

function Lista() {
  const { api, datos, modo } = usePanel()
  const [busqueda, setBusqueda] = useState('')
  const [aplicada, setAplicada] = useState('')
  const [pagina, setPagina] = useState(0)
  const [filas, setFilas] = useState<FilaPersonaje[] | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const t = window.setTimeout(() => { setAplicada(busqueda); setPagina(0) }, 350)
    return () => window.clearTimeout(t)
  }, [busqueda])

  useEffect(() => {
    let vivo = true
    setError(null)
    api.personajes(aplicada, pagina, TAMANO)
      .then((r) => { if (vivo) setFilas(r) })
      .catch((e: unknown) => { if (vivo) setError(e instanceof ErrorPanel ? e.message : String(e)) })
    return () => { vivo = false }
  }, [api, aplicada, pagina])

  const nombreArea = (a: string) => (datos ? indices(datos).areas.get(a)?.nombre ?? a : a)
  return (
    <>
      <div className="fila-flex entre" style={{ marginBottom: 12 }}>
        <h1 style={{ margin: 0 }}>Jugadores {modo === 'demo' && <span className="chip chip-oro">datos inventados</span>}</h1>
        <span className="tenue peque">Solo lectura · sin correos ni contraseñas</span>
      </div>
      <div className="filtros">
        <div className="campo buscar">
          <label htmlFor="b-jug">Buscar por personaje o usuario</label>
          <input id="b-jug" type="search" value={busqueda} onChange={(e) => setBusqueda(e.target.value)} placeholder="pepe…" />
        </div>
      </div>
      {error && <div className="banda banda-error"><div className="crece">{error}</div></div>}
      {!filas && !error && <div className="cargando">Cargando…</div>}
      {filas && (
        <div className="panel" style={{ padding: 0, overflowX: 'auto' }}>
          <table className="tabla-simple">
            <thead>
              <tr>
                <th>Personaje</th><th>Usuario</th><th>Raza</th><th className="num">Nivel</th><th className="num">Oro</th>
                <th className="num">Arena</th><th className="num">Misiones</th><th className="ocultar-movil">Área</th><th className="ocultar-movil">Actualizado</th>
              </tr>
            </thead>
            <tbody>
              {filas.length === 0 && <tr><td colSpan={9} className="tenue">Nadie coincide.</td></tr>}
              {filas.map((p) => (
                <tr key={p.id} className="clic" tabIndex={0} onClick={() => navegar('jugadores', p.id)} onKeyDown={(e) => { if (e.key === 'Enter') navegar('jugadores', p.id) }}>
                  <td><a href={enlace('jugadores', p.id)} onClick={(e) => e.stopPropagation()}>{p.name}</a></td>
                  <td className="tenue">{p.username ?? '—'}</td>
                  <td>{NOMBRES_RAZA[p.race] ?? p.race}</td>
                  <td className="num">{p.level}</td>
                  <td className="num">{fmt(p.gold)}</td>
                  <td className="num">{p.arena_best_wave ?? '—'}</td>
                  <td className="num">{p.quests_done}</td>
                  <td className="ocultar-movil">{nombreArea(p.area)}</td>
                  <td className="ocultar-movil tenue">{fecha(p.updated_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <div className="fila-flex" style={{ justifyContent: 'center', marginTop: 8 }}>
        <button disabled={pagina === 0} onClick={() => setPagina((p) => p - 1)}>← Anterior</button>
        <span className="tenue">Página {pagina + 1}</span>
        <button disabled={!filas || filas.length < TAMANO} onClick={() => setPagina((p) => p + 1)}>Siguiente →</button>
      </div>
    </>
  )
}

/** Un diccionario de Swift con claves enum puede venir como objeto o como lista [clave, valor, clave, valor…]. */
function comoMapa(x: unknown): Record<string, unknown> {
  if (Array.isArray(x)) {
    const r: Record<string, unknown> = {}
    for (let i = 0; i + 1 < x.length; i += 2) r[String(x[i])] = x[i + 1]
    return r
  }
  return x && typeof x === 'object' ? (x as Record<string, unknown>) : {}
}
const lista = (x: unknown): unknown[] => (Array.isArray(x) ? x : [])

function Ficha({ id }: { id: string }) {
  const { api, datos } = usePanel()
  const [f, setF] = useState<FichaPersonaje | null | undefined>(undefined)
  const [error, setError] = useState<string | null>(null)
  useEffect(() => {
    api.personaje(id).then(setF).catch((e: unknown) => setError(e instanceof ErrorPanel ? e.message : String(e)))
  }, [api, id])
  if (!datos) return null
  const ix = indices(datos)
  if (error) return <div className="banda banda-error"><div className="crece">{error}</div></div>
  if (f === undefined) return <div className="cargando">Cargando…</div>
  if (f === null) return <div className="banda banda-info"><div className="crece">Ese personaje ya no existe. <a href={enlace('jugadores')}>Volver</a></div></div>
  const d = f.data
  const minerales = Object.entries(comoMapa(d.minerals)).filter(([, n]) => typeof n === 'number' && n > 0)
  const misiones = Object.entries(comoMapa(d.quests))
  const town = comoMapa(d.townProgress)
  const rescatados = lista(town.rescued).map(String)
  const inventario = lista(d.inventory)
  return (
    <>
      <p><a href={enlace('jugadores')}>← Jugadores</a></p>
      <h1>{f.name} <small className="tenue">({f.username ?? 'sin usuario'})</small></h1>
      <div className="rejilla-2 ficha">
        <section className="panel">
          <h2>Personaje</h2>
          <dl>
            <dt>Raza</dt><dd>{NOMBRES_RAZA[String(d.race)] ?? String(d.race ?? '—')}</dd>
            <dt>Nivel</dt><dd>{String(d.level ?? 1)} <span className="tenue">({fmt(Number(d.xp ?? 0))} XP)</span></dd>
            <dt>Oro</dt><dd>{fmt(Number(d.gold ?? 0))}</dd>
            <dt>Mejor oleada de la arena</dt><dd>{d.arenaBestWave === null || d.arenaBestWave === undefined ? '—' : String(d.arenaBestWave)}</dd>
            <dt>Dónde está</dt><dd>{ix.areas.get(String(d.currentAreaID ?? 'town'))?.nombre ?? String(d.currentAreaID ?? 'town')}</dd>
            <dt>Objetos</dt><dd>{inventario.length}</dd>
            <dt>Versión de la fila</dt><dd>{f.version} · creado {fecha(f.created_at)} · guardado {fecha(f.updated_at)}</dd>
            <dt>id</dt><dd><code>{f.id}</code></dd>
          </dl>
        </section>
        <section className="panel">
          <h2>Minerales</h2>
          {minerales.length === 0 ? <p className="tenue">Ninguno.</p> : (
            <p>{minerales.map(([k, n]) => `${ix.minerales.get(k)?.nombre ?? k} ${fmt(n as number)}`).join(' · ')}</p>
          )}
          <h2>Historia</h2>
          <dl>
            <dt>Aldeanos rescatados</dt><dd>{rescatados.length ? rescatados.map((r) => ix.rescates.get(r)?.nombre ?? r).join(', ') : '—'}</dd>
            <dt>Princesa</dt><dd>{town.princessRescued ? 'rescatada' : 'no'}</dd>
            <dt>Mazmorras superadas</dt><dd>{lista(d.wonDungeons).map((m) => ix.mazmorras.get(String(m))?.nombre ?? String(m)).join(', ') || '—'}</dd>
            <dt>Jefes derrotados</dt><dd>{lista(d.defeatedBosses).map((m) => ix.enemigos.get(String(m))?.nombre ?? String(m)).join(', ') || '—'}</dd>
          </dl>
        </section>
        <section className="panel">
          <h2>Misiones</h2>
          {misiones.length === 0 ? <p className="tenue">Ninguna.</p> : (
            <table className="tabla-simple">
              <thead><tr><th>Misión</th><th>Estado</th></tr></thead>
              <tbody>
                {misiones.map(([k, v]) => {
                  const e = comoMapa(v)
                  return <tr key={k}><td>{ix.misiones.get(k)?.titulo ?? k}</td><td>{e.done ? '✓ hecha' : e.accepted ? 'aceptada' : '—'}</td></tr>
                })}
              </tbody>
            </table>
          )}
        </section>
        <section className="panel">
          <h2>Datos completos</h2>
          <p className="tenue peque">El PlayerProfile tal cual está guardado (solo lectura).</p>
          <details>
            <summary>Ver JSON</summary>
            <pre className="json">{JSON.stringify(d, null, 2)}</pre>
          </details>
        </section>
      </div>
    </>
  )
}
