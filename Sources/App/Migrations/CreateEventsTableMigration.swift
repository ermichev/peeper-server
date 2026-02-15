//
//  CreateEventsTableMigration.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/16.
//

import FluentKit

struct CreateEventsTableMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        return try await database.schema("events")
            .id()
            .field("timestamp", .datetime, .required)
            .field("type", .string, .required)
            .field("imageId", .uuid)
            .create()
    }

    func revert(on database: Database) async throws {
        return try await database.schema("parks").delete()
    }
}
