//
//  MPost.swift
//  diffibleData
//
//  Created by Arman Davidoff on 24.11.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import UIKit
import FirebaseFirestore

public protocol PostNetworkModelProtocol: AnyObject {
    var userID: String { get set }
    var likersIds: [String] { get set }
    var date: Date { get set }
    var id: String { get set }
    var textContent: String { get set }
    var urlImage: String? { get set }
    var imageHeight: CGFloat? { get set }
    var imageWidth: CGFloat? { get set }
    
    func convertModelToDictionary() -> [String: Any]
}

public final class PostNetworkModel: PostNetworkModelProtocol {
    
    public var userID: String
    public var likersIds: [String]
    public var date: Date
    public var id: String
    public var textContent: String
    public var urlImage: String?
    public var imageHeight: CGFloat?
    public var imageWidth: CGFloat?
    
    public init(userID: String,
                textContent: String,
                urlImage: String?,
                imageHeight: CGFloat?,
                imageWidth: CGFloat?) {
        self.userID = userID
        self.id = UUID().uuidString
        self.textContent = textContent
        self.urlImage = urlImage
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.likersIds = []
        self.date = Date()
    }
    
    init?(postDictionary: [String:Any]) {
        guard let id = postDictionary["id"] as? String,
              let date = postDictionary["date"] as? Timestamp,
              let textContent = postDictionary["textContent"] as? String,
              let userID = postDictionary["userID"] as? String
        else { return nil }
        
        self.userID = userID
        self.id = id
        self.textContent = textContent
        self.date = date.dateValue()
        self.likersIds = []
        
        if let urlImage = postDictionary["urlImage"] as? String {
            self.urlImage = urlImage
        }
        if let imageHeight = postDictionary["imageHeight"] as? CGFloat,
           let imageWidth = postDictionary["imageWidth"] as? CGFloat {
            self.imageHeight = imageHeight
            self.imageWidth = imageWidth
        }
    }
    
    convenience init?(queryDocumentSnapshot: QueryDocumentSnapshot) {
        let postDictionary = queryDocumentSnapshot.data()
        self.init(postDictionary: postDictionary)
    }
    
    convenience init?(documentSnapshot: DocumentSnapshot) {
        guard let postDictionary = documentSnapshot.data() else { return nil }
        self.init(postDictionary: postDictionary)
    }
    
    public func convertModelToDictionary() -> [String: Any] {
        var postDictionary: [String:Any] = ["userID": userID]
        postDictionary["id"] = id
        postDictionary["textContent"] = textContent
        postDictionary["date"] = FieldValue.serverTimestamp()
        
        if let urlImage = self.urlImage {
            postDictionary["urlImage"] = urlImage
        }
        if let imageHeight = self.imageHeight,
           let imageWidth = self.imageWidth {
            postDictionary["imageHeight"] = imageHeight
            postDictionary["imageWidth"] = imageWidth
        }
        return postDictionary
    }
}
