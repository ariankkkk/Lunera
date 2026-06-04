import SwiftUI
import UIKit

struct LoginView: View {
    let onLogin: () -> Void
    let onCreateAccount: () -> Void

    var body: some View {
        AuthAccountView(
            mode: .login,
            onSubmit: onLogin,
            onAlternate: onCreateAccount
        )
    }
}

struct CreateAccountView: View {
    let onCreate: () -> Void
    let onLogin: () -> Void

    var body: some View {
        AuthAccountView(
            mode: .create,
            onSubmit: onCreate,
            onAlternate: onLogin
        )
    }
}

struct RecommendationIntroView: View {
    let onChoosePreferences: () -> Void
    let onExplore: () -> Void

    @State private var pageVisible = false

    var body: some View {
        StartScreenCanvas {
            StartPalette.background
        } content: { scale in
            Image("RecommendationHero")
                .resizable()
                .frame(width: 393 * scale, height: 852 * scale)
                .position(x: 196.5 * scale, y: 426 * scale)
                .opacity(pageVisible ? 1 : 0)
                .scaleEffect(pageVisible ? 1 : 1.012)
                .animation(.easeOut(duration: 0.65), value: pageVisible)

            RecommendationCopy(scale: scale)
                .frame(width: 330 * scale, alignment: .leading)
                .position(x: 208 * scale, y: 550 * scale)
                .bottomFadeIn(pageVisible, offset: 22 * scale, delay: 0.5)

            VStack(spacing: 12 * scale) {
                StartPillButton(
                    title: "Choose my Preferences",
                    width: 331 * scale,
                    height: 48 * scale,
                    style: .primary,
                    scale: scale,
                    action: onChoosePreferences
                )

                StartPillButton(
                    title: "Explore for now",
                    width: 331 * scale,
                    height: 48 * scale,
                    style: .secondary,
                    scale: scale,
                    action: onExplore
                )
            }
            .position(x: 196.5 * scale, y: 764 * scale)
            .bottomFadeIn(pageVisible, offset: 22 * scale, delay: 0.64)
        }
        .statusBarHidden(true)
        .onAppear {
            pageVisible = false
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                pageVisible = true
            }
        }
    }
}

struct StylePreferencesView: View {
    let onBack: () -> Void
    let onComplete: () -> Void

    @State private var contentVisible = false

    private let options = [
        StylePreference(title: "Color Preference", icon: "circle.hexagongrid"),
        StylePreference(title: "Your Size", icon: "ruler"),
        StylePreference(title: "Brand Preference", icon: "atom"),
        StylePreference(title: "Price Range", icon: "dollarsign.circle"),
        StylePreference(title: "Location", icon: "map")
    ]

    var body: some View {
        StartScreenCanvas {
            StartPalette.background
        } content: { scale in
            Image("StyleHero")
                .resizable()
                .frame(width: 393 * scale, height: 334 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.56),
                            .init(color: .black.opacity(0.42), location: 0.82),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: 393 * scale, height: 334 * scale)
                }
                .position(x: 196.5 * scale, y: 167 * scale)
                .opacity(contentVisible ? 1 : 0)
                .scaleEffect(contentVisible ? 1 : 1.015)
                .animation(.easeOut(duration: 0.62), value: contentVisible)

