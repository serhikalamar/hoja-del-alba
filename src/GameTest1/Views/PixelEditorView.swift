import GameCore
import SwiftUI

/// Editor de pixel-art para que el jugador dibuje su propia arma.
/// Empieza con el diseño generado por las piezas y se guarda en el objeto.
struct PixelEditorView: View {
    enum Tool: String, CaseIterable {
        case pencil = "✎ Lápiz"
        case eraser = "⌫ Goma"
        case fill = "▧ Cubo"
        case picker = "◉ Cuentagotas"
    }

    @Environment(GameStore.self) private var store
    let item: Item
    let onClose: () -> Void

    @State private var grid: PixelGrid
    @State private var tool: Tool = .pencil
    @State private var color: UInt32 = 0xFFFFFF
    @State private var mirror = false
    @State private var undoStack: [PixelGrid] = []
    @State private var strokeStarted = false

    static let palette: [UInt32] = [
        0x1A1C2C, 0x333C57, 0x566C86, 0x94B0C2, 0xC2C3C7, 0xFFFFFF,
        0x5D275D, 0xB13E53, 0xE43B44, 0xEF7D57, 0xFFCD75, 0xFFF09A,
        0xA7F070, 0x38B764, 0x257179, 0x29366F, 0x3B5DC9, 0x41A6F6,
        0x73EFF7, 0xC879F2, 0x7A4A2A, 0xB86F50, 0xD9A066, 0x4E2E1A,
    ]

    init(item: Item, onClose: @escaping () -> Void) {
        self.item = item
        self.onClose = onClose
        _grid = State(initialValue: Self.startingGrid(for: item))
    }

    /// Dibujo actual del arma, ajustado al lienzo de 18x25.
    private static func startingGrid(for item: Item) -> PixelGrid {
        if let custom = item.customSprite, !custom.isEmpty { return PixelGrid(custom: custom) }
        return generated(for: item)
    }

