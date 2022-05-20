//
//  File.swift
//  
//
//  Created by Арман Чархчян on 06.05.2022.
//

import FirebaseFirestore

public protocol AccountContentNetworkServiceProtocol {
    func friendIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func waitingIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func requestIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func removeFriend(with friendID: String, from id: String, completion: @escaping (Result<Void, Error>) -> ())
    func deny(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ())
    func cancelRequest(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ())
}

final class AccountContentNetworkService {
    private let networkServiceRef: Firestore

    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    init(networkService: Firestore) {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        networkService.settings = settings
        self.networkServiceRef = networkService
    }
}

extension AccountContentNetworkService: AccountContentNetworkServiceProtocol {
    public func removeFriend(with friendID: String, from id: String, completion: @escaping (Result<Void, Error>) -> ()) {
        usersRef.document(id).collection(URLComponents.Paths.friendIDs.rawValue).document(friendID).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.usersRef.document(friendID).collection(URLComponents.Paths.friendIDs.rawValue).document(id).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
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
        usersRef.document(userID).collection(URLComponents.Paths.waitingUsers.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
    
    public func requestIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.sendedRequests.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
    
    public func deny(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ()) {
        usersRef.document(fromID).collection(URLComponents.Paths.waitingUsers.rawValue).document(toID).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.usersRef.document(toID).collection(URLComponents.Paths.sendedRequests.rawValue).document(fromID).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
        
    }
    
    public func cancelRequest(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ()) {
        usersRef.document(fromID).collection(URLComponents.Paths.sendedRequests.rawValue).document(toID).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.usersRef.document(toID).collection(URLComponents.Paths.waitingUsers.rawValue).document(fromID).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
        
    }
}

