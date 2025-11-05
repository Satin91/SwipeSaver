//
//  GestureObserver.swift
//  UntraX
//
//  Created by Артур Кулик.
//

import SwiftUI
import UIKit

/// Внутренний UIView который не блокирует touches, но получает gesture события
class GestureTrackingView: UIView {
    weak var coordinator: GestureCoordinator?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Всегда возвращаем nil чтобы touches проходили сквозь
        // Но gesture recognizers все равно будут получать события через delegate
        return nil
    }
}

/// Координатор для обработки жестов
class GestureCoordinator: NSObject, UIGestureRecognizerDelegate {
    let onGestureDetected: () -> Void
    var menuFrameProvider: (() -> CGRect?)?
    var gestureRecognizers: [UIGestureRecognizer] = []
    weak var targetWindow: UIWindow?
    
    init(onGestureDetected: @escaping () -> Void) {
        self.onGestureDetected = onGestureDetected
    }
    
    func setupRecognizers(on view: UIView) {
        // Добавляем recognizers на parent view hierarchy
        guard let window = view.window else { return }
        targetWindow = window
        
        // Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        window.addGestureRecognizer(tapGesture)
        gestureRecognizers.append(tapGesture)
        
        // Pan Gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        window.addGestureRecognizer(panGesture)
        gestureRecognizers.append(panGesture)
    }
    
    func removeRecognizers() {
        // Удаляем recognizers с window
        gestureRecognizers.forEach { recognizer in
            targetWindow?.removeGestureRecognizer(recognizer)
        }
        gestureRecognizers.removeAll()
        targetWindow = nil
        menuFrameProvider = nil
    }
    
    func setMenuFrameProvider(_ provider: (() -> CGRect?)?) {
        menuFrameProvider = provider
    }
    
    @objc func handleGesture(_ gesture: UIGestureRecognizer) {
        // Проверяем, не произошел ли жест внутри меню
        guard let window = targetWindow else {
            onGestureDetected()
            return
        }
        
        // Получаем координаты touch в window
        let locationInWindow = gesture.location(in: window)
        
        // Получаем frame меню
        guard let menuFrame = menuFrameProvider?(), !menuFrame.isEmpty else {
            print("DEBUG: menuFrame is nil or empty")
            onGestureDetected()
            return
        }
        
        // Проверяем, попадает ли touch в bounds меню
        let isInsideMenu = menuFrame.contains(locationInWindow)
        
        // Закрываем меню только если жест произошел ВНЕ меню
        if !isInsideMenu {
            onGestureDetected()
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

/// Обёртка UIView для отслеживания жестов
struct GestureObserverView: UIViewRepresentable {
    let onGestureDetected: () -> Void
    let shouldObserveGestures: Bool
    let menuFrameProvider: (() -> CGRect?)?
    
    func makeUIView(context: Context) -> GestureTrackingView {
        let view = GestureTrackingView()
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        
        // Устанавливаем menuFrameProvider
        context.coordinator.setMenuFrameProvider(menuFrameProvider)
        
        return view
    }
    
    func updateUIView(_ uiView: GestureTrackingView, context: Context) {
        uiView.coordinator = context.coordinator
        
        // Обновляем menuFrameProvider
        context.coordinator.setMenuFrameProvider(menuFrameProvider)
        
        // Добавляем или удаляем recognizers в зависимости от shouldObserveGestures
        if shouldObserveGestures {
            // Добавляем recognizers если их нет и view уже в hierarchy
            if uiView.window != nil && context.coordinator.gestureRecognizers.isEmpty {
                context.coordinator.setupRecognizers(on: uiView)
            }
        } else {
            // Удаляем recognizers когда не нужно отслеживать
            if !context.coordinator.gestureRecognizers.isEmpty {
                context.coordinator.removeRecognizers()
            }
        }
    }
    
    static func dismantleUIView(_ uiView: GestureTrackingView, coordinator: GestureCoordinator) {
        coordinator.removeRecognizers()
    }
    
    func makeCoordinator() -> GestureCoordinator {
        GestureCoordinator(onGestureDetected: onGestureDetected)
    }
}

/// Модификатор для отслеживания всех жестов на экране
struct GestureObserverModifier: ViewModifier {
    let onGestureDetected: () -> Void
    let shouldObserveGestures: Bool
    let menuFrameProvider: (() -> CGRect?)?
    
    func body(content: Content) -> some View {
        content
            .background(
                GestureObserverView(
                    onGestureDetected: onGestureDetected,
                    shouldObserveGestures: shouldObserveGestures,
                    menuFrameProvider: menuFrameProvider
                )
                .frame(width: 0, height: 0)
            )
    }
}

extension View {
    /// Отслеживать все жесты на экране
    func observeGestures(when condition: Bool = true, menuFrame: (() -> CGRect?)? = nil, onGestureDetected: @escaping () -> Void) -> some View {
        modifier(GestureObserverModifier(
            onGestureDetected: onGestureDetected,
            shouldObserveGestures: condition,
            menuFrameProvider: menuFrame
        ))
    }
}


