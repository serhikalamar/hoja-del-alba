// Tests de la lógica del panel (sin navegador ni Supabase): documento mínimo, validación, diff y edición masiva.
// Con EXPORTAR_EJEMPLO=<fichero.json> escribe además un borrador de ejemplo para probarlo en el juego:
//   cd tools/Harness && swift run -c release Harness balance 1 --ajustes <fichero.json>

import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
import type { DatosBase } from '../tipos/datos'
import type { GameTuning } from '../tipos/tuning'
import { filtrarFilas, rutasDeFila, tablasDe } from './catalogo'
import { dentroDeValorEntero, describir, diferencias, expandir } from './diff'
import { contarAjustes, documentoFinal, estaAjustado, minimizar, obtener, ponerValor, restaurar, valorBase, valorEfectivo } from './documento'
import { ajustarAlRango, campoDe, validarDocumento, validarValor } from './esquema'
import { aplicarMasivo } from './masivo'
import { leerNumero } from './numeros'

const carpeta = join(dirname(fileURLToPath(import.meta.url)), '../../public/data')
const leer = (f: string) => JSON.parse(readFileSync(join(carpeta, `${f}.json`), 'utf8'))
const datos: DatosBase = {
  enemigos: leer('enemigos'),
  piezas: leer('piezas'),
  minerales: leer('minerales'),
  zonas: leer('zonas'),
  misiones: leer('misiones'),
  economia: leer('economia'),
  esquema: leer('esquema'),
}

describe('números', () => {
  it('lee coma y punto', () => {
    expect(leerNumero('1,5')).toBe(1.5)
    expect(leerNumero('1.5')).toBe(1.5)
    expect(leerNumero('1.234,5')).toBe(1234.5)
    expect(leerNumero(' -3 ')).toBe(-3)
    expect(leerNumero('abc')).toBeNull()
    expect(leerNumero('')).toBeNull()
  })
})

describe('documento mínimo', () => {
  it('lee los valores base', () => {
    expect(valorBase(datos, ['enemies', 'rat', 'hp'])).toBe(12)
    expect(valorBase(datos, ['economy', 'arenaRewardBase'])).toBe(16)
    expect(valorBase(datos, ['economy', 'continentLootWeights', '0'])).toBe(35)
    expect(valorBase(datos, ['parts', 'head.sword.copper', 'stats', 'attack'])).toBe(9)
    expect(valorBase(datos, ['parts', 'head.sword.copper', 'stats', 'regen'])).toBe(0)
    expect(valorBase(datos, ['spawns', 'south.1'])).toBe('rat')
    expect(valorBase(datos, ['enemies', 'rat', 'storyHPMultiplier'])).toBeUndefined()
    expect(valorBase(datos, ['enemies', 'nadie', 'hp'])).toBeUndefined()
  })

  it('guarda solo lo distinto del base y quita lo que vuelve al base', () => {
    let d: GameTuning = {}
    d = ponerValor(d, datos, ['enemies', 'rat', 'hp'], 15)
    expect(d).toEqual({ enemies: { rat: { hp: 15 } } })
    d = ponerValor(d, datos, ['enemies', 'rat', 'hp'], 12)
    expect(d).toEqual({})
    d = ponerValor(d, datos, ['parts', 'head.sword.copper', 'stats', 'attack'], 10)
    d = ponerValor(d, datos, ['parts', 'head.sword.copper', 'price'], 28)
    expect(d).toEqual({ parts: { 'head.sword.copper': { stats: { attack: 10 }, price: 28 } } })
    d = restaurar(d, datos, ['parts', 'head.sword.copper', 'stats', 'attack'])
    expect(d).toEqual({ parts: { 'head.sword.copper': { price: 28 } } })
    expect(contarAjustes(d)).toBe(1)
  })

  it('la lista de pesos del continente se guarda entera', () => {
    let d = ponerValor({}, datos, ['economy', 'continentLootWeights', '2'], 25)
    expect(d.economy?.continentLootWeights).toEqual([35, 27, 25, 12, 6])
    expect(valorEfectivo(d, datos, ['economy', 'continentLootWeights', '2'])).toBe(25)
    expect(estaAjustado(d, datos, ['economy', 'continentLootWeights', '2'])).toBe(true)
    expect(estaAjustado(d, datos, ['economy', 'continentLootWeights', '1'])).toBe(false)
    d = restaurar(d, datos, ['economy', 'continentLootWeights', '2'])
    expect(d).toEqual({})
  })

  it('los minerales de una recompensa sustituyen a todos y sin ceros', () => {
    const base = valorBase(datos, ['rescues', 'marta', 'minerals'])
    expect(base).toEqual({ copper: 3, iron: 1 })
    let d = ponerValor({}, datos, ['rescues', 'marta', 'minerals'], { copper: 3, iron: 1, gold: 0 })
    expect(d).toEqual({})
    d = ponerValor({}, datos, ['rescues', 'marta', 'minerals'], { copper: 3, iron: 0 })
    expect(d).toEqual({ rescues: { marta: { minerals: { copper: 3 } } } })
  })

  it('minimiza un documento importado', () => {
    const d = minimizar({ schemaVersion: 1, note: 'x', enemies: { rat: { hp: 12, damage: 4 } }, economy: { wallWave: 20 } }, datos)
    expect(d).toEqual({ enemies: { rat: { damage: 4 } } })
  })
})

