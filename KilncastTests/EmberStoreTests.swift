import XCTest
import SwiftData
@testable import Kilncast

final class EmberStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        suiteName = "kln.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesTouch() async throws {
        let container = try openInMemory()
        let writer = EmberStore(modelContainer: container)
        let person = try await writer.addPerson(displayName: "Marlowe", cadenceDays: 7)
        let now = Date(timeIntervalSince1970: 1_787_983_200)
        let touch = try await writer.restoke(
            RestokeDraft(personID: person.id, channel: .note, body: "Climb."),
            at: now
        )

        let reader = EmberStore(modelContainer: container)
        let loaded = try await reader.load()
        XCTAssertEqual(loaded.people.count, 1)
        XCTAssertEqual(loaded.people[0].displayName, "Marlowe")
        XCTAssertEqual(loaded.people[0].cadenceDays, 7)
        XCTAssertEqual(loaded.touches.count, 1)
        XCTAssertEqual(loaded.touches[0].id, touch.id)
        XCTAssertEqual(loaded.touches[0].body, "Climb.")
        XCTAssertEqual(loaded.touches[0].touchedAt, now)
        XCTAssertNil(Mirror(reflecting: loaded.people[0]).children.first { $0.label == "heat" })
    }

    func test_restokeRejectsEmptyAndUnknown() async throws {
        let store = EmberStore(modelContainer: try openInMemory())
        let person = try await store.addPerson(displayName: "Marlowe", cadenceDays: 7)
        do {
            _ = try await store.restoke(RestokeDraft(personID: person.id, channel: .note, body: "  \n"))
            XCTFail("expected emptyBody")
        } catch {
            XCTAssertEqual(error as? EmberStoreError, .emptyBody)
        }
        do {
            _ = try await store.restoke(RestokeDraft(personID: UUID(), channel: .note, body: "Hello"))
            XCTFail("expected unknownPerson")
        } catch {
            XCTAssertEqual(error as? EmberStoreError, .unknownPerson)
        }
        let loaded = try await store.load()
        XCTAssertTrue(loaded.touches.isEmpty)
    }

    func test_addPersonRejectsEmptyNameAndCadence() async throws {
        let store = EmberStore(modelContainer: try openInMemory())
        do {
            _ = try await store.addPerson(displayName: "  ", cadenceDays: 7)
            XCTFail("expected emptyName")
        } catch {
            XCTAssertEqual(error as? EmberStoreError, .emptyName)
        }
        do {
            _ = try await store.addPerson(displayName: "Marlowe", cadenceDays: 0)
            XCTFail("expected invalidCadence")
        } catch {
            XCTAssertEqual(error as? EmberStoreError, .invalidCadence)
        }
    }

    func test_updateCadenceRecomputesWithoutANewTouch() async throws {
        let store = EmberStore(modelContainer: try openInMemory())
        let person = try await store.addPerson(displayName: "Tess", cadenceDays: 30)
        let now = Date(timeIntervalSince1970: 1_787_983_200)
        _ = try await store.restoke(
            RestokeDraft(personID: person.id, channel: .letter, body: "Held."),
            at: now
        )
        try await store.updateCadence(personID: person.id, cadenceDays: 5)
        let loaded = try await store.load()
        XCTAssertEqual(loaded.people[0].cadenceDays, 5)
        XCTAssertEqual(loaded.touches.count, 1)
        XCTAssertEqual(loaded.touches[0].body, "Held.")
    }

    func test_resetAllDataAndCascadeDelete() async throws {
        let store = EmberStore(modelContainer: try openInMemory())
        let person = try await store.addPerson(displayName: "Marlowe", cadenceDays: 7)
        _ = try await store.restoke(RestokeDraft(personID: person.id, channel: .note, body: "Hi"))
        try await store.deletePerson(id: person.id)
        var loaded = try await store.load()
        XCTAssertTrue(loaded.people.isEmpty)
        XCTAssertTrue(loaded.touches.isEmpty)

        let kept = try await store.addPerson(displayName: "Quin", cadenceDays: 14)
        _ = try await store.restoke(RestokeDraft(personID: kept.id, channel: .voice, body: "Held"))
        try await store.resetAllData()
        loaded = try await store.load()
        XCTAssertTrue(loaded.people.isEmpty)
        XCTAssertTrue(loaded.touches.isEmpty)
    }

    func test_seedOnceBehindVersionedKey() async throws {
        let store = EmberStore(modelContainer: try openInMemory())
        let now = Date(timeIntervalSince1970: 1_787_983_200)
        try await store.seedDemoIfNeeded(defaultsSuiteName: suiteName, allowDemoSeed: false, now: now)
        let beforeSeed = try await store.load()
        XCTAssertTrue(beforeSeed.people.isEmpty)

        try await store.seedDemoIfNeeded(defaultsSuiteName: suiteName, allowDemoSeed: true, now: now)
        let first = try await store.load()
        XCTAssertEqual(first.people.count, 4)
        XCTAssertEqual(first.touches.count, 3)
        XCTAssertTrue(defaults.bool(forKey: EmberPreferenceKey.demoSeed))
        XCTAssertTrue(defaults.bool(forKey: EmberPreferenceKey.onboardingComplete))

        try await store.seedDemoIfNeeded(defaultsSuiteName: suiteName, allowDemoSeed: true, now: now)
        let second = try await store.load()
        XCTAssertEqual(second.people.count, 4)
        XCTAssertEqual(second.touches.count, 3)
        XCTAssertTrue(first.people.contains { $0.id == KilnSeed.cinderID })
        XCTAssertFalse(first.touches.contains { $0.personID == KilnSeed.cinderID })
    }

    func test_isoWeekIsNotUsedForHeat() {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 8
        parts.day = 29
        let saturday = iso.date(from: parts) ?? Date(timeIntervalSince1970: 1_787_961_600)
        let week = ISOWeekDate.of(saturday, calendar: iso)
        XCTAssertEqual(week.daykey, "2026-W35")
        XCTAssertEqual(ISOWeekDate.parse(daykey: "2026-W35"), week)

        let prefs = EmberPreferences(suiteName: suiteName)
        var settings = EmberSettings.factory
        settings.reminderWeek = week
        prefs.save(settings)
        XCTAssertEqual(prefs.load().reminderWeek?.daykey, "2026-W35")
        XCTAssertEqual(
            HeatFormula.temperature(idleSeconds: 86_400, cadenceDays: 10),
            98.41867287844093,
            accuracy: 1e-9
        )
    }

    private func openInMemory() throws -> ModelContainer {
        switch KilnContainer.inMemory() {
        case .success(let container):
            return container
        case .failure(let error):
            throw error
        }
    }
}
