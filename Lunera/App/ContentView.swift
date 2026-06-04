import SwiftUI
import UIKit
import PhotosUI

struct ContentView: View {
    @State private var startRoute: StartRoute

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let environment = ProcessInfo.processInfo.environment
        let startRouteName = environment["LUNERA_START_ROUTE"]
        let isAuthenticated = LocalAuthStore.shared.isSignedIn
        let initialRoute: StartRoute
        let startsInMainFlow = startRouteName == "main"
            || arguments.contains("--start-detail")
            || arguments.contains("--start-search")
            || arguments.contains("--start-events")
            || arguments.contains("--start-event-detail")
            || arguments.contains("--start-event-creation")
        let requestedRoute: StartRoute?

        if arguments.contains("--start-login") || startRouteName == "login" {
            requestedRoute = .login
        } else if arguments.contains("--start-create-account") || startRouteName == "create" {
            requestedRoute = .createAccount
        } else if arguments.contains("--start-welcome") || startRouteName == "welcome" {
            requestedRoute = .welcome
        } else if arguments.contains("--start-recommendations") || startRouteName == "recommendations" {
            requestedRoute = .recommendations
        } else if arguments.contains("--start-preferences") || startRouteName == "preferences" {
            requestedRoute = .preferences
        } else if startsInMainFlow {
            requestedRoute = .main
        } else {
            requestedRoute = nil
        }

        if let requestedRoute {
            initialRoute = requestedRoute.requiresAuthentication && !isAuthenticated ? .login : requestedRoute
        } else {
            initialRoute = .welcome
        }

        _startRoute = State(initialValue: initialRoute)
    }

    var body: some View {
        Group {
            switch startRoute {
            case .welcome:
                WelcomeView {
                    go(.createAccount)
                }
                .transition(.opacity)

            case .recommendations:
                RecommendationIntroView(
                    onChoosePreferences: { go(.preferences) },
                    onExplore: { go(.main) }
                )
                .transition(.opacity)

            case .preferences:
                StylePreferencesView(
                    onBack: { go(.recommendations) },
                    onComplete: { go(.main) }
                )
                .transition(.opacity)

            case .createAccount:
                CreateAccountView(
                    onCreate: { go(.recommendations) },
                    onLogin: { go(.login) }
                )
                .transition(.opacity)

            case .login:
                LoginView(
                    onLogin: { go(.main) },
                    onCreateAccount: { go(.createAccount) }
                )
                .transition(.opacity)

            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
    }

    private func go(_ route: StartRoute) {
        withAnimation(.spring(response: 0.62, dampingFraction: 0.88)) {
            startRoute = route
        }
    }
}

#Preview {
    ContentView()
}

private struct MainTabView: View {
    @State private var selectedTab: AppTab
    @State private var selectedClosetItem: ClosetGridItem?
    @State private var selectedEvent: LuneraEvent?
    @State private var isCreatingEvent = false
    @State private var detailDragProgress: CGFloat = 0
    @State private var shouldOpenEventDetailFromLaunch: Bool
    private let screenBackground = Color(red: 0.967, green: 0.965, blue: 0.96)
    private let screenBackgroundUIColor = UIColor(red: 0.967, green: 0.965, blue: 0.96, alpha: 1)

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let environment = ProcessInfo.processInfo.environment
        let startsFromDebugPreference = UserDefaults.standard.bool(forKey: "LUNERAStartEventCreation")
        if startsFromDebugPreference {
            UserDefaults.standard.set(false, forKey: "LUNERAStartEventCreation")
        }
        let startsInSearch = arguments.contains("--start-search")
        let startsInEventDetail = arguments.contains("--start-event-detail")
        let startsInEventCreation = arguments.contains("--start-event-creation")
            || environment["LUNERA_START_EVENT_CREATION"] == "1"
            || startsFromDebugPreference
        let startsInEvents = arguments.contains("--start-events")
            || startsInEventCreation
            || environment["LUNERA_START_TAB"] == "events"
        _selectedTab = State(initialValue: startsInSearch ? .search : ((startsInEvents || startsInEventDetail) ? .events : .browse))
        _selectedEvent = State(initialValue: nil)
        _isCreatingEvent = State(initialValue: startsInEventCreation)
        _shouldOpenEventDetailFromLaunch = State(initialValue: startsInEventDetail)
    }

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()
            NavigationContainerBackground(color: screenBackgroundUIColor)
                .allowsHitTesting(false)

            GeometryReader { proxy in
                let scale = proxy.size.width / 393
                let sidePadding = 22 * scale
                let isShowingOverlay = selectedClosetItem != nil || selectedEvent != nil || isCreatingEvent
                let detailVisibility = isShowingOverlay ? max(0, 1 - detailDragProgress) : 0

                ZStack(alignment: .top) {
                    TabView(selection: $selectedTab) {
                        Tab(value: AppTab.browse) {
                            HomeView { item in
                                openClosetDetail(item)
                            }
                        } label: {
                            Label("Browse", systemImage: "tshirt.fill")
                                .opacity(selectedTab == .browse ? 1 : 0.5)
                        }

                        Tab(value: AppTab.events) {
                            EventsView(
                                onSelectEvent: { event in
                                    openEventDetail(event)
                                },
                                onAddEvent: {
                                    openEventCreation()
                                }
                            )
                        } label: {
                            Label("Events", systemImage: "calendar")
                                .opacity(selectedTab == .events ? 1 : 0.5)
                        }

                        Tab(value: AppTab.search, role: .search) {
                            SearchView()
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                                .opacity(selectedTab == .search ? 1 : 0.5)
                        }
                    }
                    .offset(x: -42 * scale * detailVisibility)
                    .allowsHitTesting(!isShowingOverlay)

                    MainTopTabBar(scale: scale, sidePadding: sidePadding)
                        .offset(x: -42 * scale * detailVisibility)
                        .allowsHitTesting(!isShowingOverlay)
                        .zIndex(10)

                    if isShowingOverlay {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .accessibilityHidden(true)
                            .zIndex(15)
                    }

                    if let selectedClosetItem {
                        ClothingDetailView(
                            item: selectedClosetItem,
                            onDragProgress: { progress in
                                detailDragProgress = progress
                            },
                            onClose: { animated in
                                closeClosetDetail(animated: animated)
                            }
                        )
                        .zIndex(20)
                    }

                    if let selectedEvent {
                        EventDetailView(
                            event: selectedEvent,
                            onDragProgress: { progress in
                                detailDragProgress = progress
                            },
                            onClose: {
                                animated in
                                closeEventDetail(animated: animated)
                            }
                        )
                        .id(selectedEvent.id)
                        .zIndex(20)
                    }

                    if isCreatingEvent {
                        EventCreationFlow(
                            onDragProgress: { progress in
                                detailDragProgress = progress
                            },
                            onClose: { animated in
                                closeEventCreation(animated: animated)
                            }
                        )
                        .zIndex(20)
                    }
                }
            }
        }
        .background(screenBackground.ignoresSafeArea())
        .tint(LuneraTheme.ink)
        .statusBarHidden(true)
        .onAppear {
            guard shouldOpenEventDetailFromLaunch else {
                return
            }

            shouldOpenEventDetailFromLaunch = false
            DispatchQueue.main.async {
                openEventDetail(.valentines)
            }
        }
    }

    private func openClosetDetail(_ item: ClosetGridItem) {
        selectedEvent = nil
        isCreatingEvent = false
        guard selectedClosetItem != item else {
            return
        }

        detailDragProgress = 1
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            selectedClosetItem = item
        }
    }

    private func closeClosetDetail(animated: Bool = true) {
        if animated {
            detailDragProgress = 0
            withAnimation(.smooth(duration: 0.36)) {
                selectedClosetItem = nil
            }
            return
        }

        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            selectedClosetItem = nil
            detailDragProgress = 0
        }
    }

    private func openEventDetail(_ event: LuneraEvent) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            selectedTab = .events
            selectedClosetItem = nil
            selectedEvent = nil
            isCreatingEvent = false
            detailDragProgress = 1
        }

        DispatchQueue.main.async {
            var mountTransaction = Transaction(animation: nil)
            mountTransaction.disablesAnimations = true

            withTransaction(mountTransaction) {
                selectedEvent = event
            }
        }
    }

    private func openEventCreation() {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            selectedTab = .events
            selectedClosetItem = nil
            selectedEvent = nil
            isCreatingEvent = false
            detailDragProgress = 1
        }

        DispatchQueue.main.async {
            var mountTransaction = Transaction(animation: nil)
            mountTransaction.disablesAnimations = true

            withTransaction(mountTransaction) {
                isCreatingEvent = true
            }
        }
    }

    private func closeEventDetail(animated: Bool = true) {
        guard animated else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                selectedEvent = nil
                detailDragProgress = 0
            }
            return
        }

        withAnimation(.smooth(duration: 0.36)) {
            selectedEvent = nil
            detailDragProgress = 0
        }
    }

    private func closeEventCreation(animated: Bool = true) {
        guard animated else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                isCreatingEvent = false
                detailDragProgress = 0
            }
            return
        }

        withAnimation(.smooth(duration: 0.36)) {
            isCreatingEvent = false
            detailDragProgress = 0
        }
    }
}

