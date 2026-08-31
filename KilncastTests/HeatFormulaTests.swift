import XCTest
@testable import Kilncast

/// Family invariant: days = idle/86400; decay = cadence×0.58; T = 100/(1+(days/decay)^2.35).
final class HeatFormulaTests: XCTestCase {
    private var gmt: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    func test_neverTouchedIsZero() {
        XCTAssertEqual(
            HeatFormula.temperature(lastTouchAt: nil, cadenceDays: 7, now: Date(), calendar: gmt),
            0
        )
        XCTAssertEqual(
            HeatFormula.forecast(lastTouchAt: nil, cadenceDays: 7, now: Date(), horizonDays: 7, calendar: gmt),
            0
        )
    }

    func test_daysAreIdleOver86400_decayIsCadenceTimes058() {
        let idle = HeatFormula.secondsPerDay * 1
        XCTAssertEqual(HeatFormula.decayFactor, 0.58, accuracy: 0)
        XCTAssertEqual(HeatFormula.exponent, 2.35, accuracy: 0)
        XCTAssertEqual(HeatFormula.secondsPerDay, 86_400, accuracy: 0)
        let temperature = HeatFormula.temperature(idleSeconds: idle, cadenceDays: 10)
        XCTAssertEqual(temperature, 98.41867287844093, accuracy: 1e-9)
    }

    func test_sameDayRestokeIsFullHeat() {
        let now = Date(timeIntervalSince1970: 1_787_983_200)
        let afternoon = now.addingTimeInterval(8 * 3_600)
        XCTAssertEqual(
            HeatFormula.temperature(lastTouchAt: afternoon, cadenceDays: 14, now: now, calendar: gmt),
            100,
            accuracy: 1e-12
        )
    }

    func test_clampsToClosedUnitInterval() {
        XCTAssertEqual(HeatFormula.temperature(idleSeconds: 0, cadenceDays: 10), 100)
        XCTAssertEqual(HeatFormula.temperature(idleSeconds: -86_400, cadenceDays: 10), 100)
        XCTAssertGreaterThanOrEqual(HeatFormula.temperature(idleSeconds: 86_400 * 400, cadenceDays: 7), 0)
        XCTAssertLessThanOrEqual(HeatFormula.temperature(idleSeconds: 86_400 * 400, cadenceDays: 7), 100)
        XCTAssertEqual(HeatFormula.temperature(idleSeconds: 86_400, cadenceDays: 0), 0)
    }

    func test_heatIsNotALastContactCountdown() {
        let logistic = HeatFormula.temperature(idleSeconds: 86_400 * 5, cadenceDays: 10)
        let linearCountdown = 50.0
        XCTAssertEqual(logistic, 58.63234016219263, accuracy: 1e-9)
        XCTAssertNotEqual(logistic, linearCountdown, accuracy: 1)
    }

    func test_forecastUsesNowPlusHorizon() {
        let last = Date(timeIntervalSince1970: 1_787_376_000)
        let now = last
        let current = HeatFormula.temperature(lastTouchAt: last, cadenceDays: 7, now: now, calendar: gmt)
        let forecast = HeatFormula.forecast(
            lastTouchAt: last,
            cadenceDays: 7,
            now: now,
            horizonDays: 7,
            calendar: gmt
        )
        XCTAssertEqual(current, 100, accuracy: 1e-12)
        XCTAssertEqual(forecast, 21.753169337682188, accuracy: 1e-9)
    }
}
