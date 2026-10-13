// Copia del borrador en localStorage (por si se cierra la pestaña sin guardar).

import type { GameTuning } from '../tipos/tuning'

const CLAVE = 'hoja-del-alba-admin.borrador.v1'

export interface Respaldo {
  doc: GameTuning
  nota: string
  /** id del borrador de Supabase al que pertenece (null = aún no guardado). */
  id: number | null
  /** Dónde se hizo (modo + URL de Supabase), para no mezclar proyectos. */
  origen: string
  fecha: string
}

export function leerRespaldo(): Respaldo | null {
  try {
    const t = localStorage.getItem(CLAVE)
    if (!t) return null
    const r = JSON.parse(t) as Respaldo
    if (!r || typeof r !== 'object' || typeof r.doc !== 'object') return null
    return r
  } catch {
    return null
  }
}

export function guardarRespaldo(r: Respaldo): void {
  try {
    localStorage.setItem(CLAVE, JSON.stringify(r))
  } catch {
    // Sin localStorage (modo privado): no pasa nada, solo no hay copia.
  }
}

export function borrarRespaldo(): void {
  try {
    localStorage.removeItem(CLAVE)
  } catch {
    // nada
  }
}

export function leerPreferencia(clave: string, porDefecto: string): string {
  try {
    return localStorage.getItem(`hoja-del-alba-admin.${clave}`) ?? porDefecto
  } catch {
    return porDefecto
  }
}

export function guardarPreferencia(clave: string, valor: string): void {
  try {
    localStorage.setItem(`hoja-del-alba-admin.${clave}`, valor)
  } catch {
    // nada
  }
}
