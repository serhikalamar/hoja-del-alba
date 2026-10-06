import GameCore
import SpriteKit

/// Escena de combate. Toda la simulación ocurre aquí; el estado que muestra la interfaz
/// se comunica a `BattleSession` mediante callbacks.
final class BattleScene: SKScene {
    weak var session: BattleSession?

    private let hero = HeroNode()
    private var groundNode: SKSpriteNode?
    private let decorLayer = SKNode()
    private var enemies: [EnemyNode] = []
    private var projectiles: [ProjectileNode] = []
    private var pickups: [MineralPickupNode] = []
    private var partPickups: [PartPickupNode] = []

    private var spawnQueue: [String] = []
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1
    private var attackTimer: TimeInterval = 0
    private var attackCount = 0
    private var dustTimer: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var clearTimer: TimeInterval?
    private var running = false

    private var level: LevelDefinition = Worlds.village.levels[0]
    private(set) var stats = Race.human.baseStats
    private var ability: Ability?
    private(set) var hp: Double = 100
    private var reportedHP = -1
    private var rng = SystemRandomNumberGenerator()
    private var builtSize = CGSize.zero

    /// Zona jugable (deja la franja de casas arriba).
    private var arena: CGRect {
        let top = CGFloat(VillageArt.bandHeight) * PX + 6
        return CGRect(x: 28, y: 24, width: max(10, size.width - 56), height: max(10, size.height - 24 - top))
    }

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor(rgb: 0x4A4440)
        anchorPoint = .zero
        addChild(decorLayer)
        addChild(hero)
        hero.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    // MARK: - API para BattleSession

    func prepare(level: LevelDefinition, stats: Stats, hp: Double, armorIcon: String, weapon: Item?, race: Race) {
        let levelChanged = level.id != self.level.id
        self.level = level
        self.stats = stats
        self.ability = weapon?.ability
        self.hp = min(hp, stats.maxHP)
        reportedHP = -1
        hero.setEquipment(armorIcon: armorIcon, weapon: weapon, race: race)
        if levelChanged && builtSize != .zero { buildScenery() }
        reportHP()
    }

    func startRound(_ wave: Wave) {
        spawnQueue = wave.spawnOrder(using: &rng)
        spawnInterval = wave.spawnInterval
        spawnTimer = 0.6
        clearTimer = nil
        attackTimer = 0
        setRunning(true)
    }

    func setRunning(_ value: Bool) {
        running = value
        isPaused = !value
        if !value { hero.setWalking(false) }
    }

    func heal(_ amount: Double) {
        hp = min(stats.maxHP, hp + amount)
        reportHP()
        floatingText("+\(Int(amount))", at: hero.position + CGVector(dx: 0, dy: 30), color: .green, size: 14)
    }

