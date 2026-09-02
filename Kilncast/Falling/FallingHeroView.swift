import SwiftUI

/// Role: Presentation. Coldest falling brick. Primary restoke verb on the kiln.
struct FallingHeroView: View {
    var brick: BrickHeat
    var horizonDays: Int
    var onRestoke: (RestokeChannel) -> Void

    init(
        brick: BrickHeat,
        horizonDays: Int = ForecastRank.defaultHorizonDays,
        onRestoke: @escaping (RestokeChannel) -> Void = { _ in }
    ) {
        self.brick = brick
        self.horizonDays = horizonDays
        self.onRestoke = onRestoke
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FireclayPalette.space(2)) {
            HStack(alignment: .firstTextBaseline) {
                Text(brick.person.displayName)
                    .kilnText(.title)
                    .lineLimit(1)
                Spacer(minLength: FireclayPalette.space(1))
                Text(EmberFigures.heat(brick.forecastT))
                    .kilnText(.title)
                    .monospacedDigit()
                    .foregroundStyle(FireclayPalette.accent)
                    .lineLimit(1)
            }
            .foregroundStyle(FireclayPalette.ink)
            Text("Forecast in \(EmberFigures.count(horizonDays)) days")
                .kilnText(.caption)
                .foregroundStyle(FireclayPalette.muted)
                .lineLimit(1)
            Button {
                onRestoke(.note)
            } label: {
                Text("Restoke")
                    .kilnText(.headline)
                    .foregroundStyle(FireclayPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap)
                    .background(FireclayPalette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Restoke \(brick.person.displayName)")
            HStack(spacing: FireclayPalette.space(1)) {
                ForEach(RestokeChannel.allCases, id: \.self) { channel in
                    Button {
                        onRestoke(channel)
                    } label: {
                        Text(channel.title)
                            .kilnText(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(FireclayPalette.ink)
                            .frame(maxWidth: .infinity, minHeight: FireclayPalette.tap)
                            .background(FireclayPalette.background)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Restoke \(brick.person.displayName) by \(channel.title)")
                }
            }
        }
        .padding(FireclayPalette.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FireclayPalette.surface)
    }
}
