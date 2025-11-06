//
//  WebViewForTab.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 29.10.2025.
//

import SwiftUI
import WebKit
import Combine

/// WebView привязанный к конкретной вкладке
struct WebViewForTab: UIViewRepresentable {
    @ObservedObject var interactor: WebViewInteractor
    let tabId: UUID
    
    func makeUIView(context: Context) -> WKWebView {
        print("🎨 [WebViewForTab] makeUIView для вкладки \(String(tabId.uuidString.prefix(8)))")
        
        // Сохраняем coordinator для этой вкладки
        interactor.webViewStore.setCoordinator(context.coordinator, for: tabId)
        
        // Получаем WebView из хранилища для этой конкретной вкладки
        let webView = interactor.webViewStore.getWebView(for: tabId)
        
        // Проверяем, был ли WebView уже настроен
        let isAlreadyConfigured = webView.navigationDelegate != nil
        
        if !isAlreadyConfigured {
            print("⚙️ [WebViewForTab] Настраиваем новый WebView для вкладки \(String(tabId.uuidString.prefix(8)))")
            setupWebView(webView, context: context)
        } else {
            print("♻️ [WebViewForTab] Переиспользуем WebView для вкладки \(String(tabId.uuidString.prefix(8)))")
            // Обновляем coordinator
            context.coordinator.webView = webView
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Можно добавить логику обновления если нужно
    }
    
    func makeCoordinator() -> WebView.Coordinator {
        // Создаем координатор используя оригинальный WebView
        let originalWebView = WebView(interactor: interactor)
        return WebView.Coordinator(originalWebView)
    }
    
    private func setupWebView(_ webView: WKWebView, context: Context) {
        // Настройки для корректного взаимодействия с элементами страницы
        webView.isUserInteractionEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.delegate = context.coordinator
        
        // Убираем обрезание контента для ScrollView
        webView.scrollView.clipsToBounds = false
        webView.clipsToBounds = false
        
        // Устанавливаем начальный верхний contentInset для панели
        webView.scrollView.contentInset = .init(top: 0, left: 0, bottom: 180, right: 0)
        
        // Настройки для лучшей производительности и взаимодействия
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = [.video, .audio]
        
        context.coordinator.webView = webView
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Настраиваем мониторинг ресурсов после создания webView
        context.coordinator.setupResourceMonitoring()
        
        // Устанавливаем черный фон для WebView
        webView.backgroundColor = UIColor(named: "Container")
        webView.isOpaque = true
        webView.scrollView.backgroundColor = UIColor(named: "Container")
        
        // Загружаем URL только для активной вкладки
        let isActiveTab = interactor.activeTabId == tabId
        
        if webView.url == nil && isActiveTab {
            if let tab = interactor.browserTabs.first(where: { $0.id == tabId }),
               !tab.currentURL.isEmpty,
               let url = URL(string: tab.currentURL) {
                print("🔗 [WebViewForTab] Загружаем сохраненный URL для активной вкладки: \(url.absoluteString)")
                webView.load(URLRequest(url: url))
            } else {
                print("🔗 [WebViewForTab] Загружаем начальный URL для активной вкладки")
                webView.load(URLRequest(url: interactor.url))
            }
        } else if !isActiveTab {
            print("⏸️ [WebViewForTab] Пропускаем загрузку для неактивной вкладки \(String(tabId.uuidString.prefix(8)))")
        }
        
        // Добавляем наблюдатели для отслеживания состояния навигации
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.url), options: [.new], context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.new], context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoForward), options: [.new], context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new], context: nil)
        
        // Настраиваем Pull to Refresh
        context.coordinator.setupRefreshControl(for: webView)
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: WebView.Coordinator) {
        // НЕ удаляем WebView, так как он хранится в WebViewStore
        // НЕ удаляем наблюдатели, так как WebView переиспользуется
        // Только удаляем refreshControl
        coordinator.refreshControl?.removeFromSuperview()
        coordinator.refreshControl = nil
    }
}

