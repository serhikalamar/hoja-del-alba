import Foundation
import Testing
@testable import GameCore

// Ajustes en vivo (RemoteTuning.swift). No llaman a `GameTuning.apply`: cambia el estado global y los tests van en paralelo.

private func body(_ text: String) -> Data { Data(text.utf8) }

private func row(version: Int, schema: Int = 1, data: String = #"{"economy": {"arenaStartingGold": 80}}"#) -> String {
    #"[{"version": \#(version), "schema_version": \#(schema), "data": \#(data), "published_at": "2026-10-13T20:49:07.212354+00:00"}]"#
}

private func published(_ version: Int) -> RemoteTuningResponse {
    .published(PublishedTuning(version: version, schemaVersion: 1, publishedAt: nil, tuning: GameTuning()))
}

@Suite("Ajustes en vivo: leer la configuración publicada")
struct RemoteTuningParseTests {
    @Test func publishedRow() throws {
        guard case .published(let p) = RemoteTuningResponse.parse(body(row(version: 7))) else {
            Issue.record("no se leyó la fila")
            return
        }
        #expect(p.version == 7)
        #expect(p.schemaVersion == 1)
        #expect(p.tuning.version == 7)  // la versión del servidor manda
        #expect(p.tuning.economy?.arenaStartingGold == 80)
        #expect(p.publishedAt != nil)
    }

    @Test func nothingPublished() {
        #expect(RemoteTuningResponse.parse(body("[]")) == .nothingPublished)
    }

    @Test func newerSchemaIsIgnored() {
        #expect(RemoteTuningResponse.parse(body(row(version: 3, schema: 2)), supportedSchemaVersion: 1) == .tooNew(version: 3, schemaVersion: 2))
        // También si solo lo dice el documento.
        let inDocument = row(version: 4, data: #"{"schemaVersion": 5}"#)
        #expect(RemoteTuningResponse.parse(body(inDocument), supportedSchemaVersion: 1) == .tooNew(version: 4, schemaVersion: 5))
        // Uno que sí entiende.
        guard case .published = RemoteTuningResponse.parse(body(row(version: 3, schema: 2)), supportedSchemaVersion: 2) else {
            Issue.record("schema 2 debería leerse si la app lo entiende")
            return
        }
    }

    @Test func unreadable() {
        let cases = [
            "no es json",
            #"{"message": "x"}"#,                                         // objeto sin versión
            #"[{"version": 2, "schema_version": 1, "data": [1, 2]}]"#,     // data no es un objeto
            #"[{"version": "2", "schema_version": 1, "data": {}}]"#,       // versión en texto
            #"[{"version": 2, "schema_version": 1, "data": {"enemies": 5}}]"#,  // tipo equivocado
        ]
        for text in cases {
            guard case .unreadable = RemoteTuningResponse.parse(body(text)) else {
                Issue.record("debería ser ilegible: \(text)")
                continue
            }
        }
    }

    @Test func picksHighestVersionIfSeveral() {
        let text = #"[{"version": 2, "schema_version": 1, "data": {}}, {"version": 5, "schema_version": 1, "data": {}}]"#
        guard case .published(let p) = RemoteTuningResponse.parse(body(text)) else {
            Issue.record("no se leyó")
            return
        }
        #expect(p.version == 5)
    }
}

@Suite("Ajustes en vivo: cuándo aplicar")
struct RemoteTuningStateTests {
    @Test func appliesNewVersionOnlyAtSafePoint() {
        var state = RemoteTuningState()
        let outcome = state.receive(published(3))
        #expect(outcome.cache == .save)
        #expect(outcome.message != nil)
        #expect(state.appliedVersion == nil)  // todavía no: espera a un momento seguro
        #expect(state.targetVersion == 3)
        let change = state.takePending()
        #expect(change?.version == 3)
        #expect(state.appliedVersion == 3)
        #expect(state.takePending() == nil)  // ya aplicado
    }

