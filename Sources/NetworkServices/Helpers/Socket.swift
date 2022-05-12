//
//  File.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import FirebaseFirestore

public protocol SocketProtocol {
    func remove()
}

final class FirestoreSocketAdapter: SocketProtocol {
    
    private let adaptee: ListenerRegistration
    
    init(adaptee: ListenerRegistration) {
        self.adaptee = adaptee
    }
    
    public func remove() {
        adaptee.remove()
    }
}
