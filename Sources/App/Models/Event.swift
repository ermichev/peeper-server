//
//  Event.swift
//  ScreenCaptureServer
//
//  Created by Александр Ермичев on 2026/02/02.
//

import Foundation
import Hummingbird

struct Event: ResponseCodable, Equatable {
    let type: EventType
    let metadata: EventMetadata
}

enum EventType: String, ResponseCodable, Equatable {
    case broadcastStarted
    case broadcastStopped
    case imageCaptured
    case screenLocked
    case screenUnlocked
}

struct EventMetadata: ResponseCodable, Equatable, Identifiable {
    let id: String
    let timestamp: Date
}
