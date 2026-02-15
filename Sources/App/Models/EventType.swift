//
//  EventType.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/16.
//

import Foundation
import Hummingbird

enum EventType: ResponseCodable, Equatable {
    case broadcastStarted
    case broadcastStopped
    case imageCaptured(imageId: UUID)
    case screenLocked
    case screenUnlocked
}

extension EventType {
    
    var name: String {
        switch self {
        case .broadcastStarted: "broadcastStarted"
        case .broadcastStopped: "broadcastStopped"
        case .imageCaptured: "imageCaptured"
        case .screenLocked: "screenLocked"
        case .screenUnlocked: "screenUnlocked"
        }
    }
    
    var imageId: UUID? {
        switch self {
        case .imageCaptured(let imageId): imageId
        default: nil
        }
    }
    
    static func from(name: String, with imageId: UUID?) -> EventType? {
        switch name {
        case "broadcastStarted": .broadcastStarted
        case "broadcastStopped": .broadcastStopped
        case "imageCaptured":
            imageId.flatMap { .imageCaptured(imageId: $0) }
        case "screenLocked": .screenLocked
        case "screenUnlocked": .screenUnlocked
        default: nil
        }
    }
}
