// Tablas de la pantalla de Balance: filas, columnas, filtros y celdas editables, a partir de los datos base.
// Cada celda apunta a una ruta del documento GameTuning y a su esquema (rango, entero…).

import type { CampoEsquema, DatosBase, Enemigo } from '../tipos/datos'
import type { Ruta } from '../tipos/tuning'
import { CLAVES_STATS } from '../tipos/tuning'
import { indices } from './documento'
import { campoDe } from './esquema'
import { NOMBRES_CAMPO } from './diff'

export interface Columna { id: string; etiqueta: string; ayuda?: string }
export interface Celda {
  ruta: Ruta
  campo: CampoEsquema
  /** La fila no tiene este valor de serie (p. ej. una estadística que la pieza no trae): base 0. */
  ausente?: boolean
}
export interface Fila {
  id: string
  nombre: string
  sub?: string
  /** Etiquetas cortas (jefe, a distancia, T2…). */
  etiquetas?: string[]
  busqueda: string
  filtros: Record<string, string[]>
  celdas: Record<string, Celda | undefined>
  /** Rutas de la fila que no son celdas numéricas (minerales, oleadas, spawns…): para "restaurar fila" y marcar cambios. */
  rutasExtra: Ruta[]
}
export interface Filtro { id: string; etiqueta: string; opciones: { valor: string; etiqueta: string }[] }
export interface Tabla {
  id: string
  titulo: string
  descripcion?: string
  columnas: Columna[]
  filas: Fila[]
  filtros: Filtro[]
}

export const PESTANAS = [
  { id: 'enemigos', titulo: 'Enemigos' },
  { id: 'piezas', titulo: 'Piezas' },
  { id: 'armadura', titulo: 'Armadura' },
  { id: 'minerales', titulo: 'Minerales' },
  { id: 'zonas', titulo: 'Zonas y aparición' },
  { id: 'mazmorras', titulo: 'Mazmorras' },
  { id: 'misiones', titulo: 'Misiones' },
  { id: 'economia', titulo: 'Economía' },
] as const
export type IdPestana = (typeof PESTANAS)[number]['id']

export const NOMBRES_FAMILIA: Record<string, string> = {
  rat: 'Rata', goblin: 'Goblin', skeleton: 'Esqueleto', slime: 'Limo', human: 'Humano', bird: 'Ave',
  bat: 'Murciélago', dog: 'Perro', boar: 'Jabalí', brute: 'Bruto', ghost: 'Espectro',
}
export const NOMBRES_FORMA: Record<string, string> = {
  axe: 'Hacha', claw: 'Garra', crown: 'Corona', curved: 'Curva', dagger: 'Daga', greatsword: 'Mandoble',
  hammer: 'Martillo', katana: 'Katana', long: 'Larga', mace: 'Maza', pommel: 'Pomo', ring: 'Anillo',
  runic: 'Rúnica', scythe: 'Guadaña', short: 'Corta', skull: 'Calavera', spear: 'Lanza', straight: 'Recta',
  sword: 'Espada', winged: 'Alada', wrapped: 'Vendada',
}
export const NOMBRES_TIPO_MATERIAL: Record<string, string> = { cloth: 'Tela', leather: 'Cuero', metal: 'Metal' }
export const NOMBRES_RAZA: Record<string, string> = { human: 'Humano', dwarf: 'Enano', elf: 'Elfo', werewolf: 'Hombre lobo' }

const unico = <T,>(xs: T[]) => [...new Set(xs)]
const norm = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
export const normalizarBusqueda = norm

function opciones(pares: [string, string][]): { valor: string; etiqueta: string }[] {
  const m = new Map(pares)
  return [...m.entries()].map(([valor, etiqueta]) => ({ valor, etiqueta })).sort((a, b) => a.etiqueta.localeCompare(b.etiqueta, 'es', { numeric: true }))
}

