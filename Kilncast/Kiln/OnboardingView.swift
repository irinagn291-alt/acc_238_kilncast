import SwiftUI

/// Role: Presentation. Four plates. Skip still writes defaults and the completion flag.
struct OnboardingView: View {
    var session: EmberSession
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(session: EmberSession = .previewEmpty()) {
        self.session = session
    }

    var body: some View {
        VStack(spacing: 0) {
            plateContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, FireclayPalette.space(2))
                .animation(reduceMotion ? nil : FireclayPalette.motion, value: page)
            VStack(spacing: FireclayPalette.space(1)) {
                Button {
                    if page < 3 {
                        page += 1
                    } else {
                        session.finishOnboarding()
                    }
                } label: {
                    Text(page < 3 ? "Next" : "Open the kiln")
                        .kilnText(.headline)
                        .foregroundStyle(FireclayPalette.ink)
                        .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap)
                        .background(FireclayPalette.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page < 3 ? "Next" : "Open the kiln")
                Button {
                    session.finishOnboarding()
                } label: {
                    Text("Skip")
                        .kilnText(.headline)
                        .foregroundStyle(FireclayPalette.ink)
                        .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap)
                        .background(FireclayPalette.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, FireclayPalette.space(2))
            .padding(.bottom, FireclayPalette.space(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FireclayPalette.background.ignoresSafeArea())
        .safeAreaPadding(.bottom, FireclayPalette.space(1))
    }

    @ViewBuilder
    private var plateContent: some View {
        switch page {
        case 0:
            plate(
                image: "kln_Onboarding1",
                title: "Who will go cold",
                line: "Every brick is colored by heat seven days from now, not by the last hello."
            )
        case 1:
            plate(
                image: "kln_Onboarding2",
                title: "Restoke the falling brick",
                line: "Pick a channel and write a Touch. A tap without a log does not heat."
            )
        case 2:
            plate(
                image: "kln_Onboarding3",
                title: "Ash stays on the rail",
                line: "Never-touched sit at zero so they cannot hide inside the forecast."
            )
        default:
            plate(
                image: EmberArtName.twist,
                title: "Catch the freeze",
                line: "A warm name that will hit the floor this week outranks a stable ember."
            )
        }
    }

    private func plate(image: String, title: String, line: String) -> some View {
        VStack(spacing: FireclayPalette.space(2)) {
            EmberArt(name: image)
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipped()
            Text(title)
                .kilnText(.title)
                .foregroundStyle(FireclayPalette.ink)
                .multilineTextAlignment(.center)
            Text(line)
                .kilnText(.body)
                .foregroundStyle(FireclayPalette.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, FireclayPalette.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
