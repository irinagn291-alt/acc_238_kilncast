import Foundation
import SwiftData

/// Role: Persistence. The only write that mutates heat. Channel + body; no derived T.
@Model
final class Touch {
    @Attribute(.unique) var id: UUID
    var channelRaw: String
    var body: String
    var touchedAt: Date
    var person: Person?

    init(
        id: UUID = UUID(),
        channelRaw: String,
        body: String,
        touchedAt: Date = Date(),
        person: Person? = nil
    ) {
        self.id = id
        self.channelRaw = channelRaw
        self.body = body
        self.touchedAt = touchedAt
        self.person = person
    }

    func snapshot() -> EmberTouch? {
        guard let person else { return nil }
        return EmberTouch(
            id: id,
            personID: person.id,
            channel: RestokeChannel(rawValue: channelRaw) ?? .note,
            body: body,
            touchedAt: touchedAt
        )
    }
}

/// Role: Ember graph. Sendable Touch. Inserting this is the only graph write.
struct EmberTouch: Sendable, Equatable, Identifiable {
    var id: UUID
    var personID: UUID
    var channel: RestokeChannel
    var body: String
    var touchedAt: Date

    init(
        id: UUID = UUID(),
        personID: UUID,
        channel: RestokeChannel,
        body: String,
        touchedAt: Date = Date()
    ) {
        self.id = id
        self.personID = personID
        self.channel = channel
        self.body = body
        self.touchedAt = touchedAt
    }
}

/// Role: Ember graph. Restoke channel. A tap without a log is not a channel write.
enum RestokeChannel: String, Sendable, Codable, CaseIterable, Equatable {
    case voice
    case letter
    case visit
    case note

    var title: String {
        switch self {
        case .voice: return "Voice"
        case .letter: return "Letter"
        case .visit: return "Visit"
        case .note: return "Note"
        }
    }
}
