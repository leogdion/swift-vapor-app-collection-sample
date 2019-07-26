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

    // TODO: get their list of products

    // TODO: convert the products into ProductResponse objects
    
    throw Abort(.notImplemented)
  }

  /**
   Delete a product from the user's list.
   */
  func delete(_ req: Request) throws -> Future<HTTPStatus> {
    // find the logged in user
    let userF = try req.user()

    // TODO: get the product id

    // TODO: find the product, throw 404 if the product is not found
    
    // TODO: throw 404 if the product is not in their list

    throw Abort(.notImplemented)
  }
}