            Button(action: onBack) {
                Circle()
                    .fill(.clear)
                    .frame(width: 44 * scale, height: 44 * scale)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .position(x: 47 * scale, y: 47 * scale)

            styleTitle(scale: scale)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .position(x: 196.5 * scale, y: 379 * scale)
                .bottomFadeIn(contentVisible, offset: 22 * scale, delay: 0.5)

            ForEach(Array(options.enumerated()), id: \.element.title) { index, option in
                StylePreferenceRow(option: option, scale: scale)
                    .frame(width: 300 * scale, height: 56 * scale)
                    .position(x: 196.5 * scale, y: (440 + CGFloat(index) * 66) * scale)
                    .bottomFadeIn(contentVisible, offset: 22 * scale, delay: 0.58 + Double(index) * 0.055)
            }

            StartPillButton(
                title: "This is my Style",
                width: 300 * scale,
                height: 48 * scale,
                style: .primary,
                scale: scale,
                action: onComplete
            )
            .position(x: 196.5 * scale, y: 782 * scale)
            .bottomFadeIn(contentVisible, offset: 22 * scale, delay: 0.92)
        }
        .statusBarHidden(true)
        .onAppear {
            contentVisible = false
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                contentVisible = true
            }
        }
    }

    private func styleTitle(scale: CGFloat) -> Text {
        Text("Your ")
            .font(.system(size: 42 * scale, weight: .regular))
            .foregroundColor(Color(red: 0.34, green: 0.37, blue: 0.44))
        + Text("Style")
            .font(.system(size: 42 * scale, weight: .semibold, design: .serif))
            .italic()
            .foregroundColor(StartPalette.ink)
    }
}

private struct AuthAccountView: View {
    let mode: AuthMode
    let onSubmit: () -> Void
    let onAlternate: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var contentVisible = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: AuthField?

