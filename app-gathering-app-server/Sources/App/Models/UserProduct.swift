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
  var userId: UUID
  var productId: UUID
}
