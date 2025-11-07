//
//  NetworkService.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

/// Сервис для работы с сетевыми запросами
final class NetworkService {
    
    // MARK: - Singleton
    static let shared = NetworkService()
    
    // MARK: - Properties
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        
        // Настройка декодера
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Public Methods
    
    /// Выполнить запрос с декодированием ответа
    /// - Parameter endpoint: Эндпоинт API
    /// - Returns: Декодированные данные
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Создаем URLRequest из эндпоинта
        let urlRequest = try endpoint.makeRequest()
        
        // Выполняем запрос
        let (data, response) = try await performRequest(urlRequest)
        
        // Отладочный вывод JSON
        #if DEBUG
        print("🔍 [NetworkService] Отладочный вывод JSON ответа:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        } else if let jsonString = String(data: data, encoding: .utf8) {
            print(jsonString)
        } else {
            print("⚠️ Не удалось преобразовать данные в JSON строку")
            print("📦 Размер данных: \(data.count) байт")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 Ожидаемый тип для декодирования: \(T.self)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        #endif
        
        // Декодируем ответ
        do {
            let decodedData = try decoder.decode(T.self, from: data)
            return decodedData
        } catch {
            #if DEBUG
            print("❌ [NetworkService] Ошибка декодирования:")
            print("Тип: \(T.self)")
            print("Ошибка: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("Детали:")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("  - Type mismatch: ожидался \(type), путь: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("  - Value not found: \(type), путь: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("  - Key not found: \(key.stringValue), путь: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("  - Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("  - Unknown error: \(decodingError)")
                }
            }
            #endif
            throw NetworkError.decodingError(error)
        }
    }
    
    /// Выполнить запрос без декодирования (возвращает сырые данные)
    /// - Parameter endpoint: Эндпоинт API
    /// - Returns: Сырые данные
    func request(_ endpoint: APIEndpoint) async throws -> Data {
        // Создаем URLRequest из эндпоинта
        let urlRequest = try endpoint.makeRequest()
        
        // Выполняем запрос
        let (data, _) = try await performRequest(urlRequest)
        
        return data
    }
    
    /// Выполнить запрос без ожидания ответа
    /// - Parameter endpoint: Эндпоинт API
    func request(_ endpoint: APIEndpoint) async throws {
        // Создаем URLRequest из эндпоинта
        let urlRequest = try endpoint.makeRequest()
        
        // Выполняем запрос
        _ = try await performRequest(urlRequest)
    }
    
    // MARK: - Private Methods
    
    /// Выполнить сетевой запрос
    /// - Parameter request: URLRequest
    /// - Returns: Данные и HTTP ответ
    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Выполняем запрос
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Проверяем тип ошибки
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw NetworkError.timeout
                default:
                    throw NetworkError.networkError(error)
                }
            }
            throw NetworkError.networkError(error)
        }
        
        // Проверяем HTTP ответ
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Обрабатываем статус код
        switch httpResponse.statusCode {
        case 200...299:
            return (data, httpResponse)
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

