//
//  QRDetector.swift
//  SwipeSaver
//
//  Created by AI Assistant on 24.10.2024.
//

import AVFoundation
import SwiftUI

// MARK: - Detected Code Type

enum DetectedCodeType {
    case qr
    case barcode(BarcodeFormat)
    
    enum BarcodeFormat {
        case ean13
        case ean8
        case code128
        case pdf417
        case other
        
        var displayName: String {
            switch self {
            case .ean13: return "EAN-13"
            case .ean8: return "EAN-8"
            case .code128: return "Code 128"
            case .pdf417: return "PDF417"
            case .other: return "Barcode"
            }
        }
    }
    
    var icon: String {
        switch self {
        case .qr:
            return "qrcode"
        case .barcode:
            return "barcode"
        }
    }
    
    var displayName: String {
        switch self {
        case .qr:
            return "QR Code"
        case .barcode(let format):
            return "Barcode " + format.displayName
        }
    }
    
    var iconColor: (Color, Color) {
        switch self {
        case .qr:
            return (Color(hex: "#6366FF"), Color(hex: "#8B5CF6"))
        case .barcode:
            return (Color(hex: "#10B981"), Color(hex: "#059669"))
        }
    }
}

/// Легковесный QR-детектор для интеграции в существующую камеру
final class QRDetector: NSObject, ObservableObject {
    @Published var detectedQRCode: String?
    @Published var qrBoundingBox: CGRect = .zero
    @Published var codeType: DetectedCodeType?
    
    private var metadataOutput: AVCaptureMetadataOutput?
    private var isEnabled = false
    private var resetTimer: Timer?
    private let resetDelay: TimeInterval = 0.5 // Сбрасываем через 0.5 секунды
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    private let queue = DispatchQueue(label: "com.swipesaver.cameraQueue")
    
    
    /// Подключает детектор к существующей AVCaptureSession
    func attach(to session: AVCaptureSession) {
        // Используем отдельную очередь для работы с session, чтобы не блокировать UI
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let output = AVCaptureMetadataOutput()
            
            // Начинаем конфигурацию (блокирует текущую очередь, но не main thread)
            session.beginConfiguration()
            
            guard session.canAddOutput(output) else {
                print("❌ Cannot add metadata output")
                session.commitConfiguration()
                return
            }
            
            session.addOutput(output)
            
            // Настраиваем delegate сразу, до commitConfiguration
            output.setMetadataObjectsDelegate(self, queue: self.queue)
            
            // Проверяем доступные типы метаданных
            let availableTypes = output.availableMetadataObjectTypes
            let supportedTypes: [AVMetadataObject.ObjectType] = [
                .qr, .ean13, .ean8, .code128, .pdf417
            ].filter { availableTypes.contains($0) }
            
            if !supportedTypes.isEmpty {
                output.metadataObjectTypes = supportedTypes
            }
            
            // Завершаем конфигурацию (на background queue)
            session.commitConfiguration()
            
            // Обновляем состояние на главном потоке
            DispatchQueue.main.async {
                self.metadataOutput = output
                self.isEnabled = true
                print("✅ QR Detector attached with types: \(supportedTypes)")
            }
        }
    }
    
    /// Отключает детектор
    func detach(from session: AVCaptureSession) {
        if let output = metadataOutput {
            session.removeOutput(output)
            metadataOutput = nil
        }
        isEnabled = false
        resetTimer?.invalidate()
        resetTimer = nil
        detectedQRCode = nil
    }
    
    /// Сброс обнаруженного кода
    func reset() {
        resetTimer?.invalidate()
        resetTimer = nil
        detectedQRCode = nil
        qrBoundingBox = .zero
        codeType = nil
    }
    
    /// Запускает таймер для автоматического сброса QR
    private func scheduleReset() {
        // Timer должен создаваться на main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.resetTimer?.invalidate()
            self.resetTimer = Timer.scheduledTimer(withTimeInterval: self.resetDelay, repeats: false) { [weak self] _ in
                self?.detectedQRCode = nil
                self?.qrBoundingBox = .zero
                self?.codeType = nil
                print("⏱️ QR code reset (out of view)")
            }
        }
    }
    
    /// Отменяет таймер сброса (QR всё еще в поле зрения)
    private func cancelReset() {
        DispatchQueue.main.async { [weak self] in
            self?.resetTimer?.invalidate()
            self?.resetTimer = nil
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRDetector: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard isEnabled else { return }
        
        // Если QR обнаружен
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            
            // Определяем тип кода
            let detectedType = determineCodeType(from: metadataObject.type)
            
            // Если это новый QR код
            if detectedQRCode != stringValue {
                // Haptic feedback на main thread
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    self.detectedQRCode = stringValue
                    self.codeType = detectedType
                    print("🔍 \(detectedType.displayName) detected: \(stringValue)")
                }
            }
            
            // Обновляем bounding box (преобразуем координаты)
            if let previewLayer = previewLayer,
               let transformedObject = previewLayer.transformedMetadataObject(for: metadataObject) {
                DispatchQueue.main.async {
                    self.qrBoundingBox = transformedObject.bounds
                }
            }
            
            // Отменяем таймер сброса (QR всё ещё в поле зрения)
            cancelReset()
            
        } else {
            // QR кодов нет в поле зрения
            print("⏱️ DEBUG: No QR in view. detectedQRCode = \(String(describing: detectedQRCode)), metadataObjects.count = \(metadataObjects.count)")
            if detectedQRCode != nil {
                print("⏱️ Scheduling reset...")
                scheduleReset()
            }
        }
    }
    
    /// Определяет тип обнаруженного кода
    private func determineCodeType(from type: AVMetadataObject.ObjectType) -> DetectedCodeType {
        switch type {
        case .qr:
            return .qr
        case .ean13:
            return .barcode(.ean13)
        case .ean8:
            return .barcode(.ean8)
        case .code128:
            return .barcode(.code128)
        case .pdf417:
            return .barcode(.pdf417)
        default:
            return .barcode(.other)
        }
    }
}

