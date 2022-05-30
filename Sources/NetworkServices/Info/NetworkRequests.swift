//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.05.2022.
//

import Foundation

public struct NetworkRequest {
    var httpMethod: HTTPMethod
    var path: String
    var body: [String: Any]
    
    public init(httpMethod: HTTPMethod, path: String, body: [String: Any]) {
        self.httpMethod = httpMethod
        self.path = path
        self.body = body
    }
}

public struct NetworkSocketDocumentRequest {
    var path: String
    var documentID: String
    
    public init(path: String, documentID: String) {
        self.path = path
        self.documentID = documentID
    }
}

public struct NetworkSocketCollectionRequest {
    var path: String
    
    public init(path: String) {
        self.path = path
    }
}
