import SwiftUI
import UIKit

struct HomeView: View {
    let onSelectItem: (ClosetGridItem) -> Void
    @State private var didOpenDetailFromLaunch = false

    private let items = [
        ClosetGridItem(imageName: "CL1"),
        ClosetGridItem(imageName: "CL2"),
        ClosetGridItem(imageName: "CL3"),
        ClosetGridItem(imageName: "CL4"),
        ClosetGridItem(imageName: "CL5"),
        ClosetGridItem(imageName: "CL6")
    ]

    init(onSelectItem: @escaping (ClosetGridItem) -> Void = { _ in }) {
        self.onSelectItem = onSelectItem
    }

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
                                    onSelectItem(item)
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
            }
        }
        .statusBarHidden(true)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("--start-detail"), !didOpenDetailFromLaunch {
                didOpenDetailFromLaunch = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if let firstItem = items.first {
                        onSelectItem(firstItem)
                    }
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

            LuneraProfileAvatarButton(size: 48 * scale, scale: scale)
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

struct ClosetGridItem: Identifiable, Hashable {
    let imageName: String

    var id: String {
        imageName
    }
}

struct ClothingDetailView: View {
    let item: ClosetGridItem
    let onDragProgress: (CGFloat) -> Void
    let onClose: (Bool) -> Void

    private let sizes = ["XS", "S", "M", "L", "XL"]

    @State private var showingMoreInfo = false
    @State private var didOpenMoreInfoFromLaunch = false
    @State private var dragOffset: CGFloat = 0
    @State private var presentationOffset: CGFloat = UIScreen.main.bounds.width + 24
    @State private var isCompletingDragClose = false
    @State private var didRunPresentationAnimation = false

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 393, proxy.size.height / 852)
            let designWidth = proxy.size.width
            let outerInset = 10 * scale
            let panelWidth = 373 * scale
            let panelPadding = 25 * scale
            let bottomInset = 35 * scale
            let heroHeight = 566 * scale
            let heroFadeExtension = 180 * scale
            let heroToTitleHeight = 65 * scale
            let panelFadeHeight = 138 * scale
            let buttonTextHeight = 36 * scale
            let buttonGap = 5 * scale
            let sizeGap = 5 * scale
            let moreButtonWidth = 116 * scale
            let orderButtonWidth = panelWidth - (panelPadding * 2) - moreButtonWidth - buttonGap
            let deviceTopCornerRadius = DeviceCornerRadius.topRadius(for: proxy, scale: scale)

            ZStack {
                ZStack(alignment: .top) {
                    Color(red: 0.961, green: 0.961, blue: 0.969)
                        .ignoresSafeArea()

                DetailHeroImage(scale: scale, width: designWidth, height: heroHeight + heroFadeExtension, topCornerRadius: deviceTopCornerRadius)
                    .frame(width: designWidth, height: heroHeight + heroFadeExtension, alignment: .top)
                    .allowsHitTesting(false)

                DetailBackButton(scale: scale, action: { closeDetail(width: proxy.size.width) })
                    .padding(.leading, 30 * scale)
                    .padding(.top, 30 * scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .zIndex(10)

                VStack {
                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 20 * scale) {
                        Image("DetailBrand")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 112 * scale, height: 20 * scale, alignment: .leading)
                            .clipped()

                        VStack(alignment: .leading, spacing: 5 * scale) {
                            Text("Mouliné knit alpaca and wool\nblend turtleneck sweater")
                                .font(.system(size: 25 * scale, weight: .semibold, design: .serif))
                                .italic()
                                .foregroundStyle(Color(red: 0.165, green: 0.184, blue: 0.271))
                                .tracking(-1.75 * scale)
                                .lineSpacing(-3 * scale)
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

                                DetailSizeRow(labels: sizes, width: panelWidth - panelPadding * 2, height: 28 * scale, gap: sizeGap, scale: scale)
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
                                scale: scale,
                                action: {
                                    withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
                                        showingMoreInfo = true
                                    }
                                }
                            )

                            DetailGlassButton(
                                title: "Order Now",
                                role: .prominent,
                                foreground: Color(red: 0.961, green: 0.961, blue: 0.969),
                                width: orderButtonWidth,
                                textHeight: buttonTextHeight,
                                scale: scale,
                                action: {}
                            )
                        }
                        .padding(.top, -1 * scale)
                    }
                    .padding(.horizontal, panelPadding)
                    .padding(.top, 25 * scale)
                    .padding(.bottom, bottomInset)
                    .frame(width: panelWidth, alignment: .leading)
                    .background(alignment: .top) {
                        ZStack(alignment: .top) {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: heroToTitleHeight)

                                Color(red: 0.961, green: 0.961, blue: 0.969)
                            }

                            LinearGradient(
                                stops: [
                                    .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0), location: 0),
                                    .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.34), location: 0.34),
                                    .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.82), location: 0.72),
                                    .init(color: Color(red: 0.961, green: 0.961, blue: 0.969), location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: panelFadeHeight + heroToTitleHeight)
                            .offset(y: -panelFadeHeight)
                        }
                        .frame(width: designWidth)
                        .allowsHitTesting(false)
                    }
                    .padding(.horizontal, outerInset)
                }
                .frame(width: designWidth, height: proxy.size.height, alignment: .bottom)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: deviceTopCornerRadius,
                        bottomLeadingRadius: deviceTopCornerRadius,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: deviceTopCornerRadius,
                        style: .continuous
                    )
                )
                .offset(x: presentationOffset + dragOffset)
                .simultaneousGesture(closeDragGesture(scale: scale, width: proxy.size.width))

                if showingMoreInfo {
                    ProductMoreInfoView {
                        withAnimation(.spring(response: 0.44, dampingFraction: 0.9)) {
                            showingMoreInfo = false
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .bottom)
                    ))
                    .zIndex(20)
                }
            }
            .onAppear {
                startPresentation(width: proxy.size.width)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear {
            dragOffset = 0
            isCompletingDragClose = false

            guard ProcessInfo.processInfo.arguments.contains("--start-more-info"), !didOpenMoreInfoFromLaunch else {
                return
            }

            didOpenMoreInfoFromLaunch = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
                    showingMoreInfo = true
                }
            }
        }
    }

    private func startPresentation(width: CGFloat) {
        guard !didRunPresentationAnimation else {
            return
        }

        didRunPresentationAnimation = true
        presentationOffset = width + 24

        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.36, extraBounce: 0)) {
                presentationOffset = 0
                onDragProgress(0)
            }
        }
    }

    private func closeDetail(width: CGFloat, animated: Bool = true) {
        guard animated else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                onClose(false)
            }
            return
        }

        isCompletingDragClose = true

        withAnimation(.smooth(duration: 0.36)) {
            presentationOffset = width + 24
            onDragProgress(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            closeDetail(width: width, animated: false)
        }
    }

    private func closeDragGesture(scale: CGFloat, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 14, coordinateSpace: .local)
            .onChanged { value in
                guard !showingMoreInfo, !isCompletingDragClose else {
                    return
                }

                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                let isRightSwipe = horizontalDistance > 0 && abs(horizontalDistance) > verticalDistance

                guard isRightSwipe else {
                    return
                }

                dragOffset = min(width, max(0, horizontalDistance))
                onDragProgress(min(1, dragOffset / width))
            }
            .onEnded { value in
                guard !showingMoreInfo, !isCompletingDragClose else {
                    return
                }

                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                let predictedDistance = value.predictedEndTranslation.width
                let isRightSwipe = horizontalDistance > 0 && abs(horizontalDistance) > verticalDistance

                guard isRightSwipe else {
                    resetDragOffset()
                    return
                }

                if dragOffset > 96 * scale || predictedDistance > 180 * scale {
                    completeDragClose(width: width)
                } else {
                    resetDragOffset()
                }
            }
    }

    private func resetDragOffset() {
        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.88)) {
            dragOffset = 0
            onDragProgress(0)
        }
    }

    private func completeDragClose(width: CGFloat) {
        isCompletingDragClose = true

        withAnimation(.snappy(duration: 0.2, extraBounce: 0)) {
            dragOffset = width + 24
            onDragProgress(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            closeDetail(width: width, animated: false)
        }
    }
}

