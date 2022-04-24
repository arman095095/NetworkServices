//
//  File.swift
//  
//
//  Created by Арман Чархчян on 10.04.2022.
//

import Foundation
import FirebaseFirestore
import UIKit

public protocol MessagingRecieveServiceProtocol {
    func listenerForMessages(completion: @escaping (Result<[MessageNetworkModelProtocol],Error>) -> Void) -> ListenerRegistration?
    func listenerlookedSendedMessages(completion: @escaping (Result<[String],Error>) -> Void) -> ListenerRegistration?
    func listenerForTyping(completion: @escaping (Result<([String],[String]),Error>) -> Void) -> ListenerRegistration?
    func listenerForChatStatus(completion: @escaping (Result<[(String,String)],Error>) -> Void) -> ListenerRegistration?
    
}

public protocol MessagingSendingServiceProtocol {
    func sendLookedMessages(friendID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func sendMessage(message: MessageNetworkModelProtocol, completion: @escaping (Result<Void,Error>) -> Void)
    func sendChatActive(friendID: String, chatID: String, completion: @escaping (Result<Void,Error>) -> Void)
    func checkTypingStatus(friendID: String, completion: @escaping (Bool) -> Void)
    func sendTyping(friendID: String, completion: @escaping (Result<Void,Error>) -> Void)
    func sendFinishTyping(friendID: String, completion: @escaping (Result<Void,Error>) -> Void)
}

public final class MessagingService {
    private let remoteStorage: RemoteStorageServiceProtocol
    private let networkServiceRef = Firestore.firestore()
    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    private let accountID: String
    
    public init(accountID: String,
                remoteStorage: RemoteStorageServiceProtocol) {
        self.accountID = accountID
        self.remoteStorage = remoteStorage
    }
}

extension MessagingService: MessagingSendingServiceProtocol {
    public func sendLookedMessages(friendID: String, completion: @escaping (Result<Void,Error>) -> Void) {
        usersRef.document(friendID).collection(URLComponents.Paths.notifications.rawValue).document(accountID).setData([URLComponents.Parameters.looked.rawValue: accountID]) { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
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
    
    public func sendChatActive(friendID: String, chatID: String, completion: @escaping (Result<Void,Error>) -> Void) {
        let ref = networkServiceRef.collection([URLComponents.Paths.users.rawValue, friendID, URLComponents.Paths.activeChat.rawValue].joined(separator: "/"))
        ref.document(chatID).setData([URLComponents.Parameters.senderID.rawValue: accountID]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    public func checkTypingStatus(friendID: String, completion: @escaping (Bool) -> Void) {
        usersRef.document(accountID).collection(URLComponents.Paths.typing.rawValue).document(friendID).getDocument { (documentSnapshot, error) in
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
    
    public func sendTyping(friendID: String, completion: @escaping (Result<Void,Error>) -> Void) {
        usersRef.document(friendID).collection(URLComponents.Paths.typing.rawValue).document(accountID).setData([URLComponents.Parameters.id.rawValue: accountID]) { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    public func sendFinishTyping(friendID: String, completion: @escaping (Result<Void,Error>) -> Void) {
        usersRef.document(friendID).collection(URLComponents.Paths.typing.rawValue).document(accountID).delete { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
}

extension MessagingService: MessagingRecieveServiceProtocol {
    public func listenerForMessages(completion: @escaping (Result<[MessageNetworkModelProtocol], Error>) -> Void) -> ListenerRegistration? {
        let ref = networkServiceRef.collection([URLComponents.Paths.users.rawValue, accountID, URLComponents.Paths.messages.rawValue].joined(separator: "/"))
        
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
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
                ref.document(message.id).delete()
            }
        }
        return listener
    }
    
    public func listenerlookedSendedMessages(completion: @escaping (Result<[String],Error>) -> Void) -> ListenerRegistration? {
        let ref = networkServiceRef.collection([URLComponents.Paths.users.rawValue, accountID, URLComponents.Paths.notifications.rawValue].joined(separator: "/"))
        
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else { return }
            var friendIds = [String]()
            querySnapshot.documentChanges.forEach {
                guard let friendID = $0.document.data()[URLComponents.Parameters.looked.rawValue] as? String else { return }
                switch $0.type {
                case .added:
                    friendIds.append(friendID)
                    ref.document(friendID).delete()
                default:
                    break
                }
            }
            
            completion(.success(friendIds))
        }
        return listener
    }
    
    public func listenerForTyping(completion: @escaping (Result<([String],[String]),Error>) -> Void) -> ListenerRegistration? {
        let ref = networkServiceRef.collection([URLComponents.Paths.users.rawValue, accountID, URLComponents.Paths.typing.rawValue].joined(separator: "/"))
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            var typingIDs = [String]()
            var finishTypingIDs = [String]()
            querySnapshot.documentChanges.forEach {
                switch $0.type {
                case .added:
                    guard let senderID = $0.document.data()[URLComponents.Parameters.id.rawValue] as? String else { return }
                    typingIDs.append(senderID)
                case .removed:
                    guard let senderID = $0.document.data()[URLComponents.Parameters.id.rawValue] as? String else { return }
                    finishTypingIDs.append(senderID)
                case .modified:
                    break
                }
            }
            completion(.success((typingIDs,finishTypingIDs)))
        }
        return listener
    }
    
    public func listenerForChatStatus(completion: @escaping (Result<[(String,String)],Error>) -> Void) -> ListenerRegistration? {
        let ref = networkServiceRef.collection([URLComponents.Paths.users.rawValue, accountID, URLComponents.Paths.activeChat.rawValue].joined(separator: "/"))
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            var chatIDs = [(String,String)]()
            querySnapshot.documentChanges.forEach {
                switch $0.type {
                case .added:
                    guard let senderID = $0.document.data()[URLComponents.Parameters.senderID.rawValue] as? String else { return }
                    let chatID = $0.document.documentID
                    let ids = (senderID,chatID)
                    chatIDs.append(ids)
                    ref.document(chatID).delete()
                default:
                    break
                }
            }
            completion(.success(chatIDs))
        }
        return listener
    }
}

private extension MessagingService {
    
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

