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

private func makeShadow(width: CGFloat, yOffset: CGFloat) -> SKShapeNode {
    let shadow = SKShapeNode(ellipseOf: CGSize(width: width, height: width * 0.35))
    shadow.fillColor = SKColor(white: 0, alpha: 0.28)
    shadow.strokeColor = .clear
    shadow.position = CGPoint(x: 0, y: yOffset)
    shadow.zPosition = -0.5
    return shadow
}

// MARK: - Caballero

final class KnightNode: SKSpriteNode {
    static let bodyRadius: CGFloat = 16
    private static let restAngle: CGFloat = -0.35

    private(set) var armorIcon = ""
    private let weaponPivot = SKNode()
    private let weapon = SKSpriteNode()
    private var isWalking = false
    private(set) var facing: CGFloat = 1

    init() {
        super.init(texture: nil, color: .white, size: CGSize(width: 16 * PX, height: 16 * PX))
        addChild(makeShadow(width: 34, yOffset: -size.height / 2 + 2))

        weaponPivot.position = CGPoint(x: 4 * PX, y: -2.5 * PX)
        weaponPivot.zPosition = 0.2
        weaponPivot.zRotation = Self.restAngle
        addChild(weaponPivot)
        weapon.anchorPoint = CGPoint(x: 5.5 / 12, y: 1.5 / 12)
        weapon.size = CGSize(width: 12 * PX * 0.85, height: 12 * PX * 0.85)
        weaponPivot.addChild(weapon)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    func setEquipment(armorIcon: String, weaponIcon: String) {
        self.armorIcon = armorIcon
        weapon.texture = Art.itemTexture(icon: weaponIcon)
        isWalking = false
        removeAction(forKey: "walk")
        texture = Art.knightTexture(.idle, armorIcon: armorIcon)
    }

    func setWalking(_ walking: Bool) {
        guard walking != isWalking else { return }
        isWalking = walking
        if walking {
            let frames = [Art.knightTexture(.walkA, armorIcon: armorIcon), Art.knightTexture(.walkB, armorIcon: armorIcon)]
            run(.repeatForever(.animate(with: frames, timePerFrame: 0.13)), withKey: "walk")
        } else {
            removeAction(forKey: "walk")
            texture = Art.knightTexture(.idle, armorIcon: armorIcon)
        }
    }

    func face(dx: CGFloat) {
        guard abs(dx) > 0.05 else { return }
        facing = dx > 0 ? 1 : -1
        xScale = facing
    }

    func swing() {
        weaponPivot.removeAction(forKey: "swing")
        weaponPivot.run(.sequence([
            .rotate(toAngle: 0.7, duration: 0.05),
            .rotate(toAngle: -2.3, duration: 0.07),
            .wait(forDuration: 0.04),
            .rotate(toAngle: Self.restAngle, duration: 0.14),
        ]), withKey: "swing")
    }

    func hurtFlash() {
        run(.sequence([
            .colorize(with: .red, colorBlendFactor: 0.75, duration: 0.04),
            .colorize(withColorBlendFactor: 0, duration: 0.18),
        ]), withKey: "hurt")
    }

    func playDeath() {
        removeAllActions()
        run(.group([
            .rotate(toAngle: facing * .pi / 2, duration: 0.3),
            .colorize(with: .red, colorBlendFactor: 0.6, duration: 0.3),
            .sequence([.wait(forDuration: 0.5), .fadeAlpha(to: 0.4, duration: 0.4)]),
        ]))
    }
}

// MARK: - Goblin

final class GoblinNode: SKSpriteNode {
    let kind: MonsterKind
    let stats: MonsterStats
    let radius: CGFloat
    private(set) var hp: Double
    private var attackTimer: TimeInterval
    private var knockback = CGVector.zero
    private let hpBarFill: SKSpriteNode
    private let hpBar = SKNode()
    var isDying = false

    static func visualScale(_ kind: MonsterKind) -> CGFloat {
        switch kind {
        case .goblin: 1
        case .goblinRunner: 0.85
        case .goblinBrute: 1.5
        case .goblinKing: 2.3
        }
    }

