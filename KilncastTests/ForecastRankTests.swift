import XCTest
@testable import Kilncast

/// Twist: kiln wall ranks by 7-day predicted heat, not current T and not last-contact age.
final class ForecastRankTests: XCTestCase {
    private var gmt: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    func test_fallingBrickOutranksStableWarmerForecast() throws {
        let now = Date(timeIntervalSince1970: 1_787_983_200)
        let today = gmt.startOfDay(for: now)
        let twentyAgo = gmt.date(byAdding: .day, value: -20, to: today) ?? today
        let falling = KilnPerson(id: KilnSeed.marloweID, displayName: "Marlowe", cadenceDays: 7)
        let stable = KilnPerson(id: KilnSeed.tessID, displayName: "Tess", cadenceDays: 30)
        let graph = EmberGraph.build(
            people: [falling, stable],
            touches: [
                EmberTouch(personID: falling.id, channel: .note, body: "today", touchedAt: today),
                EmberTouch(personID: stable.id, channel: .letter, body: "older", touchedAt: twentyAgo),
            ],
            now: today,
            horizonDays: 7,
            calendar: gmt
        )
        let fallingBrick = try XCTUnwrap(graph.bricks.first { $0.person.id == falling.id })
        let stableBrick = try XCTUnwrap(graph.bricks.first { $0.person.id == stable.id })
        XCTAssertGreaterThan(fallingBrick.currentT, stableBrick.currentT)
        XCTAssertLessThan(fallingBrick.forecastT, stableBrick.forecastT)
        XCTAssertEqual(ForecastRank.ordered(graph.bricks).map(\.person.id), [falling.id, stable.id])
    }

    func test_rankIsNotLastContactCountdown() {
        let now = Date(timeIntervalSince1970: 1_787_983_200)
        let today = gmt.startOfDay(for: now)
        let oneAgo = gmt.date(byAdding: .day, value: -1, to: today) ?? today
        let tenAgo = gmt.date(byAdding: .day, value: -10, to: today) ?? today
        let recentFall = KilnPerson(displayName: "A", cadenceDays: 2, createdAt: today)
        let olderStable = KilnPerson(displayName: "B", cadenceDays: 60, createdAt: today)
        let graph = EmberGraph.build(
            people: [recentFall, olderStable],
            touches: [
                EmberTouch(personID: recentFall.id, channel: .note, body: "recent", touchedAt: oneAgo),
                EmberTouch(personID: olderStable.id, channel: .note, body: "older", touchedAt: tenAgo),
            ],
            now: today,
            horizonDays: 7,
            calendar: gmt
        )
        let lastContactOrder = graph.bricks.sorted {
            ($0.lastTouchAt ?? .distantPast) < ($1.lastTouchAt ?? .distantPast)
        }.map(\.person.id)
        XCTAssertEqual(lastContactOrder, [olderStable.id, recentFall.id])
        XCTAssertEqual(graph.kilnWall.map(\.person.id), [recentFall.id, olderStable.id])
    }

    func test_neverTouchedStayOffTheForecastWall() {
        let now = Date(timeIntervalSince1970: 1_787_983_200)
        let ash = KilnPerson(displayName: "Cinder", cadenceDays: 14)
        let hot = KilnPerson(displayName: "Quin", cadenceDays: 30)
        let graph = EmberGraph.build(
            people: [ash, hot],
            touches: [
                EmberTouch(personID: hot.id, channel: .voice, body: "held", touchedAt: now),
            ],
            now: now,
            horizonDays: 7,
            calendar: gmt
        )
        XCTAssertEqual(graph.ash.map(\.person.id), [ash.id])
        XCTAssertEqual(graph.ash.first?.currentT, 0)
        XCTAssertEqual(graph.ash.first?.forecastT, 0)
        XCTAssertFalse(graph.kilnWall.contains { $0.person.id == ash.id })
    }
}
