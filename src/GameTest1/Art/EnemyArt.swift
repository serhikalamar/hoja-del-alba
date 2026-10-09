import CoreGraphics
import GameCore
import SpriteKit

/// Enemigos, aldeanos y princesa.
///
/// Cada cuerpo es un pequeño "esqueleto": piezas dibujadas a mano (cabeza, torso, gorros, armas)
/// más extremidades procedurales (brazos, piernas, alas, colas) que se colocan según la pose del frame.
/// Las paletas salen de unos pocos colores base por enemigo (`Spec`): cada uno se convierte en una
/// rampa de 3-4 tonos (luz arriba-izquierda, sombras frías), así los 50 enemigos comparten el detalle.
///
/// Letras de las rampas (claro → oscuro):
/// piel/pelaje `ABCD` · ropa `KLMN` · ropa secundaria (pantalón) `PQR` · cuero `WXYZ` · pelo `HIJ`
/// metal `STUV` · color de acento (capas, gorros) `FGO` · ojos `e`.
/// Colores fijos: ver `fixed`.
enum EnemyArt {
    // MARK: - Contrato con EnemyNode

    /// Frames: 0-3 ciclo de paso (contacto, cruce, contacto, cruce), 4 preparación del ataque, 5 golpe,
    /// 6 daño (retrocede con los ojos apretados). En aldeanos (`npc.*`) los frames 0-3 son una respiración en reposo.
    static let frameCount = 7
    static let walkFrames = [0, 1, 2, 3]
    static let windupFrame = 4
    static let strikeFrame = 5
    static let hurtFrame = 6

    typealias Colors = [Character: UInt32]

    /// Lienzo de trabajo: los pies apoyan en la fila `gy - 1`, el cuerpo se centra en `cx`.
    private static let canvasW = 96, canvasH = 84
    private static let cx = 48, gy = 74

    /// Frames ya recortados por enemigo (se calculan juntos porque comparten recorte).
    private static var frameCache: [String: [PixelGrid]] = [:]

    static func grid(for id: String, frame: Int) -> PixelGrid {
        let index = min(max(frame, 0), frameCount - 1)
        if let cached = frameCache[id] { return cached[index] }
        if let rows = objectRows(id) {
            // Objetos con los que se habla (carta, cartel): quietos, el mismo dibujo en todos los frames.
            var g = PixelGrid(width: rows.map(\.count).max() ?? 1, height: rows.count)
            put(&g, rows, 0, 0, fixed)
            let done = Array(repeating: g.outlined(), count: frameCount)
            frameCache[id] = done
            return done[index]
        }
        let spec = spec(id)
        let frames = (0..<frameCount).map { render(spec, frame: $0) }
        // Mismo recorte (ajustado) para todos los frames: así el movimiento se nota y el sprite no crece
        // de más (EnemyNode calcula la sombra y la barra de vida a partir del ancho de la textura).
        let bounds = frames.dropFirst().reduce(frames[0].opaqueBounds) { $0.union($1.opaqueBounds) }
        let done = frames.map { $0.cropped(to: bounds).outlined() }
        frameCache[id] = done
        return done[index]
    }

    static func render(_ s: Spec, frame: Int) -> PixelGrid {
        var g = PixelGrid(width: canvasW, height: canvasH)
        let pal = palette(s)
        let pose = Pose(frame: frame, npc: s.npc)
        switch s.body {
        case .goblin: drawHumanoid(&g, goblinRig, s, pal, pose)
        case .human: drawHumanoid(&g, humanRig, s, pal, pose)
        case .skeleton: drawHumanoid(&g, skeletonRig, s, pal, pose)
        case .brute: drawHumanoid(&g, bruteRig, s, pal, pose)
        case .rat: drawRat(&g, s, pal, pose)
        case .dog: drawDog(&g, s, pal, pose)
        case .boar: drawBoar(&g, s, pal, pose)
        case .bird: drawBird(&g, s, pal, pose)
        case .bat: drawBat(&g, s, pal, pose)
        case .slime: drawSlime(&g, s, pal, pose)
        case .ghost: drawGhost(&g, s, pal, pose)
        }
        return g
    }

    // MARK: - Pose

    enum Action { case walk, idle, windup, strike }

    struct Pose {
        let phase: Int
        let action: Action
        /// Frame de daño: el cuerpo retrocede como en la preparación (mismo recorte), pero los humanoides
        /// echan los brazos atrás y aprietan los ojos; las bestias se encogen.
        let hurt: Bool

        init(frame: Int, npc: Bool) {
            phase = frame % 4
            hurt = !npc && frame == 6
            if npc { action = .idle } else { action = frame == 4 || hurt ? .windup : (frame == 5 ? .strike : .walk) }
        }

        /// Altura del cuerpo: sube en los cruces del paso, baja al prepararse y golpear.
        var bob: Int {
            switch action {
            case .walk: [0, -1, 0, -1][phase]
            case .idle: [0, 0, 1, 1][phase]
            case .windup, .strike: 1
            }
        }

        /// Inclinación del torso (negativo = hacia atrás).
        var lean: Int { action == .windup ? -1 : (action == .strike ? 2 : 0) }

        /// Desplazamiento de los pies (delantero, trasero) y cuánto se levanta cada uno.
        var feet: (front: Int, back: Int, liftFront: Int, liftBack: Int) {
            switch action {
            case .walk:
                let d = [2, 0, -2, 0][phase]
                return (d, -d, phase == 3 ? 1 : 0, phase == 1 ? 1 : 0)
            case .idle: return (1, -1, 0, 0)
            case .windup: return (2, -2, 0, 0)
            case .strike: return (3, -3, 0, 0)
            }
        }

        /// Balanceo de los brazos al andar (opuesto a las piernas).
        var swing: Int { action == .walk ? [-1, 0, 1, 0][phase] : 0 }
    }

    // MARK: - Colores

