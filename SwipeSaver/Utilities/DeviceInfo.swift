//
//  DeviceInfo.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import SwiftUI

/// Сервис для получения информации о девайсе
/// Содержит характеристики устройства, размеры экрана и другие параметры
final class DeviceInfo: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var screenSize: CGSize
    @Published private(set) var isSmallScreen: Bool
    @Published private(set) var screenWidth: CGFloat
    @Published private(set) var screenHeight: CGFloat
    
    // MARK: - Constants
    private let smallScreenThreshold: CGFloat = 375
    
    // MARK: - Computed Properties
    
    /// Тип устройства по размеру экрана
    var deviceType: DeviceType {
        if screenWidth <= 320 {
            return .small // iPhone SE 1st gen
        } else if screenWidth <= 375 {
            return .compact // iPhone SE 2/3, iPhone 8
        } else if screenWidth <= 390 {
            return .regular // iPhone 13, 14
        } else if screenWidth <= 430 {
            return .large // iPhone Pro Max
        } else {
            return .extraLarge // iPad
        }
    }
    
    /// Является ли устройство iPad
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Является ли устройство iPhone
    var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Модель устройства
    var deviceModel: String {
        UIDevice.current.model
    }
    
    /// Safe area insets
    var safeAreaInsets: UIEdgeInsets {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets ?? .zero
    }
    
    // MARK: - Initialization
    
    init() {
        let screen = UIScreen.main.bounds
        self.screenSize = screen.size
        self.screenWidth = screen.width
        self.screenHeight = screen.height
        self.isSmallScreen = screen.width <= smallScreenThreshold
        
        // Подписываемся на изменения ориентации
        setupOrientationObserver()
    }
    
    // MARK: - Private Methods
    
    private func setupOrientationObserver() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateScreenInfo()
        }
    }
    
    private func updateScreenInfo() {
        let screen = UIScreen.main.bounds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.screenSize = screen.size
            self.screenWidth = screen.width
            self.screenHeight = screen.height
            self.isSmallScreen = screen.width <= self.smallScreenThreshold
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Device Type Enum

enum DeviceType {
    case small      // ≤ 320pt (iPhone SE 1st gen)
    case compact    // ≤ 375pt (iPhone SE 2/3, iPhone 8, iPhone 12/13 mini)
    case regular    // ≤ 390pt (iPhone 13, 14)
    case large      // ≤ 430pt (iPhone Pro Max)
    case extraLarge // > 430pt (iPad)
    
    var name: String {
        switch self {
        case .small: return "Small"
        case .compact: return "Compact"
        case .regular: return "Regular"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}
