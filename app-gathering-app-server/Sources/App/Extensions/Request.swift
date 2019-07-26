//
//  Request.swift
//  App
//
//  Created by Leo Dion on 7/25/19.
//

import Vapor

extension Request {
  /**
   Fake authentication which gets the user based on the User id given as an http header.
   */
  func user(on connection: DatabaseConnectable? = nil) throws -> Future<User> {
    let connection = connection ?? self

    let userIdOpt = http.headers.firstValue(name: .init("X-User-Id")).flatMap { UUID($0) }

    guard let userId = userIdOpt else {
      throw Abort(HTTPResponseStatus.unauthorized)
    }

    return User.find(userId, on: connection).unwrap(or: Abort(HTTPResponseStatus.unauthorized))
  }
}
