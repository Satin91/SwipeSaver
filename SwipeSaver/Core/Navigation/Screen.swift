//
//  Screen.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Перечисление всех экранов приложения
enum Screen: Hashable, Identifiable {
    case example
    
    var id: String {
        switch self {
        case .example:
            return "example"
        }
    }
    
    static func == (lhs: Screen, rhs: Screen) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .example:
            hasher.combine("example")
        }
    }
}

