//
//  materialCard.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 07.11.2025.
//

import SwiftUI


// MARK: - Neumorphic View Modifier
struct MaterialCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let topShadowColor: Color
    let bottomShadowColor: Color
    
    init(
        cornerRadius: CGFloat = 15,
        topShadowColor: Color = .white,
        bottomShadowColor: Color = .tm.shadowColor
    ) {
        self.cornerRadius = cornerRadius
        self.topShadowColor = topShadowColor
        self.bottomShadowColor = bottomShadowColor
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Background with outer shadow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.tm.container)
                        .shadow(color: .tm.shadowColor.opacity(0.08), radius: 3, x: 0, y: 0)
                        .shadow(color: .tm.shadowColor.opacity(0.07), radius: 25, x: 0, y: 0)
                    
                    // Overlays with inner shadows
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.tm.container)
//                        .overlay(alignment: .leading) {
//                            RoundedRectangle(cornerRadius: cornerRadius)
//                                .fill(Color.clear)
//                                .stroke(
//                                    LinearGradient(
//                                        colors: [.tm.border,.tm.border,.tm.border,.tm.border, .tm.border.opacity(0.6)],
//                                        startPoint: UnitPoint(x: 0.0, y: 0.4),
//                                        endPoint: UnitPoint(x: 0.3, y: 0.9)
//                                    ),
//                                    lineWidth: 1
//                                )
//                        }
                }
            )
    }
}

// MARK: - View Extension
extension View {
    /// Применяет neumorphic стиль к View
    /// - Parameters:
    ///   - cornerRadius: Радиус скругления углов (по умолчанию 15)
    ///   - topShadowColor: Цвет верхней внутренней тени (по умолчанию белый)
    ///   - bottomShadowColor: Цвет нижней внутренней тени (по умолчанию чёрный с opacity 0.3)
    /// - Returns: View с примененным neumorphic эффектом
    func material(
        cornerRadius: CGFloat = 12,
        topShadowColor: Color = .tm.shineColor,
        bottomShadowColor: Color = .tm.shadowColor
    ) -> some View {
        self.modifier(
            MaterialCardModifier(
                cornerRadius: cornerRadius,
                topShadowColor: topShadowColor,
                bottomShadowColor: bottomShadowColor
            )
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Card")
            .fontWeight(.semibold)
            .foregroundStyle(.tm.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 60)
            .padding(.horizontal)
            .material()
            .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
//    .background(Color.tm.background)
    .background(
        ZStack(content: {
            Color.black
            LinearGradient(
                colors: [Color.accentColor,
                .tm.accentSecondary],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .opacity(0.35)
        })
        .ignoresSafeArea(.all)
    )
}

