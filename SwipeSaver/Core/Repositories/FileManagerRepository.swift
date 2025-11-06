//
//  FileManagerRepository.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine

/// Репозиторий для управления файлами приложения
final class FileManagerRepository: ObservableObject {
    
    // MARK: - Published Properties
    @Published var files: [FileInfo] = []
    @Published var totalSize: Int64 = 0
    @Published var availableDiskSpace: Int64 = 0
    @Published var savedVideos: [SavedVideo] = []
    
    // MARK: - Private Properties
    private let fileManagerService: FileManagerService
    private let workingDirectory: URL
    
    // MARK: - Computed Properties
    var formattedTotalSize: String {
        fileManagerService.formatFileSize(totalSize)
    }
    
    var formattedAvailableSpace: String {
        fileManagerService.formatFileSize(availableDiskSpace)
    }
    
    // MARK: - Initialization
    
    /// Инициализация с кастомной директорией
    /// - Parameters:
    ///   - fileManagerService: Сервис файлового менеджера
    ///   - directoryName: Имя рабочей директории внутри Documents
    init(fileManagerService: FileManagerService, directoryName: String = "SavedVideos") {
        self.fileManagerService = fileManagerService
        
        // Создаем рабочую директорию
        let documentsURL = fileManagerService.documentsDirectory
        self.workingDirectory = documentsURL.appendingPathComponent(directoryName, isDirectory: true)
        
        // Создаем директорию если её нет
        try? fileManagerService.createDirectoryIfNeeded(at: workingDirectory)
        
        // Загружаем начальные данные
        loadFiles()
        updateDiskSpace()
        loadSavedVideos()
    }
    
    // MARK: - Public Methods
    
    /// Сохранить файл
    /// - Parameters:
    ///   - data: Данные для сохранения
    ///   - fileName: Имя файла
    /// - Returns: URL сохраненного файла
    @discardableResult
    func saveFile(data: Data, fileName: String) throws -> URL {
        let fileURL = workingDirectory.appendingPathComponent(fileName)
        
        try fileManagerService.saveFile(data: data, to: fileURL)
        
        // Обновляем список файлов
        loadFiles()
        
        return fileURL
    }
    
    /// Удалить файл
    /// - Parameter fileInfo: Информация о файле для удаления
    func deleteFile(_ fileInfo: FileInfo) throws {
        try fileManagerService.deleteFile(at: fileInfo.fileURL)
        
        // Обновляем список файлов
        loadFiles()
    }
    
    /// Удалить файл по URL
    /// - Parameter url: URL файла
    func deleteFile(at url: URL) throws {
        try fileManagerService.deleteFile(at: url)
        
        // Обновляем список файлов
        loadFiles()
    }
    
    /// Удалить все файлы
    func deleteAllFiles() {
        let errors = fileManagerService.deleteFiles(at: files.map { $0.fileURL })
        
        if !errors.isEmpty {
            print("⚠️ Ошибки при удалении файлов: \(errors.count)")
        }
        
        // Обновляем список файлов
        loadFiles()
    }
    
    /// Удалить файлы определенного типа
    /// - Parameter extensions: Расширения файлов для удаления
    func deleteFiles(withExtensions extensions: [String]) {
        let filesToDelete = files.filter { file in
            extensions.contains(file.fileExtension.lowercased())
        }
        
        let errors = fileManagerService.deleteFiles(at: filesToDelete.map { $0.fileURL })
        
        if !errors.isEmpty {
            print("⚠️ Ошибки при удалении файлов: \(errors.count)")
        }
        
        // Обновляем список файлов
        loadFiles()
    }
    
    /// Получить файл по имени
    /// - Parameter fileName: Имя файла
    /// - Returns: Информация о файле, если найден
    func getFile(byName fileName: String) -> FileInfo? {
        return files.first { $0.fileName == fileName }
    }
    
    /// Получить файлы определенного типа
    /// - Parameter extensions: Расширения файлов
    /// - Returns: Массив файлов
    func getFiles(withExtensions extensions: [String]) -> [FileInfo] {
        return files.filter { file in
            extensions.contains(file.fileExtension.lowercased())
        }
    }
    
    /// Проверить существование файла
    /// - Parameter fileName: Имя файла
    /// - Returns: true если файл существует
    func fileExists(fileName: String) -> Bool {
        let fileURL = workingDirectory.appendingPathComponent(fileName)
        return fileManagerService.fileExists(at: fileURL)
    }
    
    /// Обновить список файлов
    func refreshFiles() {
        loadFiles()
        updateDiskSpace()
    }
    
    /// Получить URL рабочей директории
    var directoryURL: URL {
        return workingDirectory
    }
    
    // MARK: - SavedVideo Methods
    