describe('validación con esquema.json', () => {
  it('rangos y enteros', () => {
    const cd = campoDe(datos, ['enemies', 'rat', 'attackCooldown'])!
    expect(validarValor(cd, 0.5)).toMatch(/rango/)
    expect(validarValor(cd, 1)).toBeNull()
    const lvl = campoDe(datos, ['enemies', 'rat', 'level'])!
    expect(validarValor(lvl, 2.5)).toMatch(/entero/)
    expect(ajustarAlRango(lvl, 70)).toEqual({ valor: 60, recortado: true })
    expect(campoDe(datos, ['parts', 'x', 'stats', 'lifesteal'])?.max).toBe(0.2)
    expect(campoDe(datos, ['economy', 'continentLootWeights', '0'])?.max).toBe(100)
  })

  it('avisa como el juego', () => {
    const avisos = validarDocumento(({
      enemies: { dragon: { hp: 1 }, goblin: { dmg: 3 }, rat: { attackCooldown: 0.2, storyHPMultiplier: 2 } },
      economy: { wallWave: 22.5 },
      spawns: { 'bakery.4': 'rat', 'south.1': 'ratKing' },
      dungeons: { 'valdemar.cripta': { waves: [{ ratKing: 2 }] } },
    } as unknown) as GameTuning, datos)
    const texto = avisos.join('\n')
    expect(texto).toMatch(/enemies.dragon: monstruo desconocido/)
    expect(texto).toMatch(/enemies.goblin.dmg: campo desconocido/)
    expect(texto).toMatch(/enemies.rat.attackCooldown/)
    expect(texto).toMatch(/enemies.rat.storyHPMultiplier: solo vale para jefes/)
    expect(texto).toMatch(/economy.wallWave.*entero/)
    expect(texto).toMatch(/spawns.bakery.4: los jefes/)
    expect(texto).toMatch(/spawns.south.1: los jefes/)
    expect(texto).toMatch(/oleada 1 se queda sin monstruos/)
  })

  it('avisa si una misión de "mata N" se queda sin sus monstruos', () => {
    const huertos = datos.zonas.areas.find((a) => a.id === 'valdemar.huertos')!
    const spawns: Record<string, string> = {}
    for (const z of huertos.zonas) for (const s of z.spawns) if (s.enemyID === 'zombieFarmer') spawns[s.id] = 'rat'
    for (const s of huertos.fueraDeZona) if (s.enemyID === 'zombieFarmer') spawns[s.id] = 'rat'
    expect(Object.keys(spawns).length).toBeGreaterThan(0)
    expect(validarDocumento({ spawns }, datos).join('\n')).toMatch(/valdemar.molino/)
    expect(validarDocumento({}, datos)).toEqual([])
  })
})

