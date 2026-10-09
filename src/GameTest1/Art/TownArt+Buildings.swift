import Foundation
import GameCore

/// Casas del pueblo en vista 3/4: tejado a cuatro aguas (teja, pizarra o paja) con cumbrera, limas,
/// chimenea y buhardillas; fachada de entramado o de sillares sobre una base de piedra; ventanas con
/// postigos y jardineras; puerta con herrajes; cartel del oficio y objetos delante.
/// El castillo está en `TownArt+Castle.swift`.
extension TownArt {
    enum RoofKind { case tile, slate, thatch }
    enum WallKind { case timber, stone }

    /// Aspecto de cada edificio (paletas de 4-5 tonos de oscuro a claro).
    struct HouseLook {
        var roof: RoofKind
        var roofTones: [UInt32]
        var wall: WallKind
        var plaster: [UInt32]
        var shutter: UInt32?
        var frontGable: Bool
        var litWindows: Bool
    }

    static let beamTones: [UInt32] = [0x2E1C12, 0x4A2E1A, 0x684226, 0x885A34]
    static let stoneTones: [UInt32] = [0x5E5A64, 0x7A7682, 0x96929E, 0xB2AEBA, 0xCCC8D2]
    static let cream: [UInt32] = [0xB49E7A, 0xCDB894, 0xE0CEAA, 0xEEE0C0]
    static let moss: UInt32 = 0x667E36

    static func look(_ b: Building) -> HouseLook {
        let terracotta: [UInt32] = [0x5A2216, 0x80321E, 0xA44828, 0xC46236, 0xE08852]
        switch b.style {
        case .bakery:
            return HouseLook(roof: .tile, roofTones: terracotta, wall: .timber, plaster: cream, shutter: 0x3E7A4A, frontGable: false, litWindows: true)
        case .inn:
            return HouseLook(roof: .tile, roofTones: [0x46281A, 0x603820, 0x7C4E2C, 0x9A683A, 0xBA8A54], wall: .timber, plaster: cream, shutter: 0x8E2E2E, frontGable: true, litWindows: true)
        case .smithy:
            return HouseLook(roof: .slate, roofTones: [0x24262F, 0x353845, 0x4A4E5E, 0x646A7C, 0x868EA2], wall: .stone, plaster: cream, shutter: 0x4A4A56, frontGable: false, litWindows: true)
        case .chapel:
            return HouseLook(roof: .slate, roofTones: [0x1C2A52, 0x283C6E, 0x36528A, 0x4E70A8, 0x7898CA], wall: .stone, plaster: [0xB4B0BA, 0xCAC6D0, 0xDCD8E2, 0xEEEAF2], shutter: nil, frontGable: true, litWindows: false)
        case .mill:
            return HouseLook(roof: .thatch, roofTones: [0x5E4620, 0x80642C, 0xA2843C, 0xC0A250, 0xDCC272], wall: .timber, plaster: cream, shutter: 0x8A3A2A, frontGable: false, litWindows: false)
        case .alchemist:
            return HouseLook(roof: .slate, roofTones: [0x2A1A44, 0x3E2A62, 0x563E82, 0x725AA2, 0x9A82C6], wall: .timber, plaster: [0xA898B4, 0xC0B2CA, 0xD4C8DC, 0xE6DEEC], shutter: 0x4A6A3A, frontGable: false, litWindows: true)
        case .house, .castle, .ruinedMill, .burnedFarm, .abbeyChurch, .rangerHut, .watchtower:
            if b.id == "weaver" {
                return HouseLook(roof: .tile, roofTones: [0x5E401A, 0x845E24, 0xA88032, 0xC6A046, 0xE2C46C], wall: .timber, plaster: cream, shutter: 0x2E5A9A, frontGable: false, litWindows: false)
            }
            return HouseLook(roof: .tile, roofTones: [0x173E4A, 0x205A66, 0x2A7684, 0x3E98A4, 0x6CC0C8], wall: .timber, plaster: cream, shutter: 0x2E6A8A, frontGable: true, litWindows: true)
        }
    }

    static func building(_ b: Building, open: Bool) -> PixelGrid {
        if let art = fieldBuilding(b) { return art }           // edificios de campo (`FieldArt+Buildings.swift`)
        // Los estilos de campo sin arte propio todavía se dibujan con su estilo provisional (`placeholder`).
        let b = b.withPlaceholderStyle
        return b.style == .castle ? castle(b, open: open) : house(b)
    }

    // MARK: - Casa

