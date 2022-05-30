//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.05.2022.
//

import Foundation

public enum HTTPMethod {
    case get
    case post(documentID: String?)
    case update(documentID: String)
    case delete(documentID: String)
}
