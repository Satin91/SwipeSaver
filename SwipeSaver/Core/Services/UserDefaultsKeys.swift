//
//  UserDefaultsKeys.swift
//  UntraX
//
//  Created by Артур Кулик on 23.10.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Type-safe ключи для UserDefaults
enum UserDefaultsKeys: String, CaseIterable {
    case resourceAnalysis = "resource_analysis"
    case blockedResources = "blocked_resources"
    case loadedResources = "loaded_resources"
    case pageResources = "page_resources"
    case trafficStatistics = "traffic_statistics"
    case adBlockRules = "ad_block_rules"
    case isFirstLoad = "isFirstLoad"
    case appSettings = "user_settings"
    case adBlockerEnabled = "adBlockerEnabled"
    case webViewBlockedStatistics = "webViewBlockedStatistics"
    case blockingHistory = "blockingHistory"
    case onboardingCompleted = "onboardingCompleted"
    
    // Settings keys
    case basicBlock = "basicBlock"
    case blockAds = "blockAds"
    case blockTrackers = "blockTrackers"
    case blockPopups = "blockPopups"
    case security = "security"
    case enableCookies = "enableCookies"
    case enableBrowserDarkMode = "enableBrowserDarkMode"
    case enableBrowserHistory = "enableBrowserHistory"
    case browserHistory = "browserHistory"
    case startPage = "startPage"
    case lastVisitedURL = "lastVisitedURL"
    case favorites = "favorites"
    case favoriteGroups = "favoriteGroups"
    case selectedSearchEngine = "selectedSearchEngine"
    case browserTabs = "browserTabs"
    case activeTabId = "activeTabId"
    case videoFolders = "videoFolders"
    
    var key: String {
        return self.rawValue
    }
}
