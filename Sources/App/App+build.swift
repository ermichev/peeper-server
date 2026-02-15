//
//  App+build.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/02.
//

import Configuration
import Dependencies
import FluentSQLiteDriver
import Hummingbird
import HummingbirdFluent
import Logging

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter reader: configuration reader
func buildApplication(reader: ConfigReader) async throws -> some ApplicationProtocol {
    var logger = Dependency(\.logger).wrappedValue
    logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
    
    let fluent = Dependency(\.fluent).wrappedValue
    fluent.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    await fluent.migrations.add(CreateEventsTableMigration())
    try await fluent.migrate()
    
    let router = try buildRouter()
    let app = Application(
        router: router,
        configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
        services: [fluent],
        logger: logger
    )
    return app
}

/// Build router
func buildRouter() throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    // Add ping endpoint
    router.get("/health") { _,_ in
        return Response(status: .ok)
    }
    router.addRoutes(ObservedEventsController().endpoints, atPath: "/observed")
    router.addRoutes(ObserverRequestsController().endpoints, atPath: "/observer")
    return router
}
