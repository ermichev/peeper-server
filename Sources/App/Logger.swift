//
//  Logger.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/16.
//

import Dependencies
import Logging

enum LoggerDependencyKey: DependencyKey {
    static let liveValue = Logger(label: "Peeper")
    static let testValue = Logger(label: "Peeper")
}

extension DependencyValues {
    var logger: Logger {
        get { self[LoggerDependencyKey.self] }
        set { self[LoggerDependencyKey.self] = newValue }
    }
}
