import CoreGraphics

// CONTRATO: la tienda (`ForgeShopView`) usa estas funciones. El `environment-artist` puede rehacer todo
// el interior, pero no las firmas. Todo en pixeles de arte (la tienda los muestra a 3 puntos por pixel).
//
// Composición por capas ancladas (funciona con cualquier ancho y alto):
// - la línea del suelo (`ForgeGeo.floorY`) va a una altura fija desde abajo; todo se apoya en ella;
// - la fragua (boca en arco, campana y chimenea) se centra en `focusX`, detrás del enano;
// - a su derecha: fuelle, tablero de herramientas, yunque, tina, carbón y baldas con lingotes y minerales;
// - más a la derecha (bajo los paneles de la tienda): pared más tranquila con armas, escudos y piezas,
//   en módulos que se repiten (con variaciones) hasta llenar el ancho.
// - la luz se hornea al final (`ForgeLayer.lit`): cálida desde la fragua, fría del ventanuco.
// Ficheros: +Canvas (lienzo y luz), +Room (pared, vigas, suelo), +Forge (fragua y su rincón),
// +Wall (armas, estanterías, ventanuco), +Counter (mostrador y chispas).

/// La forja del enano vista desde el mostrador: el jugador mira al enano y, detrás de él, la fragua.
enum ForgeBackdropArt {
    /// Fondo completo (sin el enano). `focusX` es la columna donde estará el centro del enano: detrás de él
    /// va la fragua encendida; a los lados, paredes de piedra con armas, piezas y herramientas colgadas,
    /// estanterías, fuelle, barriles, carbón… La parte de la derecha quedará tapada en parte por los paneles de la tienda.
    static func backdrop(width: Int, height: Int, focusX: Int) -> PixelGrid {
        let g = ForgeGeo(w: width, h: height, f: focusX)
        var L = ForgeLayer(width, height)
        drawWall(&L, g)
        drawFloor(&L, g)
        drawBeams(&L, g)
        drawArmoryWall(&L, g)
        drawForgeCorner(&L, g)
        drawForge(&L, g)
        drawFloorProps(&L, g)
        return L.lit(lights: lights(g), ambient: (0.46, 0.42, 0.5))
    }

    /// Alto del mostrador.
    static let counterHeight = 26

    /// Mostrador de madera delante del enano, tan ancho como `width`.
    static func counter(width: Int) -> PixelGrid { drawCounter(width: width) }

    /// Brasas y chispas que suben de la fragua (capa transparente encima del fondo, del mismo tamaño).
    /// Incluye las lenguas de fuego de la boca de la fragua y el vapor de la tina (cambian en cada frame).
    static let emberFrames = 6

    static func embers(width: Int, height: Int, focusX: Int, frame: Int) -> PixelGrid {
        drawEmbers(ForgeGeo(w: width, h: height, f: focusX), frame: ((frame % emberFrames) + emberFrames) % emberFrames)
    }

    /// Luces horneadas de la escena.
    static func lights(_ g: ForgeGeo) -> [ForgeLight] {
        var list = [
            // La fragua: gran luz cálida que lo baña todo y se apaga hacia los rincones.
            ForgeLight(x: Double(g.f), y: Double(g.fireY), radius: 240, power: 1.15, color: (1.25, 0.8, 0.45), squash: 0.8),
            // Calor cercano: la boca, la campana y el suelo de delante se ponen naranjas.
            ForgeLight(x: Double(g.f), y: Double(g.fireY + 4), radius: 85, power: 0.8, color: (1.3, 0.75, 0.32)),
        ]
        // Luz fría del ventanuco.
        list.append(ForgeLight(x: Double(g.windowX + 10), y: Double(g.floorY - 60), radius: 52, power: 0.65,
                               color: (0.45, 0.7, 1.15), squash: 1.4))
        // Farolillos colgados de la parte de la derecha.
        for x in g.lanternXs {
            list.append(ForgeLight(x: Double(x), y: Double(g.floorY - 58), radius: 44, power: 0.55, color: (1.2, 0.85, 0.5)))
        }
        if let c = g.chandelier {
            list.append(ForgeLight(x: Double(c.x), y: Double(c.y - 2), radius: 60, power: 0.55, color: (1.2, 0.9, 0.55)))
        }
        return list
    }
}

/// Medidas de la escena, compartidas por el fondo y las chispas.
struct ForgeGeo {
    let w: Int
    let h: Int
    /// Centro del enano (y de la fragua).
    let f: Int

    /// Línea entre la pared del fondo y el suelo.
    var floorY: Int { h - 38 }
    /// Viga maestra (parte de arriba).
    var beamY: Int { floorY - 95 }
    /// Cuerpo de ladrillo de la fragua.
    var bodyX0: Int { f - 50 }
    var bodyX1: Int { f + 50 }
    var bodyTop: Int { floorY - 62 }
    /// Boca en arco: jambas, arranque del arco y clave.
    var mouthHalf: Int { 29 }
    var springY: Int { floorY - 44 }
    var crownY: Int { floorY - 56 }
    /// Repisa de piedra bajo la boca (arriba de la repisa).
    var ledgeY: Int { floorY - 26 }
    /// Centro del fuego.
    var fireY: Int { floorY - 34 }
    /// Campana de humos.
    var hoodTop: Int { floorY - 88 }

    /// Rincón de trabajo a la derecha de la fragua.
    var bellowsX: Int { f + 55 }
    var shelfX: Int { f + 86 }
    var postX: Int { f + 138 }
    var windowX: Int { f + 152 }
    /// Inicio de los módulos de armas que se repiten.
    var armoryX: Int { f + 194 }
    static let moduleWidth = 80
    /// Rueda de velas en lo alto, si sobra pared por encima de la viga maestra.
    var chandelier: (x: Int, y: Int)? { beamY >= 34 ? (f + 112, beamY - 16) : nil }
    var lanternXs: [Int] {
        var xs: [Int] = []
        var x = armoryX + ForgeGeo.moduleWidth - 1  // delante de los pies derechos
        var i = 0
        while x < w + 20 { if i % 2 == 0 { xs.append(x) }; x += ForgeGeo.moduleWidth; i += 1 }
        return xs
    }
}

/// Dónde va cada cosa en la escena de la tienda (lo comparten la vista y el banco de pruebas).
enum ForgeShopLayout {
    /// Puntos de pantalla por pixel de arte en la tienda.
    static let scale: CGFloat = 3
    /// Ancho (en puntos) de la zona del enano, a la izquierda.
    static func dwarfAreaWidth(screenWidth: CGFloat) -> CGFloat { min(320, max(230, screenWidth * 0.34)) }
    static func dwarfCenterX(artWidth: Int) -> Int {
        Int(dwarfAreaWidth(screenWidth: CGFloat(artWidth) * scale) / scale / 2)
    }
    static func counterWidth(artWidth: Int) -> Int {
        Int(dwarfAreaWidth(screenWidth: CGFloat(artWidth) * scale) / scale)
    }
}
