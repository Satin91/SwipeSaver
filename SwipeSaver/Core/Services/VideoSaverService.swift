//
//  VideoSaverService.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Delegate для отслеживания прогресса загрузки
private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let progressHandler: (@MainActor @Sendable (Double) -> Void)?
    let completion: (Result<Data, Error>) -> Void
    
    init(progressHandler: (@MainActor @Sendable (Double) -> Void)?, completion: @escaping (Result<Data, Error>) -> Void) {
        self.progressHandler = progressHandler
        self.completion = completion
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            completion(.success(data))
        } catch {
            completion(.failure(error))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            progressHandler?(progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completion(.failure(error))
        }
    }
}

/// Сервис для загрузки видео из различных источников
final class VideoSaverService {
    
    // MARK: - Singleton
    static let shared = VideoSaverService()
    
    // MARK: - Private Properties
    private var activeDownloads: [UUID: Task<Void, Never>] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Начать загрузку видео по URL
    /// - Parameters:
    ///   - url: URL видео для загрузки
    ///   - progressHandler: Callback для обновления прогресса
    /// - Returns: Результат загрузки
    func downloadVideo(
        from url: URL,
        progressHandler: (@MainActor @Sendable (Double) -> Void)? = nil) async throws -> VideoDownloadResult {
        let downloadId = UUID()
        
        // Определяем платформу
        guard let platform = VideoPlatform.detect(from: url) else {
            throw VideoDownloadError.unsupportedPlatform
        }
        
        // РЕАЛЬНАЯ загрузка видео
        do {
            let videoData: Data
            
            // В зависимости от платформы используем разные методы
            switch platform {
            case .youtube:
                videoData = try await downloadFromYouTube(url: url, progressHandler: progressHandler)
            case .tiktok:
                videoData = try await downloadFromTikTok(url: url, progressHandler: progressHandler)
            case .instagram:
                videoData = try await downloadFromInstagram(url: url, progressHandler: progressHandler)
            case .direct:
                // Прямая ссылка - загружаем напрямую
                videoData = try await downloadDirectVideo(from: url, progressHandler: progressHandler)
            }
            
            // Успешный результат
            let result = VideoDownloadResult(
                id: downloadId,
                url: url,
                platform: platform,
                status: .completed,
                progress: 1.0,
                videoData: videoData,
                error: nil,
                title: "Видео с \(platform.rawValue)",
                thumbnail: nil
            )
            
            return result
            
        } catch {
            throw VideoDownloadError.downloadFailed(error.localizedDescription)
        }
    }
    
    /// Отменить загрузку по ID
    /// - Parameter id: UUID загрузки
    func cancelDownload(_ id: UUID) {
        activeDownloads[id]?.cancel()
        activeDownloads.removeValue(forKey: id)
    }
    
    /// Отменить все активные загрузки
    func cancelAllDownloads() {
        activeDownloads.values.forEach { $0.cancel() }
        activeDownloads.removeAll()
    }
    
    /// Проверить, поддерживается ли URL
    /// - Parameter url: URL для проверки
    /// - Returns: true если платформа поддерживается
    func isSupported(url: URL) -> Bool {
        return VideoPlatform.detect(from: url) != nil
    }
    
    // MARK: - Private Methods
    
    /// Загрузить видео с YouTube
    private func downloadFromYouTube(url: URL, progressHandler: (@MainActor @Sendable (Double) -> Void)?) async throws -> Data {
        // TODO: Интеграция с yt-dlp или YouTube API
        // Для реальной загрузки нужно:
        // 1. Использовать yt-dlp (командная строка)
        // 2. Или использовать unofficial YouTube API
        // 3. Или интегрировать с сервисом загрузки
        
        // Временно: пробуем загрузить как обычный файл (не сработает для YouTube)
        return try await downloadDirectVideo(from: url, progressHandler: progressHandler)
    }
    
    /// Загрузить видео с TikTok
    private func downloadFromTikTok(url: URL, progressHandler: (@MainActor @Sendable (Double) -> Void)?) async throws -> Data {
        // TikTok обычно требует парсинга страницы для получения прямой ссылки
        // Можно использовать API вроде https://github.com/davidteather/TikTok-Api
        
        // Временно: пробуем загрузить как обычный файл
        return try await downloadDirectVideo(from: url, progressHandler: progressHandler)
    }
    
    /// Загрузить видео с Instagram
    private func downloadFromInstagram(url: URL, progressHandler: (@MainActor @Sendable (Double) -> Void)?) async throws -> Data {
        // Instagram требует авторизации и специального API
        // Можно использовать библиотеки типа Instaloader (Python) через процесс
        
        // Временно: пробуем загрузить как обычный файл
        return try await downloadDirectVideo(from: url, progressHandler: progressHandler)
    }
    
    /// Загрузить видео напрямую по URL (для прямых ссылок на .mp4)
    private func downloadDirectVideo(from url: URL, progressHandler: (@MainActor @Sendable (Double) -> Void)?) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = DownloadDelegate(progressHandler: progressHandler) { result in
                continuation.resume(with: result)
            }
            
            // Создаем сессию с delegate
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            
            // Запускаем загрузку
            let task = session.downloadTask(with: url)
            task.resume()
        }
    }
    
    /// Загрузить видео с отслеживанием прогресса через URLSession delegate
    private func downloadWithProgress(from url: URL, progressHandler: (@MainActor @Sendable (Double) -> Void)?) async throws -> Data {
        // Создаем задачу загрузки
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    continuation.resume(throwing: VideoDownloadError.downloadFailed(error.localizedDescription))
                    return
                }
                
                guard let localURL = localURL else {
                    continuation.resume(throwing: VideoDownloadError.downloadFailed("Не удалось получить локальный файл"))
                    return
                }
                
                do {
                    let data = try Data(contentsOf: localURL)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: VideoDownloadError.downloadFailed(error.localizedDescription))
                }
            }
            
            task.resume()
        }
    }
}

