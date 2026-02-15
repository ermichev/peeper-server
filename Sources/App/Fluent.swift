//
//  Fluent.swift
//  PeeperServer
//
//  Created by Aleksandr Ermichev on 2026/02/16.
//

import Dependencies
import HummingbirdFluent

enum FluentDependencyKey: DependencyKey {
    static let liveValue = Fluent(logger: Dependency(\.logger).wrappedValue)
    static let testValue = Fluent(logger: Dependency(\.logger).wrappedValue)
}

extension DependencyValues {
    var fluent: Fluent {
        get { self[FluentDependencyKey.self] }
        set { self[FluentDependencyKey.self] = newValue }
    }
}
