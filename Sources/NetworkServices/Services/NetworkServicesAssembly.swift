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
    }
}
