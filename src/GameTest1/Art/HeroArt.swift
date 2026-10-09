import CoreGraphics
import GameCore

/// Héroe chibi por piezas: esqueleto sencillo (caderas, rodillas, tobillos, hombros, codos, manos)
/// animado por pose, cuerpo propio de cada raza y armadura por huecos (casco, peto, guantes, botas).
/// El contorno exterior se añade al final con `.outlined()`.
///
/// Ficheros: HeroPaint (herramientas), HeroBody (razas, caras, peinados), HeroGear (armadura e iconos).
enum HeroArt {
    /// Frames de animación. La carrera tiene 6 frames (`run0`…`run5`) que se repiten en bucle.
    enum Pose: String, CaseIterable {
        case idle0, idle1, idle2
        case run0, run1, run2, run3, run4, run5
        case windup, strike, recover
        case hurt
    }

    static let runPoses: [Pose] = [.run0, .run1, .run2, .run3, .run4, .run5]

    /// Lienzo antes del contorno (el sprite final mide 2 px más en cada eje). Suelo en la última fila.
    static let canvasWidth = 42
    static let canvasHeight = 50

    // MARK: - API del contrato (ver HeroLook.swift)

    /// Dibuja al héroe con su raza, aspecto y armadura en una pose. Devuelve el sprite ya contorneado.
    static func grid(_ look: HeroLook, pose: Pose) -> PixelGrid {
        var painter = Painter(look: look, pose: pose)
        painter.paint()
        return painter.canvas.grid.outlined()
    }

    /// Mano delantera (en pixeles del sprite contorneado) donde se coloca la empuñadura del arma.
    static func hand(_ look: HeroLook, pose: Pose) -> CGPoint {
        let painter = Painter(look: look, pose: pose)
        let h = painter.handPoint
        return CGPoint(x: h.x + 1, y: h.y + 1)
    }

    /// Opciones de personalización de cada raza (pantalla de creación).
    static func options(for race: Race) -> AppearanceOptions { appearanceOptions(race) }

    // MARK: - Esqueleto por pose

    enum Foot { case flat, toe, heel }

    /// Pierna: tobillo respecto a la cadera, en unidades del humano (pierna de 7). La rodilla sale por
    /// cinemática inversa (siempre hacia delante). `grounded` = el pie apoya en el suelo.
    struct LegKey {
        var ankle: V, foot: Foot, grounded: Bool
        init(_ ax: Double, _ ay: Double, _ foot: Foot = .flat, grounded: Bool = true) {
            ankle = V(ax, ay); self.foot = foot; self.grounded = grounded
        }
    }

    /// Brazo: codo y mano respecto al hombro, en unidades del humano (brazo y antebrazo de 4).
    struct ArmKey {
        var elbow: V, hand: V
        init(_ ex: Double, _ ey: Double, _ hx: Double, _ hy: Double) { elbow = V(ex, ey); hand = V(hx, hy) }
    }

    struct Rig {
        /// Caderas y todo lo de arriba (+ = abajo).
        var bob = 0
        /// Solo torso, brazos y cabeza (respiración).
        var breath = 0
        /// Inclinación: desplaza torso, brazos y cabeza (+ = hacia delante).
        var lean = 0
        var headDX = 0, headDY = 0
        var legFront: LegKey, legBack: LegKey
        var armFront: ArmKey, armBack: ArmKey
        var face: Face = .open
        /// Desplazamiento del pelo, penachos y capas sueltas (movimiento secundario).
        var flowX = 0, flowY = 0
        var tail = 0
    }

    // Piernas
    static let legStandF = LegKey(0.5, 7)
    static let legStandB = LegKey(-0.5, 7)
    static let legContactFwd = LegKey(4.4, 6.6, .heel)
    static let legContactBack = LegKey(-4.4, 5.0, .toe, grounded: false)
    static let legDownSupport = LegKey(0.8, 6.0)
    static let legDownTrail = LegKey(-4.4, 3.4, .toe, grounded: false)
    static let legUpPush = LegKey(-3.8, 7.0, .toe)
    static let legUpSwing = LegKey(3.2, 4.0, grounded: false)