private struct NavigationContainerBackground: UIViewRepresentable {
    let color: UIColor

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            uiView.window?.backgroundColor = color

            var superview = uiView.superview
            while let current = superview {
                current.backgroundColor = color
                superview = current.superview
            }

            guard let viewController = uiView.closestViewController else {
                return
            }

            viewController.view.backgroundColor = color
            viewController.navigationController?.view.backgroundColor = color
            viewController.navigationController?.visibleViewController?.view.backgroundColor = color
            viewController.navigationController?.topViewController?.view.backgroundColor = color
            viewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            viewController.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

private extension UIView {
    var closestViewController: UIViewController? {
        sequence(first: next, next: { $0?.next })
            .first { $0 is UIViewController } as? UIViewController
    }
}

private struct MainTopTabBar: View {
    let scale: CGFloat
    let sidePadding: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            MainTopTabBarBlur(height: 98 * scale)
                .allowsHitTesting(false)

            HStack(alignment: .center) {
                LuneraLogo(width: 110 * scale)

                Spacer()

                LuneraProfileAvatarButton(size: 48 * scale, scale: scale)
            }
            .padding(.top, 8 * scale)
            .padding(.horizontal, sidePadding)
        }
        .frame(height: 98 * scale, alignment: .top)
    }
}

private struct MainTopTabBarBlur: View {
    let height: CGFloat

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                LinearGradient(
                    colors: [
                        Color(red: 0.967, green: 0.965, blue: 0.96).opacity(0.92),
                        Color(red: 0.967, green: 0.965, blue: 0.96).opacity(0.52),
                        Color(red: 0.967, green: 0.965, blue: 0.96).opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
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

private enum AppTab: Hashable {
    case browse
    case events
    case search
}

private enum StartRoute {
    case welcome
    case recommendations
    case preferences
    case createAccount
    case login
    case main

    var requiresAuthentication: Bool {
        switch self {
        case .recommendations, .preferences, .main:
            true
        case .welcome, .createAccount, .login:
            false
        }
    }
}

private struct WelcomeView: View {
    let onGetStarted: () -> Void

    @State private var contentVisible = false

    var body: some View {
        GeometryReader { proxy in
            let scale = max(proxy.size.width / 393, proxy.size.height / 852)

            ZStack {
                Color(red: 0.961, green: 0.961, blue: 0.969)
                    .ignoresSafeArea()

                VStack(spacing: 7 * scale) {
                    LuneraLogo(width: 183 * scale)
                        .padding(.leading, 22 * scale)

                    Text("Guided by Your Glow")
                        .font(.system(size: 22 * scale, weight: .regular))
                        .foregroundStyle(Color(red: 0.643, green: 0.651, blue: 0.678))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.5 - 1 * scale)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 22 * scale)
                .animation(.spring(response: 0.58, dampingFraction: 0.9).delay(0.5), value: contentVisible)

                VStack {
                    Spacer()

                    Button {
                        onGetStarted()
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 17 * scale, weight: .semibold))
                            .foregroundStyle(Color(red: 0.961, green: 0.961, blue: 0.969))
                            .padding(.horizontal, 22 * scale)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48 * scale)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .luneraLiquidGlassCapsule(.primary, scale: scale)
                    .padding(.horizontal, 47 * scale)
                    .padding(.bottom, 46 * scale)
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : 22 * scale)
                    .animation(.spring(response: 0.58, dampingFraction: 0.9).delay(0.64), value: contentVisible)
                }
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
        .onAppear {
            contentVisible = false
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                contentVisible = true
            }
        }
    }
}

private struct EventsView: View {
    let onSelectEvent: (LuneraEvent) -> Void
    let onAddEvent: () -> Void

    private let logoTopPadding: CGFloat = 8
    private let sidePaddingBase: CGFloat = 22

    private let events = [
        LuneraEvent.christmas,
        LuneraEvent.valentines
    ]

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 393
            let sidePadding = sidePaddingBase * scale
            let cardHeight = 205 * scale

            ZStack(alignment: .top) {
                Color(red: 0.967, green: 0.965, blue: 0.96)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Color.clear
                        .frame(height: (logoTopPadding + 48 + 52) * scale)

                    VStack(spacing: 16 * scale) {
                        ForEach(events) { event in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onSelectEvent(event)
                            } label: {
                                EventCard(event: event, scale: scale)
                                    .frame(height: cardHeight)
                            }
                            .buttonStyle(.plain)
                        }

                        AddEventRow(scale: scale, action: onAddEvent)
                            .frame(height: 48 * scale)
                            .padding(.top, 1 * scale)
                    }
                }
                .padding(.horizontal, sidePadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .statusBarHidden(true)
    }
}

private struct LuneraEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let daysLeft: String
    let imageName: String

    static let christmas = LuneraEvent(title: "Christmas Event", daysLeft: "24 Days left", imageName: "EventChristmas")
    static let valentines = LuneraEvent(title: "Valentines", daysLeft: "81 Days left", imageName: "EventValentines")

    init(title: String, daysLeft: String, imageName: String) {
        self.id = title
        self.title = title
        self.daysLeft = daysLeft
        self.imageName = imageName
    }
}

private struct EventCard: View {
    let event: LuneraEvent
    let scale: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Image(event.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0),
                        .init(color: .black.opacity(0), location: 0.44),
                        .init(color: .black.opacity(0.72), location: 0.74),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width, height: proxy.size.height)

                HStack(alignment: .firstTextBaseline) {
                    Text(event.title)
                        .font(.system(size: 25 * scale, weight: .regular, design: .serif))
                        .italic()
                        .tracking(-2 * scale)
                        .foregroundStyle(.white)

                    Spacer()

                    Text(event.daysLeft)
                        .font(.system(size: 20 * scale, weight: .light))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .padding(.horizontal, 30 * scale)
                .padding(.bottom, 30 * scale)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 34 * scale, style: .continuous))
        }
    }
}

private struct AddEventRow: View {
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10 * scale) {
                Text("Add an event")
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 20 * scale, weight: .regular))
                    .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))
            }
            .padding(.horizontal, 18 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Capsule())
            .luneraLiquidGlassCapsule(.secondary, scale: scale)
        }
        .buttonStyle(.plain)
    }
}

private enum EventCreationStep: Int, CaseIterable {
    case name
    case date
    case picture
    case preview
}

private enum EventCreationTransitionDirection {
    case forward
    case backward
}

private struct EventCreationFadeLiftModifier: ViewModifier {
    let opacity: Double
    let yOffset: CGFloat
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: yOffset)
            .scaleEffect(scale)
    }
}

private extension AnyTransition {
    static func eventCreationFadeLift(yOffset: CGFloat, scale: CGFloat) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: EventCreationFadeLiftModifier(opacity: 0, yOffset: yOffset, scale: scale),
                identity: EventCreationFadeLiftModifier(opacity: 1, yOffset: 0, scale: 1)
            ),
            removal: .modifier(
                active: EventCreationFadeLiftModifier(opacity: 0, yOffset: -yOffset * 0.65, scale: 0.998),
                identity: EventCreationFadeLiftModifier(opacity: 1, yOffset: 0, scale: 1)
            )
        )
    }
}

