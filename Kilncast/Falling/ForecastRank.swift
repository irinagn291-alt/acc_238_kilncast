import Foundation

/// Role: Ember graph. Imminent-freeze rank: predicted T in `horizon` days, coldest first.
/// Not last-contact age. Never-touched stay off this list (ash rail).
enum ForecastRank: Sendable {
    static let defaultHorizonDays = 7

    static func ordered(_ bricks: [BrickHeat]) -> [BrickHeat] {
        bricks
            .filter { $0.lastTouchAt != nil }
            .sorted { lhs, rhs in
                if lhs.forecastT != rhs.forecastT {
                    return lhs.forecastT < rhs.forecastT
                }
                if lhs.person.createdAt != rhs.person.createdAt {
                    return lhs.person.createdAt < rhs.person.createdAt
                }
                return lhs.person.id.uuidString < rhs.person.id.uuidString
            }
    }
}
