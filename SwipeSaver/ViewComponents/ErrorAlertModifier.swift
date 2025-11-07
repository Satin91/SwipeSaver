//
//  AlertModifier.swift
//  SurfShield
//
//  Created by Артур Кулик on 11.10.2025.
//

import SwiftUI

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    var okButtonTapped: () -> Void
    
    var errorMessage: String {
        return error?.localizedDescription ?? "Unknown error occurred"
    }
    
    var errorTitle: String {
        return "Error"
    }
    
    func body(content: Content) -> some View {
        content
            .alert(errorTitle, isPresented: .constant(error != nil), presenting: error) { _ in
                Button("OK", role: .cancel) {
                    error = nil
                    okButtonTapped()
                }
            } message: { _ in
                Text(errorMessage)
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, okButtonTapped: @escaping () -> Void = { } ) -> some View {
        modifier(ErrorAlertModifier(error: error, okButtonTapped: okButtonTapped))
    }
}
