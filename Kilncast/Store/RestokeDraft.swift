import Foundation

/// Role: Ember graph. Primary verb payload. Empty body is invalid; a tap without a log does not heat.
struct RestokeDraft: Sendable, Equatable {
    var personID: UUID
    var channel: RestokeChannel
    var body: String

    func committedBody() throws -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw EmberStoreError.emptyBody }
        return trimmed
    }
}
