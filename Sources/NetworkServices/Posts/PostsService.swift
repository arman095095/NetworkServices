//
//  FirebaseManager + Extension.swift
//  diffibleData
//
//  Created by Arman Davidoff on 24.11.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import FirebaseFirestore

public protocol PostsServiceProtocol {
    func createPost(accountID: String,
                    post: PostNetworkModelProtocol,
                    completion: @escaping (Result<Void,Error>) -> Void)
    func getUserFirstPosts(count: Int,
                           userID: String,
                           completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getUserNextPosts(count: Int,
                          userID: String,
                          completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getAllNextPosts(count: Int,
                         completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getAllFirstPosts(count: Int,
                          completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getPostLikersIDs(postID: String, completion: @escaping (Result<[String],Error>) -> ())
    func deletePost(accountID: String, postID: String)
    func likePost(accountID: String, postID: String, ownerID: String)
    func unlikePost(accountID: String, postID: String, ownerID: String)
}

public final class PostsService {
    private let networkServiceRef: Firestore
    private var lastPostOfAll: DocumentSnapshot?
    private var lastPostUser: DocumentSnapshot?
    
    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    private var postsRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.posts.rawValue)
    }
    
    public init(networkService: Firestore) {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        networkService.settings = settings
        self.networkServiceRef = networkService
    }
}

extension PostsService: PostsServiceProtocol {
    
    public func createPost(accountID: String, post: PostNetworkModelProtocol, completion: @escaping (Result<Void,Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
            return
        }
        let postDict = post.convertModelToDictionary()
        postsRef.document(post.id).setData(postDict) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            self.usersRef.document(accountID).collection(URLComponents.Paths.posts.rawValue).document(post.id).setData(postDict) { (error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    public func getAllFirstPosts(count: Int, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        var posts = [PostNetworkModelProtocol]()
        postsRef.order(by: URLComponents.Parameters.date.rawValue, descending: true).limit(to: count).getDocuments() { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            guard !querySnapshot.documents.isEmpty else  {
                completion(.success([]))
                return
            }
            querySnapshot.documents.forEach { (documentSnapshot) in
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    posts.append(post)
                }
                if querySnapshot.documents.last == documentSnapshot {
                    self.lastPostOfAll = documentSnapshot
                }
            }
            completion(.success(posts))
        }
    }
    
    public func getAllNextPosts(count: Int, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        guard let lastDocument = lastPostOfAll else { return }
        var posts = [PostNetworkModelProtocol]()
        postsRef.order(by: URLComponents.Parameters.date.rawValue, descending: true).start(afterDocument: lastDocument).limit(to: count).getDocuments() { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            guard !querySnapshot.documents.isEmpty else  {
                completion(.success([]))
                return
            }
            querySnapshot.documents.forEach { (documentSnapshot) in
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    posts.append(post)
                }
                if querySnapshot.documents.last == documentSnapshot {
                    self.lastPostOfAll = documentSnapshot
                }
            }
            completion(.success(posts))
        }
    }
    
    public func getUserFirstPosts(count: Int, userID: String, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        var posts = [PostNetworkModelProtocol]()
        usersRef.document(userID).collection(URLComponents.Paths.posts.rawValue).order(by: URLComponents.Parameters.date.rawValue, descending: true).limit(to: count).getDocuments() { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            guard !querySnapshot.documents.isEmpty else  {
                completion(.success([]))
                return
            }
            querySnapshot.documents.forEach { (documentSnapshot) in
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    posts.append(post)
                }
                if querySnapshot.documents.last == documentSnapshot {
                    self.lastPostUser = documentSnapshot
                }
            }
            completion(.success(posts))
        }
    }
    
    
    public func getUserNextPosts(count: Int, userID: String, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        guard let lastDocument = lastPostUser else { return }
        var posts = [PostNetworkModelProtocol]()
        usersRef.document(userID).collection(URLComponents.Paths.posts.rawValue).order(by: URLComponents.Parameters.date.rawValue, descending: true).start(afterDocument: lastDocument).limit(to: count).getDocuments() { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            guard !querySnapshot.documents.isEmpty else  {
                completion(.success([]))
                return
            }
            querySnapshot.documents.forEach { (documentSnapshot) in
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    posts.append(post)
                }
                if querySnapshot.documents.last == documentSnapshot {
                    self.lastPostUser = documentSnapshot
                }
            }
            completion(.success(posts))
        }
    }
    
    public func deletePost(accountID: String, postID: String) {
        postsRef.document(postID).collection(URLComponents.Paths.likers.rawValue).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let _ = error {
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            querySnapshot.documents.forEach {
                self.postsRef.document(postID).collection(URLComponents.Paths.likers.rawValue).document($0.documentID).delete()
            }
            self.postsRef.document(postID).delete { (error) in
                if let _ = error {
                    return
                }
                self.usersRef.document(accountID).collection(URLComponents.Paths.posts.rawValue).document(postID).collection(URLComponents.Paths.likers.rawValue).getDocuments { [weak self] (querySnapshot, error) in
                    guard let self = self else { return }
                    if let _ = error {
                        return
                    }
                    guard let querySnapshot = querySnapshot else { return }
                    querySnapshot.documents.forEach {
                        self.usersRef.document(accountID).collection(URLComponents.Paths.posts.rawValue).document(postID).collection(URLComponents.Paths.likers.rawValue).document($0.documentID).delete()
                    }
                    self.usersRef.document(accountID).collection(URLComponents.Paths.posts.rawValue).document(postID).delete { (error) in
                        if let _ = error {
                            return
                        }
                    }
                }
            }
        }
    }
    
    public func likePost(accountID: String,
                         postID: String,
                         ownerID: String) {
        postsRef.document(postID).collection(URLComponents.Paths.likers.rawValue).document(accountID).setData([URLComponents.Parameters.id.rawValue: accountID])
        usersRef.document(ownerID).collection(URLComponents.Paths.posts.rawValue).document(postID).collection(URLComponents.Paths.likers.rawValue).document(accountID).setData([URLComponents.Parameters.id.rawValue: accountID])
    }
    
    public func unlikePost(accountID: String,
                           postID: String,
                           ownerID: String) {
        postsRef.document(postID).collection(URLComponents.Paths.likers.rawValue).document(accountID).delete()
        usersRef.document(ownerID).collection(URLComponents.Paths.posts.rawValue).document(postID).collection(URLComponents.Paths.likers.rawValue).document(accountID).delete()
    }
    
    public func getPostLikersIDs(postID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        postsRef.document(postID).collection(URLComponents.Paths.likers.rawValue).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else {
                completion(.success([]))
                return
            }
            var ids = [String]()
            querySnapshot.documents.forEach {
                if let id = $0.data()[URLComponents.Parameters.id.rawValue] as? String {
                    ids.append(id)
                }
            }
            completion(.success(ids))
        }
    }
}
