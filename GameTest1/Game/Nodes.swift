import GameCore
import SpriteKit

extension CGPoint {
    static func + (l: CGPoint, r: CGVector) -> CGPoint { CGPoint(x: l.x + r.dx, y: l.y + r.dy) }
    static func - (l: CGPoint, r: CGPoint) -> CGVector { CGVector(dx: l.x - r.x, dy: l.y - r.y) }
    func distance(to other: CGPoint) -> CGFloat { hypot(x - other.x, y - other.y) }
}

extension CGVector {
    var length: CGFloat { hypot(dx, dy) }
    var normalized: CGVector {
        let len = length
        return len > 0.0001 ? CGVector(dx: dx / len, dy: dy / len) : .zero
    }
    static func * (v: CGVector, s: CGFloat) -> CGVector { CGVector(dx: v.dx * s, dy: v.dy * s) }
}

extension SKColor {
    convenience init(rgb: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: alpha)
    }
}

func makeShadow(width: CGFloat, yOffset: CGFloat) -> SKShapeNode {
    let shadow = SKShapeNode(ellipseOf: CGSize(width: width, height: width * 0.35))
    shadow.fillColor = SKColor(white: 0, alpha: 0.3)
    shadow.strokeColor = .clear
    shadow.position = CGPoint(x: 0, y: yOffset)
    shadow.zPosition = -0.5
    return shadow
}

// MARK: - Héroe

final class HeroNode: SKSpriteNode {
    static let bodyRadius: CGFloat = 18
    /// Escala del sprite chibi respecto al pixel de arte.
    static let artScale: CGFloat = PX * 0.8
    private static let restAngle: CGFloat = -0.3

    private var armorIcon = ""
    private var race = Race.human
    private let weaponPivot = SKNode()
    private let weapon = SKSpriteNode()
    private(set) var isWalking = false
    private var isAttacking = false
    private(set) var facing: CGFloat = 1

