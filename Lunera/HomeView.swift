import SwiftUI
import UIKit

struct HomeView: View {
    @State private var selectedItem: ClosetGridItem?

    private let items = [
        ClosetGridItem(imageName: "CL1"),
        ClosetGridItem(imageName: "CL2"),
        ClosetGridItem(imageName: "CL3"),
        ClosetGridItem(imageName: "CL4"),
        ClosetGridItem(imageName: "CL5"),
        ClosetGridItem(imageName: "CL6")
    ]

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 393
            let cardSpacing = 11 * scale
            let sidePadding = 22 * scale
            let cardWidth = (proxy.size.width - (sidePadding * 2) - cardSpacing) / 2
            let cardHeight = cardWidth * 1.28
            let fixedHeaderHeight = 80 * scale

            ZStack(alignment: .top) {
                Color(red: 0.967, green: 0.965, blue: 0.96)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        LazyVGrid(
                            columns: [
                                GridItem(.fixed(cardWidth), spacing: cardSpacing),
                                GridItem(.fixed(cardWidth), spacing: cardSpacing)
                            ],
                            spacing: 12 * scale
                        ) {
                            ForEach(items) { item in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedItem = item
                                } label: {
                                    ClothingCard(item: item, scale: scale)
                                        .frame(width: cardWidth, height: cardHeight)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, sidePadding)
                        .padding(.top, fixedHeaderHeight)
                        .padding(.bottom, 28 * scale)
                    }
                }

                HeaderBlurBand(height: fixedHeaderHeight + 18 * scale)
                    .allowsHitTesting(false)

                HomeHeader(scale: scale)
                    .padding(.top, 8 * scale)
                    .padding(.horizontal, sidePadding)
                    .zIndex(1)
            }
        }
        .statusBarHidden(true)
        .fullScreenCover(item: $selectedItem) { item in
            ClothingDetailView(item: item) {
                selectedItem = nil
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("--start-detail"), selectedItem == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    selectedItem = items.first
                }
            }
        }
    }
}

private struct HeaderBlurBand: View {
    let height: CGFloat

    var body: some View {
        ZStack {
            GradientBackdropBlur(style: .systemUltraThinMaterialLight)
                .mask {
                    LinearGradient(
                        colors: [.black, .black.opacity(0.82), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            Rectangle()
                .fill(.clear)
                .background {
                    LinearGradient(
                        colors: [
                            Color(red: 0.967, green: 0.965, blue: 0.96).opacity(0.84),
                            Color(red: 0.967, green: 0.965, blue: 0.96).opacity(0.46),
                            Color(red: 0.967, green: 0.965, blue: 0.96).opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .mask {
            LinearGradient(
                colors: [.black, .black.opacity(0.94), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .ignoresSafeArea(edges: .top)
    }
}

private struct GradientBackdropBlur: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

private struct HomeHeader: View {
    let scale: CGFloat

    var body: some View {
        HStack(alignment: .center) {
            LuneraLogo(width: 110 * scale)

            Spacer()

            HStack(spacing: 9 * scale) {
                CircleIconButton(size: 25 * scale) {
                    DotGridIcon()
                        .stroke(LuneraTheme.ink, lineWidth: 1.8 * scale)
                        .frame(width: 13 * scale, height: 13 * scale)
                }

                CircleIconButton(size: 25 * scale) {
                    FilterLineIcon()
                        .stroke(LuneraTheme.ink, style: StrokeStyle(lineWidth: 1.8 * scale, lineCap: .round))
                        .frame(width: 14 * scale, height: 11 * scale)
                }
            }
        }
    }
}

private struct ClothingCard: View {
    let item: ClosetGridItem
    let scale: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .blendMode(.multiply)

                RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                    .stroke(Color(red: 0.895, green: 0.895, blue: 0.91), lineWidth: 3.3 * scale)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14 * scale, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                    .fill(Color(red: 0.985, green: 0.985, blue: 0.98))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                    .stroke(Color(red: 0.895, green: 0.895, blue: 0.91), lineWidth: 3.3 * scale)
            }
        }
    }
}

private struct CircleIconButton<Icon: View>: View {
    let size: CGFloat
    let icon: () -> Icon

    var body: some View {
        Button {
        } label: {
            icon()
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .stroke(LuneraTheme.ink, lineWidth: 1.6)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct DotGridIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dot = min(rect.width, rect.height) * 0.16
        let positions: [CGFloat] = [0.16, 0.5, 0.84]

        for x in positions {
            for y in positions {
                let center = CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
                path.addEllipse(in: CGRect(x: center.x - dot / 2, y: center.y - dot / 2, width: dot, height: dot))
            }
        }

        return path
    }
}

private struct FilterLineIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.18))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.midY))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.32, y: rect.maxY - rect.height * 0.18))
        return path
    }
}

