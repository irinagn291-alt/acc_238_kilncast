import SwiftUI

/// Role: Presentation. Never-touched stay at 0 here. They cannot hide in the forecast.
struct AshRailView: View {
    var bricks: [BrickHeat]
    var onSelect: (UUID) -> Void

    init(
        bricks: [BrickHeat] = EmberSession.previewPopulated().graph.ash,
        onSelect: @escaping (UUID) -> Void = { _ in }
    ) {
        self.bricks = bricks
        self.onSelect = onSelect
    }

    var body: some View {
        if bricks.isEmpty {
            KilnEmptyPlate(
                image: EmberArtName.emptyList,
                headline: "Ash rail is cold.",
                line: "Never-touched bricks sit here at zero.",
                fillsPage: true
            )
        } else {
            VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
                Text("Ash rail")
                    .kilnText(.caption)
                    .foregroundStyle(FireclayPalette.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FireclayPalette.space(1)) {
                        ForEach(bricks) { brick in
                            Button {
                                onSelect(brick.person.id)
                            } label: {
                                BrickFace(brick: brick)
                                    .frame(width: 88, height: 96)
                            }
                            .buttonStyle(.plain)
                            .kilnTap()
                            .accessibilityLabel(BrickFace.spoken(brick))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FireclayPalette.space(2))
            .background(FireclayPalette.surface)
        }
    }
}
