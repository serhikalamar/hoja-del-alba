// Pantalla de Balance: pestañas con las tablas y los detalles propios de cada una.

import { useMemo, type ReactNode } from 'react'
import { Lineas } from '../componentes/Graficos'
import { EditorCuentas } from '../componentes/EditorCuentas'
import { TablaBalance } from '../componentes/TablaBalance'
import { usePanel } from '../estado/panel'
import { enlace } from '../estado/ruta'
import { PESTANAS, tablasDe, type Fila, type IdPestana } from '../logica/catalogo'
import { contarAjustes, indices, valorBase, valorEfectivo } from '../logica/documento'
import { avisosMisionesSpawns, CAMPO_CUENTA_MINERAL, CAMPO_CUENTA_MONSTRUO, monstruosParaSpawn, OLEADAS_MAX, OLEADAS_MIN, spawnEfectivo } from '../logica/esquema'
import { fmt } from '../logica/numeros'
import type { Cuentas, GameTuning } from '../tipos/tuning'

const APARTADOS_PESTANA: Record<IdPestana, (keyof GameTuning)[]> = {
  enemigos: ['enemies'],
  piezas: ['parts'],
  armadura: ['armor'],
  minerales: ['minerals'],
  zonas: ['areas', 'zones', 'spawns'],
  mazmorras: ['dungeons'],
  misiones: ['quests', 'rescues'],
  economia: ['economy', 'roulette'],
}

export function cambiosEnPestana(doc: GameTuning, p: IdPestana): number {
  const parcial: GameTuning = {}
  for (const k of APARTADOS_PESTANA[p]) (parcial as Record<string, unknown>)[k] = doc[k]
  return contarAjustes(parcial)
}

export function Balance({ pestana, fila }: { pestana: IdPestana; fila?: string }) {
  const { datos, borrador } = usePanel()
  if (!datos) return null
  const tablas = tablasDe(datos, pestana)
  return (
    <>
      <nav className="pestanas" aria-label="Apartados de balance">
        {PESTANAS.map((p) => {
          const n = cambiosEnPestana(borrador.doc, p.id)
          return (
            <a key={p.id} href={enlace('balance', p.id)} className={p.id === pestana ? 'activo' : ''} aria-current={p.id === pestana ? 'page' : undefined}>
              {p.titulo}{n > 0 && <span className="cuenta" title={`${n} valores ajustados`}>{n}</span>}
            </a>
          )
        })}
      </nav>
      {pestana === 'economia' && <GraficosEconomia />}
      {tablas.map((t) => (
        <TablaBalance
          key={t.id}
          tabla={t}
          detalle={detalleDe(pestana)}
          abrir={fila}
          textoDetalle={pestana === 'enemigos' ? 'Dónde sale' : pestana === 'zonas' ? 'Spawns' : pestana === 'mazmorras' ? 'Oleadas' : pestana === 'misiones' ? 'Minerales' : 'Detalle'}
        />
      ))}
    </>
  )
}

function detalleDe(pestana: IdPestana): ((f: Fila) => ReactNode) | undefined {
  switch (pestana) {
    case 'enemigos': return (f) => <DetalleEnemigo id={f.id} />
    case 'zonas': return (f) => <DetalleSpawns fila={f} />
    case 'mazmorras': return (f) => <DetalleMazmorra id={f.id} />
    case 'misiones': return (f) => <DetalleRecompensa fila={f} />
    case 'piezas': return (f) => <DetallePieza id={f.id} />
    default: return undefined
  }
}