    static let fixed: Colors = [
        "k": 0x1A1C2C, "E": 0x1A1C2C, "w": 0xF4F4F4, "*": 0xFFFFFF, "r": 0x7A1A2A, "p": 0xF29AA0,
        "t": 0xFFF4D8, "u": 0xD8CCA8, "v": 0xA0906E,
        "g": 0xFFF0A0, "y": 0xFFCD45, "z": 0xB07A20,
        "o": 0xB07A44, "q": 0x7A4E2A, "j": 0x4A2E1A,
        "1": 0xF4F4F8, "2": 0xC0C8D4, "3": 0x8A94A6, "4": 0x566070,
        "x": 0xE43B44, "c": 0x73EFF7, "b": 0x3B5DC9, "m": 0xD090FF, "n": 0x8A3AD0, "s": 0xE8E0D0,
        "5": 0xFFF6A0, "6": 0xFFB030, "7": 0xE0501A,
    ]

    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        var out: UInt32 = 0
        for shift in [16, 8, 0] as [UInt32] {
            let va = Double((a >> shift) & 0xFF), vb = Double((b >> shift) & 0xFF)
            out |= UInt32(max(0, min(255, (va * (1 - t) + vb * t).rounded()))) << shift
        }
        return out
    }

    /// Rampa de 4 tonos: luz cálida, base, sombra fría, sombra profunda.
    static func ramp(_ c: UInt32) -> [UInt32] {
        [mix(c, 0xFFF4D6, 0.4), c, mix(c, 0x2A1E46, 0.36), mix(c, 0x1C1430, 0.6)]
    }

    struct Base { var skin, cloth, trim, leather, hair, metal, accent, eye: UInt32 }

    static func base(_ body: Body) -> Base {
        switch body {
        case .goblin: Base(skin: 0x5DAA48, cloth: 0x8F5A32, trim: 0x6A4A2A, leather: 0x5E3A24, hair: 0x2A2A1A, metal: 0xA8AEB8, accent: 0xB01A2A, eye: 0xFFD040)
        case .human: Base(skin: 0xF4C095, cloth: 0x7A4A2A, trim: 0x4A4A5A, leather: 0x5A3A22, hair: 0x5A3A22, metal: 0xA8AEB8, accent: 0xC03030, eye: 0x6A8A4A)
        case .skeleton: Base(skin: 0xE8E0C8, cloth: 0x5A4A6A, trim: 0x4A3A2A, leather: 0x4A3A2A, hair: 0x888888, metal: 0x8A8A96, accent: 0x6A2A3A, eye: 0xFF6A3A)
        case .brute: Base(skin: 0x6A9A4A, cloth: 0x6A4A36, trim: 0x5A4A3A, leather: 0x45301F, hair: 0x2A2A1A, metal: 0x8A8A96, accent: 0xA02A2A, eye: 0xFF5040)
        case .rat: Base(skin: 0x8A7A6A, cloth: 0x6A2A3A, trim: 0x6A2A3A, leather: 0x4A3A2A, hair: 0xC4B4A2, metal: 0x8A8A96, accent: 0xB01A2A, eye: 0xE03030)
        case .dog: Base(skin: 0x9A7A5A, cloth: 0x6A4A36, trim: 0x6A4A36, leather: 0x5E3A24, hair: 0xD0B890, metal: 0x8A8A96, accent: 0xB01A2A, eye: 0x2A1A10)
        case .boar: Base(skin: 0x6A4A36, cloth: 0x6A4A36, trim: 0x6A4A36, leather: 0x4A3020, hair: 0x3A2618, metal: 0x9AA0AA, accent: 0xB01A2A, eye: 0x1A1C2C)
        case .bird: Base(skin: 0x34344A, cloth: 0x34344A, trim: 0xE0A040, leather: 0x4A3020, hair: 0x6A7AAA, metal: 0x8A8A96, accent: 0xB01A2A, eye: 0xFFE070)
        case .bat: Base(skin: 0x5A3A5A, cloth: 0x7A4A70, trim: 0x5A3A5A, leather: 0x4A3020, hair: 0x7A5A7A, metal: 0x8A8A96, accent: 0xB01A2A, eye: 0xFF4040)
        case .slime: Base(skin: 0x6ACC50, cloth: 0x6ACC50, trim: 0x6ACC50, leather: 0x4A3020, hair: 0x6ACC50, metal: 0x8A8A96, accent: 0xB01A2A, eye: 0x1A1C2C)
        case .ghost: Base(skin: 0xCFEFF2, cloth: 0x8AB0C0, trim: 0x8AB0C0, leather: 0x4A3020, hair: 0xCFEFF2, metal: 0x8A8A96, accent: 0x6A4A8A, eye: 0x40E0FF)
        }
    }

    static func palette(_ s: Spec) -> Colors {
        let d = base(s.body)
        var p = fixed
        func fill(_ keys: String, _ color: UInt32) {
            let r = ramp(color)
            for (i, key) in keys.enumerated() { p[key] = r[i] }
        }
        fill("ABCD", s.skin ?? d.skin)
        fill("KLMN", s.cloth ?? d.cloth)
        fill("PQR", s.trim ?? d.trim)
        fill("WXYZ", s.leather ?? d.leather)
        fill("HIJ", s.hair ?? d.hair)
        // El metal lleva más contraste (brillo casi blanco, sombras hondas) para que se lea como tal.
        let metal = s.metal ?? d.metal
        p["S"] = mix(metal, 0xFFFFFF, 0.6); p["T"] = metal; p["U"] = mix(metal, 0x2A1E46, 0.42); p["V"] = mix(metal, 0x1C1430, 0.68)
        fill("FGO", s.accent ?? d.accent)
        let eye = s.eye ?? d.eye
        p["e"] = eye
        if s.look.contains("glowEyes") { p["E"] = mix(eye, 0xFFFFFF, 0.55); p["w"] = eye }
        return p
    }

    // MARK: - Utilidades de dibujo

    static func put(_ g: inout PixelGrid, _ rows: [String], _ x: Int, _ y: Int, _ pal: Colors, flip: Bool = false) {
        let w = rows.map(\.count).max() ?? 0
        for (j, row) in rows.enumerated() {
            for (i, ch) in row.enumerated() {
                if let c = pal[ch] { g[flip ? x + w - 1 - i : x + i, y + j] = c }
            }
        }
    }

    /// Extremidad gruesa de `a` a `b`. `colors` da un color por columna (de izquierda/arriba a derecha/abajo);
    /// `cuff` (opcional) colorea los últimos `cuffLen` pasos (puños, brazaletes, botas altas).
    static func limb(_ g: inout PixelGrid, _ a: (Int, Int), _ b: (Int, Int), _ colors: [UInt32],
                     cuff: [UInt32]? = nil, cuffLen: Int = 0) {
        let dx = b.0 - a.0, dy = b.1 - a.1
        let n = max(abs(dx), abs(dy), 1)
        let vertical = abs(dy) >= abs(dx)
        for step in 0...n {
            let x = a.0 + Int((Double(dx) * Double(step) / Double(n)).rounded())
            let y = a.1 + Int((Double(dy) * Double(step) / Double(n)).rounded())
            let set = (cuff != nil && step > n - cuffLen) ? cuff! : colors
            for (k, c) in set.enumerated() {
                if vertical { g[x + k, y] = c } else { g[x, y + k] = c }
            }
        }
    }

    static func chars(_ s: String, _ pal: Colors) -> [UInt32] { s.compactMap { pal[$0] } }

    /// Copia una capa sobre otra, oscureciéndola (para las extremidades del lado lejano).
    static func blit(_ src: PixelGrid, onto dst: inout PixelGrid, dim: Double) {
        for y in 0..<src.height {
            for x in 0..<src.width {
                if let c = src[x, y] { dst[x, y] = dim > 0 ? mix(c, 0x1C1430, dim) : c }
            }
        }
    }

    /// Gira un sprite alrededor de `pivot` (grados, positivo = horario) con supermuestreo 3×3,
    /// para que las hojas en diagonal salgan limpias. Devuelve la rejilla y la posición del pivote en ella.
    static func rotated(_ rows: [String], _ pal: Colors, pivot: (Int, Int), degrees: Double) -> (PixelGrid, (Int, Int)) {
        let src = PixelGrid(PixelSprite(rows: rows, palette: pal))
        if degrees == 0 { return (src, pivot) }
        let r = Int(Double(src.width * src.width + src.height * src.height).squareRoot()) + 2
        let size = r * 2 + 1
        var out = PixelGrid(width: size, height: size)
        let rad = degrees * .pi / 180, cs = cos(rad), sn = sin(rad)
        let px = Double(pivot.0) + 0.5, py = Double(pivot.1) + 0.5
        let subs = [0.0, -1.0 / 3, 1.0 / 3]
        for oy in 0..<size {
            for ox in 0..<size {
                var keys: [UInt32?] = []
                var counts: [Int] = []
                for sy in subs {
                    for sx in subs {
                        let rx = Double(ox - r) + sx, ry = Double(oy - r) + sy
                        let ux = rx * cs + ry * sn, uy = -rx * sn + ry * cs
                        let c = src[Int((px + ux).rounded(.down)), Int((py + uy).rounded(.down))]
                        if let i = keys.firstIndex(where: { $0 == c }) { counts[i] += 1 } else { keys.append(c); counts.append(1) }
                    }
                }
                // Gana el color opaco más votado si cubre al menos 3 de 9 muestras (las líneas finas no se pierden).
                var best = -1
                for i in counts.indices where keys[i] != nil && (best < 0 || counts[i] > counts[best]) { best = i }
                let opaque = zip(keys, counts).filter { $0.0 != nil }.reduce(0) { $0 + $1.1 }
                if best >= 0 && opaque >= 3 { out[ox, oy] = keys[best] }
            }
        }
        return (out, (r, r))
    }

    // MARK: - Especificación de cada enemigo

    enum Body { case goblin, human, skeleton, brute, rat, dog, boar, bird, bat, slime, ghost }

    struct Spec {
        var body: Body
        var skin: UInt32? = nil
        var cloth: UInt32? = nil
        var trim: UInt32? = nil
        var leather: UInt32? = nil
        var hair: UInt32? = nil
        var metal: UInt32? = nil
        var accent: UInt32? = nil
        var eye: UInt32? = nil
        var hat: String? = nil
        var weapon: String? = nil
        /// Rasgos: peinado, barba, capa, armadura, delantal, cicatrices… (ver `drawHumanoid`).
        var look: Set<String> = []
        var npc = false
    }

    static func spec(_ id: String) -> Spec {
        switch id {
        // Goblins
        case "goblin": Spec(body: .goblin, weapon: "club", look: ["loincloth"])
        case "goblinSlinger": Spec(body: .goblin, cloth: 0x6A7A3A, hat: "leatherCap", weapon: "sling")
        case "goblinThief": Spec(body: .goblin, cloth: 0x3A3A4E, accent: 0x3A3A4E, hat: "bandana", weapon: "dagger", look: ["mask"])
        case "goblinSpearman": Spec(body: .goblin, cloth: 0x7A5A3A, hat: "leatherCap", weapon: "spear")
        case "goblinShaman": Spec(body: .goblin, cloth: 0xA03A2A, accent: 0xE0D0A0, weapon: "staff", look: ["feathers", "beads"])
        case "goblinBrute": Spec(body: .goblin, skin: 0x4A8A3A, cloth: 0x6A6A78, hat: "helmet", weapon: "club", look: ["armor"])
        case "hobgoblin": Spec(body: .goblin, skin: 0xD08A4A, cloth: 0x5A3A6A, eye: 0xFFF080, hat: "helmet", weapon: "sword", look: ["armor"])
        case "goblinBomber": Spec(body: .goblin, cloth: 0xD07A30, hat: "leatherCap", weapon: "bomb", look: ["goggles"])
        case "goblinElite": Spec(body: .goblin, skin: 0x3A7A4A, cloth: 0xA02A2A, hat: "helmet", weapon: "axe", look: ["armor", "pauldron"])
        case "goblinGuard": Spec(body: .goblin, cloth: 0x2A4AA0, metal: 0xC8CCD8, hat: "helmet", weapon: "spear", look: ["armor", "goldTrim"])
        case "goblinMage": Spec(body: .goblin, cloth: 0x4A2A8A, accent: 0x4A2A8A, hat: "mageHat", weapon: "staff", look: ["robe"])
        case "goblinStandard": Spec(body: .goblin, cloth: 0xC8A030, accent: 0xB01A2A, hat: "helmet", weapon: "flag", look: ["armor"])
        case "goblinKing": Spec(body: .goblin, skin: 0x6AB050, cloth: 0x6A2A9A, accent: 0xC01A2A,
                                hat: "bigCrown", weapon: "bigSword", look: ["cape", "ermine", "chain"])
        // Humanos
        case "bandit": Spec(body: .human, cloth: 0x6A5A3A, trim: 0x4A4A5A, accent: 0xC03030, hat: "bandana", weapon: "dagger", look: ["stubble"])
        case "banditChief": Spec(body: .human, cloth: 0x8A1A2A, trim: 0x2A2A36, hair: 0x2A2A2A, accent: 0x5A1020,
                                 hat: "bandana", weapon: "bigSword", look: ["beard", "eyepatch", "cape", "pauldron"])
        case "zombieFarmer": Spec(body: .human, skin: 0x8AB07A, cloth: 0x6A7A9A, trim: 0x5A4A3A, hair: 0x6A6A50, eye: 0xFF4040,
                                  hat: "strawHat", weapon: "pitchfork", look: ["patches", "zombie", "glowEyes"])
        case "scarecrow": Spec(body: .human, skin: 0xD8B880, cloth: 0x5A7A3A, trim: 0x6A5A8A, eye: 0xFF7A20,
                               hat: "strawHat", weapon: "scythe", look: ["sackHead", "patches", "straw", "glowEyes", "crows"])
        case "cultist": Spec(body: .human, cloth: 0x5A1A2A, trim: 0x3A0F1A, hat: "hood", weapon: "staff", look: ["robe"])
        case "mercenary": Spec(body: .human, cloth: 0x6A6A78, trim: 0x4A3A2A, hat: "helmet", weapon: "sword", look: ["armor", "pauldron", "stubble"])
        case "blackKnight": Spec(body: .human, cloth: 0x2A2A36, trim: 0x22222C, metal: 0x4A4A5A, accent: 0xB01A2A, eye: 0xFF3030,
                                 hat: "greatHelm", weapon: "bigSword", look: ["armor", "pauldron", "greaves"])
        case "necromancer": Spec(body: .human, skin: 0xD8D0E0, cloth: 0x2A1A3A, eye: 0xC060FF, hat: "hood", weapon: "skullStaff", look: ["robe", "glowEyes"])
        case "assassin": Spec(body: .human, cloth: 0x22222C, trim: 0x22222C, hat: "hood", weapon: "dagger", look: ["mask"])
        case "witch": Spec(body: .human, skin: 0xA8D090, cloth: 0x4A2A6A, hair: 0x2A2A3A, accent: 0x4A2A6A, eye: 0xFFE040,
                           hat: "witchHat", weapon: "skullStaff", look: ["robe", "longHair", "longNose", "cape"])
        // Continente de Valdemar · Orden del Eclipse: túnica ceniza hasta el suelo con ribete violeta, capucha
        // de punta caída con la cara en sombra (solo brillan los ojos), luna negra con corona violeta en el pecho,
        // faja morada con lazada, manos vendadas y libro con cadena al cinto. Lanza la esfera con la mano.
        case "eclipseAcolyte": Spec(body: .human, skin: 0x3A3442, cloth: 0x6B6670, trim: 0x3A3540, leather: 0x3A3540,
                                    accent: 0x8E5CC2, eye: 0xC9A6FF, hat: "eclipseHood",
                                    look: ["robe", "glowEyes", "eclipseMoon", "sash", "tomeAtHip", "bandaged", "orbCaster", "accentHem"])
        // Esqueletos
        case "skeleton": Spec(body: .skeleton, weapon: "sword", look: ["rags"])
        case "skeletonArcher": Spec(body: .skeleton, cloth: 0x4A5A3A, weapon: "bow", look: ["rags", "quiver"])
        case "ghoul": Spec(body: .skeleton, skin: 0xA0B890, eye: 0xFF4040, weapon: "claws", look: ["hunch"])
        case "abbot": Spec(body: .skeleton, cloth: 0x4A3A5A, eye: 0x40E0FF, hat: "hood", weapon: "skullStaff", look: ["robe", "rosary", "glowEyes"])
        // Bestias
        case "rat": Spec(body: .rat)
        case "plagueRat": Spec(body: .rat, skin: 0x7A8A5A, hair: 0xA8B880, eye: 0xC0FF40, look: ["sores"])
        case "ratKing": Spec(body: .rat, skin: 0x5A4E5A, hair: 0x9A8A9A, accent: 0x9A1A3A, hat: "crown", look: ["cape", "scar", "tails"])
        case "mangyDog": Spec(body: .dog, look: ["mangy"])
        case "wolf": Spec(body: .dog, skin: 0x8A8A96, hair: 0xC8CCD4, eye: 0xFFE070)
        case "alphaWolf": Spec(body: .dog, skin: 0xD4D8E4, hair: 0x7E88B0, eye: 0xFF3030, look: ["mane", "scar"])
        case "wolfRider": Spec(body: .dog, skin: 0x6A6A78, hair: 0x9A9AA6, eye: 0xFFE070, look: ["rider", "saddle"])
        case "boar": Spec(body: .boar)
        case "armoredBoar": Spec(body: .boar, skin: 0x5A4030, look: ["armor"])
        case "crow": Spec(body: .bird)
        case "bat": Spec(body: .bat)
        case "gargoyle": Spec(body: .bat, skin: 0x7A7A86, cloth: 0x5A5A66, hair: 0x9A9AA6, eye: 0xFFB030, look: ["horns", "stone"])
        // Limos y espectros
        case "slime": Spec(body: .slime)
        case "fireSlime": Spec(body: .slime, skin: 0xF07A30, eye: 0x6A1A0A, look: ["flames"])
        case "iceSlime": Spec(body: .slime, skin: 0x8FD8F0, eye: 0x1A4A6A, look: ["ice"])
        case "wraith": Spec(body: .ghost, look: ["chains"])
        // Brutos
        case "possessedSmith": Spec(body: .brute, skin: 0xB07A6A, cloth: 0x5E3A24, trim: 0x3A2A22, accent: 0x6A4A30, eye: 0xFF7A20,
                                    weapon: "hammer", look: ["apron", "glowEyes", "embers", "horns"])
        case "mudGolem": Spec(body: .brute, skin: 0x8A6A44, cloth: 0x6A5034, trim: 0x6A5034, eye: 0x40E0FF, look: ["golem", "glowEyes"])
        case "orc": Spec(body: .brute, weapon: "axe", look: ["pauldron"])
        case "troll": Spec(body: .brute, skin: 0x6A8AA0, cloth: 0x5A4A3A, hair: 0x3A4A3A, weapon: "club", look: ["mossHair"])
        case "ogre": Spec(body: .brute, skin: 0xC8A070, cloth: 0x6A7A3A, trim: 0x5A4A2A, eye: 0xFFE040, weapon: "spikedClub", look: ["belly", "bigTooth", "scar"])
        case "berserker": Spec(body: .brute, skin: 0x7A8A3A, cloth: 0xA02A2A, hair: 0xC05020, hat: "hornedHelmet", weapon: "axe", look: ["warpaint", "braids"])
        case "warlord": Spec(body: .brute, skin: 0x4A7A3A, cloth: 0x2A2A36, metal: 0x5A5A6A, accent: 0x8A1A1A,
                             hat: "hornedHelmet", weapon: "bigSword", look: ["cape", "armor", "spikes", "scar"])
        // Aldeanos y princesa
        case "npc.baker": Spec(body: .human, cloth: 0xC8784A, trim: 0x8A5A3A, hair: 0x8A5A3A, accent: 0xF4F4F4,
                               eye: 0x6A4A2A, hat: "kerchief", weapon: "bread", look: ["dress", "apron", "cheeks", "lashes"], npc: true)
        case "npc.weaver": Spec(body: .human, cloth: 0xB05090, trim: 0x7A3060, hair: 0x3A2A2A, accent: 0x9BE0FF,
                                eye: 0x4A6A3A, weapon: "yarn", look: ["dress", "shawl", "braid", "cheeks", "lashes"], npc: true)
        case "npc.miller": Spec(body: .human, cloth: 0xD8C8A0, trim: 0x8A7A5A, hair: 0xE0E0E0, accent: 0xF0F0F0,
                                eye: 0x4A7AB0, hat: "strawHat", weapon: "sack", look: ["beard", "apron", "flour"], npc: true)
        case "npc.monk": Spec(body: .human, cloth: 0x7A5A3A, trim: 0x5A4028, hair: 0x6A5A4A,
                              eye: 0x6A5A3A, weapon: "book", look: ["robe", "tonsure", "rope", "cowl", "rosary"], npc: true)
        case "npc.innkeeper": Spec(body: .human, cloth: 0x3A6A3A, trim: 0x5A4A3A, hair: 0x8A5A3A, accent: 0xF0EAD8,
                                   eye: 0x5A3A2A, weapon: "mug", look: ["shortHair", "mustache", "apron", "belly", "sleeves"], npc: true)
        case "npc.alchemist": Spec(body: .human, cloth: 0x3B5DC9, trim: 0x29366F, hair: 0xC0502A, accent: 0x3B5DC9,
                                   eye: 0x3AA070, hat: "mageHat", weapon: "flask", look: ["robe", "longHair", "stars", "lashes", "goggles"], npc: true)
        case "npc.princess": Spec(body: .human, cloth: 0xF27AA8, trim: 0xC04A7A, hair: 0xF0D070, accent: 0xFFFFFF, eye: 0x3A7AE0,
                                  hat: "tiara", look: ["dress", "longHair", "cheeks", "lashes", "puffSleeves", "necklace"], npc: true)
        // Valdemar · Capitán Rodrigo Vela (aspecto básico): coraza de cobre, tabardo azul, capa raída, barba gris.
        case "npc.guardCaptain": Spec(body: .human, cloth: 0x3B5DC9, trim: 0x4A4A5A, hair: 0x9A9AA0, metal: 0xC8693C, accent: 0x29366F,
                                      eye: 0x5A3A26, look: ["armor", "beard", "cape", "shortHair"], npc: true)
        default: Spec(body: .goblin, weapon: "club")
        }
    }

    /// Objetos con los que se habla (NPC con `look` de objeto): dibujo fijo con los colores de `fixed`.
    static func objectRows(_ id: String) -> [String]? {
        switch id {
        // Carta del alcalde: pergamino abierto sobre el escritorio, enrollado por arriba, con renglones de tinta,
        // la firma "F." y el lacre negro de luna con borde violeta (la Orden del Eclipse) con su cinta.
        case "npc.letter": [
            "..uttttttttttu..",
            ".ttttttttttttttu",
            ".tuuuuuuuuuuuuuv",
            "..vvvvvvvvvvvvv.",
            "..ttttttttttttu.",
            "..tqqjqqqjqqttu.",
            "..ttttttttttttu.",
            "..tqjqqqjqqqqtu.",
            "..ttttttttttttu.",
            "..tqqqjqttnnnnu.",
            "..tttttttnkkmnn.",
            "..tjjtj.tnkkkmn.",
            "..ttttttnnkkknn.",
            "..uuuuuuurnnnr..",
            "........x.x.x...",
        ]
        // Cartel del camino: poste con dos tablas en punta (Valdehierro a la izquierda, Rocaforja a la derecha),
        // letras talladas, clavos y piedras al pie.
        case "npc.signpost": [
            "........uo........",
            "........oq........",
            "..uooooooooooooo..",
            "..ojjoqjjoqjjooqo.",
            "..oooooooooo3oooqj",
            "..qqqqqqqqqqqqqqj.",
            "..jjjjjjjjjjjjjj..",
            "........oq........",
            "...uooooooooooooo.",
            "..oqjjoqjjqjjooq..",
            ".joooo3ooooooooq..",
            "..jqqqqqqqqqqqqqj.",
            "...jjjjjjjjjjjjj..",
            "........oq........",
            "........oj........",
            "........oq........",
            "........oj........",
            "........oq........",
            ".......ooqj.......",
            "......3oqqj2......",
            "....2343qjj432....",
        ]
        default: nil
        }
    }

    // MARK: - Humanoides (goblin, humano, esqueleto, bruto)

    struct Rig {
        var head: [String]
        /// Punto de la cabeza que se apoya en el cuello y centro de la coronilla (para gorros).
        var headNeck: (Int, Int)
        var crown: (Int, Int)
        var torso: [String]
        /// En el torso: cuello, fila de las caderas, x de cada cadera (trasera, delantera) y hombros.
        var neck: (Int, Int)
        var hipY: Int
        var hipX: (Int, Int)
        var shoulder: ((Int, Int), (Int, Int))
        var legLen: Int
        var legColors: String
        var foot: [String]
        var armLen: Int
        var armColors: String
        var hand: [String]
        var cuff: String? = nil
        var cuffLen = 0
    }

    static let goblinRig = Rig(
        head: [
            "......ABBBBC......",
            "A...AABBBBBBBC...C",
            "BA.ABBBBBBBBBBC.CC",
            ".BAABBBBBBBBBBBBC.",
            "..CABBkkkBBBkkkC..",
            "...ABB*eeBBB*eeC..",
            "...ABBeeEBBBeeEBB.",
            "...ABBBBBBBBBBBBBB",
            "....BBBBBkttrttBC.",
            ".....CBBBBkkkkkC..",
            ".......CCCCCCC....",
        ],
        headNeck: (9, 10), crown: (9, 0),
        torso: [
            "...KKLLLM...",
            "..KWXLLLLM..",
            ".KKLXYLLLLM.",
            ".KLLMLXYLMMN",
            ".YXXXXyXXXZ.",
            ".KLLMLLWXYN.",
            "..LMLL.XYN..",
        ],
        neck: (6, 0), hipY: 6, hipX: (3, 7), shoulder: ((2, 1), (9, 1)),
        legLen: 3, legColors: "BC", foot: ["XY.", "WXXZ"],
        armLen: 4, armColors: "BC", hand: ["AB", "BC"])

    static let humanRig = Rig(
        head: [
            "....ABBBBB..",
            "..AABBBBBBC.",
            ".ABBBBBBBBBC",
            ".ABBBBBBBBBC",
            ".ABBBBkkBBkk",
            ".BBCBB*eBB*e",
            ".BBCBBeEBBeE",
            ".BBBCBBBBBBB",
            "..CBBBBBBkBC",
            "...CCBBBBBC.",
            ".....CCCC...",
        ],
        headNeck: (6, 10), crown: (6, 0),
        torso: [
            "...KLBBLLM..",
            "..KKLLBLLLM.",
            ".KKLLLLLLLMN",
            ".KLLLLLLLLMN",
            ".KLLLMLLLLMN",
            ".YXXXXyXXXXZ",
            ".KLLMLLLWXYN",
            "..LLMLLLXYN.",
        ],
        neck: (6, 0), hipY: 7, hipX: (3, 7), shoulder: ((2, 1), (8, 1)),
        legLen: 4, legColors: "QR", foot: ["XY.", "WXXZ"],
        armLen: 5, armColors: "LM", hand: ["AB", "BC"], cuff: "MN", cuffLen: 1)

    static let skeletonRig = Rig(
        head: [
            "....ABBBBB..",
            "..AABBBBBBC.",
            ".ABBBBBBBBBC",
            ".ABBBBBBBBBC",
            ".ABBBkkkBBkk",
            ".BBBBkekBBke",
            ".BBCBkkkBBkk",
            ".CBBBBBBkBBC",
            "..CBkBkBkBk.",
            "...CBkBkBkC.",
            "....CCCCC...",
        ],
        headNeck: (6, 10), crown: (6, 0),
        torso: [
            "....BBC...",
            ".AABBBBBC.",
            "..BkBkBkC.",
            "..ABkBkBC.",
            "..BkBkBkC.",
            "...CBkBC..",
            "....BBC...",
            "..ABBBBC..",
        ],
        neck: (5, 0), hipY: 7, hipX: (3, 6), shoulder: ((1, 1), (7, 1)),
        legLen: 5, legColors: "B", foot: ["B.", "BBC"],
        armLen: 5, armColors: "B", hand: ["BC", "C."])

    static let bruteRig = Rig(
        head: [
            "...AABBBBC..",
            "..ABBBBBBBC.",
            ".ABBBBBBBBBC",
            ".ABBkkkBBkkk",
            ".BBBBB*eBB*e",
            ".BBCBBeEBBeEB",
            ".BBBBtBBBBtBC",
            "..CBBtkkkktC.",
            "...CCCCCCCC..",
        ],
        headNeck: (6, 8), crown: (6, 0),
        torso: [
            ".....ABBBBC.....",
            "..AABBBBBBBBBC..",
            ".ABBBBBBBBBBBBC.",
            "ABBBBCBBBBCBBBBC",
            "ABBBBBCCBCCBBBBC",
            ".BBBBBBBBBBBBBC.",
            "..BBBCBBCBBCBC..",
            "..YXXXXXyXXXXZ..",
            "..KLLLLLMLLLLN..",
            "..KLLLMN.KLLMN..",
        ],
        neck: (8, 1), hipY: 9, hipX: (4, 9), shoulder: ((1, 3), (13, 3)),
        legLen: 3, legColors: "PQR", foot: ["XXY.", "WXXXZ"],
        armLen: 6, armColors: "ABC", hand: ["ABB", "BBC", "CCD"], cuff: "WXY", cuffLen: 2)

    /// Cabeza de saco del espantapájaros (sustituye a la cabeza humana).
    static let sackHead = [
        "....ABBBBB..",
        "..AABBCBBBC.",
        ".ABBBBBBCBBC",
        ".ABCBBBBBBBC",
        ".ABBBB6eBB6e",
        ".BBBBBeeBBee",
        ".BBCBBBBBBBB",
        "..BBkBkBkBkC",
        "..CBBkBkBkBC",
        "...CCBBBBBC.",
        "....yzyzyz..",
    ]

    /// `orb`: lanza una esfera con la mano desnuda (sin arma en la mano; ver el rasgo "orbCaster").
    enum Style { case none, swing, thrust, bow, cast, throwing, claws, orb }

    static func drawHumanoid(_ g: inout PixelGrid, _ baseRig: Rig, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        var rig = baseRig
        let look = s.look
        if look.contains("sackHead") { rig.head = sackHead }
        if look.contains("hunch") { rig.neck.0 += 1 }
        if look.contains("bandaged") { rig.hand = ["st", "uv"] }   // manos vendadas
        let weapon = s.weapon.flatMap { weapons[$0] }
        let style: Style = look.contains("orbCaster") ? .orb : (weapon?.style ?? .none)
        // En el frame de daño los brazos no siguen la preparación del ataque.
        let act: Action = pose.hurt ? .idle : pose.action
        let skirt = look.contains("robe") || look.contains("dress")
        let fh = rig.foot.count
        let legW = rig.legColors.count
        let hipC = (rig.hipX.0 + rig.hipX.1 + legW) / 2
        var feet = pose.feet
        if skirt { feet.front = max(-1, min(1, feet.front)); feet.back = max(-1, min(1, feet.back)) }
        let hipRow = gy - fh - rig.legLen
        let tx = cx - hipC + pose.lean
        let ty = hipRow - rig.hipY + pose.bob
        let headDx = pose.action == .strike ? 1 : (pose.action == .windup ? -1 : 0)
        let hx = tx + rig.neck.0 - rig.headNeck.0 + headDx
        let hy = ty + rig.neck.1 - rig.headNeck.1 + (look.contains("hunch") ? 2 : 0)
        let sB = (tx + rig.shoulder.0.0, ty + rig.shoulder.0.1)
        let sF = (tx + rig.shoulder.1.0, ty + rig.shoulder.1.1)
        let L = rig.armLen

        // Hacia dónde van las manos y cómo se inclina el arma.
        // En reposo el arma se lleva al costado, inclinada hacia delante.
        var front = (pose.swing + 1, L - 1), back = (-pose.swing, L)
        var angle = weapon?.rest ?? 0
        if act == .idle { front = (1, L - 1); back = (0, L) }
        if act == .windup { back = (2, L - 1) }
        if act == .strike { back = (-2, L - 1) }
        switch (act, style) {
        case (.windup, .thrust): front = (-3, 1); angle = 90
        case (.strike, .thrust): front = (L, 1); angle = 90
        case (.windup, .bow): front = (L, -1); back = (1, 1)
        case (.strike, .bow): front = (L, -1)
        case (.windup, .cast): front = (0, -L)
        case (.strike, .cast): front = (L - 1, -1); angle = 60
        case (.windup, .claws): front = (-2, -L + 2); angle = -45
        case (.strike, .claws): front = (L + 1, 0); angle = 90
        // Esfera: alza la palma por delante de la capucha para cargarla y la empuja al frente.
        case (.windup, .orb): front = (3, -L - 1); back = (3, L - 3)
        case (.strike, .orb): front = (L, -1); back = (-3, L - 2)
        case (.windup, _):
            // Brazo alzado por detrás de la cabeza: el arma asoma por encima.
            front = (-2, hy + (style == .throwing ? -3 : -1) - sF.1); angle = style == .swing ? -45 : 0
        case (.strike, _): front = (L - 1, 0); angle = style == .swing ? 115 : 0
        default: break
        }
        if s.npc, s.weapon != nil { front = (2, L - 2); angle = 0 }  // aldeanos: sostienen el objeto delante
        if pose.hurt { front = (-1, L - 2); back = (-2, L - 1); angle = (weapon?.rest ?? 0) - 20 }  // brazos atrás

        let crown = (hx + rig.crown.0, hy + rig.crown.1)

        // 1. Capa y melena por detrás de todo.
        if look.contains("cape") {
            drawCape(&g, pal, neckX: tx + rig.neck.0, top: ty - 1, bottom: gy - 2, phase: pose.phase, action: pose.action,
                     ermine: look.contains("ermine"))
        }
        if look.contains("longHair") || look.contains("braid") {
            drawBackHair(&g, pal, x: hx + 1, y: hy + 3, length: look.contains("braid") ? 13 : 12, phase: pose.phase,
                         braid: look.contains("braid"))
        }
        if look.contains("quiver") {
            put(&g, ["..t.", ".tqu", ".qo.", "qoq.", "oq..", "q..."], sB.0 - 2, sB.1 - 3, pal)
        }

        // 2. Extremidades del lado lejano (más oscuras).
        var far = PixelGrid(width: canvasW, height: canvasH)
        let endB = (sB.0 + back.0, sB.1 + back.1)
        limb(&far, sB, endB, chars(rig.armColors, pal), cuff: rig.cuff.map { chars($0, pal) }, cuffLen: rig.cuffLen)
        put(&far, rig.hand, endB.0, endB.1, pal)
        drawLeg(&far, rig, pal, hip: (tx + rig.hipX.0, ty + rig.hipY),
                foot: (cx - hipC + rig.hipX.0 + feet.back, gy - fh - feet.liftBack), greaves: look.contains("greaves"))
        blit(far, onto: &g, dim: 0.3)

        // 3. Pierna cercana y falda.
        drawLeg(&g, rig, pal, hip: (tx + rig.hipX.1, ty + rig.hipY),
                foot: (cx - hipC + rig.hipX.1 + feet.front, gy - fh - feet.liftFront), greaves: look.contains("greaves"))
        if skirt {
            let dress = look.contains("dress")
            let sway = pose.action == .walk ? [-1, 0, 1, 0][pose.phase] : (pose.action == .strike ? -1 : 0)
            let w = rig.torso[0].count
            drawSkirt(&g, pal, top: ty + rig.hipY - 1, bottom: gy - 2, center: tx + w / 2,
                      topW: w - 2, bottomW: w + (dress ? 4 : 1), sway: sway, dress: dress, gold: look.contains("necklace"),
                      accentHem: look.contains("accentHem"))
        }

        // 4. Torso y sus prendas.
        put(&g, rig.torso, tx, ty, pal)
        drawTorsoDetails(&g, s, rig, pal, tx: tx, ty: ty, pose: pose)

        // 5. Cabeza (con sombra sobre el cuello).
        var headLayer = PixelGrid(width: canvasW, height: canvasH)
        drawHead(&headLayer, rig, s, pal, x: hx, y: hy, pose: pose)
        if let hatName = s.hat, let hat = hats[hatName] {
            put(&headLayer, hat.rows, crown.0 - hat.anchor.0, crown.1 - hat.anchor.1, pal.merging(hat.colors) { _, new in new })
        }
        let endF = (sF.0 + front.0, sF.1 + front.1)
        let hw = rig.hand.map(\.count).max() ?? 2
        let grip = (endF.0 + hw / 2, endF.1 + rig.hand.count / 2)
        let raised = act == .windup && style == .swing
        // En la preparación el brazo armado se echa atrás, por detrás de la cabeza.
        let armBehind = act == .windup && (style == .swing || style == .throwing || style == .claws || style == .none)
        if !armBehind { overlay(headLayer, onto: &g) }

        // 6. Brazo cercano, arma y mano encima del mango (en su propia capa, con contorno interior).
        var armLayer = PixelGrid(width: canvasW, height: canvasH)
        if raised, let weapon { drawWeapon(&armLayer, weapon, pal, grip: grip, angle: angle) }
        limb(&armLayer, sF, endF, chars(rig.armColors, pal), cuff: rig.cuff.map { chars($0, pal) }, cuffLen: rig.cuffLen)
        if look.contains("puffSleeves") { put(&armLayer, [".KL.", "KLLM", ".MN."], sF.0 - 1, sF.1 - 1, pal) }
        if look.contains("straw") { put(&armLayer, ["y.g", ".gz"], endF.0 - 1, endF.1 - 1, pal) }
        if !raised, let weapon {
            drawWeapon(&armLayer, weapon, pal, grip: grip, angle: angle)
            if style == .bow && act == .windup {
                // Flecha encajada, desde la mano trasera hasta más allá del arco.
                put(&armLayer, ["x.uuuuuuu12", "x"], endB.0, grip.1, pal)
            }
            if style == .cast && (act == .windup || act == .strike) {
                let spark = act == .strike ? (grip.0 + 6, grip.1 - 6) : (grip.0 - 1, grip.1 - 10)
                put(&armLayer, [".5.", "5c5", ".5."], spark.0, spark.1, pal)
            }
        }
        put(&armLayer, rig.hand, endF.0, endF.1, pal)
        if style == .orb { drawOrbCharge(&armLayer, pal, grip: grip, action: act) }
        if look.contains("pauldron") || look.contains("spikes") {
            let spiky = look.contains("spikes")
            put(&armLayer, spiky ? ["..t..", ".SSTU", "STTUV", ".VUV."] : [".SSU", "STTUV", ".VUV"],
                sF.0 - 1, sF.1 - (spiky ? 2 : 1), pal)
        }
        overlay(armLayer, onto: &g)
        if armBehind { overlay(headLayer, onto: &g) }
    }

    /// Pega una capa encima oscureciendo el borde de lo que tapa (contorno interior selectivo):
    /// así un brazo o un arma se leen aunque sean del mismo color que el torso.
    static func overlay(_ layer: PixelGrid, onto g: inout PixelGrid, edge: Double = 0.45) {
        var shaded = g
        for y in 0..<layer.height {
            for x in 0..<layer.width where layer[x, y] != nil {
                for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y + 1)] where layer[nx, ny] == nil {
                    if let c = g[nx, ny] { shaded[nx, ny] = mix(c, 0x1A1C2C, edge) }
                }
            }
        }
        g = shaded
        blit(layer, onto: &g, dim: 0)
    }

    /// Esfera de sombra en la mano (estilo `orb`): se forma sobre la palma alzada y estalla al empujarla.
    /// Violeta del color de acento (`FGO`) con núcleo claro (`m`, `*`) y chispas oscuras (`n`).
    static func drawOrbCharge(_ g: inout PixelGrid, _ pal: Colors, grip: (Int, Int), action: Action) {
        switch action {
        case .windup:
            put(&g, [
                "..n.m..",
                ".n.FG..",
                "..FmmGn",
                "m.Gm*G.",
                "..GGGO.",
                ".n.OO.n",
            ], grip.0 - 3, grip.1 - 7, pal)
        case .strike:
            put(&g, [
                "..m..n..",
                "n..FGG..",
                "..FmmGGO",
                ".Fm**mGO",
                ".Gm**GOn",
                "..GGGOO.",
                "m..OO..n",
            ], grip.0 + 1, grip.1 - 4, pal)
        default: break
        }
    }

    static func drawLeg(_ g: inout PixelGrid, _ rig: Rig, _ pal: Colors, hip: (Int, Int), foot: (Int, Int), greaves: Bool) {
        let colors = chars(rig.legColors, pal)
        limb(&g, hip, (foot.0, foot.1 - 1), colors, cuff: greaves ? chars("STU", pal) : nil, cuffLen: greaves ? 3 : 0)
        put(&g, greaves ? rig.foot.map { $0.replacingOccurrences(of: "X", with: "T").replacingOccurrences(of: "W", with: "S") } : rig.foot,
            foot.0, foot.1, pal)
    }

    static func drawSkirt(_ g: inout PixelGrid, _ pal: Colors, top: Int, bottom: Int, center: Int,
                          topW: Int, bottomW: Int, sway: Int, dress: Bool, gold: Bool = false, accentHem: Bool = false) {
        let h = bottom - top + 1
        guard h > 0 else { return }
        for i in 0..<h {
            let t = Double(i) / Double(max(1, h - 1))
            let w = Int((Double(topW) + Double(bottomW - topW) * t).rounded())
            let shift = Int((Double(sway) * t).rounded())
            let x0 = center - w / 2 + shift
            for k in 0..<w {
                var ch: Character = "L"
                if k == 0 { ch = "K" } else if k == w - 1 { ch = "N" } else if k == w - 2 { ch = "M" }
                else if i > 1 && (k + 1) % 3 == 0 { ch = "M" }
                if i == h - 1 { ch = gold ? (k % 2 == 0 ? "y" : "z") : (dress ? (k == 0 ? "Q" : "R") : (k == 0 ? "M" : "N")) }
                // Ribete del color de acento sobre el bajo (túnicas de la Orden del Eclipse).
                if accentHem && i == h - 2 { ch = k == 0 ? "G" : "O" }
                if dress && i == h - 3 && k % 2 == 1 { ch = gold ? "P" : "M" }
                g[x0 + k, top + i] = pal[ch]
            }
        }
    }

    static func drawCape(_ g: inout PixelGrid, _ pal: Colors, neckX: Int, top: Int, bottom: Int, phase: Int,
                         action: Action, ermine: Bool) {
        let h = bottom - top + 1
        let flutter = action == .walk ? [0, 1, 0, 1][phase] : (action == .strike ? 2 : 0)
        for i in 0..<h {
            let spread = 3 + (i * 8) / max(1, h) + (i > h / 2 ? flutter : 0)
            let x0 = neckX - 1 - spread
            let x1 = neckX + 2
            for x in x0...x1 {
                var ch: Character = "G"
                if x == x0 { ch = "F" } else if x == x0 + 1 && i % 4 != 3 { ch = "F" } else if (x - x0) % 3 == 0 { ch = "O" }
                if i == h - 1 && (x - x0) % 2 == 1 { continue }   // borde deshilachado
                g[x, top + i] = pal[ch]
            }
        }
    }

    static func drawBackHair(_ g: inout PixelGrid, _ pal: Colors, x: Int, y: Int, length: Int, phase: Int, braid: Bool) {
        if braid {
            for i in 0..<length {
                let ch: Character = i % 2 == 0 ? "H" : "J"
                g[x + 1, y + i] = pal[ch]; g[x + 2, y + i] = pal[i % 2 == 0 ? "I" : "I"]
            }
            put(&g, ["FGF", ".G."], x, y + length, pal)
            return
        }
        let sway = [0, 0, 1, 1][phase]
        for i in 0..<length {
            let w = 5 - (i > length - 3 ? (i - (length - 3)) : 0)
            let off = i > length / 2 ? sway : 0
            for k in 0..<w {
                let ch: Character = k == 0 ? "H" : (k == w - 1 ? "J" : ((k + i) % 4 == 0 ? "J" : "I"))
                g[x - 1 + k - off, y + i] = pal[ch]
            }
        }
    }

    /// Prendas y detalles encima del torso (armadura, delantal, cinturón de cuerda, parches…).
    static func drawTorsoDetails(_ g: inout PixelGrid, _ s: Spec, _ rig: Rig, _ pal: Colors, tx: Int, ty: Int, pose: Pose) {
        let look = s.look
        let w = rig.torso[0].count
        let body = s.body
        if look.contains("armor") {
            switch body {
            case .brute:
                put(&g, ["....SSTTU.....", "..STTTTTTTUU..", ".STTSTTTTTTUV.", ".STTTTSTTTTUV.", "..TUTUTUTUTV..", "...VVVVVVVV..."],
                    tx + 1, ty + 1, pal)
            case .goblin:
                put(&g, ["..VSSTUV..", ".VSTTTTUV.", "VSTTSTTTUV", "VSTTTTTUUV", ".VUUSUUUV."], tx + 1, ty, pal)
            default:
                put(&g, ["..VSSTTUV..", ".VSTTTTTTUV", ".VSTSTTTTUV", ".VSTTTTTUUV", "..VUSUUSUV."], tx, ty + 1, pal)
            }
        }
        if look.contains("ermine") {
            put(&g, [".tttttttttt.", "tuktttkttktu", ".ttkttttkt.."], tx + rig.neck.0 - 6, ty, pal)
        }
        if look.contains("goldTrim") { put(&g, ["..yyyyyz"], tx + 1, ty + 4, pal) }
        if look.contains("chain") { put(&g, ["..y.y.y", "...y.y.x"], tx + 1, ty + 2, pal) }
        if look.contains("apron") {
            let tall = body == .brute ? 9 : (s.look.contains("dress") || s.look.contains("robe") ? 10 : 8)
            let ax = tx + w / 2 - 2, ay = ty + 2
            for i in 0..<tall {
                let aw = i < 3 ? 4 : (i < tall - 2 ? 6 : 7)
                let x0 = i < 3 ? ax : (i < tall - 2 ? ax - 1 : ax - 2)
                for k in 0..<aw {
                    var ch: Character = k == 0 ? "F" : (k >= aw - 1 ? "O" : "G")
                    if i > 4 && k == aw / 2 { ch = "O" }        // pliegue
                    if i == tall - 1 { ch = k % 2 == 0 ? "O" : "G" }  // dobladillo
                    g[x0 + k, ay + i] = pal[ch]
                }
            }
            put(&g, ["WXXY"], ax, ay + 3, pal)                      // lazada en la cintura
            g[ax + 1, ay + 6] = pal["O"]; g[ax + 2, ay + 6] = pal["O"]   // bolsillo
            if look.contains("flour") { put(&g, ["*..", "..*", ".*."], ax, ay + 4, pal) }
        }
        if look.contains("rope") {
            put(&g, ["tsutsutsut", "........u", "........t", "........u"], tx + 1, ty + rig.hipY - 2, pal)
        }
        if look.contains("cowl") { put(&g, [".KLLLLLM", "KLMMMMLMN"], tx + 1, ty, pal) }
        // Orden del Eclipse: faja del color de acento con lazada y caídas, luna negra con corona violeta
        // en el pecho (a la izquierda del brazo delantero para que no la tape) y libro con cadena al cinto.
        if look.contains("sash") {
            let sy = ty + rig.hipY - 1
            put(&g, [".F" + String(repeating: "G", count: w - 4) + "O"], tx, sy, pal)
            put(&g, ["FmO", ".GO", ".G.O", "..O"], tx + w - 5, sy, pal)
        }
        if look.contains("eclipseMoon") {
            put(&g, [
                ".mFG.",
                "mkkEG",
                "FkkkO",
                "GkkkO",
                ".GOO.",
            ], tx + 2, ty + 1, pal.merging(["E": 0x3A3046]) { _, new in new })
        }
        if look.contains("tomeAtHip") {
            // Libro cerrado de tapas negras con broche de luna; cuelga de la faja por una cadena.
            let book: Colors = ["a": 0x4E4260, "b": 0x30283C, "c": 0x1E1828]
            put(&g, [
                "..3.",
                "abbc",
                "abmc",
                "bmnc",
                "uttc",
            ], tx - 1, ty + rig.hipY - 1, pal.merging(book) { _, new in new })
        }
        if look.contains("shawl") { put(&g, [".FGGGGGGO.", "FGOGOGOGOO", ".GOGOGOO.", "..G.O.O.."], tx + 1, ty + 1, pal) }
        if look.contains("necklace") { put(&g, ["..y...y..", "...yxy..."], tx + 1, ty + 1, pal) }
        if look.contains("rosary") { put(&g, ["...z", "..z.", ".z..", "z...", "y..."], tx + w - 5, ty + 2, pal) }
        if look.contains("stars") { put(&g, ["y.....", "....y.", "..y..."], tx + 2, ty + 2, pal) }
        if look.contains("patches") { put(&g, ["PQ.....", "QR..k.k", "....PQk", "....QR."], tx + 2, ty + 2, pal) }
        if look.contains("straw") { put(&g, ["y.g.g.y", ".gzgzg."], tx + w / 2 - 3, ty - 1, pal) }
        if look.contains("beads") { put(&g, [".t.u.t.", "..x.c.."], tx + 2, ty + 1, pal) }
        if look.contains("loincloth") { put(&g, ["....XYZ", "....XY.", ".....Y."], tx + 1, ty + rig.hipY - 1, pal) }
        if look.contains("rags") { put(&g, ["KLLLMN", "LM.LN.", "M...N."], tx + 2, ty + rig.hipY - 1, pal) }
        if look.contains("sleeves") { put(&g, ["ttu"], tx + rig.shoulder.1.0 - 1, ty + rig.shoulder.1.1, pal) }
        if look.contains("belly") && body == .brute {
            put(&g, ["..ABBBBBC..", ".ABBBBBBBC.", ".BBBBBBBBC.", "..CBBBBCC.."], tx + 2, ty + 4, pal)
        } else if look.contains("belly") {
            put(&g, ["..KLLLM.", ".KLLLLMN", ".LLLLLMN", "..MMMN.."], tx + 2, ty + 3, pal)
        }
        if look.contains("embers") {
            let sparks = [["6...5", "..7.."], ["..5..", "6...7"], ["5..6.", "...7."], [".7...", "...56"]][pose.phase]
            put(&g, sparks, tx + 4, ty - 2, pal)
        }
        if look.contains("warpaint") { put(&g, ["..x..x..x", "...x..x.."], tx + 3, ty + 3, pal) }
        if look.contains("golem") { put(&g, ["..D..C...", ".DD...CD.", "..C.D..D."], tx + 3, ty + 2, pal) }
    }

    static func drawHead(_ g: inout PixelGrid, _ rig: Rig, _ s: Spec, _ pal: Colors, x: Int, y: Int, pose: Pose) {
        let look = s.look
        let hooded = s.hat == "hood" || s.hat == "eclipseHood" || s.hat == "greatHelm"
        if look.contains("braids") { put(&g, ["HI", "IJ", "HI", "IJ", ".J"], x - 1, y + 4, pal) }
        put(&g, rig.head, x, y, pal)
        guard s.body == .human || s.body == .brute || s.body == .goblin || s.body == .skeleton else { return }
        if pose.hurt {
            // Ojos apretados: párpado de piel y una raya (de color si los ojos brillan).
            let lid: Character = look.contains("glowEyes") ? "e" : "k"
            let eyes: [(Int, Int, Int)] = switch s.body {
            case .human where !look.contains("sackHead"): [(5, 6, 2), (5, 10, 2)]
            case .goblin: [(5, 6, 3), (5, 12, 3)]
            case .brute: [(4, 6, 2), (4, 10, 2)]
            default: []
            }
            for (row, col, w) in eyes {
                put(&g, [String(repeating: "B", count: w), String(repeating: lid, count: w)], x + col, y + row, pal)
            }
        }

        // Peinados (cabeza humana de 12 de ancho).
        if s.body == .human && !hooded && !look.contains("sackHead") {
            var hair: [String] = []
            if look.contains("messyHair") {
                hair = ["..I.H.I.....", "..HIHIIJ....", ".HHIIIIIIJ..", ".HIIIIIIIIJ.", ".IIJIIJIIJJ.", ".IIJ.J......", ".IJ.........", ".J.........."]
            } else if look.contains("tonsure") {
                hair = ["............", "....*.......", "............", ".I.......J..", ".IIJ.....JJ.", ".IIJ........", ".IJ........."]
            } else if look.contains("longHair") || look.contains("braid") {
                hair = ["...HHIIII...", "..HHIIIIIIJ.", ".HIIIIIIIIIJ", ".IIIJIIJIIJJ", ".IIJ......J.", ".IIJ........", ".IIJ........", ".IIJ........", "..IJ........"]
            } else if !look.contains("zombie") || true {
                hair = ["...HHIIII...", "..HHIIIIIIJ.", ".HIIIIIIIIIJ", ".IIIJIIJIIJJ", ".IIJ........", ".IJ.........", ".J.........."]
            }
            if look.contains("zombie") { hair = ["............", "...I..J.....", "..IJ.IJI.J..", ".IJ..J..J...", ".I..........", ".J.........."] }
            put(&g, hair, x, y - (look.contains("messyHair") ? 1 : 0), pal)
        }
        // Rasgos de la cara.
        if look.contains("lashes") { put(&g, ["....kkk...k"], x + 1, y + 4, pal) }
        if look.contains("cheeks") { put(&g, ["p...p"], x + 6, y + 7, pal) }
        if look.contains("stubble") { put(&g, ["..J.J.J", ".J.J.J."], x + 5, y + 8, pal) }
        if look.contains("beard") {
            put(&g, [".....HIIIIJ", "....HIIkkIIJ", "....IIIIIIIJ", ".....IIIIIJ", "......IIJJ", ".......IJ"], x, y + 7, pal)
        }
        if look.contains("mustache") { put(&g, ["HIIJ", "I..J"], x + 7, y + 8, pal) }
        if look.contains("eyepatch") { put(&g, [".kkkkkk....", "......kk...", "......kk..."], x, y + 4, pal) }
        if look.contains("scar") {
            switch s.body {
            case .brute: put(&g, ["x....", ".x...", "..x.."], x + 8, y + 2, pal)
            default: put(&g, ["x..", ".x.", "..x"], x + 8, y + 3, pal)
            }
        }
        if look.contains("longNose") { put(&g, [".B.", "..BC", "..DC"], x + 10, y + 6, pal) }
        if look.contains("mask") {
            switch s.body {
            case .goblin: put(&g, ["....KLLLLLLLM.", "...KLLLLLLLLMN", "....LMMMMMMMN."], x + 3, y + 7, pal)
            default: put(&g, ["...KLLLLLM", "...KLLLLLMN", "....MMMMMN."], x + 2, y + 7, pal)
            }
        }
        if look.contains("goggles") {
            switch s.body {
            case .goblin: put(&g, [".......WXXXXXXXXY", "......XcbXXXXcbX."], x, y + 2, pal)
            default: put(&g, ["WXXXXXXXXY", "...XcbXXcb"], x + 2, y + 2, pal)
            }
        }
        if look.contains("feathers") { put(&g, ["x.c.", "x.c.", ".xc.", "..q."], x + 4, y - 4, pal) }
        if look.contains("horns") && s.body == .brute { put(&g, ["t.......t", "u.......u", ".v.....v."], x + 2, y - 2, pal) }
        if look.contains("mossHair") { put(&g, ["...HIHIH...", "..HIIJIIJ...", ".IJ.J..J.J.."], x, y - 1, pal) }
        if look.contains("bigTooth") { put(&g, ["t", "u"], x + 8, y + 6, pal) }
        if look.contains("warpaint") { put(&g, ["x...x", ".x...x"], x + 5, y + 5, pal) }
        if look.contains("crows") && pose.action != .strike {
            put(&g, [".kk", "kkky"], x - 3, y - 2 + (pose.phase % 2), pal)
        }
    }

    static func drawWeapon(_ g: inout PixelGrid, _ w: Weapon, _ pal: Colors, grip: (Int, Int), angle: Double) {
        let p = pal.merging(w.colors) { _, new in new }
        let (sprite, pivot) = rotated(w.rows, p, pivot: w.grip, degrees: angle)
        g.draw(sprite, x: grip.0 - pivot.0, y: grip.1 - pivot.1)
    }

    // MARK: - Gorros (anclados al centro de la coronilla)

    struct Hat {
        let rows: [String]
        let anchor: (Int, Int)
        var colors: Colors = [:]
    }

    static let hats: [String: Hat] = [
        "helmet": Hat(rows: [
            "....SSTTU....",
            "..SSTTTTTTU..",
            ".STTTTTTTTTU.",
            ".STTTTTTTTTUV",
            "VUSUUSUUSUUSV",
        ], anchor: (6, 1)),
        "leatherCap": Hat(rows: [
            "...WWXXXY...",
            "..WXXXXXXXY.",
            ".WXXXXXXXXXY",
            ".ZYYYYYYYYYZ",
        ], anchor: (6, 1)),
        "hood": Hat(rows: [
            "....KKLLLM....",
            "..KKLLLLLLLM..",
            ".KLLLLLLLLLLM.",
            ".KLLLLLLLLLLMN",
            "KLLLLMNNNNNNNN",
            "KLLLMN......N.",
            "KLLLMN........",
            "KLLLMN........",
            "KLLLMN........",
            "KLLLLMN.......",
            ".KLLLLMN......",
            ".KLLLLLMN.....",
            "..KLLLLLMN....",
        ], anchor: (7, 2)),
        // Capucha de la Orden del Eclipse: punta caída hacia atrás, ribete violeta alrededor de la cara
        // y sombra honda bajo el borde (solo brillan los ojos).
        "eclipseHood": Hat(rows: [
            "KLM............",
            ".KLLM..........",
            "..KKKKLLLM.....",
            "..KKLLLLLLLLM..",
            ".KKLLLLLLLLLLM.",
            ".KLLLMLLLLLLLMN",
            "KLLLMLLLLLLLLMN",
            "KLLLMLLFFFGGGGO",
            "KLLMLLFkDDDDDDN",
            "KLLMLLGk.......",
            "KLLMLLGk.......",
            "KLMLLMGk.......",
            ".KMLLMGO.......",
            "..KMMGO........",
        ], anchor: (8, 4)),
        "bandana": Hat(rows: [
            "....FGGGG...",
            "..FFGGGGGGO.",
            ".FGGG*GGGGGO",
            ".OGOOOOOOOOO",
            "GO..........",
            "O...........",
        ], anchor: (6, 0)),
        "witchHat": Hat(rows: [
            "..GO............",
            "...GGO..........",
            "....GGGO........",
            ".....FGGO.......",
            ".....FGGGO......",
            "....FGGGGGO.....",
            "....yyygyyyz....",
            "..FFGGGGGGGGGO..",
            "FFGGGGGGGGGGGGGO",
            ".OOOOOOOOOOOOOO.",
        ], anchor: (8, 7)),
        "mageHat": Hat(rows: [
            "........FO...",
            ".......FGO...",
            "......FGGGO..",
            ".....FGgGGO..",
            "....FGGGGGGO.",
            "...FGGGGGyGGO",
            ".FFGGGGGGGGGGGO",
            "..OOOOOOOOOOOO.",
        ], anchor: (7, 6)),
        "strawHat": Hat(rows: [
            ".....addd.....",
            "....adddddi...",
            "...adddddddi..",
            "...xxxxxxxxx..",
            "adddadddadddddi",
            ".iiiiiiiiiiiii.",
        ], anchor: (7, 3), colors: ["a": 0xF8E0A0, "d": 0xE0B860, "i": 0xA88038]),
        "hornedHelmet": Hat(rows: [
            "t.............t",
            "tu...........ut",
            ".tu..STTTU..uv.",
            "..vSSTTTTTTUv..",
            "..STTTTTTTTTUV.",
            ".VUSUUSUUSUUSV.",
        ], anchor: (7, 3)),
        "greatHelm": Hat(rows: [
            "....FFG......",
            "...FGGO......",
            "....STTTTU...",
            "..SSTTTTTTUU.",
            ".STTTTTTTTTUV",
            ".STTTTTTTTTUV",
            ".STTTkkkkkkkk",
            ".STTTkeEkkeEk",
            ".STTTTTTTTTUV",
            ".STTUkTkTkTUV",
            ".STTTTTTTTTUV",
            "..VUUUUUUUUV.",
            "...VVVVVVVV..",
        ], anchor: (6, 2)),
        "crown": Hat(rows: [
            "y...g...y",
            "yg.gyg.gz",
            "gyyyxyyyz",
            "yzyzyzyzz",
        ], anchor: (4, 3)),
        "bigCrown": Hat(rows: [
            "g.....g.....g",
            "gy...gyg...gz",
            "gyy.gyxyg.yyz",
            "gyyyyyyyyyyyz",
            "ycyyyxyyycyyz",
            "zzzzzzzzzzzzz",
        ], anchor: (6, 4)),
        "tiara": Hat(rows: [
            "...g...",
            ".g.c.g.",
            "gyyyyyz",
        ], anchor: (3, 2)),
        "kerchief": Hat(rows: [
            "....aadd.....",
            "..aaaddddi...",
            ".adddddddddi.",
            ".dddddddddddi",
            "id.iiiiiiiii.",
            "i............",
        ], anchor: (6, 2), colors: ["a": 0xFFFFFF, "d": 0xE4E4EC, "i": 0xA8A8BC]),
    ]

    // MARK: - Armas y objetos (en vertical, con la empuñadura en `grip`)

    struct Weapon {
        let rows: [String]
        let grip: (Int, Int)
        let style: Style
        /// Inclinación al andar (grados).
        var rest = 0.0
        var colors: Colors = [:]
    }

    static let weapons: [String: Weapon] = [
        "club": Weapon(rows: [".oq.", "ooqq", "oqoq", "oqqj", ".oqj", ".oq.", ".oq.", ".qj.", ".qj."], grip: (1, 7), style: .swing, rest: 50),
        "spikedClub": Weapon(rows: ["2.2..", ".oqq.", "2oqoq2", ".oqqj", "2oqoj2", ".oqq.", "..oq.", "..oq.", "..qj.", "..qj."],
                             grip: (2, 8), style: .swing, rest: 45),
        "dagger": Weapon(rows: [".1.", ".13", ".13", ".13", "yyz", ".q.", ".j."], grip: (1, 5), style: .thrust, rest: 60),
        "sword": Weapon(rows: ["..1.", ".123", ".123", ".123", ".123", ".123", ".123", "gyyz", "..q.", "..j.", "..y."], grip: (2, 8), style: .swing, rest: 40),
        "bigSword": Weapon(rows: ["..1..", ".112.", ".1223", ".1223", ".1223", ".1223", ".1223", ".1223", ".1223", ".1223",
                                  "gyxyz", "..q..", "..j..", "..q..", "..y.."], grip: (2, 12), style: .swing, rest: 35),
        "spear": Weapon(rows: [".1.", "113", "123", ".3.", ".y.", ".o.", ".q.", ".o.", ".q.", ".o.", ".q.", ".o.", ".q.", ".o.", ".q.", ".o.", ".q.", ".j."],
                        grip: (1, 13), style: .thrust, rest: 45),
        "pitchfork": Weapon(rows: ["1.1.1", "2.2.2", "3.3.3", "33333", "..o..", "..q..", "..o..", "..q..", "..o..", "..q..", "..o..", "..j.."],
                            grip: (2, 8), style: .thrust, rest: 40),
        "staff": Weapon(rows: [".c.", "*cb", "qbq", ".q.", ".o.", ".q.", ".o.", ".q.", ".o.", ".q.", ".o.", ".q.", ".o.", ".j."], grip: (1, 10), style: .cast, rest: 35),
        "skullStaff": Weapon(rows: [".m.", "ttu", "kmk", "tuv", ".k.", ".j.", ".q.", ".j.", ".q.", ".j.", ".q.", ".j.", ".q.", ".j."], grip: (1, 10), style: .cast, rest: 35),
        "bow": Weapon(rows: ["q...", "sq..", "s.o.", "s..o", "s..o", "s..q", "s..o", "s..o", "s.o.", "sq..", "q..."], grip: (3, 5), style: .bow, rest: 10),
        "sling": Weapon(rows: [".4.", "q.q", "q.q", ".q.", ".q."], grip: (1, 4), style: .swing),
        "axe": Weapon(rows: [".q.12.", "3q1223", "3q1223", ".q1223", ".q.12.", ".o....", ".q....", ".o....", ".q....", ".j...."],
                      grip: (1, 7), style: .swing, rest: 30),
        "bomb": Weapon(rows: ["..65", ".q..", ".44.", "4234", "4344", ".44."], grip: (1, 5), style: .throwing),
        "flag": Weapon(rows: ["y......", "oFFFGGO", "oFGyyGO", "oFyGGyO", "oGGyyGO", "oGGGGO.", "oGO.GO.", "q......", "o......",
                              "q......", "o......", "q......", "j......"], grip: (0, 10), style: .swing, rest: 35),
        "scythe": Weapon(rows: [".q1122...", ".q..12233", ".q....233", ".o......3", ".q.......", ".o.......", ".q.......", ".o.......",
                                ".q.......", ".o.......", ".j......."], grip: (1, 8), style: .swing, rest: 20),
        "hammer": Weapon(rows: ["122233", "123334", "233444", "..oq..", "..oq..", "..oq..", "..oq..", "..qj..", "..qj.."],
                         grip: (2, 6), style: .swing),
        "claws": Weapon(rows: ["t.t", "tut", ".u."], grip: (1, 2), style: .claws),
        // Objetos de los aldeanos
        "bread": Weapon(rows: ["..go", ".goq", "goq.", "oq.."], grip: (1, 2), style: .none),
        "yarn": Weapon(rows: [".FG.", "FGFO", "GFGO", ".GO."], grip: (1, 3), style: .none),
        "sack": Weapon(rows: [".s..", "tut.", "tttu", "tuuv", ".vv."], grip: (1, 2), style: .none),
        "book": Weapon(rows: ["xxxk", "xgxk", "xxxk", "tttk"], grip: (1, 2), style: .none),
        "mug": Weapon(rows: ["*ss.", "oyq.", "oyqj", "oyqj", "qqj."], grip: (1, 3), style: .none),
        "flask": Weapon(rows: [".q.", ".1.", "1cc", "cmm", "mmn"], grip: (1, 4), style: .none, colors: ["c": 0xB8F0FF]),
    ]

    // MARK: - Rata

    static func drawRat(_ g: inout PixelGrid, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        let p = pose.phase
        var bodyDx = 0, headDy = 0, open = false
        var legA = 0, lift = (0, 0)
        switch pose.action {
        case .walk, .idle: legA = [1, 0, -1, 0][p]; lift = (p == 1 ? 1 : 0, p == 3 ? 1 : 0)
        case .windup: bodyDx = -1; headDy = -2; open = true; legA = 1
        case .strike: bodyDx = 2; headDy = 1; open = true; legA = 2
        }
        let bob = pose.action == .walk ? [0, -1, 0, -1][p] : (pose.action == .strike ? 1 : 0)
        let bx = cx - 8 + bodyDx, by = gy - 7 + bob
        // Cola (o colas del rey de las ratas, anudadas) que ondula.
        let tails = s.look.contains("tails") ? 3 : 1
        for t in 0..<tails {
            let fan = tails == 1 ? 0 : t - 1
            for i in 0..<(4 + t) {
                let wave = Int((1.2 * sin(Double(i) * 0.9 + Double(p) * .pi / 2 + Double(t) * 2.1)).rounded())
                let spread = i > 1 ? ((i - 1) * fan * 2) / 3 : 0
                g[bx - 1 - i, by + 3 + wave + spread] = pal[i < 2 ? "C" : "p"]
            }
        }
        if tails > 1 { put(&g, ["rp", "pr"], bx - 3, by + 2, pal) }   // el nudo
        // Patas lejanas, cuerpo, patas cercanas.
        var far = PixelGrid(width: canvasW, height: canvasH)
        for hip in [2, 7] {
            let d = hip == 2 ? -legA : legA
            limb(&far, (bx + hip, by + 4), (bx + hip + d, gy - 2), [pal["C"]!])
            put(&far, ["pp"], bx + hip + d, gy - 1, pal)
        }
        blit(far, onto: &g, dim: 0.3)
        put(&g, [
            "...AABBC..",
            ".AABABBBC.",
            "ABBBBABBCC",
            "BBIHHHHBCC",
            ".CCIIIICC.",
        ], bx, by, pal)
        if s.look.contains("cape") {
            // Manto real con ribete de armiño sobre el lomo.
            put(&g, ["....tktt", "..FGGGtu", "FFGGOGt.", "G.O.O..."], bx + 1, by - 1 + [0, 0, 1, 1][p], pal)
        }
        if s.look.contains("sores") { put(&g, ["n..", "..m", ".n."], bx + 2, by + 1, pal) }
        for hip in [1, 6] {
            let d = hip == 1 ? legA : -legA
            let l = hip == 1 ? lift.0 : lift.1
            limb(&g, (bx + hip, by + 4), (bx + hip + d, gy - 2 - l), [pal["B"]!])
            put(&g, ["pp"], bx + hip + d, gy - 1 - l, pal)
        }
        let hx = bx + 7, hy = by - 3 + headDy
        put(&g, open ? [
            "AB......",
            "BpCBB...",
            "ABB*eB..",
            "BBBeEBBB",
            "CBBBBtrp",
            ".CCCBrrt",
            "..CCCC..",
        ] : [
            "AB......",
            "BpCBB...",
            "ABB*eB..",
            "BBBeEBBB",
            "CBBBBBBp",
            ".CCCCtk.",
        ], hx, hy, pal)
        put(&g, ["u", ".u"], hx + 8, hy + 3, pal)
        if s.look.contains("scar") { put(&g, ["x.", ".x", "..x"], hx + 2, hy + 1, pal) }
        if let hat = s.hat.flatMap({ hats[$0] }) { put(&g, hat.rows, hx + 3 - hat.anchor.0, hy - hat.anchor.1, pal) }
    }

    // MARK: - Perro y lobo

    static func drawDog(_ g: inout PixelGrid, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        let p = pose.phase
        var bodyDx = 0, headDx = 0, headDy = 0, open = false
        var front = 0, rear = 0, lift = (0, 0, 0, 0)
        switch pose.action {
        case .walk, .idle:
            front = [2, 0, -2, 0][p]; rear = -front
            lift = (p == 1 ? 1 : 0, p == 3 ? 1 : 0, p == 3 ? 1 : 0, p == 1 ? 1 : 0)
        case .windup: bodyDx = -1; headDy = 1; front = 2; rear = 1; open = true
        case .strike: bodyDx = 2; headDy = -1; front = 3; rear = -2; open = true
        }
        let bob = pose.action == .walk ? [0, -1, 0, -1][p] : (pose.action == .windup ? 1 : 0)
        let bx = cx - 9 + bodyDx, by = gy - 12 + bob
        let fur = chars("BC", pal)
        // Cola peluda que se menea.
        let wag = pose.action == .walk ? [0, 1, 0, -1][p] : (pose.action == .windup ? -1 : 2)
        limb(&g, (bx, by + 2), (bx - 2, by - 1 - wag), fur)
        put(&g, ["H", "A"], bx - 2, by - 3 - wag, pal)
        // Patas lejanas (más oscuras).
        var far = PixelGrid(width: canvasW, height: canvasH)
        drawPaw(&far, pal, hip: (bx + 3, by + 4), dx: -rear, lift: lift.2)
        drawPaw(&far, pal, hip: (bx + 11, by + 4), dx: -front, lift: lift.3)
        blit(far, onto: &g, dim: 0.32)
        put(&g, [
            "......AAB.....",
            "..AABBBABBBC..",
            ".ABABBBBBABBHC",
            "ABBBBABBBBBHHC",
            "BBBBBBBBBBBHHC",
            "CBBCCCCCCCBHC.",
            ".CC......CCC..",
        ], bx, by, pal)
        if s.look.contains("mangy") { put(&g, ["..D....p..", "....p...D.", ".C...D...."], bx + 2, by + 2, pal) }
        if s.look.contains("saddle") { put(&g, ["..WWXXY..", ".XyXXXXZ.", "..Z...Z.."], bx + 2, by, pal) }
        drawPaw(&g, pal, hip: (bx + 1, by + 4), dx: rear, lift: lift.0)
        drawPaw(&g, pal, hip: (bx + 9, by + 4), dx: front, lift: lift.1)
        if s.look.contains("rider") {
            // Goblin jinete con lanza.
            let r = by - 9 + (p % 2)
            let gob: Colors = ["G": 0x5DAA48, "g": 0x3A7A3A, "h": 0x8CD070, "C": 0x8F5A32, "c": 0x5E3A24]
            let rp = pal.merging(gob) { _, new in new }
            let lance = pose.action == .strike ? 90.0 : (pose.action == .windup ? -30 : 15)
            put(&g, [
                "g...hhGG...g",
                "gg.hGGGGG.gg",
                ".ghGGkGGkGg.",
                "..GGG*eG*eG.",
                "..gGGGGGGGGG",
                "...gGtktkg..",
                "....CCCCC...",
                "...CCcCCCc..",
                "...gCCCCCg..",
                "....cc.cc...",
            ], bx + 2, r, rp)
            var arm = PixelGrid(width: canvasW, height: canvasH)
            let grip = pose.action == .strike ? (bx + 12, r + 6) : (bx + 10, r + 7)
            drawWeapon(&arm, weapons["spear"]!, pal, grip: grip, angle: lance)
            put(&arm, ["hG", "Gg"], grip.0 - 1, grip.1 - 1, rp)
            overlay(arm, onto: &g)
        }
        if s.look.contains("mane") {
            // Melena del alfa: mechones claros sobre cuello y lomo.
            put(&g, ["...H..H.H..", "..HI.HIHIJ.", ".HIIHIIJIJ.", "HIIJIIJIJJ.", "IIJIIJIJJ..", ".IJIJJIJ...", "..J.JJ....."], bx + 3, by - 4, pal)
        }
        let hx = bx + 9 + headDx, hy = by - 4 + headDy
        put(&g, open ? [
            ".AC.AC....",
            ".BCABC....",
            "ABBBBBBC..",
            "ABB*eBBBBk",
            "BBBeEBBHHk",
            "CBBBBHtrt.",
            ".CCHHrrr..",
            "..CHHHtC..",
        ] : [
            ".AC.AC....",
            ".BCABC....",
            "ABBBBBBC..",
            "ABB*eBBBBk",
            "BBBeEBBHHk",
            "CBBBBHHkk.",
            ".CCHHHC...",
        ], hx, hy, pal)
        if s.look.contains("scar") { put(&g, ["x..", ".x.", "..x", "..x"], hx + 3, hy + 1, pal) }
    }

    static func drawPaw(_ g: inout PixelGrid, _ pal: Colors, hip: (Int, Int), dx: Int, lift: Int) {
        limb(&g, hip, (hip.0 + dx, gy - 3 - lift), chars("BC", pal))
        put(&g, ["AB", "BBC"], hip.0 + dx, gy - 2 - lift, pal)
    }

    // MARK: - Jabalí

    static func drawBoar(_ g: inout PixelGrid, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        let p = pose.phase
        var bodyDx = 0, headDx = 0, headDy = 0
        var front = 0, rear = 0, lift = (0, 0)
        switch pose.action {
        case .walk, .idle: front = [1, 0, -1, 0][p]; rear = -front; lift = (p == 1 ? 1 : 0, p == 3 ? 1 : 0)
        case .windup: bodyDx = -1; headDy = 2; front = 2; rear = 2
        case .strike: bodyDx = 2; headDx = 1; headDy = -1; front = 3; rear = -2
        }
        let bob = pose.action == .walk ? [0, -1, 0, -1][p] : 0
        let bx = cx - 9 + bodyDx, by = gy - 12 + bob
        // Rabito rizado.
        put(&g, [".B", "B.", ".C"], bx - 2, by + 2 + (p % 2), pal)
        var far = PixelGrid(width: canvasW, height: canvasH)
        for (hip, d) in [(4, -rear), (12, -front)] {
            limb(&far, (bx + hip, by + 7), (bx + hip + d, gy - 2), chars("BC", pal))
            put(&far, ["jj"], bx + hip + d, gy - 1, pal)
        }
        blit(far, onto: &g, dim: 0.32)
        put(&g, [
            ".....IHIHI......",
            "...IJHIJIHIJ....",
            "..ABBIBBIBBBBC..",
            ".ABBBBBBBBBBBBC.",
            "ABBABBBBABBBBBBC",
            "BBBBBBBBBBBBBBBC",
            "BBBBBBBBBBBBBBC.",
            "CBBBBBBBBBBBBCC.",
            ".CCCCCCCCCCCC...",
        ], bx, by, pal)
        if s.look.contains("armor") {
            put(&g, ["...STTTTTTU...", "..STSTTSTTUV..", ".STTTTTTTTTUV.", ".VUVUVUVUVUVV."], bx + 1, by + 1, pal)
        }
        for (hip, d, l) in [(2, rear, lift.0), (10, front, lift.1)] {
            limb(&g, (bx + hip, by + 7), (bx + hip + d, gy - 2 - l), chars("BC", pal))
            put(&g, ["jj"], bx + hip + d, gy - 1 - l, pal)
        }
        let hx = bx + 12 + headDx, hy = by + 1 + headDy
        put(&g, [
            ".IJ......",
            "ABBC.....",
            "ABBBBB...",
            "BB*eBBB..",
            "BBeEBBBBp",
            "BBBBBBBpk",
            "CBBBBtBpp",
            ".CCCttCC.",
            "....t....",
        ], hx, hy, pal)
        if s.look.contains("armor") { put(&g, ["STTU..", "TTUUV.", ".VVV.."], hx, hy, pal) }
        if pose.action == .strike { put(&g, ["t", "t"], hx + 6, hy + 7, pal) }
    }

    // MARK: - Alas (pájaro y murciélago)

    /// Ala procedural: borde de ataque desde `root` y membrana o plumas colgando.
    /// `spread`: 0 arriba, 1 extendida, 2 abajo, 3 plegada hacia atrás.
    static func drawWing(_ g: inout PixelGrid, _ pal: Colors, root: (Int, Int), dir: Int, spread: Int, feathers: Bool) {
        let edge: [(Int, Int)]
        switch spread {
        case 0: edge = [(1, -1), (2, -2), (3, -3), (4, -4), (5, -5), (6, -5), (7, -6)]
        case 1: edge = [(1, 0), (2, -1), (3, -1), (4, -1), (5, -1), (6, -1), (7, 0), (8, 0)]
        case 2: edge = [(1, 0), (2, 1), (3, 2), (4, 3), (5, 3), (6, 4)]
        default: edge = [(-1, 0), (-2, 0), (-3, 1), (-4, 1), (-5, 1), (-6, 2)]
        }
        let n = edge.count
        for (i, e) in edge.enumerated() {
            let x = root.0 + e.0 * dir, y = root.1 + e.1
            let base = spread == 2 ? 2 : max(1, (n - i) * 2 / 3 + 1)
            let len = base + (feathers ? (i % 2) : (i % 2 == 0 ? 1 : 0))
            for k in 1...len {
                let ch: Character
                if feathers { ch = k == len ? "C" : (k == 1 ? "H" : "B") } else { ch = i % 2 == 0 && k < len ? "C" : (k == len ? "M" : "L") }
                g[x, y + k] = pal[ch]
            }
            g[x, y] = pal[feathers ? "A" : "B"]
        }
    }

    static func drawBird(_ g: inout PixelGrid, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        let p = pose.phase
        var dx = 0, dy = [0, 1, 2, 1][p], spread = [0, 1, 2, 1][p], open = false
        switch pose.action {
        case .walk, .idle: break
        case .windup: dx = -2; dy = -1; spread = 0; open = true
        case .strike: dx = 3; dy = 2; spread = 3; open = true
        }
        let bx = cx - 6 + dx, by = gy - 16 + dy
        var far = PixelGrid(width: canvasW, height: canvasH)
        drawWing(&far, pal, root: (bx + 6, by + 1), dir: spread == 3 ? 1 : -1, spread: spread, feathers: true)
        blit(far, onto: &g, dim: 0.35)
        put(&g, [
            "......ABB.",
            "....ABBBBC",
            "AABBBBBBBC",
            ".ABBHBBBBC",
            "AABHBBBBC.",
            "...CCCCC..",
        ], bx, by, pal)
        put(&g, ["z.z", "z.z"], bx + 4, by + 6, pal)
        put(&g, open ? [
            ".ABB...",
            "ABBBBQQR",
            "BB*eB...",
            "BBeEBQQR",
            ".BBBBC..",
            "..CC....",
        ] : [
            ".ABB...",
            "ABBBB..",
            "BB*eBQQ",
            "BBeEBPQR",
            ".BBBBC..",
            "..CC....",
        ], bx + 8, by - 2, pal)
        drawWing(&g, pal, root: (bx + 4, by + 2), dir: spread == 3 ? 1 : -1, spread: spread, feathers: true)
    }

    static func drawBat(_ g: inout PixelGrid, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        let p = pose.phase
        var dx = 0, dy = [0, 1, 2, 1][p], spread = [0, 1, 2, 1][p], open = false
        switch pose.action {
        case .walk, .idle: break
        case .windup: dx = -2; dy = -2; spread = 0; open = true
        case .strike: dx = 3; dy = 2; spread = 2; open = true
        }
        let bx = cx - 4 + dx, by = gy - 17 + dy
        let stone = s.look.contains("stone")
        drawWing(&g, pal, root: (bx, by + 3), dir: -1, spread: spread, feathers: false)
        drawWing(&g, pal, root: (bx + 7, by + 3), dir: 1, spread: spread, feathers: false)
        if s.look.contains("horns") { put(&g, ["t......t", "u......u", ".v....v."], bx, by - 3, pal) }
        put(&g, [
            "B......B",
            "BA....BC",
            "BBABBBBC",
            "ABBBBBBC",
            "B*eBB*eC",
            "BeEBBeEC",
            "BBBBBBBC",
            open ? ".BtrrtC." : ".BtBBtC.",
            ".CBBBBC.",
            "..CBBC..",
            "...CC...",
        ], bx, by, pal)
        if stone { put(&g, ["..D.....", ".....D..", "...C...."], bx, by + 2, pal) }
        put(&g, ["C..C", "D..D"], bx + 2, by + 11, pal)
        if stone {
            // Cola de piedra.
            put(&g, ["...C", "..C.", "BC..", "C..."], bx - 3, by + 9 + (p % 2), pal)
        }
    }

    // MARK: - Limo

    static func drawSlime(_ g: inout PixelGrid, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        let p = pose.phase
        var w: Int, h: Int, lift: Int, dx = 0, skew = 0
        switch pose.action {
        case .walk, .idle: (w, h, lift) = [(14, 11, 0), (16, 9, 0), (12, 13, 1), (13, 12, 3)][p]
        case .windup: (w, h, lift) = (18, 8, 0); dx = -2
        case .strike: (w, h, lift) = (12, 13, 2); dx = 4; skew = 3
        }
        if s.npc { (w, h, lift) = (14, 11, 0) }
        let left = cx - w / 2 + dx, bottom = gy - 1 - lift
        let top = bottom - h + 1
        let rx = Double(w) / 2, cyD = Double(top) + Double(h) * 0.62
        let cxD = Double(left) + rx
        let ryTop = Double(h) * 0.62, ryBot = Double(h) * 0.38 + 0.4
        for y in top...bottom {
            let shift = Int((Double(skew) * Double(bottom - y) / Double(max(1, h))).rounded())
            for x in left..<(left + w) {
                let nx = (Double(x) + 0.5 - cxD) / rx
                let ny = (Double(y) + 0.5 - cyD) / (Double(y) + 0.5 < cyD ? ryTop : ryBot)
                let d = nx * nx + ny * ny
                guard d <= 1.0 || (y == bottom && abs(nx) < 0.92) else { continue }
                let light = -nx * 0.55 - ny * 0.8
                var ch: Character = light > 0.45 ? "A" : (light > -0.1 ? "B" : (light > -0.5 ? "C" : "D"))
                if d > 0.82 && light < 0.2 { ch = ch == "B" ? "C" : "D" }
                if y == bottom { ch = "D" }
                g[x + shift, y] = pal[ch]
            }
        }
        // Brillo, burbujas y cara.
        let sx = (bottom - top) / 3
        put(&g, ["*A", "A."], left + w / 4, top + 2, pal)
        put(&g, ["A", ".", ".", "A"], left + 3 + (p % 2), bottom - 4, pal)
        let ex = Int(cxD) + 1 + Int((Double(skew) * 0.5).rounded())
        let ey = pose.action == .windup ? top + 2 : top + sx + 2
        if pose.action == .windup {
            put(&g, ["k...k", "kk.kk"], ex - 2, ey, pal)
        } else {
            put(&g, ["*E..*E", "EE..EE"], ex - 3, ey, pal)
        }
        if pose.action == .windup {
            put(&g, ["p.kkk.p"], ex - 3, ey + 2, pal)
        } else {
            put(&g, pose.action == .walk || pose.action == .idle ? ["p.kk.p"] : [".kkk", ".krk", "..k."], ex - 3, ey + 3, pal)
        }
        if s.look.contains("flames") {
            let fl = [[".5..6.", "656.65", "76767."], ["..5..6", ".656.6", ".7676."], ["5..6..", "65.656", "767.7."], [".6.5..", "6565.6", "7.7676"]][p]
            put(&g, fl, Int(cxD) - 3, top - 3, pal)
        }
        if s.look.contains("ice") {
            put(&g, ["..1...1.", ".12..12.", "1A2.1A2.", "........"], Int(cxD) - 4, top - 3, pal)
            put(&g, ["1.", ".2"], left + w - 4, bottom - 3, pal)
        }
    }

    // MARK: - Espectro

    static func drawGhost(_ g: inout PixelGrid, _ s: Spec, _ pal: Colors, _ pose: Pose) {
        let p = pose.phase
        // Manos (relativas al cuerpo): de reposo a los lados, alzadas al prepararse, delante al golpear.
        var dx = 0, armF = (12, 11), armB = (-2, 11), wail = false
        let float = [0, -1, -2, -1][p]
        switch pose.action {
        case .walk, .idle: break
        case .windup: dx = -2; armF = (13, 2); armB = (-3, 2); wail = true
        case .strike: dx = 3; armF = (15, 7); armB = (0, 9); wail = true
        }
        let bx = cx - 6 + dx, by = gy - 21 + float
        // Cola ondulante que se estrecha hacia atrás.
        for i in 0..<8 {
            let w = 13 - (i * 3) / 2
            let x0 = bx + (13 - w) / 2 - i / 2 + Int((1.2 * sin(Double(i) * 0.9 - Double(p) * .pi / 2)).rounded())
            for k in 0..<max(2, w) {
                if i == 7 && k % 2 == 1 { continue }
                let ch: Character = k == 0 ? "A" : (k >= w - 2 ? (k == w - 1 ? "D" : "C") : (i > 5 ? "C" : "B"))
                g[x0 + k, by + 10 + i] = pal[ch]
            }
        }
        // Brazo lejano, cuerpo, brazo cercano.
        var far = PixelGrid(width: canvasW, height: canvasH)
        let handB = (bx + armB.0, by + armB.1)
        limb(&far, (bx + 1, by + 10), handB, chars("BC", pal))
        put(&far, ["BB", "CD"], handB.0, handB.1, pal)
        blit(far, onto: &g, dim: 0.25)
        put(&g, [
            "....AAAAB....",
            "..AAAABBBBB..",
            ".AAABBBBBBBC.",
            ".AABBBBBBBBBC",
            "AABBBBkkBBkkC",
            "ABBBBBkeBBkeC",
            "ABBBBBkkBBkkC",
            "BBBBBBBBBBBBC",
            wail ? "BBBBBBBkkkBBC" : "BBBBBBBBkBBBC",
            wail ? "BBBBBBBkrkBBC" : "BBBBBBBBBBBBC",
            "BBBBBBBBBBBCC",
        ], bx, by, pal)
        var arm = PixelGrid(width: canvasW, height: canvasH)
        let hand = (bx + armF.0, by + armF.1)
        limb(&arm, (bx + 11, by + 10), hand, chars("AB", pal))
        put(&arm, ["ABB", "BBC", ".CD"], hand.0, hand.1, pal)
        if s.look.contains("chains") {
            // Grillete en la muñeca con una cadena que cuelga y se balancea.
            put(&arm, ["343"], hand.0, hand.1 + 2, pal)
            let sway = [0, 1, 0, -1][p]
            for i in 0..<4 { arm[hand.0 + 1 + (i * sway) / 2, hand.1 + 3 + i] = pal[i % 2 == 0 ? "2" : "4"] }
        }
        overlay(arm, onto: &g)
    }
}

