import XCTest
@testable import Kilncast

/// Family invariant: logistic heat, never a last-contact countdown.
final class KilncastTests: XCTestCase {
    func test_familyInvariant_daysIdleDecayLogistic() {
        XCTAssertEqual(HeatFormula.decayFactor, 0.58, accuracy: 0)
        XCTAssertEqual(HeatFormula.exponent, 2.35, accuracy: 0)
        XCTAssertEqual(HeatFormula.secondsPerDay, 86_400, accuracy: 0)
        XCTAssertEqual(HeatFormula.temperature(lastTouchAt: nil, cadenceDays: 7, now: Date()), 0)
        let idle = HeatFormula.secondsPerDay * 5
        let temperature = HeatFormula.temperature(idleSeconds: idle, cadenceDays: 10)
        XCTAssertEqual(temperature, 58.63234016219263, accuracy: 1e-9)
        XCTAssertNotEqual(temperature, 50, accuracy: 1)
    }
}
