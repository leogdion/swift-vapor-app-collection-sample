//
//  File.swift
//
//
//  Created by Leo Dion on 7/16/19.
//

import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class AppleSoftwareProduct: PostgreSQLUUIDModel {
  /// The unique identifier for this `Todo`.
  var id: UUID?

  var trackId: Int

  var productId: Product.ID

  var bundleId: String
  /// Creates a new `Todo`.
  init(id: UUID? = nil, trackId: Int, productId: UUID, bundleId: String) {
    self.id = id
    self.trackId = trackId
    self.productId = productId
    self.bundleId = bundleId
  }
}

/// Allows `Todo` to be used as a dynamic migration.
extension AppleSoftwareProduct: PostgreSQLMigration {
  static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return PostgreSQLDatabase.create(AppleSoftwareProduct.self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.trackId)
      builder.field(for: \.productId)
      builder.field(for: \.bundleId)
      builder.unique(on: \.trackId)
      builder.unique(on: \.productId)
      builder.unique(on: \.bundleId)
      builder.reference(from: \.productId, to: Product.idKey, onDelete: .cascade)
    }
  }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension AppleSoftwareProduct: Content {}

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension AppleSoftwareProduct: Parameter {}

extension AppleSoftwareProduct {
  var product: Parent<AppleSoftwareProduct, Product> {
    return parent(\.productId)
  }
}

extension Product {
  var appleSoftware: Children<Product, AppleSoftwareProduct> {
    return children(\.productId)
  }
}
