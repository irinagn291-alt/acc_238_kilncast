import Foundation

/// Role: Persistence. Preference keys. Demo seed is Simulator-only and versioned.
enum EmberPreferenceKey {
    static let demoSeed = "kln.demo.v1"
    static let onboardingComplete = "kln.onboarding.complete"
    static let defaultCadenceDays = "kln.settings.cadenceDays"
    static let forecastHorizonDays = "kln.settings.forecastHorizonDays"
    static let reminderWeek = "kln.settings.reminderWeek"
}

/// Role: Persistence. Cadence, forecast horizon, optional reminder week. Not Person/Touch.
struct EmberSettings: Sendable, Equatable {
    var defaultCadenceDays: Double
    var forecastHorizonDays: Int
    var reminderWeek: ISOWeekDate?
    var onboardingComplete: Bool

    static let factory = EmberSettings(
        defaultCadenceDays: 14,
        forecastHorizonDays: ForecastRank.defaultHorizonDays,
        reminderWeek: nil,
        onboardingComplete: false
    )
}

/// Role: Persistence. UserDefaults box. Reminder week is YYYY-Www; heat uses startOfDay idle seconds.
struct EmberPreferences: Sendable {
    var suiteName: String?

    func load() -> EmberSettings {
        let defaults = box()
        let cadence = defaults.object(forKey: EmberPreferenceKey.defaultCadenceDays) as? Double
            ?? EmberSettings.factory.defaultCadenceDays
        let horizon = defaults.object(forKey: EmberPreferenceKey.forecastHorizonDays) as? Int
            ?? EmberSettings.factory.forecastHorizonDays
        let reminder = (defaults.string(forKey: EmberPreferenceKey.reminderWeek))
            .flatMap(ISOWeekDate.parse)
        return EmberSettings(
            defaultCadenceDays: cadence > 0 ? cadence : EmberSettings.factory.defaultCadenceDays,
            forecastHorizonDays: horizon > 0 ? horizon : EmberSettings.factory.forecastHorizonDays,
            reminderWeek: reminder,
            onboardingComplete: defaults.bool(forKey: EmberPreferenceKey.onboardingComplete)
        )
    }

    func save(_ settings: EmberSettings) {
        let defaults = box()
        defaults.set(settings.defaultCadenceDays, forKey: EmberPreferenceKey.defaultCadenceDays)
        defaults.set(settings.forecastHorizonDays, forKey: EmberPreferenceKey.forecastHorizonDays)
        if let reminderWeek = settings.reminderWeek {
            defaults.set(reminderWeek.daykey, forKey: EmberPreferenceKey.reminderWeek)
        } else {
            defaults.removeObject(forKey: EmberPreferenceKey.reminderWeek)
        }
        defaults.set(settings.onboardingComplete, forKey: EmberPreferenceKey.onboardingComplete)
    }

    func resetUserState() {
        let defaults = box()
        defaults.removeObject(forKey: EmberPreferenceKey.defaultCadenceDays)
        defaults.removeObject(forKey: EmberPreferenceKey.forecastHorizonDays)
        defaults.removeObject(forKey: EmberPreferenceKey.reminderWeek)
        defaults.removeObject(forKey: EmberPreferenceKey.onboardingComplete)
    }

    private func box() -> UserDefaults {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            return suite
        }
        return .standard
    }
}