    init() {
        let size = CGSize(width: CGFloat(HeroArt.canvasWidth + 2) * Self.artScale,
                          height: CGFloat(HeroArt.canvasHeight + 2) * Self.artScale)
        super.init(texture: nil, color: .white, size: size)
        addChild(makeShadow(width: 40, yOffset: -size.height / 2 + 6))
        weaponPivot.zPosition = 0.2
        weaponPivot.zRotation = Self.restAngle
        addChild(weaponPivot)
        weaponPivot.addChild(weapon)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    private func texture(_ pose: HeroArt.Pose) -> SKTexture {
        Art.heroTexture(pose, armorIcon: armorIcon, race: race)
    }

    /// Posición de la mano para un frame, en coordenadas del nodo.
    private func handPosition(_ pose: HeroArt.Pose) -> CGPoint {
        let p = HeroArt.hand(race: race, pose: pose)
        let w = CGFloat(HeroArt.canvasWidth + 2), h = CGFloat(HeroArt.canvasHeight + 2)
        return CGPoint(x: (p.x - w / 2) * Self.artScale, y: (h / 2 - p.y) * Self.artScale)
    }

    func setEquipment(armorIcon: String, weapon item: Item?, race: Race) {
        self.armorIcon = armorIcon
        self.race = race
        isWalking = false
        isAttacking = false
        weaponPivot.removeAllActions()
        weaponPivot.position = handPosition(.idle0)
        weaponPivot.zRotation = Self.restAngle
        startLoop()

        guard let item else { weapon.texture = nil; return }
        let texture = Art.itemTexture(item)
        weapon.texture = texture
        let w = texture.size().width, h = texture.size().height
        if item.partIDs != nil {
            // Arma forjada (18x25): se agarra por la empuñadura.
            weapon.size = CGSize(width: w * PX * 0.95, height: h * PX * 0.95)
            weapon.anchorPoint = CGPoint(x: 0.5, y: 1 - (WeaponArt.gripPoint.y + 1) / h)
        } else {
            weapon.size = CGSize(width: w * PX * 1.2, height: h * PX * 1.2)
            weapon.anchorPoint = CGPoint(x: 5.5 / 12, y: 1.5 / 12)
        }
    }

    /// Animación de base: respirar (con parpadeo) o caminar.
    private func startLoop() {
        removeAction(forKey: "loop")
        texture = texture(isWalking ? .walk0 : .idle0)
        let action: SKAction
        if isWalking {
            let frames = [HeroArt.Pose.walk0, .walk1, .walk2, .walk3].map(texture)
            action = .repeatForever(.animate(with: frames, timePerFrame: 0.11))
            weaponPivot.removeAction(forKey: "bob")
            weaponPivot.run(.repeatForever(.sequence([
                .move(to: handPosition(.walk1), duration: 0.11),
                .move(to: handPosition(.walk0), duration: 0.11),
            ])), withKey: "bob")
        } else {
            let breathe = SKAction.sequence([
                .setTexture(texture(.idle0)), .wait(forDuration: 0.5),
                .setTexture(texture(.idle1)), .wait(forDuration: 0.5),
                .setTexture(texture(.idle0)), .wait(forDuration: 0.5),
                .setTexture(texture(.idle1)), .wait(forDuration: 0.35),
                .setTexture(texture(.idle2)), .wait(forDuration: 0.15),
            ])
            action = .repeatForever(breathe)
            weaponPivot.removeAction(forKey: "bob")
            let low = handPosition(.idle1), high = handPosition(.idle0)
            weaponPivot.run(.repeatForever(.sequence([
                .move(to: high, duration: 0.5), .move(to: low, duration: 0.5),
            ])), withKey: "bob")
        }
        run(action, withKey: "loop")
    }

    func setWalking(_ walking: Bool) {
        guard walking != isWalking else { return }
        isWalking = walking
        if !isAttacking { startLoop() }
    }

    func face(dx: CGFloat) {
        guard abs(dx) > 0.05 else { return }
        facing = dx > 0 ? 1 : -1
        xScale = facing
    }

    /// Golpe en tres fases: preparación (brazo arriba), tajo (brazo delante) y recuperación.
    func swing(speed: Double) {
        isAttacking = true
        removeAction(forKey: "loop")
        weaponPivot.removeAction(forKey: "bob")
        weaponPivot.removeAction(forKey: "swing")
        // Más rápido cuanta más velocidad de ataque.
        let k = max(0.45, min(1, 1.3 / speed))
        run(.sequence([
            .setTexture(texture(.windup)), .wait(forDuration: 0.07 * k),
            .setTexture(texture(.strike)), .wait(forDuration: 0.11 * k),
            .setTexture(texture(.recover)), .wait(forDuration: 0.09 * k),
            .run { [weak self] in
                self?.isAttacking = false
                self?.startLoop()
            },
        ]), withKey: "attack")
        weaponPivot.run(.sequence([
            .group([.move(to: handPosition(.windup), duration: 0.06 * k), .rotate(toAngle: 1.1, duration: 0.06 * k)]),
            .group([.move(to: handPosition(.strike), duration: 0.06 * k), .rotate(toAngle: -2.2, duration: 0.06 * k)]),
            .wait(forDuration: 0.05 * k),
            .group([.move(to: handPosition(.recover), duration: 0.1 * k), .rotate(toAngle: Self.restAngle, duration: 0.12 * k)]),
        ]), withKey: "swing")
    }

    func hurtFlash() {
        if !isAttacking {
            run(.sequence([.setTexture(texture(.hurt)), .wait(forDuration: 0.14), .run { [weak self] in self?.startLoop() }]), withKey: "loop")
        }
        run(.sequence([
            .colorize(with: .red, colorBlendFactor: 0.75, duration: 0.04),
            .colorize(withColorBlendFactor: 0, duration: 0.18),
        ]), withKey: "hurt")
    }

    func playDeath() {
        removeAllActions()
        weaponPivot.removeAllActions()
        texture = texture(.hurt)
        run(.sequence([
            .moveBy(x: -facing * 10, y: 14, duration: 0.15),
            .group([
                .rotate(toAngle: facing * .pi / 2, duration: 0.3),
                .moveBy(x: -facing * 6, y: -20, duration: 0.3),
                .colorize(with: .red, colorBlendFactor: 0.5, duration: 0.3),
            ]),
            .wait(forDuration: 0.3),
            .fadeAlpha(to: 0.4, duration: 0.4),
        ]))
        weaponPivot.run(.group([.rotate(byAngle: 4, duration: 0.6), .moveBy(x: 30 * facing, y: -10, duration: 0.6)]))
    }
}

// MARK: - Enemigo

enum EnemyAction {
    case hit(Double)
    case shoot(Double)
}

final class EnemyNode: SKSpriteNode {
    let definition: EnemyDefinition
    let stats: MonsterStats
    let radius: CGFloat
    private(set) var hp: Double
    var maxHP: Double { stats.hp }
    var isDying = false
    /// Pasa a `true` al entrar en la zona de juego; desde entonces no puede salir.
    var hasEntered = false

