import SwiftUI

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
            .background(LuneraTheme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
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
