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
        container.register(AccountNetworkServiceProtocol.self) { r in
            AccountNetworkService(networkService: Firestore.firestore())
        }
    
        container.register(ProfilesNetworkServiceProtocol.self) { r in
            ProfilesNetworkService(networkService: Firestore.firestore())
        }
        
        container.register(ProfileRemoteStorageServiceProtocol.self) { r in
            ProfileRemoteStorageService(storage: Storage.storage())
        }
        
        container.register(AccountContentNetworkServiceProtocol.self) { r in
            AccountContentNetworkService(networkService: Firestore.firestore())
        }
    }
}
