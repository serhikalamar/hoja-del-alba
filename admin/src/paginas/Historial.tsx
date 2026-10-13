// Historial: versiones publicadas (quién, cuándo, nota), volver a una versión (rollback_config) y registro admin_audit.

import { useCallback, useEffect, useMemo, useState } from 'react'
import { ErrorPanel, type Auditoria, type FilaConfig } from '../api'
import { ListaCambios } from '../componentes/ListaCambios'
import { Confirmar, Modal } from '../componentes/Modal'
import { usePanel } from '../estado/panel'
import { enlace, navegar } from '../estado/ruta'
import { diferencias } from '../logica/diff'
import { contarAjustes, soloApartados } from '../logica/documento'
import type { Json } from '../tipos/tuning'
import { fecha } from './Resumen'

const ACCIONES: Record<string, string> = {
  publish: 'Publicación',
  rollback: 'Vuelta atrás',
  draft_created: 'Borrador creado',
  draft_updated: 'Borrador guardado',
  draft_deleted: 'Borrador borrado',
  admin_added: 'Admin añadido',
  admin_removed: 'Admin quitado',
  manual_insert: 'Cambio a mano (alta)',
  manual_update: 'Cambio a mano',
  manual_delete: 'Cambio a mano (borrado)',
}

export function Historial() {
  const p = usePanel()
  const { api, configs, puedeEscribir, modo, sesion, esAdmin, publicada, sucio } = p
  const [audit, setAudit] = useState<Auditoria[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [verVersion, setVerVersion] = useState<FilaConfig | null>(null)
  const [volver, setVolver] = useState<FilaConfig | null>(null)
  const [verAudit, setVerAudit] = useState<Auditoria | null>(null)
  const [soloPublicaciones, setSoloPublicaciones] = useState(false)

  const cargarAudit = useCallback(() => {
    if (!puedeEscribir) return
    api.auditoria(200).then(setAudit).catch((e: unknown) => setError(e instanceof ErrorPanel ? e.message : String(e)))
  }, [api, puedeEscribir])
  useEffect(cargarAudit, [cargarAudit])

  const versiones = useMemo(() => configs.filter((c) => c.status !== 'draft').sort((a, b) => (b.version ?? 0) - (a.version ?? 0)), [configs])
  const quienPublico = useMemo(() => {
    const m = new Map<number, string>()
    for (const a of audit ?? []) if ((a.action === 'publish' || a.action === 'rollback') && a.config_id !== null && a.actor_name) m.set(a.config_id, a.actor_name)
    return m
  }, [audit])

  if (modo === 'demo' || !sesion || !esAdmin) {
    return (
      <>
        <h1>Historial</h1>
        <div className="banda banda-info">
          <div className="crece">
            {modo === 'demo'
              ? 'Modo demo: no hay historial (no hay Supabase configurado).'
              : !sesion ? <>Entra con tu usuario de admin para ver el historial. <a href={enlace('entrar')}>Entrar</a></> : 'Solo los admins ven el historial.'}
          </div>
        </div>
        {publicada && <p>Publicada ahora: versión <strong>{publicada.version}</strong> desde {fecha(publicada.published_at)}.</p>}
      </>
    )
  }

  const listaAudit = (audit ?? []).filter((a) => !soloPublicaciones || a.action === 'publish' || a.action === 'rollback' || a.action.startsWith('manual'))
  return (
    <>
      <div className="fila-flex entre" style={{ marginBottom: 12 }}>
        <h1 style={{ margin: 0 }}>Historial</h1>
        <button className="mini" onClick={() => { void p.recargar(); cargarAudit() }}>⟳ Actualizar</button>
      </div>
      {error && <div className="banda banda-error"><div className="crece">{error}</div></div>}

      <section className="panel">
        <h2>Versiones publicadas</h2>
        {versiones.length === 0 ? <p className="tenue">Todavía no se ha publicado nada: el juego usa sus valores de serie.</p> : (
          <div style={{ overflowX: 'auto' }}>
            <table className="tabla-simple">
              <thead><tr><th className="num">Versión</th><th>Estado</th><th>Publicada</th><th>Quién</th><th>Nota</th><th className="num">Ajustes</th><th /></tr></thead>
              <tbody>
                {versiones.map((v) => (
                  <tr key={v.id}>
                    <td className="num"><strong>v{v.version}</strong></td>
                    <td>{v.status === 'published' ? <span className="chip chip-oro">publicada</span> : <span className="chip">archivada</span>}</td>
                    <td className="tenue">{fecha(v.published_at)}</td>
                    <td>{quienPublico.get(v.id) ?? <span className="tenue">—</span>}</td>
                    <td>{v.note || <span className="tenue">sin nota</span>}</td>
                    <td className="num">{contarAjustes(v.data ?? {})}</td>
                    <td className="der">
                      <div className="fila-flex" style={{ justifyContent: 'flex-end' }}>
                        <button className="mini" onClick={() => setVerVersion(v)}>Ver</button>
                        <button className="mini" title="Carga esta versión en el editor como borrador nuevo (no publica nada)" onClick={() => {
                          if (sucio && !window.confirm('Tienes cambios sin guardar. ¿Sustituir el editor por esta versión? (se puede deshacer)')) return
                          p.empezarDesde(v.data ?? {}, `Basado en la versión ${v.version}`)
                          navegar('borrador')
                        }}>Copiar al borrador</button>
                        {v.status !== 'published' && <button className="mini peligro" onClick={() => setVolver(v)}>Volver a esta versión</button>}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <p className="tenue peque" style={{ marginTop: 8 }}>
          «Volver a esta versión» publica una copia con un número nuevo. Botón de emergencia sin la web (volver a los valores de serie): ver backend/README.md.
        </p>
      </section>

      <section className="panel">
        <div className="fila-flex entre">
          <h2 style={{ margin: 0 }}>Registro (admin_audit)</h2>
          <label className="fila-flex"><input type="checkbox" checked={soloPublicaciones} onChange={(e) => setSoloPublicaciones(e.target.checked)} /> Solo publicaciones y cambios a mano</label>
        </div>
        {!audit && !error && <div className="cargando">Cargando…</div>}
        {audit && (
          <div style={{ overflowX: 'auto', marginTop: 8 }}>
            <table className="tabla-simple">
              <thead><tr><th>Cuándo</th><th>Quién</th><th>Qué</th><th className="num">Versión</th><th>Resumen</th><th /></tr></thead>
              <tbody>
                {listaAudit.length === 0 && <tr><td colSpan={6} className="tenue">Nada todavía.</td></tr>}
                {listaAudit.map((a) => (
                  <tr key={a.id}>
                    <td className="tenue" style={{ whiteSpace: 'nowrap' }}>{fecha(a.created_at)}</td>
                    <td>{a.actor_name ?? '—'}</td>
                    <td>{ACCIONES[a.action] ?? a.action}</td>
                    <td className="num">{a.version ?? ''}</td>
                    <td>{a.summary}</td>
                    <td>{a.diff?.changes && a.diff.changes.length > 0 && <button className="mini" onClick={() => setVerAudit(a)}>Cambios ({a.diff.total ?? a.diff.changes.length})</button>}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {verVersion && (
        <Modal titulo={`Versión ${verVersion.version}`} onCerrar={() => setVerVersion(null)} ancho={960}>
          <p className="texto-2">{verVersion.note || 'Sin nota'} · {fecha(verVersion.published_at)}</p>
          <h3>Lo que cambia respecto a los valores de serie</h3>
          <ListaCambios cambios={diferencias({}, soloApartados(verVersion.data ?? {}) as Json)} antes="Serie" despues={`v${verVersion.version}`} />
          <details style={{ marginTop: 12 }}><summary>JSON</summary><pre className="json">{JSON.stringify(verVersion.data, null, 2)}</pre></details>
        </Modal>
      )}
      {verAudit && (
        <Modal titulo={`${ACCIONES[verAudit.action] ?? verAudit.action} · ${fecha(verAudit.created_at)}`} onCerrar={() => setVerAudit(null)} ancho={960}>
          <p>{verAudit.summary}</p>
          {verAudit.diff?.truncated && <p className="tenue peque">Lista recortada: {verAudit.diff.total} cambios en total.</p>}
          <ListaCambios cambios={verAudit.diff?.changes ?? []} antes="Antes" despues="Después" />
        </Modal>
      )}
      {volver && (
        <Confirmar
          titulo={`Volver a la versión ${volver.version}`}
          textoSi={`Publicar una copia de la v${volver.version}`}
          peligro
          ocupado={!!p.ocupado}
          onNo={() => setVolver(null)}
          onSi={() => { void p.volverA(volver.version!).then((ok) => { if (ok) { setVolver(null); cargarAudit() } }) }}
        >
          <p>
            Se publica una <strong>copia</strong> de la versión {volver.version} con un número nuevo; la publicada ahora ({publicada ? `v${publicada.version}` : 'ninguna'}) pasa a archivada.
            Los jugadores la aplicarán en su siguiente partida. Tu borrador no se toca.
          </p>
          <h3>Qué cambia para los jugadores</h3>
          <ListaCambios
            cambios={diferencias(soloApartados(publicada?.data ?? {}) as Json, soloApartados(volver.data ?? {}) as Json)}
            antes={publicada ? `v${publicada.version}` : 'Serie'}
            despues={`v${volver.version}`}
            limite={40}
          />
        </Confirmar>
      )}
    </>
  )
}
