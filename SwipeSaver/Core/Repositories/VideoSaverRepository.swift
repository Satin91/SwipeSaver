//
//  VideoSaverRepository.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine

/// Delegate для отслеживания прогресса загрузки
private class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    let progressHandler: (Double) -> Void
    let completion: (Result<Data, Error>) -> Void
    
    init(progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<Data, Error>) -> Void) {
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
        progressHandler(progress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completion(.failure(error))
        }
    }
}

/// Репозиторий для управления загрузкой видео
final class VideoSaverRepository: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeDownloads: [VideoDownloadResult] = []
    @Published var completedDownloads: [VideoDownloadResult] = []
    @Published var currentProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let videoSaverService: VideoSaverService
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    // MARK: - Initialization
    init(videoSaverService: VideoSaverService) {
        self.videoSaverService = videoSaverService
    }
    
    // MARK: - Public Methods
    
    /// Начать загрузку видео
    /// - Parameter urlString: URL видео в виде строки
    /// - Returns: Результат загрузки
    @MainActor
    func startDownload(from urlString: String) async throws -> VideoDownloadResult {
        // Валидация URL
        guard let url = URL(string: urlString) else {
            throw VideoDownloadError.invalidURL
        }
        
        // Проверка поддержки платформы
        guard videoSaverService.isSupported(url: url) else {
            throw VideoDownloadError.unsupportedPlatform
        }
        
        print("📥 Загрузка начата для: \(urlString)")
        
        // Запускаем загрузку с отслеживанием прогресса
        do {
            let result = try await videoSaverService.downloadVideo(from: url) { [weak self] progress in
                print("DEBUG: progress \(progress)")
                Task { @MainActor in
                    self?.currentProgress = progress
                }
            }
            handleDownloadUpdate(result)
            
            // Сбрасываем прогресс после завершения
            currentProgress = 0.0
            
            return result
        } catch {
            // Сбрасываем прогресс при ошибке
            currentProgress = 0.0
            
            if let downloadError = error as? VideoDownloadError {
                throw downloadError
            }
            throw VideoDownloadError.downloadFailed(error.localizedDescription)
        }
    }
    
    /// Отменить загрузку
    /// - Parameter downloadId: ID загрузки для отмены
    @MainActor
    func cancelDownload(_ downloadId: UUID) {
        activeTasks[downloadId]?.cancel()
        activeTasks.removeValue(forKey: downloadId)
        videoSaverService.cancelDownload(downloadId)
        
        // Удаляем из активных загрузок
        activeDownloads.removeAll { $0.id == downloadId }
    }
    
    /// Отменить все загрузки
    @MainActor
    func cancelAllDownloads() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        videoSaverService.cancelAllDownloads()
        activeDownloads.removeAll()
    }
    
    /// Получить результат загрузки по ID
    /// - Parameter downloadId: ID загрузки
    /// - Returns: Результат загрузки, если найден
    func getDownloadResult(by downloadId: UUID) -> VideoDownloadResult? {
        return activeDownloads.first { $0.id == downloadId }
            ?? completedDownloads.first { $0.id == downloadId }
    }
    
    /// Очистить завершенные загрузки
    @MainActor
    func clearCompletedDownloads() {
        completedDownloads.removeAll()
    }
    
    /// Загрузить видео по прямой ссылке (для соц. сетей)
    /// - Parameters:
    ///   - urlString: Прямая ссылка на видео
    /// - Returns: Данные видео
    @MainActor
    func downloadDirectVideo(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw VideoDownloadError.invalidURL
        }
        
        print("📥 Загрузка видео: \(urlString)")
        
        // Используем делегат для отслеживания прогресса
        let data = try await withCheckedThrowingContinuation { continuation in
            let delegate = DownloadProgressDelegate(progressHandler: { [weak self] progress in
                Task { @MainActor in
                    self?.currentProgress = progress
                }
            }, completion: { result in
                continuation.resume(with: result)
            })
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            let task = session.downloadTask(with: url)
            task.resume()
        }
        
        // Сбрасываем прогресс после завершения
        currentProgress = 0.0
        
        return data
    }
    
    // MARK: - Private Methods
    
    /// Обработать обновление статуса загрузки
    @MainActor
    private func handleDownloadUpdate(_ result: VideoDownloadResult) {
        switch result.status {
        case .pending, .downloading:
            // Обновляем или добавляем в активные
            if let index = activeDownloads.firstIndex(where: { $0.id == result.id }) {
                activeDownloads[index] = result
            } else {
                activeDownloads.append(result)
            }
            
        case .completed:
            // Перемещаем в завершенные
            activeDownloads.removeAll { $0.id == result.id }
            completedDownloads.append(result)
            
        case .failed:
            // Удаляем из активных
            activeDownloads.removeAll { $0.id == result.id }
        }
    }
}

