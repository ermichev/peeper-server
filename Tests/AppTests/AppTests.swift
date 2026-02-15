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
import NIOFoundationCompat
import MultipartKit
import Testing

@testable import App

private let reader = ConfigReader(providers: [
    InMemoryProvider(values: [
        "http.host": "127.0.0.1",
        "http.port": "0",
        "log.level": "trace",
        "testing": true
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
    func notifyEndpoint_storesEventInRepository() async throws {
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
            let eventName = "screenLocked"
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
    
    // MARK: - uploadScreenCapture tests
    
    @Test
    func uploadScreenCapture_validMultipartImage_returnsOk() async throws {
        let capturedImageData = LockIsolated<Data?>(nil)
        
        try await withDependencies {
            $0.eventRepository.uploadImage = { @Sendable imageData in
                capturedImageData.setValue(imageData)
                return true
            }
        } operation: {
            let imageData = Data("test-image".utf8)
            let boundary = UUID().uuidString
            let multipartBody = createMultipartBody(imageData: imageData, boundary: boundary)
            let buffer = ByteBuffer(data: multipartBody)
            
            let app = try await buildApplication(reader: reader)
            try await app.test(.router) { client in
                var headers = HTTPFields()
                headers[.contentType] = "multipart/form-data; boundary=\(boundary)"
                
                try await client.execute(
                    uri: "/observed/uploadScreenCapture",
                    method: .post,
                    headers: headers,
                    body: buffer
                ) { response in
                    #expect(response.status == .ok)
                }
            }
            
            let capturedData = capturedImageData.value
            #expect(capturedData == imageData)
        }
    }
    
    @Test
    func uploadScreenCapture_storeFails_returnsServerError() async throws {
        try await withDependencies {
            $0.eventRepository.uploadImage = { @Sendable _ in
                return false
            }
        } operation: {
            let imageData = Data("test-image".utf8)
            let boundary = UUID().uuidString
            let multipartBody = createMultipartBody(imageData: imageData, boundary: boundary)
            let buffer = ByteBuffer(data: multipartBody)
            
            let app = try await buildApplication(reader: reader)
            try await app.test(.router) { client in
                var headers = HTTPFields()
                headers[.contentType] = "multipart/form-data; boundary=\(boundary)"
                
                try await client.execute(
                    uri: "/observed/uploadScreenCapture",
                    method: .post,
                    headers: headers,
                    body: buffer
                ) { response in
                    #expect(response.status == .internalServerError)
                }
            }
        }
    }
    
    @Test
    func uploadScreenCapture_missingContentType_returnsBadRequest() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/observed/uploadScreenCapture",
                method: .post
            ) { response in
                #expect(response.status == .badRequest)
            }
        }
    }
    
    @Test
    func uploadScreenCapture_invalidBoundary_returnsBadRequest() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.router) { client in
            var headers = HTTPFields()
            headers[.contentType] = "multipart/form-data"
            
            try await client.execute(
                uri: "/observed/uploadScreenCapture",
                method: .post,
                headers: headers
            ) { response in
                #expect(response.status == .badRequest)
            }
        }
    }
    
    // MARK: - getScreenCapture tests
    
    @Test
    func getScreenCapture_existingImage_returnsImageData() async throws {
        let testImageId = UUID()
        let testImageData = Data("screen-capture".utf8)
        
        try await withDependencies {
            $0.imageRepository.isItemExist = { @Sendable id in
                return id == testImageId
            }
            $0.imageRepository.getItem = { @Sendable id in
                guard id == testImageId else { throw ImageRepository.Errors.notFound }
                return testImageData
            }
        } operation: {
            let app = try await buildApplication(reader: reader)
            try await app.test(.router) { client in
                try await client.execute(
                    uri: "/observer/getScreenCapture?id=\(testImageId.uuidString)",
                    method: .get
                ) { response in
                    #expect(response.status == .ok)
                    let bodyData = Data(response.body.readableBytesView)
                    #expect(bodyData == testImageData)
                }
            }
        }
    }
    
    @Test
    func getScreenCapture_missingIdParameter_returnsBadRequest() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/observer/getScreenCapture",
                method: .get
            ) { response in
                #expect(response.status == .badRequest)
            }
        }
    }
    
    @Test
    func getScreenCapture_invalidIdFormat_returnsBadRequest() async throws {
        let app = try await buildApplication(reader: reader)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/observer/getScreenCapture?id=invalid-uuid",
                method: .get
            ) { response in
                #expect(response.status == .badRequest)
            }
        }
    }
    
    @Test
    func getScreenCapture_nonExistentImage_returnsNotFound() async throws {
        try await withDependencies {
            $0.imageRepository.isItemExist = { @Sendable _ in
                return false
            }
        } operation: {
            let app = try await buildApplication(reader: reader)
            try await app.test(.router) { client in
                try await client.execute(
                    uri: "/observer/getScreenCapture?id=\(UUID().uuidString)",
                    method: .get
                ) { response in
                    #expect(response.status == .notFound)
                }
            }
        }
    }
}

// MARK: - Helper Functions

private func createMultipartBody(imageData: Data, boundary: String) -> Data {
    var body = Data()
    
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"image\"; filename=\"capture.png\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n".data(using: .utf8)!)
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    return body
}
