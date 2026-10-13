// Validación con los rangos de esquema.json (los mismos que aplica el juego en TuningSchema.swift).

import type { CampoEsquema, DatosBase } from '../tipos/datos'
import type { Cuentas, GameTuning, Json, Ruta } from '../tipos/tuning'
import { APARTADOS, CLAVES_STATS } from '../tipos/tuning'
import { indices, obtener, valorBase, valorEfectivo } from './documento'
import { fmt } from './numeros'

/** Rangos de los mapas que no están como campo en esquema.json (vienen del contrato). */
export const CAMPO_CUENTA_MINERAL: CampoEsquema = {
  clave: 'minerals', tipo: 'entero', min: 0, max: 99, descripcion: 'Unidades de mineral', codigo: 'QuestReward.minerals',
}
export const CAMPO_CUENTA_MONSTRUO: CampoEsquema = {
  clave: 'count', tipo: 'entero', min: 0, max: 40, descripcion: 'Cuántos monstruos de ese tipo', codigo: 'StoryDungeon.waves',
}
export const OLEADAS_MIN = 1
export const OLEADAS_MAX = 10

export function esEntero(campo: CampoEsquema): boolean {
  return campo.tipo === 'entero'
}

/** Esquema del campo numérico de una ruta, o undefined si la ruta no es un número ajustable. */
export function campoDe(datos: DatosBase, ruta: Ruta): CampoEsquema | undefined {
  const esq = datos.esquema
  const [ap, , campo] = ruta
  if (ap === 'economy') {
    const c = esq.apartados.economy?.campos?.find((x) => x.clave === ruta[1])
    if (!c) return undefined
    if (ruta[1] === 'continentLootWeights') return ruta.length === 3 ? { ...c, tipo: 'número' } : undefined
    return ruta.length === 2 ? c : undefined
  }
  if (campo === 'stats' && ruta.length === 4) {
    const s = esq.estadisticas.find((x) => x.clave === ruta[3])
    return s
  }
  if (campo === 'minerals' && ruta.length === 4) return CAMPO_CUENTA_MINERAL
  if (ruta.length !== 3) return undefined
  const ap2 = ap === 'rescues' && campo === 'xp' ? undefined : ap
  if (!ap2) return undefined
  return esq.apartados[ap2]?.campos?.find((x) => x.clave === campo)
}

/** Error de validación de un valor (texto en español) o null si vale. */
export function validarValor(campo: CampoEsquema, n: number): string | null {
  if (!Number.isFinite(n)) return 'No es un número'
  if (esEntero(campo) && !Number.isInteger(n)) return 'Debe ser un número entero'
  if (n < campo.min || n > campo.max) return `Fuera de rango: entre ${fmt(campo.min)} y ${fmt(campo.max)}`
  return null
}

/** Redondea los enteros y recorta al rango. */
export function ajustarAlRango(campo: CampoEsquema, n: number): { valor: number; recortado: boolean } {
  let v = esEntero(campo) ? Math.round(n) : Math.round(n * 1e6) / 1e6
  let recortado = false
  if (v < campo.min) { v = campo.min; recortado = true }
  if (v > campo.max) { v = campo.max; recortado = true }
  return { valor: v, recortado }
}

/** Aviso blando para el alcance según el tipo de ataque (el juego solo recorta a 4-300). */
export function avisoAlcance(datos: DatosBase, enemigoId: string, n: number): string | null {
  const e = indices(datos).enemigos.get(enemigoId)
  if (!e) return null
  if (e.comportamiento === 'ranged' && n < 60) return 'A distancia suele ir de 60 a 300'
  if (e.comportamiento !== 'ranged' && n > 40) return 'Cuerpo a cuerpo y embestida suelen ir de 4 a 40'
  return null
}

const CAMPOS_ENEMIGO_JEFE = new Set(['storyHPMultiplier', 'storyDamageMultiplier'])

