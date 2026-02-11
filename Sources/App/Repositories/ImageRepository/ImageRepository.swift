//
//  ImageRepository.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/02.
//

import Dependencies
import Foundation

struct ImageRepository: Sendable {
    var isItemExist: @Sendable (_ id: UUID) async throws -> Bool
    var getItem: @Sendable (_ id: UUID) async throws -> Data
    var addItem: @Sendable (_ item: Data) async throws -> UUID
    var removeItem: @Sendable (_ id: UUID) async throws -> Void
    var removeAll: @Sendable () async throws -> Void
}

extension ImageRepository {
    
    enum Errors: Error {
        case notFound
        case internalError
    }
}

extension ImageRepository: DependencyKey {
    static var liveValue: Self {
        DiskImageRepository.buildDependency(
            baseDirectory: FileManager.default.homeDirectoryForCurrentUser.absoluteString + ".peeper/images"
        )
    }
    static var testValue: Self {
        .init(
            isItemExist: unimplemented("ImageRepository.events"),
            getItem: unimplemented("ImageRepository.getItem"),
            addItem: unimplemented("ImageRepository.addItem"),
            removeItem: unimplemented("ImageRepository.removeItem"),
            removeAll:  unimplemented("ImageRepository.removeAll")
        )
    }
}

extension DependencyValues {
    var imageRepository: ImageRepository {
        get { self[ImageRepository.self] }
        set { self[ImageRepository.self] = newValue }
    }
}
