//
//  BackgroundGradient.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 07.11.2025.
//

import SwiftUI

struct BackgroundGradient: View {
    var body: some View {
        ZStack(content: {
            Color.tm.background
            LinearGradient(
                colors: [
                        Color(hex: "1a1410"),  // Глубокий коричнево-чёрный
                        Color(hex: "2d1b13"),  // Тёмный шоколад
                        Color(hex: "3d2417")   // Каштановый
                    ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .opacity(0.15)
        })
        .ignoresSafeArea(.all)
    }
}

#Preview {
    BackgroundGradient()
}
