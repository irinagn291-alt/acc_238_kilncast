import Foundation

/// Role: Ember graph. One Person as a derived heat cell. Never a stored field.
struct HeatCell: Sendable, Equatable {
    var lastTouchAt: Date?
    var cadenceDays: Double
    var now: Date

    func temperature(calendar: Calendar = .current) -> Double {
        HeatFormula.temperature(
            lastTouchAt: lastTouchAt,
            cadenceDays: cadenceDays,
            now: now,
            calendar: calendar
        )
    }
}

/// Role: Ember graph. Sort key for the kiln wall. Evaluates heat at now + horizon.
struct ForecastCell: Sendable, Equatable {
    var lastTouchAt: Date?
    var cadenceDays: Double
    var now: Date
    var horizonDays: Int

    func temperature(calendar: Calendar = .current) -> Double {
        HeatFormula.forecast(
            lastTouchAt: lastTouchAt,
            cadenceDays: cadenceDays,
            now: now,
            horizonDays: horizonDays,
            calendar: calendar
        )
    }
}

/// Role: Ember graph. Derived partition. Ash is lastTouchAt == nil; falling/hot split on forecast T.
enum DecayBand: String, Sendable, Equatable, CaseIterable {
    case ash
    case falling
    case hot

    static func of(lastTouchAt: Date?, forecastT: Double) -> DecayBand {
        guard lastTouchAt != nil else { return .ash }
        return forecastT < HeatFormula.fallingCeiling ? .falling : .hot
    }
}

/// Role: Ember graph. One kiln brick. Fill tracks forecast T; heat is recomputed from Touch.
struct BrickHeat: Sendable, Equatable, Identifiable {
    var person: KilnPerson
    var lastTouchAt: Date?
    var currentT: Double
    var forecastT: Double
    var band: DecayBand

    var id: UUID { person.id }
}
