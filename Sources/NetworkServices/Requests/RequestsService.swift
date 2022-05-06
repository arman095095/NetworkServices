//
//  File.swift
//  
//
//  Created by Арман Чархчян on 06.05.2022.
//

import FirebaseFirestore

public protocol RequestsServiceProtocol: AnyObject {
    func send(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ())
    func accept(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ())
    func deny(toID: String, fromID: String)
    func friendIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func waitingIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func requestIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
}

public final class RequestsService {
    private let networkServiceRef: Firestore

    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    public init(networkService: Firestore) {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        networkService.settings = settings
        self.networkServiceRef = networkService
    }
}

extension RequestsService: RequestsServiceProtocol {
    public func friendIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.friendIDs.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
    
    public func waitingIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.waitings.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
    
    public func requestIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.requests.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
    
    public func send(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ()) {
        usersRef.document(toID).collection(URLComponents.Paths.requests.rawValue).document(fromID).setData( [URLComponents.Parameters.userID.rawValue:fromID]) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.usersRef.document(fromID).collection(URLComponents.Paths.waitings.rawValue).document(toID).setData([URLComponents.Parameters.userID.rawValue:toID]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    public func accept(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ()) {
        usersRef.document(fromID).collection(URLComponents.Paths.waitings.rawValue).document(toID).delete()
        usersRef.document(toID).collection(URLComponents.Paths.requests.rawValue).document(fromID).delete()
        
        usersRef.document(fromID).collection(URLComponents.Paths.friendIDs.rawValue).document(toID).setData( [URLComponents.Parameters.friendID.rawValue: toID]) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.usersRef.document(toID).collection(URLComponents.Paths.friendIDs.rawValue).document(fromID).setData([URLComponents.Parameters.friendID.rawValue: fromID]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    public func deny(toID: String, fromID: String) {
        usersRef.document(fromID).collection(URLComponents.Paths.waitings.rawValue).document(toID).delete()
        usersRef.document(toID).collection(URLComponents.Paths.requests.rawValue).document(fromID).delete()
    }
}
