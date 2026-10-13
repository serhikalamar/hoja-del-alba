// Elige la API: Supabase si está bien configurado; si no, el modo demo (solo lectura).
// El cliente de Supabase se carga aparte (import dinámico): el modo demo no lo descarga.

import type { GameTuning } from '../tipos/tuning'
import { configuracion, type Configuracion } from './config'
import { ApiDemo } from './demo'
import type { PanelApi } from './tipos'

class ApiPerezosa implements PanelApi {
  readonly modo = 'supabase' as const
  private promesa: Promise<PanelApi> | null = null
  private readonly config: Configuracion
  constructor(config: Configuracion) { this.config = config }
  private real(): Promise<PanelApi> {
    this.promesa ??= import('./supabase').then((m) => new m.ApiSupabase(this.config))
    return this.promesa
  }
  sesion() { return this.real().then((a) => a.sesion()) }
  entrar(u: string, c: string) { return this.real().then((a) => a.entrar(u, c)) }
  salir() { return this.real().then((a) => a.salir()) }
  esAdmin() { return this.real().then((a) => a.esAdmin()) }
  publicada() { return this.real().then((a) => a.publicada()) }
  configs() { return this.real().then((a) => a.configs()) }
  crearBorrador(d: GameTuning, n: string | null) { return this.real().then((a) => a.crearBorrador(d, n)) }
  guardarBorrador(id: number, d: GameTuning, n: string | null) { return this.real().then((a) => a.guardarBorrador(id, d, n)) }
  borrarBorrador(id: number) { return this.real().then((a) => a.borrarBorrador(id)) }
  diff(id: number) { return this.real().then((a) => a.diff(id)) }
  publicar(id: number) { return this.real().then((a) => a.publicar(id)) }
  volverA(v: number) { return this.real().then((a) => a.volverA(v)) }
  auditoria(l?: number) { return this.real().then((a) => a.auditoria(l)) }
  resumen() { return this.real().then((a) => a.resumen()) }
  personajes(b: string, p: number, t: number) { return this.real().then((a) => a.personajes(b, p, t)) }
  personaje(id: string) { return this.real().then((a) => a.personaje(id)) }
}

export function crearApi(): PanelApi {
  return configuracion.problema ? new ApiDemo() : new ApiPerezosa(configuracion)
}

export { configuracion }
export * from './tipos'
