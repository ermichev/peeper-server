//
//  Event.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/02.
//

import FluentKit
import Foundation
import Hummingbird

struct Event: ResponseCodable, Equatable {
    let type: EventType
    let metadata: EventMetadata
}

struct EventMetadata: ResponseCodable, Equatable, Identifiable {
    let id: UUID
    let timestamp: Date
}

// -

final class EventModel: Model, @unchecked Sendable {
    static let schema = "events"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "timestamp")
    var timestamp: Date
    
    @Field(key: "type")
    var type: String
    
    @OptionalField(key: "imageId")
    var imageId: UUID?
}

extension Event {
    
    func toModel() -> EventModel {
        let model = EventModel()
        model.id = metadata.id
        model.timestamp = metadata.timestamp
        model.type = type.name
        model.imageId = type.imageId
        return model
    }
}

extension EventModel {
    
    func toEvent() -> Event? {
        guard let id else { return nil }
        guard let type = EventType.from(name: type, with: imageId) else { return nil }
        return .init(type: type, metadata: .init(id: id, timestamp: timestamp))
    }
}
