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
            Text(title)
                .kilnText(.display)
                .foregroundStyle(FireclayPalette.ink)
                .lineLimit(1)
            Button {
                session.openForecast()
            } label: {
                Text(bandSummary)
                    .kilnText(.caption)
                    .foregroundStyle(FireclayPalette.muted)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: FireclayPalette.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Imminent freeze forecast, \(bandSummary)")
        }
        .padding(.horizontal, FireclayPalette.space(2))
        .padding(.top, FireclayPalette.space(1))
        .padding(.bottom, FireclayPalette.space(2))
    }

    private var bandSummary: String {
        "\(EmberFigures.count(session.graph.falling.count)) falling · \(EmberFigures.count(session.graph.hot.count)) holding"
    }

    @ViewBuilder
    private var wall: some View {
        let ranked = session.graph.kilnWall
        ScrollView {
            VStack(alignment: .leading, spacing: FireclayPalette.space(2)) {
                if let hero = session.graph.falling.first {
                    FallingHeroView(
                        brick: hero,
                        horizonDays: session.settings.forecastHorizonDays,
                        onRestoke: { channel in
                            session.openRestoke(personID: hero.person.id, channel: channel)
                        }
                    )
                    .padding(.horizontal, FireclayPalette.space(2))
                } else if emphasizesFalling, !session.graph.bricks.isEmpty {
                    VStack(alignment: .leading, spacing: FireclayPalette.space(1)) {
                        Text("Nothing is falling.")
                            .kilnText(.headline)
                            .foregroundStyle(FireclayPalette.ink)
                        Text("Catch the brick before it hits the floor.")
                            .kilnText(.body)
                            .foregroundStyle(FireclayPalette.muted)
                    }
                    .padding(.horizontal, FireclayPalette.space(2))
                }
                if !ranked.isEmpty {
                    Text("Tap a brick to restoke")
                        .kilnText(.caption)
                        .foregroundStyle(FireclayPalette.muted)
                        .padding(.horizontal, FireclayPalette.space(2))
                    KilnWallHost(bricks: ranked, onSelect: session.openRestoke)
                }
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