function esMapa(x: unknown): x is Record<string, unknown> {
  return !!x && typeof x === 'object' && !Array.isArray(x)
}

/**
 * Revisa un documento completo como lo haría el juego (GameTuning.apply) y devuelve los avisos.
 * Lista vacía = el juego lo aplicará tal cual.
 */
export function validarDocumento(doc: GameTuning, datos: DatosBase): string[] {
  const avisos: string[] = []
  const ix = indices(datos)
  const raiz = doc as Record<string, unknown>
  for (const k of Object.keys(raiz)) {
    if (k === 'schemaVersion' || k === 'version' || k === 'note') continue
    if (!(APARTADOS as readonly string[]).includes(k)) avisos.push(`${k}: apartado desconocido; se ignora`)
  }
  if (raiz.schemaVersion !== undefined && raiz.schemaVersion !== 1) {
    avisos.push(`schemaVersion: ${String(raiz.schemaVersion)}; este panel escribe la 1`)
  }

  const numero = (ruta: Ruta, v: unknown) => {
    const ctx = ruta.join('.')
    const campo = campoDe(datos, ruta)
    if (!campo) { avisos.push(`${ctx}: campo desconocido; se ignora`); return }
    if (typeof v !== 'number') { avisos.push(`${ctx}: no es un número`); return }
    const err = validarValor(campo, v)
    if (err) avisos.push(`${ctx}: ${fmt(v)} — ${err.toLowerCase()}`)
  }
  const stats = (ruta: Ruta, v: unknown) => {
    if (!esMapa(v)) { avisos.push(`${ruta.join('.')}: debe ser un mapa estadística → número`); return }
    for (const [s, n] of Object.entries(v)) {
      if (!(CLAVES_STATS as readonly string[]).includes(s)) avisos.push(`${ruta.join('.')}.${s}: estadística desconocida; se ignora`)
      else numero([...ruta, s], n)
    }
  }
  const cuentas = (ctx: string, v: unknown, campo: CampoEsquema, valido: (id: string) => string | null) => {
    if (!esMapa(v)) { avisos.push(`${ctx}: debe ser un mapa id → cuántos`); return }
    for (const [id, n] of Object.entries(v)) {
      const e = valido(id)
      if (e) { avisos.push(`${ctx}.${id}: ${e}`); continue }
      if (typeof n !== 'number') { avisos.push(`${ctx}.${id}: no es un número`); continue }
      const err = validarValor(campo, n)
      if (err) avisos.push(`${ctx}.${id}: ${fmt(n)} — ${err.toLowerCase()}`)
    }
  }
  const mineralValido = (id: string) => (ix.minerales.has(id) ? null : 'mineral desconocido; se ignora')
  const monstruoValido = (id: string) => {
    const e = ix.enemigos.get(id)
    if (!e) return 'monstruo desconocido; se ignora'
    if (e.jefe) return 'los jefes no van en oleadas ni escoltas; se ignora'
    return null
  }

  const porId = (ap: string, existe: (id: string) => boolean, nombre: string, cada: (id: string, v: Record<string, unknown>) => void) => {
    const sec = raiz[ap]
    if (sec === undefined) return
    if (!esMapa(sec)) { avisos.push(`${ap}: debe ser un mapa id → ajuste`); return }
    for (const [id, v] of Object.entries(sec)) {
      if (!existe(id)) { avisos.push(`${ap}.${id}: ${nombre} desconocido; se ignora`); continue }
      if (!esMapa(v)) { avisos.push(`${ap}.${id}: debe ser un objeto`); continue }
      cada(id, v)
    }
  }

  porId('enemies', (id) => ix.enemigos.has(id), 'monstruo', (id, v) => {
    const jefe = ix.enemigos.get(id)!.jefe
    for (const [k, n] of Object.entries(v)) {
      if (CAMPOS_ENEMIGO_JEFE.has(k) && !jefe) { avisos.push(`enemies.${id}.${k}: solo vale para jefes; se ignora`); continue }
      numero(['enemies', id, k], n)
    }
  })
  for (const ap of ['parts', 'armor', 'minerals'] as const) {
    const existe = (id: string) => (ap === 'parts' ? ix.piezas : ap === 'armor' ? ix.armaduras : ix.minerales).has(id)
    porId(ap, existe, ap === 'parts' ? 'pieza' : ap === 'armor' ? 'diseño de armadura' : 'mineral', (id, v) => {
      for (const [k, n] of Object.entries(v)) {
        if (k === 'stats') stats([ap, id, 'stats'], n)
        else numero([ap, id, k], n)
      }
    })
  }
  porId('areas', (id) => ix.areas.has(id), 'área', (id, v) => { for (const [k, n] of Object.entries(v)) numero(['areas', id, k], n) })
  porId('zones', (id) => ix.zonas.has(id), 'zona', (id, v) => { for (const [k, n] of Object.entries(v)) numero(['zones', id, k], n) })

  const spawns = raiz.spawns
  if (spawns !== undefined) {
    if (!esMapa(spawns)) avisos.push('spawns: debe ser un mapa id de spawn → id de monstruo')
    else for (const [id, v] of Object.entries(spawns)) {
      const s = ix.spawns.get(id)
      if (!s) { avisos.push(`spawns.${id}: spawn desconocido; se ignora`); continue }
      if (typeof v !== 'string' || !ix.enemigos.has(v)) { avisos.push(`spawns.${id}: monstruo desconocido; se ignora`); continue }
      if (s.jefe || ix.enemigos.get(v)!.jefe) avisos.push(`spawns.${id}: los jefes no se cambian ni se ponen en otro sitio (misiones y piezas); se ignora`)
    }
  }

  porId('dungeons', (id) => ix.mazmorras.has(id), 'mazmorra', (id, v) => {
    for (const [k, n] of Object.entries(v)) {
      const ctx = `dungeons.${id}.${k}`
      if (k === 'waves') {
        if (!Array.isArray(n)) { avisos.push(`${ctx}: debe ser una lista de oleadas`); continue }
        if (n.length < OLEADAS_MIN || n.length > OLEADAS_MAX) avisos.push(`${ctx}: hacen falta entre ${OLEADAS_MIN} y ${OLEADAS_MAX} oleadas; se ignoran`)
        n.forEach((w, i) => {
          cuentas(`${ctx}[${i}]`, w, CAMPO_CUENTA_MONSTRUO, monstruoValido)
          if (esMapa(w) && !Object.entries(w).some(([m, c]) => typeof c === 'number' && c > 0 && !monstruoValido(m))) {
            avisos.push(`${ctx}: la oleada ${i + 1} se queda sin monstruos; se ignoran las oleadas`)
          }
        })
      } else if (k === 'bossEscort') cuentas(ctx, n, CAMPO_CUENTA_MONSTRUO, monstruoValido)
      else numero(['dungeons', id, k], n)
    }
  })
  for (const ap of ['quests', 'rescues'] as const) {
    porId(ap, (id) => (ap === 'quests' ? ix.misiones : ix.rescates).has(id), ap === 'quests' ? 'misión' : 'aldeano', (id, v) => {
      for (const [k, n] of Object.entries(v)) {
        if (k === 'minerals') cuentas(`${ap}.${id}.minerals`, n, CAMPO_CUENTA_MINERAL, mineralValido)
        else if (ap === 'rescues' && k === 'xp') avisos.push(`rescues.${id}.xp: los rescates no dan experiencia; se ignora`)
        else numero([ap, id, k], n)
      }
    })
  }
  porId('roulette', (id) => ix.ruleta.has(id), 'casilla', (id, v) => { for (const [k, n] of Object.entries(v)) numero(['roulette', id, k], n) })

  const eco = raiz.economy
  if (eco !== undefined) {
    if (!esMapa(eco)) avisos.push('economy: debe ser un objeto')
    else for (const [k, n] of Object.entries(eco)) {
      if (k === 'continentLootWeights') {
        if (!Array.isArray(n) || n.length !== 5) { avisos.push('economy.continentLootWeights: debe ser una lista de 5 números'); continue }
        n.forEach((x, i) => numero(['economy', k, String(i)], x))
        if ((n as number[]).every((x) => x === 0)) avisos.push('economy.continentLootWeights: todos a 0; el juego usará los de serie')
      } else numero(['economy', k], n)
    }
  }
  const pesos = (ap: 'minerals' | 'roulette', campo: string) => {
    const ids = ap === 'minerals' ? [...ix.minerales.keys()] : [...ix.ruleta.keys()]
    const tocado = ids.some((id) => obtener(doc, [ap, id, campo]) !== undefined)
    if (tocado && ids.every((id) => valorEfectivo(doc, datos, [ap, id, campo]) === 0)) {
      avisos.push(`${ap}: todos los ${campo} a 0; el juego usará los de serie`)
    }
  }
  pesos('minerals', 'dropWeight')
  pesos('roulette', 'weight')
  avisos.push(...avisosMisionesSpawns(doc, datos))
  return avisos
}

