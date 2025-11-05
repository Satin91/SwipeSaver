//
//  InfoAlertModifier.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

// MARK: - Info Alert Model

struct InfoAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Info Alert Modifier

struct InfoAlertModifier: ViewModifier {
    @Binding var alert: InfoAlert?
    
    func body(content: Content) -> some View {
        content
            .alert(item: $alert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension View {
    /// Показывает info alert
    func infoAlert(alert: Binding<InfoAlert?>) -> some View {
        modifier(InfoAlertModifier(alert: alert))
    }
}