describe('diferencias', () => {
  it('igual que panel_diff: hojas por clave y listas por posición', () => {
    const a = { enemies: { rat: { hp: 15 } }, economy: { continentLootWeights: [35, 27, 20, 12, 6] } }
    const b = { enemies: { rat: { hp: 18 }, goblin: { damage: 6 } }, economy: { continentLootWeights: [35, 27, 25, 12, 6] } }
    expect(diferencias(a, b)).toEqual([
      { path: 'economy/continentLootWeights/2', before: 20, after: 25 },
      { path: 'enemies/goblin', before: null, after: { damage: 6 } },
      { path: 'enemies/rat/hp', before: 15, after: 18 },
    ])
  })

  it('abre los valores enteros comparando con el base (solo lo que cambia)', () => {
    const waves: Record<string, number>[] = [{ ghoul: 3, skeleton: 5, skeletonArcher: 2 }, { cultist: 2, eclipseAcolyte: 2, fireSlime: 1, gargoyle: 2, wraith: 3 }]
    const cs = expandir([{ path: 'dungeons/valdemar.cripta', before: null, after: { waves } }], datos)
    expect(cs.every((c) => c.path.startsWith('dungeons/valdemar.cripta/waves/2/'))).toBe(true)
    expect(cs.every((c) => c.after === null)).toBe(true)
    expect(dentroDeValorEntero('dungeons/valdemar.cripta/waves/2/ghoul')).toBe(true)
    expect(dentroDeValorEntero('enemies/rat/hp')).toBe(false)
    const pesos = expandir([{ path: 'economy', before: null, after: { continentLootWeights: [30, 27, 20, 12, 6] } }], datos)
    expect(pesos).toEqual([{ path: 'economy/continentLootWeights/0', before: 35, after: 30 }])
  })

  it('describe las rutas en español con su valor base', () => {
    const c = describir(datos, { path: 'enemies/rat/hp', before: null, after: 15 })
    expect(c.apartadoNombre).toBe('Monstruos')
    expect(c.objeto).toBe('Rata de alcantarilla')
    expect(c.campo).toBe('Vida')
    expect(c.base).toBe(12)
    const s = describir(datos, { path: 'parts/head.sword.copper/stats/attack', before: null, after: 10 })
    expect(s.campo).toBe('Ataque')
    expect(s.base).toBe(9)
  })
})

describe('edición masiva', () => {
  it('+10 % de vida a los monstruos del Pedregal (sin jefes)', () => {
    const [tabla] = tablasDe(datos, 'enemigos')
    const filas = filtrarFilas(tabla.filas, '', { area: 'valdemar.pedregal', jefe: 'no' })
    expect(filas.length).toBeGreaterThan(0)
    const objetivos = filas.map((f) => f.celdas.hp!).map((c) => ({ ruta: c.ruta, campo: c.campo }))
    const r = aplicarMasivo({}, datos, objetivos, { tipo: 'porcentaje', valor: 10 })
    expect(r.cambiados).toBe(filas.length)
    for (const f of filas) {
      const base = valorBase(datos, ['enemies', f.id, 'hp']) as number
      expect(obtener(r.doc, ['enemies', f.id, 'hp'])).toBeCloseTo(base * 1.1, 5)
    }
    // Repetirlo "desde el base" da lo mismo; "desde el actual" acumula.
    const otra = aplicarMasivo(r.doc, datos, objetivos, { tipo: 'porcentaje', valor: 10 }, 'base')
    expect(otra.doc).toEqual(r.doc)
  })

  it('precio ×0,8 a las piezas T1: enteros redondeados', () => {
    const [tabla] = tablasDe(datos, 'piezas')
    const filas = filtrarFilas(tabla.filas, '', { tier: '1' })
    const objetivos = filas.map((f) => f.celdas.price!).map((c) => ({ ruta: c.ruta, campo: c.campo }))
    const r = aplicarMasivo({}, datos, objetivos, { tipo: 'multiplicar', valor: 0.8 })
    for (const f of filas) {
      const v = valorEfectivo(r.doc, datos, ['parts', f.id, 'price']) as number
      expect(Number.isInteger(v)).toBe(true)
    }
    expect(validarDocumento(r.doc, datos)).toEqual([])
  })

  it('recorta al rango y lo cuenta', () => {
    const c = campoDe(datos, ['enemies', 'rat', 'attackCooldown'])!
    const r = aplicarMasivo({}, datos, [{ ruta: ['enemies', 'rat', 'attackCooldown'], campo: c }], { tipo: 'multiplicar', valor: 0.1 })
    expect(r.recortados).toBe(1)
    expect(obtener(r.doc, ['enemies', 'rat', 'attackCooldown'])).toBe(0.8)
  })

  it('restaurar una fila entera', () => {
    const [tabla] = tablasDe(datos, 'zonas')
    const fila = tabla.filas.find((f) => f.id === 'zona:south')!
    let d = ponerValor({}, datos, ['zones', 'south', 'level'], 3)
    d = ponerValor(d, datos, ['spawns', 'south.1'], 'goblin')
    for (const ruta of rutasDeFila(fila)) d = restaurar(d, datos, ruta)
    expect(d).toEqual({})
  })
})