private enum DeviceCornerRadius {
    static func topRadius(for proxy: GeometryProxy, scale: CGFloat) -> CGFloat {
        let safeTop = max(proxy.safeAreaInsets.top, keyWindowSafeTop())
        return radius(safeTop: safeTop, shortestSide: min(proxy.size.width, proxy.size.height), scale: scale)
    }

    static func presentationTopRadius() -> CGFloat {
        let screenBounds = UIScreen.main.bounds
        let shortestSide = min(screenBounds.width, screenBounds.height)
        let safeTop = keyWindowSafeTop()
        let scale = shortestSide / 393

        return radius(safeTop: safeTop, shortestSide: shortestSide, scale: scale)
    }

    private static func keyWindowSafeTop() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets
            .top ?? 0
    }

    private static func radius(safeTop: CGFloat, shortestSide: CGFloat, scale: CGFloat) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return min(max(safeTop * 0.75, 18 * scale), 28 * scale)
        }

        if let mappedRadius = mappedPhoneRadius(for: UIScreen.main.bounds.size) {
            return mappedRadius
        }

        if safeTop > 50 {
            return min(max(safeTop + scale, 50 * scale), 62 * scale)
        }

        if safeTop > 35 {
            return min(max(safeTop, 38 * scale), 50 * scale)
        }

        return min(max(shortestSide * 0.105, 36 * scale), 48 * scale)
    }

    private static func mappedPhoneRadius(for screenSize: CGSize) -> CGFloat? {
        let width = Int(round(min(screenSize.width, screenSize.height)))
        let height = Int(round(max(screenSize.width, screenSize.height)))

        switch (width, height) {
        case (375, 812):
            return 39
        case (390, 844):
            return 47
        case (393, 852):
            return 55
        case (402, 874):
            return 56
        case (414, 896):
            return 41.5
        case (428, 926):
            return 53
        case (430, 932):
            return 62
        default:
            return nil
        }
    }
}

