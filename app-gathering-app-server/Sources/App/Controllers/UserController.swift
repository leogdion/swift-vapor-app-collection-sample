//
//  UserController.swift
//  App
//
//  Created by Leo Dion on 7/16/19.
//

import FluentPostgreSQL
import Vapor

final class UserController {
  /**
   Returns the user based on the id or name in the parameters.
   */
  func get(_ req: Request) throws -> Future<User> {
    let userNameOrId = try req.parameters.next(String.self)
    let userFound: EventLoopFuture<User?>
    
    // if an id is passed find based on id
    if let id = UUID(uuidString: userNameOrId) {
      userFound = User.find(id, on: req)
    } else {
      // otherwise find based on username
      userFound = User.query(on: req).filter(\.name == userNameOrId).first()
    }

    // if the user if not found, throw 401 error
    return userFound.unwrap(or: Abort(.unauthorized))
  }

  /**
   Signs the user up based on the SignupRequest.
   */
  func create(_ req: Request) throws -> Future<UserResponse> {
    return try req.content.decode(SignupRequest.self).flatMap { signup in
      User(name: signup.name).save(on: req)
    }.map {
      try UserResponse(name: $0.name, id: $0.requireID())
    }
  }
}