    // Brazos
    static let armIdle = ArmKey(0, 3.8, 0.4, 7.4)
    static let armFwd = ArmKey(1.8, 3.2, 5.0, 2.4)
    static let armFwdMid = ArmKey(1.2, 3.6, 4.2, 5.0)
    static let armMid = ArmKey(0.2, 3.8, 2.6, 6.4)
    static let armBackMid = ArmKey(-1.2, 3.5, -1.2, 7.2)
    static let armBack = ArmKey(-2.0, 3.0, -3.4, 6.2)
    /// El brazo de atrás se ve más cuando va hacia atrás (asoma por la espalda).
    static let armBackFar = ArmKey(-2.8, 2.6, -4.8, 5.4)

    static func rig(_ pose: Pose) -> Rig {
        switch pose {
        case .idle0:
            return Rig(legFront: legStandF, legBack: legStandB, armFront: armIdle, armBack: armIdle)
        case .idle1:
            return Rig(breath: 1, legFront: legStandF, legBack: legStandB, armFront: ArmKey(0, 3.8, 0.6, 7.2),
                       armBack: ArmKey(0, 3.8, 0.6, 7.2), flowY: -1, tail: 1)
        case .idle2:
            return Rig(breath: 1, legFront: legStandF, legBack: legStandB, armFront: ArmKey(0, 3.8, 0.6, 7.2),
                       armBack: ArmKey(0, 3.8, 0.6, 7.2), face: .blink, flowY: -1, tail: 1)
        case .run0:
            return Rig(bob: 0, lean: 1, headDX: 1, legFront: legContactFwd, legBack: legContactBack,
                       armFront: armBack, armBack: armFwd, flowX: -1, flowY: -1, tail: 0)
        case .run1:
            return Rig(bob: 1, lean: 1, headDX: 1, legFront: legDownSupport, legBack: legDownTrail,
                       armFront: armBackMid, armBack: armFwdMid, flowX: -1, flowY: -1, tail: 1)
        case .run2:
            return Rig(bob: -1, lean: 1, headDX: 1, legFront: legUpPush, legBack: legUpSwing,
                       armFront: armMid, armBack: armMid, flowX: -2, flowY: 1, tail: 2)
        case .run3:
            return Rig(bob: 0, lean: 1, headDX: 1, legFront: legContactBack, legBack: legContactFwd,
                       armFront: armFwd, armBack: armBackFar, flowX: -1, flowY: -1, tail: 0)
        case .run4:
            return Rig(bob: 1, lean: 1, headDX: 1, legFront: legDownTrail, legBack: legDownSupport,
                       armFront: armFwdMid, armBack: armBackMid, flowX: -1, flowY: -1, tail: 1)
        case .run5:
            return Rig(bob: -1, lean: 1, headDX: 1, legFront: legUpSwing, legBack: legUpPush,
                       armFront: armMid, armBack: armMid, flowX: -2, flowY: 1, tail: 2)
        case .windup:
            return Rig(lean: -1, headDX: -1, legFront: LegKey(2.2, 7), legBack: LegKey(-2.6, 7),
                       armFront: ArmKey(3.4, -0.4, 4.6, -4.6), armBack: ArmKey(1.2, 3.4, 3.4, 6.0), flowX: 1, tail: 0)
        case .strike:
            return Rig(bob: 1, lean: 2, headDX: 1, legFront: LegKey(4.8, 6.0), legBack: LegKey(-5.0, 5.0, .toe),
                       armFront: ArmKey(3.9, 0.6, 7.9, 1.0), armBack: ArmKey(-2.6, 2.4, -4.6, 5.0), face: .shout,
                       flowX: -2, flowY: -1, tail: 2)
        case .recover:
            return Rig(lean: 1, legFront: LegKey(2.6, 7), legBack: LegKey(-2.2, 7),
                       armFront: ArmKey(1.6, 3.4, 4.6, 5.6), armBack: ArmKey(-0.8, 3.6, -0.6, 7.2), flowX: -1, tail: 1)
        case .hurt:
            return Rig(lean: -2, headDX: -1, legFront: LegKey(1.6, 7), legBack: LegKey(-2.6, 7, .heel),
                       armFront: ArmKey(1.6, 2.6, 3.0, 5.6), armBack: ArmKey(-2.4, 2.0, -4.4, 4.2), face: .hurt,
                       flowX: 2, flowY: -1, tail: 0)
        }
    }

