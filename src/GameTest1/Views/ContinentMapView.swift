import GameCore
import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Mapa del mundo y del continente (pausa)
//
// Mapa ilustrado a pantalla completa de Ardenia (`WorldLayout`, GameCore). Los continentes jugables salen en color con
// cada área con su mapa real (`ContinentMapArt`), colocadas según sus salidas (`ContinentLayout`), unidas por terreno,
// ríos y caminos; niebla sobre lo no visitado; rótulos con nombre y niveles; hogueras, mazmorras, forja; el héroe en su
// casilla y las marcas de misión. Los que aún no se pueden jugar salen en gris (`WorldMapArt`) con su boceto, su sello
// "Próximamente" y una tarjeta al tocarlos. Las rutas entre continentes van punteadas.
//
// Controles: pellizcar = zoom (hacia los dedos), arrastrar = mover, doble toque = acercar ahí, tocar = tarjeta del área o
// del continente. Botones ◍ MUNDO / ▣ CONTINENTE, + / − / ◎ (centrar en mí). En Mac: rueda del ratón = zoom; en el
// trackpad, pellizcar = zoom y deslizar con dos dedos = mover (con ⌘ u ⌥, zoom); arrastrar con el ratón = mover; + y −.
// El zoom va de ver el mundo entero a `maxZoom` puntos por casilla (las casillas como en el juego). Al abrir: centrado
// en el héroe con un zoom medio (el de antes, calculado con su continente).
//
// Uso: `ContinentMapView(profile:currentAreaID:heroTile:onClose:)`. `heroTile` = casilla del héroe en `currentAreaID`
// (nil = la entrada del área); `onClose` = qué hace el botón cerrar (nil = no se muestra).

extension ExploreSession {
    /// Casilla del héroe en el área actual (para el mapa del continente).
    var heroTile: TilePoint { scene.heroFeetTile() }
}

/// Imágenes del mapa: se dibujan en segundo plano la primera vez y se quedan en `ContinentMapCache` (la segunda apertura
/// es instantánea). El zoom solo escala las imágenes: nunca se vuelven a dibujar.
@Observable
final class ContinentMapModel {
    let world: WorldLayout
    /// Áreas de los continentes jugables (las que se dibujan con su mapa real).
    let areas: [String: AreaMap]
    private(set) var worldBackground: CGImage?
    /// Fondo (terreno, ríos, caminos) de cada continente jugable.
    private(set) var backgrounds: [String: CGImage] = [:]
    private(set) var areaImages: [String: CGImage] = [:]
    private(set) var fogImages: [String: CGImage] = [:]
    @ObservationIgnored private var started = false

    init(world: WorldLayout = World.worldLayout) {
        self.world = world
        let ids = world.continents.filter(\.isPlayable).flatMap(\.layout.areaIDs)
        areas = Dictionary(uniqueKeysWithValues: ids.compactMap { World.area($0) }.map { ($0.id, $0) })
    }

    var playable: [PlacedContinent] { world.continents.filter(\.isPlayable) }

