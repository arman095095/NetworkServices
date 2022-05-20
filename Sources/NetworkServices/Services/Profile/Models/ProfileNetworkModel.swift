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
public struct ProfileNetworkModel: ProfileNetworkModelProtocol {
    
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
        var muserDictionary: [String: Any] = [URLComponents.Parameters.uid.rawValue:id]
        muserDictionary[URLComponents.Parameters.username.rawValue] = userName
        muserDictionary[URLComponents.Parameters.info.rawValue] = info
        muserDictionary[URLComponents.Parameters.sex.rawValue] = sex
        muserDictionary[URLComponents.Parameters.imageURL.rawValue] = imageUrl
        muserDictionary[URLComponents.Parameters.birthday.rawValue] = birthday
        muserDictionary[URLComponents.Parameters.country.rawValue] = country
        muserDictionary[URLComponents.Parameters.city.rawValue] = city
        muserDictionary[URLComponents.Parameters.removed.rawValue] = removed
        muserDictionary[URLComponents.Parameters.online.rawValue] = online
        muserDictionary[URLComponents.Parameters.lastActivity.rawValue] = FieldValue.serverTimestamp()
        
        return muserDictionary
    }
    
    init?(dict: [String: Any]) {
        guard let userName = dict[URLComponents.Parameters.username.rawValue] as? String,
              let info = dict[URLComponents.Parameters.info.rawValue] as? String,
              let sex = dict[URLComponents.Parameters.sex.rawValue] as? String,
              let imageURL = dict[URLComponents.Parameters.imageURL.rawValue] as? String,
              let birthDay = dict[URLComponents.Parameters.birthday.rawValue] as? String,
              let country = dict[URLComponents.Parameters.country.rawValue] as? String,
              let city = dict[URLComponents.Parameters.city.rawValue] as? String,
              let removed = dict[URLComponents.Parameters.removed.rawValue] as? Bool,
              let online = dict[URLComponents.Parameters.online.rawValue] as? Bool,
              let identifier = dict[URLComponents.Parameters.uid.rawValue] as? String else {
            return nil
        }
        let lastActivity = dict[URLComponents.Parameters.lastActivity.rawValue] as? Timestamp
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

