// Tipos del documento de ajustes `GameTuning` (contrato: assets/admin/contrato.md).
// Todo es opcional: solo cambia lo que viene. El juego valida y recorta otra vez al aplicarlo.

export const SCHEMA_VERSION = 1

export const CLAVES_STATS = [
  'maxHP', 'attack', 'defense', 'attackSpeed', 'range', 'moveSpeed',
  'critChance', 'critMultiplier', 'lifesteal', 'goldBonus', 'regen',
] as const
export type ClaveStat = (typeof CLAVES_STATS)[number]
export type MapaStats = Partial<Record<ClaveStat, number>>

/** id de monstruo → cuántos. */
export type Cuentas = Record<string, number>

export interface EnemyTuning {
  hp?: number
  damage?: number
  speed?: number
  attackCooldown?: number
  attackRange?: number
  level?: number
  dropChance?: number
  dropRolls?: number
  xpMultiplier?: number
  goldMultiplier?: number
  storyHPMultiplier?: number
  storyDamageMultiplier?: number
}

export interface PartTuning { stats?: MapaStats; price?: number; tier?: number }
export interface ArmorTuning { stats?: MapaStats; price?: number }
export interface MineralTuning { value?: number; dropWeight?: number; stats?: MapaStats }
export interface LevelTuning { level?: number }
export interface DungeonTuning { level?: number; waves?: Cuentas[]; bossEscort?: Cuentas }
export interface QuestTuning { xp?: number; gold?: number; minerals?: Record<string, number> }
export interface RescueTuning { gold?: number; minerals?: Record<string, number> }
export interface RouletteTuning { weight?: number; multiplier?: number }

export interface EconomyTuning {
  mineralDropRate?: number
  continentLootWeights?: number[]
  arenaStartingGold?: number
  arenaRewardBase?: number
  arenaRewardPerWave?: number
  arenaWavesPerShopLevel?: number
  wallWave?: number
  arenaBossXPMultiplier?: number
  storyBossXPMultiplier?: number
  respawningXPMultiplier?: number
  xpCurveBase?: number
  xpCurveExponent?: number
  xpCurveFlat?: number
  levelHPGrowth?: number
  levelAttackGrowth?: number
  levelDefensePerLevel?: number
  enemyHPPerLevel?: number
  enemyHPDifficulty?: number
  enemyDamagePerLevel?: number
  enemyDamageDifficulty?: number
  enemySpeedPerLevel?: number
  storyKillGoldBase?: number
  storyKillGoldLevelsPerCoin?: number
  storyBossGoldPerLevel?: number
  storyZoneGoldPerLevel?: number
  storyDungeonRepeatPartChance?: number
  forgeGoldBase?: number
  forgeGoldPerTier?: number
  rerollBaseCost?: number
  rerollCostStep?: number
  potionBasePrice?: number
  potionPricePerLevel?: number
  potionHeal?: number
}

export interface GameTuning {
  schemaVersion?: number
  version?: number
  note?: string
  enemies?: Record<string, EnemyTuning>
  parts?: Record<string, PartTuning>
  armor?: Record<string, ArmorTuning>
  minerals?: Record<string, MineralTuning>
  areas?: Record<string, LevelTuning>
  zones?: Record<string, LevelTuning>
  /** id de spawn → id de monstruo */
  spawns?: Record<string, string>
  dungeons?: Record<string, DungeonTuning>
  quests?: Record<string, QuestTuning>
  rescues?: Record<string, RescueTuning>
  roulette?: Record<string, RouletteTuning>
  economy?: EconomyTuning
}

/** Apartados del documento (sin los metadatos schemaVersion/version/note). */
export const APARTADOS = [
  'enemies', 'parts', 'armor', 'minerals', 'areas', 'zones', 'spawns',
  'dungeons', 'quests', 'rescues', 'roulette', 'economy',
] as const
export type Apartado = (typeof APARTADOS)[number]

/** Ruta a un valor dentro del documento, p. ej. ['enemies', 'rat', 'hp'] o ['parts', id, 'stats', 'attack']. */
export type Ruta = string[]

/** Cualquier valor JSON. */
export type Json = null | boolean | number | string | Json[] | { [k: string]: Json }
