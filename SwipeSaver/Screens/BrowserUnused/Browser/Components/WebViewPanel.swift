//
//  WebViewPanel.swift
//  SufrShield
//
//  Created by Артур Кулик on 03.09.2025.
//

import SwiftUI

struct WebViewPanel: View {
    @State private var currentURL = "https://google.com"
    @State private var showProgress = false
    @State private var showMenu = false
    
    var observables: WebViewObservables
    
    // Closures для внешних действий
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onGoToURL: (String) -> Void
    let onShowTabs: () -> Void
    let onTapMenu: (CGRect) -> Void
    let onShare: (String) -> Void
    let onHistory: () -> Void
    let onFavorites: () -> Void
    let onStats: () -> Void
    let onTheme: () -> Void
    let onCamera: () -> Void
    let onAdvancedOptions: (FavoriteGroup) -> Void
    
    init(
        observables: WebViewObservables,
        onGoBack: @escaping () -> Void = {},
        onGoForward: @escaping () -> Void = {},
        onGoToURL: @escaping (String) -> Void = { _ in },
        onShowTabs: @escaping () -> Void = {},
        onTapMenu: @escaping (CGRect) -> Void = { _ in },
        onTapFavorits: @escaping (FavoriteGroup) -> Void = { _ in },
        onShare: @escaping (String) -> Void = { _ in },
        onHistory: @escaping () -> Void = {},
        onFavorites: @escaping () -> Void,
        onStats: @escaping () -> Void = {},
        onTheme: @escaping () -> Void = {},
        onCamera: @escaping () -> Void = {}
    ) {
        self.observables = observables
        self.onGoBack = onGoBack
        self.onGoForward = onGoForward
        self.onGoToURL = onGoToURL
        self.onTapMenu = onTapMenu
        self.onShowTabs = onShowTabs
        self.onAdvancedOptions = onTapFavorits
        self.onShare = onShare
        self.onHistory = onHistory
        self.onFavorites = onFavorites
        self.onStats = onStats
        self.onTheme = onTheme
        self.onCamera = onCamera
    }
    
    @State var isFocused: Bool = false
    @State private var panelHeight: CGFloat = 0
    @State private var displayText: String = ""
    @State private var filteredSuggestions: [BrowserHistoryItem] = []
    @State private var menuButtonFrame: CGRect = .zero
    
