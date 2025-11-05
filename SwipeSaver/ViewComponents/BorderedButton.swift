//
//  BorderedButton.swift
//  UntraX
//
//  Created by UntraX team on 29.10.2025.
//

import SwiftUI

// MARK: - Bordered View Modifier (для обычных View)

struct BorderedViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Layout.Radius.medium, style: .continuous)
                    .fill(Color.tm.container)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.Radius.medium, style: .continuous)
                            .stroke(Color.tm.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Bordered Button Style (для кнопок с анимацией)

struct BorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Layout.Radius.regular, style: .continuous)
                    .fill(Color.tm.container)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.Radius.regular, style: .continuous)
                            .stroke(Color.tm.border, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - View Extension

extension View {
    /// Применяет стиль с границей к любому View
    /// - Returns: View с фоном container и обводкой border
    func bordered() -> some View {
        self.modifier(BorderedViewModifier())
    }
    
    /// Применяет стиль кнопки с границей (только для Button)
    /// - Returns: Button с примененным стилем и анимацией нажатия
    func borderedButtonStyle() -> some View {
        self.buttonStyle(BorderedButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Пример 1: Button с анимацией
        Button(action: {}) {
            HStack {
                Image(systemName: "star.fill")
                Text("Button with animation")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .borderedButtonStyle()
        
        // Пример 2: Обычный View
        HStack {
            Image(systemName: "info.circle")
            Text("Regular View (no animation)")
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .bordered()
        
        // Пример 3: VStack как контейнер
        VStack(alignment: .leading, spacing: 8) {
            Text("Container View")
                .font(.headline)
            Text("This is a bordered container with multiple elements")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .bordered()
    }
    .padding()
    .background(Color.tm.background)
}

