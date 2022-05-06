//
//  AccountService.swift
//  
//
//  Created by Арман Чархчян on 10.04.2022.
//

import Foundation
import FirebaseFirestore
import UIKit

public protocol AccountServiceProtocol {
    func createAccount(accountID: String,
                       profile: ProfileNetworkModelProtocol,
                       completion: @escaping (Result<Void, Error>) -> Void)
    func setOnline(accountID: String)
    func setOffline(accountID: String)
    func recoverAccount(accountID: String,
                        completion: @escaping (Result<Void, Error>) -> Void)
    func editAccount(accountID: String,
                     profile: ProfileNetworkModelProtocol,
                     completion: @escaping (Result<Void, Error>) -> Void)
    func removeAccount(accountID: String,
                       completion: @escaping (Error?) -> Void)
    func blockUser(accountID: String,
                   userID: String,
                   complition: @escaping (Result<Void,Error>) -> Void)
    func unblockUser(accountID: String,
                     userID: String, complition: @escaping (Result<Void,Error>) -> Void)
    func getBlockedIds(accountID: String,
                       completion: @escaping (Result<[String],Error>) -> Void)
    func getIamBlockedIDs(accountID: String,
                          completion: @escaping (Result<[String],Error>) -> Void)
}

public protocol RequestsServiceProtocol: AnyObject {
    func send(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ())
    func accept(toID: String, fromID: String, completion: @escaping (Result<Void, Error>) -> ())
    func deny(toID: String, fromID: String)
    func friendIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func waitingIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func requestIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
}

public final class AccountService {
    
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

extension AccountService: AccountServiceProtocol {
    
    public func getBlockedIds(accountID: String, completion: @escaping (Result<[String], Error>) -> Void) {
        var ids: [String] = []
        usersRef.document(accountID).collection(URLComponents.Paths.blocked.rawValue).getDocuments { (query, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            query.documents.forEach { doc in
                if let id = doc.data()[URLComponents.Parameters.id.rawValue] as? String {
                    ids.append(id)
                }
            }
            completion(.success(ids))
        }
    }
    
    public func getIamBlockedIDs(accountID: String, completion: @escaping (Result<[String], Error>) -> Void) {
        var ids: [String] = []
        usersRef.document(accountID).collection(URLComponents.Paths.iamblocked.rawValue).getDocuments { (query, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            query.documents.forEach { doc in
                if let id = doc.data()[URLComponents.Parameters.id.rawValue] as? String {
                    ids.append(id)
                }
            }
            completion(.success(ids))
        }
    }
    
    
    public func createAccount(accountID: String,
                              profile: ProfileNetworkModelProtocol,
                              completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
            return
        }
        self.setAccount(accountID: accountID, user: profile, completion: completion)
    }
    
    public func setOnline(accountID: String) {
        usersRef.document(accountID).updateData([URLComponents.Parameters.online.rawValue: true])
    }
    
    public func setOffline(accountID: String) {
        var dict: [String: Any] = [URLComponents.Parameters.lastActivity.rawValue: FieldValue.serverTimestamp()]
        dict[URLComponents.Parameters.online.rawValue] = false
        usersRef.document(accountID).updateData(dict) { _ in }
    }
    
    public func recoverAccount(accountID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
            return
        }
        usersRef.document(accountID).updateData([URLComponents.Parameters.removed.rawValue: false], completion: { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        })
    }
    
    public func removeAccount(accountID: String, completion: @escaping (Error?) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(ConnectionError.noInternet)
            return
        }
        usersRef.document(accountID).updateData([URLComponents.Parameters.removed.rawValue: true]) { (error) in
            if let error = error {
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    public func editAccount(accountID: String,
                            profile: ProfileNetworkModelProtocol,
                            completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
            return
        }
        setAccount(accountID: accountID, user: profile, completion: completion)
    }
    
    public func blockUser(accountID: String,
                          userID: String,
                          complition: @escaping (Result<Void,Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            complition(.failure(ConnectionError.noInternet))
            return
        }
        usersRef.document(accountID).collection(URLComponents.Paths.blocked.rawValue).document(userID).setData([URLComponents.Parameters.id.rawValue: userID]) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                complition(.failure(error))
            }
            self.usersRef.document(userID).collection(URLComponents.Paths.iamblocked.rawValue).document(accountID).setData([URLComponents.Parameters.id.rawValue: accountID]) { (error) in
                if let error = error {
                    complition(.failure(error))
                    return
                }
                complition(.success(()))
            }
        }
    }
    
    public func unblockUser(accountID: String,
                            userID: String,
                            complition: @escaping (Result<Void,Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            complition(.failure(ConnectionError.noInternet))
            return
        }
        usersRef.document(accountID).collection(URLComponents.Paths.blocked.rawValue).document(userID).delete { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                complition(.failure(error))
                return
            }
            self.usersRef.document(userID).collection(URLComponents.Paths.iamblocked.rawValue).document(accountID).delete { (error) in
                if let error = error {
                    complition(.failure(error))
                    return
                }
                complition(.success(()))
            }
        }
    }
}

extension AccountService: RequestsServiceProtocol {
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

private extension AccountService {
    
    func setAccount(accountID: String,
                    user: ProfileNetworkModelProtocol,
                    completion: @escaping (Result<Void,Error>) -> Void) {
        self.usersRef.document(accountID).setData(user.convertModelToDictionary()) { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
}
