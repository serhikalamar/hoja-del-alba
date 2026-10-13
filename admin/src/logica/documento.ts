// Leer y escribir valores del documento GameTuning por ruta, manteniéndolo MÍNIMO:
// solo se guarda lo que es distinto del valor base del juego, y no quedan objetos vacíos.

import type { DatosBase, Enemigo, Pieza, Zona } from '../tipos/datos'
import type { Cuentas, GameTuning, Json, Ruta } from '../tipos/tuning'
import { APARTADOS } from '../tipos/tuning'
import { casiIgual } from './numeros'

/** Valores que se guardan enteros (no campo a campo): si vienen, sustituyen a todo el valor base. */
export function esValorEntero(ruta: Ruta): boolean {
  const [ap, , campo] = ruta
  if ((ap === 'quests' || ap === 'rescues') && campo === 'minerals' && ruta.length === 3) return true
  if (ap === 'dungeons' && (campo === 'waves' || campo === 'bossEscort') && ruta.length === 3) return true
  if (ap === 'economy' && ruta[1] === 'continentLootWeights' && ruta.length === 2) return true
  return false
}

/** Índices para buscar deprisa en los datos base. */
export interface Indices {
  enemigos: Map<string, Enemigo>
  piezas: Map<string, Pieza>
  armaduras: Map<string, DatosBase['piezas']['armaduras'][number]>
  minerales: Map<string, DatosBase['minerales']['minerales'][number]>
  areas: Map<string, DatosBase['zonas']['areas'][number]>
  zonas: Map<string, Zona & { area: string }>
  spawns: Map<string, { id: string; enemyID: string; jefe: boolean; area: string; zona: string | null }>
  mazmorras: Map<string, DatosBase['zonas']['mazmorras'][number]>
  misiones: Map<string, DatosBase['misiones']['misiones'][number]>
  rescates: Map<string, DatosBase['misiones']['rescates'][number]>
  ruleta: Map<string, DatosBase['economia']['ruleta'][number]>
}

const cacheIndices = new WeakMap<DatosBase, Indices>()

export function indices(datos: DatosBase): Indices {
  const hecho = cacheIndices.get(datos)
  if (hecho) return hecho
  const zonas = new Map<string, Zona & { area: string }>()
  const spawns: Indices['spawns'] = new Map()
  for (const a of datos.zonas.areas) {
    for (const z of a.zonas) {
      zonas.set(z.id, { ...z, area: a.id })
      for (const s of z.spawns) spawns.set(s.id, { id: s.id, enemyID: s.enemyID, jefe: s.jefe, area: a.id, zona: z.id })
    }
    for (const s of a.fueraDeZona) spawns.set(s.id, { id: s.id, enemyID: s.enemyID, jefe: s.jefe, area: a.id, zona: null })
  }
  const ix: Indices = {
    enemigos: new Map(datos.enemigos.enemigos.map((e) => [e.id, e])),
    piezas: new Map(datos.piezas.piezas.map((p) => [p.id, p])),
    armaduras: new Map(datos.piezas.armaduras.map((p) => [p.id, p])),
    minerales: new Map(datos.minerales.minerales.map((m) => [m.id, m])),
    areas: new Map(datos.zonas.areas.map((a) => [a.id, a])),
    zonas,
    spawns,
    mazmorras: new Map(datos.zonas.mazmorras.map((m) => [m.id, m])),
    misiones: new Map(datos.misiones.misiones.map((m) => [m.id, m])),
    rescates: new Map(datos.misiones.rescates.map((r) => [r.id, r])),
    ruleta: new Map(datos.economia.ruleta.map((r) => [r.id, r])),
  }
  cacheIndices.set(datos, ix)
  return ix
}

function deObjeto(o: unknown, clave: string): Json | undefined {
  if (o && typeof o === 'object' && !Array.isArray(o)) return (o as Record<string, Json>)[clave]
  return undefined
}

/**
 * Valor base (del código del juego) de una ruta, o undefined si la ruta no existe.
 * Las estadísticas que una pieza no tiene valen 0.
 */
