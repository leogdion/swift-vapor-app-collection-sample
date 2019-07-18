//
//  File.swift
//
//
//  Created by Leo Dion on 7/16/19.
//

import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class AppleSoftwareDeveloper: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?

  var artistId: Int

  var developerId: Developer.ID

  /// Creates a new `Todo`.
  init(id: UUID? = nil, artistId: Int, developerId: UUID) {
    self.id = id
    self.artistId = artistId
    self.developerId = developerId
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension AppleSoftwareDeveloper: PostgreSQLMigration {
  static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return PostgreSQLDatabase.create(AppleSoftwareDeveloper.self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.artistId)
      builder.field(for: \.developerId)
      builder.unique(on: \.artistId)
      builder.unique(on: \.developerId)
      builder.reference(from: \.developerId, to: Developer.idKey, onDelete: .cascade)
    }
  }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension AppleSoftwareDeveloper: Content {}

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension AppleSoftwareDeveloper: Parameter {}

extension AppleSoftwareDeveloper {
  var developer: Parent<AppleSoftwareDeveloper, Developer> {
    return parent(\.developerId)
  }
}

extension Developer {
  var appleSoftware: Children<Developer, AppleSoftwareDeveloper> {
    return children(\.developerId)
  }
}
