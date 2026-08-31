import SwiftUI
import UIKit

/// Role: Presentation. Firebrick kiln tokens. Hex lives only here.
enum FireclayPalette {
    static let backgroundHex = "#140E0C"
    static let surfaceHex = "#2B1A14"
    static let inkHex = "#F4E6D4"
    static let accentHex = "#E24A1B"
    static let mutedHex = "#A08978"

    static let background = Color("kln_background")
    static let surface = Color("kln_surface")
    static let ink = Color("kln_ink")
    static let accent = Color("kln_accent")
    static let muted = Color("kln_muted")

    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let radius: CGFloat = 0
    static let motion = Animation.easeInOut(duration: 0.28)

    static var backgroundUI: UIColor { named("kln_background", red: 20, green: 14, blue: 12) }
    static var surfaceUI: UIColor { named("kln_surface", red: 43, green: 26, blue: 20) }
    static var inkUI: UIColor { named("kln_ink", red: 244, green: 230, blue: 212) }
    static var accentUI: UIColor { named("kln_accent", red: 226, green: 74, blue: 27) }
    static var mutedUI: UIColor { named("kln_muted", red: 160, green: 137, blue: 120) }

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    /// Brick fill tracks forecast T. Pair with a glyph so colour is never the only cue.
    static func brickFill(forecastT: Double) -> Color {
        let t = min(1, max(0, forecastT / 100))
        return Color(
            red: lerp(20, 226, t) / 255,
            green: lerp(14, 74, t) / 255,
            blue: lerp(12, 27, t) / 255
        )
    }

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    private static func named(_ name: String, red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(named: name) ?? UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}

/// Role: Presentation. Generated art with a kiln fallback when the set is missing.
struct EmberArt: View {
    var name: String = EmberArtName.emptyHome

    var body: some View {
        Group {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                KilnMark()
            }
        }
        .accessibilityHidden(true)
    }
}

/// Role: Presentation. Painted kiln wall when the asset set is missing.
struct KilnMark: View {
    var body: some View {
        Canvas { context, size in
            let box = CGRect(origin: .zero, size: size)
            context.fill(Path(box), with: .color(FireclayPalette.surface))
            let hexHeight = min(size.width, size.height) * 0.42
            let hexWidth = hexHeight * CGFloat(3).squareRoot() / 2
            let xStride = hexWidth * 0.92
            let yStride = hexHeight * 0.72
            let temps: [Double] = [18, 42, 88, 6, 28, 71]
            var index = 0
            for row in 0 ..< 2 {
                for col in 0 ..< 3 {
                    let stagger = row.isMultiple(of: 2) ? 0 : xStride / 2
                    let cx = size.width * 0.16 + CGFloat(col) * xStride + stagger
                    let cy = size.height * 0.28 + CGFloat(row) * yStride
                    let frame = CGRect(
                        x: cx - hexWidth / 2,
                        y: cy - hexHeight / 2,
                        width: hexWidth,
                        height: hexHeight
                    )
                    let path = HexagonShape().path(in: frame)
                    let heat = temps[index % temps.count]
                    index += 1
                    context.fill(path, with: .color(FireclayPalette.brickFill(forecastT: heat)))
                    context.stroke(
                        path,
                        with: .color(FireclayPalette.ink.opacity(0.35)),
                        lineWidth: 1.2
                    )
                }
            }
            let mouth = CGRect(
                x: size.width * 0.34,
                y: size.height * 0.62,
                width: size.width * 0.32,
                height: size.height * 0.22
            )
            context.fill(Path(ellipseIn: mouth), with: .color(FireclayPalette.accent.opacity(0.85)))
            context.stroke(
                Path(ellipseIn: mouth.insetBy(dx: 2, dy: 2)),
                with: .color(FireclayPalette.ink.opacity(0.4)),
                lineWidth: 1
            )
        }
        .accessibilityHidden(true)
    }
}
