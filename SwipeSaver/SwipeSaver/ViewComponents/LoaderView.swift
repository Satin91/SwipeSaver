//
//  LoaderView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

// MARK: - Loader View

struct LoaderView: View {
    let message: String?
    @State private var isAnimating = false
    @State private var backgroundOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.9
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            // Затемненный фон с анимацией
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            // Контейнер с индикатором
            VStack(spacing: 20) {
                // Анимированный индикатор
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.tm.accent, .tm.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1.0)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                // Текст сообщения
                if let message = message {
                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.tm.container.opacity(0.95))
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
            )
            .scaleEffect(contentScale)
            .opacity(backgroundOpacity > 0 ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                backgroundOpacity = 0.75
                contentScale = 1.0
            }
            
            // Задержка для анимации вращения
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Loader Modifier

struct LoaderModifier: ViewModifier {
    @Binding var isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                LoaderView(message: message)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        )
                    )
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isLoading)
    }
}

// MARK: - View Extension

extension View {
    /// Show loading overlay
    /// - Parameters:
    ///   - isLoading: Binding to control loader visibility
    ///   - message: Optional message to display
    func loader(
        isLoading: Binding<Bool>,
        message: String? = nil
    ) -> some View {
        modifier(LoaderModifier(isLoading: isLoading, message: message))
    }
}

// MARK: - Preview

#Preview("Loader") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Content Below")
                .font(.title)
                .foregroundColor(.white)
            
            Button("Test Button") {}
        }
    }
    .loader(isLoading: .constant(true), message: "Loading...")
}
