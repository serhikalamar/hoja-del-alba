#if os(macOS)
import AppKit

/// Movimiento con teclado en Mac: WASD o flechas. Escape pausa/reanuda.
final class KeyboardMovement {
    private enum Key {
        static let w: UInt16 = 13, a: UInt16 = 0, s: UInt16 = 1, d: UInt16 = 2
        static let up: UInt16 = 126, left: UInt16 = 123, down: UInt16 = 125, right: UInt16 = 124
        static let escape: UInt16 = 53
        static let movement: Set<UInt16> = [w, a, s, d, up, left, down, right]
    }

    var onChange: (CGVector) -> Void = { _ in }
    var onEscape: () -> Void = {}

    private var monitor: Any?
    private var resignObserver: NSObjectProtocol?
    private var pressed = Set<UInt16>()

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            return self.handle(event)
        }
        // Si la ventana pierde el foco no recibimos keyUp: soltamos todo.
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.releaseAll()
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        monitor = nil
        resignObserver = nil
        releaseAll()
    }

    private func releaseAll() {
        pressed.removeAll()
        onChange(.zero)
    }

    /// Devuelve `nil` para las teclas que consumimos (evita el pitido del sistema).
    private func handle(_ event: NSEvent) -> NSEvent? {
        if event.modifierFlags.contains(.command) { return event }
        if event.keyCode == Key.escape {
            if event.type == .keyDown && !event.isARepeat { onEscape() }
            return nil
        }
        guard Key.movement.contains(event.keyCode) else { return event }
        if event.type == .keyDown {
            pressed.insert(event.keyCode)
        } else {
            pressed.remove(event.keyCode)
        }
        onChange(direction)
        return nil
    }

    private var direction: CGVector {
        var dx: CGFloat = 0, dy: CGFloat = 0
        if pressed.contains(Key.w) || pressed.contains(Key.up) { dy += 1 }
        if pressed.contains(Key.s) || pressed.contains(Key.down) { dy -= 1 }
        if pressed.contains(Key.d) || pressed.contains(Key.right) { dx += 1 }
        if pressed.contains(Key.a) || pressed.contains(Key.left) { dx -= 1 }
        let length = hypot(dx, dy)
        return length > 0 ? CGVector(dx: dx / length, dy: dy / length) : .zero
    }
}
#endif
