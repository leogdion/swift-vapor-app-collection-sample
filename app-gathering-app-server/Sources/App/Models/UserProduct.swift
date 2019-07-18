//
//  UserProduct.swift
//  App
//
//  Created by Leo Dion on 7/18/19.
//

import FluentPostgreSQL
import Vapor

final class UserProduct: PostgreSQLUUIDPivot {
  typealias Left = User

  typealias Right = Product

  static var leftIDKey: LeftIDKey = \.userId

  static var rightIDKey: RightIDKey = \.productId

  var id: UUID?
  var userId: User.ID
  var productId: Product.ID
}

extension UserProduct: PostgreSQLMigration {
  static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return PostgreSQLDatabase.create(UserProduct.self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.userId)
      builder.field(for: \.productId)
      builder.reference(from: \.productId, to: Product.idKey, onDelete: .cascade)
      builder.reference(from: \.userId, to: User.idKey, onDelete: .cascade)
      builder.unique(on: \.productId, \.userId)
    }
  }
}
