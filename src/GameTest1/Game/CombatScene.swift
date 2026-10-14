import GameCore
import SpriteKit

/// Quien recibe los eventos del combate (la sesión de la arena o la del pueblo).
protocol CombatDelegate: AnyObject {
    /// Dirección del joystick / teclado (-1...1).
    var joystick: CGVector { get }
    func heroHPChanged(hp: Double, maxHP: Double)
    func heroWasHit()
    func heroDied()
    func enemyKilled(_ enemy: EnemyDefinition)
    func mineralCollected(_ mineral: Mineral)
    func partCollected(_ part: WeaponPart)
}

/// Combate compartido por la arena y el pueblo: héroe, enemigos, proyectiles, botín,
/// habilidades y efectos. Las subclases deciden el escenario y las reglas de movimiento.
class CombatScene: SKScene {
    weak var combatDelegate: CombatDelegate?

    let hero = HeroNode()

    var enemies: [EnemyNode] = []

    var projectiles: [ProjectileNode] = []

    var pickups: [MineralPickupNode] = []

    var partPickups: [PartPickupNode] = []

    var attackTimer: TimeInterval = 0

    var attackCount = 0

    var dustTimer: TimeInterval = 0

    var lastTime: TimeInterval = 0

    var elapsed: TimeInterval = 0

    var running = false

    var stats = Race.human.baseStats

    var ability: Ability?

    var hp: Double = 100

    var reportedHP = -1

    var rng = SystemRandomNumberGenerator()

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

