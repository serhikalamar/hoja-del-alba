// Modo demo (sin Supabase configurado): solo lectura. Nada se guarda en ningún servidor.
// El resumen y los jugadores son DATOS INVENTADOS para ver cómo queda el panel (se avisa en pantalla).

import {
  ErrorPanel, type Auditoria, type ConfigPublicada, type DiffServidor, type FichaPersonaje, type FilaConfig,
  type FilaPersonaje, type PanelApi, type Resumen, type Sesion,
} from './tipos'

const soloLectura = () =>
  Promise.reject(new ErrorPanel('demo', 'Modo demo: no hay Supabase configurado, así que no se puede guardar ni publicar. Exporta el JSON para probarlo en local.'))

/** Generador pseudoaleatorio fijo (los datos de ejemplo salen siempre iguales). */
function aleatorio(semilla: number) {
  let s = semilla
  return () => {
    s = (s * 1664525 + 1013904223) % 4294967296
    return s / 4294967296
  }
}

const RAZAS = ['human', 'dwarf', 'elf', 'werewolf']
const NOMBRES = ['Aldric', 'Brisa', 'Corvo', 'Dalia', 'Eldor', 'Fina', 'Garra', 'Hilda', 'Iker', 'Juno', 'Kael', 'Lia',
  'Mor', 'Nerea', 'Odo', 'Pía', 'Quim', 'Rhea', 'Sauce', 'Tor', 'Ulla', 'Vela', 'Wren', 'Xan', 'Yago', 'Zoe']
const AREAS = ['town', 'valdemar.huertos', 'valdemar.robleda', 'valdemar.abadia', 'valdemar.pedregal', 'castle', 'inn']
const MISIONES = ['valdemar.liberar', 'valdemar.molino', 'valdemar.caza_mayor', 'valdemar.hilos', 'valdemar.alcalde',
  'valdemar.pociones', 'valdemar.abadia', 'valdemar.pedregal', 'valdemar.rey_goblin']

function personajesDeEjemplo(): FilaPersonaje[] {
  const r = aleatorio(7)
  const ahora = Date.parse('2026-10-13T20:00:00Z')
  return Array.from({ length: 64 }, (_, i) => {
    const level = Math.max(1, Math.min(60, Math.round(1 + r() * r() * 22)))
    const hechas = Math.min(MISIONES.length, Math.floor(level / 2.2))
    return {
      id: `00000000-0000-4000-8000-${String(i).padStart(12, '0')}`,
      name: `${NOMBRES[i % NOMBRES.length]}${i >= NOMBRES.length ? ` ${Math.floor(i / NOMBRES.length) + 1}` : ''}`,
      username: `jugador${Math.floor(i / 2) + 1}`,
      race: RAZAS[Math.floor(r() * RAZAS.length)],
      level,
      gold: Math.round(level * 40 + r() * level * 60),
      arena_best_wave: r() < 0.7 ? Math.max(1, Math.round(level * 1.4 + r() * 8)) : null,
      quests_done: hechas,
      area: AREAS[Math.min(AREAS.length - 1, Math.floor(level / 3))],
      version: 1 + Math.floor(r() * 80),
      created_at: new Date(ahora - (20 + r() * 40) * 86400000).toISOString(),
      updated_at: new Date(ahora - r() * r() * 14 * 86400000).toISOString(),
    }
  })
}

