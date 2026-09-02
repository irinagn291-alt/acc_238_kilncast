import Foundation
import UIKit

/// Role: Presentation. Sheet identity. No view types.
enum KilnSheet: String, Identifiable, Equatable, Sendable {
    case restoke
    case settings
    case addPerson
    case forecast

    var id: String { rawValue }
}

/// Role: Presentation. Rebuilds EmberGraph from Person/Touch. Touch is the only heat write.
@MainActor
@Observable
final class EmberSession {
    var graph: EmberGraph
    var settings: EmberSettings
    var sheet: KilnSheet?
    var fault: String?
    var busy = false
    var commitBusy = false
    var commitFlash = false
    var onboarded: Bool
    var restokePersonID: UUID?
    var restokeCadenceDays: Double
    var draft = RestokeDraft(personID: UUID(), channel: .note, body: "")
    var addName = ""
    var addCadenceDays: Double

    @ObservationIgnored private var store: EmberStore?
    @ObservationIgnored private var stack: KilnLaunchStack?
    @ObservationIgnored private let preferences: EmberPreferences
    @ObservationIgnored private let shouldLoad: Bool
    @ObservationIgnored private var people: [KilnPerson] = []
    @ObservationIgnored private var touches: [EmberTouch] = []
    @ObservationIgnored private var hookConsumed = false
    @ObservationIgnored private var appeared = false
    @ObservationIgnored private var now: Date
    @ObservationIgnored private let calendar: Calendar

    init(
        store: EmberStore?,
        stack: KilnLaunchStack? = nil,
        preferences: EmberPreferences = EmberPreferences(),
        shouldLoad: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current,
        settings: EmberSettings? = nil
    ) {
        self.store = store
        self.stack = stack
        self.preferences = preferences
        self.shouldLoad = shouldLoad
        self.now = now
        self.calendar = calendar
        let loaded = settings ?? preferences.load()
        self.settings = loaded
        onboarded = loaded.onboardingComplete
        addCadenceDays = loaded.defaultCadenceDays
        restokeCadenceDays = loaded.defaultCadenceDays
        graph = EmberGraph(now: now, horizonDays: loaded.forecastHorizonDays, bricks: [])
        if store == nil, shouldLoad {
            fault = "The kiln could not be opened."
        }
    }

    static func live() -> EmberSession {
        let stack = KilnLaunchStack()
        return EmberSession(store: stack.store, stack: stack)
    }

    static func previewPopulated() -> EmberSession {
        preview(seeded: true, onboarded: true, fault: nil)
    }

    static func previewEmpty() -> EmberSession {
        preview(seeded: false, onboarded: true, fault: nil)
    }

    static func previewFault() -> EmberSession {
        preview(seeded: true, onboarded: true, fault: "The kiln could not be opened.")
    }

    static func previewRestoke() -> EmberSession {
        let session = previewPopulated()
        if let brick = session.graph.falling.first ?? session.graph.kilnWall.first {
            session.openRestoke(personID: brick.person.id)
        }
        return session
    }

    private static func preview(seeded: Bool, onboarded: Bool, fault: String?) -> EmberSession {
        let suite = "kln.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.set(onboarded, forKey: EmberPreferenceKey.onboardingComplete)
        var settings = EmberSettings.factory
        settings.onboardingComplete = onboarded
        let session = EmberSession(
            store: nil,
            preferences: EmberPreferences(suiteName: suite),
            shouldLoad: false,
            now: previewNow,
            calendar: previewCalendar,
            settings: settings
        )
        session.onboarded = onboarded
        session.fault = fault
        if seeded {
            let payload = KilnSeed.demo(now: previewNow, calendar: previewCalendar)
            session.install(people: payload.people, touches: payload.touches)
        }
        return session
    }

    static var previewNow: Date {
        Date(timeIntervalSince1970: 1_787_983_200)
    }

