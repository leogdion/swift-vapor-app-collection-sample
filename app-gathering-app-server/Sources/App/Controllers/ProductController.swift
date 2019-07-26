//
//  ProductController.swift
//  App
//
//  Created by Leo Dion on 7/24/19.
//

import FluentPostgreSQL
import Vapor

extension Request {
  func user(on connection : DatabaseConnectable? = nil) throws -> Future<User> {
    let connection = connection ?? self
    
    let userIdOpt = self.http.headers.firstValue(name: .init("X-User-Id")).flatMap{ UUID($0)}
    
    guard let userId = userIdOpt else {
      throw Abort(HTTPResponseStatus.unauthorized)
    }
    
    return User.find(userId, on: connection).unwrap(or: Abort(HTTPResponseStatus.unauthorized))
  }
}
final class ProductController {
  func list(_ req: Request) throws -> Future<[ProductResponse]> {
    
    
    let userF = try req.user()
    
    let products = userF.flatMap { user -> Future<[Product]> in
      try user.products.query(on: req).all()
    }
    
    return try products.flatMap { products in
      try products.map { try ProductResponse.future(from: $0, on: req) }.flatten(on: req)
    }
  }
  
  func delete(_ req: Request) throws -> Future<HTTPStatus> {
    let userF = try req.user()
    
    let productId = try req.parameters.next(UUID.self)
    
    let productF = Product.find(productId, on: req).unwrap(or: Abort(HTTPStatus.notFound))
    
    return userF.and(productF).flatMap { (user, product) -> EventLoopFuture<Void> in
      user.products.isAttached(product, on: req).flatMap { (isAttached) in
        guard isAttached else {
          throw Abort(HTTPStatus.notFound)
        }
        return user.products.detach(product, on: req)
      }
    }.transform(to: HTTPStatus.ok)
    
  }
}
