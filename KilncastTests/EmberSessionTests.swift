import XCTest
@testable import Kilncast

/// Family invariant through the reactive graph. Touch is the only write that heats.
@MainActor
final class EmberSessionTests: XCTestCase {
    private var suiteName: String!

    override func setUpWithError() throws {
        suiteName = "kln.session.\(UUID().uuidString)"
    }

    override func tearDownWithError() throws {
        if let suiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        suiteName = nil
    }

    func test_familyInvariant_daysIdleDecayLogistic() throws {
        let now = EmberSession.previewNow
        let calendar = EmberSession.previewCalendar
        let today = calendar.startOfDay(for: now)
        let fiveAgo = calendar.date(byAdding: .day, value: -5, to: today) ?? today
        let person = KilnPerson(displayName: "Marlowe", cadenceDays: 10, createdAt: today)
        let session = EmberSession(
            store: nil,
            preferences: EmberPreferences(suiteName: suiteName),
            shouldLoad: false,
            now: today,
            calendar: calendar
        )
        session.install(
            people: [person],
            touches: [EmberTouch(personID: person.id, channel: .note, body: "held", touchedAt: fiveAgo)]
        )
        let brick = try XCTUnwrap(session.graph.bricks.first)
        let expected = HeatFormula.temperature(
            lastTouchAt: fiveAgo,
            cadenceDays: 10,
            now: today,
            calendar: calendar
        )
        XCTAssertEqual(HeatFormula.decayFactor, 0.58, accuracy: 0)
        XCTAssertEqual(HeatFormula.exponent, 2.35, accuracy: 0)
        XCTAssertEqual(HeatFormula.secondsPerDay, 86_400, accuracy: 0)
        XCTAssertEqual(expected, 58.63234016219263, accuracy: 1e-9)
        XCTAssertEqual(brick.currentT, expected, accuracy: 1e-9)
        XCTAssertEqual(
            brick.forecastT,
            HeatFormula.forecast(
                lastTouchAt: fiveAgo,
                cadenceDays: 10,
                now: today,
                horizonDays: 7,
                calendar: calendar
            ),
            accuracy: 1e-9
        )
        XCTAssertNotEqual(brick.currentT, 50, accuracy: 1)
    }

    func test_neverTouchedStaysZeroOnAshRail() {
        let person = KilnPerson(displayName: "Cinder", cadenceDays: 14)
        let session = EmberSession.previewEmpty()
        session.install(people: [person], touches: [])
        XCTAssertEqual(session.graph.ash.map(\.person.id), [person.id])
        XCTAssertEqual(session.graph.ash.first?.currentT, 0)
        XCTAssertEqual(session.graph.ash.first?.forecastT, 0)
        XCTAssertTrue(session.graph.kilnWall.isEmpty)
    }

    func test_restokeEmptyPopulatedInvalid() async throws {
        let session = try makeStoredSession()
        let person = try await add(name: "Marlowe", cadence: 7, on: session)
        session.install(
            people: [person],
            touches: []
        )
        XCTAssertEqual(session.graph.bricks.first?.band, .ash)
        XCTAssertEqual(session.graph.bricks.first?.currentT, 0)

        session.openRestoke(personID: person.id)
        session.draft.body = "   "
        await session.commitRestoke()
        XCTAssertEqual(session.fault, session.spoken(EmberStoreError.emptyBody))
        XCTAssertEqual(session.graph.bricks.first?.currentT, 0)
        XCTAssertEqual(session.sheet, .restoke)

        session.draft.body = "Climb."
        await session.commitRestoke()
        XCTAssertNil(session.fault)
        XCTAssertNil(session.sheet)
        let heated = try XCTUnwrap(session.graph.bricks.first)
        XCTAssertEqual(heated.currentT, 100, accuracy: 1e-12)
        XCTAssertNotEqual(heated.band, .ash)
    }

    func test_horizonEditRecomputesWithoutANewTouch() {
        let session = EmberSession.previewPopulated()
        let before = session.graph.kilnWall.map(\.forecastT)
        session.settings.forecastHorizonDays = 21
        session.saveSettings()
        let after = session.graph.kilnWall.map(\.forecastT)
        XCTAssertEqual(session.graph.horizonDays, 21)
        XCTAssertNotEqual(before, after)
        XCTAssertEqual(session.graph.kilnWall.map(\.person.id), ForecastRank.ordered(session.graph.bricks).map(\.person.id))
    }

    func test_wallIsForecastRankNotLastContact() {
        let session = EmberSession.previewPopulated()
        let lastContact = session.graph.bricks
            .filter { $0.lastTouchAt != nil }
            .sorted { ($0.lastTouchAt ?? .distantPast) < ($1.lastTouchAt ?? .distantPast) }
            .map(\.person.id)
        XCTAssertEqual(session.graph.kilnWall.map(\.person.id), ForecastRank.ordered(session.graph.bricks).map(\.person.id))
        XCTAssertNotEqual(session.graph.kilnWall.map(\.person.id), lastContact)
        XCTAssertFalse(session.graph.kilnWall.contains { $0.person.id == KilnSeed.cinderID })
    }

    func test_reviewHookOpensRestokeAndSettings() {
        let session = EmberSession.previewPopulated()
        session.applyReviewHook(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(session.sheet, .restoke)
        XCTAssertEqual(session.restokePersonID, session.graph.falling.first?.person.id)

        let again = EmberSession.previewPopulated()
        again.applyReviewHook(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(again.sheet, .settings)
        again.applyReviewHook(arguments: ["-ReviewScreen", "today"])
        XCTAssertEqual(again.sheet, .settings)
    }

    func test_screensConstructWithoutArguments() {
        XCTAssertEqual(String(describing: type(of: KilnView())), "KilnView")
        XCTAssertEqual(String(describing: type(of: HiveView())), "HiveView")
        XCTAssertEqual(String(describing: type(of: ColdestView())), "ColdestView")
        XCTAssertEqual(String(describing: type(of: RestokeView())), "RestokeView")
        XCTAssertEqual(String(describing: type(of: SettingsView())), "SettingsView")
        XCTAssertEqual(String(describing: type(of: OnboardingView())), "OnboardingView")
        XCTAssertEqual(String(describing: type(of: FreezeForecastView())), "FreezeForecastView")
        XCTAssertEqual(String(describing: type(of: AddPersonView())), "AddPersonView")
        XCTAssertEqual(String(describing: type(of: KilnRootView())), "KilnRootView")
    }

    func test_forecastSheetIsTheTwistSurface() {
        let session = EmberSession.previewPopulated()
        session.openForecast()
        XCTAssertEqual(session.sheet, .forecast)
        XCTAssertFalse(session.graph.kilnWall.isEmpty)
        XCTAssertEqual(
            session.graph.kilnWall.map(\.person.id),
            ForecastRank.ordered(session.graph.bricks).map(\.person.id)
        )
    }

    private func makeStoredSession() throws -> EmberSession {
        switch KilnContainer.inMemory() {
        case .success(let container):
            return EmberSession(
                store: EmberStore(modelContainer: container),
                preferences: EmberPreferences(suiteName: suiteName),
                shouldLoad: false,
                now: EmberSession.previewNow,
                calendar: EmberSession.previewCalendar
            )
        case .failure(let error):
            throw error
        }
    }

    private func add(name: String, cadence: Double, on session: EmberSession) async throws -> KilnPerson {
        session.addName = name
        session.addCadenceDays = cadence
        await session.commitPerson()
        let brick = try XCTUnwrap(session.graph.bricks.first { $0.person.displayName == name })
        return brick.person
    }
}
