//
//  FaviconView.swift
//  UntraX
//
//  Created by Артур Кулик on 25.10.2025.
//

import SwiftUI

/// Компонент для отображения favicon сайта
struct FaviconView: View {
    let url: URL
    let faviconURL: String?
    let ogImageURL: String?
    let type: ImageLoadType
    let size: CGFloat
    
    @StateObject private var loader = AsyncImageLoader()
    
    /// Инициализатор с полным контролем
    init(
        url: URL,
        faviconURL: String? = nil,
        ogImageURL: String? = nil,
        type: ImageLoadType = .favicon,
        size: CGFloat = 28
    ) {
        self.url = url
        self.faviconURL = faviconURL
        self.ogImageURL = ogImageURL
        self.type = type
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Favicon или дефолтная иконка
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.285, style: .continuous))
                    .transition(.scale.combined(with: .opacity))
            } else if loader.isLoading {
                // Индикатор загрузки
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color.tm.accent)
            } else {
                // Дефолтная иконка с градиентом
                Image(systemName: "globe")
                    .font(.system(size: size * 0.714, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.tm.accent.opacity(0.7),
                                Color.tm.accentSecondary.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            loader.load(
                from: url,
                faviconURL: faviconURL,
                ogImageURL: ogImageURL,
                type: type
            )
        }
        .onChange(of: url) { _, newURL in
            loader.load(
                from: newURL,
                faviconURL: faviconURL,
                ogImageURL: ogImageURL,
                type: type
            )
        }
        .onChange(of: faviconURL) { _, newFaviconURL in
            loader.load(
                from: url,
                faviconURL: newFaviconURL,
                ogImageURL: ogImageURL,
                type: type
            )
        }
        .onChange(of: ogImageURL) { _, newOGImageURL in
            loader.load(
                from: url,
                faviconURL: faviconURL,
                ogImageURL: newOGImageURL,
                type: type
            )
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Стандартные favicon
        HStack(spacing: 15) {
            FaviconView(url: URL(string: "https://github.com")!)
            FaviconView(url: URL(string: "https://apple.com")!)
            FaviconView(url: URL(string: "https://google.com")!)
        }
        
        // Разные размеры
        HStack(spacing: 15) {
            FaviconView(url: URL(string: "https://github.com")!, size: 20)
            FaviconView(url: URL(string: "https://github.com")!, size: 32)
            FaviconView(url: URL(string: "https://github.com")!, size: 48)
            FaviconView(url: URL(string: "https://github.com")!, size: 64)
        }
    }
    .padding()
}