private struct DetailBackButton: View {
    let systemImage: String
    let scale: CGFloat
    let action: () -> Void

    init(systemImage: String = "chevron.left", scale: CGFloat, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.scale = scale
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20 * scale, weight: .medium))
                .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))
                .offset(x: systemImage == "chevron.left" ? -1 * scale : 0)
                .frame(width: 44 * scale, height: 44 * scale)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .detailLiquidGlassBackButton(scale: scale)
    }
}

private struct DetailHeroImage: View {
    let scale: CGFloat
    let width: CGFloat
    let height: CGFloat
    let topCornerRadius: CGFloat

    var body: some View {
        ZStack {
            heroLayer

            heroLayer
                .blur(radius: 3.5 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .clear, location: 0.34),
                            .init(color: .black.opacity(0.18), location: 0.48),
                            .init(color: .black.opacity(0.58), location: 0.66),
                            .init(color: .black.opacity(0.92), location: 0.84),
                            .init(color: .black, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            heroLayer
                .blur(radius: 8 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .clear, location: 0.48),
                            .init(color: .black.opacity(0.16), location: 0.60),
                            .init(color: .black.opacity(0.62), location: 0.78),
                            .init(color: .black, location: 0.96),
                            .init(color: .black, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            heroLayer
                .blur(radius: 14 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .clear, location: 0.62),
                            .init(color: .black.opacity(0.20), location: 0.72),
                            .init(color: .black.opacity(0.82), location: 0.88),
                            .init(color: .black, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: topCornerRadius, topTrailingRadius: topCornerRadius))
        .overlay {
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0), location: 0),
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.18), location: 0.24),
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.64), location: 0.52),
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969).opacity(0.92), location: 0.76),
                        .init(color: Color(red: 0.961, green: 0.961, blue: 0.969), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 380 * scale)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    private var heroLayer: some View {
        let cropHeight = 566 * scale

        return Image("DetailHero")
            .resizable()
            .frame(width: width * 1.6881, height: cropHeight * 1.6472)
            .offset(x: -(width * 0.3441), y: -2 * scale)
            .frame(width: width, height: height, alignment: .topLeading)
            .clipped()
    }
}

private struct DetailSizeRow: View {
    let labels: [String]
    let width: CGFloat
    let height: CGFloat
    let gap: CGFloat
    let scale: CGFloat

    private let textColor = Color(red: 0.11, green: 0.14, blue: 0.20)

