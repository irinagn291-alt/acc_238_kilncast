import SwiftUI

/// Role: Presentation. In-place Restoke. Channel plus Touch body. Empty body does not heat.
struct RestokeComposer: View {
    var session: EmberSession
    @FocusState private var bodyFocused: Bool
    @State private var confirmDelete = false

    init(session: EmberSession = .previewRestoke()) {
        self.session = session
    }

    var body: some View {
        let brick = session.restokeBrick()
        let history = session.restokeTouches()
        ScrollView {
            VStack(alignment: .leading, spacing: FireclayPalette.space(2)) {
                if let fault = session.fault {
                    Text(fault)
                        .kilnText(.body)
                        .foregroundStyle(FireclayPalette.accent)
                    Button("Retry") {
                        Task { await session.commitRestoke() }
                    }
                    .kilnText(.headline)
                    .foregroundStyle(FireclayPalette.accent)
                    .kilnTap()
                    .disabled(session.commitBusy)
                }
                if let brick {
                    HStack(alignment: .firstTextBaseline) {
                        Text(brick.person.displayName)
                            .kilnText(.title)
                            .lineLimit(1)
                        Spacer(minLength: FireclayPalette.space(1))
                        Text(EmberFigures.heat(brick.forecastT))
                            .kilnText(.title)
                            .monospacedDigit()
                            .foregroundStyle(FireclayPalette.accent)
                    }
                    .foregroundStyle(FireclayPalette.ink)
                    Text(brick.band == .ash ? "Ash rail · never touched" : "Forecast in \(EmberFigures.count(session.settings.forecastHorizonDays)) days")
                        .kilnText(.caption)
                        .foregroundStyle(FireclayPalette.muted)
                } else {
                    KilnEmptyPlate(
                        image: EmberArtName.emptyList,
                        headline: "No brick to restoke.",
                        line: "Add a person on the kiln wall, then write a Touch.",
                        actionTitle: "Add a person",
                        action: { session.openAddPerson() },
                        fillsPage: false
                    )
                }
                Picker("Channel", selection: channelBinding) {
                    ForEach(RestokeChannel.allCases, id: \.self) { channel in
                        Text(channel.title).tag(channel)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(brick == nil)
                .frame(minHeight: FireclayPalette.tap)
                TextField("What did you say?", text: bodyBinding, axis: .vertical)
                    .kilnText(.body)
                    .focused($bodyFocused)
                    .lineLimit(3 ... 6)
                    .padding(FireclayPalette.space(1))
                    .background(FireclayPalette.surface)
                    .foregroundStyle(FireclayPalette.ink)
                    .disabled(brick == nil)
                    .submitLabel(.done)
                Button {
                    bodyFocused = false
                    Task { await session.commitRestoke() }
                } label: {
                    Text("Restoke")
                        .kilnText(.headline)
                        .foregroundStyle(FireclayPalette.ink)
                        .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap)
                        .background(FireclayPalette.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(session.commitBusy || brick == nil)
                .accessibilityLabel("Restoke")
                if brick != nil {
                    labeled("Cadence, days") {
                        Stepper(value: cadenceBinding, in: 1 ... 90, step: 1) {
                            Text(EmberFigures.days(session.restokeCadenceDays))
                                .kilnText(.headline)
                                .monospacedDigit()
                                .foregroundStyle(FireclayPalette.ink)
                        }
                        .frame(minHeight: FireclayPalette.tap)
                    }
                    if !history.isEmpty {
                        labeled("Last touches") {
                            ForEach(Array(history.prefix(3))) { touch in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(touch.channel.title) · \(EmberFigures.when(touch.touchedAt))")
                                        .kilnText(.caption)
                                        .foregroundStyle(FireclayPalette.muted)
                                        .lineLimit(1)
                                    Text(touch.body)
                                        .kilnText(.body)
                                        .foregroundStyle(FireclayPalette.ink)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    Button {
                        confirmDelete = true
                    } label: {
                        Text("Remove from kiln")
                            .kilnText(.headline)
                            .foregroundStyle(FireclayPalette.ink)
                            .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap, alignment: .leading)
                            .padding(.horizontal, FireclayPalette.space(2))
                            .background(FireclayPalette.surface)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(session.commitBusy)
                    .accessibilityLabel("Remove from kiln")
                }
            }
            .padding(FireclayPalette.space(2))
        }
        .scrollDismissesKeyboard(.interactively)
        .background(FireclayPalette.background.ignoresSafeArea())
        .simultaneousGesture(TapGesture().onEnded { bodyFocused = false })
        .confirmationDialog(
            "Remove this brick and every touch?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Remove from kiln", role: .destructive) {
                Task { await session.deleteRestokePerson() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var channelBinding: Binding<RestokeChannel> {
        Binding(
            get: { session.draft.channel },
            set: { session.draft.channel = $0 }
        )
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { session.draft.body },
            set: { session.draft.body = $0 }
        )
    }

    private var cadenceBinding: Binding<Double> {
        Binding(
            get: { session.restokeCadenceDays },
            set: { next in
                session.restokeCadenceDays = max(1, next)
                Task { await session.updateRestokeCadence() }
            }
        )
    }

    private func labeled(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
            Text(title)
                .kilnText(.caption)
                .foregroundStyle(FireclayPalette.muted)
            content()
        }
    }
}
