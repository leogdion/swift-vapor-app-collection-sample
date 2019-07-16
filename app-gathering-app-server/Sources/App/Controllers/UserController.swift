//
//  UserController.swift
//  App
//
//  Created by Leo Dion on 7/16/19.
//

import Vapor

final class UserController {
  /// Returns a list of all `Todo`s.
//  func get(_ req: Request) throws -> Future<HTTPStatus> {
//    return try req.content.decode(User.self).flatMap { user in
//      return User.
//      }.transform(to: HTTPStatus.ok)
//  }
  
  /// Saves a decoded `Todo` to the database.
  func create(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.content.decode(User.self).flatMap { user in
      return user.save(on: req)
    }.transform(to: HTTPStatus.created)
  }
  
}
