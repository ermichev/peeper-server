//
//  DiskImageRepository.swift
//  PeeperServer
//
//  Created by Александр Ермичев on 2026/02/11.
//

import Foundation

final actor DiskImageRepository {
    
    // MARK: - Factory
    
    static func buildDependency(baseDirectory: String) -> ImageRepository {
        let instance = Self(baseDirectory: baseDirectory)
        return .init(
            isItemExist: instance.isItemExist,
            getItem: instance.readItem,
            addItem: instance.addItem,
            removeItem: instance.removeItem,
            removeAll: instance.removeAll
        )
    }
    
    // MARK: - Initializer
    
    init(baseDirectory: String) {
        self.baseDirectory = baseDirectory
    }
    
    // MARK: - Private properties
    
    private let baseDirectory: String
    
    private static var fileManager: FileManager { .default }
    
    // MARK: - Private methods
    
    private func filePath(for id: UUID) -> String {
        baseDirectory + "/" + id.uuidString
    }

    private func isItemExist(with id: UUID) async throws -> Bool {
        guard let url = URL(string: filePath(for: id)) else { throw ImageRepository.Errors.internalError }
        return Self.fileManager.fileExists(atPath: url.path(percentEncoded: true))
    }
    
    private func readItem(with id: UUID) async throws -> Data {
        guard let url = URL(string: filePath(for: id)) else { throw ImageRepository.Errors.internalError }
        guard try await isItemExist(with: id) else { throw ImageRepository.Errors.notFound }
        return try Data(contentsOf: url)
    }

    private func addItem(with data: Data) async throws -> UUID {
        guard let directory = URL(string: baseDirectory) else { throw ImageRepository.Errors.internalError }
        if !Self.fileManager.fileExists(atPath: directory.path(percentEncoded: true)) {
            try Self.fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        let id = UUID()
        guard let url = URL(string: filePath(for: id)) else { throw ImageRepository.Errors.internalError }
        try data.write(to: url)
        return id
    }
    
    private func removeItem(with id: UUID) async throws -> Void {
        guard let url = URL(string: filePath(for: id)) else { throw ImageRepository.Errors.internalError }
        guard try await isItemExist(with: id) else { throw ImageRepository.Errors.notFound }
        try Self.fileManager.removeItem(at: url)
    }
    
    private func removeAll() async throws -> Void {
        guard let directoryUrl = URL(string: baseDirectory) else { throw ImageRepository.Errors.internalError }
        try Self.fileManager.removeItem(at: directoryUrl)
    }
}
