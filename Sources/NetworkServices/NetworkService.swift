//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.05.2022.
//

import Foundation
import FirebaseFirestore

public protocol NetworkServiceProtocol {
    func dataTask(with request: NetworkRequest, completion: @escaping (Result<Data, Error>) -> ())
    func collectionSocketTask(with request: NetworkCollectionRequest, completion: @escaping (Result<(added: Data, removed: Data, edited: Data), Error>) -> ()) -> SocketProtocol
    func socketDocumentTask(with request: NetworkDocumentRequest, completion: @escaping (Result<Data, Error>) -> ()) -> SocketProtocol
}

public final class NetworkServiceAdapter {
    private let baseURLFirestore: Firestore
    
    init(firestore: Firestore) {
        self.baseURLFirestore = firestore
    }
}

extension NetworkServiceAdapter: NetworkServiceProtocol {
    
    public func dataTask(with request: NetworkRequest, completion: @escaping (Result<Data, Error>) -> ()) {
        let endPoint = baseURLFirestore.collection(request.path)
        switch request.httpMethod {
        case .get:
            getDataTask(endPoint: endPoint, completion: completion)
        case .set(documentID: let documentID):
            if let documentID = documentID {
                setDataTask(endPoint: endPoint,
                            with: documentID,
                            body: request.body,
                            completion: completion)
            } else {
                setDataTask(endPoint: endPoint,
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

extension NetworkServiceAdapter {
    public func collectionSocketTask(with request: NetworkCollectionRequest, completion: @escaping (Result<(added: Data, removed: Data, edited: Data), Error>) -> ()) -> SocketProtocol {
        let endPoint = baseURLFirestore.collection(request.path)
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
    
    public func socketDocumentTask(with request: NetworkDocumentRequest, completion: @escaping (Result<Data, Error>) -> ()) -> SocketProtocol {
        let endPoint = baseURLFirestore.collection(request.path)
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

private extension NetworkServiceAdapter {
    
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
    
    func setDataTask(endPoint: CollectionReference,
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
    
    func setDataTask(endPoint: CollectionReference,
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