function DetalleEnemigo({ id }: { id: string }) {
  const { datos, borrador } = usePanel()
  if (!datos) return null
  const ix = indices(datos)
  const e = ix.enemigos.get(id)
  if (!e) return null
  // Spawns donde sale AHORA con el borrador (puede haberse movido con "spawns").
  const ahora = [...ix.spawns.values()].filter((s) => spawnEfectivo(borrador.doc, datos, s.id) === id)
  const quitados = [...ix.spawns.values()].filter((s) => s.enemyID === id && spawnEfectivo(borrador.doc, datos, s.id) !== id)
  const porSitio = new Map<string, string[]>()
  for (const s of ahora) {
    const sitio = s.zona ? `${ix.areas.get(s.area)?.nombre} · ${ix.zonas.get(s.zona)?.nombre}` : `${ix.areas.get(s.area)?.nombre}`
    const nivel = s.zona ? valorEfectivo(borrador.doc, datos, ['zones', s.zona, 'level']) : valorEfectivo(borrador.doc, datos, ['areas', s.area, 'level'])
    const k = `${sitio} (nivel ${fmt(nivel as number)})`
    porSitio.set(k, [...(porSitio.get(k) ?? []), s.id])
  }
  const mazmorras = datos.zonas.mazmorras.map((m) => {
    const waves = (valorEfectivo(borrador.doc, datos, ['dungeons', m.id, 'waves']) ?? []) as Cuentas[]
    const escolta = (valorEfectivo(borrador.doc, datos, ['dungeons', m.id, 'bossEscort']) ?? {}) as Cuentas
    const oleadas = waves.map((w, i) => (w[id] ? `${i + 1} (×${w[id]})` : null)).filter(Boolean)
    return { m, oleadas, escolta: escolta[id] ?? 0, jefe: m.jefe === id }
  }).filter((x) => x.oleadas.length || x.escolta || x.jefe)
  return (
    <div className="rejilla" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))' }}>
      <div>
        <h4>Historia: zonas y spawns</h4>
        {porSitio.size === 0 ? <p className="tenue peque">No sale en ningún spawn.</p> : (
          <ul className="lista-donde">
            {[...porSitio.entries()].map(([k, ss]) => <li key={k}>{k}: <code>{ss.join(', ')}</code></li>)}
          </ul>
        )}
        {quitados.length > 0 && <p className="peque" style={{ color: 'var(--sube)' }}>Quitado por el borrador de: <code>{quitados.map((s) => s.id).join(', ')}</code></p>}
      </div>
      <div>
        <h4>Mazmorras</h4>
        {mazmorras.length === 0 ? <p className="tenue peque">En ninguna.</p> : (
          <ul className="lista-donde">
            {mazmorras.map(({ m, oleadas, escolta, jefe }) => (
              <li key={m.id}>
                {m.nombre} (nivel {fmt(valorEfectivo(borrador.doc, datos, ['dungeons', m.id, 'level']) as number)}):{' '}
                {jefe && 'jefe'}{oleadas.length > 0 && `oleadas ${oleadas.join(', ')}`}{escolta > 0 && ` · escolta ×${escolta}`}
              </li>
            ))}
          </ul>
        )}
      </div>
      <div>
        <h4>Arena</h4>
        {e.arena ? (
          <ul className="lista-donde">
            <li>Desde la oleada {e.arenaPrimeraOleada ?? '?'} (con su nivel base {e.base.level})</li>
            {e.arenaOleadasDeJefe && <li>Jefe en las oleadas {e.arenaOleadasDeJefe.join(', ')}</li>}
            {e.pieza && <li>Suelta: {e.pieza.nombre} <code>{e.pieza.id}</code></li>}
          </ul>
        ) : <p className="tenue peque">No sale en la arena.</p>}
      </div>
      <div>
        <h4>Más</h4>
        <ul className="lista-donde">
          <li>{e.nombreComportamiento} · escala ×{fmt(e.escala)} · radio {fmt(e.radio)}</li>
          {e.misiones.length > 0 && <li>Misiones: {e.misiones.map((m) => ix.misiones.get(m)?.titulo ?? m).join(', ')}</li>}
          {e.piezaHistoria && <li>Pieza en la historia: {e.piezaHistoria.nombre} <code>{e.piezaHistoria.id}</code></li>}
        </ul>
      </div>
    </div>
  )
}

function DetalleSpawns({ fila }: { fila: Fila }) {
  const { datos, borrador, cambiar, restaurar } = usePanel()
  const opciones = useMemo(() => (datos ? monstruosParaSpawn(datos) : []), [datos])
  if (!datos) return null
  const ix = indices(datos)
  const spawns = fila.rutasExtra.map((r) => ix.spawns.get(r[1])!).filter(Boolean)
  const area = fila.filtros.area?.[0]
  const avisos = avisosMisionesSpawns(borrador.doc, datos).filter((a) => !area || a.includes(` ${area};`) || a.includes('algún sitio'))
  if (spawns.length === 0) return <p className="tenue">Sin spawns aquí.</p>
  return (
    <div>
      <p className="tenue peque">Qué monstruo sale en cada punto. Los jefes no se mueven (misiones y piezas). El nivel es el de la fila.</p>
      {avisos.map((a) => <div key={a} className="banda banda-error peque">{a}</div>)}
      <div className="spawns">
        {spawns.map((s) => {
          const actual = spawnEfectivo(borrador.doc, datos, s.id) ?? s.enemyID
          const cambiado = actual !== s.enemyID
          const jefe = s.jefe
          return (
            <div key={s.id} className={`spawn${cambiado ? ' cambiado' : ''}`}>
              <code>{s.id}</code>
              {jefe ? (
                <span><span className="chip chip-jefe">jefe</span>{ix.enemigos.get(s.enemyID)?.nombre}</span>
              ) : (
                <select
                  value={actual}
                  aria-label={`Monstruo del spawn ${s.id}`}
                  onChange={(e) => cambiar(['spawns', s.id], e.target.value)}
                  title={cambiado ? `Base: ${ix.enemigos.get(s.enemyID)?.nombre}` : undefined}
                >
                  {opciones.map((o) => <option key={o.id} value={o.id}>{o.nombre} (nv {o.base.level}){o.id === s.enemyID ? ' · base' : ''}</option>)}
                </select>
              )}
              {cambiado && <button className="restaurar" title="Volver al de serie" onClick={() => restaurar([['spawns', s.id]])}>↺</button>}
            </div>
          )
        })}
      </div>
    </div>
  )
}

