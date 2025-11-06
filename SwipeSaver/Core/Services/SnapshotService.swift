//
//  SnapshotService.swift
//  SwipeSaver
//
//  Created by AI Assistant on 29.10.2025.
//

import Foundation
import UIKit
import WebKit
import Combine

/// Сервис для управления снимками экрана вкладок браузера
class SnapshotService: ObservableObject {
    
    /// Словарь: ID вкладки -> Snapshot (UIImage)
    @Published private(set) var snapshots: [UUID: UIImage] = [:]
    
    /// Путь к директории для хранения снимков
    private let snapshotsDirectory: URL
    
    // MARK: - Init
    
    init() {
        // Создаем директорию для снимков в Application Support
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        snapshotsDirectory = appSupport.appendingPathComponent("TabSnapshots", isDirectory: true)
        
        // Создаем директорию если её нет
        if !fileManager.fileExists(atPath: snapshotsDirectory.path) {
            try? fileManager.createDirectory(at: snapshotsDirectory, withIntermediateDirectories: true)
        }
        
        print("📁 [SnapshotService] Директория снимков: \(snapshotsDirectory.path)")
        
        // Загружаем сохраненные снимки при инициализации
        loadSnapshotsFromDisk()
    }
    
    // MARK: - Public Methods
    
    /// Создает снимок экрана для указанной вкладки
    /// - Parameters:
    ///   - webView: WKWebView для создания снимка
    ///   - tabId: ID вкладки
    func takeSnapshot(of webView: WKWebView, for tabId: UUID) {
        // Создаем конфигурацию снимка
        let config = WKSnapshotConfiguration()
        
        // Делаем снимок
        webView.takeSnapshot(with: config) { [weak self] image, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [SnapshotService] Ошибка создания снимка для вкладки \(String(tabId.uuidString.prefix(8))): \(error.localizedDescription)")
                return
            }
            
            if let image = image {
                // Оптимизируем размер изображения для экономии памяти
                let optimizedImage = self.resizeImage(image, targetWidth: 300)
                
                DispatchQueue.main.async {
                    self.snapshots[tabId] = optimizedImage
                    print("📸 [SnapshotService] Снимок создан для вкладки \(String(tabId.uuidString.prefix(8)))")
                    
                    // Сохраняем снимок на диск
                    self.saveSnapshotToDisk(optimizedImage, for: tabId)
                }
            }
        }
    }
    
    /// Получает снимок экрана для указанной вкладки
    /// - Parameter tabId: ID вкладки
    /// - Returns: UIImage если снимок существует
    func getSnapshot(for tabId: UUID) -> UIImage? {
        return snapshots[tabId]
    }
    
    /// Удаляет снимок экрана для указанной вкладки
    /// - Parameter tabId: ID вкладки
    func removeSnapshot(for tabId: UUID) {
        snapshots.removeValue(forKey: tabId)
        
        // Удаляем снимок с диска
        deleteSnapshotFromDisk(for: tabId)
    }
    
    /// Очищает все снимки
    func clearAllSnapshots() {
        snapshots.removeAll()
        
        // Удаляем все снимки с диска
        if let files = try? FileManager.default.contentsOfDirectory(at: snapshotsDirectory, includingPropertiesForKeys: nil) {
            for fileURL in files where fileURL.pathExtension == "jpg" {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        print("🧹 [SnapshotService] Все снимки очищены")
    }
    
    // MARK: - Private Methods
    
    /// Оптимизирует размер изображения
    /// - Parameters:
    ///   - image: Исходное изображение
    ///   - targetWidth: Целевая ширина
    /// - Returns: Изображение с оптимизированным размером
    private func resizeImage(_ image: UIImage, targetWidth: CGFloat) -> UIImage {
        let scale = targetWidth / image.size.width
        let targetHeight = image.size.height * scale
        let targetSize = CGSize(width: targetWidth, height: targetHeight)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Disk Storage
    
    /// Путь к файлу снимка для указанной вкладки
    private func snapshotFileURL(for tabId: UUID) -> URL {
        return snapshotsDirectory.appendingPathComponent("\(tabId.uuidString).jpg")
    }
    
    /// Сохраняет снимок на диск
    private func saveSnapshotToDisk(_ image: UIImage, for tabId: UUID) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Конвертируем в JPEG для экономии места
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ [SnapshotService] Не удалось конвертировать изображение в JPEG")
                return
            }
            
            let fileURL = self.snapshotFileURL(for: tabId)
            
            do {
                try jpegData.write(to: fileURL, options: .atomic)
                print("💾 [SnapshotService] Снимок сохранен на диск: \(String(tabId.uuidString.prefix(8)))")
            } catch {
                print("❌ [SnapshotService] Ошибка сохранения снимка на диск: \(error.localizedDescription)")
            }
        }
    }
    
    /// Загружает снимок с диска
    private func loadSnapshotFromDisk(for tabId: UUID) -> UIImage? {
        let fileURL = snapshotFileURL(for: tabId)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            print("⚠️ [SnapshotService] Не удалось загрузить снимок с диска для вкладки \(String(tabId.uuidString.prefix(8)))")
            return nil
        }
        
        return image
    }
    
    /// Удаляет снимок с диска
    private func deleteSnapshotFromDisk(for tabId: UUID) {
        let fileURL = snapshotFileURL(for: tabId)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
            print("🗑️ [SnapshotService] Снимок удален с диска: \(String(tabId.uuidString.prefix(8)))")
        }
    }
    
    /// Загружает все сохраненные снимки с диска
    private func loadSnapshotsFromDisk() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: self.snapshotsDirectory,
                includingPropertiesForKeys: nil
            ) else {
                print("⚠️ [SnapshotService] Не удалось прочитать директорию снимков")
                return
            }
            
            var loadedSnapshots: [UUID: UIImage] = [:]
            
            for fileURL in files {
                guard fileURL.pathExtension == "jpg" else { continue }
                
                let filename = fileURL.deletingPathExtension().lastPathComponent
                guard let tabId = UUID(uuidString: filename) else { continue }
                
                if let image = self.loadSnapshotFromDisk(for: tabId) {
                    loadedSnapshots[tabId] = image
                }
            }
            
            DispatchQueue.main.async {
                self.snapshots = loadedSnapshots
                print("📂 [SnapshotService] Загружено \(loadedSnapshots.count) снимков с диска")
            }
        }
    }
}

