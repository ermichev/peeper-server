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
    @Dependency(\.eventRepository.event) var findEvent
    
    @Dependency(\.imageRepository.isItemExist) var isImageExist
    @Dependency(\.imageRepository.getItem) var fetchImage
    
    var endpoints: RouteCollection<AppRequestContext> {
        RouteCollection(context: AppRequestContext.self)
            .get("getEvents", use: events)
            .get("getScreenCapture", use: screenCapture)
    }
    
    func events(request: Request, context: some RequestContext) async throws -> [Event] {
        let from = TimeInterval(request.uri.queryParameters["from"] ?? "")
        return try await fetchEvents(from)
    }
    
    func screenCapture(request: Request, context: some RequestContext) async throws -> ByteBuffer {
        guard let idParam = request.uri.queryParameters["id"] else { throw Errors.missingArgument }
        guard let imageId = UUID(uuidString: String(idParam)) else { throw Errors.incorrectArgument }
        guard try await isImageExist(imageId) else { throw Errors.notFound }
        let imageData = try await fetchImage(imageId)
        return ByteBuffer(data: imageData)
    }
    
    private enum Errors: Error {
        case missingArgument
        case incorrectArgument
        case notFound
    }
}
