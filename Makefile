.PHONY: project open test build mac clean

# Genera GameTest1.xcodeproj a partir de project.yml
project:
	xcodegen generate

# Abre el proyecto en Xcode (lo genera si hace falta)
open: project
	open GameTest1.xcodeproj

# Tests de la lógica del juego (no necesitan Xcode, solo las Command Line Tools)
test:
	cd Packages/GameCore && swift test

# Compila la app para el simulador (necesita Xcode instalado)
build: project
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1 \
		-destination 'generic/platform=iOS Simulator' build

# Compila y abre la versión de Mac (WASD + ratón)
mac: project
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1Mac \
		-destination 'platform=macOS' -derivedDataPath build/mac build
	open build/mac/Build/Products/Debug/GameTest1.app

clean:
	rm -rf GameTest1.xcodeproj Packages/GameCore/.build build DerivedData