    private static func generated(for item: Item) -> PixelGrid {
        WeaponArt.composite(partIDs: item.partIDs ?? [])
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0E0A18).opacity(0.97).ignoresSafeArea()
            HStack(alignment: .top, spacing: 14) {
                toolsColumn.frame(width: 170)
                canvas
                previewColumn.frame(width: 170)
            }
            .padding(14)
        }
    }

    // MARK: - Lienzo

    private var canvas: some View {
        GeometryReader { geo in
            let cell = floor(min(geo.size.width / CGFloat(grid.width), geo.size.height / CGFloat(grid.height)))
            let size = CGSize(width: cell * CGFloat(grid.width), height: cell * CGFloat(grid.height))
            Canvas { context, _ in
                for y in 0..<grid.height {
                    for x in 0..<grid.width {
                        let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell)
                        if let c = grid[x, y] {
                            context.fill(Path(rect), with: .color(Color(hex: c)))
                        } else {
                            // Tablero de transparencia
                            context.fill(Path(rect), with: .color((x + y) % 2 == 0 ? Color(hex: 0x5A5A6A) : Color(hex: 0x4A4A58)))
                        }
                    }
                }
                var lines = Path()
                for x in 0...grid.width {
                    lines.move(to: CGPoint(x: CGFloat(x) * cell, y: 0))
                    lines.addLine(to: CGPoint(x: CGFloat(x) * cell, y: size.height))
                }
                for y in 0...grid.height {
                    lines.move(to: CGPoint(x: 0, y: CGFloat(y) * cell))
                    lines.addLine(to: CGPoint(x: size.width, y: CGFloat(y) * cell))
                }
                context.stroke(lines, with: .color(.black.opacity(0.35)), lineWidth: 0.5)
                if mirror {
                    var axis = Path()
                    axis.move(to: CGPoint(x: size.width / 2, y: 0))
                    axis.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                    context.stroke(axis, with: .color(Color(hex: 0xC879F2)), lineWidth: 1)
                }
            }
            .frame(width: size.width, height: size.height)
            .overlay(Rectangle().strokeBorder(Color(hex: 0xC879F2), lineWidth: 2))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = Int(value.location.x / cell), y = Int(value.location.y / cell)
                        guard x >= 0, y >= 0, x < grid.width, y < grid.height else { return }
                        if !strokeStarted {
                            strokeStarted = true
                            undoStack.append(grid)
                            if undoStack.count > 30 { undoStack.removeFirst() }
                        }
                        apply(at: x, y)
                    }
                    .onEnded { _ in strokeStarted = false }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func apply(at x: Int, _ y: Int) {
        switch tool {
        case .pencil, .eraser:
            let value: UInt32? = tool == .pencil ? color : nil
            grid[x, y] = value
            if mirror { grid[grid.width - 1 - x, y] = value }
        case .fill:
            flood(from: x, y, with: color)
            if mirror { flood(from: grid.width - 1 - x, y, with: color) }
        case .picker:
            if let picked = grid[x, y] {
                color = picked
                tool = .pencil
            }
        }
    }

    private func flood(from x: Int, _ y: Int, with newColor: UInt32) {
        let target = grid[x, y]
        guard target != newColor else { return }
        var stack = [(x, y)]
        while let (cx, cy) = stack.popLast() {
            guard cx >= 0, cy >= 0, cx < grid.width, cy < grid.height, grid[cx, cy] == target else { continue }
            grid[cx, cy] = newColor
            stack += [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
        }
    }

    // MARK: - Herramientas

    private var toolsColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREA TU ARMA")
                .font(Theme.font(16, weight: .black))
                .foregroundStyle(Color(hex: 0xC879F2))
            ForEach(Tool.allCases, id: \.self) { t in
                Button(t.rawValue) { tool = t }
                    .buttonStyle(.pixel(tool == t ? Theme.gold : Theme.panelLight, text: tool == t ? .black : Theme.text, size: 11))
            }
            Button(mirror ? "⇋ Simetría: SÍ" : "⇋ Simetría: NO") { mirror.toggle() }
                .buttonStyle(.pixel(mirror ? Color(hex: 0xC879F2) : Theme.panelLight, text: mirror ? .black : Theme.text, size: 11))
            HStack(spacing: 6) {
                Button("↶") {
                    if let last = undoStack.popLast() { grid = last }
                }
                .buttonStyle(.pixel(Theme.panelLight, size: 12))
                .disabled(undoStack.isEmpty)
                Button("Vaciar") {
                    undoStack.append(grid)
                    grid = PixelGrid(width: grid.width, height: grid.height)
                }
                .buttonStyle(.pixel(Theme.panelLight, size: 11))
            }
            Button("Diseño generado") {
                undoStack.append(grid)
                grid = Self.generated(for: item)
            }
            .buttonStyle(.pixel(Theme.panelLight, size: 10))
            Spacer(minLength: 0)
        }
    }

    private var previewColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 4), count: 6), spacing: 4) {
                ForEach(Self.palette, id: \.self) { c in
                    Rectangle()
                        .fill(Color(hex: c))
                        .frame(width: 22, height: 22)
                        .overlay(Rectangle().strokeBorder(c == color ? Theme.gold : Color.black, lineWidth: c == color ? 3 : 1))
                        .onTapGesture {
                            color = c
                            if tool == .eraser || tool == .picker { tool = .pencil }
                        }
                }
            }
            Text("VISTA PREVIA").font(Theme.font(9)).foregroundStyle(Theme.textDim)
            HStack(alignment: .bottom, spacing: 10) {
                PixelImage(image: grid.makeCGImage(), scale: 3)
                PixelImage(image: grid.makeCGImage(), scale: 1.5)
            }
            Text(item.name)
                .font(Theme.font(10, weight: .black))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button("✓ GUARDAR DIBUJO") {
                store.setCustomSprite(grid.customSprite, for: item.id)
                onClose()
            }
            .buttonStyle(.pixel(Theme.green, text: .black, size: 12))
            .disabled(grid.pixels.allSatisfy { $0 == nil })
            Button("Usar el diseño generado") {
                store.setCustomSprite(nil, for: item.id)
                onClose()
            }
            .buttonStyle(.pixel(Theme.panelLight, size: 10))
        }
    }
}
