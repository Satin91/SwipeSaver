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
    
    @Published var webViewBlockedStatistics: ResourceAnalysisData = .init()
    @Published private(set) var browserHistory: [BrowserHistoryItem] = []
    @Published private(set) var isLoadingHistory = false
    @Published private(set) var favoriteGroups: [FavoriteGroup] = []
    // App settings
    @Published var appSettings: AppSettings
    
    // Default favorite group
    private let defaultFavoriteGroup = FavoriteGroup(
        name: "Main",
        colorHex: "#0A84FF",
        favorites: []
    )
    
    // Инициализируем из UserDefaults
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        self.webViewBlockedStatistics = userDefaultsService.load(ResourceAnalysisData.self, forKey: .webViewBlockedStatistics) ?? .init()
        self.appSettings = loadAppSettings()
        self.favoriteGroups = loadFavoriteGroups()
        
        // Асинхронно загружаем историю
        Task { @MainActor in
            await loadBrowserHistoryAsync()
        }
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
    
    // MARK: - Browser History Management
    
    /// Добавляет страницу в историю браузера
    func addToBrowserHistory(_ item: BrowserHistoryItem) {
        var history = browserHistory
        
        // Просто добавляем в начало (сохраняем дубликаты для истории посещений)
        history.insert(item, at: 0)
        
        // Ограничиваем размер
        if history.count > 1000 {
            history = Array(history.prefix(1000))
        }
        
        // Обновляем и сохраняем
        browserHistory = history
        userDefaultsService.save(history, forKey: .browserHistory)
    }
    
    /// Удаляет страницу из истории
    func removeFromBrowserHistory(_ item: BrowserHistoryItem) {
        var history = browserHistory
        history.removeAll { $0.id == item.id }
        browserHistory = history
        userDefaultsService.save(history, forKey: .browserHistory)
    }
    
    /// Очищает всю историю
    func clearBrowserHistory() {
        browserHistory = []
        userDefaultsService.save(browserHistory, forKey: .browserHistory)
    }
    
    /// Асинхронно загружает историю браузера
    private func loadBrowserHistoryAsync() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        
        // Загружаем в фоновом потоке
        let history = await Task.detached(priority: .userInitiated) { [userDefaultsService] in
            return userDefaultsService.load([BrowserHistoryItem].self, forKey: .browserHistory) ?? []
        }.value
        
        // Обновляем на главном потоке
        await MainActor.run {
            self.browserHistory = history
        }
    }
    
    /// Создает тестовые данные для истории
    // MARK: - Favorite Groups Management
    
    /// Загружает группы избранного
    private func loadFavoriteGroups() -> [FavoriteGroup] {
        return userDefaultsService.load([FavoriteGroup].self, forKey: .favoriteGroups) ?? [defaultFavoriteGroup]
    }
    
    /// Обновляет состояние групп избранного
    func updateFavoriteGroups(_ groups: [FavoriteGroup]) {
        favoriteGroups = groups
        userDefaultsService.save(groups, forKey: .favoriteGroups)
    }
    
    // MARK: - Test Data Generation
    
    func generateTestHistory() {
        // Сохраняем текущую историю
        let originalHistory = browserHistory
        var testHistory = originalHistory
        
        // Создаем копии с разными датами
        for monthOffset in 1...6 {
            for item in originalHistory {
                var newItem = item
                
                // Создаем новый UUID для уникальности
                newItem = BrowserHistoryItem(
                    title: item.title,
                    url: item.url,
                    visitDate: Calendar.current.date(byAdding: .month, value: -monthOffset, to: item.visitDate) ?? item.visitDate,
                    faviconURL: item.faviconURL
                )
                
                testHistory.append(newItem)
            }
        }
        
        // Добавляем случайные варианты времени для текущего дня
        for hourOffset in 1...12 {
            for item in originalHistory {
                var newItem = item
                
                newItem = BrowserHistoryItem(
                    title: item.title,
                    url: item.url,
                    visitDate: Calendar.current.date(byAdding: .hour, value: -hourOffset, to: Date()) ?? item.visitDate,
                    faviconURL: item.faviconURL
                )
                
                testHistory.append(newItem)
            }
        }
        
        // Сортируем по дате
        testHistory.sort { $0.visitDate > $1.visitDate }
        
        // Сохраняем тестовые данные
        browserHistory = testHistory
        userDefaultsService.save(browserHistory, forKey: .browserHistory)
        
        print("📚 [BrowserHistory] Сгенерировано \(testHistory.count) тестовых записей")
    }
}
