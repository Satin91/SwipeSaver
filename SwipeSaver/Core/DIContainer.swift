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
    let videoSaverService: VideoSaverService
    let fileManagerService: FileManagerService
    let userDefaultsObserver: UserDefaultsObserver
    let networkService: NetworkService
    let videoWatermarkService: VideoWatermarkService
    // MARK: - Repositories
    let videoSaverRepository: VideoSaverRepository
    let fileManagerRepository: FileManagerRepository
    let networkRepository: NetworkRepository
    
    // MARK: - Interactors
    let appInteractor: AppInteractor
    let videoSaverInteractor: VideoSaverInteractor
    
    // MARK: - Initialization
    init() {
        let appSettings = userDefaultsService.load(
            AppSettings.self,
            forKey: .appSettings
        ) ?? .default
        // Инициализация сервисов
        self.videoSaverService = VideoSaverService.shared
        self.fileManagerService = FileManagerService.shared
        self.networkService = NetworkService.shared
        self.videoWatermarkService = VideoWatermarkService()
        userDefaultsObserver = UserDefaultsObserver(appSettings: appSettings)
        // Загрузка настроек
        
        // Инициализация репозиториев
        self.videoSaverRepository = VideoSaverRepository(videoSaverService: videoSaverService)
        self.fileManagerRepository = FileManagerRepository(
            fileManagerService: fileManagerService,
            videoWatermarkService: videoWatermarkService,
            directoryName: "SavedVideos"
        )
        self.networkRepository = NetworkRepository(networkService: networkService)
        
        // Инициализация интеракторов
        self.appInteractor = AppInteractor(appSettings: appSettings)
        self.videoSaverInteractor = VideoSaverInteractor(
            videoSaverRepository: videoSaverRepository,
            fileManagerRepository: fileManagerRepository,
            networkRepository: networkRepository,
            userDefaultsObserver: userDefaultsObserver
        )
    }
}
