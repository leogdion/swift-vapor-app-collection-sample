import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class Product: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?

  /// A title describing what this `Todo` entails.
  var name: String

  var developerId: UUID

  /// Creates a new `Todo`.
  init(id: UUID? = nil, developerId: UUID, name: String) {
    self.id = id
    self.developerId = developerId
    self.name = name
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension Product: Migration {}

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