    func updateHero(_ dt: TimeInterval) {
        let input = movementInput()
        let magnitude = min(1, input.length)
        if magnitude > 0.05 {
            let dir = input.normalized
            hero.position = moveHero(from: hero.position, to: hero.position + dir * (CGFloat(stats.moveSpeed * dt) * magnitude))
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
        // Se ordena por los pies (como edificios, árboles y aldeanos), no por el centro del dibujo.
        hero.zPosition = depth(for: hero.position.y - hero.size.height / 2 + 8)
        if stats.regen > 0, hp < stats.maxHP {
            hp = min(stats.maxHP, hp + stats.regen * dt)
            reportHP()
        }
    }

    func updateHeroAttack(_ dt: TimeInterval) {
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
           // Solo los que ya pelean: en la exploración, el rayo despertaba a jefes del otro extremo del mapa.
           let strongest = enemies.filter({ !$0.isDying && isActive($0) }).max(by: { $0.hp < $1.hp }) {
            strike(strongest, damage: stats.attack * ability.strikeDamage)
        }
    }

    var abilityColor: UInt32 {
        ability?.elements.first?.color ?? 0xFFFFFF
    }

    func applyHit(_ enemy: EnemyNode, hit: Combat.Hit, primary: Bool) {
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

    @discardableResult
    func deal(_ enemy: EnemyNode, amount: Double, isCrit: Bool, source: CGPoint?, color: SKColor? = nil) -> Bool {
        guard !enemy.isDying else { return false }
        // Pegar a enemigos de más nivel cuesta; a los de menos, se nota.
        let amount = amount * Leveling.damageFactor(attackerLevel: heroLevel, defenderLevel: enemy.level)
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

    func heroHit(by raw: Double) {
        let amount = Combat.incomingDamage(raw: raw, defense: stats.defense)
        hp -= amount
        hero.hurtFlash()
        floatingText("-\(Int(amount.rounded()))", at: hero.position + CGVector(dx: 0, dy: 26), color: SKColor(rgb: 0xFF5050), size: 13)
        reportHP()
        combatDelegate?.heroWasHit()
        if hp <= 0 {
            hp = 0
            running = false
            hero.setWalking(false)
            hero.playDeath()
            run(.sequence([.wait(forDuration: 1.2), .run { [weak self] in self?.combatDelegate?.heroDied() }]))
        }
    }

    func reportHP() {
        let rounded = Int(hp.rounded(.up))
        guard rounded != reportedHP else { return }
        reportedHP = rounded
        combatDelegate?.heroHPChanged(hp: hp, maxHP: stats.maxHP)
    }

    func updateEnemies(_ dt: TimeInterval) {
        for enemy in enemies where !enemy.isDying {
            guard isActive(enemy) else { continue }
            let previous = enemy.position
            if let action = enemy.step(dt: dt, now: elapsed, target: chaseTarget(for: enemy), heroRadius: HeroNode.bodyRadius) {
                switch action {
                case .hit(let damage):
                    heroHit(by: damage * Leveling.damageFactor(attackerLevel: enemy.level, defenderLevel: heroLevel))
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
            if !enemy.isDying { constrain(enemy, previous: previous) }
        }
        // Separar puede empujar los pies a una casilla sólida (agua, muro): se vuelve a ajustar
        // desde la posición válida de antes del empujón.
        let beforePush = enemies.map(\.position)
        separateEnemies()
        for (enemy, previous) in zip(enemies, beforePush) where enemy.position != previous {
            constrain(enemy, previous: previous)
        }
        for enemy in enemies { enemy.zPosition = depth(for: enemy.position.y - enemy.size.height / 2 + 6) }
    }

    func shoot(from enemy: EnemyNode, damage: Double) {
        let dir = (hero.position - enemy.position).normalized
        let scaled = damage * Leveling.damageFactor(attackerLevel: enemy.level, defenderLevel: heroLevel)
        let projectile = ProjectileNode(enemyID: enemy.definition.id, damage: scaled, velocity: dir * 210)
        projectile.position = enemy.position + CGVector(dx: dir.dx * enemy.radius, dy: 6)
        projectile.zPosition = 120
        addChild(projectile)
        projectiles.append(projectile)
    }

    func updateProjectiles(_ dt: TimeInterval) {
        for projectile in projectiles.reversed() {
            projectile.position = projectile.position + projectile.velocity * CGFloat(dt)
            projectile.life -= dt
            if projectile.position.distance(to: hero.position) < HeroNode.bodyRadius + 4 {
                heroHit(by: projectile.damage)
                remove(projectile)
                if !running { return }
            } else if projectile.life <= 0 || blocksShot(at: projectile.position) {
                remove(projectile)
            }
        }
    }

    func remove(_ projectile: ProjectileNode) {
        projectiles.removeAll { $0 === projectile }
        projectile.removeFromParent()
    }

    func separateEnemies() {
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

    func kill(_ enemy: EnemyNode) {
        guard !enemy.isDying else { return }
        enemy.isDying = true
        enemies.removeAll { $0 === enemy }
        enemyDied(enemy)
        combatDelegate?.enemyKilled(enemy.definition)

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

        for mineral in enemy.stats.rollDrops(in: lootContinent, using: &rng) {
            let pickup = MineralPickupNode(mineral: mineral)
            pickup.position = enemy.position + CGVector(dx: CGFloat.random(in: -18...18, using: &rng), dy: CGFloat.random(in: -12...12, using: &rng))
            pickup.zPosition = -2
            addChild(pickup)
            pickups.append(pickup)
        }
        if enemy.definition.isBoss, dropsSpecialPart(enemy), let partID = PartCatalog.bossPartID(for: enemy.definition, continent: lootContinent),
           let part = PartCatalog.part(partID) {
            let drop = PartPickupNode(part: part)
            drop.position = enemy.position
            drop.zPosition = 5
            addChild(drop)
            partPickups.append(drop)
            shake(intensity: 10)
            floatingText("¡\(part.name)!", at: enemy.position + CGVector(dx: 0, dy: 50), color: SKColor(rgb: 0xFFCD45), size: 16, duration: 2)
        }
    }

    func updatePickups(_ dt: TimeInterval) {
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

    func collect(_ pickup: MineralPickupNode) {
        pickups.removeAll { $0 === pickup }
        pickup.removeFromParent()
        combatDelegate?.mineralCollected(pickup.mineral)
        floatingText("+1 \(pickup.mineral.name)", at: hero.position + CGVector(dx: 0, dy: 34),
                     color: SKColor(rgb: Sprites.mineralColors(pickup.mineral).mid), size: 12)
    }

    func collectPart(_ drop: PartPickupNode) {
        partPickups.removeAll { $0 === drop }
        drop.removeFromParent()
        combatDelegate?.partCollected(drop.part)
        floatingText("¡PIEZA ESPECIAL!", at: hero.position + CGVector(dx: 0, dy: 44), color: SKColor(rgb: 0xFFCD45), size: 16, duration: 1.5)
    }

    func pulse(radius: CGFloat, damage: Double, color: UInt32) {
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

    func strike(_ enemy: EnemyNode, damage: Double) {
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

    func chainLightning(from first: EnemyNode, jumps: Int, damage: Double) {
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

    func lightningLine(from a: CGPoint, to b: CGPoint) {
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

    func explosion(at point: CGPoint, radius: CGFloat, damage: Double, color: UInt32) {
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

    func slashEffect(direction: CGVector, reach: CGFloat) {
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

    func dust(at point: CGPoint) {
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

    func statusParticle(on enemy: EnemyNode, color: UInt32) {
        let bit = SKSpriteNode(color: SKColor(rgb: color), size: CGSize(width: PX * 1.4, height: PX * 1.4))
        bit.position = enemy.position + CGVector(dx: CGFloat.random(in: -10...10), dy: CGFloat.random(in: -4...enemy.size.height / 3))
        bit.zPosition = 145
        addChild(bit)
        bit.run(.sequence([.group([.moveBy(x: 0, y: 18, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
    }

    func burst(at point: CGPoint, color: SKColor, count: Int) {
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

    func floatingText(_ text: String, at point: CGPoint, color: SKColor, size: CGFloat, duration: TimeInterval = 0.7) {
        let node = SKNode()
        node.name = Self.floatingTextName
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

    /// Halo de luz suave (degradado radial) del color indicado, para mezclar en modo aditivo.
    func makeGlow(radius: CGFloat, color: UInt32, alpha: CGFloat) -> SKSpriteNode {
        let glow = SKSpriteNode(texture: Self.glowTexture)
        glow.size = CGSize(width: radius * 2, height: radius * 2)
        glow.color = SKColor(rgb: color)
        glow.colorBlendFactor = 1
        glow.alpha = alpha
        glow.blendMode = .add
        return glow
    }

    private static let glowTexture: SKTexture = {
        let n = 64
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 0.45), CGColor(gray: 1, alpha: 0)] as CFArray
        let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.4, 1])!
        let c = CGPoint(x: CGFloat(n) / 2, y: CGFloat(n) / 2)
        ctx.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: CGFloat(n) / 2, options: [])
        return SKTexture(cgImage: ctx.makeImage()!)
    }()

    /// Efecto de subir de nivel sobre el héroe.
    func levelUpEffect(_ level: Int) {
        floatingText("¡NIVEL \(level)!", at: hero.position + CGVector(dx: 0, dy: 60), color: SKColor(rgb: 0xFFCD45), size: 22, duration: 1.8)
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.strokeColor = SKColor(rgb: 0xFFCD45)
        ring.lineWidth = 4
        ring.position = CGPoint(x: hero.position.x, y: hero.position.y - hero.size.height / 2 + 10)
        ring.zPosition = 140
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: 4, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
        burst(at: hero.position, color: SKColor(rgb: 0xFFE9A0), count: 24)
    }

    func depth(for y: CGFloat) -> CGFloat {
        10 + (1 - y / max(1, worldHeight)) * 50
    }

    /// Nivel del héroe (para la diferencia de nivel en combate).
    var heroLevel = 1

    /// Equipa al héroe y fija sus estadísticas y vida.
    func prepareHero(stats: Stats, hp: Double, look: HeroLook, weapon: Item?, level: Int = 1) {
        self.stats = stats
        self.heroLevel = level
        self.ability = weapon?.ability
        self.hp = min(hp, stats.maxHP)
        reportedHP = -1
        hero.setEquipment(look: look, weapon: weapon)
        reportHP()
    }

    /// Quita enemigos, proyectiles y botín (al cambiar de zona).
    static let floatingTextName = "floatingText"

    func clearCombat() {
        for node in enemies as [SKNode] + projectiles as [SKNode] + pickups as [SKNode] + partPickups as [SKNode] {
            node.removeFromParent()
        }
        children.filter { $0.name == Self.floatingTextName }.forEach { $0.removeFromParent() }
        enemies.removeAll()
        projectiles.removeAll()
        pickups.removeAll()
        partPickups.removeAll()
    }

    // MARK: - Ganchos para las subclases

    /// Continente cuya familia de minerales sueltan los monstruos (nil = la tabla de la arena).
    var lootContinent: Continent?

    /// ¿Suelta este jefe su pieza única? (en las mazmorras de historia repetidas, no siempre).
    func dropsSpecialPart(_ enemy: EnemyNode) -> Bool { true }

    /// Hacia dónde quiere ir el héroe este frame (-1...1). Por defecto, el joystick o el teclado; la exploración
    /// lo sustituye mientras el héroe camina solo hasta un NPC tocado.
    func movementInput() -> CGVector { combatDelegate?.joystick ?? .zero }

    /// Nueva posición del héroe tras moverse (límites, colisiones…).
    func moveHero(from old: CGPoint, to new: CGPoint) -> CGPoint { new }

    /// Corrige la posición de un enemigo después de moverse.
    func constrain(_ enemy: EnemyNode, previous: CGPoint) {}

    /// ¿Para un muro (o edificio, acantilado…) este disparo enemigo?
    func blocksShot(at point: CGPoint) -> Bool { false }

    /// ¿Este enemigo actúa en este frame? (En el pueblo solo los que te han visto.)
    func isActive(_ enemy: EnemyNode) -> Bool { true }

    /// Hacia dónde camina un enemigo. Por defecto, directo al héroe; un mapa con obstáculos
    /// puede devolver un punto en la dirección del camino (a la misma distancia que el héroe o más).
    func chaseTarget(for enemy: EnemyNode) -> CGPoint { hero.position }

    /// Aviso de que un enemigo acaba de morir (antes de soltar el botín).
    func enemyDied(_ enemy: EnemyNode) {}

    /// Nodo que tiembla con los golpes fuertes.
    var shakeNode: SKNode? { nil }

    /// Alto del mundo, para ordenar la profundidad (lo de abajo se dibuja delante).
    var worldHeight: CGFloat { size.height }

    func shake(intensity: CGFloat) {
        guard let node = shakeNode, node.action(forKey: "shake") == nil else { return }
        let origin = node.position
        let moves = (0..<6).map { _ in
            SKAction.moveBy(x: CGFloat.random(in: -intensity...intensity), y: CGFloat.random(in: -intensity...intensity), duration: 0.03)
        }
        node.run(.sequence(moves + [.move(to: origin, duration: 0.03)]), withKey: "shake")
    }

    /// Avanza toda la simulación de combate un frame.
    func updateCombat(_ dt: TimeInterval) {
        elapsed += dt
        updateHero(dt)
        updateEnemies(dt)
        guard running else { return }
        updateProjectiles(dt)
        guard running else { return }
        updateHeroAttack(dt)
        updatePickups(dt)
    }

    /// Tiempo transcurrido desde el último frame (0 en el primero).
    func frameDelta(_ currentTime: TimeInterval) -> TimeInterval {
        let dt = lastTime == 0 ? 0 : min(1.0 / 20, currentTime - lastTime)
        lastTime = currentTime
        return dt
    }

}