    // MARK: - Pintor

    struct Painter {
        let look: HeroLook
        let pose: Pose
        let race: Race
        let body: Body
        let rig: Rig
        let clothes: BaseClothes
        let skin: Ramp
        let hair: Ramp
        let eye: UInt32
        let style: HairStyle
        var canvas = Canvas(width: HeroArt.canvasWidth, height: HeroArt.canvasHeight)
        /// Pixeles de las piernas (muslo y espinilla), para las faldas.
        var legPixels = Set<Pt>()

        init(look: HeroLook, pose: Pose) {
            self.look = look
            self.pose = pose
            race = look.race
            body = HeroArt.body(look.race)
            var rig = HeroArt.rig(pose)
            // NPC con casco bajo el brazo: en reposo dobla el brazo delantero y apoya la mano en la cadera.
            if look.extras.heldHelmet != nil, [.idle0, .idle1, .idle2].contains(pose) { rig.armFront = HeroArt.armHoldHip }
            self.rig = rig
            clothes = HeroArt.baseClothes(look.race)
            let options = HeroArt.appearanceOptions(look.race)
            let a = look.appearance
            func pick(_ list: [UInt32], _ i: Int) -> UInt32 { list[((i % list.count) + list.count) % list.count] }
            let skinColor = pick(options.skinTones, a.skinTone)
            skin = look.race == .werewolf ? Ramp(base: skinColor, spread: 1.25) : Ramp.skin(skinColor)
            hair = Ramp.hair(look.extras.hairColor ?? pick(options.hairColors, a.hairColor))
            eye = pick(options.eyeColors, a.eyeColor)
            let styles = HeroArt.hairStyles(look.race)
            style = styles[((a.hairStyle % styles.count) + styles.count) % styles.count]
        }

        func gear(_ slot: EquipmentSlot) -> GearLook? { look.gear[slot] }

        // Desplazamientos de la pose
        var hipShift: Int { rig.lean / 2 }
        var upper: Pt { Pt(rig.lean, rig.bob + rig.breath) }
        var headOrigin: Pt {
            Pt(body.head.x + rig.lean + rig.headDX, body.head.y + rig.bob + rig.breath + rig.headDY)
        }
        var shoulderFront: V { body.shoulderFront + V(Double(upper.x), Double(upper.y)) }
        var shoulderBack: V { body.shoulderBack + V(Double(upper.x), Double(upper.y)) }

        var handPoint: V { shoulderFront + rig.armFront.hand * body.armK }

        // MARK: Composición

        mutating func paint() {
            if race == .werewolf { drawTail() }
            drawCapeBack()   // extras de NPC (HeroExtras.swift): no hacen nada en el héroe
            drawBackLayers()
            drawArm(rig.armBack, shoulder: shoulderBack, front: false)
            drawLeg(rig.legBack, hipX: body.hipBack, front: false)
            separated { $0.drawLeg($0.rig.legFront, hipX: $0.body.hipFront, front: true) }
            separated(sides: true) { $0.drawTorso() }
            if !look.extras.isEmpty {
                drawTabardAndWear()
                drawCapeClasp()
            }
            drawNeck()
            drawHead()
            drawBeard()
            if look.extras.heldHelmet != nil { separated { $0.drawHeldHelmet() } }
            separated { $0.drawArm($0.rig.armFront, shoulder: $0.shoulderFront, front: true) }
        }

        /// Dibuja algo y oscurece los pixeles de debajo que lo rodean: línea interior que separa
        /// una pieza de lo que tapa (pierna delantera, brazo, torso).
        mutating func separated(sides: Bool = false, _ draw: (inout Painter) -> Void) {
            let before = canvas.color
            draw(&self)
            let w = canvas.width, h = canvas.height
            var changed = Set<Int>()
            for i in 0..<before.count where canvas.color[i] != before[i] { changed.insert(i) }
            var edge = Set<Int>()
            let dirs = sides ? [(-1, 0), (1, 0)] : [(-1, 0), (1, 0), (0, -1), (0, 1)]
            for i in changed {
                let x = i % w, y = i / w
                for (dx, dy) in dirs {
                    let nx = x + dx, ny = y + dy
                    guard nx >= 0, ny >= 0, nx < w, ny < h else { continue }
                    let j = ny * w + nx
                    if !changed.contains(j), before[j] != nil { edge.insert(j) }
                }
            }
            for j in edge {
                guard let c = canvas.color[j] else { continue }
                canvas.set(j % w, j / w, Ink.mix(c, Ink.outline, 0.55), canvas.tag(j % w, j / w))
            }
        }

