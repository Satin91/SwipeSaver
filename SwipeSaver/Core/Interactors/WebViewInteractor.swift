//
//  WebViewInteractor.swift
//  SufrShield
//
//  Created by Артур Кулик on 04.09.2025.
//

import Foundation
import Combine

protocol WebViewObservables {
    var url: URL { get }
    var canGoBack: Bool { get }
    var goBack: Bool { get }
    var canGoForward: Bool { get }
    var goForward: Bool { get }
    var refresh: Bool { get }
    var favoriteGroups: [FavoriteGroup] { get }
    var progress: Double { get }
    var isDarkThemeEnabled: Bool { get }
    var shouldShowPanels: Bool { get }
}

protocol WebViewActions {
    func setCanGoBack(_ isAvailable: Bool)
    func setCanGoForward(_ isAvailable: Bool)
    func updateLoadingProgress(_ progress: Double)
}

protocol WebViewNavigationDelegate: AnyObject {
    func goBack()
    func goForward()
    func reload()
    func loadURL(_ url: URL)
}

class WebViewInteractor: WebViewObservables, WebViewActions, ObservableObject {
    
    // Делегат который использует WebView
    weak var navigationDelegate: WebViewNavigationDelegate?
    // DataStorage для AppSettings, ResourceMonitor и прочих штук
    let userDefaultsObserver: UserDefaultsObserver
    // Проверяет сколько и кто блокируется
    private var resourceMonitor: ResourceMonitor?
    // WebView репозиторий, куда в будущем переедут большинство методов WebViewInteractor
    private let webViewRepository: WebViewRepository
    // Репозиторий для вкладок
    let browserTabsRepository: BrowserTabsRepository
    // Хранилище вкладок
    let webViewStore = WebViewStore()
    // BrowserPanelManager для управления видимостью панелей
    let panelManager = BrowserPanelManager()
    
    @Published private (set) var goBack: Bool = false
    @Published private (set) var goForward: Bool = false
    @Published private (set) var url: URL = URL(string: "https://google.com")!
    @Published private (set) var canGoBack: Bool = false
    @Published private (set) var canGoForward: Bool = false
    @Published private (set) var refresh: Bool = false
    @Published private (set) var progress: Double = 0
    @Published private (set) var isDarkThemeEnabled: Bool = false
    @Published private (set) var shouldShowPanels: Bool = true
    @Published private (set) var resourceAnalysis: ResourceAnalysisData?
    @Published private (set) var browserHistory: [BrowserHistoryItem] = []
    @Published var toastMessage: ToastMessage? // Всплывающее окно
    
    // Единый источник истины для настроек
    var appSettings: AppSettings {
        get { userDefaultsObserver.appSettings }
        set { userDefaultsObserver.updateAppSettings(newValue) }
    }
    
    // Метадата которая обновляется при каждом сайте, нужна для добавления в избранные
    var metaData: [String: Any] = [:]
    
    // Scripts
    public var darkThemeScript: String {
        BrowserScripts.darkThemeScript
    }
    
    public var metaDataScript: String {
        BrowserScripts.metaDataScript
    }
    
    init(webViewRepository: WebViewRepository, browserTabsRepository: BrowserTabsRepository) {
        self.webViewRepository = webViewRepository
        self.browserTabsRepository = browserTabsRepository
        self.userDefaultsObserver = webViewRepository.userDefaultsObserver
        setupResourceMonitor()
        setStartPage()
        setupPanelManagerObserver()
        loadBrowserHistory()
    }
    
    private func subscribe() {
        // Теперь не нужно, так как appSettings - это computed property
    }
    
    private func setupPanelManagerObserver() {
        panelManager.$shouldShowPanels.assign(to: &$shouldShowPanels)
    }
    
    private func setupResourceMonitor() {
        resourceMonitor = ResourceMonitor()
    }
    
    private func setStartPage() {
        if appSettings.enableBrowserHistory, let lastVisitedUrl = userDefaultsObserver.userDefaultsService.load(URL.self, forKey: .lastVisitedURL) {
            self.url = lastVisitedUrl
        } else {
            // Безопасная обработка startPage с fallback на текущий поисковик
            let startPageString = userDefaultsObserver.appSettings.startPage.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let validURL = URL(string: startPageString), !startPageString.isEmpty {
                self.url = validURL
            } else {
                // Fallback на домашнюю страницу выбранного поисковика
                self.url = URL(string: appSettings.startPage) ?? URL(string: "https://google.com")!
            }
        }
    }
    
    func updateAddress(_ url: URL?) {
        guard let url = url else { return }
        self.url = url
        
        // Сохраняем последний URL в UserDefaults
        userDefaultsObserver.userDefaultsService.save(url, forKey: .lastVisitedURL)
    }
    
