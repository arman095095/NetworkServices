//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.05.2022.
//

import Foundation

public enum NetworkRequestType {
    case load
    case common(path: String, body: [String: Any])
}

public struct NetworkRequest {
    var httpMethod: HTTPMethod
    var path: String
    var body: [String: Any]
}

public struct NetworkDocumentRequest {
    var path: String
    var documentID: String
}

public struct NetworkCollectionRequest {
    var path: String
}

public struct UploadRequest {
    var path: String
    var data: Data
    var dataType: DataType
}

public struct DownloadRequest {
    var path: String
}
