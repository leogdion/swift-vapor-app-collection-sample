//
//  File.swift
//  
//
//  Created by Leo Dion on 7/16/19.
//

import Vapor
import FluentPostgreSQL

/// A single entry of a Todo list.
final class iTunesProduct: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?
  
  var trackId : Int
  
  /// Creates a new `Todo`.
  init(id: UUID, trackId: Int) {
    self.id = id
    self.trackId = trackId
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension iTunesProduct: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension iTunesProduct: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension iTunesProduct: Parameter { }
