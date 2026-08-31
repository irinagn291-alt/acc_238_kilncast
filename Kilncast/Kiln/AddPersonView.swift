import SwiftUI

/// Role: Presentation. Name plus cadence. New bricks start on the ash rail.
struct AddPersonView: View {
    var session: EmberSession
    @FocusState private var nameFocused: Bool

    init(session: EmberSession = .previewEmpty()) {
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
                            Task { await session.commitPerson() }
                        }
                        .kilnText(.headline)
                        .foregroundStyle(FireclayPalette.accent)
                        .kilnTap()
                        .disabled(session.commitBusy)
                    }
                    Text("How often should they be touched?")
                        .kilnText(.body)
                        .foregroundStyle(FireclayPalette.muted)
                    TextField("Name", text: nameBinding)
                        .kilnText(.headline)
                        .focused($nameFocused)
                        .padding(FireclayPalette.space(1))
                        .frame(minHeight: FireclayPalette.tap)
                        .background(FireclayPalette.surface)
                        .foregroundStyle(FireclayPalette.ink)
                        .submitLabel(.done)
                    HStack {
                        Text("Cadence, days")
                            .kilnText(.caption)
                            .foregroundStyle(FireclayPalette.muted)
                        Spacer()
                        TextField("Days", text: cadenceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .kilnText(.headline)
                            .monospacedDigit()
                            .foregroundStyle(FireclayPalette.ink)
                            .frame(minWidth: FireclayPalette.tap, minHeight: FireclayPalette.tap)
                    }
                    Button {
                        nameFocused = false
                        Task { await session.commitPerson() }
                    } label: {
                        Text("Add to the kiln")
                            .kilnText(.headline)
                            .foregroundStyle(FireclayPalette.ink)
                            .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap)
                            .background(FireclayPalette.accent)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(session.commitBusy)
                }
                .padding(FireclayPalette.space(2))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FireclayPalette.background.ignoresSafeArea())
            .simultaneousGesture(TapGesture().onEnded { nameFocused = false })
            .navigationTitle("Add a person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        session.sheet = nil
                    } label: {
                        Text("Close")
                            .kilnText(.headline)
                            .foregroundStyle(FireclayPalette.ink)
                            .padding(.horizontal, FireclayPalette.space(1))
                            .kilnTap()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { session.addName },
            set: { session.addName = $0 }
        )
    }

    private var cadenceText: Binding<String> {
        Binding(
            get: { EmberFigures.days(session.addCadenceDays) },
            set: { raw in
                let normalized = raw.replacingOccurrences(
                    of: Locale.current.decimalSeparator ?? ".",
                    with: "."
                )
                guard let value = Double(normalized), value > 0 else { return }
                session.addCadenceDays = value
            }
        )
    }
}