function celda(datos: DatosBase, ruta: Ruta, ausente = false): Celda | undefined {
  const campo = campoDe(datos, ruta)
  return campo ? { ruta, campo, ausente } : undefined
}

function nombreStat(datos: DatosBase, k: string) {
  return datos.esquema.estadisticas.find((s) => s.clave === k)
}

/** Columnas de estadísticas: las que aparecen en alguna fila (en el orden de StatKind). */
function columnasStats(datos: DatosBase, presentes: Set<string>): Columna[] {
  return CLAVES_STATS.filter((k) => presentes.has(k)).map((k) => {
    const s = nombreStat(datos, k)
    return { id: `stat.${k}`, etiqueta: s?.nombre ?? k, ayuda: s?.descripcion }
  })
}

const ETIQUETAS_ENEMIGO: Record<string, string> = {
  hp: 'Vida', damage: 'Daño', speed: 'Veloc.', attackCooldown: 'Espera (s)', attackRange: 'Alcance', level: 'Nivel',
  dropChance: 'Prob. mineral', dropRolls: 'Tiradas', xpMultiplier: '× XP', goldMultiplier: '× Oro',
  storyHPMultiplier: '× Vida hist.', storyDamageMultiplier: '× Daño hist.',
}

const CAMPOS_ENEMIGO = ['hp', 'damage', 'speed', 'attackCooldown', 'attackRange', 'level', 'dropChance', 'dropRolls',
  'xpMultiplier', 'goldMultiplier', 'storyHPMultiplier', 'storyDamageMultiplier'] as const

function ayudaDe(datos: DatosBase, apartado: string, clave: string) {
  return datos.esquema.apartados[apartado]?.campos?.find((c) => c.clave === clave)?.descripcion
}

/** Dónde sale un enemigo (texto corto). */
export function dondeSale(e: Enemigo): string {
  const partes: string[] = []
  for (const a of e.areas) partes.push(a.nombreZona ? `${a.nombreArea} · ${a.nombreZona}` : a.nombreArea)
  for (const m of e.mazmorras) partes.push(`${m.nombre}${m.oleadas.length ? ` (oleada ${m.oleadas.join(', ')})` : ''}`)
  if (e.arena) partes.push(`Arena desde la oleada ${e.arenaPrimeraOleada ?? '?'}`)
  return partes.join(' · ')
}

