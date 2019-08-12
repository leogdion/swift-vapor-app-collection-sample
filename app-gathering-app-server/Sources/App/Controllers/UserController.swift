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