function DetalleMazmorra({ id }: { id: string }) {
  const { datos, borrador, cambiar, restaurar } = usePanel()
  const opciones = useMemo(() => (datos ? monstruosParaSpawn(datos).map((e) => ({ id: e.id, nombre: `${e.nombre} (nv ${e.base.level})` })) : []), [datos])
  if (!datos) return null
  const m = indices(datos).mazmorras.get(id)
  if (!m) return null
  const waves = (valorEfectivo(borrador.doc, datos, ['dungeons', id, 'waves']) ?? []) as Cuentas[]
  const baseWaves = (valorBase(datos, ['dungeons', id, 'waves']) ?? []) as Cuentas[]
  const escolta = (valorEfectivo(borrador.doc, datos, ['dungeons', id, 'bossEscort']) ?? {}) as Cuentas
  const baseEscolta = (valorBase(datos, ['dungeons', id, 'bossEscort']) ?? {}) as Cuentas
  const ponerWaves = (w: Cuentas[]) => cambiar(['dungeons', id, 'waves'], w)
  const wavesCambiadas = JSON.stringify(waves) !== JSON.stringify(baseWaves)
  const escoltaCambiada = JSON.stringify(escolta) !== JSON.stringify(baseEscolta)
  const vacias = waves.map((w, i) => (Object.values(w).some((n) => n > 0) ? null : i + 1)).filter(Boolean)
  return (
    <div>
      <div className="fila-flex entre" style={{ marginBottom: 8 }}>
        <h4 style={{ margin: 0 }}>Oleadas ({waves.length}) {wavesCambiadas && <span className="chip chip-oro">cambiadas</span>}</h4>
        <div className="fila-flex">
          <button className="mini" disabled={waves.length >= OLEADAS_MAX} onClick={() => ponerWaves([...waves, { ...(waves[waves.length - 1] ?? {}) }])}>+ Oleada</button>
          {wavesCambiadas && <button className="mini plano" onClick={() => restaurar([['dungeons', id, 'waves']])}>↺ Oleadas de serie</button>}
        </div>
      </div>
      <p className="tenue peque">Sustituyen a todas las oleadas ({OLEADAS_MIN}–{OLEADAS_MAX}); sin jefes; 0–40 de cada monstruo. {m.nombreJefe ? `Jefe: ${m.nombreJefe} (no se cambia).` : 'Sin jefe.'}</p>
      {vacias.length > 0 && <div className="banda banda-error peque">La oleada {vacias.join(', ')} se queda sin monstruos: el juego ignoraría todas las oleadas.</div>}
      <div className="oleadas">
        {waves.map((w, i) => (
          <div key={i} className="oleada">
            <div className="fila-flex entre">
              <h4>Oleada {i + 1}</h4>
              <button className="plano mini" disabled={waves.length <= OLEADAS_MIN} onClick={() => ponerWaves(waves.filter((_, j) => j !== i))} aria-label={`Quitar la oleada ${i + 1}`}>✕</button>
            </div>
            <EditorCuentas
              valor={w}
              base={baseWaves[i]}
              opciones={opciones}
              campo={CAMPO_CUENTA_MONSTRUO}
              textoAnadir="Añadir monstruo"
              onCambiar={(nw) => ponerWaves(waves.map((x, j) => (j === i ? nw : x)))}
            />
          </div>
        ))}
      </div>
      <div className="fila-flex entre" style={{ marginTop: 14 }}>
        <h4 style={{ margin: 0 }}>Escolta del jefe {escoltaCambiada && <span className="chip chip-oro">cambiada</span>}</h4>
        {escoltaCambiada && <button className="mini plano" onClick={() => restaurar([['dungeons', id, 'bossEscort']])}>↺ Escolta de serie</button>}
      </div>
      <div className="oleada" style={{ maxWidth: 360, marginTop: 6 }}>
        <EditorCuentas valor={escolta} base={baseEscolta} opciones={opciones} campo={CAMPO_CUENTA_MONSTRUO} textoAnadir="Añadir monstruo"
          onCambiar={(n) => cambiar(['dungeons', id, 'bossEscort'], n)} />
      </div>
    </div>
  )
}

