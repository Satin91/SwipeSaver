//
//  InternetBrowserView.swift
//  SufrShield
//
//  Created by Артур Кулик on 03.09.2025.
//

import SwiftUI

struct InternetBrowserView: View {
    @StateObject var interactor = Executor.webViewInteractor
    @State private var showShareSheet = false
    @EnvironmentObject var coordinator: Coordinator
    @State private var menuRect: CGRect? = nil
    // Показываем BrowserTabsView как overlay
    @State private var showBrowserTabs = false
    
    var body: some View {
        browser
            .toast(message: $interactor.toastMessage)
    }
    
    @ViewBuilder
    var browser: some View {
        GeometryReader { geometry in
            VStack(spacing: .zero) {
                WebViewPanel(
                    observables: interactor,
                    onGoBack: {
                        interactor.goBack(true)
                    },
                    onGoForward: {
                        interactor.goForward(true)
                    },
                    onGoToURL: { url in
                        interactor.goToUrl(string: url)
                    },
                    onShowTabs: {
                        // Создаем снимок активной вкладки перед открытием экрана табов
                        // Только если вкладка уже загружена (не пустая)
                        if let activeTabId = interactor.browserTabsRepository.activeTabId {
                            let webView = interactor.webViewStore.getWebView(for: activeTabId)
                            if webView.url != nil {
                                interactor.webViewStore.takeSnapshot(for: activeTabId)
                            }
                        }
                        
                        showBrowserTabs = true
                    },
                    onTapMenu: { frame in
                        menuRect = frame
                    },
                    onTapFavorits: { group in
                        interactor.addToFavorites(group: group)
                    },
                    onShare: { url in
                        showShareSheet = true
                    },
                    onHistory: {
                        coordinator.fullScreenCover(to: .browserHistory(onTapHistoryItem: { url in
                            interactor.goToUrl(string: url?.absoluteString ?? "")
                        }))
                    },
                    onFavorites: {
                        coordinator.fullScreenCover(to: .browserFavorites(onTapFavoriteItem: { url in
                            interactor.goToUrl(string: url?.absoluteString ?? "")
                        }))
                    }
                )
                .zIndex(2.0)
                
                // Контейнер с несколькими WebView (как TabView)
                WebViewContainer(interactor: interactor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: interactor.shouldShowPanels)
//                    .padding(.bottom, 122)
                    .ignoresSafeArea(edges: .top)
                    .ignoresSafeArea(.all)
                    .zIndex(1.0)
                    .frame(height: max(0, geometry.size.height - 20), alignment: .top)
            }
        }
        .overlay {
            // BrowserTabsView как overlay
            if showBrowserTabs {
                BrowserTabsView(onSwitchTab: { tabId in
                    // Закрываем overlay (БЕЗ dismiss!)
                    interactor.switchToTab(tabId)
                    showBrowserTabs = false
                })
//                .opacity(showBrowserTabs ? 1 : 0)
                .animation(.easeIn(duration: 0.1), value: showBrowserTabs)
                .zIndex(100)
            }
        }
        .overlay {
            MenuView(rect: $menuRect) {
                VStack {
                    MenuItemRow(icon: .star, title: "Favorites") {
                        coordinator.fullScreenCover(to: .browserFavorites(onTapFavoriteItem: { url in
                            interactor.goToUrl(string: url?.absoluteString ?? "")
                        }))
                    }
                    MenuItemRow(icon: .time, title: "History") {
                        coordinator.fullScreenCover(to: .browserHistory(onTapHistoryItem: { url in
                            interactor.goToUrl(string: url?.absoluteString ?? "")
                        }))
                    }
                    MenuItemRow(icon: .share, title: "Share") {
                        showShareSheet.toggle()
                    }
                    MenuItemRow(icon: .settings, title: "Settings", showDivider: false) {
                        coordinator.push(to: .settings)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [interactor.url])
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Ничего не нужно обновлять
    }
}

#Preview {
    InternetBrowserView()
}
