//
//  ModernLoadingIndicator.swift
//  SufrShield
//
//  Created by Артур Кулик on 03.09.2025.
//

import SwiftUI

struct ModernLoadingIndicator: View {
    let progress: Double
    
    @State private var waveOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        VStack(spacing: 0) {
            // Основной прогресс-бар
            ZStack(alignment: .leading) {
                // Фон прогресс-бара
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                .tm.container.opacity(0.3),
                                .tm.container.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 4)
                
                // Анимированный прогресс
                HStack(spacing: 0) {
                    // Градиентный прогресс
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .tm.accent,
                                    .tm.accentSecondary,
                                    .tm.accentTertiary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, progress * UIScreen.main.bounds.width))
                        .shadow(
                            color: .tm.accent.opacity(0.6),
                            radius: 4,
                            x: 0,
                            y: 0
                        )
                    
                    // Волновой эффект
                    if progress > 0 {
                        WaveEffect()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .tm.accent.opacity(0.8),
                                        .tm.accentSecondary.opacity(0.6)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 20, height: 4)
                            .offset(x: waveOffset)
                            .animation(
                                .linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                                value: waveOffset
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            // Индикатор загрузки с пульсацией
            if progress < 1.0 {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .tm.accent,
                                        .tm.accentSecondary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 6, height: 6)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: pulseScale
                            )
                            .shadow(
                                color: .tm.accent.opacity(glowIntensity),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(
            // Размытый фон для индикатора
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Запуск волновой анимации
        waveOffset = UIScreen.main.bounds.width
        
        // Запуск пульсации
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
        
        // Запуск свечения
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
}

// MARK: - Wave Effect Shape
struct WaveEffect: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let waveLength = width / 4
        let amplitude = height * 0.3
        
        path.move(to: CGPoint(x: 0, y: height / 2))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / waveLength
            let sine = sin(relativeX * .pi * 2)
            let y = height / 2 + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        ModernLoadingIndicator(progress: 0.3)
        ModernLoadingIndicator(progress: 0.7)
        ModernLoadingIndicator(progress: 1.0)
    }
    .padding()
    .background(Color.tm.background)
}
