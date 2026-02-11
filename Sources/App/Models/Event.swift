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

enum EventType: ResponseCodable, Equatable {
    case broadcastStarted
    case broadcastStopped
    case imageCaptured(imageId: UUID)
    case screenLocked
    case screenUnlocked
}

struct EventMetadata: ResponseCodable, Equatable, Identifiable {
    let id: UUID
    let timestamp: Date
}