    /// Dibuja (o saca de la caché) lo que falta: primero el área `first`, luego niebla y fondos, el mundo y el resto.
    func load(visited: Set<String>, castleOpen: (String) -> Bool, first: String?) {
        guard !started else { return }
        started = true
        let cache = ContinentMapCache.shared
        // Lo que ya está dibujado, al momento.
        worldBackground = cache.image(ContinentMapArt.worldKey(world))
        for pc in playable {
            if let bg = cache.image(ContinentMapArt.backgroundKey(pc.layout, framed: false)) { backgrounds[pc.id] = bg }
            for id in pc.layout.areaIDs {
                if let fog = cache.image(ContinentMapArt.fogKey(id)) { fogImages[id] = fog }
                if visited.contains(id), let image = cache.image(ContinentMapArt.areaKey(id, castleOpen: castleOpen(pc.id))) { areaImages[id] = image }
            }
        }
        let allAreas = playable.flatMap(\.layout.areaIDs)
        let known = self.areas
        let missingAreas = ((first.map { [$0] } ?? []) + allAreas.filter { $0 != first })
            .filter { visited.contains($0) && areaImages[$0] == nil && known[$0] != nil }
        let missingFog = allAreas.filter { fogImages[$0] == nil }
        let missingBackgrounds = playable.filter { backgrounds[$0.id] == nil }
        guard worldBackground == nil || !missingAreas.isEmpty || !missingFog.isEmpty || !missingBackgrounds.isEmpty else { return }
        let world = world, areas = known
        let open: [String: Bool] = Dictionary(uniqueKeysWithValues: playable.map { ($0.id, castleOpen($0.id)) })
        let owner: [String: String] = Dictionary(uniqueKeysWithValues: playable.flatMap { pc in pc.layout.areaIDs.map { ($0, pc.id) } })
        Task.detached(priority: .userInitiated) { [weak self] in
            let t0 = CFAbsoluteTimeGetCurrent()
            var missingAreas = missingAreas
            // Primero el área donde está el héroe: es lo que se mira al abrir.
            if let here = missingAreas.first, here == first, let area = areas[here] {
                let image = ContinentMapArt.cachedArea(area, castleOpen: open[owner[here] ?? ""] ?? false)
                missingAreas.removeFirst()
                await MainActor.run { [weak self] in self?.areaImages[here] = image }
            }
            var fogs: [String: CGImage] = [:]
            for id in missingFog { if let area = areas[id] { fogs[id] = ContinentMapArt.cachedFog(area) } }
            var bgs: [String: CGImage] = [:]
            for pc in missingBackgrounds {
                let own = Dictionary(uniqueKeysWithValues: pc.layout.areaIDs.compactMap { areas[$0] }.map { ($0.id, $0) })
                bgs[pc.id] = ContinentMapArt.cachedBackground(pc.layout, areas: own, framed: false)
            }
            let fogsDone = fogs, bgsDone = bgs
            await MainActor.run { [weak self] in
                self?.fogImages.merge(fogsDone) { $1 }
                self?.backgrounds.merge(bgsDone) { $1 }
            }
            let t1 = CFAbsoluteTimeGetCurrent()
            let worldImage = ContinentMapArt.cachedWorld(world)
            await MainActor.run { [weak self] in self?.worldBackground = worldImage }
            let t2 = CFAbsoluteTimeGetCurrent()
            for id in missingAreas {
                guard let area = areas[id] else { continue }
                let image = ContinentMapArt.cachedArea(area, castleOpen: open[owner[id] ?? ""] ?? false)
                await MainActor.run { [weak self] in self?.areaImages[id] = image }
            }
            #if DEBUG
            print(String(format: "Mapa del continente: área actual, niebla y fondo %.0f ms, mundo %.0f ms, %d áreas %.0f ms",
                         (t1 - t0) * 1000, (t2 - t1) * 1000, missingAreas.count, (CFAbsoluteTimeGetCurrent() - t2) * 1000))
            #endif
        }
    }
}

struct ContinentMapView: View {
    let profile: PlayerProfile
    let currentAreaID: String
    var heroTile: TilePoint? = nil
    var onClose: (() -> Void)? = nil

    /// Puntos por casilla con el zoom máximo (como en la escena: 24 px × 2).
    static let maxZoom: CGFloat = 48
    /// Por debajo de este zoom (pt por casilla) se ve "el mundo": carteles de continente en vez de los de área.
    static let worldZoom: CGFloat = 3.2

    @State private var model: ContinentMapModel?
    @State private var zoom: CGFloat = 0
    @State private var center = MapPoint(0, 0)
    @State private var size: CGSize = .zero
    @State private var dragStart: MapPoint?
    @State private var pinchStart: (zoom: CGFloat, anchor: MapPoint, location: CGPoint)?
    /// Área tocada (tarjeta de área) o continente gris tocado (tarjeta de continente).
    @State private var selected: String?
    @State private var selectedContinent: String?
    @State private var pulse = false
    @Environment(\.displayScale) private var displayScale
    #if os(macOS)
    @State private var scrollMonitor: Any?
    @State private var globalFrame: CGRect = .zero
    #endif

    /// Continente donde está el héroe.
    private var continentID: String { profile.continentID }
    private var continent: Continent { World.continent(continentID) ?? World.continents[0] }