function tablaEnemigos(datos: DatosBase): Tabla {
  const ix = indices(datos)
  const continenteDe = (area: string) => ix.areas.get(area)?.continente ?? ''
  const filas: Fila[] = datos.enemigos.enemigos.map((e) => {
    const areas = unico([...e.areas.map((a) => a.area), ...e.mazmorras.map((m) => ix.mazmorras.get(m.id)?.area ?? '')].filter(Boolean))
    const zonas = unico(e.areas.map((a) => a.zona).filter((z): z is string => !!z))
    const celdas: Record<string, Celda | undefined> = {}
    for (const k of CAMPOS_ENEMIGO) {
      if ((k === 'storyHPMultiplier' || k === 'storyDamageMultiplier') && !e.jefe) continue
      celdas[k] = celda(datos, ['enemies', e.id, k])
    }
    const donde: string[] = []
    if (e.arena) donde.push('arena')
    if (e.areas.length || e.mazmorras.length) donde.push('historia')
    return {
      id: e.id,
      nombre: e.nombre,
      sub: `${e.id} · ${NOMBRES_FAMILIA[e.familia] ?? e.familia} · ${e.nombreComportamiento}`,
      etiquetas: [...(e.jefe ? ['jefe'] : []), ...(e.arena ? [] : ['no sale en la arena'])],
      busqueda: norm(`${e.id} ${e.nombre} ${e.familia} ${e.nombreComportamiento} ${dondeSale(e)}`),
      filtros: {
        area: areas,
        zona: zonas,
        continente: unico(areas.map(continenteDe).filter(Boolean)),
        jefe: [e.jefe ? 'si' : 'no'],
        familia: [e.familia],
        comportamiento: [e.comportamiento],
        donde,
      },
      celdas,
      rutasExtra: [],
    }
  })
  const enemigos = datos.enemigos.enemigos
  return {
    id: 'enemigos',
    titulo: 'Monstruos y jefes',
    descripcion: datos.enemigos.nota,
    columnas: CAMPOS_ENEMIGO.map((k) => ({ id: k, etiqueta: ETIQUETAS_ENEMIGO[k] ?? NOMBRES_CAMPO[k] ?? k, ayuda: ayudaDe(datos, 'enemies', k) })),
    filas,
    filtros: [
      { id: 'continente', etiqueta: 'Continente', opciones: opciones(datos.zonas.continentes.map((c) => [c.id, c.nombre])) },
      { id: 'area', etiqueta: 'Área', opciones: opciones(datos.zonas.areas.map((a) => [a.id, a.nombre])) },
      {
        id: 'zona', etiqueta: 'Zona',
        opciones: opciones(datos.zonas.areas.flatMap((a) => a.zonas.map((z) => [z.id, `${a.nombre} · ${z.nombre}`] as [string, string]))),
      },
      { id: 'jefe', etiqueta: 'Jefe', opciones: [{ valor: 'si', etiqueta: 'Solo jefes' }, { valor: 'no', etiqueta: 'Sin jefes' }] },
      { id: 'familia', etiqueta: 'Familia', opciones: opciones(enemigos.map((e) => [e.familia, NOMBRES_FAMILIA[e.familia] ?? e.familia])) },
      { id: 'comportamiento', etiqueta: 'Ataque', opciones: opciones(enemigos.map((e) => [e.comportamiento, e.nombreComportamiento])) },
      { id: 'donde', etiqueta: 'Modo', opciones: [{ valor: 'arena', etiqueta: 'Arena' }, { valor: 'historia', etiqueta: 'Historia' }] },
    ],
  }
}

function tablaPiezas(datos: DatosBase): Tabla {
  const presentes = new Set(datos.piezas.piezas.flatMap((p) => Object.keys(p.base.stats)))
  const cols = columnasStats(datos, presentes)
  const filas: Fila[] = datos.piezas.piezas.map((p) => {
    const celdas: Record<string, Celda | undefined> = {
      price: celda(datos, ['parts', p.id, 'price']),
      tier: celda(datos, ['parts', p.id, 'tier']),
    }
    for (const c of cols) {
      const k = c.id.slice(5)
      celdas[c.id] = celda(datos, ['parts', p.id, 'stats', k], !(k in p.base.stats))
    }
    const origen = p.origen.nombreJefe ?? p.origen.nombreNpc
    return {
      id: p.id,
      nombre: p.nombre,
      sub: `${p.id} · ${p.nombreHueco} · ${p.material}${origen ? ` · ${origen}` : ''}`,
      etiquetas: [`T${p.base.tier}`, ...(p.unica ? ['única'] : []), ...(p.habilidad ? [p.habilidad.nombre] : [])],
      busqueda: norm(`${p.id} ${p.nombre} ${p.material} ${p.forma} ${NOMBRES_FORMA[p.forma] ?? ''} ${p.grupo} ${origen ?? ''} ${p.habilidad?.nombre ?? ''}`),
      filtros: {
        tier: [String(p.base.tier)],
        hueco: [p.hueco],
        grupo: [p.grupo],
        forma: [p.forma],
        material: [p.material],
        origen: [p.origen.tipo],
      },
      celdas,
      rutasExtra: [],
    }
  })
  const ps = datos.piezas.piezas
  return {
    id: 'piezas',
    titulo: 'Piezas de arma',
    descripcion: 'Las estadísticas son el valor final de la pieza; las que no tiene valen 0 (puedes añadirlas). Lo ya forjado no cambia.',
    columnas: [
      { id: 'price', etiqueta: 'Precio', ayuda: ayudaDe(datos, 'parts', 'price') },
      { id: 'tier', etiqueta: 'Tier', ayuda: ayudaDe(datos, 'parts', 'tier') },
      ...cols,
    ],
    filas,
    filtros: [
      { id: 'tier', etiqueta: 'Tier', opciones: opciones(ps.map((p) => [String(p.base.tier), `T${p.base.tier}`])) },
      { id: 'hueco', etiqueta: 'Hueco', opciones: opciones(ps.map((p) => [p.hueco, p.nombreHueco])) },
      { id: 'grupo', etiqueta: 'Grupo', opciones: opciones(ps.map((p) => [p.grupo, p.grupo])) },
      { id: 'forma', etiqueta: 'Forma', opciones: opciones(ps.map((p) => [p.forma, NOMBRES_FORMA[p.forma] ?? p.forma])) },
      { id: 'material', etiqueta: 'Material', opciones: opciones(ps.map((p) => [p.material, p.material])) },
      { id: 'origen', etiqueta: 'Origen', opciones: opciones(ps.map((p) => [p.origen.tipo, p.origen.tipo])) },
    ],
  }
}