    var body: some View {
        Canvas { context, canvasSize in
            let pillWidth = (canvasSize.width - gap * CGFloat(labels.count - 1)) / CGFloat(labels.count)

            for (index, label) in labels.enumerated() {
                let x = CGFloat(index) * (pillWidth + gap)
                let rect = CGRect(x: x, y: 0, width: pillWidth, height: canvasSize.height)
                let path = Path(roundedRect: rect, cornerRadius: canvasSize.height / 2)

                context.fill(path, with: .color(textColor.opacity(0.1)))

                let resolvedText = context.resolve(
                    Text(label)
                        .font(.system(size: 14 * scale, weight: .light))
                        .foregroundStyle(textColor)
                )

                context.draw(resolvedText, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
            }
        }
        .frame(width: width, height: height)
    }
}

private extension View {
    @ViewBuilder
    func detailLiquidGlassBackButton(scale: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(.white.opacity(0.18), in: Circle())
                .glassEffect(.regular.tint(.white.opacity(0.42)).interactive(), in: Circle())
                .shadow(color: .white.opacity(0.72), radius: 1.5 * scale, x: -0.5 * scale, y: -0.5 * scale)
                .shadow(color: .black.opacity(0.055), radius: 7 * scale, x: 0, y: 2 * scale)
        } else {
            self
                .background(.white.opacity(0.82), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.86), lineWidth: max(1, 1.2 * scale))
                }
                .shadow(color: .black.opacity(0.055), radius: 7 * scale, x: 0, y: 2 * scale)
        }
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
    let action: () -> Void

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
        Button(action: action) {
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

private enum ProductMoreInfoTab: CaseIterable, Hashable {
    case availability
    case details
    case care

    var title: String {
        switch self {
        case .availability:
            "Availability"
        case .details:
            "Details"
        case .care:
            "Care"
        }
    }
}

private struct ProductMoreInfoView: View {
    let onClose: () -> Void

    @State private var selectedTab: ProductMoreInfoTab
    @State private var dragOffset: CGFloat = 0

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        _selectedTab = State(initialValue: Self.initialTabFromLaunchArguments())
    }

    private static func initialTabFromLaunchArguments() -> ProductMoreInfoTab {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--more-info-care") {
            return .care
        }

        if arguments.contains("--more-info-availability") {
            return .availability
        }

        return .availability
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = max(proxy.size.width / 393, proxy.size.height / 852)
            let designWidth = 393 * scale
            let designHeight = 852 * scale
            let deviceTopCornerRadius = DeviceCornerRadius.topRadius(for: proxy, scale: scale)

            ZStack {
                Color(red: 0.961, green: 0.961, blue: 0.969)
                    .ignoresSafeArea()

                ZStack(alignment: .top) {
                    heroLayers(scale: scale, topCornerRadius: deviceTopCornerRadius)
                        .frame(width: designWidth, height: designHeight, alignment: .top)
                        .allowsHitTesting(false)

                    DetailBackButton(systemImage: "chevron.down", scale: scale, action: onClose)
                        .position(x: 47 * scale, y: 47 * scale)
                        .zIndex(10)

                    Text("More Info")
                        .font(.system(size: 32 * scale, weight: .semibold, design: .serif))
                        .italic()
                        .tracking(-1.9 * scale)
                        .foregroundStyle(Color(red: 0.165, green: 0.184, blue: 0.271))
                        .position(x: 196.5 * scale, y: titleY(scale: scale))

                    MoreInfoLiquidGlassPicker(selectedTab: $selectedTab, scale: scale)
                        .frame(width: 338 * scale, height: 48 * scale)
                        .position(x: 196.5 * scale, y: tabsY(scale: scale))

                    tabContentLayers(scale: scale)
                }
                .frame(width: designWidth, height: designHeight)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: deviceTopCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: deviceTopCornerRadius,
                    style: .continuous
                )
            )
            .offset(y: max(dragOffset, 0))
            .gesture(topSwipeDismissGesture(scale: scale))
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .preferredColorScheme(.light)
        .onAppear {
            selectedTab = Self.initialTabFromLaunchArguments()
        }
    }

    private func heroLayers(scale: CGFloat, topCornerRadius: CGFloat) -> some View {
        ZStack(alignment: .top) {
            ForEach(ProductMoreInfoTab.allCases, id: \.self) { tab in
                heroLayer(for: tab, scale: scale, topCornerRadius: topCornerRadius)
                    .opacity(tab == selectedTab ? 1 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: selectedTab)
    }

    @ViewBuilder
    private func heroLayer(for tab: ProductMoreInfoTab, scale: CGFloat, topCornerRadius: CGFloat) -> some View {
        switch tab {
        case .details:
            MoreInfoFullBleedHero(
                imageName: "MoreInfoDetailsHero",
                scale: scale,
                imageHeight: 498 * scale,
                topCornerRadius: topCornerRadius,
                fadeHeight: 318 * scale,
                fadeMidLocation: 0.56,
                fadeMidOpacity: 0.68
            )
        case .care:
            MoreInfoFullBleedHero(
                imageName: "MoreInfoCareHero",
                scale: scale,
                imageHeight: 498 * scale,
                topCornerRadius: topCornerRadius,
                fadeHeight: 306 * scale,
                fadeMidLocation: 0.58,
                fadeMidOpacity: 0.66
            )
        case .availability:
            MoreInfoFullBleedHero(
                imageName: "MoreInfoAvailabilityHero",
                scale: scale,
                imageHeight: 474 * scale,
                topCornerRadius: topCornerRadius,
                fadeHeight: 302 * scale,
                fadeMidLocation: 0.58,
                fadeMidOpacity: 0.68
            )
        }
    }

    private func tabContentLayers(scale: CGFloat) -> some View {
        ZStack(alignment: .top) {
            ForEach(ProductMoreInfoTab.allCases, id: \.self) { tab in
                tabContent(for: tab, scale: scale)
                    .position(x: 196.5 * scale, y: contentY(for: tab, scale: scale))
                    .opacity(tab == selectedTab ? 1 : 0)
                    .allowsHitTesting(tab == selectedTab)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: selectedTab)
    }

    @ViewBuilder
    private func tabContent(for tab: ProductMoreInfoTab, scale: CGFloat) -> some View {
        switch tab {
        case .details:
            MoreInfoDetailsContent(scale: scale)
        case .care:
            MoreInfoCareContent(scale: scale)
        case .availability:
            MoreInfoAvailabilityContent(scale: scale)
        }
    }

    private func titleY(scale: CGFloat) -> CGFloat {
        348 * scale
    }

    private func tabsY(scale: CGFloat) -> CGFloat {
        407 * scale
    }

    private func contentY(for tab: ProductMoreInfoTab, scale: CGFloat) -> CGFloat {
        switch tab {
        case .details:
            552 * scale
        case .care:
            646 * scale
        case .availability:
            646 * scale
        }
    }

    private func topSwipeDismissGesture(scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 14, coordinateSpace: .local)
            .onChanged { value in
                guard value.startLocation.y <= 190 * scale, value.translation.height > 0 else {
                    return
                }

                dragOffset = value.translation.height
            }
            .onEnded { value in
                guard value.startLocation.y <= 190 * scale else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        dragOffset = 0
                    }
                    return
                }

                if value.translation.height > 96 * scale || value.predictedEndTranslation.height > 180 * scale {
                    onClose()
                } else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

private struct MoreInfoFullBleedHero: View {
    let imageName: String
    let scale: CGFloat
    let imageHeight: CGFloat
    let topCornerRadius: CGFloat
    var fadeHeight: CGFloat? = nil
    var fadeMidLocation: Double = 0.72
    var fadeMidOpacity: Double = 0.72

    var body: some View {
        let background = Color(red: 0.961, green: 0.961, blue: 0.969)
        let heroWidth = 393 * scale
        let resolvedFadeHeight = fadeHeight ?? 330 * scale

        ZStack(alignment: .top) {
            heroImage(width: heroWidth)

            heroImage(width: heroWidth)
                .blur(radius: 4.5 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .clear, location: 0.30),
                            .init(color: .black.opacity(0.18), location: 0.46),
                            .init(color: .black.opacity(0.64), location: 0.68),
                            .init(color: .black, location: 0.94),
                            .init(color: .black, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: heroWidth, height: imageHeight)
                }

            heroImage(width: heroWidth)
                .blur(radius: 10 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .clear, location: 0.45),
                            .init(color: .black.opacity(0.20), location: 0.62),
                            .init(color: .black.opacity(0.78), location: 0.84),
                            .init(color: .black, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: heroWidth, height: imageHeight)
                }

            heroImage(width: heroWidth)
                .blur(radius: 18 * scale)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .clear, location: 0.58),
                            .init(color: .black.opacity(0.22), location: 0.72),
                            .init(color: .black.opacity(0.86), location: 0.90),
                            .init(color: .black, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: heroWidth, height: imageHeight)
                }

            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    stops: [
                        .init(color: background.opacity(0), location: 0),
                        .init(color: background.opacity(0.12), location: 0.24),
                        .init(color: background.opacity(fadeMidOpacity), location: fadeMidLocation),
                        .init(color: background.opacity(0.86), location: 0.88),
                        .init(color: background, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: resolvedFadeHeight)
            }
            .frame(width: heroWidth, height: imageHeight, alignment: .bottom)
        }
        .frame(width: heroWidth, height: 852 * scale, alignment: .top)
        .clipped()
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: topCornerRadius, topTrailingRadius: topCornerRadius))
    }

    private func heroImage(width: CGFloat) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: imageHeight, alignment: .top)
            .clipped()
    }
}

