// API real: Supabase con la clave PÚBLICA. La seguridad la dan RLS y las comprobaciones de 002_panel.sql.
// Todo lo que habla con Supabase está aquí; el resto del panel solo ve la interfaz PanelApi.

import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import type { GameTuning } from '../tipos/tuning'
import { SCHEMA_VERSION } from '../tipos/tuning'
import { emailDe, type Configuracion } from './config'
import {
  ErrorPanel, type Auditoria, type ConfigPublicada, type DiffServidor, type FichaPersonaje, type FilaConfig,
  type FilaPersonaje, type PanelApi, type Resumen, type Sesion,
} from './tipos'

interface ErrorPostgrest { code?: string; message?: string; hint?: string | null; details?: string | null; status?: number }

/** Traduce los errores de PostgREST / Auth a mensajes en español (códigos de backend/README.md). */
export function traducirError(e: unknown): ErrorPanel {
  if (e instanceof ErrorPanel) return e
  const err = (e ?? {}) as ErrorPostgrest & { name?: string }
  const code = err.code ?? ''
  const hint = err.hint ?? ''
  const msg = err.message ?? String(e)
  if (code === '42501' || hint === 'no_admin') return new ErrorPanel('no_admin', 'No eres administrador: tu usuario no está en la tabla admins (ver backend/README.md, "Hacerte administrador").')
  if (code === 'P0002' || hint === 'no_existe') return new ErrorPanel('no_existe', 'Eso ya no existe (¿lo ha borrado o publicado otra persona?).')
  if (hint === 'no_es_borrador') return new ErrorPanel('no_es_borrador', 'Esa configuración ya no es un borrador (¿se ha publicado?). Recarga.')
  if (hint === 'ya_publicada') return new ErrorPanel('ya_publicada', 'Esa versión ya es la publicada.')
  if (code === 'PGRST202' || code === '42883') return new ErrorPanel('falta_funcion', 'Falta una función en Supabase: ejecuta backend/supabase/migrations/002_panel.sql en el SQL Editor.')
  if (code === '42P01' || code === 'PGRST205') return new ErrorPanel('falta_tabla', 'Faltan las tablas del panel en Supabase: ejecuta 002_panel.sql.')
  if (code === 'PGRST301' || code === 'PGRST303' || /JWT/i.test(msg)) return new ErrorPanel('sesion', 'La sesión ha caducado: vuelve a entrar.')
  if (code === '23514') return new ErrorPanel('datos', `Supabase rechaza los datos (${msg}). ¿Nota de más de 500 caracteres o documento de más de 512 KB?`)
  if (code === 'invalid_credentials' || /Invalid login credentials/i.test(msg)) return new ErrorPanel('credenciales', 'Usuario o contraseña incorrectos.')
  if (code === 'email_not_confirmed') return new ErrorPanel('email', 'Supabase pide confirmar el email: desactiva "Confirm email" (backend/README.md, paso 3).')
  if (code === 'over_request_rate_limit' || err.status === 429) return new ErrorPanel('limite', 'Demasiados intentos: espera un poco.')
  if (/Failed to fetch|NetworkError|Load failed|fetch failed/i.test(msg)) return new ErrorPanel('red', 'No hay conexión con Supabase (¿URL correcta? ¿sin red?).')
  return new ErrorPanel(code || 'desconocido', msg)
}

async function esperar<T>(p: PromiseLike<{ data: T | null; error: unknown }>): Promise<T> {
  let r: { data: T | null; error: unknown }
  try {
    r = await p
  } catch (e) {
    throw traducirError(e)
  }
  if (r.error) throw traducirError(r.error)
  return r.data as T
}

/** schema_version de la columna = schemaVersion de dentro de data (backend/README.md, "Formato"). */
function conFormato(data: GameTuning): GameTuning {
  return { ...data, schemaVersion: data.schemaVersion ?? SCHEMA_VERSION }
}

export class ApiSupabase implements PanelApi {
  readonly modo = 'supabase' as const
  private readonly sb: SupabaseClient
  private readonly config: Configuracion

  constructor(config: Configuracion) {
    this.config = config
    this.sb = createClient(config.url, config.clave, {
      auth: { persistSession: true, autoRefreshToken: true, storageKey: 'hoja-del-alba-admin.sesion' },
    })
  }

