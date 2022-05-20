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

public protocol ProfileRemoteStorageServiceProtocol {
    func uploadProfile(accountID: String,
                       image: Data,
                       completion: @escaping (Result<URL ,Error>) -> Void)
}

final class ProfileRemoteStorageService {

    private let storage: Storage
    
    private var avatarRef : StorageReference {
        storage.reference().child(StorageURLComponents.Paths.avatars.rawValue)
    }
    
    init(storage: Storage) {
        self.storage = storage
    }
}

extension ProfileRemoteStorageService: ProfileRemoteStorageServiceProtocol {
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
}


