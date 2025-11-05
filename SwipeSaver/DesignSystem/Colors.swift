//
//  Colors.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

public enum ThemeColors: String {
    case accent = "Accent"
    case accentSecondary = "AccentSecondary"
    case accentTertiary = "AccentTertiary"
    case title = "Title"
    case titleSecondary = "TitleSecondary"
    case subTitle = "Subtitle"
    case background = "Background"
    case backgroundSecondary = "BackgroundSecondary"
    case container = "Container"
    case error = "Error"
    case success = "Success"
    case inactive = "Inactive"
    case shadowColor = "ShadowColor"
    case glassBorder = "GlassBorder"
    case glassOverlay = "GlassOverlay"
    
    var color: Color {
        let name = self.rawValue
        return Color(name)
    }
}

public struct Colors {
    public var accent: Color { ThemeColors.accent.color }
    public var accentSecondary: Color { ThemeColors.accentSecondary.color }
    public var accentTertiary: Color { ThemeColors.accentTertiary.color }
    public var background: Color { ThemeColors.background.color }
    public var backgroundSecondary: Color { ThemeColors.backgroundSecondary.color }
    public var container: Color { ThemeColors.container.color }
    public var error: Color { ThemeColors.error.color }
    public var success: Color { ThemeColors.success.color }
    public var title: Color { ThemeColors.title.color }
    public var titleSecondary: Color { ThemeColors.titleSecondary.color }
    public var subTitle: Color { ThemeColors.subTitle.color }
    public var inactive: Color { ThemeColors.inactive.color }
    public var shadowColor: Color { ThemeColors.shadowColor.color }
    public var glassBorder: Color { ThemeColors.glassBorder.color }
    public var glassOverlay: Color { ThemeColors.glassOverlay.color }
}

// Расширение для ShapeStyle
extension ShapeStyle where Self == Color {
    static var tm: Colors {
        Colors()
    }
}

// Расширение для Color
extension Color {
    public static var tm: Colors { Colors() }
    
    init(color: ThemeColors) {
        self = color.color
    }
}
