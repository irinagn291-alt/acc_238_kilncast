import XCTest
@testable import Kilncast

/// Architecture: heat is a derived cell. Touch is the only write. Cadence edits recompute.
final class EmberGraphTests: XCTestCase {
    private var gmt: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    func test_personSnapshotStoresNoHeat() {
        let person = KilnPerson(displayName: "Marlowe", cadenceDays: 7)
        let labels = Set(Mirror(reflecting: person).children.compactMap(\.label))
        XCTAssertEqual(labels, ["id", "displayName", "cadenceDays", "createdAt"])
        XCTAssertFalse(labels.contains("heat"))
        XCTAssertFalse(labels.contains("forecastT"))
        XCTAssertFalse(labels.contains("lastTouchAt"))
    }

    func test_restokeEmptyPopulatedInvalid() {
        let person = KilnPerson(displayName: "Marlowe", cadenceDays: 7)
        let empty = EmberGraph.build(people: [person], touches: [], now: Date(), calendar: gmt)
        XCTAssertEqual(empty.bricks.first?.currentT, 0)
        XCTAssertEqual(empty.bricks.first?.band, .ash)

        let draft = RestokeDraft(personID: person.id, channel: .note, body: "   ")
        XCTAssertThrowsError(try draft.committedBody()) { error in
            XCTAssertEqual(error as? EmberStoreError, .emptyBody)
        }
        let stillCold = EmberGraph.build(people: [person], touches: [], now: Date(), calendar: gmt)
        XCTAssertEqual(stillCold.bricks.first?.currentT, 0)

        let now = gmt.startOfDay(for: Date(timeIntervalSince1970: 1_787_983_200))
        let touch = EmberTouch(personID: person.id, channel: .note, body: "Restoke.", touchedAt: now)
        let heated = EmberGraph.build(people: [person], touches: [touch], now: now, calendar: gmt)
        XCTAssertEqual(heated.bricks.first?.currentT, 100)
        XCTAssertNotEqual(heated.bricks.first?.band, .ash)
    }

    func test_cadenceEditRecomputesWithoutANewTouch() {
        let now = gmt.startOfDay(for: Date(timeIntervalSince1970: 1_787_983_200))
        let fiveAgo = gmt.date(byAdding: .day, value: -5, to: now) ?? now
        let person = KilnPerson(displayName: "Marlowe", cadenceDays: 10)
        let touch = EmberTouch(personID: person.id, channel: .note, body: "one", touchedAt: fiveAgo)
        let wide = EmberGraph.build(people: [person], touches: [touch], now: now, calendar: gmt)
        let tightPerson = KilnPerson(
            id: person.id,
            displayName: person.displayName,
            cadenceDays: 2,
            createdAt: person.createdAt
        )
        let tight = EmberGraph.build(people: [tightPerson], touches: [touch], now: now, calendar: gmt)
        XCTAssertGreaterThan(wide.bricks[0].currentT, tight.bricks[0].currentT)
        XCTAssertEqual(wide.bricks[0].lastTouchAt, tight.bricks[0].lastTouchAt)
    }

    func test_fallingAndHotSplitOnForecastT() {
        let now = gmt.startOfDay(for: Date(timeIntervalSince1970: 1_787_983_200))
        let falling = KilnPerson(id: KilnSeed.marloweID, displayName: "Marlowe", cadenceDays: 7)
        let hot = KilnPerson(id: KilnSeed.quinID, displayName: "Quin", cadenceDays: 30)
        let graph = EmberGraph.build(
            people: [falling, hot],
            touches: [
                EmberTouch(personID: falling.id, channel: .note, body: "fall", touchedAt: now),
                EmberTouch(personID: hot.id, channel: .voice, body: "hold", touchedAt: now),
            ],
            now: now,
            horizonDays: 7,
            calendar: gmt
        )
        XCTAssertEqual(graph.falling.map(\.person.id), [falling.id])
        XCTAssertEqual(graph.hot.map(\.person.id), [hot.id])
        XCTAssertLessThan(graph.falling[0].forecastT, HeatFormula.fallingCeiling)
        XCTAssertGreaterThanOrEqual(graph.hot[0].forecastT, HeatFormula.fallingCeiling)
    }
}
