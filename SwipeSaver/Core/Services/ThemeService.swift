//
//  ThemeService.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

/// Режимы темы приложения
enum ThemeMode: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

/// Сервис управления темой приложения
final class ThemeService {
    
    // MARK: - Private Properties
    private let userDefaultsService = UserDefaultsService.shared
    private let themeKey: UserDefaultsKeys = .themeMode
    
    // MARK: - Public Methods
    
    /// Получить текущий режим темы
    func getCurrentTheme() -> ThemeMode {
        return userDefaultsService.load(ThemeMode.self, forKey: themeKey) ?? .system
    }
    
    /// Установить новый режим темы
    func setTheme(_ mode: ThemeMode) {
        userDefaultsService.save(mode, forKey: themeKey)
    }
}