function tablaArmadura(datos: DatosBase): Tabla {
  const presentes = new Set(datos.piezas.armaduras.flatMap((p) => Object.keys(p.base.stats)))
  const cols = columnasStats(datos, presentes)
  const as = datos.piezas.armaduras
  return {
    id: 'armadura',
    titulo: 'Diseños de armadura',
    descripcion: 'Valores con material de tier 1: el material los multiplica (poder) y la ruleta también. Coste = precio × poder^1,3 + 5.',
    columnas: [{ id: 'price', etiqueta: 'Precio', ayuda: ayudaDe(datos, 'armor', 'price') }, ...cols],
    filas: as.map((a) => {
      const celdas: Record<string, Celda | undefined> = { price: celda(datos, ['armor', a.id, 'price']) }
      for (const c of cols) {
        const k = c.id.slice(5)
        celdas[c.id] = celda(datos, ['armor', a.id, 'stats', k], !(k in a.base.stats))
      }
      return {
        id: a.id,
        nombre: a.nombre,
        sub: `${a.id} · ${a.nombreHueco} · ${NOMBRES_TIPO_MATERIAL[a.tipoMaterial] ?? a.tipoMaterial}`,
        busqueda: norm(`${a.id} ${a.nombre} ${a.nombreHueco} ${a.tipoMaterial}`),
        filtros: { hueco: [a.hueco], material: [a.tipoMaterial] },
        celdas,
        rutasExtra: [],
      }
    }),
    filtros: [
      { id: 'hueco', etiqueta: 'Hueco', opciones: opciones(as.map((a) => [a.hueco, a.nombreHueco])) },
      { id: 'material', etiqueta: 'Material', opciones: opciones(as.map((a) => [a.tipoMaterial, NOMBRES_TIPO_MATERIAL[a.tipoMaterial] ?? a.tipoMaterial])) },
    ],
  }
}

