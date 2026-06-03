import SwiftUI

struct LoginView: View {
    let onLogin: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var heroLifted = false

    var body: some View {
        ZStack {
            LuneraTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 28)

                LuneraLogo(width: 104)
                    .padding(.bottom, 34)

                VStack(alignment: .leading, spacing: 22) {
                    ClosetPreview()
                        .offset(y: heroLifted ? 0 : 10)
                        .opacity(heroLifted ? 1 : 0)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(LuneraTheme.ink)

                        Text("Sign in to continue building your wardrobe.")
                            .font(.system(size: 15))
                            .foregroundStyle(LuneraTheme.softInk)
                    }

                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(LuneraTextFieldStyle())

                        SecureField("Password", text: $password)
                            .textFieldStyle(LuneraTextFieldStyle())
                    }

                    LuneraButton("LOGIN", systemImage: "arrow.right") {
                        onLogin()
                    }

                    Button {
                    } label: {
                        HStack {
                            Rectangle()
                                .fill(LuneraTheme.line)
                                .frame(height: 1)

                            Text("Continue with Apple")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(LuneraTheme.ink)
                                .lineLimit(1)

                            Rectangle()
                                .fill(LuneraTheme.line)
                                .frame(height: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 28)

                Button {
                } label: {
                    Text("New to Lunera? Create an account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LuneraTheme.softInk)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 18)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.08)) {
                heroLifted = true
            }
        }
    }
}

private struct ClosetPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.83, green: 0.78, blue: 0.70),
                            Color(red: 0.96, green: 0.92, blue: 0.86)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(alignment: .bottom, spacing: 16) {
                GarmentTile(color: LuneraTheme.clay, icon: "tshirt")
                    .rotationEffect(.degrees(-4))

                GarmentTile(color: LuneraTheme.ink, icon: "shoeprints.fill")
                    .offset(y: -10)

                GarmentTile(color: LuneraTheme.moss, icon: "handbag")
                    .rotationEffect(.degrees(5))
            }
            .padding(22)
        }
        .frame(height: 180)
        .shadow(color: .black.opacity(0.08), radius: 20, y: 12)
    }
}

private struct GarmentTile: View {
    let color: Color
    let icon: String

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.white.opacity(0.86))
            .frame(width: 74, height: 112)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(color)
            }
    }
}

#Preview {
    LoginView {}
}