    private var attackTimer: TimeInterval
    private var knockback = CGVector.zero
    private let textures: [SKTexture]
    /// Tiempo restante de la preparación del ataque (el golpe llega al terminar).
    private var windup: TimeInterval?
    private let hpBarFill: SKSpriteNode
    private let hpBar = SKNode()

    // Estados de habilidades
    private struct DoT { var dps: Double; var remaining: Double }
    private var burns: [DoT] = []
    private var poisons: [DoT] = []
    private var slowAmount: Double = 0
    private var slowUntil: TimeInterval = 0
    private var particleTimer: TimeInterval = 0

    // Embestida
    private enum Charge { case approach, windup(Double), dash(Double, CGVector) }
    private var charge = Charge.approach
    private var dashHit = false

    init(definition: EnemyDefinition, level: Int) {
        self.definition = definition
        self.stats = definition.stats(level: level)
        self.hp = stats.hp
        self.radius = CGFloat(definition.bodyRadius)
        self.attackTimer = TimeInterval.random(in: 0.3...max(0.31, stats.attackCooldown))
        let textures = Art.enemyTextures(definition.id)
        self.textures = textures
        let scale = CGFloat(definition.scale)
        let texSize = textures[0].size()
        let spriteSize = CGSize(width: texSize.width * PX * scale, height: texSize.height * PX * scale)

        let barWidth = max(26, spriteSize.width * 0.6)
        hpBarFill = SKSpriteNode(color: SKColor(rgb: definition.isBoss ? 0xFF7A20 : 0xE43B44),
                                 size: CGSize(width: barWidth, height: definition.isBoss ? 5 : 3))
        super.init(texture: textures[0], color: .white, size: spriteSize)

        addChild(makeShadow(width: spriteSize.width * 0.6, yOffset: -spriteSize.height / 2 + 3 * scale))
        let back = SKSpriteNode(color: .black, size: CGSize(width: barWidth + 2, height: hpBarFill.size.height + 2))
        hpBar.addChild(back)
        hpBarFill.zPosition = 0.01
        hpBar.addChild(hpBarFill)
        hpBar.position = CGPoint(x: 0, y: spriteSize.height / 2 + 5)
        hpBar.zPosition = 0.3
        hpBar.isHidden = !definition.isBoss
        addChild(hpBar)

        startWalking()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    // MARK: Animaciones

    private var facingSign: CGFloat { xScale >= 0 ? 1 : -1 }

    private func startWalking() {
        let frameTime = definition.speed > 90 ? 0.1 : 0.2
        run(.repeatForever(.animate(with: Array(textures[0...1]), timePerFrame: frameTime)), withKey: "walk")
    }

    private var windupDuration: TimeInterval {
        if definition.isBoss { return 0.45 }
        if definition.behavior == .ranged { return 0.32 }
        return definition.speed > 95 ? 0.18 : 0.26
    }

    /// Se echa hacia atrás con el arma levantada: aviso de que va a golpear.
    private func playWindup() {
        removeAction(forKey: "walk")
        removeAction(forKey: "pose")
        texture = textures[2]
        run(.group([
            .rotate(toAngle: 0.2 * facingSign, duration: windupDuration * 0.8),
            .scaleY(to: 0.9, duration: windupDuration * 0.8),
        ]), withKey: "pose")
    }

    /// Golpe hacia delante y vuelta a la normalidad.
    private func playStrike(_ dir: CGVector) {
        removeAction(forKey: "pose")
        texture = textures[3]
        let lunge = dir * (definition.behavior == .ranged ? -4 : 10)
        run(.sequence([
            .group([
                .rotate(toAngle: -0.25 * facingSign, duration: 0.05),
                .scaleY(to: 1.08, duration: 0.05),
                .moveBy(x: lunge.dx, y: lunge.dy, duration: 0.05),
            ]),
            .wait(forDuration: 0.08),
            .group([
                .rotate(toAngle: 0, duration: 0.14),
                .scaleY(to: 1, duration: 0.14),
                .moveBy(x: -lunge.dx, y: -lunge.dy, duration: 0.14),
            ]),
            .run { [weak self] in self?.startWalking() },
        ]), withKey: "pose")
    }

    // MARK: Movimiento y ataque

    func step(dt: TimeInterval, now: TimeInterval, target: CGPoint, heroRadius: CGFloat) -> EnemyAction? {
        let toTarget = target - position
        let distance = toTarget.length
        let dir = toTarget.normalized

        position = position + knockback * CGFloat(dt)
        knockback = knockback * CGFloat(max(0, 1 - 10 * dt))

        let slowFactor = now < slowUntil ? 1 - slowAmount : 1
        let speed = CGFloat(stats.speed * slowFactor * dt)
        let contact = heroRadius + radius + CGFloat(stats.attackRange)
        attackTimer -= dt

        // Durante la preparación no se mueve; al terminar llega el golpe (se puede esquivar).
        if let remaining = windup {
            let left = remaining - dt * slowFactor
            guard left <= 0 else { windup = left; return nil }
            windup = nil
            playStrike(dir)
            switch definition.behavior {
            case .ranged: return .shoot(stats.damage)
            default: return distance <= contact * 1.3 ? .hit(stats.damage) : nil
            }
        }
        if abs(toTarget.dx) > 2 { xScale = toTarget.dx > 0 ? 1 : -1 }

        switch definition.behavior {
        case .melee:
            if distance > contact {
                position = position + dir * speed
                attackTimer = max(attackTimer, 0.25)
                return nil
            }
            guard attackTimer <= 0 else { return nil }
            attackTimer = stats.attackCooldown
            windup = windupDuration
            playWindup()
            return nil

        case .ranged:
            let range = CGFloat(stats.attackRange)
            // Primero entran en la zona de juego; solo entonces disparan o retroceden.
            if !hasEntered || distance > range * 0.95 {
                position = position + dir * speed
            } else if distance < range * 0.45 {
                position = position + dir * (-speed * 0.6)
            }
            guard hasEntered, distance <= range * 1.05, attackTimer <= 0 else { return nil }
            attackTimer = stats.attackCooldown
            windup = windupDuration
            playWindup()
            return nil

        case .charger:
            let bodyContact = heroRadius + radius + 6
            switch charge {
            case .approach:
                position = position + dir * speed
                if distance < 180 && attackTimer <= 0 {
                    charge = .windup(0.45)
                    run(.repeat(.sequence([.moveBy(x: 2, y: 0, duration: 0.04), .moveBy(x: -2, y: 0, duration: 0.04)]), count: 5))
                    run(.sequence([.colorize(with: .red, colorBlendFactor: 0.6, duration: 0.2), .colorize(withColorBlendFactor: 0, duration: 0.25)]))
                } else if distance <= bodyContact && attackTimer <= -0.6 {
                    attackTimer = stats.attackCooldown * 0.5
                    lunge(dir)
                    return .hit(stats.damage * 0.5)
                }
            case .windup(let t):
                if t - dt <= 0 {
                    charge = .dash(0.5, dir)
                    removeAction(forKey: "walk")
                    texture = textures[3]
                    run(.group([.scaleY(to: 0.85, duration: 0.08), .rotate(toAngle: -0.15 * facingSign, duration: 0.08)]), withKey: "pose")
                } else {
                    charge = .windup(t - dt)
                }
                dashHit = false
            case .dash(let t, let dashDir):
                position = position + dashDir * CGFloat(stats.speed * 4.2 * dt)
                if t - dt <= 0 {
                    charge = .approach
                    attackTimer = stats.attackCooldown
                    run(.sequence([.group([.scaleY(to: 1, duration: 0.15), .rotate(toAngle: 0, duration: 0.15)]),
                                   .run { [weak self] in self?.startWalking() }]), withKey: "pose")
                } else {
                    charge = .dash(t - dt, dashDir)
                }
                if !dashHit && distance <= bodyContact {
                    dashHit = true
                    return .hit(stats.damage)
                }
            }
            return nil
        }
    }

    private func lunge(_ dir: CGVector) {
        let l = dir * 6
        run(.sequence([.moveBy(x: l.dx, y: l.dy, duration: 0.06), .moveBy(x: -l.dx, y: -l.dy, duration: 0.1)]))
    }

    // MARK: Daño y estados

    /// Aplica daño. Devuelve `true` si muere.
    func takeDamage(_ amount: Double, from source: CGPoint?, flash: Bool = true) -> Bool {
        hp -= amount
        hpBar.isHidden = false
        hpBarFill.xScale = CGFloat(max(0, hp / stats.hp))
        if flash {
            run(.sequence([
                .colorize(with: .white, colorBlendFactor: 0.9, duration: 0.03),
                .colorize(withColorBlendFactor: 0, duration: 0.12),
            ]), withKey: "hit")
            if windup == nil {
                run(.sequence([.scaleY(to: 0.84, duration: 0.04), .scaleY(to: 1, duration: 0.1)]), withKey: "squash")
            }
        }
        if let source {
            let force: CGFloat = definition.isBoss ? 25 : (definition.bodyRadius > 18 ? 70 : 180)
            knockback = (position - source).normalized * force
        }
        return hp <= 0
    }

    func addBurn(dps: Double) {
        burns = [DoT(dps: max(dps, burns.first?.dps ?? 0), remaining: 3)]
    }

    func addPoison(dps: Double) {
        poisons.append(DoT(dps: dps, remaining: 3))
        if poisons.count > 5 { poisons.removeFirst() }
    }

    func applySlow(_ amount: Double, now: TimeInterval) {
        slowAmount = max(amount, now < slowUntil ? slowAmount : 0)
        slowUntil = now + 2
    }

    /// Daño por quemadura/veneno acumulado en este frame. Devuelve (daño, color de partícula).
    func tickStatuses(dt: TimeInterval, now: TimeInterval) -> (Double, UInt32?) {
        var damage = 0.0
        var particle: UInt32?
        func tick(_ list: inout [DoT]) -> Double {
            var d = 0.0
            for i in list.indices {
                let step = min(dt, list[i].remaining)
                d += list[i].dps * step
                list[i].remaining -= dt
            }
            list.removeAll { $0.remaining <= 0 }
            return d
        }
        let burn = tick(&burns), poison = tick(&poisons)
        damage = burn + poison
        particleTimer -= dt
        if damage > 0, particleTimer <= 0 {
            particleTimer = 0.18
            particle = burn >= poison ? 0xFF8A30 : 0x8BD450
        }
        // Tinte azul mientras está ralentizado.
        if action(forKey: "hit") == nil {
            updateTint(slowed: now < slowUntil)
        }
        return (damage, particle)
    }

    private func updateTint(slowed: Bool) {
        if slowed {
            color = SKColor(rgb: 0x8FD8F0)
            colorBlendFactor = 0.45
        } else if colorBlendFactor > 0, action(forKey: "hit") == nil, case .approach = charge {
            colorBlendFactor = 0
        }
    }

    func push(_ offset: CGVector) {
        if case .dash = charge { return }
        position = position + offset
    }
}

// MARK: - Proyectiles

final class ProjectileNode: SKSpriteNode {
    let damage: Double
    let velocity: CGVector
    var life: TimeInterval = 3