private struct EventCreationFlow: View {
    let onDragProgress: (CGFloat) -> Void
    let onClose: (Bool) -> Void

    @State private var step: EventCreationStep = .name
    @State private var eventName = ""
    @State private var eventDate = Calendar.current.date(byAdding: .day, value: 81, to: Date()) ?? Date()
    @State private var selectedEventPhotoItem: PhotosPickerItem?
    @State private var selectedEventImage: UIImage?
    @State private var isShowingUnsplashPicker = false
    @State private var transitionDirection: EventCreationTransitionDirection = .forward
    @State private var presentationOffset: CGFloat = UIScreen.main.bounds.width + 24
    @State private var didRunPresentationAnimation = false

    private let background = Color(red: 0.967, green: 0.965, blue: 0.96)
    private let ink = Color(red: 0.165, green: 0.184, blue: 0.271)
    private let mutedInk = Color(red: 0.61, green: 0.62, blue: 0.66)

    private var previewTitle: String {
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Event" : trimmedName
    }

    private var daysLeftText: String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: eventDate)
        let days = max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
        return days == 1 ? "1 Day Left" : "\(days) Days Left"
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 393, proxy.size.height / 852)
            let deviceCornerRadius = EventDeviceCornerRadius.radius(for: proxy, scale: scale)

            ZStack(alignment: .top) {
                background
                    .ignoresSafeArea()

                EventCircleControl(systemImage: "chevron.left", label: "Back", scale: scale) {
                    goBack(width: proxy.size.width)
                }
                .position(x: 47 * scale, y: 47 * scale)
                .zIndex(10)

                if step == .preview {
                    EventCircleControl(systemImage: "pencil", label: "Edit event", scale: scale) {
                        moveTo(.picture, direction: .backward)
                    }
                    .position(x: proxy.size.width - 47 * scale, y: 47 * scale)
                    .transition(.opacity)
                    .zIndex(10)
                }

                stepContent(scale: scale, width: proxy.size.width)
                    .id(step)
                    .transition(stepTransition(for: step, scale: scale))
                    .animation(stepAnimation(for: step), value: step)

            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: deviceCornerRadius,
                    bottomLeadingRadius: deviceCornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
            .offset(x: presentationOffset)
            .onAppear {
                startPresentation(width: proxy.size.width)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .preferredColorScheme(.light)
        .onChange(of: selectedEventPhotoItem) { _, newItem in
            loadEventImage(from: newItem)
        }
        .sheet(isPresented: $isShowingUnsplashPicker) {
            UnsplashEventImagePicker(initialQuery: previewTitle) { photo in
                loadUnsplashImage(from: photo)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.light)
        }
    }

    @ViewBuilder
    private func stepContent(scale: CGFloat, width: CGFloat) -> some View {
        switch step {
        case .name:
            EventCreationNameStep(
                eventName: $eventName,
                placeholderColor: mutedInk,
                textColor: ink,
                buttonTitle: "Next",
                scale: scale,
                action: goNext
            )
        case .date:
            EventCreationDateStep(
                title: "When is the event?",
                titleColor: ink,
                scale: scale,
                width: width,
                selectedDate: $eventDate,
                action: goNext
            )
        case .picture:
            EventCreationPictureStep(
                title: "Add a picture",
                titleColor: ink,
                scale: scale,
                selectedItem: $selectedEventPhotoItem,
                onUnsplash: showUnsplashPicker
            )
        case .preview:
            EventCreationPreviewStep(title: previewTitle, daysLeft: daysLeftText, image: selectedEventImage, scale: scale) {
                close(width: width)
            }
        }
    }

    private var stepAnimation: Animation {
        .spring(response: 0.46, dampingFraction: 0.92, blendDuration: 0.08)
    }

    private var previewFadeAnimation: Animation {
        .easeInOut(duration: 0.20)
    }

    private func stepAnimation(for newStep: EventCreationStep) -> Animation {
        newStep == .preview ? previewFadeAnimation : stepAnimation
    }

    private func stepTransition(for newStep: EventCreationStep, scale: CGFloat) -> AnyTransition {
        guard newStep != .preview else {
            return .opacity
        }

        let offset = (transitionDirection == .forward ? 10 : -10) * scale
        return .eventCreationFadeLift(yOffset: offset, scale: 0.992)
    }

    private func startPresentation(width: CGFloat) {
        guard !didRunPresentationAnimation else {
            return
        }

        didRunPresentationAnimation = true
        presentationOffset = width + 24
        onDragProgress(1)

        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.36, extraBounce: 0)) {
                presentationOffset = 0
                onDragProgress(0)
            }
        }
    }

    private func goNext() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let currentIndex = EventCreationStep.allCases.firstIndex(of: step),
              currentIndex < EventCreationStep.allCases.index(before: EventCreationStep.allCases.endIndex) else {
            return
        }

        moveTo(EventCreationStep.allCases[EventCreationStep.allCases.index(after: currentIndex)], direction: .forward)
    }

    private func loadEventImage(from item: PhotosPickerItem?) {
        guard let item else {
            return
        }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                await MainActor.run {
                    selectedEventPhotoItem = nil
                }
                return
            }

            await MainActor.run {
                selectedEventImage = image
                selectedEventPhotoItem = nil

                if step == .picture {
                    goNext()
                }
            }
        }
    }

    private func showUnsplashPicker() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isShowingUnsplashPicker = true
    }

    private func loadUnsplashImage(from photo: UnsplashPhoto) {
        isShowingUnsplashPicker = false

        Task {
            await UnsplashClient.shared.trackDownload(for: photo)

            guard let image = await UnsplashClient.shared.loadImage(from: photo.urls.regular) else {
                return
            }

            await MainActor.run {
                selectedEventImage = image

                if step == .picture {
                    goNext()
                }
            }
        }
    }

    private func goBack(width: CGFloat) {
        guard let currentIndex = EventCreationStep.allCases.firstIndex(of: step), currentIndex > 0 else {
            close(width: width)
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        moveTo(EventCreationStep.allCases[EventCreationStep.allCases.index(before: currentIndex)], direction: .backward)
    }

    private func moveTo(_ newStep: EventCreationStep, direction: EventCreationTransitionDirection) {
        transitionDirection = direction
        withAnimation(stepAnimation(for: newStep)) {
            step = newStep
        }
    }

    private func close(width: CGFloat, animated: Bool = true) {
        guard animated else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                onClose(false)
            }
            return
        }

        withAnimation(.smooth(duration: 0.36)) {
            presentationOffset = width + 24
            onDragProgress(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            close(width: width, animated: false)
        }
    }
}