function resumenDeEjemplo(ps: FilaPersonaje[]): Resumen {
  const ahora = Date.parse('2026-10-13T20:00:00Z')
  const cuenta = <K extends string | number>(xs: K[]) => {
    const m = new Map<K, number>()
    for (const x of xs) m.set(x, (m.get(x) ?? 0) + 1)
    return m
  }
  const porNivel = cuenta(ps.map((p) => p.level))
  const oroNivel = new Map<number, number[]>()
  for (const p of ps) oroNivel.set(p.level, [...(oroNivel.get(p.level) ?? []), p.gold])
  const oros = ps.map((p) => p.gold).sort((a, b) => a - b)
  const arena = ps.filter((p) => p.arena_best_wave !== null)
  const top = [...arena].sort((a, b) => (b.arena_best_wave ?? 0) - (a.arena_best_wave ?? 0)).slice(0, 10)
  const qd = cuenta(ps.map((p) => p.quests_done))
  return {
    ejemplo: true,
    generated_at: new Date(ahora).toISOString(),
    accounts: 41,
    accounts_with_characters: 32,
    characters: ps.length,
    active_last_24h: ps.filter((p) => ahora - Date.parse(p.updated_at) < 86400000).length,
    active_last_7d: ps.filter((p) => ahora - Date.parse(p.updated_at) < 7 * 86400000).length,
    by_race: Object.fromEntries(cuenta(ps.map((p) => p.race))),
    by_level: [...porNivel.entries()].sort((a, b) => a[0] - b[0]).map(([level, characters]) => ({ level, characters })),
    by_race_and_level: [],
    gold: {
      average: Math.round(oros.reduce((a, b) => a + b, 0) / oros.length),
      median: oros[Math.floor(oros.length / 2)],
      max: oros[oros.length - 1],
      by_level: [...oroNivel.entries()].sort((a, b) => a[0] - b[0]).map(([level, xs]) => ({ level, average: Math.round(xs.reduce((a, b) => a + b, 0) / xs.length) })),
    },
    arena: {
      record: top[0]?.arena_best_wave ?? null,
      players: arena.length,
      average_best_wave: Math.round((arena.reduce((a, p) => a + (p.arena_best_wave ?? 0), 0) / arena.length) * 10) / 10,
      top: top.map((p) => ({ wave: p.arena_best_wave ?? 0, character: p.name, username: p.username, race: p.race, level: p.level })),
    },
    story: {
      average_quests_done: Math.round((ps.reduce((a, p) => a + p.quests_done, 0) / ps.length) * 10) / 10,
      quests_done_distribution: [...qd.entries()].sort((a, b) => a[0] - b[0]).map(([quests_done, characters]) => ({ quests_done, characters })),
      quests: MISIONES.map((q, i) => ({
        quest: q,
        accepted: ps.filter((p) => p.quests_done >= i).length,
        done: ps.filter((p) => p.quests_done > i).length,
      })),
      dungeons_won: [
        { dungeon: 'valdemar.calabozos', characters: 9 },
        { dungeon: 'valdemar.cripta', characters: 14 },
      ],
      princess_rescued: ps.filter((p) => p.quests_done >= 9).length,
      average_villagers_rescued: 3.4,
      by_area: [...cuenta(ps.map((p) => p.area)).entries()].sort((a, b) => b[1] - a[1]).map(([area, characters]) => ({ area, characters })),
    },
  }
}

export class ApiDemo implements PanelApi {
  readonly modo = 'demo' as const
  private readonly ps = personajesDeEjemplo()

  sesion(): Promise<Sesion | null> { return Promise.resolve(null) }
  entrar(): Promise<Sesion> { return soloLectura() }
  salir(): Promise<void> { return Promise.resolve() }
  esAdmin(): Promise<boolean> { return Promise.resolve(false) }
  publicada(): Promise<ConfigPublicada | null> { return Promise.resolve(null) }
  configs(): Promise<FilaConfig[]> { return Promise.resolve([]) }
  crearBorrador(): Promise<FilaConfig> { return soloLectura() }
  guardarBorrador(): Promise<FilaConfig> { return soloLectura() }
  borrarBorrador(): Promise<void> { return soloLectura() }
  diff(): Promise<DiffServidor> { return soloLectura() }
  publicar(): Promise<FilaConfig> { return soloLectura() }
  volverA(): Promise<FilaConfig> { return soloLectura() }
  auditoria(): Promise<Auditoria[]> { return Promise.resolve([]) }
  resumen(): Promise<Resumen> { return Promise.resolve(resumenDeEjemplo(this.ps)) }

  personajes(busqueda: string, pagina: number, tamano: number): Promise<FilaPersonaje[]> {
    const b = busqueda.trim().toLowerCase()
    const filtrados = this.ps
      .filter((p) => !b || p.name.toLowerCase().includes(b) || (p.username ?? '').includes(b))
      .sort((a, c) => c.updated_at.localeCompare(a.updated_at))
    return Promise.resolve(filtrados.slice(pagina * tamano, (pagina + 1) * tamano))
  }

  personaje(id: string): Promise<FichaPersonaje | null> {
    const p = this.ps.find((x) => x.id === id)
    if (!p) return Promise.resolve(null)
    return Promise.resolve({
      id: p.id,
      name: p.name,
      username: p.username,
      version: p.version,
      created_at: p.created_at,
      updated_at: p.updated_at,
      data: {
        name: p.name,
        race: p.race,
        level: p.level,
        xp: p.level * 37,
        gold: p.gold,
        arenaBestWave: p.arena_best_wave,
        currentAreaID: p.area,
        minerals: { copper: 12, iron: 5, silver: 2 },
        quests: Object.fromEntries(MISIONES.slice(0, p.quests_done + 1).map((q, i) => [q, { accepted: true, done: i < p.quests_done }])),
        townProgress: { rescued: ['marta', 'elena'].slice(0, Math.min(2, p.quests_done)), princessRescued: p.quests_done >= 9 },
        wonDungeons: p.quests_done >= 6 ? ['valdemar.cripta'] : [],
        defeatedBosses: p.quests_done >= 2 ? ['ogre'] : [],
        inventory: [],
        ejemplo: 'datos inventados (modo demo)',
      },
    })
  }
}