    private static func house(_ b: Building) -> PixelGrid {
        let T = tile
        let W = b.width * T, H = b.height * T
        let M = b.style == .chapel ? 46 : 26         // margen de arriba: chimeneas y campanario
        var g = PixelGrid(width: W, height: H + M)
        let L = look(b)
        let seed = hash(b.x, b.y, 900)
        let base = H + M                             // línea del suelo
        let wallTop = base - 54
        let roofTop = M + 4
        let eave = wallTop + 6
        let doorC = (b.doorX - b.x) * T + b.doorWidth * T / 2

        // Fachada y base de piedra
        if L.wall == .stone {
            ashlarWall(&g, 3, wallTop, W - 6, base - wallTop, seed: seed, tones: b.style == .chapel ? [0x8A8692, 0xA4A0AC, 0xBAB6C2, 0xD2CED8] : stoneTones)
        } else {
            plasterWall(&g, 3, wallTop, W - 6, base - 8 - wallTop, tones: L.plaster, seed: seed)
            plinth(&g, 2, base - 8, W - 4, 8, seed: seed)
        }
        // Huecos de la fachada: ventanas repartidas sin pisar la puerta ni el cartel
        let winY = eave + 9
        var bays: [Int] = []
        let signSide = doorC < W / 2 ? 1 : -1
        var x = 12
        while x + 14 < W - 8 {
            let clearDoor = abs(x + 7 - doorC) > (b.style == .chapel ? 30 : 21)
            let clearSign = b.style == .chapel || !(signSide == 1 ? (x + 7 > doorC + 10 && x + 7 < doorC + 34) : (x + 7 < doorC - 10 && x + 7 > doorC - 34))
            if clearDoor && clearSign { bays.append(x) ; x += 32 } else { x += 6 }
        }
        if L.wall == .timber { timberFrame(&g, W: W, top: eave, bottom: base - 8, bays: bays, doorC: doorC, seed: seed) }
        for (i, bx) in bays.enumerated() {
            if b.style == .chapel {
                lancetWindow(&g, bx + 2, winY - 4)
            } else {
                window(&g, bx, winY, shutter: L.shutter, lit: L.litWindows && (hash(bx, seed, 3) % 3 != 0), flowers: hash(i, seed, 4) % 4 != 0 ? hash(i, seed, 5) : nil)
            }
        }
        // Puerta
        door(&g, doorC, base, width: b.style == .chapel || b.style == .inn ? 18 : 14, height: b.style == .chapel ? 28 : 24,
             wood: b.style == .chapel ? 0x7A4A28 : 0x6A4026, stoneFrame: true, double: b.style == .chapel || b.style == .inn)
        // Tejado, sombra del alero y remates
        let hip = min(26, (eave - roofTop) / 2)
        paintRoof(&g, x0: 0, x1: W, top: roofTop, bottom: eave, hip: hip, kind: L.roof, tones: L.roofTones, seed: seed)
        tintRect(&g, 3, eave, W - 6, 2, (0.62, 0.62, 0.74))
        tintRect(&g, 3, eave + 2, W - 6, 2, (0.82, 0.82, 0.9))
        if L.frontGable && b.style != .chapel {
            frontGable(&g, cx: doorC, halfW: 26, ridgeTop: roofTop + 2, apex: roofTop + 16, bottom: eave, look: L, seed: seed)
        }
        // Buhardillas
        if !L.frontGable && W >= 120 && L.roof != .thatch {
            let dx = doorC < W / 2 ? W - 44 : 30
            dormer(&g, dx, eave - 26, look: L, seed: seed)
        }
        // Chimenea (la forja, más grande)
        if b.style != .chapel {
            let cxh = doorC < W / 2 ? W - 30 : 22
            chimney(&g, cxh, roofTop + 14, height: b.style == .smithy ? 30 : 24, wide: b.style == .smithy || b.style == .bakery, seed: seed)
        }
        decorate(&g, b, W: W, base: base, eave: eave, wallTop: wallTop, roofTop: roofTop, doorC: doorC, signSide: signSide, look: L)
        return g.outlined()
    }

    // MARK: Tejado

    /// Tejado a cuatro aguas visto desde delante y arriba: faldón frontal, limas laterales (la izquierda
    /// iluminada, la derecha en sombra), cumbrera y alero. Tejas, pizarras o paja con musgo.
    static func paintRoof(_ g: inout PixelGrid, x0: Int, x1: Int, top: Int, bottom: Int, hip: Int, kind: RoofKind, tones: [UInt32], seed: Int) {
        let h = bottom - top, w = x1 - x0
        let rowH = kind == .thatch ? 7 : (kind == .slate ? 4 : 6)
        let colW = kind == .thatch ? 3 : (kind == .slate ? 5 : 5)
        let n = Double(tones.count)
        for y in top..<bottom {
            let t = Double(y - top) / Double(max(1, h))
            let inset = Int((Double(hip) * (1 - t)).rounded())
            let ry = y - top
            let row = ry / rowH, ly = ry % rowH
            for x in x0..<x1 {
                let fx = x - x0
                let side = fx < inset ? -1 : (x >= x1 - inset ? 1 : 0)
                let off = kind == .slate ? (row % 2) * 2 + hash(row, 7, seed) % 3 : 0
                let col = (fx + off) / colW, lx = (fx + off) % colW
                let th = hash(col, row, seed)
                var l = 0.64 - Double(fx) / Double(w) * 0.16 - t * 0.14
                switch kind {
                case .tile:
                    // Tejas curvas en canales verticales: lomo claro, canal oscuro y labio en cada hilada
                    l += Double(th % 4) * 0.03 - 0.045
                    l += [-0.26, 0.16, 0.1, -0.02, -0.14][lx]
                    if ly == rowH - 1 { l -= 0.22 } else if ly == rowH - 2 && lx >= 1 && lx <= 3 { l += 0.06 } else if ly == 0 { l -= 0.06 }
                case .slate:
                    l += Double(th % 5) * 0.035 - 0.07
                    if lx == 0 { l -= 0.24 }
                    if ly == rowH - 1 { l -= 0.32 } else if ly == 0 { l += 0.12 }
                    if th % 13 == 0 { l -= 0.12 }
                case .thatch:
                    // Haces de paja: hebras verticales y un labio redondeado en cada hilada
                    l += Double(hash(x, row, seed + 1) % 5 - 2) * 0.06
                    if hash(x, y / 2, seed + 2) % 4 == 0 { l -= 0.1 }
                    l += [0.1, 0.06, 0.02, 0, -0.04, -0.14, -0.3][ly]
                }
                if side == -1 { l += 0.2 } else if side == 1 { l -= 0.3 }
                l += (bayer(x, y) - 0.5) * 0.12
                var c = tones[max(0, min(tones.count - 1, Int(l * n)))]
                if kind != .slate {
                    let m = noise(Double(x) / 6, Double(y) / 4, seed + 3)
                    if m > 0.8 - t * 0.06 && hash(x, y, seed + 4) % 3 != 0 { c = mix(c, moss, ly == rowH - 1 ? 0.3 : 0.5) }
                }
                g[x, y] = c
            }
        }
        // Limas: arista clara a la izquierda y oscura a la derecha
        line(&g, x0 + hip, top, x0, bottom - 1, tones[4])
        line(&g, x0 + hip + 1, top, x0 + 1, bottom - 1, tones[3])
        line(&g, x1 - 1 - hip, top, x1 - 1, bottom - 1, tones[0])
        // Cumbrera: caballetes redondeados
        for x in (x0 + hip - 1)...(x1 - hip) {
            let k = (x - x0) % 7
            g[x, top - 2] = k == 0 ? tones[1] : tones[3]
            g[x, top - 1] = k == 0 ? tones[1] : (k < 3 ? tones[4] : tones[3])
            g[x, top] = k == 6 ? tones[0] : tones[2]
            g[x, top + 1] = tones[1]
        }
        // Alero: tabla de madera con las cabezas de las tejas (en la paja, un labio grueso redondeado)
        for x in x0..<x1 {
            if kind == .thatch {
                let wob = hash(x / 3, 0, seed) % 2
                g[x, bottom - 3] = tones[3]; g[x, bottom - 2] = tones[2]
                g[x, bottom - 1] = tones[1]; g[x, bottom] = wob == 0 ? tones[0] : tones[1]
                if wob == 0 { g[x, bottom + 1] = tones[0] }
            } else {
                g[x, bottom - 2] = (x - x0) % colW == 0 ? tones[0] : (kind == .tile ? tones[3] : tones[1])
                g[x, bottom - 1] = beamTones[1]
                g[x, bottom] = beamTones[0]
            }
        }
    }

