//
//  File.swift
//  
//
//  Created by Арман Чархчян on 22.04.2022.
//

import Foundation
import Swinject
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

public final class NetworkServicesAssembly: Assembly {
    public init() { }
    public func assemble(container: Container) {
        container.register(AuthServiceProtocol.self) { r in
            AuthService(authNetworkService: Auth.auth())
        }
    
        container.register(RemoteStorageServiceProtocol.self) { r in
            RemoteStorageService(storage: Storage.storage())
        }
    
        container.register(AccountServiceProtocol.self) { r in
            AccountService(networkService: Firestore.firestore())
        }.implements(RequestsServiceProtocol.self)
    
        container.register(ProfilesServiceProtocol.self) { r in
            ProfilesService(networkService: Firestore.firestore())
        }
        
        container.register(PostsServiceProtocol.self) { r in
            PostsService(networkService: Firestore.firestore())
        }
    }
}
