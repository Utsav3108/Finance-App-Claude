import SwiftUI

/// Spent (solid) / left (same hue at 40% + hatch). Always hidden from VoiceOver; the owner supplies text.
struct ProgressBar: View {
    enum Height {
        case large, medium, compact
        var points: CGFloat {
            switch self {
            case .large: 16
            case .medium: 12
            case .compact: 4
            }
        }
    }

    /// 0...1 (values outside are clamped for drawing).
    let fraction: Double
    let tint: Color
    var height: Height = .medium

    @ScaledMetric(relativeTo: .footnote) private var scale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let clamped = min(max(fraction.isFinite ? fraction : 0, 0), 1)
        let h = height.points * (height == .compact ? 1 : scale)
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppRadius.bar)
                    .fill(tint.opacity(0.4))
                    .overlay {
                        if !reduceTransparency && height != .compact {
                            HatchPattern().stroke(tint.opacity(0.4), lineWidth: 2).clipShape(RoundedRectangle(cornerRadius: AppRadius.bar))
                        }
                    }
                RoundedRectangle(cornerRadius: AppRadius.bar)
                    .fill(tint)
                    .frame(width: proxy.size.width * clamped)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: clamped)
            }
        }
        .frame(height: h)
        .accessibilityHidden(true)
    }
}

private struct HatchPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 8
        var x = -rect.height
        while x < rect.width {
            path.move(to: CGPoint(x: x, y: rect.height))
            path.addLine(to: CGPoint(x: x + rect.height, y: 0))
            x += step
        }
        return path
    }
}

#Preview("ProgressBar") {
    VStack(spacing: 16) {
        ProgressBar(fraction: 0.37, tint: AppColor.accentWarning, height: .large)
        ProgressBar(fraction: 0.72, tint: AppColor.accentBrand, height: .medium)
        ProgressBar(fraction: 1.4, tint: AppColor.expense, height: .medium)
        ProgressBar(fraction: 0.5, tint: AppColor.accentMarigold, height: .compact)
    }
    .padding()
    .background(AppColor.surface)
}