    @Test func sameVersionDoesNothing() {
        var state = RemoteTuningState()
        _ = state.receive(published(3))
        _ = state.takePending()
        let outcome = state.receive(published(3))
        #expect(state.pending == nil)
        #expect(outcome.message == nil)
        #expect(outcome.cache == .save)
    }

    @Test func duringAGameOnlyTheLatestWaits() {
        // Llegan dos versiones durante una partida: al acabar se aplica solo la última.
        var state = RemoteTuningState()
        _ = state.receive(published(3))
        _ = state.takePending()
        _ = state.receive(published(4))
        _ = state.receive(published(5))
        #expect(state.appliedVersion == 3)
        #expect(state.takePending()?.version == 5)
        #expect(state.appliedVersion == 5)
    }

    @Test func rollbackToAppliedVersionCancelsPending() {
        // Se publica la 4 durante la partida, pero el servidor vuelve a decir 3 (la aplicada): nada que hacer.
        var state = RemoteTuningState()
        _ = state.receive(published(3))
        _ = state.takePending()
        _ = state.receive(published(4))
        _ = state.receive(published(3))
        #expect(state.pending == nil)
        #expect(state.appliedVersion == 3)
    }

    @Test func nothingPublishedResetsToDefaults() {
        var state = RemoteTuningState()
        // Sin nada aplicado: nada que hacer, pero la caché se borra.
        #expect(state.receive(.nothingPublished) == RemoteTuningState.Outcome(cache: .delete, message: nil))
        #expect(state.pending == nil)

        _ = state.receive(published(2))
        _ = state.takePending()
        let outcome = state.receive(.nothingPublished)
        #expect(outcome.cache == .delete)
        #expect(state.pending == .reset)
        #expect(state.pending?.tuning == GameTuning())
        #expect(state.takePending() == .reset)
        #expect(state.appliedVersion == nil)
    }

    @Test func tooNewOrUnreadableKeepsWhatWasThere() {
        var state = RemoteTuningState()
        _ = state.receive(published(2))  // p. ej. la de la caché
        _ = state.takePending()
        let tooNew = state.receive(.tooNew(version: 9, schemaVersion: 99))
        #expect(tooNew.cache == .keep)
        #expect(tooNew.message?.contains("schema_version 99") == true)
        #expect(state.pending == nil)
        #expect(state.appliedVersion == 2)

        let broken = state.receive(.unreadable("x"))
        #expect(broken.cache == .keep)
        #expect(state.pending == nil)
        #expect(state.appliedVersion == 2)
    }

    @Test func fetchThrottle() {
        var state = RemoteTuningState()
        let start = Date(timeIntervalSince1970: 1_000_000)
        #expect(state.shouldFetch(now: start))  // al abrir, siempre
        state.noteFetched(at: start)
        #expect(!state.shouldFetch(now: start.addingTimeInterval(60)))
        #expect(!state.shouldFetch(now: start.addingTimeInterval(RemoteTuningState.minimumFetchInterval - 1)))
        #expect(state.shouldFetch(now: start.addingTimeInterval(RemoteTuningState.minimumFetchInterval)))
        #expect(state.shouldFetch(now: start.addingTimeInterval(-60)))  // el reloj fue hacia atrás
    }
}

@Suite("Ajustes en vivo: caché en disco")
struct RemoteTuningCacheTests {
    @Test func roundTripAndOfflineStart() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ajustes-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let cache = RemoteTuningCache(url: folder.appendingPathComponent("sub/ajustes-en-vivo.json"))
        #expect(cache.load() == nil)

        // Se descarga la 6 y se guarda tal cual.
        let response = body(row(version: 6))
        var online = RemoteTuningState()
        #expect(online.receive(RemoteTuningResponse.parse(response)).cache == .save)
        cache.save(response)

        // Otro arranque, sin red: se aplica la de la caché.
        var offline = RemoteTuningState()
        let cached = try #require(cache.load())
        _ = offline.receive(RemoteTuningResponse.parse(cached))
        let change = offline.takePending()
        #expect(change?.version == 6)
        #expect(change?.tuning.economy?.arenaStartingGold == 80)

        cache.delete()
        #expect(cache.load() == nil)
    }
}
