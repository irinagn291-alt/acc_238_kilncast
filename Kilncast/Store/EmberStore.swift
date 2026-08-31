import Foundation
import SwiftData

/// Role: Persistence. Typed store failures. Never crash on a save.
enum EmberStoreError: Error, Equatable, Sendable {
    case containerFailed
    case emptyName
    case emptyBody
    case unknownPerson
    case invalidCadence
    case saveFailed
}

/// Role: Persistence. @ModelActor seam. Maps Person/Touch to Sendable structs. UI never sees @Model.
@ModelActor
actor EmberStore {
    func load() async throws -> (people: [KilnPerson], touches: [EmberTouch]) {
        try Task.checkCancellation()
        let people = try modelContext.fetch(
            FetchDescriptor<Person>(sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.id)])
        )
        let touches = try modelContext.fetch(
            FetchDescriptor<Touch>(sortBy: [SortDescriptor(\.touchedAt), SortDescriptor(\.id)])
        )
        return (people.map { $0.snapshot() }, touches.compactMap { $0.snapshot() })
    }

    func addPerson(displayName: String, cadenceDays: Double) async throws -> KilnPerson {
        try Task.checkCancellation()
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw EmberStoreError.emptyName }
        guard cadenceDays > 0 else { throw EmberStoreError.invalidCadence }
        let person = Person(displayName: name, cadenceDays: cadenceDays)
        modelContext.insert(person)
        try save()
        return person.snapshot()
    }

    func updateCadence(personID: UUID, cadenceDays: Double) async throws {
        try Task.checkCancellation()
        guard cadenceDays > 0 else { throw EmberStoreError.invalidCadence }
        guard let person = try person(id: personID) else { throw EmberStoreError.unknownPerson }
        person.cadenceDays = cadenceDays
        try save()
    }

    /// Primary verb. Writes a Touch. A tap without a log does not heat.
    func restoke(_ draft: RestokeDraft, at touchedAt: Date = Date()) async throws -> EmberTouch {
        try Task.checkCancellation()
        let body = try draft.committedBody()
        guard let person = try person(id: draft.personID) else { throw EmberStoreError.unknownPerson }
        let touch = Touch(
            channelRaw: draft.channel.rawValue,
            body: body,
            touchedAt: touchedAt,
            person: person
        )
        modelContext.insert(touch)
        person.touches.append(touch)
        try save()
        guard let snapshot = touch.snapshot() else { throw EmberStoreError.saveFailed }
        return snapshot
    }

    func deletePerson(id: UUID) async throws {
        try Task.checkCancellation()
        guard let person = try person(id: id) else { throw EmberStoreError.unknownPerson }
        modelContext.delete(person)
        try save()
    }

    func resetAllData() async throws {
        try Task.checkCancellation()
        let people = try modelContext.fetch(FetchDescriptor<Person>())
        for person in people {
            modelContext.delete(person)
        }
        try save()
    }

    func seedDemoIfNeeded(
        defaultsSuiteName: String?,
        allowDemoSeed: Bool,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws {
        try Task.checkCancellation()
        guard allowDemoSeed else { return }
        let defaults = preferenceDefaults(suiteName: defaultsSuiteName)
        guard defaults.object(forKey: EmberPreferenceKey.demoSeed) == nil else { return }
        let payload = KilnSeed.demo(now: now, calendar: calendar)
        for person in payload.people {
            modelContext.insert(
                Person(
                    id: person.id,
                    displayName: person.displayName,
                    cadenceDays: person.cadenceDays,
                    createdAt: person.createdAt
                )
            )
        }
        for touch in payload.touches {
            guard let owner = try person(id: touch.personID) else { throw EmberStoreError.unknownPerson }
            let stored = Touch(
                id: touch.id,
                channelRaw: touch.channel.rawValue,
                body: touch.body,
                touchedAt: touch.touchedAt,
                person: owner
            )
            modelContext.insert(stored)
            owner.touches.append(stored)
        }
        try save()
        defaults.set(true, forKey: EmberPreferenceKey.demoSeed)
        defaults.set(true, forKey: EmberPreferenceKey.onboardingComplete)
    }

    private func preferenceDefaults(suiteName: String?) -> UserDefaults {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            return suite
        }
        return .standard
    }

    private func person(id: UUID) throws -> Person? {
        let target = id
        var descriptor = FetchDescriptor<Person>(predicate: #Predicate { $0.id == target })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw EmberStoreError.saveFailed
        }
    }
}