describe('borrador de ejemplo para el juego', () => {
  it('es válido y se puede exportar', () => {
    let d: GameTuning = {}
    const [enemigos] = tablasDe(datos, 'enemigos')
    const pedregal = filtrarFilas(enemigos.filas, '', { area: 'valdemar.pedregal', jefe: 'no' })
    d = aplicarMasivo(d, datos, pedregal.map((f) => ({ ruta: f.celdas.hp!.ruta, campo: f.celdas.hp!.campo })), { tipo: 'porcentaje', valor: 10 }).doc
    const [piezas] = tablasDe(datos, 'piezas')
    const t1 = filtrarFilas(piezas.filas, '', { tier: '1' })
    d = aplicarMasivo(d, datos, t1.map((f) => ({ ruta: f.celdas.price!.ruta, campo: f.celdas.price!.campo })), { tipo: 'multiplicar', valor: 0.8 }).doc
    d = ponerValor(d, datos, ['enemies', 'ogre', 'storyHPMultiplier'], 1.5)
    d = ponerValor(d, datos, ['parts', 'head.dagger.copper', 'stats', 'attack'], 7)
    d = ponerValor(d, datos, ['armor', 'helm.knight', 'price'], 25)
    d = ponerValor(d, datos, ['minerals', 'ruby', 'value'], 30)
    d = ponerValor(d, datos, ['minerals', 'ruby', 'stats', 'critChance'], 0.035)
    d = ponerValor(d, datos, ['zones', 'south', 'level'], 2)
    d = ponerValor(d, datos, ['areas', 'bakery', 'level'], 3)
    d = ponerValor(d, datos, ['spawns', 'south.1'], 'goblin')
    d = ponerValor(d, datos, ['dungeons', 'valdemar.cripta', 'level'], 9)
    d = ponerValor(d, datos, ['dungeons', 'valdemar.cripta', 'waves'], [{ skeleton: 6, ghoul: 2 }, { wraith: 3, gargoyle: 2 }])
    d = ponerValor(d, datos, ['quests', 'valdemar.caza_mayor', 'gold'], 70)
    d = ponerValor(d, datos, ['quests', 'valdemar.caza_mayor', 'minerals'], { iron: 3, silver: 1 })
    d = ponerValor(d, datos, ['rescues', 'marta', 'gold'], 40)
    d = ponerValor(d, datos, ['roulette', 'masterwork', 'weight'], 6)
    d = ponerValor(d, datos, ['economy', 'arenaStartingGold'], 70)
    d = ponerValor(d, datos, ['economy', 'mineralDropRate'], 0.2)
    d = ponerValor(d, datos, ['economy', 'continentLootWeights', '0'], 30)
    expect(validarDocumento(d, datos)).toEqual([])
    const final = documentoFinal(d, 'Ejemplo del panel: Pedregal +10 % vida, piezas T1 ×0,8')
    expect(final.schemaVersion).toBe(1)
    const destino = process.env.EXPORTAR_EJEMPLO
    if (destino) writeFileSync(destino, JSON.stringify(final, null, 2))
  })
})
