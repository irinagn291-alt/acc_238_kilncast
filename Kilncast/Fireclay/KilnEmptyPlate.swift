import SwiftUI

/// Role: Presentation. Catalog names. Images arrive in a later asset step.
enum EmberArtName {
    static let emptyHome = "kln_EmptyHome"
    static let emptyList = "kln_EmptyList"
    static let card = "kln_CardBackdrop"
    static let control = "kln_ControlFace"
    static let twist = "kln_TwistHero"
    static let success = "kln_SuccessMark"
    static let header = "kln_HeaderDecor"
    static let splash = "kln_Splash"
}

/// Role: Presentation. Empty plate: generated art, one headline, one line, one CTA.
struct KilnEmptyPlate: View {
    var image: String = EmberArtName.emptyHome
    var headline: String = "The hive is cold."
    var line: String = "Add a person and restoke."
    var actionTitle: String = "Add a person"
    var action: () -> Void = {}
    var fillsPage: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: FireclayPalette.space(2)) {
                EmberArt(name: image)
                    .frame(maxWidth: 280)
                    .frame(height: 240)
                    .clipped()
                Text(headline)
                    .kilnText(.title)
                    .foregroundStyle(FireclayPalette.ink)
                    .multilineTextAlignment(.center)
                Text(line)
                    .kilnText(.body)
                    .foregroundStyle(FireclayPalette.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: fillsPage ? .infinity : nil, alignment: .top)
            Button(action: action) {
                Text(actionTitle)
                    .kilnText(.headline)
                    .foregroundStyle(FireclayPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap)
                    .background(FireclayPalette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(FireclayPalette.space(3))
        .frame(maxWidth: .infinity, maxHeight: fillsPage ? .infinity : nil)
    }
}

/// Role: Presentation. Brief ember after a successful Touch. Reduce Motion fades only.
struct EmberFlash: View {
    var visible: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        EmberArt(name: EmberArtName.success)
            .frame(width: 128, height: 128)
            .opacity(visible ? 1 : 0)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : FireclayPalette.motion, value: visible)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}
