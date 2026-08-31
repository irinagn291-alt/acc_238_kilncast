import SwiftUI

/// Role: Presentation. Hive is the kiln wall. Empty, populated, and error.
struct HiveView: View {
    var session: EmberSession

    init(session: EmberSession = .previewPopulated()) {
        self.session = session
    }

    var body: some View {
        KilnView(session: session, title: "Hive", emphasizesFalling: false)
    }
}