    private func processURLString(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Получаем выбранный поисковик
        let startPage = appSettings.startPage
        
        // Если строка пустая, возвращаем домашнюю страницу поисковика
        if trimmed.isEmpty {
            return startPage
        }
        
        // Если уже есть протокол, возвращаем как есть
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        
        // Если это IP адрес (содержит только цифры, точки и двоеточия)
        if trimmed.range(of: #"^\d+\.\d+\.\d+\.\d+(:\d+)?$"#, options: .regularExpression) != nil {
            return "http://\(trimmed)"
        }
        
        // Если содержит точку (вероятно домен), добавляем https://
        if trimmed.contains(".") {
            return "https://\(trimmed)"
        }
        
        // Если не содержит точку, считаем поисковым запросом
        let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return "https://google.com\(encodedQuery)"
    }
    
    func goToUrl(string: String) {
        let processedURLString = processURLString(string)
        
        guard let url = URL(string: processedURLString) else {
            print("DEBUG: WRONG URL: \(processedURLString)")
            return
        }
        
        navigationDelegate?.loadURL(url)
    }
    
    func refreshPage() {
        navigationDelegate?.reload()
    }
    
    func goBack(_ isGo: Bool) {
        navigationDelegate?.goBack()
    }
    
    func goForward(_ isGo: Bool) {
        navigationDelegate?.goForward()
    }
    
    func setCanGoBack(_ isAvailable: Bool) {
        self.canGoBack = isAvailable
    }
    
    func setCanGoForward(_ isAvailable: Bool) {
        self.canGoForward = isAvailable
    }
    
    func updateLoadingProgress(_ progress: Double) {
        self.progress = progress
    }
    
    /// Получает ResourceMonitor для настройки WebView
    func getResourceMonitor() -> ResourceMonitor? {
        return resourceMonitor
    }

    /// Получает данные анализа ресурсов
    func getResourceAnalysis() -> ResourceAnalysisData? {
        return resourceAnalysis
    }
    
    /// Сбрасывает данные анализа ресурсов
    func resetResourceAnalysis() {
        resourceAnalysis = nil
    }
}

// MARK: - Browser History Management
extension WebViewInteractor {
    func showToastError(message: String) {
        self.toastMessage = .init(text: message, type: .error)
    }
    /// Загружает историю браузера из UserDefaults
    private func loadBrowserHistory() {
        browserHistory = userDefaultsObserver.userDefaultsService.load([BrowserHistoryItem].self, forKey: .browserHistory) ?? []
    }
    
    /// Сохраняет историю браузера в UserDefaults
    private func saveBrowserHistory() {
        userDefaultsObserver.userDefaultsService.save(browserHistory, forKey: .browserHistory)
    }
    
    /// Добавляет страницу в историю браузера
    /// - Parameters:
    ///   - url: URL страницы
    ///   - title: Заголовок страницы (опционально)
    ///   - faviconURL: URL favicon (опционально)
    func addToBrowserHistory(url: URL, title: String? = nil, faviconURL: String? = nil) {
        print("📚 [BrowserHistory] Попытка сохранить: URL=\(url.absoluteString)")
        print("📚 [BrowserHistory] Title='\(title ?? "nil")', length=\(title?.count ?? 0)")
        
        // Игнорируем системные страницы и ошибки
        guard !url.absoluteString.contains("about:blank"),
              !url.absoluteString.contains("data:"),
              !url.absoluteString.contains("file://") else {
            print("📚 [BrowserHistory] ❌ Пропускаем: системная страница")
            return
        }
        
        // Проверяем наличие валидного заголовка (основной фильтр)
        guard let pageTitle = title, !pageTitle.isEmpty, pageTitle.count > 1 else {
            print("📚 [BrowserHistory] ❌ Пропускаем страницу без заголовка: \(url.absoluteString)")
            return
        }
        
        // Игнорируем служебные и редиректные URL
        guard shouldSaveToHistory(url: url) else {
            print("📚 [BrowserHistory] ❌ Пропускаем служебный URL: \(url.absoluteString)")
            return
        }
        
        // Создаём новый элемент истории
        let historyItem = BrowserHistoryItem(
            title: pageTitle,
            url: url.absoluteString,
            visitDate: Date(),
            faviconURL: faviconURL
        )
        
        // Обновляем историю через UserDefaultsObserver
        userDefaultsObserver.addToBrowserHistory(historyItem)
        
        // Обновляем локальную копию
        browserHistory = userDefaultsObserver.browserHistory
        
        print("📚 [BrowserHistory] ✅ Добавлена страница: '\(pageTitle)' [\(browserHistory.count) элементов]")
        
        // Сохраняем навигацию во вкладку
        if let activeTabId = browserTabsRepository.activeTabId {
            browserTabsRepository.updateTabNavigation(
                tabId: activeTabId,
                url: url.absoluteString,
                title: pageTitle
            )
        }
        
        // Загружаем favicon асинхронно
        Task {
            await FaviconService.shared.getFavicon(for: url)
        }
    }
    
