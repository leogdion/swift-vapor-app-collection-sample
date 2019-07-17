//
//  UserController.swift
//  App
//
//  Created by Leo Dion on 7/16/19.
//

import Vapor
import FluentPostgreSQL

final class UserController {
  /// Returns a list of all `Todo`s.
  func get(_ req: Request) throws -> Future<User> {
    let userNameOrId = try req.parameters.next(String.self)
    let userFound : EventLoopFuture<User?>
    if let id = UUID(uuidString: userNameOrId) {
      userFound = User.find(id, on: req)
    } else {
      userFound = User.query(on: req).filter(\.name == userNameOrId).first()
    }
    
    return userFound.map { (possibleUser) -> (User) in
      guard let user = possibleUser else {
        throw Abort(.notFound)
      }
      return user
    }
  }
  
  /// Saves a decoded `Todo` to the database.
  func create(_ req: Request) throws -> Future<User> {
    return try req.content.decode(User.self).flatMap { user in
      return user.save(on: req)
    }
  }
  
}