    var body: some View {
        content
            .offset(y: observables.shouldShowPanels ? 0 : -panelHeight)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: observables.shouldShowPanels)
            .onChange(of: observables.progress) { _, newProgress in
                handleProgressChange(newProgress)
            }
            .onChange(of: observables.shouldShowPanels) { _, new in
                if !new && isFocused { isFocused = false }
            }
    }
    
    // MARK: - Main Content
    
    private var content: some View {
        VStack(spacing: 0) {
//            if observables.shouldShowPanels {
                navigationBar
                    .opacity(observables.shouldShowPanels ? 1 : 0)
                    .animation(.easeOut(duration: 0.15), value: observables.shouldShowPanels)
                
                // Подсказки под адресной строкой - всегда в стеке
                AddressBarSuggestionsView(
                    suggestions: filteredSuggestions,
                    searchText: displayText,
                    onSelectSuggestion: { suggestion in
                        displayText = suggestion.url
                        onGoToURL(suggestion.url)
                        isFocused = false
                    }
                )
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: (isFocused && !filteredSuggestions.isEmpty) ? .infinity : 0)
                .clipped()
                .opacity((isFocused && !filteredSuggestions.isEmpty) ? 1 : 0)
                
                menuGrid
                    .opacity(observables.shouldShowPanels ? 1 : 0)
                    .animation(.easeOut(duration: 0.15), value: observables.shouldShowPanels)
//            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused && !filteredSuggestions.isEmpty)
        .frame(height: observables.shouldShowPanels ? nil : 1)
        .frame(maxWidth: .infinity)
//        .background(Color.tm.background)
        .overlay(alignment: .bottom) { bottomBorder }
        .overlay(alignment: .bottom) { progressIndicator }
        .background { menuBackgroundTap }
//        .neumorphic()
        .background( .tm.background )
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack(spacing: 12) {
            navigationButtons
            addressBar
            trailingButtons
        }
        .animation(.easeInOut(duration: 0.4), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showMenu)
        .animation(.easeInOut(duration: 0.3), value: observables.isDarkThemeEnabled)
        .padding(.horizontal, .regular)
        .padding(.top, .regular)
        .padding(.bottom, showMenu ? .medium : .regular)
    }
    
    private var navigationButtons: some View {
        Group {
            if !isFocused {
                HStack(spacing: 8) {
                    WebViewNavigationButton(.back, isEnabled: observables.canGoBack, action: onGoBack)
                    WebViewNavigationButton(.forward, isEnabled: observables.canGoForward, action: onGoForward)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity).animation(.easeInOut(duration: 0.25).delay(0.25)),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
    
    private var addressBar: some View {
        AddressBarView(
            urlText: observables.url.absoluteString,
            favoriteGroups: observables.favoriteGroups,
            browserHistory: Executor.webViewInteractor.getBrowserHistory(),
            onGoAction: onGoToURL,
            onTapLeadingButton: onAdvancedOptions,
            isFocused: $isFocused,
            displayText: $displayText,
            filteredSuggestions: $filteredSuggestions
        )
    }
    
    private var trailingButtons: some View {
        Group {
            if !isFocused {
                WebViewNavigationButton(.tabs) {
                    onShowTabs()
                }
                WebViewNavigationButton(.menu) {
                    onTapMenu(menuButtonFrame)
                }
            }
        }
        .background(
            GeometryReader { geometry in
                let frame = geometry.frame(in: .global)
                Color.clear
                    .task(id: frame) {
                        menuButtonFrame = frame
                    }
            }
        )
        .transition(.asymmetric(
            insertion: .move(edge: .trailing)
                .animation(.easeInOut(duration: 0.8).delay(0))
                .combined(with: .opacity).animation(.easeInOut(duration: 0.25).delay(0.25)),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
    
    // MARK: - Menu Grid
    
    private var menuGrid: some View {
        Group {
            if showMenu {
                HStack(spacing: 10) {
                    favoritesButton
                    historyButton
                    statsButton
                    shareButton
                    themeToggleButton
                    cameraButton
                }
                .padding(.horizontal, .regular)
                .padding(.bottom, .regularExt)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
    
    private var favoritesButton: some View {
        MenuIconButton(icon: "star", isDarkMode: observables.isDarkThemeEnabled) {
            // TODO: Favorites
            onFavorites()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMenu = false
            }
        }
    }
    
    private var historyButton: some View {
        MenuIconButton(icon: "clock", isDarkMode: observables.isDarkThemeEnabled) {
            // TODO: History
            onHistory()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMenu = false
            }
        }
    }
    
    private var statsButton: some View {
        MenuIconButton(icon: "chart.bar", isDarkMode: observables.isDarkThemeEnabled) {
            onStats()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMenu = false
            }
        }
    }
    
    private var shareButton: some View {
        MenuIconButton(icon: "square.and.arrow.up", isDarkMode: observables.isDarkThemeEnabled) {
            onShare(currentURL)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMenu = false
            }
        }
    }
    
    private var themeToggleButton: some View {
        MenuIconToggleButton(
            icon: "sun.max.fill",
            isOn: observables.isDarkThemeEnabled
        ) {
            onTheme()
        }
    }
    
    private var cameraButton: some View {
        MenuIconButton(icon: "camera", isDarkMode: observables.isDarkThemeEnabled) {
            onCamera()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMenu = false
            }
        }
    }
    
    // MARK: - Background & Overlays
    
//    private var panelBackground: some View {
//        Group {
//            .regularMaterial
//        }
//        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showMenu)
//        .animation(.easeInOut(duration: 0.3), value: observables.isDarkThemeEnabled)
//        .shadow(color: Color.tm.shadowColor.opacity(0.15), radius: 20, x: 0, y: 8)
//    }
    
    private var bottomBorder: some View {
        Rectangle()
            .fill(.tm.border.opacity(0.15))
            .frame(height: 1)
    }
    
    private var progressIndicator: some View {
        Group {
            if showProgress {
                ZStack(alignment: .leading) {
                    progressBackground
                    progressBar
                }
                .animation(.easeInOut(duration: 0.3), value: observables.progress)
            }
        }
    }
    
    private var progressBackground: some View {
        Rectangle()
            .fill(Color.tm.border.opacity(0.2))
            .frame(height: 3)
    }
    
    private var progressBar: some View {
        Rectangle()
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
            .frame(width: UIScreen.main.bounds.width * observables.progress, height: 3)
            .shadow(color: Color.tm.accent.opacity(0.5), radius: 4, x: 0, y: 0)
    }
    
    private var menuBackgroundTap: some View {
        Group {
            if showMenu {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
                    .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleProgressChange(_ newProgress: Double) {
        if newProgress > 0 {
            showProgress = true
        }
        
        if newProgress >= 1.0 {
            // Задержка перед исчезновением, чтобы показать полную загрузку
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.05)) {
                    showProgress = false
                }
            }
        }
    }
}

// MARK: - Menu Icon Components

/// Компактная иконочная кнопка для меню
struct MenuIconButton: View {
    let icon: String
    let isDarkMode: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(Color.tm.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .contentShape(Rectangle())
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .opacity(isPressed ? 0.6 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

/// Компактная иконочная кнопка-переключатель для Dark Theme
struct MenuIconToggleButton: View {
    let icon: String
    let isOn: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(isOn ? Color.tm.inactive : Color.tm.accent)
                    .animation(.easeInOut(duration: 0.2), value: isOn) // Анимация только цвета
                
                // Диагональная черта когда Dark Mode включен (без анимации)
                if isOn {
                    Rectangle()
                        .fill(Color.tm.inactive)
                        .frame(width: 2, height: 28)
                        .rotationEffect(.degrees(45))
                        .transition(.identity) // Без анимации появления/исчезновения
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .opacity(isPressed ? 0.6 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed) // Анимация только для нажатия
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Suggestions Height Preference Key

struct SuggestionsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview(body: {
    WebViewPanel(observables: Executor.webViewInteractor, onFavorites: {})
})