    /// Hastial frontal que sobresale del tejado: dos vertientes que bajan desde la cumbrera (la
    /// izquierda al sol, la derecha en sombra) y, debajo, la cara triangular con entramado.
    private static func frontGable(_ g: inout PixelGrid, cx: Int, halfW: Int, ridgeTop: Int, apex: Int, bottom: Int, look L: HouseLook, seed: Int) {
        let h = bottom - apex
        // Sombra de la vertiente derecha sobre el tejado principal
        for y in ridgeTop..<bottom { tintRect(&g, cx + halfW + 6, y + 2, 4, 1, (0.6, 0.6, 0.72)) }
        let n = Double(L.roofTones.count)
        for y in ridgeTop...bottom {
            let ow = halfW + 5 - max(0, (apex - y)) * 3 / 10
            let iw = y < apex ? -1 : (y - apex) * halfW / max(1, h)
            for x in (cx - ow)...(cx + ow) {
                let ax = abs(x - cx)
                if ax <= iw {
                    // Cara del hastial: revoco con entramado
                    let nz = noise(Double(x) / 4, Double(y) / 4, seed + 8)
                    g[x, y] = tone(L.plaster, 0.72 - Double(x - cx) / Double(halfW) * 0.2 + (nz - 0.5) * 0.3, x, y)
                    continue
                }
                // Vertientes: hiladas paralelas al borde
                let along = y - ax / 2
                let row = (along - ridgeTop + 64) / 5, ly = (along - ridgeTop + 64) % 5
                let lx = (ax + row * 2) % 5
                var l = x < cx ? 0.78 : 0.3
                l -= Double(ax) / Double(ow) * 0.12
                if L.roof == .tile { l += [-0.24, 0.12, 0.08, -0.02, -0.12][lx] * 0.8 } else if lx == 0 { l -= 0.2 }
                if ly == 4 { l -= 0.22 } else if ly == 0 { l += 0.06 }
                l += Double(hash(row, ax / 5, seed) % 3) * 0.04 + (bayer(x, y) - 0.5) * 0.12
                g[x, y] = L.roofTones[max(0, min(L.roofTones.count - 1, Int(l * n)))]
            }
            // Bordes de la vertiente (canto exterior) y tablas de la cara
            g[cx - ow, y] = L.roofTones[4]; g[cx + ow, y] = L.roofTones[0]
            if iw >= 0 {
                g[cx - iw - 1, y] = beamTones[3]; g[cx - iw - 2, y] = beamTones[2]
                g[cx + iw + 1, y] = beamTones[1]; g[cx + iw + 2, y] = beamTones[0]
            }
        }
        // Cumbrera del hastial
        for y in ridgeTop..<apex { g[cx, y] = L.roofTones[4]; g[cx + 1, y] = L.roofTones[1] }
        // Entramado de la cara: pendolón, tirante, tornapuntas y ventanuco
        fill(&g, cx - 1, apex + 4, 3, h - 4, beamTones[1]); vline(&g, cx - 1, apex + 4, h - 4, beamTones[3])
        let tieY = apex + h * 2 / 3
        let tw = (tieY - apex) * halfW / max(1, h)
        fill(&g, cx - tw, tieY, tw * 2 + 1, 3, beamTones[1]); hline(&g, cx - tw, tieY, tw * 2 + 1, beamTones[3]); hline(&g, cx - tw, tieY + 2, tw * 2 + 1, beamTones[0])
        for s in [-1, 1] {
            line(&g, cx + s * 2, tieY + 3, cx + s * (halfW - 4), bottom - 1, beamTones[1])
            line(&g, cx + s * 3, tieY + 3, cx + s * (halfW - 3), bottom - 1, s < 0 ? beamTones[2] : beamTones[0])
        }
        let wy = apex + (tieY - apex) / 2 + 2
        fill(&g, cx - 5, wy - 4, 11, 9, beamTones[0])
        for yy in (wy - 3)..<(wy + 4) { for xx in (cx - 4)...(cx + 4) {
            g[xx, yy] = L.litWindows ? tone([0xFFF2C0, 0xFFD878, 0xF2A848], Double(xx - cx + 4 + yy - wy + 3) / 14, xx, yy) : tone([0x9ACBEA, 0x4E80B0, 0x34587E], Double(xx - cx + 4 + yy - wy + 3) / 12, xx, yy)
        } }
        vline(&g, cx, wy - 3, 7, beamTones[0]); hline(&g, cx - 4, wy, 9, beamTones[0])
        fill(&g, cx - 6, wy + 4, 13, 2, stoneTones[3])
        // Remate del vértice
        fill(&g, cx - 1, ridgeTop - 5, 3, 5, beamTones[2]); g[cx - 1, ridgeTop - 5] = beamTones[3]; g[cx, ridgeTop - 6] = beamTones[3]
    }

    private static func dormer(_ g: inout PixelGrid, _ x: Int, _ y: Int, look L: HouseLook, seed: Int) {
        // Sombra sobre el tejado
        tintRect(&g, x + 16, y + 6, 4, 16, (0.6, 0.6, 0.72))
        // Frente
        plasterWall(&g, x + 1, y + 8, 14, 14, tones: L.plaster, seed: seed + 5)
        vline(&g, x + 1, y + 8, 14, beamTones[1]); vline(&g, x + 14, y + 8, 14, beamTones[0])
        window(&g, x + 3, y + 10, shutter: nil, lit: L.litWindows, flowers: nil, small: true)
        // Tejadillo a dos aguas
        for i in 0..<10 {
            let yy = y + i
            for xx in (x + 7 - i - 1)...(x + 8 + i) {
                let left = xx <= x + 7
                g[xx, yy] = tone(L.roofTones, left ? 0.78 - Double(i % 3) * 0.1 : 0.32 - Double(i % 3) * 0.08, xx, yy)
            }
            g[x + 7 - i - 1, yy] = beamTones[3]; g[x + 8 + i, yy] = beamTones[0]
        }
        hline(&g, x - 3, y + 10, 22, beamTones[0])
    }

