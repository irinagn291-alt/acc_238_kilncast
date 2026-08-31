import SwiftUI

/// Role: Presentation. Restoke screen. ReviewScreen log. Empty, populated, error.
struct RestokeView: View {
    var session: EmberSession

    init(session: EmberSession = .previewRestoke()) {
        self.session = session
    }

    var body: some View {
        NavigationStack {
            RestokeComposer(session: session)
                .navigationTitle("Restoke")
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
