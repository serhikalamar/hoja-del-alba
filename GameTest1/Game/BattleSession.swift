import GameCore
import Observation
import SpriteKit
#if os(iOS)
import UIKit
#endif

/// Puente entre la escena SpriteKit y la interfaz SwiftUI de una partida a un nivel.
@Observable
final class BattleSession {
    enum Phase: Equatable {
        case intro, fighting, paused, intermission, victory, defeat
    }

    let level: LevelDefinition
    private(set) var phase: Phase = .intro
    private(set) var round = 0
    private(set) var hp: Double = 0
    private(set) var maxHP: Double = 0
    private(set) var enemiesLeft = 0
    private(set) var kills = 0
    private(set) var goldEarned = 0
    private(set) var mineralsEarned: [Mineral: Int] = [:]
    /// Piezas especiales conseguidas en esta partida.
    private(set) var partsEarned: [WeaponPart] = []
    private(set) var lastRoundReward = 0
    private(set) var levelClearBonus = 0
    private(set) var shopOffers: [ShopOffer] = []
    private(set) var rerolls = 0

    var totalRounds: Int { level.roundCount }
    var rerollCost: Int { ShopGenerator.rerollCost(rerollsSoFar: rerolls) }
    var totalMineralsEarned: Int { mineralsEarned.values.reduce(0, +) }

    /// Dirección del joystick (-1...1). La escena la lee en cada frame.
    @ObservationIgnored var joystick: CGVector = .zero
    @ObservationIgnored let scene: BattleScene
    @ObservationIgnored private unowned let store: GameStore
    @ObservationIgnored private var rng = SystemRandomNumberGenerator()
    #if os(iOS)
    @ObservationIgnored private let haptics = UIImpactFeedbackGenerator(style: .light)
    #endif

    init(level: LevelDefinition, store: GameStore) {
        self.level = level
        self.store = store
        scene = BattleScene(size: CGSize(width: 844, height: 390))
        scene.scaleMode = .resizeFill
        scene.session = self
        let stats = store.profile.totalStats
        hp = stats.maxHP
        maxHP = stats.maxHP
        applyEquipment(hp: hp)
    }

    private func applyEquipment(hp: Double) {
        let profile = store.profile
        scene.prepare(
            level: level,
            stats: profile.totalStats,
            hp: hp,
            armorIcon: profile.equippedArmor?.icon ?? "armor_tunic",
            weapon: profile.equippedWeapon,
            race: profile.race
        )
    }

    // MARK: - Flujo de rondas

    func startNextRound() {
        guard round < totalRounds, phase == .intro || phase == .intermission else { return }
        round += 1
        let stats = store.profile.totalStats
        // Entre rondas se recupera un 25% de la vida.
        let startHP = round == 1 ? stats.maxHP : min(stats.maxHP, hp + stats.maxHP * 0.25)
        applyEquipment(hp: startHP)
        let wave = level.waves[round - 1]
        enemiesLeft = wave.totalMonsters
        scene.startRound(wave)
        phase = .fighting
    }

    func pause() {
        guard phase == .fighting else { return }
        joystick = .zero
        scene.setRunning(false)
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        scene.setRunning(true)
        phase = .fighting
    }

    // MARK: - Callbacks de la escena

    func heroHPChanged(hp: Double, maxHP: Double) {
        self.hp = hp
        self.maxHP = maxHP
    }

    func heroWasHit() {
        #if os(iOS)
        haptics.impactOccurred()
        #endif
    }

    func enemyKilled(_ enemy: EnemyDefinition) {
        kills += 1
        enemiesLeft = max(0, enemiesLeft - 1)
        if enemy.isBoss { store.profile.defeatedBosses.insert(enemy.id) }
    }

    func partCollected(_ part: WeaponPart) {
        partsEarned.append(part)
        store.profile.addPart(part.id)
        store.save()
    }

    func mineralCollected(_ mineral: Mineral) {
        mineralsEarned[mineral, default: 0] += 1
        store.profile.addMineral(mineral)
    }

    func roundCleared() {
        joystick = .zero
        lastRoundReward = store.profile.earnGold(level.roundReward(round))
        goldEarned += lastRoundReward
        if round >= totalRounds {
            levelClearBonus = store.profile.earnGold(level.clearBonus)
            goldEarned += levelClearBonus
            store.profile.completeLevel(level.id, totalLevels: Worlds.village.levels.count)
            phase = .victory
        } else {
            shopOffers = ShopGenerator.offers(level: level.id, using: &rng)
            rerolls = 0
            phase = .intermission
        }
        store.save()
    }

    func heroDied() {
        joystick = .zero
        phase = .defeat
        store.save()
    }

    // MARK: - Tienda

    func reroll() {
        let cost = rerollCost
        guard store.profile.gold >= cost else { return }
        store.profile.gold -= cost
        rerolls += 1
        shopOffers = ShopGenerator.offers(level: level.id, using: &rng)
        store.save()
    }

    func canAfford(_ offer: ShopOffer) -> Bool {
        store.profile.gold >= offer.price
    }

    /// Compra una oferta. Las pociones curan al momento.
    func buy(_ offer: ShopOffer) {
        guard let index = shopOffers.firstIndex(where: { $0.id == offer.id }), !shopOffers[index].sold else { return }
        switch offer.kind {
        case .potion(let fraction):
            guard store.profile.gold >= offer.price, hp < maxHP else { return }
            store.profile.gold -= offer.price
            scene.heal(maxHP * fraction)
        case .equipment, .part:
            do { try store.profile.buy(offer) } catch { return }
        }
        shopOffers[index].sold = true
        store.save()
    }
}