        // MARK: Piernas

        func legGeometry(_ key: LegKey, hipX: Double) -> (hip: V, knee: V, ankle: V) {
            let s = body.legLen / 7
            let hip = V(hipX + Double(hipShift), body.hipY + Double(rig.bob))
            var ankle = hip + key.ankle * s
            let drop = key.foot == .toe ? 3 : 2
            let groundY = Double(HeroArt.canvasHeight - 1 - drop)
            ankle.y = key.grounded ? groundY : min(ankle.y, groundY)
            // Cinemática inversa de dos huesos; la rodilla siempre hacia delante.
            let seg = body.legLen * 0.54
            let dx = ankle.x - hip.x, dy = ankle.y - hip.y
            let d = max(0.001, min(2 * seg - 0.01, (dx * dx + dy * dy).squareRoot()))
            let a = acos(max(-1, min(1, d / (2 * seg))))
            let base = atan2(dy, dx)
            let k1 = hip + V(cos(base + a), sin(base + a)) * seg
            let k2 = hip + V(cos(base - a), sin(base - a)) * seg
            let knee = k1.x > k2.x ? k1 : k2
            return (hip, knee, ankle)
        }

        mutating func drawLeg(_ key: LegKey, hipX: Double, front: Bool) {
            let (hip, knee, ankle) = legGeometry(key, hipX: hipX)
            let depth: (Ramp) -> Ramp = { front ? $0 : $0.behind }
            let trousers = depth(clothes.trousers)
            if body.digitigrade {
                let fur = depth(skin)
                let s = body.legLen / 7
                let hock = V(ankle.x - 2.4 * s, ankle.y - 2.8 * s)
                let kneeW = knee + V(1.2, -0.4)
                legPixels.formUnion(canvas.limb(hip, kneeW, w: body.thighW, fur, .fur))
                // Pantalón corto rasgado sobre el muslo.
                for p in Canvas.segment(hip, hip.lerp(kneeW, 0.6), w: body.thighW + 1) {
                    canvas.set(p.0.x, p.0.y, trousers[Canvas.tones(body.thighW + 1)[p.1]], .cloth)
                }
                legPixels.formUnion(canvas.limb(kneeW, hock, w: body.shinW, fur, .fur))
                legPixels.formUnion(canvas.limb(hock, ankle, w: body.shinW - 1, fur, .fur))
            } else {
                legPixels.formUnion(canvas.limb(hip, knee, w: body.thighW, trousers, .cloth))
                legPixels.formUnion(canvas.limb(knee, ankle, w: body.shinW, trousers, .cloth))
            }
            let shinW = body.digitigrade ? body.shinW - 1 : body.shinW
            if let boots = gear(.boots) {
                drawBoot(boots, knee: knee, ankle: ankle, foot: key.foot, shinW: shinW, front: front)
            } else if let shoes = clothes.shoes {
                drawFoot(ankle: ankle, w: shinW, kind: key.foot, ramp: depth(shoes), len: body.footLen)
            } else {
                drawPaw(ankle: ankle, w: shinW, kind: key.foot, ramp: depth(skin))
            }
        }

        /// Pixeles del pie a partir del tobillo (punta hacia la derecha).
        func footShape(ankle: V, w: Int, kind: Foot, len: Int) -> (Set<Pt>, Set<Pt>) {
            let sx = Int((ankle.x - Double(w) / 2).rounded()), ay = Int(ankle.y.rounded(.down))
            var pts = Set<Pt>(), sole = Set<Pt>()
            func row(_ y: Int, _ a: Int, _ b: Int, sole s: Bool = false) {
                guard a <= b else { return }
                for x in a...b { pts.insert(Pt(x, y)); if s { sole.insert(Pt(x, y)) } }
            }
            switch kind {
            case .flat:
                row(ay, sx, sx + w)
                row(ay + 1, sx - 1, sx + len - 1)
                row(ay + 2, sx - 1, sx + len - 1, sole: true)
            case .toe:
                row(ay, sx, sx + w - 1)
                row(ay + 1, sx, sx + w)
                row(ay + 2, sx + 1, sx + w)
                row(ay + 3, sx + 1, sx + w - 1, sole: true)
            case .heel:
                row(ay - 1, sx + len - 2, sx + len - 1)
                row(ay, sx, sx + len - 1)
                row(ay + 1, sx - 1, sx + len - 2)
                row(ay + 2, sx - 1, sx + 2, sole: true)
            }
            return (pts, sole)
        }