    /// Сохранить видео и создать модель SavedVideo
    /// - Parameters:
    ///   - data: Данные видео
    ///   - title: Название видео
    ///   - platform: Платформа (YouTube, TikTok, Social, etc.)
    ///   - quality: Качество видео
    ///   - extension: Расширение файла
    /// - Returns: Модель SavedVideo
    @discardableResult
    func saveVideoAndCreateModel(
        data: Data,
        title: String?,
        platform: String,
        quality: String? = nil,
        extension ext: String = "mp4"
    ) throws -> SavedVideo {
        // Генерируем имя файла
        let fileName = generateVideoFileName(
            title: title,
            platform: platform,
            quality: quality,
            extension: ext
        )
        
        // Сохраняем файл
        let fileURL = try saveFile(data: data, fileName: fileName)
        
        // Создаем модель
        let savedVideo = SavedVideo(
            id: UUID(),
            fileName: fileName,
            fileURL: fileURL,
            platform: platform,
            title: title ?? "Untitled",
            dateAdded: Date(),
            fileSize: Int64(data.count)
        )
        
        // Добавляем в список сохраненных видео
        savedVideos.insert(savedVideo, at: 0)
        
        print("✅ Видео сохранено: \(fileName)")
        
        return savedVideo
    }
    
    /// Сохранить видео из результата загрузки
    /// - Parameters:
    ///   - data: Данные видео
    ///   - result: Результат загрузки
    /// - Returns: Модель SavedVideo
    @discardableResult
    func saveVideoFromDownloadResult(
        data: Data,
        result: VideoDownloadResult
    ) throws -> SavedVideo {
        // Генерируем имя файла
        let fileName = generateVideoFileName(
            title: result.title,
            platform: result.platform.rawValue,
            quality: nil,
            extension: "mp4"
        )
        
        // Сохраняем файл
        let fileURL = try saveFile(data: data, fileName: fileName)
        
        // Создаем модель
        let savedVideo = SavedVideo(
            id: result.id,
            fileName: fileName,
            fileURL: fileURL,
            platform: result.platform.rawValue,
            title: result.title,
            dateAdded: Date(),
            fileSize: Int64(data.count)
        )
        
        // Добавляем в список сохраненных видео
        savedVideos.insert(savedVideo, at: 0)
        
        print("✅ Видео сохранено: \(fileName)")
        
        return savedVideo
    }
    
    /// Удалить сохраненное видео
    /// - Parameter video: Видео для удаления
    func deleteSavedVideo(_ video: SavedVideo) throws {
        // Удаляем файл
        try deleteFile(at: video.fileURL)
        
        // Удаляем из списка
        savedVideos.removeAll { $0.id == video.id }
        
        print("🗑️ Видео удалено: \(video.fileName)")
    }
    
    /// Очистить все сохраненные видео
    func clearAllSavedVideos() {
        deleteAllFiles()
        savedVideos.removeAll()
        print("🗑️ Все видео удалены")
    }
    
    /// Загрузить сохраненные видео (приватный метод для инициализации)
    private func loadSavedVideos() {
        let videoFiles = getFiles(withExtensions: ["mp4", "mov", "avi"])
        
        savedVideos = videoFiles.map { fileInfo in
            let platform = VideoPlatform.extractFromFileName(fileInfo.fileName)
            return SavedVideo(from: fileInfo, platform: platform)
        }
        
        print("📁 Загружено сохраненных видео: \(savedVideos.count)")
    }
    
    /// Обновить список сохраненных видео
    func refreshSavedVideos() {
        loadSavedVideos()
    }
    
    /// Генерировать имя файла для видео
    /// - Parameters:
    ///   - title: Название видео
    ///   - platform: Платформа
    ///   - quality: Качество
    ///   - extension: Расширение файла
    /// - Returns: Имя файла
    private func generateVideoFileName(
        title: String?,
        platform: String,
        quality: String?,
        extension ext: String
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let platformTag = platform.lowercased()
        let qualityTag = quality.map { "_\($0.replacingOccurrences(of: " ", with: "_"))" } ?? ""
        let titleTag = title.map { "_\($0)" } ?? ""
        
        return "\(platformTag)\(titleTag)\(qualityTag)_\(timestamp).\(ext)"
    }
    
    // MARK: - Private Methods
    
    /// Загрузить список файлов
    private func loadFiles() {
        do {
            files = try fileManagerService.getFiles(in: workingDirectory)
            
            // Сортируем по дате создания (новые первыми)
            files.sort { $0.createdDate > $1.createdDate }
            
            // Обновляем общий размер
            totalSize = files.reduce(0) { $0 + $1.fileSize }
            
            print("📁 Загружено файлов: \(files.count), размер: \(formattedTotalSize)")
            
        } catch {
            print("❌ Ошибка загрузки файлов: \(error.localizedDescription)")
            files = []
            totalSize = 0
        }
    }
    
    /// Обновить информацию о свободном месте
    private func updateDiskSpace() {
        availableDiskSpace = fileManagerService.getAvailableDiskSpace() ?? 0
    }
}

