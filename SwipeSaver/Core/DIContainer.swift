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
    let userDefaultsService: UserDefaultsService = .shared
    let browserFavoriteService: BrowserFavoriteService
    let videoSaverService: VideoSaverService
    let fileManagerService: FileManagerService
    let userDefaultsObserver: UserDefaultsObserver
    // MARK: - Repositories
    let videoSaverRepository: VideoSaverRepository
    let fileManagerRepository: FileManagerRepository
    let webViewRepository: WebViewRepository
    let browserTabsRepository: BrowserTabsRepository
    
    // MARK: - Interactors
    let appInteractor: AppInteractor
    let videoSaverInteractor: VideoSaverInteractor
    let webViewInteractor: WebViewInteractor
    
    // MARK: - Initialization
    init() {
        let appSettings = userDefaultsService.load(
            AppSettings.self,
            forKey: .appSettings
        ) ?? .default
        // Инициализация сервисов
        self.videoSaverService = VideoSaverService.shared
        self.fileManagerService = FileManagerService.shared
        self.browserFavoriteService = .init(userDefaultsService: userDefaultsService)
        userDefaultsObserver = UserDefaultsObserver(appSettings: appSettings)
        // Загрузка настроек
        
        // Инициализация репозиториев
        self.videoSaverRepository = VideoSaverRepository(videoSaverService: videoSaverService)
        self.fileManagerRepository = FileManagerRepository(fileManagerService: fileManagerService, directoryName: "SavedVideos")
        self.webViewRepository = WebViewRepository(favoritesService: browserFavoriteService, userDefaultsObserver: userDefaultsObserver)
        self.browserTabsRepository = BrowserTabsRepository(userDefaultsService: userDefaultsService)
        
        // Инициализация интеракторов
        self.appInteractor = AppInteractor(appSettings: appSettings)
        self.videoSaverInteractor = VideoSaverInteractor(
            videoSaverRepository: videoSaverRepository,
            fileManagerRepository: fileManagerRepository
        )
        self.webViewInteractor = WebViewInteractor(webViewRepository: webViewRepository, browserTabsRepository: browserTabsRepository)
    }
}
