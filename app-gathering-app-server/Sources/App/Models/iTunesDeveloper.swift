//
//  File.swift
//  
//
//  Created by Leo Dion on 7/16/19.
//

import FluentPostgreSQL
import Vapor


/// A single entry of a Todo list.
final class iTunesDeveloper: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?
  
  var artistId : Int
  
  /// Creates a new `Todo`.
  init(id: UUID? = nil, artistId: Int) {
    self.id = id
    self.artistId = artistId
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension iTunesDeveloper: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension iTunesDeveloper: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension iTunesDeveloper: Parameter { }
