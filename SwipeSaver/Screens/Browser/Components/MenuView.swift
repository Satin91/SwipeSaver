//
//  BrowserPanelMenu.swift
//  UntraX
//
//  Created by Артур Кулик.
//

import SwiftUI

/// Компонент меню в виде PopOver
struct MenuView<Content: View>: View {
    @Binding var rect: CGRect?
    let content: Content
    @State private var menuFrame: CGRect = .zero
    @State private var calculatedPosition: CGPoint = .zero
    @State private var geometryGlobalOrigin: CGPoint = .zero
    @State private var lastKnownMenuSize: CGSize? = nil // Сохраняем последний размер меню
    
    // Computed property для определения состояния показа меню
    private var isPresented: Bool {
        rect != nil
    }
    
    // Computed property для получения anchorFrame
    private var anchorFrame: CGRect {
        rect ?? .zero
    }
    
    init(rect: Binding<CGRect?>, @ViewBuilder content: () -> Content) {
        self._rect = rect
        self.content = content()
    }
    
    // MARK: - Position Calculation
    
    private func calculatePosition(screenSize: CGSize, geometryOrigin: CGPoint) {
        guard let rect = rect else { return }
        
        // Используем реальный размер меню если есть, иначе последний известный, иначе примерный
        let menuWidth: CGFloat
        let menuHeight: CGFloat
        
        if menuFrame.width > 0 && menuFrame.height > 0 {
            menuWidth = menuFrame.width
            menuHeight = menuFrame.height
            // Сохраняем для следующего раза
            lastKnownMenuSize = CGSize(width: menuWidth, height: menuHeight)
            print("📐 [MenuView] Реальный размер меню: \(menuWidth) x \(menuHeight)")
        } else if let lastSize = lastKnownMenuSize {
            // Используем последний известный размер для мгновенного позиционирования
            menuWidth = lastSize.width
            menuHeight = lastSize.height
            print("📐 [MenuView] Используем кэшированный размер: \(menuWidth) x \(menuHeight)")
        } else {
            // Первый показ - используем примерный размер (будет уточнен после первого рендера)
            menuWidth = 192 // Ширина меню 160 + padding
            menuHeight = 330 // Примерная высота для 6 элементов (~55px каждый)
            print("📐 [MenuView] Используем примерный размер: \(menuWidth) x \(menuHeight)")
        }
        
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Отступ от краев экрана
        let edgePadding: CGFloat = 16
        
        // Конвертируем anchorFrame из глобальных координат в координаты GeometryReader
        // Вычитаем позицию GeometryReader из глобальных координат кнопки
        let localAnchorX = anchorFrame.midX - geometryOrigin.x
        let localAnchorMaxY = anchorFrame.maxY - geometryOrigin.y
        let localAnchorMinY = anchorFrame.minY - geometryOrigin.y
        
        // Начальная позиция X - центрируем относительно кнопки
        var x: CGFloat = localAnchorX
        var y: CGFloat = localAnchorMaxY
        
        // Проверка и корректировка позиции по X с учетом границ экрана
        let menuHalfWidth = menuWidth / 2
        
        // Проверка: выходит ли меню справа от экрана
        if x + menuHalfWidth > screenWidth - edgePadding {
            x = screenWidth - edgePadding - menuHalfWidth
        }
        
        // Проверка: выходит ли меню слева от экрана
        if x - menuHalfWidth < edgePadding {
            x = edgePadding + menuHalfWidth
        }
        
        
        let menuHalfHeight = menuHeight / 2
        let menuSpacing: CGFloat = 0 // Отступ между меню и кнопкой
        
        // Позиционируем меню под кнопкой (по умолчанию)
        // Центр меню = нижний край кнопки + отступ + половина высоты меню
        // Это обеспечит, что верхний край меню будет на anchorFrame.maxY + menuSpacing
        y = localAnchorMaxY + menuSpacing + menuHalfHeight
        
        // Проверка: выходит ли меню снизу экрана
        // Проверяем, помещается ли меню целиком под кнопкой
        if y + menuHalfHeight > screenHeight - edgePadding {
            // Если не помещается снизу, показываем над кнопкой
            // Центр меню = верхний край кнопки - отступ - половина высоты меню
            // Это обеспечит, что нижний край меню будет на anchorFrame.minY - menuSpacing
            y = localAnchorMinY - menuSpacing - menuHalfHeight
            
            // Убеждаемся, что меню не выходит сверху экрана
            if y - menuHalfHeight < edgePadding {
                y = edgePadding + menuHalfHeight
            }
        }
        
        calculatedPosition = CGPoint(x: x, y: y)
    }
    
