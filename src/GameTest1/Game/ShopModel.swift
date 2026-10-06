import GameCore
import Observation

/// Ofertas de la forja del enano. La usan la arena (entre rondas) y el pueblo (al entrar en la forja).
@Observable
final class ShopModel {
    private(set) var offers: [ShopOffer]
    private(set) var rerolls = 0
    let level: Int

    @ObservationIgnored private unowned let store: GameStore
    /// Cura al héroe una fracción de su vida máxima.
    @ObservationIgnored private let heal: (Double) -> Void
    /// ¿Le falta vida al héroe? (si no, la poción no se puede comprar).
    @ObservationIgnored let needsHealing: () -> Bool
    @ObservationIgnored private var rng = SystemRandomNumberGenerator()

    init(store: GameStore, level: Int, heal: @escaping (Double) -> Void, needsHealing: @escaping () -> Bool) {
        self.store = store
        self.level = level
        self.heal = heal
        self.needsHealing = needsHealing
        offers = []
        offers = ShopGenerator.offers(level: level, using: &rng)
    }

    var rerollCost: Int { ShopGenerator.rerollCost(rerollsSoFar: rerolls) }

    func canAfford(_ offer: ShopOffer) -> Bool { store.profile.gold >= offer.price }

    func reroll() {
        let cost = rerollCost
        guard store.profile.gold >= cost else { return }
        store.profile.gold -= cost
        rerolls += 1
        offers = ShopGenerator.offers(level: level, using: &rng)
        store.save()
    }

    func buy(_ offer: ShopOffer) {
        guard let index = offers.firstIndex(where: { $0.id == offer.id }), !offers[index].sold else { return }
        switch offer.kind {
        case .potion(let fraction):
            guard canAfford(offer), needsHealing() else { return }
            store.profile.gold -= offer.price
            heal(fraction)
        case .equipment, .part:
            do { try store.profile.buy(offer) } catch { return }
        }
        offers[index].sold = true
        store.save()
    }
}