private struct MoreInfoLiquidGlassPicker: View {
    @Binding var selectedTab: ProductMoreInfoTab
    let scale: CGFloat

    var body: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ProductMoreInfoTab.allCases, id: \.self) { tab in
                Text(tab.title)
                    .tag(tab)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .controlSize(.large)
        .font(.system(size: 15 * scale, weight: .medium))
        .padding(.top, 3)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .frame(height: 48 * scale)
        .clipShape(Capsule())
        .onChange(of: selectedTab) { _, _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

private struct MoreInfoDetailsContent: View {
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 9 * scale) {
            MoreInfoDarkPill(text: "Ref. 5814/936", trailing: nil, scale: scale)
            MoreInfoDarkPill(text: "Made in Italy", trailing: "🇮🇹", scale: scale)

            MoreInfoInfoCard(title: "Outer layer", detail: "Polyamide 48%, Alpaca 38%, Wool 14%", height: 66 * scale, scale: scale)
                .padding(.top, 6 * scale)

            MoreInfoInfoCard(title: "Outer shell", detail: "48% RCS certified recycled polyamide", height: 58 * scale, scale: scale)
        }
        .frame(width: 274 * scale)
    }
}

private struct MoreInfoDarkPill: View {
    let text: String
    let trailing: String?
    let scale: CGFloat

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 13.5 * scale, weight: .regular))
                .foregroundStyle(.white)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: 11 * scale))
            }
        }
        .padding(.horizontal, 12 * scale)
        .frame(height: 24 * scale)
        .background(Color(red: 0.11, green: 0.14, blue: 0.20), in: Capsule())
    }
}