  async sesion(): Promise<Sesion | null> {
    const { data } = await this.sb.auth.getSession()
    const email = data.session?.user.email
    if (!email) return null
    return { email, usuario: this.usuarioDe(email) }
  }

  private usuarioDe(email: string): string {
    // Deshace la plantilla: "{usuario}@dominio" o "yo+{usuario}@gmail.com".
    const [antes, despues] = this.config.plantilla.split('{usuario}')
    if (email.startsWith(antes) && email.endsWith(despues)) return email.slice(antes.length, email.length - despues.length)
    return email
  }

  async entrar(usuario: string, contrasena: string): Promise<Sesion> {
    const email = emailDe(usuario, this.config.plantilla)
    const { data, error } = await this.sb.auth.signInWithPassword({ email, password: contrasena }).catch((e: unknown) => ({ data: null, error: e }))
    if (error || !data?.session) throw traducirError(error ?? new Error('No se pudo iniciar sesión'))
    return { email, usuario: usuario.trim().toLowerCase() }
  }

  async salir(): Promise<void> {
    await this.sb.auth.signOut()
  }

  async esAdmin(): Promise<boolean> {
    return (await esperar<boolean>(this.sb.rpc('is_admin'))) === true
  }

  async publicada(): Promise<ConfigPublicada | null> {
    const filas = await esperar<ConfigPublicada[]>(this.sb.rpc('published_config'))
    return filas?.[0] ?? null
  }

  async configs(): Promise<FilaConfig[]> {
    return (await esperar<FilaConfig[]>(this.sb.from('game_config').select('*').order('id', { ascending: false }))) ?? []
  }

  async crearBorrador(data: GameTuning, nota: string | null): Promise<FilaConfig> {
    const d = conFormato(data)
    return esperar<FilaConfig>(
      this.sb.from('game_config').insert({ data: d, schema_version: d.schemaVersion, note: nota || null }).select().single(),
    )
  }

  async guardarBorrador(id: number, data: GameTuning, nota: string | null): Promise<FilaConfig> {
    const d = conFormato(data)
    const filas = await esperar<FilaConfig[]>(
      this.sb.from('game_config').update({ data: d, schema_version: d.schemaVersion, note: nota || null }).eq('id', id).select(),
    )
    if (!filas || filas.length === 0) throw new ErrorPanel('no_es_borrador', 'Ese borrador ya no existe o ya no es un borrador (¿se ha publicado o borrado?). Recarga.')
    return filas[0]
  }

  async borrarBorrador(id: number): Promise<void> {
    const filas = await esperar<FilaConfig[]>(this.sb.from('game_config').delete().eq('id', id).select('id'))
    if (!filas || filas.length === 0) throw new ErrorPanel('no_es_borrador', 'No se ha borrado: ya no es un borrador.')
  }

  async diff(id: number): Promise<DiffServidor> {
    return esperar<DiffServidor>(this.sb.rpc('config_diff', { draft_id: id }))
  }

  async publicar(id: number): Promise<FilaConfig> {
    return esperar<FilaConfig>(this.sb.rpc('publish_config', { draft_id: id }))
  }

  async volverA(version: number): Promise<FilaConfig> {
    return esperar<FilaConfig>(this.sb.rpc('rollback_config', { version }))
  }

  async auditoria(limite = 100): Promise<Auditoria[]> {
    return (await esperar<Auditoria[]>(this.sb.from('admin_audit').select('*').order('created_at', { ascending: false }).limit(limite))) ?? []
  }

  async resumen(): Promise<Resumen> {
    return esperar<Resumen>(this.sb.rpc('admin_summary'))
  }

  async personajes(busqueda: string, pagina: number, tamano: number): Promise<FilaPersonaje[]> {
    return (await esperar<FilaPersonaje[]>(
      this.sb.rpc('admin_characters', { search: busqueda.trim() || null, page_size: tamano, page: pagina }),
    )) ?? []
  }

  async personaje(id: string): Promise<FichaPersonaje | null> {
    const filas = await esperar<FichaPersonaje[]>(this.sb.rpc('admin_character', { character_id: id }))
    return filas?.[0] ?? null
  }
}
