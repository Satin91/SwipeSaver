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
    case twitter = "Twitter"
    case facebook = "Facebook"
    case vk = "VK"
    case ok = "OK"
    case rutube = "RuTube"
    case twitch = "Twitch"
    case reddit = "Reddit"
    case pinterest = "Pinterest"
    case linkedin = "LinkedIn"
    case snapchat = "Snapchat"
    case vimeo = "Vimeo"
    case dailymotion = "Dailymotion"
    case bilibili = "Bilibili"
    case telegram = "Telegram"
    case direct = "Direct" // Прямая ссылка на видео
    
    /// Определить платформу по URL
    static func detect(from url: URL) -> VideoPlatform? {
        let host = url.host?.lowercased() ?? ""
        let pathExtension = url.pathExtension.lowercased()
        
        // YouTube
        if host.contains("youtube.com") || host.contains("youtu.be") {
            return .youtube
        }
        // TikTok
        else if host.contains("tiktok.com") || host.contains("vt.tiktok.com") {
            return .tiktok
        }
        // Instagram
        else if host.contains("instagram.com") {
            return .instagram
        }
        // Twitter / X
        else if host.contains("twitter.com") || host.contains("x.com") || host.contains("t.co") {
            return .twitter
        }
        // Facebook
        else if host.contains("facebook.com") || host.contains("fb.watch") || host.contains("fb.com") {
            return .facebook
        }
        // VK
        else if host.contains("vk.com") || host.contains("vk.ru") {
            return .vk
        }
        // OK (Одноклассники)
        else if host.contains("ok.ru") || host.contains("odnoklassniki.ru") {
            return .ok
        }
        // RuTube
        else if host.contains("rutube.ru") {
            return .rutube
        }
        // Twitch
        else if host.contains("twitch.tv") {
            return .twitch
        }
        // Reddit
        else if host.contains("reddit.com") || host.contains("redd.it") {
            return .reddit
        }
        // Pinterest
        else if host.contains("pinterest.com") || host.contains("pin.it") {
            return .pinterest
        }
        // LinkedIn
        else if host.contains("linkedin.com") {
            return .linkedin
        }
        // Snapchat
        else if host.contains("snapchat.com") {
            return .snapchat
        }
        // Vimeo
        else if host.contains("vimeo.com") {
            return .vimeo
        }
        // Dailymotion
        else if host.contains("dailymotion.com") || host.contains("dai.ly") {
            return .dailymotion
        }
        // Bilibili
        else if host.contains("bilibili.com") || host.contains("b23.tv") {
            return .bilibili
        }
        // Telegram
        else if host.contains("t.me") || host.contains("telegram.org") {
            return .telegram
        }
        // Прямая ссылка на видео файл
        else if ["mp4", "mov", "avi", "mkv", "webm", "m4v", "mpg", "mpeg", "wmv", "flv", "3gp"].contains(pathExtension) {
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
        } else if lowercased.contains("twitter") || lowercased.contains("x.com") {
            return .twitter
        } else if lowercased.contains("facebook") {
            return .facebook
        } else if lowercased.contains("vk") {
            return .vk
        } else if lowercased.contains("ok") || lowercased.contains("odnoklassniki") {
            return .ok
        } else if lowercased.contains("rutube") {
            return .rutube
        } else if lowercased.contains("twitch") {
            return .twitch
        } else if lowercased.contains("reddit") {
            return .reddit
        } else if lowercased.contains("pinterest") {
            return .pinterest
        } else if lowercased.contains("linkedin") {
            return .linkedin
        } else if lowercased.contains("snapchat") {
            return .snapchat
        } else if lowercased.contains("vimeo") {
            return .vimeo
        } else if lowercased.contains("dailymotion") {
            return .dailymotion
        } else if lowercased.contains("bilibili") {
            return .bilibili
        } else if lowercased.contains("telegram") {
            return .telegram
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

