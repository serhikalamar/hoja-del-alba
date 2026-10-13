// Configuración del panel (variables VITE_* de .env.local o de los "secrets"/"vars" del workflow de Pages).

export const PLANTILLA_POR_DEFECTO = '{usuario}@jugadores.valdehierro.app'

export interface Configuracion {
  url: string
  clave: string
  plantilla: string
  /** null = configuración válida; si no, por qué se arranca en modo demo. */
  problema: string | null
}

/** Decodifica el payload de un JWT (sin verificarlo) para mirar el rol. */
function rolDelJwt(clave: string): string | null {
  const partes = clave.split('.')
  if (partes.length !== 3) return null
  try {
    const b64 = partes[1].replace(/-/g, '+').replace(/_/g, '/')
    const json = JSON.parse(atob(b64 + '='.repeat((4 - (b64.length % 4)) % 4))) as { role?: string }
    return json.role ?? null
  } catch {
    return null
  }
}

/** ¿Es una clave secreta? (service_role o sb_secret_): el panel se niega a usarla. */
export function esClaveSecreta(clave: string): boolean {
  if (clave.startsWith('sb_secret_')) return true
  return rolDelJwt(clave) === 'service_role'
}

export function comprobarConfiguracion(url: string | undefined, clave: string | undefined, plantilla: string | undefined): Configuracion {
  const u = (url ?? '').trim().replace(/\/+$/, '')
  const k = (clave ?? '').trim()
  const p = (plantilla ?? '').trim() || PLANTILLA_POR_DEFECTO
  let problema: string | null = null
  if (!u || !k) problema = 'Supabase no está configurado (faltan VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY).'
  else if (u.includes('xxxxxxxx')) problema = 'VITE_SUPABASE_URL tiene el valor de ejemplo.'
  else if (!/^https?:\/\//.test(u)) problema = 'VITE_SUPABASE_URL debe empezar por https://'
  else if (esClaveSecreta(k)) problema = 'Esa clave es SECRETA (service_role / sb_secret_): el panel se niega a usarla. Usa la clave pública (anon o sb_publishable_) y cambia la secreta en Supabase si se ha publicado.'
  else if (!p.includes('{usuario}')) problema = 'VITE_EMAIL_PLANTILLA debe contener {usuario}.'
  return { url: u, clave: problema ? '' : k, plantilla: p, problema }
}

export const configuracion: Configuracion = comprobarConfiguracion(
  import.meta.env.VITE_SUPABASE_URL as string | undefined,
  import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined,
  import.meta.env.VITE_EMAIL_PLANTILLA as string | undefined,
)

/** Reglas del nombre de usuario (las mismas que AccountRules del juego y profiles_username_formato). */
export function validarUsuario(usuario: string): string | null {
  const u = usuario.trim().toLowerCase()
  if (u.length < 3 || u.length > 20) return 'El usuario tiene de 3 a 20 caracteres.'
  if (!/^[a-z0-9_]+$/.test(u)) return 'Solo letras a-z, números y _ (sin acentos ni ñ).'
  return null
}

export function emailDe(usuario: string, plantilla: string): string {
  return plantilla.replace('{usuario}', usuario.trim().toLowerCase())
}
