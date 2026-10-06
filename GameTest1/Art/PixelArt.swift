import CoreGraphics
import Foundation
import SpriteKit
import SwiftUI

/// Tamaño en puntos de un pixel de arte dentro de la escena.
let PX: CGFloat = 3

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
