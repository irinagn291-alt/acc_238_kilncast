import Foundation

/// Role: Ember graph. Reactive snapshot. Each Person is a derived cell; Touch is the only write.
struct EmberGraph: Sendable, Equatable {
    var now: Date
    var horizonDays: Int
    var bricks: [BrickHeat]

    var ash: [BrickHeat] {
        bricks.filter { $0.band == .ash }
    }

    var falling: [BrickHeat] {
        ForecastRank.ordered(bricks.filter { $0.band == .falling })
    }

    var hot: [BrickHeat] {
        ForecastRank.ordered(bricks.filter { $0.band == .hot })
    }

    /// Kiln wall order: forecast T, coldest first. Ash is excluded.
    var kilnWall: [BrickHeat] {
        ForecastRank.ordered(bricks)
    }

    static func build(
        people: [KilnPerson],
        touches: [EmberTouch],
        now: Date,
        horizonDays: Int = ForecastRank.defaultHorizonDays,
        calendar: Calendar = .current
    ) -> EmberGraph {
        let latestByPerson = latestTouchDates(touches)
        let bricks = people.map { person in
            let lastTouchAt = latestByPerson[person.id]
            let heat = HeatCell(
                lastTouchAt: lastTouchAt,
                cadenceDays: person.cadenceDays,
                now: now
            )
            let forecast = ForecastCell(
                lastTouchAt: lastTouchAt,
                cadenceDays: person.cadenceDays,
                now: now,
                horizonDays: horizonDays
            )
            let currentT = heat.temperature(calendar: calendar)
            let forecastT = forecast.temperature(calendar: calendar)
            return BrickHeat(
                person: person,
                lastTouchAt: lastTouchAt,
                currentT: currentT,
                forecastT: forecastT,
                band: DecayBand.of(lastTouchAt: lastTouchAt, forecastT: forecastT)
            )
        }
        return EmberGraph(now: now, horizonDays: horizonDays, bricks: bricks)
    }

    static func latestTouchDates(_ touches: [EmberTouch]) -> [UUID: Date] {
        var latest: [UUID: Date] = [:]
        for touch in touches {
            if let existing = latest[touch.personID] {
                if touch.touchedAt > existing {
                    latest[touch.personID] = touch.touchedAt
                }
            } else {
                latest[touch.personID] = touch.touchedAt
            }
        }
        return latest
    }
}
