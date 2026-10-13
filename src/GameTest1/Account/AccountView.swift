import GameCore
import SwiftUI

// Pantalla de cuenta (iniciar sesión / crear cuenta / jugar sin cuenta), como panel encima de la
// selección y la creación de personaje. Estilo pixel, botones grandes para el dedo.

// MARK: - Botón de la selección de personaje

/// "👤 CUENTA · Sin cuenta" / "Conectado como X". Si la app no tiene `AccountManager`, no se dibuja.
struct AccountButton: View {
    @Environment(AccountManager.self) private var account: AccountManager?
    var compact = false
    let action: () -> Void

    var body: some View {
        if let account {
            Button(action: action) {
                if compact {
                    Text(account.username == nil ? "👤 CUENTA" : "👤 \(account.username ?? "")")
                        .lineLimit(1)
                } else {
                    HStack(spacing: 8) {
                        Text("👤").font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CUENTA").font(Theme.font(9, weight: .black)).foregroundStyle(Theme.textDim)
                            Text(account.statusLine)
                                .font(Theme.font(11, weight: .black))
                                .foregroundStyle(account.username == nil ? Theme.text : Theme.green)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 0)
                        if account.syncStatus == .syncing {
                            Text("⟳").foregroundStyle(Theme.gold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.pixel(Theme.panelLight, size: compact ? 12 : 11, minHeight: 44))
        }
    }
}

extension View {
    /// Panel de cuenta por encima de la pantalla.
    func accountPanel(isPresented: Binding<Bool>) -> some View {
        overlay {
            if isPresented.wrappedValue {
                AccountPanel { isPresented.wrappedValue = false }
            }
        }
    }
}

// MARK: - Panel

struct AccountPanel: View {
    @Environment(AccountManager.self) private var account: AccountManager?
    @Environment(RemoteConfig.self) private var remoteConfig: RemoteConfig?
    @Environment(GameStore.self) private var store
    let close: () -> Void

    private enum Mode { case signIn, signUp }
    @State private var mode: Mode = .signIn
    @State private var username = ""
    @State private var password = ""
    @State private var repeatPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { if account?.isBusy != true { close() } }
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 12) {
                        header
                        if let account {
                            if !account.isConfigured {
                                notConfigured(account)
                            } else if let name = account.username {
                                signedIn(account, name: name)
                            } else {
                                signedOut(account)
                            }
                        }
                        if let line = remoteConfig?.statusLine {
                            note(line, color: Theme.textDim.opacity(0.7), size: 9)
                        }
                    }
                    .padding(16)
                    .frame(width: min(460, geo.size.width - 24))
                    .pixelPanel()
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    .padding(.vertical, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("CUENTA")
                .font(Theme.font(20, weight: .black))
                .foregroundStyle(Theme.gold)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            Spacer()
            Button("✕") { close() }
                .buttonStyle(.pixel(Theme.panelLight, size: 14, minHeight: 44))
                .disabled(account?.isBusy == true)
        }
    }

    // MARK: Sin configuración

    private func notConfigured(_ account: AccountManager) -> some View {
        VStack(spacing: 10) {
            note("Las cuentas todavía no están activadas en esta versión del juego.")
            note("Puedes jugar igual: tus personajes se guardan en este dispositivo.", color: Theme.textDim)
            if case .invalid(let problem) = account.configuration {
                note("Configuración: \(problem.message)", color: Theme.orange, size: 10)
            }
            note("(Para activarlas: backend/README.md)", color: Theme.textDim.opacity(0.7), size: 9)
            playLocalButton
        }
    }

    // MARK: Sesión iniciada

    private func signedIn(_ account: AccountManager, name: String) -> some View {
        VStack(spacing: 10) {
            Text("Conectado como")
                .font(Theme.font(11, weight: .bold))
                .foregroundStyle(Theme.textDim)
            Text(name.uppercased())
                .font(Theme.font(22, weight: .black))
                .foregroundStyle(Theme.green)
            syncLine(account)
            if account.charactersOverLimit > 0 {
                note("\(account.charactersOverLimit) personaje(s) no caben en la cuenta (máximo \(Roster.maxCharacters)) y se quedan solo en este dispositivo.",
                     color: Theme.orange, size: 10)
            }
            if account.unreadableCharacters > 0 {
                note("Hay \(account.unreadableCharacters) personaje(s) en la nube de una versión más nueva del juego.",
                     color: Theme.orange, size: 10)
            }
            HStack(spacing: 10) {
                Button("⟳ SINCRONIZAR") { Task { await account.syncNow() } }
                    .buttonStyle(.pixel(Theme.blue, text: .black, size: 13, minHeight: 48))
                    .disabled(account.isBusy || account.syncStatus == .syncing)
                Button("CERRAR SESIÓN") { Task { await account.signOut() } }
                    .buttonStyle(.pixel(Theme.panel, text: Theme.red, size: 13, minHeight: 48))
                    .disabled(account.isBusy)
            }
            note("Al cerrar sesión, tus personajes siguen en este dispositivo y en la nube.", color: Theme.textDim, size: 9)
            Button("▶ VOLVER AL JUEGO") { close() }
                .buttonStyle(.pixel(Color(hex: 0x2E8A44), text: .white, size: 15, minHeight: 48))
                .disabled(account.isBusy)
        }
    }

    private func syncLine(_ account: AccountManager) -> some View {
        let (text, color): (String, Color) = switch account.syncStatus {
        case .idle: ("Personajes guardados en este dispositivo.", Theme.textDim)
        case .syncing: ("⟳ Sincronizando…", Theme.gold)
        case .synced(let date): ("✓ Guardado en la nube · \(date.formatted(date: .omitted, time: .shortened))", Theme.green)
        case .failed(let message): ("⚠ \(message)", Theme.orange)
        }
        return note(text, color: color, size: 11)
    }

    // MARK: Sin sesión

    private func signedOut(_ account: AccountManager) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                modeButton("INICIAR SESIÓN", .signIn)
                modeButton("CREAR CUENTA", .signUp)
            }
            field("USUARIO", text: $username, secure: false)
            field("CONTRASEÑA", text: $password, secure: true)
            if mode == .signUp {
                field("REPETIR CONTRASEÑA", text: $repeatPassword, secure: true)
                note("Usuario: 3-20 letras sin acentos, números o _. Contraseña: 8 caracteres o más. Apúntala: de momento no se puede recuperar.",
                     color: Theme.textDim, size: 9)
                if !store.roster.characters.isEmpty {
                    note("Tus personajes de este dispositivo se guardarán en la cuenta.", color: Theme.textDim, size: 9)
                }
            }
            if let errorMessage {
                note(errorMessage, color: Theme.red, size: 11)
            }
            Button {
                submit(account)
            } label: {
                Text(account.isBusy ? "…" : (mode == .signIn ? "▶ ENTRAR" : "✚ CREAR CUENTA"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pixel(Color(hex: 0xB01A1A), text: Theme.gold, size: 16, minHeight: 50))
            .disabled(account.isBusy)
            playLocalButton
        }
    }

