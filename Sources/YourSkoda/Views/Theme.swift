import SwiftUI

enum Theme {
    static let skodaGreen = Color(red: 0.05, green: 0.66, blue: 0.32)     // #0FA852-ish
    static let skodaDeep = Color(red: 0.02, green: 0.16, blue: 0.12)
    static let electric = Color(red: 0.29, green: 0.78, blue: 0.90)
    static let warnOrange = Color(red: 0.95, green: 0.6, blue: 0.15)
    static let dangerRed = Color(red: 0.86, green: 0.24, blue: 0.24)

    static func batteryColor(_ percent: Int) -> Color {
        switch percent {
        case ..<20: return dangerRed
        case 20..<50: return warnOrange
        default: return skodaGreen
        }
    }
}

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var trailing: (() -> AnyView)? = nil

    var body: some View {
        HStack {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.skodaGreen)
            }
            Text(title)
                .font(.headline)
            Spacer()
            trailing?()
        }
    }
}

struct PillLabel: View {
    let text: String
    var color: Color = .secondary
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15), in: Capsule())
        .foregroundStyle(color)
    }
}

struct LoadingButton: View {
    let title: String
    let systemImage: String
    var role: ButtonRole? = nil
    var isLoading: Bool
    var tint: Color = Theme.skodaGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .frame(minWidth: 90)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .disabled(isLoading)
    }
}
