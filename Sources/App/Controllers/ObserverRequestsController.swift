//
//  ObserverRequestsController.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/07.
//

import Dependencies
import Foundation
import Hummingbird

struct ObserverRequestsController {
    
    @Dependency(\.eventRepository.events) var fetchEvents
    
    var endpoints: RouteCollection<AppRequestContext> {
        RouteCollection(context: AppRequestContext.self)
            .get("events", use: events)
    }
    
    func events(request: Request, context: some RequestContext) async throws -> [Event] {
        let from = TimeInterval(request.uri.queryParameters["from"] ?? "")
        return try await fetchEvents(from)
    }
}
