.PHONY: project open test build mac clean harness-link balance historia check-town check-valdemar sprites hero maps mapa-continente mapa-mundo dungeon shop shots fichas datos verify admin admin-build admin-test

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
# (No borra la carpeta: así varios agentes pueden usar el banco a la vez.)
harness-link:
	@mkdir -p tools/Harness/Sources/Harness/App
	@find tools/Harness/Sources/Harness/App -type l ! -exec test -e {} \; -delete
	@find $(CURDIR)/src/GameTest1 -name '*.swift' ! -name 'GameTest1App.swift' -exec ln -sf {} tools/Harness/Sources/Harness/App/ \;

# Balance de la arena: oleada en la que cae un bot con distintos equipos.
balance: harness-link
	$(HARNESS) balance

# Modo historia de Valdemar: un bot con equipo T1 juega el continente con combate real (nivel, muertes, oro, minerales).
historia: harness-link
	$(HARNESS) historia

# Comprueba el flujo del pueblo (diálogos, rescates, castillo, muerte).
check-town: harness-link
	$(HARNESS) town

# Comprueba el flujo del continente 1 (salidas, misiones, castillo, reaparición, mazmorras de historia).
check-valdemar: harness-link
	$(HARNESS) valdemar

# Hojas de sprites, mapas y capturas en tools/Harness/output/
sprites: harness-link
	$(HARNESS) sprites
hero: harness-link
	$(HARNESS) hero
maps: harness-link
	$(HARNESS) maps
# Mapa del continente de la pausa entero a PNG + tiempos de dibujo → tools/Harness/output/continente_*.png
mapa-continente: harness-link
	$(HARNESS) mapa-continente
# Mapa del mundo de la pausa (6 continentes, los futuros en gris) → tools/Harness/output/mundo*.png
mapa-mundo: harness-link
	$(HARNESS) mapa-mundo
dungeon: harness-link
	$(HARNESS) dungeon
shop: harness-link
	$(HARNESS) shop
shots: harness-link
	$(HARNESS) shots

# Regenera las fichas de assets/ (razas, bestiario, aldeanos, catálogo) desde el código.
fichas: harness-link
	$(HARNESS) fichas

# Valores base del juego en JSON para el panel web de administración (admin/public/data/; contrato en assets/admin/contrato.md).
datos: harness-link
	$(HARNESS) exportar-datos

# --- Panel web de administración (admin/; guía en admin/README.md) ---
# Servidor de desarrollo en http://localhost:5174 (sin admin/.env.local arranca en modo demo).
admin:
	cd admin && ([ -d node_modules ] || npm install) && npm run dev

# Tests de la lógica del panel + tipos + compilación en admin/dist/.
admin-build:
	cd admin && ([ -d node_modules ] || npm install) && npm test && npm run build

# Solo los tests del panel (Vitest).
admin-test:
	cd admin && ([ -d node_modules ] || npm install) && npm test

# Todo lo que hay que pasar antes de dar un cambio por bueno.
verify: test check-town check-valdemar
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1Mac -destination 'platform=macOS' -derivedDataPath build/mac build -quiet
	xcodebuild -project GameTest1.xcodeproj -scheme GameTest1 -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ios build -quiet

clean:
	rm -rf GameTest1.xcodeproj src/GameCore/.build build DerivedData tools/Harness/.build tools/Harness/output admin/dist
