import SwiftUI

/// Role: Presentation. Host. The kiln is home; Restoke and Settings arrive as sheets.
struct ContentView: View {
    var session: EmberSession

    init(session: EmberSession = .previewPopulated()) {
        self.session = session
    }

    var body: some View {
        KilnRootView(session: session)
    }
}

#Preview {
    ContentView()
}
