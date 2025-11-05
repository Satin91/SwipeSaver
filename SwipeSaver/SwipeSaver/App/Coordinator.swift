//
//  Coordinator.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

/// Координатор навигации
/// Управляет всей навигацией в приложении
final class Coordinator: ObservableObject {
    // MARK: - Published Properties
    @Published var tabsPaths = [NavigationPath(), NavigationPath(), NavigationPath()]
    @Published var mainPath = NavigationPath()
    @Published var presentedScreen: Screen? = nil
    
    // MARK: - Navigation Methods
    
    /// Показать экран как fullScreenCover
    func fullScreenCover(to screen: Screen) {
        presentedScreen = screen
    }
    
    /// Навигация вперед (push)
    func push(to screen: Screen) {
        mainPath.append(screen)
    }
    
    /// Навигация назад (pop)
    func pop() {
        mainPath.removeLast()
    }
    
    /// Создание View для экрана
    @ViewBuilder 
    func build(screen: Screen) -> some View {
        switch screen {
        case .example:
            ExampleView()
        }
    }
}