        mutating func drawFoot(ankle: V, w: Int, kind: Foot, ramp: Ramp, len: Int, tag: Tag = .gear) {
            let (pts, sole) = footShape(ankle: ankle, w: w, kind: kind, len: len)
            canvas.fill(pts, ramp, tag)
            for p in sole { canvas.set(p.x, p.y, ramp.dp, tag) }
        }

        /// Pata del hombre lobo con garras.
        mutating func drawPaw(ankle: V, w: Int, kind: Foot, ramp: Ramp) {
            let (pts, _) = footShape(ankle: ankle, w: w, kind: kind, len: 5)
            canvas.fill(pts, ramp, .fur)
            let claw: UInt32 = 0xF0E8D8
            let tip = pts.filter { p in !pts.contains(Pt(p.x + 1, p.y)) }
            for p in tip.sorted(by: { $0.y > $1.y }).prefix(2) { canvas.set(p.x + 1, p.y, claw, .gear) }
        }

        // MARK: Brazos

        mutating func drawArm(_ key: ArmKey, shoulder: V, front: Bool) {
            let s = body.armK
            let elbow = shoulder + key.elbow * s
            let hand = shoulder + key.hand * s
            let depth: (Ramp) -> Ramp = { front ? $0 : $0.behind }
            let chest = gear(.chest)
            let sleeve = sleeveRamp(chest).map(depth)
            let fore = forearmRamp(chest).map(depth)
            let skinR = depth(skin)
            canvas.limb(shoulder, elbow, w: body.upperW, sleeve ?? skinR, sleeve == nil ? (race == .werewolf ? .fur : .skin) : .cloth)
            canvas.limb(elbow, hand, w: body.foreW, fore ?? skinR, fore == nil ? (race == .werewolf ? .fur : .skin) : .cloth)
            if let chest { drawSleeveDetail(chest, shoulder: shoulder, elbow: elbow, hand: hand, front: front) }
            let f = body.fist
            let fx = Int((hand.x - Double(f) / 2).rounded()), fy = Int((hand.y - Double(f) / 2).rounded())
            if let gloves = gear(.gloves) {
                drawGlove(gloves, elbow: elbow, hand: hand, fist: Pt(fx, fy), front: front)
            } else {
                canvas.fill(Canvas.rect(fx, fy, f, f), skinR, race == .werewolf ? .fur : .skin)
                if race == .werewolf {
                    let claw: UInt32 = 0xF0E8D8
                    canvas.set(fx + f, fy + f - 1, claw)
                    canvas.set(fx + f - 1, fy + f, claw)
                    canvas.set(fx + 1, fy + f, claw)
                }
            }
            if let chest { drawPauldron(chest, shoulder: shoulder, front: front) }
        }

        // MARK: Torso

        /// Filas del torso ya desplazadas: (y, x0, x1, parte alta).
        var torsoRows: [(y: Int, x0: Int, x1: Int, upper: Bool)] {
            body.torso.enumerated().map { i, span in
                let isUpper = i < body.belt
                let dx = isUpper ? upper.x : hipShift
                let dy = isUpper ? upper.y : rig.bob
                return (body.torsoTop + i + dy, span.0 + dx, span.1 + dx, isUpper)
            }
        }

        var torsoCenter: Int { Int(body.cx.rounded(.down)) + upper.x }

