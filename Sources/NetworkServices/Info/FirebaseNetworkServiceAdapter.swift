//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.05.2022.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

public protocol NetworkServiceProtocol {
    func dataTask(with request: NetworkRequest, completion: @escaping (Result<Data, Error>) -> ())
    func collectionSocketTask(with request: NetworkSocketCollectionRequest, completion: @escaping (Result<(added: Data, removed: Data, edited: Data), Error>) -> ()) -> SocketProtocol
    func socketDocumentTask(with request: NetworkSocketDocumentRequest, completion: @escaping (Result<Data, Error>) -> ()) -> SocketProtocol
    func downloadTask(request: LoadRequest, completion: @escaping (Result<Data, Error>) -> ())
    func uploadTask(request: LoadRequest, data: DataWrapper, completion: @escaping (Result<URL, Error>) -> ())
    func deleteData(request: LoadRequest)
}

public final class FirebaseNetworkServiceAdapter {
    private let baseFirestoreURL: Firestore
    private let baseStorageURL: Storage
    private let baseAuthURL: Auth
    
    init(baseFirestoreURL: Firestore, baseStorageURL: Storage, baseAuthURL: Auth) {
        self.baseFirestoreURL = baseFirestoreURL
        self.baseStorageURL = baseStorageURL
        self.baseAuthURL = baseAuthURL
    }
}

extension FirebaseNetworkServiceAdapter: NetworkServiceProtocol {
    public func downloadTask(request: LoadRequest, completion: @escaping (Result<Data, Error>) -> ()) {
        let endPoint = baseStorageURL.reference(forURL: request.path)
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
        baseStorageURL.reference(forURL: request.path).putData(data.value, metadata: data.metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.baseStorageURL.reference(forURL: request.path).downloadURL { (url, error) in
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
        baseStorageURL.reference(forURL: request.path).delete()
    }
    
    public func dataTask(with request: NetworkRequest, completion: @escaping (Result<Data, Error>) -> ()) {
        let endPoint = baseFirestoreURL.collection(request.path)
        switch request.httpMethod {
        case .get:
            getDataTask(endPoint: endPoint, completion: completion)
        case .post(documentID: let documentID):
            if let documentID = documentID {
                postDataTask(endPoint: endPoint,
                            with: documentID,
                            body: request.body,
                            completion: completion)
            } else {
                postDataTask(endPoint: endPoint,
                            body: request.body,
                            completion: completion)
            }
        case .update(documentID: let documentID):
            updateDataTask(endPoint: endPoint,
                           with: documentID,
                           body: request.body,
                           completion: completion)
        case .delete(documentID: let documentID):
            endPoint.document(documentID).delete()
        }
    }
}

extension FirebaseNetworkServiceAdapter {
    public func collectionSocketTask(with request: NetworkSocketCollectionRequest, completion: @escaping (Result<(added: Data, removed: Data, edited: Data), Error>) -> ()) -> SocketProtocol {
        let endPoint = baseFirestoreURL.collection(request.path)
        let listener = endPoint.addSnapshotListener { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            var addedJson: [[String: Any]] = []
            var editedJson: [[String: Any]] = []
            var removedJson: [[String: Any]] = []
            guard let querySnapshot = query else { return }
            querySnapshot.documentChanges.forEach { change in
                switch change.type {
                case .added:
                    let json = change.document.data()
                    addedJson.append(json)
                case .modified:
                    let json = change.document.data()
                    editedJson.append(json)
                case .removed:
                    let json = change.document.data()
                    removedJson.append(json)
                }
            }
            guard let addedData = try? JSONSerialization.data(withJSONObject: addedJson, options: []) else { return }
            guard let editedData = try? JSONSerialization.data(withJSONObject: editedJson, options: []) else { return }
            guard let removedData = try? JSONSerialization.data(withJSONObject: removedJson, options: []) else { return }
            completion(.success((added: addedData, removed: removedData, edited: editedData)))
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func socketDocumentTask(with request: NetworkSocketDocumentRequest, completion: @escaping (Result<Data, Error>) -> ()) -> SocketProtocol {
        let endPoint = baseFirestoreURL.collection(request.path)
        let listener = endPoint.document(request.documentID).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot,
                  let json = snapshot.data() else { return }
            guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else { return }
            completion(.success(data))
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
}

private extension FirebaseNetworkServiceAdapter {
    
    func getDataTask(endPoint: CollectionReference, completion: @escaping (Result<Data, Error>) -> ()) {
        endPoint.getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            let dicts: [[String: Any]] = query.documents.map { $0.data() }
            guard let data = try? JSONSerialization.data(withJSONObject: dicts, options: []) else { return }
            completion(.success(data))
        }
    }
    
    func postDataTask(endPoint: CollectionReference,
                     with documentID: String,
                     body: [String: Any],
                     completion: @escaping (Result<Data, Error>) -> ()) {
        endPoint.document(documentID).setData(body) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = try? JSONSerialization.data(withJSONObject: body, options: []) else { return }
            completion(.success(data))
        }
    }
    
    func postDataTask(endPoint: CollectionReference,
                     body: [String: Any],
                     completion: @escaping (Result<Data, Error>) -> ()) {
        endPoint.addDocument(data: body) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = try? JSONSerialization.data(withJSONObject: body, options: []) else { return }
            completion(.success(data))
        }
    }
    
    func updateDataTask(endPoint: CollectionReference,
                        with documentID: String,
                        body: [String: Any],
                        completion: @escaping (Result<Data, Error>) -> ()) {
        endPoint.document(documentID).updateData(body) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = try? JSONSerialization.data(withJSONObject: body, options: []) else { return }
            completion(.success(data))
        }
    }
}