    private func modeButton(_ title: String, _ value: Mode) -> some View {
        Button {
            mode = value
            errorMessage = nil
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.pixel(mode == value ? Theme.gold : Theme.panelLight, text: mode == value ? .black : Theme.text, size: 12, minHeight: 44))
    }

    private func field(_ title: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(Theme.font(9, weight: .black)).foregroundStyle(Theme.textDim)
            Group {
                if secure {
                    SecureField("", text: text)
                    #if os(iOS)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                    #endif
                } else {
                    TextField("", text: text)
                    #if os(iOS)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                    #endif
                }
            }
            .autocorrectionDisabled()
            .textFieldStyle(.plain)
            .font(Theme.font(16, weight: .black))
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(Color.black.opacity(0.7))
            .overlay(Rectangle().strokeBorder(Theme.gold, lineWidth: 2))
            .onChange(of: text.wrappedValue) { _, _ in errorMessage = nil }
            .onSubmit { if let account { submit(account) } }
        }
    }

    private var playLocalButton: some View {
        Button {
            close()
        } label: {
            VStack(spacing: 1) {
                Text("JUGAR SIN CUENTA")
                Text("Se guarda solo en este dispositivo").font(Theme.font(9, weight: .bold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pixel(Theme.panelLight, size: 13, minHeight: 48))
        .disabled(account?.isBusy == true)
    }

    private func note(_ text: String, color: Color = Theme.text, size: CGFloat = 12) -> some View {
        Text(text)
            .font(Theme.font(size, weight: .bold))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }

    // MARK: Acciones

    private func submit(_ account: AccountManager) {
        guard !account.isBusy else { return }
        if mode == .signUp, password != repeatPassword {
            errorMessage = "Las contraseñas no coinciden."
            return
        }
        let name = username
        let secret = password
        Task {
            let error = mode == .signIn
                ? await account.signIn(username: name, password: secret)
                : await account.signUp(username: name, password: secret)
            if let error {
                errorMessage = error
            } else {
                password = ""
                repeatPassword = ""
                close()
            }
        }
    }
}
