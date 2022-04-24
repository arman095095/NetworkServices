//
//  NetworkParameters.swift
//  
//
//  Created by Арман Чархчян on 11.04.2022.
//

import Foundation

enum RequestLimits: Int {
    case posts = 20
    case users = 15
}

struct URLComponents {

    enum Paths: String {
        case users
        case blocked
        case iamblocked
        case notifications
        case likers
        case activeChat
        case typing
        case posts
        case messages
    }

    enum Parameters: String {
        case lastActivity
        case online
        case removed
        case id
        case looked
        case senderID
        case date
    }
}


struct StorageURLComponents {
    
    enum Parameters: String {
        case m4a = ".m4a"
        case audioM4A = "audio/m4a"
        case imageJpeg = "image/jpeg"
    }
    
    enum Paths: String {
        case avatars = "Avatars"
        case chats = "Chats"
        case posts = "Posts"
        case audio = "audio"
    }
}