function tablaMinerales(datos: DatosBase): Tabla {
  const ms = datos.minerales.minerales
  const presentes = new Set(ms.flatMap((m) => Object.keys(m.base.stats)))
  const cols = columnasStats(datos, presentes)
  return {
    id: 'minerales',
    titulo: 'Minerales',
    descripcion: datos.minerales.nota,
    columnas: [
      { id: 'value', etiqueta: 'Valor', ayuda: ayudaDe(datos, 'minerals', 'value') },
      { id: 'dropWeight', etiqueta: 'Peso arena', ayuda: ayudaDe(datos, 'minerals', 'dropWeight') },
      ...cols,
    ],
    filas: ms.map((m) => {
      const celdas: Record<string, Celda | undefined> = {
        value: celda(datos, ['minerals', m.id, 'value']),
        dropWeight: celda(datos, ['minerals', m.id, 'dropWeight']),
      }
      for (const c of cols) {
        const k = c.id.slice(5)
        celdas[c.id] = celda(datos, ['minerals', m.id, 'stats', k], !(k in m.base.stats))
      }
      return {
        id: m.id,
        nombre: m.nombre,
        sub: `${m.id} · rareza ${m.rareza}`,
        busqueda: norm(`${m.id} ${m.nombre}`),
        filtros: { rareza: [String(m.rareza)], continente: m.continentes },
        celdas,
        rutasExtra: [],
      }
    }),
    filtros: [
      { id: 'continente', etiqueta: 'Continente', opciones: opciones(datos.zonas.continentes.map((c) => [c.id, c.nombre])) },
      { id: 'rareza', etiqueta: 'Rareza', opciones: opciones(ms.map((m) => [String(m.rareza), `Rareza ${m.rareza}`])) },
    ],
  }
}

function tablaZonas(datos: DatosBase): Tabla {
  const filas: Fila[] = []
  for (const a of datos.zonas.areas) {
    const enemigosArea = (spawns: { enemyID: string }[]) => spawns.map((s) => s.enemyID).join(' ')
    filas.push({
      id: `area:${a.id}`,
      nombre: a.nombre,
      sub: `${a.id} · ${a.nombreTipo}${a.zonas.length ? ` · ${a.zonas.length} zonas` : ''}${a.fueraDeZona.length ? ` · ${a.fueraDeZona.length} spawns` : ''}`,
      etiquetas: ['área'],
      busqueda: norm(`${a.id} ${a.nombre} ${a.nombreTipo} ${enemigosArea(a.fueraDeZona)}`),
      filtros: { continente: [a.continente], area: [a.id], tipo: ['area'], tipoArea: [a.tipo] },
      celdas: { level: celda(datos, ['areas', a.id, 'level']) },
      rutasExtra: a.fueraDeZona.map((s) => ['spawns', s.id]),
    })
    for (const z of a.zonas) {
      filas.push({
        id: `zona:${z.id}`,
        nombre: z.nombre,
        sub: `${z.id} · ${a.nombre} · ${z.spawns.length} spawns`,
        etiquetas: ['zona'],
        busqueda: norm(`${z.id} ${z.nombre} ${a.nombre} ${enemigosArea(z.spawns)} ${z.spawns.map((s) => s.nombre).join(' ')}`),
        filtros: { continente: [a.continente], area: [a.id], tipo: ['zona'], tipoArea: [a.tipo] },
        celdas: { level: celda(datos, ['zones', z.id, 'level']) },
        rutasExtra: z.spawns.map((s) => ['spawns', s.id]),
      })
    }
  }
  return {
    id: 'zonas',
    titulo: 'Áreas, zonas y aparición',
    descripcion: 'Nivel de los monstruos de cada área (fuera de zonas) y de cada zona. Abre una fila para ver y cambiar qué monstruo sale en cada spawn (los jefes no se mueven).',
    columnas: [{ id: 'level', etiqueta: 'Nivel', ayuda: 'Nivel de los monstruos' }],
    filas,
    filtros: [
      { id: 'continente', etiqueta: 'Continente', opciones: opciones(datos.zonas.continentes.map((c) => [c.id, c.nombre])) },
      { id: 'area', etiqueta: 'Área', opciones: opciones(datos.zonas.areas.map((a) => [a.id, a.nombre])) },
      { id: 'tipo', etiqueta: 'Fila', opciones: [{ valor: 'area', etiqueta: 'Áreas' }, { valor: 'zona', etiqueta: 'Zonas' }] },
      { id: 'tipoArea', etiqueta: 'Tipo de área', opciones: opciones(datos.zonas.areas.map((a) => [a.tipo, a.nombreTipo])) },
    ],
  }
}

