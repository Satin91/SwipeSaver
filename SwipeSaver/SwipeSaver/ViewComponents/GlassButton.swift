//
//  GlassButton.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

enum GlassButtonStyle {
    case primary
    case destructive
    
    var gradientColors: [Color] {
        switch self {
        case .primary:
            return [Color.tm.accent, Color.tm.accentSecondary]
        case .destructive:
            return [Color.tm.error, Color.tm.error.opacity(0.8)]
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary:
            return Color.tm.accent
        case .destructive:
            return Color.tm.error
        }
    }
}

struct GlassButton: View {
    let title: String
    let icon: String?
    let style: GlassButtonStyle
    let action: () -> Void
    
    init(title: String, icon: String? = nil, style: GlassButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Выполняем действие
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: style.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: style.shadowColor.opacity(0.4), radius: 15, x: 0, y: 8)
            .shadow(color: Color.tm.shadowColor.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassButton(title: "Start", icon: "play.fill", style: .primary) {
            print("Button tapped")
        }
        
        GlassButton(title: "Cancel", icon: "xmark", style: .destructive) {
            print("Cancel tapped")
        }
    }
    .padding()
    .background(Color.tm.background)
}
