//
//  ProductController.swift
//  App
//
//  Created by Leo Dion on 7/24/19.
//

import FluentPostgreSQL
import Vapor

final class ProductController {
  func list(_ req: Request) throws -> Future<[ProductResponse]> {
    let userF = try req.content.decode(UserRequest.self).flatMap { User.find($0.id, on: req) }.unwrap(or: Abort(HTTPResponseStatus.unauthorized))

    let products = try userF.flatMap { user -> Future<[Product]> in
      try user.products.query(on: req).all()
    }

    return try products.flatMap { products in
      try products.map { try ProductResponse.future(from: $0, on: req) }.flatten(on: req)
    }
  }
}
