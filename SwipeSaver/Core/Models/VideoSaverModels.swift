//
//  VideoSaverModels.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

// MARK: - Platform

/// Тип видеоплатформы
enum VideoPlatform: String, Codable {
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case instagram = "Instagram"
    case direct = "Direct" // Прямая ссылка на видео
    
    /// Определить платформу по URL
    static func detect(from url: URL) -> VideoPlatform? {
        let host = url.host?.lowercased() ?? ""
        let pathExtension = url.pathExtension.lowercased()
        
        if host.contains("youtube.com") || host.contains("youtu.be") {
            return .youtube
        } else if host.contains("tiktok.com") {
            return .tiktok
        } else if host.contains("instagram.com") {
            return .instagram
        } else if ["mp4", "mov", "avi", "mkv", "webm", "m4v"].contains(pathExtension) {
            // Прямая ссылка на видео файл
            return .direct
        }
        
        return nil
    }
    
    /// Извлечь платформу из имени файла
    static func extractFromFileName(_ fileName: String) -> VideoPlatform? {
        let lowercased = fileName.lowercased()
        
        if lowercased.contains("youtube") {
            return .youtube
        } else if lowercased.contains("tiktok") {
            return .tiktok
        } else if lowercased.contains("instagram") {
            return .instagram
        } else if lowercased.contains("direct") {
            return .direct
        }
        
        return .direct // По умолчанию считаем прямой ссылкой
    }
}

// MARK: - Download Status

/// Статус загрузки видео
enum VideoDownloadStatus {
    case pending        // Ожидает загрузки
    case downloading    // Загружается
    case completed      // Завершено
    case failed         // Ошибка
}

// MARK: - Download Result

/// Результат загрузки видео
struct VideoDownloadResult {
    let id: UUID
    let url: URL
    let platform: VideoPlatform
    let status: VideoDownloadStatus
    let progress: Double      // 0.0 - 1.0
    let videoData: Data?      // Данные видео после загрузки
    let error: Error?         // Ошибка, если есть
    let title: String?        // Название видео
    let thumbnail: URL?       // URL превью
}

// MARK: - Errors

/// Ошибки при загрузке видео
enum VideoDownloadError: LocalizedError {
    case invalidURL
    case unsupportedPlatform
    case downloadFailed(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .unsupportedPlatform:
            return "Платформа не поддерживается"
        case .downloadFailed(let reason):
            return "Ошибка загрузки: \(reason)"
        case .networkError:
            return "Ошибка сети"
        }
    }
}

// MARK: - Saved Video

/// Модель сохраненного видео
struct SavedVideo: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let fileURL: URL
    let platform: String
    let title: String?
    let dateAdded: Date
    let fileSize: Int64
    
    /// Инициализация из FileInfo
    init(from fileInfo: FileInfo, platform: VideoPlatform?, title: String? = nil) {
        self.id = fileInfo.id
        self.fileName = fileInfo.fileName
        self.fileURL = fileInfo.fileURL
        self.platform = platform?.rawValue ?? "Unknown"
        self.title = title
        self.dateAdded = fileInfo.createdDate
        self.fileSize = fileInfo.fileSize
    }
    
    /// Стандартная инициализация
    init(id: UUID, fileName: String, fileURL: URL, platform: String, title: String?, dateAdded: Date, fileSize: Int64) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.platform = platform
        self.title = title
        self.dateAdded = dateAdded
        self.fileSize = fileSize
    }
}

