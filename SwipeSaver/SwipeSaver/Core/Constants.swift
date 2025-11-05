//
//  Constants.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

enum Constants {
    // MARK: - App Group
    static var appGroupID = "group.SwipeSaver.group"
    
    // MARK: - URLs
    static let privacyPolicyURL = "https://yourapp.com/privacy"
    static let termsOfUseURL = "https://yourapp.com/terms"
    static let appStoreLink = "https://apps.apple.com/app/id<YOUR_APP_ID>"
    
    // MARK: - API Keys
    static let apphudApiKey = "<YOUR_APPHUD_API_KEY>"
    
    // MARK: - App Info
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

