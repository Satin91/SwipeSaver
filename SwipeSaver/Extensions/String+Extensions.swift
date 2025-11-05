//
//  String+Extensions.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

extension String {
    /// Создает AttributedString с выделенными фразами
    /// - Parameters:
    ///   - phrases: Массив фраз для выделения
    ///   - color: Цвет для выделенных фраз
    ///   - font: Шрифт для текста
    ///   - baseColor: Базовый цвет текста
    /// - Returns: AttributedString с выделенными фразами
    public func attributed(
        phrases: [String],
        color: Color,
        font: Font = .openRunde(size: 24),
        baseColor: Color = Color.tm.title
    ) -> AttributedString {
        var attributedString = AttributedString(self)
        
        // Настройки базового шрифта
        attributedString.font = font
        attributedString.foregroundColor = UIColor(baseColor)
        
        // Выделяем указанные фразы
        for phrase in phrases {
            if let range = attributedString.range(of: phrase) {
                attributedString[range].foregroundColor = UIColor(color)
            }
        }
        
        return attributedString
    }
    
    /// Проверяет, является ли строка валидным email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Проверяет, является ли строка валидным URL
    var isValidURL: Bool {
        if let url = URL(string: self) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    /// Удаляет пробелы в начале и конце строки
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
