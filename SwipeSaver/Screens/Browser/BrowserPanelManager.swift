//
//  BrowserPanelManager.swift
//  UntraX
//
//  Created by Артур Кулик on 25.10.2025.
//

import SwiftUI
import Combine

/// Менеджер для управления видимостью панелей браузера (WebViewPanel и TabBar)
/// при скролле контента
final class BrowserPanelManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Показывать ли панели (true = показать, false = скrыть)
    @Published private(set) var shouldShowPanels: Bool = true
    
    // MARK: - Private Properties
    
    /// Последняя позиция скролла по Y
    private var lastContentOffsetY: CGFloat = 0
    
    /// Минимальное смещение для срабатывания скрытия/показа
    private let scrollThreshold: CGFloat = 10
    
    /// Флаг инициализации - игнорируем первые вызовы при загрузке контента
    private var isInitialized: Bool = false
    
    /// Счётчик вызовов для игнорирования начальных скачков
    private var scrollCallCount: Int = 0
    
    // MARK: - Public Methods
    
    /// Показать панели с анимацией
    func showPanels() {
        guard !shouldShowPanels else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.shouldShowPanels = true
        }
    }
    
    /// Скрыть панели с анимацией
    func hidePanels() {
        guard shouldShowPanels else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.shouldShowPanels = false
        }
    }
    
    /// Сбросить состояние (показать панели без анимации)
    /// Вызывать при загрузке нового URL или перезагрузке страницы
    func reset() {
        shouldShowPanels = true
        lastContentOffsetY = 0
        isInitialized = false
        scrollCallCount = 0
    }
    
    // MARK: - Scroll Handling
    
    /// Обрабатывает изменение позиции скролла
    /// - Parameters:
    ///   - scrollView: UIScrollView который скроллится
    func handleScrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffsetY = scrollView.contentOffset.y
        
        // Инициализация: пропускаем первые 3 вызова, чтобы избежать ложных срабатываний при загрузке
        if !isInitialized {
            scrollCallCount += 1
            if scrollCallCount > 3 {
                isInitialized = true
                lastContentOffsetY = currentOffsetY
            }
            return
        }
        
        let deltaY = currentOffsetY - lastContentOffsetY
        
        // Игнорируем мелкие изменения (увеличен порог для стабильности)
        guard abs(deltaY) > 8 else { return }
        
        // В самом верху страницы - всегда показываем панели
        if currentOffsetY <= 0 {
            showPanels()
            lastContentOffsetY = currentOffsetY
            return
        }
        
        // В начале страницы (первые 100pt) - показываем панели
        if currentOffsetY < 100 {
            showPanels()
            lastContentOffsetY = currentOffsetY
            return
        }
        
        // Блокировка: если близко к концу контента - не меняем состояние панелей
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height
        let bottomOffset = currentOffsetY + scrollViewHeight
        
        if bottomOffset >= contentHeight - 150 {
            lastContentOffsetY = currentOffsetY
            return
        }
        
        // Скролл вниз - скрываем панели
        if deltaY > scrollThreshold {
            hidePanels()
        }
        // Скролл вверх - показываем панели
        else if deltaY < -scrollThreshold {
            showPanels()
        }
        
        lastContentOffsetY = currentOffsetY
    }
    
    /// Обрабатывает окончание перетаскивания скролла
    func handleScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Не требуется дополнительная логика
    }
    
    /// Обрабатывает окончание инерционного скролла
    func handleScrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Не требуется дополнительная логика
    }
}