        mutating func drawTorso() {
            let rows = torsoRows
            var top = Set<Pt>(), low = Set<Pt>()
            for r in rows { for x in r.x0...r.x1 { if r.upper { top.insert(Pt(x, r.y)) } else { low.insert(Pt(x, r.y)) } } }
            let beltY0 = rows[body.belt].y
            var belt = Set<Pt>(), legs = Set<Pt>()
            for p in low { if p.y <= beltY0 + 1 { belt.insert(p) } else { legs.insert(p) } }

            // Ropa base
            if race == .werewolf {
                canvas.fill(top, skin, .fur, soft: true)
                // Pecho más claro.
                let cx = torsoCenter
                let chest = Ramp(base: Ink.mix(skin.md, 0xF4ECD8, 0.55), spread: 0.7)
                for r in rows where r.upper && r.y >= rows[1].y {
                    for x in (cx - 3)...(cx + 3) where x > r.x0 + 1 && x < r.x1 - 1 {
                        let edge = abs(x - cx) == 3 || r.y == rows[body.belt - 1].y
                        canvas.set(x, r.y, edge ? chest.dk : (x < cx ? chest.lt : chest.md), .fur)
                    }
                }
                // Mechones del pelaje en los bordes.
                for r in rows where r.upper && (r.y - rows[0].y) % 2 == 1 {
                    canvas.set(r.x0 - 1, r.y, skin.md, .fur)
                    canvas.set(r.x1 + 1, r.y, skin.dk, .fur)
                }
            } else {
                canvas.fill(top, clothes.shirt, .cloth, soft: true)
                drawCollar(rows)
            }
            canvas.fill(legs, clothes.trousers, .cloth)
            canvas.fill(belt, clothes.belt, .gear)
            let buckle = Pt(torsoCenter + 1 - upper.x + hipShift, beltY0)
            canvas.fill(Canvas.rect(buckle.x, buckle.y, 2, 2), clothes.buckle, .gear)

            if let chest = gear(.chest) { drawChest(chest, rows: rows) }
        }

        /// Cuello de la camisa (V con cordón).
        mutating func drawCollar(_ rows: [(y: Int, x0: Int, x1: Int, upper: Bool)]) {
            let cx = torsoCenter + 1
            let y0 = rows[0].y
            canvas.set(cx - 1, y0, skin.md, .skin); canvas.set(cx, y0, skin.md, .skin); canvas.set(cx + 1, y0, skin.dk, .skin)
            canvas.set(cx, y0 + 1, skin.dk, .skin)
            canvas.set(cx - 2, y0, clothes.shirtTrim.md, .cloth); canvas.set(cx + 2, y0, clothes.shirtTrim.dk, .cloth)
            canvas.set(cx - 1, y0 + 1, clothes.shirtTrim.md, .cloth); canvas.set(cx + 1, y0 + 1, clothes.shirtTrim.dk, .cloth)
            canvas.set(cx, y0 + 2, clothes.shirtTrim.dk, .cloth)
        }

        mutating func drawNeck() {
            let cx = torsoCenter + 1
            let y = body.torsoTop + upper.y
            for dy in -2...0 { for dx in -2...1 {
                if canvas[cx + dx, y + dy] == nil {
                    canvas.set(cx + dx, y + dy, dx == 1 ? skin.dk : skin.md, race == .werewolf ? .fur : .skin)
                }
            } }
            if race == .werewolf, let neck = style.neck {
                stampHair(neck, flow: false)
            }
        }

        // MARK: Cabeza

        var hairPens: [Character: Pen] {
            [
                "H": Pen(hair, nil, .hair), "D": Pen(hair, .dk, .hair), "X": Pen(hair, .dp, .hair),
                "J": Pen(hair, .hi, .hair), "L": Pen(hair, .lt, .hair),
                "k": Pen(Ramp.flat(Ink.mix(hair.dp, Ink.outline, 0.5)), .md, .hair),
                "G": Pen(Ramp(material: [0xFFE08A, 0xE0A838, 0x9A6420]), .md, .gear),
            ]
        }

        var skinPens: [Character: Pen] {
            let tag: Tag = race == .werewolf ? .fur : .skin
            return [
                "F": Pen(skin, .lt, tag), "f": Pen(skin, .md, tag), "s": Pen(skin, .dk, tag),
                "S": Pen(skin, .dp, tag), "h": Pen(skin, .hi, tag),
                "b": Pen(Ramp.flat(Ink.mix(skin.lt, 0xF06A7A, 0.35)), .md, tag),
            ]
        }

