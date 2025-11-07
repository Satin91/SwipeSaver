//
//  AnimatedHeaderView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 26.10.2025.
//

import SwiftUI

struct HeaderView<Content: View>: View {
    let title: String
    let onClose: () -> Void
    let externalIsContentLoaded: Bool?
    let animationDelay: Double
    @ViewBuilder let customContent: () -> Content
    
    // Internal state for automatic animation
    @State private var internalIsContentLoaded: Bool = false
    
    // Computed property to use external or internal state
    private var isContentLoaded: Bool {
        externalIsContentLoaded ?? internalIsContentLoaded
    }
    
    init(
        title: String,
        isContentLoaded: Bool? = nil,
        animationDelay: Double = 0.3,
        onClose: @escaping () -> Void,
        @ViewBuilder customContent: @escaping () -> Content
    ) {
        self.title = title
        self.externalIsContentLoaded = isContentLoaded
        self.animationDelay = animationDelay
        self.onClose = onClose
        self.customContent = customContent
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with title and buttons
            HStack(spacing: 16) {
                // Title with smooth animation
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.tm.title)
                        .shadow(color: Color.tm.accent.opacity(0.1), radius: 8, x: 0, y: 2)
                    
//                    // Subtle underline accent
//                    if isContentLoaded {
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(
//                                LinearGradient(
//                                    colors: [
//                                        Color.tm.accent.opacity(0.6),
//                                        Color.tm.accentSecondary.opacity(0.4),
//                                        Color.clear
//                                    ],
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                )
//                            )
//                            .frame(width: 60, height: 3)
//                            .transition(.scale(scale: 0, anchor: .leading).combined(with: .opacity))
//                    }
                }
                .opacity(isContentLoaded ? 1 : 0)
                .offset(y: isContentLoaded ? 0 : -10)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isContentLoaded)
                
                Spacer()
                
                // Close button
                closeButton
                    .opacity(isContentLoaded ? 1 : 0)
                    .offset(x: isContentLoaded ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isContentLoaded)
            }
            .padding(.horizontal, 20)
            .padding(.top, .medium)
            .padding(.bottom, .large)
            
            // Custom content area (SearchBar or any other view)
            customContent()
//                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(
            ZStack {
                // Blurred background
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.tm.background.opacity(0.7),
                        Color.tm.background.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .top)
        )
        .onAppear {
            // If external state is not provided, trigger internal animation
            if externalIsContentLoaded == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation {
                        internalIsContentLoaded = true
                    }
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var closeButton: some View {
        Button(action: onClose) {
            ZStack {
                // Soft background
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.tm.container.opacity(0.7))
                    .frame(width: 36, height: 36)
                
                // Subtle border
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        Color.tm.subTitle.opacity(0.15),
                        lineWidth: 1
                    )
                    .frame(width: 36, height: 36)
                
                // Icon
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tm.subTitle.opacity(0.7))
            }
            .shadow(color: Color.tm.shadowColor.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - No Custom Content Initializer

extension HeaderView where Content == EmptyView {
    init(
        title: String,
        isContentLoaded: Bool? = nil,
        animationDelay: Double = 0.3,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.externalIsContentLoaded = isContentLoaded
        self.animationDelay = animationDelay
        self.onClose = onClose
        self.customContent = { EmptyView() }
    }
}

// MARK: - Preview

#Preview("With External State") {
    ZStack {
        Color.tm.background
            .ignoresSafeArea()
        
        VStack {
            HeaderView(
                title: "History",
                isContentLoaded: true,
                onClose: {}
            ) {
                // Example search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.tm.accent)
                    Text("Search...")
                        .foregroundColor(.tm.subTitle)
                    Spacer()
                }
                .padding()
                .background(Color.tm.container.opacity(0.6))
                .cornerRadius(14)
            }
            
            Spacer()
        }
    }
}

#Preview("With Auto Animation") {
    ZStack {
        Color.tm.background
            .ignoresSafeArea()
        
        VStack {
            HeaderView(
                title: "Settings",
                animationDelay: 0.5,
                onClose: {}
            ) {
                // Example custom content
                Text("Auto-animated header")
                    .foregroundColor(.tm.subTitle)
                    .padding()
            }
            
            Spacer()
        }
    }
}

