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
  
  var artistId : Int
  
  var developerId: UUID
  
  /// Creates a new `Todo`.
  init(id: UUID? = nil, artistId: Int, developerId: UUID) {
    self.id = id
    self.artistId = artistId
    self.developerId = developerId
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension AppleSoftwareDeveloper: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension AppleSoftwareDeveloper: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension AppleSoftwareDeveloper: Parameter { }
