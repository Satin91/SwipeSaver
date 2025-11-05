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