        /// Pelo con la cabeza como origen; `flow` aplica el movimiento secundario.
        mutating func stampHair(_ layer: Layer, flow: Bool, skipAbove: Int? = nil, castShadow: Bool = false) {
            let o = headOrigin
            let dx = flow ? rig.flowX : 0, dy = flow ? rig.flowY : 0
            let before = castShadow ? canvas.pixels(tagged: .hair) : []
            canvas.stamp(layer.rows, x: o.x + layer.x + dx, y: o.y + layer.y + dy, hairPens,
                         skipAbove: skipAbove.map { o.y + $0 })
            if castShadow {
                let added = canvas.pixels(tagged: .hair).subtracting(before)
                canvas.castShadow(from: added, onto: .skin, skin.md)
            }
        }

        /// Hasta dónde se ve el pelo de detrás con cada casco (fila de la caja de la cabeza), nil = no se ve.
        var hairBackCut: Int?? {
            switch gear(.helmet)?.styleID {
            case nil, "helm.circlet": .some(nil)
            case "helm.hood": .none
            case "helm.great": .some(18)
            case "helm.horned": .some(9)
            default: .some(12)
            }
        }

        mutating func drawBackLayers() {
            if let back = style.back, let cut = hairBackCut {
                stampHair(back, flow: style.flows, skipAbove: cut)
            }
            if let helmet = gear(.helmet) { drawHelmetBack(helmet) }
        }

        mutating func drawHead() {
            let o = headOrigin
            let helmet = gear(.helmet)
            let covers = helmet.map { $0.styleID != "helm.circlet" } ?? false
            switch race {
            case .werewolf:
                canvas.stamp(wolfHead.rows, x: o.x + wolfHead.x, y: o.y + wolfHead.y, wolfPens)
                drawWolfFace(o)
                if !covers, let front = style.front { stampHair(front, flow: false) }
            case .human, .elf, .dwarf:
                let face = race == .dwarf ? dwarfFace : (race == .elf ? elfFace : humanFace)
                canvas.stamp(face, x: o.x, y: o.y, skinPens)
                drawEyes(o)
                if race == .elf {
                    // Las orejas salen por debajo del pelo y del casco.
                    canvas.stamp(elfEarBack.rows, x: o.x + elfEarBack.x, y: o.y + elfEarBack.y, skinPens)
                    canvas.stamp(elfEarFront.rows, x: o.x + elfEarFront.x, y: o.y + elfEarFront.y, skinPens)
                }
                if race == .dwarf {
                    if !covers { stampHair(dwarfTopHair, flow: false, castShadow: true) }
                    if helmet?.styleID != "helm.great" { stampHair(dwarfBrows, flow: false) }
                } else if !covers, let front = style.front {
                    stampHair(front, flow: false, castShadow: true)
                }
            }
            if let helmet { drawHelmet(helmet) }
            if race == .dwarf, let beard = style.front {
                stampHair(beard, flow: false)
            }
        }

        var eyePens: [Character: Pen] {
            let iris = Ramp(base: eye, spread: 1)
            return [
                "k": Pen(Ramp.flat(0x241A2E), .md, .eye), "w": Pen(Ramp.flat(0xFFFFFF), .md, .eye),
                "p": Pen(iris, .dp, .eye), "i": Pen(iris, .md, .eye), "I": Pen(iris, .hi, .eye),
            ]
        }

        mutating func drawEyes(_ o: Pt) {
            let pens = eyePens
            if race == .dwarf {
                let rows = rig.face == .blink || rig.face == .hurt ? dwarfBlink : dwarfEye
                canvas.stamp(rows, x: o.x + 7, y: o.y + 11, pens)
                canvas.stamp(rows, x: o.x + 13, y: o.y + 11, pens)
                return
            }
            switch rig.face {
            case .open, .shout:
                canvas.stamp(eyeOpen, x: o.x + 6, y: o.y + 11, pens)
                canvas.stamp(eyeOpen, x: o.x + 13, y: o.y + 11, pens)
                // Pestañas exteriores.
                canvas.set(o.x + 5, o.y + 11, 0x241A2E, .eye)
                canvas.set(o.x + 16, o.y + 11, 0x241A2E, .eye)
            case .blink:
                canvas.stamp(eyeBlink, x: o.x + 6, y: o.y + 11, pens)
                canvas.stamp(eyeBlink, x: o.x + 13, y: o.y + 11, pens)
            case .hurt:
                canvas.stamp(eyeHurtLeft, x: o.x + 6, y: o.y + 11, pens)
                canvas.stamp(eyeHurtRight, x: o.x + 13, y: o.y + 11, pens)
            }
            // Boca
            let mouth: UInt32 = Ink.mix(skin.dk, 0x8A2A3A, 0.5)
            let mx = o.x + 12, my = o.y + 16
            switch rig.face {
            case .open, .blink:
                canvas.set(mx, my, mouth, .skin)
            case .shout, .hurt:
                canvas.set(mx - 1, my, mouth, .skin); canvas.set(mx, my, mouth, .skin)
                canvas.set(mx - 1, my + 1, 0xC85A5A, .skin); canvas.set(mx, my + 1, mouth, .skin)
            }
        }

