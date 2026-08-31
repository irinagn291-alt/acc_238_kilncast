import Foundation

/// Role: Ember graph. Family invariant. Heat is always derived; this type stores nothing.
enum HeatFormula: Sendable {
    static let decayFactor = 0.58
    static let exponent = 2.35
    static let secondsPerDay = 86_400.0
    static let fallingCeiling = 50.0

    /// days = idle/86400; decay = cadence×0.58; T = 100/(1+(days/decay)^2.35), clamp 0…100.
    static func temperature(idleSeconds: Double, cadenceDays: Double) -> Double {
        guard cadenceDays > 0 else { return 0 }
        let days = max(0, idleSeconds / secondsPerDay)
        let decay = cadenceDays * decayFactor
        guard decay > 0 else { return 0 }
        let ratio = days / decay
        let lifted = pow(ratio, exponent)
        guard lifted.isFinite else { return 0 }
        let raw = 100 / (1 + lifted)
        guard raw.isFinite else { return 0 }
        return min(100, max(0, raw))
    }

    static func idleSeconds(from lastTouchAt: Date, now: Date, calendar: Calendar) -> Double {
        let lastDay = calendar.startOfDay(for: lastTouchAt)
        let nowDay = calendar.startOfDay(for: now)
        return nowDay.timeIntervalSince(lastDay)
    }

    /// Never-touched = 0. Not a countdown.
    static func temperature(
        lastTouchAt: Date?,
        cadenceDays: Double,
        now: Date,
        calendar: Calendar = .current
    ) -> Double {
        guard let lastTouchAt else { return 0 }
        let idle = idleSeconds(from: lastTouchAt, now: now, calendar: calendar)
        return temperature(idleSeconds: idle, cadenceDays: cadenceDays)
    }

    static func forecastNow(
        _ now: Date,
        horizonDays: Int,
        calendar: Calendar
    ) -> Date {
        let horizon = max(0, horizonDays)
        return calendar.date(byAdding: .day, value: horizon, to: now)
            ?? now.addingTimeInterval(Double(horizon) * secondsPerDay)
    }

    /// Same formula at now + horizon. Never-touched stay 0 so they cannot hide in the forecast.
    static func forecast(
        lastTouchAt: Date?,
        cadenceDays: Double,
        now: Date,
        horizonDays: Int,
        calendar: Calendar = .current
    ) -> Double {
        guard lastTouchAt != nil else { return 0 }
        let future = forecastNow(now, horizonDays: horizonDays, calendar: calendar)
        return temperature(
            lastTouchAt: lastTouchAt,
            cadenceDays: cadenceDays,
            now: future,
            calendar: calendar
        )
    }
}