    static var previewCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    func install(people: [KilnPerson], touches: [EmberTouch]) {
        self.people = people
        self.touches = touches
        rebuildGraph()
    }

    func appear() async {
        guard shouldLoad else {
            applyReviewHook()
            return
        }
        if appeared {
            applyReviewHook()
            return
        }
        appeared = true
        let spinner = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled {
                busy = true
            }
        }
        if let stack {
            await stack.prepare()
        }
        settings = preferences.load()
        onboarded = settings.onboardingComplete
        addCadenceDays = settings.defaultCadenceDays
        await reload()
        spinner.cancel()
        busy = false
        applyReviewHook()
    }

    func retry() async {
        fault = nil
        if store == nil {
            let next = KilnLaunchStack()
            stack = next
            store = next.store
            if store == nil {
                fault = "The kiln could not be opened."
                return
            }
        }
        appeared = false
        await appear()
    }

    func noteDayChange() {
        now = Date()
        rebuildGraph()
    }

    func finishOnboarding() {
        var next = settings
        if next.defaultCadenceDays <= 0 {
            next.defaultCadenceDays = EmberSettings.factory.defaultCadenceDays
        }
        if next.forecastHorizonDays <= 0 {
            next.forecastHorizonDays = ForecastRank.defaultHorizonDays
        }
        next.onboardingComplete = true
        settings = next
        preferences.save(next)
        onboarded = true
        addCadenceDays = next.defaultCadenceDays
        applyReviewHook()
    }

    func reopenOnboarding() {
        sheet = nil
        var next = settings
        next.onboardingComplete = false
        settings = next
        preferences.save(next)
        onboarded = false
    }

    func openRestoke(personID: UUID) {
        openRestoke(personID: personID, channel: .note)
    }

    func openRestoke(personID: UUID, channel: RestokeChannel) {
        restokePersonID = personID
        restokeCadenceDays = graph.bricks.first { $0.person.id == personID }?.person.cadenceDays
            ?? settings.defaultCadenceDays
        draft = RestokeDraft(personID: personID, channel: channel, body: "")
        sheet = .restoke
    }

    func restokeTouches() -> [EmberTouch] {
        guard let restokePersonID else { return [] }
        return touches
            .filter { $0.personID == restokePersonID }
            .sorted { lhs, rhs in
                if lhs.touchedAt != rhs.touchedAt {
                    return lhs.touchedAt > rhs.touchedAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    func updateRestokeCadence() async {
        guard let restokePersonID else { return }
        guard restokeCadenceDays > 0 else {
            fault = spoken(EmberStoreError.invalidCadence)
            return
        }
        do {
            if let store {
                try await store.updateCadence(personID: restokePersonID, cadenceDays: restokeCadenceDays)
                try await reloadFromStore()
            } else if let index = people.firstIndex(where: { $0.id == restokePersonID }) {
                people[index].cadenceDays = restokeCadenceDays
                rebuildGraph()
            }
            fault = nil
        } catch {
            fault = spoken(error)
        }
    }

    func deleteRestokePerson() async {
        guard let restokePersonID else { return }
        guard !commitBusy else { return }
        commitBusy = true
        defer { commitBusy = false }
        do {
            if let store {
                try await store.deletePerson(id: restokePersonID)
                try await reloadFromStore()
            } else {
                people.removeAll { $0.id == restokePersonID }
                touches.removeAll { $0.personID == restokePersonID }
                rebuildGraph()
            }
            self.restokePersonID = nil
            sheet = nil
            fault = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            fault = spoken(error)
        }
    }

    func openSettings() {
        sheet = .settings
    }

    func openAddPerson() {
        addName = ""
        addCadenceDays = settings.defaultCadenceDays
        sheet = .addPerson
    }

    func openForecast() {
        sheet = .forecast
    }

    private func flashCommit() {
        commitFlash = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            commitFlash = false
        }
    }

    func restokeBrick() -> BrickHeat? {
        guard let restokePersonID else { return nil }
        return graph.bricks.first { $0.person.id == restokePersonID }
    }

    /// Primary verb. Writes a Touch. A tap without a log does not heat.
    func commitRestoke() async {
        guard !commitBusy else { return }
        commitBusy = true
        defer { commitBusy = false }
        do {
            let body = try draft.committedBody()
            if let store {
                _ = try await store.restoke(
                    RestokeDraft(personID: draft.personID, channel: draft.channel, body: body),
                    at: now
                )
                try await reloadFromStore()
            } else {
                applyLocalTouch(body: body)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            flashCommit()
            sheet = nil
            fault = nil
        } catch {
            fault = spoken(error)
        }
    }

    func commitPerson() async {
        guard !commitBusy else { return }
        commitBusy = true
        defer { commitBusy = false }
        let name = addName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            fault = spoken(EmberStoreError.emptyName)
            return
        }
        guard addCadenceDays > 0 else {
            fault = spoken(EmberStoreError.invalidCadence)
            return
        }
        do {
            if let store {
                _ = try await store.addPerson(displayName: name, cadenceDays: addCadenceDays)
                try await reloadFromStore()
            } else {
                let person = KilnPerson(displayName: name, cadenceDays: addCadenceDays, createdAt: now)
                people.append(person)
                rebuildGraph()
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            flashCommit()
            sheet = nil
            fault = nil
        } catch {
            fault = spoken(error)
        }
    }

    func saveSettings() {
        preferences.save(settings)
        addCadenceDays = settings.defaultCadenceDays
        rebuildGraph()
    }

    func setReminder(_ on: Bool) {
        settings.reminderWeek = on ? ISOWeekDate.of(now, calendar: calendar) : nil
        saveSettings()
    }

    func resetAll() async {
        guard !commitBusy else { return }
        commitBusy = true
        defer { commitBusy = false }
        do {
            if let store {
                try await store.resetAllData()
            }
            people = []
            touches = []
            rebuildGraph()
            sheet = nil
            fault = nil
        } catch {
            fault = spoken(error)
        }
    }

    func applyReviewHook(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        guard let hook = ReviewHook.consume(
            arguments: arguments,
            onboarded: onboarded,
            consumed: &hookConsumed
        ) else { return }
        switch hook {
        case .today:
            sheet = nil
        case .log:
            if let brick = graph.falling.first ?? graph.kilnWall.first ?? graph.ash.first {
                openRestoke(personID: brick.person.id)
            }
        case .goals:
            sheet = .settings
        }
    }

    private func reload() async {
        guard store != nil else {
            rebuildGraph()
            return
        }
        do {
            try await reloadFromStore()
            fault = fault == "The kiln could not be opened." ? nil : fault
        } catch {
            fault = spoken(error)
        }
    }

    private func reloadFromStore() async throws {
        guard let store else { throw EmberStoreError.containerFailed }
        let loaded = try await store.load()
        people = loaded.people
        touches = loaded.touches
        rebuildGraph()
    }

    private func applyLocalTouch(body: String) {
        let touch = EmberTouch(
            personID: draft.personID,
            channel: draft.channel,
            body: body,
            touchedAt: now
        )
        touches.append(touch)
        rebuildGraph()
    }

    private func rebuildGraph() {
        graph = EmberGraph.build(
            people: people,
            touches: touches,
            now: now,
            horizonDays: settings.forecastHorizonDays,
            calendar: calendar
        )
    }

    func spoken(_ error: Error) -> String {
        switch error as? EmberStoreError {
        case .containerFailed:
            return "The kiln could not be opened."
        case .emptyName:
            return "Name a person."
        case .emptyBody:
            return "Write a touch. A tap without a log does not heat."
        case .unknownPerson:
            return "That brick is gone."
        case .invalidCadence:
            return "Cadence must be greater than zero."
        case .saveFailed:
            return "The kiln could not be saved."
        case nil:
            return "The kiln could not be updated."
        }
    }
}
