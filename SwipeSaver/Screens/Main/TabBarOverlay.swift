//
//  TabBarOverlay.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//

import SwiftUI

struct TabItem: Identifiable {
    let id: Int
    let icon: ImageResource
    let title: String
}

struct TabBarOverlay: View {
    @Binding var selectedTab: Int
    let items: [TabItem]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                ForEach(items) { item in
                    tabButton(for: item)
                }
            }
            .frame(height: 49)
            
            // Анимированная полоска
//            animatedIndicator
        }
    }
    
    private var animatedIndicator: some View {
        GeometryReader { geometry in
            let itemWidth = geometry.size.width / CGFloat(items.count)
            let xOffset = CGFloat(selectedTab) * itemWidth + itemWidth / 2
            
            HStack(spacing: 0) {
                Spacer()
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.tm.accent,
                                Color.tm.accentSecondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 3)
                    .shadow(color: Color.tm.accent.opacity(0.6), radius: 4, x: 0, y: 0)
                    .offset(x: xOffset - geometry.size.width / 2)
                
                Spacer()
            }
        }
        .frame(height: 3)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }
    
    private func tabButton(for item: TabItem) -> some View {
        VStack(spacing: 0) {
                // Основная иконка
                Image(item.icon)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(
                        selectedTab == item.id
                        ? LinearGradient(
                            colors: [
                                Color.tm.accent,
                                Color.tm.accent.opacity(0.9),
                                Color.tm.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.tm.inactive,
                                Color.tm.inactive
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(selectedTab == item.id ? 1.05 : 1.0)
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedTab)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = item.id
            }
        }
    }
}

#Preview {
    TabBarOverlay(selectedTab: .constant(0), items: [.init(id: 0, icon: .home, title: "Title")])
}
