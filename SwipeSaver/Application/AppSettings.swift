//
//  AppSettings.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Модель настроек приложения
struct AppSettings: Codable {
    // MARK: - Settings
    var startPage = "https://startpage.com"
    var enableBrowserHistory: Bool = false
    var notificationsEnabled: Bool = true
    var language: String = "en"
    
    // MARK: - Watermark Settings
    /// Включить водяной знак на видео (для бесплатной версии)
    var enableWatermark: Bool = true
    
    // MARK: - Premium
    /// Статус Premium подписки (для отключения водяного знака)
    var isPremiumUser: Bool = false
    
    // MARK: - Default
    static let `default` = AppSettings()
}

