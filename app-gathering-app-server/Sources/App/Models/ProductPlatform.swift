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
