//
//  ApiEndpoint.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case noData
    case networkError(Error)
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL адрес"
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .httpError(let statusCode):
            return "HTTP ошибка: \(statusCode)"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Ошибка кодирования: \(error.localizedDescription)"
        case .noData:
            return "Нет данных в ответе"
        case .networkError(let error):
            return "Сетевая ошибка: \(error.localizedDescription)"
        case .timeout:
            return "Превышено время ожидания"
        case .unauthorized:
            return "Требуется авторизация (401)"
        case .forbidden:
            return "Доступ запрещен (403)"
        case .notFound:
            return "Ресурс не найден (404)"
        case .serverError:
            return "Внутренняя ошибка сервера (500)"
        }
    }
}

// MARK: - HTTP Method

/// HTTP методы запросов
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Endpoint Protocol

/// Протокол для эндпоинтов API
protocol APIEndpointProtocol {
    /// Базовый URL
    var baseURL: String { get }
    
    /// Путь к ресурсу
    var path: String { get }
    
    /// HTTP метод
    var method: HTTPMethod { get }
    
    /// Заголовки запроса
    var headers: [String: String]? { get }
    
    /// Тело запроса
    var body: Data? { get }
    
    /// Timeout запроса
    var timeout: TimeInterval { get }
    
    /// Создать URLRequest
    func makeRequest() throws -> URLRequest
}

// MARK: - API Endpoint Default Implementation

extension APIEndpointProtocol {
    /// Базовая реализация создания URLRequest
    func makeRequest() throws -> URLRequest {
        // Формируем полный URL
        let urlString: String
        if baseURL.isEmpty {
            // Если baseURL пустой, path должен содержать полный URL
            urlString = path
        } else {
            urlString = baseURL + path
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        // Создаем запрос
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        // Добавляем заголовки
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Добавляем тело запроса
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}

// MARK: - API Endpoint

/// Эндпоинты API
enum APIEndpoint {
    case fetchSocialVideo(url: String)
}

// MARK: - API Endpoint Implementation

extension APIEndpoint: APIEndpointProtocol {
    
    var baseURL: String {
        switch self {
        case .fetchSocialVideo:
            // Базовый URL будет определяться из полного URL в path
            return ""
        }
    }
    
    var path: String {
        switch self {
        case .fetchSocialVideo:
            return ""
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .fetchSocialVideo:
            return .post
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .fetchSocialVideo:
            return [
                "x-rapidapi-key": "019563167emshba8f6d212ef19abp19a9a1jsn37646a1e9f62",
                "x-rapidapi-host": "social-download-all-in-one.p.rapidapi.com",
                "Content-Type": "application/json"
            ]
        }
    }
    
    /// Параметры запроса
    var parameters: [String: Any] {
        switch self {
        case .fetchSocialVideo(let url):
            return ["url": url]
        }
    }
    
    var body: Data? {
        switch self {
        case .fetchSocialVideo:
            // Для POST запроса параметры должны быть в body как JSON
            return try? JSONSerialization.data(withJSONObject: parameters, options: [])
        }
    }
    
    var timeout: TimeInterval {
        switch self {
        case .fetchSocialVideo:
            return 60
        }
    }
    
    /// Переопределяем makeRequest для создания правильного запроса
    func makeRequest() throws -> URLRequest {
        switch self {
        case .fetchSocialVideo:
            // Формируем полный URL без query параметров
            let urlString = baseURL + path
            guard let finalURL = URL(string: urlString) else {
                throw NetworkError.invalidURL
            }
            
            // Создаем запрос
            var request = URLRequest(url: finalURL)
            request.httpMethod = method.rawValue
            request.timeoutInterval = timeout
            
            // Добавляем заголовки
            headers?.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            // Добавляем body с параметрами в JSON формате
            if let body = body {
                request.httpBody = body
            }
            
            return request
        }
    }
}
