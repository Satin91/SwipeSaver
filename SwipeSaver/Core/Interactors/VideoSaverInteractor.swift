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
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let videoSaverRepository: VideoSaverRepository
    private let networkRepository: NetworkRepository
    private let fileManagerRepository: FileManagerRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Список сохраненных видео (из repository)
    var savedVideos: [SavedVideo] {
        return fileManagerRepository.savedVideos
    }
    
    // MARK: - Initialization
    init(videoSaverRepository: VideoSaverRepository, fileManagerRepository: FileManagerRepository, networkRepository: NetworkRepository) {
        self.videoSaverRepository = videoSaverRepository
        self.networkRepository = networkRepository
        self.fileManagerRepository = fileManagerRepository
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Универсальный метод для загрузки видео (автоматически определяет тип ссылки)
    /// - Parameter urlString: URL видео
    @MainActor
    func downloadVideo(from urlString: String) async {
        if isDirectVideoURL(urlString) {
            await downloadAndSaveVideo(from: urlString)
        } else {
            await downloadSocialVideo(from: urlString)
        }
    }
    
    /// Скачать и сохранить видео
    /// - Parameter urlString: URL видео
    @MainActor
    private func downloadAndSaveVideo(from urlString: String) async {
        isDownloading = true
        errorMessage = nil
        
        do {
            let downloadResult = try await videoSaverRepository.startDownload(from: urlString)
            await handleDownloadSuccess(downloadResult)
        } catch {
            handleDownloadError(error)
        }
    }
    
    /// Скачать и сохранить видео из соц. сети
    /// - Parameter urlString: URL видео
    @MainActor
    private func downloadSocialVideo(from urlString: String) async {
        isDownloading = true
        errorMessage = nil
        
        do {
            // 1. Получаем информацию о видео через API
            let response: SocialVideoResponse = try await networkRepository.request(
                .fetchSocialVideo(url: urlString)
            )
            
            guard response.isSuccess else {
                throw VideoDownloadError.downloadFailed(response.errorMessage ?? "Не удалось получить видео")
            }
            
            // 2. Выбираем видео для загрузки
            guard let videoToDownload = response.videoWithAudio ?? response.bestMP4Video ?? response.bestQualityVideo else {
                throw VideoDownloadError.downloadFailed("Видео не найдено")
            }
            
            print("📥 Загружаем: \(videoToDownload.formatDescription)")
            
            // 3. Загружаем видео
            let videoData = try await videoSaverRepository.downloadDirectVideo(from: videoToDownload.url)
            
            // 4. Сохраняем через repository (автоматически добавит в список)
            try fileManagerRepository.saveVideoAndCreateModel(
                data: videoData,
                title: response.title,
                platform: "Social",
                quality: videoToDownload.qualityDescription,
                extension: videoToDownload.ext ?? "mp4"
            )
            
            isDownloading = false
            
        } catch {
            print("❌ Ошибка: \(error)")
            handleDownloadError(error)
        }
    }
    
    /// Удалить сохраненное видео
    /// - Parameter video: Видео для удаления
    func deleteSavedVideo(_ video: SavedVideo) {
        do {
            try fileManagerRepository.deleteSavedVideo(video)
        } catch {
            print("❌ Ошибка удаления видео: \(error.localizedDescription)")
            errorMessage = "Не удалось удалить видео"
        }
    }
    
    /// Получить размер всех сохраненных видео
    func getTotalSize() -> Int64 {
        return fileManagerRepository.totalSize
    }
    
    /// Получить отформатированный размер
    func getFormattedTotalSize() -> String {
        return fileManagerRepository.formattedTotalSize
    }
    
    /// Очистить все сохраненные видео
    func clearAllVideos() {
        fileManagerRepository.clearAllSavedVideos()
    }
    
    /// Определяет, является ли URL прямой ссылкой на видео файл
    /// - Parameter urlString: URL для проверки
    /// - Returns: true, если это прямая ссылка на видео, false - если это ссылка на соц. сеть
    func isDirectVideoURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        
        // Список поддерживаемых видео расширений
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "mpg", "mpeg", "wmv", "flv", "webm", "3gp"]
        
        // Если URL заканчивается на видео расширение - это Direct, иначе - Social
        let pathExtension = url.pathExtension.lowercased()
        return videoExtensions.contains(pathExtension)
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
        do {
            // Сохраняем через repository (автоматически добавит в список)
            try fileManagerRepository.saveVideoFromDownloadResult(data: data, result: result)
            isDownloading = false
        } catch {
            handleDownloadError(VideoDownloadError.downloadFailed("Не удалось сохранить файл: \(error.localizedDescription)"))
        }
    }
}

