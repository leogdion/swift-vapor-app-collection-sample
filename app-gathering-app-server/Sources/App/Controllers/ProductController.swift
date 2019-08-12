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

final class ProductController {
  /**
   Lists the user's products.
   */
func list(_ req: Request) throws -> Future<[ProductResponse]> {
  // find the logged in user
  let userF = try req.user()

  // get their list of products
  let products = userF.flatMap { user -> Future<[Product]> in
    try user.products.query(on: req).all()
  }

  // convert the products into ProductResponse objects
  return products.flatMap { products in
    try products.map { try ProductResponse.future(from: $0, on: req) }.flatten(on: req)
  }
}

  /**
   Delete a product from the user's list.
   */
  func delete(_ req: Request) throws -> Future<HTTPStatus> {
    // find the logged in user
    let userF = try req.user()

    // get the product id
    let productId = try req.parameters.next(UUID.self)

    // find the product, throw 404 if the product is not found
    let productF = Product.find(productId, on: req).unwrap(or: Abort(HTTPStatus.notFound))

    return userF.and(productF).flatMap { (user, product) -> EventLoopFuture<Void> in
      // throw 404 if the product is not in their list
      user.products.isAttached(product, on: req).flatMap { isAttached in
        guard isAttached else {
          throw Abort(HTTPStatus.notFound)
        }
        return user.products.detach(product, on: req)
      }
    }.transform(to: HTTPStatus.ok)
  }
}
