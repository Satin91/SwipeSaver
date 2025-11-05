//
//  DIContainer.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Dependency Injection Container
/// Центральное место для создания и хранения всех зависимостей приложения
class DIContainer {
    // MARK: - Services
    let userDefaultsService: UserDefaultsService
    let themeService: ThemeService
    
    // MARK: - Repositories
    let themeRepository: ThemeRepository
    
    // MARK: - Interactors
    let appInteractor: AppInteractor
    
    // MARK: - Initialization
    init() {
        // Инициализация сервисов
        self.userDefaultsService = UserDefaultsService.shared
        self.themeService = ThemeService()
        
        // Загрузка настроек
        let appSettings = userDefaultsService.load(
            AppSettings.self,
            forKey: .appSettings
        ) ?? .default
        
        // Инициализация репозиториев
        self.themeRepository = ThemeRepository(themeService: themeService)
        
        // Инициализация интеракторов
        self.appInteractor = AppInteractor(
            themeRepository: themeRepository,
            appSettings: appSettings
        )
    }
}