    /// Получает историю браузера
    func getBrowserHistory() -> [BrowserHistoryItem] {
        return browserHistory
    }
    
    /// Очищает историю браузера
    func clearBrowserHistory() {
        browserHistory.removeAll()
        saveBrowserHistory()
        print("📚 [BrowserHistory] История очищена")
    }
    
    /// Удаляет конкретный элемент из истории
    /// - Parameter item: Элемент для удаления
    func removeFromBrowserHistory(_ item: BrowserHistoryItem) {
        browserHistory.removeAll { $0.id == item.id }
        saveBrowserHistory()
        print("📚 [BrowserHistory] Удалена страница: \(item.title)")
    }
    
    /// Проверяет, нужно ли сохранять URL в историю
    /// - Parameter url: URL для проверки
    /// - Returns: true если URL нужно сохранить в историю
    private func shouldSaveToHistory(url: URL) -> Bool {
        let urlString = url.absoluteString.lowercased()
        let host = url.host?.lowercased() ?? ""
        
        // Игнорируем служебные домены и пути
        let ignoredHosts = [
            "sso.yandex.ru",
            "passport.yandex.ru", 
            "oauth.yandex.ru",
            "login.yandex.ru",
            "auth.yandex.ru",
            "social.yandex.ru",
            "oauth.vk.com",
            "oauth.vkontakte.ru",
            "login.vk.com",
            "oauth.google.com",
            "accounts.google.com",
            "login.microsoft.com",
            "login.live.com",
            "oauth.facebook.com",
            "www.facebook.com/login",
            "api.twitter.com",
            "oauth.twitter.com"
        ]
        
        // Игнорируем служебные пути (только в начале или как отдельный сегмент)
        let ignoredPaths = [
            "/oauth",
            "/auth",
            "/login",
            "/logout", 
            "/sso",
            "/passport",
            "/social",
            "/callback",
            "/redirect"
        ]
        
        // Проверяем домены
        for ignoredHost in ignoredHosts {
            if host.contains(ignoredHost) {
                print("📚 [BrowserHistory] Заблокирован по домену: \(ignoredHost)")
                return false
            }
        }
        
        // Проверяем пути
        for ignoredPath in ignoredPaths {
            if urlString.contains(ignoredPath) {
                print("📚 [BrowserHistory] Заблокирован по пути: \(ignoredPath)")
                return false
            }
        }
        
        // Игнорируем очень короткие URL (вероятно служебные)
        if urlString.count < 10 {
            print("📚 [BrowserHistory] Заблокирован: слишком короткий URL")
            return false
        }
        
        // Игнорируем URL без домена
        if host.isEmpty {
            print("📚 [BrowserHistory] Заблокирован: нет домена")
            return false
        }
        
        return true
    }
}

// MARK: - Favorites Management
extension WebViewInteractor {
    
    /// Получает все группы избранного
    var favoriteGroups: [FavoriteGroup] {
        return webViewRepository.favoriteGroups
    }
    
    func updateMetaData(metaData: [String: Any], groupId: UUID? = nil) {
//        webvViewRepository.addToFavorites(metaData: metaData, groupId: groupId)
        self.metaData = metaData
        print("⭐ [Favorites] Meta data Страницы обновлены \(metaData)")
    }
    
    /// Добавляет текущую страницу в избранное
    /// - Parameters:
    ///   - metaData: Словарь с метаданными страницы (url, title)
    ///   - groupId: ID группы, в которую добавить (опционально, по умолчанию первая группа)
    func addToFavorites(group: FavoriteGroup) {
        webViewRepository.addToFavorites(metaData: metaData, groupId: group.id)
        print("⭐ [Favorites] Страница добавлена в избранное")
    }
    
    /// Проверяет, находится ли текущий URL в избранном
    /// - Parameter url: URL для проверки
    /// - Returns: true если URL в избранном
    func isInFavorites(_ url: String) -> Bool {
        return webViewRepository.isInFavorites(url)
    }
    
    /// Удаляет страницу из избранного
    /// - Parameters:
    ///   - item: Элемент избранного для удаления
    ///   - group: Группа, из которой удалить
    func removeFromFavorites(_ item: BrowserFavoriteItem, from group: FavoriteGroup) {
        webViewRepository.removeFromFavorites(item, from: group)
        print("🗑️ [Favorites] Страница удалена из избранного")
    }
    