private struct EventCreationNameStep: View {
    @Binding var eventName: String
    let placeholderColor: Color
    let textColor: Color
    let buttonTitle: String
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        VStack(spacing: 21 * scale) {
            ZStack {
                if eventName.isEmpty {
                    Text("What is the Event?")
                        .font(nameFont)
                        .italic()
                        .tracking(-1.6 * scale)
                        .foregroundStyle(placeholderColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .allowsHitTesting(false)
                }

                TextField("", text: $eventName)
                    .font(nameFont)
                    .italic()
                    .tracking(-1.6 * scale)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .tint(textColor)
                    .textFieldStyle(.plain)
                    .lineLimit(1)
                    .frame(width: 330 * scale, height: 34 * scale)
                    .onSubmit(action)
            }
            .frame(width: 330 * scale, height: 34 * scale)

            EventCreationPrimaryButton(title: buttonTitle, width: 202 * scale, scale: scale, action: action)
        }
        .frame(width: 330 * scale, height: 103 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var nameFont: Font {
        .system(size: 26 * scale, weight: .semibold, design: .serif)
    }
}

private struct EventCreationPromptStep: View {
    let title: String
    let titleColor: Color
    let buttonTitle: String
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        VStack(spacing: 21 * scale) {
            Text(title)
                .font(.system(size: 26 * scale, weight: .semibold, design: .serif))
                .italic()
                .tracking(-1.6 * scale)
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .multilineTextAlignment(.center)
                .frame(width: 330 * scale, height: 34 * scale)

            EventCreationPrimaryButton(title: buttonTitle, width: 202 * scale, scale: scale, action: action)
        }
        .frame(width: 330 * scale, height: 103 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct EventCreationDateStep: View {
    let title: String
    let titleColor: Color
    let scale: CGFloat
    let width: CGFloat
    @Binding var selectedDate: Date
    let action: () -> Void

    private var contentPadding: CGFloat {
        18 * scale
    }

    private var buttonCornerRadius: CGFloat {
        24 * scale
    }

    private var containerCornerRadius: CGFloat {
        buttonCornerRadius + contentPadding
    }

    private var calendarContentWidth: CGFloat {
        min(336 * scale, width - 42 * scale)
    }

    private var calendarContainerWidth: CGFloat {
        calendarContentWidth + (contentPadding * 2)
    }

    private var calendarHeight: CGFloat {
        330 * scale
    }

    var body: some View {
        VStack(spacing: 18 * scale) {
            Text(title)
                .font(.system(size: 26 * scale, weight: .semibold, design: .serif))
                .italic()
                .tracking(-1.6 * scale)
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .multilineTextAlignment(.center)
                .frame(width: 330 * scale, height: 34 * scale)

            EventCreationNativeCalendar(
                selectedDate: stableSelectedDate,
                minimumDate: Date(),
                tintColor: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1)
            )
            .frame(width: calendarContentWidth, height: calendarHeight, alignment: .center)
            .clipped()
            .padding(contentPadding)
            .frame(width: calendarContainerWidth)
            .frame(height: calendarHeight + (contentPadding * 2))
            .eventCreationDatePickerGlass(cornerRadius: containerCornerRadius, scale: scale)

            EventCreationPrimaryButton(title: "Next", width: 202 * scale, scale: scale, action: action)
        }
        .frame(width: calendarContainerWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var stableSelectedDate: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newValue in
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    selectedDate = newValue
                }
            }
        )
    }
}

private struct EventCreationNativeCalendar: UIViewRepresentable {
    let selectedDate: Binding<Date>
    let minimumDate: Date
    let tintColor: UIColor

    func makeUIView(context: Context) -> EventCreationNativeCalendarHost {
        let host = EventCreationNativeCalendarHost()
        host.datePicker.datePickerMode = .date
        host.datePicker.preferredDatePickerStyle = .inline
        host.datePicker.backgroundColor = .clear
        host.datePicker.tintColor = tintColor
        host.datePicker.minimumDate = minimumDate
        host.datePicker.setDate(selectedDate.wrappedValue, animated: false)
        host.datePicker.addTarget(
            context.coordinator,
            action: #selector(Coordinator.dateChanged(_:)),
            for: .valueChanged
        )
        return host
    }

    func updateUIView(_ host: EventCreationNativeCalendarHost, context: Context) {
        context.coordinator.selectedDate = selectedDate
        host.datePicker.minimumDate = minimumDate
        host.datePicker.tintColor = tintColor

        guard !Calendar.current.isDate(host.datePicker.date, inSameDayAs: selectedDate.wrappedValue) else {
            return
        }

        UIView.performWithoutAnimation {
            host.datePicker.setDate(selectedDate.wrappedValue, animated: false)
            host.layoutIfNeeded()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedDate: selectedDate)
    }

    final class Coordinator: NSObject {
        var selectedDate: Binding<Date>

        init(selectedDate: Binding<Date>) {
            self.selectedDate = selectedDate
        }

        @objc
        func dateChanged(_ sender: UIDatePicker) {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                selectedDate.wrappedValue = sender.date
            }
        }
    }
}

private final class EventCreationNativeCalendarHost: UIView {
    let datePicker = UIDatePicker()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        datePicker.backgroundColor = .clear
        datePicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        datePicker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        datePicker.setContentHuggingPriority(.defaultLow, for: .vertical)
        datePicker.setContentCompressionResistancePriority(.required, for: .horizontal)
        datePicker.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(datePicker)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        datePicker.frame = bounds
    }
}

private struct EventCreationPictureStep: View {
    let title: String
    let titleColor: Color
    let scale: CGFloat
    @Binding var selectedItem: PhotosPickerItem?
    let onUnsplash: () -> Void

    var body: some View {
        VStack(spacing: 21 * scale) {
            Text(title)
                .font(.system(size: 26 * scale, weight: .semibold, design: .serif))
                .italic()
                .tracking(-1.6 * scale)
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .multilineTextAlignment(.center)
                .frame(width: 330 * scale, height: 34 * scale)

            HStack(spacing: 10 * scale) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    EventCreationPrimaryButtonLabel(title: "Library", width: 146 * scale, scale: scale)
                }
                .buttonStyle(.plain)

                Button(action: onUnsplash) {
                    EventCreationPrimaryButtonLabel(title: "Unsplash", width: 146 * scale, scale: scale)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 330 * scale, height: 103 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct UnsplashEventImagePicker: View {
    @Environment(\.dismiss) private var dismiss

    let initialQuery: String
    let onSelect: (UnsplashPhoto) -> Void

    @State private var query: String
    @State private var photos: [UnsplashPhoto] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let background = Color(red: 0.967, green: 0.965, blue: 0.96)
    private let ink = Color(red: 0.11, green: 0.14, blue: 0.20)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(initialQuery: String, onSelect: @escaping (UnsplashPhoto) -> Void) {
        self.initialQuery = initialQuery
        self.onSelect = onSelect
        _query = State(initialValue: initialQuery)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background
                    .ignoresSafeArea()

                content
            }
            .navigationTitle("Unsplash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(ink)
                }
            }
            .searchable(text: $query, prompt: "Search images")
            .onSubmit(of: .search, search)
            .task {
                await searchIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .tint(ink)
        } else if let errorMessage {
            Text(errorMessage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.55, green: 0.56, blue: 0.60))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        } else if photos.isEmpty {
            Text("No images found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.55, green: 0.56, blue: 0.60))
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(photos) { photo in
                        Button {
                            onSelect(photo)
                            dismiss()
                        } label: {
                            UnsplashPhotoCell(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
    }

    private func search() {
        Task {
            await runSearch()
        }
    }

    private func searchIfNeeded() async {
        guard photos.isEmpty else {
            return
        }

        await runSearch()
    }

    @MainActor
    private func runSearch() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            photos = try await UnsplashClient.shared.searchPhotos(query: trimmedQuery)
        } catch UnsplashClientError.missingAccessKey {
            errorMessage = "Unsplash access key missing"
        } catch {
            errorMessage = "Unable to load Unsplash"
        }

        isLoading = false
    }
}

private struct UnsplashPhotoCell: View {
    let photo: UnsplashPhoto
    private let height: CGFloat = 168

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: photo.urls.small) { phase in
                    imageContent(for: phase, width: width)
                }
                .frame(width: width, height: height)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.48)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width, height: height)

                Text(photo.user.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 9)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func imageContent(for phase: AsyncImagePhase, width: CGFloat) -> some View {
        switch phase {
        case .empty:
            Rectangle()
                .fill(Color(red: 0.88, green: 0.88, blue: 0.90))
                .overlay {
                    ProgressView()
                        .tint(Color(red: 0.11, green: 0.14, blue: 0.20))
                }
                .frame(width: width, height: height)
        case .success(let image):
            image
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
        case .failure:
            Rectangle()
                .fill(Color(red: 0.88, green: 0.88, blue: 0.90))
                .frame(width: width, height: height)
        @unknown default:
            Rectangle()
                .fill(Color(red: 0.88, green: 0.88, blue: 0.90))
                .frame(width: width, height: height)
        }
    }
}

private struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Decodable, Identifiable {
    let id: String
    let urls: UnsplashPhotoURLs
    let links: UnsplashPhotoLinks
    let user: UnsplashUser
}

private struct UnsplashPhotoURLs: Decodable {
    let regular: URL
    let small: URL
}

private struct UnsplashPhotoLinks: Decodable {
    let downloadLocation: URL

    enum CodingKeys: String, CodingKey {
        case downloadLocation = "download_location"
    }
}

private struct UnsplashUser: Decodable {
    let name: String
}

private enum UnsplashClientError: Error {
    case missingAccessKey
    case invalidURL
    case requestFailed
}

