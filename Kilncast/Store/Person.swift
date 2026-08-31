import Foundation
import SwiftData

/// Role: Persistence. SwiftData Person. Heat, forecast T, band, lastTouchAt are never stored.
@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var cadenceDays: Double
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Touch.person)
    var touches: [Touch]

    init(
        id: UUID = UUID(),
        displayName: String,
        cadenceDays: Double,
        createdAt: Date = Date(),
        touches: [Touch] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.cadenceDays = cadenceDays
        self.createdAt = createdAt
        self.touches = touches
    }

    func snapshot() -> KilnPerson {
        KilnPerson(
            id: id,
            displayName: displayName,
            cadenceDays: cadenceDays,
            createdAt: createdAt
        )
    }
}

/// Role: Ember graph. Sendable Person at the repository seam. The UI never sees @Model.
struct KilnPerson: Sendable, Equatable, Identifiable {
    var id: UUID
    var displayName: String
    var cadenceDays: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        cadenceDays: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.cadenceDays = cadenceDays
        self.createdAt = createdAt
    }
}
