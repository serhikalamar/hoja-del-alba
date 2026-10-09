import Testing
@testable import GameCore

/// Monstruos de continente: están en el bestiario pero no en la arena.
@Suite("Monstruos de continente")
struct ContinentEnemyTests {
    @Test func eclipseAcolyteIsARangedLevelSevenHuman() {
        let acolyte = Bestiary.enemy("eclipseAcolyte")
        #expect(acolyte != nil)
        #expect(acolyte?.behavior == .ranged)
        #expect(acolyte?.level == 7)
        #expect(acolyte?.template == "human")
        #expect(acolyte?.isBoss == false)
    }

    @Test func arenaOnlyUsesTheOriginalFifty() {
        #expect(!Arena.originalEnemyIDs.contains("eclipseAcolyte"))
        for id in Arena.originalEnemyIDs { #expect(Bestiary.enemy(id) != nil, "\(id)") }
        for n in 1...80 {
            for id in Arena.wave(n).spawns.keys {
                #expect(Arena.originalEnemyIDs.contains(id), "oleada \(n): \(id)")
            }
        }
    }
}
