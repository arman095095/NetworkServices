//
//  FireBaseStorageHelp.swift
//  diffibleData
//
//  Created by Arman Davidoff on 27.02.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation
import FirebaseStorage
import UIKit

public protocol RemoteStorageServiceProtocol {
    func uploadChat(audio: Data, completion: @escaping (Result<String, Error>) -> Void)
    func uploadChat(image: Data, completion: @escaping (Result<String, Error>) -> Void)
    func uploadProfile(accountID: String,
                       image: Data,
                       completion: @escaping (Result<URL ,Error>) -> Void)
    func uploadPost(image: Data, completion: @escaping (Result<String, Error>) -> Void)
    func download(url: URL, completion: @escaping (Result<Data, Error>) -> Void)
    func delete(from url: URL)
}

final class RemoteStorageService {

    private let storage: Storage
    
    init(storage: Storage) {
        self.storage = storage
    }
}

extension RemoteStorageService: RemoteStorageServiceProtocol {

    public func uploadChat(audio: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = StorageURLComponents.Parameters.audioM4A.rawValue
        let audioName = [UUID().uuidString,Date().description,StorageURLComponents.Parameters.m4a.rawValue].joined()
        audioRef.child(audioName).putData(audio, metadata: metadata) { [weak self] (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.audioRef.child(audioName).downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else { return }
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    public func uploadChat(image: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = StorageURLComponents.Parameters.imageJpeg.rawValue
        let photoName = [UUID().uuidString,Date().description].joined()
        
        chatsImagesRef.child(photoName).putData(image, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.chatsImagesRef.child(photoName).downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else { return }
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    public func uploadProfile(accountID: String, image: Data, completion: @escaping (Result<URL ,Error>) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = StorageURLComponents.Parameters.imageJpeg.rawValue
        avatarRef.child(accountID).putData(image, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.avatarRef.child(accountID).downloadURL { (url, error) in
                guard let downloadURL = url else { return }
                completion(.success(downloadURL))
            }
        }
    }
    
    public func uploadPost(image: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let metadata = StorageMetadata()
        let imageName = UUID().uuidString
        metadata.contentType = StorageURLComponents.Parameters.imageJpeg.rawValue
        postsImagesRef.child(imageName).putData(image, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.postsImagesRef.child(imageName).downloadURL { (url, error) in
                guard let downloadURL = url else { return }
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    public func download(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let ref = storage.reference(forURL: url.absoluteString)
        let megaByte = Int64(1*1024*1024)
        ref.getData(maxSize: megaByte) { [weak self] (data, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            self?.delete(from: url)
            completion(.success(data))
        }
    }
    
    public func delete(from url: URL) {
        let ref = storage.reference(forURL: url.absoluteString)
        ref.delete { _ in }
    }
}

private extension RemoteStorageService {
    var avatarRef : StorageReference {
        storage.reference().child(StorageURLComponents.Paths.avatars.rawValue)
    }
    
    var chatsImagesRef: StorageReference {
        storage.reference().child(StorageURLComponents.Paths.chats.rawValue)
    }
    
    var postsImagesRef: StorageReference {
        storage.reference().child(StorageURLComponents.Paths.posts.rawValue)
    }
    
    var audioRef: StorageReference {
        storage.reference().child(StorageURLComponents.Paths.audio.rawValue)
    }
}
