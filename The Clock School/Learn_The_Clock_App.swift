//
//  The_Clock_School_App.swift
//  The Clock School
//
//  Created by Sebastian Strus on 2/19/26.
//

import SwiftUI

@main
struct The_Clock_School_App: App {
    
    @AppStorage("shouldShowOnboarding") private var shouldShowOnboarding = true
    
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var videoViewModel = VideoPlayerViewModel.shared
    @StateObject private var store = StoreManager.shared
    
    
    var body: some Scene {
        WindowGroup {
            
            ZStack {
                WelcomeContentView()
                    .environmentObject(settings)
                    .environmentObject(videoViewModel)
                    .environmentObject(store)
                    .preferredColorScheme(settings.isDarkMode ? .dark : .light)
                    .transition(.opacity)
                
                if shouldShowOnboarding {
                    LandingView(showOnboarding: $shouldShowOnboarding)
                        .transition(.opacity)
                        .zIndex(1)
                }
                
            }
            .task {
                await store.loadProducts()
                await store.refreshEntitlements()
            }

        }
    }
}
