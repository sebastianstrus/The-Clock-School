//
//  PaywallView.swift
//  The Clock School
//
//  Created by Sebastian Strus on 7/5/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var showRestoreAlert = false

    private var dark: Bool { settings.isDarkMode }
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    // Palette (matches TaskCategoryGridView)
    private let goldGlow   = Color(hex: "#FFE9A8")
    private let goldBright = Color(hex: "#F5D06F")
    private let goldMain   = Color(hex: "#D4A64A")
    private let goldDeep   = Color(hex: "#8F6B1A")

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: isPad ? 32 : 24) {
                    Spacer(minLength: isPad ? 32 : 16)

                    medallion

                    VStack(spacing: isPad ? 12 : 8) {
                        Text("Unlock Full Access".localized)
                            .font(.system(size: isPad ? 40 : 28, weight: .bold, design: .serif))
                            .foregroundStyle(titleGradient)
                            .multilineTextAlignment(.center)
                            .tracking(0.5)

                        Text("One-time purchase. Lifetime access.".localized)
                            .font(.system(size: isPad ? 20 : 15, weight: .medium, design: .rounded))
                            .foregroundColor(subtitleColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    featuresCard
                        .padding(.horizontal, isPad ? 40 : 20)

                    purchaseButton
                        .padding(.horizontal, isPad ? 40 : 20)

                    HStack(spacing: 20) {
                        Button {
                            Task {
                                await store.restore()
                                showRestoreAlert = true
                            }
                        } label: {
                            Text("Restore Purchases".localized)
                                .font(.system(size: isPad ? 16 : 14, weight: .medium, design: .rounded))
                                .foregroundColor(linkColor)
                        }
                    }
                    .padding(.top, 4)

                    Text("No subscriptions. No ads.".localized)
                        .font(.system(size: isPad ? 14 : 12, weight: .regular, design: .rounded))
                        .foregroundColor(subtitleColor.opacity(0.75))
                        .padding(.bottom, isPad ? 40 : 24)
                }
                .frame(maxWidth: isPad ? 720 : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: isPad ? 20 : 16, weight: .semibold))
                    .foregroundColor(dark ? .white.opacity(0.85) : .black.opacity(0.7))
                    .padding(isPad ? 14 : 12)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(dark ? 0.10 : 0.55))
                            .overlay(
                                Circle().strokeBorder(goldMain.opacity(0.35), lineWidth: 1)
                            )
                    )
            }
            .padding(.trailing, isPad ? 24 : 16)
            .padding(.top, isPad ? 24 : 16)
        }
        .task {
            await store.loadProducts()
        }
        .alert("Restore Complete".localized, isPresented: $showRestoreAlert) {
            Button("OK".localized, role: .cancel) {
                if store.isPremium { dismiss() }
            }
        } message: {
            Text(store.isPremium
                 ? "Your purchase has been restored.".localized
                 : "No previous purchases found.".localized)
        }
        .alert(
            "Purchase Failed".localized,
            isPresented: Binding(
                get: { store.purchaseError != nil },
                set: { if !$0 { store.purchaseError = nil } }
            )
        ) {
            Button("OK".localized, role: .cancel) { store.purchaseError = nil }
        } message: {
            Text(store.purchaseError ?? "")
        }
        .onChange(of: store.isPremium) { _, newValue in
            if newValue { dismiss() }
        }
        .preferredColorScheme(dark ? .dark : .light)
    }

    // MARK: - Background

    private var background: some View {
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
                    colors: [goldMain.opacity(0.22), .clear],
                    center: UnitPoint(x: 0.12, y: 0.08),
                    startRadius: 0,
                    endRadius: 340
                )
                .blendMode(.plusLighter)
                RadialGradient(
                    colors: [goldDeep.opacity(0.28), .clear],
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

    // MARK: - Medallion

    private var medallion: some View {
        let size: CGFloat = isPad ? 160 : 110
        let iconSize: CGFloat = isPad ? 74 : 52
        return ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [goldBright, goldMain, goldDeep, goldMain, goldBright, goldGlow, goldBright],
                        center: .center
                    )
                )
            Circle()
                .fill(
                    LinearGradient(
                        colors: dark
                            ? [Color(hex: "#1A1626"), Color(hex: "#0C0A18")]
                            : [Color(hex: "#2A2436"), Color(hex: "#150F20")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(isPad ? 5 : 3.5)
            Image(systemName: "crown.fill")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [goldGlow, goldMain],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: goldDeep.opacity(0.55), radius: 2, x: 0, y: 2)
        }
        .frame(width: size, height: size)
        .shadow(color: goldDeep.opacity(dark ? 0.7 : 0.35), radius: isPad ? 12 : 8, x: 0, y: 5)
    }

    // MARK: - Features Card

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: isPad ? 18 : 14) {
            featureRow(
                icon: "lock.open.fill",
                title: "Unlock Medium & Hard".localized,
                subtitle: "Access all 6 premium task cards".localized
            )
            featureRow(
                icon: "infinity",
                title: "Lifetime Access".localized,
                subtitle: "One-time purchase, keep forever".localized
            )
            featureRow(
                icon: "nosign",
                title: "No Ads".localized,
                subtitle: "Enjoy a distraction-free experience".localized
            )
            featureRow(
                icon: "sparkles",
                title: "Support Development".localized,
                subtitle: "Help build more learning features".localized
            )
        }
        .padding(isPad ? 26 : 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
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
            RoundedRectangle(cornerRadius: 20, style: .continuous)
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
        .shadow(color: dark ? .black.opacity(0.55) : goldDeep.opacity(0.20), radius: 14, x: 0, y: 6)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: isPad ? 18 : 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [goldBright, goldMain],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: isPad ? 44 : 36, height: isPad ? 44 : 36)
                Image(systemName: icon)
                    .font(.system(size: isPad ? 20 : 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: goldDeep.opacity(0.35), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: isPad ? 19 : 15, weight: .semibold, design: .rounded))
                    .foregroundColor(textPrimary)
                Text(subtitle)
                    .font(.system(size: isPad ? 15 : 12, weight: .regular, design: .rounded))
                    .foregroundColor(textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task { await store.purchase() }
        } label: {
            HStack(spacing: 10) {
                if store.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Unlock for".localized)
                        .font(.system(size: isPad ? 20 : 17, weight: .semibold, design: .rounded))
                    Text(priceText)
                        .font(.system(size: isPad ? 22 : 18, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: isPad ? 64 : 56)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [goldDeep, goldMain, goldBright, goldMain, goldDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(goldGlow.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: goldMain.opacity(0.6), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressableScaleStyle())
        .disabled(store.isPurchasing)
    }

    private var priceText: String {
        store.premiumProduct?.displayPrice ?? "$6.99"
    }

    // MARK: - Colors

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: dark
                ? [goldBright, goldMain]
                : [Color(hex: "#3A2A10"), Color(hex: "#5C4218")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var subtitleColor: Color {
        dark ? Color.white.opacity(0.75) : Color(hex: "#4A3820")
    }

    private var textPrimary: Color {
        dark ? Color(hex: "#F4EBD0") : Color(hex: "#2A2015")
    }

    private var textSecondary: Color {
        dark ? Color.white.opacity(0.65) : Color(hex: "#6B5230")
    }

    private var linkColor: Color {
        dark ? goldBright : goldDeep
    }
}

private struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
