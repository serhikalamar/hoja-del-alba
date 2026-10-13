// Diferencias entre dos documentos (igual que panel_diff de 002_panel.sql) y cómo contarlas en español.

import type { DatosBase } from '../tipos/datos'
import type { Json } from '../tipos/tuning'
import { esValorEntero, indices, valorBase } from './documento'
import { fmt } from './numeros'

export interface Cambio {
  /** Ruta con "/" (como la devuelve config_diff): "enemies/rat/hp". */
  path: string
  before: Json | null
  after: Json | null
}

/** Hojas que cambian entre a y b: objetos por clave y listas por posición. */
export function diferencias(a: Json | undefined | null, b: Json | undefined | null, ruta = ''): Cambio[] {
  const x = a ?? null
  const y = b ?? null
  if (JSON.stringify(x) === JSON.stringify(y)) return []
  const esObj = (v: Json | null) => v !== null && typeof v === 'object' && !Array.isArray(v)
  const unir = (k: string) => (ruta === '' ? k : `${ruta}/${k}`)
  if (esObj(x) && esObj(y)) {
    const ox = x as Record<string, Json>
    const oy = y as Record<string, Json>
    const claves = [...new Set([...Object.keys(ox), ...Object.keys(oy)])].sort()
    return claves.flatMap((k) => diferencias(ox[k], oy[k], unir(k)))
  }
  if (Array.isArray(x) && Array.isArray(y)) {
    const n = Math.max(x.length, y.length)
    const r: Cambio[] = []
    for (let i = 0; i < n; i++) r.push(...diferencias(x[i], y[i], unir(String(i))))
    return r
  }
  return [{ path: ruta === '' ? '/' : ruta, before: x, after: y }]
}

export const NOMBRES_APARTADO: Record<string, string> = {
  enemies: 'Monstruos',
  parts: 'Piezas',
  armor: 'Armaduras',
  minerals: 'Minerales',
  areas: 'Áreas',
  zones: 'Zonas',
  spawns: 'Aparición',
  dungeons: 'Mazmorras',
  quests: 'Misiones',
  rescues: 'Rescates',
  roulette: 'Ruleta',
  economy: 'Economía',
  schemaVersion: 'Formato',
  note: 'Nota',
  version: 'Versión',
}

export const NOMBRES_CAMPO: Record<string, string> = {
  hp: 'Vida',
  damage: 'Daño',
  speed: 'Velocidad',
  attackCooldown: 'Espera entre ataques',
  attackRange: 'Alcance',
  level: 'Nivel',
  dropChance: 'Prob. de mineral',
  dropRolls: 'Tiradas de mineral',
  xpMultiplier: '× XP',
  goldMultiplier: '× Oro',
  storyHPMultiplier: '× Vida (historia)',
  storyDamageMultiplier: '× Daño (historia)',
  price: 'Precio',
  tier: 'Tier',
  value: 'Valor',
  dropWeight: 'Peso en la arena',
  xp: 'XP',
  gold: 'Oro',
  minerals: 'Minerales',
  waves: 'Oleadas',
  bossEscort: 'Escolta del jefe',
  weight: 'Peso',
  multiplier: 'Multiplicador',
}

export interface CambioLegible extends Cambio {
  apartado: string
  apartadoNombre: string
  objeto: string
  campo: string
  /** Valor base del juego (para mostrar "base → antes → después"). */
  base: Json | undefined
}

function nombreStat(datos: DatosBase, clave: string): string {
  return datos.esquema.estadisticas.find((s) => s.clave === clave)?.descripcion ?? clave
}

