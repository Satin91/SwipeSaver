//
//  SocialVideoModels.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

// MARK: - Social Video Response

/// Ответ от API с информацией о видео
struct SocialVideoResponse: Codable {
    let error: Bool
    let message: String?
    let status: Int?
    let timeEnd: Int?
    let author: String?
    let duration: Int?
    let medias: [SocialMediaItem]?
    let thumbnail: String?
    let title: String?
    
    enum CodingKeys: String, CodingKey {
        case error, message, status, author, duration, medias, thumbnail, title
        case timeEnd = "time_end"
    }
}

// MARK: - Social Media Item

/// Медиа элемент (видео/аудио файл)
struct SocialMediaItem: Codable {
    let audioQuality: String?
    let audioSampleRate: String?
    let bitrate: Int?
    let duration: Int?
    let ext: String?
    let `extension`: String?
    let formatId: Int?
    let fps: Int?
    let height: Int?
    let isAudio: Bool?
    let label: String?
    let mimeType: String?
    let quality: String?
    let type: String?
    let url: String
    let width: Int?
    
    enum CodingKeys: String, CodingKey {
        case audioQuality, audioSampleRate, bitrate, duration, ext, formatId, fps, height, label, quality, type, url, width
        case mimeType = "mimeType"
        case `extension` = "extension"
        case isAudio = "is_audio"
    }
    
    /// Является ли это видео файлом
    var isVideo: Bool {
        return type?.lowercased() == "video" && (isAudio == false || isAudio == nil)
    }
    
    /// Является ли это аудио файлом (или видео с аудио)
    var hasAudio: Bool {
        return isAudio == true || audioQuality != nil
    }
    
    /// Форматированное описание качества
    var qualityDescription: String {
        if let height = height {
            return "\(height)p"
        } else if let quality = quality {
            return quality
        } else if let label = label {
            return label
        }
        return "Unknown"
    }
    
    /// Полное описание формата
    var formatDescription: String {
        let format = ext ?? "unknown"
        let quality = qualityDescription
        let hasAudioIndicator = hasAudio ? " (with audio)" : ""
        return "\(format) (\(quality))\(hasAudioIndicator)"
    }
}

// MARK: - Helper Extensions

extension SocialVideoResponse {
    /// Получить все видео файлы
    var videoFiles: [SocialMediaItem] {
        return medias?.filter { $0.isVideo } ?? []
    }
    
    /// Получить все аудио файлы
    var audioFiles: [SocialMediaItem] {
        return medias?.filter { $0.hasAudio } ?? []
    }
    
    /// Получить видео файл с наилучшим качеством
    var bestQualityVideo: SocialMediaItem? {
        return videoFiles.max(by: { ($0.height ?? 0) < ($1.height ?? 0) })
    }
    
    /// Получить видео файл со средним качеством
    var mediumQualityVideo: SocialMediaItem? {
        let videos = videoFiles.sorted(by: { ($0.height ?? 0) > ($1.height ?? 0) })
        guard videos.count > 0 else { return nil }
        
        // Если видео мало, возвращаем первое
        if videos.count <= 2 {
            return videos.first
        }
        
        // Иначе возвращаем среднее по качеству
        return videos[videos.count / 2]
    }
    
    /// Получить видео файл с наименьшим качеством
    var lowestQualityVideo: SocialMediaItem? {
        return videoFiles.min(by: { ($0.height ?? 0) < ($1.height ?? 0) })
    }
    
    /// Получить видео в формате MP4 с наилучшим качеством
    var bestMP4Video: SocialMediaItem? {
        return videoFiles
            .filter { $0.ext?.lowercased() == "mp4" }
            .max(by: { ($0.height ?? 0) < ($1.height ?? 0) })
    }
    
    /// Получить видео с аудио (полноценное видео для скачивания)
    var videoWithAudio: SocialMediaItem? {
        return videoFiles.first { $0.hasAudio }
    }
    
    /// Успешный ли ответ
    var isSuccess: Bool {
        return !error && medias != nil && !(medias?.isEmpty ?? true)
    }
    
    /// Сообщение об ошибке (если есть)
    var errorMessage: String? {
        return error ? message : nil
    }
    
    /// Форматированное описание продолжительности
    var durationFormatted: String {
        guard let duration = duration else { return "Unknown" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