private final class UnsplashClient {
    static let shared = UnsplashClient()

    private let decoder = JSONDecoder()

    private var accessKey: String? {
        let environment = ProcessInfo.processInfo.environment
        let candidates = [
            environment["UNSPLASH_ACCESS_KEY"],
            environment["LUNERA_UNSPLASH_ACCESS_KEY"],
            UserDefaults.standard.string(forKey: "UnsplashAccessKey"),
            Bundle.main.object(forInfoDictionaryKey: "UnsplashAccessKey") as? String
        ]

        return candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    func searchPhotos(query: String) async throws -> [UnsplashPhoto] {
        guard let accessKey else {
            throw UnsplashClientError.missingAccessKey
        }

        var components = URLComponents(string: "https://api.unsplash.com/search/photos")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "24"),
            URLQueryItem(name: "orientation", value: "landscape")
        ]

        guard let url = components?.url else {
            throw UnsplashClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw UnsplashClientError.requestFailed
        }

        return try decoder.decode(UnsplashSearchResponse.self, from: data).results
    }

    func trackDownload(for photo: UnsplashPhoto) async {
        guard let accessKey else {
            return
        }

        var request = URLRequest(url: photo.links.downloadLocation)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        _ = try? await URLSession.shared.data(for: request)
    }

    func loadImage(from url: URL) async -> UIImage? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            return nil
        }

        return UIImage(data: data)
    }
}

private struct EventCreationDatePickerPopup: View {
    @Binding var selectedDate: Date
    let scale: CGFloat
    let onCancel: () -> Void
    let onDone: () -> Void

    private var contentPadding: CGFloat { 18 * scale }
    private var buttonCornerRadius: CGFloat { 24 * scale }
    private var containerCornerRadius: CGFloat { buttonCornerRadius + contentPadding }
    private var popupWidth: CGFloat { min(344 * scale, UIScreen.main.bounds.width - 36 * scale) }
    private var calendarWidth: CGFloat { popupWidth - (contentPadding * 2) }
    private var calendarHeight: CGFloat { 330 * scale }

    var body: some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 14 * scale) {
                EventCreationCalendarGrid(
                    selectedDate: $selectedDate,
                    scale: scale,
                    width: calendarWidth,
                    height: calendarHeight
                )

                HStack(spacing: 10 * scale) {
                    EventCreationSecondaryButton(title: "Cancel", scale: scale, action: onCancel)
                    EventCreationPrimaryButton(title: "Done", width: 142 * scale, scale: scale, action: onDone)
                }
            }
            .padding(.horizontal, contentPadding)
            .padding(.top, contentPadding)
            .padding(.bottom, contentPadding)
            .frame(width: popupWidth)
            .frame(height: calendarHeight + 48 * scale + 14 * scale + (contentPadding * 2))
            .eventCreationDatePickerGlass(cornerRadius: containerCornerRadius, scale: scale)
        }
    }
}

private struct EventCreationCalendarGrid: View {
    @Binding var selectedDate: Date
    let scale: CGFloat
    let width: CGFloat
    let height: CGFloat
    let onSelect: (() -> Void)?

    @State private var displayedMonth: Date

    private let ink = Color(red: 0.08, green: 0.09, blue: 0.11)
    private let mutedInk = Color(red: 0.45, green: 0.45, blue: 0.46)
    private let disabledInk = Color(red: 0.70, green: 0.70, blue: 0.72)
    private let selectionFill = Color(red: 0.875, green: 0.88, blue: 0.895)
    private let weekdays = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    init(
        selectedDate: Binding<Date>,
        scale: CGFloat,
        width: CGFloat,
        height: CGFloat,
        onSelect: (() -> Void)? = nil
    ) {
        _selectedDate = selectedDate
        self.scale = scale
        self.width = width
        self.height = height
        self.onSelect = onSelect
        _displayedMonth = State(initialValue: Self.monthStart(for: selectedDate.wrappedValue))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }

    private var todayStart: Date {
        calendar.startOfDay(for: Date())
    }

    private var displayedDates: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return Array(repeating: nil, count: 42)
        }

        let firstWeekday = calendar.component(.weekday, from: displayedMonth)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        let monthDates = monthRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: displayedMonth)
        }
        let filledDates = Array(repeating: Date?.none, count: leadingEmptyDays) + monthDates
        return filledDates + Array(repeating: Date?.none, count: max(0, 42 - filledDates.count))
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var canGoToPreviousMonth: Bool {
        displayedMonth > Self.monthStart(for: todayStart)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 34 * scale)

            weekdayRow
                .padding(.top, 20 * scale)
                .frame(height: 45 * scale, alignment: .bottom)

            dateGrid
                .padding(.top, 6 * scale)
                .frame(height: height - (34 * scale) - (45 * scale), alignment: .top)
        }
        .frame(width: width, height: height)
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }

    private var header: some View {
        HStack(spacing: 4 * scale) {
            Text(monthTitle)
                .font(.system(size: 18 * scale, weight: .bold))
                .foregroundStyle(ink)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 17 * scale, weight: .bold))
                .foregroundStyle(ink)

            Spacer(minLength: 0)

            Button(action: goToPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 27 * scale, weight: .bold))
                    .foregroundStyle(canGoToPreviousMonth ? ink : disabledInk)
                    .frame(width: 37 * scale, height: 34 * scale)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoToPreviousMonth)

            Button(action: goToNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 27 * scale, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 37 * scale, height: 34 * scale)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 13 * scale, weight: .bold))
                    .foregroundStyle(mutedInk)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dateGrid: some View {
        VStack(spacing: 5 * scale) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        dateCell(displayedDates[(row * 7) + column])
                            .frame(width: width / 7, height: 36 * scale)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dateCell(_ date: Date?) -> some View {
        if let date {
            let dayStart = calendar.startOfDay(for: date)
            let isSelected = calendar.isDate(dayStart, inSameDayAs: selectedDate)
            let isDisabled = dayStart < todayStart

            Button {
                select(date)
            } label: {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(selectionFill)
                            .frame(width: 36 * scale, height: 36 * scale)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 20 * scale, weight: .regular))
                        .foregroundStyle(isDisabled ? disabledInk : ink)
                        .frame(width: 36 * scale, height: 36 * scale)
                }
                .frame(width: width / 7, height: 36 * scale)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        } else {
            Color.clear
        }
    }

    private func select(_ date: Date) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            selectedDate = date
        }

        onSelect?()
    }

    private func goToPreviousMonth() {
        guard canGoToPreviousMonth,
              let previousMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else {
            return
        }

        setDisplayedMonth(previousMonth)
    }

    private func goToNextMonth() {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else {
            return
        }

        setDisplayedMonth(nextMonth)
    }

    private func setDisplayedMonth(_ date: Date) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            displayedMonth = Self.monthStart(for: date)
        }
    }

    private static func monthStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

private extension View {
    @ViewBuilder
    func eventCreationDatePickerGlass(cornerRadius: CGFloat, scale: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            self
                .background(.white.opacity(0.22), in: shape)
                .glassEffect(.regular.tint(.white.opacity(0.42)).interactive(), in: shape)
                .overlay {
                    shape
                        .stroke(.white.opacity(0.78), lineWidth: max(1, 1.1 * scale))
                }
                .shadow(color: .white.opacity(0.62), radius: 1.4 * scale, x: -0.5 * scale, y: -0.5 * scale)
                .shadow(color: .black.opacity(0.070), radius: 11 * scale, x: 0, y: 4 * scale)
        } else {
            self
                .background(.white.opacity(0.72), in: shape)
                .overlay {
                    shape
                        .stroke(.white.opacity(0.86), lineWidth: max(1, 1.2 * scale))
                }
                .shadow(color: .black.opacity(0.045), radius: 7 * scale, x: 0, y: 2 * scale)
        }
    }
}

private struct EventCreationPreviewStep: View {
    let title: String
    let daysLeft: String
    let image: UIImage?
    let scale: CGFloat
    let action: () -> Void

