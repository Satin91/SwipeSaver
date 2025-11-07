//
//  FileManagerRepository.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine

/// Структура для хранения связей видео-папка в UserDefaults
struct VideoFolderMapping: Codable {
    let videoId: String  // UUID видео в виде строки
    let folderId: String? // UUID папки в виде строки или nil
}

/// Репозиторий для управления файлами приложения
final class FileManagerRepository: ObservableObject {
    
    // MARK: - Published Properties
    @Published var files: [FileInfo] = []
    @Published var totalSize: Int64 = 0
    @Published var availableDiskSpace: Int64 = 0
    @Published var savedVideos: [SavedVideo] = []
    
    // MARK: - Private Properties
    private let fileManagerService: FileManagerService
    private let videoWatermarkService: VideoWatermarkService
    private let workingDirectory: URL
    private let userDefaultsService: UserDefaultsService
    
    // MARK: - Settings
    /// Включить водяной знак для сохраняемых видео (зависит от настроек и Premium статуса)
    var isWatermarkEnabled: Bool {
        let settings = userDefaultsService.load(AppSettings.self, forKey: .appSettings) ?? .default
        // Водяной знак включен если: настройка включена И пользователь НЕ Premium
        return settings.enableWatermark && !settings.isPremiumUser
    }
    
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
    ///   - videoWatermarkService: Сервис водяных знаков
    ///   - userDefaultsService: Сервис пользовательских настроек
    ///   - directoryName: Имя рабочей директории внутри Documents
    init(
        fileManagerService: FileManagerService,
        videoWatermarkService: VideoWatermarkService,
        userDefaultsService: UserDefaultsService = .shared,
        directoryName: String = "SavedVideos"
    ) {
        self.fileManagerService = fileManagerService
        self.videoWatermarkService = videoWatermarkService
        self.userDefaultsService = userDefaultsService
        
        // Создаем рабочую директорию
        let documentsURL = fileManagerService.documentsDirectory
        self.workingDirectory = documentsURL.appendingPathComponent(directoryName, isDirectory: true)
        
        // Создаем директорию если её нет
        try? fileManagerService.createDirectoryIfNeeded(at: workingDirectory)
        
        // Загружаем начальные данные
        loadFiles()
        updateDiskSpace()
        loadSavedVideos() // Теперь loadSavedVideos сам подгружает маппинги
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
    ) async throws -> SavedVideo {
        // Генерируем временное имя файла
        let tempFileName = UUID().uuidString + ".\(ext)"
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)
        
        // Сохраняем временный файл
        try data.write(to: tempFileURL)
        
        // Применяем водяной знак, если включен
        let processedFileURL: URL
        if isWatermarkEnabled {
            print("🎬 Применяем водяной знак...")
            do {
                processedFileURL = try await videoWatermarkService.applyWatermark(to: tempFileURL)
                // Удаляем временный файл
                try? FileManager.default.removeItem(at: tempFileURL)
            } catch {
                print("⚠️ Ошибка применения водяного знака: \(error.localizedDescription)")
                print("⚠️ Сохраняем видео без водяного знака")
                processedFileURL = tempFileURL
            }
        } else {
            processedFileURL = tempFileURL
        }
        
        // Читаем обработанное видео
        let processedData = try Data(contentsOf: processedFileURL)
        
        // Генерируем финальное имя файла
        let fileName = generateVideoFileName(
            title: title,
            platform: platform,
            quality: quality,
            extension: ext
        )
        
        // Сохраняем файл в рабочую директорию
        let fileURL = try saveFile(data: processedData, fileName: fileName)
        
        // Удаляем обработанный временный файл
        try? FileManager.default.removeItem(at: processedFileURL)
        
        // Создаем модель
        let savedVideo = SavedVideo(
            id: UUID(),
            fileName: fileName,
            fileURL: fileURL,
            platform: platform,
            title: title ?? "Untitled",
            dateAdded: Date(),
            fileSize: Int64(processedData.count)
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
        
        // Удаляем связь из UserDefaults
        removeFolderMapping(videoId: video.id)
        
        print("🗑️ Видео удалено: \(video.fileName)")
    }
    