function tablaMazmorras(datos: DatosBase): Tabla {
  const ix = indices(datos)
  return {
    id: 'mazmorras',
    titulo: 'Mazmorras de historia',
    descripcion: 'Nivel fijo de los monstruos. Abre una fila para cambiar las oleadas (1-10, sin jefes) y la escolta del jefe.',
    columnas: [{ id: 'level', etiqueta: 'Nivel', ayuda: ayudaDe(datos, 'dungeons', 'level') }],
    filas: datos.zonas.mazmorras.map((m) => ({
      id: m.id,
      nombre: m.nombre,
      sub: `${m.id} · ${ix.areas.get(m.area)?.nombre ?? m.area} · ${m.nombreJefe ? `jefe: ${m.nombreJefe}` : 'sin jefe'} · ${m.base.waves.length} oleadas`,
      etiquetas: m.repetible ? ['repetible'] : [],
      busqueda: norm(`${m.id} ${m.nombre} ${m.nombreJefe ?? ''} ${ix.areas.get(m.area)?.nombre ?? ''}`),
      filtros: { area: [m.area], continente: [ix.areas.get(m.area)?.continente ?? ''], repetible: [m.repetible ? 'si' : 'no'] },
      celdas: { level: celda(datos, ['dungeons', m.id, 'level']) },
      rutasExtra: [['dungeons', m.id, 'waves'], ['dungeons', m.id, 'bossEscort']],
    })),
    filtros: [
      { id: 'continente', etiqueta: 'Continente', opciones: opciones(datos.zonas.continentes.map((c) => [c.id, c.nombre])) },
      { id: 'area', etiqueta: 'Área', opciones: opciones(datos.zonas.mazmorras.map((m) => [m.area, ix.areas.get(m.area)?.nombre ?? m.area])) },
      { id: 'repetible', etiqueta: 'Repetible', opciones: [{ valor: 'si', etiqueta: 'Repetibles' }, { valor: 'no', etiqueta: 'Una vez' }] },
    ],
  }
}

function tablaMisiones(datos: DatosBase): Tabla {
  const ix = indices(datos)
  const filas: Fila[] = [
    ...datos.misiones.misiones.map((m): Fila => ({
      id: `mision:${m.id}`,
      nombre: m.titulo,
      sub: `${m.id} · da: ${m.nombreDaMision}`,
      etiquetas: ['misión'],
      busqueda: norm(`${m.id} ${m.titulo} ${m.nombreDaMision} ${m.resumen} ${m.objetivos.join(' ')}`),
      filtros: { tipo: ['mision'], area: m.areas },
      celdas: { xp: celda(datos, ['quests', m.id, 'xp']), gold: celda(datos, ['quests', m.id, 'gold']) },
      rutasExtra: [['quests', m.id, 'minerals']],
    })),
    ...datos.misiones.rescates.map((r): Fila => ({
      id: `rescate:${r.id}`,
      nombre: r.nombre,
      sub: `${r.id} · ${r.nombreArea}${r.pieza ? ` · da ${r.pieza.nombre}` : ''}`,
      etiquetas: [r.papel],
      busqueda: norm(`${r.id} ${r.nombre} ${r.nombreArea} ${r.papel}`),
      filtros: { tipo: ['rescate'], area: [r.area] },
      celdas: { gold: celda(datos, ['rescues', r.id, 'gold']) },
      rutasExtra: [['rescues', r.id, 'minerals']],
    })),
  ]
  const areas = unico([...datos.misiones.misiones.flatMap((m) => m.areas), ...datos.misiones.rescates.map((r) => r.area)])
  return {
    id: 'misiones',
    titulo: 'Misiones y rescates',
    descripcion: 'Recompensas. Abre una fila para cambiar los minerales (si los cambias, sustituyen a todos los de la recompensa). Los rescates no dan XP.',
    columnas: [{ id: 'xp', etiqueta: 'XP' }, { id: 'gold', etiqueta: 'Oro' }],
    filas,
    filtros: [
      { id: 'tipo', etiqueta: 'Tipo', opciones: [{ valor: 'mision', etiqueta: 'Misiones' }, { valor: 'rescate', etiqueta: 'Rescates' }] },
      { id: 'area', etiqueta: 'Área', opciones: opciones(areas.map((a) => [a, ix.areas.get(a)?.nombre ?? a])) },
    ],
  }
}

