//
//  WebViewContainer.swift
//  UntraX
//
//  Created by Артур Кулик on 29.10.2025.
//

import SwiftUI

/// Контейнер который управляет несколькими WebView и переключается между ними
struct WebViewContainer: View {
    @ObservedObject var interactor: WebViewInteractor
    
    var body: some View {
        ZStack {
            // Создаем WebView для каждой вкладки
            ForEach(interactor.browserTabs, id: \.id) { tab in
                WebViewWrapper(
                    interactor: interactor,
                    tabId: tab.id,
                    isActive: interactor.activeTabId == tab.id
                )
                .opacity(interactor.activeTabId == tab.id ? 1 : 0)
                .zIndex(interactor.activeTabId == tab.id ? 1 : 0)
            }
        }
    }
}

/// Обертка для WebView привязанная к конкретной вкладке
private struct WebViewWrapper: View {
    @ObservedObject var interactor: WebViewInteractor
    let tabId: UUID
    let isActive: Bool
    
    var body: some View {
        WebViewForTab(interactor: interactor, tabId: tabId)
            .onAppear {
                if isActive {
                    // Когда WebView появляется и он активный, устанавливаем delegate
                    DispatchQueue.main.async {
                        interactor.setActiveNavigationDelegate(for: tabId)
                    }
                }
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    // Когда WebView становится активным, обновляем delegate
                    interactor.setActiveNavigationDelegate(for: tabId)
                    interactor.syncURLFromWebView(for: tabId)
                }
            }
    }
}

