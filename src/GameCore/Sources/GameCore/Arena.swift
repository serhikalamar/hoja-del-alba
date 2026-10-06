import Foundation

/// Arena de oleadas infinitas, cada vez más difíciles.
/// - Cada 2 oleadas: forja del enano y ritual.
/// - Cada 5 oleadas: jefe y cambio de escenario.
public enum Arena {
    /// Oleadas entre una visita a la forja y la siguiente.
    public static let shopEvery = 2
    /// Oleadas con el mismo escenario (y cada cuántas sale un jefe).
    public static let stageLength = 5

    /// Nivel de dificultad de los enemigos: sube 1 cada 2 oleadas y no tiene tope.
    public static func enemyLevel(wave: Int) -> Int {
        1 + (max(1, wave) - 1) / 2
    }

    /// Tier del bestiario disponible (qué enemigos pueden salir), de 1 a 10.
    public static func tier(wave: Int) -> Int {
        min(10, 1 + (max(1, wave) - 1) / 2)
    }

    /// Orden de los escenarios: cada cambio se nota (suelo y hora del día distintos).
    /// Calle → huertos → cementerio al atardecer → murallas de noche → plaza al atardecer →
    /// molino de noche → abadía → salón del trono → pozo de la bruja → mercado.
    static let stageOrder = [1, 3, 5, 9, 4, 7, 8, 10, 6, 2]

    /// Escenario de la oleada: cambia cada `stageLength` oleadas y recorre los 10 del pueblo.
    public static func stage(wave: Int) -> LevelDefinition {
        let index = ((max(1, wave) - 1) / stageLength) % stageOrder.count
        return Worlds.village.level(stageOrder[index])!
    }

    public static func isBossWave(_ wave: Int) -> Bool { wave % stageLength == 0 }

    public static func isShopWave(_ wave: Int) -> Bool { wave % shopEvery == 0 }

    /// Oro por superar la oleada.
    public static func reward(wave: Int) -> Int { 12 + 7 * wave }

    /// Nivel de la forja tras la oleada.
    public static func shopLevel(wave: Int) -> Int { min(10, 1 + wave / 2) }

    public static func wave(_ number: Int) -> Wave {
        let n = max(1, number)
        var rng = SeededGenerator(seed: UInt64(n * 7_777))
        let tier = tier(wave: n)
        let pool = Bestiary.all.filter { !$0.isBoss && $0.level <= tier }
        // Los enemigos del tier actual salen más.
        let candidates = pool.map { ($0.id, $0.level >= tier - 1 ? 3.0 : 1.0) }
        let total = min(60, 4 + 2 * n)
        var spawns: [String: Int] = [:]
        for _ in 0..<total {
            spawns[WeightedPicker.pick(candidates, using: &rng), default: 0] += 1
        }
        if isBossWave(n) {
            let bosses = Bestiary.bosses.sorted { $0.level < $1.level }
            let boss = bosses[(n / stageLength - 1) % bosses.count]
            spawns[boss.id] = 1
        }
        return Wave(spawns: spawns, spawnInterval: max(0.4, 1.5 - 0.03 * Double(n)))
    }
}