export function valorBase(datos: DatosBase, ruta: Ruta): Json | undefined {
  const ix = indices(datos)
  const [ap, id, campo, sub] = ruta
  switch (ap) {
    case 'enemies': {
      const e = ix.enemigos.get(id)
      if (!e) return undefined
      if (campo === 'storyHPMultiplier' || campo === 'storyDamageMultiplier') return e.jefe ? (e.base[campo] ?? 1) : undefined
      return ruta.length === 3 ? deObjeto(e.base, campo) : undefined
    }
    case 'parts':
    case 'armor':
    case 'minerals': {
      const o = ap === 'parts' ? ix.piezas.get(id) : ap === 'armor' ? ix.armaduras.get(id) : ix.minerales.get(id)
      if (!o) return undefined
      if (campo === 'stats') {
        if (ruta.length === 3) return o.base.stats as Json
        return ruta.length === 4 ? (o.base.stats[sub] ?? 0) : undefined
      }
      return ruta.length === 3 ? deObjeto(o.base, campo) : undefined
    }
    case 'areas':
      return ruta.length === 3 && campo === 'level' ? ix.areas.get(id)?.base.level : undefined
    case 'zones':
      return ruta.length === 3 && campo === 'level' ? ix.zonas.get(id)?.base.level : undefined
    case 'spawns':
      return ruta.length === 2 ? ix.spawns.get(id)?.enemyID : undefined
    case 'dungeons': {
      const m = ix.mazmorras.get(id)
      if (!m || ruta.length !== 3) return undefined
      return deObjeto(m.base, campo)
    }
    case 'quests': {
      const m = ix.misiones.get(id)
      return m && ruta.length === 3 ? deObjeto(m.base, campo) : undefined
    }
    case 'rescues': {
      const r = ix.rescates.get(id)
      return r && ruta.length === 3 ? deObjeto(r.base, campo) : undefined
    }
    case 'roulette': {
      const r = ix.ruleta.get(id)
      return r && ruta.length === 3 ? deObjeto(r.base, campo) : undefined
    }
    case 'economy': {
      const v = deObjeto(datos.economia.base, id)
      if (ruta.length === 2) return v
      if (id === 'continentLootWeights' && ruta.length === 3 && Array.isArray(v)) return v[Number(campo)]
      return undefined
    }
  }
  return undefined
}

/** Valor que hay en el documento en esa ruta (undefined = no se ajusta). */
export function obtener(doc: unknown, ruta: Ruta): Json | undefined {
  let o: unknown = doc
  for (const k of ruta) {
    if (o === null || typeof o !== 'object') return undefined
    o = Array.isArray(o) ? o[Number(k)] : (o as Record<string, unknown>)[k]
  }
  return o as Json | undefined
}

/** Valor efectivo: el ajustado si lo hay; si no, el base. */
export function valorEfectivo(doc: GameTuning, datos: DatosBase, ruta: Ruta): Json | undefined {
  if (ruta[0] === 'economy' && ruta[1] === 'continentLootWeights' && ruta.length === 3) {
    const lista = obtener(doc, ruta.slice(0, 2))
    if (Array.isArray(lista)) return lista[Number(ruta[2])]
    return valorBase(datos, ruta)
  }
  const v = obtener(doc, ruta)
  return v === undefined ? valorBase(datos, ruta) : v
}

/** Mapa de cuentas sin los ceros (un 0 es lo mismo que no estar). */
export function sinCeros(m: Record<string, number> | undefined | null): Record<string, number> {
  const r: Record<string, number> = {}
  if (!m) return r
  for (const k of Object.keys(m).sort()) if (m[k] !== 0 && m[k] !== undefined) r[k] = m[k]
  return r
}

/** Igualdad de JSON con tolerancia en los números y sin contar los ceros de los mapas de cuentas. */
export function igualJson(a: Json | undefined, b: Json | undefined): boolean {
  if (typeof a === 'number' && typeof b === 'number') return casiIgual(a, b)
  if (a === b) return true
  if (a === undefined || b === undefined || a === null || b === null) return false
  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false
    return a.every((x, i) => igualJson(x, b[i]))
  }
  if (typeof a === 'object' && typeof b === 'object') {
    const ka = Object.keys(a).filter((k) => a[k] !== undefined)
    const kb = Object.keys(b).filter((k) => b[k] !== undefined)
    const claves = new Set([...ka, ...kb])
    for (const k of claves) if (!igualJson(a[k] ?? 0, b[k] ?? 0)) return false
    return true
  }
  return false
}

function copia<T>(x: T): T {
  return x === undefined ? x : (JSON.parse(JSON.stringify(x)) as T)
}

function normalizar(ruta: Ruta, valor: Json): Json {
  const [ap, , campo] = ruta
  if ((ap === 'quests' || ap === 'rescues') && campo === 'minerals') return sinCeros(valor as Cuentas)
  if (ap === 'dungeons' && campo === 'bossEscort') return sinCeros(valor as Cuentas)
  if (ap === 'dungeons' && campo === 'waves' && Array.isArray(valor)) return valor.map((w) => sinCeros(w as Cuentas))
  return valor
}

/** Quita la ruta y los objetos que se queden vacíos por el camino. Devuelve un documento nuevo. */
export function quitar(doc: GameTuning, ruta: Ruta): GameTuning {
  const nuevo = copia(doc) as Record<string, unknown>
  const pila: Record<string, unknown>[] = [nuevo]
  let o: unknown = nuevo
  for (let i = 0; i < ruta.length - 1; i++) {
    o = (o as Record<string, unknown> | undefined)?.[ruta[i]]
    if (!o || typeof o !== 'object' || Array.isArray(o)) return nuevo as GameTuning
    pila.push(o as Record<string, unknown>)
  }
  delete pila[pila.length - 1][ruta[ruta.length - 1]]
  for (let i = pila.length - 1; i > 0; i--) {
    if (Object.keys(pila[i]).length === 0) delete pila[i - 1][ruta[i - 1]]
  }
  return nuevo as GameTuning
}

