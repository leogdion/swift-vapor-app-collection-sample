// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the  Software), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
// THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
