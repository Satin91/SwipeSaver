//
//  Executor.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Executor - фасад для доступа к зависимостям из DIContainer
/// Используйте этот класс для получения синглтон-экземпляров
class Executor {
    // Приватный контейнер зависимостей
    static private let container = DIContainer()
    
    // MARK: - Public API
    
    /// Доступ к AppInteractor
    static var appInteractor: AppInteractor {
        return container.appInteractor
    }
    
    /// Доступ к VideoSaverInteractor
    static var videoSaverInteractor: VideoSaverInteractor {
        return container.videoSaverInteractor
    }
    
    /// Доступ к FileManagerRepository
    static var fileManagerRepository: FileManagerRepository {
        return container.fileManagerRepository
    }
    
    /// Доступ к UserDefaultsService
    static var userDefaultsService: UserDefaultsService {
        return container.userDefaultsService
    }
    
    static var userDefaultsObserver: UserDefaultsObserver {
        return container.userDefaultsObserver
    }
}
