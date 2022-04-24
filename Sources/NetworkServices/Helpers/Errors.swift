//
//  File.swift
//  
//
//  Created by Арман Чархчян on 11.04.2022.
//

import Foundation

public enum GetUserInfoError: LocalizedError {
    case getData
    case convertData
    
    public var errorDescription: String? {
        switch self {
        case .getData:
            return NSLocalizedString("Ошибка получения данных", comment: "")
        case .convertData:
            return NSLocalizedString("Ошибка конвертации данных", comment: "")
        }
    }
}

public enum ConnectionError: LocalizedError {
    case noInternet
    public var errorDescription: String? {
        switch self {
        case .noInternet:
            return "Проверьте подключение к интернету"
        }
    }
}
