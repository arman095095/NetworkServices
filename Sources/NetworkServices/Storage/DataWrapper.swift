//
//  File.swift
//  
//
//  Created by Арман Чархчян on 30.05.2022.
//

import Foundation
import FirebaseStorage

public enum DataWrapper {
    case image(data: Data)
    case audio(data: Data)
    
    var metadata: StorageMetadata {
        switch self {
        case .image:
            let metadata = StorageMetadata()
            metadata.contentType = StorageURLComponents.Parameters.imageJpeg.rawValue
            return metadata
        case .audio:
            let metadata = StorageMetadata()
            metadata.contentType = StorageURLComponents.Parameters.audioM4A.rawValue
            return metadata
        }
    }
    
    var value: Data {
        switch self {
        case .image(data: let data):
            return data
        case .audio(data: let data):
            return data
        }
    }
}

private extension DataWrapper {
    struct StorageURLComponents {
        enum Parameters: String {
            case audioM4A = "audio/m4a"
            case imageJpeg = "image/jpeg"
        }
    }
}