    // MARK: - Escenario

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 50, size.height > 50,
              abs(size.width - builtSize.width) > 1 || abs(size.height - builtSize.height) > 1 else { return }
        builtSize = size
        buildScenery()
        hero.position = clamp(hero.position == .zero ? CGPoint(x: size.width / 2, y: size.height / 2) : hero.position)
    }

    private func buildScenery() {
        groundNode?.removeFromParent()
        decorLayer.removeAllChildren()

        let artW = Int((size.width / PX).rounded(.up))
        let artH = Int((size.height / PX).rounded(.up))
        let image = VillageArt.background(width: artW, height: artH, level: level)
        let ground = SKSpriteNode(texture: ArtCache.texture(fromImage: image))
        ground.size = CGSize(width: CGFloat(artW) * PX, height: CGFloat(artH) * PX)
        ground.anchorPoint = CGPoint(x: 0, y: 1)
        ground.position = CGPoint(x: 0, y: size.height)
        ground.zPosition = -10
        addChild(ground)
        groundNode = ground

        // Decoración en los bordes de la zona de juego.
        var decorRNG = SeededGenerator(seed: UInt64(level.id * 31))
        let props: [PixelSprite] = switch level.ground {
        case "farm": [Sprites.hay, Sprites.crate, Sprites.barrel]
        case "graveyard": [Sprites.gravestone, Sprites.gravestone, Sprites.lampPost]
        case "castle": [Sprites.barrel, Sprites.lampPost]
        default: [Sprites.barrel, Sprites.crate, Sprites.lampPost]
        }
        let a = arena
        for i in 0..<7 {
            let sprite = props[Int.random(in: 0..<props.count, using: &decorRNG)]
            let node = SKSpriteNode(texture: ArtCache.texture(fromImage: sprite.makeCGImage()))
            node.size = CGSize(width: CGFloat(sprite.width) * PX, height: CGFloat(sprite.height) * PX)
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            let onLeft = i % 2 == 0
            let x = onLeft ? CGFloat.random(in: 6...a.minX + 20, using: &decorRNG)
                           : CGFloat.random(in: a.maxX - 20...size.width - 6, using: &decorRNG)
            let y = CGFloat.random(in: a.minY...a.maxY - 20, using: &decorRNG)
            node.position = CGPoint(x: x, y: y)
            node.zPosition = depth(for: y)
            decorLayer.addChild(node)
            if level.time != .day, sprite.rows == Sprites.lampPost.rows {
                let glow = SKShapeNode(circleOfRadius: 46)
                glow.fillColor = SKColor(rgb: 0xFFD870, alpha: 0.13)
                glow.strokeColor = .clear
                glow.position = CGPoint(x: 0, y: node.size.height - 4)
                glow.blendMode = .add
                node.addChild(glow)
            }
        }
    }

    // MARK: - Bucle

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(1.0 / 20, currentTime - lastTime)
        lastTime = currentTime
        guard running, dt > 0 else { return }
        elapsed += dt

        updateHero(dt)
        updateSpawning(dt)
        updateEnemies(dt)
        guard running else { return }
        updateProjectiles(dt)
        guard running else { return }
        updateHeroAttack(dt)
        updatePickups(dt)
        checkRoundEnd(dt)
    }

    // MARK: - Héroe

    private func updateHero(_ dt: TimeInterval) {
        let input = session?.joystick ?? .zero
        let magnitude = min(1, input.length)
        if magnitude > 0.05 {
            let dir = input.normalized
            hero.position = clamp(hero.position + dir * (CGFloat(stats.moveSpeed * dt) * magnitude))
            hero.face(dx: dir.dx)
            hero.setWalking(true)
            dustTimer -= dt
            if dustTimer <= 0 {
                dustTimer = 0.22
                dust(at: hero.position + CGVector(dx: -dir.dx * 10, dy: -hero.size.height / 2 + 6))
            }
        } else {
            hero.setWalking(false)
        }
        hero.zPosition = depth(for: hero.position.y)
        if stats.regen > 0, hp < stats.maxHP {
            hp = min(stats.maxHP, hp + stats.regen * dt)
            reportHP()
        }
    }

    private func updateHeroAttack(_ dt: TimeInterval) {
        attackTimer -= dt
        guard attackTimer <= 0 else { return }
        let reach = CGFloat(stats.range) + HeroNode.bodyRadius * 0.5
        let candidates = enemies.filter { !$0.isDying && $0.position.distance(to: hero.position) - $0.radius <= reach }
        guard let target = candidates.min(by: {
            $0.position.distance(to: hero.position) < $1.position.distance(to: hero.position)
        }) else { return }

        attackTimer = 1 / stats.attackSpeed
        attackCount += 1
        let aim = (target.position - hero.position).normalized
        hero.face(dx: aim.dx)
        hero.swing(speed: stats.attackSpeed)
        slashEffect(direction: aim, reach: reach)

        // El objetivo recibe el golpe completo; los demás dentro del arco (~145°), el 75%.
        for enemy in candidates {
            let dir = (enemy.position - hero.position).normalized
            let isPrimary = enemy === target
            guard isPrimary || dir.dx * aim.dx + dir.dy * aim.dy > 0.3 else { continue }
            var hit = Combat.rollHit(stats: stats, using: &rng)
            if !isPrimary { hit.amount *= 0.75 }
            applyHit(enemy, hit: hit, primary: isPrimary)
        }

        guard let ability else { return }
        if ability.pulseEvery > 0, attackCount % ability.pulseEvery == 0 {
            pulse(radius: CGFloat(ability.pulseRadius), damage: stats.attack * ability.pulseDamage, color: abilityColor)
        }
        if ability.strikeEvery > 0, attackCount % ability.strikeEvery == 0,
           let strongest = enemies.filter({ !$0.isDying }).max(by: { $0.hp < $1.hp }) {
            strike(strongest, damage: stats.attack * ability.strikeDamage)
        }
    }

    private var abilityColor: UInt32 {
        ability?.elements.first?.color ?? 0xFFFFFF
    }

    /// Golpe del héroe con todos los efectos de la habilidad del arma.
    private func applyHit(_ enemy: EnemyNode, hit: Combat.Hit, primary: Bool) {
        let died = deal(enemy, amount: hit.amount, isCrit: hit.isCrit, source: hero.position)
        guard let ability else { return }

        if hit.isCrit, ability.critExplosion > 0 {
            explosion(at: enemy.position, radius: 60, damage: stats.attack * ability.critExplosion, color: 0xFF9A40)
        }
        if primary, ability.chain > 0 {
            chainLightning(from: enemy, jumps: ability.chain, damage: hit.amount * ability.chainDamage)
        }
        guard !died, !enemy.isDying else { return }
        if ability.burn > 0 { enemy.addBurn(dps: hit.amount * ability.burn / 3) }
        if ability.poison > 0 { enemy.addPoison(dps: hit.amount * ability.poison / 3) }
        if ability.slow > 0 { enemy.applySlow(ability.slow, now: elapsed) }
        if ability.execute > 0, enemy.hp / enemy.maxHP < ability.execute, !enemy.definition.isBoss {
            floatingText("¡EJECUTADO!", at: enemy.position + CGVector(dx: 0, dy: enemy.size.height / 2 + 8),
                         color: SKColor(rgb: 0xC879F2), size: 12)
            _ = enemy.takeDamage(enemy.hp + 1, from: nil)
            kill(enemy)
        }
    }

    /// Aplica daño y muestra el número. Devuelve `true` si el enemigo muere.
    @discardableResult
    private func deal(_ enemy: EnemyNode, amount: Double, isCrit: Bool, source: CGPoint?, color: SKColor? = nil) -> Bool {
        guard !enemy.isDying else { return false }
        let died = enemy.takeDamage(amount, from: source)
        floatingText(
            isCrit ? "\(Int(amount))!" : "\(Int(amount))",
            at: enemy.position + CGVector(dx: CGFloat.random(in: -6...6), dy: enemy.size.height / 2),
            color: color ?? (isCrit ? SKColor(rgb: 0xFFCD45) : .white),
            size: isCrit ? 17 : 13
        )
        if stats.lifesteal > 0 {
            hp = min(stats.maxHP, hp + amount * stats.lifesteal)
            reportHP()
        }
        if died { kill(enemy) }
        return died
    }

    private func heroHit(by raw: Double) {
        let amount = Combat.incomingDamage(raw: raw, defense: stats.defense)
        hp -= amount
        hero.hurtFlash()
        floatingText("-\(Int(amount.rounded()))", at: hero.position + CGVector(dx: 0, dy: 26), color: SKColor(rgb: 0xFF5050), size: 13)
        reportHP()
        session?.heroWasHit()
        if hp <= 0 {
            hp = 0
            running = false
            hero.setWalking(false)
            hero.playDeath()
            run(.sequence([.wait(forDuration: 1.2), .run { [weak self] in self?.session?.heroDied() }]))
        }
    }

    private func reportHP() {
        let rounded = Int(hp.rounded(.up))
        guard rounded != reportedHP else { return }
        reportedHP = rounded
        session?.heroHPChanged(hp: hp, maxHP: stats.maxHP)
    }

    // MARK: - Enemigos

    private func updateSpawning(_ dt: TimeInterval) {
        guard !spawnQueue.isEmpty else { return }
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }
        spawnTimer = spawnInterval
        spawn(spawnQueue.removeFirst())
    }

    private func spawn(_ id: String) {
        guard let definition = Bestiary.enemy(id) else { return }
        let enemy = EnemyNode(definition: definition, level: level.id)
        let a = arena
        let margin: CGFloat = 30
        switch Int.random(in: 0..<4, using: &rng) {
        case 0: enemy.position = CGPoint(x: -margin, y: CGFloat.random(in: a.minY...a.maxY, using: &rng))
        case 1: enemy.position = CGPoint(x: size.width + margin, y: CGFloat.random(in: a.minY...a.maxY, using: &rng))
        case 2: enemy.position = CGPoint(x: CGFloat.random(in: a.minX...a.maxX, using: &rng), y: -margin)
        default: enemy.position = CGPoint(x: CGFloat.random(in: a.minX...a.maxX, using: &rng), y: a.maxY + 20)
        }
        if definition.isBoss {
            enemy.position = CGPoint(x: size.width / 2, y: a.maxY + 10)
            floatingText("¡\(definition.name.uppercased())!", at: CGPoint(x: size.width / 2, y: size.height / 2 + 40),
                         color: SKColor(rgb: 0xFFCD45), size: 22, duration: 2)
            shake(intensity: 6)
        }
        enemy.zPosition = depth(for: enemy.position.y)
        addChild(enemy)
        enemies.append(enemy)
    }

    private func updateEnemies(_ dt: TimeInterval) {
        for enemy in enemies where !enemy.isDying {
            if let action = enemy.step(dt: dt, now: elapsed, target: hero.position, heroRadius: HeroNode.bodyRadius) {
                switch action {
                case .hit(let damage):
                    heroHit(by: damage)
                    if !running { return }
                case .shoot(let damage):
                    shoot(from: enemy, damage: damage)
                }
            }
            let (dot, particle) = enemy.tickStatuses(dt: dt, now: elapsed)
            if let particle { statusParticle(on: enemy, color: particle) }
            if dot > 0, enemy.takeDamage(dot, from: nil, flash: false) {
                kill(enemy)
            }
        }
        separateEnemies()
        let bounds = arena.insetBy(dx: -6, dy: -6)
        for enemy in enemies {
            // Los que ya entraron no pueden salir (si no, los tiradores huirían fuera de alcance).
            if enemy.hasEntered {
                enemy.position = CGPoint(x: min(bounds.maxX, max(bounds.minX, enemy.position.x)),
                                         y: min(bounds.maxY, max(bounds.minY, enemy.position.y)))
            } else if bounds.contains(enemy.position) {
                enemy.hasEntered = true
            }
            enemy.zPosition = depth(for: enemy.position.y)
        }
    }

    private func shoot(from enemy: EnemyNode, damage: Double) {
        let dir = (hero.position - enemy.position).normalized
        let projectile = ProjectileNode(enemyID: enemy.definition.id, damage: damage, velocity: dir * 210)
        projectile.position = enemy.position + CGVector(dx: dir.dx * enemy.radius, dy: 6)
        projectile.zPosition = 120
        addChild(projectile)
        projectiles.append(projectile)
    }

    private func updateProjectiles(_ dt: TimeInterval) {
        for projectile in projectiles.reversed() {
            projectile.position = projectile.position + projectile.velocity * CGFloat(dt)
            projectile.life -= dt
            if projectile.position.distance(to: hero.position) < HeroNode.bodyRadius + 4 {
                heroHit(by: projectile.damage)
                remove(projectile)
                if !running { return }
            } else if projectile.life <= 0 {
                remove(projectile)
            }
        }
    }

    private func remove(_ projectile: ProjectileNode) {
        projectiles.removeAll { $0 === projectile }
        projectile.removeFromParent()
    }

    /// Evita que los enemigos se amontonen en el mismo punto.
    private func separateEnemies() {
        let count = enemies.count
        guard count > 1 else { return }
        for i in 0..<(count - 1) {
            for j in (i + 1)..<count {
                let a = enemies[i], b = enemies[j]
                let delta = b.position - a.position
                let dist = delta.length
                let minDist = (a.radius + b.radius) * 0.85
                guard dist < minDist else { continue }
                let dir = dist > 0.01 ? delta.normalized : CGVector(dx: 1, dy: 0)
                let overlap = (minDist - dist) / 2
                a.push(dir * -overlap)
                b.push(dir * overlap)
            }
        }
    }

    private func kill(_ enemy: EnemyNode) {
        guard !enemy.isDying else { return }
        enemy.isDying = true
        enemies.removeAll { $0 === enemy }
        session?.enemyKilled(enemy.definition)

        if let ability, ability.healOnKill > 0 {
            hp = min(stats.maxHP, hp + stats.maxHP * ability.healOnKill)
            reportHP()
        }

        enemy.removeAllActions()
        let away: CGFloat = enemy.position.x >= hero.position.x ? 1 : -1
        enemy.run(.sequence([
            .group([
                .moveBy(x: 14 * away, y: 16, duration: 0.14),
                .rotate(byAngle: -0.9 * away, duration: 0.28),
            ]),
            .group([.moveBy(x: 6 * away, y: -18, duration: 0.14), .fadeOut(withDuration: 0.2), .scaleY(to: 0.5, duration: 0.2)]),
            .removeFromParent(),
        ]))
        burst(at: enemy.position, color: SKColor(rgb: 0xC8C8D0), count: enemy.definition.isBoss ? 40 : 8)

        for mineral in enemy.stats.rollDrops(using: &rng) {
            let pickup = MineralPickupNode(mineral: mineral)
            pickup.position = enemy.position + CGVector(dx: CGFloat.random(in: -18...18, using: &rng), dy: CGFloat.random(in: -12...12, using: &rng))
            pickup.zPosition = -2
            addChild(pickup)
            pickups.append(pickup)
        }
        if enemy.definition.isBoss, let partID = enemy.definition.specialPartID, let part = PartCatalog.part(partID) {
            let drop = PartPickupNode(part: part)
            drop.position = enemy.position
            drop.zPosition = 5
            addChild(drop)
            partPickups.append(drop)
            shake(intensity: 10)
            floatingText("¡\(part.name)!", at: enemy.position + CGVector(dx: 0, dy: 50), color: SKColor(rgb: 0xFFCD45), size: 16, duration: 2)
        }
    }

    // MARK: - Botín

    private func updatePickups(_ dt: TimeInterval) {
        for pickup in pickups.reversed() {
            let toHero = hero.position - pickup.position
            if toHero.length < 22 {
                collect(pickup)
            } else if pickup.magnetized || toHero.length < 80 {
                pickup.magnetized = true
                pickup.position = pickup.position + toHero.normalized * CGFloat(340 * dt)
            }
        }
        for drop in partPickups.reversed() {
            let toHero = hero.position - drop.position
            if toHero.length < 26 {
                collectPart(drop)
            } else if drop.magnetized {
                drop.position = drop.position + toHero.normalized * CGFloat(220 * dt)
            }
        }
    }

    private func collect(_ pickup: MineralPickupNode) {
        pickups.removeAll { $0 === pickup }
        pickup.removeFromParent()
        session?.mineralCollected(pickup.mineral)
        floatingText("+1 \(pickup.mineral.name)", at: hero.position + CGVector(dx: 0, dy: 34),
                     color: SKColor(rgb: Sprites.mineralColors(pickup.mineral).mid), size: 12)
    }

    private func collectPart(_ drop: PartPickupNode) {
        partPickups.removeAll { $0 === drop }
        drop.removeFromParent()
        session?.partCollected(drop.part)
        floatingText("¡PIEZA ESPECIAL!", at: hero.position + CGVector(dx: 0, dy: 44), color: SKColor(rgb: 0xFFCD45), size: 16, duration: 1.5)
    }

    // MARK: - Fin de ronda

    private func checkRoundEnd(_ dt: TimeInterval) {
        guard spawnQueue.isEmpty, enemies.isEmpty else { return }
        if clearTimer == nil {
            clearTimer = 2.5
            pickups.forEach { $0.magnetized = true }
            partPickups.forEach { $0.magnetized = true }
            projectiles.forEach { $0.removeFromParent() }
            projectiles.removeAll()
        }
        clearTimer! -= dt
        if (pickups.isEmpty && partPickups.isEmpty) || clearTimer! <= 0 {
            pickups.forEach(collect)
            partPickups.forEach(collectPart)
            setRunning(false)
            session?.roundCleared()
        }
    }

    // MARK: - Efectos de habilidades

    private func pulse(radius: CGFloat, damage: Double, color: UInt32) {
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = SKColor(rgb: color)
        ring.fillColor = SKColor(rgb: color, alpha: 0.15)
        ring.lineWidth = 4
        ring.position = hero.position
        ring.zPosition = 140
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: radius / 10, duration: 0.25), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        for enemy in enemies where !enemy.isDying && enemy.position.distance(to: hero.position) - enemy.radius <= radius {
            deal(enemy, amount: damage, isCrit: false, source: hero.position, color: SKColor(rgb: color))
            if let ability, !enemy.isDying {
                if ability.burn > 0 { enemy.addBurn(dps: damage * ability.burn / 3) }
                if ability.poison > 0 { enemy.addPoison(dps: damage * ability.poison / 3) }
                if ability.slow > 0 { enemy.applySlow(ability.slow, now: elapsed) }
            }
        }
    }

    private func strike(_ enemy: EnemyNode, damage: Double) {
        let path = CGMutablePath()
        var point = CGPoint(x: enemy.position.x + CGFloat.random(in: -20...20), y: size.height + 10)
        path.move(to: point)
        while point.y > enemy.position.y + 10 {
            point = CGPoint(x: enemy.position.x + CGFloat.random(in: -10...10), y: point.y - 30)
            path.addLine(to: point)
        }
        path.addLine(to: enemy.position)
        let bolt = SKShapeNode(path: path)
        bolt.strokeColor = SKColor(rgb: 0xFFF4C0)
        bolt.lineWidth = 4
        bolt.glowWidth = 3
        bolt.zPosition = 160
        addChild(bolt)
        bolt.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
        burst(at: enemy.position, color: SKColor(rgb: 0xFFE066), count: 12)
        deal(enemy, amount: damage, isCrit: true, source: nil, color: SKColor(rgb: 0xFFE066))
    }

    private func chainLightning(from first: EnemyNode, jumps: Int, damage: Double) {
        var current = first
        var hit: Set<ObjectIdentifier> = [ObjectIdentifier(first)]
        for _ in 0..<jumps {
            guard let next = enemies
                .filter({ !$0.isDying && !hit.contains(ObjectIdentifier($0)) && $0.position.distance(to: current.position) < 130 })
                .min(by: { $0.position.distance(to: current.position) < $1.position.distance(to: current.position) }) else { break }
            hit.insert(ObjectIdentifier(next))
            lightningLine(from: current.position, to: next.position)
            let target = next
            current = next
            deal(target, amount: damage, isCrit: false, source: nil, color: SKColor(rgb: 0xFFE066))
        }
    }

    private func lightningLine(from a: CGPoint, to b: CGPoint) {
        let path = CGMutablePath()
        path.move(to: a)
        let steps = 4
        for i in 1..<steps {
            let t = CGFloat(i) / CGFloat(steps)
            path.addLine(to: CGPoint(x: a.x + (b.x - a.x) * t + CGFloat.random(in: -8...8),
                                     y: a.y + (b.y - a.y) * t + CGFloat.random(in: -8...8)))
        }
        path.addLine(to: b)
        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor(rgb: 0xFFE066)
        line.lineWidth = 3
        line.zPosition = 150
        addChild(line)
        line.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
    }

    private func explosion(at point: CGPoint, radius: CGFloat, damage: Double, color: UInt32) {
        let blast = SKShapeNode(circleOfRadius: radius)
        blast.fillColor = SKColor(rgb: color, alpha: 0.35)
        blast.strokeColor = SKColor(rgb: color)
        blast.lineWidth = 3
        blast.position = point
        blast.zPosition = 140
        blast.setScale(0.2)
        addChild(blast)
        blast.run(.sequence([.group([.scale(to: 1, duration: 0.15), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
        for enemy in enemies where !enemy.isDying && enemy.position.distance(to: point) - enemy.radius <= radius {
            deal(enemy, amount: damage, isCrit: false, source: point, color: SKColor(rgb: color))
        }
    }

    // MARK: - Efectos visuales

    private func slashEffect(direction: CGVector, reach: CGFloat) {
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: max(20, reach * 0.75), startAngle: 1.25, endAngle: -1.25, clockwise: true)
        let arc = SKShapeNode(path: path)
        arc.strokeColor = SKColor(rgb: ability != nil ? abilityColor : 0xFFFFFF, alpha: 0.9)
        arc.lineWidth = 4
        arc.lineCap = .square
        arc.position = hero.position
        arc.zRotation = atan2(direction.dy, direction.dx)
        arc.zPosition = 150
        addChild(arc)
        arc.run(.sequence([.group([.fadeOut(withDuration: 0.18), .scale(to: 1.15, duration: 0.18)]), .removeFromParent()]))
    }

    private func dust(at point: CGPoint) {
        for i in 0..<2 {
            let puff = SKSpriteNode(color: SKColor(rgb: 0xD8D0C0, alpha: 0.7), size: CGSize(width: PX * 2, height: PX * 2))
            puff.position = point + CGVector(dx: CGFloat(i * 6 - 3), dy: 0)
            puff.zPosition = 5
            addChild(puff)
            puff.run(.sequence([
                .group([.moveBy(x: CGFloat.random(in: -6...6), y: 8, duration: 0.35), .fadeOut(withDuration: 0.35), .scale(to: 0.4, duration: 0.35)]),
                .removeFromParent(),
            ]))
        }
    }

    private func statusParticle(on enemy: EnemyNode, color: UInt32) {
        let bit = SKSpriteNode(color: SKColor(rgb: color), size: CGSize(width: PX * 1.4, height: PX * 1.4))
        bit.position = enemy.position + CGVector(dx: CGFloat.random(in: -10...10), dy: CGFloat.random(in: -4...enemy.size.height / 3))
        bit.zPosition = 145
        addChild(bit)
        bit.run(.sequence([.group([.moveBy(x: 0, y: 18, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
    }

    private func burst(at point: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let bit = SKSpriteNode(color: Bool.random() ? color : .white, size: CGSize(width: PX, height: PX))
            bit.position = point
            bit.zPosition = 140
            addChild(bit)
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let distance = CGFloat.random(in: 12...34)
            bit.run(.sequence([
                .group([.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.3), .fadeOut(withDuration: 0.3)]),
                .removeFromParent(),
            ]))
        }
    }

    private func shake(intensity: CGFloat) {
        let moves = (0..<6).map { _ in
            SKAction.moveBy(x: CGFloat.random(in: -intensity...intensity), y: CGFloat.random(in: -intensity...intensity), duration: 0.03)
        }
        groundNode?.run(.sequence(moves + [.move(to: CGPoint(x: 0, y: size.height), duration: 0.03)]))
    }

    private func floatingText(_ text: String, at point: CGPoint, color: SKColor, size: CGFloat, duration: TimeInterval = 0.7) {
        let node = SKNode()
        node.position = point
        node.zPosition = 200
        let shadow = SKLabelNode(fontNamed: "Menlo-Bold")
        shadow.text = text
        shadow.fontSize = size
        shadow.fontColor = .black
        shadow.position = CGPoint(x: 1.5, y: -1.5)
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.zPosition = 0.1
        node.addChild(shadow)
        node.addChild(label)
        addChild(node)
        node.run(.sequence([
            .group([.moveBy(x: 0, y: 26, duration: duration), .sequence([.wait(forDuration: duration * 0.6), .fadeOut(withDuration: duration * 0.4)])]),
            .removeFromParent(),
        ]))
    }

    // MARK: - Utilidades

    private func clamp(_ p: CGPoint) -> CGPoint {
        let a = arena
        return CGPoint(x: min(a.maxX, max(a.minX, p.x)), y: min(a.maxY, max(a.minY, p.y)))
    }

    /// Lo que está más abajo en pantalla se dibuja delante.
    private func depth(for y: CGFloat) -> CGFloat {
        10 + (1 - y / max(1, size.height)) * 50
    }
}
