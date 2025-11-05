//
//  ThemeRepository.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

/// Репозиторий для управления темой приложения
final class ThemeRepository: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTheme: ThemeMode
    
    // MARK: - Private Properties
    private let themeService: ThemeService
    
    // MARK: - Computed Properties
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
    
    // MARK: - Initialization
    init(themeService: ThemeService) {
        self.themeService = themeService
        self.currentTheme = themeService.getCurrentTheme()
    }
    
    // MARK: - Public Methods
    
    /// Установить новую тему
    func setTheme(_ mode: ThemeMode) {
        currentTheme = mode
        themeService.setTheme(mode)
    }
}

