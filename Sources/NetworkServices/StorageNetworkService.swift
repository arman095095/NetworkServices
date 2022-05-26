//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.05.2022.
//

import Foundation
import FirebaseStorage

struct StorageURLComponents {
    enum Parameters: String {
        case audioM4A = "audio/m4a"
        case imageJpeg = "image/jpeg"
    }
}

public enum DataType {
    case image
    case audio
    
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
}

public protocol StorageNetworkServiceProtocol {
    func downloadTask(path: String, completion: @escaping (Result<Data, Error>) -> ())
    func uploadTask(data: Data, path: String, dataType: DataType ,completion: @escaping (Result<URL, Error>) -> ())
    func deleteData(url: String)
}

public final class StorageNetworkServiceAdapter {

    private let storage: Storage
    
    public init(storage: Storage) {
        self.storage = storage
    }
}

extension StorageNetworkServiceAdapter: StorageNetworkServiceProtocol {
    
    public func downloadTask(path: String, completion: @escaping (Result<Data, Error>) -> ()) {
        let endPoint = storage.reference(forURL: path)
        let megaByte = Int64(1*1024*1024)
        endPoint.getData(maxSize: megaByte) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            completion(.success(data))
        }
    }
    
    public func uploadTask(data: Data, path: String, dataType: DataType ,completion: @escaping (Result<URL, Error>) -> ()) {
        storage.reference(forURL: path).putData(data, metadata: dataType.metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.storage.reference(forURL: path).downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else { return }
                completion(.success(downloadURL))
            }
        }
    }
    
    public func deleteData(url: String) {
        storage.reference(forURL: url).delete()
    }
}
