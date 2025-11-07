//
//  NetworkRepository.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Репозиторий для работы с сетевыми запросами
final class NetworkRepository {
    
    // MARK: - Private Properties
    private let networkService: NetworkService
    
    // MARK: - Initialization
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    // MARK: - Public Methods
    
    /// Выполнить сетевой запрос
    /// - Parameter endpoint: Эндпоинт API
    /// - Returns: Декодированные данные
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        return try await networkService.request(endpoint)
    }
}

