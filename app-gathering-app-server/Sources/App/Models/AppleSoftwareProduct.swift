//
//  File.swift
//  
//
//  Created by Leo Dion on 7/16/19.
//

import Vapor
import FluentPostgreSQL

/// A single entry of a Todo list.
final class AppleSoftwareProduct: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?
  
  var trackId : Int
  
  var productId: UUID
  
  
  var bundleId : String
  /// Creates a new `Todo`.
  init(id: UUID, trackId: Int, productId: UUID, bundleId: String) {
    self.id = id
    self.trackId = trackId
    self.productId = productId
    self.bundleId = bundleId
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension AppleSoftwareProduct: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension AppleSoftwareProduct: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension AppleSoftwareProduct: Parameter { }
