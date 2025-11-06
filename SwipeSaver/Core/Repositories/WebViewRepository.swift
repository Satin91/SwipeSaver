//
//  WebViewRepository.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 26.10.2025.
//

import Foundation

final class WebViewRepository: ObservableObject {
    let favoritesService: BrowserFavoriteService
    let userDefaultsObserver: UserDefaultsObserver
    private let defaultGroup = FavoriteGroup(
        name: "Main",
        colorHex: "#0A84FF",
        favorites: []
    )
    
    init(favoritesService: BrowserFavoriteService, userDefaultsObserver: UserDefaultsObserver) {
        self.favoritesService = favoritesService
        self.userDefaultsObserver = userDefaultsObserver
    }
    
    // MARK: - Favorite Groups Methods
    
    /// Получает все группы избранного
    var favoriteGroups: [FavoriteGroup] {
        return userDefaultsObserver.favoriteGroups
    }
    
    /// Создает новую группу избранного
    func createFavoriteGroup(name: String, colorHex: String) {
        var groups = favoriteGroups
        let newGroup = FavoriteGroup(
            name: name,
            colorHex: colorHex,
            favorites: []
        )
        groups.append(newGroup)
        userDefaultsObserver.updateFavoriteGroups(groups)
    }
    
    /// Удаляет группу избранного
    func deleteFavoriteGroup(_ group: FavoriteGroup) {
        // Не даем удалить основную группу
        guard group.name != defaultGroup.name else { return }
        var groups = favoriteGroups
        groups.removeAll { $0.id == group.id }
        userDefaultsObserver.updateFavoriteGroups(groups)
    }
    
    /// Добавляет страницу в группу избранного
    func addToFavorites(metaData: [String: Any], groupId: UUID? = nil) {
        guard let url = metaData["url"] as? String,
              let title = metaData["title"] as? String else {
            print("❌ [WebViewRepository] Ошибка: отсутствуют обязательные поля")
            return
        }
        
        var groups = favoriteGroups
        
        // Если группа не указана, добавляем в основную
        let targetGroupId = groupId ?? groups[0].id
        
        guard let groupIndex = groups.firstIndex(where: { $0.id == targetGroupId }) else {
            print("❌ [WebViewRepository] Ошибка: группа не найдена")
            return
        }
        
        // Проверяем, нет ли уже такого URL в этой группе
        guard !groups[groupIndex].favorites.contains(where: { $0.url == url }) else {
            print("⚠️ [WebViewRepository] URL уже в избранном этой группы: \(url)")
            return
        }
        
        print("DEBUG: Favorite MetaData \(metaData)")
        
        let favorite = BrowserFavoriteItem(
            url: url,
            title: title,
            description: metaData["description"] as? String,
            siteName: metaData["siteName"] as? String,
            previewImageURL: metaData["previewImageURL"] as? String,
            ogImageURL: metaData["ogImageURL"] as? String,
            faviconURL: metaData["faviconURL"] as? String
        )
        
        groups[groupIndex].favorites.append(favorite)
        userDefaultsObserver.updateFavoriteGroups(groups)
        print("✅ [WebViewRepository] Добавлено в группу '\(groups[groupIndex].name)': \(title)")
    }
    
    /// Удаляет страницу из группы избранного
    func removeFromFavorites(_ item: BrowserFavoriteItem, from group: FavoriteGroup) {
        var groups = favoriteGroups
        guard let groupIndex = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[groupIndex].favorites.removeAll { $0.id == item.id }
        userDefaultsObserver.updateFavoriteGroups(groups)
        print("🗑️ [WebViewRepository] Удалено из группы '\(group.name)': \(item.title)")
    }
    
    /// Проверяет, находится ли URL в избранном
    func isInFavorites(_ url: String) -> Bool {
        return favoriteGroups.contains { group in
            group.favorites.contains { $0.url == url }
        }
    }
    
    /// Обновляет название группы
    func updateGroupName(_ group: FavoriteGroup, newName: String) {
        var groups = favoriteGroups
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].name = newName
        userDefaultsObserver.updateFavoriteGroups(groups)
    }
    
    /// Обновляет цвет группы
    func updateGroupColor(_ group: FavoriteGroup, newColorHex: String) {
        var groups = favoriteGroups
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].colorHex = newColorHex
        userDefaultsObserver.updateFavoriteGroups(groups)
    }
}
