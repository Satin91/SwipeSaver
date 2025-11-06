//
//  VideoWatermarkService.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//

import AVFoundation
import UIKit

enum WatermarkPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
    
    func offset(videoSize: CGSize, watermarkSize: CGSize, padding: CGFloat = 20) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: padding, y: padding)
        case .topRight:
            return CGPoint(x: videoSize.width - watermarkSize.width - padding, y: padding)
        case .bottomLeft:
            return CGPoint(x: padding, y: videoSize.height - watermarkSize.height - padding)
        case .bottomRight:
            return CGPoint(x: videoSize.width - watermarkSize.width - padding, y: videoSize.height - watermarkSize.height - padding)
        case .center:
            return CGPoint(x: (videoSize.width - watermarkSize.width) / 2, y: (videoSize.height - watermarkSize.height) / 2)
        }
    }
}

struct WatermarkConfiguration {
    var text: String = "SwipeSaver"
    var fontSize: CGFloat = 24
    var textColor: UIColor = .white
    var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5)
    var opacity: Float = 0.7
    var position: WatermarkPosition = .bottomRight
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    static var `default`: WatermarkConfiguration {
        return WatermarkConfiguration()
    }
}

final class VideoWatermarkService {
    
    // MARK: - Public Methods
    
    /// Применить водяной знак к видео
    /// - Parameters:
    ///   - videoURL: URL исходного видео
    ///   - configuration: Конфигурация водяного знака
    /// - Returns: URL обработанного видео с водяным знаком
    func applyWatermark(
        to videoURL: URL,
        configuration: WatermarkConfiguration = .default
    ) async throws -> URL {
        
        print("🎬 Начинаем наложение водяного знака...")
        
        // Создаем AVAsset из видео
        let asset = AVAsset(url: videoURL)
        
        // Проверяем, что видео содержит видео-трек
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw WatermarkError.noVideoTrack
        }
        
        // Получаем параметры видео
        let videoSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let duration = try await asset.load(.duration)
        
        // Определяем корректный размер с учетом трансформации (для портретного видео)
        let actualVideoSize = videoSize.applying(preferredTransform)
        let correctedSize = CGSize(
            width: abs(actualVideoSize.width),
            height: abs(actualVideoSize.height)
        )
        
        // Создаем композицию
        let composition = AVMutableComposition()
        
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw WatermarkError.compositionCreationFailed
        }
        
        // Копируем видео трек
        try await compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: videoTrack,
            at: .zero
        )
        
        compositionVideoTrack.preferredTransform = preferredTransform
        
        // Добавляем аудио треки, если они есть
        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
            if let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) {
                try? await compositionAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: audioTrack,
                    at: .zero
                )
            }
        }
        
        // Создаем watermark layer
        let watermarkLayer = createWatermarkLayer(
            configuration: configuration,
            videoSize: correctedSize
        )
        
        // Создаем video layer
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: correctedSize)
        
        // Создаем parent layer
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: correctedSize)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
        
        // Создаем video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = correctedSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        
        // Создаем instruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(preferredTransform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        // Экспортируем видео
        let outputURL = try await exportVideo(
            composition: composition,
            videoComposition: videoComposition
        )
        
        print("✅ Водяной знак успешно наложен!")
        return outputURL
    }
    
    // MARK: - Private Methods
    
    /// Создать слой с водяным знаком
    private func createWatermarkLayer(
        configuration: WatermarkConfiguration,
        videoSize: CGSize
    ) -> CALayer {
        
        // Создаем текстовый слой
        let textLayer = CATextLayer()
        textLayer.string = configuration.text
        textLayer.font = UIFont.systemFont(ofSize: configuration.fontSize, weight: .bold)
        textLayer.fontSize = configuration.fontSize
        textLayer.foregroundColor = configuration.textColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        
        // Вычисляем размер текста
        let textSize = (configuration.text as NSString).size(
            withAttributes: [
                .font: UIFont.systemFont(ofSize: configuration.fontSize, weight: .bold)
            ]
        )
        
        let padding: CGFloat = 16
        let layerSize = CGSize(
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )
        
        // Создаем контейнер с фоном
        let containerLayer = CALayer()
        containerLayer.frame = CGRect(origin: .zero, size: layerSize)
        containerLayer.backgroundColor = configuration.backgroundColor.cgColor
        containerLayer.cornerRadius = configuration.cornerRadius
        containerLayer.opacity = configuration.opacity
        
        // Позиционируем текст в контейнере
        textLayer.frame = CGRect(
            x: padding,
            y: (layerSize.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        containerLayer.addSublayer(textLayer)
        
        // Позиционируем watermark
        let position = configuration.position.offset(
            videoSize: videoSize,
            watermarkSize: layerSize,
            padding: configuration.padding
        )
        
        containerLayer.position = CGPoint(
            x: position.x + layerSize.width / 2,
            y: videoSize.height - position.y - layerSize.height / 2
        )
        
        return containerLayer
    }
    
    /// Экспортировать видео
    private func exportVideo(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition
    ) async throws -> URL {
        
        // Создаем временный файл для выходного видео
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // Удаляем файл, если он уже существует
        try? FileManager.default.removeItem(at: outputURL)
        
        // Создаем export session
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw WatermarkError.exportSessionCreationFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Экспортируем
        await exportSession.export()
        
        // Проверяем статус
        switch exportSession.status {
        case .completed:
            print("✅ Видео успешно экспортировано: \(outputURL.path)")
            return outputURL
            
        case .failed:
            if let error = exportSession.error {
                print("❌ Ошибка экспорта: \(error.localizedDescription)")
                throw WatermarkError.exportFailed(error)
            } else {
                throw WatermarkError.exportFailed(nil)
            }
            
        case .cancelled:
            throw WatermarkError.exportCancelled
            
        default:
            throw WatermarkError.unknownExportError
        }
    }
}

// MARK: - Errors

enum WatermarkError: LocalizedError {
    case noVideoTrack
    case compositionCreationFailed
    case exportSessionCreationFailed
    case exportFailed(Error?)
    case exportCancelled
    case unknownExportError
    
    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "Видео не содержит видео-трек"
        case .compositionCreationFailed:
            return "Не удалось создать композицию видео"
        case .exportSessionCreationFailed:
            return "Не удалось создать сессию экспорта"
        case .exportFailed(let error):
            if let error = error {
                return "Ошибка экспорта: \(error.localizedDescription)"
            }
            return "Ошибка экспорта видео"
        case .exportCancelled:
            return "Экспорт отменен"
        case .unknownExportError:
            return "Неизвестная ошибка экспорта"
        }
    }
}