    private let background = Color(red: 0.967, green: 0.965, blue: 0.96)
    private let ink = Color(red: 0.165, green: 0.184, blue: 0.271)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                if let image {
                    EventDetailHero(image: image, background: background, scale: scale)
                        .frame(width: proxy.size.width, height: 286 * scale)
                        .allowsHitTesting(false)
                } else {
                    EventDetailHero(imageName: LuneraEvent.valentines.imageName, background: background, scale: scale)
                        .frame(width: proxy.size.width, height: 286 * scale)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 216 * scale)

                    Text(title)
                        .font(.system(size: 32 * scale, weight: .semibold, design: .serif))
                        .italic()
                        .tracking(-2 * scale)
                        .foregroundStyle(ink)
                        .lineLimit(1)

                    Text(daysLeft)
                        .font(.system(size: 17 * scale, weight: .regular))
                        .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))
                        .padding(.top, 3 * scale)
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack {
                    Spacer()

                    EventCreationPrimaryButton(title: "Looks Good", width: 324 * scale, scale: scale, action: action)
                        .padding(.bottom, 34 * scale)
                }
            }
        }
    }
}

private struct EventCreationSecondaryButton: View {
    let title: String
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16 * scale, weight: .semibold))
                .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.20))
                .lineLimit(1)
                .frame(width: 142 * scale, height: 48 * scale)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.55), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.84), lineWidth: max(1, 1 * scale))
        }
        .shadow(color: .black.opacity(0.055), radius: 8 * scale, x: 0, y: 3 * scale)
    }
}

private struct EventCreationPrimaryButton: View {
    let title: String
    let width: CGFloat
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            EventCreationPrimaryButtonLabel(title: title, width: width, scale: scale)
        }
        .buttonStyle(.plain)
    }
}

private struct EventCreationPrimaryButtonLabel: View {
    let title: String
    let width: CGFloat
    let scale: CGFloat

    var body: some View {
        Text(title)
            .font(.system(size: 16 * scale, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(width: width, height: 48 * scale)
            .contentShape(Capsule())
            .buttonStyle(.plain)
            .luneraLiquidGlassCapsule(.primary, scale: scale)
    }
}

private enum EventDetailSection: CaseIterable, Hashable {
    case wardrobe
    case lunera
    case todo

    var title: String {
        switch self {
        case .wardrobe:
            "Wardrope"
        case .lunera:
            "Lunera"
        case .todo:
            "To-Do"
        }
    }
}

private struct EventDetailView: View {
    let event: LuneraEvent
    let onDragProgress: (CGFloat) -> Void
    let onClose: (Bool) -> Void

    @State private var selectedSection: EventDetailSection = .wardrobe
    @State private var todoItems = [
        EventTodoItem(title: "Buy this"),
        EventTodoItem(title: "Buy this"),
        EventTodoItem(title: "Buy this"),
        EventTodoItem(title: "Buy this")
    ]
    @State private var keyboardOverlap: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var presentationOffset: CGFloat = UIScreen.main.bounds.width + 24
    @State private var isCompletingDragClose = false
    @State private var didRunPresentationAnimation = false

    private let background = Color(red: 0.967, green: 0.965, blue: 0.96)
    private let ink = Color(red: 0.11, green: 0.14, blue: 0.20)
    private let mutedInk = Color(red: 0.61, green: 0.62, blue: 0.66)

    init(event: LuneraEvent, onDragProgress: @escaping (CGFloat) -> Void, onClose: @escaping (Bool) -> Void) {
        self.event = event
        self.onDragProgress = onDragProgress
        self.onClose = onClose
        _selectedSection = State(initialValue: Self.initialSectionFromLaunchArguments())
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 393, proxy.size.height / 852)
            let designWidth = 393 * scale
            let designHeight = max(proxy.size.height, 852 * scale)
            let deviceCornerRadius = EventDeviceCornerRadius.radius(for: proxy, scale: scale)

            ZStack(alignment: .top) {
                background
                    .ignoresSafeArea()

                EventDetailHero(imageName: event.imageName, background: background, scale: scale)
                    .frame(width: proxy.size.width, height: 286 * scale, alignment: .top)
                    .allowsHitTesting(false)

                EventCircleControl(systemImage: "chevron.left", label: "Back", scale: scale) {
                    closeDetail(width: proxy.size.width)
                }
                    .position(x: 47 * scale, y: 47 * scale)
                    .zIndex(10)

                EventCircleControl(systemImage: "pencil", label: "Edit event", scale: scale) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                    .position(x: proxy.size.width - 47 * scale, y: 47 * scale)
                    .zIndex(10)

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 212 * scale)

                    Text(event.title)
                        .font(.system(size: 34 * scale, weight: .semibold, design: .serif))
                        .italic()
                        .tracking(-2.2 * scale)
                        .foregroundStyle(Color(red: 0.165, green: 0.184, blue: 0.271))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(event.daysLeft.replacingOccurrences(of: "left", with: "Left"))
                        .font(.system(size: 18 * scale, weight: .regular))
                        .foregroundStyle(ink)
                        .padding(.top, 6 * scale)

                    EventSectionPicker(selectedSection: $selectedSection, scale: scale)
                        .frame(width: 338 * scale, height: 48 * scale)
                        .padding(.top, 20 * scale)

                    EventSectionContent(
                        selectedSection: selectedSection,
                        todoItems: $todoItems,
                        scale: scale,
                        ink: ink,
                        mutedInk: mutedInk,
                        background: background,
                        keyboardOverlap: keyboardOverlap
                    )
                    .frame(width: 346 * scale)
                    .padding(.top, 18 * scale)

                    Spacer(minLength: 0)
                }
                .frame(width: designWidth, height: designHeight, alignment: .top)
                .position(x: proxy.size.width / 2, y: designHeight / 2)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: deviceCornerRadius,
                    bottomLeadingRadius: deviceCornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
            .offset(x: presentationOffset + dragOffset)
            .simultaneousGesture(closeDragGesture(scale: scale, width: proxy.size.width))
            .onAppear {
                startPresentation(width: proxy.size.width)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                updateKeyboardOverlap(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                updateKeyboardOverlap(from: notification)
            }
            .background {
                KeyboardDismissGestureInstaller(isActive: keyboardOverlap > 0) {
                    dismissKeyboard()
                }
            }
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
        .statusBarHidden(true)
        .preferredColorScheme(.light)
        .onAppear {
            dragOffset = 0
            isCompletingDragClose = false
        }
    }

    private func startPresentation(width: CGFloat) {
        guard !didRunPresentationAnimation else {
            return
        }

        didRunPresentationAnimation = true
        presentationOffset = width + 24
        onDragProgress(1)

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
        dismissKeyboard()

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
                guard !isCompletingDragClose else {
                    return
                }

                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                let isRightSwipe = horizontalDistance > 0 && abs(horizontalDistance) > verticalDistance

                guard isRightSwipe else {
                    return
                }

                dismissKeyboard()
                dragOffset = min(width, max(0, horizontalDistance))
                onDragProgress(min(1, dragOffset / width))
            }
            .onEnded { value in
                guard !isCompletingDragClose else {
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
        dismissKeyboard()

        withAnimation(.snappy(duration: 0.2, extraBounce: 0)) {
            dragOffset = width + 24
            onDragProgress(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            closeDetail(width: width, animated: false)
        }
    }

    private func updateKeyboardOverlap(from notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        let overlap = max(0, UIScreen.main.bounds.height - endFrame.minY)
        let isShowing = overlap > keyboardOverlap

        withAnimation(Self.keyboardAnimation(duration: duration, isShowing: isShowing)) {
            keyboardOverlap = overlap
        }
    }

    private static func keyboardAnimation(duration: Double, isShowing: Bool) -> Animation {
        .spring(
            response: max(duration, isShowing ? 0.42 : 0.48),
            dampingFraction: isShowing ? 0.86 : 0.9,
            blendDuration: 0.08
        )
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private static func initialSectionFromLaunchArguments() -> EventDetailSection {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--event-todo") {
            return .todo
        }

        if arguments.contains("--event-lunera") {
            return .lunera
        }

        return .wardrobe
    }
}

private struct KeyboardDismissGestureInstaller: UIViewRepresentable {
    let isActive: Bool
    let dismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isActive: isActive, dismiss: dismiss)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.isActive = isActive
        context.coordinator.dismiss = dismiss

        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(in: uiView.window)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.remove()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isActive: Bool
        var dismiss: () -> Void

        private weak var window: UIWindow?
        private weak var recognizer: UITapGestureRecognizer?

        init(isActive: Bool, dismiss: @escaping () -> Void) {
            self.isActive = isActive
            self.dismiss = dismiss
        }

        func installIfNeeded(in newWindow: UIWindow?) {
            guard let newWindow else {
                return
            }

            if window === newWindow, recognizer != nil {
                return
            }

            remove()

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapRecognizer.cancelsTouchesInView = false
            tapRecognizer.delaysTouchesBegan = false
            tapRecognizer.delaysTouchesEnded = false
            tapRecognizer.delegate = self
            newWindow.addGestureRecognizer(tapRecognizer)

            window = newWindow
            recognizer = tapRecognizer
        }

        func remove() {
            if let recognizer, let window {
                window.removeGestureRecognizer(recognizer)
            }

            recognizer = nil
            window = nil
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard isActive, recognizer.state == .ended else {
                return
            }

            dismiss()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard isActive else {
                return false
            }

            return !touchIsInsideTextInput(touch)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private func touchIsInsideTextInput(_ touch: UITouch) -> Bool {
            var view = touch.view

            while let currentView = view {
                if currentView is UITextField || currentView is UITextView || currentView is UISearchTextField {
                    return true
                }

                view = currentView.superview
            }

            return false
        }
    }
}

private enum EventDeviceCornerRadius {
    static func radius(for proxy: GeometryProxy, scale: CGFloat) -> CGFloat {
        let safeTop = max(proxy.safeAreaInsets.top, keyWindowSafeTop())
        return radius(safeTop: safeTop, shortestSide: min(proxy.size.width, proxy.size.height), scale: scale)
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

private enum EventHeroImageSource {
    case asset(String)
    case image(UIImage)
}

private struct EventDetailHero: View {
    let imageSource: EventHeroImageSource
    let background: Color
    let scale: CGFloat

    init(imageName: String, background: Color, scale: CGFloat) {
        self.imageSource = .asset(imageName)
        self.background = background
        self.scale = scale
    }

    init(image: UIImage, background: Color, scale: CGFloat) {
        self.imageSource = .image(image)
        self.background = background
        self.scale = scale
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                heroLayer(proxy: proxy)

                heroLayer(proxy: proxy)
                    .blur(radius: 3.0 * scale)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: .clear, location: 0.42),
                                .init(color: .black.opacity(0.20), location: 0.55),
                                .init(color: .black.opacity(0.72), location: 0.72),
                                .init(color: .black, location: 0.92),
                                .init(color: .black, location: 1.00)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                heroLayer(proxy: proxy)
                    .blur(radius: 8.0 * scale)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: .clear, location: 0.58),
                                .init(color: .black.opacity(0.16), location: 0.68),
                                .init(color: .black.opacity(0.74), location: 0.84),
                                .init(color: .black, location: 1.00)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                Color(red: 0.78, green: 0.76, blue: 0.80)
                    .opacity(0.18)

                VStack {
                    Spacer(minLength: 0)

                    LinearGradient(
                        stops: [
                            .init(color: background.opacity(0), location: 0),
                            .init(color: background.opacity(0.18), location: 0.20),
                            .init(color: background.opacity(0.66), location: 0.54),
                            .init(color: background, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 176 * scale)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .clipped()
        }
    }

    private func heroLayer(proxy: GeometryProxy) -> some View {
        Group {
            switch imageSource {
            case .asset(let imageName):
                Image(imageName)
                    .resizable()
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
            }
        }
        .scaledToFill()
        .frame(width: proxy.size.width, height: proxy.size.height)
        .clipped()
    }
}

private struct EventCircleControl: View {
    let systemImage: String
    let label: String
    let scale: CGFloat
    let action: () -> Void

    private var usesLightGlass: Bool {
        systemImage == "chevron.left" || systemImage == "pencil"
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize * scale, weight: .medium))
                .foregroundStyle(usesLightGlass ? Color(red: 0.11, green: 0.14, blue: 0.20) : .white)
                .offset(x: systemImage == "chevron.left" ? -1 * scale : 0)
                .frame(width: (usesLightGlass ? 44 : 34) * scale, height: (usesLightGlass ? 44 : 34) * scale)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .eventCircleControlGlass(isLight: usesLightGlass, scale: scale)
        .accessibilityLabel(label)
    }

    private var iconSize: CGFloat {
        switch systemImage {
        case "chevron.left":
            20
        case "pencil":
            18
        default:
            16
        }
    }
}

private extension View {
    @ViewBuilder
    func eventCircleControlGlass(isLight: Bool, scale: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            if isLight {
                self
                    .background(.white.opacity(0.18), in: Circle())
                    .glassEffect(.regular.tint(.white.opacity(0.42)).interactive(), in: Circle())
                    .shadow(color: .white.opacity(0.72), radius: 1.5 * scale, x: -0.5 * scale, y: -0.5 * scale)
                    .shadow(color: .black.opacity(0.055), radius: 7 * scale, x: 0, y: 2 * scale)
            } else {
                self
                    .background(Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.20), in: Circle())
                    .glassEffect(.regular.tint(Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.38)).interactive(), in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 6 * scale, x: 0, y: 2 * scale)
            }
        } else {
            if isLight {
                self
                    .background(.white.opacity(0.82), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.86), lineWidth: max(1, 1.2 * scale))
                    }
                    .shadow(color: .black.opacity(0.055), radius: 7 * scale, x: 0, y: 2 * scale)
            } else {
                self
                    .background(Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.46), in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 6 * scale, x: 0, y: 2 * scale)
            }
        }
    }
}

