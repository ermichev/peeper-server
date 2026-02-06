//
//  EventRepository.swift
//  ScreenCaptureServer
//
//  Created by Александр Ермичев on 2026/02/02.
//

import Dependencies
import Foundation

struct EventRepository: Sendable {
    var events: @Sendable (_ from: TimeInterval?) async throws -> [Event]
    var uploadImage: @Sendable (_ image: Data) async throws -> Bool
    var notifyEvent: @Sendable (_ event: String) async throws -> Bool
}

extension EventRepository {
    
    enum Errors: Error {
        case unknownEventType
        case useUploadImage
    }
}

extension EventRepository: DependencyKey {
    static var liveValue: Self { InMemoryEventRepository.make() }
    static var testValue: Self {
        .init(
            events: unimplemented("EventRepository.events"),
            uploadImage: unimplemented("EventRepository.uploadImage"),
            notifyEvent: unimplemented("EventRepository.notifyEvent")
        )
    }
}

extension DependencyValues {
    var eventRepository: EventRepository {
        get { self[EventRepository.self] }
        set { self[EventRepository.self] = newValue }
    }
}
