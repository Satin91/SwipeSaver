//
//  VideoSaverRepository.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine

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
    
    /// Загрузить видео по URL (возвращает только данные)
    /// - Parameter urlString: URL видео в виде строки
    /// - Returns: Данные видео
    @MainActor
    func downloadVideo(from urlString: String) async throws -> Data {
        // Валидация URL
        guard let url = URL(string: urlString) else {
            throw VideoDownloadError.invalidURL
        }
        
        print("📥 Загрузка начата для: \(urlString)")
        
        // Запускаем загрузку с отслеживанием прогресса
        do {
            let videoData = try await videoSaverService.downloadVideo(from: url) { [weak self] progress in
                Task { @MainActor in
                    self?.currentProgress = progress
                }
            }
            
            // Сбрасываем прогресс после завершения
            currentProgress = 0.0
            
            return videoData
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
        // Просто используем общий метод downloadVideo
        return try await downloadVideo(from: urlString)
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

