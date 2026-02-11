//
//  ObservedEventsController.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/02.
//

import Dependencies
import Foundation
import Hummingbird
import MultipartKit

struct ObservedEventsController {
    
    @Dependency(\.eventRepository.notifyEvent) var handleEvent
    @Dependency(\.eventRepository.uploadImage) var storeImage
    
    var endpoints: RouteCollection<AppRequestContext> {
        RouteCollection(context: AppRequestContext.self)
            .post("notify", use: notifyEvent)
            .post("uploadScreenCapture", use: uploadImage)
    }
    
    struct NotifyEventRequest: Codable {
        let event: String
    }
    
    struct UploadImageRequest: Codable {
        let image: Data
    }
    
    private func notifyEvent(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let request = try await request.decode(as: NotifyEventRequest.self, context: context)
        if try await handleEvent(request.event) {
            return .ok
        } else {
            return .badRequest
        }
    }
    
    private func uploadImage(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let imageData = try await decodeMultipart(request: request)
        guard try await storeImage(imageData) else { throw Errors.savingFailed }
        return .ok
    }
    
    private func decodeMultipart(request: Request) async throws -> Data {
        let buffer = try await request.body.collect(upTo: 100_000_000)
        guard let contentType = request.headers[.contentType] else { throw Errors.invalidRequest }
        guard let boundary = contentType.firstMatch(of: /boundary=(.+)/)?.output.1 else { throw Errors.invalidRequest }
        let typedRequest = try FormDataDecoder().decode(UploadImageRequest.self, from: buffer, boundary: String(boundary))
        return typedRequest.image
    }
    
    // -
    
    private enum Errors: Error {
        case emptyBody
        case invalidRequest
        case savingFailed
    }
}
