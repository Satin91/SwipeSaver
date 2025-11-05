//
//  DividerView.swift
//  UntraX
//
//  Created by Артур Кулик.
//

import SwiftUI

/// Компонент делителя из двух полосок
struct DividerView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Верхняя полоска - темный цвет
            Rectangle()
                .fill(.tm.title.opacity(0.04))
                .frame(height: 1)
            
            // Нижняя полоска - белый цвет
            Rectangle()
                .fill(.tm.backgroundTertiary.opacity(0.8))
                .frame(height: 1)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Разделитель")
        
        DividerView()
        
        Text("Еще контент")
    }
    .padding()
    .background(Color.tm.background)
}

