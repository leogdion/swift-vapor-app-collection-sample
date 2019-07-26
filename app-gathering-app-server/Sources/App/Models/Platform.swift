//
//  Platform.swift
//  App
//
//  Created by Leo Dion on 7/15/19.
//

import FluentPostgreSQL
import Vapor

final class Platform: PostgreSQLModel {
  var id: Int?

  /// A title describing what this `Todo` entails.
  var name: String

  /// Creates a new `Todo`.
  init(id: Int? = nil, name: String) {
    self.id = id
    self.name = name
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension Platform: PostgreSQLMigration {
  static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return PostgreSQLDatabase.create(Platform.self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.name)
      builder.unique(on: \.name)
    }
  }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Platform: Content {}

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Platform: Parameter {}
