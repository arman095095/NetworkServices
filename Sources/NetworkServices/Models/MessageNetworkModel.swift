//
//  Message.swift
//  
//
//  Created by Арман Чархчян on 11.04.2022.
//

import Foundation
import FirebaseFirestore

public enum MessageStatus: String {
    case sended
    case looked
    case incomingNew
    case incoming
}

public protocol MessageNetworkModelProtocol: AnyObject {
    var adressID: String { get }
    var senderID: String { get }
    var id: String { get }
    var audioURL: String? { get set }
    var photoURL: String? { get set }
    var content: String { get }
    var date: Date? { get set }
    var imageRatio: Double? { get set }
    var audioDuration: Float? { get set }
    var status: MessageStatus { get set }
    func convertModelToDictionary() -> [String: Any]
}

public final class MessageNetworkModel: MessageNetworkModelProtocol {
    public var adressID: String
    public var senderID: String
    public var id: String
    public var audioURL: String?
    public var photoURL: String?
    public var content: String
    public var imageRatio: Double?
    public var audioDuration: Float?
    public var date: Date?
    public var status: MessageStatus
    
    public init(audioURL: String?,
                photoURL: String?,
                adressID: String,
                senderID: String,
                content: String,
                imageRatio: Double?,
                audioDuration: Float?,
                id: String,
                date: Date?) {
        self.photoURL = photoURL
        self.imageRatio = imageRatio
        self.audioURL = audioURL
        self.audioDuration = audioDuration
        self.senderID = senderID
        self.adressID = adressID
        self.content = content
        self.date = date
        self.id = id
        self.status = .sended
    }
    
    init?(queryDocumentSnapshot: QueryDocumentSnapshot) {
        let mmessegeDictionary = queryDocumentSnapshot.data()
        
        guard let senderID = mmessegeDictionary[URLComponents.Parameters.senderID.rawValue] as? String,
              let id = mmessegeDictionary[URLComponents.Parameters.id.rawValue] as? String,
              let date = mmessegeDictionary[URLComponents.Parameters.date.rawValue] as? Timestamp,
              let content = mmessegeDictionary[URLComponents.Parameters.content.rawValue] as? String,
              let adressID = mmessegeDictionary[URLComponents.Parameters.adressID.rawValue] as? String,
              let statusString = mmessegeDictionary[URLComponents.Parameters.status.rawValue] as? String,
              let status = MessageStatus(rawValue: statusString)
        else { return nil }
        
        if let urlPhotoString = mmessegeDictionary[URLComponents.Parameters.photoURL.rawValue] as? String,
           let imageRatio = mmessegeDictionary[URLComponents.Parameters.imageRatio.rawValue] as? Double {
            self.photoURL = urlPhotoString
            self.imageRatio = imageRatio
        }
        if let audioURL = mmessegeDictionary[URLComponents.Parameters.audioURL.rawValue] as? String {
            self.audioURL = audioURL
            self.audioDuration = mmessegeDictionary[URLComponents.Parameters.audioDuration.rawValue] as? Float ?? 0.0
        }
        self.senderID = senderID
        self.adressID = adressID
        self.content = content
        self.status = status
        self.date = date.dateValue()
        self.id = id
    }
    
    public func convertModelToDictionary() -> [String : Any] {
        var mmessegeDictionary: [String: Any] = [:]
        mmessegeDictionary[URLComponents.Parameters.date.rawValue] = FieldValue.serverTimestamp()
        mmessegeDictionary[URLComponents.Parameters.senderID.rawValue] = senderID
        mmessegeDictionary[URLComponents.Parameters.adressID.rawValue] = adressID
        mmessegeDictionary[URLComponents.Parameters.id.rawValue] = id
        mmessegeDictionary[URLComponents.Parameters.content.rawValue] = content
        mmessegeDictionary[URLComponents.Parameters.status.rawValue] = status.rawValue
        
        if let photoUrl = self.photoURL {
            mmessegeDictionary[URLComponents.Parameters.photoURL.rawValue] = photoUrl
            mmessegeDictionary[URLComponents.Parameters.imageRatio.rawValue] = imageRatio
        }
        if let audioURL = self.audioURL {
            mmessegeDictionary[URLComponents.Parameters.audioURL.rawValue] = audioURL
            mmessegeDictionary[URLComponents.Parameters.audioDuration.rawValue] = audioDuration
        }
        return mmessegeDictionary
    }
}
