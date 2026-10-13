import Foundation

/// Arena de oleadas infinitas, cada vez más difíciles.
/// - Cada 2 oleadas: forja del enano y ritual.
/// - Cada 5 oleadas: jefe y se baja un piso de la mazmorra.
public enum Arena {
    /// Oleadas entre una visita a la forja y la siguiente.
    public static let shopEvery = 2
    /// Oleadas con el mismo escenario (y cada cuántas sale un jefe).
    public static let stageLength = 5

    /// Oleada a partir de la cual los enemigos suben un nivel por oleada (el muro: con el equipo al máximo
    /// solo aguanta quien lo ha mejorado bien y va sobrado de nivel). 20 de serie (`economy.wallWave`).
    public static var wallWave: Int { Int(TunedData.current.economy.wallWave) }

    /// Nivel de dificultad de los enemigos: nivel 1 en las 5 primeras oleadas (para forjar la primera arma),
    /// luego sube 3 niveles cada 5 oleadas hasta la `wallWave` (nivel 10) y, desde ahí, 2 por oleada
    /// (más deprisa de lo que sube el héroe: es el muro). No tiene tope.
    /// 1-5 → 1 · 6 → 2 · 8 → 3 · 10 → 4 · 15 → 7 · 20 → 10 · 22 → 14 · 25 → 20.
    public static func enemyLevel(wave: Int) -> Int {
        let w = max(1, wave)
        let base = 1 + max(0, min(w, wallWave) - 4) * 3 / 5
        return base + 2 * max(0, w - wallWave)
    }

    /// Tier del bestiario disponible (qué enemigos pueden salir), de 1 a 10.
    public static func tier(wave: Int) -> Int {
        min(10, 1 + (max(1, wave) - 1) / 2)
    }

    /// Piso de la mazmorra en la oleada: se baja uno cada `stageLength` oleadas y, tras el último, se vuelve al primero.
    public static func floor(wave: Int) -> DungeonFloor {
        Dungeon.floors[(depth(wave: wave) - 1) % Dungeon.floors.count]
    }

    /// Profundidad (piso 1, 2, 3…): no tiene tope aunque los pisos se repitan.
    public static func depth(wave: Int) -> Int { 1 + (max(1, wave) - 1) / stageLength }

    public static func isBossWave(_ wave: Int) -> Bool { wave % stageLength == 0 }

    public static func isShopWave(_ wave: Int) -> Bool { wave % shopEvery == 0 }

    /// Oro por superar la oleada: 16 + 7 × oleada (`economy.arenaRewardBase` / `arenaRewardPerWave`).
    public static func reward(wave: Int) -> Int {
        let k = TunedData.current.economy
        return Int(k.arenaRewardBase) + Int(k.arenaRewardPerWave) * wave
    }

    /// Nivel de la forja tras la oleada: un tier nuevo de material cada 4 oleadas
    /// (T2 en las paradas 2 y 4, T3 en la 6, T4 en la 10, T5 en la 14, T6 en la 18).
    /// Oleadas por nivel: 2 (`economy.arenaWavesPerShopLevel`).
    public static func shopLevel(wave: Int) -> Int {
        min(10, max(1, wave / Int(TunedData.current.economy.arenaWavesPerShopLevel)))
    }

    /// Los 50 enemigos originales del bestiario (40 normales + 10 jefes): los únicos que salen en la arena.
    /// Los monstruos y jefes de los continentes (p. ej. `eclipseAcolyte`) se añaden a `Bestiary.all` pero no aquí,
    /// así la arena no cambia al crecer el mundo.
    public static let originalEnemyIDs: Set<String> = [
        "rat", "goblin", "goblinSlinger", "mangyDog", "ratKing",
        "goblinThief", "crow", "bandit", "goblinSpearman", "banditChief",
        "skeleton", "zombieFarmer", "boar", "goblinShaman", "scarecrow",
        "goblinBrute", "cultist", "slime", "bat", "possessedSmith",
        "wolf", "hobgoblin", "skeletonArcher", "mudGolem", "alphaWolf",
        "goblinBomber", "ghoul", "fireSlime", "mercenary", "witch",
        "orc", "plagueRat", "wraith", "wolfRider", "ogre",
        "troll", "blackKnight", "gargoyle", "necromancer", "abbot",
        "goblinElite", "berserker", "iceSlime", "assassin", "warlord",
        "goblinGuard", "goblinMage", "armoredBoar", "goblinStandard", "goblinKing",
    ]

    /// Enemigos de la arena, en el orden del bestiario (el orden importa: fija las oleadas con la misma semilla).
    public static var enemies: [EnemyDefinition] { Bestiary.all.filter { originalEnemyIDs.contains($0.id) } }

    public static func wave(_ number: Int) -> Wave {
        let n = max(1, number)
        var rng = SeededGenerator(seed: UInt64(n * 7_777))
        let tier = tier(wave: n)
        let pool = enemies.filter { !$0.isBoss && $0.level <= tier }
        // Los enemigos del tier actual salen más.
        let candidates = pool.map { ($0.id, $0.level >= tier - 1 ? 3.0 : 1.0) }
        // En las oleadas de jefe salen la mitad de monstruos normales: el reto es el jefe.
        let total = min(60, 4 + 2 * n) / (isBossWave(n) ? 2 : 1)
        var spawns: [String: Int] = [:]
        for _ in 0..<total {
            spawns[WeightedPicker.pick(candidates, using: &rng), default: 0] += 1
        }
        if isBossWave(n) {
            let bosses = enemies.filter(\.isBoss).sorted { $0.level < $1.level }
            let boss = bosses[(n / stageLength - 1) % bosses.count]
            spawns[boss.id] = 1
        }
        return Wave(spawns: spawns, spawnInterval: max(0.4, 1.5 - 0.03 * Double(n)))
    }
}
