import SwiftUI

/// Role: Presentation. Derived falling partition. Same wall as Hive and Coldest.
struct FallingBandView: View {
    var bricks: [BrickHeat]

    init(bricks: [BrickHeat] = EmberSession.previewPopulated().graph.falling) {
        self.bricks = bricks
    }

    var body: some View {
        if bricks.isEmpty {
            KilnEmptyPlate(
                image: EmberArtName.emptyList,
                headline: "Nothing is falling.",
                line: "Catch the brick before it hits the floor.",
                fillsPage: true
            )
        } else {
            VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
                HStack(spacing: FireclayPalette.space(1)) {
                    BandMark(band: .falling)
                        .frame(width: 16, height: 14)
                    Text("Falling")
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
