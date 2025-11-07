//
//  InfoAlertModifier.swift
//  SurfShield
//
//  Created by Артур Кулик on 11.10.2025.
//

import SwiftUI

enum InfoAlertStyle {
    case info // Только OK кнопка
    case destructive // Cancel + Delete кнопки
}

struct InfoAlert {
    var title: String
    var text: String
    var style: InfoAlertStyle
    var deleteTitle: String // Название кнопки удаления
    
    init(
        title: String,
        text: String,
        style: InfoAlertStyle = .info,
        deleteTitle: String = "Delete"
    ) {
        self.title = title
        self.text = text
        self.style = style
        self.deleteTitle = deleteTitle
    }
}

struct InfoAlertModifier: ViewModifier {
    @Binding var infoAlert: InfoAlert?
    var onDismiss: (() -> Void)?
    var onDelete: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                infoAlert?.title ?? "",
                isPresented: .constant(infoAlert != nil),
                presenting: infoAlert
            ) { alert in
                switch alert.style {
                case .info:
                    // Простой алерт с OK кнопкой
                    Button("OK", role: .cancel) {
                        onDismiss?()
                        infoAlert = nil
                    }
                    
                case .destructive:
                    // Алерт с подтверждением удаления
                    Button("Cancel", role: .cancel) {
                        onDismiss?()
                        infoAlert = nil
                    }
                    
                    Button(alert.deleteTitle, role: .destructive) {
                        onDelete?()
                        infoAlert = nil
                    }
                }
            } message: { alert in
                Text(alert.text)
            }
    }
}

extension View {
    /// Show info alert with custom title and message
    /// - Parameters:
    ///   - alert: Binding to InfoAlert
    ///   - onDismiss: Callback when dismissed (OK or Cancel)
    ///   - onDelete: Callback when delete is confirmed (only for .destructive style)
    func infoAlert(
        alert: Binding<InfoAlert?>,
        onDismiss: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) -> some View {
        modifier(InfoAlertModifier(
            infoAlert: alert,
            onDismiss: onDismiss,
            onDelete: onDelete
        ))
    }
}
