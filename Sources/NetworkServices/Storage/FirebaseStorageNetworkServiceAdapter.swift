//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.05.2022.
//

import Foundation
import FirebaseStorage

public protocol StorageNetworkServiceProtocol {
    func downloadTask(request: LoadRequest, completion: @escaping (Result<Data, Error>) -> ())
    func uploadTask(request: LoadRequest, data: DataWrapper, completion: @escaping (Result<URL, Error>) -> ())
    func deleteData(request: LoadRequest)
}

public final class FirebaseStorageNetworkServiceAdapter {

    private let baseURL: Storage
    
    public init(baseURL: Storage) {
        self.baseURL = baseURL
    }
}

extension FirebaseStorageNetworkServiceAdapter: StorageNetworkServiceProtocol {
    
    public func downloadTask(request: LoadRequest, completion: @escaping (Result<Data, Error>) -> ()) {
        let endPoint = baseURL.reference(forURL: request.path)
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
    
    public func uploadTask(request: LoadRequest, data: DataWrapper, completion: @escaping (Result<URL, Error>) -> ()) {
        baseURL.reference(forURL: request.path).putData(data.value, metadata: data.metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.baseURL.reference(forURL: request.path).downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else { return }
                completion(.success(downloadURL))
            }
        }
    }
    
    public func deleteData(request: LoadRequest) {
        baseURL.reference(forURL: request.path).delete()
    }
}
