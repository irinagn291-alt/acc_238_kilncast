import SwiftUI
import UIKit

/// Role: Presentation. Pointy hex. Used as a clip, not a stored heat.
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let radius = min(rect.width, rect.height) / 2
        for index in 0 ..< 6 {
            let angle = (CGFloat.pi / 2) + (CGFloat(index) * .pi / 3)
            let point = CGPoint(x: cx + radius * cos(angle), y: cy + radius * sin(angle))
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// Role: Presentation. Forecast T fill plus a non-colour cue. Heat is derived.
struct BrickFace: View {
    var brick: BrickHeat
    var pressed: Bool = false
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        brick: BrickHeat = BrickHeat(
            person: KilnPerson(id: KilnSeed.marloweID, displayName: "Marlowe", cadenceDays: 7),
            lastTouchAt: EmberSession.previewNow,
            currentT: 80,
            forecastT: 22,
            band: .falling
        ),
        pressed: Bool = false
    ) {
        self.brick = brick
        self.pressed = pressed
    }

    var body: some View {
        let compact = sizeCategory >= .accessibilityMedium
        ZStack {
            FireclayPalette.brickFill(forecastT: brick.forecastT)
            HexagonShape()
                .stroke(strokeColor, lineWidth: 1.5)
            VStack(spacing: 0) {
                BandMark(band: brick.band)
                    .frame(width: 16, height: 12)
                Text(brick.person.displayName)
                    .kilnText(compact ? .micro : .caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .truncationMode(.tail)
                Text(EmberFigures.heat(brick.forecastT))
                    .kilnText(compact ? .caption : .headline)
                    .monospacedDigit()
                    .lineLimit(1)
                Text(bandWord)
                    .kilnText(.micro)
                    .foregroundStyle(FireclayPalette.ink.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(.horizontal, FireclayPalette.space(1))
            .foregroundStyle(FireclayPalette.ink)
            if pressed {
                HexagonShape()
                    .fill(FireclayPalette.ink.opacity(0.14))
            }
        }
        .clipShape(HexagonShape())
        .scaleEffect(!reduceMotion && pressed ? 0.96 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spoken(brick))
        .accessibilityAddTraits(.isButton)
    }

    private var bandWord: String {
        switch brick.band {
        case .ash: return "First touch"
        case .falling: return "Falling"
        case .hot: return "Holding"
        }
    }

    private var strokeColor: Color {
        switch brick.band {
        case .ash: return FireclayPalette.muted
        case .falling: return FireclayPalette.accent.opacity(0.85)
        case .hot: return FireclayPalette.ink.opacity(0.35)
        }
    }

    static func spoken(_ brick: BrickHeat) -> String {
        let heat = EmberFigures.heat(brick.forecastT)
        let band: String
        switch brick.band {
        case .ash: band = "ash rail, never touched"
        case .falling: band = "falling, forecast \(heat)"
        case .hot: band = "holding, forecast \(heat)"
        }
        return "\(brick.person.displayName), \(band)"
    }
}

/// Role: Presentation. Crack, ember, or ash hatch. Colour is never the only signal.
struct BandMark: View {
    var band: DecayBand = .falling

    var body: some View {
        Canvas { context, size in
            let box = CGRect(origin: .zero, size: size)
            context.stroke(
                Path { path in
                    switch band {
                    case .ash:
                        path.move(to: CGPoint(x: 1, y: 2))
                        path.addLine(to: CGPoint(x: size.width - 1, y: size.height - 2))
                        path.move(to: CGPoint(x: 1, y: size.height / 2))
                        path.addLine(to: CGPoint(x: size.width - 1, y: size.height / 2))
                        path.move(to: CGPoint(x: 1, y: size.height - 2))
                        path.addLine(to: CGPoint(x: size.width - 1, y: 2))
                    case .falling:
                        path.move(to: CGPoint(x: size.width * 0.35, y: 1))
                        path.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.45))
                        path.addLine(to: CGPoint(x: size.width * 0.4, y: size.height * 0.55))
                        path.addLine(to: CGPoint(x: size.width * 0.65, y: size.height - 1))
                    case .hot:
                        path.addEllipse(in: box.insetBy(dx: size.width * 0.28, dy: size.height * 0.18))
                    }
                },
                with: .color(FireclayPalette.ink.opacity(0.9)),
                lineWidth: 1.2
            )
        }
        .accessibilityHidden(true)
    }
}

/// Role: Presentation. UICollectionView brick. Binds a HeatCell snapshot; owns no T.
@MainActor
final class BrickCell: UICollectionViewCell {
    static let reuseID = "BrickCell"

    func apply(_ brick: BrickHeat, pressed: Bool = false) {
        contentConfiguration = UIHostingConfiguration {
            BrickFace(brick: brick, pressed: pressed)
        }
        .margins(.all, 0)
        .minSize(width: FireclayPalette.tap, height: FireclayPalette.tap)
        var clear = UIBackgroundConfiguration.listPlainCell()
        clear.backgroundColor = .clear
        backgroundConfiguration = clear
        isAccessibilityElement = true
        accessibilityLabel = BrickFace.spoken(brick)
        accessibilityTraits = .button
    }
}
