//
//  UserResponse.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/26/19.
//

import Foundation

#if os(Linux) || os(macOS)
  import Vapor
#endif
struct UserResponse: Codable {
  let name: String
  let id: UUID
}

#if os(Linux) || os(macOS)
  extension UserResponse: Content {}
#endif