    var body: some View {
        StartScreenCanvas {
            StartPalette.background
        } content: { scale in
            Image("AuthHero")
                .resizable()
                .frame(width: 393 * scale, height: 852 * scale)
                .position(x: 196.5 * scale, y: 426 * scale)
                .opacity(contentVisible ? Double(heroOpacity) : 0)
                .scaleEffect(contentVisible ? 1 : 1.012)
                .animation(.easeOut(duration: 0.62), value: contentVisible)

            Color.clear
                .frame(width: 393 * scale, height: 852 * scale)
                .contentShape(Rectangle())
                .position(x: 196.5 * scale, y: 426 * scale)
                .onTapGesture {
                    dismissKeyboard()
                }

            ZStack {
                Text(mode.title)
                    .font(.system(size: 32 * scale, weight: .regular, design: .serif))
                    .italic()
                    .tracking(-1.7 * scale)
                    .foregroundStyle(StartPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .frame(width: 310 * scale)
                    .position(x: 196.5 * scale, y: mode == .create ? 467 * scale : 486 * scale)
                    .bottomFadeIn(contentVisible, offset: 22 * scale, delay: 0.5)

                VStack(spacing: 11 * scale) {
                    if mode == .create {
                        StartAuthField(
                            placeholder: "Name",
                            icon: "person.crop.circle",
                            text: $name,
                            field: .name,
                            focusedField: $focusedField,
                            scale: scale
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    StartAuthField(
                        placeholder: "Email Address",
                        icon: "envelope.circle",
                        text: $email,
                        field: .email,
                        focusedField: $focusedField,
                        scale: scale
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                    StartAuthField(
                        placeholder: "Password",
                        icon: "lock.circle",
                        text: $password,
                        field: .password,
                        focusedField: $focusedField,
                        isSecure: true,
                        scale: scale
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture {
                }
                .frame(width: 300 * scale)
                .position(x: 196.5 * scale, y: mode == .create ? 599 * scale : 596 * scale)
                .bottomFadeIn(contentVisible, offset: 24 * scale, delay: 0.6)

                StartPillButton(
                    title: mode.buttonTitle,
                    width: 235 * scale,
                    height: 46 * scale,
                    style: .primary,
                    scale: scale,
                    action: onSubmit
                )
                .position(x: 196.5 * scale, y: mode == .create ? 732 * scale : 710 * scale)
                .bottomFadeIn(contentVisible, offset: 22 * scale, delay: 0.76)

                StartApplePrototypeButton(
                    title: mode.appleButtonTitle,
                    width: 235 * scale,
                    height: 46 * scale,
                    scale: scale,
                    action: onSubmit
                )
                .position(x: 196.5 * scale, y: mode == .create ? 783 * scale : 759 * scale)
                .bottomFadeIn(contentVisible, offset: 18 * scale, delay: 0.82)

                HStack(spacing: 4 * scale) {
                    Text(mode.alternateLead)
                        .foregroundStyle(StartPalette.ink)

                    Button(action: onAlternate) {
                        Text(mode.alternateAction)
                            .underline()
                            .foregroundStyle(StartPalette.ink)
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 16 * scale, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .position(x: 196.5 * scale, y: mode == .create ? 823 * scale : 806 * scale)
                .bottomFadeIn(contentVisible, offset: 16 * scale, delay: 0.88)
            }
            .frame(width: 393 * scale, height: 852 * scale)
            .offset(y: keyboardLift(scale: scale))
        }
        .statusBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            contentVisible = false
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                contentVisible = true
            }
        }
    }

    private var keyboardProgress: CGFloat {
        min(1, max(0, keyboardHeight / 300))
    }

    private var heroOpacity: CGFloat {
        1 - keyboardProgress * 0.92
    }

    private func keyboardLift(scale: CGFloat) -> CGFloat {
        guard keyboardHeight > 0 else { return 0 }
        return -min(230 * scale, keyboardHeight * 0.64)
    }

    private func updateKeyboardHeight(from notification: Notification) {
        let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        let overlap = max(0, UIScreen.main.bounds.height - endFrame.minY)

        withAnimation(keyboardMotionAnimation(isShowing: overlap > keyboardHeight)) {
            keyboardHeight = overlap
        }
    }

    private func keyboardMotionAnimation(isShowing: Bool) -> Animation {
        .spring(
            response: isShowing ? 0.5 : 0.56,
            dampingFraction: isShowing ? 0.88 : 0.9,
            blendDuration: 0.08
        )
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private enum AuthField: Hashable {
    case name
    case email
    case password
}

private enum AuthMode {
    case create
    case login

    var title: String {
        switch self {
        case .create:
            "Create an Account"
        case .login:
            "Log In"
        }
    }

    var buttonTitle: String {
        switch self {
        case .create:
            "Create"
        case .login:
            "Log In"
        }
    }

    var alternateLead: String {
        switch self {
        case .create:
            "Have an account already?"
        case .login:
            "Need an account?"
        }
    }

    var alternateAction: String {
        switch self {
        case .create:
            "Log In"
        case .login:
            "Create"
        }
    }

    var appleButtonTitle: String {
        switch self {
        case .create:
            "Sign up with Apple"
        case .login:
            "Sign in with Apple"
        }
    }
}

private struct StartScreenCanvas<Background: View, Content: View>: View {
    @ViewBuilder var background: () -> Background
    @ViewBuilder var content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { proxy in
            let scale = max(proxy.size.width / 393, proxy.size.height / 852)
            let designWidth = 393 * scale
            let designHeight = 852 * scale

            ZStack {
                background()
                    .ignoresSafeArea()

                ZStack {
                    content(scale)
                }
                .frame(width: designWidth, height: designHeight)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}

private struct RecommendationCopy: View {
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 9 * scale) {
            HStack(alignment: .firstTextBaseline, spacing: 5 * scale) {
                LuneraLogo(width: 119 * scale)
                    .offset(y: 3 * scale)

                Text("recommends")
                    .font(.system(size: 33 * scale, weight: .semibold, design: .serif))
                    .italic()
                    .tracking(-2.1 * scale)
                    .foregroundStyle(.black)
            }

            Text("clothes tailored to your\nstyle.")
                .font(.system(size: 36 * scale, weight: .semibold, design: .serif))
                .italic()
                .tracking(-2.7 * scale)
                .lineSpacing(8 * scale)
                .foregroundStyle(.black)
        }
    }
}

private struct StylePreference: Hashable {
    let title: String
    let icon: String
}

private struct StylePreferenceRow: View {
    let option: StylePreference
    let scale: CGFloat

    var body: some View {
        Button {
        } label: {
            HStack {
                Text(option.title)
                    .font(.system(size: 16 * scale, weight: .regular))
                    .foregroundStyle(StartPalette.ink)
                    .lineLimit(1)

                Spacer()

                Image(systemName: option.icon)
                    .font(.system(size: 18 * scale, weight: .regular))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(StartPalette.ink)
                    .frame(width: 26 * scale, height: 26 * scale)
            }
            .padding(.leading, 16 * scale)
            .padding(.trailing, 15 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 17 * scale, style: .continuous))
        }
        .buttonStyle(.plain)
        .luneraLiquidGlassRounded(.control, cornerRadius: 17 * scale, scale: scale)
    }
}

private struct StartAuthField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    let field: AuthField
    @FocusState.Binding var focusedField: AuthField?
    var isSecure = false
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 9 * scale) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16 * scale, weight: .regular))
                        .foregroundStyle(StartPalette.ink)
                        .allowsHitTesting(false)
                }

                if isSecure {
                    SecureField("", text: $text)
                        .textContentType(.password)
                        .focused($focusedField, equals: field)
                } else {
                    TextField("", text: $text)
                        .textContentType(placeholder == "Email Address" ? .emailAddress : .name)
                        .focused($focusedField, equals: field)
                }
            }
            .font(.system(size: 16 * scale, weight: .regular))
            .foregroundStyle(StartPalette.ink)
            .tint(StartPalette.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            Image(systemName: icon)
                .font(.system(size: 21 * scale, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(StartPalette.ink)
                .frame(width: 24 * scale, height: 24 * scale)
        }
        .padding(.leading, 16 * scale)
        .padding(.trailing, 14 * scale)
        .frame(height: 56 * scale)
        .contentShape(RoundedRectangle(cornerRadius: 17 * scale, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 17 * scale, style: .continuous)
                .fill(StartPalette.control)
        }
        .onTapGesture {
            focusedField = field
        }
    }
}

private struct StartPillButton: View {
    let title: String
    let width: CGFloat
    let height: CGFloat
    let style: StartButtonStyle
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16 * scale, weight: .semibold))
                .foregroundStyle(style.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 22 * scale)
                .frame(width: width, height: height)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .luneraLiquidGlassCapsule(style.glassStyle, scale: scale)
    }
}

