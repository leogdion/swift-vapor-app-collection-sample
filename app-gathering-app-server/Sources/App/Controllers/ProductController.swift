//
//  ProductController.swift
//  App
//
//  Created by Leo Dion on 7/24/19.
//

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
