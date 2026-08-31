import SwiftUI
@testable import Kilncast

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("kiln", AnyView(KilnRootView())),
            ("restoke", AnyView(RestokeView())),
            ("settings", AnyView(SettingsView()))
        ]
    }
}
