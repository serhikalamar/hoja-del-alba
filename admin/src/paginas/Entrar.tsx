// Entrar con usuario y contraseña del juego (email sintético con la misma plantilla que la app).

import { useState, type FormEvent } from 'react'
import { configuracion, ErrorPanel } from '../api'
import { emailDe, validarUsuario } from '../api/config'
import { usePanel } from '../estado/panel'
import { navegar } from '../estado/ruta'

export function Entrar() {
  const p = usePanel()
  const [usuario, setUsuario] = useState('')
  const [contrasena, setContrasena] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [enviando, setEnviando] = useState(false)

  const enviar = async (e: FormEvent) => {
    e.preventDefault()
    const err = validarUsuario(usuario)
    if (err) { setError(err); return }
    if (!contrasena) { setError('Escribe la contraseña.'); return }
    setEnviando(true)
    setError(null)
    try {
      await p.entrar(usuario, contrasena)
      setContrasena('')
      navegar('resumen')
    } catch (e2) {
      setError(e2 instanceof ErrorPanel ? e2.message : String(e2))
    } finally {
      setEnviando(false)
    }
  }

  return (
    <div className="entrar">
      <div className="titulo">
        <img src={`${import.meta.env.BASE_URL}icono.svg`} alt="" />
        <h1>Hoja del Alba</h1>
        <p className="texto-2">Panel de administración</p>
      </div>
      {p.modo === 'demo' ? (
        <div className="panel">
          <h2>Modo demo</h2>
          <p>{p.problemaConfig}</p>
          <p className="texto-2">
            Puedes ver todos los valores base del juego, probar ajustes en este navegador y exportar el JSON para el banco de pruebas.
            No se guarda ni se publica nada, y el resumen y los jugadores son datos inventados.
          </p>
          <p className="texto-2 peque">
            Para conectarlo: copia <code>admin/.env.example</code> a <code>admin/.env.local</code>, rellena la URL y la clave pública de Supabase,
            y vuelve a arrancar (<code>npm run dev</code>). Detalles en <code>admin/README.md</code>.
          </p>
          <button className="primario" onClick={() => navegar('resumen')}>Entrar en modo demo</button>
        </div>
      ) : p.sesion ? (
        <div className="panel">
          <h2>Conectado</h2>
          <p>Como <strong>{p.sesion.usuario}</strong> ({p.esAdmin ? 'admin' : 'no admin: solo lectura'}).</p>
          <div className="fila-flex">
            <button className="primario" onClick={() => navegar('resumen')}>Ir al resumen</button>
            <button onClick={() => void p.salir()}>Salir</button>
          </div>
        </div>
      ) : (
        <div className="panel">
          <form onSubmit={(e) => void enviar(e)}>
            <div className="campo">
              <label htmlFor="usuario">Usuario (el del juego)</label>
              <input id="usuario" autoComplete="username" autoCapitalize="none" spellCheck={false} value={usuario} onChange={(e) => setUsuario(e.target.value)} />
              {usuario && !validarUsuario(usuario) && <small className="tenue">Entra como {emailDe(usuario, configuracion.plantilla)}</small>}
            </div>
            <div className="campo">
              <label htmlFor="contrasena">Contraseña</label>
              <input id="contrasena" type="password" autoComplete="current-password" value={contrasena} onChange={(e) => setContrasena(e.target.value)} />
            </div>
            {error && <div className="banda banda-error peque" role="alert"><div className="crece">{error}</div></div>}
            <button className="primario" type="submit" disabled={enviando}>{enviando ? 'Entrando…' : 'Entrar'}</button>
            <button type="button" className="plano" onClick={() => { p.entrarComoInvitado(); navegar('balance', 'enemigos') }}>
              Ver sin entrar (solo valores base, sin guardar)
            </button>
          </form>
          <p className="tenue peque" style={{ marginTop: 12 }}>
            Solo los usuarios de la tabla <code>admins</code> pueden guardar y publicar; el resto ve el panel en solo lectura.
            No hay «he olvidado mi contraseña» (el email es sintético).
          </p>
        </div>
      )}
    </div>
  )
}