private struct EventSectionPicker: View {
    @Binding var selectedSection: EventDetailSection
    let scale: CGFloat

    var body: some View {
        Picker("", selection: $selectedSection) {
            ForEach(EventDetailSection.allCases, id: \.self) { section in
                Text(section.title)
                    .tag(section)
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
        .onChange(of: selectedSection) { _, _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

private struct EventSectionContent: View {
    let selectedSection: EventDetailSection
    @Binding var todoItems: [EventTodoItem]
    let scale: CGFloat
    let ink: Color
    let mutedInk: Color
    let background: Color
    let keyboardOverlap: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            EventWardrobeSection(
                items: [
                    EventWardrobeItem(imageName: "CL1", badge: .sparkles),
                    EventWardrobeItem(imageName: "CL2", badge: .hanger)
                ],
                includesAddTile: true,
                scale: scale
            )
            .frame(width: EventWardrobeSection.gridWidth(scale: scale), alignment: .top)
            .opacity(selectedSection == .wardrobe ? 1 : 0)
            .allowsHitTesting(selectedSection == .wardrobe)

            EventWardrobeSection(
                items: [
                    EventWardrobeItem(imageName: "CL1", badge: .plus),
                    EventWardrobeItem(imageName: "CL2", badge: .plus),
                    EventWardrobeItem(imageName: "CL3", badge: .plus),
                    EventWardrobeItem(imageName: "CL4", badge: .plus)
                ],
                includesAddTile: false,
                scale: scale
            )
            .frame(width: EventWardrobeSection.gridWidth(scale: scale), alignment: .top)
            .overlay(alignment: .bottom) {
                EventAISearchBar(scale: scale, ink: ink, mutedInk: mutedInk)
                    .frame(width: 330 * scale)
                    .offset(y: 70 * scale - searchKeyboardLift)
                    .opacity(selectedSection == .lunera ? 1 : 0)
            }
            .opacity(selectedSection == .lunera ? 1 : 0)
            .allowsHitTesting(selectedSection == .lunera)

            EventTodoSection(
                items: $todoItems,
                scale: scale,
                ink: ink,
                mutedInk: mutedInk
            )
            .opacity(selectedSection == .todo ? 1 : 0)
            .allowsHitTesting(selectedSection == .todo)
        }
        .animation(.easeInOut(duration: 0.18), value: selectedSection)
    }

    private var searchKeyboardLift: CGFloat {
        guard selectedSection == .lunera else { return 0 }
        return max(0, keyboardOverlap - 10 * scale)
    }
}

private struct EventWardrobeItem: Identifiable, Hashable {
    enum Badge: Hashable {
        case sparkles
        case hanger
        case plus
    }

    let imageName: String
    let badge: Badge

    var id: String {
        "\(imageName)-\(badge.identitySuffix)"
    }
}

private extension EventWardrobeItem.Badge {
    var identitySuffix: String {
        switch self {
        case .sparkles:
            "sparkles"
        case .hanger:
            "hanger"
        case .plus:
            "plus"
        }
    }
}

private struct EventWardrobeSection: View {
    let items: [EventWardrobeItem]
    let includesAddTile: Bool
    let scale: CGFloat

    static func gridWidth(scale: CGFloat) -> CGFloat {
        (148 * 2 + 6) * scale
    }

    var body: some View {
        let cardSpacing = 6 * scale
        let cardWidth = 148 * scale
        let cardHeight = 194 * scale

        VStack(spacing: cardSpacing) {
            ForEach(tileRows, id: \.self) { row in
                HStack(spacing: cardSpacing) {
                    ForEach(row, id: \.self) { tile in
                        switch tile {
                        case .item(let item):
                            EventWardrobeCard(item: item, scale: scale)
                                .frame(width: cardWidth, height: cardHeight)
                        case .add:
                            EventAddWardrobeCard(scale: scale)
                                .frame(width: cardWidth, height: cardHeight)
                        case .empty:
                            Color.clear
                                .frame(width: cardWidth, height: cardHeight)
                        }
                    }
                }
            }
        }
        .frame(width: Self.gridWidth(scale: scale), alignment: .top)
    }

    private var tileRows: [[Tile]] {
        let tiles = items.map(Tile.item) + (includesAddTile ? [.add] : [])
        let paddedTiles = tiles.count.isMultiple(of: 2) ? tiles : tiles + [.empty]
        return stride(from: 0, to: paddedTiles.count, by: 2).map { index in
            Array(paddedTiles[index..<min(index + 2, paddedTiles.count)])
        }
    }

    private enum Tile: Hashable {
        case item(EventWardrobeItem)
        case add
        case empty
    }
}

private struct EventWardrobeCard: View {
    let item: EventWardrobeItem
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            EventWardrobeBadge(badge: item.badge, scale: scale)
                .padding(.leading, 8 * scale)
                .padding(.bottom, 8 * scale)
        }
        .background {
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .fill(Color(red: 0.988, green: 0.988, blue: 0.985))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14 * scale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .stroke(Color(red: 0.895, green: 0.895, blue: 0.91), lineWidth: 2 * scale)
        }
    }
}

private struct EventWardrobeBadge: View {
    let badge: EventWardrobeItem.Badge
    let scale: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.11, green: 0.14, blue: 0.20))

            switch badge {
            case .sparkles:
                Image(systemName: "sparkles")
                    .font(.system(size: 15 * scale, weight: .regular))
                    .foregroundStyle(.white)
            case .hanger:
                Image(systemName: "hanger")
                    .font(.system(size: 13.5 * scale, weight: .regular))
                    .foregroundStyle(.white)
            case .plus:
                Image(systemName: "plus")
                    .font(.system(size: 19 * scale, weight: .regular))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 26 * scale, height: 26 * scale)
    }
}

