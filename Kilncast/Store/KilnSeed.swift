import Foundation

/// Role: Persistence. Simulator-only demo kiln. Device never seeds. Key: kln.demo.v1.
enum KilnSeed {
    static let cinderID = uuid("11111111-1111-4111-8111-111111111111")
    static let marloweID = uuid("22222222-2222-4222-8222-222222222222")
    static let tessID = uuid("33333333-3333-4333-8333-333333333333")
    static let quinID = uuid("44444444-4444-4444-8444-444444444444")
    static let marloweTouchID = uuid("55555555-5555-4555-8555-555555555555")
    static let tessTouchID = uuid("66666666-6666-4666-8666-666666666666")
    static let quinTouchID = uuid("77777777-7777-4777-8777-777777777777")

    /// Seed identities are literals. Failure here is a programmer error.
    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    static func demo(now: Date, calendar: Calendar) -> (people: [KilnPerson], touches: [EmberTouch]) {
        let today = calendar.startOfDay(for: now)
        let created = today
        let twentyDaysAgo = calendar.date(byAdding: .day, value: -20, to: today) ?? today
        let people = [
            KilnPerson(id: cinderID, displayName: "Cinder", cadenceDays: 14, createdAt: created),
            KilnPerson(id: marloweID, displayName: "Marlowe", cadenceDays: 7, createdAt: created),
            KilnPerson(id: tessID, displayName: "Tess", cadenceDays: 30, createdAt: created),
            KilnPerson(id: quinID, displayName: "Quin", cadenceDays: 30, createdAt: created),
        ]
        let touches = [
            EmberTouch(
                id: marloweTouchID,
                personID: marloweID,
                channel: .note,
                body: "Restoke before the brick falls.",
                touchedAt: today
            ),
            EmberTouch(
                id: tessTouchID,
                personID: tessID,
                channel: .letter,
                body: "Long cadence, still warm enough.",
                touchedAt: twentyDaysAgo
            ),
            EmberTouch(
                id: quinTouchID,
                personID: quinID,
                channel: .voice,
                body: "Just restoked. Holds heat.",
                touchedAt: today
            ),
        ]
        return (people, touches)
    }
}
