.PHONY: project open test build mac clean harness-link balance check-town sprites maps shots fichas verify

# Genera GameTest1.xcodeproj a partir de project.yml
project:
	xcodegen generate

# Abre el proyecto en Xcode (lo genera si hace falta)
open: project
	open GameTest1.xcodeproj

# Tests de la lógica del juego (no necesitan Xcode, solo las Command Line Tools)
test:
	cd src/GameCore && swift test

# Compila la app para el simulador (necesita Xcode instalado)
build: project
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1 \
		-destination 'generic/platform=iOS Simulator' build

# Compila y abre la versión de Mac (WASD + ratón)
mac: project
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1Mac \
		-destination 'platform=macOS' -derivedDataPath build/mac build
	open build/mac/Build/Products/Debug/GameTest1.app

# --- Banco de pruebas sin pantalla (tools/Harness) ---
HARNESS = cd tools/Harness && swift run -c release Harness

# Enlaza las fuentes de la app (salvo el punto de entrada) dentro del banco de pruebas.
harness-link:
	@rm -rf tools/Harness/Sources/Harness/App && mkdir -p tools/Harness/Sources/Harness/App
	@find $(CURDIR)/src/GameTest1 -name '*.swift' ! -name 'GameTest1App.swift' -exec ln -sf {} tools/Harness/Sources/Harness/App/ \;

# Balance de la arena: oleada en la que cae un bot con distintos equipos.
balance: harness-link
	$(HARNESS) balance

# Comprueba el flujo del pueblo (diálogos, rescates, castillo, muerte).
check-town: harness-link
	$(HARNESS) town

# Hojas de sprites, mapas y capturas en tools/Harness/output/
sprites: harness-link
	$(HARNESS) sprites
maps: harness-link
	$(HARNESS) maps
shots: harness-link
	$(HARNESS) shots

# Regenera las fichas de assets/ (razas, bestiario, aldeanos, catálogo) desde el código.
fichas: harness-link
	$(HARNESS) fichas

# Todo lo que hay que pasar antes de dar un cambio por bueno.
verify: test check-town
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1Mac -destination 'platform=macOS' -derivedDataPath build/mac build -quiet
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1 -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ios build -quiet

clean:
	rm -rf GameTest1.xcodeproj src/GameCore/.build build DerivedData tools/Harness/.build tools/Harness/output
