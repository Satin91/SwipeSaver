//
//  MainView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

/// Главный View приложения
struct MainView: View {
    @StateObject private var coordinator = Coordinator()
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    
    private let appInteractor = Executor.appInteractor
    
    var body: some View {
        content
            .environmentObject(appState)
            .environmentObject(coordinator)
            .preferredColorScheme(.dark)
            .fullScreenCover(item: $coordinator.presentedScreen) { screen in
                coordinator.build(screen: screen)
            }
            .onChange(of: scenePhase) { _, _ in
                Task {
                    await appInteractor.appCheck()
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch appState.viewState {
        case .splash:
            SplashScreenView()
        case .onboarding:
            OnboardingView()
        case .main:
            mainContent
        }
    }
    
    private var mainContent: some View {
//        SaverView()
        NavigationStack(path: $coordinator.mainPath) {
            TabBarView()
                .navigationDestination(for: Screen.self) { screen in
                    coordinator.build(screen: screen)
                }
        }
    }
}

#Preview {
    MainView()
}
