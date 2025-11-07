//
//  UserDefaultsObserver.swift
//  SufrShield
//
//  Created by Артур Кулик on 06.09.2025.
//

import Foundation
import Combine

class UserDefaultsObserver: ObservableObject {
//    static let shared = UserDefaultsObserver()
    private var cancellables = Set<AnyCancellable>()
    let userDefaultsService = UserDefaultsService.shared
    
    @Published private(set) var isLoadingHistory = false
    @Published var videoFolders: [VideoFolder] = []
    // App settings
    @Published var appSettings: AppSettings
    
    // Инициализируем из UserDefaults
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        self.appSettings = loadAppSettings()
        self.videoFolders = loadVideoFolders()
    }
    
    func updateAppSettings(_ settings: AppSettings) {
        // Просто обновляем настройки в памяти
        // Сохранение в UserDefaults должно происходить в том месте, откуда вызывается этот метод
        self.appSettings = settings
        userDefaultsService.save(settings, forKey: .appSettings)
    }
    
    private func loadAppSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.appSettings.key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    /// Сброс настроек к значениям по умолчанию
    func resetSettingsToDefault() {
        appSettings = .default
    }
    

    // MARK: - Video Folders Management
    
    /// Загружает папки с видео
    private func loadVideoFolders() -> [VideoFolder] {
        let folders = userDefaultsService.load([VideoFolder].self, forKey: .videoFolders) ?? []
        
        // Если папок нет, создаём дефолтные
        if folders.isEmpty {
            let defaultFolders = [
                VideoFolder(name: "Избранное", iconName: "star.fill", color: "FFD700"),
                VideoFolder(name: "Для работы", iconName: "briefcase.fill", color: "4A90E2")
            ]
            updateVideoFolders(defaultFolders)
            return defaultFolders
        }
        
        return folders
    }
    
    /// Обновляет состояние папок и сохраняет в UserDefaults
    func updateVideoFolders(_ folders: [VideoFolder]) {
        videoFolders = folders
        userDefaultsService.save(folders, forKey: .videoFolders)
    }
    
    /// Получить папку, в которой находится видео (вспомогательный метод для чтения)
    func getFolderForVideo(_ videoId: UUID) -> VideoFolder? {
        return videoFolders.first { $0.containsVideo(videoId) }
    }
    
}
