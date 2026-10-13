import Foundation

// MARK: - Botín y forja por continente (fase 1, M6)
//
// En la historia los monstruos sueltan la familia de minerales del continente del área (Valdemar: cobre, hierro,
// plata, oro, esmeralda con 35/27/20/12/6) y la forja vende el tier de su continente (+1 tras su misión final).
// La arena no cambia: sus 10 minerales (`Mineral.roll`) y su escalera de tiers (`Arena.shopLevel`).

extension Continent {
    /// Pesos de la familia, de común a muy rara (`progresion.md` §5). Los ajusta el balance-designer.
    /// Ajustable: `economy.continentLootWeights`.
    public static var familyWeights: [Double] { TunedData.current.economy.continentLootWeights }

    /// Tabla de botín: cada mineral de la familia con su peso.
    public var lootTable: [(Mineral, Double)] {
        zip(minerals, Self.familyWeights).map { ($0, $1) }
    }

    /// Tira el dado de minerales del continente.
    public func rollMineral<G: RandomNumberGenerator>(using rng: inout G) -> Mineral {
        WeightedPicker.pick(lootTable, using: &rng)
    }
}

extension MonsterStats {
    /// Minerales soltados al morir en un área del continente (nil = la tabla de la arena). Cuántos sueltan sigue la
    /// misma regla que en la arena (`rollDrops`); solo cambia cuál.
    public func rollDrops<G: RandomNumberGenerator>(in continent: Continent?, using rng: inout G) -> [Mineral] {
        let drops = rollDrops(using: &rng)
        guard let continent, !continent.minerals.isEmpty else { return drops }
        return drops.map { _ in continent.rollMineral(using: &rng) }
    }
}

extension PlayerProfile {
    /// Tier de material que vende la forja de la historia: el del continente donde está el héroe, y uno más
    /// tras completar su misión final (`valdemar.rey_goblin`).
    public var storyForgeTier: Int {
        guard let continent = World.continent(continentID) else { return 1 }
        let bonus = continent.finalQuestID.map { isQuestDone($0) ? 1 : 0 } ?? 0
        return min(6, max(1, continent.tier + bonus))
    }
}
