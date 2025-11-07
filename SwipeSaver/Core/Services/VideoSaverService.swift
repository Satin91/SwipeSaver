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
    /// - Returns: Данные видео
    func downloadVideo(
        from url: URL,
        progressHandler: (@MainActor @Sendable (Double) -> Void)? = nil) async throws -> Data {
        
        // Просто загружаем видео с прогрессом
        let videoData = try await downloadDirectVideo(from: url, progressHandler: progressHandler)
        return videoData
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
}