/** Monstruo que hay en cada spawn con el documento aplicado. */
export function spawnEfectivo(doc: GameTuning, datos: DatosBase, spawnId: string): string | undefined {
  const v = obtener(doc, ['spawns', spawnId])
  return typeof v === 'string' ? v : (valorBase(datos, ['spawns', spawnId]) as string | undefined)
}

/**
 * Misiones de "mata N de X" que se quedarían sin X en su área por los cambios de spawns.
 * (El juego, en ese caso, deshace los cambios de spawns de esa área.)
 */
export function avisosMisionesSpawns(doc: GameTuning, datos: DatosBase): string[] {
  const ix = indices(datos)
  if (!doc.spawns || Object.keys(doc.spawns).length === 0) return []
  const avisos: string[] = []
  const spawnsDe = (area: string | null) =>
    [...ix.spawns.values()].filter((s) => area === null || s.area === area).map((s) => spawnEfectivo(doc, datos, s.id))
  for (const m of datos.misiones.misiones) {
    const buscados = m.monstruos.filter((id) => !ix.enemigos.get(id)?.jefe)
    if (buscados.length === 0) continue
    if (m.areas.length > 0) {
      for (const area of m.areas) {
        if (!spawnsDe(area).some((e) => e && buscados.includes(e))) {
          avisos.push(`spawns: «${m.id}» necesita ${buscados.join('/')} en ${area}; el juego deshará los cambios de spawns de esa área`)
        }
      }
    } else {
      const enMazmorras = datos.zonas.mazmorras.some((d) => {
        const waves = (valorEfectivo(doc, datos, ['dungeons', d.id, 'waves']) ?? []) as Cuentas[]
        const escolta = (valorEfectivo(doc, datos, ['dungeons', d.id, 'bossEscort']) ?? {}) as Cuentas
        return [...waves, escolta].some((w) => buscados.some((b) => (w[b] ?? 0) > 0))
      })
      if (!enMazmorras && !spawnsDe(null).some((e) => e && buscados.includes(e))) {
        avisos.push(`spawns: «${m.id}» necesita ${buscados.join('/')} en algún sitio; el juego deshará todos los cambios de spawns`)
      }
    }
  }
  return avisos
}

/** Monstruos que se pueden poner en un spawn (los que no son jefes), ordenados por nivel. */
export function monstruosParaSpawn(datos: DatosBase) {
  return datos.enemigos.enemigos.filter((e) => !e.jefe).sort((a, b) => a.base.level - b.base.level || a.nombre.localeCompare(b.nombre, 'es'))
}

/** Valor JSON numérico o null. */
export function comoNumero(v: Json | undefined): number | null {
  return typeof v === 'number' ? v : null
}
