//
//  UserDefaultsKeys.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Type-safe ключи для UserDefaults
enum UserDefaultsKeys {
    case appSettings
    case onboardingCompleted
    case isFirstLoad
    case themeMode
    
    var key: String {
        switch self {
        case .appSettings: return "appSettings"
        case .onboardingCompleted: return "onboardingCompleted"
        case .isFirstLoad: return "isFirstLoad"
        case .themeMode: return "themeMode"
        }
    }
}
