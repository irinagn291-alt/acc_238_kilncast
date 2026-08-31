import SwiftUI

/// Role: Presentation. Kiln-first root. Hive and Coldest are this wall, not tabs.
struct KilnRootView: View {
    var session: EmberSession
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(session: EmberSession = .previewPopulated()) {
        self.session = session
    }

    var body: some View {
        Group {
            if session.onboarded {
                KilnView(session: session)
            } else {
                OnboardingView(session: session)
            }
        }
        .preferredColorScheme(.dark)
        .overlay { EmberFlash(visible: session.commitFlash) }
        .task { await session.appear() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                session.noteDayChange()
            }
        }
        .sheet(item: sheetBinding) { sheet in
            switch sheet {
            case .restoke:
                RestokeView(session: session)
            case .settings:
                SettingsSheet(session: session)
            case .addPerson:
                AddPersonView(session: session)
            case .forecast:
                FreezeForecastView(session: session)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : FireclayPalette.motion, value: session.sheet)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : FireclayPalette.motion, value: session.onboarded)
    }

    private var sheetBinding: Binding<KilnSheet?> {
        Binding(
            get: { session.sheet },
            set: { session.sheet = $0 }
        )
    }
}

/// Role: Presentation. Hex kiln wall ranked by 7-day forecast T. Not a last-contact list.
struct KilnView: View {
    var session: EmberSession
    var title: String
    var emphasizesFalling: Bool

    init(session: EmberSession = .previewPopulated(), title: String = "Kiln", emphasizesFalling: Bool = false) {
        self.session = session
        self.title = title
        self.emphasizesFalling = emphasizesFalling
    }

    var body: some View {
        NavigationStack {
            KilnStage(session: session, title: title, emphasizesFalling: emphasizesFalling)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            session.openAddPerson()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(FireclayPalette.ink)
                        }
                        .kilnTap()
                        .accessibilityLabel("Add a person")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            session.openSettings()
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(FireclayPalette.ink)
                        }
                        .kilnTap()
                        .accessibilityLabel("Settings")
                    }
                }
        }
    }
}

/// Role: Presentation. Hive, Coldest, and Kiln share this wall.
struct KilnStage: View {
    var session: EmberSession
    var title: String
    var emphasizesFalling: Bool

    init(
        session: EmberSession = .previewPopulated(),
        title: String = "Kiln",
        emphasizesFalling: Bool = false
    ) {
        self.session = session
        self.title = title
        self.emphasizesFalling = emphasizesFalling
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if let fault = session.fault {
                faultBanner(fault)
            }
            ZStack {
                wall
                if session.graph.bricks.isEmpty, session.fault == nil {
                    EmptyKilnView {
                        session.openAddPerson()
                    }
                }
                if session.busy {
                    FireclayPalette.surface.opacity(0.65)
                    ProgressView()
                        .tint(FireclayPalette.ink)
                }
            }
        }
        .background(FireclayPalette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
            EmberArt(name: EmberArtName.header)
                .frame(maxHeight: FireclayPalette.space(8))
                .clipped()
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .kilnText(.display)
                    .foregroundStyle(FireclayPalette.ink)
                    .lineLimit(1)
                Spacer(minLength: FireclayPalette.space(1))
                Text(EmberFigures.heat(session.graph.falling.first?.forecastT ?? 0))
                    .kilnText(.title)
                    .monospacedDigit()
                    .foregroundStyle(FireclayPalette.accent)
                    .lineLimit(1)
                    .accessibilityLabel("Coldest forecast \(EmberFigures.heat(session.graph.falling.first?.forecastT ?? 0))")
            }
            Button {
                session.openForecast()
            } label: {
                Text("Imminent freeze · \(EmberFigures.count(session.settings.forecastHorizonDays)) days")
                    .kilnText(.caption)
                    .foregroundStyle(FireclayPalette.muted)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: FireclayPalette.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Imminent freeze forecast")
        }
        .padding(.horizontal, FireclayPalette.space(2))
        .padding(.top, FireclayPalette.space(1))
        .padding(.bottom, FireclayPalette.space(2))
    }

    @ViewBuilder
    private var wall: some View {
        let ranked = session.graph.kilnWall
        ScrollView {
            VStack(alignment: .leading, spacing: FireclayPalette.space(2)) {
                if emphasizesFalling || !session.graph.falling.isEmpty {
                    FallingBandView(bricks: session.graph.falling)
                }
                if !session.graph.hot.isEmpty {
                    HotBandView(bricks: session.graph.hot)
                }
                KilnWallHost(bricks: ranked, onSelect: session.openRestoke)
                AshRailView(bricks: session.graph.ash, onSelect: session.openRestoke)
            }
            .padding(.bottom, FireclayPalette.space(2))
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func faultBanner(_ message: String) -> some View {
        HStack(alignment: .center, spacing: FireclayPalette.space(1)) {
            Text(message)
                .kilnText(.caption)
                .foregroundStyle(FireclayPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: FireclayPalette.space(1))
            Button("Retry") {
                Task { await session.retry() }
            }
            .kilnText(.headline)
            .foregroundStyle(FireclayPalette.accent)
            .kilnTap()
        }
        .padding(FireclayPalette.space(2))
        .background(FireclayPalette.surface)
    }
}

/// Role: Presentation. Empty kiln. Headline, one line, one CTA.
struct EmptyKilnView: View {
    var action: () -> Void = {}

    var body: some View {
        KilnEmptyPlate(action: action, fillsPage: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FireclayPalette.background.opacity(0.92))
    }
}
