//
//  AppState.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

/// Глобальное состояние приложения
final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var viewState: AppViewState = .splash
    @Published var isShowPaywall: Bool = false
    
    // MARK: - Services
    let deviceInfo = DeviceInfo()
    
    // MARK: - Private Properties
    private let appInteractor = Executor.appInteractor
    private let userDefaultsService = UserDefaultsService.shared
    var isFirstLoad: Bool = true
    
    // MARK: - View States
    enum AppViewState {
        case splash
        case onboarding
        case main
    }
    
    // MARK: - Initialization
    init() {
        let isOnboardingShown = userDefaultsService.load(
            Bool.self,
            forKey: .onboardingCompleted
        ) ?? false
        
        self.isFirstLoad = userDefaultsService.load(
            Bool.self,
            forKey: .isFirstLoad
        ) ?? true
        
        // Всегда начинаем с splash screen
        appCheck()
    }
    
    // MARK: - Public Methods
    
    /// Завершение онбординга
    func onboardingCompleted() {
        userDefaultsService.save(true, forKey: .onboardingCompleted)
        userDefaultsService.save(false, forKey: .isFirstLoad)
        
        withAnimation(.easeIn(duration: 0.3)) {
            viewState = .main
        }
    }
    
    // MARK: - Private Methods
    
    /// Проверка состояния приложения при запуске
    private func appCheck() {
        Task { @MainActor in
            await appInteractor.appCheck()
            
            let isOnboardingShown = userDefaultsService.load(
                Bool.self,
                forKey: .onboardingCompleted
            ) ?? false
            
            self.isFirstLoad = userDefaultsService.load(
                Bool.self,
                forKey: .isFirstLoad
            ) ?? true
            
            withAnimation(.easeIn(duration: 0.3)) {
                self.viewState = isOnboardingShown ? .main : .onboarding
            }
        }
    }
}
