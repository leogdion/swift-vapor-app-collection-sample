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

  init(id: UUID? = nil, userId: User.ID, productId: Product.ID) {
    self.id = id
    self.userId = userId
    self.productId = productId
  }
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

extension UserProduct: ModifiablePivot {
  convenience init(_ left: User, _ right: Product) throws {
    try self.init(userId: left.requireID(), productId: right.requireID())
  }
}

extension User {
  var products: Siblings<User, Product, UserProduct> {
    return siblings()
  }
}

extension Product {
  var users: Siblings<Product, User, UserProduct> {
    return siblings()
  }
}
