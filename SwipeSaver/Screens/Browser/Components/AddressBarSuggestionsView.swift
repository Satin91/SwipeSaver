//
//  AddressBarSuggestionsView.swift
//  UntraX
//
//  Created by AI Assistant on 27.10.2025.
//

import SwiftUI

/// View для отображения подсказок при вводе в адресную строку
struct AddressBarSuggestionsView: View {
    let suggestions: [BrowserHistoryItem]
    let searchText: String
    let onSelectSuggestion: (BrowserHistoryItem) -> Void
    
    var body: some View {
        if !suggestions.isEmpty {
            VStack(spacing: 0) {
                ForEach(suggestions.prefix(5)) { suggestion in
                    suggestionRow(for: suggestion)
                        .onTapGesture {
                            onSelectSuggestion(suggestion)
                        }
                    
                    if suggestion.id != suggestions.prefix(5).last?.id {
                        Divider()
                            .background(Color.tm.border.opacity(0.2))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.tm.container.opacity(0.98))
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 16,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.tm.border.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }
    
    private func suggestionRow(for item: BrowserHistoryItem) -> some View {
        HStack(spacing: 12) {
            // Favicon или иконка
            faviconView(for: item)
            
            // Текст
            VStack(alignment: .leading, spacing: 4) {
                // Заголовок с подсветкой
                Text(highlightedText(item.title, matching: searchText))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.tm.title)
                    .lineLimit(1)
                
                // URL с подсветкой - показываем полный путь если есть
                Text(highlightedText(displayURL(for: item), matching: searchText))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.tm.subTitle)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Стрелка
            Image(systemName: "arrow.up.left")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.tm.subTitle.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func faviconView(for item: BrowserHistoryItem) -> some View {
        Group {
            if let urlString = item.faviconURL,
               let url = URL(string: urlString) {
                FaviconView(url: url)
                    .frame(width: 32, height: 32)
            } else if let url = URL(string: item.url) {
                FaviconView(url: url)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundColor(.tm.subTitle)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.tm.border.opacity(0.2))
                    )
            }
        }
    }
    
    /// Создает AttributedString с подсветкой совпадений
    private func highlightedText(_ text: String, matching searchText: String) -> AttributedString {
        guard !searchText.isEmpty else {
            return AttributedString(text)
        }
        
        var attributedString = AttributedString(text)
        let lowercasedText = text.lowercased()
        let lowercasedSearch = searchText.lowercased()
        
        // Находим все вхождения
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        
        while let range = lowercasedText.range(of: lowercasedSearch, range: searchRange) {
            // Конвертируем Range<String.Index> в Range<AttributedString.Index>
            if let attributedRange = Range<AttributedString.Index>(range, in: attributedString) {
                attributedString[attributedRange].foregroundColor = .tm.accent
                attributedString[attributedRange].font = .system(size: 15, weight: .semibold)
            }
            
            // Продолжаем поиск после текущего совпадения
            searchRange = range.upperBound..<lowercasedText.endIndex
        }
        
        return attributedString
    }
    
    /// Определяет какой URL показывать - только домен или с путем
    private func displayURL(for item: BrowserHistoryItem) -> String {
        guard let urlComponents = URLComponents(string: item.url),
              let host = urlComponents.host else {
            return item.url
        }
        
        // Убираем "www." из домена
        var displayHost = host
        if displayHost.hasPrefix("www.") {
            displayHost = String(displayHost.dropFirst(4))
        }
        
        // Проверяем есть ли путь (не просто "/")
        let path = urlComponents.path
        let hasPath = !path.isEmpty && path != "/"
        
        // Проверяем есть ли query параметры
        let hasQuery = urlComponents.query != nil && !(urlComponents.query?.isEmpty ?? true)
        
        // Если есть путь или query параметры - показываем полный URL
        if hasPath || hasQuery {
            var result = displayHost
            
            // Добавляем путь
            if hasPath {
                result += path
            }
            
            // Добавляем query параметры (опционально, можно убрать если слишком длинно)
            if hasQuery, let query = urlComponents.query {
                result += "?\(query)"
            }
            
            return result
        }
        
        // Иначе показываем только домен
        return displayHost
    }
}

#Preview {
    VStack {
        Spacer()
        
        AddressBarSuggestionsView(
            suggestions: [
                BrowserHistoryItem(
                    title: "Google",
                    url: "https://google.com",
                    visitDate: Date()
                ),
                BrowserHistoryItem(
                    title: "GitHub - Where the world builds software",
                    url: "https://github.com",
                    visitDate: Date()
                ),
                BrowserHistoryItem(
                    title: "Dribbble Dashboard",
                    url: "https://dribbble.com/dashboard/feature",
                    visitDate: Date()
                ),
                BrowserHistoryItem(
                    title: "Stack Overflow Question",
                    url: "https://stackoverflow.com/questions/12345/some-question",
                    visitDate: Date()
                )
            ],
            searchText: "go",
            onSelectSuggestion: { _ in }
        )
        
        Spacer()
    }
    .background(Color.black.opacity(0.5))
}

