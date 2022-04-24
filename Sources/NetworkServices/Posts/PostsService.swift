//
//  FirebaseManager + Extension.swift
//  diffibleData
//
//  Created by Arman Davidoff on 24.11.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import FirebaseFirestore

public protocol PostsServiceProtocol {
    func createPost(post: PostNetworkModelProtocol, completion: @escaping (Result<Void,Error>) -> Void)
    func getUserFirstPosts(user: ProfileNetworkModelProtocol, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getUserNextPosts(user: ProfileNetworkModelProtocol, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getAllNextPosts(completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getAllFirstPosts(completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ())
    func getPostLikers(post: PostNetworkModelProtocol, completion: @escaping (Result<[String],Error>) -> ())
    func deletePost(post: PostNetworkModelProtocol)
    func likePost(post: PostNetworkModelProtocol)
    func unlikePost(post: PostNetworkModelProtocol)
}

public final class PostsService {
    private let profilesService: ProfilesServiceProtocol
    private let networkServiceRef = Firestore.firestore()
    public var lastPostOfAll: DocumentSnapshot?
    public var lastPostUser: DocumentSnapshot?

    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    private var postsRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.posts.rawValue)
    }
    
    private let accountID: String
    
    public init(accountID: String,
                profilesService: ProfilesServiceProtocol) {
        self.accountID = accountID
        self.profilesService = profilesService
    }
}

//MARK: Posts Extension
extension PostsService: PostsServiceProtocol {
    
    public func createPost(post: PostNetworkModelProtocol, completion: @escaping (Result<Void,Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
            return
        }
        post.userID = accountID
        postsRef.document(post.id).setData(post.convertModelToDictionary()) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            self.usersRef.document(self.accountID).collection(URLComponents.Paths.posts.rawValue).document(post.id).setData(post.convertModelToDictionary(), completion: { (error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            })
        }
    }
    