    /// Создает новую группу избранного
    /// - Parameters:
    ///   - name: Название группы
    ///   - colorHex: Цвет группы в формате hex
    func createFavoriteGroup(name: String, colorHex: String) {
        webViewRepository.createFavoriteGroup(name: name, colorHex: colorHex)
        print("📁 [Favorites] Создана новая группа: \(name)")
    }
}

// MARK: - Browser Tabs Management
extension WebViewInteractor {
    
    /// Получает все вкладки браузера
    var browserTabs: [BrowserTab] {
        return browserTabsRepository.tabs
    }
    
    /// Получает активную вкладку
    var activeTab: BrowserTab? {
        return browserTabsRepository.activeTab
    }
    
    /// Получает ID активной вкладки
    var activeTabId: UUID? {
        return browserTabsRepository.activeTabId
    }
    
    /// Создает новую вкладку
    /// - Parameters:
    ///   - title: Заголовок вкладки
    ///   - url: Начальный URL
    /// - Returns: Созданная вкладка
    @discardableResult
    func createNewTab(title: String = "New Tab", url: String = "") -> BrowserTab {
        let newTab = browserTabsRepository.createNewTab(title: title, url: url)
        
        // Важно: сразу переключаемся на новую вкладку чтобы установить правильный delegate
        // НО не вызываем полный switchToTab, чтобы не перезагружать
        browserTabsRepository.setActiveTab(newTab.id)
        
        // Когда WebView для этой вкладки создастся, он автоматически установит delegate
        // через WebViewForTab.makeUIView()
        
        print("➕ [WebViewInteractor] Создана новая вкладка: \(String(newTab.id.uuidString.prefix(8)))")
        
        return newTab
    }
    
    /// Удаляет вкладку
    /// - Parameter tabId: ID вкладки для удаления
    func deleteTab(_ tabId: UUID) {
        // Удаляем WebView из хранилища
        webViewStore.removeWebView(for: tabId)
        
        // Удаляем вкладку из репозитория
        browserTabsRepository.deleteTab(tabId)
    }
    
    /// Устанавливает активную вкладку и загружает её URL
    /// - Parameter tabId: ID вкладки
    func switchToTab(_ tabId: UUID) {
        browserTabsRepository.setActiveTab(tabId)
        
        // Устанавливаем navigationDelegate для активной вкладки
        setActiveNavigationDelegate(for: tabId)
        
        // Получаем WebView для этой вкладки
        let webView = webViewStore.getWebView(for: tabId)
        
        // Если WebView пустой (не был загружен), загружаем URL из вкладки
        if webView.url == nil {
            if let tab = browserTabsRepository.tabs.first(where: { $0.id == tabId }),
               !tab.currentURL.isEmpty,
               let url = URL(string: tab.currentURL) {
                print("🔗 [WebViewInteractor] Загружаем сохраненный URL при переключении: \(url.absoluteString)")
                webView.load(URLRequest(url: url))
            }
        }
        
        // Синхронизируем URL в адресной строке с реальным URL WebView
        syncURLFromWebView(for: tabId)
    }
    
    /// Синхронизирует URL адресной строки с реальным URL WebView
    /// - Parameter tabId: ID вкладки
    func syncURLFromWebView(for tabId: UUID) {
        // Получаем WebView для этой вкладки
        let webView = webViewStore.getWebView(for: tabId)
        
        // Обновляем URL в адресной строке из WebView (НЕ из репозитория!)
        if let currentURL = webView.url {
            self.url = currentURL
            print("🔄 [WebViewInteractor] Синхронизирован URL из WebView: \(currentURL.absoluteString)")
        } else if let activeTab = browserTabsRepository.activeTab,
                  !activeTab.currentURL.isEmpty,
                  let fallbackURL = URL(string: activeTab.currentURL) {
            // Fallback: если WebView пустой, берем из репозитория
            self.url = fallbackURL
            print("🔄 [WebViewInteractor] Использован fallback URL из репозитория: \(fallbackURL.absoluteString)")
        }
        
        // Обновляем состояние кнопок навигации
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
    }
    
    /// Устанавливает navigationDelegate для указанной вкладки
    /// - Parameter tabId: ID вкладки
    func setActiveNavigationDelegate(for tabId: UUID) {
        if let coordinator = webViewStore.getCoordinator(for: tabId) as? WebViewNavigationDelegate {
            self.navigationDelegate = coordinator
            print("🔗 [WebViewInteractor] Установлен navigationDelegate для вкладки \(String(tabId.uuidString.prefix(8)))")
        } else {
            print("⚠️ [WebViewInteractor] Coordinator не найден для вкладки \(String(tabId.uuidString.prefix(8)))")
        }
    }
    
    /// Получает количество вкладок
    var tabsCount: Int {
        return browserTabsRepository.tabsCount
    }
    
    /// Удаляет все вкладки
    func clearAllTabs() {
        browserTabsRepository.clearAllTabs()
    }
}
