//
//  UserDefaultsService.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Сервис для работы с UserDefaults
/// Поддерживает generic типы и type-safe ключи
class UserDefaultsService {
    
    // MARK: - Singleton
    static let shared = UserDefaultsService()
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Сохраняет объект в UserDefaults
    func save<T: Codable>(_ object: T, forKey key: UserDefaultsKeys) {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key.key)
            print("✅ UserDefaults: Saved '\(key.key)'")
        } catch {
            print("❌ UserDefaults: Error saving '\(key.key)': \(error)")
        }
    }
    
    /// Загружает объект из UserDefaults
    func load<T: Codable>(_ type: T.Type, forKey key: UserDefaultsKeys) -> T? {
        guard let data = userDefaults.data(forKey: key.key) else {
            print("⚠️ UserDefaults: No data for '\(key.key)'")
            return nil
        }
        
        do {
            let object = try JSONDecoder().decode(type, from: data)
            print("✅ UserDefaults: Loaded '\(key.key)'")
            return object
        } catch {
            print("❌ UserDefaults: Error loading '\(key.key)': \(error)")
            return nil
        }
    }
    
    /// Удаляет объект из UserDefaults
    func delete(forKey key: UserDefaultsKeys) {
        userDefaults.removeObject(forKey: key.key)
        print("🗑️ UserDefaults: Deleted '\(key.key)'")
    }
}
