//
//  MUser + Firestore.swift
//  diffibleData
//
//  Created by Arman Davidoff on 21.12.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import FirebaseFirestore

public protocol ProfileNetworkModelProtocol {
    var userName: String { get set }
    var info: String { get set }
    var sex: String { get set }
    var imageUrl: String { get set }
    var id: String { get set }
    var country: String { get set }
    var city: String { get set }
    var birthday: String { get set }
    var removed: Bool { get set }
    var online: Bool { get set }
    var lastActivity: Date? { get set }
    var postsCount: Int { get set }
    
    func convertModelToDictionary() -> [String: Any]
}

//MARK: FirebaseFirestore
struct ProfileNetworkModel: ProfileNetworkModelProtocol {
    
    public var userName: String
    public var info: String
    public var sex: String
    public var imageUrl: String
    public var id: String
    public var country: String
    public var city: String
    public var birthday: String
    public var removed: Bool
    public var online: Bool
    public var lastActivity: Date?
    public var postsCount: Int
    
    public init(userName: String,
                imageName: String,
                identifier: String,
                sex: String,
                info: String,
                birthDay: String,
                country: String,
                city: String) {
        self.userName = userName
        self.info = info
        self.sex = sex
        self.imageUrl = imageName
        self.id = identifier
        self.birthday = birthDay
        self.country = country
        self.city = city
        self.removed = false
        self.online = true
        self.lastActivity = nil
        self.postsCount = 0
    }
    
    public func convertModelToDictionary() -> [String: Any] { //For send Model to Firebase as Dictionary
        var muserDictionary: [String: Any] = ["uid":id]
        muserDictionary["username"] = userName
        muserDictionary["info"] = info
        muserDictionary["sex"] = sex
        muserDictionary["imageURL"] = imageUrl
        muserDictionary["birthday"] = birthday
        muserDictionary["country"] = country
        muserDictionary["city"] = city
        muserDictionary["removed"] = removed
        muserDictionary["online"] = online
        muserDictionary["lastActivity"] = FieldValue.serverTimestamp()
        
        return muserDictionary
    }
    
    init?(dict: [String: Any]) {
        guard let userName = dict["username"] as? String,
              let info = dict["info"] as? String,
              let sex = dict["sex"] as? String,
              let imageURL = dict["imageURL"] as? String,
              let birthDay = dict["birthday"] as? String,
              let country = dict["country"] as? String,
              let city = dict["city"] as? String,
              let removed = dict["removed"] as? Bool,
              let online = dict["online"] as? Bool,
              let identifier = dict["uid"] as? String else {
            return nil
        }
        let lastActivity = dict["lastActivity"] as? Timestamp
        self.userName = userName
        self.info = info
        self.sex = sex
        self.imageUrl = imageURL
        self.id = identifier
        self.birthday = birthDay
        self.country = country
        self.city = city
        self.removed = removed
        self.online = online
        self.lastActivity = lastActivity?.dateValue()
        self.postsCount = 0
    }
}
