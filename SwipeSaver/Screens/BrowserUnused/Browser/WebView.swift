//
//  WebView.swift
//  SufrShield
//
//  Created by Артур Кулик on 03.09.2025.
//

import SwiftUI
import WebKit
import Combine

struct WebView: UIViewRepresentable {
    @ObservedObject var interactor: WebViewInteractor
    
    var cancellable = Set<AnyCancellable>()
    
    func makeUIView(context: Context) -> WKWebView {
        // Создаем конфигурацию с предустановленным скриптом
        let config = WKWebViewConfiguration()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // Отключаем autoresizing mask для использования Auto Layout
//        webView.translatesAutoresizingMaskIntoConstraints = false
        
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
//        webView.scrollView.contentInset = .init(top: 0, left: 0, bottom: 180, right: 0)
        
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
        
        // Применяем тему немедленно при создании WebView
        webView.load(URLRequest(url: interactor.url))
        
        // Добавляем наблюдатели для отслеживания состояния навигации
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.url), options: [.new], context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.new], context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoForward), options: [.new], context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new], context: nil)
        
        // Настраиваем Pull to Refresh
        context.coordinator.setupRefreshControl(for: webView)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // Удаляем наблюдатели при уничтожении view
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.url))
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.canGoBack))
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.canGoForward))
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        
        // Удаляем refreshControl
        coordinator.refreshControl?.removeFromSuperview()
        coordinator.refreshControl = nil
    }
    
    //MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WebViewNavigationDelegate, WKUIDelegate {
        var parent: WebView?
        weak var webView: WKWebView?
        var cancellable = Set<AnyCancellable>()
        var refreshControl: UIRefreshControl?
        var isRefreshing = false
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("DEBUG: Начало загрузки страницы")
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            // Обновляем состояние навигации при начале загрузки
            parent?.interactor.setCanGoBack(webView.canGoBack)
            parent?.interactor.setCanGoForward(webView.canGoForward)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Обновляем состояние навигации при завершении загрузки
            parent?.interactor.setCanGoBack(webView.canGoBack)
            parent?.interactor.setCanGoForward(webView.canGoForward)
            
            // Обновляем URL в interactor (это автоматически сохранит его)
            if let currentURL = webView.url {
                parent?.interactor.updateAddress(currentURL)
                
                // Получаем мета-данные страницы
                webView.evaluateJavaScript(parent?.interactor.metaDataScript ?? "") { [weak self] result, error in
                    guard let self = self,
                          let metaData = result as? [String: Any] else { return }
                    
                    // Получаем title из метаданных или webView
                    let title = (metaData["title"] as? String) ?? webView.title ?? ""
                    let faviconURL = metaData["faviconURL"] as? String
                    
                    // Добавляем в историю
                    DispatchQueue.main.async {
                        self.parent?.interactor.addToBrowserHistory(
                            url: currentURL,
                            title: title,
                            faviconURL: faviconURL
                        )
                        
                        self.parent?.interactor.updateMetaData(metaData: metaData)
                    }
                }
            }

            if isRefreshing {
                isRefreshing = false
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
            }
            
            print("DEBUG: Загрузка страницы завершена")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("DEBUG: Ошибка загрузки страницы: \(error.localizedDescription)")
            
            // Если идёт обновление через pull to refresh, останавливаем индикатор даже при ошибке
            if isRefreshing {
                isRefreshing = false
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("DEBUG: Ошибка начала загрузки страницы: \(error.localizedDescription)")
            
//            parent?.interactor.showToastError(message: error.localizedDescription)
            // Если идёт обновление через pull to refresh, останавливаем индикатор даже при ошибке
            if isRefreshing {
                isRefreshing = false
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Проверяем URL и его схему
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString
                
                // Если URL не HTTP/HTTPS - открываем через систему
                if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        // Отменяем загрузку в WebView
                        decisionHandler(.cancel)
                        return
                    }
                }
            }
            
            // HTTP/HTTPS - разрешаем загрузку в WebView
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            
            // Если запрос не из-за клика (например, form submit), разрешаем обычную навигацию
            guard navigationAction.targetFrame == nil || !(navigationAction.targetFrame?.isMainFrame ?? false) else {
                return nil
            }

            // Загружаем URL в том же WKWebView вместо создания нового
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
        
         
        // MARK: - KVO Observer
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = webView else { return }
            if keyPath == #keyPath(WKWebView.canGoBack) {
                parent?.interactor.setCanGoBack(webView.canGoBack)
            } else if keyPath == #keyPath(WKWebView.canGoForward) {
                parent?.interactor.setCanGoForward(webView.canGoForward)
            } else if keyPath == #keyPath(WKWebView.estimatedProgress) {
                parent?.interactor.updateLoadingProgress(webView.estimatedProgress)
            } else if  keyPath == #keyPath(WKWebView.url) {
                parent?.interactor.updateAddress(webView.url)
//                parent?.interactor.goToUrl(string: webView.url!.absoluteString) //TODO: MAKE UPDATING ADDRESS BAR
            }
        }
        
        func goBack() {
            webView?.goBack()
        }
        
        func goForward() {
            webView?.goForward()
        }
        
        func reload() {
            webView?.reload()
//            addedContentRules()
        }
        
        func loadURL(_ url: URL) {
            webView?.load(URLRequest(url: url))
        }
        
        // MARK: - Resource Monitoring
        
        public func setupResourceMonitoring() {
            guard let webView = webView,
                  let resourceMonitor = parent?.interactor.getResourceMonitor() else { return }
            
            // Добавляем обработчики сообщений
            webView.configuration.userContentController.add(resourceMonitor, name: "resourceAnalysis")
            
            // Внедряем JavaScript для анализа ресурсов
            let analysisScript = WKUserScript(
                source: ResourceMonitor.buildResourceInfoJavascript(),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            webView.configuration.userContentController.addUserScript(analysisScript)
        }
        
        // MARK: - Pull to Refresh
        
        func setupRefreshControl(for webView: WKWebView) {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
            
            // Настраиваем цвет индикатора
            refreshControl.tintColor = UIColor(named: "Accent")
            
            // Используем стандартный API для UIScrollView (iOS 10+)
            // Это предотвращает скачки скролла
            webView.scrollView.refreshControl = refreshControl
            
            self.refreshControl = refreshControl
        }
        
        @objc func handleRefresh() {
            // Тактильный отклик при начале обновления
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Устанавливаем флаг что идёт refresh
            isRefreshing = true
            
            // Вызываем перезагрузку через интерактор (правильная архитектура)
            self.webView?.reload()
            
            // refreshControl будет остановлен автоматически в didFinish
        }
    }
}

extension WebView.Coordinator: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        parent?.interactor.panelManager.handleScrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        parent?.interactor.panelManager.handleScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        parent?.interactor.panelManager.handleScrollViewDidEndDecelerating(scrollView)
    }
    
}
