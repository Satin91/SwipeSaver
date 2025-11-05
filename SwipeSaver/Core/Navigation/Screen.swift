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
    case browserHistory(onTapHistoryItem: (URL?) -> Void)
    case browserFavorites(onTapFavoriteItem: (URL?) -> Void)
    case browserTabs(onSwitchTab: (UUID) -> Void)
    case settings
    
    var id: String {
        switch self {
        case .browserHistory:
            return "BrowserHistory"
        case .browserFavorites:
            return "BrowserFavorites"
        case .browserTabs:
            return "BrowserTabs"
        case .settings:
            return "Settings"
        }
    }
    
    static func == (lhs: Screen, rhs: Screen) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(
        into hasher: inout Hasher
    ) {
        switch self {
        case .browserHistory:
            hasher.combine("browserHistory")
        case .browserFavorites:
            hasher.combine("browserFavorites")
        case .browserTabs:
            hasher.combine("browserTabs")
        case .settings:
            hasher.combine("settings")
        }
    }
}



