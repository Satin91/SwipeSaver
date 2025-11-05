//
//  ExampleViewModel.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI
import Combine

/// ViewModel для ExampleView
@MainActor
final class ExampleViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var data: String = ""
    
    // MARK: - Private Properties
    private let repository = Executor.exampleRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Загрузить данные
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Симуляция загрузки данных
            try await Task.sleep(nanoseconds: 1_000_000_000)
            data = "Data loaded successfully!"
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Обновить данные
    func refreshData() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Подписка на изменения
    }
}

