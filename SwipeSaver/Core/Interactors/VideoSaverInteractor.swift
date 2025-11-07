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
    private let userDefaultsObserver: UserDefaultsObserver
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Список сохраненных видео (из repository)
    var savedVideos: [SavedVideo] {
        return fileManagerRepository.savedVideos
    }
    
    /// Список папок для видео (из UserDefaultsObserver)
    var videoFolders: [VideoFolder] {
        return userDefaultsObserver.videoFolders
    }
    
    // MARK: - Initialization
    init(videoSaverRepository: VideoSaverRepository, fileManagerRepository: FileManagerRepository, networkRepository: NetworkRepository, userDefaultsObserver: UserDefaultsObserver) {
        self.videoSaverRepository = videoSaverRepository
        self.networkRepository = networkRepository
        self.fileManagerRepository = fileManagerRepository
        self.userDefaultsObserver = userDefaultsObserver
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Универсальный метод для загрузки видео (автоматически определяет тип ссылки)
    /// - Parameter urlString: URL видео
    @MainActor
    func downloadVideo(from urlString: String) async {
        isDownloading = true
        errorMessage = nil
        
        do {
            if isDirectVideoURL(urlString) {
                // Прямая ссылка - загружаем напрямую
                let videoData = try await videoSaverRepository.downloadVideo(from: urlString)
                
                // Сохраняем через repository
                try await fileManagerRepository.saveVideoAndCreateModel(
                    data: videoData,
                    title: "Direct Video",
                    platform: "Direct",
                    quality: nil,
                    extension: "mp4"
                )
                
                isDownloading = false
            } else {
                // Соц. сеть - получаем информацию через API
                let response: SocialVideoResponse = try await networkRepository.request(
                    .fetchSocialVideo(url: urlString)
                )
                
                guard response.isSuccess else {
                    throw VideoDownloadError.downloadFailed(response.errorMessage ?? "Не удалось получить видео")
                }
                
                guard let videoToDownload = response.videoWithAudio ?? response.bestMP4Video ?? response.bestQualityVideo else {
                    throw VideoDownloadError.downloadFailed("Видео не найдено")
                }
                
                print("📥 Загружаем: \(videoToDownload.formatDescription)")
                
                // Определяем платформу из оригинальной ссылки
                let platform = detectPlatform(from: urlString)
                
                // Загружаем видео
                let videoData = try await videoSaverRepository.downloadDirectVideo(from: videoToDownload.url)
                
                // Сохраняем через repository с правильной платформой
                try await fileManagerRepository.saveVideoAndCreateModel(
                    data: videoData,
                    title: response.title,
                    platform: platform.rawValue,
                    quality: videoToDownload.qualityDescription,
                    extension: videoToDownload.ext ?? "mp4"
                )
                
                isDownloading = false
            }
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
            
            // Удаляем видео из всех папок
            var folders = userDefaultsObserver.videoFolders
            for i in 0..<folders.count {
                folders[i].removeVideo(video.id)
            }
            userDefaultsObserver.updateVideoFolders(folders)
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
        
        // Очищаем все папки от видео
        var folders = userDefaultsObserver.videoFolders
        for i in 0..<folders.count {
            folders[i].videoIds.removeAll()
        }
        userDefaultsObserver.updateVideoFolders(folders)
    }
    
    // MARK: - Folder Management
    
    /// Переместить видео в папку
    /// - Parameters:
    ///   - videoId: ID видео
    ///   - toFolderId: ID папки назначения (nil для удаления из папки)
    func moveVideoToFolder(_ videoId: UUID, toFolderId: UUID?) {
        var folders = userDefaultsObserver.videoFolders
        
        // Удаляем видео из всех папок
        for i in 0..<folders.count {
            folders[i].removeVideo(videoId)
        }
        
        // Добавляем в новую папку, если указана
        if let toFolderId = toFolderId,
           let folderIndex = folders.firstIndex(where: { $0.id == toFolderId }) {
            folders[folderIndex].addVideo(videoId)
            print("📁 Видео \(videoId) перемещено в папку \(folders[folderIndex].name)")
        } else {
            print("📁 Видео \(videoId) удалено из всех папок")
        }
        
        // Обновляем состояние
        userDefaultsObserver.updateVideoFolders(folders)
    }
    
    /// Получить папку, в которой находится видео
    /// - Parameter videoId: ID видео
    /// - Returns: Папка или nil
    func getFolderForVideo(_ videoId: UUID) -> VideoFolder? {
        return userDefaultsObserver.getFolderForVideo(videoId)
    }
    
    /// Получить видео в папке
    /// - Parameter folder: Папка
    /// - Returns: Массив видео
    func getVideosInFolder(_ folder: VideoFolder) -> [SavedVideo] {
        return savedVideos.filter { folder.videoIds.contains($0.id) }
    }
    
    /// Получить видео без папки
    /// - Returns: Массив видео
    func getVideosWithoutFolder() -> [SavedVideo] {
        let allFolderVideoIds = videoFolders.flatMap { $0.videoIds }
        return savedVideos.filter { !allFolderVideoIds.contains($0.id) }
    }
    
    /// Создать новую папку
    /// - Parameters:
    ///   - name: Название папки
    ///   - iconName: Имя иконки
    ///   - color: Цвет в hex формате
    func createFolder(name: String, iconName: String, color: String) {
        var folders = userDefaultsObserver.videoFolders
        let newFolder = VideoFolder(name: name, iconName: iconName, color: color)
        folders.append(newFolder)
        userDefaultsObserver.updateVideoFolders(folders)
        print("📁 Создана папка \(name)")
    }
    
    /// Удалить папку
    /// - Parameter folderId: ID папки
    func deleteFolder(_ folderId: UUID) {
        var folders = userDefaultsObserver.videoFolders
        folders.removeAll { $0.id == folderId }
        userDefaultsObserver.updateVideoFolders(folders)
        print("📁 Папка удалена")
    }
    
    /// Определяет, является ли URL прямой ссылкой на видео файл
    /// - Parameter urlString: URL для проверки
    /// - Returns: true, если это прямая ссылка на видео, false - если это ссылка на соц. сеть
    func isDirectVideoURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        
        let host = url.host?.lowercased() ?? ""
        
        // Список доменов социальных сетей
        let socialDomains = [
            "youtube.com", "youtu.be",
            "tiktok.com", "vt.tiktok.com",
            "instagram.com",
            "twitter.com", "x.com", "t.co",
            "facebook.com", "fb.watch", "fb.com",
            "vk.com", "vk.ru",
            "ok.ru", "odnoklassniki.ru",
            "rutube.ru",
            "twitch.tv",
            "reddit.com", "redd.it",
            "pinterest.com", "pin.it",
            "linkedin.com",
            "snapchat.com",
            "vimeo.com",
            "dailymotion.com", "dai.ly",
            "bilibili.com", "b23.tv",
            "t.me", "telegram.org"
        ]
        
        // Если это ссылка на соц. сеть - точно не прямая ссылка
        for domain in socialDomains {
            if host.contains(domain) {
                return false
            }
        }
        
        // Если это НЕ соц. сеть - считаем прямой ссылкой
        // (даже если нет расширения, это может быть прямая ссылка от CDN)
        return true
    }
    
    /// Определить платформу из URL
    /// - Parameter urlString: URL для проверки
    /// - Returns: Платформа
    private func detectPlatform(from urlString: String) -> VideoPlatform {
        guard let url = URL(string: urlString) else {
            return .direct
        }
        
        return VideoPlatform.detect(from: url) ?? .direct
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
}

