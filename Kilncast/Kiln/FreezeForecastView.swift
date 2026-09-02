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
                        .frame(maxHeight: 120)
                        .frame(maxWidth: .infinity)
                    Text("Imminent freeze")
                        .kilnText(.display)
                        .foregroundStyle(FireclayPalette.ink)
                    Text("Ranked by heat seven days from now. Restoke the name that will go cold this week.")
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
                        KilnEmptyPlate(action: { session.openAddPerson() }, fillsPage: false)
                    } else if session.graph.falling.isEmpty {
                        VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
                            Text("Nothing is falling.")
                                .kilnText(.headline)
                                .foregroundStyle(FireclayPalette.ink)
                            Text("Catch the brick before it hits the floor.")
                                .kilnText(.body)
                                .foregroundStyle(FireclayPalette.muted)
                        }
                        AshRailView(bricks: session.graph.ash, onSelect: session.openRestoke)
                    } else {
                        FallingBandView(
                            bricks: session.graph.falling,
                            onRestoke: session.openRestoke,
                            fillsPage: false
                        )
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
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            session.sheet = nil
                        }
                        .tint(FireclayPalette.ink)
                    }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