    init(enemyID: String, damage: Double, velocity: CGVector) {
        self.damage = damage
        self.velocity = velocity
        let texture = ProjectileNode.texture(for: enemyID)
        super.init(texture: texture, color: .white, size: CGSize(width: texture.size().width * PX, height: texture.size().height * PX))
        zRotation = atan2(velocity.dy, velocity.dx)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    private static func texture(for enemyID: String) -> SKTexture {
        switch enemyID {
        case "goblinSlinger":
            return ArtCache.texture("proj.rock") { PixelSprite(rows: [".R.", "RRr", ".r."], palette: ["R": 0x9A9AA6, "r": 0x5A5A66]) }
        case "skeletonArcher":
            return ArtCache.texture("proj.arrow") { PixelSprite(rows: ["F....S.", "FHHHHSS", "F....S."], palette: ["F": 0xFFFFFF, "H": 0x8F5A32, "S": 0xC0C4CC]) }
        case "goblinBomber":
            return ArtCache.texture("proj.bomb") { PixelSprite(rows: [".Y..", ".BB.", "BBBB", "BBBB", ".BB."], palette: ["B": 0x2A2A3A, "Y": 0xFFB030]) }
        default:
            let color: UInt32 = switch enemyID {
            case "witch": 0x8BD450
            case "necromancer", "abbot": 0xB070FF
            case "cultist": 0xFF4040
            case "goblinMage": 0x41A6F6
            default: 0x73EFF7
            }
            return ArtCache.texture("proj.orb.\(color)") {
                PixelSprite(rows: [".OO.", "OWOO", "OOOO", ".OO."], palette: ["O": color, "W": 0xFFFFFF])
            }
        }
    }
}

// MARK: - Botín

final class MineralPickupNode: SKNode {
    let mineral: Mineral
    var magnetized = false
    private let gem: SKSpriteNode

