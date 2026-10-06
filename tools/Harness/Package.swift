// swift-tools-version:5.10
// Banco de pruebas sin pantalla: compila el código de la app para macOS y permite simular
// partidas, medir el balance y renderizar sprites y capturas a PNG.
// Las fuentes de la app se enlazan en Sources/Harness/App con `make harness-link`.
import PackageDescription

let package = Package(
    name: "Harness",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../src/GameCore")],
    targets: [
        .executableTarget(name: "Harness", dependencies: ["GameCore"]),
    ]
)