    static func chimney(_ g: inout PixelGrid, _ x: Int, _ bottom: Int, height: Int, wide: Bool, seed: Int) {
        let w = wide ? 12 : 9
        let top = bottom - height
        for y in top..<bottom {
            for xx in x..<(x + w) {
                let row = (y - top) / 3, ly = (y - top) % 3
                let lx = (xx - x + (row % 2) * 3) % 6
                var c: UInt32 = [0x8E4A36, 0x9E5640, 0xA8604A][hash((xx - x + (row % 2) * 3) / 6, row, seed) % 3]
                if ly == 2 || lx == 0 { c = 0x6A3628 }
                if xx == x { c = light(c, 1.1) } else if xx >= x + w - 2 { c = dark(c, 0.72) }
                g[xx, y] = c
            }
        }
        // Remate de piedra y boca negra con hollín
        fill(&g, x - 1, top - 3, w + 2, 3, 0xA4A0AC)
        hline(&g, x - 1, top - 3, w + 2, 0xCCC8D2)
        hline(&g, x - 1, top - 1, w + 2, 0x6E6A76)
        fill(&g, x + 1, top - 4, w - 2, 1, 0x1E1A1E)
        g[x + 2, top - 5] = 0x3A3438; g[x + w - 3, top - 5] = 0x3A3438
        // Sombra en el tejado
        tintRect(&g, x + w, top + 4, 3, height - 4, (0.62, 0.62, 0.74))
    }

    // MARK: Fachada

    static func plasterWall(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, tones: [UInt32], seed: Int) {
        for yy in y..<(y + h) {
            for xx in x..<(x + w) {
                let n = noise(Double(xx) / 5, Double(yy) / 4, seed + 1) * 0.6 + noise(Double(xx) / 2, Double(yy) / 2, seed + 2) * 0.4
                var l = 0.72 - Double(xx - x) / Double(max(1, w)) * 0.22 + (n - 0.5) * 0.35
                if yy > y + h - 5 { l -= 0.12 }                               // salpicaduras de barro
                g[xx, yy] = tone(tones, l, xx, yy, dither: 0.25)
                if hash(xx, yy, seed + 9) % 61 == 0 { g[xx, yy] = tones[0] }  // desconchones
            }
        }
    }

    static func timberFrame(_ g: inout PixelGrid, W: Int, top: Int, bottom: Int, bays: [Int], doorC: Int, seed: Int) {
        func post(_ x: Int, _ y0: Int, _ y1: Int) {
            fill(&g, x, y0, 4, y1 - y0, beamTones[1])
            vline(&g, x, y0, y1 - y0, beamTones[3])
            vline(&g, x + 3, y0, y1 - y0, beamTones[0])
            for yy in stride(from: y0 + 3, to: y1, by: 7) where hash(x, yy, seed) % 2 == 0 { g[x + 1, yy] = beamTones[2]; g[x + 2, yy + 1] = beamTones[0] }
        }
        func beam(_ x0: Int, _ x1: Int, _ y: Int) {
            fill(&g, x0, y, x1 - x0, 3, beamTones[1])
            hline(&g, x0, y, x1 - x0, beamTones[3])
            hline(&g, x0, y + 2, x1 - x0, beamTones[0])
        }
        beam(3, W - 3, top - 1)
        beam(3, W - 3, bottom - 3)
        post(3, top, bottom)
        post(W - 7, top, bottom)
        // Postes entre vanos y riostras en aspa donde no hay ventana
        var cols: [Int] = [doorC - 13, doorC + 9]
        for bx in bays { cols.append(bx - 6); cols.append(bx + 16) }
        cols = cols.filter { $0 > 8 && $0 < W - 12 }.sorted()
        var last = 7
        for c in cols where c - last >= 5 {
            post(c, top + 2, bottom - 3)
            let gap = c - last
            func brace(_ a: Int, _ b: Int) {
                line(&g, a + 1, bottom - 4, b - 1, top + 2, beamTones[1]); line(&g, a + 2, bottom - 4, b, top + 2, beamTones[2])
                line(&g, a + 1, top + 2, b - 1, bottom - 4, beamTones[1]); line(&g, a + 2, top + 2, b, bottom - 4, beamTones[0])
            }
            if gap > 16 && !bays.contains(where: { $0 > last && $0 < c }) && !(doorC > last && doorC < c) {
                if gap > 30 {
                    let mid = (last + c) / 2 - 2
                    post(mid, top + 2, bottom - 3)
                    brace(last, mid); brace(mid + 4, c)
                } else {
                    brace(last, c)
                }
            }
            last = c + 4
        }
    }

    /// Base de piedra irregular con sillares redondeados.
    static func plinth(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, seed: Int) {
        for yy in y..<(y + h) {
            for xx in x..<(x + w) {
                let row = (yy - y) / 4, ly = (yy - y) % 4
                let off = row * 5 + hash(row, 0, seed) % 4
                let lx = (xx + off) % 9
                let st = hash((xx + off) / 9, row, seed + 1)
                var c = stoneTones[1 + st % 3]
                if ly == 3 || lx == 0 { c = stoneTones[0] } else if ly == 0 { c = light(c, 1.08) } else if lx == 8 { c = dark(c, 0.88) }
                if xx > x + w - 4 { c = dark(c, 0.86) }
                if ly == 2 && hash(xx, yy, seed) % 9 == 0 { c = moss }
                g[xx, yy] = c
            }
        }
        hline(&g, x, y, w, stoneTones[4])
    }

    static func ashlarColor(_ x: Int, _ y: Int, tones: [UInt32], seed: Int) -> UInt32 {
        let row = y / 6, ly = y % 6
        let rw = 10 + hash(row, 1, seed) % 5
        let off = (row * 7) % rw
        let lx = (x + off) % rw
        let h = hash((x + off) / rw, row, seed + 2)
        var c = tones[h % 3 + 1]
        if ly == 5 || lx == 0 { return tones[0] }
        if ly == 0 { c = light(c, 1.07) } else if lx == rw - 1 || ly == 4 { c = dark(c, 0.9) }
        if h % 7 == 0 && ly == 2 && lx > 2 && lx < rw - 3 { c = dark(c, 0.9) }
        return c
    }

