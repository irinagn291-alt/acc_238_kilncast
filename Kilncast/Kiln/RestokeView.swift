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
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            session.sheet = nil
                        }
                        .tint(FireclayPalette.ink)
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
