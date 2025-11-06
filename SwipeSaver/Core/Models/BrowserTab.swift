//
//  BrowserTab.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 29.10.2025.
//

import Foundation

// MARK: - BrowserTab

/// Модель вкладки браузера
struct BrowserTab: Identifiable, Codable, Equatable {
    /// Уникальный идентификатор вкладки
    let id: UUID
    
    /// Заголовок вкладки (title из HTML страницы)
    var title: String
    
    /// История URL для этой вкладки (весь путь навигации)
    var history: [String]
    
    /// Текущий URL (последний в истории)
    var currentURL: String
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        title: String = "New Tab",
        history: [String] = [],
        currentURL: String = ""
    ) {
        self.id = id
        self.title = title
        self.history = history
        self.currentURL = currentURL
    }
}

// MARK: - BrowserTab Extensions

extension BrowserTab {
    
    /// Проверяет, загружена ли страница
    var isLoaded: Bool {
        return !currentURL.isEmpty
    }
    
    /// Получает домен из текущего URL
    var domain: String? {
        guard let url = URL(string: currentURL),
              let host = url.host else {
            return nil
        }
        
        // Убираем "www." если есть
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        
        return host
    }
}