    init(mineral: Mineral) {
        self.mineral = mineral
        gem = SKSpriteNode(texture: Art.mineralTexture(mineral), size: CGSize(width: 7 * PX * 1.1, height: 7 * PX * 1.1))
        super.init()
        addChild(makeShadow(width: 14, yOffset: -8))
        gem.zPosition = 0.1
        addChild(gem)
        let pop = SKAction.sequence([.moveBy(x: 0, y: 18, duration: 0.15), .moveBy(x: 0, y: -18, duration: 0.2)])
        pop.timingMode = .easeOut
        let bob = SKAction.repeatForever(.sequence([.moveBy(x: 0, y: 3, duration: 0.5), .moveBy(x: 0, y: -3, duration: 0.5)]))
        gem.run(.sequence([pop, bob]))
        if mineral.rarityTier >= 7 {
            gem.run(.repeatForever(.sequence([
                .colorize(with: .white, colorBlendFactor: 0.6, duration: 0.25),
                .colorize(withColorBlendFactor: 0, duration: 0.25),
                .wait(forDuration: 0.6),
            ])))
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }
}

/// Pieza especial que suelta un jefe.
final class PartPickupNode: SKNode {
    let part: WeaponPart
    var magnetized = false

    init(part: WeaponPart) {
        self.part = part
        super.init()
        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = SKColor(rgb: 0xFFCD45, alpha: 0.25)
        glow.strokeColor = SKColor(rgb: 0xFFCD45, alpha: 0.8)
        glow.lineWidth = 2
        glow.run(.repeatForever(.sequence([.scale(to: 1.25, duration: 0.5), .scale(to: 1, duration: 0.5)])))
        addChild(glow)
        let texture = ArtCache.texture(fromImage: Art.partImage(part))
        let icon = SKSpriteNode(texture: texture, size: CGSize(width: texture.size().width * PX * 1.1, height: texture.size().height * PX * 1.1))
        icon.zPosition = 0.1
        icon.run(.repeatForever(.sequence([.moveBy(x: 0, y: 5, duration: 0.6), .moveBy(x: 0, y: -5, duration: 0.6)])))
        addChild(icon)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }
}
