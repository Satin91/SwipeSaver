//
//  FaviconService.swift
//  UntraX
//
//  Created by Артур Кулик on 25.10.2025.
//

import Foundation
import UIKit

/// Типы логотипов/иконок
enum LogoType {
    case favicon        // Маленькая иконка (16x16, 32x32)
    case ogImage        // Open Graph изображение (высокое качество)
    case appleTouchIcon // Apple Touch Icon (180x180)
}

/// Сервис для загрузки и кэширования favicon сайтов
actor FaviconService {
    static let shared = FaviconService()
    
    /// JavaScript для получения мета-данных страницы
    static var metaDataScript: String {
        """
        (function() {
            var meta = {
                url: window.location.href,
                title: document.title,
                ogImageURL: document.querySelector('meta[property="og:image"]')?.content ||
                           document.querySelector('meta[property="og:image:url"]')?.content ||
                           document.querySelector('meta[name="twitter:image"]')?.content,
                description: document.querySelector('meta[property="og:description"]')?.content ||
                            document.querySelector('meta[name="description"]')?.content,
                siteName: document.querySelector('meta[property="og:site_name"]')?.content,
                faviconURL: document.querySelector('link[rel*="icon"]')?.href ||
                           document.querySelector('link[rel="shortcut icon"]')?.href ||
                           document.querySelector('link[rel="apple-touch-icon"]')?.href
            };
            return meta;
        })();
        """
    }
    
    // MARK: - Properties
    
    /// Кэш загруженных иконок (ключ: domain или full URL для og:image)
    private var faviconCache: [String: UIImage] = [:]
    
    /// Очередь загрузки для предотвращения дублирования запросов
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Получает favicon для URL
    /// - Parameters:
    ///   - url: URL сайта
    ///   - providedFaviconURL: URL favicon из метатегов страницы (опционально)
    ///   - providedOgImageURL: URL Open Graph изображения из метатегов (опционально)
    /// - Returns: UIImage с favicon или nil
    func getFavicon(
        for url: URL,
        providedFaviconURL: String? = nil,
        providedOgImageURL: String? = nil
    ) async -> UIImage? {
        let domain = extractDomain(from: url)
        
        // Проверяем кэш
        if let cachedImage = faviconCache[domain] {
            return cachedImage
        }
        
        // Проверяем, не загружается ли уже
        if let existingTask = loadingTasks[domain] {
            return await existingTask.value
        }
        
        // Создаём новую задачу загрузки
        let task = Task<UIImage?, Never> {
            return await loadFavicon(
                for: domain,
                from: url,
                providedFaviconURL: providedFaviconURL,
                providedOgImageURL: providedOgImageURL
            )
        }
        
        loadingTasks[domain] = task
        let result = await task.value
        loadingTasks.removeValue(forKey: domain)
        
        return result
    }
    
    /// Получает Open Graph изображение (высокое качество)
    /// - Parameters:
    ///   - ogImageURL: URL Open Graph изображения
    ///   - fallbackURL: URL сайта для fallback
    /// - Returns: UIImage с логотипом или nil
    func getOGImage(ogImageURL: String, fallbackURL: URL) async -> UIImage? {
        // Используем полный URL как ключ кэша для OG изображений
        let cacheKey = "og:\(ogImageURL)"
        
        // Проверяем кэш
        if let cachedImage = faviconCache[cacheKey] {
            return cachedImage
        }
        
        // Проверяем, не загружается ли уже
        if let existingTask = loadingTasks[cacheKey] {
            return await existingTask.value
        }
        
        // Создаём новую задачу загрузки
        let task = Task<UIImage?, Never> {
            return await loadOGImage(ogImageURL: ogImageURL, cacheKey: cacheKey)
        }
        
        loadingTasks[cacheKey] = task
        let result = await task.value
        loadingTasks.removeValue(forKey: cacheKey)
        
        return result
    }
    
    /// Получает favicon синхронно (из кэша)
    /// - Parameter url: URL сайта
    /// - Returns: UIImage с favicon или nil
    func getCachedFavicon(for url: URL) async -> UIImage? {
        let domain = extractDomain(from: url)
        return faviconCache[domain]
    }
    
    /// Получает OG изображение синхронно (из кэша)
    /// - Parameter ogImageURL: URL OG изображения
    /// - Returns: UIImage или nil
    func getCachedOGImage(for ogImageURL: String) async -> UIImage? {
        let cacheKey = "og:\(ogImageURL)"
        return faviconCache[cacheKey]
    }
    
    // MARK: - Private Methods
    
    /// Загружает favicon для домена с приоритетной стратегией
    private func loadFavicon(
        for domain: String,
        from url: URL,
        providedFaviconURL: String? = nil,
        providedOgImageURL: String? = nil
    ) async -> UIImage? {
        // Генерируем все возможные URL для загрузки с приоритетами
        let faviconURLs = generatePrioritizedFaviconURLs(
            for: domain,
            baseURL: url,
            providedFaviconURL: providedFaviconURL,
            providedOgImageURL: providedOgImageURL
        )
        
        print("🔍 [FaviconService] Попытка загрузить favicon для \(domain)")
        print("   Всего вариантов: \(faviconURLs.count)")
        
        // Пробуем загрузить по приоритету
        for (index, faviconURL) in faviconURLs.enumerated() {
            if let image = await downloadImage(from: faviconURL) {
                // Сохраняем в кэш
                faviconCache[domain] = image
                print("✅ [FaviconService] Загружен favicon для \(domain) (вариант \(index + 1)/\(faviconURLs.count))")
                print("   URL: \(faviconURL)")
                return image
            }
        }
        
        print("❌ [FaviconService] Не удалось загрузить favicon для \(domain)")
        return nil
    }
    
    /// Загружает Open Graph изображение
    private func loadOGImage(ogImageURL: String, cacheKey: String) async -> UIImage? {
        guard let url = URL(string: ogImageURL) else {
            print("❌ [FaviconService] Невалидный OG Image URL: \(ogImageURL)")
            return nil
        }
        
        if let image = await downloadImage(from: url) {
            faviconCache[cacheKey] = image
            print("✅ [FaviconService] Загружено OG изображение: \(ogImageURL)")
            return image
        }
        
        print("❌ [FaviconService] Не удалось загрузить OG изображение: \(ogImageURL)")
        return nil
    }
    
    /// Генерирует приоритетный список URL для favicon
    /// Стратегия:
    /// 1. Favicon URL из метатегов страницы (самый надёжный)
    /// 2. Apple Touch Icon из метатегов
    /// 3. Стандартные пути на сайте
    /// 4. Google Favicon API
    /// 5. DuckDuckGo Icons API
    /// 6. Clearbit Logo API
    private func generatePrioritizedFaviconURLs(
        for domain: String,
        baseURL: URL,
        providedFaviconURL: String?,
        providedOgImageURL: String?
    ) -> [URL] {
        var urls: [URL] = []
        
        // ПРИОРИТЕТ 1: Favicon URL из метатегов страницы
        if let faviconURLString = providedFaviconURL,
           let faviconURL = URL(string: faviconURLString) {
            urls.append(faviconURL)
            print("   📌 Приоритет 1: Favicon из метатегов: \(faviconURLString)")
        }
        
        // ПРИОРИТЕТ 2: Стандартные пути с правильным origin
        let schemes = ["https://", "http://"]
        let standardPaths = [
            "/favicon.ico",
            "/favicon.png",
            "/favicon.svg",
            "/apple-touch-icon.png",
            "/apple-touch-icon-precomposed.png",
            "/apple-touch-icon-120x120.png",
            "/apple-touch-icon-152x152.png",
            "/apple-touch-icon-180x180.png"
        ]
        
        for scheme in schemes {
            for path in standardPaths {
                if let url = URL(string: "\(scheme)\(domain)\(path)") {
                    urls.append(url)
                }
            }
        }
        
        // ПРИОРИТЕТ 3: Google Favicon API (очень надёжный fallback)
        // Поддерживает разные размеры: sz=16, 32, 64, 128, 256
        if let googleURL = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=128") {
            urls.append(googleURL)
            print("   🔄 Fallback: Google Favicon API")
        }
        
        // ПРИОРИТЕТ 4: DuckDuckGo Icons API (хорошая альтернатива)
        if let duckDuckGoURL = URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico") {
            urls.append(duckDuckGoURL)
            print("   🔄 Fallback: DuckDuckGo Icons API")
        }
        
        // ПРИОРИТЕТ 5: Clearbit Logo API (отлично для корпоративных сайтов)
        if let clearbitURL = URL(string: "https://logo.clearbit.com/\(domain)") {
            urls.append(clearbitURL)
            print("   🔄 Fallback: Clearbit Logo API")
        }
        
        return urls
    }
    
    /// Загружает изображение по URL
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            // Настраиваем request с таймаутом
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.cachePolicy = .returnCacheDataElseLoad
            
            // Устанавливаем User-Agent для обхода блокировок
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Проверяем статус ответа
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    return nil
                }
                
                // Проверяем Content-Type (должно быть изображение)
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                   !contentType.contains("image") {
                    // Игнорируем, если это не изображение
                    return nil
                }
            }
            
            // Проверяем размер файла (не больше 5MB для OG images, 1MB для favicons)
            let maxSize = url.absoluteString.contains("og:") ? 5 * 1024 * 1024 : 1024 * 1024
            guard data.count <= maxSize else {
                print("⚠️ [FaviconService] Изображение слишком большое: \(data.count) байт")
                return nil
            }
            
            // Создаём UIImage
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            // Оптимизируем размер изображения для экономии памяти
            return optimizeImage(image, maxSize: 256)
            
        } catch {
            // Игнорируем ошибки загрузки (таймауты, 404 и т.д.)
            return nil
        }
    }
    
    /// Оптимизирует изображение до максимального размера
    private func optimizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        // Если изображение уже маленькое, возвращаем как есть
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        // Вычисляем новый размер с сохранением пропорций
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Создаём уменьшенное изображение
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimizedImage ?? image
    }
    
    /// Извлекает домен из URL
    private func extractDomain(from url: URL) -> String {
        guard let host = url.host else { return url.absoluteString }
        
        // Убираем "www." если есть
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        
        return host
    }
    
    /// Очищает кэш
    func clearCache() {
        faviconCache.removeAll()
        loadingTasks.removeAll()
        print("🗑️ [FaviconService] Кэш очищен")
    }
}

