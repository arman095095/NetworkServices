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
    
        container.register(AccountServiceProtocol.self) { r in
            AccountService(networkService: Firestore.firestore())
        }
    
        container.register(ProfilesServiceProtocol.self) { r in
            ProfilesService(networkService: Firestore.firestore())
        }
        
        container.register(ProfileRemoteStorageServiceProtocol.self) { r in
            ProfileRemoteStorageService(storage: Storage.storage())
        }
        
        container.register(AccountInfoNetworkServiceProtocol.self) { r in
            AccountInfoNetworkService(networkService: Firestore.firestore())
        }
    }
}