private struct StartApplePrototypeButton: View {
    let title: String
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8 * scale) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18 * scale, weight: .semibold))

                Text(title)
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18 * scale)
            .frame(width: width, height: height)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .background {
            Capsule()
                .fill(.black)
                .shadow(color: .black.opacity(0.14), radius: 11 * scale, y: 5 * scale)
        }
    }
}

private enum StartButtonStyle {
    case primary
    case secondary

    var background: Color {
        switch self {
        case .primary:
            StartPalette.ink
        case .secondary:
            .white.opacity(0.82)
        }
    }

    var foreground: Color {
        switch self {
        case .primary:
            StartPalette.background
        case .secondary:
            StartPalette.ink
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary:
            .black.opacity(0.18)
        case .secondary:
            .black.opacity(0.05)
        }
    }

    var glassStyle: LuneraLiquidGlassStyle {
        switch self {
        case .primary:
            .primary
        case .secondary:
            .secondary
        }
    }
}

private enum StartPalette {
    static let background = Color(red: 0.961, green: 0.961, blue: 0.969)
    static let ink = Color(red: 0.110, green: 0.137, blue: 0.200)
    static let control = Color(red: 0.898, green: 0.900, blue: 0.914)
}

private extension View {
    func bottomFadeIn(_ visible: Bool, offset: CGFloat, delay: Double) -> some View {
        opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : offset)
            .animation(
                .spring(response: 0.58, dampingFraction: 0.9).delay(delay),
                value: visible
            )
    }
}

#Preview("Create Account") {
    CreateAccountView(onCreate: {}, onLogin: {})
}

#Preview("Recommendation") {
    RecommendationIntroView(onChoosePreferences: {}, onExplore: {})
}

#Preview("Style") {
    StylePreferencesView(onBack: {}, onComplete: {})
}