const GRUPOS_ECONOMIA: [RegExp, string, string][] = [
  [/^arena|^wallWave/, 'arena', 'Arena'],
  [/^story/, 'historia', 'Historia'],
  [/XP|^xpCurve|^level/, 'xp', 'Experiencia y niveles'],
  [/^enemy/, 'monstruos', 'Escalado de monstruos'],
  [/^forge|^reroll|^potion/, 'forja', 'Forja y tienda'],
  [/^mineral|^continent/, 'minerales', 'Minerales'],
]
export function grupoEconomia(clave: string): [string, string] {
  for (const [re, id, nombre] of GRUPOS_ECONOMIA) if (re.test(clave)) return [id, nombre]
  return ['otros', 'Otros']
}

function tablaEconomia(datos: DatosBase): Tabla {
  const campos = (datos.esquema.apartados.economy?.campos ?? []).filter((c) => c.clave !== 'continentLootWeights')
  const filas: Fila[] = campos.map((c) => {
    const [g, gn] = grupoEconomia(c.clave)
    return {
      id: c.clave,
      nombre: c.descripcion,
      sub: `${c.clave} · ${c.codigo}`,
      etiquetas: [gn],
      busqueda: norm(`${c.clave} ${c.descripcion} ${c.codigo} ${gn}`),
      filtros: { grupo: [g] },
      celdas: { valor: celda(datos, ['economy', c.clave]) },
      rutasExtra: [],
    }
  })
  return {
    id: 'economia',
    titulo: 'Números globales',
    columnas: [{ id: 'valor', etiqueta: 'Valor' }],
    filas,
    filtros: [{ id: 'grupo', etiqueta: 'Grupo', opciones: GRUPOS_ECONOMIA.map(([, id, n]) => ({ valor: id, etiqueta: n })) }],
  }
}

function tablaPesosContinente(datos: DatosBase): Tabla {
  const c = datos.esquema.apartados.economy?.campos?.find((x) => x.clave === 'continentLootWeights')
  const familia = datos.minerales.familias[0]
  const celdas: Record<string, Celda | undefined> = {}
  for (let i = 0; i < 5; i++) celdas[`w${i}`] = celda(datos, ['economy', 'continentLootWeights', String(i)])
  return {
    id: 'pesos',
    titulo: 'Minerales de la historia por continente',
    descripcion: `${c?.descripcion ?? ''}. Se aplican igual en todos los continentes (en ${familia?.nombre ?? 'Valdemar'}: ${familia?.minerales.map((m) => indices(datos).minerales.get(m.id)?.nombre ?? m.id).join(', ') ?? ''}).`,
    columnas: [0, 1, 2, 3, 4].map((i) => ({
      id: `w${i}`,
      etiqueta: familia ? (indices(datos).minerales.get(familia.minerales[i]?.id)?.nombre ?? `Familia ${i + 1}`) : `Familia ${i + 1}`,
      ayuda: `Peso del mineral ${i + 1} de la familia del continente (1 = el más común)`,
    })),
    filas: [{
      id: 'continentLootWeights',
      nombre: 'Pesos de la familia',
      sub: 'continentLootWeights · Continent.familyWeights',
      busqueda: 'continentlootweights pesos familia minerales',
      filtros: {},
      celdas,
      rutasExtra: [],
    }],
    filtros: [],
  }
}

