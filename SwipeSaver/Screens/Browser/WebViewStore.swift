//
//  WebViewStore.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 29.10.2025.
//

import Foundation
import WebKit
import Combine
import UIKit

/// Простое хранилище WebView для каждой вкладки
class WebViewStore: ObservableObject {
    
    /// Словарь: ID вкладки -> WKWebView
    private var webViews: [UUID: WKWebView] = [:]
    
    /// Словарь: ID вкладки -> Coordinator (navigationDelegate)
    var coordinators: [UUID: Any] = [:]
    
    /// Сервис для работы со снимками
    let snapshotService = SnapshotService()
    
    /// Published снимки для автоматического обновления UI
    @Published var snapshots: [UUID: UIImage] = [:]
    
    /// Подписки для отслеживания изменений
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init() {
        // Подписываемся на изменения снимков из snapshotService
        snapshotService.$snapshots
            .assign(to: &$snapshots)
    }
    
    /// Получает WebView для указанной вкладки (или создает новый если нет)
    /// - Parameter tabId: ID вкладки
    /// - Returns: WKWebView для этой вкладки
    func getWebView(for tabId: UUID) -> WKWebView {
        // Если WebView уже существует - возвращаем его
        if let existingWebView = webViews[tabId] {
            print("🌐 [WebViewStore] Возвращаем существующий WebView для вкладки \(String(tabId.uuidString.prefix(8)))")
            return existingWebView
        }
        
        // Создаем новый WebView
        let webView = createNewWebView()
        webViews[tabId] = webView
        
        print("🌐 [WebViewStore] Создан новый WebView для вкладки \(String(tabId.uuidString.prefix(8)))")
        print("🌐 [WebViewStore] Всего WebView в хранилище: \(webViews.count)")
        
        return webView
    }
    
    /// Удаляет WebView для указанной вкладки
    /// - Parameter tabId: ID вкладки
    func removeWebView(for tabId: UUID) {
        if let webView = webViews[tabId] {
            // Очищаем WebView перед удалением
            webView.stopLoading()
            webView.loadHTMLString("", baseURL: nil)
            webViews.removeValue(forKey: tabId)
            
            // Удаляем coordinator
            coordinators.removeValue(forKey: tabId)
            
            // Удаляем snapshot через сервис
            snapshotService.removeSnapshot(for: tabId)
            
            print("🗑️ [WebViewStore] Удален WebView для вкладки \(String(tabId.uuidString.prefix(8)))")
            print("🌐 [WebViewStore] Осталось WebView в хранилище: \(webViews.count)")
        }
    }
    
    /// Сохраняет coordinator для вкладки
    /// - Parameters:
    ///   - coordinator: Coordinator для сохранения
    ///   - tabId: ID вкладки
    func setCoordinator(_ coordinator: Any, for tabId: UUID) {
        coordinators[tabId] = coordinator
        print("📝 [WebViewStore] Coordinator сохранен для вкладки \(String(tabId.uuidString.prefix(8)))")
    }
    
    /// Получает coordinator для вкладки
    /// - Parameter tabId: ID вкладки
    /// - Returns: Coordinator если существует
    func getCoordinator(for tabId: UUID) -> Any? {
        return coordinators[tabId]
    }
    
    /// Получает количество сохраненных WebView
    var count: Int {
        return webViews.count
    }
    
    /// Получает информацию о вкладке из WebView (URL, title)
    /// - Parameter tabId: ID вкладки
    /// - Returns: Кортеж с URL и title, если WebView существует
    func getWebViewInfo(for tabId: UUID) -> (url: String?, title: String?)? {
        guard let webView = webViews[tabId] else {
            return nil
        }
        
        let url = webView.url?.absoluteString
        let title = webView.title
        
        return (url: url, title: title)
    }
    
    /// Очищает все WebView
    func clearAll() {
        webViews.values.forEach { webView in
            webView.stopLoading()
            webView.loadHTMLString("", baseURL: nil)
        }
        webViews.removeAll()
        
        // Удаляем все снимки через сервис
        snapshotService.clearAllSnapshots()
        
        print("🧹 [WebViewStore] Все WebView очищены")
    }
    
    // MARK: - Snapshots
    
    /// Создает снимок экрана для указанной вкладки
    /// - Parameter tabId: ID вкладки
    func takeSnapshot(for tabId: UUID) {
        guard let webView = webViews[tabId] else {
            print("⚠️ [WebViewStore] WebView не найден для вкладки \(String(tabId.uuidString.prefix(8)))")
            return
        }
        
        // Делегируем создание снимка сервису
        snapshotService.takeSnapshot(of: webView, for: tabId)
    }
    
    /// Получает снимок экрана для указанной вкладки
    /// - Parameter tabId: ID вкладки
    /// - Returns: UIImage если снимок существует
    func getSnapshot(for tabId: UUID) -> UIImage? {
        return snapshotService.getSnapshot(for: tabId)
    }
    
    /// Удаляет снимок экрана для указанной вкладки
    /// - Parameter tabId: ID вкладки
    func removeSnapshot(for tabId: UUID) {
        snapshotService.removeSnapshot(for: tabId)
    }
    
    // MARK: - Private
    
    /// Создает базовый WebView с минимальными настройками
    private func createNewWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // Базовые настройки
        webView.backgroundColor = UIColor(named: "Container")
        webView.isOpaque = true
        
        return webView
    }
}

