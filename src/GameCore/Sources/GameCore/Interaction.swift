import Foundation

// MARK: - Hablar con un NPC tocándolo
//
// Los aldeanos, prisioneros, pistas y el Capitán ya no hablan al acercarse: se tocan (iPhone) o se pulsan (Mac).
// - Si el héroe está a `reachTiles` casillas o menos, habla al momento.
// - Si está más lejos, camina hasta él por las casillas (`TilePathfinder`, sin atravesar muros ni pisar puertas,
//   salidas o bajadas) y habla al llegar. Mover el joystick o las teclas cancela el paseo.
// Siguen por proximidad: puertas, salidas `>`, bajadas `e`, casillas cerradas por la historia y recoger el botín.
// Las distancias van en cualquier unidad (puntos de la escena) con el tamaño de casilla al lado.

/// Caja táctil de un NPC: el centro de su dibujo y su medio ancho y medio alto (misma unidad que el toque).
public struct NPCHitBox: Equatable, Sendable {
    public let id: String
    public let centerX: Double
    public let centerY: Double
    public let halfWidth: Double
    public let halfHeight: Double

    public init(id: String, centerX: Double, centerY: Double, halfWidth: Double, halfHeight: Double) {
        self.id = id
        self.centerX = centerX
        self.centerY = centerY
        self.halfWidth = halfWidth
        self.halfHeight = halfHeight
    }
}

/// Qué hacer al tocar a un NPC.
public enum NPCTapDecision: Equatable, Sendable {
    /// Está al alcance: se habla ya.
    case talk
    /// Está lejos pero se puede llegar: el héroe camina hasta él.
    case walk
    /// No hay camino (detrás de un muro, en otra sala): no pasa nada.
    case unreachable
}

public enum NPCInteraction {
    /// Distancia de pies a pies (en casillas) a la que se habla sin caminar. Es también la del indicador "…".
    public static let reachTiles: Double = 2
    /// Margen alrededor del dibujo del NPC para el dedo (en casillas, por cada lado).
    public static let touchSlopTiles: Double = 0.5

    /// ¿Está el héroe al alcance para hablar? `dx`/`dy`: de los pies del héroe a los del NPC.
    public static func isInReach(dx: Double, dy: Double, tileSize: Double) -> Bool {
        (dx * dx + dy * dy).squareRoot() <= reachTiles * tileSize
    }

    /// El NPC tocado: aquel cuya caja (agrandada con `touchSlopTiles`) contiene el toque; si hay varios,
    /// el de centro más cercano. nil si el toque no cae sobre ninguno.
    public static func pick(x: Double, y: Double, among boxes: [NPCHitBox], tileSize: Double) -> String? {
        let slop = touchSlopTiles * tileSize
        return boxes
            .filter { abs(x - $0.centerX) <= $0.halfWidth + slop && abs(y - $0.centerY) <= $0.halfHeight + slop }
            .min { hypot(x - $0.centerX, y - $0.centerY) < hypot(x - $1.centerX, y - $1.centerY) }?
            .id
    }

    /// El más cercano de los que están al alcance (tecla de acción en Mac). `distances`: id → distancia de pies a pies.
    public static func closestInReach(_ distances: [(id: String, distance: Double)], tileSize: Double) -> String? {
        distances.filter { $0.distance <= reachTiles * tileSize }.min { $0.distance < $1.distance }?.id
    }

    /// Hablar, caminar o nada.
    public static func decide(distance: Double, tileSize: Double, hasPath: Bool) -> NPCTapDecision {
        if distance <= reachTiles * tileSize { return .talk }
        return hasPath ? .walk : .unreachable
    }

    /// Casillas desde las que se puede hablar con un NPC que está en `npc` (centro a centro, con margen para que
    /// al llegar al centro de la casilla ya se esté al alcance).
    public static func isTalkTile(_ p: TilePoint, npc: TilePoint) -> Bool {
        let dx = Double(p.x - npc.x), dy = Double(p.y - npc.y)
        return (dx * dx + dy * dy).squareRoot() <= reachTiles - 0.5
    }
}

// MARK: - Camino por casillas

public enum TilePathfinder {
    /// Camino más corto (8 direcciones, sin cortar esquinas de muros) desde `start` hasta la primera casilla que cumpla
    /// `isGoal`. Incluye la casilla de salida y la de llegada; `[start]` si ya se está en una meta; nil si no hay camino.
    /// `start` se acepta aunque no sea `passable` (el héroe puede estar pisando el borde de un muro o una puerta).
    public static func path(from start: TilePoint, isGoal: (TilePoint) -> Bool, passable: (TilePoint) -> Bool,
                            maxNodes: Int = 6000) -> [TilePoint]? {
        if isGoal(start) { return [start] }
        var cost: [TilePoint: Double] = [start: 0]
        var parent: [TilePoint: TilePoint] = [:]
        var heap = MinHeap()
        heap.push(0, start)
        var visited = 0
        let steps: [(Int, Int, Double)] = [(1, 0, 1), (-1, 0, 1), (0, 1, 1), (0, -1, 1),
                                           (1, 1, 1.4142), (1, -1, 1.4142), (-1, 1, 1.4142), (-1, -1, 1.4142)]
        while let (c, p) = heap.pop() {
            guard c <= cost[p] ?? .infinity else { continue }
            if isGoal(p) {
                var out = [p]
                var cur = p
                while let prev = parent[cur] { out.append(prev); cur = prev }
                return out.reversed()
            }
            visited += 1
            if visited > maxNodes { return nil }
            for (dx, dy, w) in steps {
                let n = TilePoint(p.x + dx, p.y + dy)
                guard passable(n) else { continue }
                // En diagonal, las dos casillas de al lado deben estar libres (no se corta la esquina de un muro).
                if dx != 0 && dy != 0, !passable(TilePoint(p.x + dx, p.y)) || !passable(TilePoint(p.x, p.y + dy)) { continue }
                let next = c + w
                if next < cost[n] ?? .infinity {
                    cost[n] = next
                    parent[n] = p
                    heap.push(next, n)
                }
            }
        }
        return nil
    }

    /// Montículo mínimo de (coste, casilla).
    private struct MinHeap {
        private var items: [(Double, TilePoint)] = []

        mutating func push(_ cost: Double, _ p: TilePoint) {
            items.append((cost, p))
            var i = items.count - 1
            while i > 0 {
                let parent = (i - 1) / 2
                guard items[i].0 < items[parent].0 else { break }
                items.swapAt(i, parent)
                i = parent
            }
        }

        mutating func pop() -> (Double, TilePoint)? {
            guard !items.isEmpty else { return nil }
            items.swapAt(0, items.count - 1)
            let top = items.removeLast()
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var m = i
                if l < items.count, items[l].0 < items[m].0 { m = l }
                if r < items.count, items[r].0 < items[m].0 { m = r }
                if m == i { break }
                items.swapAt(i, m)
                i = m
            }
            return top
        }
    }
}

extension AreaMap {
    /// Casilla por la que el héroe puede pasar caminando solo (paseo hasta un NPC): se pisa y no es una puerta,
    /// una salida `>`, una bajada `e` ni la puerta `D` de un interior (esas llevan a otra área).
    public func isStrollable(_ p: TilePoint) -> Bool {
        guard p.x >= 0, p.y >= 0, p.x < width, p.y < height, isWalkable(p) else { return false }
        if building(at: p) != nil { return false }
        if exit(at: p) != nil || dungeonEntrance(at: p) != nil { return false }
        switch tile(p.x, p.y) {
        case .exit, .areaExit, .cave: return false
        default: return true
        }
    }
}