        var wolfPens: [Character: Pen] {
            let muzzle = Ramp(base: Ink.mix(skin.md, 0xF4ECD8, 0.55), spread: 0.7)
            return [
                "F": Pen(skin, nil, .fur, group: 1), "W": Pen(muzzle, nil, .fur, group: 1),
                "L": Pen(skin, .lt, .fur, group: 1), "d": Pen(skin, .dk, .fur, group: 1),
                "D": Pen(skin, .dp, .fur, group: 1), "w": Pen(muzzle, .lt, .fur, group: 1),
                "A": Pen(Ramp.flat(Ink.mix(skin.dk, 0xC07080, 0.5)), .md, .fur, group: 1),
                "n": Pen(Ramp.flat(0x241A2E), .md, .fur, group: 1),
                "m": Pen(Ramp.flat(Ink.mix(skin.dp, Ink.outline, 0.4)), .md, .fur, group: 1),
                "T": Pen(Ramp.flat(0xFFFFFF), .md, .fur, group: 1),
            ]
        }

        mutating func drawWolfFace(_ o: Pt) {
            let pens = eyePens
            let closed = rig.face == .blink || rig.face == .hurt
            let rows = closed ? wolfBlink : wolfEye
            canvas.stamp(rows, x: o.x + 6, y: o.y + 6, pens)
            canvas.stamp(rows, x: o.x + 12, y: o.y + 6, pens)
            // Ceño
            let brow: UInt32 = skin.dp
            canvas.set(o.x + 5, o.y + 5, brow, .fur); canvas.set(o.x + 6, o.y + 5, brow, .fur)
            canvas.set(o.x + 13, o.y + 5, brow, .fur); canvas.set(o.x + 14, o.y + 5, brow, .fur)
            if rig.face == .shout || rig.face == .hurt {
                // Fauces abiertas
                for x in (o.x + 13)...(o.x + 20) { canvas.set(x, o.y + 13, 0x5A1A2A, .fur) }
                canvas.set(o.x + 14, o.y + 13, 0xFFFFFF, .fur); canvas.set(o.x + 19, o.y + 13, 0xFFFFFF, .fur)
            }
        }

        mutating func drawTail() {
            let tail = wolfTails[min(rig.tail, wolfTails.count - 1)]
            let hip = V(body.hipBack + Double(hipShift), body.hipY + Double(rig.bob))
            let pens: [Character: Pen] = [
                "H": Pen(skin.behind, nil, .fur),
            ]
            let w = tail.rows.map(\.count).max() ?? 0
            let x = Int(hip.x) - w + 2, y = Int(hip.y) - tail.rows.count + 1
            canvas.stamp(tail.rows, x: x, y: y, pens)
            // Punta clara
            let tip = Ramp(base: Ink.mix(skin.md, 0xF4ECD8, 0.6), spread: 0.6)
            for (ry, row) in tail.rows.enumerated() {
                for (rx, ch) in row.enumerated() where ch == "H" && rx <= 2 {
                    canvas.set(x + rx, y + ry, rx == 0 ? tip.md : tip.lt, .fur)
                }
            }
        }
    }
}

extension HeroArt.Ramp {
    /// Variante para las piezas del lado lejano (brazo y pierna de atrás): un tono más oscura.
    var behind: HeroArt.Ramp {
        HeroArt.Ramp(hi: lt, lt: md, md: HeroArt.Ink.mix(md, dk, 0.55), dk: dk, dp: dp)
    }
}
