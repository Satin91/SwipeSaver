//
//  BrowserHistoryView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 25.10.2025.
//

import SwiftUI

struct BrowserHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var userDefaultsObserver = Executor.userDefaultsObserver
    @State private var searchText = ""
    @State private var isContentLoaded = false
    @State private var shouldShowHistory = false
    let onTapHistoryItem: (URL?) -> Void
//    @State private var selectedFilter: HistoryFilter = .all
//    
//    enum HistoryFilter: String, CaseIterable {
//        case all = "Все"
//        case mostVisited = "Популярные"
//        case suspicious = "Подозрительные"
//    }
    
    var body: some View {
        content
            .onAppear {
                // Задержка для плавного появления контента
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        isContentLoaded = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            shouldShowHistory = true
                        }
                    }
                }
            }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            // Header with custom search bar
            HeaderView(
                title: "History",
                isContentLoaded: isContentLoaded,
                animationDelay: 0.3,
                onClose: {
                    dismiss()
                }
            ) {
                searchBar
                    .padding(.horizontal, 20)
            }
            
            // History list
            historyList
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.background)
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        TextFieldView(
            placeholder: "Search history...",
            text: $searchText,
            icon: "magnifyingglass"
        )
        .opacity(isContentLoaded ? 1 : 0)
        .offset(y: isContentLoaded ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isContentLoaded)
    }
    
    private var historyList: some View {
        List {
            if userDefaultsObserver.isLoadingHistory || !isContentLoaded {
                loadingView
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else if filteredHistory.isEmpty {
                emptyState
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                // Все элементы в одном списке с визуальной группировкой
                ForEach(groupedHistory, id: \.section) { group in
                    Section {
                        ForEach(group.items) { item in
                            HistoryItemView(item: item) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    userDefaultsObserver.removeFromBrowserHistory(item)
                                }
                            }
                            .onTapGesture {
                                onTapHistoryItem(URL(string: item.url))
                                dismiss()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: .zero, trailing: 16))
                        }
                    } header: {
                        sectionHeader(title: group.section.rawValue)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .opacity(shouldShowHistory ? 1 : 0)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.easeOut(duration: 0.5), value: isContentLoaded)
    }
    
    
    
    // MARK: - Computed Properties
    
    /// Отфильтрованная история по поисковому запросу
    private var filteredHistory: [BrowserHistoryItem] {
        guard !searchText.isEmpty else {
            return userDefaultsObserver.browserHistory
        }
        
        return userDefaultsObserver.browserHistory.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            item.domain.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Группированная история по секциям
    private var groupedHistory: [(section: HistorySection, items: [BrowserHistoryItem])] {
        filteredHistory.groupedBySection()
    }
    
    // MARK: - UI Components
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            // Декоративная линия слева
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.tm.accent.opacity(0.6),
                            Color.tm.accentSecondary.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 4, height: 20)
            
        Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.tm.title.opacity(0.85))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Rectangle()
                .fill(Color.tm.container)
        )
    }
    
    /// Пустое состояние когда нет истории
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.tm.accent)
            
            Text("Loading history...")
                .font(.system(size: 16))
                .foregroundColor(.tm.subTitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.tm.subTitle.opacity(0.3))
            
            Text("History is empty")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.tm.title.opacity(0.7))
            
            Text("Visited pages will appear here")
                .font(.system(size: 14))
                .foregroundColor(.tm.subTitle.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    private var backgroundGradient: some View {
        let isLight = colorScheme == .light
        let opacityMultiplier: CGFloat = isLight ? 1.8 : 1.0
        
        return ZStack {
            // Основной мягкий градиент
            LinearGradient(
                colors: [
                    Color.tm.background,
                    Color.tm.backgroundSecondary.opacity(0.8),
                    Color.tm.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Улучшенный mesh-градиент эффект
            ZStack {
                // Верхний левый акцент - более яркий
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.tm.accent.opacity(0.18 * opacityMultiplier),
                                Color.tm.accent.opacity(0.10 * opacityMultiplier),
                                Color.tm.accent.opacity(0.04 * opacityMultiplier),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -120)
                    .blur(radius: 60)
                
                // Правый верхний акцент - теплый
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.tm.accentSecondary.opacity(0.15 * opacityMultiplier),
                                Color.tm.accentSecondary.opacity(0.08 * opacityMultiplier),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 280, height: 240)
                    .offset(x: 110, y: -80)
                    .blur(radius: 55)
                
                // Центральный элемент - более насыщенный
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.tm.accent.opacity(0.12 * opacityMultiplier),
                                Color.tm.accentSecondary.opacity(0.08 * opacityMultiplier),
                                Color.tm.accent.opacity(0.04 * opacityMultiplier),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 260, height: 260)
                    .offset(x: -60, y: 140)
                    .blur(radius: 65)
                
                // Нижний правый - мягкий переход
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.tm.accentSecondary.opacity(0.14 * opacityMultiplier),
                                Color.tm.accent.opacity(0.06 * opacityMultiplier),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 260)
                    .offset(x: 90, y: 250)
                    .blur(radius: 50)
                
                // Дополнительный акцент в середине справа
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.tm.accent.opacity(0.10 * opacityMultiplier),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 120
                        )
                    )
                    .frame(width: 220, height: 220)
                    .offset(x: 100, y: 80)
                    .blur(radius: 48)
                
                // Слой глубины для объема
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.tm.accent.opacity(0.06 * opacityMultiplier),
                                Color.clear,
                                Color.tm.accentSecondary.opacity(0.05 * opacityMultiplier),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 350, height: 300)
                    .offset(x: 0, y: 100)
                    .blur(radius: 70)
            }
            
            // Улучшенный оверлей для единства
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.tm.background.opacity(0.25),
                            Color.clear,
                            Color.tm.backgroundSecondary.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    BrowserHistoryView(onTapHistoryItem: { _ in })
}
