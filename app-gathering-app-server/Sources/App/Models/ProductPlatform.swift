//
//  ProductPlatform.swift
//  App
//
//  Created by Leo Dion on 7/18/19.
//

import Foundation

import FluentPostgreSQL
import Vapor

final class ProductPlatform: PostgreSQLUUIDPivot {
  typealias Left = Product

  typealias Right = Platform

  static var leftIDKey: LeftIDKey = \.productId

  static var rightIDKey: RightIDKey = \.platformId

  var id: UUID?
  var productId: Product.ID
  var platformId: Platform.ID

  init(id: UUID? = nil, productId: UUID, platformId: Int) {
    self.id = id
    self.productId = productId
    self.platformId = platformId
  }
}

extension ProductPlatform: PostgreSQLMigration {
  static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return PostgreSQLDatabase.create(ProductPlatform.self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.productId)
      builder.field(for: \.platformId)
      builder.reference(from: \.productId, to: Product.idKey, onDelete: .cascade)
      builder.reference(from: \.platformId, to: Platform.idKey, onDelete: .cascade)
      builder.unique(on: \.productId, \.platformId)
    }
  }
}

extension Product {
  var platforms: Siblings<Product, Platform, ProductPlatform> {
    return siblings()
  }
}

extension Platform {
  var products: Siblings<Platform, Product, ProductPlatform> {
    return siblings()
  }
}
