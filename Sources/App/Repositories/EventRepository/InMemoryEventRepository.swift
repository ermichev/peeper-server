//
//  InMemoryEventRepository.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/02.
//

import Dependencies
import Foundation

final actor InMemoryEventRepository {
   
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
    
    @Dependency(\.imageRepository.addItem) var saveImage
    @Dependency(\.imageRepository.removeAll) var clearSavedImages
    
    private var events: [Event] = []
    
    // MARK: - Private methods
    
    private func events(_ from: TimeInterval?) async throws -> [Event] {
        events
    }
    
    private func event(_ id: UUID) async throws -> Event? {
        events.first { $0.metadata.id == id }
    }
    
    private func uploadImage(_ image: Data) async throws -> Bool {
        let imageId = try await saveImage(image)
        events.append(.init(type: .imageCaptured(imageId: imageId), metadata: .init()))
        return true
    }
    
    private func notifyEvent(_ event: String) async throws -> Bool {
        guard let type = EventType(rawEvent: event) else { throw EventRepository.Errors.unknownEventType }
        events.append(.init(type: type, metadata: .init()))
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
