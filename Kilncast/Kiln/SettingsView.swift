import SwiftUI

/// Role: Presentation. Settings. Cadence, horizon, reminder, contact, reset. ReviewScreen goals.
struct SettingsView: View {
    var session: EmberSession
    @State private var confirmReset = false

    init(session: EmberSession = .previewPopulated()) {
        self.session = session
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FireclayPalette.space(2)) {
                    if let fault = session.fault {
                        Text(fault)
                            .kilnText(.body)
                            .foregroundStyle(FireclayPalette.accent)
                        Button("Retry") {
                            Task { await session.retry() }
                        }
                        .kilnText(.headline)
                        .foregroundStyle(FireclayPalette.accent)
                        .kilnTap()
                    } else if session.graph.bricks.isEmpty {
                        KilnEmptyPlate(
                            image: EmberArtName.emptyList,
                            headline: "Empty kiln",
                            line: "Defaults still apply. Add a person on the wall.",
                            actionTitle: "Add a person",
                            action: { session.openAddPerson() }
                        )
                    } else {
                        Text("Cadence sets decay. Horizon is the freeze rank, not a countdown.")
                            .kilnText(.body)
                            .foregroundStyle(FireclayPalette.muted)
                    }

                    labeled("Default cadence, days") {
                        cadenceField
                    }
                    labeled("Forecast horizon, days") {
                        horizonField
                    }
                    Toggle(isOn: reminderBinding) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Optional reminder week")
                                .kilnText(.headline)
                            if let week = session.settings.reminderWeek {
                                Text(week.daykey)
                                    .kilnText(.caption)
                                    .foregroundStyle(FireclayPalette.muted)
                            }
                        }
                        .foregroundStyle(FireclayPalette.ink)
                    }
                    .tint(FireclayPalette.accent)
                    .frame(minHeight: FireclayPalette.tap)

                    if let url = URL(string: "https://kilncast.pro/contact-us") {
                        Link(destination: url) {
                            actionLabel("Contact Kilncast", color: FireclayPalette.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        session.reopenOnboarding()
                    } label: {
                        actionLabel("Re-run onboarding", color: FireclayPalette.ink)
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        actionLabel("Reset all data", color: FireclayPalette.ink)
                    }
                    .buttonStyle(.plain)
                    .disabled(session.commitBusy)
                }
                .padding(FireclayPalette.space(2))
            }
            .background(FireclayPalette.background.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            session.sheet = nil
                        }
                        .tint(FireclayPalette.ink)
                    }
            }
            .confirmationDialog("Clear every brick and touch?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset all data", role: .destructive) {
                    Task { await session.resetAll() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var cadenceField: some View {
        HStack {
            TextField("Days", text: cadenceText)
                .keyboardType(.decimalPad)
                .kilnText(.headline)
                .monospacedDigit()
                .foregroundStyle(FireclayPalette.ink)
                .frame(minHeight: FireclayPalette.tap)
            Text(EmberFigures.days(session.settings.defaultCadenceDays))
                .kilnText(.caption)
                .monospacedDigit()
                .foregroundStyle(FireclayPalette.muted)
        }
    }

    private var horizonField: some View {
        Stepper(value: horizonBinding, in: 1 ... 30, step: 1) {
            Text(EmberFigures.count(session.settings.forecastHorizonDays))
                .kilnText(.headline)
                .monospacedDigit()
                .foregroundStyle(FireclayPalette.ink)
        }
        .frame(minHeight: FireclayPalette.tap)
    }

    private func labeled(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
            Text(title)
                .kilnText(.caption)
                .foregroundStyle(FireclayPalette.muted)
            content()
        }
    }

    private func actionLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .kilnText(.headline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap, alignment: .leading)
            .padding(.horizontal, FireclayPalette.space(2))
            .background(FireclayPalette.surface)
            .contentShape(Rectangle())
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { session.settings.reminderWeek != nil },
            set: { session.setReminder($0) }
        )
    }

    private var horizonBinding: Binding<Int> {
        Binding(
            get: { session.settings.forecastHorizonDays },
            set: { next in
                session.settings.forecastHorizonDays = max(1, next)
                session.saveSettings()
            }
        )
    }

    private var cadenceText: Binding<String> {
        Binding(
            get: { EmberFigures.days(session.settings.defaultCadenceDays) },
            set: { raw in
                let normalized = raw.replacingOccurrences(
                    of: Locale.current.decimalSeparator ?? ".",
                    with: "."
                )
                guard let value = Double(normalized), value > 0 else { return }
                session.settings.defaultCadenceDays = value
                session.saveSettings()
            }
        )
    }
}

/// Role: Presentation. Settings as a sheet over the kiln.
struct SettingsSheet: View {
    var session: EmberSession

    var body: some View {
        SettingsView(session: session)
    }
}