    private static func ashlarWall(_ g: inout PixelGrid, _ x: Int, _ y: Int, _ w: Int, _ h: Int, seed: Int, tones: [UInt32]) {
        for yy in y..<(y + h) {
            for xx in x..<(x + w) {
                var c = ashlarColor(xx, yy, tones: tones, seed: seed)
                if xx > x + w - 6 { c = dark(c, 0.88) }
                if yy > y + h - 6 && noise(Double(xx) / 3, Double(yy) / 2, seed + 5) > 0.62 { c = mix(c, moss, 0.6) }
                g[xx, yy] = c
            }
        }
    }

    // MARK: Ventanas y puertas

    /// Ventana de 14×14 con marco, cruceta, postigos, dintel, alféizar y jardinera.
    static func window(_ g: inout PixelGrid, _ x: Int, _ y: Int, shutter: UInt32?, lit: Bool, flowers: Int?, small: Bool = false) {
        let w = small ? 10 : 14, h = small ? 10 : 14
        // Postigos abiertos a los lados
        if let s = shutter, !small {
            for sx in [x - 6, x + w + 1] {
                fill(&g, sx, y, 5, h, s)
                vline(&g, sx, y, h, light(s, 1.18))
                vline(&g, sx + 4, y, h, dark(s, 0.7))
                for yy in [y + 3, y + 9] { hline(&g, sx + 1, yy, 3, dark(s, 0.78)) }
                g[sx + 2, y + 1] = 0x2A2A30; g[sx + 2, y + h - 2] = 0x2A2A30
            }
        }
        // Marco y dintel
        fill(&g, x - 1, y - 1, w + 2, h + 2, beamTones[0])
        fill(&g, x - 2, y - 3, w + 4, 2, stoneTones[3]); hline(&g, x - 2, y - 3, w + 4, stoneTones[4])
        // Cristal
        for yy in y..<(y + h) {
            for xx in x..<(x + w) {
                let t = Double((xx - x) + (yy - y)) / Double(w + h)
                var c: UInt32
                if lit {
                    c = tone([0xFFF2C0, 0xFFD878, 0xF2A848, 0xC87A30], t * 1.1, xx, yy)
                } else {
                    c = tone([0x9ACBEA, 0x4E80B0, 0x34587E, 0x243E5C], t * 1.2 + 0.15, xx, yy)
                    if (xx - x) - (yy - y) == 2 || (xx - x) - (yy - y) == 3 { c = 0xA8D4F0 }
                }
                g[xx, yy] = c
            }
        }
        if lit && !small {
            // Cortinas recogidas
            for yy in y..<(y + h) { g[x, yy] = 0xB84A3A; if yy < y + 6 { g[x + 1, yy] = 0xB84A3A }; g[x + w - 1, yy] = 0x983A2E }
        }
        // Cruceta
        vline(&g, x + w / 2 - 1, y, h, beamTones[1]); hline(&g, x, y + h / 2 - 1, w, beamTones[1])
        vline(&g, x + w / 2, y, h, beamTones[0])
        // Alféizar
        fill(&g, x - 2, y + h + 1, w + 4, 2, stoneTones[3]); hline(&g, x - 2, y + h + 2, w + 4, stoneTones[1])
        if let f = flowers {
            // Jardinera con flores y hojas que cuelgan
            fill(&g, x - 1, y + h + 3, w + 2, 4, 0x7A4A28); hline(&g, x - 1, y + h + 3, w + 2, 0xA06838); hline(&g, x - 1, y + h + 6, w + 2, 0x4A2A16)
            let petals: [UInt32] = [[0xE8483C, 0xF4F0E8, 0xF6C83A, 0xE87AB0][f % 4], [0xF6C83A, 0xE87AB0, 0xF4F0E8, 0x8AB4F0][(f >> 3) % 4]]
            for i in 0..<(w + 2) {
                let px = x - 1 + i
                g[px, y + h] = i % 2 == 0 ? 0x3E7A36 : 0x5A9A44
                if i % 3 == 1 { g[px, y + h - 1] = petals[i % 2]; g[px, y + h - 2] = light(petals[i % 2], 1.15) }
                if hash(px, f, 2) % 3 == 0 { g[px, y + h + 7] = 0x3E7A36 }
            }
        }
    }

    /// Ventana alta de capilla, en arco apuntado con vidriera.
    static func lancetWindow(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        let w = 10, h = 20
        for yy in 0..<h {
            for xx in 0..<w {
                let inArch = yy >= 5 || abs(Double(xx) - 4.5) <= Double(yy) + 0.5
                guard inArch else { continue }
                let edge = xx == 0 || xx == w - 1 || yy == h - 1 || (yy < 5 && abs(Double(xx) - 4.5) > Double(yy) - 0.5)
                let glass: [UInt32] = [0x3E7AD8, 0xD8483C, 0xF2C440, 0x4EB060]
                var c = edge ? 0x4A4656 : glass[((xx / 3) + (yy / 4)) % 4]
                if !edge && (xx == 4 || xx == 5) { c = 0x4A4656 }
                if !edge && (xx + yy) % 5 == 0 { c = light(c, 1.25) }
                g[x + xx, y + yy] = c
            }
        }
        fill(&g, x - 1, y + h, w + 2, 2, 0xD2CED8)
    }

