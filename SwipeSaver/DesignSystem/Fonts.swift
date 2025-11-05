//
//  Fonts.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

extension Font {
    // MARK: - SF Pro Text
    public static func sfProText(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
    
    // MARK: - SF Pro Rounded
    public static func sfProRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    // MARK: - Preset Fonts
    
    /// Large Title - 34pt Bold
    static var largeTitle: Font {
        return .sfProText(size: 34, weight: .bold)
    }
    
    /// Title - 28pt Bold
    static var title: Font {
        return .sfProText(size: 28, weight: .bold)
    }
    
    /// Title 2 - 22pt Bold
    static var title2: Font {
        return .sfProText(size: 22, weight: .bold)
    }
    
    /// Title 3 - 20pt Semibold
    static var title3: Font {
        return .sfProText(size: 20, weight: .semibold)
    }
    
    /// Headline - 17pt Semibold
    static var headline: Font {
        return .sfProText(size: 17, weight: .semibold)
    }
    
    /// Body - 17pt Regular
    static var body: Font {
        return .sfProText(size: 17, weight: .regular)
    }
    
    /// Callout - 16pt Regular
    static var callout: Font {
        return .sfProText(size: 16, weight: .regular)
    }
    
    /// Subheadline - 15pt Regular
    static var subheadline: Font {
        return .sfProText(size: 15, weight: .regular)
    }
    
    /// Footnote - 13pt Regular
    static var footnote: Font {
        return .sfProText(size: 13, weight: .regular)
    }
    
    /// Caption - 12pt Regular
    static var caption: Font {
        return .sfProText(size: 12, weight: .regular)
    }
    
    /// Caption 2 - 11pt Regular
    static var caption2: Font {
        return .sfProText(size: 11, weight: .regular)
    }
}
