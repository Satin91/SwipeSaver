//
//  BrowserFavoriteItem.swift
//  UntraX
//
//  Created by Артур Кулик on 26.10.2025.
//

import Foundation

/// Модель для избранных страниц
struct BrowserFavoriteItem: Codable, Identifiable, Equatable {
    let id: UUID
    let url: String
    let title: String
    let description: String?
    let siteName: String?
    let previewImageURL: String?
    let ogImageURL: String?
    let faviconURL: String?
    let addedDate: Date
    
    var hasLargePreview: Bool {
        previewImageURL != nil
    }
    
    init(
        url: String,
        title: String,
        description: String? = nil,
        siteName: String? = nil,
        previewImageURL: String? = nil,
        ogImageURL: String? = nil,
        faviconURL: String? = nil
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.description = description
        self.siteName = siteName
        self.previewImageURL = previewImageURL
        self.ogImageURL = ogImageURL
        self.faviconURL = faviconURL
        self.addedDate = Date()
    }
}
