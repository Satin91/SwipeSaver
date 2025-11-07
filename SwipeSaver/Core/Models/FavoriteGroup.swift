//
//  FavoriteGroup.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 26.10.2025.
//

import SwiftUI

struct FavoriteGroup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var colorHex: String
    var favorites: [BrowserFavoriteItem]
    
    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        favorites: [BrowserFavoriteItem] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.favorites = favorites
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Predefined Colors

extension FavoriteGroup {
    static let colors: [String] = [
        "#0A84FF", // Blue
        "#FF453A", // Red
        "#FF9F0A", // Orange
        "#32D74B", // Green
        "#64D2FF", // Light Blue
        "#BF5AF2", // Purple
        "#FF375F", // Pink
        "#FFD60A"  // Yellow
    ]
    
    static func randomColor() -> String {
        colors.randomElement() ?? colors[0]
    }
}
