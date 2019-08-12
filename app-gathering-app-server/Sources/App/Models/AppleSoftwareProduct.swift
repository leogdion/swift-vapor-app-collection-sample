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
