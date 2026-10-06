import GameCore
import Observation
import SpriteKit
#if os(iOS)
import UIKit
#endif

/// Partida en la arena: oleadas infinitas cada vez más difíciles.
@Observable
final class BattleSession: CombatDelegate {
    enum Phase: Equatable {
        /// Pantalla de inicio.
        case intro
        case fighting
        case paused
        /// Pausa corta entre oleadas (sin tienda): continúa sola.
        case waveBreak
        /// Cada 2 oleadas: forja del enano y ritual.
        case intermission
        case defeat
    }

    private(set) var phase: Phase = .intro
    /// Oleada actual (1-based); 0 antes de empezar.
    private(set) var wave = 0
    private(set) var hp: Double = 0
    private(set) var maxHP: Double = 0
    private(set) var enemiesLeft = 0
    private(set) var kills = 0
    private(set) var goldEarned = 0
    private(set) var mineralsEarned: [Mineral: Int] = [:]
    /// Piezas especiales conseguidas en esta partida.
    private(set) var partsEarned: [WeaponPart] = []
    private(set) var lastWaveReward = 0
    /// Escenario actual (cambia cada 5 oleadas).
    private(set) var stage: LevelDefinition
    /// Aviso grande en pantalla ("¡Nuevo escenario!").
    private(set) var banner: String?
    /// Forja del enano entre oleadas.
    private(set) var shop: ShopModel?
    private(set) var isNewRecord = false

    var bestWave: Int { store.profile.arenaBestWave ?? 0 }
    var totalMineralsEarned: Int { mineralsEarned.values.reduce(0, +) }
    var nextWaveHasBoss: Bool { Arena.isBossWave(wave + 1) }

    /// Dirección del joystick (-1...1). La escena la lee en cada frame.
    @ObservationIgnored var joystick: CGVector = .zero
    @ObservationIgnored let scene: BattleScene
    @ObservationIgnored private unowned let store: GameStore
    @ObservationIgnored private var breakTask: Task<Void, Never>?
    #if os(iOS)
    @ObservationIgnored private let haptics = UIImpactFeedbackGenerator(style: .light)
    #endif

    init(store: GameStore) {
        self.store = store
        stage = Arena.stage(wave: 1)
        scene = BattleScene(size: CGSize(width: 844, height: 390))
        scene.scaleMode = .resizeFill
        scene.session = self
        scene.combatDelegate = self
        let stats = store.profile.totalStats
        hp = stats.maxHP
        maxHP = stats.maxHP
        applyEquipment(hp: hp)
    }

    private func applyEquipment(hp: Double) {
        let profile = store.profile
        scene.prepare(
            level: stage,
            stats: profile.totalStats,
            hp: hp,
            armorIcon: profile.equippedArmor?.icon ?? "armor_tunic",
            weapon: profile.equippedWeapon,
            race: profile.race
        )
    }

    // MARK: - Flujo de oleadas

    func startNextWave() {
        guard phase == .intro || phase == .intermission || phase == .waveBreak else { return }
        breakTask?.cancel()
        let afterShop = phase == .intermission
        wave += 1
        let newStage = Arena.stage(wave: wave)
        let stageChanged = newStage.id != stage.id
        stage = newStage

        let stats = store.profile.totalStats
        // Tras la forja se recupera un 30% de la vida; entre oleadas, un 10%.
        let heal = afterShop ? 0.3 : 0.1
        let startHP = wave == 1 ? stats.maxHP : min(stats.maxHP, hp + stats.maxHP * heal)
        applyEquipment(hp: startHP)

        let next = Arena.wave(wave)
        enemiesLeft = next.totalMonsters
        scene.startRound(next, enemyLevel: Arena.enemyLevel(wave: wave))
        phase = .fighting

        if stageChanged {
            showBanner("NUEVO ESCENARIO: \(stage.name.uppercased())")
        } else if Arena.isBossWave(wave) {
            showBanner("¡OLEADA \(wave): JEFE!")
        } else {
            showBanner("OLEADA \(wave)")
        }
    }

    private func showBanner(_ text: String) {
        banner = text
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            if self?.banner == text { self?.banner = nil }
        }
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
        lastWaveReward = store.profile.earnGold(Arena.reward(wave: wave))
        goldEarned += lastWaveReward
        if wave > bestWave {
            store.profile.arenaBestWave = wave
            isNewRecord = true
        }
        if Arena.isShopWave(wave) {
            shop = ShopModel(store: store, level: Arena.shopLevel(wave: wave),
                             heal: { [weak self] fraction in
                                 guard let self else { return }
                                 self.scene.heal(self.maxHP * fraction)
                             },
                             needsHealing: { [weak self] in (self?.hp ?? 0) < (self?.maxHP ?? 0) })
            phase = .intermission
        } else {
            // Respiro corto y la siguiente oleada empieza sola.
            phase = .waveBreak
            breakTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(2.2))
                guard !Task.isCancelled, self?.phase == .waveBreak else { return }
                self?.startNextWave()
            }
        }
        store.save()
    }

    func heroDied() {
        joystick = .zero
        breakTask?.cancel()
        phase = .defeat
        store.save()
    }
}
