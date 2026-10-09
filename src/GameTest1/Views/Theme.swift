import GameCore
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum Theme {
    static let background = Color(hex: 0x14142B)
    static let panel = Color(hex: 0x262B44)
    static let panelLight = Color(hex: 0x3A4466)
    static let border = Color(hex: 0x8B9BB4)
    static let text = Color(hex: 0xF4F4F4)
    static let textDim = Color(hex: 0x94B0C2)
    static let gold = Color(hex: 0xFFCD75)
    static let red = Color(hex: 0xE43B44)
    static let green = Color(hex: 0x63C74D)
    static let blue = Color(hex: 0x41A6F6)
    static let purple = Color(hex: 0xB55088)
    static let orange = Color(hex: 0xEF7D57)

    static func font(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: text
        case .rare: blue
        case .epic: Color(hex: 0xC879F2)
        case .legendary: orange
        }
    }

    static func mineralColor(_ mineral: Mineral) -> Color {
        Color(hex: Sprites.mineralColors(mineral).mid)
    }
}

// MARK: - Paneles y botones

struct PixelPanelModifier: ViewModifier {
    var fill: Color = Theme.panel
    var border: Color = Theme.border

    func body(content: Content) -> some View {
        content
            .background(fill)
            .overlay(Rectangle().inset(by: 3).strokeBorder(border.opacity(0.35), lineWidth: 2))
            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
            .background(Rectangle().fill(Color.black.opacity(0.45)).offset(x: 4, y: 4))
    }
}

extension View {
    func pixelPanel(fill: Color = Theme.panel, border: Color = Theme.border) -> some View {
        modifier(PixelPanelModifier(fill: fill, border: border))
    }
}

struct PixelButtonStyle: ButtonStyle {
    var color: Color = Theme.panelLight
    var textColor: Color = Theme.text
    var fontSize: CGFloat = 14
    /// Alto mínimo (44+ para que sea cómodo de tocar en el móvil).
    var minHeight: CGFloat = 0
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(fontSize))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(minHeight: minHeight)
            .background(color.brightness(configuration.isPressed ? -0.12 : 0))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.black.opacity(0.3)).frame(height: 4)
            }
            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 3))
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(isEnabled ? 1 : 0.4)
    }
}

extension ButtonStyle where Self == PixelButtonStyle {
    static var pixel: PixelButtonStyle { PixelButtonStyle() }
    static func pixel(_ color: Color, text: Color = Theme.text, size: CGFloat = 14, minHeight: CGFloat = 0) -> PixelButtonStyle {
        PixelButtonStyle(color: color, textColor: text, fontSize: size, minHeight: minHeight)
    }
}

// MARK: - Piezas pequeñas

struct GoldLabel: View {
    let amount: Int
    var prefix = ""
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 5) {
            PixelImage(image: Art.coin, scale: size / 8 * 1.1)
            Text("\(prefix)\(amount)")
                .font(Theme.font(size))
                .foregroundStyle(Theme.gold)
                .monospacedDigit()
        }
    }
}

struct MineralChip: View {
    let mineral: Mineral
    let count: Int
    var scale: CGFloat = 2.6

    var body: some View {
        HStack(spacing: 3) {
            PixelImage(image: Art.mineralImage(mineral), scale: scale)
            Text("\(count)")
                .font(Theme.font(11))
                .foregroundStyle(count > 0 ? Theme.text : Theme.textDim.opacity(0.5))
                .monospacedDigit()
        }
    }
}

/// Fila con los 10 minerales del jugador.
struct MineralBar: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Mineral.allCases) { mineral in
                MineralChip(mineral: mineral, count: store.profile.count(of: mineral))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .pixelPanel()
    }
}

struct StatLines: View {
    let stats: Stats
    var fontSize: CGFloat = 11

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(stats.entries, id: \.kind) { entry in
                Text("\(entry.kind.formatBonus(entry.value)) \(entry.kind.shortName)")
                    .font(Theme.font(fontSize, weight: .bold))
                    .foregroundStyle(entry.value >= 0 ? Theme.green : Theme.red)
            }
        }
    }
}

/// Nivel del personaje con su barra de experiencia.
struct LevelBadge: View {
    let level: Int
    /// 0…1 hacia el siguiente nivel.
    let progress: Double
    var width: CGFloat = 170

    var body: some View {
        HStack(spacing: 6) {
            Text("NV \(level)")
                .font(Theme.font(12, weight: .black))
                .foregroundStyle(Theme.gold)
                .frame(minWidth: 40, alignment: .leading)
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.6))
                Rectangle().fill(Color(hex: 0xB55088))
                    .frame(width: max(0, (width - 46) * min(1, progress)))
            }
            .frame(width: width - 46, height: 6)
            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 1))
        }
        .shadow(color: .black, radius: 0, x: 1, y: 1)
    }
}

struct HPBar: View {
    let hp: Double
    let maxHP: Double
    var width: CGFloat = 160

    var body: some View {
        let fraction = maxHP > 0 ? max(0, min(1, hp / maxHP)) : 0
        HStack(spacing: 6) {
            PixelImage(image: Art.heart, scale: 2.4)
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.6))
                Rectangle()
                    .fill(fraction > 0.3 ? Theme.red : Theme.orange)
                    .frame(width: (width - 6) * fraction)
                    .padding(3)
                    .animation(.easeOut(duration: 0.15), value: fraction)
                Text("\(Int(min(hp, maxHP).rounded(.up)))/\(Int(maxHP.rounded(.up)))")
                    .font(Theme.font(10))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
            }
            .frame(width: width, height: 18)
            .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 2))
        }
    }
}

/// Indicador de si un objeto es mejor que el equipado.
struct CompareBadge: View {
    let item: Item
    let equipped: Item?

    var body: some View {
        if let equipped, equipped.id != item.id {
            let diff = item.powerScore - equipped.powerScore
            Text(diff > 0.5 ? "▲ MEJOR" : (diff < -0.5 ? "▼ PEOR" : "= IGUAL"))
                .font(Theme.font(9))
                .foregroundStyle(diff > 0.5 ? Theme.green : (diff < -0.5 ? Theme.red : Theme.textDim))
        }
    }
}

/// Etiquetas de color con los elementos de una pieza.
struct ElementChips: View {
    let elements: [Element]
    var fontSize: CGFloat = 8

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
                Text(element.name.uppercased())
                    .font(Theme.font(fontSize, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color(hex: element.color))
                    .overlay(Rectangle().strokeBorder(Color.black.opacity(0.6), lineWidth: 1))
            }
        }
    }
}

/// Nombre de la habilidad de un arma ("???" si aún es secreta).
struct AbilityTag: View {
    @Environment(GameStore.self) private var store
    let ability: Ability?
    var fontSize: CGFloat = 10

    var body: some View {
        if let ability {
            let known = store.profile.discoveredAbilities.contains(ability.id)
            Text(known ? "✦ \(ability.name)" : "✦ ???")
                .font(Theme.font(fontSize, weight: .black))
                .foregroundStyle(known ? Color(hex: ability.elements.first?.color ?? 0xFFFFFF) : Theme.textDim)
        }
    }
}
