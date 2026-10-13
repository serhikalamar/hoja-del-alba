// Tipos de los JSON de valores base que genera `make datos` en admin/public/data/.
// Los valores ajustables van siempre en `base`, con las mismas claves que el contrato GameTuning.

import type { ArmorTuning, Cuentas, DungeonTuning, EconomyTuning, EnemyTuning, MineralTuning, PartTuning, QuestTuning, RescueTuning, RouletteTuning } from './tuning'

export interface Cabecera { generado: string; schemaVersion: number; nota?: string }

export interface AparicionEnArea {
  area: string
  nombreArea: string
  zona: string | null
  nombreZona: string | null
  nivel: number
  spawns: string[]
}
export interface AparicionEnMazmorra { id: string; nombre: string; nivel: number; jefe: boolean; oleadas: number[] }
export interface Enlace { id: string; nombre: string }

export interface Enemigo {
  id: string
  nombre: string
  familia: string
  comportamiento: string
  nombreComportamiento: string
  jefe: boolean
  escala: number
  radio: number
  base: Required<Pick<EnemyTuning, 'hp' | 'damage' | 'speed' | 'attackCooldown' | 'attackRange' | 'level' | 'dropChance' | 'dropRolls' | 'xpMultiplier' | 'goldMultiplier'>> & EnemyTuning
  areas: AparicionEnArea[]
  mazmorras: AparicionEnMazmorra[]
  misiones: string[]
  arena: boolean
  arenaPrimeraOleada?: number
  arenaOleadasDeJefe?: number[]
  pieza?: Enlace
  piezaHistoria?: Enlace
}
export interface DatosEnemigos extends Cabecera { enemigos: Enemigo[] }

export interface OrigenPieza { tipo: string; jefe?: string; nombreJefe?: string; npc?: string; nombreNpc?: string }
export interface Pieza {
  id: string
  nombre: string
  hueco: string
  nombreHueco: string
  forma: string
  material: string
  grupo: string
  unica: boolean
  elementos: string[]
  habilidad?: Enlace
  origen: OrigenPieza
  base: Required<Pick<PartTuning, 'price' | 'tier'>> & { stats: Record<string, number> }
}
export interface Armadura {
  id: string
  nombre: string
  hueco: string
  nombreHueco: string
  tipoMaterial: string
  materiales: { id: string; nombre: string; tier: number }[]
  base: Required<Pick<ArmorTuning, 'price'>> & { stats: Record<string, number> }
}
export interface Material { id: string; nombre: string; tier: number; poder: number; elemento: string }
export interface DatosPiezas extends Cabecera { piezas: Pieza[]; armaduras: Armadura[]; materiales: Material[] }

export interface Mineral {
  id: string
  nombre: string
  rareza: number
  continentes: string[]
  base: Required<Pick<MineralTuning, 'value' | 'dropWeight'>> & { stats: Record<string, number> }
}
export interface FamiliaMinerales { continente: string; nombre: string; minerales: { id: string; peso: number }[] }
export interface DatosMinerales extends Cabecera { minerales: Mineral[]; familias: FamiliaMinerales[] }

export interface Spawn { id: string; enemyID: string; nombre: string; jefe: boolean }
export interface Zona { id: string; nombre: string; base: { level: number }; spawns: Spawn[] }
export interface Area {
  id: string
  nombre: string
  tipo: string
  nombreTipo: string
  continente: string
  base: { level: number }
  zonas: Zona[]
  fueraDeZona: Spawn[]
  rescates: Enlace[]
  mazmorras: string[]
}
export interface Continente { id: string; nombre: string; tier: number; niveles: number[]; areas: string[]; minerales: string[] }
export interface Mazmorra {
  id: string
  nombre: string
  area: string
  jefe: string | null
  nombreJefe: string | null
  piso: string
  repetible: boolean
  base: { level: number; waves: Cuentas[]; bossEscort: Cuentas } & DungeonTuning
}
export interface OleadaArena {
  oleada: number
  piso: string
  tier: number
  nivelEnemigos: number
  jefe: boolean
  forja: boolean
  nivelForja: number | null
  oro: number
  spawns: Cuentas
}
export interface DatosZonas extends Cabecera { continentes: Continente[]; areas: Area[]; mazmorras: Mazmorra[]; arena: OleadaArena[] }

export interface Mision {
  id: string
  titulo: string
  resumen: string
  daMision: string
  nombreDaMision: string
  objetivos: string[]
  areas: string[]
  monstruos: string[]
  base: Required<Pick<QuestTuning, 'xp' | 'gold'>> & { minerals: Record<string, number> }
}
export interface RescateMision {
  id: string
  nombre: string
  papel: string
  area: string
  nombreArea: string
  pieza?: Enlace
  base: Required<Pick<RescueTuning, 'gold'>> & { minerals: Record<string, number> }
}
export interface DatosMisiones extends Cabecera { misiones: Mision[]; rescates: RescateMision[] }

export interface CasillaRuleta {
  id: string
  nombre: string
  rareza: string
  suerte: number
  base: Required<RouletteTuning>
}
export interface DatosEconomia extends Cabecera {
  base: Required<EconomyTuning>
  ruleta: CasillaRuleta[]
  tablas: {
    xpParaSubir: { nivel: number; xp: number }[]
    oroArenaPorOleada: { oleada: number; oro: number }[]
    nivelEnemigosArena: { oleada: number; nivel: number }[]
  }
}

export interface CampoEsquema {
  clave: string
  tipo: string // "número" | "entero" | "lista de 5 números"
  min: number
  max: number
  descripcion: string
  codigo: string
}
export interface ApartadoEsquema {
  descripcion: string
  clave?: string
  campos?: CampoEsquema[]
  mapas?: Record<string, string>
  valor?: string
}
export interface EstadisticaEsquema extends CampoEsquema { nombre: string }
export interface DatosEsquema extends Cabecera {
  apartados: Record<string, ApartadoEsquema>
  estadisticas: EstadisticaEsquema[]
  documento: Record<string, string>
  reglas: string[]
}

/** Todos los datos base juntos. */
export interface DatosBase {
  enemigos: DatosEnemigos
  piezas: DatosPiezas
  minerales: DatosMinerales
  zonas: DatosZonas
  misiones: DatosMisiones
  economia: DatosEconomia
  esquema: DatosEsquema
}
