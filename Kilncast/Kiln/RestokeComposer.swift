import SwiftUI

/// Role: Presentation. In-place Restoke. Channel plus Touch body. Empty body does not heat.
struct RestokeComposer: View {
    var session: EmberSession
    @FocusState private var bodyFocused: Bool

    init(session: EmberSession = .previewRestoke()) {
        self.session = session
    }

    var body: some View {
        let brick = session.restokeBrick()
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
                        action: { session.openAddPerson() }
                    )
                }
                Picker("Channel", selection: channelBinding) {
                    ForEach(RestokeChannel.allCases, id: \.self) { channel in
                        Text(label(channel)).tag(channel)
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
                .disabled(session.commitBusy)
                .accessibilityLabel("Restoke")
            }
            .padding(FireclayPalette.space(2))
        }
        .scrollDismissesKeyboard(.interactively)
        .background(FireclayPalette.background.ignoresSafeArea())
        .simultaneousGesture(TapGesture().onEnded { bodyFocused = false })
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

    private func label(_ channel: RestokeChannel) -> String {
        switch channel {
        case .voice: return "Voice"
        case .letter: return "Letter"
        case .visit: return "Visit"
        case .note: return "Note"
        }
    }
}
