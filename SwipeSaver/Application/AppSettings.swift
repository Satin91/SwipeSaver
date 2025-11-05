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
    var isDarkMode: Bool = false
    var notificationsEnabled: Bool = true
    var language: String = "en"
    
    // MARK: - Default
    static let `default` = AppSettings()
}

