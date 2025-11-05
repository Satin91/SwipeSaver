//
//  BrowserTabsRepository.swift
//  UntraX
//
//  Created by Артур Кулик on 29.10.2025.
//

import Foundation
import Combine

/// Репозиторий для управления вкладками браузера
class BrowserTabsRepository: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Список всех вкладок
    @Published private(set) var tabs: [BrowserTab] = []
    
    /// ID активной вкладки
    @Published private(set) var activeTabId: UUID?
    
    // MARK: - Private Properties
    
    private let userDefaultsService: UserDefaultsService
    
    // MARK: - Computed Properties
    
    /// Активная вкладка
    var activeTab: BrowserTab? {
        guard let activeTabId = activeTabId else { return nil }
        return tabs.first { $0.id == activeTabId }
    }
    
    // MARK: - Initialization
    
    init(userDefaultsService: UserDefaultsService = .shared) {
        self.userDefaultsService = userDefaultsService
        loadTabs()
    }
    
    // MARK: - Public Methods
    
    /// Загружает вкладки из UserDefaults
    func loadTabs() {
        tabs = userDefaultsService.load([BrowserTab].self, forKey: .browserTabs) ?? []
        activeTabId = userDefaultsService.load(UUID.self, forKey: .activeTabId)
        
        // Если нет вкладок, создаем первую
        if tabs.isEmpty {
            let newTab = createNewTab()
            setActiveTab(newTab.id)
        }
        
        print("📑 [BrowserTabs] Загружено вкладок: \(tabs.count)")
    }
    
    /// Сохраняет вкладки в UserDefaults
    private func saveTabs() {
        userDefaultsService.save(tabs, forKey: .browserTabs)
        if let activeTabId = activeTabId {
            userDefaultsService.save(activeTabId, forKey: .activeTabId)
        }
        print("📑 [BrowserTabs] Сохранено вкладок: \(tabs.count)")
    }
    
    /// Создает новую вкладку
    /// - Parameters:
    ///   - title: Заголовок вкладки
    ///   - url: Начальный URL
    /// - Returns: Созданная вкладка
    @discardableResult
    func createNewTab(title: String = "New Tab", url: String = "") -> BrowserTab {
        let newTab = BrowserTab(title: title, currentURL: url)
        tabs.append(newTab)
        saveTabs()
        print("📑 [BrowserTabs] Создана новая вкладка: \(newTab.id)")
        return newTab
    }
    
    /// Удаляет вкладку
    /// - Parameter tabId: ID вкладки для удаления
    func deleteTab(_ tabId: UUID) {
        tabs.removeAll { $0.id == tabId }
        
        // Если удалили активную вкладку, устанавливаем активной первую
        if activeTabId == tabId {
            activeTabId = tabs.first?.id
        }
        
        // Если вкладок не осталось, создаем новую
        if tabs.isEmpty {
            let newTab = createNewTab()
            setActiveTab(newTab.id)
        }
        
        saveTabs()
        print("📑 [BrowserTabs] Удалена вкладка: \(tabId)")
    }
    
    /// Устанавливает активную вкладку
    /// - Parameter tabId: ID вкладки
    func setActiveTab(_ tabId: UUID) {
        guard tabs.contains(where: { $0.id == tabId }) else {
            print("⚠️ [BrowserTabs] Вкладка \(tabId) не найдена")
            return
        }
        
        activeTabId = tabId
        saveTabs()
        print("📑 [BrowserTabs] Установлена активная вкладка: \(tabId)")
    }
    
    /// Обновляет данные вкладки при посещении нового URL
    /// - Parameters:
    ///   - tabId: ID вкладки
    ///   - url: Новый URL
    ///   - title: Заголовок страницы
    func updateTabNavigation(tabId: UUID, url: String, title: String?) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else {
            print("⚠️ [BrowserTabs] Вкладка \(tabId) не найдена")
            return
        }
        
        var tab = tabs[index]
        
        // Обновляем заголовок если он есть
        if let title = title, !title.isEmpty {
            tab.title = title
        }
        
        // Добавляем URL в историю
        tab.history.append(url)
        
        // Обновляем текущий URL
        tab.currentURL = url
        
        tabs[index] = tab
        saveTabs()
        
        print("📑 [BrowserTabs] Обновлена вкладка \(tabId): '\(tab.title)' - \(url)")
        print("📑 [BrowserTabs] История вкладки содержит \(tab.history.count) элементов")
    }
    
    /// Получает количество вкладок
    var tabsCount: Int {
        return tabs.count
    }
    
    /// Удаляет все вкладки
    func clearAllTabs() {
        tabs.removeAll()
        activeTabId = nil
        
        // Создаем новую пустую вкладку
        let newTab = createNewTab()
        setActiveTab(newTab.id)
        
        print("📑 [BrowserTabs] Все вкладки удалены")
    }
}