private struct MoreInfoInfoCard: View {
    let title: String
    let detail: String
    let height: CGFloat
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            Text(title)
                .font(.system(size: 16 * scale, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.black)

            Text(detail)
                .font(.system(size: 12.5 * scale, weight: .regular))
                .foregroundStyle(.black)
                .lineLimit(2)
        }
        .padding(.horizontal, 14 * scale)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .background(Color(red: 0.86, green: 0.87, blue: 0.89), in: RoundedRectangle(cornerRadius: 18 * scale, style: .continuous))
    }
}

private struct MoreInfoCareContent: View {
    let scale: CGFloat

    private let rows: [CareRow] = [
        CareRow(title: "Hand Wash Up to 30C", icon: .handWash),
        CareRow(title: "Do not Bleach", icon: .bleach),
        CareRow(title: "Iron Up To 110ºc/230ºf", icon: .iron),
        CareRow(title: "Do Not Tumble Dry", icon: .tumbleDry),
        CareRow(title: "Wash Inside Out", icon: .insideOut),
        CareRow(title: "Dry Flat", icon: .dryFlat, disabled: true),
        CareRow(title: "Iron Inside Out", icon: .iron, disabled: true)
    ]

    var body: some View {
        VStack(spacing: 10 * scale) {
            ForEach(rows, id: \.title) { row in
                HStack {
                    Text(row.title)
                        .font(.system(size: 15.5 * scale, weight: .regular))
                        .foregroundStyle(row.disabled ? Color.black.opacity(0.22) : .black)

                    Spacer()

                    CareInstructionIcon(icon: row.icon, disabled: row.disabled, scale: scale)
                }
                .padding(.horizontal, 16 * scale)
                .frame(width: 276 * scale, height: 44 * scale)
                .background(Color(red: 0.86, green: 0.87, blue: 0.89).opacity(row.disabled ? 0.45 : 1), in: Capsule())
            }
        }
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.68),
                    .init(color: .black.opacity(0.34), location: 0.86),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct CareRow {
    let title: String
    let icon: CareInstruction
    var disabled = false
}

private enum CareInstruction {
    case handWash
    case bleach
    case iron
    case tumbleDry
    case insideOut
    case dryFlat
}

private struct CareInstructionIcon: View {
    let icon: CareInstruction
    let disabled: Bool
    let scale: CGFloat