    /// Puerta de tablones con marco de piedra en arco, herrajes, aldaba y escalón.
    static func door(_ g: inout PixelGrid, _ cx: Int, _ base: Int, width w: Int, height h: Int, wood: UInt32, stoneFrame: Bool, double: Bool) {
        let x = cx - w / 2, top = base - h - 2
        let r = w / 2
        // Marco de dovelas
        if stoneFrame {
            for yy in (top - 3)..<(base - 2) {
                for xx in (x - 3)..<(x + w + 3) {
                    let dy = Double(yy - (top + r)), dx = Double(xx) - (Double(cx) - 0.5)
                    let outer = yy >= top + r || dx * dx + dy * dy <= Double((r + 3) * (r + 3))
                    guard outer else { continue }
                    let seg = yy >= top + r ? (yy - top) / 5 : Int((atan2(dy, dx) + Double.pi) * 3)
                    var c = stoneTones[2 + seg % 2]
                    if xx < cx { c = light(c, 1.06) } else { c = dark(c, 0.92) }
                    if (yy - top) % 5 == 0 && yy >= top + r { c = stoneTones[0] }
                    g[xx, yy] = c
                }
            }
        }
        // Hoja(s) de la puerta
        for yy in top..<(base - 2) {
            for xx in x..<(x + w) {
                let dy = Double(yy - (top + r)), dx = Double(xx) - (Double(cx) - 0.5)
                guard yy >= top + r || dx * dx + dy * dy <= Double(r * r) else { continue }
                let plank = (xx - x) % 4
                var c = wood
                if plank == 0 { c = dark(wood, 0.62) } else if plank == 1 { c = light(wood, 1.12) } else if plank == 3 { c = dark(wood, 0.86) }
                if hash(xx, yy / 3, 41) % 9 == 0 { c = dark(c, 0.9) }
                g[xx, yy] = c
            }
        }
        if double { vline(&g, cx - 1, top + 1, h + 1, 0x24160E); vline(&g, cx, top + 1, h + 1, dark(wood, 0.75)) }
        // Bisagras de hierro con clavos
        for hy in [top + r + 2, base - 9] {
            hline(&g, x, hy, w, 0x2C2C36); hline(&g, x, hy + 1, w, 0x4A4A58)
            for xx in stride(from: x + 1, to: x + w, by: 3) { g[xx, hy] = 0x8A8A9A }
        }
        // Aldaba y ventanuco enrejado
        let kx = double ? cx + 2 : x + w - 4
        g[kx, base - 14] = 0xE8B83A; g[kx + 1, base - 14] = 0xB08020; g[kx, base - 13] = 0xB08020; g[kx + 1, base - 12] = 0xE8B83A
        if !double {
            fill(&g, cx - 2, top + 3, 4, 3, 0x1E1410); g[cx - 1, top + 4] = 0x6A6A78; g[cx, top + 4] = 0x6A6A78
        }
        // Escalón de piedra
        fill(&g, x - 4, base - 2, w + 8, 2, stoneTones[3])
        hline(&g, x - 4, base - 2, w + 8, stoneTones[4])
        hline(&g, x - 4, base - 1, w + 8, stoneTones[1])
    }

    // MARK: Carteles y objetos

    /// Cartel colgado de un brazo de hierro con el dibujo del oficio.
    static func hangingSign(_ g: inout PixelGrid, wallX: Int, y: Int, dir: Int, icon: (inout PixelGrid, Int, Int) -> Void) {
        let armEnd = wallX + dir * 18
        let x0 = min(wallX, armEnd), x1 = max(wallX, armEnd)
        hline(&g, x0, y, x1 - x0 + 1, 0x2C2C36)
        line(&g, wallX, y + 5, wallX + dir * 6, y, 0x2C2C36)
        g[wallX, y - 1] = 0x4A4A58; g[armEnd, y - 1] = 0x4A4A58
        let bx = min(wallX + dir * 4, armEnd) + (dir > 0 ? 1 : 1)
        let sx = dir > 0 ? bx : armEnd
        // Cadenas
        vline(&g, sx + 2, y + 1, 2, 0x6A6A78); vline(&g, sx + 13, y + 1, 2, 0x6A6A78)
        // Tablero
        fill(&g, sx, y + 3, 16, 13, 0x3A2416)
        fill(&g, sx + 1, y + 4, 14, 11, 0xB88A54)
        hline(&g, sx + 1, y + 4, 14, 0xD8AA70)
        vline(&g, sx + 14, y + 4, 11, 0x8A6236)
        hline(&g, sx + 1, y + 14, 14, 0x8A6236)
        icon(&g, sx + 3, y + 6)
    }