    var body: some View {
        // Содержимое меню
        GeometryReader { geometry in
            let globalOrigin = geometry.frame(in: .global).origin
            
            VStack(spacing: 0) {
                if isPresented {
                    menuContent
                        .transition(.opacity)
                        .onAppear {
                            geometryGlobalOrigin = globalOrigin
                            calculatePosition(screenSize: geometry.size, geometryOrigin: globalOrigin)
                        }
                        .onChange(of: rect) { _, newRect in
                            // Вычисляем позицию СРАЗУ при изменении rect
                            if newRect != nil {
                                geometryGlobalOrigin = globalOrigin
                                calculatePosition(screenSize: geometry.size, geometryOrigin: globalOrigin)
                            }
                        }
                        .onChange(of: anchorFrame) { _, _ in
                            // Обновляем origin при каждом изменении, чтобы учесть возможные изменения layout
                            geometryGlobalOrigin = globalOrigin
                            calculatePosition(screenSize: geometry.size, geometryOrigin: globalOrigin)
                        }
                        .onChange(of: menuFrame) { _, _ in
                            geometryGlobalOrigin = globalOrigin
                            calculatePosition(screenSize: geometry.size, geometryOrigin: globalOrigin)
                        }
                        .onChange(of: isPresented) { _, newValue in
                            if newValue {
                                geometryGlobalOrigin = globalOrigin
                                calculatePosition(screenSize: geometry.size, geometryOrigin: globalOrigin)
                            }
                        }
                }
            }
            .position(calculatedPosition)
            .animation(.easeInOut(duration: 0.2), value: isPresented)
            .task(id: rect) {
                // Вычисляем позицию синхронно при первом появлении
                if rect != nil {
                    geometryGlobalOrigin = globalOrigin
                    calculatePosition(screenSize: geometry.size, geometryOrigin: globalOrigin)
                }
            }
        }
        .observeGestures(when: isPresented, menuFrame: { menuFrame }) {
            // Закрываем меню при любом жесте ВНЕ меню
            withAnimation(.easeInOut(duration: 0.2)) {
                DispatchQueue.main.async{
                    rect = nil
                }
            }
        }
    }
    
    private var menuContent: some View {
        VStack(spacing: 0) {
            // Заголовок
            // Дочерние View в VStack
            VStack(spacing: 0) {
                content
                    .padding(.vertical, .regular)
                    .padding(.horizontal, .medium)
            }
        }
        .background(.tm.container)
        .cornerRadius(Layout.Radius.medium)
        .shadow(color: Color.tm.shadowColor.opacity(0.65), radius: 30, x: 10, y: 10)
//        .padding(.horizontal, .medium)
        .background(
            GeometryReader { geometry in
                let frame = geometry.frame(in: .global)
                Color.clear
                    .task(id: frame) {
                        menuFrame = frame
                    }
            }
        )
    }
}

/// Строка меню с иконкой и текстом
struct MenuItemRow: View {
    let icon: ImageResource
    let title: String
    let action: () -> Void
    let isShowChevron: Bool
    let showDivider: Bool
    
    @State private var isPressed = false
    
    init(icon: ImageResource, title: String, showDivider: Bool = true, isShowChevron: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.showDivider = showDivider
        self.isShowChevron = isShowChevron
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack(spacing: .regular) {
                    // Иконка
                    Image(icon)
//                        .font(.system(size: 22, weight: .regular))
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.tm.subTitle)
//                        .foregroundStyle(.tm.error)
                        .frame(width: 22, height: 22)
                    
                    // Текст
                    Text(title)
                        .font(.tm.defaultTextMedium)
                        .foregroundColor(.tm.title)
//                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    // Стрелка
                    if isShowChevron {
                        Image(.chevronRight)
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 18, height: 18)
                        //                        .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.tm.subTitle.opacity(0.7))
                    }
                }
                .padding(.vertical, .regular)
                .contentShape(Rectangle())
                .background(
                    Color.tm.backgroundSecondary.opacity(isPressed ? 0.5 : 0)
                )
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .overlay(alignment: .bottom) {
                if showDivider {
                    DividerView()
                }
            }
        }
        .frame(width: 160)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var menuRect: CGRect? = nil
        
        var body: some View {
            ZStack {
                Color.tm.background
                    .ignoresSafeArea()
                
                Button("Показать меню") {
                    if menuRect == nil {
                        menuRect = CGRect(x: 150, y: 100, width: 50, height: 50)
                    } else {
                        menuRect = nil
                    }
                }
                
                MenuView(rect: $menuRect) {
                    MenuItemRow(icon: .star, title: "Избранное") {
                        print("Избранное")
                        menuRect = nil
                    }
                    
                    MenuItemRow(icon: .sun, title: "История") {
                        print("История")
                        menuRect = nil
                    }
                    
                    MenuItemRow(icon: .sun, title: "Статистика") {
                        print("Статистика")
                        menuRect = nil
                    }
                    
                    MenuItemRow(icon: .sun, title: "Поделиться") {
                        print("Поделиться")
                        menuRect = nil
                    }
                    
                    MenuItemRow(icon: .sun, title: "Камера", showDivider: false) {
                        print("Камера")
                        menuRect = nil
                    }
                }
            }
        }
    }
    
    return PreviewWrapper()
}

