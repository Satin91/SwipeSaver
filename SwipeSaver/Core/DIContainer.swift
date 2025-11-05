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
    let videoSaverService: VideoSaverService
    let fileManagerService: FileManagerService
    
    // MARK: - Repositories
    let themeRepository: ThemeRepository
    let videoSaverRepository: VideoSaverRepository
    let fileManagerRepository: FileManagerRepository
    
    // MARK: - Interactors
    let appInteractor: AppInteractor
    let videoSaverInteractor: VideoSaverInteractor
    
    // MARK: - Initialization
    init() {
        // Инициализация сервисов
        self.userDefaultsService = UserDefaultsService.shared
        self.themeService = ThemeService()
        self.videoSaverService = VideoSaverService.shared
        self.fileManagerService = FileManagerService.shared
        
        // Загрузка настроек
        let appSettings = userDefaultsService.load(
            AppSettings.self,
            forKey: .appSettings
        ) ?? .default
        
        // Инициализация репозиториев
        self.themeRepository = ThemeRepository(themeService: themeService)
        self.videoSaverRepository = VideoSaverRepository(videoSaverService: videoSaverService)
        self.fileManagerRepository = FileManagerRepository(fileManagerService: fileManagerService, directoryName: "SavedVideos")
        
        // Инициализация интеракторов
        self.appInteractor = AppInteractor(
            themeRepository: themeRepository,
            appSettings: appSettings
        )
        self.videoSaverInteractor = VideoSaverInteractor(
            videoSaverRepository: videoSaverRepository,
            fileManagerRepository: fileManagerRepository
        )
    }
}