    init(kind: MonsterKind, level: Int) {
        self.kind = kind
        self.stats = kind.stats(level: level)
        self.hp = stats.hp
        self.radius = CGFloat(kind.bodyRadius)
        self.attackTimer = TimeInterval.random(in: 0.3...stats.attackCooldown)
        let scale = Self.visualScale(kind)
        let textures = Art.goblinTextures(kind)
        let spriteSize = CGSize(width: 14 * PX * scale, height: 14 * PX * scale)

        let barWidth = max(26, spriteSize.width * 0.6)
        hpBarFill = SKSpriteNode(color: SKColor(red: 0.89, green: 0.23, blue: 0.27, alpha: 1),
                                 size: CGSize(width: barWidth, height: 3))
        super.init(texture: textures[0], color: .white, size: spriteSize)

        addChild(makeShadow(width: spriteSize.width * 0.6, yOffset: -spriteSize.height / 2 + 3 * scale))

        let back = SKSpriteNode(color: .black, size: CGSize(width: barWidth + 2, height: 5))
        hpBar.addChild(back)
        hpBarFill.zPosition = 0.01
        hpBar.addChild(hpBarFill)
        hpBar.position = CGPoint(x: 0, y: spriteSize.height / 2 + 4)
        hpBar.zPosition = 0.3
        hpBar.isHidden = !kind.isBoss
        addChild(hpBar)

        if kind == .goblinKing {
            let crown = SKSpriteNode(texture: Art.crown, size: CGSize(width: 7 * PX * 1.4, height: 4 * PX * 1.4))
            crown.position = CGPoint(x: 0, y: spriteSize.height / 2 - 2)
            crown.zPosition = 0.1
            addChild(crown)
        }

        let frameTime = kind == .goblinRunner ? 0.1 : 0.18
        run(.repeatForever(.animate(with: textures, timePerFrame: frameTime)), withKey: "walk")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) no soportado") }

    /// Mueve el goblin hacia el objetivo. Devuelve el daño si ataca en este frame.
    func step(dt: TimeInterval, target: CGPoint, contactDistance: CGFloat) -> Double? {
        let toTarget = target - position
        let distance = toTarget.length
        if abs(toTarget.dx) > 2 { xScale = toTarget.dx > 0 ? 1 : -1 }

        position = position + knockback * CGFloat(dt)
        knockback = knockback * CGFloat(max(0, 1 - 10 * dt))

        attackTimer -= dt
        if distance > contactDistance {
            position = position + toTarget.normalized * CGFloat(stats.speed * dt)
            attackTimer = max(attackTimer, 0.25)
            return nil
        }
        guard attackTimer <= 0 else { return nil }
        attackTimer = stats.attackCooldown
        let lunge = toTarget.normalized * 6
        run(.sequence([.moveBy(x: lunge.dx, y: lunge.dy, duration: 0.06), .moveBy(x: -lunge.dx, y: -lunge.dy, duration: 0.1)]))
        return stats.damage
    }

    /// Aplica daño. Devuelve `true` si muere.
    func takeDamage(_ amount: Double, from source: CGPoint) -> Bool {
        hp -= amount
        hpBar.isHidden = false
        hpBarFill.xScale = CGFloat(max(0, hp / stats.hp))
        run(.sequence([
            .colorize(with: .white, colorBlendFactor: 0.9, duration: 0.03),
            .colorize(withColorBlendFactor: 0, duration: 0.12),
        ]), withKey: "hit")
        let force: CGFloat = kind.isBoss ? 30 : (kind == .goblinBrute ? 80 : 190)
        knockback = (position - source).normalized * force
        return hp <= 0
    }

    func push(_ offset: CGVector) {
        position = position + offset
    }
}

// MARK: - Mineral en el suelo

final class MineralPickupNode: SKNode {
    let mineral: Mineral
    var magnetized = false
    private let gem: SKSpriteNode

    init(mineral: Mineral) {
        self.mineral = mineral
        gem = SKSpriteNode(texture: Art.mineralTexture(mineral), size: CGSize(width: 7 * PX * 0.9, height: 7 * PX * 0.9))
        super.init()
        addChild(makeShadow(width: 14, yOffset: -8))
        gem.zPosition = 0.1
        addChild(gem)

        // Salta al aparecer y luego flota.
        let pop = SKAction.sequence([
            .moveBy(x: 0, y: 18, duration: 0.15),
            .moveBy(x: 0, y: -18, duration: 0.2),
        ])
        pop.timingMode = .easeOut
        let bob = SKAction.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 0.5),
            .moveBy(x: 0, y: -3, duration: 0.5),
        ]))
        gem.run(.sequence([pop, bob]))

        if mineral.rarityTier >= 7 {
            // Destello para minerales raros.
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
