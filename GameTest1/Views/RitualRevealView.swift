import GameCore
import SwiftUI

/// Final del ritual: la ruleta decide la potencia y después se revela el arma y su habilidad.
struct RitualRevealView: View {
    enum Action { case equip, draw, keep }

    @Environment(GameStore.self) private var store
    let result: CraftResult
    let luck: Double
    let onFinish: (Action) -> Void

    @State private var rotation: Double = 0
    @State private var revealed = false

    static func color(for index: Int) -> Color {
        [Color(hex: 0x566C86), Color(hex: 0x8F563B), Color(hex: 0x94B0C2),
         Color(hex: 0x41A6F6), Color(hex: 0xB55088), Color(hex: 0xFFCD75)][index % 6]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            HStack(spacing: 24) {
                ZStack(alignment: .top) {
                    Wheel(probabilities: Roulette.probabilities(luck: luck))
                        .frame(width: 190, height: 190)
                        .rotationEffect(.degrees(rotation))
                    Pointer()
                        .fill(Color.white)
                        .overlay(Pointer().stroke(Color.black, lineWidth: 3))
                        .frame(width: 26, height: 24)
                        .offset(y: -10)
                }
                resultPanel.frame(width: 330)
            }
        }
        .onAppear(perform: spin)
    }

    @ViewBuilder
    private var resultPanel: some View {
        if revealed {
            let item = result.item
            let quality = result.quality
            HStack(alignment: .top, spacing: 12) {
                PixelImage(image: Art.itemImage(item), scale: 4)
                    .shadow(color: Self.color(for: result.segmentIndex), radius: 10)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(quality.name.uppercased()) ×\(quality.multiplier, specifier: "%.1f")")
                        .font(Theme.font(18, weight: .black))
                        .foregroundStyle(Self.color(for: result.segmentIndex))
                    Text(item.name)
                        .font(Theme.font(12, weight: .black))
                        .foregroundStyle(Theme.rarityColor(item.rarity))
                        .fixedSize(horizontal: false, vertical: true)
                    CompareBadge(item: item, equipped: store.profile.equipped(item.slot))
                    StatLines(stats: item.stats, fontSize: 10)
                    if let ability = item.ability {
                        VStack(alignment: .leading, spacing: 2) {
                            if result.discoveredNewAbility {
                                Text("¡HABILIDAD SECRETA DESCUBIERTA!")
                                    .font(Theme.font(9, weight: .black))
                                    .foregroundStyle(Theme.gold)
                            }
                            Text("✦ \(ability.name)")
                                .font(Theme.font(13, weight: .black))
                                .foregroundStyle(Color(hex: ability.elements.first?.color ?? 0xFFFFFF))
                            Text(ability.description)
                                .font(Theme.font(9, weight: .bold))
                                .foregroundStyle(Theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(6)
                        .background(Color(hex: 0x2A1640))
                        .overlay(Rectangle().strokeBorder(Color(hex: 0xC879F2), lineWidth: 2))
                    } else {
                        Text("Sin habilidad secreta")
                            .font(Theme.font(9, weight: .bold))
                            .foregroundStyle(Theme.textDim)
                    }
                    HStack(spacing: 6) {
                        Button("EQUIPAR") { onFinish(.equip) }
                            .buttonStyle(.pixel(Theme.green, text: .black, size: 11))
                        Button("✎ CREA TU ARMA") { onFinish(.draw) }
                            .buttonStyle(.pixel(Color(hex: 0xC879F2), text: .black, size: 11))
                        Button("GUARDAR") { onFinish(.keep) }
                            .buttonStyle(.pixel(Theme.panelLight, size: 11))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .pixelPanel()
            .transition(.scale.combined(with: .opacity))
        } else {
            Text("¡EL RITUAL\nESTÁ EN MARCHA!")
                .font(Theme.font(20, weight: .black))
                .foregroundStyle(Color(hex: 0xC879F2))
        }
    }

    private func spin() {
        let probs = Roulette.probabilities(luck: luck)
        let start = probs.prefix(result.segmentIndex).reduce(0, +) * 360
        let sweep = probs[result.segmentIndex] * 360
        // Punto aleatorio dentro de la casilla ganadora (sin tocar los bordes).
        let landing = start + sweep * Double.random(in: 0.2...0.8)
        let target = 360 * 6 - landing
        withAnimation(.timingCurve(0.15, 0.85, 0.25, 1, duration: 3.2)) {
            rotation = target
        } completion: {
            withAnimation(.spring(duration: 0.35)) { revealed = true }
        }
    }
}

/// Rueda dibujada con polígonos para mantener el estilo pixel.
private struct Wheel: View {
    let probabilities: [Double]

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius: CGFloat = min(size.width, size.height) / 2 - 3
        var start = -90.0   // grados, 0 = derecha, sentido horario (Y hacia abajo)
        for (index, p) in probabilities.enumerated() {
            let sweep = p * 360
            let path = wedge(center: center, radius: radius, start: start, sweep: sweep)
            context.fill(path, with: .color(RitualRevealView.color(for: index)))
            context.stroke(path, with: .color(.black), lineWidth: 2)
            if sweep > 16 {
                drawLabel(index: index, in: context, center: center, radius: radius, angle: start + sweep / 2)
            }
            start += sweep
        }
        let rimRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: rimRect), with: .color(.black), lineWidth: 5)
        let hub = Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24))
        context.fill(hub, with: .color(Theme.panel))
        context.stroke(hub, with: .color(.black), lineWidth: 3)
    }

    private func wedge(center: CGPoint, radius: CGFloat, start: Double, sweep: Double) -> Path {
        var path = Path()
        path.move(to: center)
        let steps = max(2, Int(sweep / 4))
        for step in 0...steps {
            let degrees: Double = start + sweep * Double(step) / Double(steps)
            let angle = CGFloat(degrees * .pi / 180)
            path.addLine(to: CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
        }
        path.closeSubpath()
        return path
    }

    private func drawLabel(index: Int, in context: GraphicsContext, center: CGPoint, radius: CGFloat, angle: Double) {
        var labelContext = context
        labelContext.translateBy(x: center.x, y: center.y)
        labelContext.rotate(by: .degrees(angle))
        let labelPoint = CGPoint(x: radius * 0.66, y: 0)
        // En la mitad izquierda giramos el texto 180° para que no quede boca abajo.
        let normalized = (angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        if normalized > 90 && normalized < 270 {
            labelContext.translateBy(x: labelPoint.x, y: 0)
            labelContext.rotate(by: .degrees(180))
            labelContext.translateBy(x: -labelPoint.x, y: 0)
        }
        let multiplier = Roulette.segments[index].multiplier
        let text = Text(String(format: "x%.1f", multiplier))
            .font(Theme.font(12, weight: .black))
            .foregroundStyle(Color.black)
        labelContext.draw(text, at: labelPoint)
    }
}

/// Flecha que apunta hacia abajo, sobre la rueda.
private struct Pointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
