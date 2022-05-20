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
    
        container.register(RemoteStorageServiceProtocol.self) { r in
            RemoteStorageService(storage: Storage.storage())
        }
    
        container.register(AccountServiceProtocol.self) { r in
            AccountService(networkService: Firestore.firestore())
        }
    
        container.register(ProfilesServiceProtocol.self) { r in
            ProfilesService(networkService: Firestore.firestore())
        }
        
        container.register(PostsServiceProtocol.self) { r in
            PostsService(networkService: Firestore.firestore())
        }
        
        container.register(RequestsServiceProtocol.self) { r in
            RequestsService(networkService: Firestore.firestore())
        }
        
        container.register(MessagingServiceProtocol.self) { r in
            MessagingService(networkService: Firestore.firestore())
        }
    }
}
