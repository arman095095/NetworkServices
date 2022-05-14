//
//  File.swift
//  
//
//  Created by Арман Чархчян on 10.04.2022.
//

import Foundation
import FirebaseFirestore
import UIKit

public protocol MessagingServiceProtocol {
    func send(message: MessageNetworkModelProtocol, completion: @escaping (Result<Void, Error>) -> Void)
    func initMessagesSocket(lastMessageDate: Date?, accountID: String, from id: String, completion: @escaping (Result<[MessageNetworkModelProtocol], Error>) -> Void) -> SocketProtocol
    func sendLookedMessages(from id: String, for friendID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func initlookedSendedMessagesSocket(accountID: String, from id: String, completion: @escaping (Bool) -> Void) -> SocketProtocol
    func typingStatus(from id: String, for friendID: String, completion: @escaping (Bool) -> Void)
    func sendDidBeganTyping(from id: String, friendID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func sendDidFinishTyping(from id: String, friendID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func initDidBeganTypingStatusSocket(from id: String, friendID: String ,completion: @escaping (Bool) -> Void) -> SocketProtocol
    func initDidFinishedTypingStatusSocket(from id: String, friendID: String ,completion: @escaping (Bool) -> Void) -> SocketProtocol
}

public final class MessagingService {
    
    private let networkServiceRef: Firestore
    
    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    public init(networkService: Firestore) {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        networkService.settings = settings
        self.networkServiceRef = networkService
    }
}

extension MessagingService: MessagingServiceProtocol {
    public func send(message: MessageNetworkModelProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        usersRef
            .document(message.adressID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(message.senderID)
            .collection(URLComponents.Paths.messages.rawValue)
            .document(message.id)
            .setData(message.convertModelToDictionary()) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                self.usersRef
                    .document(message.senderID)
                    .collection(URLComponents.Paths.friendIDs.rawValue)
                    .document(message.adressID)
                    .collection(URLComponents.Paths.messages.rawValue)
                    .document(message.id)
                    .setData(message.convertModelToDictionary()) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        completion(.success(()))
                    }
            }
    }
    
    public func initMessagesSocket(lastMessageDate: Date?, accountID: String, from id: String, completion: @escaping (Result<[MessageNetworkModelProtocol], Error>) -> Void) -> SocketProtocol {
        let ref = usersRef
            .document(accountID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.messages.rawValue)
        let handler: ((QuerySnapshot?, Error?) -> ()) = { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else { return }
            var newMessages = [MessageNetworkModelProtocol]()
            querySnapshot.documentChanges.forEach { change in
                guard case .added = change.type else { return }
                guard let message = MessageNetworkModel(queryDocumentSnapshot: change.document) else { return }
                newMessages.append(message)
            }
        }
        var listener: ListenerRegistration
        if let lastMessageDate = lastMessageDate {
            let query = ref.whereField(URLComponents.Parameters.date.rawValue, isGreaterThan: lastMessageDate)
            listener = query.addSnapshotListener(handler)
        } else {
            listener = ref.addSnapshotListener(handler)
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func sendLookedMessages(from id: String, for friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.lookedMessages.rawValue)
            .document(id)
            .setData([URLComponents.Parameters.looked.rawValue: id]) { (error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
    }
    
    public func initlookedSendedMessagesSocket(accountID: String, from id: String, completion: @escaping (Bool) -> Void) -> SocketProtocol {
        let ref = usersRef
            .document(accountID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.lookedMessages.rawValue)
        
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
            if let _ = error {
                completion(false)
                return
            }
            guard let querySnapshot = querySnapshot,
                  !querySnapshot.isEmpty,
                  let first = querySnapshot.documentChanges.first else {
                completion(false)
                return
            }
            switch first.type {
            case .added:
                completion(true)
                ref.document(first.document.documentID).delete()
            default:
                break
            }
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func typingStatus(from id: String, for friendID: String, completion: @escaping (Bool) -> Void) {
        usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.typing.rawValue)
            .document(friendID)
            .getDocument { (documentSnapshot, error) in
                if let _ = error {
                    completion(false)
                    return
                }
                guard let doc = documentSnapshot else {
                    completion(false)
                    return
                }
                guard let _ = doc.data()?[URLComponents.Parameters.id.rawValue] as? String else {
                    completion(false)
                    return
                }
                completion(true)
            }
    }
    
    public func sendDidBeganTyping(from id: String, friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.typing.rawValue)
            .document(id)
            .setData([URLComponents.Parameters.id.rawValue: id]) { (error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
    }
    
    public func sendDidFinishTyping(from id: String, friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.typing.rawValue)
            .document(id)
            .delete { (error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
    }
    
    public func initDidBeganTypingStatusSocket(from id: String, friendID: String ,completion: @escaping (Bool) -> Void) -> SocketProtocol {
        let ref = usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.typing.rawValue)
        
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
            if let _ = error {
                completion(false)
                return
            }
            guard let querySnapshot = querySnapshot,
                  let first = querySnapshot.documentChanges.first else {
                completion(false)
                return
            }
            switch first.type {
            case .added:
                completion(true)
            default:
                completion(false)
            }
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func initDidFinishedTypingStatusSocket(from id: String, friendID: String ,completion: @escaping (Bool) -> Void) -> SocketProtocol {
        let ref = usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.typing.rawValue)
        
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
            if let _ = error {
                completion(false)
                return
            }
            guard let querySnapshot = querySnapshot,
                  let first = querySnapshot.documentChanges.first else {
                completion(false)
                return
            }
            switch first.type {
            case .removed:
                completion(true)
            default:
                completion(false)
            }
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
}
/*
public func sendMessage(message: MessageNetworkModelProtocol, completion: @escaping (Result<Void,Error>) -> Void) {
    if !InternetConnectionManager.isConnectedToNetwork() {
        completion(.failure(ConnectionError.noInternet))
    }
    if let imageData = message.imageData {
        sendPhotoMessage(message: message, image: imageData, completion: completion)
    } else if let audioLocalURL = message.audioURL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(audioLocalURL)
        guard let audioData = try? Data(contentsOf: url) else {
            completion(.failure(NSError(domain: "Error", code: 10, userInfo: nil)))
            return
        }
        sendAudioMessage(message: message, audioData: audioData, completion: completion)
    } else {
        sendPreparedMessage(message: message, completion: completion)
    }
}

func sendAudioMessage(message: MessageNetworkModelProtocol, audioData: Data, completion: @escaping (Result<Void,Error>) -> Void) {
    remoteStorage.uploadChat(audio: audioData) { [weak self] (result) in
        switch result {
        case .success(let url):
            message.audioURL = url
            self?.sendPreparedMessage(message: message, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

func sendPhotoMessage(message: MessageNetworkModelProtocol, image: Data, completion: @escaping (Result<Void,Error>) -> Void) {
    remoteStorage.uploadChat(image: image) { [weak self] (result) in
        switch result {
        case .success(let url):
            message.photoURL = url
            self?.sendPreparedMessage(message: message, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

func sendPreparedMessage(message: MessageNetworkModelProtocol, completion: @escaping (Result<Void,Error>) -> Void) {
    let ref = networkServiceRef.collection([URLComponents.Paths.users.rawValue, message.adressID, URLComponents.Paths.messages.rawValue].joined(separator: "/"))
    ref.document(message.id).setData(message.convertModelToDictionary()) { (error) in
        if let error = error {
            completion(.failure(error))
            return
        }
        completion(.success(()))
    }
}
}

*/
