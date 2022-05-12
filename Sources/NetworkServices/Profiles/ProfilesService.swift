//
//  ProfilesService.swift
//  
//
//  Created by Арман Чархчян on 10.04.2022.
//

import FirebaseFirestore

public protocol ProfilesServiceProtocol {
    func getProfileInfo(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol,Error>) -> ())
    func getFirstProfilesIDs(count: Int, completion: @escaping (Result<[String],Error>) -> Void)
    func getNextProfilesIDs(count: Int, completion: @escaping (Result<[String],Error>) -> Void)
    func initProfileSocket(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol, Error>) -> Void) -> SocketProtocol
}

final class ProfilesService {
    private let networkServiceRef: Firestore
    private var lastProfile: DocumentSnapshot?
    
    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    init(networkService: Firestore) {
        self.networkServiceRef = networkService
    }
}

extension ProfilesService: ProfilesServiceProtocol {
    
    public func initProfileSocket(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol, Error>) -> Void) -> SocketProtocol {
        let listener = usersRef.document(userID).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot,
                  let data = snapshot.data(),
                  let profile = ProfileNetworkModel(dict: data) else { return }
            completion(.success(profile))
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }

    public func getFirstProfilesIDs(count: Int, completion: @escaping (Result<[String],Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        let query = usersRef.order(by: URLComponents.Parameters.lastActivity.rawValue, descending: true).limit(to: count)
        getFirstUsersIDs(query: query, completion: completion)
    }
    
    public func getNextProfilesIDs(count: Int, completion: @escaping (Result<[String],Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        let query = usersRef.order(by: URLComponents.Parameters.lastActivity.rawValue, descending: true).limit(to: count)
        getNextUsersIDs(count: count, query: query, completion: completion)
    }

    public func getProfileInfo(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol,Error>) -> ()) {
        usersRef.document(userID).getDocument { [weak self] (documentSnapshot, error) in
            if let error = error  {
                completion(.failure(error))
                return
            }
            if let dict = documentSnapshot?.data() {
                if var muser = ProfileNetworkModel(dict: dict) {
                    self?.getProfilePostsCount(userID: userID) { (result) in
                        switch result {
                        case .success(let count):
                            muser.postsCount = count
                            completion(.success(muser))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.failure(GetUserInfoError.convertData))
                }
            } else {
                completion(.failure(GetUserInfoError.getData))
            }
        }
    }
}

private extension ProfilesService {

    func getProfilePostsCount(userID: String, completion: @escaping (Result<Int,Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.posts.rawValue).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            let count = querySnapshot.count
            completion(.success(count))
        }
    }

    func getFirstUsersIDs(query: Query, completion: @escaping (Result<[String],Error>) -> Void) {
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            self.lastProfile = querySnapshot.documents.last
            completion(.success(querySnapshot.documents.map { $0.documentID }))
        }
    }
    
    func getNextUsersIDs(count: Int, query: Query, completion: @escaping (Result<[String],Error>) -> Void) {
        guard let lastDocument = lastProfile else { return }
        query.start(afterDocument: lastDocument).limit(to: count).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            self.lastProfile = querySnapshot.documents.last
            completion(.success(querySnapshot.documents.map { $0.documentID }))
        }
    }
}