    /// Очистить все сохраненные видео
    func clearAllSavedVideos() {
        deleteAllFiles()
        savedVideos.removeAll()
        
        // Очищаем все связи через UserDefaultsService
        userDefaultsService.delete(forKey: .videoFolderMappings)
        
        print("🗑️ Все видео удалены")
    }
    
    /// Переместить видео в папку
    /// - Parameters:
    ///   - video: Видео для перемещения
    ///   - folderId: ID папки или nil для удаления из папки
    func moveVideoToFolder(_ video: SavedVideo, folderId: UUID?) {
        if let index = savedVideos.firstIndex(where: { $0.id == video.id }) {
            var updatedVideo = savedVideos[index]
            updatedVideo = SavedVideo(
                id: updatedVideo.id,
                fileName: updatedVideo.fileName,
                fileURL: updatedVideo.fileURL,
                platform: updatedVideo.platform,
                title: updatedVideo.title,
                dateAdded: updatedVideo.dateAdded,
                fileSize: updatedVideo.fileSize,
                folderId: folderId
            )
            savedVideos[index] = updatedVideo
            
            // Сохраняем в UserDefaults
            saveFolderMapping(videoId: updatedVideo.id, folderId: folderId)
            
            print("📁 Видео перемещено: \(video.fileName) -> папка: \(folderId?.uuidString ?? "без папки")")
        }
    }
    
    // MARK: - UserDefaults Methods
    
    /// Сохранить связь видео-папка в UserDefaults
    private func saveFolderMapping(videoId: UUID, folderId: UUID?) {
        var mappings = loadAllFolderMappings()
        
        // Удаляем старую связь для этого видео
        mappings.removeAll { $0.videoId == videoId.uuidString }
        
        // Добавляем новую связь
        let newMapping = VideoFolderMapping(
            videoId: videoId.uuidString,
            folderId: folderId?.uuidString
        )
        mappings.append(newMapping)
        
        print("💾 Сохраняем маппинг: Видео \(videoId.uuidString) -> Папка \(folderId?.uuidString ?? "nil")")
        print("💾 Всего маппингов: \(mappings.count)")
        
        // Сохраняем через UserDefaultsService
        userDefaultsService.save(mappings, forKey: .videoFolderMappings)
    }
    
    /// Загрузить все связи видео-папка из UserDefaults
    private func loadAllFolderMappings() -> [VideoFolderMapping] {
        return userDefaultsService.load([VideoFolderMapping].self, forKey: .videoFolderMappings) ?? []
    }
    
    /// Удалить связь видео-папка при удалении видео
    private func removeFolderMapping(videoId: UUID) {
        var mappings = loadAllFolderMappings()
        mappings.removeAll { $0.videoId == videoId.uuidString }
        userDefaultsService.save(mappings, forKey: .videoFolderMappings)
    }
    
    /// Загрузить сохраненные видео (приватный метод для инициализации)
    private func loadSavedVideos() {
        let videoFiles = getFiles(withExtensions: ["mp4", "mov", "avi"])
        
        // Загружаем маппинги папок
        let mappings = loadAllFolderMappings()
        let mappingsDict = Dictionary(uniqueKeysWithValues: mappings.map { ($0.videoId, $0.folderId) })
        
        print("📁 Загружено маппингов из UserDefaults: \(mappings.count)")
        mappings.forEach { print("  📌 Видео: \($0.videoId) -> Папка: \($0.folderId ?? "nil")") }
        
        savedVideos = videoFiles.map { fileInfo in
            let platform = VideoPlatform.extractFromFileName(fileInfo.fileName)
            
            // Проверяем, есть ли сохраненная связь с папкой
            let folderIdString = mappingsDict[fileInfo.id.uuidString]
            let folderId = folderIdString?.flatMap { UUID(uuidString: $0) }
            
            if folderId != nil {
                print("  ✅ Видео \(fileInfo.fileName) восстановлено в папку \(folderId!.uuidString)")
            }
            
            return SavedVideo(from: fileInfo, platform: platform, folderId: folderId)
        }
        
        print("📁 Загружено сохраненных видео: \(savedVideos.count)")
        print("📁 Видео в папках: \(savedVideos.filter { $0.folderId != nil }.count)")
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

