//
//  FileManagerService.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Модель информации о файле
struct FileInfo: Identifiable {
    let id: UUID
    let fileName: String
    let fileURL: URL
    let fileSize: Int64
    let createdDate: Date
    let modifiedDate: Date
    let fileExtension: String
}

/// Ошибки при работе с файловой системой
enum FileManagerError: LocalizedError {
    case directoryCreationFailed
    case fileNotFound
    case deletionFailed(String)
    case saveFailed(String)
    case readFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            return "Не удалось создать директорию"
        case .fileNotFound:
            return "Файл не найден"
        case .deletionFailed(let reason):
            return "Ошибка удаления: \(reason)"
        case .saveFailed(let reason):
            return "Ошибка сохранения: \(reason)"
        case .readFailed(let reason):
            return "Ошибка чтения: \(reason)"
        }
    }
}

/// Сервис для работы с файловой системой
final class FileManagerService {
    
    // MARK: - Singleton
    static let shared = FileManagerService()
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Directory Management
    
    /// Получить путь к директории документов
    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Создать директорию если её нет
    /// - Parameter path: Путь к директории
    /// - Returns: URL созданной/существующей директории
    @discardableResult func createDirectoryIfNeeded(at path: URL) throws -> URL {
        if !fileManager.fileExists(atPath: path.path) {
            do {
                try fileManager.createDirectory(
                    at: path,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("📁 Директория создана: \(path.lastPathComponent)")
            } catch {
                print("❌ Ошибка создания директории: \(error.localizedDescription)")
                throw FileManagerError.directoryCreationFailed
            }
        }
        return path
    }
    
    /// Проверить существование файла или директории
    /// - Parameter path: Путь для проверки
    /// - Returns: true если существует
    func fileExists(at path: URL) -> Bool {
        return fileManager.fileExists(atPath: path.path)
    }
    
    // MARK: - File Operations
    
    /// Сохранить данные в файл
    /// - Parameters:
    ///   - data: Данные для сохранения
    ///   - url: URL файла
    func saveFile(data: Data, to url: URL) throws {
        do {
            try data.write(to: url)
            print("✅ Файл сохранен: \(url.lastPathComponent)")
        } catch {
            print("❌ Ошибка сохранения файла: \(error.localizedDescription)")
            throw FileManagerError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Удалить файл
    /// - Parameter url: URL файла для удаления
    func deleteFile(at url: URL) throws {
        guard fileExists(at: url) else {
            throw FileManagerError.fileNotFound
        }
        
        do {
            try fileManager.removeItem(at: url)
            print("✅ Файл удален: \(url.lastPathComponent)")
        } catch {
            print("❌ Ошибка удаления файла: \(error.localizedDescription)")
            throw FileManagerError.deletionFailed(error.localizedDescription)
        }
    }
    
    /// Удалить несколько файлов
    /// - Parameter urls: Массив URL файлов
    /// - Returns: Массив ошибок (если были)
    func deleteFiles(at urls: [URL]) -> [Error] {
        var errors: [Error] = []
        
        for url in urls {
            do {
                try deleteFile(at: url)
            } catch {
                errors.append(error)
            }
        }
        
        return errors
    }
    
    /// Переместить файл
    /// - Parameters:
    ///   - source: Исходный URL
    ///   - destination: Целевой URL
    func moveFile(from source: URL, to destination: URL) throws {
        guard fileExists(at: source) else {
            throw FileManagerError.fileNotFound
        }
        
        do {
            try fileManager.moveItem(at: source, to: destination)
            print("✅ Файл перемещен: \(source.lastPathComponent) → \(destination.lastPathComponent)")
        } catch {
            throw FileManagerError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Скопировать файл
    /// - Parameters:
    ///   - source: Исходный URL
    ///   - destination: Целевой URL
    func copyFile(from source: URL, to destination: URL) throws {
        guard fileExists(at: source) else {
            throw FileManagerError.fileNotFound
        }
        
        do {
            try fileManager.copyItem(at: source, to: destination)
            print("✅ Файл скопирован: \(source.lastPathComponent)")
        } catch {
            throw FileManagerError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - File Information
    
    /// Получить информацию о файле
    /// - Parameter url: URL файла
    /// - Returns: Информация о файле
    func getFileInfo(at url: URL) throws -> FileInfo {
        guard fileExists(at: url) else {
            throw FileManagerError.fileNotFound
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            
            let fileSize = attributes[.size] as? Int64 ?? 0
            let createdDate = attributes[.creationDate] as? Date ?? Date()
            let modifiedDate = attributes[.modificationDate] as? Date ?? Date()
            
            return FileInfo(
                id: UUID(),
                fileName: url.lastPathComponent,
                fileURL: url,
                fileSize: fileSize,
                createdDate: createdDate,
                modifiedDate: modifiedDate,
                fileExtension: url.pathExtension
            )
        } catch {
            throw FileManagerError.readFailed(error.localizedDescription)
        }
    }
    
    /// Получить список файлов в директории
    /// - Parameters:
    ///   - directory: URL директории
    ///   - extensions: Фильтр по расширениям файлов (опционально)
    /// - Returns: Массив информации о файлах
    func getFiles(in directory: URL, withExtensions extensions: [String]? = nil) throws -> [FileInfo] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // Фильтруем по расширениям если указаны
            let filteredURLs: [URL]
            if let extensions = extensions {
                filteredURLs = fileURLs.filter { url in
                    extensions.contains(url.pathExtension.lowercased())
                }
            } else {
                filteredURLs = fileURLs
            }
            
            // Получаем информацию о каждом файле
            return filteredURLs.compactMap { url in
                try? getFileInfo(at: url)
            }
        } catch {
            throw FileManagerError.readFailed(error.localizedDescription)
        }
    }
    
    /// Получить размер файла
    /// - Parameter url: URL файла
    /// - Returns: Размер в байтах
    func getFileSize(at url: URL) throws -> Int64 {
        let info = try getFileInfo(at: url)
        return info.fileSize
    }
    
    /// Получить общий размер файлов в директории
    /// - Parameter directory: URL директории
    /// - Returns: Размер в байтах
    func getTotalSize(of directory: URL) throws -> Int64 {
        let files = try getFiles(in: directory)
        return files.reduce(0) { $0 + $1.fileSize }
    }
    
    // MARK: - Utility Methods
    
    /// Форматировать размер файла в читаемый вид
    /// - Parameter bytes: Размер в байтах
    /// - Returns: Форматированная строка (например "125.5 MB")
    func formatFileSize(_ bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    /// Получить доступное место на диске
    /// - Returns: Размер в байтах
    func getAvailableDiskSpace() -> Int64? {
        do {
            let systemAttributes = try fileManager.attributesOfFileSystem(forPath: documentsDirectory.path)
            return systemAttributes[.systemFreeSize] as? Int64
        } catch {
            print("❌ Ошибка получения свободного места: \(error.localizedDescription)")
            return nil
        }
    }
}

