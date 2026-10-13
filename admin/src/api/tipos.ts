// Tipos de lo que devuelve la API de Supabase del panel (backend/README.md, "Referencia de la API para la web").

import type { Cambio } from '../logica/diff'
import type { GameTuning } from '../tipos/tuning'

export type EstadoConfig = 'draft' | 'published' | 'archived'

export interface FilaConfig {
  id: number
  version: number | null
  status: EstadoConfig
  data: GameTuning
  schema_version: number
  note: string | null
  created_by: string | null
  created_at: string
  updated_at: string
  published_at: string | null
  published_by: string | null
}

export interface ConfigPublicada {
  version: number
  schema_version: number
  data: GameTuning
  published_at: string
}

export interface DiffServidor {
  from_version: number | null
  schema_version_before: number | null
  schema_version_after: number
  changes: Cambio[]
  total: number
  truncated: boolean
}

export interface Auditoria {
  id: number
  created_at: string
  actor: string | null
  actor_name: string | null
  action: string
  config_id: number | null
  version: number | null
  summary: string
  diff: {
    from_version?: number | null
    restored_version?: number | null
    changes?: Cambio[]
    total?: number
    truncated?: boolean
  } | null
}

export interface Resumen {
  generated_at: string
  accounts: number
  accounts_with_characters: number
  characters: number
  active_last_24h: number
  active_last_7d: number
  by_race: Record<string, number>
  by_level: { level: number; characters: number }[]
  by_race_and_level: { race: string; level: number; characters: number }[]
  gold: { average: number; median: number; max: number; by_level: { level: number; average: number }[] }
  arena: {
    record: number | null
    players: number
    average_best_wave: number | null
    top: { wave: number; character: string; username: string | null; race: string; level: number }[]
  }
  story: {
    average_quests_done: number
    quests_done_distribution: { quests_done: number; characters: number }[]
    quests: { quest: string; accepted: number; done: number }[]
    dungeons_won: { dungeon: string; characters: number }[]
    princess_rescued: number
    average_villagers_rescued: number
    by_area: { area: string; characters: number }[]
  }
  /** Solo en modo demo: datos inventados. */
  ejemplo?: boolean
}

export interface FilaPersonaje {
  id: string
  name: string
  username: string | null
  race: string
  level: number
  gold: number
  arena_best_wave: number | null
  quests_done: number
  area: string
  version: number
  created_at: string
  updated_at: string
}

export interface FichaPersonaje {
  id: string
  name: string
  username: string | null
  data: Record<string, unknown>
  version: number
  created_at: string
  updated_at: string
}

export interface Sesion {
  usuario: string
  email: string
}

/** Error con un mensaje en español listo para enseñar. */
export class ErrorPanel extends Error {
  readonly codigo: string
  constructor(codigo: string, mensaje: string) {
    super(mensaje)
    this.codigo = codigo
  }
}

export interface PanelApi {
  readonly modo: 'supabase' | 'demo'
  sesion(): Promise<Sesion | null>
  entrar(usuario: string, contrasena: string): Promise<Sesion>
  salir(): Promise<void>
  esAdmin(): Promise<boolean>
  publicada(): Promise<ConfigPublicada | null>
  configs(): Promise<FilaConfig[]>
  crearBorrador(data: GameTuning, nota: string | null): Promise<FilaConfig>
  guardarBorrador(id: number, data: GameTuning, nota: string | null): Promise<FilaConfig>
  borrarBorrador(id: number): Promise<void>
  diff(id: number): Promise<DiffServidor>
  publicar(id: number): Promise<FilaConfig>
  volverA(version: number): Promise<FilaConfig>
  auditoria(limite?: number): Promise<Auditoria[]>
  resumen(): Promise<Resumen>
  personajes(busqueda: string, pagina: number, tamano: number): Promise<FilaPersonaje[]>
  personaje(id: string): Promise<FichaPersonaje | null>
}