    var body: some View {
        ZStack {
            Color(hex: 0x285F96).ignoresSafeArea()
            if let model {
                GeometryReader { geo in
                    canvas(model)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .contentShape(Rectangle())
                        .gesture(dragGesture)
                        .simultaneousGesture(pinchGesture)
                        .onTapGesture(count: 2, coordinateSpace: .local) { zoomBy(2, at: $0, animated: true) }
                        .onTapGesture(coordinateSpace: .local) { tap(at: $0, model: model) }
                        .onAppear { resize(geo.size, model: model) }
                        .onChange(of: geo.size) { _, new in resize(new, model: model) }
                        #if os(macOS)
                        .onAppear { globalFrame = geo.frame(in: .global) }
                        .onChange(of: geo.frame(in: .global)) { _, new in globalFrame = new }
                        #endif
                }
                .ignoresSafeArea()
                controls(model)
                if model.worldBackground == nil || model.playable.contains(where: { pc in
                    model.backgrounds[pc.id] == nil || pc.layout.areaIDs.contains { profile.hasVisitedOnMap($0) && model.areaImages[$0] == nil }
                }) {
                    // Lo que falta va apareciendo según se dibuja.
                    Text("Dibujando el mapa…")
                        .font(Theme.font(12, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.65))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 12)
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            let model = self.model ?? ContinentMapModel()
            self.model = model
            let visited = Set(model.playable.flatMap(\.layout.areaIDs).filter(profile.hasVisitedOnMap))
            let profile = self.profile
            model.load(visited: visited, castleOpen: { profile.isCastleOpen(continentID: $0) }, first: heroSpot?.areaID)
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
            #if os(macOS)
            installScrollMonitor()
            #endif
        }
        #if os(macOS)
        .onDisappear {
            if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
            scrollMonitor = nil
        }
        #endif
    }

    // MARK: Lienzo

    private func image(_ cg: CGImage, _ rect: TileRect, pxPerTile: Int, visible view: CGRect) -> some View {
        let r = screenRect(rect)
        let interp: Image.Interpolation = zoom / CGFloat(pxPerTile) * displayScale >= 1 ? .none : .medium
        return Group {
            if r.intersects(view) {
                Image(decorative: cg, scale: 1).resizable().interpolation(interp)
                    .frame(width: r.width, height: r.height).position(x: r.midX, y: r.midY)
            }
        }
    }

    @ViewBuilder
    private func canvas(_ model: ContinentMapModel) -> some View {
        let view = CGRect(origin: .zero, size: size)
        let world = model.world
        ZStack(alignment: .topLeading) {
            if let bg = model.worldBackground {
                image(bg, TileRect(x: 0, y: 0, width: world.width, height: world.height), pxPerTile: ContinentMapArt.worldScale, visible: view)
            }
            ForEach(model.playable) { pc in
                if let bg = model.backgrounds[pc.id] {
                    image(bg, pc.frame, pxPerTile: ContinentMapArt.backgroundScale, visible: view)
                }
                ForEach(pc.layout.areaIDs, id: \.self) { id in
                    if let frame = pc.frame(of: id) {
                        if profile.hasVisitedOnMap(id), let img = model.areaImages[id] {
                            image(img, frame, pxPerTile: ContinentMapArt.areaScale, visible: view)
                        } else if let fog = model.fogImages[id] {
                            // Sin visitar (o aún dibujándose): nubes con la silueta.
                            let pad = ContinentMapArt.fogPad
                            image(fog, TileRect(x: frame.x - pad, y: frame.y - pad, width: frame.width + 2 * pad, height: frame.height + 2 * pad),
                                  pxPerTile: ContinentMapArt.fogScale, visible: view)
                        }
                    }
                }
            }
            if let selected, let id = world.continentID(ofArea: selected), let frame = world.continent(id)?.frame(of: selected) {
                highlight(screenRect(frame))
            }
            if let selectedContinent, let pc = world.continent(selectedContinent) {
                highlight(screenRect(pc.landBounds).insetBy(dx: -6, dy: -6))
            }
            if zoom >= 2.4 { pins(model) }
            labels(model)
            heroMarker(model)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func highlight(_ r: CGRect) -> some View {
        Rectangle().strokeBorder(Theme.gold, style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
            .frame(width: r.width, height: r.height).position(x: r.midX, y: r.midY)
            .allowsHitTesting(false)
    }

    /// Carteles: de área (cartel del juego, nombre y niveles) o, al ver el mundo, de continente; en los continentes
    /// grises, su nombre con el sello "Próximamente".
    @ViewBuilder
    private func labels(_ model: ContinentMapModel) -> some View {
        let screenBox = CGRect(origin: .zero, size: size)
        let worldView = zoom < Self.worldZoom
        // Viendo el mundo, los carteles encogen con el zoom para no tapar los continentes.
        let signScale = worldView ? min(1, max(0.55, zoom / 2.6)) : 1
        ForEach(model.world.continents) { pc in
            let land = screenRect(pc.landBounds)
            if pc.isPlayable {
                if worldView {
                    if land.intersects(screenBox) {
                        // Debajo de su tierra (arriba suele estar la cara del héroe).
                        AreaSign(name: pc.entry.name, levels: levelText(pc.entry.levels), explored: true, current: pc.id == continentID)
                            .fixedSize()
                            .scaleEffect(signScale)
                            .position(x: land.midX, y: min(land.maxY + 14, size.height - 30))
                            .allowsHitTesting(false)
                    }
                } else {
                    areaLabels(pc, model: model)
                }
            } else if land.intersects(screenBox) {
                VStack(spacing: 4) {
                    AreaSign(name: pc.entry.name, levels: levelText(pc.entry.levels), explored: false, current: false, pending: true)
                    ComingSoonSeal(small: worldView)
                }
                .fixedSize()
                .scaleEffect(signScale)
                .position(x: min(max(land.midX, 110 * signScale), size.width - 110 * signScale),
                          y: min(max(land.midY, 80), size.height - 50))
                .allowsHitTesting(false)
                // Con zoom, las zonas del boceto con su nombre (sin más detalle).
                if zoom >= 5 {
                    ForEach(pc.entry.plannedAreas) { planned in
                        if let frame = pc.frame(of: planned.id) {
                            let r = screenRect(frame)
                            if r.intersects(screenBox) {
                                AreaSign(name: planned.name, levels: planned.levels.map(levelText) ?? "Capital", explored: false,
                                         current: false, pending: true)
                                    .fixedSize()
                                    .scaleEffect(0.8)
                                    .position(x: r.midX, y: r.minY + 4)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Carteles de las áreas de un continente jugable, siempre dentro de la parte visible del área.
    @ViewBuilder
    private func areaLabels(_ pc: PlacedContinent, model: ContinentMapModel) -> some View {
        ForEach(pc.layout.areaIDs, id: \.self) { id in
            if let frame = pc.frame(of: id), let area = model.areas[id] {
                let full = screenRect(frame)
                let r = full.intersection(CGRect(origin: .zero, size: size))
                if !r.isNull, r.width > 60, r.height > 30 {
                    let visited = profile.hasVisitedOnMap(id)
                    // Ancho aproximado del cartel (fuente monoespaciada) para no cortarlo en el borde de la pantalla.
                    let half = CGFloat(max(area.name.count, visited ? 8 : 18)) * 4.3 + 12
                    let x = min(max(r.midX, half + 4), size.width - half - 4)
                    // Cuelga del borde de arriba del área, por debajo de la barra de arriba; con poco zoom, más pequeño
                    // y por encima del área (no tapa al héroe ni los iconos).
                    let small = zoom < 8
                    let y = min(max(full.minY - (small ? 14 : 0), 78), r.maxY - 22)
                    AreaSign(name: area.name, levels: levelText(area.levelRange), explored: visited, current: heroSpot?.areaID == id)
                        .fixedSize()
                        .scaleEffect(small ? 0.8 : 1)
                        .position(x: x, y: y)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    /// Hogueras, mazmorras, forja (solo en lo visitado y con algo de zoom) y marcas de misión.
    @ViewBuilder
    private func pins(_ model: ContinentMapModel) -> some View {
        ForEach(mapPins(model)) { item in
            if let p = model.world.point(of: item.pin.spot.tile, in: item.pin.spot.areaID) {
                let s = screen(p)
                if CGRect(origin: .zero, size: size).insetBy(dx: -30, dy: -30).contains(s) {
                    PinIcon(kind: item.pin.kind, pulse: pulse)
                        .position(x: s.x + CGFloat(item.slot) * 20, y: s.y - 14)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    /// Iconos a mostrar, con un hueco para los que caen en la misma casilla.
    private func mapPins(_ model: ContinentMapModel) -> [PlacedPin] {
        var list: [MapPin] = []
        for pc in model.playable {
            guard let continent = World.continent(pc.id) else { continue }
            if zoom >= 6 { list += World.landmarkPins(of: continent).filter { profile.hasVisitedOnMap($0.spot.areaID) } }
            list += profile.questPins(in: continent)
        }
        var used: [MapSpot: Int] = [:]
        return list.map { pin in
            let slot = used[pin.spot, default: 0]
            used[pin.spot] = slot + 1
            return PlacedPin(pin: pin, slot: slot)
        }
    }

    @ViewBuilder
    private func heroMarker(_ model: ContinentMapModel) -> some View {
        if let p = heroPoint(model) {
            let s = screen(p)
            ZStack {
                Circle().stroke(Theme.gold.opacity(pulse ? 0.15 : 0.7), lineWidth: 3)
                    .frame(width: pulse ? 64 : 44, height: pulse ? 64 : 44)
                PixelImage(image: Art.gridImage("mapa.cara.\(HeroLook(profile: profile).cacheKey)",
                                                ContinentMapArt.heroFace(HeroLook(profile: profile)).outlined(0xFFCD75)), scale: 1.4)
                    .offset(y: pulse ? -3 : 0)
            }
            .position(x: s.x, y: s.y - 16)
            .allowsHitTesting(false)
        }
    }

    // MARK: Botones y tarjetas

    @ViewBuilder
    private func controls(_ model: ContinentMapModel) -> some View {
        let worldView = zoom < Self.worldZoom
        // Cabecera: el continente que hay en el centro de la pantalla (el del héroe si no hay ninguno).
        let shown = model.world.hit(center).flatMap { World.atlasEntry($0.continentID) } ?? World.atlasEntry(continentID)
        let title = shown?.name ?? continent.name
        let levels = shown?.levels ?? continent.levels
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(worldView ? "ARDENIA" : title.uppercased()).font(Theme.font(16, weight: .black)).foregroundStyle(Theme.gold)
                    Text(worldView ? "Los seis continentes · niveles 1-60" : "Niveles \(levels.lowerBound)-\(levels.upperBound)")
                        .font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.textDim)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .pixelPanel(fill: Theme.panel.opacity(0.92))
                Spacer()
                if let onClose {
                    Button("✕ CERRAR", action: onClose)
                        .buttonStyle(.pixel(Theme.red, size: 15, minHeight: 46))
                }
            }
            Spacer()
            HStack(alignment: .bottom) {
                if let selected, let summary = profile.mapSummary(of: selected) {
                    AreaCard(summary: summary) { self.selected = nil }
                } else if let selectedContinent, let entry = World.atlasEntry(selectedContinent) {
                    ContinentCard(entry: entry) { self.selectedContinent = nil }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    Button(worldView ? "▣ CONTINENTE" : "◍ MUNDO") { worldView ? showContinent(model) : showWorld(model) }
                        .buttonStyle(.pixel(Theme.panelLight, size: 12, minHeight: 46))
                    Button("+") { zoomBy(1.6, at: nil, animated: true) }
                        .keyboardShortcut("+", modifiers: [])
                        .buttonStyle(MapButtonStyle())
                    Button("−") { zoomBy(1 / 1.6, at: nil, animated: true) }
                        .keyboardShortcut("-", modifiers: [])
                        .buttonStyle(MapButtonStyle())
                    Button("◎") { centerOnHero(model) }
                        .buttonStyle(MapButtonStyle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: Transformación mapa ↔ pantalla

    private func screen(_ p: MapPoint) -> CGPoint {
        CGPoint(x: (CGFloat(p.x) - CGFloat(center.x)) * zoom + size.width / 2,
                y: (CGFloat(p.y) - CGFloat(center.y)) * zoom + size.height / 2)
    }

    private func mapPoint(_ s: CGPoint) -> MapPoint {
        MapPoint(Double((s.x - size.width / 2) / zoom) + center.x, Double((s.y - size.height / 2) / zoom) + center.y)
    }

    private func screenRect(_ r: TileRect) -> CGRect {
        let o = screen(MapPoint(Double(r.x), Double(r.y)))
        return CGRect(x: o.x, y: o.y, width: CGFloat(r.width) * zoom, height: CGFloat(r.height) * zoom)
    }

    private var heroSpot: MapSpot? {
        let area = World.area(currentAreaID)
        return World.mapSpot(areaID: currentAreaID, tile: heroTile ?? area?.entry ?? TilePoint(0, 0))
    }

    private func heroPoint(_ model: ContinentMapModel) -> MapPoint? {
        heroSpot.flatMap { model.world.point(of: $0.tile, in: $0.areaID) }
    }

    /// Zoom que encaja un rectángulo del mundo en la pantalla.
    private func fitZoom(_ r: TileRect) -> CGFloat {
        guard size.width > 0, size.height > 0, r.width > 0, r.height > 0 else { return 1 }
        return min(size.width / CGFloat(r.width), size.height / CGFloat(r.height))
    }

    /// El mínimo: el mundo entero.
    private func minZoom(_ model: ContinentMapModel) -> CGFloat {
        fitZoom(TileRect(x: 0, y: 0, width: model.world.width, height: model.world.height))
    }

    /// El continente del héroe entero (su lienzo).
    private func continentZoom(_ model: ContinentMapModel) -> CGFloat {
        model.world.continent(continentID).map { fitZoom($0.frame) } ?? minZoom(model)
    }

    /// El centro, sin dejar ver fuera del mapa (si el mapa cabe entero, centrado).
    private func clamped(_ c: MapPoint, zoom z: CGFloat, model: ContinentMapModel) -> MapPoint {
        let hw = Double(size.width / 2 / z), hh = Double(size.height / 2 / z)
        let w = Double(model.world.width), h = Double(model.world.height)
        let x = w <= 2 * hw ? w / 2 : min(max(c.x, hw), w - hw)
        let y = h <= 2 * hh ? h / 2 : min(max(c.y, hh), h - hh)
        return MapPoint(x, y)
    }

    private func resize(_ new: CGSize, model: ContinentMapModel) {
        size = new
        guard new.width > 0, new.height > 0 else { return }
        let low = minZoom(model)
        if zoom == 0 {
            // Al abrir: centrado en el héroe con un zoom medio (entre su continente entero y las casillas grandes).
            var start = (continentZoom(model) * Self.maxZoom).squareRoot() * 0.75
            #if DEBUG
            if let debug = Self.debugZoom { start = debug == 0 ? low : (debug < 0 ? Self.maxZoom : debug) }
            #endif
            zoom = min(Self.maxZoom, max(low, start))
            center = heroPoint(model) ?? model.world.continent(continentID)?.landBounds.center ?? MapPoint(0, 0)
            #if DEBUG
            if let id = Self.debugCenter, let pc = model.world.continent(id) { center = pc.landBounds.center; selectedContinent = pc.isPlayable ? nil : id }
            #endif
        }
        zoom = min(Self.maxZoom, max(low, zoom))
        center = clamped(center, zoom: zoom, model: model)
    }

    /// Acerca o aleja manteniendo fijo el punto de la pantalla `at` (nil = el centro).
    private func zoomBy(_ factor: CGFloat, at location: CGPoint?, animated: Bool) {
        guard let model else { return }
        let target = min(Self.maxZoom, max(minZoom(model), zoom * factor))
        let anchor = location.map(mapPoint) ?? center
        let s = location ?? CGPoint(x: size.width / 2, y: size.height / 2)
        let newCenter = MapPoint(anchor.x - Double((s.x - size.width / 2) / target), anchor.y - Double((s.y - size.height / 2) / target))
        let apply = {
            zoom = target
            center = clamped(newCenter, zoom: target, model: model)
        }
        if animated { withAnimation(.easeOut(duration: 0.25), apply) } else { apply() }
    }

    private func centerOnHero(_ model: ContinentMapModel) {
        guard let p = heroPoint(model) else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            if zoom < 12 { zoom = min(Self.maxZoom, max(minZoom(model), 16)) }
            center = clamped(p, zoom: zoom, model: model)
        }
    }

    private func showWorld(_ model: ContinentMapModel) {
        withAnimation(.easeOut(duration: 0.35)) {
            zoom = minZoom(model)
            center = clamped(MapPoint(Double(model.world.width) / 2, Double(model.world.height) / 2), zoom: zoom, model: model)
            selected = nil
        }
    }

    private func showContinent(_ model: ContinentMapModel) {
        guard let pc = model.world.continent(continentID) else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            zoom = max(minZoom(model), continentZoom(model))
            center = clamped(pc.frame.center, zoom: zoom, model: model)
            selectedContinent = nil
        }
    }

    private func tap(at location: CGPoint, model: ContinentMapModel) {
        let hit = model.world.hit(mapPoint(location))
        withAnimation(.easeOut(duration: 0.15)) {
            if let hit, model.world.continent(hit.continentID)?.isPlayable == false {
                selected = nil
                selectedContinent = selectedContinent == hit.continentID ? nil : hit.continentID
            } else {
                selectedContinent = nil
                let id = hit?.areaID
                selected = id == selected ? nil : id
            }
        }
    }

    // MARK: Gestos

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard pinchStart == nil, let model else { dragStart = nil; return }
                // Si el arrastre empieza (o sigue tras un pellizco), se toma el centro de ahora como origen.
                let origin = dragStart ?? MapPoint(center.x + Double(value.translation.width / zoom),
                                                   center.y + Double(value.translation.height / zoom))
                dragStart = origin
                center = clamped(MapPoint(origin.x - Double(value.translation.width / zoom),
                                          origin.y - Double(value.translation.height / zoom)), zoom: zoom, model: model)
            }
            .onEnded { _ in dragStart = nil }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard let model else { return }
                let start = pinchStart ?? (zoom, mapPoint(value.startLocation), value.startLocation)
                pinchStart = start
                let target = min(Self.maxZoom, max(minZoom(model), start.zoom * value.magnification))
                // El punto bajo los dedos se queda bajo los dedos.
                let c = MapPoint(start.anchor.x - Double((start.location.x - size.width / 2) / target),
                                 start.anchor.y - Double((start.location.y - size.height / 2) / target))
                zoom = target
                center = clamped(c, zoom: target, model: model)
            }
            .onEnded { _ in pinchStart = nil; dragStart = nil }
    }

    #if os(macOS)
    /// Rueda del ratón = zoom; trackpad con dos dedos = mover (con ⌘ u ⌥, zoom).
    private func installScrollMonitor() {
        guard scrollMonitor == nil else { return }
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard let window = event.window, let content = window.contentView, let model else { return event }
            let p = CGPoint(x: event.locationInWindow.x, y: content.bounds.height - event.locationInWindow.y)
            guard globalFrame.contains(p) else { return event }
            let local = CGPoint(x: p.x - globalFrame.minX, y: p.y - globalFrame.minY)
            let zoomKey = event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option)
            if event.hasPreciseScrollingDeltas && !zoomKey {
                center = clamped(MapPoint(center.x - Double(event.scrollingDeltaX / zoom), center.y - Double(event.scrollingDeltaY / zoom)),
                                 zoom: zoom, model: model)
            } else {
                let step = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY * 0.01 : event.scrollingDeltaY * 0.12
                zoomBy(exp(step), at: local, animated: false)
            }
            return nil
        }
    }
    #endif

    #if DEBUG
    /// `-centro-mapa <continente>` para las capturas: centra en ese continente (y abre su tarjeta si es gris).
    static var debugCenter: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-centro-mapa"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// `-zoom-mapa <puntos por casilla | min | max>` para las capturas.
    static var debugZoom: CGFloat? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-zoom-mapa"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "min": return 0
        case "max": return -1
        default: return Double(args[i + 1]).map { CGFloat($0) }
        }
    }
    #endif

    private func levelText(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? "Nv \(range.lowerBound)" : "Nv \(range.lowerBound)-\(range.upperBound)"
    }
}

// MARK: - Piezas

/// Icono con su hueco (si varios caen en la misma casilla, se ponen en fila).
private struct PlacedPin: Identifiable {
    let pin: MapPin
    let slot: Int
    var id: String { pin.id }
}

/// Cartel de madera con el nombre del área y sus niveles. `pending`: de un continente aún sin construir (gris).
private struct AreaSign: View {
    let name: String
    let levels: String
    let explored: Bool
    let current: Bool
    var pending = false

    var body: some View {
        VStack(spacing: 1) {
            Text(name.uppercased())
                .font(Theme.font(12, weight: .black))
                .foregroundStyle(explored ? Theme.gold : Theme.text.opacity(0.85))
            Text(explored || pending ? levels : "\(levels) · sin explorar")
                .font(Theme.font(9, weight: .bold))
                .foregroundStyle(explored ? Theme.text : Theme.textDim)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: explored ? 0x5A3A22 : (pending ? 0x4A4A50 : 0x3A3442)).opacity(0.92))
        .overlay(Rectangle().inset(by: 2).strokeBorder(Color(hex: current ? 0xFFCD75 : (pending ? 0x8A8A90 : 0x9C6B3A)), lineWidth: 1.5))
        .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
    }
}

/// Sello rojo inclinado de "Próximamente · en preparación".
private struct ComingSoonSeal: View {
    var small = false

    var body: some View {
        VStack(spacing: 0) {
            Text("PRÓXIMAMENTE").font(Theme.font(small ? 11 : 14, weight: .black))
            Text("en preparación").font(Theme.font(small ? 8 : 10, weight: .bold))
        }
        .foregroundStyle(Color(hex: 0xE8584F))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .overlay(Rectangle().strokeBorder(Color(hex: 0xE8584F), lineWidth: 2.5))
        .overlay(Rectangle().inset(by: 4).strokeBorder(Color(hex: 0xE8584F).opacity(0.6), lineWidth: 1))
        .background(Color.black.opacity(0.35))
        .rotationEffect(.degrees(-7))
    }
}

/// Tarjeta de un continente que aún no se puede jugar: nombre, niveles, una frase y "Próximamente".
private struct ContinentCard: View {
    let entry: AtlasEntry
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.name.uppercased()).font(Theme.font(14, weight: .black)).foregroundStyle(Theme.text)
                Text("Niveles \(entry.levels.lowerBound)-\(entry.levels.upperBound)")
                    .font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.textDim)
                Text(entry.teaser)
                    .font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("PRÓXIMAMENTE · en preparación")
                    .font(Theme.font(11, weight: .black)).foregroundStyle(Color(hex: 0xE8584F))
            }
            .frame(maxWidth: 300, alignment: .leading)
            Button("✕", action: onClose)
                .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 44))
                .frame(minWidth: 44)
        }
        .padding(10)
        .pixelPanel(fill: Color(hex: 0x3A3A42).opacity(0.96))
    }
}

/// Icono de un sitio del mapa (pixel-art dibujado en código).
private struct PinIcon: View {
    let kind: MapPinKind
    let pulse: Bool

    var body: some View {
        switch kind {
        case .safePoint:
            PixelImage(image: Art.gridImage("mapa.hoguera", ContinentMapArt.campfire), scale: 2.2)
        case .dungeon:
            PixelImage(image: Art.gridImage("mapa.mazmorra", ContinentMapArt.dungeon), scale: 2.2)
        case .forge:
            PixelImage(image: Art.anvil, scale: 1.3)
        case .questOffer:
            PixelImage(image: Art.gridImage("questMarker.offer", Sprites.questMarker(.offer)), scale: 2.2)
                .offset(y: pulse ? -3 : 0)
        case .questTurnIn:
            PixelImage(image: Art.gridImage("questMarker.turnIn", Sprites.questMarker(.turnIn)), scale: 2.2)
                .offset(y: pulse ? -3 : 0)
        case .questTarget:
            ZStack {
                Circle().stroke(Theme.red.opacity(pulse ? 0.2 : 0.8), lineWidth: 2.5)
                    .frame(width: pulse ? 40 : 26, height: pulse ? 40 : 26)
                    .offset(y: 10)
                PixelImage(image: Art.gridImage("mapa.objetivo", ContinentMapArt.targetFlag), scale: 2.6)
            }
        }
    }
}

/// Tarjeta de un área tocada: nombre, niveles, misiones de aquí, mazmorra, forja y hoguera.
private struct AreaCard: View {
    let summary: MapAreaSummary
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.name.uppercased()).font(Theme.font(14, weight: .black)).foregroundStyle(Theme.gold)
                Text(summary.levelText + (summary.visited ? "" : " · sin explorar"))
                    .font(Theme.font(10, weight: .bold)).foregroundStyle(Theme.textDim)
                ForEach(summary.dungeons, id: \.self) { id in
                    line("⛫ Mazmorra: \(World.placeName(id))", Theme.purple)
                }
                if summary.hasForge { line("⚒ Forja del enano", Theme.orange) }
                if summary.hasSafePoint { line("♨ Hoguera: punto seguro", Theme.text) }
                if !summary.offers.isEmpty || !summary.active.isEmpty {
                    Text("MISIONES").font(Theme.font(9, weight: .black)).foregroundStyle(Theme.orange).padding(.top, 2)
                    ForEach(summary.offers, id: \.self) { id in line("! " + (World.quest(id)?.title ?? id), Theme.gold) }
                    ForEach(summary.active, id: \.self) { id in line("• " + (World.quest(id)?.title ?? id), Theme.text) }
                } else {
                    line("Sin misiones aquí ahora mismo", Theme.textDim)
                }
            }
            .frame(maxWidth: 290, alignment: .leading)
            Button("✕", action: onClose)
                .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 44))
                .frame(minWidth: 44)
        }
        .padding(10)
        .pixelPanel(fill: Theme.panel.opacity(0.95))
    }

    private func line(_ text: String, _ color: Color) -> some View {
        Text(text).font(Theme.font(10, weight: .bold)).foregroundStyle(color).fixedSize(horizontal: false, vertical: true)
    }
}

/// Botón cuadrado de 46 pt (cómodo para el dedo).
private struct MapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(22, weight: .black))
            .foregroundStyle(Theme.text)
            .frame(width: 46, height: 46)
            .background(Theme.panelLight.brightness(configuration.isPressed ? -0.12 : 0))
            .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.3)).frame(height: 4) }
            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
            .offset(y: configuration.isPressed ? 2 : 0)
    }
}