/** Traduce una ruta "enemies/rat/hp" a algo legible ("Monstruos · Rata de alcantarilla · Vida"). */
export function describir(datos: DatosBase, c: Cambio): CambioLegible {
  const ix = indices(datos)
  const partes = c.path.split('/')
  const [ap, id, campo, sub, sub2] = partes
  let objeto = id ?? ''
  let nombreCampo = campo ? (NOMBRES_CAMPO[campo] ?? campo) : ''
  let rutaBase = partes
  switch (ap) {
    case 'enemies': objeto = ix.enemigos.get(id)?.nombre ?? id; break
    case 'parts': objeto = ix.piezas.get(id)?.nombre ?? id; break
    case 'armor': objeto = ix.armaduras.get(id)?.nombre ?? id; break
    case 'minerals': objeto = ix.minerales.get(id)?.nombre ?? id; break
    case 'areas': objeto = ix.areas.get(id)?.nombre ?? id; break
    case 'zones': {
      const z = ix.zonas.get(id)
      objeto = z ? `${z.nombre} (${ix.areas.get(z.area)?.nombre ?? z.area})` : id
      break
    }
    case 'spawns': {
      const s = ix.spawns.get(id)
      objeto = s ? `${id} (${s.zona ? ix.zonas.get(s.zona)?.nombre : ix.areas.get(s.area)?.nombre})` : id
      nombreCampo = 'Monstruo'
      break
    }
    case 'dungeons': {
      objeto = ix.mazmorras.get(id)?.nombre ?? id
      if (campo === 'waves' && sub !== undefined) {
        nombreCampo = `Oleada ${Number(sub) + 1}${sub2 ? ` · ${ix.enemigos.get(sub2)?.nombre ?? sub2}` : ''}`
        rutaBase = partes
      } else if (campo === 'bossEscort' && sub) nombreCampo = `Escolta · ${ix.enemigos.get(sub)?.nombre ?? sub}`
      break
    }
    case 'quests': objeto = ix.misiones.get(id)?.titulo ?? id; break
    case 'rescues': objeto = ix.rescates.get(id)?.nombre ?? id; break
    case 'roulette': objeto = ix.ruleta.get(id)?.nombre ?? id; break
    case 'economy': {
      objeto = id === 'continentLootWeights' ? 'Pesos de minerales del continente' : id
      nombreCampo = id === 'continentLootWeights' ? `Familia ${Number(campo) + 1}` : (datos.esquema.apartados.economy?.campos?.find((x) => x.clave === id)?.descripcion ?? id)
      break
    }
  }
  if (campo === 'stats' && sub) nombreCampo = nombreStat(datos, sub)
  if (campo === 'minerals' && sub) nombreCampo = `Minerales · ${ix.minerales.get(sub)?.nombre ?? sub}`
  let base = valorBase(datos, rutaBase)
  if (base === undefined && ap === 'dungeons' && campo === 'waves' && sub !== undefined) {
    const w = valorBase(datos, [ap, id, campo]) as Record<string, number>[] | undefined
    base = sub2 ? (w?.[Number(sub)]?.[sub2] ?? 0) : undefined
  }
  if (base === undefined && ap === 'dungeons' && campo === 'bossEscort' && sub) {
    base = ((valorBase(datos, [ap, id, campo]) as Record<string, number> | undefined)?.[sub]) ?? 0
  }
  if (base === undefined && (ap === 'quests' || ap === 'rescues') && campo === 'minerals' && sub) {
    base = ((valorBase(datos, [ap, id, campo]) as Record<string, number> | undefined)?.[sub]) ?? 0
  }
  return { ...c, apartado: ap, apartadoNombre: NOMBRES_APARTADO[ap] ?? ap, objeto, campo: nombreCampo, base }
}

/** Valor JSON en texto corto. */
export function textoValor(v: Json | undefined | null, datos?: DatosBase): string {
  if (v === undefined || v === null) return '—'
  if (typeof v === 'number') return fmt(v)
  if (typeof v === 'string') {
    if (datos) return indices(datos).enemigos.get(v)?.nombre ?? v
    return v
  }
  if (Array.isArray(v)) return `[${v.map((x) => textoValor(x, datos)).join(', ')}]`
  if (typeof v === 'object') {
    const e = Object.entries(v)
    if (e.length === 0) return 'ninguno'
    return e.map(([k, x]) => `${datos ? (indices(datos).minerales.get(k)?.nombre ?? indices(datos).enemigos.get(k)?.nombre ?? k) : k} ${textoValor(x)}`).join(', ')
  }
  return String(v)
}

/** Agrupa cambios por apartado, en el orden del contrato. */
export function agrupar(cambios: CambioLegible[]): { apartado: string; nombre: string; cambios: CambioLegible[] }[] {
  const orden = Object.keys(NOMBRES_APARTADO)
  const grupos = new Map<string, CambioLegible[]>()
  for (const c of cambios) {
    if (!grupos.has(c.apartado)) grupos.set(c.apartado, [])
    grupos.get(c.apartado)!.push(c)
  }
  return [...grupos.entries()]
    .sort((a, b) => orden.indexOf(a[0]) - orden.indexOf(b[0]))
    .map(([apartado, cs]) => ({ apartado, nombre: NOMBRES_APARTADO[apartado] ?? apartado, cambios: cs }))
}

/** ¿La ruta está DENTRO de un valor que se guarda entero (minerales, oleadas, escolta, pesos)? Ahí null = "no está". */
export function dentroDeValorEntero(path: string): boolean {
  const partes = path.split('/')
  for (let n = 2; n < partes.length; n++) if (esValorEntero(partes.slice(0, n))) return true
  return false
}

/**
 * Abre los cambios de objetos enteros ("enemies/goblin": null → {damage: 6}) en hojas ("enemies/goblin/damage").
 * Con los datos base, un valor entero que falta en un lado (oleadas, minerales…) se compara con su valor base,
 * para enseñar solo lo que de verdad cambia.
 */
export function expandir(cambios: Cambio[], datos?: DatosBase): Cambio[] {
  const compuesto = (v: Json | null) => v !== null && typeof v === 'object'
  return cambios.flatMap((c) => {
    if ((compuesto(c.before) && c.after === null) || (compuesto(c.after) && c.before === null)) {
      const vacio = (v: Json | null): Json => (Array.isArray(v) ? [] : {})
      const raiz = c.path === '/' ? '' : c.path
      const ruta = raiz.split('/')
      const base = datos && esValorEntero(ruta) ? (valorBase(datos, ruta) ?? null) : null
      const hojas = diferencias(c.before ?? base ?? vacio(c.after), c.after ?? base ?? vacio(c.before), raiz)
      return expandir(hojas, datos)
    }
    return [c]
  })
}
