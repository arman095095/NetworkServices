//
//  Message.swift
//  
//
//  Created by Арман Чархчян on 11.04.2022.
//

import Foundation
import FirebaseFirestore

public protocol MessageNetworkModelProtocol: AnyObject {
    var adressID: String { get }
    var senderID: String { get }
    var id: String { get }
    var audioURL: String? { get set }
    var photoURL: String? { get set }
    var content: String { get }
    var date: Date? { get set }
    var imageData: Data? { get set }
    var imageRatio: Double? { get set }
    var audioDuration: Float? { get set }
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
    public var imageData: Data?
    public var audioDuration: Float?
    public var date: Date?
    
    public init(imageData: Data?,
                audioURL: String?,
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
        self.imageData = imageData
        self.id = id
    }
    
    init?(queryDocumentSnapshot: QueryDocumentSnapshot) {
        let mmessegeDictionary = queryDocumentSnapshot.data()
        
        guard let senderID = mmessegeDictionary["senderID"] as? String,
              let id = mmessegeDictionary["id"] as? String,
              let date = mmessegeDictionary["date"] as? Timestamp,
              let content = mmessegeDictionary["content"] as? String,
              let adressID = mmessegeDictionary["adressID"] as? String
        else { return nil }
        
        if let urlPhotoString = mmessegeDictionary["photoURL"] as? String,
           let imageRatio = mmessegeDictionary["imageRatio"] as? Double {
            self.photoURL = urlPhotoString
            self.imageRatio = imageRatio
        }
        if let audioURL = mmessegeDictionary["audioURL"] as? String {
            self.audioURL = audioURL
            self.audioDuration = mmessegeDictionary["audioDuration"] as? Float ?? 0.0
        }
        self.senderID = senderID
        self.adressID = adressID
        self.content = content
        self.date = date.dateValue()
        self.id = id
    }
    
    public func convertModelToDictionary() -> [String : Any] {
        var mmessegeDictionary: [String: Any] = [:]
        mmessegeDictionary["date"] = FieldValue.serverTimestamp()
        mmessegeDictionary["senderID"] = senderID
        mmessegeDictionary["adressID"] = adressID
        mmessegeDictionary["id"] = id
        mmessegeDictionary["content"] = content
        
        if let photoUrl = self.photoURL {
            mmessegeDictionary["photoURL"] = photoUrl
            mmessegeDictionary["imageRatio"] = imageRatio
        }
        if let audioURL = self.audioURL {
            mmessegeDictionary["audioURL"] = audioURL
            mmessegeDictionary["audioDuration"] = audioDuration
        }
        return mmessegeDictionary
    }
}
