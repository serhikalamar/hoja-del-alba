import CoreGraphics

// CONTRATO: la tienda (`ForgeShopView`) usa `Pose`, `width`, `height`, `counterLine` y `grid(_:)`.
// El `pixel-artist` puede rehacer todo el interior, pero no estas firmas.

/// El herrero enano de la tienda: grande, de frente, detrás del mostrador y mirando al jugador.
/// Busto de medio cuerpo: casco de acero con gafas de forja, cejas pobladas, nariz enorme, barba
/// trenzada con anillas, delantal de cuero con remaches y quemaduras, guantes y martillo de forja.
/// Luz arriba-izquierda y contraluz naranja de la fragua que tiene detrás.
/// Piezas: `+Paint` (utilidades y rampas), `+Head` (casco, cara, barba), `+Body` (torso, brazos, martillo).
enum DwarfSmithArt {
    enum Pose: CaseIterable {
        /// Respira (alterna con `idle1`).
        case idle0, idle1
        /// Parpadea.
        case blink
        /// Habla (boca abierta).
        case talk
        /// Martillo arriba / abajo (golpea el yunque o el mostrador).
        case hammerUp, hammerDown
        /// Contento: le acabas de comprar algo.
        case happy
    }

    /// Lienzo fijo (pixeles de arte, ya contorneado) igual para todas las poses.
    static let width = 80
    static let height = 88
    /// Filas desde abajo que quedan tapadas por el mostrador (el enano se apoya en él).
    static let counterLine = 22

    static func grid(_ pose: Pose) -> PixelGrid {
        var p = Painter(width: innerW, height: innerH)
        let breath = pose == .idle1 ? 1 : 0
        // Torso (respira: baja 1 px en `idle1`).
        p.dy = breath
        drawTorso(&p)
        // Antebrazos (quietos, apoyados en el mostrador); el codo queda bajo la manga.
        p.dy = 0
        drawForearm(&p, ex: 11, ey: 46, wx: 14, wy: 57.5, bias: 0.05)
        switch pose {
        case .hammerUp: break
        case .hammerDown: drawForearm(&p, ex: mirror(11), ey: 45, wx: 62, wy: 52, bias: -0.05)
        default: drawForearm(&p, ex: mirror(11), ey: 46, wx: mirror(14), wy: 57.5, bias: -0.05)
        }
        // Mangas y cabeza (respiran).
        p.dy = breath
        drawUpperArm(&p, side: -1)
        drawUpperArm(&p, side: 1)
        drawHead(&p, pose: pose)
        // Manos y martillo.
        p.dy = 0
        drawFist(&p, cx: 15, cy: 61.5, thumbRight: true, bias: 0.05)
        switch pose {
        case .hammerUp:
            drawForearm(&p, ex: 66.5, ey: 47, wx: 64.5, wy: 29, bias: -0.05, ra: 5.6, rb: 4.6)
            drawHammer(&p, cx: 64, headY: 1, gripY: 28, faceRight: true)
            drawFist(&p, cx: 64.5, cy: 24.5, thumbRight: false, bias: 0)
        case .hammerDown:
            drawHammer(&p, cx: 59, headY: 54, gripY: 52, faceRight: true)
            drawFist(&p, cx: 60, cy: 53, thumbRight: false, bias: 0)
            drawSpark(&p, x: 70, y: 60)
        default:
            drawHammer(&p, cx: 63, headY: 32, gripY: 60, faceRight: true)
            drawFist(&p, cx: mirror(15), cy: 61.5, thumbRight: false, bias: -0.05)
        }
        p.forgeRim(maxY: hiddenRow)
        return p.g.outlined()
    }
}
