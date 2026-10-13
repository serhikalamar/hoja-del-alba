import GameCore
import Observation
import SpriteKit
#if os(iOS)
import UIKit
#endif

/// Partida en la arena: oleadas infinitas cada vez más difíciles.
/// También las mazmorras de historia (M8, `story != nil`): oleadas fijas de una `StoryDungeon` con el personaje
/// de verdad, sin forja ni reinicio; al ganar o perder se vuelve a la exploración (`GameStore.finishStoryDungeon`).
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
        /// Mazmorra de historia: diálogo antes de la oleada del jefe.
        case storyDialog
        /// Mazmorra de historia ganada.
        case storyVictory
    }

    /// Mazmorra de historia en curso (nil = arena).
    let story: StoryDungeon?
    var isStory: Bool { story != nil }
    /// Diálogo en pantalla (fase `storyDialog`).
    private(set) var storyDialog: (speaker: String, lines: [String], index: Int)?
    /// Aviso al ganar o al perder la mazmorra de historia.
    private(set) var storyMessage = ""
    /// Primera victoria en esta mazmorra (el jefe suelta su pieza seguro).
    @ObservationIgnored private var isFirstWin = true
    @ObservationIgnored private var bossIntroShown = false

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
    /// Piso actual de la mazmorra (se baja uno cada 5 oleadas).
    private(set) var floor: DungeonFloor
    /// Profundidad del piso actual (1, 2, 3…).
    var depth: Int { Arena.depth(wave: max(1, wave)) }
    /// Aviso grande en pantalla ("¡Nuevo escenario!").
    private(set) var banner: String?
    /// Forja del enano entre oleadas.
    private(set) var shop: ShopModel?
    private(set) var isNewRecord = false

    /// Récord del personaje (no de la copia de la partida).
    var bestWave: Int { store.character.arenaBestWave ?? 0 }
    var level: Int { store.profile.characterLevel }
    var xpProgress: Double {
        let need = Leveling.xpToNext(store.profile.characterLevel)
        return need > 0 ? Double(store.profile.levelXP) / Double(need) : 1
    }
    var totalMineralsEarned: Int { mineralsEarned.values.reduce(0, +) }
    var nextWaveHasBoss: Bool { story.map { $0.isBossWave(wave + 1) } ?? Arena.isBossWave(wave + 1) }

    /// Dirección del joystick (-1...1). La escena la lee en cada frame.
    @ObservationIgnored var joystick: CGVector = .zero
    @ObservationIgnored let scene: BattleScene
    @ObservationIgnored private unowned let store: GameStore
    @ObservationIgnored private var breakTask: Task<Void, Never>?
    #if os(iOS)
    @ObservationIgnored private let haptics = UIImpactFeedbackGenerator(style: .light)
    #endif

    init(store: GameStore, story: StoryDungeon? = nil) {
        self.store = store
        self.story = story
        floor = story?.floor ?? Arena.floor(wave: 1)
        scene = BattleScene(size: CGSize(width: 844, height: 390))
        scene.scaleMode = .resizeFill
        scene.session = self
        scene.combatDelegate = self
        let stats = store.profile.totalStats
        hp = stats.maxHP
        maxHP = stats.maxHP
        applyEquipment(hp: hp)
        if let story {
            // Botín de la familia del continente de la bajada; empieza sin pantalla de inicio.
            scene.lootContinent = World.area(story.entranceAreaID).flatMap { World.continent($0.continentID) }
            isFirstWin = !(store.profile.wonDungeons ?? []).contains(story.id)
            startNextWave()
        }
    }

    /// Oleadas en total (mazmorra de historia) o nil (arena, infinitas).
    var totalWaves: Int? { story?.totalWaves }

    private func applyEquipment(hp: Double) {
        let profile = store.profile
        scene.prepare(
            floor: floor,
            stats: profile.totalStats,
            hp: hp,
            look: HeroLook(profile: profile),
            weapon: profile.equippedWeapon,
            level: profile.characterLevel
        )
    }

    // MARK: - Flujo de oleadas

    func startNextWave() {
        if let story { startStoryWave(story); return }
        guard phase == .intro || phase == .intermission || phase == .waveBreak else { return }
        breakTask?.cancel()
        let afterShop = phase == .intermission
        wave += 1
        let stageChanged = wave > 1 && Arena.depth(wave: wave) != Arena.depth(wave: wave - 1)
        floor = Arena.floor(wave: wave)

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
            showBanner("PISO \(depth): \(floor.name.uppercased())")
        } else if Arena.isBossWave(wave) {
            showBanner("¡OLEADA \(wave): JEFE!")
        } else {
            showBanner("OLEADA \(wave)")
        }
    }

    // MARK: - Mazmorra de historia

    private func startStoryWave(_ story: StoryDungeon) {
        guard phase == .intro || phase == .waveBreak || phase == .storyDialog else { return }
        breakTask?.cancel()
        let next = wave + 1
        // Antes del jefe, su diálogo (la confesión del Abad).
        if story.isBossWave(next), !bossIntroShown {
            bossIntroShown = true
            let lines = story.bossIntroLines(firstWin: isFirstWin)
            if !lines.isEmpty {
                joystick = .zero
                scene.setRunning(false)
                storyDialog = (story.bossSpeakerName, lines, 0)
                phase = .storyDialog
                return
            }
        }
        storyDialog = nil
        wave = next
        let stats = store.profile.totalStats
        let startHP = wave == 1 ? stats.maxHP : min(stats.maxHP, hp + stats.maxHP * 0.1)
        applyEquipment(hp: startHP)
        let round = story.wave(wave)
        enemiesLeft = round.totalMonsters
        scene.startRound(round, enemyLevel: story.level)
        phase = .fighting
        if story.isBossWave(wave) {
            showBanner("¡JEFE!")
        } else {
            showBanner(wave == 1 ? "\(story.name.uppercased()) · OLEADA 1/\(story.totalWaves)" : "OLEADA \(wave)/\(story.totalWaves)")
        }
    }

    /// Avanza el diálogo de la mazmorra; al terminar empieza la oleada del jefe.
    func advanceStoryDialog() {
        guard phase == .storyDialog, var dialog = storyDialog else { return }
        if dialog.index < dialog.lines.count - 1 {
            dialog.index += 1
            storyDialog = dialog
        } else if let story {
            startStoryWave(story)
        }
    }

    /// ¿Suelta el jefe su pieza? Siempre la primera vez; al repetir, con `StoryDungeon.repeatPartChance`.
    func bossDropsPart() -> Bool {
        guard let story else { return true }
        var rng = SystemRandomNumberGenerator()
        return story.bossDropsPart(firstWin: isFirstWin, using: &rng)
    }

    private func winStory(_ story: StoryDungeon) {
        joystick = .zero
        let first = store.profile.winDungeon(story.id)
        var rng = SystemRandomNumberGenerator()
        for reward in story.rewards(firstWin: first, using: &rng) {
            store.profile.grant(reward)
            goldEarned += reward.gold
            for (mineral, count) in reward.minerals { mineralsEarned[mineral, default: 0] += count }
        }
        store.profile.syncStory()
        let texts = ValdemarDialogue.dungeonTexts[story.id]
        storyMessage = (first ? texts?.firstWin : texts?.win) ?? "¡\(story.name): despejada!"
        if first, let defeat = story.bossDefeatText { storyMessage += "\n" + defeat }
        phase = .storyVictory
        store.save()
    }

    /// Volver a la exploración: al ganar o al salir desde la pausa, junto a la bajada; al perder, al punto seguro.
    func leaveStory() {
        guard let story else { return }
        switch phase {
        case .storyVictory:
            store.finishStoryDungeon(won: true)
        case .defeat:
            store.finishStoryDungeon(won: false, message: ValdemarDialogue.dungeonTexts[story.id]?.lose)
        default:
            store.finishStoryDungeon(won: false, abandoned: true)
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
        // Puede haber cambiado de equipo en el inventario de la pausa.
        applyEquipment(hp: hp)
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
        if let story {
            // Historia: experiencia y oro de verdad, y cuenta para las misiones (`kill`, `defeat`).
            let level = story.level
            goldEarned += store.profile.earnGold(StoryEconomy.killGold(enemy, level: level))
            // Mazmorra repetible: los normales, con `Leveling.respawningMultiplier`; el jefe, entero.
            let xp = Leveling.storyXPForKill(enemy, level: level, heroLevel: store.profile.characterLevel, respawns: true)
            if store.profile.gainXP(xp) > 0 { levelUp() }
            store.profile.record(.killed(enemyID: enemy.id, areaID: story.id))
            return
        }
        // Experiencia de la partida (se pierde al acabar, como todo en la arena).
        let xp = Leveling.xpForKill(enemy, level: Arena.enemyLevel(wave: wave), heroLevel: store.profile.characterLevel)
        if store.profile.gainXP(xp) > 0 { levelUp() }
    }

    private func levelUp() {
        let oldMax = maxHP
        let stats = store.profile.totalStats
        applyEquipment(hp: hp + max(0, stats.maxHP - oldMax))
        scene.levelUpEffect(store.profile.characterLevel)
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
        if let story {
            if wave >= story.totalWaves {
                winStory(story)
            } else {
                lastWaveReward = 0
                phase = .waveBreak
                breakTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(2.2))
                    guard !Task.isCancelled, self?.phase == .waveBreak else { return }
                    self?.startNextWave()
                }
                store.save()
            }
            return
        }
        lastWaveReward = store.profile.earnGold(Arena.reward(wave: wave))
        goldEarned += lastWaveReward
        if wave > bestWave { isNewRecord = true }
        store.recordArenaWave(wave)
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