    private static func decorate(_ g: inout PixelGrid, _ b: Building, W: Int, base: Int, eave: Int, wallTop: Int, roofTop: Int, doorC: Int, signSide: Int, look L: HouseLook) {
        let signWall = doorC + signSide * 12
        let signY = eave + 6
        switch b.style {
        case .bakery:
            hangingSign(&g, wallX: signWall, y: signY, dir: signSide) { g, x, y in
                ellipse(&g, x + 5, y + 4, 5, 3, 0x7A3E14); ellipse(&g, x + 5, y + 3, 5, 3, 0xD08A40)
                hline(&g, x + 2, y + 2, 3, 0xF4CC88); g[x + 4, y + 3] = 0x9A5A26; g[x + 7, y + 3] = 0x9A5A26
            }
            // Toldo a rayas sobre la ventana del lado del cartel y sacos de harina
            awning(&g, x: doorC - signSide * 34 - 11, y: eave + 4, w: 24, a: 0xF0E6D0, b: 0xC8463C)
            sack(&g, doorC + signSide * 14 - 5, base - 12, flour: true)
            crate(&g, doorC - signSide * 14 - (signSide > 0 ? 12 : 0), base - 13)
        case .inn:
            hangingSign(&g, wallX: signWall, y: signY, dir: signSide) { g, x, y in
                // Jarra de cerveza con espuma
                fill(&g, x + 2, y + 2, 6, 6, 0xE8A830); fill(&g, x + 2, y + 1, 6, 2, 0xFFFFFF)
                vline(&g, x + 8, y + 3, 4, 0x8A6236); g[x + 9, y + 3] = 0x8A6236; g[x + 9, y + 6] = 0x8A6236
                vline(&g, x + 3, y + 3, 4, 0xFFD870)
            }
            barrel(&g, doorC - signSide * 16 - 6, base - 18)
            barrel(&g, doorC - signSide * 28 - 6, base - 18)
        case .smithy:
            hangingSign(&g, wallX: signWall, y: signY, dir: signSide) { g, x, y in
                // Yunque y martillo
                fill(&g, x + 1, y + 3, 8, 2, 0x4A4A58); fill(&g, x + 3, y + 5, 4, 2, 0x3A3A46); fill(&g, x + 2, y + 7, 6, 1, 0x3A3A46)
                hline(&g, x + 1, y + 3, 8, 0x8A8A9A); line(&g, x + 6, y, x + 9, y + 2, 0x6A4026); fill(&g, x + 4, y - 1, 3, 2, 0x5A5A68)
            }
            // Fragua abierta con brasas, yunque y armas apoyadas
            let fx = doorC - signSide * 30 - 10
            fill(&g, fx, base - 26, 20, 18, 0x2A1A14)
            for yy in (base - 16)..<(base - 8) { for xx in (fx + 2)..<(fx + 18) { g[xx, yy] = tone([0x8A1E0E, 0xD8401A, 0xF89A30, 0xFFE070], Double(base - 8 - yy) / 10 + (bayer(xx, yy) - 0.5) * 0.4 - Double(abs(xx - fx - 10)) / 20, xx, yy) } }
            hline(&g, fx, base - 27, 20, stoneTones[3])
            anvil(&g, doorC + signSide * 22 - 6, base - 10)
        case .alchemist:
            hangingSign(&g, wallX: signWall, y: signY, dir: signSide) { g, x, y in
                ellipse(&g, x + 5, y + 5, 4, 3, 0x7A3ACA); ellipse(&g, x + 4, y + 4, 2, 1, 0xC898F2)
                fill(&g, x + 4, y, 3, 3, 0xE8F0F2); g[x + 4, y] = 0xFFFFFF
            }
            // Hierbas secándose y macetas con plantas raras
            for i in 0..<5 { let hx = 10 + i * 5; vline(&g, hx, eave + 2, 4 + i % 2 * 2, [0x4E8A3A, 0x7AA048, 0x9A6AB0][i % 3]) }
            pot(&g, doorC - 16, base - 9, plant: 0x6A3A9A)
            pot(&g, doorC + 11, base - 9, plant: 0x3E8A5A)
        case .mill:
            hangingSign(&g, wallX: signWall, y: signY, dir: signSide) { g, x, y in
                // Saco de trigo con espigas
                ellipse(&g, x + 5, y + 5, 4, 3, 0xE6DCC6); hline(&g, x + 3, y + 2, 5, 0x8A6A3A)
                for i in 0..<3 { vline(&g, x + 3 + i * 2, y - 1, 3, 0xE8C040) }
            }
            // Rueda de molino de agua en el lado contrario a la puerta
            let wx = doorC < W / 2 ? W - 22 : 22
            waterWheel(&g, wx, base - 21)
            sack(&g, doorC + signSide * 14 - 5, base - 12, flour: true)
            sack(&g, doorC + signSide * 24 - 5, base - 11, flour: false)
        case .chapel:
            chapelTower(&g, doorC, base: base, top: roofTop - 8, eave: eave, look: L)
            pot(&g, doorC - 26, base - 9, plant: 0x3E8A5A)
            pot(&g, doorC + 21, base - 9, plant: 0xE87AB0)
        case .house, .castle, .ruinedMill, .burnedFarm, .abbeyChurch, .rangerHut, .watchtower:
            if b.id == "weaver" {
                hangingSign(&g, wallX: signWall, y: signY, dir: signSide) { g, x, y in
                    // Ovillo y aguja
                    ellipse(&g, x + 4, y + 5, 3, 3, 0xD84A6A); line(&g, x + 2, y + 3, x + 6, y + 7, 0xF08AA8); line(&g, x + 2, y + 6, x + 5, y + 3, 0xA02A4A)
                    line(&g, x + 8, y + 1, x + 9, y + 8, 0xC8C8D2)
                }
                // Tendedero con telas de colores
                let lx0 = doorC - signSide * 36 - 14
                hline(&g, lx0, eave + 5, 28, 0x5A3A22)
                for (i, c) in [0xD84A6A, 0x3E7AD8, 0xF2C440, 0x4EB060].enumerated() {
                    let cc = UInt32(c)
                    fill(&g, lx0 + 1 + i * 7, eave + 6, 5, 8 + i % 2 * 3, cc)
                    vline(&g, lx0 + 1 + i * 7, eave + 6, 8 + i % 2 * 3, light(cc, 1.2))
                    hline(&g, lx0 + 1 + i * 7, eave + 9, 5, dark(cc, 0.8))
                }
            } else {
                // Casa del alcalde: escudo y banderín
                hangingSign(&g, wallX: signWall, y: signY, dir: signSide) { g, x, y in
                    fill(&g, x + 2, y, 7, 6, 0x2E5AA8); fill(&g, x + 3, y + 6, 5, 2, 0x2E5AA8); g[x + 5, y + 8] = 0x2E5AA8
                    fill(&g, x + 4, y + 2, 3, 3, 0xE8B83A)
                }
                pot(&g, doorC - 16, base - 9, plant: 0x3E8A5A)
                pot(&g, doorC + 11, base - 9, plant: 0xD84A6A)
            }
        }
    }

