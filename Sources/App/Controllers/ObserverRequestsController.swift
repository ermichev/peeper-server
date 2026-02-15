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
            .get("getEvents", use: getEvents)
            .get("getScreenCapture", use: getScreenCapture)
    }
    
    func getEvents(request: Request, context: some RequestContext) async throws -> [Event] {
        let from = TimeInterval(request.uri.queryParameters["from"] ?? "")
        return try await fetchEvents(from)
    }
    
    func getScreenCapture(request: Request, context: some RequestContext) async throws -> Response {
        guard let idParam = request.uri.queryParameters["id"] else { return Response(status: .badRequest) }
        guard let imageId = UUID(uuidString: String(idParam)) else { return Response(status: .badRequest) }
        guard try await isImageExist(imageId) else { return Response(status: .notFound) }
        let imageData = try await fetchImage(imageId)
        return ByteBuffer(data: imageData)
            .response(from: request, context: context)
    }
}
