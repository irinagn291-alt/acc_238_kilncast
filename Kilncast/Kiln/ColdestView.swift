import SwiftUI

/// Role: Presentation. Coldest is the same wall, falling bricks first. Not a tab.
struct ColdestView: View {
    var session: EmberSession

    init(session: EmberSession = .previewPopulated()) {
        self.session = session
    }

    var body: some View {
        KilnView(session: session, title: "Coldest", emphasizesFalling: true)
    }
}