function poner(doc: GameTuning, ruta: Ruta, valor: Json): GameTuning {
  const nuevo = copia(doc) as Record<string, unknown>
  let o = nuevo
  for (let i = 0; i < ruta.length - 1; i++) {
    const k = ruta[i]
    if (!o[k] || typeof o[k] !== 'object' || Array.isArray(o[k])) o[k] = {}
    o = o[k] as Record<string, unknown>
  }
  o[ruta[ruta.length - 1]] = valor
  return nuevo as GameTuning
}

/**
 * Pone un valor en el documento. Si es igual al valor base, lo quita (el documento queda mínimo).
 * Un elemento de `continentLootWeights` (["economy","continentLootWeights","2"]) cambia la lista entera.
 */
export function ponerValor(doc: GameTuning, datos: DatosBase, ruta: Ruta, valor: Json): GameTuning {
  if (ruta[0] === 'economy' && ruta[1] === 'continentLootWeights' && ruta.length === 3) {
    const base = (valorBase(datos, ruta.slice(0, 2)) as number[] | undefined) ?? []
    const actual = obtener(doc, ruta.slice(0, 2))
    const lista = Array.isArray(actual) ? [...(actual as number[])] : [...base]
    lista[Number(ruta[2])] = valor as number
    return ponerValor(doc, datos, ruta.slice(0, 2), lista)
  }
  const v = normalizar(ruta, valor)
  const base = valorBase(datos, ruta)
  if (base !== undefined && igualJson(v, base)) return quitar(doc, ruta)
  return poner(doc, ruta, v)
}

/** Vuelve un campo a su valor base. */
export function restaurar(doc: GameTuning, datos: DatosBase, ruta: Ruta): GameTuning {
  if (ruta[0] === 'economy' && ruta[1] === 'continentLootWeights' && ruta.length === 3) {
    const base = valorBase(datos, ruta)
    return base === undefined ? doc : ponerValor(doc, datos, ruta, base)
  }
  return quitar(doc, ruta)
}

/** ¿Está ajustado (distinto del base) este campo? */
export function estaAjustado(doc: GameTuning, datos: DatosBase, ruta: Ruta): boolean {
  const v = valorEfectivo(doc, datos, ruta)
  const b = valorBase(datos, ruta)
  return v !== undefined && !igualJson(v, b)
}

/** Todas las rutas hoja del documento (sin entrar en los valores enteros: minerales, oleadas, pesos). */
export function rutasHoja(doc: unknown, prefijo: Ruta = []): Ruta[] {
  if (prefijo.length > 0 && esValorEntero(prefijo)) return [prefijo]
  if (doc === null || typeof doc !== 'object' || Array.isArray(doc)) return prefijo.length ? [prefijo] : []
  const r: Ruta[] = []
  for (const k of Object.keys(doc)) {
    if (prefijo.length === 0 && !(APARTADOS as readonly string[]).includes(k)) continue
    r.push(...rutasHoja((doc as Record<string, unknown>)[k], [...prefijo, k]))
  }
  return r
}

/** Quita del documento lo que coincide con los valores base (p. ej. al importar o copiar una versión). */
export function minimizar(doc: GameTuning, datos: DatosBase): GameTuning {
  let r: GameTuning = soloApartados(doc)
  for (const ruta of rutasHoja(r)) {
    const v = obtener(r, ruta)
    const b = valorBase(datos, ruta)
    if (v !== undefined && b !== undefined && igualJson(normalizar(ruta, v), b)) r = quitar(r, ruta)
  }
  return r
}

/** El documento sin los metadatos (schemaVersion, version, note) ni claves desconocidas de primer nivel. */
export function soloApartados(doc: GameTuning): GameTuning {
  const r: Record<string, unknown> = {}
  for (const k of APARTADOS) {
    const v = (doc as Record<string, unknown>)[k]
    if (v !== undefined && v !== null && !(typeof v === 'object' && Object.keys(v as object).length === 0)) r[k] = copia(v)
  }
  return r as GameTuning
}

/** Documento listo para guardar o exportar: schemaVersion + nota opcional + apartados. */
export function documentoFinal(doc: GameTuning, nota?: string): GameTuning {
  const r: GameTuning = { schemaVersion: 1 }
  if (nota && nota.trim()) r.note = nota.trim()
  return { ...r, ...soloApartados(doc) }
}

/** Número de valores ajustados (hojas). */
export function contarAjustes(doc: GameTuning): number {
  return rutasHoja(soloApartados(doc)).length
}
