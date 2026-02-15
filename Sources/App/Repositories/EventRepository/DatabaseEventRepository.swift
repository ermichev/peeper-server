//
//  DatabaseEventRepository.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/16.
//

import Dependencies
import FluentKit
import Foundation
import HummingbirdFluent

final actor DatabaseEventRepository {
   
    // MARK: - Factory
    
    static func buildDependency() -> EventRepository {
        let instance = Self()
        return .init(
            events: instance.events,
            event: instance.event,
            uploadImage: instance.uploadImage,
            notifyEvent: instance.notifyEvent
        )
    }
    
    // MARK: - Private properties
    
    @Dependency(\.fluent) var fluent
    @Dependency(\.imageRepository.addItem) var saveImage
    @Dependency(\.imageRepository.removeAll) var clearSavedImages
    
    // MARK: - Private methods
    
    private func events(_ from: TimeInterval?) async throws -> [Event] {
        if let from {
            try await EventModel
                .query(on: fluent.db())
                .filter(\.$timestamp, .greaterThanOrEqual, Date(timeIntervalSince1970: from))
                .all()
                .compactMap { $0.toEvent() }
        } else {
            try await EventModel
                .query(on: fluent.db())
                .all()
                .compactMap { $0.toEvent() }
        }
    }
    
    private func event(_ id: UUID) async throws -> Event? {
        try await EventModel.find(id, on: fluent.db())?.toEvent()
    }
    
    private func uploadImage(_ image: Data) async throws -> Bool {
        let imageId = try await saveImage(image)
        let eventModel = Event(type: .imageCaptured(imageId: imageId), metadata: .init()).toModel()
        try await eventModel.save(on: fluent.db())
        return true
    }
    
    private func notifyEvent(_ event: String) async throws -> Bool {
        guard let type = EventType(rawEvent: event) else { throw EventRepository.Errors.unknownEventType }
        let eventModel = Event(type: type, metadata: .init()).toModel()
        try await eventModel.save(on: fluent.db())
        return true
    }
}

private extension EventType {
    
    init?(rawEvent: String) {
        switch rawEvent {
        case "broadcastStarted": self = .broadcastStarted
        case "broadcastStopped": self = .broadcastStopped
        case "screenLocked": self = .screenLocked
        case "screenUnlocked": self = .screenUnlocked
        default: return nil
        }
    }
}

private extension EventMetadata {
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
    }
}