extension PixelGrid {
    /// Rectángulo que contiene todos los pixeles opacos.
    var opaqueBounds: CGRect {
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where self[x, y] != nil {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX else { return CGRect(x: 0, y: 0, width: width, height: height) }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    func cropped(to rect: CGRect) -> PixelGrid {
        let ox = Int(rect.minX), oy = Int(rect.minY)
        var out = PixelGrid(width: Int(rect.width), height: Int(rect.height))
        for y in 0..<out.height {
            for x in 0..<out.width { out[x, y] = self[ox + x, oy + y] }
        }
        return out
    }

    /// Recorta los bordes transparentes.
    func trimmed() -> PixelGrid { cropped(to: opaqueBounds) }
}

extension Art {
    static func enemyTextures(_ id: String) -> [SKTexture] {
        (0..<EnemyArt.frameCount).map { frame in ArtCache.texture("enemy.\(id).\(frame)", grid: { EnemyArt.grid(for: id, frame: frame) }) }
    }

    static func npcImage(_ look: String) -> CGImage { enemyImage("npc.\(look)") }

    /// Frames de paso de un aldeano (en reposo: respiración suave).
    static func npcTextures(_ look: String) -> [SKTexture] {
        let all = enemyTextures("npc.\(look)")
        return EnemyArt.walkFrames.map { all[$0] }
    }

    static func enemyImage(_ id: String) -> CGImage {
        ArtCache.image("enemy.\(id).0", grid: { EnemyArt.grid(for: id, frame: 0) })
    }
}
