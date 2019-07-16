//
//  Platform.swift
//  App
//
//  Created by Leo Dion on 7/15/19.
//

import Vapor
import FluentPostgreSQL

final class Platform : PostgreSQLModel {
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
extension Platform: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Platform: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Platform: Parameter { }