function DetalleRecompensa({ fila }: { fila: Fila }) {
  const { datos, borrador, cambiar, restaurar } = usePanel()
  if (!datos) return null
  const ix = indices(datos)
  const ruta = fila.rutasExtra[0]
  const valor = (valorEfectivo(borrador.doc, datos, ruta) ?? {}) as Cuentas
  const base = (valorBase(datos, ruta) ?? {}) as Cuentas
  const cambiado = JSON.stringify(valor) !== JSON.stringify(base)
  const opciones = datos.minerales.minerales.map((m) => ({ id: m.id, nombre: m.nombre }))
  const mision = ruta[0] === 'quests' ? ix.misiones.get(ruta[1]) : undefined
  const rescate = ruta[0] === 'rescues' ? ix.rescates.get(ruta[1]) : undefined
  return (
    <div className="rejilla" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))' }}>
      <div>
        {mision && (
          <>
            <p>{mision.resumen}</p>
            <ul className="lista-donde">{mision.objetivos.map((o) => <li key={o}>{o}</li>)}</ul>
          </>
        )}
        {rescate && <p>{rescate.nombre} ({rescate.papel}) en {rescate.nombreArea}.{rescate.pieza && <> Da la pieza {rescate.pieza.nombre} (no se cambia).</>}</p>}
      </div>
      <div>
        <div className="fila-flex entre">
          <h4 style={{ margin: 0 }}>Minerales {cambiado && <span className="chip chip-oro">cambiados</span>}</h4>
          {cambiado && <button className="mini plano" onClick={() => restaurar([ruta])}>↺ De serie</button>}
        </div>
        <p className="tenue peque">Si los cambias, sustituyen a todos los de la recompensa (0–99 de cada uno).</p>
        <div className="oleada">
          <EditorCuentas valor={valor} base={base} opciones={opciones} campo={CAMPO_CUENTA_MINERAL} textoAnadir="Añadir mineral" onCambiar={(n) => cambiar(ruta, n)} />
        </div>
      </div>
    </div>
  )
}

function DetallePieza({ id }: { id: string }) {
  const { datos } = usePanel()
  if (!datos) return null
  const p = indices(datos).piezas.get(id)
  if (!p) return null
  return (
    <ul className="lista-donde">
      <li>Hueco: {p.nombreHueco} · forma <code>{p.forma}</code> · material {p.material} · grupo {p.grupo}</li>
      <li>Origen: {p.origen.tipo}{p.origen.nombreJefe ? ` (${p.origen.nombreJefe})` : ''}{p.origen.nombreNpc ? ` (${p.origen.nombreNpc})` : ''}</li>
      {p.elementos.length > 0 && <li>Elementos: {p.elementos.join(', ')}</li>}
      {p.habilidad && <li>Habilidad: {p.habilidad.nombre} <code>{p.habilidad.id}</code></li>}
    </ul>
  )
}

function GraficosEconomia() {
  const { datos, borrador } = usePanel()
  if (!datos) return null
  const v = (k: string) => valorEfectivo(borrador.doc, datos, ['economy', k]) as number
  const b = datos.economia.base
  const xpBase = datos.economia.tablas.xpParaSubir.map((r) => ({ x: r.nivel, y: r.xp }))
  const xpAjustada = xpBase.map((p) => ({ x: p.x, y: Math.round(v('xpCurveBase') * Math.pow(p.x, v('xpCurveExponent'))) + v('xpCurveFlat') }))
  const oroBase = datos.economia.tablas.oroArenaPorOleada.map((r) => ({ x: r.oleada, y: r.oro }))
  const oroAjustado = oroBase.map((p) => ({ x: p.x, y: v('arenaRewardBase') + v('arenaRewardPerWave') * p.x }))
  const total = (ps: { y: number }[]) => ps.reduce((a, p) => a + p.y, 0)
  return (
    <div className="rejilla-2">
      <section className="panel">
        <h3>XP para subir de nivel</h3>
        <p className="tenue peque">round(base × nivel^exponente) + fija. Del 1 al 60: {fmt(total(xpBase))} → {fmt(total(xpAjustada))} XP en total (base {fmt(b.xpCurveBase)}, exp. {fmt(b.xpCurveExponent)}, fija {fmt(b.xpCurveFlat)}).</p>
        <Lineas base={xpBase} ajustada={xpAjustada} etiquetaX="Nivel" etiquetaY="XP" />
      </section>
      <section className="panel">
        <h3>Oro de la arena por oleada</h3>
        <p className="tenue peque">base + porOleada × oleada. Hasta la oleada {oroBase.length}: {fmt(total(oroBase))} → {fmt(total(oroAjustado))} de oro (más {fmt(v('arenaStartingGold'))} al empezar).</p>
        <Lineas base={oroBase} ajustada={oroAjustado} etiquetaX="Oleada" etiquetaY="Oro" />
      </section>
    </div>
  )
}
