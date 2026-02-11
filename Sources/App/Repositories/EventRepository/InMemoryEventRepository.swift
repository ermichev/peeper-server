//
//  InMemoryEventRepository.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/02.
//

import Foundation

enum InMemoryEventRepository {
    
    actor EventsHolder {
        var events: [Event] = []
        func addEvent(_ event: Event) {
            events.append(event)
        }
    }
    
    @MainActor static var events = EventsHolder()
    
    static func make() -> EventRepository {
        return .init(
            events: events,
            uploadImage: uploadImage,
            notifyEvent: notifyEvent
        )
    }
    
    private static func events(_ from: TimeInterval?) async throws -> [Event] {
        await events.events
    }
    
    private static func uploadImage(_ image: Data) async throws -> Bool {
        await Self.events.addEvent(.init(type: .imageCaptured, metadata: .init()))
        return true
    }
    
    private static func notifyEvent(_ event: String) async throws -> Bool {
        guard let type = EventType(rawValue: event) else { throw EventRepository.Errors.unknownEventType }
        guard type != .imageCaptured else { throw EventRepository.Errors.useUploadImage }
        await Self.events.addEvent(.init(type: type, metadata: .init()))
        return true
    }
}

private extension EventMetadata {
    
    init() {
        self.id = UUID().uuidString
        self.timestamp = Date()
    }
}
