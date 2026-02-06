//
//  AppTests.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/02.
//

import Configuration
import Dependencies
import Foundation
import Hummingbird
import HummingbirdTesting
import Logging
import Testing

@testable import App

private let reader = ConfigReader(providers: [
    InMemoryProvider(values: [
        "http.host": "127.0.0.1",
        "http.port": "0",
        "log.level": "trace"
    ])
])

@Suite
struct AppTests {
    
    @Test
    func healthEndpoint_alwaysReturnsOk() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.router) { client in
            try await client.execute(uri: "/health", method: .get) { response in
                #expect(response.status == .ok)
            }
        }
    }
    
    @Test
    func norifyEndpoint_storesEventInRepository() async throws {
        @MainActor class EventsHolder {
            var events: [String] = []
        }

        let eventsHolder = EventsHolder()
        
        try await withDependencies {
            $0.eventRepository.notifyEvent = { @MainActor in
                eventsHolder.events.append($0)
                return true
            }
        } operation: {
            let eventName = EventType.screenLocked.rawValue
            let request = ObservedEventsController.NotifyEventRequest(event: eventName)
            let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
            
            let app = try await buildApplication(reader: reader)
            try await app.test(.router) { client in
                try await client.execute(uri: "/observed/notify", method: .post, body: buffer) { @MainActor response in
                    #expect(response.status == .ok)
                    #expect(eventsHolder.events.first == eventName)
                }
            }
        }
    }
}
