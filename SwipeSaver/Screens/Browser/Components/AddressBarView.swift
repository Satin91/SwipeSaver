//
//  AddressBarView.swift
//  SufrShield
//
//  Created by Артур Кулик on 03.09.2025.
//

import SwiftUI

struct AddressBarView: View {
    var urlText: String
    let favoriteGroups: [FavoriteGroup]
    let browserHistory: [BrowserHistoryItem]
    let onGoAction: (String) -> Void
    let onTapLeadingButton: (FavoriteGroup) -> Void
    
    @Binding var isFocused: Bool
    @Binding var displayText: String
    @Binding var filteredSuggestions: [BrowserHistoryItem]
    
    @State private var buttonFrame: CGRect = .zero
    @FocusState private var textFieldFocused: Bool
    
    private let weViewInteractor = Executor.webViewInteractor
    
    var body: some View {
        content
            .onChange(of: isFocused) { _, focused in
                textFieldFocused = focused
                if focused {
                    displayText = urlText
                    updateSuggestions()
                    DispatchQueue.main.async {
                        selectAllText()
                    }
                } else {
                    displayText = getDomain(from: urlText)
                    filteredSuggestions = []
                }
            }
            .onChange(of: textFieldFocused) { _, focused in
                isFocused = focused
            }
            .onChange(of: displayText) { _, newValue in
                if isFocused {
                    updateSuggestions()
                }
            }
            .onAppear {
                displayText = getDomain(from: urlText)
            }
            .onChange(of: urlText) { _, newValue in
                if !isFocused {
                    displayText = getDomain(from: newValue)
                }
            }
    }
    
    var content: some View {
        HStack(alignment: .center, spacing: 12) {
            // Иконка замка/глобуса
            leadingButton
            // Поле ввода
            textField
            // Кнопка очистки или reload
            trailingButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            backgroundContainer
        )
    }
    
     private var textField: some View {
         ZStack {
             // Прозрачная область для расширения тапа
             Color.clear
                 .contentShape(Rectangle())
                 .onTapGesture {
                     if !textFieldFocused {
                         textFieldFocused = true
                     }
                 }
             
             TextField("Search or enter address", text: $displayText)
                 .textFieldStyle(PlainTextFieldStyle())
                 .font(.tm.bodyText)
                 .font(.system(size: 17, weight: .regular))
             
                 .foregroundStyle(.tm.title)
                 .autocorrectionDisabled(true)
                 .keyboardType(.webSearch)
                 .textInputAutocapitalization(.never)
                 .focused($textFieldFocused)
                 .multilineTextAlignment(.leading)
                 .frame(maxWidth: .infinity, alignment: .leading)
                 .onSubmit {
                     onGoAction(displayText)
                     textFieldFocused = false
                 }
         }
         .frame(height: 28)
     }
    
    private var trailingButton: some View {
        Button(action: {
            if isFocused {
                displayText = ""
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .opacity(isFocused ? 1 : 0)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    Color.tm.subTitle.opacity(0.5)
                )
        }
    }
    
    private var leadingButton: some View {
        Menu {
            Section(header: Text("Select Group")) {
                ForEach(favoriteGroups, id: \.id) { group in
                    Button(action: {
                        onTapLeadingButton(group)
                    }) {
                        Text(group.name)
                    }
                }
            }
        } label: {
            Image("star")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .tint(.tm.accent)
        }
        
    }
    
    var backgroundContainer: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.tm.container)
//            .onTapGesture(perform: {
//                if !isFocused { isFocused.toggle() }
//            })
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.tm.border, lineWidth: 1)
            )
    }
    
    private var isSecureConnection: Bool {
        urlText.hasPrefix("https://")
    }
    
    // Функция для извлечения домена из URL
    private func getDomain(from url: String) -> String {
        var cleanUrl = url
        
        // Убираем протокол
        if cleanUrl.hasPrefix("http://") {
            cleanUrl = String(cleanUrl.dropFirst(7))
        } else if cleanUrl.hasPrefix("https://") {
            cleanUrl = String(cleanUrl.dropFirst(8))
        }
        
        // Убираем www.
        if cleanUrl.hasPrefix("www.") {
            cleanUrl = String(cleanUrl.dropFirst(4))
        }
        
        // Извлекаем только домен (убираем path, query, fragment)
        if let slashIndex = cleanUrl.firstIndex(of: "/") {
            cleanUrl = String(cleanUrl[..<slashIndex])
        }
        
        // Убираем порт (если есть)
        if let colonIndex = cleanUrl.firstIndex(of: ":") {
            cleanUrl = String(cleanUrl[..<colonIndex])
        }
        
        return cleanUrl
    }
    
    // Функция для выделения всего текста
    private func selectAllText() {
        // Находим UITextField в иерархии представлений
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            findAndSelectAllInTextField(in: window)
        }
    }
    
    private func findAndSelectAllInTextField(in view: UIView) {
        for subview in view.subviews {
            if let textField = subview as? UITextField {
                // Выделяем весь текст
                textField.selectAll(nil)
                return
            } else {
                findAndSelectAllInTextField(in: subview)
            }
        }
    }
    
    // MARK: - Suggestions Logic
    
    /// Обновляет список подсказок на основе введенного текста
    private func updateSuggestions() {
        // Если текст пустой или слишком короткий, не показываем подсказки
        guard !displayText.trimmingCharacters(in: .whitespaces).isEmpty,
              displayText.count >= 1 else {
            filteredSuggestions = []
            return
        }
        
        // Фильтруем историю по введенному тексту
        let filtered = browserHistory.filtered(by: displayText)
        
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
                let search = displayText.lowercased()
                
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
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isFocused = false
        @State private var displayText = ""
        @State private var suggestions: [BrowserHistoryItem] = []
        
        var body: some View {
            AddressBarView(
                urlText: "https://google.com",
                favoriteGroups: [],
                browserHistory: [
                    BrowserHistoryItem(
                        title: "Google",
                        url: "https://google.com",
                        visitDate: Date()
                    ),
                    BrowserHistoryItem(
                        title: "GitHub - Where the world builds software",
                        url: "https://github.com",
                        visitDate: Date()
                    )
                ],
                onGoAction: { url in },
                onTapLeadingButton: { _ in },
                isFocused: $isFocused,
                displayText: $displayText,
                filteredSuggestions: $suggestions
            )
        }
    }
    
    return PreviewWrapper()
}
