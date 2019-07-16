//
//  File.swift
//  
//
//  Created by Leo Dion on 7/16/19.
//

import Vapor

final class UserController {
  func create(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.content.decode(User.self).flatMap { user in
      return user.save(on: req)
    }.transform(to: HTTPStatus.created)
  }
  
  /// Deletes a parameterized `Todo`.
  func get(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters.next(Product.self).flatMap { todo in
      return todo.delete(on: req)
    }.transform(to: .ok)
  }
}
