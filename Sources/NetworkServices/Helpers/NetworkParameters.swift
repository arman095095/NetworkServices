//
//  NetworkParameters.swift
//  
//
//  Created by Арман Чархчян on 11.04.2022.
//

import Foundation

public struct URLComponents {

    public enum Paths: String {
        case users
        case blocked
        case iamblocked
        case lookedMessages
        case notifications
        case likers
        case activeChat
        case typing
        case posts
        case messages
        case sendedRequests
        case waitingUsers
        case friendIDs
    }

    public enum Parameters: String {
        case photoURL
        case imageRatio
        case audioURL
        case audioDuration
        case lastActivity
        case online
        case removed
        case id
        case looked
        case senderID
        case date
        case friendID
        case userID
        case status
        case content
        case adressID
        case textContent
        case urlImage
        case imageHeight
        case imageWidth
        case uid
        case username
        case info
        case sex
        case imageURL
        case birthday
        case country
        case city
    }
}


public struct StorageURLComponents {
    
    public enum Parameters: String {
        case m4a = ".m4a"
        case audioM4A = "audio/m4a"
        case imageJpeg = "image/jpeg"
    }
    
    public enum Paths: String {
        case avatars = "Avatars"
        case chats = "Chats"
        case posts = "Posts"
        case audio = "audio"
    }
}
