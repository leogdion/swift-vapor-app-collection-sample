import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class Product: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?

  /// A title describing what this `Todo` entails.
  var name: String

  var developerId: UUID

  var sourceImageUrl: URL?

  /// Creates a new `Todo`.
  init(id: UUID? = nil, developerId: UUID, name: String, sourceImageUrl _: URL = nil) {
    self.id = id
    self.developerId = developerId
    self.name = name
    sourceImageUrl
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension Product: PostgreSQLMigration {
  static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return PostgreSQLDatabase.create(Product.self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.name)
      builder.field(for: \.developerId)
      builder.unique(on: \.name)
      builder.reference(from: \.developerId, to: Developer.idKey, onDelete: .cascade)
    }
  }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Product: Content {}

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Product: Parameter {}

extension Product {
  var developer: Parent<Product, Developer> {
    return parent(\.developerId)
  }
}

extension Developer {
  var products: Children<Developer, Product> {
    return children(\.developerId)
  }
}