function tablaRuleta(datos: DatosBase): Tabla {
  return {
    id: 'ruleta',
    titulo: 'Ruleta de la forja',
    descripcion: 'Peso de cada casilla y cuánto multiplica las estadísticas y el valor del objeto forjado.',
    columnas: [
      { id: 'weight', etiqueta: 'Peso', ayuda: ayudaDe(datos, 'roulette', 'weight') },
      { id: 'multiplier', etiqueta: 'Multiplicador', ayuda: ayudaDe(datos, 'roulette', 'multiplier') },
    ],
    filas: datos.economia.ruleta.map((r) => ({
      id: r.id,
      nombre: r.nombre,
      sub: `${r.id} · ${r.rareza}`,
      busqueda: norm(`${r.id} ${r.nombre} ${r.rareza}`),
      filtros: {},
      celdas: { weight: celda(datos, ['roulette', r.id, 'weight']), multiplier: celda(datos, ['roulette', r.id, 'multiplier']) },
      rutasExtra: [],
    })),
    filtros: [],
  }
}

const cache = new WeakMap<DatosBase, Map<string, Tabla[]>>()

/** Las tablas de una pestaña (Economía tiene dos: números globales y ruleta). */
export function tablasDe(datos: DatosBase, pestana: IdPestana): Tabla[] {
  let m = cache.get(datos)
  if (!m) { m = new Map(); cache.set(datos, m) }
  const hecho = m.get(pestana)
  if (hecho) return hecho
  let r: Tabla[]
  switch (pestana) {
    case 'enemigos': r = [tablaEnemigos(datos)]; break
    case 'piezas': r = [tablaPiezas(datos)]; break
    case 'armadura': r = [tablaArmadura(datos)]; break
    case 'minerales': r = [tablaMinerales(datos)]; break
    case 'zonas': r = [tablaZonas(datos)]; break
    case 'mazmorras': r = [tablaMazmorras(datos)]; break
    case 'misiones': r = [tablaMisiones(datos)]; break
    case 'economia': r = [tablaEconomia(datos), tablaPesosContinente(datos), tablaRuleta(datos)]; break
  }
  m.set(pestana, r)
  return r
}

/** Filtra las filas: búsqueda (sin acentos) y filtros (cada filtro, alguno de sus valores). */
export function filtrarFilas(filas: Fila[], busqueda: string, filtros: Record<string, string>): Fila[] {
  const palabras = norm(busqueda).split(/\s+/).filter(Boolean)
  return filas.filter((f) => {
    if (palabras.some((p) => !f.busqueda.includes(p))) return false
    for (const [k, v] of Object.entries(filtros)) {
      if (!v) continue
      if (!(f.filtros[k] ?? []).includes(v)) return false
    }
    return true
  })
}

/** Rutas de todas las celdas y extras de una fila (para restaurarla entera). */
export function rutasDeFila(f: Fila): Ruta[] {
  return [...Object.values(f.celdas).filter((c): c is Celda => !!c).map((c) => c.ruta), ...f.rutasExtra]
}

/** Pestaña y fila de la pantalla de Balance donde se edita una ruta del documento ("enemies/rat/hp"). */
export function filaDeRuta(datos: DatosBase, path: string): [IdPestana, string] | null {
  const [ap, id] = path.split('/')
  switch (ap) {
    case 'enemies': return ['enemigos', id]
    case 'parts': return ['piezas', id]
    case 'armor': return ['armadura', id]
    case 'minerals': return ['minerales', id]
    case 'areas': return ['zonas', `area:${id}`]
    case 'zones': return ['zonas', `zona:${id}`]
    case 'spawns': {
      const s = indices(datos).spawns.get(id)
      return s ? ['zonas', s.zona ? `zona:${s.zona}` : `area:${s.area}`] : null
    }
    case 'dungeons': return ['mazmorras', id]
    case 'quests': return ['misiones', `mision:${id}`]
    case 'rescues': return ['misiones', `rescate:${id}`]
    case 'roulette': return ['economia', id]
    case 'economy': return ['economia', id]
  }
  return null
}
