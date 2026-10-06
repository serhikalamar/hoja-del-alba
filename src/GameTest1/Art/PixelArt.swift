import CoreGraphics
import Foundation
import GameCore
import SpriteKit
import SwiftUI

/// Tamaño en puntos de un pixel de arte dentro de la escena.
let PX: CGFloat = 2

/// Sprite definido como filas de caracteres; cada carácter es un color de la paleta.
/// Los caracteres que no están en la paleta ('.') son transparentes.
struct PixelSprite {
    var rows: [String]
    var palette: [Character: UInt32]

    var width: Int { rows.map(\.count).max() ?? 0 }
    var height: Int { rows.count }

    func recolored(_ changes: [Character: UInt32]) -> PixelSprite {
        PixelSprite(rows: rows, palette: palette.merging(changes) { _, new in new })
    }

    /// Sustituye las filas a partir de `start` (para frames de animación).
    func replacingRows(from start: Int, with newRows: [String]) -> PixelSprite {
        var copy = self
        for (offset, row) in newRows.enumerated() where start + offset < copy.rows.count {
            copy.rows[start + offset] = row
        }
        return copy
    }

    func makeCGImage() -> CGImage {
        let w = width, h = height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        for (y, row) in rows.enumerated() {
            for (x, char) in row.enumerated() {
                guard let color = palette[char] else { continue }
                let i = (y * w + x) * 4
                pixels[i] = UInt8((color >> 16) & 0xFF)
                pixels[i + 1] = UInt8((color >> 8) & 0xFF)
                pixels[i + 2] = UInt8(color & 0xFF)
                pixels[i + 3] = 255
            }
        }
        return PixelCanvas.image(width: w, height: h, pixels: pixels)
    }
}

/// Lienzo de colores para componer sprites por capas (cuerpo + accesorios) y añadir contorno.
struct PixelGrid {
    var width: Int
    var height: Int
    var pixels: [UInt32?]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = Array(repeating: nil, count: width * height)
    }

    init(_ sprite: PixelSprite) {
        self.init(width: sprite.width, height: sprite.height)
        draw(sprite, x: 0, y: 0)
    }

    init(custom: CustomSprite) {
        self.init(width: custom.width, height: custom.height)
        for (i, value) in custom.pixels.enumerated() where value >= 0 {
            pixels[i] = UInt32(value)
        }
    }

    subscript(x: Int, y: Int) -> UInt32? {
        get { x >= 0 && y >= 0 && x < width && y < height ? pixels[y * width + x] : nil }
        set { if x >= 0 && y >= 0 && x < width && y < height { pixels[y * width + x] = newValue } }
    }

    /// Dibuja un sprite encima. `flipX` lo refleja horizontalmente.
    mutating func draw(_ sprite: PixelSprite, x ox: Int, y oy: Int, flipX: Bool = false) {
        let w = sprite.width
        for (y, row) in sprite.rows.enumerated() {
            for (x, char) in row.enumerated() {
                guard let color = sprite.palette[char] else { continue }
                self[ox + (flipX ? w - 1 - x : x), oy + y] = color
            }
        }
    }

    mutating func draw(_ grid: PixelGrid, x ox: Int, y oy: Int) {
        for y in 0..<grid.height {
            for x in 0..<grid.width {
                if let color = grid[x, y] { self[ox + x, oy + y] = color }
            }
        }
    }

    /// Añade un contorno de 1 pixel alrededor de lo opaco (agranda 1 px por lado).
    func outlined(_ color: UInt32 = 0x1A1C2C) -> PixelGrid {
        var out = PixelGrid(width: width + 2, height: height + 2)
        out.draw(self, x: 1, y: 1)
        for y in 0..<out.height {
            for x in 0..<out.width where out[x, y] == nil {
                let neighbours = [self[x - 2, y - 1], self[x, y - 1], self[x - 1, y - 2], self[x - 1, y]]
                if neighbours.contains(where: { $0 != nil }) { out[x, y] = color }
            }
        }
        return out
    }

    /// Desplaza el contenido (para frames de animación).
    func shifted(dx: Int, dy: Int) -> PixelGrid {
        var out = PixelGrid(width: width, height: height)
        out.draw(self, x: dx, y: dy)
        return out
    }

    var customSprite: CustomSprite {
        CustomSprite(width: width, height: height, pixels: pixels.map { $0.map(Int.init) ?? -1 })
    }

    func makeCGImage() -> CGImage {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for (i, value) in pixels.enumerated() {
            guard let color = value else { continue }
            bytes[i * 4] = UInt8((color >> 16) & 0xFF)
            bytes[i * 4 + 1] = UInt8((color >> 8) & 0xFF)
            bytes[i * 4 + 2] = UInt8(color & 0xFF)
            bytes[i * 4 + 3] = 255
        }
        return PixelCanvas.image(width: max(1, width), height: max(1, height), pixels: bytes)
    }
}

enum PixelCanvas {
    /// Crea un CGImage RGBA a partir de bytes (alfa 0 o 255).
    static func image(width: Int, height: Int, pixels: [UInt8]) -> CGImage {
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}

/// Caché de imágenes y texturas por clave. Solo se usa desde el hilo principal.
enum ArtCache {
    private static var images: [String: CGImage] = [:]
    private static var textures: [String: SKTexture] = [:]

    static func image(_ key: String, _ build: () -> PixelSprite) -> CGImage {
        if let cached = images[key] { return cached }
        let image = build().makeCGImage()
        images[key] = image
        return image
    }

    static func texture(_ key: String, _ build: () -> PixelSprite) -> SKTexture {
        if let cached = textures[key] { return cached }
        let texture = SKTexture(cgImage: image(key, build))
        texture.filteringMode = .nearest
        textures[key] = texture
        return texture
    }

    static func image(_ key: String, grid build: () -> PixelGrid) -> CGImage {
        if let cached = images[key] { return cached }
        let image = build().makeCGImage()
        images[key] = image
        return image
    }

    static func texture(_ key: String, grid build: () -> PixelGrid) -> SKTexture {
        if let cached = textures[key] { return cached }
        let texture = SKTexture(cgImage: image(key, grid: build))
        texture.filteringMode = .nearest
        textures[key] = texture
        return texture
    }

    static func texture(fromImage image: CGImage) -> SKTexture {
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .nearest
        return texture
    }
}

/// Imagen pixel-art escalada sin suavizado para SwiftUI.
struct PixelImage: View {
    let image: CGImage
    var scale: CGFloat = 3

    var body: some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .interpolation(.none)
            .frame(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
    }
}
