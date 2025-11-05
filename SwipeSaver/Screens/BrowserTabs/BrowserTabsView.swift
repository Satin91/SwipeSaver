//
//  BrowserTabsView.swift
//  UntraX
//
//  Created by Артур Кулик on 29.10.2025.
//

import SwiftUI

struct BrowserTabsView: View {
    @StateObject private var interactor = Executor.webViewInteractor
    
    let onSwitchTab: (UUID) -> Void
    
    @State private var isContentLoaded = true
    @State private var newTabURL = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var filteredSuggestions: [BrowserHistoryItem] = []
    
    private var tabsRepository: BrowserTabsRepository {
        interactor.browserTabsRepository
    }
    
    var body: some View {
        content
            .onAppear {
                print("🔄 [BrowserTabsView] Экран появился - создаем снимки")
                
                // Сразу создаем снимок текущей активной вкладки
                if let activeTabId = tabsRepository.activeTabId {
                    let webView = interactor.webViewStore.getWebView(for: activeTabId)
                    if webView.url != nil {
                        print("📸 [BrowserTabsView] Создаем снимок активной вкладки \(String(activeTabId.uuidString.prefix(8)))")
                        interactor.webViewStore.takeSnapshot(for: activeTabId)
                    }
                }
                
                // Затем создаем снимки для остальных вкладок
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    createSnapshotsForAllTabs()
                }
            }
            .onReceive(tabsRepository.$tabs) { tabs in
                // Обновляем снимки когда меняется список вкладок
                print("📋 [BrowserTabsView] Список вкладок обновлен: \(tabs.count) вкладок")
            }
            .onReceive(tabsRepository.$activeTabId) { _ in }
    }
    
    var content: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HeaderView(
                    title: "Tabs",
                    isContentLoaded: true,
                    onClose: {
                        // Закрываем через callback
                        onSwitchTab(tabsRepository.activeTabId ?? UUID())
                    }
                ) { }
                tabsList
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Убираем фокус при тапе на область вкладок
                        if isTextFieldFocused {
                            isTextFieldFocused = false
                        }
                    }
                Spacer()
                    .frame(height: 88) // Место для текстового поля
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Убираем фокус при тапе на Spacer
                        if isTextFieldFocused {
                            isTextFieldFocused = false
                        }
                    }
            }
            
            // TextField и Suggestions внизу экрана
            VStack(spacing: 0) {
                // Suggestions НАД текстовым полем
                if isTextFieldFocused && !filteredSuggestions.isEmpty {
                    AddressBarSuggestionsView(
                        suggestions: filteredSuggestions,
                        searchText: newTabURL,
                        onSelectSuggestion: { suggestion in
                            newTabURL = suggestion.url
                            createTabWithURL()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: filteredSuggestions.count)
                }
                
                // TextField для быстрого создания вкладки
                quickAddTextField
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.tm.background)
            }
        }
        .background(Color.tm.background)
        .onChange(of: newTabURL) { _, newValue in
            if isTextFieldFocused {
                updateSuggestions()
            }
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if focused {
                updateSuggestions()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    filteredSuggestions = []
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var tabsList: some View {
        Group {
            if tabsRepository.tabs.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(tabsRepository.tabs, id: \.id) { tab in
                            TabCardView(
                                tab: tab,
                                webViewStore: interactor.webViewStore,
                                isActive: tabsRepository.activeTabId == tab.id,
                                onTap: {
                                    print("🔵 Нажали на вкладку: \(tab.id) - \(tab.title)")
                                    
                                    // Создаем снимок текущей активной вкладки перед переключением
                                    // Только если она загружена
                                    if let currentActiveTabId = tabsRepository.activeTabId {
                                        let webView = interactor.webViewStore.getWebView(for: currentActiveTabId)
                                        if webView.url != nil {
                                            interactor.webViewStore.takeSnapshot(for: currentActiveTabId)
                                        }
                                    }
                                    
                                    interactor.switchToTab(tab.id)
                                    onSwitchTab(tab.id)  // Вызываем callback
                                },
                                onDelete: {
                                    print("🗑️ Удаляем вкладку: \(tab.id)")
                                    withAnimation {
                                        interactor.deleteTab(tab.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .opacity(isContentLoaded ? 1 : 0)
//                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isContentLoaded)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 60))
                .foregroundColor(.tm.subTitle.opacity(0.3))
            
            Text("No tabs")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.tm.title.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var quickAddTextField: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tm.accent)
                
                TextField("Enter URL to create new tab", text: $newTabURL)
                    .font(.system(size: 15))
                    .foregroundColor(.tm.title)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .focused($isTextFieldFocused)
                    .submitLabel(.go)
                    .onSubmit {
                        createTabWithURL()
                    }
                
                if !newTabURL.isEmpty {
                    Button(action: {
                        newTabURL = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.tm.subTitle.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tm.container.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isTextFieldFocused ? Color.tm.accent.opacity(0.3) : Color.tm.border.opacity(0.2),
                                lineWidth: isTextFieldFocused ? 2 : 1
                            )
                    )
            )
            
            if !newTabURL.isEmpty {
                Button(action: {
                    createTabWithURL()
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.tm.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(isContentLoaded ? 1 : 0)
        .offset(y: isContentLoaded ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: isContentLoaded)
    }
    
    // MARK: - Actions
    
    private func createTabWithURL() {
        guard !newTabURL.isEmpty else { return }
        
        let urlToLoad = newTabURL
        
        // Создаем новую вкладку
        let newTab = interactor.createNewTab(title: "New Tab", url: urlToLoad)
        
        // Переключаемся на новую вкладку
        interactor.switchToTab(newTab.id)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            interactor.goToUrl(string: urlToLoad)
        }
        // Загружаем URL через goToUrl для корректной обработки
        
        
        // Очищаем поле и закрываем
        newTabURL = ""
        isTextFieldFocused = false
        filteredSuggestions = []
        onSwitchTab(newTab.id)
        
        print("✅ [BrowserTabsView] Создана вкладка с URL: \(urlToLoad)")
    }
    
    // MARK: - Suggestions Logic
    
    /// Обновляет список подсказок на основе введенного текста
    private func updateSuggestions() {
        // Если текст пустой или слишком короткий, не показываем подсказки
        guard !newTabURL.trimmingCharacters(in: .whitespaces).isEmpty,
              newTabURL.count >= 1 else {
            filteredSuggestions = []
            return
        }
        
        // Получаем историю браузера
        let browserHistory = interactor.getBrowserHistory()
        
        // Фильтруем историю по введенному тексту
        let filtered = browserHistory.filtered(by: newTabURL)
        
        // Удаляем дубликаты по URL (оставляем самый свежий)
        var uniqueURLs = [String: BrowserHistoryItem]()
        for item in filtered {
            // Если URL ещё нет или текущий элемент новее
            if let existing = uniqueURLs[item.url] {
                if item.visitDate > existing.visitDate {
                    uniqueURLs[item.url] = item
                }
            } else {
                uniqueURLs[item.url] = item
            }
        }
        
        // Сортируем по релевантности и дате
        filteredSuggestions = Array(uniqueURLs.values)
            .sorted { item1, item2 in
                // Приоритет: точное совпадение в начале > совпадение в середине > дата
                let search = newTabURL.lowercased()
                
                let title1 = item1.title.lowercased()
                let url1 = item1.url.lowercased()
                let domain1 = item1.domain.lowercased()
                
                let title2 = item2.title.lowercased()
                let url2 = item2.url.lowercased()
                let domain2 = item2.domain.lowercased()
                
                // Проверяем точное совпадение в начале
                let startsWithTitle1 = title1.hasPrefix(search)
                let startsWithTitle2 = title2.hasPrefix(search)
                
                if startsWithTitle1 != startsWithTitle2 {
                    return startsWithTitle1
                }
                
                let startsWithDomain1 = domain1.hasPrefix(search)
                let startsWithDomain2 = domain2.hasPrefix(search)
                
                if startsWithDomain1 != startsWithDomain2 {
                    return startsWithDomain1
                }
                
                let startsWithUrl1 = url1.hasPrefix(search)
                let startsWithUrl2 = url2.hasPrefix(search)
                
                if startsWithUrl1 != startsWithUrl2 {
                    return startsWithUrl1
                }
                
                // Если все одинаково, сортируем по дате (новые первые)
                return item1.visitDate > item2.visitDate
            }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Snapshots
    
    /// Создает снимки для всех вкладок (только для загруженных)
    private func createSnapshotsForAllTabs() {
        let activeTabId = tabsRepository.activeTabId
        
        for tab in tabsRepository.tabs {
            // Пропускаем активную вкладку (её снимок уже создан)
            if tab.id == activeTabId {
                continue
            }
            
            // Проверяем, загружена ли вкладка
            let webView = interactor.webViewStore.getWebView(for: tab.id)
            if webView.url != nil {
                // Создаем снимок сразу без задержки
                self.interactor.webViewStore.takeSnapshot(for: tab.id)
                print("📸 [BrowserTabsView] Создан снимок для вкладки \(String(tab.id.uuidString.prefix(8)))")
            } else {
                print("⏸️ [BrowserTabsView] Пропускаем создание снимка для незагруженной вкладки \(String(tab.id.uuidString.prefix(8)))")
            }
        }
    }
}

// MARK: - Tab Card View

struct TabCardView: View {
    let tab: BrowserTab
    @ObservedObject var webViewStore: WebViewStore
    let isActive: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    // Получаем реальные данные из WebView
    private var webViewInfo: (url: String?, title: String?)? {
        webViewStore.getWebViewInfo(for: tab.id)
    }
    
    // Получаем снимок экрана напрямую из Published snapshots
    private var snapshot: UIImage? {
        webViewStore.snapshots[tab.id]
    }
    
    // Используем title из WebView если есть, иначе из tab
    private var displayTitle: String {
        webViewInfo?.title ?? tab.title
    }
    
    // Используем URL из WebView если есть, иначе из tab
    private var displayURL: String? {
        webViewInfo?.url ?? tab.currentURL
    }
    
    // Получаем домен из URL
    private var displayDomain: String? {
        guard let urlString = displayURL,
              let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        
        // Убираем "www." если есть
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        
        return host
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Превью страницы (снимок экрана) - увеличенный размер
                ZStack(alignment: .topTrailing) {
                    if let snapshot = snapshot {
                        Image(uiImage: snapshot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 16,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 16
                                )
                            )
                    } else {
                        // Плейсхолдер если снимка нет
                        ZStack {
                            Color.tm.border.opacity(0.1)
                            
                            VStack(spacing: 6) {
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundColor(.tm.subTitle.opacity(0.3))
                                
                                Text("No preview")
                                    .font(.system(size: 11))
                                    .foregroundColor(.tm.subTitle.opacity(0.5))
                            }
                        }
                        .frame(height: 180)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 16,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 16
                            )
                        )
                    }
                    
                    // Кнопка удаления поверх превью
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 24, height: 24)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
                
                // Компактная информация о вкладке
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(displayTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.tm.title)
                            .lineLimit(1)
                        
                        Spacer(minLength: 0)
                        
                        if isActive {
                            Circle()
                                .fill(Color.tm.accent)
                                .frame(width: 5, height: 5)
                        }
                    }
                    
                    if let domain = displayDomain {
                        Text(domain)
                            .font(.system(size: 11))
                            .foregroundColor(.tm.subTitle.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.tm.container.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isActive ? Color.tm.accent.opacity(0.4) : Color.tm.border.opacity(0.2),
                                lineWidth: isActive ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BrowserTabsView(onSwitchTab: { _ in })
}

