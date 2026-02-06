//
//  ObservedEventsController.swift
//  PeeperServer
//
//  Created by Александр Ермичев on 2026/02/02.
//

import Dependencies
import Hummingbird

struct ObservedEventsController {
    
    @Dependency(\.eventRepository.notifyEvent) var handleEvent
    
    var endpoints: RouteCollection<AppRequestContext> {
        RouteCollection(context: AppRequestContext.self)
            .post("notify", use: notifyEvent)
    }
    
    struct NotifyEventRequest: Codable {
        let event: String
    }
    
    func notifyEvent(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let request = try await request.decode(as: NotifyEventRequest.self, context: context)
        if try await handleEvent(request.event) {
            return .ok
        } else {
            return .badRequest
        }
    }
}

