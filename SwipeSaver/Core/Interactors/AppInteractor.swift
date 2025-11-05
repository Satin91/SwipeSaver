//
//  AppInteractor.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/// Главный интерактор приложения
/// Отвечает за бизнес-логику уровня приложения
final class AppInteractor: ObservableObject {
    // MARK: - Dependencies
    private let userDefaultsService = UserDefaultsService.shared
    private let themeRepository: ThemeRepository
    
    // MARK: - Published Properties
    @Published public var appSettings: AppSettings
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(themeRepository: ThemeRepository, appSettings: AppSettings) {
        self.appSettings = appSettings
        self.themeRepository = themeRepository
        // Автоматически сохраняем настройки при изменении
        setupSettingsAutoSave()
    }
    
    // MARK: - Public Methods
    
    /// Проверка при запуске приложения
    @MainActor
    public func appCheck() async {
        print("🔄 App check started...")
    }
    
    // MARK: - Private Methods
    /// Автосохранение настроек при изменении
    private func setupSettingsAutoSave() {
        $appSettings
            .dropFirst() // Пропускаем начальное значение из init
            .sink { [weak self] newSettings in
                guard let self = self else { return }
                self.userDefaultsService.save(newSettings, forKey: .appSettings)
                print("✅ Settings saved")
            }
            .store(in: &cancellables)
    }
}