    var body: some View {
        iconView
            .foregroundStyle(disabled ? Color.black.opacity(0.18) : .black)
            .frame(width: 20 * scale, height: 20 * scale)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .handWash:
            Image(systemName: "hands.sparkles")
                .font(.system(size: 14 * scale, weight: .regular))
        case .bleach:
            LaundryTriangleIcon()
                .stroke(lineWidth: 1.6 * scale)
                .frame(width: 18 * scale, height: 18 * scale)
        case .iron:
            LaundryIronIcon()
                .stroke(lineWidth: 1.4 * scale)
                .frame(width: 19 * scale, height: 18 * scale)
        case .tumbleDry:
            Image(systemName: "xmark.square")
                .font(.system(size: 14 * scale, weight: .regular))
        case .insideOut:
            Image(systemName: "tshirt")
                .font(.system(size: 14 * scale, weight: .regular))
        case .dryFlat:
            LaundryDryFlatIcon()
                .stroke(lineWidth: 1.5 * scale)
                .frame(width: 18 * scale, height: 15 * scale)
        }
    }
}

private struct LaundryTriangleIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.maxY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY - rect.height * 0.12))
        path.closeSubpath()
        return path
    }
}

private struct LaundryIronIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.27))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY - rect.height * 0.27))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.midY),
            control: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.38)
        )
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.midY - rect.height * 0.16))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.midY - rect.height * 0.16))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.midY + rect.height * 0.10))
        path.closeSubpath()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.maxY - rect.height * 0.08))
        return path
    }
}

private struct LaundryDryFlatIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.12), cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.05))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.midY))
        return path
    }
}

private struct MoreInfoAvailabilityContent: View {
    let scale: CGFloat

    private let stores = [
        StoreAvailability(name: "Massimo Dutti Gendjik", available: ["XS", "S"]),
        StoreAvailability(name: "Massimo Dutti 28 May", available: ["XS", "M"]),
        StoreAvailability(name: "Massimo Dutti Crescent Mall", available: ["XS", "S", "L"]),
        StoreAvailability(name: "Massimo Dutti Port Baku", available: [], disabled: true)
    ]

    var body: some View {
        VStack(spacing: 14 * scale) {
            ForEach(stores, id: \.name) { store in
                VStack(alignment: .leading, spacing: 12 * scale) {
                    Text(store.name)
                        .font(.system(size: 15 * scale, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(store.disabled ? Color.black.opacity(0.18) : .black)
                        .padding(.leading, 2 * scale)

                    HStack(spacing: 7 * scale) {
                        ForEach(["XS", "S", "M", "L", "XL"], id: \.self) { size in
                            Text(size)
                                .font(.system(size: 12.5 * scale, weight: .regular))
                                .foregroundStyle(sizeColor(size, store: store))
                                .frame(width: 40 * scale, height: 24 * scale)
                                .background(sizeBackground(size, store: store), in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16 * scale)
                .frame(width: 276 * scale, height: 88 * scale, alignment: .leading)
                .background(Color(red: 0.86, green: 0.87, blue: 0.89).opacity(store.disabled ? 0.42 : 1), in: RoundedRectangle(cornerRadius: 18 * scale, style: .continuous))
            }
        }
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.70),
                    .init(color: .black.opacity(0.26), location: 0.88),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func sizeColor(_ size: String, store: StoreAvailability) -> Color {
        if store.disabled || !store.available.contains(size) {
            return Color.black.opacity(0.18)
        }
        return Color(red: 0.11, green: 0.14, blue: 0.20)
    }

    private func sizeBackground(_ size: String, store: StoreAvailability) -> Color {
        if store.disabled || !store.available.contains(size) {
            return Color(red: 0.80, green: 0.81, blue: 0.84).opacity(0.35)
        }
        return Color(red: 0.79, green: 0.80, blue: 0.83).opacity(0.72)
    }
}

private struct StoreAvailability {
    let name: String
    let available: Set<String>
    var disabled = false
}

#Preview {
    HomeView()
}
