import SwiftUI
import UIKit

enum LuneraTheme {
    static let background = Color(red: 0.965, green: 0.955, blue: 0.94)
    static let ink = Color(red: 0.08, green: 0.075, blue: 0.07)
    static let softInk = Color(red: 0.35, green: 0.32, blue: 0.29)
    static let line = Color(red: 0.83, green: 0.80, blue: 0.76)
    static let clay = Color(red: 0.62, green: 0.48, blue: 0.39)
    static let moss = Color(red: 0.37, green: 0.43, blue: 0.35)
    static let paper = Color(red: 0.99, green: 0.985, blue: 0.97)
}

struct LuneraButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .luneraLiquidGlassRounded(.primary, cornerRadius: 8, scale: 1)
    }
}

struct LuneraTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 15))
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(LuneraTheme.paper)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(LuneraTheme.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LuneraLogo: View {
    let width: CGFloat

    var body: some View {
        Image("LuneraLogo")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .accessibilityLabel("Lunera")
    }
}

struct LuneraProfileAvatarButton: View {
    let size: CGFloat
    let scale: CGFloat
    let action: () -> Void

    init(size: CGFloat, scale: CGFloat, action: @escaping () -> Void = {}) {
        self.size = size
        self.scale = scale
        self.action = action
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image("ProfileAvatar")
                .resizable()
                .scaledToFill()
                .frame(width: size * 0.72, height: size * 0.72)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.92), lineWidth: max(1, 1.4 * scale))
                }
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
        .luneraLiquidGlassCircle(.secondary, scale: scale)
    }
}

enum LuneraLiquidGlassStyle {
    case primary
    case secondary
    case control

    var fallbackFill: Color {
        switch self {
        case .primary:
            Color(red: 0.110, green: 0.137, blue: 0.200)
        case .secondary:
            .white.opacity(0.84)
        case .control:
            Color(red: 0.898, green: 0.900, blue: 0.914)
        }
    }

    var supportingFillOpacity: Double {
        switch self {
        case .primary:
            0.32
        case .secondary:
            0.48
        case .control:
            0.42
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary:
            .black.opacity(0.18)
        case .secondary:
            .black.opacity(0.055)
        case .control:
            .black.opacity(0.035)
        }
    }

    @available(iOS 26.0, *)
    var glass: Glass {
        switch self {
        case .primary:
            .regular.tint(fallbackFill).interactive()
        case .secondary:
            .regular.tint(.white.opacity(0.5)).interactive()
        case .control:
            .regular.tint(fallbackFill.opacity(0.62)).interactive()
        }
    }
}

extension View {
    @ViewBuilder
    func luneraLiquidGlassCircle(_ style: LuneraLiquidGlassStyle, scale: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(style.fallbackFill.opacity(style.supportingFillOpacity), in: Circle())
                .glassEffect(style.glass, in: Circle())
                .shadow(color: .white.opacity(0.72), radius: 1.5 * scale, x: -0.5 * scale, y: -0.5 * scale)
                .shadow(color: style.shadowColor, radius: glassShadowRadius(for: style, scale: scale), x: 0, y: glassShadowOffset(for: style, scale: scale))
        } else {
            self
                .background(style.fallbackFill.opacity(max(style.supportingFillOpacity, 0.72)), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.86), lineWidth: max(1, 1.2 * scale))
                }
                .shadow(color: .black.opacity(0.045), radius: 7 * scale, x: 0, y: 2 * scale)
        }
    }

    @ViewBuilder
    func luneraLiquidGlassCapsule(_ style: LuneraLiquidGlassStyle, scale: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(style.fallbackFill.opacity(style.supportingFillOpacity), in: Capsule())
                .glassEffect(style.glass, in: Capsule())
                .shadow(color: style.shadowColor, radius: glassShadowRadius(for: style, scale: scale), x: 0, y: glassShadowOffset(for: style, scale: scale))
        } else {
            self
                .background(style.fallbackFill, in: Capsule())
                .shadow(color: style.shadowColor, radius: glassShadowRadius(for: style, scale: scale), x: 0, y: glassShadowOffset(for: style, scale: scale))
        }
    }

    @ViewBuilder
    func luneraLiquidGlassRounded(_ style: LuneraLiquidGlassStyle, cornerRadius: CGFloat, scale: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(style.fallbackFill.opacity(style.supportingFillOpacity), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .glassEffect(style.glass, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: style.shadowColor, radius: glassShadowRadius(for: style, scale: scale), x: 0, y: glassShadowOffset(for: style, scale: scale))
        } else {
            self
                .background(style.fallbackFill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: style.shadowColor, radius: glassShadowRadius(for: style, scale: scale), x: 0, y: glassShadowOffset(for: style, scale: scale))
        }
    }

    private func glassShadowRadius(for style: LuneraLiquidGlassStyle, scale: CGFloat) -> CGFloat {
        switch style {
        case .primary:
            10 * scale
        case .secondary:
            7 * scale
        case .control:
            3 * scale
        }
    }

    private func glassShadowOffset(for style: LuneraLiquidGlassStyle, scale: CGFloat) -> CGFloat {
        switch style {
        case .primary:
            4 * scale
        case .secondary:
            2 * scale
        case .control:
            1 * scale
        }
    }
}