private struct ClosetGridItem: Identifiable {
    let id = UUID()
    let imageName: String
}

private struct ClothingDetailView: View {
    let item: ClosetGridItem
    let onClose: () -> Void

    private let sizes = ["XS", "S", "M", "L", "XL"]

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 393, 1.08)
            let designWidth = proxy.size.width
            let outerInset = 10 * scale
            let panelWidth = 373 * scale
            let panelPadding = 25 * scale
            let bottomInset = 1 * scale
            let heroHeight = 548 * scale
            let heroFadeExtension = 150 * scale
            let panelTopOverlap = 90 * scale
            let buttonTextHeight = 36 * scale
            let buttonGap = 5 * scale
            let moreButtonWidth = 116 * scale
            let orderButtonWidth = panelWidth - (panelPadding * 2) - moreButtonWidth - buttonGap

            ZStack(alignment: .top) {
                Color(red: 0.961, green: 0.961, blue: 0.969)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        DetailHeroImage(scale: scale, width: designWidth, height: heroHeight + heroFadeExtension)

                        DetailBackButton(scale: scale, action: onClose)
                        .padding(.leading, 30 * scale)
                        .padding(.top, 46 * scale)
                    }
                    .frame(width: designWidth, height: heroHeight - panelTopOverlap)

                    VStack(alignment: .leading, spacing: 20 * scale) {
                        Image("DetailBrand")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 112 * scale, height: 20 * scale, alignment: .leading)
                            .clipped()

                        VStack(alignment: .leading, spacing: 5 * scale) {
                            Text("Mouliné knit alpaca and wool\nblend turtleneck sweater")
                                .font(.system(size: 22.5 * scale, weight: .semibold, design: .serif))
                                .italic()
                                .foregroundStyle(Color(red: 0.165, green: 0.184, blue: 0.271))
                                .lineSpacing(-1 * scale)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("250 AZN")
                                .font(.system(size: 18 * scale, weight: .regular))
                                .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))
                        }

                        VStack(alignment: .leading, spacing: 10 * scale) {
                            VStack(alignment: .leading, spacing: 5 * scale) {
                                Text("Size")
                                    .font(.system(size: 16 * scale, weight: .regular))
                                    .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))

                                HStack(spacing: 5 * scale) {
                                    ForEach(sizes, id: \.self) { size in
                                        Text(size)
                                            .font(.system(size: 14 * scale, weight: .light))
                                            .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 5 * scale)
                                            .background(Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.1), in: Capsule())
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 5 * scale) {
                                Text("Color")
                                    .font(.system(size: 16 * scale, weight: .regular))
                                    .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))

                                Image("DetailColor")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20 * scale, height: 20 * scale)
                                    .clipShape(Circle())
                                    .padding(2 * scale)
                                    .background(Color(red: 0.11, green: 0.14, blue: 0.20), in: Circle())
                            }
                        }

                        HStack(spacing: buttonGap) {
                            DetailGlassButton(
                                title: "More Info",
                                role: .standard,
                                foreground: Color(red: 0.11, green: 0.14, blue: 0.20),
                                width: moreButtonWidth,
                                textHeight: buttonTextHeight,
                                scale: scale
                            )

                            DetailGlassButton(
                                title: "Order Now",
                                role: .prominent,
                                foreground: Color(red: 0.961, green: 0.961, blue: 0.969),
                                width: orderButtonWidth,
                                textHeight: buttonTextHeight,
                                scale: scale
                            )
                        }
                        .padding(.top, -1 * scale)
                    }
                    .padding(.horizontal, panelPadding)
                    .padding(.top, 25 * scale)
                    .padding(.bottom, bottomInset)
                    .frame(width: panelWidth, alignment: .leading)
                    .background(Color(red: 0.961, green: 0.961, blue: 0.969), in: RoundedRectangle(cornerRadius: 45 * scale, style: .continuous))
                    .overlay(alignment: .top) {
                        LinearGradient(
                            colors: [
                                Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0),
                                Color(red: 0.961, green: 0.961, blue: 0.969)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 72 * scale)
                        .offset(y: -72 * scale)
                        .allowsHitTesting(false)
                    }
                    .padding(.horizontal, outerInset)
                }
                .frame(width: designWidth, height: proxy.size.height, alignment: .bottom)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .statusBarHidden(true)
    }
}

