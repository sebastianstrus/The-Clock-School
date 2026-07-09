//
//  SettingsView.swift
//  The Clock School
//
//  Created by Sebastian Strus on 2/21/26.
//


import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var store: StoreManager
    @Environment(\.colorScheme) var colorScheme

    @State private var showProgressAlert = false
    @State private var showResetProgressConfirm = false
    @State private var showCacheAlert = false
    @State private var showingLanguageHelp = false
    @State private var showOnboarding: Bool = false
    @State private var showPaywall = false
    @State private var showRestoreAlert = false

    private var dark: Bool { settings.isDarkMode }

    // Palette (matches TaskCategoryGridView / PaywallView)
    private let goldGlow   = Color(hex: "#FFE9A8")
    private let goldBright = Color(hex: "#F5D06F")
    private let goldMain   = Color(hex: "#D4A64A")
    private let goldDeep   = Color(hex: "#8F6B1A")

    var learningSectionHeader: some View {
        HStack(spacing: 6) {
            Text("Learning Settings".localized)
            Spacer()
        }
    }

    var resetSectionHeader: some View {
        HStack(spacing: 6) {
            Text("Default Settings".localized)
            Spacer()
        }
    }

    var body: some View {
        ZStack {
            premiumBackground.ignoresSafeArea()

            List {
                Section {
                    premiumBanner
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section(header: Text("Intro Screens".localized)) {
                    NavigationLink(destination: LandingView(showOnboarding: $showOnboarding)) {
                        Label("About".localized, systemImage: "info.circle.fill")
                    }
                }

                Section(header: learningSectionHeader) {
                    Toggle(isOn: settings.$is24HourClock) {
                        Label("24h format".localized, systemImage: "clock.fill")
                    }
                    .tint(goldMain)
                }

                Section(header: Text("Appearance".localized)) {
                    HStack {
                        Label("Theme".localized, systemImage: "paintbrush.fill")
                        Spacer()
                        Picker("Theme".localized, selection: Binding(
                            get: { settings.isDarkMode ? 1 : 0 },
                            set: { settings.isDarkMode = $0 == 1 }
                        )) {
                            Text("Light".localized).tag(0)
                            Text("Dark".localized).tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                }

                Section(header: Text("Language".localized)) {
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Label("App Language".localized, systemImage: "globe")
                            Spacer()
                            Text(settings.primaryLanguage.displayName)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.openAppLanguageSettings()
                        }
                    }
                }

                Section(header: Text("Premium".localized)) {
                    if store.isPremium {
                        HStack {
                            Label("Lifetime Access".localized, systemImage: "crown.fill")
                                .foregroundColor(goldDeep)
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Full Access".localized, systemImage: "lock.open.fill")
                        }
                    }
                    Button {
                        Task {
                            await store.restore()
                            showRestoreAlert = true
                        }
                    } label: {
                        Label("Restore Purchases".localized, systemImage: "arrow.clockwise")
                    }
                }

                Section(header: Text("Progress".localized)) {
                    Button(role: .destructive) {
                        showResetProgressConfirm = true
                    } label: {
                        Label("Reset Progress".localized, systemImage: "arrow.counterclockwise")
                    }
                }

                Section(header: resetSectionHeader) {
                    Button {
                        settings.resetSettings()
                    } label: {
                        Label("Reset Settings".localized, systemImage: "gearshape")
                    }
                }

                Section {
                    Link(destination: URL(string: "https://sebastianstrus.com/documents/the-clock-school/privacy-policy.html")!) {
                        HStack {
                            Label("Privacy Policy".localized, systemImage: "hand.raised.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")!) {
                        HStack {
                            Label("Terms of Service".localized, systemImage: "doc.text.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .tint(goldMain)
        }
        .navigationTitle("Settings".localized)
        .confirmationDialog(
            "Reset all category progress?".localized,
            isPresented: $showResetProgressConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Progress".localized, role: .destructive) {
                settings.resetCategoryProgress()
            }
            Button("Cancel".localized, role: .cancel) { }
        } message: {
            Text("This will clear your progress in all 9 task categories. This action cannot be undone.".localized)
        }
        .alert("Are you sure you want to delete the application cache and close the app?".localized, isPresented: $showCacheAlert) {
            Button("Delete".localized, role: .destructive) {
                settings.clearUserDefaultsAndCloseApp()
            }
            Button("Cancel".localized, role: .cancel) { }
        } message: {
            Text("This action cannot be undone.".localized)
        }
        .alert("Restore Complete".localized, isPresented: $showRestoreAlert) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text(store.isPremium
                 ? "Your purchase has been restored.".localized
                 : "No previous purchases found.".localized)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(settings)
                .environmentObject(store)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(
                    item: URL(string: "https://apps.apple.com/app/6787504939")!,
                    subject: Text("The Clock School".localized),
                    message: Text("Check out The Clock School - a great clock learning app!".localized)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityLabel("Share".localized)
                }
            }
        }
    }

    // MARK: - Premium Banner (top)

    @ViewBuilder
    private var premiumBanner: some View {
        if store.isPremium {
            premiumOwnedBanner
        } else {
            premiumCTA
        }
    }

    private var premiumCTA: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [goldBright, goldMain],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: goldDeep.opacity(0.5), radius: 1, x: 0, y: 1)
                }
                .shadow(color: goldDeep.opacity(0.45), radius: 5, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock Full Access".localized)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(dark ? Color(hex: "#F4EBD0") : Color(hex: "#2A2015"))
                    Text("Lifetime · No Ads".localized)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(dark ? Color.white.opacity(0.7) : Color(hex: "#6B5230"))
                }
                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(goldDeep)
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: dark
                                    ? [Color(hex: "#1B1728"), Color(hex: "#131022")]
                                    : [Color(hex: "#FFFDF6"), Color(hex: "#FBF3DF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [goldGlow.opacity(dark ? 0.15 : 0.35), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                goldGlow.opacity(dark ? 0.85 : 0.75),
                                goldMain.opacity(0.55),
                                goldDeep.opacity(0.60)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: dark ? .black.opacity(0.45) : goldDeep.opacity(0.20), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var premiumOwnedBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(hex: "#16A34A").opacity(0.45), radius: 5, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text("Lifetime Access".localized)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(dark ? Color(hex: "#F4EBD0") : Color(hex: "#2A2015"))
                Text("Thank you for your support!".localized)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(dark ? Color.white.opacity(0.7) : Color(hex: "#6B5230"))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: dark
                            ? [Color(hex: "#1B1728"), Color(hex: "#131022")]
                            : [Color(hex: "#FFFDF6"), Color(hex: "#FBF3DF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            goldGlow.opacity(dark ? 0.85 : 0.75),
                            goldMain.opacity(0.55),
                            goldDeep.opacity(0.60)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: dark ? .black.opacity(0.45) : goldDeep.opacity(0.20), radius: 10, x: 0, y: 5)
    }

    // MARK: - Background

    private var premiumBackground: some View {
        ZStack {
            if dark {
                LinearGradient(
                    colors: [
                        Color(hex: "#0E0918"),
                        Color(hex: "#180F26"),
                        Color(hex: "#0A0510")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [goldMain.opacity(0.20), .clear],
                    center: UnitPoint(x: 0.12, y: 0.08),
                    startRadius: 0,
                    endRadius: 340
                )
                .blendMode(.plusLighter)
                RadialGradient(
                    colors: [goldDeep.opacity(0.26), .clear],
                    center: UnitPoint(x: 0.9, y: 0.92),
                    startRadius: 0,
                    endRadius: 380
                )
                .blendMode(.plusLighter)
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: "#F2E5BE"),
                        Color(hex: "#E6D19B"),
                        Color(hex: "#D6BB78")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [Color(hex: "#FFF3C8").opacity(0.85), .clear],
                    center: UnitPoint(x: 0.18, y: 0.08),
                    startRadius: 0,
                    endRadius: 320
                )
                RadialGradient(
                    colors: [Color(hex: "#C9A96E").opacity(0.35), .clear],
                    center: UnitPoint(x: 0.88, y: 0.95),
                    startRadius: 0,
                    endRadius: 420
                )
            }
        }
    }
}






import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var showingClearConfirmation = false
    
    var body: some View {
        VStack {
            Text("").frame(height: 0)
            List {
                Section(header: sectionHeader(DifficultyLevel.easy.localizedName)) {
                    columnHeaders()
                    resultsSection(for: .easy)
                }

                Section(header: sectionHeader(DifficultyLevel.medium.localizedName)) {
                    columnHeaders()
                    resultsSection(for: .medium)
                }

                Section(header: sectionHeader(DifficultyLevel.hard.localizedName)) {
                    columnHeaders()
                    resultsSection(for: .hard)
                }
                

            }
            .navigationTitle("Statistics".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingClearConfirmation = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear All Statistics?".localized, isPresented: $showingClearConfirmation) {
                Button("Clear".localized, role: .destructive) {
                    settings.clearStatistics()
                }
                Button("Cancel".localized, role: .cancel) {}
            } message: {
                Text("This will permanently delete all saved results.".localized)
            }
        }
    }
    
    private func columnHeaders() -> some View {
        HStack(spacing: 4) {
            Text("Name".localized)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .font(Font.system(size: 13).bold())
                .foregroundColor(.primary)
            
            Text("Count".localized)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .font(Font.system(size: 13).bold())
                .foregroundColor(.primary)
            
            Text("Format".localized)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .font(Font.system(size: 13).bold())
                .foregroundColor(.primary)
            
            Text("Result".localized)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .font(Font.system(size: 13).bold())
                .foregroundColor(.primary)
            
            Text("Date".localized)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .font(Font.system(size: 13).bold())
                .foregroundColor(.primary)
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
    
    private func resultsSection(for difficulty: DifficultyLevel) -> some View {
        let results = settings.loadGameResults()
            .filter { $0.difficulty == difficulty }
            .sorted { $0.time < $1.time }
            .sorted { $0.is24HourClock && !$1.is24HourClock }
            .sorted { $0.exampleCount > $1.exampleCount }
                
        return Group {
            if results.isEmpty {
                Text("No results yet".localized)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .padding(.vertical, 8)
            } else {
                ForEach(results) { result in
                    HStack(spacing: 4) {
                        Text(result.name)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .font(.subheadline)
                        
                        Text("\(result.exampleCount)")
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            .font(.system(size: 13, design: .monospaced))
                        
                        Text(result.is24HourClock ? "24h" : "12h")
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            .font(.system(size: 13, design: .monospaced))
                        
                        Text(result.time.formattedTime)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            .font(.system(size: 15, design: .monospaced))
                        
                        Text(formatDate(result.date))
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