    public func getPostLikers(post: PostNetworkModelProtocol, completion: @escaping (Result<[String],Error>) -> ()) {
        postsRef.document(post.id).collection(URLComponents.Paths.likers.rawValue).getDocuments { (querySnapshot, error) in
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
    
    public func getUserFirstPosts(user: ProfileNetworkModelProtocol, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        var posts = [PostNetworkModelProtocol]()
        if user.removed {
            completion(.success(posts))
            return
        }
        let userID = user.id
        usersRef.document(userID).collection(URLComponents.Paths.posts.rawValue).order(by: URLComponents.Parameters.date.rawValue, descending: true).limit(to: RequestLimits.posts.rawValue).getDocuments() { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            guard !querySnapshot.documents.isEmpty else  {
                completion(.success([]))
                return
            }
            var i = 0
            let count = querySnapshot.documents.count
            querySnapshot.documents.forEach { (documentSnapshot) in
                i += 1
                if i == count { self.lastPostUser = documentSnapshot }
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    post.owner = user
                    posts.append(post)
                }
            }
            let postsCount = posts.count
            var index = 0
            posts.forEach { post in
                self.getPostLikers(post: post, completion: { (result) in
                    index += 1
                    switch result {
                    case .success(let ids):
                        post.likersIds = ids
                        post.likedByMe = ids.contains(self.accountID)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    if index == postsCount {
                        completion(.success(posts))
                    }
                })
            }
        }
    }
    
    public func getUserNextPosts(user: ProfileNetworkModelProtocol, completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        guard let last = lastPostUser,
              let postOwnerID = PostNetworkModel(documentSnapshot: last)?.userID,
              postOwnerID == user.id else { return }
        var posts = [PostNetworkModelProtocol]()
        if user.removed {
            completion(.success(posts))
            return
        }
        let userID = user.id
        usersRef.document(userID).collection(URLComponents.Paths.posts.rawValue).order(by: URLComponents.Parameters.date.rawValue, descending: true).start(afterDocument: last).limit(to: RequestLimits.posts.rawValue).getDocuments() { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            guard !querySnapshot.documents.isEmpty else  {
                completion(.success([]))
                return
            }
            var i = 0
            let count = querySnapshot.documents.count
            querySnapshot.documents.forEach { (documentSnapshot) in
                i += 1
                if i == count { self.lastPostUser = documentSnapshot }
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    post.owner = user
                    posts.append(post)
                }
            }
            
            let postsCount = posts.count
            var index = 0
            posts.forEach { post in
                self.getPostLikers(post: post, completion: { (result) in
                    index += 1
                    switch result {
                    case .success(let ids):
                        post.likersIds = ids
                        post.likedByMe = ids.contains(self.accountID)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    if index == postsCount {
                        completion(.success(posts))
                    }
                })
            }
        }
    }
    
    public func getAllNextPosts(completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        guard let lastDocument = lastPostOfAll else { return }
        var posts = [PostNetworkModelProtocol]()
        postsRef.order(by: URLComponents.Parameters.date.rawValue, descending: true).start(afterDocument: lastDocument).limit(to: RequestLimits.posts.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
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
            
            var dict: [String: [PostNetworkModelProtocol]] = [:]
            querySnapshot.documents.forEach { (documentSnapshot) in
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    let postOwnerId = post.userID
                    if let postsArr = dict[postOwnerId] {
                        var new = postsArr
                        new.append(post)
                        dict[postOwnerId] = new
                    } else {
                        dict[postOwnerId] = [post]
                    }
                    posts.append(post)
                }
                if querySnapshot.documents.last == documentSnapshot {
                    self.lastPostOfAll = documentSnapshot
                }
            }
            
            let count = dict.keys.count
            var index = 0
            dict.keys.forEach { userid in
                self.profilesService.getProfileInfo(userID: userid, completion: { (result) in
                    switch result {
                    case .success(let user):
                        index += 1
                        dict[userid]?.forEach { post in
                            post.owner = user
                        }
                        if index == count {
                            let postsCount = posts.count
                            var i = 0
                            posts.forEach { post in
                                self.getPostLikers(post: post, completion: { (result) in
                                    i += 1
                                    switch result {
                                    case .success(let ids):
                                        post.likersIds = ids
                                        post.likedByMe = ids.contains(self.accountID)
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                    if i == postsCount {
                                        completion(.success(posts))
                                    }
                                })
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
        }
    }
    
    public func getAllFirstPosts(completion: @escaping (Result<[PostNetworkModelProtocol],Error>) -> ()) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        var posts = [PostNetworkModelProtocol]()
        postsRef.order(by: URLComponents.Parameters.date.rawValue, descending: true).limit(to: RequestLimits.posts.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
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
            
            var dict: [String: [PostNetworkModelProtocol]] = [:]
            querySnapshot.documents.forEach { (documentSnapshot) in
                if let post = PostNetworkModel(documentSnapshot: documentSnapshot) {
                    let postOwnerId = post.userID
                    if let postsArr = dict[postOwnerId] {
                        var new = postsArr
                        new.append(post)
                        dict[postOwnerId] = new
                    } else {
                        dict[postOwnerId] = [post]
                    }
                    posts.append(post)
                }
                if querySnapshot.documents.last == documentSnapshot {
                    self.lastPostOfAll = documentSnapshot
                }
            }
            
            let count = dict.keys.count
            var index = 0
            
            dict.keys.forEach { userid in
                self.profilesService.getProfileInfo(userID: userid, completion: { (result) in
                    switch result {
                    case .success(let user):
                        index += 1
                        dict[userid]?.forEach { post in
                            post.owner = user
                        }
                        if index == count {
                            let postsCount = posts.count
                            var i = 0
                            posts.forEach { post in
                                self.getPostLikers(post: post, completion: { (result) in
                                    i += 1
                                    switch result {
                                    case .success(let ids):
                                        post.likersIds = ids
                                        post.likedByMe = ids.contains(self.accountID)
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                    if i == postsCount {
                                        completion(.success(posts))
                                    }
                                })
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
            
        }
    }
    
    public func deletePost(post: PostNetworkModelProtocol) {
        postsRef.document(post.id).collection(URLComponents.Paths.likers.rawValue).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let _ = error {
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            querySnapshot.documents.forEach {
                self.postsRef.document(post.id).collection(URLComponents.Paths.likers.rawValue).document($0.documentID).delete()
            }
            self.postsRef.document(post.id).delete { (error) in
                if let _ = error {
                    return
                }
                self.usersRef.document(self.accountID).collection(URLComponents.Paths.posts.rawValue).document(post.id).collection(URLComponents.Paths.likers.rawValue).getDocuments { [weak self] (querySnapshot, error) in
                    guard let self = self else { return }
                    if let _ = error {
                        return
                    }
                    guard let querySnapshot = querySnapshot else { return }
                    querySnapshot.documents.forEach {
                        self.usersRef.document(self.accountID).collection(URLComponents.Paths.posts.rawValue).document(post.id).collection(URLComponents.Paths.likers.rawValue).document($0.documentID).delete()
                    }
                    self.usersRef.document(self.accountID).collection(URLComponents.Paths.posts.rawValue).document(post.id).delete { (error) in
                        if let _ = error {
                            return
                        }
                    }
                }
            }
        }
    }
    
    public func likePost(post: PostNetworkModelProtocol) {
        let postOwnerId = post.userID
        postsRef.document(post.id).collection(URLComponents.Paths.likers.rawValue).document(accountID).setData([URLComponents.Parameters.id.rawValue: accountID])
        usersRef.document(postOwnerId).collection(URLComponents.Paths.posts.rawValue).document(post.id).collection(URLComponents.Paths.likers.rawValue).document(self.accountID).setData([URLComponents.Parameters.id.rawValue: self.accountID])
    }
    
    public func unlikePost(post: PostNetworkModelProtocol) {
        let postOwnerId = post.userID
        postsRef.document(post.id).collection(URLComponents.Paths.likers.rawValue).document(accountID).delete()
        usersRef.document(postOwnerId).collection(URLComponents.Paths.posts.rawValue).document(post.id).collection(URLComponents.Paths.likers.rawValue).document(self.accountID).delete()
    }
}
