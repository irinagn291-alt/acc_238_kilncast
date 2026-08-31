import SwiftUI

/// Role: Presentation. Futura only. Six steps. Tabular T through EmberFigures.
enum FuturaScale {
    static let family = "Futura"

    enum Step: CaseIterable {
        case display
        case title
        case headline
        case body
        case caption
        case micro

        var size: CGFloat {
            switch self {
            case .display: return 28
            case .title: return 22
            case .headline: return 17
            case .body: return 16
            case .caption: return 13
            case .micro: return 11
            }
        }

        var style: Font.TextStyle {
            switch self {
            case .display: return .largeTitle
            case .title: return .title2
            case .headline: return .headline
            case .body: return .body
            case .caption: return .caption
            case .micro: return .caption2
            }
        }

        /// Medium for kiln titles and T. Book is not on iOS; Medium carries body.
        var face: String {
            "Futura-Medium"
        }
    }

    static func font(_ step: Step) -> Font {
        .custom(step.face, size: step.size, relativeTo: step.style)
    }
}

enum EmberFigures {
    static func heat(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value.rounded())) ?? "—"
    }

    static func days(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value == value.rounded() ? 0 : 1
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func count(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}

extension View {
    func kilnText(_ step: FuturaScale.Step) -> some View {
        font(FuturaScale.font(step))
    }

    func kilnTap() -> some View {
        frame(minWidth: FireclayPalette.tap, minHeight: FireclayPalette.tap)
        .contentShape(Rectangle())
    }
}
