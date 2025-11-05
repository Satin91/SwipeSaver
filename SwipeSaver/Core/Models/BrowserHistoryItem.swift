//
//  BrowserHistory.swift
//  UntraX
//
//  Created by Артур Кулик on 25.10.2025.
//

import Foundation

// MARK: - BrowserHistoryItem

/// Элемент истории браузера
struct BrowserHistoryItem: Identifiable, Codable, Equatable {
    /// Уникальный идентификатор
    let id: UUID
    
    /// Название страницы (title из HTML)
    let title: String
    
    /// URL адрес страницы
    let url: String
    
    /// Дата и время посещения
    let visitDate: Date
    
    /// Favicon URL (опционально, для будущего использования)
    let faviconURL: String?
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        visitDate: Date = Date(),
        faviconURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.visitDate = visitDate
        self.faviconURL = faviconURL
    }
    
    // MARK: - Computed Properties
    
    /// Доменное имя (например, "google.com")
    var domain: String {
        guard let urlComponents = URLComponents(string: url),
              let host = urlComponents.host else {
            return url
        }
        
        // Убираем "www." если есть
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        
        return host
    }
    
    /// Форматированное время для отображения (использует текущий Locale)
    var formattedTime: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(visitDate) {
            // Сегодня - показываем время
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.timeStyle = .short
            return formatter.string(from: visitDate)
        } else if calendar.isDateInYesterday(visitDate) {
            // Вчера - показываем время
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.timeStyle = .short
            return formatter.string(from: visitDate)
        } else if calendar.isDate(visitDate, equalTo: now, toGranularity: .weekOfYear) {
            // На этой неделе - показываем день недели и время
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "EEE HH:mm"
            return formatter.string(from: visitDate)
        } else if calendar.isDate(visitDate, equalTo: now, toGranularity: .year) {
            // В этом году - показываем день и месяц
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "d MMM"
            return formatter.string(from: visitDate)
        } else {
            // Старше года - показываем полную дату
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: visitDate)
        }
    }
    
    /// Секция для группировки в истории
    var section: HistorySection {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(visitDate) {
            return .today
        } else if calendar.isDateInYesterday(visitDate) {
            return .yesterday
        } else if calendar.isDate(visitDate, equalTo: now, toGranularity: .weekOfYear) {
            return .thisWeek
        } else if calendar.isDate(visitDate, equalTo: now, toGranularity: .month) {
            return .thisMonth
        } else {
            return .older
        }
    }
}

// MARK: - HistorySection

/// Секции для группировки истории
enum HistorySection: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case older = "Older"
}

// MARK: - Array Extension

extension Array where Element == BrowserHistoryItem {
    /// Группирует элементы истории по секциям
    func groupedBySection() -> [(section: HistorySection, items: [BrowserHistoryItem])] {
        var grouped: [HistorySection: [BrowserHistoryItem]] = [:]
        
        for item in self {
            grouped[item.section, default: []].append(item)
        }
        
        // Сортируем секции в правильном порядке и элементы по дате (новые сверху)
        return HistorySection.allCases.compactMap { section in
            guard let items = grouped[section], !items.isEmpty else { return nil }
            let sortedItems = items.sorted { $0.visitDate > $1.visitDate }
            return (section, sortedItems)
        }
    }
    
    /// Фильтрует элементы истории по поисковому запросу
    func filtered(by searchText: String) -> [BrowserHistoryItem] {
        guard !searchText.isEmpty else { return self }
        
        let lowercasedSearch = searchText.lowercased()
        return self.filter { item in
            item.title.lowercased().contains(lowercasedSearch) ||
            item.url.lowercased().contains(lowercasedSearch) ||
            item.domain.lowercased().contains(lowercasedSearch)
        }
    }
}

