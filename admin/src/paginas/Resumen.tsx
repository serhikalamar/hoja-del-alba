// Resumen de jugadores (RPC admin_summary).

import { useCallback, useEffect, useState } from 'react'
import { ErrorPanel, type Resumen as TResumen } from '../api'
import { Barras, BarrasDobles, Columnas } from '../componentes/Graficos'
import { usePanel } from '../estado/panel'
import { enlace } from '../estado/ruta'
import { NOMBRES_RAZA } from '../logica/catalogo'
import { indices } from '../logica/documento'
import { fmt } from '../logica/numeros'

export function fecha(iso: string | null | undefined): string {
  if (!iso) return '—'
  const d = new Date(iso)
  return Number.isNaN(d.getTime()) ? iso : d.toLocaleString('es-ES', { dateStyle: 'medium', timeStyle: 'short' })
}

export function Resumen() {
  const { api, datos, sesion, esAdmin, publicada, modo } = usePanel()
  const [r, setR] = useState<TResumen | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [cargando, setCargando] = useState(false)

  const cargar = useCallback(() => {
    if (modo === 'supabase' && (!sesion || !esAdmin)) return
    setCargando(true)
    setError(null)
    api.resumen().then(setR).catch((e: unknown) => setError(e instanceof ErrorPanel ? e.message : String(e))).finally(() => setCargando(false))
  }, [api, modo, sesion, esAdmin])
  useEffect(cargar, [cargar])

  if (!datos) return null
  const ix = indices(datos)
  const nombreArea = (id: string) => ix.areas.get(id)?.nombre ?? id
  const nombreMision = (id: string) => ix.misiones.get(id)?.titulo ?? id
  const nombreMazmorra = (id: string) => ix.mazmorras.get(id)?.nombre ?? id
  const raza = (id: string) => NOMBRES_RAZA[id] ?? id

  const ajustes = (
    <section className="panel">
      <h2>Ajustes publicados</h2>
      {publicada ? (
        <p>Versión <strong>{publicada.version}</strong> desde {fecha(publicada.published_at)} · <a href={enlace('historial')}>historial</a></p>
      ) : (
        <p className="texto-2">{modo === 'demo' ? 'Modo demo: no hay nada publicado; el juego usa sus valores de serie.' : 'Nada publicado: el juego usa sus valores de serie.'}</p>
      )}
    </section>
  )

  if (modo === 'supabase' && !sesion) {
    return <>{ajustes}<div className="banda banda-info"><div className="crece"><strong>Resumen de jugadores</strong><br />Entra con tu usuario de admin para verlo. <a href={enlace('entrar')}>Entrar</a></div></div></>
  }
  if (modo === 'supabase' && !esAdmin) {
    return <>{ajustes}<div className="banda banda-aviso"><div className="crece"><strong>Solo para admins</strong><br />Tu usuario no está en la tabla <code>admins</code>. Mira backend/README.md, «Hacerte administrador».</div></div></>
  }

  return (
    <>
      <div className="fila-flex entre" style={{ marginBottom: 12 }}>
        <h1 style={{ margin: 0 }}>Resumen {r?.ejemplo && <span className="chip chip-oro" title="Modo demo: con Supabase configurado salen los datos reales">datos inventados</span>}</h1>
        <span className="tenue peque">
          {r && <>Generado {fecha(r.generated_at)} · </>}
          <button className="mini" onClick={cargar} disabled={cargando}>{cargando ? 'Cargando…' : '⟳ Actualizar'}</button>
        </span>
      </div>
      {error && <div className="banda banda-error"><div className="crece">{error}</div></div>}
      {!r && !error && <div className="cargando">Cargando…</div>}
      {r && (
        <>
          <div className="cifras">
            <Cifra valor={r.accounts} etiqueta="Cuentas" extra={`${fmt(r.accounts_with_characters)} con personajes`} />
            <Cifra valor={r.characters} etiqueta="Personajes" />
            <Cifra valor={r.active_last_24h} etiqueta="Activos en 24 h" extra="personajes guardados" />
            <Cifra valor={r.active_last_7d} etiqueta="Activos en 7 días" extra="personajes guardados" />
            <Cifra valor={r.gold.average} etiqueta="Oro medio" extra={`mediana ${fmt(r.gold.median)} · máx. ${fmt(r.gold.max)}`} />
            <Cifra valor={r.arena.record ?? 0} etiqueta="Récord de la arena" extra={`${fmt(r.arena.players)} jugadores · media ${fmt(r.arena.average_best_wave)}`} />
          </div>
          <div className="rejilla-2">
            <section className="panel">
              <h2>Personajes por raza</h2>
              <Barras datos={Object.entries(r.by_race).sort((a, b) => b[1] - a[1]).map(([k, n]) => ({ etiqueta: raza(k), valor: n }))} />
            </section>
            <section className="panel">
              <h2>Personajes por nivel</h2>
              <Columnas datos={r.by_level.map((x) => ({ x: x.level, y: x.characters }))} etiquetaX="Nivel" etiquetaY="Personajes" />
            </section>
            <section className="panel">
              <h2>Oro medio por nivel</h2>
              <Columnas datos={r.gold.by_level.map((x) => ({ x: x.level, y: x.average }))} etiquetaX="Nivel" etiquetaY="Oro medio" />
            </section>
            <section className="panel">
              <h2>Top 10 de la arena</h2>
              {r.arena.top.length === 0 ? <p className="tenue">Nadie ha jugado la arena todavía.</p> : (
                <table className="tabla-simple">
                  <thead><tr><th className="num">#</th><th>Personaje</th><th>Usuario</th><th>Raza</th><th className="num">Nivel</th><th className="num">Oleada</th></tr></thead>
                  <tbody>
                    {r.arena.top.map((t, i) => (
                      <tr key={i}><td className="num">{i + 1}</td><td>{t.character}</td><td className="tenue">{t.username ?? '—'}</td><td>{raza(t.race)}</td><td className="num">{t.level}</td><td className="num"><strong>{t.wave}</strong></td></tr>
                    ))}
                  </tbody>
                </table>
              )}
            </section>
          </div>
          <h2 style={{ marginTop: 8 }}>Historia</h2>
          <div className="cifras">
            <Cifra valor={r.story.average_quests_done} etiqueta="Misiones hechas (media)" />
            <Cifra valor={r.story.princess_rescued} etiqueta="Han rescatado a la princesa" />
            <Cifra valor={r.story.average_villagers_rescued} etiqueta="Aldeanos rescatados (media)" />
          </div>
          <div className="rejilla-2">
            <section className="panel">
              <h2>Misiones: aceptadas y hechas</h2>
              <BarrasDobles datos={r.story.quests.map((q) => ({ etiqueta: nombreMision(q.quest), a: q.accepted, b: q.done }))} nombres={['Aceptada', 'Hecha']} />
            </section>
            <section className="panel">
              <h2>Personajes según misiones hechas</h2>
              <Columnas datos={r.story.quests_done_distribution.map((x) => ({ x: x.quests_done, y: x.characters }))} etiquetaX="Misiones hechas" etiquetaY="Personajes" />
            </section>
            <section className="panel">
              <h2>Dónde están</h2>
              <Barras datos={r.story.by_area.map((x) => ({ etiqueta: nombreArea(x.area), valor: x.characters }))} />
            </section>
            <section className="panel">
              <h2>Mazmorras superadas</h2>
              <Barras datos={r.story.dungeons_won.map((x) => ({ etiqueta: nombreMazmorra(x.dungeon), valor: x.characters }))} vacio="Nadie ha superado una mazmorra todavía." />
            </section>
          </div>
          {ajustes}
        </>
      )}
    </>
  )
}

function Cifra({ valor, etiqueta, extra }: { valor: number; etiqueta: string; extra?: string }) {
  return (
    <div className="cifra">
      <div className="valor">{fmt(valor)}</div>
      <div className="etiqueta">{etiqueta}</div>
      {extra && <div className="extra">{extra}</div>}
    </div>
  )
}
