import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class Product: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?
  
  /// A title describing what this `Todo` entails.
  var name: String
  
  var developerID: UUID
  
  /// Creates a new `Todo`.
  init(id: UUID? = nil, developerID: UUID, name: String) {
    self.id = id
    self.developerID = developerID
    self.name = name
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension Product: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Product: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Product: Parameter { }
