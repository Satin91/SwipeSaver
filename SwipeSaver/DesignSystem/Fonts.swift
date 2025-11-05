//
//  Fonts.swift
//  UntraX
//
//  Created by Артур Кулик on 23.10.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

extension Font {
    // MARK: - Open Runde
    public static func openRunde(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName = fontNameForWeight(weight)
        return .custom(fontName, size: size)
    }
    
    private static func fontNameForWeight(_ weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:
            return "OpenRunde-Regular"
        case .regular:
            return "OpenRunde-Regular"
        case .medium:
            return "OpenRunde-Medium"
        case .semibold:
            return "OpenRunde-Semibold"
        case .bold, .heavy, .black:
            return "OpenRunde-Bold"
        default:
            return "OpenRunde-Regular"
        }
    }
    
    // MARK: - Open Runde (explicit)
    public static func openRundeRegular(size: CGFloat) -> Font {
        return .custom("OpenRunde-Regular", size: size)
    }
    
    public static func openRundeMedium(size: CGFloat) -> Font {
        return .custom("OpenRunde-Medium", size: size)
    }
    
    public static func openRundeSemibold(size: CGFloat) -> Font {
        return .custom("OpenRunde-Semibold", size: size)
    }
    
    public static func openRundeBold(size: CGFloat) -> Font {
        return .custom("OpenRunde-Bold", size: size)
    }
    
    // MARK: - SF Pro Rounded
    public static func sfProRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    // MARK: - Preset Fonts
    
    /// Hero Title - 34pt Bold
    static var heroTitle: Font {
        return .openRunde(size: 34, weight: .bold)
    }
    
    /// Large Title - 28pt Bold
    static var largeTitle: Font {
        return .openRunde(size: 28, weight: .bold)
    }
    
    /// Section Title - 22pt Bold
    static var sectionTitle: Font {
        return .openRunde(size: 22, weight: .bold)
    }
    
    /// Title - 20pt Semibold
    static var title: Font {
        return .openRunde(size: 20, weight: .semibold)
    }
    
    /// Headline - 17pt Semibold
    static var headline: Font {
        return .openRunde(size: 17, weight: .semibold)
    }
    
    /// Body Text - 17pt Regular
    static var bodyText: Font {
        return .openRunde(size: 17, weight: .regular)
    }
    
    /// Default Text - 16pt Regular
    static var defaultText: Font {
        return .openRunde(size: 16, weight: .regular)
    }
    
    /// Secondary Text - 15pt Regular
    static var secondaryText: Font {
        return .openRunde(size: 15, weight: .regular)
    }
    
    /// Hint Text - 13pt Regular
    static var hintText: Font {
        return .openRunde(size: 13, weight: .regular)
    }
    
    /// Caption Text - 12pt Regular
    static var captionText: Font {
        return .openRunde(size: 12, weight: .regular)
    }
    
    /// Small Text - 11pt Regular
    static var smallText: Font {
        return .openRunde(size: 11, weight: .regular)
    }
    
    // MARK: - Medium Weight Fonts
    
    /// Body Text Medium - 17pt Medium
    static var bodyTextMedium: Font {
        return .openRunde(size: 17, weight: .medium)
    }
    
    /// Default Text Medium - 16pt Medium
    static var defaultTextMedium: Font {
        return .openRunde(size: 16, weight: .medium)
    }
    
    /// Secondary Text Medium - 15pt Medium
    static var secondaryTextMedium: Font {
        return .openRunde(size: 15, weight: .medium)
    }
    
    /// Hint Text Medium - 13pt Medium
    static var hintTextMedium: Font {
        return .openRunde(size: 13, weight: .medium)
    }
    
    /// Caption Text Medium - 12pt Medium
    static var captionTextMedium: Font {
        return .openRunde(size: 12, weight: .medium)
    }
    
    /// Small Text Medium - 11pt Medium
    static var smallTextMedium: Font {
        return .openRunde(size: 11, weight: .medium)
    }
}

// MARK: - Theme Font Extension
extension Font {
    static var tm: ThemeFonts {
        ThemeFonts()
    }
}

struct ThemeFonts {
    /// Hero Title - 34pt Bold
    var heroTitle: Font { .heroTitle }
    
    /// Large Title - 28pt Bold
    var largeTitle: Font { .largeTitle }
    
    /// Section Title - 22pt Bold
    var sectionTitle: Font { .sectionTitle }
    
    /// Title - 20pt Semibold
    var title: Font { .title }
    
    /// Headline - 17pt Semibold
    var headline: Font { .headline }
    
    /// Body Text - 17pt Regular
    var bodyText: Font { .bodyText }
    
    /// Default Text - 16pt Regular
    var defaultText: Font { .defaultText }
    
    /// Secondary Text - 15pt Regular
    var secondaryText: Font { .secondaryText }
    
    /// Hint Text - 13pt Regular
    var hintText: Font { .hintText }
    
    /// Caption Text - 12pt Regular
    var captionText: Font { .captionText }
    
    /// Small Text - 11pt Regular
    var smallText: Font { .smallText }
    
    // MARK: - Medium Weight
    
    /// Body Text Medium - 17pt Medium
    var bodyTextMedium: Font { .bodyTextMedium }
    
    /// Default Text Medium - 16pt Medium
    var defaultTextMedium: Font { .defaultTextMedium }
    
    /// Secondary Text Medium - 15pt Medium
    var secondaryTextMedium: Font { .secondaryTextMedium }
    
    /// Hint Text Medium - 13pt Medium
    var hintTextMedium: Font { .hintTextMedium }
    
    /// Caption Text Medium - 12pt Medium
    var captionTextMedium: Font { .captionTextMedium }
    
    /// Small Text Medium - 11pt Medium
    var smallTextMedium: Font { .smallTextMedium }
}
