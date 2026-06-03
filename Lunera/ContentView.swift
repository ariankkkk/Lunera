import SwiftUI

struct ContentView: View {
    @State private var isSignedIn = true

    var body: some View {
        Group {
            if isSignedIn {
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                LoginView {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        isSignedIn = true
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}

private struct MainTabView: View {
    @State private var selectedTab: AppTab

    init() {
        let startsInSearch = ProcessInfo.processInfo.arguments.contains("--start-search")
        let startsInEvents = ProcessInfo.processInfo.arguments.contains("--start-events")
            || ProcessInfo.processInfo.environment["LUNERA_START_TAB"] == "events"
        _selectedTab = State(initialValue: startsInSearch ? .search : (startsInEvents ? .events : .browse))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.browse) {
                HomeView()
            } label: {
                Label("Browse", systemImage: "tshirt.fill")
                    .opacity(selectedTab == .browse ? 1 : 0.5)
            }

            Tab(value: AppTab.events) {
                EventsView()
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
        .tint(LuneraTheme.ink)
    }
}

private enum AppTab {
    case browse
    case events
    case search
}

private struct EventsView: View {
    private let logoWidth: CGFloat = 110
    private let logoTopPadding: CGFloat = 8
    private let sidePaddingBase: CGFloat = 22

    private let events = [
        LuneraEvent(title: "Christmas Event", daysLeft: "24 Days left", imageName: "EventChristmas"),
        LuneraEvent(title: "Valentines", daysLeft: "81 Days left", imageName: "EventValentines")
    ]

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 393
            let sidePadding = sidePaddingBase * scale
            let cardHeight = 198 * scale

            ZStack(alignment: .top) {
                Color(red: 0.967, green: 0.965, blue: 0.96)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    LuneraLogo(width: logoWidth * scale)
                        .padding(.top, logoTopPadding * scale)
                        .padding(.bottom, 52 * scale)

                    VStack(spacing: 16 * scale) {
                        ForEach(events) { event in
                            EventCard(event: event, scale: scale)
                                .frame(height: cardHeight)
                        }

                        AddEventRow(scale: scale)
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

private struct LuneraEvent: Identifiable {
    let id = UUID()
    let title: String
    let daysLeft: String
    let imageName: String
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
                    colors: [
                        .black.opacity(0.0),
                        .black.opacity(0.2),
                        .black.opacity(0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width, height: proxy.size.height)

                HStack(alignment: .firstTextBaseline) {
                    Text(event.title)
                        .font(.system(size: 21 * scale, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(.white)

                    Spacer()

                    Text(event.daysLeft)
                        .font(.system(size: 16 * scale, weight: .light))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .padding(.horizontal, 29 * scale)
                .padding(.bottom, 31 * scale)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 25 * scale, style: .continuous))
        }
    }
}

private struct AddEventRow: View {
    let scale: CGFloat

    var body: some View {
        Button {
        } label: {
            HStack(spacing: 10 * scale) {
                Text("Add an event")
                    .font(.system(size: 16 * scale, weight: .regular))
                    .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.61))

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 20 * scale, weight: .regular))
                    .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.61))
            }
            .padding(.horizontal, 14 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 23 * scale, style: .continuous)
                    .fill(Color.white.opacity(0.32))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 23 * scale, style: .continuous)
                    .stroke(
                        Color(red: 0.69, green: 0.70, blue: 0.74),
                        style: StrokeStyle(lineWidth: 0.9 * scale, lineCap: .round, dash: [2.2 * scale, 2.2 * scale])
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let scale = min(proxy.size.width / 393, proxy.size.height / 852)
                let logoY = proxy.size.height * 0.095
                let promptY = proxy.size.height * 0.505

                ZStack {
                    Color(red: 0.967, green: 0.965, blue: 0.96)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        LuneraLogo(width: 111 * scale)
                    }
                    .frame(width: proxy.size.width)
                    .position(x: proxy.size.width / 2, y: logoY)

                    VStack(spacing: 17 * scale) {
                        Text("✨")
                            .font(.system(size: 43 * scale))
                            .lineLimit(1)
                            .accessibilityHidden(true)

                        Text("Lets find you something to wear")
                            .font(.system(size: 21 * scale, weight: .regular, design: .serif))
                            .italic()
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