private struct DetailBackButton: View {
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16 * scale, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34 * scale, height: 34 * scale)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .detailBackGlass(scale: scale)
    }
}

private extension View {
    @ViewBuilder
    func detailBackGlass(scale: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular.tint(Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.26)).interactive(),
                in: Circle()
            )
        } else {
            self.background(Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.25), in: Circle())
        }
    }
}

private struct DetailHeroImage: View {
    let scale: CGFloat
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            heroLayer
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.46),
                            .init(color: .black.opacity(0.58), location: 0.66),
                            .init(color: .clear, location: 0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            heroLayer
                .blur(radius: 3.2 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.34),
                            .init(color: .black.opacity(0.28), location: 0.52),
                            .init(color: .black.opacity(0.78), location: 0.72),
                            .init(color: .black, location: 0.84),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            heroLayer
                .blur(radius: 7.5 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.58),
                            .init(color: .black.opacity(0.35), location: 0.70),
                            .init(color: .black, location: 0.84),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 45 * scale, topTrailingRadius: 45 * scale))
        .overlay {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.65),
                        Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 58 * scale)

                Spacer()

                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0), location: 0),
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.46), location: 0.34),
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.82), location: 0.64),
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 280 * scale)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    private var heroLayer: some View {
        let cropHeight = 548 * scale

        return Image("DetailHero")
            .resizable()
            .scaledToFill()
            .frame(width: width * 1.6881, height: cropHeight * 1.6472)
            .offset(x: -(width * 0.3441), y: cropHeight * 0.0447)
            .frame(width: width, height: height, alignment: .topLeading)
            .clipped()
    }
}

private struct DetailGlassButton: View {
    enum Role {
        case standard
        case prominent
    }

    let title: String
    let role: Role
    let foreground: Color
    let width: CGFloat?
    let textHeight: CGFloat
    let scale: CGFloat

    var body: some View {
        if #available(iOS 26.0, *) {
            exactButton
                .glassEffect(glass, in: Capsule())
        } else {
            exactButton
                .background(fallbackFill, in: Capsule())
                .shadow(color: .black.opacity(role == .prominent ? 0.16 : 0.05), radius: 8 * scale, x: 0, y: 3 * scale)
        }
    }

    private var exactButton: some View {
        Button {
        } label: {
            Text(title)
                .font(.system(size: 17 * scale, weight: role == .prominent ? .semibold : .medium))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .frame(width: width, height: 48 * scale)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        switch role {
        case .standard:
            return .regular.interactive()
        case .prominent:
            return .regular.tint(Color(red: 0.11, green: 0.14, blue: 0.20)).interactive()
        }
    }

    private var fallbackFill: Color {
        role == .prominent
            ? Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.98)
            : Color.white.opacity(0.72)
    }
}

#Preview {
    HomeView()
}
