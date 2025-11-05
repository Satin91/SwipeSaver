//
//  VideoSaverInteractor.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine

/// Интерактор для управления загрузкой и сохранением видео
final class VideoSaverInteractor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var savedVideos: [SavedVideo] = []
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let videoSaverRepository: VideoSaverRepository
    private let fileManagerRepository: FileManagerRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(videoSaverRepository: VideoSaverRepository, fileManagerRepository: FileManagerRepository) {
        self.videoSaverRepository = videoSaverRepository
        self.fileManagerRepository = fileManagerRepository
        setupSubscriptions()
        loadSavedVideos()
    }
    
    // MARK: - Public Methods
    
    /// Скачать и сохранить видео
    /// - Parameter urlString: URL видео
    @MainActor
    func downloadAndSaveVideo(from urlString: String) async {
        isDownloading = true
        errorMessage = nil
        
        do {
            let downloadResult = try await videoSaverRepository.startDownload(from: urlString)
            await handleDownloadSuccess(downloadResult)
        } catch {
            handleDownloadError(error)
        }
    }
    
    /// Удалить сохраненное видео
    /// - Parameter video: Видео для удаления
    func deleteSavedVideo(_ video: SavedVideo) {
        do {
            try fileManagerRepository.deleteFile(at: video.fileURL)
            
            // Удаляем из списка
            savedVideos.removeAll { $0.id == video.id }
            
        } catch {
            print("❌ Ошибка удаления видео: \(error.localizedDescription)")
            errorMessage = "Не удалось удалить видео"
        }
    }
    
    /// Получить размер всех сохраненных видео
    /// - Returns: Размер в байтах
    func getTotalSize() -> Int64 {
        return fileManagerRepository.totalSize
    }
    
    /// Получить отформатированный размер
    /// - Returns: Строка с размером (например "125.5 MB")
    func getFormattedTotalSize() -> String {
        return fileManagerRepository.formattedTotalSize
    }
    
    /// Очистить все сохраненные видео
    func clearAllVideos() {
        fileManagerRepository.deleteAllFiles()
        savedVideos.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Настроить подписки на изменения в репозитории
    private func setupSubscriptions() {
        // Отслеживаем прогресс загрузки
        videoSaverRepository.$currentProgress
            .sink { [weak self] progress in
                self?.downloadProgress = progress
            }
            .store(in: &cancellables)
        
        // Отслеживаем активные загрузки
        videoSaverRepository.$activeDownloads
            .sink { [weak self] downloads in
                self?.isDownloading = !downloads.isEmpty
            }
            .store(in: &cancellables)
    }
    
    /// Обработать успешную загрузку
    @MainActor
    private func handleDownloadSuccess(_ result: VideoDownloadResult) async {
        guard result.status == .completed,
              let videoData = result.videoData else {
            isDownloading = false
            return
        }
        
        // Сохраняем файл
        await saveVideoToFile(result: result, data: videoData)
    }
    
    /// Обработать ошибку загрузки
    private func handleDownloadError(_ error: Error) {
        isDownloading = false
        
        if let downloadError = error as? VideoDownloadError {
            errorMessage = downloadError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        print("❌ Ошибка загрузки: \(errorMessage ?? "Неизвестная ошибка")")
    }
    
    /// Сохранить видео в файловую систему
    @MainActor
    private func saveVideoToFile(result: VideoDownloadResult, data: Data) async {
        // Генерируем имя файла
        let fileName = generateFileName(for: result)
        
        do {
            // Сохраняем файл через FileManagerRepository
            let fileURL = try fileManagerRepository.saveFile(data: data, fileName: fileName)
            
            // Создаем модель сохраненного видео
            let savedVideo = SavedVideo(
                id: result.id,
                fileName: fileName,
                fileURL: fileURL,
                platform: result.platform.rawValue,
                title: result.title,
                dateAdded: Date(),
                fileSize: Int64(data.count)
            )
            
            // Добавляем в список
            savedVideos.insert(savedVideo, at: 0)
            
            isDownloading = false
            
            print("✅ Видео сохранено: \(fileName)")
            
        } catch {
            handleDownloadError(VideoDownloadError.downloadFailed("Не удалось сохранить файл: \(error.localizedDescription)"))
        }
    }
    
    /// Генерировать имя файла для видео
    private func generateFileName(for result: VideoDownloadResult) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let platform = result.platform.rawValue.lowercased()
        return "\(platform)_\(timestamp).mp4"
    }
    
    /// Загрузить список сохраненных видео
    private func loadSavedVideos() {
        // Получаем файлы из FileManagerRepository
        let videoFiles = fileManagerRepository.getFiles(withExtensions: ["mp4"])
        
        // Конвертируем FileInfo в SavedVideo
        savedVideos = videoFiles.map { fileInfo in
            let platform = VideoPlatform.extractFromFileName(fileInfo.fileName)
            return SavedVideo(from: fileInfo, platform: platform)
        }
        
        print("📁 Загружено сохраненных видео: \(savedVideos.count)")
    }
}

