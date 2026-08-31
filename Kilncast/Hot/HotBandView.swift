import SwiftUI

/// Role: Presentation. Derived holding partition. Forecast T at or above the ceiling.
struct HotBandView: View {
    var bricks: [BrickHeat]

    init(bricks: [BrickHeat] = EmberSession.previewPopulated().graph.hot) {
        self.bricks = bricks
    }

    var body: some View {
        if bricks.isEmpty {
            KilnEmptyPlate(
                image: EmberArtName.emptyList,
                headline: "Nothing is holding.",
                line: "Restoke a brick to keep the heat.",
                fillsPage: true
            )
        } else {
            VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
                HStack(spacing: FireclayPalette.space(1)) {
                    BandMark(band: .hot)
                        .frame(width: 16, height: 14)
                    Text("Holding")
                        .kilnText(.headline)
                    Text(EmberFigures.count(bricks.count))
                        .kilnText(.caption)
                        .monospacedDigit()
                        .foregroundStyle(FireclayPalette.muted)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(FireclayPalette.ink)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FireclayPalette.space(1)) {
                        ForEach(bricks) { brick in
                            BrickFace(brick: brick)
                                .frame(width: 88, height: 96)
                        }
                    }
                }
            }
            .padding(FireclayPalette.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FireclayPalette.surface)
            .accessibilityElement(children: .combine)
        }
    }
}
