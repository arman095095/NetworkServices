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
    var owner: ProfileNetworkModelProtocol? { get set }
    var date: Date { get set }
    var id: String { get set }
    var textContent: String { get set }
    var urlImage: String? { get set }
    var imageSize: CGSize? { get set }
    var likedByMe: Bool { get set }
    
    func convertModelToDictionary() -> [String: Any]
}

final class PostNetworkModel: PostNetworkModelProtocol {
    
    var userID: String
    var likersIds: [String]
    var owner: ProfileNetworkModelProtocol?
    var date: Date
    var id: String
    var textContent: String
    var urlImage: String?
    var imageSize: CGSize?
    var likedByMe: Bool
    
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
        self.likedByMe = false
        
        if let urlImage = postDictionary["urlImage"] as? String {
            self.urlImage = urlImage
        }
        if let imageHeight = postDictionary["imageHeight"] as? CGFloat,let imageWidth = postDictionary["imageWidth"] as? CGFloat  {
            self.imageSize = CGSize(width: imageWidth, height: imageHeight)
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
    
    func convertModelToDictionary() -> [String: Any] {
        var postDictionary: [String:Any] = ["userID": userID]
        postDictionary["id"] = id
        postDictionary["textContent"] = textContent
        postDictionary["date"] = date
        
        if let urlImage = self.urlImage {
            postDictionary["urlImage"] = urlImage
        }
        if let imageSize = self.imageSize {
            postDictionary["imageHeight"] = imageSize.height
            postDictionary["imageWidth"] = imageSize.width
        }
        return postDictionary
    }
}
