import CoreGraphics
import Foundation
import GameCore

/// `Harness mapa-continente`: el mapa del continente de la pausa entero a PNG, con los mismos dibujos que la app
/// (`ContinentMapArt`): fondo, áreas con su mapa real, niebla, iconos y el héroe. Mide lo que tarda cada capa.
/// Salida: `continente_<id>_<partida>.png` (reducido para mirarlo entero), `..._grande.png` (resolución del zoom
/// máximo) y `..._pueblo.png` (recorte alrededor del héroe a resolución completa).
@MainActor
func continentMapShots() {
    func ms(_ start: CFAbsoluteTime) -> String { String(format: "%.0f ms", (CFAbsoluteTimeGetCurrent() - start) * 1000) }
    for continent in World.continents {
        var t0 = CFAbsoluteTimeGetCurrent()
        let layout = continent.placement
        print("Continente \(continent.name): \(layout.width)×\(layout.height) casillas, colocación en \(ms(t0))")
        for id in layout.areaIDs {
            let f = layout.frame(of: id)!
            print("  \(id): (\(f.x), \(f.y)) \(f.width)×\(f.height)")
        }
        for road in layout.roads {
            print("  camino \(road.id): " + road.points.map { String(format: "(%.1f, %.1f)", $0.x, $0.y) }.joined(separator: " → ")
                  + (road.label.map { "  «\($0)»" } ?? ""))
        }
        let areas = Dictionary(uniqueKeysWithValues: layout.areaIDs.compactMap { World.area($0) }.map { ($0.id, $0) })

        // Tiempos de dibujo (release, sin caché).
        t0 = CFAbsoluteTimeGetCurrent()
        let background = ContinentMapArt.background(layout, areas: areas).makeCGImage()
        print("  fondo \(background.width)×\(background.height) px: \(ms(t0))")
        var areaImages: [String: CGImage] = [:], fogImages: [String: CGImage] = [:]
        var total = CFAbsoluteTimeGetCurrent()
        for (id, area) in areas.sorted(by: { $0.key < $1.key }) {
            t0 = CFAbsoluteTimeGetCurrent()
            areaImages[id] = ContinentMapArt.areaGrid(area, castleOpen: false).makeCGImage()
            print("  área \(id) \(areaImages[id]!.width)×\(areaImages[id]!.height) px: \(ms(t0))")
        }
        print("  todas las áreas: \(ms(total))")
        total = CFAbsoluteTimeGetCurrent()
        for (id, area) in areas { fogImages[id] = ContinentMapArt.fog(area).makeCGImage() }
        print("  niebla de todas las áreas: \(ms(total))")

        // Dos partidas: recién liberado el pueblo (como `-pantalla mapa`) y todo visitado.
        var story = PlayerProfile.newGame()
        story.town.rescued = Valdehierro.villagerIDs
        story.town.killedSpawns.formUnion(Valdehierro.town.spawns.filter { !$0.id.hasPrefix("courtyard") }.map(\.id))
        story.syncStory()
        for id in [Valdemar.huertosID, Valdemar.robledaID, Valdehierro.townID] { story.arrive(at: id) }
        for id in [ValdemarQuests.molino, ValdemarQuests.cazaMayor, ValdemarQuests.pedregal] { story.accept(id) }
        var all = story
        for id in layout.areaIDs { all.arrive(at: id) }
        all.arrive(at: Valdehierro.townID)

        for (name, profile) in [("partida", story), ("todo", all)] {
            let scale = 24 / ContinentMapArt.backgroundScale  // el fondo, a la escala del arte de las áreas
            let T = ContinentMapArt.areaScale
            let w = layout.width * T, h = layout.height * T
            let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.interpolationQuality = .none
            func draw(_ image: CGImage, x: Double, y: Double, w iw: Double, h ih: Double) {
                ctx.draw(image, in: CGRect(x: x, y: Double(h) - y - ih, width: iw, height: ih))
            }
            draw(background, x: 0, y: 0, w: Double(background.width * scale), h: Double(background.height * scale))
            for id in layout.areaIDs {
                let f = layout.frame(of: id)!
                if profile.hasVisitedOnMap(id) {
                    draw(areaImages[id]!, x: Double(f.x * T), y: Double(f.y * T), w: Double(f.width * T), h: Double(f.height * T))
                } else {
                    let pad = ContinentMapArt.fogPad
                    draw(fogImages[id]!, x: Double((f.x - pad) * T), y: Double((f.y - pad) * T),
                         w: Double((f.width + 2 * pad) * T), h: Double((f.height + 2 * pad) * T))
                }
            }
            // Iconos (a 3 px por pixel) en su casilla real.
            func pin(_ grid: PixelGrid, _ p: MapPoint, s: Int = 3) {
                let img = grid.makeCGImage()
                draw(img, x: p.x * Double(T) - Double(img.width * s) / 2, y: p.y * Double(T) - Double(img.height * s),
                     w: Double(img.width * s), h: Double(img.height * s))
            }
            for landmark in World.landmarkPins(of: continent) where profile.hasVisitedOnMap(landmark.spot.areaID) {
                guard let p = layout.point(of: landmark.spot.tile, in: landmark.spot.areaID) else { continue }
                switch landmark.kind {
                case .safePoint: pin(ContinentMapArt.campfire, p)
                case .dungeon: pin(ContinentMapArt.dungeon, p)
                case .forge: pin(Sprites.anvil, p, s: 2)
                default: break
                }
            }
            for road in layout.roads where road.isFrontier {
                pin(ContinentMapArt.signpost, MapPoint(road.points.last!.x, Double(layout.margin) * 0.6), s: 4)
            }
            for quest in profile.questPins(in: continent) {
                guard let p = layout.point(of: quest.spot.tile, in: quest.spot.areaID) else { continue }
                switch quest.kind {
                case .questOffer: pin(Sprites.questMarker(.offer), p)
                case .questTurnIn: pin(Sprites.questMarker(.turnIn), p)
                case .questTarget: pin(ContinentMapArt.targetFlag, p, s: 4)
                default: break
                }
            }
            let hero = layout.point(of: TilePoint(21, 14), in: Valdehierro.townID)!
            pin(ContinentMapArt.heroFace(HeroLook(profile: profile)).outlined(0xFFCD75), hero, s: 4)
            let full = ctx.makeImage()!
            save(full, "continente_\(continent.id)_\(name)_grande")
            // Reducido a 1/4 (para verlo entero) y recorte alrededor del héroe.
            let small = CGContext(data: nil, width: w / 4, height: h / 4, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            small.interpolationQuality = .high
            small.draw(full, in: CGRect(x: 0, y: 0, width: w / 4, height: h / 4))
            save(small.makeImage()!, "continente_\(continent.id)_\(name)")
            let crop = CGRect(x: Int(hero.x) * T - 900, y: Int(hero.y) * T - 520, width: 1800, height: 1040)
            if let cut = full.cropping(to: crop) { save(cut, "continente_\(continent.id)_\(name)_pueblo") }
        }
    }
}

/// `Harness mapa-mundo`: el mapa del mundo de la pausa (Ardenia) entero a PNG: el fondo del mundo con los continentes
/// futuros en gris y, encima, los jugables con su fondo y sus áreas (todas visitadas). Mide el fondo del mundo.
/// Salida: `mundo.png` (3 px por casilla) y `mundo_grande.png` (6 px por casilla).
@MainActor
func worldMapShots() {
    func ms(_ start: CFAbsoluteTime) -> String { String(format: "%.0f ms", (CFAbsoluteTimeGetCurrent() - start) * 1000) }
    var t0 = CFAbsoluteTimeGetCurrent()
    let world = World.worldLayout
    print("Mundo: \(world.width)×\(world.height) casillas, colocación en \(ms(t0))")
    for c in world.continents {
        print("  \(c.id)\(c.isPlayable ? "" : " (próximamente)"): lienzo \(c.frame.x),\(c.frame.y) \(c.frame.width)×\(c.frame.height)")
    }
    for r in world.routes {
        print("  ruta \(r.id) (\(r.route.kind.rawValue)): " + r.points.map { String(format: "(%.0f, %.0f)", $0.x, $0.y) }.joined(separator: " → "))
    }
    t0 = CFAbsoluteTimeGetCurrent()
    let background = ContinentMapArt.worldBackground(world).makeCGImage()
    print("  fondo del mundo \(background.width)×\(background.height) px: \(ms(t0))")

    let T = 6
    let w = world.width * T, h = world.height * T
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    func draw(_ image: CGImage, _ r: TileRect, smooth: Bool) {
        ctx.interpolationQuality = smooth ? .high : .none
        ctx.draw(image, in: CGRect(x: r.x * T, y: h - r.maxY * T, width: r.width * T, height: r.height * T))
    }
    draw(background, TileRect(x: 0, y: 0, width: world.width, height: world.height), smooth: false)
    for pc in world.continents where pc.isPlayable {
        let areas = Dictionary(uniqueKeysWithValues: pc.layout.areaIDs.compactMap { World.area($0) }.map { ($0.id, $0) })
        draw(ContinentMapArt.background(pc.layout, areas: areas, framed: false).makeCGImage(), pc.frame, smooth: true)
        for id in pc.layout.areaIDs {
            guard let area = areas[id], let f = pc.frame(of: id) else { continue }
            draw(ContinentMapArt.areaGrid(area, castleOpen: false).makeCGImage(), f, smooth: true)
        }
    }
    if let hero = world.point(of: TilePoint(21, 14), in: Valdehierro.townID) {
        let face = ContinentMapArt.heroFace(HeroLook(profile: PlayerProfile.newGame())).outlined(0xFFCD75).makeCGImage()
        ctx.interpolationQuality = .none
        ctx.draw(face, in: CGRect(x: hero.x * Double(T) - Double(face.width), y: Double(h) - hero.y * Double(T) - Double(face.height),
                                  width: Double(face.width * 2), height: Double(face.height * 2)))
    }
    let full = ctx.makeImage()!
    save(full, "mundo_grande")
    let small = CGContext(data: nil, width: w / 2, height: h / 2, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    small.interpolationQuality = .high
    small.draw(full, in: CGRect(x: 0, y: 0, width: w / 2, height: h / 2))
    save(small.makeImage()!, "mundo")
}
