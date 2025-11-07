//
//  WebViewNavigationButton.swift
//  SufrShield
//
//  Created by Артур Кулик on 03.09.2025.
//

import SwiftUI

enum WebViewNavigationButtonType {
    case back
    case forward
    case refresh
    case share
    case menu
    case tabs
    
    var icon: ImageResource {
        switch self {
        case .back:
            return .chevronLeft
        case .forward:
            return .chevronRight
        case .refresh:
            return .reload
        case .share:
            return .share
        case .menu:
            return .menu1 // Современная сетка для меню
        case .tabs:
            return .browserTabs
        }
    }
    
    var isEnabled: Bool {
        switch self {
        case .back, .forward:
            return false // Будет передаваться извне
        case .refresh, .share, .menu, .tabs:
            return true
        }
    }
}

struct WebViewNavigationButton: View {
    let type: WebViewNavigationButtonType
    let action: () -> Void
    let isEnabled: Bool
    
    @State private var isPressed = false
    
    init(_ type: WebViewNavigationButtonType, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.type = type
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Иконка
                Image(type.icon)
//                    .font(.system(size: 17, weight: .semibold))
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(
                        LinearGradient(
                            colors: isEnabled ? [
                                Color.tm.title,
                                Color.tm.title.opacity(0.9)
                            ] : [
                                Color.tm.subTitle.opacity(0.5),
                                Color.tm.subTitle.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 40, height: 40)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}