    /// Torre-campanario de la capilla, delante del tejado: puerta doble, rosetón, campana y aguja.
    private static func chapelTower(_ g: inout PixelGrid, _ cx: Int, base: Int, top: Int, eave: Int, look L: HouseLook) {
        let hw = 16
        let tones: [UInt32] = [0x7E7A88, 0x9C98A6, 0xB4B0BE, 0xCCC8D6]
        // Sombra de la torre sobre el tejado
        tintRect(&g, cx + hw, top + 6, 5, eave - top, (0.6, 0.6, 0.72))
        for y in top..<base {
            for x in (cx - hw)..<(cx + hw) {
                var c = ashlarColor(x, y, tones: tones, seed: 55)
                if x < cx - hw + 3 { c = light(c, 1.06) } else if x > cx + hw - 5 { c = dark(c, 0.84) }
                g[x, y] = c
            }
        }
        // Contrafuertes en las esquinas
        for x in [cx - hw - 3, cx + hw] {
            for y in (eave + 4)..<base { for k in 0..<3 { g[x + k, y] = x < cx ? (k == 0 ? tones[3] : tones[2]) : (k == 2 ? tones[0] : tones[1]) } }
            for k in 0..<3 { g[x + k, eave + 3] = tones[3]; g[x + k, eave + 2] = 0x5A5664 }
        }
        // Cornisa y campanario
        fill(&g, cx - hw - 2, top, hw * 2 + 4, 3, tones[3]); hline(&g, cx - hw - 2, top + 3, hw * 2 + 4, tones[0])
        let by = top + 6
        for y in by..<(by + 18) {
            for x in (cx - 7)...(cx + 6) {
                let dx = Double(x - cx) + 0.5, dy = Double(y - (by + 7))
                guard y >= by + 7 || dx * dx + dy * dy <= 49 else { continue }
                g[x, y] = 0x1E1A24
            }
        }
        ball(&g, cx, by + 11, 4, 4, [0x7A5418, 0xB0802A, 0xE0B040, 0xFFE07A])
        fill(&g, cx - 5, by + 15, 10, 1, 0xB0802A)
        g[cx, by + 16] = 0x7A5418
        hline(&g, cx - 8, by + 18, 16, tones[3])
        // Rosetón con vidriera
        let ry = eave + 4
        ellipse(&g, cx, ry, 9, 9, 0x4A4656)
        let glass: [UInt32] = [0xD8483C, 0x3E7AD8, 0xF2C440, 0x4EB060, 0x9A58C8, 0x3E7AD8, 0xF2C440, 0x4EB060]
        for y in -7...7 {
            for x in -7...7 where x * x + y * y <= 52 {
                let a = (atan2(Double(y), Double(x)) + Double.pi) / (2 * Double.pi) * 8
                var c = glass[Int(a) % 8]
                if x * x + y * y <= 5 { c = 0xF6E6A0 }
                if Int(a * 10) % 10 == 0 || (x * x + y * y > 30 && x * x + y * y < 37) { c = 0x4A4656 }
                g[cx + x, ry + y] = (x + y) < -4 ? light(c, 1.15) : c
            }
        }
        // Aguja de pizarra con cruz dorada
        let sh = 30
        for i in 0..<sh {
            let w = (i * (hw + 2)) / sh
            for x in (cx - w)...(cx + w) {
                let row = i / 3
                var l = x < cx ? 0.75 : 0.3
                if i % 3 == 2 { l -= 0.15 }
                if (x + row) % 4 == 0 { l -= 0.08 }
                g[x, top - sh + i] = tone(L.roofTones, l, x, top - sh + i)
            }
        }
        vline(&g, cx, top - sh - 9, 9, 0xE8C048); hline(&g, cx - 3, top - sh - 6, 7, 0xE8C048); g[cx - 1, top - sh - 9] = 0xFFF0A0
        // Puerta doble de la capilla (encima de la torre)
        door(&g, cx, base, width: 20, height: 30, wood: 0x7A4A28, stoneFrame: true, double: true)
    }

    private static func awning(_ g: inout PixelGrid, x: Int, y: Int, w: Int, a: UInt32, b: UInt32) {
        for yy in 0..<8 {
            for xx in 0..<w {
                var c = (xx / 4) % 2 == 0 ? a : b
                if yy < 2 { c = light(c, 1.05) } else if yy > 5 { c = dark(c, 0.85) }
                g[x + xx, y + yy] = c
            }
        }
        for xx in 0..<w where xx % 4 != 3 { g[x + xx, y + 8] = dark((xx / 4) % 2 == 0 ? a : b, 0.8) }
        hline(&g, x, y - 1, w, beamTones[0])
    }

    static func pot(_ g: inout PixelGrid, _ x: Int, _ y: Int, plant: UInt32) {
        fill(&g, x, y + 3, 7, 6, 0xB0603A)
        hline(&g, x - 1, y + 3, 9, 0xD0804A); hline(&g, x, y + 8, 7, 0x7A3A22)
        vline(&g, x + 5, y + 4, 4, 0x8A4A2A)
        ball(&g, x + 3, y, 4, 3, [0x1E5030, 0x2E7038, 0x4A9A44, 0x7ACA5A])
        g[x + 1, y - 1] = plant; g[x + 4, y - 2] = plant; g[x + 5, y] = plant
    }

    private static func anvil(_ g: inout PixelGrid, _ x: Int, _ y: Int) {
        fill(&g, x, y, 12, 3, 0x4A4A58); hline(&g, x, y, 12, 0x9A9AAA); fill(&g, x - 2, y + 1, 2, 1, 0x4A4A58)
        fill(&g, x + 3, y + 3, 6, 3, 0x3A3A46); fill(&g, x + 1, y + 6, 10, 3, 0x6A4026); hline(&g, x + 1, y + 6, 10, 0x8A5A34)
    }

    /// Rueda de molino vista de frente: llanta, radios, palas y el agua que cae.
    static func waterWheel(_ g: inout PixelGrid, _ cx: Int, _ cy: Int) {
        let r = 15
        for y in -r - 2...r + 2 {
            for x in -r - 2...r + 2 {
                let d = Double(x * x + y * y).squareRoot()
                guard d <= Double(r) + 2.5 else { continue }
                let a = atan2(Double(y), Double(x))
                let lit = (x + y) < 0
                if d > Double(r) - 0.5 {
                    if Int((a + Double.pi) / (Double.pi / 6) * 4) % 4 == 0 { g[cx + x, cy + y] = lit ? 0x9A6A3A : 0x5A3A22 }
                } else if d > Double(r) - 3 {
                    g[cx + x, cy + y] = lit ? 0x8A5A30 : 0x5E3C20
                } else if abs(sin(a * 3)) < 0.18 && d > 2 {
                    g[cx + x, cy + y] = lit ? 0x7A4E2C : 0x5A3820
                } else if d <= 3 {
                    g[cx + x, cy + y] = d < 1.5 ? 0x2C2C36 : 0x5A5A68
                }
            }
        }
        // Canal de madera arriba y agua que cae y salpica
        fill(&g, cx - 4, cy - r - 6, 12, 3, 0x6A4026); hline(&g, cx - 4, cy - r - 6, 12, 0x8A5A34)
        for y in (cy - r - 3)...(cy + r + 4) {
            g[cx + 4, y] = y % 3 == 0 ? 0xE6F6FF : 0x7ABEEA
            g[cx + 5, y] = y % 2 == 0 ? 0x4E94D0 : 0x9AD8FF
        }
        for (dx, dy) in [(2, r + 4), (7, r + 4), (1, r + 3), (8, r + 3), (4, r + 5)] { g[cx + dx, cy + dy] = 0xE6F6FF }
    }
}