private struct EventAddWardrobeCard: View {
    let scale: CGFloat

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                    .fill(Color(red: 0.88, green: 0.885, blue: 0.895))

                Circle()
                    .fill(Color(red: 0.66, green: 0.67, blue: 0.70))
                    .frame(width: 26 * scale, height: 26 * scale)

                Image(systemName: "plus")
                    .font(.system(size: 24 * scale, weight: .light))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add wardrobe item")
    }
}

private struct EventAISearchBar: View {
    let scale: CGFloat
    let ink: Color
    let mutedInk: Color

    @State private var query = ""

    var body: some View {
        HStack(spacing: 12 * scale) {
            TextField(
                "",
                text: $query,
                prompt: Text("What are you looking for?")
                    .foregroundStyle(mutedInk)
                    .font(.system(size: 16 * scale, weight: .regular))
            )
            .font(.system(size: 16 * scale, weight: .regular))
            .foregroundStyle(ink)
            .tint(ink)
            .submitLabel(.search)
            .textInputAutocapitalization(.sentences)
            .lineLimit(1)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                query = ""
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 19 * scale, weight: .regular))
                    .foregroundStyle(ink)
                    .frame(width: 30 * scale, height: 30 * scale)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 20 * scale)
        .padding(.trailing, 13 * scale)
        .frame(height: 48 * scale)
        .eventAISearchInputGlass(scale: scale)
    }
}

private extension View {
    @ViewBuilder
    func eventAISearchInputGlass(scale: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(.white.opacity(0.035), in: Capsule())
                .glassEffect(.regular.interactive(), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.36), lineWidth: max(1, 0.8 * scale))
                }
                .shadow(color: .white.opacity(0.22), radius: 1.0 * scale, x: -0.5 * scale, y: -0.5 * scale)
                .shadow(color: .black.opacity(0.024), radius: 9 * scale, x: 0, y: 4 * scale)
        } else {
            self
                .background(.white.opacity(0.24), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.42), lineWidth: max(1, 0.8 * scale))
                }
                .shadow(color: .black.opacity(0.024), radius: 9 * scale, x: 0, y: 4 * scale)
        }
    }
}

private struct EventTodoItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    var isDone = false
}

private struct EventTodoSection: View {
    @Binding var items: [EventTodoItem]
    let scale: CGFloat
    let ink: Color
    let mutedInk: Color

    var body: some View {
        VStack(spacing: 0) {
            ForEach($items) { $item in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                        item.isDone.toggle()
                    }
                } label: {
                    EventTodoRow(title: item.title, isDone: item.isDone, scale: scale, ink: ink, mutedInk: mutedInk)
                }
                .buttonStyle(.plain)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                EventTodoRow(title: "Add", isDone: false, scale: scale, ink: mutedInk, mutedInk: mutedInk)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 25 * scale)
        .padding(.vertical, 20 * scale)
        .background {
            RoundedRectangle(cornerRadius: 33 * scale, style: .continuous)
                .fill(.white.opacity(0.70))
                .shadow(color: .black.opacity(0.035), radius: 18 * scale, x: 0, y: 9 * scale)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 33 * scale, style: .continuous)
                .stroke(.white.opacity(0.86), lineWidth: 1 * scale)
        }
    }
}

private struct EventTodoRow: View {
    let title: String
    let isDone: Bool
    let scale: CGFloat
    let ink: Color
    let mutedInk: Color

    var body: some View {
        HStack(spacing: 14 * scale) {
            Text(title)
                .font(.system(size: 17 * scale, weight: .regular))
                .foregroundStyle(ink)
                .strikethrough(isDone, color: mutedInk)
                .lineLimit(1)

            Spacer()

            Circle()
                .stroke(isDone ? mutedInk : Color(red: 0.11, green: 0.14, blue: 0.20), lineWidth: 1.2 * scale)
                .background {
                    Circle()
                        .fill(isDone ? Color(red: 0.11, green: 0.14, blue: 0.20).opacity(0.1) : .clear)
                }
                .frame(width: 18 * scale, height: 18 * scale)
        }
        .frame(height: 30 * scale)
        .contentShape(Rectangle())
    }
}

private struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let scale = min(proxy.size.width / 393, proxy.size.height / 852)
                let promptY = proxy.size.height * 0.505

                ZStack {
                    Color(red: 0.967, green: 0.965, blue: 0.96)
                        .ignoresSafeArea()

                    VStack(spacing: 17 * scale) {
                        Text("✨")
                            .font(.system(size: 43 * scale))
                            .lineLimit(1)
                            .accessibilityHidden(true)

                        Text("Lets find you something to wear")
                            .font(.system(size: 21 * scale, weight: .regular, design: .serif))
                            .italic()
                            .tracking(-1.47 * scale)
                            .foregroundStyle(LuneraTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .frame(width: proxy.size.width - 34 * scale)
                    .position(x: proxy.size.width / 2, y: promptY)
                }
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
        }
        .searchable(text: $searchText, prompt: "Search")
        .statusBarHidden(true)
    }
}
