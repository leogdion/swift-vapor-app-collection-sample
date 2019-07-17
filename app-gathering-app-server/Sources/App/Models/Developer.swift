//
//  Developer.swift
//  App
//
//  Created by Leo Dion on 7/15/19.
//

import FluentPostgreSQL
import Vapor
final class Developer: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?
  
  /// A title describing what this `Todo` entails.
  var name: String
  
  var url: URL?
  
  /// Creates a new `Todo`.
  init(id: UUID? = nil, name: String, url: URL? = nil) {
    self.id = id
    self.name = name
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension Developer: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Developer: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Developer: Parameter { }
