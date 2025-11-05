//
//  AsyncImageLoader.swift
//  UntraX
//
//  Created by Артур Кулик on 27.10.2025.
//

import SwiftUI

/// Типы изображений для загрузки
enum ImageLoadType {
    case favicon           // Маленькая иконка сайта
    case ogImage           // Open Graph изображение (высокое качество)
    case auto              // Автоматический выбор (приоритет: OG > favicon)
}

/// Загрузчик изображений с поддержкой кэширования и асинхронной загрузки
@MainActor
final class AsyncImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    
    private var loadingTask: Task<Void, Never>?
    private var currentURL: URL?
    private var currentOGImageURL: String?
    private var currentFaviconURL: String?
    private var loadType: ImageLoadType = .auto
    
    /// Загружает изображение по URL с использованием кэша
    /// - Parameters:
    ///   - url: URL сайта для загрузки favicon
    ///   - faviconURL: URL favicon из метатегов (опционально)
    ///   - ogImageURL: URL Open Graph изображения (опционально)
    ///   - type: Тип загружаемого изображения
    func load(
        from url: URL,
        faviconURL: String? = nil,
        ogImageURL: String? = nil,
        type: ImageLoadType = .auto
    ) {
        // Если параметры не изменились, не перезагружаем
        guard currentURL != url || 
              currentFaviconURL != faviconURL || 
              currentOGImageURL != ogImageURL ||
              loadType != type else { 
            return 
        }
        
        currentURL = url
        currentFaviconURL = faviconURL
        currentOGImageURL = ogImageURL
        loadType = type
        
        // Отменяем предыдущую загрузку
        cancel()
        
        // Создаём новую задачу
        loadingTask = Task {
            // Проверяем отмену перед началом работы
            guard !Task.isCancelled else { return }
            
            // В зависимости от типа загружаем разные изображения
            switch type {
            case .favicon:
                await loadFavicon(url: url, faviconURL: faviconURL)
                
            case .ogImage:
                if let ogURL = ogImageURL {
                    await loadOGImage(ogImageURL: ogURL, fallbackURL: url)
                } else {
                    // Fallback на favicon если OG изображения нет
                    await loadFavicon(url: url, faviconURL: faviconURL)
                }
                
            case .auto:
                // Пробуем загрузить OG изображение, если есть
                if let ogURL = ogImageURL {
                    await loadOGImage(ogImageURL: ogURL, fallbackURL: url)
                } else {
                    // Иначе загружаем favicon
                    await loadFavicon(url: url, faviconURL: faviconURL)
                }
            }
        }
    }
    
    /// Загружает favicon
    private func loadFavicon(url: URL, faviconURL: String?) async {
        guard !Task.isCancelled else { return }
        
        // Проверяем кэш
        if let cachedImage = await FaviconService.shared.getCachedFavicon(for: url) {
            guard !Task.isCancelled else { return }
            image = cachedImage
            return
        }
        
        // Если иконки нет в кэше - показываем лоадер
        guard !Task.isCancelled else { return }
        withAnimation(.easeIn(duration: 0.2)) {
            isLoading = true
        }
        
        // Загружаем favicon с передачей метаданных
        if let loadedImage = await FaviconService.shared.getFavicon(
            for: url,
            providedFaviconURL: faviconURL
        ) {
            guard !Task.isCancelled else { return }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                image = loadedImage
                isLoading = false
            }
        } else {
            guard !Task.isCancelled else { return }
            withAnimation {
                isLoading = false
            }
        }
    }
    
    /// Загружает Open Graph изображение
    private func loadOGImage(ogImageURL: String, fallbackURL: URL) async {
        guard !Task.isCancelled else { return }
        
        // Проверяем кэш
        if let cachedImage = await FaviconService.shared.getCachedOGImage(for: ogImageURL) {
            guard !Task.isCancelled else { return }
            image = cachedImage
            return
        }
        
        // Показываем лоадер
        guard !Task.isCancelled else { return }
        withAnimation(.easeIn(duration: 0.2)) {
            isLoading = true
        }
        
        // Загружаем OG изображение
        if let loadedImage = await FaviconService.shared.getOGImage(
            ogImageURL: ogImageURL,
            fallbackURL: fallbackURL
        ) {
            guard !Task.isCancelled else { return }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                image = loadedImage
                isLoading = false
            }
        } else {
            guard !Task.isCancelled else { return }
            
            // Если OG изображение не удалось загрузить, пробуем favicon как fallback
            await loadFavicon(url: fallbackURL, faviconURL: currentFaviconURL)
        }
    }
    
    /// Отменяет текущую загрузку
    func cancel() {
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    /// Сбрасывает состояние загрузчика
    func reset() {
        cancel()
        image = nil
        isLoading = false
        currentURL = nil
        currentOGImageURL = nil
        currentFaviconURL = nil
    }
}

