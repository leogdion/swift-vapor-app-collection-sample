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
  var productId: UUID
  var platformId: Int
}
