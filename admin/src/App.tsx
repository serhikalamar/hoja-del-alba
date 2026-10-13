// Estructura del panel: cabecera con navegación, avisos, la pantalla de cada ruta y la barra del borrador.

import { usePanel } from './estado/panel'
import { enlace, useRuta } from './estado/ruta'
import { PESTANAS, type IdPestana } from './logica/catalogo'
import { contarAjustes } from './logica/documento'
import { Balance } from './paginas/Balance'
import { Borrador } from './paginas/Borrador'
import { Entrar } from './paginas/Entrar'
import { Historial } from './paginas/Historial'
import { Jugadores } from './paginas/Jugadores'
import { fecha, Resumen } from './paginas/Resumen'

const NAV = [
  { id: 'resumen', texto: 'Resumen' },
  { id: 'jugadores', texto: 'Jugadores' },
  { id: 'balance', texto: 'Balance' },
  { id: 'borrador', texto: 'Borrador' },
  { id: 'historial', texto: 'Historial' },
] as const

export function App() {
  const p = usePanel()
  const ruta = useRuta()
  const [seccion, sub, sub2] = ruta

  if (p.errorDatos) {
    return (
      <div className="contenido">
        <div className="banda banda-error"><div className="crece"><strong>No se pueden cargar los valores base</strong><br />{p.errorDatos}</div></div>
      </div>
    )
  }
  if (!p.datos || p.comprobandoSesion) return <div className="cargando">Cargando el panel…</div>

  const pideEntrar = p.modo === 'supabase' && !p.sesion && !p.invitado
  if (pideEntrar || seccion === 'entrar') {
    return (
      <div className="app">
        <div className="contenido"><Entrar /></div>
        <Avisos />
      </div>
    )
  }

  const actual = seccion ?? 'resumen'
  const ajustes = contarAjustes(p.borrador.doc)
  const pestana: IdPestana = (PESTANAS.find((x) => x.id === sub)?.id ?? 'enemigos')

  let pagina
  switch (actual) {
    case 'jugadores': pagina = <Jugadores id={sub} />; break
    case 'balance': pagina = <Balance key={pestana} pestana={pestana} fila={sub2} />; break
    case 'borrador': pagina = <Borrador />; break
    case 'historial': pagina = <Historial />; break
    default: pagina = <Resumen />
  }

  return (
    <div className="app">
      <header className="cabecera">
        <div className="cabecera-in">
          <a className="marca" href={enlace('resumen')}>
            <img className="marca-icono" src={`${import.meta.env.BASE_URL}icono.svg`} alt="" />
            <span className="marca-texto">Hoja del Alba<small>Panel de administración</small></span>
          </a>
          <nav className="nav" aria-label="Secciones">
            {NAV.map((n) => (
              <a key={n.id} href={enlace(n.id)} className={actual === n.id ? 'activo' : ''} aria-current={actual === n.id ? 'page' : undefined}>
                {n.texto}
                {n.id === 'borrador' && (p.sucio && p.puedeEscribir ? <span className="punto" title="Cambios sin guardar" /> : ajustes > 0 ? <span className="punto" style={{ background: 'var(--tenue)' }} title={`${ajustes} ajustes`} /> : null)}
              </a>
            ))}
          </nav>
          <div className="usuario">
            {p.modo === 'demo' ? (
              <span className="chip chip-oro">MODO DEMO</span>
            ) : p.sesion ? (
              <>
                <span>{p.sesion.usuario}</span>
                <span className={`chip${p.esAdmin ? ' chip-oro' : ''}`}>{p.esAdmin ? 'admin' : 'solo lectura'}</span>
                <button className="mini" onClick={() => void p.salir()}>Salir</button>
              </>
            ) : (
              <a className="boton mini" href={enlace('entrar')} onClick={() => void p.salir()}>Entrar</a>
            )}
          </div>
        </div>
      </header>

      <main className="contenido">
        {p.modo === 'demo' && (
          <div className="banda banda-aviso">
            <div className="crece">
              <strong>Modo demo · solo lectura.</strong> {p.problemaConfig} Ves los valores base del juego y puedes probar ajustes y exportarlos,
              pero no se guarda ni se publica nada. Resumen y jugadores: datos inventados.
            </div>
          </div>
        )}
        {p.modo === 'supabase' && p.sesion && !p.esAdmin && (
          <div className="banda banda-info">
            <div className="crece"><strong>Solo lectura.</strong> Tu usuario no es admin: puedes mirar, pero no guardar ni publicar (los cambios se quedan en este navegador).</div>
          </div>
        )}
        {p.modo === 'supabase' && !p.sesion && p.invitado && (
          <div className="banda banda-info">
            <div className="crece"><strong>Sin sesión · solo lectura.</strong> Ves los valores base y la versión publicada. <a href={enlace('entrar')} onClick={() => void p.salir()}>Entrar</a></div>
          </div>
        )}
        {p.respaldoPendiente && (
          <div className="banda banda-aviso">
            <div className="crece">
              <strong>Hay cambios sin guardar en este navegador</strong> (del {fecha(p.respaldoPendiente.fecha)}{p.respaldoPendiente.id ? `, borrador ${p.respaldoPendiente.id}` : ''}).
            </div>
            <button className="primario" onClick={p.recuperarRespaldo}>Recuperarlos</button>
            <button onClick={p.olvidarRespaldo}>Descartarlos</button>
          </div>
        )}
        {pagina}
      </main>

      {(ajustes > 0 || (p.sucio && p.puedeEscribir)) && actual !== 'borrador' && (
        <div className="barra-borrador" role="status">
          <div className="barra-borrador-in">
            <span>
              <strong>{ajustes}</strong> {ajustes === 1 ? 'valor ajustado' : 'valores ajustados'}
              {p.puedeEscribir && (p.ocupado ? <> · <span className="tenue">{p.ocupado}</span></> : p.sucio ? <> · <span style={{ color: 'var(--sube)' }}>sin guardar{p.autoguardado ? ' (autoguardado en unos segundos)' : ''}</span></> : <> · <span className="tenue">guardado</span></>)}
              {!p.puedeEscribir && <span className="tenue"> · solo en este navegador</span>}
            </span>
            <span className="crece" />
            <button className="mini" onClick={p.deshacer} disabled={!p.puedeDeshacer}>↶ Deshacer</button>
            {p.puedeEscribir && <button className="mini" onClick={() => void p.guardar()} disabled={!p.sucio || !!p.ocupado}>💾 Guardar</button>}
            <a className="boton mini primario" href={enlace('borrador')}>{p.puedeEscribir ? 'Ver cambios y publicar' : 'Ver cambios y exportar'}</a>
          </div>
        </div>
      )}
      <footer className="pie">
        Valores base: {p.datos.esquema.generado.split(':')[0]} · formato GameTuning {p.datos.esquema.schemaVersion} · {p.datos.enemigos.enemigos.length} monstruos, {p.datos.piezas.piezas.length} piezas, {p.datos.zonas.areas.length} áreas
      </footer>
      <Avisos />
    </div>
  )
}

function Avisos() {
  const { avisos, cerrarAviso } = usePanel()
  return (
    <div className="toasts" aria-live="polite">
      {avisos.map((a) => (
        <div key={a.id} className={`toast toast-${a.tipo}`} role={a.tipo === 'error' ? 'alert' : 'status'}>
          <span>{a.texto}</span>
          <button className="plano mini" onClick={() => cerrarAviso(a.id)} aria-label="Cerrar aviso">✕</button>
        </div>
      ))}
    </div>
  )
}
