import SwiftUI

/// Role: Presentation. Ranked falling rows. Restoke is the verb, not a hex copy of the wall.
struct FallingBandView: View {
    var bricks: [BrickHeat]
    var onRestoke: (UUID) -> Void
    var fillsPage: Bool

    init(
        bricks: [BrickHeat] = EmberSession.previewPopulated().graph.falling,
        onRestoke: @escaping (UUID) -> Void = { _ in },
        fillsPage: Bool = false
    ) {
        self.bricks = bricks
        self.onRestoke = onRestoke
        self.fillsPage = fillsPage
    }

    var body: some View {
        if bricks.isEmpty {
            KilnEmptyPlate(
                image: EmberArtName.emptyList,
                headline: "Nothing is falling.",
                line: "Catch the brick before it hits the floor.",
                fillsPage: fillsPage
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
                ForEach(bricks) { brick in
                    FallingRankRow(brick: brick) {
                        onRestoke(brick.person.id)
                    }
                }
            }
            .padding(FireclayPalette.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FireclayPalette.surface)
        }
    }
}

/// Role: Presentation. One falling forecast row. Tap restokes.
struct FallingRankRow: View {
    var brick: BrickHeat
    var onRestoke: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: FireclayPalette.space(2)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(brick.person.displayName)
                    .kilnText(.headline)
                    .foregroundStyle(FireclayPalette.ink)
                    .lineLimit(1)
                Text("Forecast \(EmberFigures.heat(brick.forecastT))")
                    .kilnText(.caption)
                    .monospacedDigit()
                    .foregroundStyle(FireclayPalette.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: FireclayPalette.space(1))
            Button(action: onRestoke) {
                Text("Restoke")
                    .kilnText(.headline)
                    .foregroundStyle(FireclayPalette.ink)
                    .padding(.horizontal, FireclayPalette.space(2))
                    .frame(minHeight: FireclayPalette.tap)
                    .background(FireclayPalette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Restoke \(brick.person.displayName)")
        }
        .padding(.vertical, FireclayPalette.space(1))
        .contentShape(Rectangle())
        .onTapGesture(perform: onRestoke)
        .accessibilityElement(children: .contain)
    }
}
