import Foundation
import GameCore
import Observation
import os

/// Ajustes en vivo: la configuración que se publica desde el panel de administración (Supabase, tabla `game_config`).
///
/// - Sin Supabase configurado no hace nada (ni siquiera mira la caché): el juego usa sus valores de serie.
/// - Al abrir el juego aplica la última descargada (caché en disco) y pregunta al servidor; al volver a primer plano
///   pregunta otra vez, como mucho cada `RemoteTuningState.minimumFetchInterval`.
/// - Solo usa la clave pública (no hace falta sesión): `GET /rest/v1/rpc/published_config`.
/// - Se aplica fuera de las partidas: en la selección de personaje o justo antes de empezar una (`GameStore.beforeNewGame`).
///   Lo que llega durante una partida espera a la siguiente.
/// - Las decisiones (qué aplicar, formato demasiado nuevo, caché) están en GameCore (`RemoteTuning.swift`, con tests).
@Observable
final class RemoteConfig {
    /// Versión de los ajustes que usa el juego ahora (nil = valores de serie).
    private(set) var appliedVersion: Int?

    @ObservationIgnored private let client: SupabaseClient?
    @ObservationIgnored private let cache: RemoteTuningCache
    private var state = RemoteTuningState()
    @ObservationIgnored private weak var store: GameStore?
    @ObservationIgnored private var isFetching = false
    @ObservationIgnored private let log = Logger(subsystem: "com.sergimartinez.gametest1", category: "ajustes-en-vivo")

    init(configuration: SupabaseConfig.State = SupabaseConfig.load(),
         folder: URL = RosterStore.defaultURL().deletingLastPathComponent()) {
        self.client = configuration.settings.map { SupabaseClient(settings: $0) }
        self.cache = RemoteTuningCache(url: folder.appendingPathComponent("ajustes-en-vivo.json"))
    }

    var isEnabled: Bool { client != nil }

    /// Texto corto para la pantalla de cuenta.
    var statusLine: String? {
        guard isEnabled else { return nil }
        let target = state.targetVersion
        guard let appliedVersion else {
            return target.map { "Ajustes del juego: versión \($0) (se aplica al empezar la partida)" } ?? "Ajustes del juego: de serie"
        }
        if target != appliedVersion {
            return "Ajustes del juego: versión \(appliedVersion) (hay cambios para la siguiente partida)"
        }
        return "Ajustes del juego: versión \(appliedVersion)"
    }

    /// Al abrir la app (una vez): aplica la caché y pregunta al servidor.
    func attach(to store: GameStore) {
        guard client != nil, self.store !== store else { return }
        self.store = store
        store.beforeNewGame = { [weak self] in self?.applyPending(force: true) }
        if let cached = cache.load() {
            let response = RemoteTuningResponse.parse(cached)
            if let message = state.receive(response).message { log.info("\(message, privacy: .public) (caché)") }
            applyPending(force: false)
        }
        refresh()
    }

    /// Al volver a primer plano.
    func appBecameActive() {
        guard store != nil else { return }  // la primera descarga la hace `attach`
        refresh()
    }

    private func refresh(now: Date = Date()) {
        guard let client, !isFetching, state.shouldFetch(now: now) else { return }
        isFetching = true
        Task { @MainActor [weak self] in
            let result: Result<Data, Error>
            do {
                result = .success(try await client.publishedConfig())
            } catch {
                result = .failure(error)
            }
            self?.finishFetch(result, at: now)
        }
    }

    @MainActor
    private func finishFetch(_ result: Result<Data, Error>, at date: Date) {
        isFetching = false
        switch result {
        case .success(let body):
            state.noteFetched(at: date)
            let outcome = state.receive(RemoteTuningResponse.parse(body))
            switch outcome.cache {
            case .save: cache.save(body)
            case .delete: cache.delete()
            case .keep: break
            }
            if let message = outcome.message { log.notice("\(message, privacy: .public)") }
            applyPending(force: false)
        case .failure(let error):
            // Sin red o sin la migración 002: se sigue con lo que hubiera (la caché o los valores de serie).
            let text = (error as? AccountError)?.errorDescription ?? error.localizedDescription
            log.info("Ajustes en vivo: no se pudo descargar (\(text, privacy: .public)); se sigue con la versión \(self.appliedVersion.map(String.init) ?? "de serie", privacy: .public).")
        }
    }

    /// Aplica lo pendiente si es un momento seguro. `force`: justo antes de empezar una partida.
    private func applyPending(force: Bool) {
        guard let store, force || store.canApplyCloudChanges else { return }
        guard let change = state.takePending() else { return }
        let warnings = GameTuning.apply(change.tuning)
        appliedVersion = change.version
        log.notice("Ajustes en vivo: aplicada la versión \(change.version.map(String.init) ?? "de serie", privacy: .public) (\(warnings.count) avisos).")
        for warning in warnings.prefix(30) {
            log.notice("  aviso: \(warning, privacy: .public)")
        }
    }
}
