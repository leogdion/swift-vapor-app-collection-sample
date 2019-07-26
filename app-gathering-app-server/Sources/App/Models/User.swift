//
//  User.swift
//  App
//
//  Created by Leo Dion on 7/15/19.
//

import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class User: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?

  /// A title describing what this `Todo` entails.
  var name: String

  /// Creates a new `Todo`.
  init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension User: PostgreSQLMigration {
  static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return PostgreSQLDatabase.create(User.self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.name)
      builder.unique(on: \.name)
    }
  }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension User: Content {}

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension User: Parameter {}
