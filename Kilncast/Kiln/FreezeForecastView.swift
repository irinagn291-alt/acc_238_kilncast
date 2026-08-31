import SwiftUI

/// Role: Presentation. Twist screen: 7-day predicted heat rank. Not a tab.
struct FreezeForecastView: View {
    var session: EmberSession

    init(session: EmberSession = .previewPopulated()) {
        self.session = session
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FireclayPalette.space(2)) {
                    EmberArt(name: EmberArtName.twist)
                        .frame(maxHeight: 180)
                        .frame(maxWidth: .infinity)
                    Text("Imminent freeze")
                        .kilnText(.display)
                        .foregroundStyle(FireclayPalette.ink)
                    Text("Ranked by heat seven days from now. A warm name that will go cold this week sits above a stable ember.")
                        .kilnText(.body)
                        .foregroundStyle(FireclayPalette.muted)
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
                        KilnEmptyPlate(action: { session.openAddPerson() })
                    } else {
                        FallingBandView(bricks: session.graph.falling)
                        KilnWallHost(bricks: session.graph.kilnWall, onSelect: session.openRestoke)
                        AshRailView(bricks: session.graph.ash, onSelect: session.openRestoke)
                    }
                }
                .padding(.horizontal, FireclayPalette.space(2))
                .padding(.vertical, FireclayPalette.space(2))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FireclayPalette.background.ignoresSafeArea())
            .navigationTitle("Forecast")
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
}
