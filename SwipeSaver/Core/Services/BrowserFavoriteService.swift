//
//  BrowserFavoriteService.swift
//  UntraX
//
//  Created by Артур Кулик on 26.10.2025.
//

import Foundation

/// Сервис для работы с избранными страницами
class BrowserFavoriteService {
    private var favorites: [BrowserFavoriteItem] = []
    private let userDefaultsService: UserDefaultsService
    
    init(userDefaultsService: UserDefaultsService) {
        self.userDefaultsService = userDefaultsService
        loadFavorites()
    }
    
    /// Загружает избранное из UserDefaults
    private func loadFavorites() {
        favorites = userDefaultsService.load([BrowserFavoriteItem].self, forKey: .favorites) ?? []
    }
    
    /// Сохраняет избранное в UserDefaults
    private func saveFavorites() {
        userDefaultsService.save(favorites, forKey: .favorites)
    }
    
    /// Добавляет страницу в избранное
    func addToFavorites(metaData: [String: Any]) {
        guard let url = metaData["url"] as? String,
              let title = metaData["title"] as? String else {
            print("❌ [FavoriteService] Ошибка: отсутствуют обязательные поля")
            return
        }
        
        // Проверяем, нет ли уже такого URL в избранном
        guard !favorites.contains(where: { $0.url == url }) else {
            print("⚠️ [FavoriteService] URL уже в избранном: \(url)")
            return
        }
        
        let favorite = BrowserFavoriteItem(
            url: url,
            title: title,
            description: metaData["description"] as? String,
            siteName: metaData["siteName"] as? String,
            previewImageURL: metaData["ogImage"] as? String,
            ogImageURL: metaData["ogImageURL"] as? String,
            faviconURL: metaData["faviconURL"] as? String
        )
        
        favorites.append(favorite)
        saveFavorites()
        print("✅ [FavoriteService] Добавлено в избранное: \(title)")
    }
    
    /// Получает все избранные страницы
    func getFavorites() -> [BrowserFavoriteItem] {
        return favorites
    }
    
    /// Удаляет страницу из избранного
    func removeFromFavorites(_ item: BrowserFavoriteItem) {
        favorites.removeAll { $0.id == item.id }
        saveFavorites()
        print("🗑️ [FavoriteService] Удалено из избранного: \(item.title)")
    }
    
    /// Проверяет, находится ли URL в избранном
    func isInFavorites(_ url: String) -> Bool {
        return favorites.contains { $0.url == url }
    }
}
