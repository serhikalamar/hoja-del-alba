// Borrador y publicación: nota, guardar, ver cambios (config_diff), publicar, descartar, importar/exportar JSON.

import { useMemo, useRef, useState } from 'react'
import { ErrorPanel, type DiffServidor, type FilaConfig } from '../api'
import { ListaCambios } from '../componentes/ListaCambios'
import { Confirmar, Modal } from '../componentes/Modal'
import { usePanel } from '../estado/panel'
import { enlace } from '../estado/ruta'
import { diferencias, expandir } from '../logica/diff'
import { contarAjustes, documentoFinal, minimizar, soloApartados } from '../logica/documento'
import { validarDocumento } from '../logica/esquema'
import type { GameTuning, Json } from '../tipos/tuning'
import { fecha } from './Resumen'

export function Borrador() {
  const p = usePanel()
  const { datos, borrador, publicada, puedeEscribir, sucio, modo, configs } = p
  const [diffServidor, setDiffServidor] = useState<DiffServidor | null>(null)
  const [cargandoDiff, setCargandoDiff] = useState(false)
  const [confirmarPublicar, setConfirmarPublicar] = useState(false)
  const [confirmarDescartar, setConfirmarDescartar] = useState(false)
  const [importando, setImportando] = useState<{ doc: GameTuning; nota: string; avisos: string[]; nombre: string } | null>(null)
  const [pegar, setPegar] = useState<string | null>(null)
  const fichero = useRef<HTMLInputElement>(null)

  const docPublicada = useMemo(() => soloApartados(publicada?.data ?? {}), [publicada])
  const cambiosLocal = useMemo(() => expandir(diferencias(docPublicada as Json, borrador.doc as Json)), [docPublicada, borrador.doc])
  const avisos = useMemo(() => (datos ? validarDocumento(borrador.doc, datos) : []), [datos, borrador.doc])
  if (!datos) return null
  const ajustes = contarAjustes(borrador.doc)
  const borradores = configs.filter((c) => c.status === 'draft')
  const siguiente = Math.max(0, ...configs.map((c) => c.version ?? 0)) + 1

  const verCambiosServidor = async () => {
    if (borrador.id === null) return
    setCargandoDiff(true)
    try {
      setDiffServidor(await p.api.diff(borrador.id))
    } catch (e) {
      p.notificar(e instanceof ErrorPanel ? e.message : String(e), 'error')
    } finally {
      setCargandoDiff(false)
    }
  }

  const exportar = () => {
    const doc = documentoFinal(borrador.doc, borrador.nota)
    const blob = new Blob([JSON.stringify(doc, null, 2) + '\n'], { type: 'application/json' })
    const a = document.createElement('a')
    a.href = URL.createObjectURL(blob)
    a.download = `ajustes-${borrador.id ? `borrador-${borrador.id}` : 'local'}-${new Date().toISOString().slice(0, 10)}.json`
    a.click()
    window.setTimeout(() => URL.revokeObjectURL(a.href), 1000)
  }
  const copiar = async () => {
    try {
      await navigator.clipboard.writeText(JSON.stringify(documentoFinal(borrador.doc, borrador.nota), null, 2))
      p.notificar('JSON copiado al portapapeles.', 'ok')
    } catch {
      p.notificar('No se pudo copiar (permiso del navegador). Usa «Exportar JSON».', 'error')
    }
  }

  const leerImportado = (texto: string, nombre: string) => {
    try {
      let j = JSON.parse(texto) as Record<string, unknown>
      if (j && typeof j === 'object' && 'data' in j && typeof j.data === 'object' && ('status' in j || 'schema_version' in j)) j = j.data as Record<string, unknown>
      if (!j || typeof j !== 'object' || Array.isArray(j)) throw new Error('El JSON debe ser un objeto GameTuning.')
      const doc = j as GameTuning
      setImportando({ doc, nota: typeof doc.note === 'string' ? doc.note : '', avisos: validarDocumento(doc, datos), nombre })
    } catch (e) {
      p.notificar(`No es un JSON válido: ${e instanceof Error ? e.message : String(e)}`, 'error')
    }
  }

  return (
    <>
      <h1>Borrador y publicación</h1>
      <section className="panel">
        <div className="fila-flex entre">
          <div>
            <h2 style={{ marginBottom: 4 }}>
              {borrador.id !== null ? `Borrador ${borrador.id}` : modo === 'demo' ? 'Borrador local (modo demo)' : 'Borrador nuevo (sin guardar)'}
            </h2>
            <div className="texto-2 peque">
              {ajustes} valores ajustados respecto a los de serie · {cambiosLocal.length} diferencias campo a campo respecto a {publicada ? `la versión ${publicada.version} publicada` : 'los de serie (nada publicado)'}
              {borrador.actualizado && <> · guardado {fecha(borrador.actualizado)}</>}
            </div>
          </div>
          <div className="fila-flex">
            {sucio && puedeEscribir && <span className="chip chip-oro">cambios sin guardar</span>}
            {!sucio && puedeEscribir && borrador.id !== null && <span className="chip">guardado</span>}
          </div>
        </div>

        <div className="campo" style={{ marginTop: 12 }}>
          <label htmlFor="nota">Nota (qué cambia y por qué; la verán los demás admins en el historial)</label>
          <textarea id="nota" rows={2} maxLength={500} value={borrador.nota} onChange={(e) => p.setNota(e.target.value)} placeholder="Ej.: Pedregal más duro y piezas T1 más baratas" />
        </div>

        <div className="fila-flex" style={{ marginTop: 12 }}>
          {puedeEscribir && (
            <>
              <button className="primario" onClick={() => void p.guardar()} disabled={!sucio || !!p.ocupado}>💾 Guardar borrador</button>
              <label className="fila-flex" title="Guarda solo 8 s después del último cambio">
                <input type="checkbox" checked={p.autoguardado} onChange={(e) => p.setAutoguardado(e.target.checked)} /> Autoguardado
              </label>
            </>
          )}
          <button onClick={p.deshacer} disabled={!p.puedeDeshacer}>↶ Deshacer</button>
          {puedeEscribir && (
            <button className="primario" onClick={() => setConfirmarPublicar(true)} disabled={cambiosLocal.length === 0 || !!p.ocupado}>
              ⚑ Publicar…
            </button>
          )}
          <button className="peligro" onClick={() => setConfirmarDescartar(true)} disabled={!!p.ocupado || (borrador.id === null && cambiosLocal.length === 0 && borrador.nota === '')}>
            ✕ Descartar…
          </button>
        </div>
        <div className="fila-flex" style={{ marginTop: 8 }}>
          <button onClick={exportar}>⇩ Exportar JSON</button>
          <button onClick={() => void copiar()}>⧉ Copiar JSON</button>
          <button onClick={() => fichero.current?.click()}>⇧ Importar JSON…</button>
          <button onClick={() => setPegar('')}>Pegar JSON…</button>
          <input ref={fichero} type="file" accept="application/json,.json" className="oculto" onChange={(e) => {
            const f = e.target.files?.[0]
            if (f) void f.text().then((t) => leerImportado(t, f.name))
            e.target.value = ''
          }} />
        </div>
        <p className="tenue peque" style={{ marginTop: 8 }}>
          Para probarlo en local antes de publicar: exporta el JSON y ejecuta
          {' '}<code>cd tools/Harness && swift run -c release Harness balance --ajustes ruta/al/fichero.json</code> (imprime los avisos del juego).
        </p>
        {!puedeEscribir && (
          <div className="banda banda-info peque" style={{ marginTop: 8 }}>
            <div className="crece">
              {modo === 'demo'
                ? 'Modo demo: los cambios se quedan solo en este navegador. No se guardan en Supabase ni se publican.'
                : 'Solo lectura: tus cambios se quedan en este navegador. Para guardar y publicar hace falta ser admin.'}
            </div>
          </div>
        )}
      </section>

      {avisos.length > 0 && (
        <section className="panel" style={{ borderColor: 'var(--error)' }}>
          <h2>Avisos ({avisos.length})</h2>
          <p className="texto-2 peque">Así los vería el juego al aplicar el borrador (lo inválido se ignora o se recorta).</p>
          <ul className="lista-donde mono peque">{avisos.map((a) => <li key={a}>{a}</li>)}</ul>
        </section>
      )}

      <section className="panel">
        <div className="fila-flex entre">
          <h2 style={{ margin: 0 }}>Cambios respecto a {publicada ? `la versión ${publicada.version}` : 'los valores de serie'}</h2>
          {puedeEscribir && borrador.id !== null && (
            <button onClick={() => void verCambiosServidor()} disabled={cargandoDiff} title="config_diff: lo guardado en Supabase frente a la publicada">
              {cargandoDiff ? 'Cargando…' : 'Ver cambios guardados (servidor)'}
            </button>
          )}
        </div>
        {sucio && puedeEscribir && <p className="peque" style={{ color: 'var(--sube)' }}>Incluye cambios que aún no están guardados en Supabase.</p>}
        <div style={{ marginTop: 10 }}>
          <ListaCambios cambios={cambiosLocal} antes={publicada ? `v${publicada.version}` : 'Serie'} despues="Borrador" />
        </div>
      </section>

      {puedeEscribir && borradores.length > 0 && (
        <section className="panel">
          <h2>Borradores guardados</h2>
          <table className="tabla-simple">
            <thead><tr><th className="num">id</th><th>Nota</th><th>Actualizado</th><th className="num">Ajustes</th><th /></tr></thead>
            <tbody>
              {borradores.map((c: FilaConfig) => (
                <tr key={c.id}>
                  <td className="num">{c.id}{c.id === borrador.id && <span className="chip chip-oro" style={{ marginLeft: 6 }}>abierto</span>}</td>
                  <td>{c.note || <span className="tenue">sin nota</span>}</td>
                  <td className="tenue">{fecha(c.updated_at)}</td>
                  <td className="num">{contarAjustes(c.data ?? {})}</td>
                  <td className="der">
                    {c.id !== borrador.id && (
                      <button className="mini" onClick={() => {
                        if (sucio && !window.confirm('Tienes cambios sin guardar en el borrador abierto. ¿Abrir otro igualmente?')) return
                        p.abrirBorrador(c)
                      }}>Abrir</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}

      {diffServidor && (
        <Modal titulo={`config_diff: borrador ${borrador.id} frente a ${diffServidor.from_version ? `la versión ${diffServidor.from_version}` : 'nada publicado'}`} onCerrar={() => setDiffServidor(null)} ancho={960}>
          <p className="texto-2 peque">
            {diffServidor.total} cambios · formato {diffServidor.schema_version_before ?? '—'} → {diffServidor.schema_version_after}
            {diffServidor.truncated && ' · la lista viene recortada a 300'}
          </p>
          <ListaCambios cambios={diffServidor.changes.filter((c) => c.path !== 'schemaVersion' && c.path !== 'note')} antes={diffServidor.from_version ? `v${diffServidor.from_version}` : 'Serie'} />
        </Modal>
      )}

      {confirmarPublicar && (
        <Confirmar
          titulo={`Publicar la versión ${siguiente}`}
          textoSi={sucio ? `Guardar y publicar v${siguiente}` : `Publicar v${siguiente}`}
          ocupado={!!p.ocupado}
          onNo={() => setConfirmarPublicar(false)}
          onSi={() => { void p.publicar().then((ok) => { if (ok) setConfirmarPublicar(false) }) }}
        >
          <p>
            Los jugadores la recibirán al abrir el juego o volver a él (como mucho cada 15 min) y la aplicarán <strong>en la siguiente partida</strong>.
            Lo ya forjado no cambia. Se puede volver atrás desde el Historial.
          </p>
          <p><strong>{cambiosLocal.length}</strong> cambios respecto a {publicada ? `la versión ${publicada.version}` : 'los valores de serie'} · nota: {borrador.nota ? <em>«{borrador.nota}»</em> : <span style={{ color: 'var(--sube)' }}>sin nota</span>}</p>
          {avisos.length > 0 && <div className="banda banda-error peque"><div className="crece">Hay {avisos.length} avisos: el juego ignorará o recortará esas partes.</div></div>}
          <ListaCambios cambios={cambiosLocal} limite={40} antes={publicada ? `v${publicada.version}` : 'Serie'} despues={`v${siguiente}`} />
        </Confirmar>
      )}

      {confirmarDescartar && (
        <Confirmar
          titulo="Descartar el borrador"
          textoSi={borrador.id !== null && puedeEscribir ? `Borrar el borrador ${borrador.id}` : 'Descartar los cambios'}
          peligro
          onNo={() => setConfirmarDescartar(false)}
          onSi={() => { void p.descartar().then(() => setConfirmarDescartar(false)) }}
        >
          <p>
            Se pierden los {cambiosLocal.length} cambios {borrador.id !== null && puedeEscribir ? `y se borra el borrador ${borrador.id} de Supabase` : 'de este navegador'}.
            El editor vuelve a {publicada ? `la versión ${publicada.version} publicada` : 'los valores de serie'}. Exporta el JSON antes si lo quieres guardar.
          </p>
        </Confirmar>
      )}

      {pegar !== null && (
        <Modal titulo="Pegar JSON" onCerrar={() => setPegar(null)} pie={<><button onClick={() => setPegar(null)}>Cancelar</button><button className="primario" onClick={() => { const t = pegar; setPegar(null); leerImportado(t, 'texto pegado') }}>Revisar</button></>}>
          <textarea rows={14} className="mono" value={pegar} onChange={(e) => setPegar(e.target.value)} placeholder='{ "schemaVersion": 1, "enemies": { "rat": { "hp": 15 } } }' />
        </Modal>
      )}

      {importando && (
        <Confirmar
          titulo={`Importar ${importando.nombre}`}
          textoSi="Sustituir el borrador"
          onNo={() => setImportando(null)}
          onSi={() => {
            p.reemplazar(minimizar(importando.doc, datos))
            if (importando.nota) p.setNota(importando.nota)
            p.notificar(`Importado ${importando.nombre}. Puedes deshacerlo.`, 'ok')
            setImportando(null)
          }}
        >
          <p>Sustituye lo que hay en el editor (se puede deshacer). Se quitan los valores iguales a los de serie.</p>
          <p>{contarAjustes(minimizar(importando.doc, datos))} valores ajustados{importando.nota && <> · nota «{importando.nota}»</>}</p>
          {importando.avisos.length === 0 ? <p style={{ color: 'var(--ok)' }}>✓ Sin avisos: el juego lo aplicará tal cual.</p> : (
            <>
              <p style={{ color: 'var(--error)' }}>{importando.avisos.length} avisos (el juego ignorará o recortará esas partes):</p>
              <ul className="lista-donde mono peque">{importando.avisos.slice(0, 50).map((a) => <li key={a}>{a}</li>)}</ul>
            </>
          )}
        </Confirmar>
      )}
      <p className="tenue peque">¿Quieres empezar desde una versión antigua? En el <a href={enlace('historial')}>Historial</a>, «Copiar al borrador».</p>
    </>
  )
}
